---
name: companion-system
description: "Gacha companion systems — species, rarity, stats, cosmetics, deterministic seeding. Use when designing pet/companion systems, collectible mechanics, or gamification features. Triggers on 'companion', 'gacha', 'pet system', 'collectible', 'rarity system'."
triggers: ["companion", "gacha", "pet system", "collectible", "rarity system", "mascot", "buddy system"]
tags: [design, gamification, companion, gacha, collectibles]
department: design
---

# Companion System — Gacha, Rarity, Stats, and Collectible Mechanics

Systematic approach to designing companion/pet systems with gacha mechanics, rarity tiers, stat systems, deterministic seeding, cosmetics, and monetization. Derived from production patterns in a large-scale CLI companion system (BUDDY system, `src/buddy/`, 6 files ~73KB, 18 species, 5 rarity tiers).

## 1. Species System

Define species as distinct entities with unique visual traits, personality archetypes, and animation sets. Each species is a self-contained design unit.

### Species Definition

```typescript
interface Species {
  id: string;                    // 'duck', 'dragon', 'axolotl'
  displayName: string;           // 'Duck', 'Dragon', 'Axolotl'
  personality: PersonalityType;  // affects dialogue and reactions
  baseSprite: AsciiSprite;       // idle frame ASCII art
  animations: AnimationSet;      // idle, happy, thinking, surprised
  statAffinity: StatAffinity;    // which stats trend higher for this species
  flavorText: string;            // "A loyal duck who debugs with quacks"
}

type PersonalityType =
  | 'stoic'      // minimal reactions, precise commentary
  | 'chaotic'    // random outbursts, unpredictable
  | 'nurturing'  // encouraging, supportive
  | 'scholarly'  // references docs, explains concepts
  | 'mischievous'; // jokes, pranks, playful
```

### Reference Species Roster (18 species)

| Species | Personality | Stat Affinity | Visual Archetype |
|---------|-------------|---------------|------------------|
| Duck | Chaotic | CHAOS high | Quacking, wing flaps |
| Goose | Mischievous | CHAOS + SNARK | Aggressive honking |
| Blob | Nurturing | PATIENCE high | Amorphous wobble |
| Cat | Stoic | WISDOM + SNARK | Tail swish, slow blink |
| Dragon | Scholarly | WISDOM + DEBUGGING | Wing spread, fire breath |
| Octopus | Scholarly | DEBUGGING high | Tentacle wave |
| Owl | Stoic | WISDOM high | Head rotation |
| Penguin | Nurturing | PATIENCE + WISDOM | Waddle, belly slide |
| Turtle | Stoic | PATIENCE max | Shell retreat |
| Snail | Nurturing | PATIENCE max | Trail shimmer |
| Ghost | Mischievous | CHAOS + SNARK | Fade in/out |
| Axolotl | Nurturing | PATIENCE + DEBUGGING | Gill flutter |
| Capybara | Nurturing | PATIENCE + WISDOM | Chill lounge |
| Cactus | Stoic | PATIENCE + SNARK | Spine wiggle |
| Robot | Scholarly | DEBUGGING max | Antenna blink |
| Rabbit | Chaotic | CHAOS + DEBUGGING | Ear twitch, hop |
| Mushroom | Mischievous | CHAOS + WISDOM | Spore puff |
| Chonk | Chaotic | CHAOS + PATIENCE | Round bounce |

**Scaling:** Start with 8-12 species for launch. Add species in seasonal drops (3-4 per season) to drive engagement spikes.

## 2. Gacha Rarity System

Weighted random selection determines companion rarity at hatch time. Rarity affects stat ranges, cosmetic options, and visual effects.

### Rarity Tiers

| Tier | Weight | Probability | Stat Range | Visual Effect |
|------|--------|-------------|------------|---------------|
| Common | 60 | 60% | 10-40 | None |
| Uncommon | 25 | 25% | 25-60 | Subtle glow |
| Rare | 10 | 10% | 40-80 | Particle aura |
| Epic | 4 | 4% | 60-95 | Animated border |
| Legendary | 1 | 1% | 80-100 | Full animation + sound |

