# Security

Render trusted HTML and caller-selected assets only. Forme can read local image
paths and consumes CPU/memory in the host process. It is not an HTML sandbox;
thread cancellation is not a reliable rendering timeout.

Keep confidential documents out of logs and public issue attachments. Use a
minimal synthetic reproduction when reporting a problem. Send potential
security vulnerabilities privately to ajaya@clearstack.io rather than posting
sensitive details publicly. No response-time guarantee is offered.

The initial 0.1.0 release is still in preparation. Before deployment, qualify the
exact package and pinned native dependencies on your application's target.

Dependency audit exceptions and their call-path evidence are recorded in
[the security review](docs/security-exceptions.md). They must be re-reviewed
when the pinned engine or public native interface changes.
