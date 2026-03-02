#!/usr/bin/env bash
# Inject Hypothes.is annotation script into all Widoco-generated HTML files.
# Idempotent: strips existing hypothes.is tags before injecting.

set -euo pipefail

OUTPUT_DIR="${1:-output}"

if [ ! -d "$OUTPUT_DIR" ]; then
  echo "Error: output directory '$OUTPUT_DIR' not found."
  exit 1
fi

HYPOTHESIS_TAG='<script src="https://hypothes.is/embed.js" async></script>'

# Find all HTML files in the output directory
html_files=$(find "$OUTPUT_DIR" -name "*.html" -type f)

if [ -z "$html_files" ]; then
  echo "No HTML files found in $OUTPUT_DIR"
  exit 1
fi

count=0
for f in $html_files; do
  # Remove any existing hypothes.is script tags (idempotent)
  sed -i '' 's|<script src="https://hypothes.is/embed.js"[^>]*></script>||g' "$f"
  # Inject before </head>
  sed -i '' "s|</head>|${HYPOTHESIS_TAG}</head>|" "$f"
  count=$((count + 1))
done

echo "Injected Hypothes.is into $count HTML file(s) in $OUTPUT_DIR"
