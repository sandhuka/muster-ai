# iOS System Integration

## Purpose
Define how the product participates in the iOS ecosystem beyond the app itself — notifications, widgets, Live Activities, Shortcuts, HealthKit, share sheets, and deep linking. Apple's best apps feel woven into the OS, not isolated behind an app icon. This skill covers when to extend into system surfaces, what to show there, and how to bring users back into the app gracefully. Read this skill when designing any feature that touches notifications, widgets, Live Activities, Shortcuts, HealthKit permissions, or deep links. See the `ios-hig-reference` skill for in-app platform conventions. See the `ios-onboarding-psychology` skill for permission timing rules.

## When to Extend vs. Stay Inside the App
Not every feature should become a widget or notification. Apply this filter:

| Extend to system surface when... | Stay inside the app when... |
|----------------------------------|---------------------------|
| The user needs the info without opening the app (e.g., daily summary, streak count) | The info requires context that only the full app can provide (e.g., detailed views, progress charts) |
| The action is a single tap (e.g., "Start today's session") | The action requires multiple steps or decisions |
| Timeliness matters (e.g., reminder at their preferred time) | The content is evergreen and can wait |
| It reduces friction for a daily habit (widget tap to core action) | It would be noise at the system level |

**Apple's rule**: System surfaces are for glanceable, timely, actionable content. If it doesn't meet all three criteria, it belongs inside the app.

## Apple Ecosystem Fit
System integrations must feel like they were built by Apple, not bolted on by a third party:

- **Use system APIs as designed** — Don't abuse notifications as marketing channels. Don't cram interactive UI into widgets. Don't use Live Activities for static content.
- **Match system visual language** — Widgets use SF Symbols, system fonts, and standard widget layouts. Notifications use system formatting. Don't brand these surfaces heavily.
- **Respect user control** — Every notification category must be independently disableable. Widgets are opt-in. Shortcuts are user-initiated. Never force a system surface on the user.
- **Graceful degradation** — If the user denies notification permission, the app works perfectly without it. Widgets are a convenience, not a requirement.

## Notification UX Methodology

### Defining Notification Categories
For each notification category in your product, define:

| Column | Description |
|--------|-------------|
| **Category** | A short name for the notification type |
| **Content** | The message template — what the user sees |
| **Timing** | When the notification fires (user-set time, event-driven, etc.) |
| **User Value** | Why the user benefits from this notification |
| **Priority** | Default (banner + sound) or Low (silent, notification center only) |

Example category table:

| Category | Content | Timing | User Value | Priority |
|----------|---------|--------|-----------|----------|
| Daily reminder | "[Action] is ready. [Duration] — [details]." | User's preferred time (learned or set) | Trigger daily habit | Default |
| Schedule update (premium) | "Tomorrow: [plan summary]." | Evening before | Plan awareness | Low (informational) |
| Milestone | "[Achievement description]!" | After qualifying event | Motivation/celebration | Default |

### What to Never Send
- Guilt-based re-engagement ("You haven't used the app in X days!")
- Loss aversion manipulation ("Don't lose your streak!")
- Marketing/promotional content — never through push notifications
- Social pressure notifications (unless the product has genuine social features)
- High-frequency notifications — define a maximum per day and enforce it

### Notification Content Hierarchy
```
Title:    [Short, actionable — 4-6 words max]
Subtitle: [Optional — context or personalization]
Body:     [1 sentence — what they'll do and how long]
```

Example:
```
Title:    Your [session type] is ready
Subtitle: [Category] • [Duration]
Body:     [Personalized detail]. Tap to start.
```

### Notification Actions
| Action | Label | Behavior |
|--------|-------|----------|
| **Default tap** | (open app) | Deep link to main screen with content loaded |
| **Primary action** | "[Action verb]" | Deep link directly into the core experience |
| **Snooze** | "Later" | Reschedule notification +1 hour. Maximum 2 snoozes, then no more for today. |

