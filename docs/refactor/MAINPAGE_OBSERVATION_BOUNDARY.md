# MainPage Observation Boundary

Last updated: 2026-07-18

`RPGApp` owns the live `AppState` instance and passes it explicitly to
`MainPage`. The shell no longer subscribes to the whole `InheritedNotifier`.
Instead, each shell concern observes the smallest immutable projection that can
change its composition.

## Boundaries

| Boundary | Observed inputs | Intentionally ignored |
|---|---|---|
| Workspace | core workspace revision, selected Skill ID, theme and reduced-motion preference | profile edits, tutorial steps, analytics identity, persistence progress |
| Profile | scalar profile fields, avatar byte identity and unopened reward count | task, RoadMap and persistence-only changes |
| Tutorial | visible module and step | all unrelated domain and preference changes |
| Analytics dialogs | analytics snapshot identity and weekly-goal summary | persistence progress and profile-only changes |
| Settings | theme, sound, tooltip, reduced-motion and persistence status | task and RoadMap mutations |

The event listener is non-rendering state. `MainPage` attaches it directly to
the supplied `AppState`, rebinds when that instance changes, and detaches it on
dispose. Mutation callbacks use that explicit state rather than creating an
inherited dependency.

## Persistence Notifications

A domain mutation may still publish separate `dirty`, `saving`, and `saved`
persistence states. Those states belong to the settings/recovery projection and
must not rebuild the workspace. This preserves observable persistence feedback
without coupling save scheduling to expensive screen composition.

## Change Rule

Add a field to `MainPageWorkspaceProjection` only when it changes shell or
workspace composition. Data needed by one feature remains in that feature's
selector. Do not restore `AppStateProvider.of(context)` in `MainPage`, profile
shell helpers, or desktop sidebar profile composition.

## Regression Guards

- `test/main_page_observation_test.dart` characterizes unrelated persistence,
  profile, tutorial, domain, selection, theme and state-replacement behavior.
- `tool/architecture_audit.dart` rejects a broad provider subscription in the
  MainPage shell and requires the explicit root state handoff and workspace
  boundary.

## Version And Native Image Policy

`pubspec.yaml` is authoritative for the application version. The visible
`kAppVersionLabel` must equal `v${pubspecVersion}`; the architecture audit and
`test/version_sync_test.dart` reject drift.

Theme capture starts with local `ui.Image` ownership. Ownership transfers to
the overlay only after a mounted check. A local frame is disposed on capture
completion after unmount or on error; the overlay disposes replaced images and
the root disposes its current image on unmount. No async path calls `setState`
after unmount.
