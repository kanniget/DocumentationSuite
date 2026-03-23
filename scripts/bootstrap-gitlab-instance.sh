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

copy_file() {
  local source=$1
  local target=$2
  mkdir -p "$(dirname "$target")"
  cp "$source" "$target"
}

copy_tree() {
  local source_dir=$1
  local target_dir=$2
  mkdir -p "$target_dir"
  cp -R "$source_dir/." "$target_dir/"
}

render_template() {
  local source=$1
  local target=$2
  local site_url_line=""

  if [[ -n $site_url ]]; then
    site_url_line="site_url: $site_url"
  fi

  mkdir -p "$(dirname "$target")"
  sed \
    -e "s|__SITE_NAME__|$site_name|g" \
    -e "s|__REPO_NAME__|$repo_name|g" \
    -e "s|__SITE_URL_LINE__|$site_url_line|g" \
    "$source" > "$target"
}

main() {
  require_command git
  require_command cp
  require_command mkdir
  require_command sed

  mkdir -p "$instance_dir"

  copy_tree "$repo_root/scripts/scaffolds/gitlab-instance" "$instance_dir"
  render_template "$repo_root/scripts/scaffolds/gitlab-instance/docs/index.md" "$instance_dir/docs/index.md"
  render_template "$repo_root/scripts/scaffolds/gitlab-instance/mkdocs.yml" "$instance_dir/mkdocs.yml"

  copy_file "$repo_root/docs/templates/requirements/prd-template.md" "$instance_dir/docs/requirements/prd.md"
  copy_file "$repo_root/docs/templates/requirements/srs-template.md" "$instance_dir/docs/requirements/srs.md"
  copy_file "$repo_root/docs/templates/architecture/system-architecture-template.md" "$instance_dir/docs/architecture/system-architecture.md"
  copy_file "$repo_root/docs/templates/architecture/high-level-design-template.md" "$instance_dir/docs/architecture/high-level-design.md"
  copy_file "$repo_root/docs/templates/architecture/low-level-design-template.md" "$instance_dir/docs/architecture/low-level-design.md"
  copy_file "$repo_root/docs/templates/architecture/interface-control-template.md" "$instance_dir/docs/architecture/interface-control.md"
  copy_file "$repo_root/docs/templates/quality/test-plan-template.md" "$instance_dir/docs/quality/test-plan.md"
  copy_file "$repo_root/docs/templates/quality/verification-validation-template.md" "$instance_dir/docs/quality/verification-validation-plan.md"
  copy_file "$repo_root/docs/templates/operations/runbook-template.md" "$instance_dir/docs/operations/runbook.md"
  copy_file "$repo_root/docs/templates/operations/postmortem-template.md" "$instance_dir/docs/operations/postmortem.md"
  copy_file "$repo_root/docs/templates/operations/release-readiness-template.md" "$instance_dir/docs/operations/release-readiness.md"
  copy_file "$repo_root/docs/templates/governance/adr-template.md" "$instance_dir/docs/governance/adr-001.md"
  copy_file "$repo_root/docs/templates/governance/change-log-template.md" "$instance_dir/docs/governance/change-log.md"
  copy_file "$repo_root/docs/templates/project-management/delivery-plan-template.md" "$instance_dir/docs/project-management/delivery-plan.md"

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

  local commit_status="No new commit created"

  git -C "$instance_dir" add -A

  if ! git -C "$instance_dir" rev-parse --verify HEAD >/dev/null 2>&1; then
    git -C "$instance_dir" commit -m "initial build" >/dev/null
    commit_status='Committed generated files with message: initial build'
  elif ! git -C "$instance_dir" diff --cached --quiet; then
    git -C "$instance_dir" commit -m "initial build" >/dev/null
    commit_status='Committed generated files with message: initial build'
  fi

  git -C "$instance_dir" push -u origin main >/dev/null

  cat <<SUMMARY
Created documentation repository at: $instance_dir
Configured remote origin: $remote_url
$commit_status
Pushed branch: main

Next steps:
  1. Review the copied templates and adjust the generated mkdocs.yml navigation if needed.
  2. Replace placeholder values in docs/index.md and the copied templates.
  3. Configure DOC_LIBRARY_TRIGGER_URL and DOC_LIBRARY_TRIGGER_TOKEN in GitLab CI/CD variables to notify the central library pipeline.
SUMMARY
}

main "$@"
