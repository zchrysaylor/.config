---
name: slop-solvent
description: Removes AI-slop vocabulary, stock rhetoric, filler, and formatting from prose while preserving meaning and the writer's voice. Use when drafting or editing prose, documentation, blog posts, reports, emails, comments, or written content generation, especially when asked to unslop text, remove AI tells, or make writing less generic.
---

# Slop solvent

Edit writing to remove formulaic AI phrasing. Prefer concrete information and ordinary language. Apply these checks to your own prose while this skill is active.

## Quick start

`/skill:slop-solvent Rewrite the following paragraph: ...`

`/skill:slop-solvent Edit README.md for AI slop without changing technical claims.`

Read [PATTERNS.md](PATTERNS.md) and [VOCABULARY.md](VOCABULARY.md) before editing. They contain the full checklist and word watchlists.

## Process

1. Identify the text, audience, intended tone, and required format. If no target is supplied or clear from context, ask for it. When drafting, use the user's facts and constraints.
2. Read the whole text. Note facts, qualifications, citations, distinctive details, and terminology that must survive.
3. Scan for content problems first, then rhetorical patterns, vocabulary, and formatting. Look for clusters and repetition, not just isolated words.
4. Rewrite at sentence or paragraph level. Delete empty claims, state useful points directly, and replace abstract praise with supported details. Do not merely swap synonyms.
5. Compare the revision with the original. Check numbers, names, negation, causal claims, scope, uncertainty, citations, and technical meaning.
6. Self-audit: "Which sentences still sound prefabricated? What do they actually tell the reader?" Fix remaining patterns without making the prose choppy or impersonal.
7. Return the edited text. Add a short note only for unresolved factual or citation problems, or when the user requests an explanation. For file edits, report the paths and relevant checks briefly.

## Editing priorities

- Preserve meaning before shortening. Keep concrete facts, useful context, and the writer's intended attitude.
- Remove inflated significance, promotional praise, invented consensus, and unsupported analysis.
- Replace staged revelations, slogan-like contrasts, therapeutic scripts, and repeated sentence formulas with the actual point.
- Prefer "is", "has", "use", and named actions over elaborate substitutes. Keep consistent names for the same thing.
- Use complete, readable sentences. Prefer active voice when the actor is known and relevant. Split sentences that require backtracking.
- Let the information determine the number of examples, paragraphs, and list items. Do not force triples or conclusions.
- Apply the watchlists in context. A precise technical term is better than a vague plain-language replacement.

## Default house style

Follow an explicit user or publication style guide over these defaults.

- Avoid em dashes in edited prose. Restructure with periods or commas, without creating comma splices. Do not replace them with en dashes, hyphen-as-dash punctuation, or parenthetical detours. Preserve meaningful compound hyphens, ranges, and technical notation.
- Use colons before actual lists or examples, not to manufacture a reveal or join unrelated clauses.
- Use sentence-case headings and straight quotes in prose you control. Preserve proper names and exact quotations.
- Remove decorative emojis, excessive bold, and redundant bold-label-and-colon bullets. Keep useful lists, comparison tables, code blocks, and navigational headings.
- Omit chatbot greetings, praise, offers of further help, and announcements of how clear or honest the answer is. Answer directly.

## Safeguards

- These are editing heuristics, not an authorship detector. Do not claim a word, punctuation mark, or pattern proves AI use, or promise to defeat detection tools.
- Do not invent evidence, measurements, mechanisms, sources, personal anecdotes, or opinions to make prose more concrete. If a substantive claim needs support, flag it rather than silently deleting or strengthening it.
- Preserve necessary uncertainty, warnings, disclosures, and limitations. Remove their boilerplate framing, not their substance. Never imply verification or testing that did not occur.
- Do not alter quotations, code, identifiers, commands, URLs, or citation metadata merely because they contain watchlist words. Repair broken markup only within the requested scope, without changing code behavior.
- Preserve deliberate voice, dialect, humor, and genre conventions. Do not add typos, slang, fake emotion, or artificial sentence variation to simulate humanity.
- A useful sentence may survive unchanged. Genuine contrasts, factual triples, and established terminology are allowed when they carry information.

## Examples

Before: "This robust tool serves as a game-changer, seamlessly enhancing your workflow."
After, if the surrounding text establishes this behavior: "The tool checks changed files before each commit."
Without that context: flag the missing description of what the tool does. Do not invent one.

Before: "I'll be honest: here's the catch. The cache isn't just fast, it stores responses for 60 seconds. That's the whole point."
After: "The cache stores responses for 60 seconds."
The revision retains the stated duration and drops the unsupported speed claim.

Before: "Parser rejects bad date → exit 2, no write."
After: "The parser rejects an invalid date, exits with code 2, and writes nothing."
