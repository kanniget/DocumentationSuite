# Documentation Suite

A starter repository for systems and software engineering documentation written in Markdown.

## Purpose

This repository provides a practical baseline for documenting:

- product and system requirements
- software architecture, high-level design, low-level design, and decision records
- delivery plans and release readiness
- operational procedures and incident response
- quality strategy and test planning
- governance artifacts such as decision records and change logs

The structure is intentionally lightweight so teams can adopt it quickly and tailor it to their domain.

## Repository Structure

```text
.
├── docs/
│   ├── templates/
│   │   ├── architecture/
│   │   ├── governance/
│   │   ├── operations/
│   │   ├── project-management/
│   │   ├── quality/
│   │   └── requirements/
│   ├── examples/
│   │   └── order-status-platform/
│   └── TEMPLATE_INDEX.md
└── .github/
    └── pull_request_template.md
```

## Getting Started

1. Review `docs/TEMPLATE_INDEX.md` to find the right template.
2. Review `docs/examples/order-status-platform/` for a filled-out sample implementation of the templates.
3. Copy the chosen template into your working documentation area.
4. Replace placeholder values such as `<system-name>` and `<date>`.
5. Remove sections that do not apply and add domain-specific detail.
6. Keep decisions, assumptions, and open questions explicit.

## Suggested Usage Model

- Use `requirements` templates early in discovery and planning.
- Use `architecture` templates during solution design and technical review, from system context through HLD and DLD detail.
- Use `quality` templates before implementation and test execution.
- Use `operations` templates before production rollout and during support.
- Use `governance` templates for durable decision history.
- Use `project-management` templates for delivery coordination.

## Conventions

- Prefer one artifact per concern.
- Use stable IDs where possible for traceability.
- Link related documents together.
- Capture owners and review dates for living documents.
- Record status explicitly so readers know whether a document is draft, active, or superseded.

## Next Steps

Consider extending this suite with:

- domain-specific templates for cloud, data, security, or compliance
- automation for generating new documents from templates
- markdown linting and formatting checks
- a published documentation site using MkDocs, Docusaurus, or similar tooling
- more end-to-end example implementations for additional domains

## Bootstrapping a Central Documentation Library

Use `scripts/bootstrap-central-doc-library.sh` to create a GitLab-hosted central documentation catalog that receives publish notifications from project documentation repositories.

```bash
export GIT_REMOTE_BASE="git@gitlab.example.com:platform"
./scripts/bootstrap-central-doc-library.sh /path/to/workspace central-doc-library
```

The script will:

- create `/path/to/workspace/central-doc-library/` if it does not already exist
- initialize a Git repository on the `main` branch
- configure the `origin` remote using `GIT_REMOTE_BASE` and the repo name, unless the repo parameter is already a full Git URL
- scaffold a small MkDocs site for the central catalog
- seed a `data/doc-sources.csv` registry and a renderer script that turns it into a browsable catalog page
- generate a `.gitlab-ci.yml` that can ingest `DOC_SOURCE_*` trigger variables, optionally commit catalog updates back to the default branch, and publish the site with GitLab Pages

Optional environment variables:

- `DOC_LIBRARY_SITE_NAME` to override the generated site name
- `DOC_LIBRARY_SITE_URL` to set the published site URL in `mkdocs.yml`

## Bootstrapping a GitLab Documentation Instance

Use `scripts/bootstrap-gitlab-instance.sh` to create a new MkDocs-based documentation repository from this suite.

```bash
export GIT_REMOTE_BASE="git@gitlab.example.com:platform"
./scripts/bootstrap-gitlab-instance.sh /path/to/workspace order-status-docs
```

The script will:

- create `/path/to/workspace/order-status-docs/` if it does not already exist
- initialize a Git repository on the `main` branch
- configure the `origin` remote using `GIT_REMOTE_BASE` and the repo name, unless the repo parameter is already a full Git URL
- scaffold a `docs/` tree from the templates in this repository
- generate an `mkdocs.yml` configured for Material for MkDocs
- generate a `.gitlab-ci.yml` that validates the docs, publishes GitLab Pages from the default branch, publishes tagged versions with `mike`, and can notify a central document library pipeline

Optional environment variables:

- `DOCS_SITE_NAME` to override the generated MkDocs site name
- `DOCS_SITE_URL` to set the published site URL in `mkdocs.yml`
- `DOC_LIBRARY_TRIGGER_URL`, `DOC_LIBRARY_TRIGGER_TOKEN`, and `DOC_LIBRARY_TRIGGER_REF` in GitLab CI/CD variables to notify a central document library pipeline after a successful publish
