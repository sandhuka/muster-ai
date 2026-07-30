# Mobile Design Patterns

## Purpose
Define generic mobile screen patterns and freemium UX conventions applicable to any product. This file covers reusable patterns only — for platform conventions (navigation, typography, layout), see the `ios-hig-reference` skill. For screen hierarchy decisions, see the `ios-content-hierarchy` skill. For onboarding flow design, see the `ios-onboarding-psychology` skill.

## Screen Types & Templates
Quick reference for which layout pattern fits each screen category:

| Screen Type | Layout Pattern | When to Use |
|-------------|---------------|-------------|
| Dashboard | Card-based, key metrics + quick action | Primary home screen showing today's state and main CTA |
| List/Feed | Scrollable with filters, sort, search | Browsing collections, catalogs, or content libraries |
| Detail | Hero content + actions + related info | Deep-dive into a single item |
| Form/Input | Progressive disclosure, inline validation | Onboarding steps, settings forms, data entry |
| Settings | Grouped list (`.insetGrouped`) with sub-pages | User preferences, account management |
| Calendar | Grid with day cells, tappable for detail | Schedule views, history, planning |

## Freemium UX Patterns
Designing screens that serve both free and premium users in a single codebase:

- **Upgrade banners**: Non-intrusive banner at the top or bottom of a gated section. Show what the feature does, not just that it's locked. E.g., a gated section shows a sample preview with an overlay explaining the benefit of upgrading.
- **Gated features with premium badges**: Use a small badge/icon on features that require premium. Tapping opens a focused upgrade sheet explaining the specific benefit — not a generic paywall
- **Interstitial previews**: After completing a free-tier action, show a preview of what premium adds with a clear dismiss path. Never block the core free experience
- **Degraded vs. hidden**: Prefer showing a degraded/preview version of premium features over hiding them entirely — users should know what they're missing. Hide only when showing would confuse
- **Consistent upgrade entry points**: Every upgrade prompt leads to the same subscription sheet so the user always knows what they're buying
