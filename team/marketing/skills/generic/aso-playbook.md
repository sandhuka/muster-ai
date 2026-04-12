# App Store Optimization (ASO) Playbook

## Purpose
Strategic ASO for maximizing organic discovery and conversion on the App Store. Marketing owns keyword research, ranking strategy, testing methodology, and conversion optimization. Content agent owns the actual copy (`team/content/skills/app-store-listing.md`). See `knowledge-base/research/app-store-intel.md` for keyword data.

## How the Algorithm Works
Apple's ranking factors (approximate priority):
1. **Download velocity** — recent volume relative to category (most important)
2. **Keyword relevance** — match between query and metadata
3. **Ratings/reviews** — volume, recency, average (see `app-review-ratings.md`)
4. **Engagement** — retention, session frequency, uninstall rate
5. **Conversion rate** — impression-to-install ratio
6. **Update frequency** — regular updates signal active maintenance

Downloads and ratings create a flywheel: more downloads → higher ranking → more impressions → more downloads.

## Keyword Research

### Step 1: Build the Universe (100+ candidates)
Sources: App Store Connect suggested keywords, competitor keyword analysis (AppTweak/Sensor Tower), user language from reviews and support, Research agent's `app-store-intel.md`, Google Trends for seasonal patterns.

### Step 2: Score Each Keyword (1-5 scale)

| Dimension | 1 (Low) | 5 (High) |
|-----------|---------|----------|
| Volume | <10/day | 100+/day |
| Relevance | Tangential | Describes exactly what the product does |
| Competition | Dominated by 3+ apps | Few or weak competitors |
| Current rank | Not ranking | Already top 20 |

**Priority**: (Volume x Relevance) + (Competition_inverse x 2). Focus on 12+/20 scores. High-relevance/low-competition beats high-volume/high-competition.

### Keyword Clusters

| Cluster | Keywords |
|---------|---------|
| Primary | daily workout routine, personalized workout, smart workout app, AI workout, daily fitness |
| Secondary | home workout, bodyweight workout, workout planner, fitness routine, exercise app |
| Long-tail | strength and yoga app, weekly workout planner, adaptive workout, workout without equipment |
| Seasonal (rotate) | Jan: "new year workout," Spring: "summer body workout," Sep: "fall fitness routine" |
| Competitor (Search Ads only) | down dog, fitbod, fiton, freeletics |

## Metadata Strategy
Content agent writes the actual copy. Marketing provides keyword priorities and testing direction.

| Element | Chars | Marketing Input | Content Delivers | Test Cadence |
|---------|-------|----------------|-----------------|-------------|
| Title | 30 | Primary keyword to include | Final copy | Quarterly |
| Subtitle | 30 | Differentiator to highlight | Final copy | Quarterly |
| Keywords | 100 | Scored keyword list, allocation (60% primary, 30% secondary, 10% seasonal) | Field population | Every release |
| Description | 4000 | Value prop priority, above-fold focus | Full copy | As needed |

**Keyword field rules** (relay to Content): no spaces after commas, no duplicates of title/subtitle words, singular form only, no "app" or "free." Update with each release.

Never change title AND subtitle simultaneously — isolate variables for measurement.

## Screenshot & Preview Strategy
Marketing defines strategic direction. Content + UI/UX agents create the actual assets.

| Position | Purpose | Marketing Direction |
|----------|---------|-------------------|
| 1 | Hook — "what does this app do?" | Show Today screen with routine |
| 2 | Differentiate | Active session with 3D exercise animation |
| 3 | Expand value | Weekly plan with recovery indicators |
| 4 | Social proof | Streak/progress or testimonial overlay |
| 5 | Multi-discipline | Yoga + strength + stretching in one frame |

**Testing**: Use Apple's Product Page Optimization. Test screenshot ORDER first (biggest impact), then individual content. Need ~1K impressions/variant, run 7-14 days.

**Preview video**: 15-30 sec, core loop (open → routine → exercise → complete). First 3 seconds = poster frame. Sound-off design with captions.

## Category & Editorial

- **Primary**: Health & Fitness. **Secondary**: Lifestyle
- **App Store editorial**: Submit 6-8 weeks before desired featuring via App Store Connect. Pitch: design quality, Apple-native tech (SwiftUI, HealthKit, Siri), unique value, privacy-first. Resubmit with every major update

## Conversion Rate Optimization

| Metric | Category Average | Target |
|--------|-----------------|-------------|
| Tap-through (impressions → page views) | Varies | Track trend weekly |
| Conversion (page views → installs) | 3-5% | 5%+ |

**Test priority**: (1) screenshot order, (2) app icon, (3) subtitle, (4) first description line, (5) preview video. Track in App Store Connect Analytics weekly.

## Localization

| Priority | Market | Approach |
|----------|--------|----------|
| 1 | US | Full optimization (primary) |
| 2 | UK, Canada, Australia | Keyword + subtitle localization (spelling/terminology) |
| 3 | India | Keyword localization + regional pricing |
| 4 | Germany, Japan, France | Keyword-only (translate top 10 keywords per locale) |
| 5 | Full listing translation | Defer to 50K+ users with data showing traffic from that market |

## Solo Founder Routine

**Monthly (2 hours)**:
1. Review keyword rankings for top 10 keywords (15 min)
2. Compare conversion metrics month-over-month (15 min)
3. Competitor listing scan — changes in screenshots, subtitles (15 min)
4. Identify lowest-performing keywords, research replacements (15 min)
5. Check Product Page Optimization test results (15 min)
6. Review velocity and rating check (15 min)
7. Plan keyword/metadata changes for next release (15 min)

**Quarterly (4 hours)**: Full keyword universe refresh, competitive gap analysis, screenshot creative planning, seasonal rotation, localization review.