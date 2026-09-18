# Reviewing Native Dependency Advisories

After reading this guide, you will understand the current audit exceptions and
when they must be reconsidered. Review date: 2026-09-18.

## Scope

These exceptions acknowledge vulnerable dependencies; they do not patch them.
They apply only to Forme revision `f408920e632c59da0651b5b6d32f8c1397477673`,
the locked dependency graph and the HTML-only Ruby API. Rendering is not a
sandbox for arbitrary HTML. See [SECURITY](../SECURITY.md).

| Advisory | Locked package | Why the affected path is inaccessible |
| --- | --- | --- |
| [RUSTSEC-2026-0195](https://rustsec.org/advisories/RUSTSEC-2026-0195.html) | quick-xml 0.37.5 | The engine uses plain `Reader`, never `NsReader` or its namespace resolver. |
| [RUSTSEC-2026-0194](https://rustsec.org/advisories/RUSTSEC-2026-0194.html) | quick-xml 0.37.5 | Duplicate-attribute handling is vulnerable in upstream SVG parsing, but the HTML mapper never constructs SVG nodes. |
| [RUSTSEC-2023-0071](https://rustsec.org/advisories/RUSTSEC-2023-0071.html) | rsa 0.9.10 | Private-key operations occur only in certification, which HTML conversion leaves disabled. |

## Verify the boundaries

`ext/forme_pdf/src/lib.rs` accepts only CSS and fonts, rejects unknown options,
and calls `forme_pdf_html::render_html` with default HTML options. In the pinned
upstream tree, `html/src/dom.rs` parses with html5ever. `html/src/map.rs` has no
`NodeKind::Svg` construction and initializes `certification: None`.
`engine/src/image_loader.rs` accepts JPEG, PNG and WebP, so an SVG image cannot
enter the XML parser through an image URL. Font registration does not parse XML.
Only `forme-pdf` consumes quick-xml and rsa in the locked dependency graph.

The exceptions are configured in `.cargo/audit.toml`. Scheduled CI continues to
report other advisories, including unmaintained dependency warnings. Re-review
all exceptions when the engine pin, options schema, Cargo features or exports
change, especially SVG, raw document/JSON, imports or signing. Check the exact
new call paths; do not carry exceptions forward automatically.

## Remove exceptions when possible

Prefer an upstream update to quick-xml 0.41+ or feature-gating unused SVG and
certification dependencies. The current upstream 0.37 constraint prevents a
lockfile-only upgrade. RustSec lists no patched RSA version at review time;
a version bump alone is not remediation. Track upstream fixes during the weekly
dependency review and remove an exception once the dependency is fixed or removed.
