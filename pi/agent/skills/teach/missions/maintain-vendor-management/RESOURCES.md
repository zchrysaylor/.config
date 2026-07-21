# log-vendor-management Mastery — Resources

## Knowledge (in-repo — highest trust, this is the source of truth)

- [`AGENTS.md`](../../../../../Code/IdeaProjects/deliveryhero/log-vendor-management/AGENTS.md)
  The canonical map: domain glossary, module deep-dive, security model, config reference, critical risks. Use for: orientation on anything before touching code.
- `docs/architecture.md`, `docs/security.md`, `docs/conventions.md`, `docs/glossary.md`
  Long-form architecture, auth, dev conventions, terminology. Use for: deeper dives per topic.
- `docs/order-processing-configs.md`, `docs/vms-message-publishing.md`, `docs/link_and_unlink.md`
  Feature-specific runbooks. Use for: the specific flow named.
- Key code anchors (read the real thing, not the summary):
  - `vendor-management-service/.../db/model/PlatformVendorConfig.kt` — the config aggregate
  - `vendor-management-service/.../db/model/Configuration.kt` — the persisted row + merge logic
  - `vendor-management-service/.../service/PlatformVendorConfigService.kt` — hierarchy resolution
  - `vendor-management-service/.../messaging/listener/ReactiveSqsConsumer.kt` — the coroutine SQS engine
  - `vendor-management-service/.../api/ConfigController.kt` — the most-maintained REST entrypoint

## Knowledge (external — Kotlin/Spring idioms, use sparingly & only to ground a claim)

- [Kotlin docs: Null safety](https://kotlinlang.org/docs/null-safety.html) — for `?`, `?.`, `?:`, `!!`.
- [Kotlin docs: Data classes](https://kotlinlang.org/docs/data-classes.html) — for `data class` + `.copy()`.
- [Kotlin docs: Extension functions](https://kotlinlang.org/docs/extensions.html) — the codebase leans heavily on these.
- [Kotlin docs: Coroutines & suspend](https://kotlinlang.org/docs/coroutines-overview.html) — for `suspend`, `launch`, `Channel`.
- [Spring WebFlux reference](https://docs.spring.io/spring-framework/reference/web/webflux.html) — reactive controllers, `Mono`/`Flux`.
- [Project Reactor reference](https://projectreactor.io/docs/core/release/reference/) — `Mono`/`Flux` operators.

## Wisdom (Communities)
- _To be filled in._ Ask Zachary which internal channel/team owns this service (likely a DH Logistics Slack channel + the VMS on-call rotation) — that's the real-world "community" for incident wisdom and PR review culture.

## Gaps
- No external community identified yet. Internal team channel + code-review norms are the highest-value "wisdom" source; capture them once known.
