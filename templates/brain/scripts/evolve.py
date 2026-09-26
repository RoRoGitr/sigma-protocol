"""
Stage 4: Autonomous skill & agent evolution from vault knowledge.

Detection is rule-based (free, instant).
Proposal generation uses LLM (Claude Agent SDK, ~$0.50/proposal).

Usage:
    uv run python evolve.py                    # detect + propose
    uv run python evolve.py --detect-only      # detection only (free)
    uv run python evolve.py --apply            # detect + propose + apply
    uv run python evolve.py --project example-app # single project
    uv run python evolve.py --global-only      # skip project scan
"""
from __future__ import annotations

import argparse
import asyncio
import json
import re
import sys
import yaml
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from config import (
    CONNECTIONS_DIR,
    EVOLUTION_DIR,
    PROJECTS_DIR,
    QA_DIR,
    SCRIPTS_DIR,
    VAULT_PATH,
    now_iso,
    today_str,
)
from utils import list_wiki_articles, setup_logging

logger = setup_logging("evolve")

EVOLUTION_LOG = VAULT_PATH / "inbox" / "evolution-log.md"
SKILLS_DIR = Path.home() / ".claude" / "skills"
AGENTS_DIR = Path.home() / ".claude" / "agents"

MAX_PROPOSALS = 20
SKILL_GAP_THRESHOLD = 5      # min articles per tag to flag as gap
STALENESS_DAYS = 14           # days behind latest article to flag stale
AGENT_ARTICLE_THRESHOLD = 30  # min articles for new agent proposal
AGENT_GOTCHA_THRESHOLD = 5    # min gotchas for new agent proposal

# ── YAML frontmatter parsing ──────────────────────────────────────────


def parse_frontmatter(content: str) -> dict:
    """Extract YAML frontmatter from a markdown file. Simple parser, no PyYAML needed."""
    if not content.startswith("---"):
        return {}
    end = content.find("---", 3)
    if end == -1:
        return {}
    fm_text = content[3:end].strip()
    result = {}
    for line in fm_text.splitlines():
        if ":" not in line:
            continue
        key, _, val = line.partition(":")
        key = key.strip()
        val = val.strip().strip('"').strip("'")
        # Handle YAML lists: [a, b, c] or - a
        if val.startswith("[") and val.endswith("]"):
            val = [v.strip().strip('"').strip("'") for v in val[1:-1].split(",") if v.strip()]
        result[key] = val
    return result


def extract_tags_from_frontmatter(content: str) -> list[str]:
    """Extract tags list from frontmatter."""
    fm = parse_frontmatter(content)
    tags = fm.get("tags", [])
    if isinstance(tags, str):
        # Handle: tags: tag1, tag2
        tags = [t.strip() for t in tags.split(",")]
    return [t for t in tags if t]


# ── Discovery ─────────────────────────────────────────────────────────


def _load_project_map_from_config() -> dict[str, str]:
    """Load project_map from .brain-config.yaml if it exists.

    Returns {pattern: slug} dict, or empty dict if no config.
    """
    config_path = SCRIPTS_DIR.parent / ".brain-config.yaml"
    if not config_path.exists():
        return {}
    try:
        with open(config_path, encoding="utf-8") as f:
            cfg = yaml.safe_load(f) or {}
        return cfg.get("project_map", {})
    except (OSError, yaml.YAMLError):
        return {}


def discover_project_paths() -> dict[str, Path]:
    """Discover project directories that have .claude/ configuration.

    Strategy:
    1. If .brain-config.yaml has a project_map, walk home directory matching
       those patterns against directory names.
    2. Otherwise, walk ~/ at depth 2 looking for directories containing .claude/.
    """
    project_map = _load_project_map_from_config()

    if project_map:
        # Config-driven discovery: walk ~/ looking for directories matching patterns
        result: dict[str, Path] = {}
        home = Path.home()
        for category_dir in home.iterdir():
            if not category_dir.is_dir() or category_dir.name.startswith("."):
                continue
            try:
                for project_dir in category_dir.iterdir():
                    if not project_dir.is_dir() or project_dir.name.startswith("."):
                        continue
                    for pattern, slug in project_map.items():
                        if pattern in project_dir.name:
                            result[slug] = project_dir
                            break
            except PermissionError:
                continue
        return result

    # Fallback: walk ~/ depth 2 looking for .claude/ directories
    result = {}
    home = Path.home()
    for category_dir in home.iterdir():
        if not category_dir.is_dir() or category_dir.name.startswith("."):
            continue
        try:
            for project_dir in category_dir.iterdir():
                if not project_dir.is_dir() or project_dir.name.startswith("."):
                    continue
                if (project_dir / ".claude").is_dir():
                    slug = project_dir.name.lower().replace(" ", "-")
                    result[slug] = project_dir
        except PermissionError:
            continue
    return result


