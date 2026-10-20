//! Native result ownership boundary. Each call owns an independent result.
use base64::{engine::general_purpose::STANDARD, Engine};
use forme::{
    model::{Document, NodeKind},
    render_with_options, RenderOptions,
};
use forme_pdf_html::{html_to_document, FontSpec, HtmlOptions};
use html5ever::{parse_document, tendril::TendrilSink};
use markup5ever_rcdom::{NodeData, RcDom};
use serde::Deserialize;
use std::{
    collections::HashMap,
    fs::File,
    io::Read,
    panic::{catch_unwind, AssertUnwindSafe},
    path::{Path, PathBuf},
    ptr, slice,
    thread::{self, Builder},
};

/// Deepest element nesting accepted. Parsing, mapping and layout recurse per
/// level, so deeper documents fail cleanly instead of overflowing the stack.
const MAX_DEPTH: usize = 512;
/// Renders run on their own thread: Ruby threads often have a 1 MiB stack.
const RENDER_STACK_BYTES: usize = 64 << 20;
const MAX_IMAGE_BYTES: u64 = 64 << 20;

#[derive(Default, Deserialize)]
#[serde(default, deny_unknown_fields)]
struct Options {
    css: Option<String>,
    fonts: Vec<Font>,
    image_root: Option<String>,
}
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Font {
    family: String,
    data: String,
    weight: u32,
    italic: bool,
}

pub struct RenderResult {
    status: i32,
    pdf: Vec<u8>,
    metadata: Vec<u8>,
    error: Vec<u8>,
}
impl RenderResult {
    fn error(status: i32, message: String) -> Self {
        Self {
            status,
            pdf: vec![],
            metadata: vec![],
            error: message.into_bytes(),
        }
    }
}
fn render(html: &[u8], options: &[u8]) -> Result<RenderResult, String> {
    let html = std::str::from_utf8(html).map_err(|_| "HTML must be UTF-8")?;
    let input: Options = serde_json::from_slice(options).map_err(|e| e.to_string())?;
    let image_root = input
        .image_root
        .map(|root| Path::new(&root).canonicalize())
        .transpose()
        .map_err(|_| "image_root must be a readable directory")?;
    if nesting_depth(html) > MAX_DEPTH {
        return Err(format!("HTML nesting exceeds {MAX_DEPTH} levels"));
    }
    let mut opts = HtmlOptions {
        css: input.css,
        ..HtmlOptions::default()
    };
    for font in input.fonts {
        let data = STANDARD
            .decode(font.data)
            .map_err(|_| "Invalid font Base64")?;
        ttf_parser::Face::parse(&data, 0).map_err(|_| "Invalid font data")?;
        if font.family.is_empty() || !(1..=1000).contains(&font.weight) {
            return Err("Invalid font family or weight".into());
        }
        opts.fonts.push(FontSpec {
            family: font.family,
            data,
            weight: font.weight,
            italic: font.italic,
        });
    }
    // forme_pdf_html::render_html, with file images resolved by this binding.
    let (mut doc, mut warnings) = html_to_document(html, &opts);
    resolve_local_images(&mut doc, image_root.as_deref(), &mut warnings);
    let (pdf, engine_warnings, passes) = render_with_options(
        &doc,
        RenderOptions {
            audit_content: opts.audit_content,
        },
    )
    .map_err(|e| e.to_string())?;
    warnings.extend(engine_warnings);
    let metadata = serde_json::to_vec(
        &serde_json::json!({"warnings": dedup_warnings(warnings), "passes": passes}),
    )
    .map_err(|e| e.to_string())?;
    Ok(RenderResult {
        status: 0,
        pdf,
        metadata,
        error: vec![],
    })
}

/// Element depth of the parsed DOM, measured without recursion.
fn nesting_depth(html: &str) -> usize {
    let dom = parse_document(RcDom::default(), Default::default()).one(html);
    let mut deepest = 0;
    // Hold `dom` until the walk ends: rcdom's iterative Drop empties child
    // lists even while other handles still reference those children.
    let mut pending = vec![(dom.document.clone(), 0)];
    while let Some((node, depth)) = pending.pop() {
        let depth = depth + usize::from(matches!(node.data, NodeData::Element { .. }));
        deepest = deepest.max(depth);
        pending.extend(node.children.borrow().iter().map(|c| (c.clone(), depth)));
    }
    deepest
}

