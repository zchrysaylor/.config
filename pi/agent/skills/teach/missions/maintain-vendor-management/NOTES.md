# Working Notes

## Learner profile
- ~2 years Java. Fluent in Spring MVC / JDBC blocking model. **New to Kotlin** — annotate Kotlin idioms inline the first few times they appear; taper off as they stick.
- Goal is CODEBASE mastery, not Kotlin-language mastery. Every Kotlin explanation must earn its place by unlocking codebase understanding.

## Teaching preferences
- Format: beautiful, print-friendly, self-contained HTML lesson → then in-agent scenario quiz with immediate feedback.
- Each lesson = ONE thing, quick to complete, tangible win.
- Cite real file paths in every lesson (increases trust + gives a path to go deeper).
- Lean on Java→Kotlin analogies (e.g. "data class ≈ record + Lombok @With", "companion object ≈ static").

## Curriculum spine (rough — adjust to ZPD)
1. ✅ Config domain model & hierarchy (L0001) — data classes, nullability, .copy(), sources.
2. Reactive model: suspend / coroutines / no-blocking (the #1 Java→Kotlin leap + critical risk).
3. Request trace end-to-end: ConfigController.save → service → R2DBC → outbox.
4. Event ingestion: SQS → ReactiveSqsConsumer → listeners.
5. The transactional outbox + VMMP (WAL/LSN).
6. Security: JWT multi-issuer, GEID scoping as security boundary, reactive authz.
7. Blast radius: 3 services × 19 stamps, Flyway migrations, deploy triggers.

## Observations / callouts to reuse
- `Configuration.kt:116` has a stray `println("keysToFilter:: ...")` in `filterAndMerge` — real production debug leftover. Excellent live example of "what to catch in code review" + logging-hygiene security rule. (Do NOT let learner assume println is an accepted pattern.)
- Extension functions on nullable receivers (`Map<K,V>?.filterAndMerge`) are everywhere — worth its own mini-explanation.
