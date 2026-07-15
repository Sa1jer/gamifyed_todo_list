# Refactor Documentation

The living architecture sources are:

- [Architecture inventory](ARCHITECTURE_INVENTORY.md)
- [Target architecture](TARGET_ARCHITECTURE.md)
- [Logic and readability audit](LOGIC_AND_READABILITY_AUDIT.md)
- [Memory and allocation audit](MEMORY_AUDIT.md)
- [Current batch result](REFACTOR_RESULT.md)
- [AppState map](../APPSTATE_MAP.md)

The July 2026 acceptance snapshot is kept separately so later work does not
silently rewrite the evidence for this batch:

- [Final inventory](FINAL_ARCHITECTURE_INVENTORY.md)
- [Final architecture](FINAL_ARCHITECTURE.md)
- [Final logic audit](FINAL_LOGIC_AUDIT.md)
- [Final memory audit](FINAL_MEMORY_AUDIT.md)
- [Final result](FINAL_REFACTOR_RESULT.md)
- [Completion matrix](COMPLETION_MATRIX.md)

Run `dart run tool/architecture_audit.dart` to print the current largest Dart
files and enforce the dependency boundaries introduced by this program. These
documents do not authorize a state-management migration, storage/schema
rewrite, or product redesign.