/// The engine reads `/`, `./` and `../` image sources from disk itself. Inline
/// them as data URIs when they resolve to a regular file inside `image_root`;
/// otherwise omit the image. Warnings never echo paths or OS errors.
fn resolve_local_images(doc: &mut Document, root: Option<&Path>, warnings: &mut Vec<String>) {
    let mut pending: Vec<_> = doc.children.iter_mut().collect();
    while let Some(node) = pending.pop() {
        if let NodeKind::Image { src, .. } = &mut node.kind {
            if src.starts_with('/') || src.starts_with("./") || src.starts_with("../") {
                match local_image(src, root) {
                    Ok(data) => *src = format!("data:image/*;base64,{}", STANDARD.encode(data)),
                    Err(reason) => {
                        warnings.push(format!("Local image omitted: {reason}"));
                        src.clear();
                    }
                }
            }
        }
        pending.extend(node.children.iter_mut());
    }
}

fn local_image(src: &str, root: Option<&Path>) -> Result<Vec<u8>, &'static str> {
    let root = root.ok_or("pass image_root to allow file images")?;
    let path = if src.starts_with('/') {
        PathBuf::from(src)
    } else {
        root.join(src)
    };
    let path = path.canonicalize().map_err(|_| "file not found")?;
    if !path.starts_with(root) {
        return Err("path is outside image_root");
    }
    let file = File::open(&path).map_err(|_| "file not readable")?;
    if !file.metadata().map_err(|_| "file not readable")?.is_file() {
        return Err("not a regular file");
    }
    let mut data = Vec::new();
    file.take(MAX_IMAGE_BYTES + 1)
        .read_to_end(&mut data)
        .map_err(|_| "file not readable")?;
    if data.len() as u64 > MAX_IMAGE_BYTES {
        return Err("file exceeds 64 MiB");
    }
    Ok(data)
}

/// Same as forme_pdf_html's private helper: collapse repeats into "… (×N)".
fn dedup_warnings(warnings: Vec<String>) -> Vec<String> {
    let mut order = Vec::new();
    let mut counts: HashMap<String, usize> = HashMap::new();
    for warning in warnings {
        let count = counts.entry(warning.clone()).or_insert(0);
        if *count == 0 {
            order.push(warning);
        }
        *count += 1;
    }
    order
        .into_iter()
        .map(|w| match counts[&w] {
            1 => w,
            n => format!("{w} (×{n})"),
        })
        .collect()
}
#[no_mangle]
pub extern "C" fn forme_abi_version() -> u32 {
    1
}

