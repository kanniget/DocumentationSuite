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
