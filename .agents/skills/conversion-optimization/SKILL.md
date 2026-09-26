---
name: conversion-optimization
description: "Conversion rate optimization for pages, forms, signups, onboarding, and paywalls. Use when improving conversion rates. Triggers on \'conversion\', \'CRO\', \'signup flow\', \'onboarding\', \'paywall optimization\'."
---

# Conversion Optimization

Unified CRO skill covering all conversion touchpoints.

## Operating Loop

1. Name one conversion event and its denominator, then record a baseline window and source. Do not claim a lift without those receipts.
2. Inspect the matching surface: message and primary action for a page; fields and errors for a form; account creation and verification for signup; first-value event for onboarding; trigger, frequency, and dismissal for a modal; entitlement, price, and restore path for a paywall.
3. State one testable hypothesis, the intended audience, the primary metric, guardrails, and the minimum observation window before changing the surface.
4. Ship one reversible variant where the project supports experimentation. Otherwise record the change and compare equivalent before/after periods, including material traffic or pricing changes.
5. Keep, revise, or revert from the measured result. Record the decision and evidence; a winning variant in one audience is not a universal rule.

## When NOT to Use

- Not for traffic acquisition (SEO, ads) — optimizes existing traffic conversion
- Not for product feature development — UX/UI conversion surface optimization
- Not for backend performance — frontend conversion touchpoints only
- Not for brand awareness campaigns — direct response conversion metrics

## Related Skills

- `ab-test-spec` — experiment design and measurement contract
- `direct-response-copy` — page and offer copy
- `research` — current audience and market evidence
- `brand-voice` — approved messaging constraints

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

Read, Grep, Glob
