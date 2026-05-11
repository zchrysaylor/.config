---
name: otv2-checklist
description: Reviews code changes against the OTv2 release-safety checklist for canary safety, Liquibase migrations, DB/SNS/event compatibility, enums, validation, and load-test risks. Use when reviewing OTv2 changes, pull requests, diffs, Hunk sessions, or when the user mentions the OTv2 checklist.
---

# OTv2 Checklist

Use this skill to review changes against the OTv2 checklist. The checklist text below is the source-of-truth review rubric and must stay unchanged because it is defined in GitHub.

## Quick start

1. Identify the change scope: uncommitted diff, branch diff, PR, commit, or active Hunk session.
2. Inspect the relevant code and migration/event/DTO changes.
3. Walk through each checklist item and mark findings clearly:
   - `Pass` when the changes satisfy the item.
   - `Concern` when there is a concrete risk or missing evidence.
   - `N/A` when the item does not apply.
4. Summarize only actionable concerns, with file/line references when possible.

## Review workflow

- Prefer the user's current review context. If they are using Hunk, use the Hunk review workflow to inspect the live session and add focused inline comments when useful.
- If no review context is provided, ask what to review or inspect the current repository diff.
- Apply the checklist conservatively: compatibility and rollback/canary safety risks should be called out even when the code appears correct in isolation.
- Do not rewrite or modernize the checklist language during review; use it as-is.

## Checklist

<!-- Check these by replacing x in the check boxes like this [x] -->

- [ ] Are the changes canary-safe?
  - Not removing a mandatory field or enum value from DB (including order_details json, etc.), SNS event still being used by the pods with previous image.
  - Not changing/adding any new mandatory field in DB, queue message DTOs which will fail validation for existing pods.
  - Not addding any new validation on existing field (or new enum value) in DB, queue message DTOs which will fail validation for existing pods.
  - Later, if a rollback is needed it will impact the records which have such new enum values. See [SafeEnumWrapper](https://github.com/deliveryhero/log-vendor-bootstrap-java/blob/master/bootstrap-jackson/src/main/java/com/ninecookies/services/bootstrap/jackson/SafeEnumWrapper.java).


- [ ] Adhering to Liquibase guidelines?
  - Creating indexes concurrently on existing column.
  - Not making any column data type change which may require manual PG ANALYZE.
  - Avoid setting default value to newly column, as it updates all the existing rows.
  - No manual changes to previously added changeset id, as it blocks the liquibase job altogether.


- [ ] Other pitfalls
  - No temporal validation like `@Future` for persisted fields, as it may not be in future when the record gets loaded next time.
  - Has the [Data Engineering](https://deliveryhero.enterprise.slack.com/archives/C016TKX783A) team been informed, in case of new fields in DB or SNS notifications?
    - Note: they do not need to be informed for new fields within OrderDetails, they are storing the JSON as a string.
  - Have enums been changed? This might lead to problems with calls from the auto-generated clients, like CRS or DPS are using
  - Possible needed load-test enhancement evaluated? E.g. if it puts significant load on the system (more DB-writes/message-processing, etc.) it should be reflected in the load-test.