def scan_skills(root: Path) -> list[dict]:
    """Scan a directory for SKILL.md files, parse frontmatter + content."""
    skills = []
    if not root.exists():
        return skills
    for skill_md in root.rglob("SKILL.md"):
        try:
            content = skill_md.read_text(encoding="utf-8")
        except OSError:
            continue
        fm = parse_frontmatter(content)
        skills.append({
            "name": fm.get("name", skill_md.parent.name),
            "description": fm.get("description", ""),
            "path": str(skill_md),
            "mtime": datetime.fromtimestamp(skill_md.stat().st_mtime, tz=timezone.utc),
            "content": content,
            "skills_list": fm.get("skills", []),
        })
    return skills


def scan_agents(root: Path) -> list[dict]:
    """Scan a directory for agent .md files, parse frontmatter + content."""
    agents = []
    if not root.exists():
        return agents
    for agent_md in root.glob("*.md"):
        if agent_md.name.startswith("_") or agent_md.name == "README.md":
            continue
        try:
            content = agent_md.read_text(encoding="utf-8")
        except OSError:
            continue
        fm = parse_frontmatter(content)
        agents.append({
            "name": fm.get("name", agent_md.stem),
            "description": fm.get("description", ""),
            "path": str(agent_md),
            "mtime": datetime.fromtimestamp(agent_md.stat().st_mtime, tz=timezone.utc),
            "content": content,
            "skills": fm.get("skills", []) if isinstance(fm.get("skills"), list) else [],
        })
    return agents


# ── Signal Detection (rule-based, free) ───────────────────────────────


def extract_vault_tags() -> dict[str, list[str]]:
    """Extract tag -> [article_paths] mapping from all vault articles."""
    tag_map: dict[str, list[str]] = {}
    for article in list_wiki_articles():
        if article.name.startswith("_"):
            continue
        try:
            content = article.read_text(encoding="utf-8")
        except OSError:
            continue
        tags = extract_tags_from_frontmatter(content)
        rel = str(article.relative_to(VAULT_PATH))
        for tag in tags:
            tag_map.setdefault(tag.lower(), []).append(rel)
    return tag_map


def detect_skill_gaps(tag_map: dict[str, list[str]], skills: list[dict]) -> list[dict]:
    """Detector 1: Tag clusters with no matching skill."""
    # Build skill keyword index
    skill_keywords: set[str] = set()
    for skill in skills:
        name = skill["name"].lower().replace("-", " ").replace("_", " ")
        skill_keywords.update(name.split())
        desc = skill.get("description", "").lower()
        skill_keywords.update(w for w in desc.split() if len(w) > 3)

    gaps = []
    for tag, articles in sorted(tag_map.items(), key=lambda x: -len(x[1])):
        if len(articles) < SKILL_GAP_THRESHOLD:
            continue
        # Check if any skill covers this tag
        tag_words = set(tag.replace("-", " ").replace("_", " ").split())
        if tag_words & skill_keywords:
            continue
        # Determine which projects this tag spans
        projects = set()
        for a in articles:
            parts = a.split("/")
            if parts[0] == "projects" and len(parts) >= 2:
                projects.add(parts[1])
        gaps.append({
            "type": "skill_gap",
            "tag": tag,
            "article_count": len(articles),
            "projects": sorted(projects),
            "confidence": min(0.95, 0.5 + len(articles) * 0.03),
            "evidence": articles[:5],
        })
    return gaps[:MAX_PROPOSALS]


