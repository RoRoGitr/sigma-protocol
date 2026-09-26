"""Initialize the AI Brain vault directory structure.
Usage:
    uv run python scripts/init_vault.py                          # default ~/Documents/AI Brain/
    uv run python scripts/init_vault.py --vault-path ~/my-brain  # custom path
    uv run python scripts/init_vault.py --dry-run                # preview only
"""
from __future__ import annotations

import argparse
import datetime
import os
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEMPLATES_DIR = ROOT / "templates"


def find_projects(scan_paths: list[Path]) -> list[dict]:
    """Scan directories for projects (dirs with .git, package.json, etc.)."""
    projects = []
    indicators = [".git", "package.json", "pyproject.toml", "Cargo.toml", "CLAUDE.md"]

    for scan_path in scan_paths:
        if not scan_path.exists():
            continue
        try:
            entries = list(scan_path.iterdir())
        except PermissionError:
            continue
        for entry in entries:
            if not entry.is_dir() or entry.name.startswith("."):
                continue
            for indicator in indicators:
                if (entry / indicator).exists():
                    slug = entry.name.lower().replace(" ", "-")
                    projects.append({
                        "name": entry.name,
                        "slug": slug,
                        "path": str(entry),
                    })
                    break

    return projects


def create_vault(vault_path: Path, projects: list[dict], dry_run: bool = False) -> dict:
    """Create the vault directory structure."""
    stats = {"dirs_created": 0, "files_created": 0, "projects_scaffolded": 0}

    # Create base directories
    dirs = [
        "memory",
        "sessions",
        "projects",
        "connections",
        "qa",
        "inbox",
        "inbox/evolution",
        "research",
        "agents",
    ]
    for d in dirs:
        target = vault_path / d
        if not target.exists():
            if not dry_run:
                target.mkdir(parents=True, exist_ok=True)
            stats["dirs_created"] += 1
            print(f"  Created: {d}/")

    # Copy template files
    vault_template = TEMPLATES_DIR / "vault"
    if vault_template.exists():
        for template_file in vault_template.rglob("*.md"):
            rel = template_file.relative_to(vault_template)
            target = vault_path / rel
            if not target.exists():
                if not dry_run:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(template_file, target)
                stats["files_created"] += 1
                print(f"  Copied: {rel}")

    # Scaffold project directories
    project_scaffold = TEMPLATES_DIR / "project-scaffold"
    for project in projects:
        project_dir = vault_path / "projects" / project["slug"]
        if not project_dir.exists():
            if not dry_run:
                project_dir.mkdir(parents=True, exist_ok=True)
                if project_scaffold.exists():
                    for sf in project_scaffold.glob("*.md"):
                        target = project_dir / sf.name
                        content = sf.read_text(encoding="utf-8")
                        content = content.replace("{{project_name}}", project["name"])
                        content = content.replace("{{project_slug}}", project["slug"])
                        content = content.replace("{{project_path}}", project["path"])
                        target.write_text(content, encoding="utf-8")
            stats["projects_scaffolded"] += 1
            print(f"  Scaffolded: projects/{project['slug']}/")

    # Generate index
    if not dry_run:
        index_path = vault_path / "memory" / "index.md"
        if index_path.exists():
            return stats
        index_lines = [
            "---",
            "type: memory",
            f"date: {datetime.date.today().isoformat()}",
            "status: active",
            "tags: [index, meta]",
            "---",
            "",
            "# Memory Index",
            "",
            "Cross-session knowledge organized by topic.",
            "",
            "## Projects",
        ]
        for p in projects:
            index_lines.append(f"- [[projects/{p['slug']}/_index]] — {p['name']}")
        index_lines.extend(["", "## Topics", "(populated by compile.py)", ""])
        index_path.write_text("\n".join(index_lines), encoding="utf-8")

    return stats


def write_config(vault_path: Path, projects: list[dict]) -> None:
    """Write .brain-config.yaml to the repo root."""
    config = {
        "vault_path": str(vault_path),
        "brain_name": vault_path.name,
        "project_map": {p["name"]: p["slug"] for p in projects},
        "autoresearch_cooldown_hours": 24,
        "spawn_min_battery": 15,
        "created": datetime.date.today().isoformat(),
    }
    config_path = ROOT / ".brain-config.yaml"
    try:
        import yaml  # type: ignore

        with open(config_path, "w", encoding="utf-8") as f:
            yaml.dump(config, f, default_flow_style=False)
    except Exception:
        lines = [
            f"vault_path: {config['vault_path']}",
            f"brain_name: {config['brain_name']}",
            f"autoresearch_cooldown_hours: {config['autoresearch_cooldown_hours']}",
            f"spawn_min_battery: {config['spawn_min_battery']}",
            f"created: {config['created']}",
            "project_map:",
        ]
        for name, slug in config["project_map"].items():
            lines.append(f"  {name}: {slug}")
        config_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"  Config: .brain-config.yaml")


def main() -> None:
    parser = argparse.ArgumentParser(description="Initialize the Claude Brain vault")
    parser.add_argument(
        "--vault-path",
        type=str,
        default=str(Path.home() / "Documents" / "AI Brain"),
        help="Path for the Obsidian vault or plain folder (default: ~/Documents/AI Brain/)",
    )
    parser.add_argument(
        "--scan-paths",
        type=str,
        default=None,
        help="Comma-separated paths to scan for projects",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview without creating files",
    )
    args = parser.parse_args()

    vault_path = Path(args.vault_path).expanduser()

    if args.scan_paths:
        scan_paths = [Path(p.strip()).expanduser() for p in args.scan_paths.split(",")]
    else:
        scan_paths = [
            Path.home(),
            Path.home() / "projects",
            Path.home() / "code",
        ]

    print(f"{'[DRY RUN] ' if args.dry_run else ''}Initializing vault at: {vault_path}")

    # Detect projects
    print(f"\nScanning for projects in: {', '.join(str(p) for p in scan_paths)}")
    projects = find_projects(scan_paths)
    print(f"Found {len(projects)} projects")
    for p in projects:
        print(f"  - {p['name']} → {p['slug']}")

    # Create vault
    print(f"\nCreating vault structure:")
    stats = create_vault(vault_path, projects, args.dry_run)

    # Write config
    if not args.dry_run:
        write_config(vault_path, projects)

    # Summary
    print(f"\nDone!")
    print(f"  Directories: {stats['dirs_created']}")
    print(f"  Files: {stats['files_created']}")
    print(f"  Projects: {stats['projects_scaffolded']}")
    print(f"\nNext: Open {vault_path} as an Obsidian vault")
    print(f"Then: Merge hooks from .claude/settings.json into your existing settings")


if __name__ == "__main__":
    main()
