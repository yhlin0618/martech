# NSQL Implementation Guide

A practical guide for implementing the NSQL Confirmation Protocol in AI systems.

---

## Quick Start

### What is NSQL?

NSQL (Natural SQL) is a **confirmation protocol** for human-AI communication. Instead of requiring users to write queries, AI presents structured confirmations that users verify before execution.

### 5-Minute Example

**User says**: "Show me last month's sales by region"

**Your AI should respond**:

```
I understand you want:

transform Sales to RegionReport
as sum(revenue) as total_revenue
grouped by region
where date in [2024-11-01, 2024-11-30]

Is this correct?
```

**User confirms**: "Yes"

**AI executes** and returns results.

---

## When to Use NSQL

### Use NSQL When:

- **Ambiguous terms**: "high-value customer", "recent", "active"
- **Data queries**: Any request for reports, summaries, or analysis
- **Bulk operations**: Updates, deletes, or imports affecting multiple records
- **Business logic**: Terms that could have multiple interpretations

### Skip NSQL When:

- **Simple confirmable actions**: "Open file X", "Go to page Y"
- **Binary choices**: "Yes/No" questions
- **Well-defined commands**: Where there's only one possible interpretation

---

## Core Workflow

```
┌──────────────────────────────────────────────────────────┐
│  1. RECEIVE          User speaks in natural language     │
├──────────────────────────────────────────────────────────┤
│  2. PARSE            Extract intent, entities, scope     │
├──────────────────────────────────────────────────────────┤
│  3. ANALYZE          Identify ambiguities                │
├──────────────────────────────────────────────────────────┤
│  4. DISAMBIGUATE     If unclear, present options         │
│     or CONFIRM       If clear, present confirmation      │
├──────────────────────────────────────────────────────────┤
│  5. AWAIT            User confirms, corrects, or rejects │
├──────────────────────────────────────────────────────────┤
│  6. ITERATE          If not confirmed, update and repeat │
│     or EXECUTE       If confirmed, perform the action    │
└──────────────────────────────────────────────────────────┘
```

---

## Confirmation Format Specification

### Query Confirmation

Use this format for data queries:

```
I understand you want:

transform {source_table} to {result_name}
as {column1}, {column2}, ...
[grouped by {dimension1}, {dimension2}, ...]
[where {condition1} and {condition2} ...]
[ordered by {column} {asc|desc}]
[limit {n}]

Is this correct?
```

**Example**:

```
I understand you want:

transform Orders to CustomerSummary
as customer_id, count(order_id) as order_count, sum(amount) as total_spent
grouped by customer_id
where order_date >= '2024-01-01'
ordered by total_spent desc
limit 100

Is this correct?
```

### Operation Confirmation

Use this format for data modifications:

```
I will perform:

{ACTION} on {target}
with {parameters}

This will affect approximately {N} records.
[Warning: This action cannot be undone.]

Proceed?
```

**Example**:

```
I will perform:

UPDATE on Customers
set status = 'inactive'
where last_purchase_date < '2024-06-01'

This will affect approximately 1,247 records.
Warning: This action cannot be undone.

Proceed?
```

### Disambiguation Format

Use this when multiple interpretations exist:

```
"{ambiguous_term}" could mean:

1. {interpretation_1} (Recommended)
   → {brief_explanation}

2. {interpretation_2}
   → {brief_explanation}

3. {interpretation_3}
   → {brief_explanation}

Which do you mean?
```

**Example**:

```
"High-value customer" could mean:

1. RFM Score >= 4 in all dimensions (Recommended)
   → Based on Recency, Frequency, Monetary analysis

2. Annual spending > $10,000
   → Pure revenue-based definition

3. Top 10% by lifetime value
   → Relative ranking approach

Which do you mean?
```

---

## Disambiguation Patterns

### Time References

| User Says | Possible Interpretations |
|-----------|-------------------------|
| "last month" | Calendar month vs Rolling 30 days |
| "recently" | Last 7 days vs Last 30 days vs Today |
| "this year" | Calendar YTD vs Rolling 365 days |
| "Q1" | Calendar Q1 vs Fiscal Q1 |

**Implementation**: Always ask when time is mentioned without explicit dates.

### Business Terms

Common ambiguous business terms:

| Term | Possible Meanings |
|------|-------------------|
| "sales" | Revenue amount vs Unit count |
| "customer" | Account vs Individual |
| "active" | Recent purchase vs Has subscription |
| "churn" | Canceled vs Inactive period |

**Implementation**: Maintain a dictionary of business terms with their possible definitions. See `dictionary.yaml`.

### Implicit Aggregations

When users say "show X by Y", the aggregation is often implicit:

