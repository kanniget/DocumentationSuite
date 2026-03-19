#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bootstrap-central-doc-library.sh <directory> <repo-name>

Creates a new MkDocs-based central documentation library repository in
<directory>/<repo-name>, initializes a Git repository, configures the remote,
and writes a GitLab CI pipeline that can ingest notifications from individual
documentation repositories.

Environment variables:
  GIT_REMOTE_BASE         Base remote prefix used when <repo-name> is not already a URL.
                          Examples:
                            git@gitlab.example.com:platform
                            https://gitlab.example.com/platform
  DOC_LIBRARY_SITE_NAME   Optional display name for the generated documentation library site.
  DOC_LIBRARY_SITE_URL    Optional published site URL to place in mkdocs.yml.
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
destination_root=$1
repo_name=$2
instance_dir="$destination_root/$repo_name"
site_name=${DOC_LIBRARY_SITE_NAME:-Central Documentation Library}
site_url=${DOC_LIBRARY_SITE_URL:-}

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

write_docs_home() {
  cat > "$instance_dir/docs/index.md" <<INDEX
# ${site_name}

This site aggregates links and metadata for documentation repositories published
across the platform.

## What This Repository Does

- hosts a searchable landing page for available documentation sets
- tracks the latest source reference reported by each contributing repository
- provides a central GitLab pipeline target for documentation publish notifications

## Getting Started

1. Review \`docs/library/index.md\` to verify the generated catalog layout.
2. Set the CI/CD variables described in \`docs/library/contributing.md\`.
3. Point project documentation pipelines at this repository's trigger endpoint.
4. Replace placeholder values with team-specific ownership and support details.
INDEX
}

write_docs_library_index() {
  cat > "$instance_dir/docs/library/index.md" <<'INDEX'
# Documentation Catalog

The catalog is generated from `data/doc-sources.csv`.

| Project | Default Ref | Last Reported SHA | Site URL | Last Updated (UTC) |
| --- | --- | --- | --- | --- |
| _No documentation sources registered yet._ | - | - | - | - |
INDEX
}

write_docs_contributing() {
  cat > "$instance_dir/docs/library/contributing.md" <<'CONTRIB'
# Contributing a Documentation Source

Each source documentation repository can notify this central library after a
successful publish.

## Required Variables in the Source Repository

Configure the following variables in the source repository's GitLab CI/CD
settings:

- `DOC_LIBRARY_TRIGGER_URL`: pipeline trigger URL for this repository
- `DOC_LIBRARY_TRIGGER_TOKEN`: pipeline trigger token for this repository
- `DOC_LIBRARY_TRIGGER_REF`: optional branch or tag in this repository to run

The source repository should submit these variables when triggering the central
pipeline:

- `DOC_SOURCE_PROJECT`: GitLab project path, such as `platform/payments-docs`
- `DOC_SOURCE_REF`: source branch or tag that was published
- `DOC_SOURCE_SHA`: commit SHA that produced the publish
- `DOC_SOURCE_URL`: optional published documentation URL
- `DOC_SOURCE_PIPELINE_URL`: optional source pipeline URL

## Optional Variables in This Repository

Set these variables if you want catalog updates to be committed back into this
repository automatically:

- `DOC_LIBRARY_PUSH_TOKEN`: token with permission to push to the default branch
- `DOC_LIBRARY_PUSH_USERNAME`: username to use for Git commits and pushes
- `DOC_LIBRARY_PUSH_EMAIL`: email to use for Git commits

Without push credentials, the pipeline will still validate and publish the site,
but catalog updates reported by trigger variables will not be persisted.
CONTRIB
}

write_csv_seed() {
  cat > "$instance_dir/data/doc-sources.csv" <<'CSV'
project,ref,sha,site_url,pipeline_url,updated_at
CSV
}

write_catalog_renderer() {
  cat > "$instance_dir/scripts/update-doc-library-catalog.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
csv_file="$repo_root/data/doc-sources.csv"
output_file="$repo_root/docs/library/index.md"

die() {
  echo "Error: $*" >&2
  exit 1
}

escape_markdown() {
  local value=${1:-}
  value=${value//|/\\|}
  printf '%s' "$value"
}

ensure_csv_exists() {
  if [[ ! -f $csv_file ]]; then
    mkdir -p "$(dirname "$csv_file")"
    cat > "$csv_file" <<'CSV'
project,ref,sha,site_url,pipeline_url,updated_at
CSV
  fi
}

upsert_from_env() {
  local project=${DOC_SOURCE_PROJECT:-}
  local ref=${DOC_SOURCE_REF:-}
  local sha=${DOC_SOURCE_SHA:-}
  local site_url=${DOC_SOURCE_URL:-}
  local pipeline_url=${DOC_SOURCE_PIPELINE_URL:-}
  local updated_at

  [[ -n $project ]] || return 0
  [[ -n $ref ]] || die "DOC_SOURCE_REF is required when DOC_SOURCE_PROJECT is set"
  [[ -n $sha ]] || die "DOC_SOURCE_SHA is required when DOC_SOURCE_PROJECT is set"

  updated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local temp_file
  temp_file=$(mktemp)

  awk -F',' -v OFS=',' \
    -v project="$project" \
    -v ref="$ref" \
    -v sha="$sha" \
    -v site_url="$site_url" \
    -v pipeline_url="$pipeline_url" \
    -v updated_at="$updated_at" '
      NR == 1 { print; next }
      $1 == project {
        print project, ref, sha, site_url, pipeline_url, updated_at
        found = 1
        next
      }
      { print }
      END {
        if (!found) {
          print project, ref, sha, site_url, pipeline_url, updated_at
        }
      }
    ' "$csv_file" > "$temp_file"

  mv "$temp_file" "$csv_file"
}

render_catalog() {
  mkdir -p "$(dirname "$output_file")"

  {
    cat <<'HEADER'
# Documentation Catalog

The catalog is generated from `data/doc-sources.csv`.

| Project | Default Ref | Last Reported SHA | Site URL | Last Updated (UTC) |
| --- | --- | --- | --- | --- |
HEADER

    if [[ $(wc -l < "$csv_file") -le 1 ]]; then
      printf '| _No documentation sources registered yet._ | - | - | - | - |\n'
      exit 0
    fi

    tail -n +2 "$csv_file" | sort | while IFS=',' read -r project ref sha site_url pipeline_url updated_at; do
      project=$(escape_markdown "$project")
      ref=$(escape_markdown "$ref")
      sha=$(escape_markdown "$sha")
      site_url=$(escape_markdown "$site_url")
      pipeline_url=$(escape_markdown "$pipeline_url")
      updated_at=$(escape_markdown "$updated_at")

      if [[ -n $site_url ]]; then
        site_url="[link]($site_url)"
      else
        site_url='-'
      fi

      if [[ -n $pipeline_url ]]; then
        project="[$project]($pipeline_url)"
      fi

      printf '| %s | `%s` | `%s` | %s | %s |\n' \
        "$project" "$ref" "$sha" "$site_url" "${updated_at:--}"
    done
  } > "$output_file"
}

ensure_csv_exists
upsert_from_env
render_catalog
SCRIPT

  chmod +x "$instance_dir/scripts/update-doc-library-catalog.sh"
}

write_mkdocs_config() {
  cat > "$instance_dir/mkdocs.yml" <<MKDOCS
site_name: ${site_name}
site_description: Central catalog for published documentation repositories
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
  - Library:
      - Catalog: library/index.md
      - Contributing Sources: library/contributing.md
repo_name: ${repo_name}
edit_uri: ""
MKDOCS
}

write_gitlab_ci() {
  cat > "$instance_dir/.gitlab-ci.yml" <<'GITLABCI'
stages:
  - update
  - validate
  - publish

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
    - pip install mkdocs-material

update_catalog:
  extends: .default_python
  stage: update
  script:
    - bash scripts/update-doc-library-catalog.sh
    - |
      if [ -z "$DOC_SOURCE_PROJECT" ]; then
        echo "No DOC_SOURCE_PROJECT supplied; skipping catalog persistence."
        exit 0
      fi
      if [ -z "$DOC_LIBRARY_PUSH_TOKEN" ] || [ -z "$DOC_LIBRARY_PUSH_USERNAME" ] || [ -z "$DOC_LIBRARY_PUSH_EMAIL" ]; then
        echo "Push credentials are not configured; catalog changes will not be committed back."
        exit 0
      fi
      git config user.name "$DOC_LIBRARY_PUSH_USERNAME"
      git config user.email "$DOC_LIBRARY_PUSH_EMAIL"
      if git diff --quiet -- docs/library/index.md data/doc-sources.csv; then
        echo "No catalog changes detected."
        exit 0
      fi
      git add docs/library/index.md data/doc-sources.csv
      git commit -m "Update documentation catalog for $DOC_SOURCE_PROJECT"
      remote_url="https://${DOC_LIBRARY_PUSH_USERNAME}:${DOC_LIBRARY_PUSH_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git"
      git push "$remote_url" HEAD:$CI_DEFAULT_BRANCH
  rules:
    - if: '$DOC_SOURCE_PROJECT'
    - when: manual

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
GITLABCI
}

write_gitignore() {
  cat > "$instance_dir/.gitignore" <<'IGNORE'
site/
.cache/
IGNORE
}

main() {
  require_command git
  require_command mkdir

  mkdir -p "$instance_dir/docs/library" "$instance_dir/data" "$instance_dir/scripts"

  write_docs_home
  write_docs_library_index
  write_docs_contributing
  write_csv_seed
  write_catalog_renderer
  write_mkdocs_config
  write_gitlab_ci
  write_gitignore

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
Created central documentation library repository at: $instance_dir
Configured remote origin: $remote_url

Next steps:
  1. Review docs/library/contributing.md and configure the CI/CD variables it describes.
  2. Create a pipeline trigger token in this repository and provide the trigger URL/token to source documentation repositories.
  3. Commit the generated files in the new repository.
SUMMARY
}

main "$@"
