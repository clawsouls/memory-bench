# Memory Retrieval Benchmark: FTS vs Hybrid

A reproducible benchmark for comparing memory search modes in AI agent systems.

## Overview

Compares two retrieval strategies for AI agent long-term memory:

- **FTS-only**: SQLite FTS5 keyword matching. No ML model required.
- **Hybrid**: FTS + semantic vector search (e.g., Ollama bge-m3). Requires embedding model.

## Results (SoulClaw v2026.3.34)

Tested against 303 memory files (~14K lines) accumulated over 6+ weeks of daily AI agent operation.

| Category | Questions | FTS Score | Hybrid Score | FTS % | Hybrid % | Delta |
|----------|-----------|-----------|-------------|-------|----------|-------|
| Exact | 10 | 17/20 | 17/20 | 85% | 85% | 0% |
| Paraphrase | 10 | 6/20 | 11/20 | 30% | 55% | +25% |
| Contextual | 10 | 6/20 | 11/20 | 30% | 55% | +25% |
| **Total** | **30** | **29/60** | **39/60** | **48%** | **65%** | **+17%** |

Full analysis: [blog.clawsouls.ai/posts/fts-vs-hybrid-memory-benchmark](https://blog.clawsouls.ai/en/posts/fts-vs-hybrid-memory-benchmark/)

## Question Categories

- **Exact**: Query uses terms that appear verbatim in source documents
- **Paraphrase**: Query uses synonyms or indirect references
- **Contextual**: Abstract questions requiring contextual understanding

## Questions

The included `questions.json` contains **sanitized example questions** demonstrating the format. Replace them with questions specific to your own agent's memory corpus.

Each question needs:
- `id`: Unique identifier (E01, P01, C01, etc.)
- `category`: `exact`, `paraphrase`, or `contextual`
- `question`: The query to search for
- `answer`: Expected answer (for human evaluation)
- `ground_truth_files`: Which memory files contain the answer

## How to Run

### Prerequisites

- [SoulClaw](https://github.com/clawsouls/soulclaw) installed with memory files
- `sqlite3` and `jq` installed
- For hybrid: [Ollama](https://ollama.com) with `bge-m3` model

### Steps

1. **Write your questions** — Edit `questions.json` with questions specific to your agent's memory corpus. Include ground truth file paths.

2. **Run FTS benchmark**:
   ```bash
   chmod +x benchmark.sh
   ./benchmark.sh
   ```

3. **Run hybrid search** — Configure SoulClaw with Ollama, then use the memory search API.

4. **Score results** — Human evaluation using the rubric below.

### Scoring Rubric

| Score | Meaning |
|-------|---------|
| 0 | Irrelevant — retrieved results don't contain the answer |
| 1 | Partially relevant — related content found but answer incomplete |
| 2 | Correct — answer is directly retrievable from top-5 results |

## File Structure

```
questions.json    # 30 benchmark questions with ground truth
benchmark.sh      # FTS search script
results/          # Output directory (created on run)
README.md         # This file
```

## Adapting to Your Corpus

The benchmark is designed to run against **any** SoulClaw workspace. To adapt:

1. Replace `questions.json` with questions about *your* agent's memory
2. Set `ground_truth_files` to the files where answers live in *your* corpus
3. Run the benchmark and score results

This is intentionally **not** an automated benchmark — human evaluation avoids the circular reasoning of using an LLM to judge LLM retrieval quality.

## Limitations

- **Single evaluator**: Results reflect one human's judgment
- **Small sample**: 30 questions (statistically limited but deeply evaluated)
- **Bilingual corpus**: Korean + English mixed; results may differ for monolingual corpora
- **No semantic-only mode**: Compared FTS vs Hybrid, not pure semantic

## Citation

If you use this benchmark in research:

```
@misc{memory-bench-2026,
  title={FTS vs Hybrid Memory Search: A Real-World Benchmark},
  author={ClawSouls},
  year={2026},
  url={https://github.com/clawsouls/memory-bench}
}
```

## License

MIT
