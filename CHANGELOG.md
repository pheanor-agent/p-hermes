# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- B1 Wiki overview document (`docs/wiki/getting-started/overview.md`) — 2,500+ characters
- Spec-Driven Dev 2.0 system (sdd-inject.py, sdd-validate.py, sdd-lint.py)
- SDD 2.0 integrated deployment pipeline (`src/deploy.sh`)
- 8 slide decks with CALMER framework restructuring
- Expression D1-based quality improvements across all docs
- Spec D04/D05 approved (domain mapping, font stack, slide density)
- Git repository initialization + remote configuration

### Changed
- Spec D03: Updated to v1.2.0 (GitHub Pages absolute URL + internal relative paths)
- Spec D04: Updated to v1.0.1 (all Blog = technical blog, domain-based length tiers)
- Spec D05: Updated to v1.1.0 (light theme, font stack, slide density grades)
- Architecture docs: 9-section structure with Mermaid diagrams
- Removed negative-contrast patterns across all docs
- Fixed broken links (10 issues resolved)

### Fixed
- GitHub Pages slide HTML rendering (39-byte issue resolved)
- Mobile slide diagram visibility (JOB-1696 Rev.4 design pending)
- Font loading: Added Noto Sans KR + Mono KR to Google Fonts
- YAML frontmatter: Added author, status, tags, related_specs fields

### Removed
- No deletions (archive-only policy)

---

## [1.0.0] - 2026-06-13

### Added
- Repository initialization
- `README.md` — System overview and quick start
- `ARCHITECTURE.md` — Full 3-tier architecture with diagrams
- `PORTING.md` — Environment setup guide
- `docs/` — Detailed Wiki reference documentation
- `docs/systems/` — Individual system deep-dives
- `LICENSE` — MIT License
- `.gitignore`, `.nojekyll` — GitHub Pages configuration

### Notes
- This repository contains **system architecture documentation only**
- No sensitive information (API keys, tokens, personal data) is included
- Actual job data, novels, research content are excluded
- For porting to a new environment, see [PORTING.md](PORTING.md)

---

## [1.0.0] - 2026-06-13

### Added
- Repository initialization
- `README.md` — System overview and quick start
- `ARCHITECTURE.md` — Full 3-tier architecture with diagrams
- `PORTING.md` — Environment setup guide
- `docs/` — Detailed Wiki reference documentation
- `docs/systems/` — Individual system deep-dives
- `LICENSE` — MIT License
- `.gitignore`, `.nojekyll` — GitHub Pages configuration
