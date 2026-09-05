---
name: k-vocab-gen
description: Generates high-quality Korean vocabulary flashcards.
disable-model-invocation: true
---

# Korean Flashcard Generation

Create Korean vocabulary flashcards optimized for **productive, contemporary spoken Korean**.

The goal is not encyclopedic knowledge of every dictionary sense. Prioritize meanings, forms, constructions, collocations, and examples that help a learner understand and speak naturally with Korean speakers.

## Card Template

### Front

```
<Korean word or construction>
<short natural context, only when useful>
```

### Back

```
<core English meaning>

<natural Korean example>
<natural English translation>

<part of speech> · <optional usage note>
```

The context and usage note are optional. Do not add them merely for consistency.

## Rules

### 1. Prioritize conversational usefulness

Prefer meanings/forms commonly used or encountered in contemporary conversation. A sense being technically valid in a dictionary is not enough reason to teach it.

If a sense is archaic, literary, highly formal, religious, legal, technical, or otherwise uncommon:

* omit it if it has little practical value;
* mark it as recognition vocabulary if useful to recognize; or
* note its register and give the normal conversational alternative.

Do not present obscure senses as equally important to common ones.

### 2. Use accurate, discriminative English

Avoid English glosses that imply a broader equivalence than the Korean word actually has. Definitions should be concise but specific enough to teach real usage.

Examples:

* `마음` → **heart/mind; feelings; intention/desire**, not "personality"
* `체험` → **firsthand/hands-on experience**, not generic "experience"
* `추억` → **memory/recollection of the past, often nostalgic or emotionally meaningful**, not generic "memory"
* `반갑다` → **glad/pleased to see or meet someone; pleased to receive welcome news**, not generic "glad"

When Korean words share an English translation but differ in nuance or usage, make the distinction clear.

### 3. Teach the form actually used

Do not automatically use the dictionary headword. If a particular form, construction, or collocation is substantially more useful, teach it instead.

Examples:

* `전통적` → `전통적인 / 전통적이다`
* "fixed/regular" `일정` → `일정하다`
* "deserving" `싸다` → `~아/어도 싸다`
* `말미암다` → preferably `~로 말미암아`

For uncommon/formal words, identify the normal conversational alternative:

* `~로 말미암아` → `formal/written · in conversation, usually: 때문에`
* `그러므로` → `formal/written · in conversation, usually: 그래서`
* `행실` → note that it is formal/old-fashioned; `행동` is generally more conversational

Describe the relationship accurately. Do not say `also commonly:` when the important distinction is actually register, nuance, or grammar.

### 4. Keep the front minimally informative

Normally show only:

```
<Korean word>
```

Add short Korean context only when it materially helps distinguish or learn the intended usage.

Do not put `(동사)`, `(명사)`, etc. on the front merely as hints.

Do not use dictionary homonym numbers such as `싸다¹`, `싸다²`, `싸다³`. They are artificial metadata rather than useful conversational knowledge.

### 5. Distinguish unrelated homonyms with natural context

Give unrelated homonyms separate cards and distinguish them with the **smallest useful natural Korean context**, preferably a common collocation:

```
싸다
가격이 싸다
```

```
싸다
짐을 싸다
```

```
싸다
똥을 싸다
```

These distinguish "cheap," "pack," and "poop" without arbitrary numbering.

Context should teach useful Korean, not merely label which card is being tested.

### 6. Do not unnecessarily split related senses

Separate genuinely unrelated homonyms, but keep closely related meanings together when they share a coherent core concept.

For example, `펴다` can include:

* `책을 펴다` — open a book
* `우산을 펴다` — open an umbrella
* `허리를 펴다` — straighten one's back

These related meanings do not need separate numbered cards.

By contrast, unrelated meanings of `싸다` should be separate.

### 7. Context is useful beyond homonyms

Use front-side context when a collocation or construction materially teaches how a word is used, even without homonymy.

For example:

```
들어주다
부탁을 들어주다
```

is often more useful than bare `들어주다`, because it teaches the common meaning "grant/do someone a favor."

Likewise:

```
모시다
부모님을 모시고 가다
```

teaches the honorific verb in a natural environment.

However, do not add context when the bare word is already a good retrieval target.

### 8. Use natural spoken examples

Examples should sound like contemporary Korean a person could naturally say.

Prefer the polite `해요체` (`요`-ending) for example sentences. Use another ending only when a `요`-ending would be unnatural or would fail to demonstrate the target conjugation or register.

Prefer common collocations, conversational grammar/endings, and realistic situations. Avoid unnatural sentences created merely to demonstrate a dictionary definition.

English translations should express what the Korean naturally means, not mechanically translate each word.

### 9. Keep back-side metadata sparse

Put part of speech on the back, where it reinforces grammar without becoming a retrieval hint.

The optional usage note should contain only genuinely useful information, such as:

* common alternative;
* register;
* important construction/collocation;
* nuance distinction;
* warning about a misleading English equivalent.

Do not force every card to have an alternative.

Valid examples include:

```
동사 · also commonly: 감동받다
```

```
formal/written · in conversation, usually: 때문에
```

```
형용사
```

## Good Card Examples

### Normal Word

**Front**

```
감동하다
```

**Back**

```
to be moved; touched

그 영화 보고 정말 감동했어요.
I was really moved by that movie.

동사 · also commonly: 감동받다
```

### Unrelated Homonym

**Front**

```
싸다
짐을 싸다
```

**Back**

```
to pack

아직 짐도 안 쌌어요.
I haven't even packed yet.

동사
```

`짐을 싸다` naturally distinguishes this from unrelated meanings such as "cheap" and "poop."

### Construction Rather Than Single Word

**Front**

```
~아/어도 싸다
```

**Back**

```
to deserve; it would be understandable if...

그렇게 무례하게 굴었으니 욕을 먹어도 싸요.
He was so rude that he deserves to get criticized.

표현 · usually indicates that a negative consequence is deserved or unsurprising
```

Teach this as the construction `~아/어도 싸다`, not standalone `싸다 = deserving`, because the construction is the unit needed for natural comprehension and production.
