# banana-claude — Research Notes

**Source:** https://github.com/AgriciDaniel/banana-claude  
**Reviewed:** 2026-05-04  
**Reviewed by:** Swarm  

---

## What is banana-claude

A Claude Code skill/plugin that turns Claude into a Creative Director for image generation using Google Gemini Flash image models.

Key idea: Claude interprets user intent, selects domain expertise, constructs optimized prompts using a 5-component formula, and orchestrates Gemini for image generation.

---

## What we took from it

### 1. 5-Component Prompt Formula
This is the most directly applicable pattern for Hbtech.Vision.

Formula:
```
Subject + Action + Location/Context + Composition + Style
```

Applied to architectural rendering:
- **Subject** — building type, key physical details, facade elements
- **Action** — lighting condition, time of day, weather, atmosphere
- **Location/Context** — surroundings, landscape, environment, site context
- **Composition** — camera angle, focal length, framing, perspective
- **Style** — materials, visual style, reference aesthetic, finish quality

This structure is now adopted in `planning/API-CONTRACT-DRAFT.md` as the standard for the `prompt` field.

### 2. Domain Modes
The idea of selecting a "domain expertise mode" per request is useful.

For Hbtech.Vision we adapted this as `domain_mode`:
- `exterior_day`
- `exterior_evening`
- `exterior_overcast`
- `interior`
- `aerial`
- `detail_facade`

This is now an optional field in the API contract.

### 3. Session Consistency
The concept of maintaining style/character consistency across multi-turn generation sessions is relevant for iterative client approval workflows.

This is noted as a future feature consideration, not MVP-1 scope.

### 4. Cost Tracking per Request
The pattern of logging cost per generation request is practical.

Our `metrics` block in the response contract already includes `estimated_cost_usd`. This confirms the pattern is correct.

### 5. Batch Variations
Generating N variations of one request is useful for preview-mode exploration.

Noted as a future `options.batch_count` field, not MVP-1 scope.

---

## What we did NOT take from it

### Gemini Flash image as render core
banana-claude uses Gemini text-to-image generation.

This does NOT work for our primary use case because:
- Gemini Flash image generation does not accept depth maps or control images
- It does not preserve building geometry reliably
- It is not a geometry-controlled pipeline

Our render core requires ControlNet-based geometry control.
Gemini image generation may be used as an optional fast concept sketch layer only.

See `planning/DECISIONS.md` ADR-009 for the formal decision.

### Claude Code plugin architecture
banana-claude is a developer IDE tool, not a serverless production endpoint.

Our architecture requires a serverless API endpoint that accepts control images and returns render artifacts. These are different classes of tools.

---

## Summary

| Pattern | Adopted | Notes |
|---------|---------|-------|
| 5-component prompt formula | ✅ Yes | Added to API contract |
| Domain modes | ✅ Yes | Added as optional field |
| Session consistency | 🔜 Later | Future feature |
| Cost tracking per request | ✅ Confirmed | Already in response contract |
| Batch variations | 🔜 Later | Future option |
| Gemini as render core | ❌ No | No geometry control |
| Claude Code plugin pattern | ❌ No | Wrong class of tool |
| Gemini as fast concept layer | ✅ Optional | ADR-009 |
