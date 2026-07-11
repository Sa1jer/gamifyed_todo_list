## Widget rules

Read the root [AGENTS.md](../../AGENTS.md),
[docs/MOBILE_UX_UI_AUDIT.md](../../docs/MOBILE_UX_UI_AUDIT.md), and
[docs/DESKTOP_VISUAL_SYSTEM.md](../../docs/DESKTOP_VISUAL_SYSTEM.md) first.

- Treat presentation changes as presentation changes: do not move domain rules
  into widgets or turn a visual request into a persistence change.
- Preserve action-first mobile UX and verify both narrow/mobile and desktop
  compositions when shared UI changes.
- Keep advanced settings out of the primary flow unless the task calls for
  them. Respect reduced motion, semantics, keyboard navigation, and safe
  dialog/bottom-sheet context capture.
- Avoid broad AppState dependencies when a widget needs one derived value; do
  not call global mutation methods from hover or transient animation state.