def detect_skill_staleness(skills: list[dict], tag_map: dict[str, list[str]]) -> list[dict]:
    """Detector 2: Skills with vault knowledge newer than skill file."""
    stale = []
    now = datetime.now(timezone.utc)
    for skill in skills:
        skill_name_words = set(skill["name"].lower().replace("-", " ").split())
        # Find matching vault articles by tag overlap
        latest_article_time = None
        matching_articles = []
        for tag, articles in tag_map.items():
            tag_words = set(tag.replace("-", " ").split())
            if tag_words & skill_name_words:
                for a in articles:
                    article_path = VAULT_PATH / a
                    if article_path.exists():
                        mtime = datetime.fromtimestamp(article_path.stat().st_mtime, tz=timezone.utc)
                        if latest_article_time is None or mtime > latest_article_time:
                            latest_article_time = mtime
                        matching_articles.append(a)
        if latest_article_time is None:
            continue
        days_behind = (latest_article_time - skill["mtime"]).days
        if days_behind >= STALENESS_DAYS:
            stale.append({
                "type": "skill_stale",
                "skill": skill["name"],
                "skill_path": skill["path"],
                "skill_mtime": skill["mtime"].isoformat()[:10],
                "latest_article": latest_article_time.isoformat()[:10],
                "days_behind": days_behind,
                "matching_articles": matching_articles[:5],
                "confidence": min(0.9, 0.5 + days_behind * 0.01),
            })
    return sorted(stale, key=lambda x: -x["days_behind"])[:MAX_PROPOSALS]


def _read_gotchas(project_slug: str) -> list[str]:
    """Read gotcha entries from a project's gotchas.md file."""
    gotchas_path = PROJECTS_DIR / project_slug / "gotchas.md"
    if not gotchas_path.exists():
        return []
    content = gotchas_path.read_text(encoding="utf-8")
    # Extract gotcha items (lines starting with - or numbered items after ## headings)
    gotchas = []
    for line in content.splitlines():
        line = line.strip()
        if line.startswith("- ") or line.startswith("* "):
            gotchas.append(line[2:].strip())
        elif re.match(r"^\d+\.\s", line):
            gotchas.append(re.sub(r"^\d+\.\s*", "", line).strip())
    return gotchas


def detect_agent_enrichment(agents: list[dict], project_paths: dict[str, Path]) -> list[dict]:
    """Detector 3: Gotchas not reflected in agent DNA."""
    enrichments = []

    # Scan all projects with gotchas
    for project_slug in sorted(PROJECTS_DIR.iterdir()):
        if not project_slug.is_dir():
            continue
        slug = project_slug.name
        gotchas = _read_gotchas(slug)
        if not gotchas:
            continue

        # Find agents that serve this project
        # 1. Project-level agents
        repo_path = project_paths.get(slug)
        project_agents = []
        if repo_path and (repo_path / ".claude" / "agents").exists():
            project_agents = scan_agents(repo_path / ".claude" / "agents")

        # 2. Global agents that mention this project
        relevant_agents = list(project_agents)
        for agent in agents:
            desc_lower = agent.get("description", "").lower()
            content_lower = agent.get("content", "").lower()
            if slug.replace("-", " ") in desc_lower or slug.replace("-", " ") in content_lower:
                relevant_agents.append(agent)

        for agent in relevant_agents:
            agent_content = agent.get("content", "").lower()
            # Count gotchas NOT mentioned in agent DNA
            missing = []
            for gotcha in gotchas:
                # Extract key phrase (first ~40 chars, lowered)
                key = gotcha[:40].lower()
                # Check if any significant words from the gotcha appear in agent
                significant_words = [w for w in key.split() if len(w) > 4]
                if significant_words and not any(w in agent_content for w in significant_words[:3]):
                    missing.append(gotcha[:80])

            if len(missing) >= 2:
                enrichments.append({
                    "type": "agent_enrichment",
                    "agent": agent["name"],
                    "agent_path": agent["path"],
                    "scope": "project:" + slug if agent in project_agents else "global",
                    "source_project": slug,
                    "gotchas_total": len(gotchas),
                    "gotchas_missing": len(missing),
                    "missing_sample": missing[:5],
                    "confidence": min(0.9, 0.4 + len(missing) * 0.05),
                })

    return sorted(enrichments, key=lambda x: -x["gotchas_missing"])[:MAX_PROPOSALS]


def detect_agent_skill_links(agents: list[dict], skills: list[dict]) -> list[dict]:
    """Detector 4: Agents missing links to relevant skills."""
    missing_links = []
    skill_names = {s["name"] for s in skills}

    for agent in agents:
        agent_skills = set(agent.get("skills", []))
        agent_desc = agent.get("description", "").lower()
        agent_name = agent["name"].lower()

        # Find skills that match agent's domain but aren't linked
        for skill in skills:
            if skill["name"] in agent_skills:
                continue
            skill_desc = skill.get("description", "").lower()
            skill_name_words = set(skill["name"].replace("-", " ").split())
            agent_name_words = set(agent_name.replace("-", " ").split())

            # Check for domain overlap
            overlap = skill_name_words & agent_name_words
            if not overlap:
                # Check description keyword overlap (significant words only)
                agent_keywords = {w for w in agent_desc.split() if len(w) > 4}
                skill_keywords = {w for w in skill_desc.split() if len(w) > 4}
                overlap = agent_keywords & skill_keywords

            if len(overlap) >= 2:
                missing_links.append({
                    "type": "agent_link",
                    "agent": agent["name"],
                    "agent_path": agent["path"],
                    "skill": skill["name"],
                    "skill_path": skill["path"],
                    "overlap_keywords": sorted(overlap)[:5],
                    "confidence": min(0.8, 0.3 + len(overlap) * 0.1),
                })

    return sorted(missing_links, key=lambda x: -x["confidence"])[:MAX_PROPOSALS]


