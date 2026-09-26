---
name: legal
description: Legal document generation and compliance guidance for indie Apple developers. Covers privacy policies, terms of service, EULAs, GDPR/CCPA/DPDP compliance, and Apple App Store legal requirements. Use when user needs legal documents or compliance guidance.
allowed-tools: [Read, Glob, Grep, AskUserQuestion]
---

# Legal Document Generation & Compliance

Legal document generation and compliance guidance for indie Apple developers. Generate privacy policies, terms of service, and EULAs tailored to your app's data practices and target markets.

## When This Skill Activates

Use this skill when the user:
- Needs a privacy policy for their app
- Needs terms of service or EULA
- Asks about legal compliance for App Store submission
- Mentions GDPR, CCPA, DPDP, or COPPA compliance
- Wants to update legal documents after adding analytics, ads, or tracking
- Asks about Apple's privacy requirements or Privacy Nutrition Labels
- Needs legal document hosting guidance (GitHub Pages, in-app, website)

## How to Use

1. Establish the app, entity, jurisdictions, launch date, data categories, third-party SDKs, retention/deletion behavior, payment model, and target stores.
2. Build a facts table that labels each item as supplied, repository-observed, or unknown. Do not fill unknown facts with defaults.
3. Draft a bounded Markdown template that keeps unknowns as explicit placeholders and maps disclosures to the supplied data practices.
4. For jurisdiction- or date-sensitive requirements, identify the applicable official source and date checked. Do not represent the draft as a compliance determination without qualified legal review.
5. Before publication, have the operator verify every placeholder, store disclosure, consent/deletion flow, and counsel-review requirement against the live product.

## Scope boundaries

- This skill can prepare an intake, draft, and verification checklist. It does not determine legal compliance or replace counsel.
- Consent UI, account deletion, permission priming, and subscription disclosures are project implementation work. Route them to the relevant installed product, privacy, or billing skill only after confirming that skill exists in the active catalog.