### Weighted Selection Algorithm

```typescript
function selectRarity(weights: RarityWeights): Rarity {
  const total = Object.values(weights).reduce((a, b) => a + b, 0);
  let roll = Math.random() * total;

  for (const [rarity, weight] of Object.entries(weights)) {
    roll -= weight;
    if (roll <= 0) return rarity as Rarity;
  }

  return 'common'; // fallback
}

// Pity system — guaranteed rare+ after N common pulls
function selectWithPity(
  weights: RarityWeights,
  consecutiveCommons: number,
  pityThreshold: number = 10
): Rarity {
  if (consecutiveCommons >= pityThreshold) {
    // Remove common from the pool
    const { common, ...boosted } = weights;
    return selectRarity(boosted);
  }
  return selectRarity(weights);
}
```

### Pity System

Prevent frustration from long streaks of common results:
- Soft pity: After 8 consecutive commons, double the rare+ weights
- Hard pity: After 12 consecutive commons, guarantee rare or above
- Track pity counter per user, persist across sessions

## 3. Stat System

Numerical attributes (0-100) that influence companion behavior. Stats are generated at hatch, not leveled.

### Stat Definitions

| Stat | Range | Behavioral Effect |
|------|-------|-------------------|
| DEBUGGING | 0-100 | High: spots bugs in code, suggests fixes. Low: ignores errors |
| PATIENCE | 0-100 | High: calm during long builds. Low: complaints during waits |
| CHAOS | 0-100 | High: random comments, unexpected actions. Low: predictable |
| WISDOM | 0-100 | High: insightful commentary, doc references. Low: surface-level |
| SNARK | 0-100 | High: sarcastic, witty. Low: earnest, straightforward |

### Stat Generation

Stats are generated within the rarity-defined range, with species affinity applied:

```typescript
function generateStats(species: Species, rarity: Rarity): Stats {
  const [min, max] = RARITY_STAT_RANGES[rarity];

  return {
    DEBUGGING: clamp(randomInRange(min, max) + species.statAffinity.DEBUGGING, 0, 100),
    PATIENCE: clamp(randomInRange(min, max) + species.statAffinity.PATIENCE, 0, 100),
    CHAOS: clamp(randomInRange(min, max) + species.statAffinity.CHAOS, 0, 100),
    WISDOM: clamp(randomInRange(min, max) + species.statAffinity.WISDOM, 0, 100),
    SNARK: clamp(randomInRange(min, max) + species.statAffinity.SNARK, 0, 100),
  };
}
```

### Stat-Driven Behavior

Stats map to concrete behavior thresholds:

```typescript
function getCompanionResponse(companion: Companion, event: Event): string | null {
  if (event.type === 'build_error' && companion.stats.DEBUGGING > 70) {
    return pickFrom(DEBUG_HINTS); // "Have you checked the import path?"
  }
  if (event.type === 'long_wait' && companion.stats.PATIENCE < 30) {
    return pickFrom(IMPATIENT_COMMENTS); // "Are we done yet?"
  }
  if (companion.stats.CHAOS > 80 && Math.random() < 0.1) {
    return pickFrom(RANDOM_OUTBURSTS); // Unprompted chaos
  }
  return null; // Silent
}
```

## 4. Deterministic Seeding

Companion identity is derived from a hash of user identity + seed. Same user always gets the same base companion. Reproducible, fair, and verifiable.

### Bone Generation (Identity Layer)