def detect_new_agent_need(project_paths: dict[str, Path]) -> list[dict]:
    """Detector 5: Projects with high article/gotcha density but no dedicated agents."""
    needs = []

    for project_dir in sorted(PROJECTS_DIR.iterdir()):
        if not project_dir.is_dir():
            continue
        slug = project_dir.name

        # Count articles
        articles = list(project_dir.rglob("*.md"))
        article_count = len([a for a in articles if not a.name.startswith("_")])

        # Count gotchas
        gotchas = _read_gotchas(slug)

        if article_count < AGENT_ARTICLE_THRESHOLD and len(gotchas) < AGENT_GOTCHA_THRESHOLD:
            continue

        # Check if project has dedicated agents
        repo_path = project_paths.get(slug)
        has_agents = False
        if repo_path and (repo_path / ".claude" / "agents").exists():
            agent_files = list((repo_path / ".claude" / "agents").glob("*.md"))
            has_agents = len([f for f in agent_files if f.name != "README.md"]) > 0

        if not has_agents:
            needs.append({
                "type": "new_agent",
                "project": slug,
                "article_count": article_count,
                "gotcha_count": len(gotchas),
                "repo_path": str(repo_path) if repo_path else "not found",
                "confidence": min(0.85, 0.4 + article_count * 0.01 + len(gotchas) * 0.02),
            })

    return sorted(needs, key=lambda x: -(x["article_count"] + x["gotcha_count"] * 3))[:MAX_PROPOSALS]


# ── Proposal Generation (LLM-powered) ─────────────────────────────────


async def generate_proposals(detections: list[dict]) -> list[dict]:
    """Use LLM to generate concrete proposal content for each detection."""
    from claude_agent_sdk import ClaudeAgentOptions, ResultMessage, TextBlock, query  # type: ignore

    proposals = []
    for det in detections[:MAX_PROPOSALS]:
        det_type = det["type"]
        if det_type == "skill_gap":
            prompt_text = f"""Generate a SKILL.md file for a new Claude Code skill.

Skill name: {det['tag']}-patterns
Topic: Patterns and gotchas related to "{det['tag']}" found across {det['article_count']} vault articles in projects: {', '.join(det.get('projects', []))}.

Requirements:
- Frontmatter: name, description (starts with "Use when...", max 500 chars, triggers only)
- Sections: overview, When to Use, Key Patterns, Common Mistakes
- Under 200 words for the content (token efficiency)
- No hedging, no filler, direct and declarative
- Description must include trigger phrases for discovery

Output ONLY the SKILL.md content, nothing else."""

        elif det_type == "skill_stale":
            prompt_text = f"""The skill "{det['skill']}" at {det['skill_path']} is {det['days_behind']} days behind the latest vault knowledge.

Relevant vault articles: {', '.join(det.get('matching_articles', [])[:3])}

Generate a markdown section (## Recent Patterns) that could be appended to this skill with the latest patterns from the vault. Keep it under 100 words. Direct, no filler."""

        elif det_type == "agent_enrichment":
            prompt_text = f"""The agent "{det['agent']}" is missing {det['gotchas_missing']} gotchas from project {det['source_project']}.

Sample missing gotchas:
{chr(10).join('- ' + g for g in det.get('missing_sample', []))}

Generate a "## Gotchas ({det['source_project']})" DNA section that could be appended to the agent definition. Use concise bullet points. Under 150 words. Methodology-focused (how to AVOID these), not framework-specific."""

        elif det_type == "agent_link":
            prompt_text = f"""Recommend linking skill "{det['skill']}" to agent "{det['agent']}".
Overlap keywords: {', '.join(det.get('overlap_keywords', []))}

Generate a 2-sentence justification for adding this skill to the agent's skills list."""

        elif det_type == "new_agent":
            prompt_text = f"""Generate an agent definition (.md file) for project "{det['project']}".
The project has {det['article_count']} vault articles and {det['gotcha_count']} gotchas.

Requirements:
- Frontmatter: name, description, tools (Read, Write, Edit, Bash, Glob, Grep), model (sonnet)
- Brief role description
- DNA section with project-specific methodology
- Under 200 words total
- No hedging, no filler

Output ONLY the agent .md content."""

        else:
            continue

        try:
            result_text = ""
            async for message in query(
                prompt=prompt_text,
                options=ClaudeAgentOptions(
                    cwd=str(VAULT_PATH),
                    system_prompt={"type": "preset", "preset": "claude_code"},
                    allowed_tools=[],
                    permission_mode="acceptEdits",
                    max_turns=2,
                ),
            ):
                if isinstance(message, ResultMessage):
                    if hasattr(message, "content") and message.content:
                        for block in message.content:
                            if isinstance(block, TextBlock):
                                result_text = block.text
                                break
                    if not result_text:
                        result_text = str(message)

            det["proposal_content"] = result_text
            det["generated_at"] = now_iso()
            proposals.append(det)
            logger.info("Generated proposal for %s: %s", det_type, det.get("tag") or det.get("skill") or det.get("agent") or det.get("project"))
        except Exception as e:
            logger.error("Failed to generate proposal for %s: %s", det_type, e)
            det["proposal_content"] = f"(Generation failed: {e})"
            det["generated_at"] = now_iso()
            proposals.append(det)

    return proposals


