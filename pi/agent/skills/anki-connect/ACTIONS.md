# AnkiConnect Action Catalog

Use this catalog to map intent to candidate actions, not as a parameter reference or guarantee of installed support. Check availability using `apiReflect` with `scopes:["actions"]` and consult upstream documentation or implementation for unfamiliar parameters.

## Confirmation-required examples

Always request and receive confirmation before adding, modifying, or deleting notes/cards, including indirect changes. These examples are not exhaustive:

- Notes: `addNote`, `addNotes`, `updateNoteFields`, `updateNoteTags`, `updateNote`, `updateNoteModel`, `addTags`, `removeTags`, `deleteNotes`, `removeEmptyNotes`, `replaceTags`, `replaceTagsInAllNotes`, `clearUnusedTags`.
- Cards/reviews: `setEaseFactors`, `setSpecificValueOfCard`, `suspend`, `unsuspend`, `forgetCards`, `relearnCards`, `answerCards`, `guiAnswerCard`, `guiUndo`, `insertReviews`, `setDueDate`, `changeDeck`.
- Imports: `importPackage` and `guiImportFile` workflows that add or modify collection data.
- Deck/model modifications that materially affect notes/cards, including deck deletion, model edits, and scheduling-configuration changes.
- Media deletion or overwrites that affect existing notes/cards.

Confirm once per logical operation with its intent, scope, and count when known. Apply the same policy to nested `multi` actions.

## Cards

`getEaseFactors`, `setEaseFactors`, `setSpecificValueOfCard`, `suspend`, `unsuspend`, `suspended`, `areSuspended`, `areDue`, `getIntervals`, `findCards`, `cardsToNotes`, `cardsModTime`, `cardsInfo`, `forgetCards`, `relearnCards`, `answerCards`, `setDueDate`.

## Decks

`deckNames`, `deckNamesAndIds`, `getDecks`, `createDeck`, `changeDeck`, `deleteDecks`, `getDeckConfig`, `saveDeckConfig`, `setDeckConfigId`, `cloneDeckConfigId`, `removeDeckConfigId`, `getDeckStats`.

## Graphical interface

`guiBrowse`, `guiSelectCard`, `guiSelectedNotes`, `guiAddCards`, `guiEditNote`, `guiAddNoteSetData`, `guiCurrentCard`, `guiStartCardTimer`, `guiShowQuestion`, `guiShowAnswer`, `guiAnswerCard`, `guiUndo`, `guiDeckOverview`, `guiDeckBrowser`, `guiDeckReview`, `guiImportFile`, `guiExitAnki`, `guiCheckDatabase`, `guiPlayAudio`.

## Media

`storeMediaFile`, `retrieveMediaFile`, `getMediaFilesNames`, `getMediaDirPath`, `deleteMediaFile`.

## Miscellaneous

`requestPermission`, `version`, `apiReflect`, `sync`, `getProfiles`, `getActiveProfile`, `loadProfile`, `multi`, `exportPackage`, `importPackage`, `reloadCollection`.

## Models (note types)

`modelNames`, `modelNamesAndIds`, `findModelsById`, `findModelsByName`, `modelFieldNames`, `modelFieldDescriptions`, `modelFieldFonts`, `modelFieldsOnTemplates`, `createModel`, `modelTemplates`, `modelStyling`, `updateModelTemplates`, `updateModelStyling`, `findAndReplaceInModels`, `modelTemplateRename`, `modelTemplateReposition`, `modelTemplateAdd`, `modelTemplateRemove`, `modelFieldRename`, `modelFieldReposition`, `modelFieldAdd`, `modelFieldRemove`, `modelFieldSetFont`, `modelFieldSetFontSize`, `modelFieldSetDescription`.

## Notes

`addNote`, `addNotes`, `canAddNotes`, `canAddNotesWithErrorDetail`, `updateNoteFields`, `updateNote`, `updateNoteModel`, `updateNoteTags`, `getNoteTags`, `addTags`, `removeTags`, `getTags`, `clearUnusedTags`, `replaceTags`, `replaceTagsInAllNotes`, `findNotes`, `notesInfo`, `notesModTime`, `deleteNotes`, `removeEmptyNotes`.

## Statistics and reviews

`getNumCardsReviewedToday`, `getNumCardsReviewedByDay`, `getCollectionStatsHTML`, `cardReviews`, `getReviewsOfCards`, `getLatestReviewID`, `insertReviews`.

## Additional implementation-specific actions

These may be absent from the documentation or installed build. Verify availability and parameters before use:

- `canAddNote` — `{note: ...}`; single-note preflight returning a boolean.
- `canAddNoteWithErrorDetail` — `{note: ...}`; returns `canAdd` and an `error` on failure.
- `deckNameFromId` — `{deckId: ...}`.
- `modelNameFromId` — `{modelId: ...}`.
- `guiReviewActive` — no parameters; reports whether a card is actively being reviewed.
- `guiSelectNote` — deprecated; takes a card ID through the `note` parameter. Prefer `guiSelectCard`.
