//! Native result ownership boundary. Each call owns an independent result.
use base64::{engine::general_purpose::STANDARD, Engine};
use forme_pdf_html::{render_html, FontSpec, HtmlOptions};
use serde::Deserialize;
use std::{
    panic::{catch_unwind, AssertUnwindSafe},
    ptr, slice,
};

#[derive(Default, Deserialize)]
#[serde(default, deny_unknown_fields)]
struct Options {
    css: Option<String>,
    fonts: Vec<Font>,
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
    let output = render_html(html, &opts).map_err(|e| e.to_string())?;
    let metadata = serde_json::to_vec(
        &serde_json::json!({"warnings": output.warnings, "passes": output.passes}),
    )
    .map_err(|e| e.to_string())?;
    Ok(RenderResult {
        status: 0,
        pdf: output.pdf,
        metadata,
        error: vec![],
    })
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
        render(h, o).unwrap_or_else(|e| RenderResult::error(1, e))
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
