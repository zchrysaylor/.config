# Vocabulary watchlists

These lists contain words that LLMs tend to use at a high frequency. They are editorial prompts, not a blacklist or an AI detector. Inspect density, repetition, context, and whether the word supplies information. Prefer deletion of empty claims over synonym substitution.

## General-purpose AI vocabulary

Inspect these words, especially in abstract praise and paragraph openings:

- additionally, align / alignment / align with, bolstered, compelling, crucial, deep dive, delve, diverse array, elevate, embark, emphasizing, enduring, enhance / enhancement, ever-evolving;
- facilitate, foster / fostering, garner, groundbreaking, game-changer, highlight, holistic, interplay, intricate / intricacies, key, landscape, leverage, meticulous / meticulously, multifaceted;
- navigate / navigation, nuanced / nuance, paradigm, pivotal, profound, realm, resonate, rich, robust / robustness, seamless / seamlessly, showcase, synergy / synergistic, tapestry, testament, transformative, underscore, unleash, valuable / valuable insights, vibrant, vital.

Inspect ordinary inflections too, judging each use in context. Literal landscapes, musical underscores, navigation controls, and accurate statistical uses of "robust" are not empty metaphors.

## Stock phrases and throat-clearing

- "moreover", "furthermore", "notably", "that said", "that being said", "at its core", "important to note", "it is important to note that";
- "key takeaway", "in today's fast-paced...", "stands as", "serves as", "let's unpack", "ultimately", "worth noting", "worth nothing";
- "in summary", "in conclusion", "overall", "it is crucial to remember", "it's worth naming", "to be clear".

Usually delete the introduction and begin with the point. Keep a transition that expresses a needed relationship. Distinguish "worth nothing" from "worth noting"; do not assume a literal valuation is a typo.

## Abstract and coding metaphors

Inspect these when they replace the actual component, operation, or consequence:

- substrate, wedge, vector, locus, vantage, nexus, primitive as a noun, harness as a metaphor, surface / API surface / surface area, bedrock, scaffolding as a metaphor, modality, paradigm;
- gold-plating, ratchet as a metaphor, evacuate for moving code, endgame, north star, flywheel, load-bearing, churn, seam;
- thin wrapper, single source of truth, sharp edge, footgun, plumbing, wiring, under the hood, happy path, blast radius, surgical / surgically, escape hatch.

Possible rewrites, only when they preserve the intended meaning:

- "substrate" becomes "base", storage, runtime, or the actual component name.
- "wedge in" becomes "add"; "vector" becomes "method" when it is not a mathematical vector, attack vector, or other precise term.
- "gold-plating" becomes "work beyond the requirements"; "evacuate" becomes "move out".
- "ratchet" becomes the actual mechanism or "a limit that only tightens"; "endgame" becomes "last phase".
- "blast radius" becomes a description of the affected services or users.
- "plumbing" or "wiring" becomes the named connection or operation.
- "single source of truth" becomes the authoritative file or system and who reads it.
- "thin wrapper" becomes a description of what the function delegates and what it adds.

Literal substrates, seams, load-bearing walls, test harnesses, vectors, and ratchets retain their normal names. Do not rename an API, architecture term, or code identifier to avoid a match.

## Coding-agent adjectives and technical terms

Inspect unsupported claims involving:

- failure mode, trade-off, first-class, end-to-end, straightforward, cleanly, invariant;
- zero-cost, ergonomic / ergonomics, composable, idempotent / idempotency, orthogonal, canonical, scaffold / scaffolding, mechanical / mechanically.

These often have precise meanings. Keep the term when it describes a documented property or established concept. Explain it for the audience when useful. Do not replace "idempotent" with "safe", "byte-identical" with "similar", or "invariant" with "assumption". Those changes lose meaning. Name the actual failure, cost, guarantee, or comparison instead of using technical adjectives as praise.

Examples:

- Keep "The operation is idempotent: repeating the same request leaves the same final state" when that guarantee is established.
- Replace "The escape hatch makes integration seamless" with the documented override and its effect, if provided.
- Replace "The surgical fix cleanly addresses the failure mode" with the specific change and failure it addresses.

## Additional contextual watchlist

Treat these as contextual review prompts, not automatic reasons to rewrite.

Inspect: load-bearing, honest / honestly, worth nothing, worth noting, churn / churns / churned / churning, seam / seams, substrate / substrates, seamless / seamlessly.

Other words to review in context:

plainly, quietly, refusal, survived, re-derived, halves, asserted, nobody, genuinely, deliberately, premise, refuses, pre-fix, outright, byte-identical, ruling, genuine, handed, carries.

Most of these are ordinary words. Keep "halves" for actual halves, "refusal" for an actual refusal, "ruling" for a court ruling, "byte-identical" for byte-for-byte equality, and "pre-fix" for a before-the-fix distinction when clear. Inspect "quietly", "genuinely", "plainly", and "honestly" when they add mood or announced sincerity without information.

## Plain-word substitutions

Prefer these when the words mean the same thing in context:

- utilize / leverage → use;
- facilitate → help;
- numerous → many;
- in the event that → if;
- in order to → to;
- due to the fact that → because;
- authored → wrote;
- relocated → moved;
- attempted → tried.

Do not apply substitutions to protected quotations, code, names, or references. Preserve distinctions such as financial leverage, relocation records, formal facilitation, and attempts whose outcomes matter. Read the resulting sentence for meaning instead of treating replacements as a word filter.
