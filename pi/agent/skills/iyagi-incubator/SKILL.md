---
name: iyagi-incubator
description: Creates short Korean stories constrained to the learner's known grammar formulas and language level. Use when the user wants Korean reading or writing practice, asks for a Korean story/composition, or mentions Korean grammar practice.
---

# Iyagi Incubator

## Quick start

1. Read `PROFILE.md` and `GRAMMAR.md` before composing.
2. If the user did not provide a story topic, ask for one and pause.
3. Use the level from the user's prompt; otherwise use `PROFILE.md`. If no level is set, ask for a Sejong level (`1A`, `1B`, `2A`, `2B`, `3A`, `3B`, `4A`, or `4B`) or general level (`beginner`, `intermediate`, etc).
4. Compose a short Korean story that targets grammar from `GRAMMAR.md` and keeps vocabulary near the selected level.

## Grammar source of truth

- `GRAMMAR.md` lists grammar formulas the learner already knows.
- Treat each table row as one known target grammar pattern.
- Use a natural subset of 3-6 formulas per story, or all formulas if the list is short and the result still sounds natural.
- Avoid introducing advanced unlisted grammar. If an unlisted pattern is necessary, keep it simple and add a concise explanatory footnote to the story.
- When the user says they know a new formula or wants one removed/changed, update `GRAMMAR.md`.

## Level and vocabulary

- `PROFILE.md` stores the learner's default level and explains the rough vocabulary and complexity expectations for each level.
   - Levels are loosely based on the King Sejong Institute level system.
- User-provided level in the prompt overrides `PROFILE.md` for that response.
- Prefer common daily-life vocabulary. Introduce only a few new words, and gloss them.
- Never use romanization.

## Story workflow

When generating a story:

1. State the topic and chosen level.
2. Write the Korean story first. Keep it short:
   - `1A`/`1B`: 5-8 short sentences.
   - `2A`/`2B`: 1-2 short paragraphs.
   - `3A`/`3B`: 2-3 short paragraphs with simple narrative flow.
   - `4A`/`4B`: 3-4 short paragraphs. Keep it to one page — trim vocabulary if it overflows.
3. Provide a natural English translation after the Korean if enabled in `PROFILE.md`.
4. Add a compact table: formula, sentence from the story, meaning in context.
5. Add 5-10 useful vocabulary items if enabled in `PROFILE.md`.
6. Add 2-3 comprehension or rewrite questions for practice, if enabled in `PROFILE.md`.
7. Compile the aesthetic one-page PDF with the Typst template (see [Compiled one-pager](#compiled-one-pager-typst)).

## Compiled one-pager (Typst)

After presenting the story in chat, render a one-page PDF with the bundled Typst template so the learner gets a keepsake study sheet.

- Requires the `typst` CLI. Check with `typst --version`; if it is missing, tell the user (e.g. `brew install typst`) and skip this step rather than failing.
- `iyagi-template.typ` is the reusable template. It defines `iyagi-sheet(...)` and all styling (colored section headers, masthead, grammar/vocabulary tables). **Do not edit it per story** — only fill an instance file.
- `example.typ` / `example.pdf` are a worked example you can mimic.

### Steps

1. Pick a short kebab-case slug from the topic (e.g. `first-love`).
2. Choose the output directory `<OUT>`:
   - **Default:** the skill's own `stories/` folder, `<SKILL_DIR>/stories/`. It is git-ignored, so generated sheets never show up as repo changes.
   - **Override:** if the user named a directory in the prompt, use that instead.

   Write the instance file there as `<OUT>/<slug>.typ`. Its first line imports the template **by absolute path**:
   `#import "<SKILL_DIR>/iyagi-template.typ": iyagi-sheet`
   Replace `<SKILL_DIR>` with the absolute path of this skill's directory (the folder this `SKILL.md` lives in).
3. Call `iyagi-sheet(...)` with the story data (skeleton below). Pass `none` for any section that is disabled in `PROFILE.md` — the template omits it automatically.
4. Compile in place, writing the PDF beside the instance: `typst compile --root / <OUT>/<slug>.typ <OUT>/<slug>.pdf`
   (`--root /` lets Typst read the template from its absolute location. Alternatively, copy `iyagi-template.typ` next to the instance, import it as `"iyagi-template.typ"`, and compile without `--root` to get a self-contained bundle.)
5. Confirm it compiled and tell the user the PDF path. The layout targets one A4 page; if content overflows, trim vocabulary to ~8 items or shorten the story.

### Argument mapping

- `topic`, `level`: strings.
- `korean`, `english`: content blocks `[ ... ]`. Separate paragraphs with one blank line. Use `english: none` when translation is disabled.
- `grammar`: array of `(formula: "...", sentence: "...", meaning: "...")` dictionaries — one per row of the grammar table.
- `vocab`: array of `("한국어", "english")` pairs, or `none`.
- `questions`: array of content blocks `[ ... ]`, or `none`.

### Escaping (inside the `.typ` file)

- In `"..."` strings, write `\\` for a literal backslash and `\"` for a literal quote.
- In `[ ... ]` content blocks, prefix any literal `#`, `*`, `_`, `@`, `<`, `>`, `` ` ``, `$`, `\`, `[`, or `]` with a backslash. Straight quotes `"` are safe (Typst renders smart quotes).
- Never use romanization anywhere.

### Instance skeleton

```typ
#import "<SKILL_DIR>/iyagi-template.typ": iyagi-sheet

#iyagi-sheet(
  topic: "first love",
  level: "2A",
  korean: [
    첫 번째 문단…

    두 번째 문단…
  ],
  english: [
    First paragraph…

    Second paragraph…
  ],
  grammar: (
    (formula: "있어요", sentence: "민수는 첫사랑이 있었어요.", meaning: "Minsu had a first love."),
  ),
  vocab: (
    ("첫사랑", "first love"),
  ),
  questions: (
    [민수의 첫사랑은 누구예요?],
  ),
)
```

## If context is missing

- No topic: ask "What topic should the story be about?"
- No level: ask for a level and offer to save it to `PROFILE.md`.
- Empty grammar list: ask the user to add known formulas or offer to add formulas they provide.
