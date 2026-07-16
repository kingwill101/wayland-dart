# Phase 03: Protocol Generator Modernization

This phase hardens the code generator so it stays aligned with upstream Wayland protocol updates. It adds automation around fetching XMLs, validates schema changes, and makes regeneration a predictable, repeatable process for the monorepo.

## Tasks

- [ ] Add a generator CLI flag to `packages/client/bin/scanner.dart` to refresh protocol XMLs before codegen (with a cache directory and checksum tracking)
- [ ] Implement XML schema validation for fetched protocol files and fail fast on malformed inputs
- [ ] Ensure generated Dart files include the source XML URL and protocol version in headers for traceability
- [ ] Add a `justfile` or `melos` task at the repo root to run the full protocol refresh + codegen pipeline in one command
- [ ] Update `packages/client/README.md` with the new regeneration workflow and expected outputs