```typescript
interface CompanionBones {
  species: string;     // Deterministic from hash
  rarity: Rarity;      // Deterministic from hash
  stats: Stats;        // Deterministic from hash
  cosmetics: Cosmetics; // Deterministic from hash
  shiny: boolean;      // 1% chance, deterministic
}

function generateBones(userId: string, seed: string): CompanionBones {
  const hash = deterministicHash(`${userId}:${seed}`);

  // Partition the hash into segments for each attribute
  const speciesIndex = hashSegment(hash, 0, 4) % SPECIES_COUNT;
  const rarityRoll = hashSegment(hash, 4, 8) % 100;
  const shinyRoll = hashSegment(hash, 8, 12) % 100;

  return {
    species: SPECIES_LIST[speciesIndex],
    rarity: rarityFromRoll(rarityRoll),
    stats: statsFromHash(hash, speciesIndex),
    cosmetics: cosmeticsFromHash(hash),
    shiny: shinyRoll < 1, // 1% chance
  };
}
```

### Soul Generation (Personality Layer)

The soul (name + personality quirks) is generated by the LLM on first hatch, then cached permanently:

```typescript
interface CompanionSoul {
  name: string;        // LLM-generated, e.g., "Professor Quacksworth"
  catchphrase: string; // Signature line
  quirks: string[];    // Behavioral traits
  backstory: string;   // 2-3 sentence origin
}

async function hatchCompanion(bones: CompanionBones): Promise<Companion> {
  // Check cache first — soul is generated once
  const cached = await cache.get(`soul:${bones.species}:${bones.hash}`);
  if (cached) return { ...bones, soul: cached };

  // Generate soul via LLM
  const soul = await generateSoul(bones);
  await cache.set(`soul:${bones.species}:${bones.hash}`, soul);

  return { ...bones, soul };
}
```

**Key property:** Bones are deterministic (same input = same output). Soul is stochastic but cached (generated once, never changes).

## 5. Cosmetics Layer

Visual customization layered on top of the base sprite. Cosmetics are progression rewards, not stat modifiers.

### Cosmetic Slots

| Slot | Options | Source |
|------|---------|--------|
| Hat | Crown, Tophat, Propeller, Halo, Wizard, Beanie, Tinyduck | Gacha drops, achievements, seasonal events |
| Eyes | `·` `+` `x` `@` `o` `*` | Default per species + unlockable |
| Shiny | 1% chance at hatch | Deterministic from seed |
| Trail | None, Sparkle, Fire, Ice, Rainbow | Progression milestones |
| Badge | Achievement icons | Specific accomplishment triggers |

### Layered Rendering

```typescript
// Sprite composition: base + hat + eyes + effects
function renderCompanion(companion: Companion): string[] {
  const base = getBaseSprite(companion.species, companion.animation);
  const withHat = overlayHat(base, companion.cosmetics.hat);
  const withEyes = replaceEyes(withHat, companion.cosmetics.eyes);
  const withEffects = applyEffects(withEyes, {
    shiny: companion.shiny,
    rarity: companion.rarity,
    trail: companion.cosmetics.trail,
  });
  return withEffects;
}
```

### ASCII Sprite Renderer

For CLI/terminal companions, sprites are ASCII art with ANSI color codes:

```typescript
// 44KB CompanionSprite — frame-by-frame ASCII with color
interface SpriteFrame {
  lines: string[];           // ASCII art lines
  colors: AnsiColor[][];     // Color map per character
  width: number;
  height: number;
}

interface AnimationSet {
  idle: SpriteFrame[];       // 2-4 frames, loop
  happy: SpriteFrame[];      // 3-6 frames, play once
  thinking: SpriteFrame[];   // 2-3 frames, loop while waiting
  surprised: SpriteFrame[];  // 2 frames, play once
}
```

**Positioning:** Companion renders beside the input box with a speech bubble. Speech bubble points toward the companion sprite. Bubble content driven by stats + current context.

## 6. Monetization Patterns

Revenue streams that do not compromise gameplay fairness (cosmetic-only monetization).

### Direct Revenue

| Channel | Model | Example |
|---------|-------|---------|
| Cosmetic packs | One-time purchase | "Winter Pack" — 3 hats + 2 trails, $4.99 |
| Seasonal drops | Limited-time purchase | "Spooky Season" — ghost hat + pumpkin eyes, $2.99 |
| Agent Pass | Subscription (monthly) | Exclusive cosmetics + early species access, $9.99/mo |
| Shiny Boost | Consumable | 5x shiny chance for next 10 hatches, $1.99 |