### Notification Timing Intelligence
- Default: 8:00 AM local time
- After 2+ weeks of usage: shift to user's actual usage time +/- 30 min
- Never send between 10 PM and 7 AM unless the user consistently uses the app at those times
- If the user already completed today's action: suppress the reminder

## Widget Design Rules

### Defining Widget Types
For each widget, define size, content, and tap destination. Common patterns:

| Widget Pattern | Size | Content | Tap Destination |
|----------------|------|---------|----------------|
| **Daily summary** | Small (systemSmall) | Key metric + duration/count | Main screen |
| **Daily summary** | Medium (systemMedium) | Expanded summary: item names, duration, CTA affordance | Main screen |
| **Streak/counter** | Small (systemSmall) | Streak number + label. Simple. | Progress/history |
| **Week overview** | Medium (systemMedium) | 7-day mini chart, current day highlighted | Progress/history |

### Widget Design Principles
- **Glanceable** — The user should understand the widget in < 2 seconds without reading
- **Fresh** — Widget content must reflect current state, not stale data. Use `TimelineProvider` with appropriate refresh cadence (every 4 hours or on significant data change)
- **Minimal branding** — Small logo or wordmark only. The content IS the brand. Don't waste widget space on logos.
- **System-native feel** — Use SF Symbols, system fonts (SF Pro), and WidgetKit standard layouts. Custom fonts and brand colors are acceptable but should feel at home on the Home Screen
- **Dark mode** — Widgets must look correct in both modes. Use semantic colors or design system tokens that adapt.
- **Lock Screen variants** — iOS 16+ Lock Screen widgets: even simpler. One key metric. Circular or rectangular accessory format.

### Widget Don'ts
- Don't show "Upgrade to Premium" in a widget — that's not glanceable, timely, or actionable
- Don't show notifications/alerts in widgets — that's what notifications are for
- Don't require sign-in state to show useful content — free tier widgets should work fully
- Don't update every minute — respect battery life. Widget data doesn't change that often.

## Live Activities

### When to Use
Live Activity is appropriate **only during a time-bound, real-time activity** within your product (e.g., an active session, a timed event, a delivery in progress).

### Live Activity Content Template
| Area | Content |
|------|---------|
| **Compact (Lock Screen)** | Current item name + time remaining or count |
| **Expanded (Lock Screen)** | Current item name + thumbnail (static) + timer + "Next: [item name]" |
| **Dynamic Island (compact)** | Timer countdown only |
| **Dynamic Island (expanded)** | Current item name + timer + progress (e.g., 3/8) |

### Live Activity Rules
- Start: when user begins the time-bound activity
- Update: on each state transition, pause/resume
- End: when activity completes or user cancels
- Tap: deep link back to the active screen (resume in progress)
- Don't show Live Activity for sub-states shorter than 15 seconds (too brief to be useful)

## Siri and Shortcuts

### Defining Shortcut Actions
For each shortcut action, define:

| Column | Description |
|--------|-------------|
| **Action** | Name of the shortcut |
| **Phrase** | What the user says to Siri |
| **What It Does** | App behavior on invocation |
| **Parameters** | Any configurable inputs |

Example:

| Action | Phrase | What It Does | Parameters |
|--------|--------|-------------|-----------|
| **Start session** | "Start my session" | Opens app into core experience with today's content | None |
| **Show today's plan** | "What's my plan today?" | Opens app to main screen | None |

