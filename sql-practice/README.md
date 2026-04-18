# SQL Practice Project

> 100+ questions from basics to interview tricks. E-commerce domain with 58,000+ rows.

## Quick Setup

```bash
# Option 1: Docker (recommended)
docker run -d --name sql-practice -p 5432:5432 -e POSTGRES_PASSWORD=pass postgres:15

# Option 2: Local PostgreSQL
# Just ensure PostgreSQL is running on localhost:5432

# Load schema + data
psql -U postgres -f schema.sql
psql -U postgres -d sql_practice -f seed-data.sql

# Connect
psql -U postgres -d sql_practice
```

## Schema (ER Diagram)

```
departments ──< employees (self-ref: manager_id → employees.id)

customers ──< orders ──< order_items >── products
    │            │                          │
    │            └──< payments              └──< reviews >── customers
    │
    └──< login_logs

salary_history >── employees
```

**Tables:** departments (10), employees (500), customers (2,000), products (500), orders (10,000), order_items (30,000), payments (10,000), reviews (~4,000), login_logs (~3,500), salary_history (~300)

## Questions (100+)

| File | # Qs | Topics | Difficulty |
|------|------|--------|-----------|
| 01-basics | 8 | SELECT, WHERE, ORDER BY, LIMIT, DISTINCT | Easy |
| 02-filtering | 8 | AND/OR, IN, BETWEEN, LIKE, IS NULL | Easy-Medium |
| 03-aggregations | 8 | COUNT, SUM, AVG, GROUP BY, HAVING | Easy-Medium |
| 04-joins | 10 | INNER, LEFT, SELF, CROSS, multi-table | Medium-Hard |
| 05-subqueries | 7 | Scalar, correlated, EXISTS, IN | Medium-Hard |
| 06-window-functions | 10 | ROW_NUMBER, RANK, LAG, LEAD, running totals | Medium-Hard |
| 07-cte-recursive | 6 | WITH, recursive (org chart, date series) | Hard |
| 08-set-operations | 4 | UNION, INTERSECT, EXCEPT | Medium |
| 09-string-date | 7 | SPLIT_PART, EXTRACT, DATE_TRUNC, AGE | Medium |
| 10-case-pivot | 6 | CASE WHEN, conditional aggregation, pivot | Medium-Hard |
| 11-dml | 5 | INSERT, UPDATE, DELETE, UPSERT | Medium-Hard |
| 12-advanced 🔥 | 24 | Gaps & islands, top-N, duplicates, NULL traps, anti-joins, relational division | Hard |
| 13-performance | 5 | EXPLAIN, indexes, query rewriting | Hard |

**Total: 108 questions**

## How to Practice

1. Read the question in `questions/` folder
2. Write your query in psql or any SQL client
3. Check your answer against `solutions/` folder
4. If stuck: the hint in the question tells you which concept to use

## Key Interview Traps Covered

- ❌ `bonus != 30000` excludes NULLs → use `OR bonus IS NULL`
- ❌ `NOT IN` fails with NULLs in subquery → use `NOT EXISTS`
- ❌ Window function in WHERE clause → wrap in CTE
- ❌ `LAST_VALUE` without proper frame → add `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`
- ❌ Function on indexed column → prevents index usage
- ❌ `ROW_NUMBER` for "top N with ties" → use `DENSE_RANK`
- ❌ `SUM` ignores NULLs but `COUNT(*)` doesn't → know the difference
