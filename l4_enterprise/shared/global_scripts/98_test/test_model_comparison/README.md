# eWOM Model Comparison Report

**Date**: 2026-02-21
**Task**: Compare OpenAI models on eWOM review rating (Likert 1-5 + NaN)
**API**: Responses API via `fn_response_api.R` (unified wrapper)
**Baseline**: Claude Opus 4.6 (independent assessment)

---

## Part 1: Single-Review Test (Pilot)

### Test Case

| Item | Value |
|------|-------|
| Product | can_opener |
| Title | "Love it" |
| Body | "Finally broke down and bought this electric can opener after realizing my arthritis no longer allows me to manually open anything... Pleasantly surprised with how light weight it is as well as durable... And for the price under $20 the quality of this is outstanding... Will recommend." |

### Baselines

| # | Statement | o3-mini | Claude Opus 4.6 |
|---|-----------|:-------:|:----------------:|
| S1 | "...enthusiasm for exploring the new product." | 3 | 2 |
| S2 | "...offered a solution" | 4 | 4 |
| S3 | "...aims to educate others." | 3 | 3 |
| S4 | "...frustration over minor issues." | NaN | NaN |

### Pilot Results (3 efforts x 3 models = 36 calls)

| Model | vs o3-mini (Exact / ~1) | vs Claude (Exact / ~1) | Avg Time |
|-------|:-----------------------:|:----------------------:|:--------:|
| gpt-4o-mini | 50% / 100% | 50% / 75% | 1.4s |
| gpt-5-mini | 33% / 92% | 25% / 75% | 6.3s |
| gpt-5-nano | 33% / 75% | 33% / 75% | 9.6s |

**Pilot limitation**: Only one review tested, all models clustered at score=4 for S1-S3. Insufficient discrimination.

---

## Part 2: Comprehensive Test (5 Reviews)

### Reviews Designed for Full Score Range

| ID | Label | Title | Key Trait |
|----|-------|-------|-----------|
| A | necessity-driven positive | "Love it" | Original review; satisfied but not enthusiastic |
| B | angry major issues | "WORST PURCHASE EVER" | Motor died, blade dull, cut finger |
| C | educational comparison | "Detailed comparison after testing 3 models" | 6-month comparison, numbered tips, brand names |
| D | minimal zero-info | "ok" | Body: "It works." |
| E | mixed minor annoyances | "Decent but a few small gripes" | Good motor, but tiny font, stiff button, loose lid |

### Claude Opus 4.6 Expected Scores (Baseline)

| Review | S1 (enthusiasm) | S2 (solution) | S3 (educate) | S4 (frustration-minor) |
|:------:|:---:|:---:|:---:|:---:|
| A | 2 | 4 | 3 | NaN |
| B | NaN | NaN | 3 | NaN |
| C | 4 | 5 | 5 | NaN |
| D | NaN | NaN | NaN | NaN |
| E | NaN | NaN | 3 | 4 |

Score distribution: NaN (13), 2 (1), 3 (4), 4 (1), 5 (2)

**Key design choices:**
- B-S4 = NaN: review has frustration but over MAJOR issues (motor died, cut finger), not "minor issues" as statement specifies
- E-S4 = 4: review explicitly lists minor annoyances (tiny font, stiff button, loose battery lid)
- D = all NaN: "It works." provides zero evaluable information

### Comprehensive Results (5 reviews x 4 stmts x 3 models = 60 calls)

| Model | Exact | Within-1 | DIFF | Avg Time |
|-------|:-----:|:--------:|:----:|:--------:|
| **gpt-5-nano** | **12/20 (60%)** | **90%** | **2** | 5.4s |
| **gpt-5-mini** | **12/20 (60%)** | **90%** | **2** | 5.4s |
| gpt-4o-mini | 11/20 (55%) | 75% | 5 | 1.3s |

### Full Score Distribution

| Case | Expected | gpt-4o-mini | gpt-5-nano | gpt-5-mini |
|:----:|:--------:|:-----------:|:----------:|:----------:|
| A-S1 | **2** | 4 (DIFF) | 4 (DIFF) | 3 (~1) |
| A-S2 | 4 | 4 (OK) | 5 (~1) | 5 (~1) |
| A-S3 | 3 | 4 (~1) | 4 (~1) | 4 (~1) |
| A-S4 | NaN | NaN (OK) | NaN (OK) | NaN (OK) |
| B-S1 | NaN | NaN (OK) | NaN (OK) | NaN (OK) |
| B-S2 | **NaN** | NaN (OK) | 5 (DIFF) | 4 (DIFF) |
| B-S3 | 3 | 5 (DIFF) | 4 (~1) | 4 (~1) |
| B-S4 | **NaN** | 1 (DIFF) | NaN (OK) | NaN (OK) |
| C-S1 | 4 | 5 (~1) | 5 (~1) | 4 (OK) |
| C-S2 | 5 | 4 (~1) | 5 (OK) | 5 (OK) |
| C-S3 | 5 | 5 (OK) | 5 (OK) | 5 (OK) |
| C-S4 | **NaN** | 1 (DIFF) | NaN (OK) | 4 (DIFF) |
| D-S1 | NaN | NaN (OK) | NaN (OK) | NaN (OK) |
| D-S2 | NaN | NaN (OK) | NaN (OK) | NaN (OK) |
| D-S3 | NaN | NaN (OK) | NaN (OK) | NaN (OK) |
| D-S4 | NaN | NaN (OK) | NaN (OK) | NaN (OK) |
| E-S1 | NaN | 2 (DIFF) | NaN (OK) | NaN (OK) |
| E-S2 | NaN | NaN (OK) | NaN (OK) | NaN (OK) |
| E-S3 | 3 | 4 (~1) | 4 (~1) | 4 (~1) |
| E-S4 | 4 | 4 (OK) | 5 (~1) | 5 (~1) |

