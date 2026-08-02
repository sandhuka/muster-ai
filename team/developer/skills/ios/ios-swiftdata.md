# iOS SwiftData & Persistence

## Purpose
Define SwiftData model definitions, queries, predicates, migrations, and persistence patterns for iOS development. Use SwiftData. Do not use Core Data. See the `ios-best-practices` skill for the repository pattern and dual-backend architecture. See Developer's `ios-testing` skill for in-memory testing patterns.

## Model Definitions
- Use `@Model` macro for all persistent types
- Keep models as plain data containers — business logic belongs in ViewModels or services
- All models should conform to `Identifiable` with a stable UUID
- Property name `description` is disallowed in `@Model` classes
- Property observers (`willSet`/`didSet`) on `@Model` classes are silently ignored — do not use
- Enum properties must conform to `Codable`. Enums with associated values ARE supported

## Relationships
- Use `@Relationship` on **one side only** — placing it on both sides causes a circular reference
- Always specify an explicit inverse: `@Relationship(deleteRule: .cascade, inverse: \Sight.destination)`
- Always specify an explicit delete rule. Default is `.nullify` which sets the reference to nil — this can orphan objects or crash if the property is non-optional. `.cascade` is most common
- SwiftData frequently gets inverse relationships wrong — always be explicit

## Attributes
- `@Attribute(.externalStorage)` is a suggestion, not a requirement — only applies to `Data` properties, SwiftData decides actual storage
- `@Transient` properties are not persisted and must have a default value. They reset to the default on every fetch. Prefer computed properties for derived data — use `@Transient` only if the computation is expensive
- `#Unique` — only one per model. Multiple constraints go in a single macro: `#Unique<Foo>([\.email], [\.username])`

## Saving
- Autosave timing is unpredictable — prefer explicit `modelContext.save()` when correctness matters
- No need to check `modelContext.hasChanges` before saving — just call `save()` directly

## Concurrency
- `ModelContext` and model instances must **never** cross actor boundaries — they are not sendable
- `ModelContainer` and persistent identifiers ARE sendable
- To transfer a model across actors: send its `persistentModelID`, then re-fetch in the destination context
- Persistent identifiers are temporary before first save (start with lowercase "t") — save before relying on an ID

## Schema Strategy
- Keep schema additive — add nullable columns for future features rather than requiring destructive migrations
- Always have an explicit migration schema (`VersionedSchema` + `SchemaMigrationPlan`), even for lightweight migrations
- Test migrations with production-like data before release

## Queries
- `@Query` only works inside SwiftUI views — never use it in classes, ViewModels, or services
- Use `ModelContext.fetch()` with `FetchDescriptor` in ViewModels and services for one-shot queries
- Use `#Predicate` for type-safe filtering
- `ModelContext.fetchCount()` for counts — note: does not live-update unless something else triggers it (e.g., `@Query`)
- Sort and limit at the query level, not in Swift after fetching

## FetchDescriptor Optimization
- Set `propertiesToFetch` to load only the properties you need (fetches all by default)
- Set `relationshipKeyPathsForPrefetching` when you know certain relationships will be used — avoids lazy-load overhead

## Predicates
Predicates support only a subset of Swift. Some unsupported operations won't compile; others **compile but crash at runtime**.

**Safe operations:**
- String matching: always use `localizedStandardContains()` — not `lowercased().contains()`
- Prefix matching: use `starts(with:)` — `hasPrefix()` is not supported
- Empty check: `!collection.isEmpty` — safe

**Unsupported (won't compile):**
- `String.hasSuffix()`, `String.lowercased()`
- `Sequence.map()`, `Sequence.reduce()`, `Sequence.count(where:)`
- `Collection.first`
- Custom operators

**Dangerous (compiles but crashes at runtime):**
- `collection.isEmpty == false` — use `!collection.isEmpty` instead
- Computed properties in predicates
- `@Transient` properties in predicates
- Custom `Codable` structs in predicates
- Regular expressions in predicates
- Any predicate referencing data not stored as `@Model` properties

## Indexing
- `#Index<Model>` speeds up queries at a small write cost — avoid for write-heavy/read-rare data
- Single property indexes: `#Index<Article>([\.type], [\.author])`
- Compound indexes for properties queried together: `#Index<Article>([\.type, \.author])`
- Place inside the model class

## CloudKit
**Only applies if the project uses SwiftData with CloudKit.**
- Never use `@Attribute(.unique)` or `#Unique` — not supported, breaks local data too
- All model properties must have default values or be marked optional
- All relationships must be optional
- Indexes and subclasses are supported (with correct OS)
- Design for eventual consistency — code must function with unsynced data

## Class Inheritance
- Both parent and child classes must use the `@Model` macro
- Must list parent AND child classes explicitly in `ModelContainer` schema — SwiftData does not infer the connection
- Relationships to a parent class can contain any subclass instance
- `@Query` on a subclass returns only that type; on the parent returns all subclasses
- Filter subclasses in predicates with `is`: `#Predicate<Article> { $0 is Tutorial }`
- Typecasting in predicates works: `if let tutorial = article as? Tutorial { tutorial.difficulty < 3 }`
- Prefer protocols over subclassing when simpler — inheritance is not always the right tool
- Avoid deep subclass hierarchies — increases migration complexity

## ModelContainer Setup
- Configure `ModelContainer` at app launch in the `App` struct
- Inject via `.modelContainer()` modifier — available to all descendant views
- For hybrid local/cloud architectures, the local container can serve as offline cache

For local-to-cloud migration patterns, see the `ios-best-practices` skill (Hybrid Local/Cloud Architecture).

## Testing
- Use in-memory `ModelContainer` for all persistence tests — fast, isolated, no disk cleanup
- Create via `ModelContainer(for: Model.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))`
- Test repository protocol implementations against in-memory containers
- Test migration paths by creating data with the old schema, running migration, verifying results

## Principles

1. **Additive schema, always**: Never require destructive migrations for new features. Optional columns today save migration headaches tomorrow. Always have an explicit migration schema in place.

2. **Query at the database level**: Filter, sort, and limit in `FetchDescriptor` — not in Swift after fetching all rows. Use `propertiesToFetch` and `relationshipKeyPathsForPrefetching` to minimize data loaded.

3. **Predicates are limited**: Only use stored `@Model` properties in predicates. Never trust that a predicate compiles means it works — test predicate queries explicitly. `isEmpty == false` will crash; `!isEmpty` won't.

4. **Models don't cross boundaries**: Never pass `ModelContext` or model instances across actors. Send persistent identifiers and re-fetch. Save before relying on any ID.
