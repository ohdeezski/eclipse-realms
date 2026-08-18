#!/usr/bin/env bash
# Generate a deterministic release-artifact manifest for one export directory.
# Usage: generate_release_manifest.sh <platform> <artifact-directory> <output-file>

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <platform> <artifact-directory> <output-file>" >&2
  exit 64
fi

platform="$1"
artifact_dir="$2"
output_file="$3"
repo_root="$(git rev-parse --show-toplevel)"
metadata_file="$repo_root/client/release_metadata.json"

if [ ! -d "$artifact_dir" ]; then
  echo "Artifact directory does not exist: $artifact_dir" >&2
  exit 1
fi
if [ ! -f "$metadata_file" ]; then
  echo "Release metadata does not exist: $metadata_file" >&2
  exit 1
fi

release_version="$(sed -n 's/^[[:space:]]*"release_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$metadata_file" | head -n 1)"
content_version="$(sed -n 's/^[[:space:]]*"content_version"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$metadata_file" | head -n 1)"
save_schema_version="$(sed -n 's/^[[:space:]]*"save_schema_version"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$metadata_file" | head -n 1)"
protocol_version="$(sed -n 's/^[[:space:]]*"protocol_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$metadata_file" | head -n 1)"

if [ -z "$release_version" ] || [ -z "$content_version" ] || [ -z "$save_schema_version" ] || [ -z "$protocol_version" ]; then
  echo "Release metadata is missing a required version field" >&2
  exit 1
fi

output_name="$(basename "$output_file")"
mapfile -t artifacts < <(find "$artifact_dir" -type f ! -name "$output_name" -printf '%P\n' | LC_ALL=C sort)
if [ "${#artifacts[@]}" -eq 0 ]; then
  echo "No artifacts found in $artifact_dir" >&2
  exit 1
fi

commit_sha="${GITHUB_SHA:-$(git rev-parse HEAD)}"
godot_version="$(godot --version | head -n 1)"

{
  printf '{\n'
  printf '  "platform": "%s",\n' "$platform"
  printf '  "release_version": "%s",\n' "$release_version"
  printf '  "content_version": %s,\n' "$content_version"
  printf '  "save_schema_version": %s,\n' "$save_schema_version"
  printf '  "protocol_version": "%s",\n' "$protocol_version"
  printf '  "commit_sha": "%s",\n' "$commit_sha"
  printf '  "godot_version": "%s",\n' "$godot_version"
  printf '  "artifacts": [\n'
  for index in "${!artifacts[@]}"; do
    relative_path="${artifacts[$index]}"
    absolute_path="$artifact_dir/$relative_path"
    separator=","
    if [ "$index" -eq $(( ${#artifacts[@]} - 1 )) ]; then
      separator=""
    fi
    printf '    {"path": "%s", "bytes": %s, "sha256": "%s"}%s\n' \
      "$relative_path" \
      "$(wc -c < "$absolute_path" | tr -d ' ')" \
      "$(sha256sum "$absolute_path" | awk '{print $1}')" \
      "$separator"
  done
  printf '  ]\n'
  printf '}\n'
} > "$output_file"

echo "Wrote release manifest: $output_file"
