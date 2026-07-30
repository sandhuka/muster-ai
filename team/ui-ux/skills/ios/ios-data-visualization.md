# iOS Data Visualization

## Purpose
Define how to design charts, trends, streaks, and progress views for the product — following Apple Health's philosophy of calm, insight-led data presentation. Data visualization in a fitness app serves reflection and motivation, not dashboard vanity. Every chart must answer a question the user actually has, not just display data because it exists. Read this skill when designing Progress (F-TRK-1/2), streak displays, history views, weekly volume trends, Plan tab rationale, or any screen where health/fitness data needs to be understood at a glance. See the `ios-content-hierarchy` skill for deciding which data gets emphasis. See the `accessibility` skill for VoiceOver requirements on data elements.

## Apple Health-Style Chart Philosophy
Apple Health is the gold standard for fitness data visualization. Study what it does:

1. **Minimal ink** — No gridlines, no background fills, no 3D effects, no gradients on bars. The data itself is the only visual element that uses color or weight. Everything else is barely there.
2. **Strong labeling** — Axes are labeled with plain language ("This Week", "Average: 23 min"), not raw numbers. The user should understand the chart without studying the axes.
3. **Calm density** — Apple shows less data at a time than most fitness apps. A weekly view shows 7 bars, not 30. A monthly view is a summary, not a dense heatmap. Density increases only on drill-in.
4. **Insight over decoration** — Apple highlights *what changed* ("Up 12% from last week") rather than just showing the raw data. The chart supports the insight; the insight is the hero.
5. **Consistent palette** — One accent color per metric. Don't rainbow-code data. Use design system accent colors sparingly — most chart elements should be neutral with one highlighted data point.

## Choosing the Right Visualization

