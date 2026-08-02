# Referral & Virality

## Purpose
Word-of-mouth amplification: referral program, viral loops, social sharing hooks. Referral is the only channel with zero marginal cost — if viral coefficient (k) reaches 0.3-0.5, every 2-3 users bring in 1 additional. See the `retention-lifecycle` skill for milestone celebrations that trigger sharing, the `community-building` skill for community-driven word-of-mouth.

## Viral Loop Design
Product-native moments where users are intrinsically motivated to share:

| Moment | Share Content | Why Shareable |
|--------|-------------|--------------|
| [Core action] completion | Summary card ([session details]) | Pride, "look what I did today" |
| Streak milestone (7/30/100) | Streak badge card | Achievement, social proof |
| Weekly summary | Week-in-review card | Reflection, accountability |
| First [core action] | "Just started" card | New beginning energy |
| Year-in-review | Annual summary card | End-of-year sharing trend |

### Share Content Requirements
- Visually appealing, brand-consistent (coordinate with UI/UX agent)
- Show enough to intrigue, not enough to satisfy — drive app download
- Include product branding subtly (user's achievement is the hero)
- Include way to find app (App Store badge or @[your-handle])
- Instagram Stories format (1080x1920). One-tap share via iOS share sheet

### Channel Priority for Sharing
1. iMessage/WhatsApp (most personal, highest conversion)
2. Instagram Stories (widest friend reach)
3. Text/email (direct sharing)

## Referral Program

### Mechanics
- **Reward**: Premium time — not discounts (discounts devalue; premium time creates upgrade behavior)
- **Referrer**: 1 week free premium per successful referral
- **Referee**: 1 week free premium trial (first experience is premium product)
- **Cap**: Max 12 weeks (3 months) from referrals. Prevents gaming
- **"Successful"**: Referee downloads AND completes [activation event] (filters junk referrals)
- **Implementation**: Unique code per user, deep link to App Store, referral dashboard in-app (Developer agent)

### UI Placement
- Settings/Profile: permanent "Invite Friends" with code
- Post-[core action]: subtle "Share with a friend" (not blocking)
- Streak milestones: referral link included with share card
- After NPS 9-10: show referral program immediately
- Never: pop-up modals, "invite X friends to unlock Y" gates

## NPS-Driven Advocacy
- Day 30: NPS survey (0-10)
- Promoters (9-10) → referral prompt
- Passives (7-8) → "What would make it a 10?" feedback
- Detractors (0-6) → feedback/support. Never show referral

## Challenge Features (Product Input)
Marketing defines strategy; Developer implements.

| Feature | Description | When to Build |
|---------|------------|--------------|
| Friend challenges | 1-on-1 consistency challenge (both complete [daily action] for 7 days) | Post-10K users |
| Community challenges | App-wide seasonal events ("[Seasonal theme]: [N actions] in [N days]") | Post-25K users |
| Leaderboards | Opt-in, consistency-based (days active, not performance). Anonymous option | Post-50K users |

## Metrics

| Metric | 6-Month Target | 12-Month Target |
|--------|---------------|----------------|
| Viral coefficient (k) | 0.15-0.2 | 0.3-0.5 |
| Invite rate (% who send 1+ referral) | 5%+ | 10%+ |
| Referral conversion (click → install) | 20%+ | 25%+ |
| Share rate (% of shareable moments → actual share) | 3%+ | 5%+ |

## Implementation Priority
1. **Launch**: Share cards for [core action] completion + streak milestones. iOS share sheet integration
2. **Post-1K**: Referral codes, tracking, reward fulfillment. "Invite Friends" in settings
3. **Post-10K**: Friend challenges, NPS-triggered prompts
4. **Post-25K**: Community challenges, participation counters

## Anti-Patterns
- Never gate features behind referrals
- Never import/spam contacts
- Never fake social proof ("5 friends use [Product Name]" when they don't)
- Never use push to ask for referrals (in-app only, at natural moments)
- Never penalize non-referrers