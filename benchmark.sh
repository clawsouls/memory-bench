#!/bin/bash
# Memory Retrieval Benchmark: FTS vs Hybrid
# Usage: ./benchmark.sh [--workspace /path/to/.openclaw/workspace]
#
# Prerequisites:
#   - SoulClaw installed (npm i -g soulclaw)
#   - Workspace with memory files (MEMORY.md + memory/*.md)
#   - sqlite3, jq installed
#   - For hybrid mode: Ollama running with bge-m3 model
#
# This script queries the SoulClaw memory database in FTS-only mode
# and outputs results for human evaluation.

set -euo pipefail

WORKSPACE="${1:-.openclaw/workspace}"
QUESTIONS="questions.json"
RESULTS_DIR="results"
DB_PATH=""

# Find the memory database
for candidate in \
  "$HOME/.openclaw/memory/main.sqlite" \
  "$HOME/.openclaw/.openclaw-data/memory.db" \
  "$WORKSPACE/.openclaw-data/memory.db"; do
  if [[ -f "$candidate" ]]; then
    DB_PATH="$candidate"
    break
  fi
done

if [[ -z "$DB_PATH" ]]; then
  echo "Error: Cannot find SoulClaw memory database."
  echo "Searched: ~/.openclaw/memory/main.sqlite, ~/.openclaw/.openclaw-data/memory.db"
  exit 1
fi

if [[ ! -f "$QUESTIONS" ]]; then
  echo "Error: $QUESTIONS not found. Run from the memory-bench directory."
  exit 1
fi

mkdir -p "$RESULTS_DIR"

echo "=== Memory Retrieval Benchmark ==="
echo "Database: $DB_PATH"
echo "Questions: $(jq length "$QUESTIONS")"

# Count corpus stats
FTS_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM chunks_fts;" 2>/dev/null || echo "0")
TOTAL_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM chunks;" 2>/dev/null || echo "0")
VECTOR_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM chunks WHERE embedding IS NOT NULL;" 2>/dev/null || echo "0")
echo "Chunks: $TOTAL_COUNT total, $FTS_COUNT FTS-indexed, $VECTOR_COUNT with embeddings"
echo ""

# Run FTS searches
echo "--- FTS-only Results ---"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT="$RESULTS_DIR/fts-$TIMESTAMP.jsonl"

jq -c '.[]' "$QUESTIONS" | while IFS= read -r item; do
  ID=$(echo "$item" | jq -r '.id')
  CATEGORY=$(echo "$item" | jq -r '.category')
  QUESTION=$(echo "$item" | jq -r '.question')
  
  # Extract keywords for FTS (simple: take nouns/terms > 2 chars)
  # For Korean/multilingual, FTS5 handles tokenization
  SAFE_Q=$(echo "$QUESTION" | sed "s/'/''/g" | head -c 100)
  
  RESULTS=$(sqlite3 -json "$DB_PATH" \
    "SELECT source, substr(text, 1, 300) as snippet, rank 
     FROM chunks_fts 
     WHERE chunks_fts MATCH '\"$SAFE_Q\"' 
     ORDER BY rank 
     LIMIT 5;" 2>/dev/null || echo "[]")
  
  echo "{\"id\":\"$ID\",\"category\":\"$CATEGORY\",\"question\":$(echo "$QUESTION" | jq -Rs .),\"results\":$RESULTS}" >> "$OUTPUT"
  
  RESULT_COUNT=$(echo "$RESULTS" | jq 'length' 2>/dev/null || echo 0)
  printf "  %-4s [%-10s] %s → %s results\n" "$ID" "$CATEGORY" "$QUESTION" "$RESULT_COUNT"
done

echo ""
echo "Results saved to: $OUTPUT"
echo ""
echo "=== Next Steps ==="
echo "1. For hybrid search, ensure Ollama is running with bge-m3:"
echo "   ollama pull bge-m3 && ollama serve"
echo "2. Configure SoulClaw: soulclaw config set agents.defaults.memorySearch.provider ollama"
echo "3. Use SoulClaw's memory search API or CLI for hybrid results"
echo "4. Human-evaluate results using scoring rubric in README.md"
echo ""
echo "Scoring: 0 = irrelevant, 1 = partially relevant, 2 = correct answer retrievable"
