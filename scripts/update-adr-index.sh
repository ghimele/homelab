#!/bin/bash

# Path to the ADR directory
ADR_DIR="./docs/adr"
INDEX_FILE="$ADR_DIR/ADR-000-Index.md"
TEMPLATE_FILE="$ADR_DIR/ADR-000-Template.md"

# Initialize content for different status categories
accepted_records=""
rejected_records=""
superseded_records=""
deprecated_records=""
non_standard_status_records=""

# Start creating the index file
echo "# Architecture Decision Records" > "$INDEX_FILE"
echo "" >> "$INDEX_FILE"

# Loop through all ADR markdown files and categorize them
for file in "$ADR_DIR"/*.md; do
  if [[ "$file" != "$INDEX_FILE" && "$file" != "$TEMPLATE_FILE" ]]; then
    # Extract the first header (title) from the file
    title=$(grep -m 1 '^# ' "$file" | sed 's/# //')
    filename=$(basename "$file")
    
    # Extract the status
    status=$(grep -m 1 '^## Status' -A 1 "$file" | tail -n 1 | tr -d '[]')

    # Categorize based on status
    case "$status" in
      Accepted)
        accepted_records+="- [$title](./$filename)\n"
        ;;
      Rejected)
        rejected_records+="- [$title](./$filename)\n"
        ;;
      Superseded)
        superseded_records+="- [$title](./$filename)\n"
        ;;
      Deprecated)
        deprecated_records+="- [$title](./$filename)\n"
        ;;
      *)
        non_standard_status_records+="- [$title](./$filename)\n"
        ;;
    esac
  fi
done

# Write the index structure to the file
echo "## Accepted Records" >> "$INDEX_FILE"
echo "" >> "$INDEX_FILE"
if [[ -n "$accepted_records" ]]; then
  echo -e "$accepted_records" >> "$INDEX_FILE"
else
  echo "None" >> "$INDEX_FILE"
fi

echo "## Rejected Records" >> "$INDEX_FILE"
echo "" >> "$INDEX_FILE"
if [[ -n "$rejected_records" ]]; then
  echo -e "$rejected_records" >> "$INDEX_FILE"
else
  echo "None" >> "$INDEX_FILE"
fi

echo "" >> "$INDEX_FILE"
echo "## Deprecated Records" >> "$INDEX_FILE"
echo "" >> "$INDEX_FILE"
if [[ -n "$deprecated_records" ]]; then
  echo -e "$deprecated_records" >> "$INDEX_FILE"
else
  echo "None" >> "$INDEX_FILE"
fi

echo "" >> "$INDEX_FILE"
echo "## Superseded Records" >> "$INDEX_FILE"
echo "" >> "$INDEX_FILE"
if [[ -n "$superseded_records" ]]; then
  echo -e "$superseded_records" >> "$INDEX_FILE"
else
  echo "None" >> "$INDEX_FILE"
fi

echo "" >> "$INDEX_FILE"
echo "## Records with non-standard statuses" >> "$INDEX_FILE"
echo "" >> "$INDEX_FILE"
if [[ -n "$non_standard_status_records" ]]; then
  echo -e "$non_standard_status_records" >> "$INDEX_FILE"
else
  echo "None" >> "$INDEX_FILE"
fi

echo "ADR index updated at $INDEX_FILE"