/// Render valid caller-owned buffers; null input is allowed only at length zero.
/// # Safety
/// Non-null pointers must address readable buffers of the supplied lengths.
#[no_mangle]
pub unsafe extern "C" fn forme_render_html(
    html: *const u8,
    html_len: usize,
    options: *const u8,
    options_len: usize,
) -> *mut RenderResult {
    let output = catch_unwind(AssertUnwindSafe(|| {
        if (html.is_null() && html_len != 0)
            || (options.is_null() && options_len != 0)
            || html_len > isize::MAX as usize
            || options_len > isize::MAX as usize
        {
            return RenderResult::error(1, "Invalid input buffer".into());
        }
        let h = if html_len == 0 {
            &[]
        } else {
            slice::from_raw_parts(html, html_len)
        };
        let o = if options_len == 0 {
            b"{}"
        } else {
            slice::from_raw_parts(options, options_len)
        };
        thread::scope(|scope| {
            match Builder::new()
                .name("forme-render".into())
                .stack_size(RENDER_STACK_BYTES)
                .spawn_scoped(scope, || render(h, o))
            {
                Ok(worker) => match worker.join() {
                    Ok(output) => output.unwrap_or_else(|e| RenderResult::error(1, e)),
                    Err(_) => RenderResult::error(2, "Native renderer panicked".into()),
                },
                Err(_) => RenderResult::error(1, "Cannot start render thread".into()),
            }
        })
    }))
    .unwrap_or_else(|_| RenderResult::error(2, "Native renderer panicked".into()));
    Box::into_raw(Box::new(output))
}
/// # Safety
/// Result must be a live handle returned by forme_render_html, or null.
#[no_mangle]
pub unsafe extern "C" fn forme_result_status(result: *const RenderResult) -> i32 {
    result.as_ref().map_or(3, |r| r.status)
}
/// Borrow result bytes: field 0 = PDF, 1 = metadata JSON, 2 = error UTF-8.
/// # Safety
/// Result must be live and len must point to writable size_t storage.
#[no_mangle]
pub unsafe extern "C" fn forme_result_bytes(
    result: *const RenderResult,
    field: u32,
    len: *mut usize,
) -> *const u8 {
    if len.is_null() {
        return ptr::null();
    }
    *len = 0;
    let Some(r) = result.as_ref() else {
        return ptr::null();
    };
    let bytes = match field {
        0 => &r.pdf,
        1 => &r.metadata,
        2 => &r.error,
        _ => return ptr::null(),
    };
    *len = bytes.len();
    bytes.as_ptr()
}
/// # Safety
/// Handle must be null or a live allocation from forme_render_html, destroyed once.
#[no_mangle]
pub unsafe extern "C" fn forme_result_destroy(result: *mut RenderResult) {
    if !result.is_null() {
        drop(Box::from_raw(result));
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn pdf() {
        assert!(render(b"<p>hello</p>", b"{}")
            .unwrap()
            .pdf
            .starts_with(b"%PDF-"));
    }
    #[test]
    fn invalid_utf8() {
        assert!(render(&[255], b"{}").is_err());
    }
    #[test]
    fn unknown_option() {
        assert!(render(b"hi", br#"{"typo":1}"#).is_err());
    }
    #[test]
    fn null_buffer() {
        unsafe {
            let r = forme_render_html(ptr::null(), 1, ptr::null(), 0);
            assert_ne!(forme_result_status(r), 0);
            forme_result_destroy(r);
            forme_result_destroy(ptr::null_mut());
        }
    }
    /// Render through the C ABI, as Ruby does: status and error text.
    fn ffi_render(html: &str, options: &str) -> (i32, String) {
        unsafe {
            let r = forme_render_html(html.as_ptr(), html.len(), options.as_ptr(), options.len());
            let mut len = 0;
            let error = forme_result_bytes(r, 2, &mut len);
            let error = String::from_utf8_lossy(slice::from_raw_parts(error, len)).into_owned();
            let status = forme_result_status(r);
            forme_result_destroy(r);
            (status, error)
        }
    }
    #[test]
    fn nesting_limit() {
        let nested = |depth: usize| "<div>".repeat(depth) + "x" + &"</div>".repeat(depth);
        assert_eq!(nesting_depth(&nested(10)), 12);
        assert_eq!(ffi_render(&nested(MAX_DEPTH - 2), "{}").0, 0);
        let (status, error) = ffi_render(&nested(MAX_DEPTH), "{}");
        assert_eq!(status, 1);
        assert!(error.contains("nesting"));
    }
    #[test]
    fn deep_render_on_small_caller_stack() {
        let html = "<div>".repeat(MAX_DEPTH - 2);
        let status = thread::Builder::new()
            .stack_size(256 << 10)
            .spawn(move || unsafe {
                let r = forme_render_html(html.as_ptr(), html.len(), ptr::null(), 0);
                let status = forme_result_status(r);
                forme_result_destroy(r);
                status
            })
            .unwrap()
            .join()
            .unwrap();
        assert_eq!(status, 0);
    }
    #[test]
    fn file_images_need_image_root() {
        let html = br#"<img width="10" height="10" src="/etc/hosts">"#;
        let metadata = render(html, b"{}").unwrap().metadata;
        let metadata = String::from_utf8(metadata).unwrap();
        assert!(metadata.contains("Local image omitted: pass image_root"));
        assert!(!metadata.contains("/etc/hosts"));
        let outside = render(html, br#"{"image_root":"/tmp"}"#).unwrap().metadata;
        assert!(String::from_utf8(outside)
            .unwrap()
            .contains("outside image_root"));
        assert!(render(html, br#"{"image_root":"/nonexistent/forme"}"#).is_err());
    }
    #[test]
    fn result_accessors_reject_invalid_arguments() {
        unsafe {
            assert_eq!(forme_result_status(ptr::null()), 3);
            let r = forme_render_html(b"hi".as_ptr(), 2, ptr::null(), 0);
            let mut len = 7;
            assert!(forme_result_bytes(r, 3, &mut len).is_null());
            assert_eq!(len, 0);
            assert!(forme_result_bytes(r, 0, ptr::null_mut()).is_null());
            assert!(forme_result_bytes(ptr::null(), 0, &mut len).is_null());
            assert!(!forme_result_bytes(r, 0, &mut len).is_null());
            assert!(len > 0);
            forme_result_destroy(r);
        }
    }
    #[test]
    fn parallel() {
        let tasks: Vec<_> = (0..8)
            .map(|i| {
                std::thread::spawn(move || {
                    render(format!("<p>{i}</p>").as_bytes(), b"{}").unwrap().pdf
                })
            })
            .collect();
        let pdfs: Vec<_> = tasks.into_iter().map(|t| t.join().unwrap()).collect();
        assert_ne!(pdfs[0], pdfs[1]);
    }
}
