# Maintaining gettori/packs

How the index gets signed and served, what is protected and why, and what to
do when a credential leaks. Contributors want README.md instead.

## How a pack reaches Tori

1. A pull request to `main` runs `validate.yml`. It downloads the tori CLI
   from the GitHub releases named in `tori-support.json`. The newest release
   checks every pack offline and builds the index, then downloads and hashes
   the changed packs' release assets and looks up their pinned packages. The
   oldest release loads only the packs whose `min_tori` is that release.
2. A merge to `main` runs `publish.yml`. It builds the index with the newest
   CLI, signs it with key `k1`, commits `index.json` and `index.json.sig` to
   the `published` branch, and POSTs the site's deploy hook.
3. The site (gettori/docsweb, a Cloudflare Worker) rebuilds. Once it serves
   packs, it reads the index from `published` and serves it with every pack
   file at the commit the index names.
4. From the Tori release that ships the catalog, Tori fetches the index from
   gettori.app, checks the signature against the public keys compiled into it
   (`TRUSTED_KEYS` in tori's `src-tauri/src/packs/catalog.rs`), and checks
   every downloaded file against its row's sha256.

Publish also runs every Monday and can be started by hand
(`gh workflow run publish.yml --repo gettori/packs`). The index expires 30
days after it is signed. Tori still uses an expired index but marks it stale,
so the weekly run is what keeps it fresh in a quiet month.

## tori-support.json

Maps each kind's `schema_version` to the first Tori release that loads it:
`{ "<kind>": { "<schema_version>": "<release>" } }`. Each row's `min_tori`
comes from here, and a pack whose kind and version have no entry fails both
workflows.

A schema bump goes in this order: tori PR, tori release, then a PR here that
adds the mapping. The release has to exist first, because the workflows
download its CLI.

## Branches and protection

`main` requires a pull request. Required approvals are 0, because a sole
maintainer cannot approve their own PR; raise it once there is a second
maintainer. Force pushes and deletion are off. Admins can bypass.

`published` holds only the signed index and a README. Nobody edits it by
hand. Force pushes and deletion are off, enforced for admins too, so its
history is a record of every index that was ever live. It does not require a
PR, so the workflow can push to it.

Why the index is not on `main`: the workflow's `GITHUB_TOKEN` cannot bypass
the PR rule. A ruleset bypass for the GitHub Actions app is refused by the
API ("must be part of the ruleset source or owner organization"). A write
deploy key would need deploy keys enabled for the whole org. Tori trusts the
signature, not the branch, so a separate branch costs nothing. A bad push to
`published` makes Tori refuse the index and keep its cached one. If the index
ever has to live on `main`, use an org-owned GitHub App as the bypass, not a
deploy key.

## Secrets

Both live in the `publish` environment, which only `main` may deploy to, so a
workflow edited on another branch cannot read them. There are no repo-level
secrets.

- `PACKS_SIGNING_KEY`: the Ed25519 private key `k1`, PKCS#8 PEM.
- `SITE_DEPLOY_HOOK`: the Cloudflare deploy hook URL for docsweb's `main`.
  The URL is the credential: whoever has it can start builds.

`validate.yml` gets no secrets and a read-only token, since it runs on
contributors' files.

## When something leaks

### The deploy hook

1. Cloudflare dashboard, Workers & Pages, `docsweb`, Settings, Builds, Deploy
   Hooks: create a new hook on `main`, then delete the old one.
2. `gh secret set SITE_DEPLOY_HOOK --repo gettori/packs --env publish`, and
   paste the new URL at the prompt.
3. `gh workflow run publish.yml --repo gettori/packs`, and check that a build
   starts.

The worst a leaked hook does is start builds, and Cloudflare rate limits
those.

### The signing key

This one is expensive, because the trusted keys are compiled into Tori. A
leaked key can sign any index, and every Tori that trusts it accepts that
index until it updates.

1. Make `k2` with Homebrew's OpenSSL (macOS's own cannot make Ed25519 keys):

   ```sh
   O=$(brew --prefix openssl@3)/bin/openssl
   $O genpkey -algorithm ed25519 -out packs-k2.pem
   $O pkey -in packs-k2.pem -pubout -outform DER | tail -c 32 | xxd -i -c 18
   ```

   The last line prints the 32 public key bytes in the form `catalog.rs` uses.
2. In tori, add `("k2", [...])` to `TRUSTED_KEYS`. After a leak, remove `k1`
   in the same change. For a planned rotation, keep `k1` for now.
3. Release Tori.
4. `gh secret set PACKS_SIGNING_KEY --repo gettori/packs --env publish <
   packs-k2.pem`, change `--key-id k1` to `--key-id k2` in `publish.yml` by
   PR, and let it publish.
5. For a planned rotation, remove `k1` from tori in a later release, once
   most users have the one that added `k2`.
6. Back up `packs-k2.pem` the same way as `k1`, then delete any loose copies.

### A maintainer's GitHub account

Remove their access, then rotate both secrets as above: someone with admin
rights could have read them through a workflow they started on `main`.

## Checking a published index by hand

```sh
O=$(brew --prefix openssl@3)/bin/openssl
curl -fsSLO https://raw.githubusercontent.com/gettori/packs/published/index.json
curl -fsSLO https://raw.githubusercontent.com/gettori/packs/published/index.json.sig
# k1's public key, the same 32 bytes as TRUSTED_KEYS in catalog.rs
printf '302a300506032b6570032100%s' 7eb352af976f9d75a48644153b0129120a981df88f47139f1f0aef8748b49fd5 \
  | xxd -r -p | $O pkey -pubin -inform DER -out k1.pub.pem
jq -r .signature index.json.sig | base64 -d > sig.bin
$O pkeyutl -verify -pubin -inkey k1.pub.pem -rawin -in index.json -sigfile sig.bin
```

`Signature Verified Successfully` means the index is what `k1` signed. Check
that its `packs_commit` is a commit on `main`, too.

## Known gaps

- Rollback on a fresh install. Every index ever signed stays valid. A Tori
  with a cache refuses an index older than the one it has, but a fresh install
  accepts any of them, even an expired one. So someone who can push to
  `published`, or serve the site, could bring back a pack that was later
  pulled. Tracked in gettori/tickets#71, to be settled before the catalog
  ships.
- `actions/checkout@v4` runs on Node 20, which GitHub has deprecated. Bump it
  here and in tori together.
