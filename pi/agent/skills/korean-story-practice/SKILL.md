---
name: korean-story-practice
description: Creates short Korean stories constrained to the learner's known grammar formulas and language level. Use when the user wants Korean reading or writing practice, asks for a Korean story/composition, or mentions Korean grammar practice.
---

# Korean Story Practice

## Quick start

1. Read `PROFILE.md`, `LEVELS.md`, and `GRAMMAR.md` before composing.
2. If the user did not provide a story topic, ask for one and pause.
3. Use the level from the user's prompt; otherwise use `PROFILE.md`. If no level is set, ask for a Sejong level (`1A`, `1B`, `2A`, `2B`, or `3A`) or general level (`beginner`, `intermediate`, etc).
4. Compose a short Korean story that targets grammar from `GRAMMAR.md` and keeps vocabulary near the selected level.

## Grammar source of truth

- `GRAMMAR.md` lists grammar formulas the learner already knows.
- Treat each table row as one known target grammar pattern.
- Use a natural subset of 3-6 formulas per story, or all formulas if the list is short and the result still sounds natural.
- Avoid introducing advanced unlisted grammar. If an unlisted pattern is necessary, keep it simple and add a concise explanatory footnote to the story.
- When the user says they know a new formula or wants one removed/changed, update `GRAMMAR.md`.

## Level and vocabulary

- `PROFILE.md` stores the learner's default Sejong level.
- `LEVELS.md` explains the rough vocabulary and complexity expectations for each level.
- User-provided level in the prompt overrides `PROFILE.md` for that response.
- Prefer common daily-life vocabulary. Introduce only a few new words, and gloss them.
- Do not use romanization unless the user asks for it.

## Story workflow

When generating a story:

1. State the topic, chosen Sejong level, and target grammar count.
2. Write the Korean story first. Keep it short:
   - `1A`/`1B`: 5-8 short sentences.
   - `2A`/`2B`: 1-2 short paragraphs.
   - `3A`: 2-3 short paragraphs with simple narrative flow.
3. Bold the Korean phrase where each target grammar formula appears.
4. Provide a natural English translation after the Korean.
5. Add a compact table: formula, sentence from the story, meaning in context.
6. Add 5-10 useful vocabulary items.
7. Add 2-3 comprehension or rewrite questions for practice.

## If context is missing

- No topic: ask "What topic should the story be about?"
- No level: ask for a Sejong level and offer to save it to `PROFILE.md`.
- Empty grammar list: ask the user to add known formulas or offer to add formulas they provide.
