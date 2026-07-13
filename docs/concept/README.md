# Product Concept Discovery

This directory records product decisions that are not yet implementation
commitments. It supports RPG To-Do's shift from a gamified task list toward a
calm tool for crossing the gap between intention and real-world action.

## Reading guide

- **Repository fact**: verified in the current code or project documents.
- **Product principle**: an agreed design value from the discovery brief.
- **Inference**: a reasoned interpretation of facts; validate it with users.
- **Product hypothesis**: a proposed behavior worth testing before scaling.
- **Speculative experiment**: an optional idea, not a roadmap commitment.

The documents do not diagnose or treat ADHD, Autism, depression, anxiety, or
any other condition. They describe broadly useful executive-function
accommodations: clearer instructions, lower transition cost, visible context,
and non-punitive return.

## Documents

1. [Current product model](CURRENT_PRODUCT_MODEL.md) - factual current loop,
   data flow, and friction map.
2. [Product doctrine](PRODUCT_DOCTRINE.md) - purpose, principles, and feature
   decision test.
3. [Execution intervention map](EXECUTION_INTERVENTION_MAP.md) - START,
   CONTINUE, FINISH, and RETURN interventions.
4. [Future domain model](FUTURE_DOMAIN_MODEL.md) - conceptual roles and safe
   alternatives before any schema decision.
5. [Core product loop](CORE_PRODUCT_LOOP.md) - loop options and recommendation.
6. [Innovation backlog](PRODUCT_INNOVATION_BACKLOG.md) - ranked ideas and
   evidence labels.
7. [RPG mechanics reassessment](RPG_MECHANICS_REASSESSMENT.md) - feedback in
   service of real work.
8. [Future user journeys](FUTURE_USER_JOURNEYS.md) - low-decision flows for
   common execution failures.
9. [Concept transition roadmap](CONCEPT_TRANSITION_ROADMAP.md) - reversible,
   architecture-safe implementation sequence.
10. [Product validation plan](PRODUCT_VALIDATION_PLAN.md) - how to test value
    without vanity metrics or analytics work.
11. [Next Action + Boot Entry implementation](NEXT_ACTION_BOOT_ENTRY_IMPLEMENTATION.md)
    - current MVP decision, domain boundary, persistence policy, and rollback.

## Current implementation status

The first conceptual slice, Next Action Lens + Boot Entry, is implemented as a
mobile presentation experiment. It uses a pure resolver and session-only plan;
it does not change Task storage, XP, Goal, RoadMap, or reward behavior. Return
Context remains the next concept candidate and requires separate validation.

## Non-negotiable boundary

These documents do not authorize production changes. A future implementation
task must pass the [Product Doctrine decision test](PRODUCT_DOCTRINE.md#decision-test),
follow [AGENTS.md](../../AGENTS.md), and name any model, storage, AppState, XP,
RoadMap, or recurring-rule impact explicitly.