| Data Type | Best Visualization | When to Use | Avoid |
|-----------|--------------------|-------------|-------|
| **Session frequency over time** | Vertical bars (daily/weekly) | Progress tab — "How often am I training?" | Line charts (frequency is discrete, not continuous) |
| **Duration trends** | Smooth line chart with area fill | Progress tab — "Am I doing more or less?" | Bar chart (duration is continuous, line shows trend) |
| **Current streak** | Single large number + supporting text | Today screen, Progress header | Ring/gauge (streaks are simple counts, not percentages) |
| **Weekly plan overview** | Calendar row (7 day cells) | Plan tab — horizontal week view | Dense monthly calendar for weekly planning |
| **Session history** | Calendar heatmap (month view) | Progress tab — "Which days did I train?" | List (too long), line chart (too abstract) |
| **Discipline balance** | Horizontal stacked bar or simple proportion | Progress detail — "Am I doing enough yoga?" | Pie chart (hard to read on mobile, Apple never uses them) |
| **Volume per muscle group** | Horizontal bar chart | Progress detail (premium) | Radar/spider chart (looks cool, communicates poorly) |
| **Goal progress** | Ring or linear progress bar | If the product adds goal tracking | Multiple competing rings (Activity app does this well, but one ring is clearer than three) |
| **Single metric change** | Plain text with delta | Anywhere — "23 min avg ↑12%" | Chart (don't chart when a sentence suffices) |

### The Plain Text Rule
If the data can be communicated in one sentence, use text — not a chart. "You worked out 4 times this week, up from 3 last week" is clearer than a bar chart with 2 bars. Charts earn their space only when they reveal patterns that text cannot.

## Temporal Fitness Data Patterns

### Streaks
- **Display**: Single large number ("12 day streak") with supporting context ("Your longest: 18 days")
- **Visual**: The number is the hero. No flame icons, no animations, no escalating visual urgency. Keep the tone calm.
- **Broken streak**: Show gracefully. "Last active: 2 days ago. Start a new streak today." Never: "You lost your 12-day streak!"
- **Rest days in streaks**: Rest days DO NOT break streaks if the Plan prescribed rest. "12 day streak (includes 2 rest days)" — the algorithm told them to rest, don't punish it.

### Session Frequency
- Default view: current week (7 vertical bars, one per day)
- Each bar represents total session minutes for that day
- Today's bar is highlighted with the design system accent color; past days are neutral; future days are empty/dotted
- Tap a bar → sheet with that day's session summary

### Duration Trends
- Default view: past 4 weeks, line chart
- Y-axis: minutes. Labeled with "min" suffix, not raw numbers
- X-axis: week labels ("This Week", "Last Week", "2 Weeks Ago", "3 Weeks Ago") — not dates
- Highlight: current week's data point is enlarged and colored
- Average line: subtle dashed horizontal line labeled "Avg: X min"

### Session History Calendar
- Month grid view (Apple Health style)
- Days with sessions: filled dot or colored cell (intensity = shade)
- Days without sessions: empty/neutral
- Today: outlined or highlighted border
- Rest days (plan-prescribed): different indicator than skipped days (subtle icon or lighter fill)
- Tap a day → session detail for that day

## Context and Framing

### Baselines and Comparisons
- Always show a comparison frame: "vs. last week", "vs. your average"
- Use relative language: "Up 15%", "Same as last week", "Down slightly" — not just raw numbers
- Period selector: Week / Month / 3 Months. Default to Week for most users (most actionable timeframe)
- Never compare a partial week to a full week without noting it: "This week (so far)" vs "Last week"

### Delta Display
- Positive change: design system accent color + "↑" arrow. No green (avoid red/green for colorblind users)
- Negative change: neutral/secondary color + "↓" arrow. Never red (red = error in our system, not decline)
- No change: "—" or "Same as last week" in secondary text
- Frame all deltas as informational, not judgmental. "↓ 10%" is a data point, not a failure.

### Avoiding Misleading Visualizations
- Y-axis always starts at 0 for bar charts (don't truncate to exaggerate differences)
- Line charts may start above 0 if the data range is narrow (e.g., 20-30 min) — but label the axis clearly
- Don't show trend lines on < 3 data points — it's noise, not a trend
- Week 1 users: show their data without comparison frames. "Your first week!" not "↓100% from last week" (there was no last week)

## Chart Accessibility and Narration

### VoiceOver Requirements
Every chart must have a complete text alternative that conveys the same insight:

```
.accessibilityLabel("Session frequency this week.
Monday: 25 minutes. Tuesday: rest day. Wednesday: 18 minutes.
Thursday: 30 minutes. Friday through Sunday: not yet completed.
Average this week: 24 minutes, up from 20 minutes last week.")
```

### Rules
- The accessibility label tells the story, not just the data. Include the insight ("up from 20 minutes last week").
- Group chart + title + subtitle as one accessibility element (`.accessibilityElement(children: .combine)`)
- For interactive charts (tap to see day detail): each data point should be individually accessible via VoiceOver swipe
- For trend lines: describe the trend direction ("trending upward over 4 weeks") not individual data points

### Non-Visual Summaries
Below or above every chart, include a 1-line text summary of the key insight. This helps all users (not just VoiceOver) and ensures the chart has a clear point:
- "4 sessions this week — your most active week yet."
- "Average session length: 22 min, consistent over the past month."

This text summary IS the chart's justification for existing. If you can't write the summary, the chart isn't communicating anything.

## Empty, Sparse, and Noisy Data States

### New User (0-2 sessions)
- Don't show charts. Show the single metric that exists: "1 session completed. Keep going!"
- No empty chart frames with zero bars — that feels discouraging
- Threshold to show charts: minimum 3 data points (3 sessions or 3 days with data)
- Before threshold: text-only progress summary

### Early User (3-7 sessions)
- Show simple charts (weekly frequency bars) but without comparisons or trend lines
- Label: "Your first week" or "Building your baseline" — frame as beginning, not judgment
- No "vs. last week" until there IS a last week

### Sparse/Inconsistent User
- Gaps in data are normal. Don't fill gaps with zeros — leave them visually empty
- Calendar heatmap: empty days are just empty, not highlighted as "missed"
- If user had a 2-week gap: show data before and after without comment. No "You were away for 14 days" banner.

### Offline/Partial Sync (Premium)
- If some data hasn't synced: show available data with a subtle "Syncing..." indicator
- Never show partial data as complete. Label: "Last synced: 2 hours ago" if stale

## Motivation Without Pressure
The product's brand tone extends to data visualization. The Progress tab should feel like a knowledgeable guide reviewing your log — informed, encouraging, never shaming.

### Do
- Frame positively: "4 sessions this week" not "3 days missed"
- Celebrate consistency: "You've trained every Monday for a month"
- Acknowledge effort: "22 minutes today. Every session counts."
- Normalize rest: "Rest day — your muscles are recovering" (when plan prescribes rest)
- Show personal bests naturally: "Your longest streak: 18 days" (as a reference point, not a pressure)

### Don't
- Guilt-trip: "You haven't trained in 3 days!" or "Don't break your streak!"
- Negative framing: "0 of 5 sessions completed this week"
- Punishing colors: red for missed days, fading/graying out for inactivity
- Loss aversion: "Your streak will reset tomorrow!" — manipulative, not coaching
- Social comparison: "Users like you average 5 sessions/week" — keep the experience personal, not competitive

### The Duolingo Anti-Pattern
Duolingo weaponizes streaks — guilt owl, fire icons, "Don't lose your streak!" push notifications. This drives engagement through anxiety, not value. Your product's streak display should be purely informational: a number, a personal best, and a calm acknowledgment. If the streak breaks, the number resets without fanfare. The user's progress (total sessions, strength gains, consistency trends) is permanent — streaks are just one lens.

## Annotation and Insight Patterns

### Milestone Badges
- Triggered at meaningful thresholds: 10th session, 30-day streak, first month complete
- Display: small badge/chip on the relevant chart point, not a full-screen takeover
- Tappable to see detail: "30 sessions completed — you're building a real habit"
- Keep rare and meaningful. If everything is a milestone, nothing is.

### Algorithmic Summaries (Premium)
- On Progress tab: 1-2 sentences from the algorithm about their training pattern
- Example: "Your upper body is 20% ahead of lower body this month. This week's plan balances that."
- Show as a card above or below the charts — it's an insight, not a chart label
- Must be grounded in their data, not generic advice

### "Why This Matters" Tooltips
- On charts that might confuse: small (i) icon that opens a sheet explaining the metric
- Example: Volume chart → "Volume measures total work (sets × reps × difficulty). Higher volume = more training stimulus."
- Only for non-obvious metrics. Don't explain "Sessions This Week."

## Output Format
When designing data visualization screens, include:

```markdown
## Data Visualization Spec: [Screen/Section Name]

### Chart Selection Rationale
| Data | Visualization | Why This Type | Insight It Communicates |
|------|--------------|---------------|------------------------|
| Weekly frequency | 7 vertical bars | Discrete daily data, easy week-over-week scan | "How often am I training?" |
| ... | ... | ... | ... |

### Text Summary
"[The 1-line insight this chart communicates — serves as VoiceOver label and visible subtitle]"

### Data States
| State | Threshold | What's Shown |
|-------|-----------|-------------|
| Empty (new user) | 0-2 sessions | Text-only: "1 session completed" |
| Early | 3-7 sessions | Simple chart, no comparisons |
| Normal | 8+ sessions | Full chart with comparisons and trends |
| Sparse (gap) | 7+ day gap | Data shown without comment, empty days neutral |

### Accessibility Narration
```
[Full VoiceOver label for the chart]
```

### Tone Check
- [ ] No guilt language
- [ ] No negative framing (missed, failed, lost)
- [ ] Rest days shown as positive/neutral
- [ ] Broken streaks handled gracefully
- [ ] Milestones are rare and meaningful
```
