# kora_pawnshop agent guide

`kora_pawnshop` is a Kora pawn shop resource: players sell configured valuables and melt jewellery into materials through a `kora_lib` NUI app opened via `kora_target`. Layout: `fxmanifest.lua`, `shared/config.lua` (config and lookup helpers), `client/client.lua` (app, blip, target zone, melt timer), `server/server.lua` (sell/melt/pickup authority and exploit bans), `locales/en.json`, `test/smoke/` (offline Lua regression) and `tests/` (kora_qa feature files).

## Documentation

User-facing documentation lives in `docs/` (Markdown, published via the Kora Docusaurus site, kora_docs_next). Read `docs/index.md` first (hub and documentation map). Layout: `installation.md` (install, manifest, dependencies, testing), `how-to-use.md` (sell/melt/pickup flows, validation, anti-exploit), and topic pages `configuration.md`, `items.md`, `events.md`, `database.md`, `troubleshooting.md`. The resource has no commands or exports, so there is no `commands.md` or `api/`.

When you add, change, or remove a feature, config option, command, export, event, item, permission, or database table/column, update the matching page in `docs/` in the same change (feature and behaviour changes must update the matching docs in the same change). Keep docs accurate to the code; do not document behaviour that does not exist.

Docs rules: plain Markdown with `title`/`sidebar_position` front matter (no `id`/`slug`), relative links only between docs pages, assets inside `docs/`, fenced code blocks with a language, and no raw `<`, `>`, `{`, `}` outside code (pages are parsed as MDX). The release version comes from `fxmanifest.lua`'s `version` field.
