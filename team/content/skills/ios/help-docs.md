# Help Documentation

## Purpose
Define the methodology for writing help center content — FAQs, how-to articles, troubleshooting guides, and support reply templates. Required for App Store review (Apple expects a support URL) and user self-service. See `team/content/skills/brand-voice.md` for voice consistency. See `team/legal/skills/terms-privacy.md` for legal language that must appear in help content.

## Help Content Types

| Type | Format | When to Write | Example |
|------|--------|--------------|---------|
| FAQ | Question + 2-3 sentence answer | Launch (core set) + each feature release | "How does [Product Name] choose my daily routine?" |
| How-to | Step-by-step with numbered steps | For multi-step user tasks | "How to change your fitness level" |
| Troubleshooting | Problem → cause → fix | When a known issue has a user-side resolution | "My routine isn't loading" |
| Policy | Factual explanation of terms/policies | Launch (required set) | "How to cancel your subscription" |

## FAQ Structure

### Launch FAQ Set (Minimum Viable)
These must exist before App Store submission:

**Product**
- How does [Product Name] build my daily routine?
- What's the difference between free and premium?
- What disciplines does [Product Name] cover?
- Can I use [Product Name] without equipment?

**Account & Subscription**
- How do I subscribe to premium?
- How do I cancel my subscription?
- How do I restore my purchase on a new device?
- How do I delete my account and data?

**Privacy & Data**
- What data does [Product Name] collect?
- Is my data stored on your servers? (two-tier answer: depends on free vs. premium)
- How do I request my data be deleted?

### FAQ Writing Rules
- Question must use the user's language, not product language: "How do I cancel?" not "Subscription termination procedure"
- Answer in 2-3 sentences max. If longer, it's a how-to article, not an FAQ
- Link to the relevant how-to article if the answer involves multiple steps
- Include keywords naturally for search/SEO

## How-To Article Structure

```
# [Task in user's words]

[1-sentence context: when/why you'd do this]

1. [Step with specific UI reference]
2. [Step]
3. [Step]

**Note**: [Edge case or important detail, if any]
```

### Writing Rules
- Title is the task: "How to change your workout preferences" not "Preferences Guide"
- Steps reference specific UI elements: "Tap the gear icon in the top right" not "Go to settings"
- Include the minimum number of steps — don't explain obvious actions ("tap the button that says Continue")
- One article per task — don't combine "how to change equipment" and "how to change fitness level"

## Troubleshooting Article Structure

```
# [Problem in user's words]

**What's happening**: [Brief description of the symptom]

**Try this**:
1. [Most likely fix]
2. [Next most likely fix]
3. [Escalation: contact support]
```

### Writing Rules
- Title is the symptom, not the cause: "My routine isn't loading" not "Network connectivity issues"
- Order fixes from easiest to most involved
- Always end with "Contact us at [email]" as the last resort
- Never assume technical knowledge — "Force close the app" needs "swipe up from the bottom of your screen"

## Support Reply Templates

### Structure
All support replies follow: **Acknowledge → Address → Next step**

### Common Scenarios

**Bug report**:
> Thanks for reporting this. [Specific acknowledgment of what they described]. We're looking into it and will update the app when it's resolved. In the meantime, [workaround if available].

**Feature request**:
> Appreciate the suggestion. [Brief acknowledgment that shows you understand what they want]. We'll keep this in mind as we plan future updates.

**Subscription issue**:
> [Specific acknowledgment]. Subscriptions are managed by Apple — you can check your status in iOS Settings > [Your Name] > Subscriptions. If the issue persists after checking there, reply here and we'll dig deeper.

**Account deletion request**:
> You can delete your account and all data from Settings > Data > Delete Account in the app. This permanently removes everything from our servers. Note: cancel your subscription separately in iOS Settings to avoid future charges.

### Reply Rules
- Response within 24 hours
- Address the specific issue — never send a generic template unmodified
- Intelligent Coach tone — calm, direct, helpful
- Never promise timelines for fixes or features
- Never ask users to do more than 3 steps in a single reply

## Principles

1. **Self-service reduces support load**: Every question answered in the help center is a support email you don't receive. Invest in the launch FAQ set — it pays for itself immediately.
2. **User's words, not yours**: "How do I cancel?" not "Subscription management." Match the language users actually type into search or support emails.
3. **Shortest path to resolution**: Users in help docs are frustrated or confused. Get them to the answer in the fewest words possible. Empathy is shown through speed, not lengthy apologies.