| User Says | Implicit Aggregation |
|-----------|---------------------|
| "sales by region" | sum(sales)? average(sales)? count(orders)? |
| "customers by segment" | count(customers)? sum(revenue)? |

**Implementation**: Always make aggregation explicit in confirmation.

---

## Integration Examples

### Python Implementation Sketch

```python
class NSQLConfirmation:
    def __init__(self, dictionary_path="dictionary.yaml"):
        self.dictionary = self.load_dictionary(dictionary_path)

    def process_request(self, user_input: str) -> dict:
        """Process user request and return confirmation or disambiguation."""

        # Step 1: Parse intent
        parsed = self.parse_intent(user_input)

        # Step 2: Identify ambiguities
        ambiguities = self.find_ambiguities(parsed)

        if ambiguities:
            # Step 3a: Return disambiguation options
            return {
                "type": "disambiguation",
                "term": ambiguities[0]["term"],
                "options": ambiguities[0]["options"]
            }
        else:
            # Step 3b: Return confirmation
            return {
                "type": "confirmation",
                "nsql": self.format_confirmation(parsed),
                "affects": self.estimate_scope(parsed)
            }

    def format_confirmation(self, parsed: dict) -> str:
        """Format parsed intent as NSQL confirmation string."""
        lines = [f"transform {parsed['source']} to {parsed['target']}"]
        lines.append(f"as {', '.join(parsed['columns'])}")

        if parsed.get('group_by'):
            lines.append(f"grouped by {', '.join(parsed['group_by'])}")
        if parsed.get('where'):
            lines.append(f"where {parsed['where']}")
        if parsed.get('order_by'):
            lines.append(f"ordered by {parsed['order_by']}")
        if parsed.get('limit'):
            lines.append(f"limit {parsed['limit']}")

        return '\n'.join(lines)
```

### Prompt Engineering Guidelines

When using LLMs to implement NSQL, include these instructions:

```
## NSQL Confirmation Protocol

When users request data or operations:

1. NEVER execute immediately. Always confirm first.

2. Format your understanding as NSQL:
   - Use "transform X to Y as ..." for queries
   - Use "{ACTION} on X with ..." for operations

3. If any term is ambiguous (time references, business terms, aggregations):
   - Present numbered options
   - Mark one as "(Recommended)"
   - Ask user to choose

4. After user confirms, then execute.

5. If user says "no" or provides correction:
   - Update your understanding
   - Present new confirmation
   - Do NOT execute until confirmed

Example flow:
User: "Show sales by region"
You: "I understand you want:

transform Sales to RegionReport
as sum(revenue) as total_revenue
grouped by region

Is this correct?"

User: "Yes"
You: [Execute and show results]
```

---

## Best Practices

### 1. Always Confirm Destructive Operations

Any operation that:
- Deletes data
- Updates multiple records
- Cannot be easily reversed

Must include explicit warning and confirmation.

### 2. Prefer Recommended Defaults

When presenting disambiguation options:
- Always mark one as "(Recommended)"
- Choose the most common interpretation
- Explain briefly why it's recommended

### 3. Keep Confirmations Readable

- Use natural language keywords
- Proper indentation
- No technical jargon
- Show actual values, not placeholders

### 4. Show Scope

For operations, always show:
- How many records affected
- What specifically will change
- Whether it's reversible

### 5. Support Iteration

Users may say:
- "Yes" → Execute
- "No" → Ask what's wrong
- "Almost, but..." → Update and re-confirm
- "Add also..." → Incorporate and re-confirm

---

## Configuration Files

### dictionary.yaml

Define business terms and their interpretations:

```yaml
business_terms:
  high_value_customer:
    term: "high-value customer"
    definitions:
      - name: "RFM-based"
        condition: "rfm_r >= 4 AND rfm_f >= 4 AND rfm_m >= 4"
        recommended: true
      - name: "Revenue-based"
        condition: "annual_revenue > 10000"
```

### protocol.yaml

Define confirmation formats and triggers:

```yaml
confirmation_formats:
  query:
    template: |
      transform {source} to {target}
      as {operations}
      ...

disambiguation_triggers:
  - trigger: "time references"
    examples: ["last month", "recently"]
```

---

## Troubleshooting

### User keeps saying "no"

- Your interpretation may be fundamentally wrong
- Ask: "I'm having trouble understanding. Could you describe what you're looking for differently?"

### Ambiguity not detected

- Expand your dictionary with more terms
- Add domain-specific business vocabulary
- Log unrecognized terms for future improvement

### Confirmation too verbose

- Focus on changed/filtered elements
- Use defaults for common patterns
- Only show what's non-obvious

---

*Version 1.0 | 2025-12-24*
