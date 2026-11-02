# AppleSuite build

Public build scripts for a private iOS source repository.

Only repository maintainers can manually dispatch this workflow. Enter the full
40-character source commit SHA. The source is fetched with a dedicated read-only
deploy key stored in the `SOURCE_DEPLOY_KEY` Actions secret. No personal access
token is stored here. Pull requests and pushes do not trigger builds.
GitHub SSH host keys are pinned in `github-known-hosts`, verified through the
authenticated GitHub `/meta` API on November 2, 2026. If GitHub rotates its host
keys, verify the replacement through GitHub and update this file; never disable
strict host-key verification.

Raw compiler output and test diagnostics stay in the temporary runner workspace.
The IPA and diagnostics are encrypted together using OpenSSL CMS
AuthEnvelopedData (AES-256-GCM, RSA-OAEP-SHA256). Only the recipient certificate is
public. The decryption private key stays with the owner. Artifacts expire after
7 days. No source or build caches are uploaded.

The Actions page exposes workflow code, step status, timing and the requested
source commit SHA. GitHub's hosted runner processes the private source. Anyone
with write access to this build repository can change workflows that use its
secret, so grant write access only to trusted maintainers.

Download `encrypted-ios-build`, check its SHA-256, then decrypt locally:

```sh
openssl cms -decrypt -binary -inform DER -in build.cms \
  -recip recipient.pem -inkey /private/path/recipient.key \
  -out build.tar.gz
tar -xzf build.tar.gz
```

Use OpenSSL 3. The extracted IPA is unsigned and needs Apple signing before
installation on an iPhone. Keep a secure backup of the recipient private key;
losing it makes encrypted artifacts unrecoverable.

Commits use `GhostLee <8407671+GhostLee@users.noreply.github.com>`.