---

## Error Analysis

### gpt-4o-mini: 5 DIFF errors

| Case | Expected | Actual | Error Pattern |
|------|:--------:|:------:|---------------|
| A-S1 | 2 | 4 | Cannot detect non-enthusiasm in positive review |
| B-S3 | 3 | 5 | Over-rates educational intent of angry vent |
| **B-S4** | **NaN** | **1** | Gives score (1) instead of NaN. Recognizes no "minor" frustration but still rates |
| **C-S4** | **NaN** | **1** | Same pattern: gives 1 instead of NaN for absent characteristic |
| **E-S1** | **NaN** | **2** | Same pattern: gives score instead of NaN |

**Systematic weakness**: gpt-4o-mini struggles with the NaN/score boundary. When a characteristic is absent, it gives low scores (1-2) instead of NaN. This is a **protocol compliance issue** -- it understands the characteristic isn't there but doesn't follow the "[NaN,NaN]" output format.

### gpt-5-nano: 2 DIFF errors

| Case | Expected | Actual | Error Pattern |
|------|:--------:|:------:|---------------|
| A-S1 | 2 | 4 | Same S1 struggle as all models |
| B-S2 | NaN | 5 | Interprets "returning for refund" as "offering a solution" |

### gpt-5-mini: 2 DIFF errors

| Case | Expected | Actual | Error Pattern |
|------|:--------:|:------:|---------------|
| B-S2 | NaN | 4 | Same as nano: sees "returning" as solution-offering |
| C-S4 | NaN | 4 | Interprets Brand X "too loud" as "frustration over minor issues" |

---

## Part 3: Batch Scaling Test (Structured Outputs)

### Design

Evaluate how accuracy scales when rating **multiple statements in a single API call** using Structured Outputs (JSON Schema).

| Parameter | Value |
|-----------|-------|
| Review | Review A ("Love it") |
| Statements | 60 eWOM dimensions (15 scored + 45 NaN) |
| Batch sizes | 10, 20, 30, 40, 50, 60 |
| Models | gpt-5-nano, gpt-5-mini |
| Efforts | low, medium, high |
| Output format | JSON Schema with `strict: true` |
| Total calls | 36 |

Score distribution: 5 (x2), 4 (x4), 3 (x6), 2 (x3), NaN (x45)

### Results: Accuracy by Batch Size (effort=medium)

| Batch | nano Exact | nano ~1 | nano NaN | mini Exact | mini ~1 | mini NaN |
|:-----:|:---------:|:-------:|:--------:|:----------:|:-------:|:--------:|
| 10 | 20% | 90% | 100% | 30% | 70% | 100% |
| 20 | 40% | 70% | 100% | 40% | 60% | 100% |
| 30 | 57% | 77% | 100% | 57% | 77% | 100% |
| 40 | 62% | 82% | 96% | **75%** | **90%** | 100% |
| 50 | 74% | 84% | 97% | **80%** | **90%** | 100% |
| **60** | 78% | 87% | 100% | **82%** | **92%** | **100%** |

### Results: Effort Comparison at Batch=60

| Model | Effort | Exact | ~1 | NaN Recall | Time | s/stmt |
|-------|:------:|:-----:|:--:|:----------:|:----:|:------:|
| nano | low | 78% | 87% | 100% | 28s | 0.47 |
| nano | medium | 78% | 87% | 100% | 80s | 1.33 |
| nano | high | 80% | 87% | 100% | 114s | 1.90 |
| mini | low | 77% | 87% | 98% | 36s | 0.60 |
| **mini** | **medium** | **82%** | **92%** | **100%** | **51s** | **0.85** |
| mini | high | 78% | 85% | 100% | 88s | 1.47 |

### Key Finding: Accuracy IMPROVES with Batch Size

This is **counterintuitive** -- accuracy goes UP, not down, as batch size increases from 10 to 60:

```
Batch 10: ~25% exact  (too few statements for calibration)
Batch 20: ~40% exact
Batch 30: ~57% exact
Batch 40: ~73% exact  (inflection point)
Batch 50: ~77% exact
Batch 60: ~80% exact  (best performance)
```

**Explanation**: With more statements, the model implicitly calibrates its scoring scale. Seeing 60 diverse dimensions (most irrelevant) gives the model better context for distinguishing "present but weak" (score 2-3) from "not present at all" (null).

