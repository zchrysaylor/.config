---
name: html-out
description: Creates complete standalone HTML documents using the bundled Terminal Atlas template and writes them to a file. Use when the user asks for html-out, HTML-formatted output, or a standalone HTML report/page.
---

# HTML Out

## Required output style

When this skill is active, format the user-facing response as a complete standalone HTML document based on the bundled [`template.html`](template.html).

## Workflow

1. Read `template.html` from this skill directory before producing the response.
2. Keep the template's visual system: dark editorial theme, bordered panels/cards, terminal-style labels, typography, spacing, and responsive CSS.
3. Replace the demo content with content tailored to the user's request.
4. Preserve a valid standalone document: `<!doctype html>`, `<html>`, `<head>`, embedded `<style>`, and `<body>`.
5. Do not rely on external assets, scripts, fonts, stylesheets, or network calls unless the user explicitly asks.
6. Write the completed HTML to a new `.html` file in the current working directory, unless the user specifies a different output location.

## Content guidelines

- Use semantic sections, clear headings, and concise copy.
- Prefer existing template components: `topbar`, `hero`, `terminal`, `panel`, `card`, `grid-2`, `grid-3`, `docs-layout`, `table-wrap`, `timeline`, and `note`.
- Use tables for structured comparisons and cards for grouped concepts.
- Escape user-provided text correctly for HTML.
- If the answer includes code, place it in template-styled code or terminal blocks.

## File output

Always create a new `.html` file for the generated page. Use the current working directory by default and choose a clear, kebab-case filename such as `report.html`, `overview.html`, or a name derived from the user's topic. If the user specifies a path or filename, use that location instead. After writing the file, respond with a concise summary and the file path; do not paste the full HTML unless explicitly asked.
