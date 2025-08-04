#!/usr/bin/env bash
shopt -s globstar nullglob

TARGET_DIR="$(realpath "${1:-.}")"
cd "$TARGET_DIR" || {
  echo "❌ Cannot cd into $TARGET_DIR"
  exit 1
}

log_file="$TARGET_DIR/pdf_metadata.log"
[[ -e $log_file ]] && rm "$log_file"

pdf_files=(**/*.pdf)
if [[ ${#pdf_files[@]} -eq 0 ]]; then
  echo "❌ No PDF files found in $TARGET_DIR" | tee -a "$log_file"
  exit 1
fi

total_files=${#pdf_files[@]}
bar_progress=0

draw_progress_bar() {
  local progress=$1 total=$2 width=50
  local percent=$((100 * progress / total))
  local filled=$((width * progress / total))
  local empty=$((width - filled))
  local bar
  bar="$(printf "%${filled}s" | tr ' ' '#')$(printf "%${empty}s")"

  tput sc
  tput cup $(($(tput lines) - 1)) 0
  printf "\rProgress: [%-${width}s] %3d%% (%d/%d)" "$bar" "$percent" "$progress" "$total"
  tput rc
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$log_file"
  draw_progress_bar "$bar_progress" "$total_files"
}

# Group files by directory (series)
declare -A series_files
for file in "${pdf_files[@]}"; do
  dir="$(dirname "$file")"
  series_files["$dir"]+="$file"$'\n'
done

for dir in "${!series_files[@]}"; do
  IFS=$'\n' read -rd '' -a files <<<"$(printf '%s' "${series_files["$dir"]}" | sort)"
  for idx in "${!files[@]}"; do
    ((current_file++))
    file="${files[$idx]}"
    series_dir=$(basename "$dir")
    series_index=$((idx + 1))

    log "($current_file/$total_files) Processing: $file"

    title=$(ebook-meta "$file" | awk -F': *' '/^Title/ {print $2}')
    authors=$(ebook-meta "$file" | awk -F': *' '/^Author\(s\)/ {print $2}' | sed 's/, */ \& /g')

    if [[ -z "$title" || -z "$authors" ]]; then
      log "($current_file/$total_files) Missing title or authors, skipping: $file"
      ((bar_progress++))
      continue
    fi

    log "($current_file/$total_files) Fetching metadata for: $title by $authors"
    opf_file=$(mktemp --suffix=.opf)
    fetch-ebook-metadata --title "$title" --authors "$authors" --opf >"$opf_file" 2>>"$log_file"

    if grep -q '<dc:title' "$opf_file"; then
      ebook-meta "$file" --from-opf "$opf_file" --series "$series_dir" --index "$series_index" >>"$log_file" 2>&1
      log "($current_file/$total_files) ✅ Metadata found, embedding into file for: $file"
    else
      log "($current_file/$total_files) ❌ No metadata found for: $file"
      metadata=()
      while IFS=':' read -r key value; do
        key=$(echo "$key" | tr -d '\r' | xargs)
        value=$(echo "$value" | xargs)
        case "$key" in
        Title) metadata+=(--title "$value") ;;
        "Author(s)")
          stripped_authors=$(echo "$value" | sed 's/\[[^][]*\]//g' | xargs)
          metadata+=(--authors "$stripped_authors")
          ;;
        Publisher) metadata+=(--publisher "$value") ;;
        Tags) metadata+=(--tags "$value") ;;
        Languages) metadata+=(--language "$value") ;;
        Series) metadata+=(--series "$series_dir") ;; # Override with folder name
        "Series Index") continue ;;                   # Ignore OPF value
        Rating) metadata+=(--rating "$value") ;;
        Published) metadata+=(--date "$value") ;;
        Identifiers)
          while IFS=',' read -ra ids; do
            for id in "${ids[@]}"; do
              key_val=$(echo "$id" | xargs)
              id_type=${key_val%%:*}
              id_val=${key_val#*:}
              metadata+=(--identifier "$id_type:$id_val")
            done
          done <<<"$value"
          ;;
        esac
      done < <(ebook-meta "$file")

      metadata+=(--series "$series_dir" --index "$series_index")
      ebook-meta "$file" "${metadata[@]}" >>"$log_file" 2>&1
      log "($current_file/$total_files) ✔️ Metadata extracted from file for: $file"
    fi

    rm -f "$opf_file"
    ((bar_progress++))
  done
done

draw_progress_bar "$bar_progress" "$total_files"
echo ""
tput cup "$(tput lines)" 0 && echo ""
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 📚 Changes made written in $log_file"
