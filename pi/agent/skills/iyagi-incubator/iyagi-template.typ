// See example.typ for a full worked instance. Internal helpers use the `ii-`
// (iyagi-incubator) prefix; only `iyagi-sheet` is meant to be called.

// ---- Palette (supplied cool/dusk scheme on a creamy ivory ground) ----
#let ii-ink   = rgb("#232433")
#let ii-paper = rgb("#f4f4f6")
#let ii-muted = rgb("#5f6f87")
#let ii-palette = (
  rgb("#5f6f87"),  // 0 slate blue     (Korean Story)
  rgb("#5e7173"),  // 1 teal           (English Translation)
  rgb("#98879f"),  // 2 muted lavender (Target Grammar)
  rgb("#473759"),  // 3 deep purple    (Vocabulary)
  rgb("#424849"),  // 4 graphite       (Practice)
)

#let ii-tint(c, amount) = c.lighten(amount)

// ---- Section block with colored header ----
#let ii-section(color, label-en, label-ko, body, pad-bottom: 0pt) = {
  block(
    width: 100%,
    breakable: false,
    inset: 0pt,
    {
      block(
        width: 100%,
        fill: color,
        radius: (top-left: 4pt, top-right: 4pt),
        inset: (x: 12pt, y: 5pt),
        {
          grid(
            columns: (1fr, auto),
            align: (left + horizon, right + horizon),
            column-gutter: 8pt,
            box({
              box(baseline: 0.15em, rect(
                width: 3pt, height: 0.95em,
                fill: white.transparentize(35%),
                radius: 2pt,
              ))
              h(7pt)
              text(
                font: "NanumGothic",
                size: 10pt,
                weight: "bold",
                fill: white,
                tracking: 0.3pt,
                upper(label-en),
              )
            }),
            text(
              font: "NanumGothic",
              size: 9pt,
              weight: "regular",
              fill: white.transparentize(22%),
              label-ko,
            ),
          )
        },
      )
      block(
        width: 100%,
        above: 0.425em,
        fill: ii-tint(color, 93%),
        stroke: 0.6pt + ii-tint(color, 45%),
        radius: (bottom-left: 4pt, bottom-right: 4pt),
        inset: (left: 12pt, right: 12pt, top: 8pt, bottom: 8pt + pad-bottom),
        body,
      )
    },
  )
}

// ---- Small pill badge (masthead) ----
#let ii-badge(color, key, val) = box(
  fill: ii-tint(color, 88%),
  stroke: 0.7pt + ii-tint(color, 40%),
  radius: 20pt,
  inset: (x: 11pt, y: 5pt),
  baseline: 0.32em,
  {
    text(font: "NanumGothic", size: 7.6pt, weight: "bold",
      fill: color.darken(12%), tracking: 0.5pt, upper(key))
    h(5pt)
    text(font: "NanumGothic", size: 9pt, weight: "bold", fill: ii-ink, val)
  },
)

