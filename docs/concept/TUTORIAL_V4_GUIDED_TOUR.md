# Tutorial v4: Cohesive Guided Product Tour

Status: implemented presentation architecture, native cross-platform QA pending

## Decision

Tutorial v4 is one optional guided journey through the real product. It is not
a sequence of independent tips and not a data-reset mode.

The first-run Core and Full Product Tour serve different jobs:

- Core is a short interactive start: Skill, Quest, next useful action. Real
  data changes only when the user saves the normal forms.
- Full Product Tour is read-only for domain data. It may navigate and focus
  presentation state, but cannot create, complete, award, or reconfigure.
- Topic replay is an isolated session for one chapter and remains available
  after historical completion.

## Runtime Model

Persisted `TutorialProgress` records history and first-run compatibility.
`GuidedTourPlan` defines the ordered session independently of that history.
`GuidedTourSession` owns only current index and presentation phase. The app
bridge receives scalar history inputs and explicit Core callbacks, so Flutter
presentation objects never enter AppState or storage.

The transition lifecycle is:

```text
presenting -> leaving -> navigating -> waitingForAnchor
  -> entering -> presenting
```

Only one `GuidedTourHost` can render a card. Route and anchor waits are bounded
and cancellation-safe.

## Teaching The Real Product

The full plan traverses Act, RoadMap, Statistics, Trophies, and Profile.
Desktop uses persistent Statistics/Trophies workspaces; mobile uses ordinary
secondary pages. Profile guidance ends beside the real Training Center. No
tutorial-specific replica of a product page is allowed.

Semantic anchors name product intent rather than widget structure. Desktop
cards try right/left/bottom/top and avoid the target and reserved rails; mobile
uses a stable bottom coach card. A missing optional target is skipped, resolved
to a declared parent, explained conceptually, or ends the chapter safely.

## Safety Contract

Full replay must leave these unchanged: Skills, Tasks, XP, History, rewards,
RoadMap topology, Goal progress, Welcome, and persisted tutorial completion.
It must not call first-incomplete history logic because replay order belongs to
the current session plan.

## Accessibility Contract

One card announces one title and overall step progress. Controls remain
reachable at `200%` text. Escape and mobile Back pause safely. Reduced motion
keeps the same state order without translation. A restrained outline identifies
the real target without making it look like a changed app state.

## Why v3 Was Replaced

V3 had several visual owners: a root overlay, special dialog flags, and inline
hints. It used generic fallbacks, tutorial-only desktop Statistics/Trophies
routes, weak chapter continuity, and navigation timing that could reveal the
next lesson before the new surface settled. The machinery was individually
robust, but the product experience felt like unrelated popups.

## Intentionally Rejected

- Fake tutorial Skills, Tasks, XP, rewards, or chests.
- Welcome or history reset as replay implementation.
- One mandatory tour after the short Core.
- Tutorial-only Statistics or Trophies pages.
- Fixed delays or frame-count readiness.
- Y-midpoint-only placement or universal centered fallbacks.
- Root and nested tutorial overlays at the same time.

## Remaining Evidence

Widget and pure-Dart tests cover sequencing, geometry, Back/Escape, large text,
session isolation, and read-only replay. Release sign-off still needs a native
desktop walkthrough in both themes with resizing and a physical Android
TalkBack/large-text pass. These are evidence gates, not missing architecture.
