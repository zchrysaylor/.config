---
name: flashcards
description: Generates high-quality spaced-repetition flashcards from notes, articles, textbook excerpts, lists, sequences, formulas, or concepts. Use when the user asks for flash cards/flashcards, Anki or Mochi cards, spaced repetition prompts, memorization cards, cloze cards, or converting study material into cards.
---

# Flashcards

Generate flashcards by turning source material into a graph of small concepts and relationships.

## Core rules

1. **Understand first.** Do not card unclear material. If the text is ambiguous, first state the clarification needed or make a labeled assumption.
2. **Atomic cards.** One smallest useful fact per card. Avoid answers with multiple independent clauses unless the card is an intentional summary/test card.
3. **Repeat yourself.** Prefer several small, overlapping cards over one large card.
4. **Two-way prompts.** When useful, ask both directions: term → definition and definition → term; notation → meaning and meaning → notation; symbol/formula → interpretation and interpretation → symbol/formula.
5. **Multiple framings.** Include formal/informal, intuition, example/non-example, cause/effect, and contextual prompts when they test distinct retrieval routes.
6. **Cache insights.** If a verified implication follows from the source, make cards for it and label it as inferred if not explicit.
7. **Hierarchies both ways.** For taxonomies, make parent → children and child → parent cards, plus definition cards for each node.
8. **Sequences selectively.** For ordered lists, use enough of: whole-sequence recall, position → item, item → position, predecessor/successor, and cloze. Do not overproduce if a smaller set is adequate.
9. **Keep wording simple.** Questions should be quick to parse and answers quick to grade.
10. **Organize by source.** If producing deck metadata, group by source/chapter/section rather than trying to invent a perfect topic ontology.

## Workflow

1. Extract the learnable units: terms, definitions, notations, formulas, properties, relationships, examples, procedures, hierarchies, and sequences.
2. Build cards from relationships between units. Each card should traverse one edge in the concept graph.
3. Add redundancy deliberately: reverse directions and alternate wording where it improves recall.
4. Add summary/test cards only after the atomic cards exist.
5. Review the output for overloaded answers, duplicate cards with no new retrieval path, and unanswerable prompts.

## Output format

Default to a Markdown table:

| Question | Answer | Notes |
|---|---|---|

- Omit `Notes` if no caveats, source references, or inferred labels are needed.
- Preserve math notation and code exactly when relevant.
- If the user requests CSV/TSV/Anki/Mochi, output that format instead.
- For cloze cards, use `{{c1::text}}` by default unless the user asks for another syntax.

## Card patterns

### Definitions and terms

- `What is [term]?` → concise definition.
- `What is the term for [definition]?` → term.
- `Informally, what is [term]?` → intuition.
- `Formally, what is [term]?` → formal statement.

### Notation, symbols, formulas

- `What does [symbol] denote?` → concept.
- `What is the notation for [concept]?` → symbol.
- `[formula expression]` → result.
- `What relationship does [formula] express?` → interpretation.

### Hierarchies

- `What are the subtypes/parts of [parent]?` → children.
- `[child] is a kind/part of ...` → parent.
- `What distinguishes [A] from [B]?` → contrast.

### Sequences

For a sequence named `S` with items `A, B, C`:

- `S: Recall all elements in order` → `A, B, C.`
- `S: What element has position 2?` → `B.`
- `S: What is the position of B?` → `2.`
- `S: What comes after A?` → `B.`
- `S: What comes before C?` → `B.`
- Cloze: `S: {{c1::A}}, {{c2::B}}, {{c3::C}}.`

Use `scripts/sequence.py` for deterministic CSV generation from a titled line list.

### Procedures

- `What is the first/next step in [procedure]?` → step.
- `After [step], what comes next?` → next step.
- `Why do you do [step]?` → purpose.
- Avoid cards that require reciting many steps unless also supported by atomic step cards.

## Quality checklist

Before finalizing, ensure:

- Each answer is objectively gradeable.
- No card asks for a list that is too long unless it is a deliberate summary/test card.
- Important relationships are asked in both directions where useful.
- Inferred cards do not overstate the source.
- The user can import/copy the result without extra cleanup.
