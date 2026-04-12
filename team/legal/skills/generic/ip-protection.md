# Intellectual Property Protection

## Purpose
Guide intellectual property strategy — trademarks, copyrights, AI-generated content ownership, open-source compliance, and trade secrets. See `team/legal/skills/terms-privacy.md` for IP clauses in the ToS. See `team/legal/skills/compliance.md` for platform IP rules.

## Trademark

### Registration Strategy
- Search USPTO TESS database before finalizing any brand name, tagline, or character name
- Relevant international classes for fitness software: Class 9 (software), Class 41 (fitness/education services), Class 42 (SaaS)
- File trademark application in primary markets before public launch or marketing spend
- Use ™ before registration, ® after

### Character Names & Brand Assets
- Character names used in marketing (not just in-app) should be trademarked if they become part of brand identity
- File character names under Class 41 (entertainment/fitness services) alongside the app name
- Document character visual designs with dated records (creation files, git commits) to establish prior art

## Copyright

### Original Content
- All original content (app copy, marketing, documentation, exercise metadata) is automatically copyrighted upon creation
- Register copyright for high-value creative works only if enforcement is anticipated (optional but strengthens claims)

### Third-Party Content
- Verify licenses for all images, fonts, icons, and audio before use
- Creative Commons: verify specific license terms (NC, SA, ND restrictions) — not all CC licenses allow commercial use
- Maintain a `THIRD_PARTY_LICENSES` file in the codebase, updated with each dependency change

## AI-Generated Content IP

### Ownership Landscape (Evolving)
- **US Copyright Office (current position)**: Works generated entirely by AI without human creative control are not copyrightable. Works with sufficient human authorship in the selection, arrangement, or modification of AI output may qualify.
- **Practical implication**: Maximize human creative direction in the pipeline — prompt design, pose selection, animation refinement, character design decisions. Document the human creative process.
- **International variance**: EU, UK, and other jurisdictions have different stances. Research local rules before expanding to new markets.

### Protecting AI-Generated Assets
- **Documentation**: Maintain records of the human creative process — prompts, selection criteria, refinement steps, design briefs. This evidence supports copyrightability claims.
- **Trade secret layer**: Even if individual assets have weak copyright, the complete library (selection, arrangement, metadata, progression chains) is protectable as a compilation and as trade secrets.
- **ToS licensing**: Grant users a limited, non-exclusive, non-transferable license to view content within the app. Prohibit download, redistribution, screen-recording for sharing, and derivative works.
- **Disclosure**: No legal requirement to disclose AI generation method to end users currently. Monitor evolving regulations (EU AI Act, state-level transparency laws). Consider voluntary disclosure if it supports brand positioning.

### Clone Defense
- Document unique combinations (character designs + exercise metadata + progression chains + algorithm logic) as a defensible moat
- File DMCA takedowns for direct asset theft (screenshots, ripped animations)
- App Store: report clone apps through Apple's IP infringement process

## Open Source Compliance

### License Risk Tiers

| Tier | Licenses | Commercial Use | Action Required |
|------|----------|---------------|-----------------|
| Safe | MIT, Apache 2.0, BSD 2/3-clause | Yes, minimal obligations | Include attribution notice |
| Caution | LGPL | Yes, with conditions | Must allow relinking; no static linking without compliance |
| Avoid | GPL, AGPL | Copyleft obligations | Avoid in proprietary apps unless willing to open-source |

### Process
- Maintain a complete inventory of all dependencies (direct and transitive)
- Include all required attribution notices in the app (Settings > Licenses or equivalent)
- Audit license compatibility before adding any new dependency
- For CocoaPods/SPM: `pod licenses` or manual review of each package's LICENSE file

## Trade Secrets

### What Qualifies
- Proprietary algorithm logic (constraint rules, weighting, recovery calculations)
- Exercise library curation methodology and metadata schema
- AI content generation pipeline (prompts, tools, workflows, refinement process)
- Business processes and agent coordination systems

### Protection Measures
- Use NDAs with any contractors, partners, or beta testers who access proprietary systems
- Limit access to algorithm source code and generation pipeline on a need-to-know basis
- Mark confidential documents clearly
- Solo-founder note: even without employees, protect trade secrets in contractor agreements and platform ToS

## Principles

1. **Document human creativity**: For AI-generated assets, the strength of your IP claim is proportional to the documented human creative input. Build the habit of recording design decisions, not just outputs.
2. **Compilation > individual assets**: A single AI-generated animation may have weak standalone copyright. The curated library — with progression chains, metadata, and arrangement — is a stronger protectable work.
3. **Register what matters most**: Trademark the app name and character names before launch. Copyright registration is optional but valuable for high-stakes enforcement. Prioritize registration over perfection.
