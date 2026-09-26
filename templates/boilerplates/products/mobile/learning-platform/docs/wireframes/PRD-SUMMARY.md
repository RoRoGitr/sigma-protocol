# Step 5 — Wireframe PRD Summary (Learning Platform)

**Generated:** 2025-12-17  
**Platform:** Mobile (Expo + React Native + NativeWind)  
**Design Direction:** Dark Gradient (Quittr Cosmic + Cal AI Clean)  
**Status:** Ready for implementation in Cursor  

---

## What Step 5 Produced

Step 5 generated **wireframe PRDs** (not production code) for **every screen** from Step 4.

You now have:
- **Flow PRDs**: one per flow (overview, patterns, motion rules)
- **Screen PRDs**: one per screen (ASCII wireframe + motion + states)
- **Wireframe Tracker**: proof of 100% coverage vs Step 4

---

## Where the PRDs Live

- **Tracker (Source of Truth for coverage):** `/docs/prds/flows/WIREFRAME-TRACKER.md`
- **Flow + Screen PRDs:** `/docs/prds/flows/*`

---

## Implementation Workflow (How You Build in Cursor)

### Core idea
You will build a runnable **UI prototype** from these PRDs.  
Backend integrations (Supabase logic, AI pipelines, LiveKit wiring) come later.

### Recommended Cursor flow
1. Open Cursor in your project root: `$HOME/your-project`
2. Start with the **first flow** below (Launch) because it includes the **project bootstrap**
3. Drag the PRD file into Cursor chat and ask:  
   “Implement this PRD screen-by-screen. Keep Dark Gradient tokens and smooth motion.”
4. As you implement each screen, keep the same:
   - typography (Satoshi + Plus Jakarta Sans)
   - gradient + glass tokens
   - motion presets and reduced-motion fallback

---

## Build Order (Recommended)

| Order | Flow | Folder | Why first |
|---:|---|---|---|
| 1 | Launch | `01-launch/` | Boots the project + splash routing gate |
| 2 | Onboarding | `02-onboarding/` | Fast win + activation |
| 3 | Auth | `03-auth/` | Account creation / sign-in |
| 4 | Home | `04-home/` | Daily return loop |
| 5 | Learn | `05-learn/` | Core content UX |
| 6 | Practice | `06-practice/` | Gamified practice loops |
| 7 | AI Tutor | `07-ai-tutor/` | Differentiator UX (mock responses) |
| 8 | Schedule | `08-schedule/` | Booking flow + video room shell |
| 9 | Feed | `09-feed/` | AI Tutor presence |
| 10 | Profile/Settings | `10-profile/` | Control + account management shell |
| 11 | Subscription | `11-subscription/` | Paywall shell (mock RevenueCat) |
| 12 | Errors/Empty | `12-errors/` | Polish + resilience |

---

## What “Done” Looks Like (Prototype Quality Gates)

- [ ] All screens navigable (Expo Router stacks + tabs)
- [ ] All screens have loading/error/empty states
- [ ] Smooth transitions (no jank, 60fps target)
- [ ] No emoji icons (Lucide only)
- [ ] Dark Gradient look is consistent across the app
- [ ] Reduced motion supported

---

## Screen Coverage Proof (Step 4 → Step 5)

Step 4 screen inventory total: **113**  
Step 5 wireframe PRDs created: **113**  
Gap: **0** ✅

See: `/docs/prds/flows/WIREFRAME-TRACKER.md`

---

## Next Steps

1. **Approve Step 5** (PRDs are complete)
2. Implement the prototype in Cursor
3. Proceed to Step 6 (Design System) once the prototype stabilizes


