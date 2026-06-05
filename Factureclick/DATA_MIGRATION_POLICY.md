# Data Migration Policy

This project stores user data locally with SwiftData. Persisted model changes must be designed to preserve existing user data by default.

## Non-Negotiable Rules

1. Existing user data must not be reset, deleted, or silently replaced as part of a normal feature rollout.
2. New persisted fields must be migration-safe before they ship.
3. Store resets are development-only emergency actions and must never be introduced as silent production fallback behavior.
4. Every change to a SwiftData model is also a data migration change.

## Safe Change Patterns

- Prefer adding optional stored properties for new data.
- Prefer safe defaults and nil-aware UI/service fallbacks.
- Prefer adding new related models over heavily reshaping core models.
- Prefer additive schema changes over destructive ones.

## High-Risk Changes

These changes require explicit migration review before implementation:

- Adding new non-optional stored properties
- Removing stored properties that may exist in older stores
- Renaming stored properties without a formal migration plan
- Changing relationships or delete rules
- Changing uniqueness assumptions or identifiers
- Replacing one store location/name strategy with another

## Required Review Before Merging

For any persisted model change, confirm all of the following:

1. Can an existing install open its current store without reset?
2. Can old records still be decoded and shown in the UI?
3. Do new properties have safe defaults or optional storage?
4. Does saving an old record after editing still work?
5. Have export, repository, and view model paths been checked for nil-safe behavior?

## Current Persistence Strategy

- Canonical store: `Factureclick.store`
- Legacy compatibility store: `Factureclick-v2.store`
- Existing stores are opened non-destructively
- No silent deletion of persistent files
- No automatic fallback that discards user data

## When a Bigger Change Is Needed

If a feature requires incompatible model changes, do not patch around it with a reset. Introduce an explicit migration strategy first. That may mean:

- redesigning the storage shape
- splitting data into a new model
- or moving to a formal `VersionedSchema` and `SchemaMigrationPlan`

## Release Discipline

- Model changes should be reviewed with migration impact in mind before coding starts.
- Persistence fixes should preserve existing stores whenever possible.
- Temporary development recovery logic must stay clearly separated from production behavior.
