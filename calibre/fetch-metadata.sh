#!/usr/bin/env bash

shopt -s globstar nullglob

TARGET_DIR="${1:-.}"

cd "$TARGET_DIR" || {
  echo "❌ Cannot cd into $TARGET_DIR"
  exit 1
}

for file in **/*.pdf; do
  echo "📝 Processing: $file"

  # Extract existing title and authors
  title=$(ebook-meta "$file" | awk -F': *' '/^Title/ {print $2}')
  authors=$(ebook-meta "$file" | awk -F': *' '/^Author\(s\)/ {print $2}' | sed 's/, */ \& /g')

  if [[ -z "$title" || -z "$authors" ]]; then
    echo "⚠️  Missing title or authors, skipping: $file"
    continue
  fi

  echo "🔍 Fetching metadata for: $title by $authors"

  # Create a temporary OPF file
  opf_file=$(mktemp --suffix=.opf)

  fetch-ebook-metadata \
    --title "$title" \
    --authors "$authors" \
    --opf >"$opf_file"

  if grep -q '<dc:title' "$opf_file"; then
    echo "✅ Metadata found, embedding into file"
    ebook-meta "$file" --from-opf "$opf_file"
  else
    echo "❌ No metadata found for: $file"
  fi

  rm -f "$opf_file"
done
