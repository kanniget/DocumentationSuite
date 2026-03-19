#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bootstrap-gitlab-instance.sh <directory> <repo-name>

Creates a new MkDocs-based documentation instance in <directory>/<repo-name>,
initializes a Git repository, configures the remote, copies the documentation
suite templates, and writes a GitLab CI pipeline.

Environment variables:
  GIT_REMOTE_BASE   Base remote prefix used when <repo-name> is not already a URL.
                    Examples:
                      git@gitlab.example.com:platform
                      https://gitlab.example.com/platform
                    The script appends "/<repo-name>.git" for HTTP(S) bases and
                    "<separator><repo-name>.git" for SSH-style bases.
  DOCS_SITE_URL     Optional published site URL to place in mkdocs.yml.
  DOCS_SITE_NAME    Optional display name for the generated documentation site.
USAGE
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 2 ]]; then
  usage >&2
  exit 1
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

destination_root=$1
repo_name=$2
instance_dir="$destination_root/$repo_name"
site_name=${DOCS_SITE_NAME:-$repo_name}
site_url=${DOCS_SITE_URL:-}

die() {
  echo "Error: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

build_remote_url() {
  local input=$1
  local base=${GIT_REMOTE_BASE:-}

  if [[ $input =~ ^(https?|ssh):// ]] || [[ $input == git@*:* ]]; then
    printf '%s\n' "$input"
    return 0
  fi

  [[ -n $base ]] || die "GIT_REMOTE_BASE must be set when repo-name is not already a Git URL"

  base=${base%/}
  if [[ $base =~ ^https?:// ]]; then
    printf '%s/%s.git\n' "$base" "$input"
  elif [[ $base == *:* ]]; then
    printf '%s/%s.git\n' "$base" "$input"
  else
    printf '%s/%s.git\n' "$base" "$input"
  fi
}

copy_template() {
  local source=$1
  local target=$2
  mkdir -p "$(dirname "$target")"
  cp "$source" "$target"
}

write_index() {
  cat > "$instance_dir/docs/index.md" <<INDEX
# ${site_name}

Welcome to the documentation set for **${site_name}**.

Use the navigation to browse requirements, architecture, quality, operations,
governance, and delivery planning artifacts.

## Repository Metadata

- **Repository:** ${repo_name}
- **Status:** Draft
- **Owner:** <team>
- **Last Reviewed:** <yyyy-mm-dd>

## Getting Started

1. Replace placeholder values such as \`<system-name>\` and \`<date>\`.
2. Remove sections that do not apply to your system.
3. Add links between related documents to improve traceability.
4. Update the GitLab CI variables if you want to notify a central document library pipeline after successful builds.
INDEX
}

write_mkdocs_config() {
  cat > "$instance_dir/mkdocs.yml" <<MKDOCS
site_name: ${site_name}
site_description: Documentation for ${site_name}
${site_url:+site_url: ${site_url}}
theme:
  name: material
markdown_extensions:
  - admonition
  - attr_list
  - def_list
  - footnotes
  - md_in_html
  - tables
  - toc:
      permalink: true
plugins:
  - search
nav:
  - Home: index.md
  - Requirements:
      - Product Requirements Document: requirements/prd.md
      - Software Requirements Specification: requirements/srs.md
  - Architecture:
      - System Architecture: architecture/system-architecture.md
      - High-Level Design: architecture/high-level-design.md
      - Low-Level Design: architecture/low-level-design.md
      - Interface Control: architecture/interface-control.md
  - Quality:
      - Test Plan: quality/test-plan.md
      - Verification and Validation Plan: quality/verification-validation-plan.md
  - Operations:
      - Runbook: operations/runbook.md
      - Postmortem: operations/postmortem.md
      - Release Readiness: operations/release-readiness.md
  - Governance:
      - Architecture Decision Record: governance/adr-001.md
      - Change Log: governance/change-log.md
  - Project Management:
      - Delivery Plan: project-management/delivery-plan.md
repo_name: ${repo_name}
edit_uri: ""
MKDOCS
}

write_gitlab_ci() {
  cat > "$instance_dir/.gitlab-ci.yml" <<'GITLABCI'
stages:
  - validate
  - publish
  - notify

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"
  MKDOCS_BUILD_STRICT: "true"

cache:
  paths:
    - .cache/pip

.default_python:
  image: python:3.12-slim
  before_script:
    - python --version
    - pip install --upgrade pip
    - pip install mkdocs-material mkdocs-git-revision-date-localized-plugin mike

validate_docs:
  extends: .default_python
  stage: validate
  script:
    - if [ "$MKDOCS_BUILD_STRICT" = "true" ]; then mkdocs build --strict; else mkdocs build; fi
  artifacts:
    paths:
      - site/
    expire_in: 1 week

pages:
  extends: .default_python
  stage: publish
  script:
    - if [ "$MKDOCS_BUILD_STRICT" = "true" ]; then mkdocs build --strict; else mkdocs build; fi
    - mv site public
  artifacts:
    paths:
      - public
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'

publish_version:
  extends: .default_python
  stage: publish
  script:
    - mike deploy --update-aliases "$CI_COMMIT_TAG" latest
    - mike set-default latest
  rules:
    - if: '$CI_COMMIT_TAG'

notify_document_library:
  image: curlimages/curl:8.7.1
  stage: notify
  needs:
    - job: pages
      optional: true
    - job: publish_version
      optional: true
  script:
    - |
      if [ -z "$DOC_LIBRARY_TRIGGER_URL" ] || [ -z "$DOC_LIBRARY_TRIGGER_TOKEN" ]; then
        echo "Document library trigger variables are not configured; skipping notification."
        exit 0
      fi
      curl --fail --request POST \
        --form token="$DOC_LIBRARY_TRIGGER_TOKEN" \
        --form ref="${DOC_LIBRARY_TRIGGER_REF:-main}" \
        --form "variables[DOC_SOURCE_PROJECT]=$CI_PROJECT_PATH" \
        --form "variables[DOC_SOURCE_REF]=$CI_COMMIT_REF_NAME" \
        --form "variables[DOC_SOURCE_SHA]=$CI_COMMIT_SHA" \
        "$DOC_LIBRARY_TRIGGER_URL"
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
    - if: '$CI_COMMIT_TAG'
GITLABCI
}

main() {
  require_command git
  require_command cp
  require_command mkdir

  mkdir -p "$instance_dir"

  copy_template "$repo_root/docs/templates/requirements/prd-template.md" "$instance_dir/docs/requirements/prd.md"
  copy_template "$repo_root/docs/templates/requirements/srs-template.md" "$instance_dir/docs/requirements/srs.md"
  copy_template "$repo_root/docs/templates/architecture/system-architecture-template.md" "$instance_dir/docs/architecture/system-architecture.md"
  copy_template "$repo_root/docs/templates/architecture/high-level-design-template.md" "$instance_dir/docs/architecture/high-level-design.md"
  copy_template "$repo_root/docs/templates/architecture/low-level-design-template.md" "$instance_dir/docs/architecture/low-level-design.md"
  copy_template "$repo_root/docs/templates/architecture/interface-control-template.md" "$instance_dir/docs/architecture/interface-control.md"
  copy_template "$repo_root/docs/templates/quality/test-plan-template.md" "$instance_dir/docs/quality/test-plan.md"
  copy_template "$repo_root/docs/templates/quality/verification-validation-template.md" "$instance_dir/docs/quality/verification-validation-plan.md"
  copy_template "$repo_root/docs/templates/operations/runbook-template.md" "$instance_dir/docs/operations/runbook.md"
  copy_template "$repo_root/docs/templates/operations/postmortem-template.md" "$instance_dir/docs/operations/postmortem.md"
  copy_template "$repo_root/docs/templates/operations/release-readiness-template.md" "$instance_dir/docs/operations/release-readiness.md"
  copy_template "$repo_root/docs/templates/governance/adr-template.md" "$instance_dir/docs/governance/adr-001.md"
  copy_template "$repo_root/docs/templates/governance/change-log-template.md" "$instance_dir/docs/governance/change-log.md"
  copy_template "$repo_root/docs/templates/project-management/delivery-plan-template.md" "$instance_dir/docs/project-management/delivery-plan.md"

  write_index
  write_mkdocs_config
  write_gitlab_ci

  if [[ ! -d "$instance_dir/.git" ]]; then
    git -C "$instance_dir" init -b main >/dev/null
  fi

  local remote_url
  remote_url=$(build_remote_url "$repo_name")
  if git -C "$instance_dir" remote get-url origin >/dev/null 2>&1; then
    git -C "$instance_dir" remote set-url origin "$remote_url"
  else
    git -C "$instance_dir" remote add origin "$remote_url"
  fi

  if ! git -C "$instance_dir" rev-parse --verify HEAD >/dev/null 2>&1; then
    git -C "$instance_dir" add .
  fi

  cat <<SUMMARY
Created documentation instance at: $instance_dir
Configured remote origin: $remote_url

Next steps:
  1. Review and update placeholders in docs/.
  2. Commit the generated files in the new repository.
  3. Configure DOC_LIBRARY_TRIGGER_URL and DOC_LIBRARY_TRIGGER_TOKEN in GitLab CI/CD variables to notify the central library pipeline.
SUMMARY
}

main "$@"
