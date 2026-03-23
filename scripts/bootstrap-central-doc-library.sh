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
  require_command mkdir
  require_command cp
  require_command sed

  mkdir -p "$instance_dir"

  copy_tree "$script_dir/scaffolds/central-doc-library" "$instance_dir"
  render_template "$script_dir/scaffolds/central-doc-library/docs/index.md" "$instance_dir/docs/index.md"
  render_template "$script_dir/scaffolds/central-doc-library/mkdocs.yml" "$instance_dir/mkdocs.yml"

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
    git -C "$instance_dir" add -A
    git -C "$instance_dir" commit -m "initial build" >/dev/null
    git -C "$instance_dir" push -u origin main
  fi

  cat <<SUMMARY
Created central documentation library repository at: $instance_dir
Configured remote origin: $remote_url

Next steps:
  1. Review docs/library/contributing.md and configure the CI/CD variables it describes.
  2. Create a pipeline trigger token in this repository and provide the trigger URL/token to source documentation repositories.
  3. Verify the initial build commit on origin/main and continue catalog configuration.
  4. Ensure GitLab runners can resolve the GitLab hostname configured by `external_url`; artifact uploads and Pages publishes depend on coordinator connectivity.
SUMMARY
}

main "$@"
