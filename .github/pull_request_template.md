<!-- Keep the sections; delete the guidance comments. -->

## Pack

<!-- Which file, its kind (lsp, dap, formatters, themes, agents), and whether
     this is a new pack or a change to one. -->

## Measured against

<!-- The exact output of the tool's version command on the machine you
     measured on, and the `verified_against` and `verified_on` values after
     this change. Measured means you ran the tool and saw it work; a value
     copied from its docs is not. Themes have neither field. -->

## How you measured it

<!-- What you ran and what you saw. For a language server or debugger: the
     launch args you started it with and what it answered to `initialize`
     (dev/handshake-probe.mjs in the tori repo does this). For an agent: the
     ACP handshake and one session (dev/acp-probe.mjs). For a formatter: a file
     before and after. For a theme: a screenshot. If a step could not be run,
     say which and why. -->

## Checks

- [ ] `tori validate-pack --assets --registry <your file>` passes
- [ ] The file name is the pack's `id`, and the id is new or this PR changes
      the pack that already has it
- [ ] `contributor` names you and `license` is the SPDX id of what you are
      contributing

## Notes

<!-- Anything you decided against, anything you could not verify. Saying
     "I could not test X" is more useful than leaving it implied. -->
