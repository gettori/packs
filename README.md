# Tori packs

Every language server, linter, debugger, formatter, theme and agent that
[Tori](https://github.com/gettori/tori) knows about is a pack: one file in this
repo.

Tori ships a pinned snapshot of this repo inside the app. An upcoming Tori
release adds a signed catalog, so anything merged here after that snapshot
reaches Tori without a new release: each pane in Settings gets an "Add a ..."
button that lists it, and [gettori.app/packs](https://gettori.app/packs)
lists every pack. Until then, a
pack reaches Tori through its next snapshot, or through the folder below.

## The folders

| Folder | Kind | File |
| --- | --- | --- |
| `lsp/` | Language servers and linters | `<id>.toml` |
| `dap/` | Debuggers | `<id>.toml` |
| `formatters/` | Formatters | `<id>.toml` |
| `themes/` | Themes | `<id>.json` |
| `agents/` | Agents | `<id>.toml` |
| `icons/` | An agent's logo, optional | `<id>.svg` |

A file's name is its `id`. Ids match `^[a-z0-9][a-z0-9._-]*$`.

An icon belongs to the agent with the same id, so `icons/<id>.svg` needs an
`agents/<id>.toml`. Tori draws only its shape, in the theme's text colour, so
draw it in one colour on a transparent background. The validator wants it
under 32 KB, with an `<svg>` root that has a `viewBox`, and with no
`<script>`, no `<foreignObject>` and no `on*` attribute.

The schema for each kind is documented in the Tori repo:
[LSP-SERVERS.md](https://github.com/gettori/tori/blob/main/docs/LSP-SERVERS.md),
[DEBUGGERS.md](https://github.com/gettori/tori/blob/main/docs/DEBUGGERS.md),
[FORMATTERS.md](https://github.com/gettori/tori/blob/main/docs/FORMATTERS.md),
[THEMES.md](https://github.com/gettori/tori/blob/main/docs/THEMES.md) and
[ADAPTERS.md](https://github.com/gettori/tori/blob/main/docs/ADAPTERS.md).

## Contributing a pack

1. Write the file under its kind's folder. Start from a pack of the same kind
   that already works the way yours should.
2. Fill `description`, `contributor = { name = "...", github = "..." }` and
   `license` (an SPDX id). Every kind except themes also needs
   `verified_against`, the exact version you ran, and `verified_on`, the date
   you ran it, as `YYYY-MM-DD`.
3. Try it in Tori before opening a pull request: copy the file into
   `~/.config/tori/packs/<kind>/` and restart Tori (themes load without a
   restart). If it does not load, the kind's Settings pane lists it under
   "Needs fixing" with the reason.
4. Run the validator, which is the same check CI runs:

   ```sh
   tori validate-pack --assets --registry <kind>/<id>.toml
   ```

   `tori` is the app's own binary. Each Tori release also publishes it on its
   own as `tori-cli-<version>-macos-universal.tar.gz`. `--assets` downloads
   every release asset the pack names and checks its sha256, and
   `--registry` checks that every pinned package exists.
5. Open a pull request. The template asks how you measured it.

A new agent that speaks ACP, or a language server, debugger or formatter that
Tori already knows how to drive, needs only its pack. An agent that needs a new
transcript parser is a change to Tori first: open an issue there.

## Using a pack without the catalog

Any file in `~/.config/tori/packs/<kind>/` loads at start, whether or not it is
in this repo. It cannot reuse the id of a pack Tori ships. To change a bundled
pack, copy it under a new id and switch the bundled one off on its card in
Settings. Themes have no switch: pick yours in Appearance.

## What a pack may run

Tori runs what a pack tells it to, so the validator limits what that can be.

- An agent's `[install]` program is one of `npm`, `pnpm`, `bun`, `pip`,
  `pipx`, `uv`, `brew`, `cargo`, `go` or `gem`. No argument may contain `-c`,
  `|`, `;`, `&&` or a backtick.
- An agent's `[chat].program` is a runner, `npx`, `bunx` or `uvx`, and its
  arguments pin `package@version`.
- npm and pip installs pin an exact version. Release assets carry a sha256.
- A hint's `update` and `uninstall` scripts may use the shell, but not `curl`,
  `wget`, `sudo`, `eval`, `sh -c` or `bash -c`, and they may not pipe into a
  shell. Tori shows the script and asks before it runs one.

A reviewer still reads every file.

## Maintaining

How the index is signed and published, and what to do when a credential
leaks: [MAINTAINING.md](MAINTAINING.md).

## License

Apache-2.0. See [LICENSE](LICENSE). Each pack's own `license` field covers
what that pack describes.

The files in `icons/` are the logos of the products they name and belong to
their owners; the license above does not cover them. They are here to tell
one agent from another, not to claim any endorsement. The bundled ones come
from [Simple Icons](https://simpleicons.org) (CC0), except Codex's, which
comes from [lobe-icons](https://github.com/lobehub/lobe-icons) (MIT).
