# Retention & Lifecycle Marketing

## Purpose
Post-install retention strategy: trigger architecture for push/email/in-app messaging, gamification design, churn prevention, and win-back. Marketing owns WHEN and WHY to message users; Content agent owns the COPY (`team/content/skills/notification-copy.md`, `team/content/skills/email-sequences.md`, `team/content/skills/subscription-copy.md`). See `team/marketing/skills/analytics.md` for retention metrics and cohort analysis.

## The Habit Loop
The product's retention depends on building a daily habit:
1. **Cue**: Push notification or time-of-day habit
2. **Routine**: Open app → see today's routine → complete session
3. **Reward**: Completion feeling, streak progress, algorithm improving
4. **Investment**: Each routine makes the algorithm smarter → higher switching cost

**Time-to-value target**: 70%+ of users who start onboarding should complete their first routine in the same session (<10 min total).

## Push Notification Strategy
Marketing owns strategy. Content agent owns copy. Developer implements.

**Permission timing**: Request AFTER first completed routine (60%+ grant rate vs. 30-40% during onboarding).

### Notification Types

| Type | Trigger | Frequency |
|------|---------|-----------|
| Routine ready | Daily, at user's typical workout time | 1x/day max |
| Streak at risk | No activity by usual time | Triggered |
| Streak milestone | 7, 14, 30, 60, 100 days | Triggered |
| Weekly summary | End of week | 1x/week |
| Win-back | 3+ days inactive | Triggered (see Win-Back) |

### Frequency Rules
- Hard cap: 1 push/day, 5/week
- Quiet hours: no notifications before 7 AM or after 10 PM local time
- Back-off: if user dismisses 3 in a row without opening, reduce to every other day for 2 weeks
- Personalize send time based on user's typical workout time (cold start default: 7:30 AM)
- Never use push to promote premium. Never guilt-trip. If user disables notifications, respect it completely

## Email Lifecycle Strategy
Marketing owns trigger architecture and segmentation. Content agent writes all copy.

### Segmentation

| Dimension | Segments |
|-----------|---------|
| Engagement | Active (3+ sessions/7 days), Cooling (1-2/7 days), Lapsed (0/14 days), Churned (0/30+ days) |
| Subscription | Free, Trial, Premium, Cancelled |

### Trigger Architecture

| Sequence | Trigger | Emails | Handoff to Content |
|----------|---------|--------|-------------------|
| Welcome | Signup | 3 over 7 days | Goal: drive second session, reinforce value |
| Re-engagement | 3/7/14/30 days inactive | 4 escalating touches | Tone: gentle → direct → honest. Stop after 30 days |
| Trial ending | 2 days before trial expires | 1 | Remind of value received |
| Cancellation | Subscription cancelled | 1 + survey | "Sorry to see you go" + feedback collection |
| Win-back post-cancel | 14 days after cancel | 1 | "Here's what's new" |

### Frequency Rules
- Active: max 2/week. Cooling: max 1/week. Lapsed: max 2/month. Churned: stop after 3 months of no opens
- Unsubscribe rate target: <0.5% per send

## In-App Messaging Strategy
Surface premium value at natural moments. Never interrupt the core experience.

| Trigger | Timing |
|---------|--------|
| After completing routine | After 3rd+ routine: preview weekly plan |
| Viewing Plan tab (free) | Sample plan with upgrade overlay |
| After 1 week of use | "Your history unlocks smarter planning" |
| Hitting free intelligence limit | After 2nd weekly smart routine |

For upgrade prompt copy, see Content agent's `team/content/skills/subscription-copy.md`. Feature discovery should be progressive — introduce premium features gradually at moments where the user would benefit.

## Streak & Gamification Design

### Philosophy
**Celebrate consistency. Never punish breaks.** The algorithm adjusts when life happens — streaks should too.

### Rules
- Streak day = 1+ completed routines. Grace period: 1 rest day/week without breaking streak
- If streak breaks: "Start a new streak" (positive), never "You lost your streak" (loss aversion)
- No visible countdown timers. No competitive streaks between users

### Milestones

| Days | Reward |
|------|--------|
| 7 | Streak badge + shareable card |
| 30 | Badge upgrade + premium trial (1 week) for free users |
| 100 | Special achievement + shareable card |
| 365 | Personalized year-in-review |

See `team/marketing/skills/referral-virality.md` for how milestones integrate with sharing.

## Churn Prevention

### Early Warning Signals

| Signal | Intervention |
|--------|-------------|
| Session frequency drops 50%+ week-over-week | In-app: surface shorter routine options |
| Notification opt-out | Email re-engagement sequence |
| No sessions for 3 days | Push: "Your routine is ready when you are" |
| Cancellation initiated | Pre-cancellation survey (below) |

### Pre-Cancellation Flow
1. Survey: "What's not working?" (too expensive / not using enough / features missing / switching / other)
2. Response by answer: "Too expensive" → show annual savings (reframing, not discounting). "Not using enough" → offer shorter routines. "Features missing" → feedback form
3. Always allow easy cancellation. Never a dark pattern. Never offer a discount (devalues product)

## Win-Back Strategy

| Segment | Channel | Message Direction |
|---------|---------|-------------------|
| Cooling (7-13 days) | Push (if opted in) | "Your routine is ready" — not "We miss you" |
| Lapsed (14-29 days) | Email | "Your algorithm trained on X sessions. It's ready to get smarter" |
| Churned (30+ days) | Email (low frequency) | "Here's what's new since you left" |
| Seasonal | All channels | January + September win-back campaigns. See `seasonal-cultural-marketing.md` |

Never guilt. Lead with value. For cancelled subscribers: max 3 win-back emails over 90 days. Never offer a lower price.

## Retention Targets

| Metric | 90-Day | Year 1 |
|--------|--------|--------|
| D1 retention | 40%+ | 45%+ |
| D7 retention | 18%+ | 22%+ |
| D30 retention | 10%+ | 14%+ |
| WAU/MAU | 25%+ | 30%+ |
| Routines/user/week | 2.5+ | 3.0+ |
| Push opt-in | 55%+ | 60%+ |
| Email open rate | 25%+ | 30%+ |