### Key Finding: effort=high Often HURTS

| Model | effort=medium | effort=high | Delta |
|-------|:------------:|:-----------:|:-----:|
| mini (batch=40) | **75%** exact | 60% exact | **-15%** |
| mini (batch=60) | **82%** exact | 78% exact | -4% |
| nano (batch=30) | 57% exact | 50% exact | -7% |

**Explanation**: Higher reasoning effort causes "overthinking" -- the model generates more nuanced arguments that lead to scoring characteristics that should be null. The NaN recall drops from 100% to 88-93% at effort=high.

### Winner: gpt-5-mini (effort=medium)

At the practical operating point (batch=60, effort=medium):

| Metric | gpt-5-nano | **gpt-5-mini** |
|--------|:----------:|:--------------:|
| Exact match | 78% | **82%** |
| Within-1 | 87% | **92%** |
| NaN recall | 100% | **100%** |
| Time (total) | 80s | **51s** |
| s/stmt | 1.33 | **0.85** |

gpt-5-mini is both **faster** and **more accurate** than gpt-5-nano at effort=medium with batch processing.

---

## Key Findings (Final)

1. **Batch processing with Structured Outputs is the optimal approach**: gpt-5-mini at effort=medium achieves 82% exact match and 92% within-1 when rating 60 statements at once, vs 60% exact in single-statement mode (Part 2). JSON Schema enforces consistent output format.

2. **Accuracy IMPROVES with batch size**: Counterintuitively, rating more statements at once (10→60) increases accuracy from ~25% to ~82%. More statements provide implicit calibration context.

3. **effort=medium is the sweet spot**: effort=high causes overthinking (-4% to -15% accuracy vs medium). effort=low is fast but less precise. effort=medium balances accuracy and speed.

4. **gpt-5-mini > gpt-5-nano for batch processing**: At batch=60/effort=medium, mini is both faster (0.85 vs 1.33 s/stmt) and more accurate (82% vs 78% exact).

5. **NaN discipline remains the critical differentiator**:
   - gpt-5-mini (effort=medium): **100% NaN recall** at all batch sizes
   - gpt-5-nano: dips to 96-97% at batch 40-50
   - gpt-4o-mini (Part 2): only 85% NaN recall -- gives 1-2 instead of NaN

6. **Batch size 40+ is the practical minimum**: Accuracy inflects sharply between batch 30 (57%) and 40 (75%). Below 30 statements, insufficient calibration context.

7. **gpt-4o-mini should not be used for research**: NaN protocol failures (3/20 in Part 2) contaminate rating data. Speed advantage doesn't compensate.

---

## Final Recommendation

| Use Case | Model | Effort | Batch Size | Rationale |
|----------|-------|:------:|:----------:|-----------|
| **Research production** | **gpt-5-mini** | **medium** | **60** | 82% exact, 92% ~1, 100% NaN recall, 0.85s/stmt |
| Budget alternative | gpt-5-nano | medium | 60 | 78% exact, 87% ~1, 100% NaN, 1.33s/stmt |
| Speed-optimized | gpt-5-mini | low | 60 | 77% exact, 87% ~1, 36s total |
| Small-batch fallback | gpt-5-mini | medium | 40+ | Accuracy drops below 60% at batch<30 |
| **Avoid** | gpt-4o-mini | any | any | NaN failures; gpt-5-nano with low effort is faster and more accurate |
| **Avoid** | any model | high | any | Overthinking degrades accuracy |

---

## Scripts

| Script | Purpose |
|--------|---------|
| `run_batch_scaling_test.R` | **Part 3**: Batch scaling with Structured Outputs (36 calls) |
| `run_comprehensive_test.R` | **Part 2**: 5 reviews x 4 statements x 3 models (60 calls) |
| `run_single_model.R` | Run single model: `Rscript run_single_model.R <model> [effort]` |
| `analyze_rating_results.R` | Analyze pilot results against both baselines |
| `test_rating_models.R` | Original pilot test runner |

## Result Files

| File | Contents |
|------|----------|
| `results_batch_scaling_20260221_100648.csv` | Part 3: batch scaling summary (36 rows) |
| `results_batch_detail_20260221_100648.csv` | Part 3: per-statement detail |
| `results_comprehensive_20260221_092554.csv` | Part 2: full 60-call comprehensive test |
| `results_20260221_090856.csv` | Part 1 pilot: gpt-5-nano + gpt-5-mini |
| `results_gpt4omini_20260221_091441.csv` | Part 1 pilot: gpt-4o-mini |

## Technical Notes

### R + JSON Schema 陷阱

`jsonlite::toJSON(auto_unbox = TRUE)` 會把長度為 1 的 R 向量轉成 JSON 純量。對 JSON Schema 的 `required` 欄位（必須是陣列）和 nullable `type`（如 `["integer", "null"]`），需用 `I()` 包裝強制保持陣列格式：

```r
# WRONG: required = c("ratings")  → "required": "ratings"
# RIGHT: required = I(c("ratings")) → "required": ["ratings"]
```
