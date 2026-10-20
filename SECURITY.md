# Security

Render trusted HTML and caller-selected assets only. Local image files are read
only inside a caller-supplied `image_root:`, at most 64 MiB each. Rendering
consumes CPU/memory in the host process, and some layouts, such as deeply nested
tables, can take far longer than their size suggests. It is not an HTML sandbox;
thread cancellation is not a reliable rendering timeout.

Keep confidential documents out of logs and public issue attachments. Use a
minimal synthetic reproduction when reporting a problem. Send potential
security vulnerabilities privately to ajaya@clearstack.io rather than posting
sensitive details publicly. No response-time guarantee is offered.

Dependency audit exceptions and their call-path evidence are recorded in
[the security review](docs/security-exceptions.md). They must be re-reviewed
when the pinned engine or public native interface changes.