### Indirect Revenue (Engagement)

| Mechanism | Effect |
|-----------|--------|
| Daily hatch | One free hatch per day — drives daily active usage |
| Achievement cosmetics | Complete tasks to unlock exclusive items |
| Collection bonuses | Own 10+ species = bonus cosmetic slot |
| Social trading | Trade companions with other users (marketplace fee) |

### NFT Integration (Optional)

For projects that want on-chain companion ownership:

```typescript
interface OnChainCompanion {
  tokenId: bigint;           // ERC-721 token
  chain: 'base';             // Base L2 for low gas
  metadata: {
    species: string;
    rarity: Rarity;
    stats: Stats;
    shiny: boolean;
    cosmetics: Cosmetics[];  // Separate ERC-1155 tokens, composable
  };
}

// Marketplace revenue model
const MARKETPLACE_FEE = 0.025; // 2.5% on secondary sales
const MINT_PRICE_USDC = 5.00;  // Primary mint via x402 crypto payment
```

**Composability:** Base companion is ERC-721. Cosmetics are ERC-1155 tokens that can be equipped/unequipped. Cosmetics work across any companion of compatible species.

## 7. Implementation Checklist

### Phase 1: Core System (MVP)

- [ ] Define 8-12 launch species with sprites and personality types
- [ ] Implement deterministic bone generation from user hash
- [ ] Implement rarity weighted selection with pity system
- [ ] Implement stat generation within rarity ranges
- [ ] Implement soul generation via LLM with permanent cache
- [ ] Build sprite renderer (ASCII for CLI, SVG/Canvas for web)
- [ ] Wire stat-driven behavior responses to application events
- [ ] Persist companion state (bones + soul + cosmetics)

### Phase 2: Cosmetics and Progression

- [ ] Implement cosmetic slot system (hat, eyes, trail, badge)
- [ ] Build layered sprite composition renderer
- [ ] Create achievement system that unlocks cosmetics
- [ ] Implement daily hatch mechanic
- [ ] Add seasonal species and cosmetic drops
- [ ] Build collection tracker with bonus thresholds

### Phase 3: Monetization

- [ ] Integrate payment system for cosmetic packs
- [ ] Implement Agent Pass subscription with exclusive rewards
- [ ] Build companion trading/gifting between users
- [ ] (Optional) Deploy ERC-721 + ERC-1155 contracts on Base L2
- [ ] (Optional) Build marketplace with fee collection

## Quality Gates

- [ ] Deterministic seeding produces identical companions for identical inputs (property test)
- [ ] Rarity distribution matches expected weights within 2% over 10,000 samples
- [ ] Pity system guarantees rare+ within the configured threshold (no infinite common streaks)
- [ ] Stats stay within rarity-defined ranges after affinity bonus
- [ ] Sprite rendering handles all cosmetic combinations without visual artifacts
- [ ] Soul generation is cached permanently — never regenerates for the same bones
- [ ] Monetization is cosmetic-only — no stat advantages from purchases
- [ ] Shiny rate is exactly 1% over large sample (deterministic verification)
- [ ] Species roster has balanced personality distribution (no >30% single type)

## When NOT to Use

- Not for systems where randomness is undesirable — companions are inherently gacha-based
- Not for applications with strict anti-gambling compliance (gacha with real-money elements may require legal review)
- Not for pure utility tools where gamification would feel patronizing
- Not for products targeting demographics that reject collectible mechanics
- Not when the development budget cannot sustain ongoing species/cosmetic content drops

## Related Skills

- `frontend-design` — design (sprite rendering, animation, UI integration)
- `marketing-psychology` — marketing (engagement loops, FOMO mechanics, collection drive)
- `smart-contract-security` — security (NFT contract patterns if using on-chain companions)
- `reducing-entropy` — core (compact companion state for context-limited environments)

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

Read, Write, Edit, Bash (for property testing scripts), Grep (for event hook discovery)