// ---- Main template function ----
#let iyagi-sheet(
  topic: "",
  level: "",
  korean: [],
  english: none,
  grammar: (),
  vocab: none,
  questions: none,
) = {
  set page(
    paper: "a4",
    margin: (x: 1.7cm, top: 1.15cm, bottom: 1.15cm),
    fill: ii-paper,
  )
  set text(
    font: ("Libertinus Serif", "NanumMyeongjo"),
    size: 10.5pt,
    fill: ii-ink,
    lang: "en",
  )
  set par(justify: true, leading: 0.7em, spacing: 0.85em)

  let sec-i = 0
  let color-at(i) = ii-palette.at(calc.rem(i, ii-palette.len()))

  // ---------- Masthead ----------
  block(width: 100%, {
    text(font: "NanumGothic", size: 8pt, weight: "bold",
      fill: ii-muted, tracking: 2.5pt, upper("Korean Reader · 한국어 이야기"))
    v(3pt)
    text(font: "Libertinus Serif", size: 22pt, weight: "bold",
      fill: ii-ink, style: "italic", topic)
    v(6pt)
    ii-badge(ii-palette.at(0), "Level", level)
  })
  v(6pt)
  line(length: 100%, stroke: 0.8pt + ii-tint(ii-ink, 55%))
  v(8pt)

  // ---------- 1. Korean Story ----------
  ii-section(color-at(sec-i), "Korean Story", "한국어 이야기", {
    set text(size: 10.5pt)
    set par(leading: 0.72em, spacing: 0.66em, first-line-indent: 0pt)
    korean
  })
  sec-i += 1
  v(6pt)

  // ---------- 2. English Translation (omittable) ----------
  if english != none {
    ii-section(color-at(sec-i), "English Translation", "영어 번역", {
      set text(size: 9.5pt, fill: ii-tint(ii-ink, 8%))
      set par(leading: 0.66em, spacing: 0.66em)
      english
    })
    sec-i += 1
    v(6pt)
  }

  // ---------- 3. Target Grammar (3-column table) ----------
  if grammar != none and grammar.len() > 0 {
    let g-color = color-at(sec-i)
    sec-i += 1
    ii-section(g-color, "Target Grammar", "핵심 문법", {
      set par(justify: false)
      let header(t) = table.cell(
        inset: (x: 8pt, y: 6pt),
        align: bottom + left,
        text(font: "NanumGothic", size: 8pt, weight: "bold",
          fill: g-color.darken(8%), tracking: 0.6pt, upper(t)),
      )
      table(
        columns: (auto, 1fr, auto),
        stroke: none,
        inset: (x: 8pt, y: 5pt),
        align: (left + horizon, left + horizon, left + horizon),
        fill: (_, row) => if row == 0 { none }
          else if calc.odd(row) { ii-tint(g-color, 96%) }
          else { white.transparentize(40%) },
        header("Formula"),
        header("Sentence"),
        header("Meaning"),
        table.hline(y: 1, stroke: 1.4pt + g-color),
        ..grammar.map(g => (
          text(font: "NanumGothic", size: 9.5pt, weight: "bold",
            fill: g-color.darken(15%), g.formula),
          text(size: 9.5pt, g.sentence),
          text(size: 9pt, fill: ii-tint(ii-ink, 12%), style: "italic", g.meaning),
        )).flatten(),
      )
    })
    v(6pt)
  }

  // ---------- 4 & 5. Vocabulary + Practice ----------
  let has-vocab = vocab != none and vocab.len() > 0
  let has-q = questions != none and questions.len() > 0

  let vocab-block(v-color, cols, pad: 0pt) = ii-section(
    v-color, "Useful Vocabulary", "유용한 어휘",
    {
      set par(justify: false)
      let vtable(rows) = table(
        columns: (auto, 1fr),
        stroke: none,
        inset: (x: 8pt, y: 4.5pt),
        align: (left + horizon, left + horizon),
        fill: (_, row) => if calc.even(row) { ii-tint(v-color, 96%) }
          else { white.transparentize(40%) },
        ..rows.map(p => (
          text(size: 9.5pt, weight: "bold", fill: v-color.darken(12%), p.at(0)),
          text(size: 9pt, fill: ii-tint(ii-ink, 12%), p.at(1)),
        )).flatten(),
      )
      if cols <= 1 {
        vtable(vocab)
      } else {
        let half = calc.ceil(vocab.len() / 2)
        grid(
          columns: (1fr, 1fr),
          column-gutter: 12pt,
          vtable(vocab.slice(0, half)),
          vtable(vocab.slice(half)),
        )
      }
    },
    pad-bottom: pad,
  )

  let practice-block(q-color, label-en, pad: 0pt) = ii-section(
    q-color, label-en, "연습 문제",
    {
      set par(justify: false, leading: 0.72em, spacing: 0.58em)
      for (i, q) in questions.enumerate() {
        grid(
          columns: (auto, 1fr),
          column-gutter: 8pt,
          align: (right + top, left + top),
          box(
            fill: q-color,
            radius: 50%,
            width: 15pt, height: 15pt,
            align(center + horizon,
              text(font: "NanumGothic", size: 8pt, weight: "bold",
                fill: white, str(i + 1))),
          ),
          box(inset: (top: 1pt), text(size: 9.5pt, q)),
        )
        if i < questions.len() - 1 { v(3.5pt) }
      }
    },
    pad-bottom: pad,
  )

  if has-vocab and has-q {
    let v-color = color-at(sec-i)
    let q-color = color-at(sec-i + 1)
    sec-i += 2
    let gutter = 10pt
    layout(size => {
      let avail = size.width - gutter
      let w-v = avail * 1.5 / 2.5
      let w-q = avail * 1.0 / 2.5
      context {
        let h-v = measure(box(width: w-v, vocab-block(v-color, 2))).height
        let h-q = measure(box(width: w-q, practice-block(q-color, "Practice"))).height
        let mh = calc.max(h-v, h-q)
        grid(
          columns: (1.5fr, 1fr),
          column-gutter: gutter,
          align: (top, top),
          vocab-block(v-color, 2, pad: mh - h-v),
          practice-block(q-color, "Practice", pad: mh - h-q),
        )
      }
    })
  } else if has-vocab {
    let v-color = color-at(sec-i)
    sec-i += 1
    vocab-block(v-color, 2)
  } else if has-q {
    let q-color = color-at(sec-i)
    sec-i += 1
    practice-block(q-color, "Practice Questions")
  }
}