### Shortcut Design Rules
- Donate shortcuts after the user has performed the action at least twice (don't donate on first use)
- Use `INRelevantShortcut` to suggest actions at the user's typical usage time
- Shortcut results should include a visual snippet (key metrics) when possible
- Siri responses should be brief: "Today's [content summary]. Opening [Product Name]."

### App Intents (iOS 16+)
- Implement as `AppIntent` for modern Shortcuts integration
- Expose intents matching your core actions
- Parameterize where useful (e.g., category filter for "Start a [type] session")

## Health and Permission Touchpoints

### HealthKit Integration Methodology
When your product integrates with HealthKit, define each data type:

| Column | Description |
|--------|-------------|
| **Data** | The HealthKit data type |
| **Read/Write** | Direction of data flow |
| **Purpose** | How your product uses this data |
| **Permission Prompt Framing** | How to explain the request to the user |

Example:

| Data | Read/Write | Purpose | Permission Prompt Framing |
|------|-----------|---------|--------------------------|
| **Active Energy** | Read | Factor into algorithm calculations | "See your daily activity to improve recommendations" |
| **HKWorkout** | Write | Log sessions to Health | "Save your sessions to your Health record" |
| **Heart Rate** | Read (if Apple Watch) | Intensity calibration | "Use heart rate to calibrate intensity" |

### Permission Request Design
- Each HealthKit permission has its own system prompt — you can't customize it
- Design a **pre-permission screen** (shown before the system dialog) that explains:
  - What data you're requesting
  - What the product will do with it (specific, not vague)
  - What happens if they decline (app still works, this feature is just enhanced)
- See `ios-onboarding-psychology.md` for permission timing rules — never ask during onboarding

### Motion & Fitness Permission
- Required for step count and activity data
- Pre-permission: "[Product Name] uses motion data to understand your daily activity level. This helps improve recommendations based on your overall activity."
- If declined: suppress features that depend on it, show a Settings deep link if user later wants to enable

## Deep Linking and Continuity

### Deep Link Destination Template
For each entry point, define target and fallback:

| Source | Target | App State Required |
|--------|--------|-------------------|
| Daily reminder notification | Main screen with content loaded | Content must be pre-generated |
| Primary notification action | Core experience screen | Content ready, session prepared |
| Summary widget tap | Main screen | Standard app state |
| Streak widget tap | Progress/history tab | Standard app state |
| Live Activity tap | Active session (resume) | Session must still be in progress |
| Shortcut invocation | Core experience | Generate content if needed, then start |
| Settings app link | App root (default tab) | Standard app state |

### Deep Link Rules
- Every deep link must handle the case where the target state isn't available: content not ready yet, show main screen with loading; session ended, show main screen with completion summary
- Deep links should never bypass onboarding — if the user hasn't completed onboarding, land them there
- Use `NSUserActivity` for Handoff if multi-device support is added
- Universal links for any future sharing features (share content link that opens in-app or App Store)

## System Settings and Account Surfaces

### In-App Settings That Link to System
| Setting | In-App Location | System Destination |
|---------|----------------|-------------------|
| Notification preferences | Settings > Notifications | If user wants granular control, link to system Settings |
| Health permissions | Settings > Health | Deep link to Health app's Sources > [Product Name] |
| Subscription management | Settings > Subscription | Link to Apple's subscription management (`itms-apps://`) |

### Subscription Management (Apple's Rules)
- Apple requires: if you offer subscriptions, you must link to Apple's subscription management
- Show subscription status in Settings: plan name, renewal date, "Manage Subscription" link
- Don't build custom cancellation flows — link to Apple's system
- After cancellation: show when premium access expires, what will change (graceful downgrade)

## Output Format
When designing a system integration feature, produce:

```markdown
## System Integration Spec: [Feature Name]

### Surface
[Notification / Widget / Live Activity / Shortcut / HealthKit / Deep Link]

### Trigger
[What causes this to appear or become available]

### Content
| Element | Value | Notes |
|---------|-------|-------|
| Title | "..." | |
| Body | "..." | |
| Visual | [icon/thumbnail] | |

### User Action → Destination
| Action | Destination | Fallback (if target unavailable) |
|--------|------------|--------------------------------|
| Tap | [screen] | [fallback screen] |
| ... | ... | ... |

### Permission Dependency
| Permission | Required? | Pre-prompt copy | Fallback if denied |
|-----------|-----------|----------------|-------------------|
| [permission] | [yes/no] | "..." | [degraded experience description] |

### Timing/Frequency Rules
[When it appears, how often, suppression rules]
```
