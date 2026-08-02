# App Store Optimization (ASO) Playbook

## Purpose
Strategic ASO for maximizing organic discovery and conversion on the App Store. Marketing owns keyword research, ranking strategy, testing methodology, and conversion optimization. Content agent owns the actual copy (the `app-store-listing` skill). See `knowledge-base/research/app-store-intel.md` for keyword data.

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

| Cluster | Strategy | Example Pattern |
|---------|----------|-----------------|
| Primary | Terms that describe exactly what your app does — the core action in user language | "[your core action] app," "[daily/weekly] [your activity]," "smart [your category]" |
| Secondary | Broader category terms with high volume — users searching generally | "[your category]," "[activity type] app," "[activity] planner" |
| Long-tail | Lower competition, high relevance — captures specific differentiators | "[combination feature] app," "[specific use case]," "[activity] without [common requirement you eliminate]" |
| Seasonal (rotate) | Capitalize on your category's seasonal search patterns | Identify 3-4 annual peaks in your category and prepare keyword variants for each |
| Competitor (Search Ads only) | Users searching for alternatives — never in organic metadata | Top 3-5 direct competitors by brand name |

**Building your clusters**: Start with how users describe their problem ("I need a [X]"), not how you describe your solution. Mine competitor reviews for the exact language users use — those are your highest-converting keywords.

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

| Position | Purpose | Strategic Direction |
|----------|---------|-------------------|
| 1 | Hook — "what does this app do?" | Show [core screen — the one that communicates your value prop in a single glance] |
| 2 | Differentiate | Show [your most visually distinctive feature — what no competitor's screenshots look like] |
| 3 | Expand value | Show [depth feature — what makes power users stay] |
| 4 | Social proof | Streak/progress visualization or testimonial overlay |
| 5 | Breadth | Show [range of capabilities — communicate that you're more than one thing] |

**Screenshot sequencing principle**: Each screenshot should answer the next question a browsing user would ask. Screenshot 1: "What is this?" → Screenshot 2: "How is it different?" → Screenshot 3: "What else can it do?" → Screenshot 4: "Can I trust it?" → Screenshot 5: "Is it really that comprehensive?"

**Testing**: Use Apple's Product Page Optimization. Test screenshot ORDER first (biggest impact), then individual content. Need ~1K impressions/variant, run 7-14 days.

**Preview video**: 15-30 sec, core loop ([open → primary screen → core action → completion]). First 3 seconds = poster frame. Sound-off design with captions.

## Category & Editorial

- **Primary**: [Your primary App Store category]. **Secondary**: [Adjacent category that broadens discovery]
- **App Store editorial**: Submit 6-8 weeks before desired featuring via App Store Connect. Pitch: design quality, Apple-native tech (SwiftUI, relevant frameworks), unique value proposition, privacy-first approach. Resubmit with every major update

## Conversion Rate Optimization

| Metric | Category Average | Target |
|--------|-----------------|-------------|
| Tap-through (impressions → page views) | Varies | Track trend weekly |
| Conversion (page views → installs) | 3-5% | 5%+ |

**Test priority**: (1) screenshot order, (2) app icon, (3) subtitle, (4) first description line, (5) preview video. Track in App Store Connect Analytics weekly.

## Localization

| Priority | Market | Approach |
|----------|--------|----------|
| 1 | [Primary market] | Full optimization |
| 2 | [English-speaking markets with terminology differences] | Keyword + subtitle localization (spelling/terminology) |
| 3 | [High-growth market with price sensitivity] | Keyword localization + regional pricing |
| 4 | [Top 3 non-English App Store markets relevant to your category] | Keyword-only (translate top 10 keywords per locale) |
| 5 | Full listing translation | Defer until 50K+ users with data showing traffic from that market |

**Prioritization principle**: Localize based on data (App Store Connect → Metrics → Sources), not assumptions. Your category's geographic distribution may surprise you.

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
