# Design Specs
<!-- Feature-specific design specifications. UI/UX agent produces; Developer agent consumes. -->
<!-- PM coordinates: UI/UX creates spec → Content applies copy → Developer implements. -->

## Naming Convention
- Feature specs: `f-[feature-id]-[name].md` (e.g., `f-onb-onboarding-flow.md`, `f-ply-workout-session.md`)
- Structural specs: descriptive name (e.g., `navigation-structure.md`)
- Feature IDs should match the IDs in `product-spec.md` Section 3 (MVP Features)

## Spec Structure
Each design spec should include:

1. **Metadata**: Sprint/wave, author (UI/UX agent), date, status (draft/final), priority
2. **Content Hierarchy Map**: Ranked list of information by importance (what the user needs to see first)
3. **States**: All possible states for the screen (loading, ready, empty, error, edge cases)
4. **Wireframe**: Text-based layout with annotation numbers for each element
5. **Annotations**: Table mapping annotation numbers to: element name, component (library component or `needs-component: Name`), content source, interaction behavior
6. **Copy**: Final copy applied by Content agent (with Content agent's session reference)
7. **Component Requests Summary**: Which components are available vs. need to be built

## Workflow
1. UI/UX agent creates spec using wireframe methodology skill
2. Content agent applies copy to the spec
3. Developer agent implements from the spec
4. QA agent validates against the spec
