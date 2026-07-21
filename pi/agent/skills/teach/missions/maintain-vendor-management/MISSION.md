# Mission: Master the log-vendor-management codebase (to maintain it)

## Why
Zachary is taking over maintenance of `log-vendor-management` — the source-of-truth vendor service for DH Logistics. He needs to confidently diagnose incidents, review PRs, and ship changes to a publicly-exposed, security-sensitive service without introducing the silent bugs the codebase is prone to (bypassing the outbox, blocking the reactor, breaking GEID scoping, corrupting JSONB configs).

## Success looks like
- Can trace any request or event end-to-end through the layers (controller/listener → service → R2DBC repo → outbox) and name the file at each hop.
- Reads Kotlin idioms fluently in THIS codebase — `data class`, nullability, `.copy()`, extension functions, `suspend`/coroutines, `Flow`/`Mono` — enough to review and edit safely (not to become a Kotlin language expert).
- Can predict the blast radius of a change: which of the 3 services (VMS/VMMP/VMCS) and which of the 19 stamps it touches.
- Internalizes the 5 critical risks (outbox-only publishing, no blocking in reactive chains, GEID scoping as a security boundary, replication-slot care, nullable-only JSONB evolution) as reflexes during code review.
- Can safely run/reason about the operational replay & import scripts.

## Constraints
- Learner has ~2 years Java experience; comfortable with Spring MVC / JDBC mental models. New to Kotlin — explain Kotlin idioms as they appear, but the GOAL is codebase mastery, not language mastery.
- Learning style: read a beautiful HTML lesson, then answer scenario quiz questions from the agent in chat (tight feedback loop).
- Time-boxed lessons: each teaches ONE thing and is completable quickly.

## Out of scope (for now)
- Becoming a general Kotlin language expert (coroutines theory, DSL authoring) beyond what this codebase uses.
- The TypeScript/Node e2e harness and Drone/Jsonnet CI internals — until the core service model is solid.
- Front-end / VBO UI (separate repo).
