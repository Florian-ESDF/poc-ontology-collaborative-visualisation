#!/usr/bin/env bash
# Widoco + Hypothes.is PoC Pipeline
# Downloads the Wine ontology, generates HTML docs with Widoco, injects
# Hypothes.is annotations, and serves the result.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

ONTOLOGY_URL="https://www.w3.org/TR/owl-guide/wine.rdf"
WIDOCO_JAR_URL="https://github.com/dgarijo/Widoco/releases/download/v1.4.25/widoco-1.4.25-jar-with-dependencies_JDK-17.jar"
ONTOLOGY_DIR="ontology"
ONTOLOGY_FILE="$ONTOLOGY_DIR/wine.rdf"
WIDOCO_JAR="widoco.jar"
OUTPUT_DIR="output"
PORT="${1:-8080}"

# --- Step 0: Ensure Java is installed ---
echo "==> Step 0: Checking Java..."
if ! java -version &>/dev/null; then
  echo "    Java not found. Installing via Homebrew..."
  if ! command -v brew &>/dev/null; then
    echo "ERROR: Homebrew is required to install Java. Install it from https://brew.sh" >&2
    exit 1
  fi
  brew install openjdk
  # Link so that system java wrappers find it
  sudo ln -sfn "$(brew --prefix openjdk)/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk.jdk
  echo "    Java installed."
else
  echo "    Java found: $(java -version 2>&1 | head -1 | tr -d '\n')"
fi

# --- Step 1: Download the Wine ontology ---
echo "==> Step 1: Downloading Wine ontology..."
mkdir -p "$ONTOLOGY_DIR"
if [ -f "$ONTOLOGY_FILE" ]; then
  echo "    Already exists, skipping download."
else
  curl -fSL "$ONTOLOGY_URL" -o "$ONTOLOGY_FILE"
  echo "    Downloaded to $ONTOLOGY_FILE"
fi

# --- Step 2: Download Widoco JAR if needed ---
echo "==> Step 2: Checking Widoco JAR..."
if [ -f "$WIDOCO_JAR" ]; then
  echo "    Already exists, skipping download."
else
  echo "    Downloading Widoco JAR..."
  curl -fSL "$WIDOCO_JAR_URL" -o "$WIDOCO_JAR"
  echo "    Downloaded to $WIDOCO_JAR"
fi

# --- Step 3: Generate HTML docs with Widoco ---
echo "==> Step 3: Running Widoco..."
java -jar "$WIDOCO_JAR" \
  -ontFile "$ONTOLOGY_FILE" \
  -outFolder "$OUTPUT_DIR" \
  -confFile config/config.properties \
  -uniteSections \
  -lang en \
  -rewriteAll \
  -noPlaceHolderText

echo "    Widoco output written to $OUTPUT_DIR/"

# --- Step 4: Inject Hypothes.is ---
echo "==> Step 4: Injecting Hypothes.is annotation layer..."
bash "$SCRIPT_DIR/inject-hypothesis.sh" "$OUTPUT_DIR"

# --- Step 5: Serve ---
echo "==> Step 5: Serving docs at http://localhost:$PORT"
echo "    Open http://localhost:$PORT/index-en.html in your browser."
echo "    Press Ctrl+C to stop."
cd "$OUTPUT_DIR"
python3 -m http.server "$PORT"