# ── Proposal Writing ──────────────────────────────────────────────────


def write_proposals(proposals: list[dict]) -> Path:
    """Write proposals to inbox/evolution/ as markdown files."""
    EVOLUTION_DIR.mkdir(parents=True, exist_ok=True)

    date = today_str()
    for i, prop in enumerate(proposals):
        det_type = prop["type"]
        name = prop.get("tag") or prop.get("skill") or prop.get("agent") or prop.get("project") or f"unknown-{i}"
        filename = f"{date}-{det_type}-{name}.md"
        filepath = EVOLUTION_DIR / filename

        # Build proposal markdown
        evidence = prop.get("evidence") or prop.get("matching_articles") or prop.get("missing_sample") or []
        if isinstance(evidence, list):
            evidence_yaml = "\n".join(f"  - {e}" for e in evidence[:5])
        else:
            evidence_yaml = f"  - {evidence}"

        scope = prop.get("scope", "global")
        target = ""
        if det_type == "skill_gap":
            target = f"~/.claude/skills/{name}-patterns/SKILL.md"
        elif det_type == "skill_stale":
            target = prop.get("skill_path", "")
        elif det_type == "agent_enrichment":
            target = prop.get("agent_path", "")
        elif det_type == "agent_link":
            target = prop.get("agent_path", "")
        elif det_type == "new_agent":
            repo = prop.get("repo_path", "")
            target = f"{repo}/.claude/agents/{name}-specialist.md" if repo != "not found" else f"~/.claude/agents/{name}-specialist.md"

        content = f"""---
type: {det_type}
target: {target}
scope: {scope}
confidence: {prop.get('confidence', 0.5)}
evidence:
{evidence_yaml}
created: {now_iso()}
status: pending
---
# Proposal: {det_type.replace('_', ' ').title()} — {name}

## Detection
{json.dumps({k: v for k, v in prop.items() if k not in ('proposal_content', 'content', 'generated_at')}, indent=2, default=str)}

## Proposed Content

{prop.get('proposal_content', '(no content generated — run without --detect-only)')}
"""
        filepath.write_text(content, encoding="utf-8")
        logger.info("Wrote proposal: %s", filepath.name)

    return EVOLUTION_DIR


# ── Proposal application ──────────────────────────────────────────────

APPLIED_STATE = VAULT_PATH / "inbox" / "evolution-applied.json"
MAX_APPLY_PER_RUN = 10
LINK_PROMOTE_SEEN = 3


def _fingerprint(prop: dict) -> str:
    name = prop.get("tag") or prop.get("skill") or prop.get("agent") or prop.get("project") or "unknown"
    return f"{prop.get('type', '?')}:{name}"


