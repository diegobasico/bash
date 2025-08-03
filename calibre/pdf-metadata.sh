#!/usr/bin/env bash

shopt -s globstar nullglob

TARGET_DIR="$(realpath "${1:-.}")"

cd "$TARGET_DIR" || {
  echo "❌ Cannot cd into $TARGET_DIR"
  exit 1
}

log_file="$TARGET_DIR/pdf_metadata.log"

pdf_files=(**/*.pdf)

if [[ ${#pdf_files[@]} -eq 0 ]]; then
  echo "❌ No PDF files found in $TARGET_DIR" | tee -a "$log_file"
  exit 1
fi

for file in **/*.pdf; do
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 📝 Processing: $file" | tee -a "$log_file"

  title=$(ebook-meta "$file" | awk -F': *' '/^Title/ {print $2}')
  authors=$(ebook-meta "$file" | awk -F': *' '/^Author\(s\)/ {print $2}' | sed 's/, */ \& /g')

  if [[ -z "$title" || -z "$authors" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  Missing title or authors, skipping: $file" | tee -a "$log_file"
    continue
  fi

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔍 Fetching metadata for: $title by $authors" | tee -a "$log_file"

  opf_file=$(mktemp --suffix=.opf)

  fetch-ebook-metadata \
    --title "$title" \
    --authors "$authors" \
    --opf >"$opf_file"

  if grep -q '<dc:title' "$opf_file"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Metadata found, embedding into file for: $file" | tee -a "$log_file"
    ebook-meta "$file" --from-opf "$opf_file" >>"$log_file" 2>&1
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ No metadata found for: $file" | tee -a "$log_file"
  fi

  rm -f "$opf_file"
done

echo "Changes made written in $log_file"
