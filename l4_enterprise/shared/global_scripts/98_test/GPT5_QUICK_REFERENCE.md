# GPT-5 API Quick Reference

## Status
✅ **WORKING** - All tests passing (7/7)
🔧 **FIXED** - 2025-10-06

---

## The Fix

**Problem**: Response parsing expected wrong structure
**Solution**: Iterate through `output` array to find `type: "message"` item

---

## Correct Response Structure

```json
{
  "output": [
    {"type": "reasoning", "summary": []},
    {
      "type": "message",
      "content": [
        {"type": "output_text", "text": "Hello World"}
      ]
    }
  ]
}
```

---

## Quick Test

```bash
export OPENAI_API_KEY="sk-proj-..."
Rscript -e "source('scripts/global_scripts/98_test/test_gpt5_api.R'); quick_gpt5_test()"
```

---

## Usage

```r
source("scripts/global_scripts/08_ai/fn_chat_api.R")

messages <- list(
  list(role = "system", content = "You are helpful."),
  list(role = "user", content = "Hello!")
)

response <- fn_chat_api(messages, model = "gpt-5-2025-08-07")
```

---

## Key Differences: GPT-4 vs GPT-5

| Feature | GPT-4 | GPT-5 |
|---------|-------|-------|
| Endpoint | `/v1/chat/completions` | `/v1/responses` |
| Input | `messages` array | `input` string |
| Output | `choices[0].message.content` | `output[type=message].content[].text` |
| Special Params | `temperature` | `reasoning.effort` |

---

## Test Files

1. **test_gpt5_api.R** - Comprehensive test suite (7 tests)
2. **test_gpt5_api_debug.R** - Deep debugging with full response logging
3. **GPT5_API_TEST_REPORT.md** - Complete test documentation

---

## Test Results Summary

```
Test 1: Simple GPT-5 Call           ✅ PASSED
Test 2: Debug Format                ✅ PASSED
Test 3: Marketing Prompt            ✅ PASSED
Test 4: API Format Comparison       ✅ PASSED
Test 5: Error Handling              ✅ PASSED
Test 6: Response Structure          ✅ PASSED
Test 7: Performance                 ✅ PASSED

Total: 7/7 (100.0%)
```

---

## Performance

- **Average Response Time**: 1.2-1.6 seconds
- **Timeout**: 60 seconds (configurable)
- **Token Usage**: ~30-100 tokens per simple request

---

## Code Location

**Main Function**: `scripts/global_scripts/08_ai/fn_chat_api.R`
**Fixed Lines**: 155-182 (response parsing logic)

---

## Principles Followed

- MP047: Functional Programming
- MP081: Explicit Parameter Specification
- MP123: AI Prompt Configuration Management
- R21: One Function One File
- R69: Function File Naming
- MP50: Debug Code Tracing

---

## Production Ready ✅

All tests pass. Safe to deploy.