def _target_for(prop: dict) -> Path | None:
    det_type = prop.get("type")
    if det_type == "skill_gap":
        return SKILLS_DIR / f"{prop.get('tag', 'unknown')}-patterns" / "SKILL.md"
    if det_type == "skill_stale":
        path = prop.get("skill_path")
        return Path(path) if path else None
    if det_type in ("agent_enrichment", "agent_link"):
        path = prop.get("agent_path")
        return Path(path) if path else None
    if det_type == "new_agent":
        repo = prop.get("repo_path", "not found")
        name = prop.get("project", "unknown")
        if repo and repo != "not found":
            return Path(repo) / ".claude" / "agents" / f"{name}-specialist.md"
        return AGENTS_DIR / f"{name}-specialist.md"
    return None


def _load_applied_state() -> dict:
    try:
        return json.loads(APPLIED_STATE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def _save_applied_state(state: dict) -> None:
    APPLIED_STATE.parent.mkdir(parents=True, exist_ok=True)
    APPLIED_STATE.write_text(json.dumps(state, indent=2, default=str), encoding="utf-8")


def _append_evolve_block(path: Path, fp: str, det_type: str, body: str, seen: int) -> bool:
    if not path.exists():
        return False
    content = path.read_text(encoding="utf-8")
    if f"EVOLVE id={fp} " in content:
        return False
    block = (
        f"\n\n<!-- EVOLVE id={fp} type={det_type} verified=false seen={seen} applied={today_str()} -->\n"
        f"{body.strip()}\n"
        f"<!-- /EVOLVE id={fp} -->\n"
    )
    with open(path, "a", encoding="utf-8") as f:
        f.write(block)
    return True


def _create_file(path: Path, body: str) -> bool:
    if path.exists():
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    note = (
        f"<!-- EVOLVE-SCAFFOLD verified=false created={today_str()} "
        "machine-scaffolded; review before trusting -->\n"
    )
    path.write_text(note + body.strip() + "\n", encoding="utf-8")
    return True


def _skill_exists_similar(tag: str) -> bool:
    if not tag or not SKILLS_DIR.exists():
        return False
    base = tag.replace("-patterns", "").strip("-")
    existing = {d.name for d in SKILLS_DIR.iterdir() if d.is_dir()}
    if {tag, f"{tag}-patterns", base, f"{base}-patterns"} & existing:
        return True
    return any(base and (base == name or base in name.split("-")) for name in existing)


def _add_skill_to_frontmatter(path: Path, skill: str) -> bool:
    if not path.exists() or not skill or not (SKILLS_DIR / skill).is_dir():
        return False
    content = path.read_text(encoding="utf-8")
    if re.search(rf"^\s*-\s+{re.escape(skill)}\s*$", content, re.M):
        return False

    lines = content.splitlines(keepends=True)
    out: list[str] = []
    in_fm = False
    in_skills = False
    count = 0
    inserted = False

    for i, line in enumerate(lines):
        if i == 0 and line.startswith("---"):
            in_fm = True
            out.append(line)
            continue
        if in_fm and line.startswith("---"):
            if in_skills and count < 8 and not inserted:
                out.append(f"  - {skill}\n")
                inserted = True
            in_fm = False
            in_skills = False
            out.append(line)
            continue
        if in_fm and re.match(r"^skills\s*:", line):
            in_skills = True
            out.append(line)
            continue
        if in_skills:
            if re.match(r"^\s*-\s+", line):
                count += 1
                out.append(line)
                continue
            if count < 8 and not inserted:
                out.append(f"  - {skill}\n")
                inserted = True
            in_skills = False
            out.append(line)
            continue
        out.append(line)

    if not inserted:
        return False
    path.write_text("".join(out), encoding="utf-8")
    return True


def apply_proposals(proposals: list[dict]) -> dict:
    """Apply proposals idempotently with reversible verified:false markers."""
    if str(__import__("os").environ.get("EVOLVE_APPLY", "1")) == "0":
        return {"applied": [], "skipped": [{"reason": "EVOLVE_APPLY=0 kill-switch"}], "promoted": []}

    state = _load_applied_state()
    applied: list[dict] = []
    skipped: list[dict] = []
    promoted: list[str] = []
    count = 0

    for prop in proposals:
        fp = _fingerprint(prop)
        if count >= MAX_APPLY_PER_RUN:
            skipped.append({"fp": fp, "reason": "max-per-run"})
            continue
        body = prop.get("proposal_content", "")
        if not body or body.startswith("(Generation failed") or body.startswith("(no content"):
            skipped.append({"fp": fp, "reason": "no-content"})
            continue
        target = _target_for(prop)
        if target is None:
            skipped.append({"fp": fp, "reason": "no-target"})
            continue

        record = state.get(fp, {"seen": 0, "first_seen": today_str(), "applied": False})
        record["seen"] = int(record.get("seen", 0)) + 1
        det_type = prop.get("type")
        did_apply = False

        try:
            if det_type in ("agent_enrichment", "skill_stale"):
                did_apply = _append_evolve_block(target, fp, det_type, body, record["seen"])
            elif det_type in ("skill_gap", "new_agent"):
                if det_type == "skill_gap" and _skill_exists_similar(prop.get("tag", "")):
                    skipped.append({"fp": fp, "reason": "similar-skill-exists"})
                    state[fp] = record
                    continue
                did_apply = _create_file(target, body)
            elif det_type == "agent_link":
                if record["seen"] >= LINK_PROMOTE_SEEN:
                    did_apply = _add_skill_to_frontmatter(target, prop.get("skill", ""))
                    if did_apply:
                        promoted.append(fp)
                else:
                    skipped.append({"fp": fp, "reason": f"link-needs-seen-{LINK_PROMOTE_SEEN}-at-{record['seen']}"})
        except OSError as exc:
            skipped.append({"fp": fp, "reason": f"io:{exc}"})
            state[fp] = record
            continue

        if did_apply:
            record.update({"applied": True, "applied_at": now_iso(), "target": str(target), "verified": False})
            applied.append({"fp": fp, "type": det_type, "target": str(target), "seen": record["seen"]})
            count += 1
        elif det_type in ("agent_enrichment", "skill_stale", "skill_gap", "new_agent"):
            skipped.append({"fp": fp, "reason": "already-applied-or-target-missing"})
        state[fp] = record

    _save_applied_state(state)
    return {"applied": applied, "skipped": skipped, "promoted": promoted}


def _load_pending_proposals() -> list[dict]:
    proposals: list[dict] = []
    if not EVOLUTION_DIR.exists():
        return proposals
    for file in sorted(EVOLUTION_DIR.glob("*.md")):
        try:
            text = file.read_text(encoding="utf-8")
        except OSError:
            continue
        fm = parse_frontmatter(text)
        if str(fm.get("status", "pending")).lower() not in ("pending", ""):
            continue
        detection: dict = {}
        if "## Detection" in text and "## Proposed Content" in text:
            detection_json = text.split("## Detection", 1)[1].split("## Proposed Content", 1)[0].strip()
            try:
                detection = json.loads(detection_json)
            except json.JSONDecodeError:
                detection = {}
        detection.setdefault("type", fm.get("type", ""))
        detection["proposal_content"] = text.split("## Proposed Content", 1)[1].strip() if "## Proposed Content" in text else ""
        detection["_proposal_file"] = str(file)
        proposals.append(detection)
    return proposals


def log_evolution(detections: list[dict], proposals: list[dict], applied: bool) -> None:
    """Append to evolution-log.md."""
    EVOLUTION_DIR.mkdir(parents=True, exist_ok=True)

    summary = {
        "skill_gaps": len([d for d in detections if d["type"] == "skill_gap"]),
        "stale_skills": len([d for d in detections if d["type"] == "skill_stale"]),
        "agent_enrichments": len([d for d in detections if d["type"] == "agent_enrichment"]),
        "missing_links": len([d for d in detections if d["type"] == "agent_link"]),
        "new_agents": len([d for d in detections if d["type"] == "new_agent"]),
    }

    entry = f"""
## [{now_iso()}] evolve | {'applied' if applied else 'proposed'}
- Detections: {len(detections)} total
- Proposals: {len(proposals)} generated
- Skill gaps: {summary['skill_gaps']}
- Stale skills: {summary['stale_skills']}
- Agent enrichments: {summary['agent_enrichments']}
- Missing links: {summary['missing_links']}
- New agents needed: {summary['new_agents']}
"""
    with open(EVOLUTION_LOG, "a", encoding="utf-8") as f:
        f.write(entry)


# ── Main ──────────────────────────────────────────────────────────────


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Stage 4: Autonomous skill & agent evolution from vault knowledge"
    )
    parser.add_argument("--detect-only", action="store_true", help="Detection only, no LLM (free)")
    parser.add_argument("--apply", action="store_true", help="Apply proposals after generation")
    parser.add_argument("--apply-pending", action="store_true", help="Apply existing written proposals without LLM generation")
    parser.add_argument("--project", type=str, help="Single project slug to analyze")
    parser.add_argument("--global-only", action="store_true", help="Skip project-level scan")
    args = parser.parse_args()

    if args.apply_pending:
        pending = _load_pending_proposals()
        print(f"--apply-pending: {len(pending)} pending proposal(s)")
        result = apply_proposals(pending)
        print(f"applied {len(result['applied'])}, promoted {len(result['promoted'])}, skipped {len(result['skipped'])}")
        for item in result["applied"]:
            print(f"  applied {item['type']} -> {item['target']} (verified:false, seen {item['seen']})")
        log_evolution([], pending, applied=True)
        return

    # ── Phase 1: Discovery ────────────────────────────────────────────
    project_paths = discover_project_paths()
    global_skills = scan_skills(SKILLS_DIR)
    global_agents = scan_agents(AGENTS_DIR)

    print(f"Discovered: {len(project_paths)} projects, {len(global_skills)} global skills, {len(global_agents)} global agents")

    # ── Phase 2: Detection ────────────────────────────────────────────
    tag_map = extract_vault_tags()
    print(f"Vault: {len(tag_map)} unique tags across {sum(len(v) for v in tag_map.values())} tag instances")

    all_detections: list[dict] = []

    # Detector 1: Skill gaps
    gaps = detect_skill_gaps(tag_map, global_skills)
    all_detections.extend(gaps)
    print(f"Detector 1 (skill gaps): {len(gaps)} found")

    # Detector 2: Stale skills
    stale = detect_skill_staleness(global_skills, tag_map)
    all_detections.extend(stale)
    print(f"Detector 2 (stale skills): {len(stale)} found")

    # Detector 3: Agent enrichment from gotchas
    if not args.global_only:
        enrichments = detect_agent_enrichment(global_agents, project_paths)
        all_detections.extend(enrichments)
        print(f"Detector 3 (agent enrichment): {len(enrichments)} found")
    else:
        print("Detector 3 (agent enrichment): SKIPPED (--global-only)")

    # Detector 4: Missing agent-skill links
    links = detect_agent_skill_links(global_agents, global_skills)
    all_detections.extend(links)
    print(f"Detector 4 (missing links): {len(links)} found")

    # Detector 5: New agent needs
    if not args.global_only:
        needs = detect_new_agent_need(project_paths)
        all_detections.extend(needs)
        print(f"Detector 5 (new agents): {len(needs)} found")
    else:
        print("Detector 5 (new agents): SKIPPED (--global-only)")

    # Filter to single project if specified
    if args.project:
        all_detections = [
            d for d in all_detections
            if args.project in str(d.get("projects", []))
            or args.project == d.get("source_project")
            or args.project == d.get("project")
            or args.project in d.get("scope", "")
        ]
        print(f"Filtered to project '{args.project}': {len(all_detections)} detections")

    print(f"\nTotal detections: {len(all_detections)}")

    if args.detect_only:
        # Output JSON summary
        summary = {
            "timestamp": now_iso(),
            "detections": all_detections,
            "summary": {
                "skill_gaps": len([d for d in all_detections if d["type"] == "skill_gap"]),
                "stale_skills": len([d for d in all_detections if d["type"] == "skill_stale"]),
                "agent_enrichments": len([d for d in all_detections if d["type"] == "agent_enrichment"]),
                "missing_links": len([d for d in all_detections if d["type"] == "agent_link"]),
                "new_agents_needed": len([d for d in all_detections if d["type"] == "new_agent"]),
                "total": len(all_detections),
            },
        }
        print(json.dumps(summary, indent=2, default=str))
        log_evolution(all_detections, [], applied=False)
        return

    if not all_detections:
        print("No evolution opportunities detected.")
        log_evolution([], [], applied=False)
        return

    # ── Phase 3: Proposal Generation ──────────────────────────────────
    print(f"\nGenerating proposals for {min(len(all_detections), MAX_PROPOSALS)} detections...")
    proposals = asyncio.run(generate_proposals(all_detections))
    print(f"Generated {len(proposals)} proposals")

    # ── Phase 4: Write proposals ──────────────────────────────────────
    output_dir = write_proposals(proposals)
    print(f"Proposals written to: {output_dir}")

    log_evolution(all_detections, proposals, applied=args.apply)

    if args.apply:
        result = apply_proposals(proposals)
        print(f"\n--apply: applied {len(result['applied'])}, promoted {len(result['promoted'])}, skipped {len(result['skipped'])}")
        for item in result["applied"]:
            print(f"  applied {item['type']} -> {item['target']} (verified:false, seen {item['seen']})")
        if result["applied"]:
            print("Mutations are tagged verified:false and wrapped in EVOLVE blocks for review and revert.")


if __name__ == "__main__":
    main()
