#!/bin/bash
# Unified file validator - routes to appropriate validator based on file type
# This replaces the condition-based filtering that isn't supported in hooks schema

FILE_PATH="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Exit early if no file path
[[ -z "$FILE_PATH" ]] && exit 0

# Get file extension and path patterns
EXT="${FILE_PATH##*.}"
BASENAME="$(basename "$FILE_PATH")"

# Route to appropriate validator based on file type/path
case "$FILE_PATH" in
  */prds/*.md)
    python3 "$SCRIPT_DIR/prd-validator.py" "$FILE_PATH"
    ;;
  *.feature)
    python3 "$SCRIPT_DIR/bdd-validator.py" "$FILE_PATH"
    ;;
  *.ts|*.tsx)
    bash "$SCRIPT_DIR/typescript-validator.sh" "$FILE_PATH"
    ;;
  *token*.json|*theme*.json)
    python3 "$SCRIPT_DIR/design-tokens-validator.py" "$FILE_PATH"
    ;;
  *.csv)
    python3 "$SCRIPT_DIR/csv-validator.py" "$FILE_PATH"
    ;;
  */components/*.tsx|*/components/*.jsx|*/app/*/page.tsx|*/app/*/page.jsx)
    bash "$SCRIPT_DIR/ui-validation.sh" "$FILE_PATH"
    ;;
esac

# Always exit 0 - validators provide feedback but don't block
exit 0
