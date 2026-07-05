# dsir-country-profile — agent skill

An [Agent Skill](https://agentskills.io) that wraps the
[DSIR](https://github.com/shanlong-who/DSIR) R package workflow: pull
WHO GHO / UN SDG indicator data, clean it to the unified 15-column
schema, and generate country profiles (trend charts, AARR progress
table, markdown summary).

## Requirements

R (>= 4.1) with the packages `DSIR` (>= 0.8.0), `dplyr`, `readr`,
`ggplot2` installed. Everything else is plain `Rscript` — no other
runtime needed.

## Install in Claude Code (one command per step)

```
/plugin marketplace add shanlong-who/DSIR
/plugin install dsir-country-profile@dsir
```

Note the part after `@` is the marketplace *name* (`dsir`, defined in
`.claude-plugin/marketplace.json`), not the repository name. Once
installed, the skill triggers automatically on requests like "get life
expectancy for the Philippines" or "make a health profile for Viet
Nam"; invoke it explicitly with
`/dsir-country-profile:dsir-country-profile`.

Working inside this repository? Nothing to install — the skill is
picked up automatically from `.claude/skills/`.

## Other agents

- **GitHub Copilot**: the skill is mirrored at
  `.github/skills/dsir-country-profile/`, where Copilot discovers it
  automatically in this repository.
- **Gemini CLI**: compatible as-is (the SKILL.md frontmatter uses only
  the portable `name` / `description` fields). Copy this folder into
  the agent's skills directory (e.g. `.gemini/skills/` in a project,
  or the user-level equivalent) — no changes needed.

## Maintenance note

The canonical copy lives in `.claude/skills/dsir-country-profile/`;
`.github/skills/dsir-country-profile/` is a mirror (symlinks are not
reliable on Windows checkouts). After editing the skill, refresh the
mirror:

```powershell
# PowerShell (repo root)
Copy-Item -Force .claude/skills/dsir-country-profile/SKILL.md .github/skills/dsir-country-profile/
Copy-Item -Recurse -Force .claude/skills/dsir-country-profile/scripts, .claude/skills/dsir-country-profile/references .github/skills/dsir-country-profile/
```

```bash
# bash (repo root)
cp .claude/skills/dsir-country-profile/SKILL.md .github/skills/dsir-country-profile/
cp -r .claude/skills/dsir-country-profile/{scripts,references} .github/skills/dsir-country-profile/
```

(`README.md` and `.claude-plugin/` are Claude-Code packaging and are
deliberately not mirrored.)
