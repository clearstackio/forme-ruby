# Setting Up the GitHub Repository

After reading this guide, you will know what is checked in and which GitHub and
RubyGems settings a maintainer must enable. These instructions prepare
`clearstackio/forme-ruby`; they do not authorize pushing or publishing.

## Repository files

The repository includes an MIT license, contributor and security guides, issue
forms, a pull-request template, CODEOWNERS, Dependabot, CodeQL, dependency review,
and build/release workflows. Actions are pinned to full commit SHAs; Dependabot
proposes updates. CI runs on pull requests, main pushes and a weekly schedule.
PR jobs do not receive publishing credentials. Checkout does not persist tokens.

## Configure GitHub after an authorized push

1. Set the description to “Native HTML and print CSS to PDF for Ruby and Rails,
   powered by Forme.” Use topics `ruby`, `rails`, `pdf`, `rust`, `html-to-pdf`.
2. Enable Issues and private vulnerability reporting. Enable the dependency
   graph, Dependabot alerts, secret scanning and push protection where available.
   CodeQL is provided as an advanced workflow for Ruby, Rust and GitHub Actions; do not also enable
   CodeQL default setup.
3. After the first successful run, protect `main` with a ruleset requiring pull
   requests, one approving review, resolved conversations, current branches and
   the `CI required`, CodeQL matrix and dependency-review checks. Select the
   actual check names from GitHub. Block deletion and force pushes. Require code
   owner review for changes; add another trusted maintainer so the sole owner's
   pull requests can be reviewed. Do not silently bypass review to unblock them.
4. Allow only reviewed Actions, keep the default workflow token read-only, and
   disable Actions creating or approving pull requests. Keep fork approval on.
5. Create environment `rubygems`, restrict deployment to `main`, and configure a
   trusted maintainer as required reviewer with self-review prevented. Confirm
   an eligible second reviewer exists before enabling this requirement.
6. Configure RubyGems trusted publishing exactly as [releasing](releasing.md)
   specifies. Do not store a long-lived publishing key in repository secrets.

The existing remote has older history. The prepared local root commit replaces
that history only after explicit authorization and consumer coordination. Enable
force-push protection after that authorized initial transition. A backup local
branch preserves the prior history. Never force-push just to make CI pass.

## Release evidence

`CI required` fails if any Ruby test, package build, distribution installation or
audit fails or is skipped. Linux packages are built against glibc 2.28 and checked
for newer symbol requirements. Compatibility jobs install the same artifact,
not a newly rebuilt library. Rolling Arch is deliberately retested weekly.

The manual release workflow accepts only a successful CI run from this repository,
for the exact main commit. It validates package names, versions, platforms and
license files before trusted publication, and records an attestation for the
promotion workflow. Keep the successful CI URL with release notes. GitHub
settings, hosted matrix success and RubyGems setup must be confirmed separately;
local tests do not establish any of them.

See GitHub's [secure Actions guidance](https://docs.github.com/en/actions/reference/security/secure-use)
and RubyGems' [trusted publishing guide](https://guides.rubygems.org/trusted-publishing/).

Rust scanning uses CodeQL’s supported `none` build mode with the pinned Rust
toolchain; see [GitHub’s Rust scanning requirements](https://docs.github.com/en/code-security/reference/code-scanning/codeql/build-options-for-compiled-languages#building-rust).
