# published

Written by `.github/workflows/publish.yml` on `main`. Do not edit by hand.

`index.json` is the packs index, and `index.json.sig` is its Ed25519
signature (`{ key_id, signature }` over the exact bytes of `index.json`).
The rows name the `main` commit they were built from as `packs_commit`.
