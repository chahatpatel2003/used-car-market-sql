# Provenance

This was a course project for CSCI 126 at California State University, Fresno, Summer 2025. Two documents were recovered from Google Drive in October 2026:

- **`CSCI 126 PROJECT FINAL VERSION v2.docx`:** the project report. It contains the dataset description, the four `CREATE TABLE` statements, the design and normalization discussion, the ER diagram, the 15 queries with explanations, and the findings.
- **`CSCI 126 - Updated Queries.docx`:** revision notes for the report. They contain saved output tables for queries 3, 5, 9, 11 and 15, plus revised wording for the findings. Its five queries are identical to the report's.

## How the files were produced

| File | Method |
|---|---|
| `sql/schema.sql` | Text from the report's first `CREATE TABLE` up to the "Design & Normalization" heading, unchanged. SHA-256 `316f96e6b571c052c9b83ed775054a2a476951ad60ca0510daee03a559fc1489`. |
| `sql/queries.sql` | Each query's SQL text taken from below its "Query N – title" heading, unchanged. The heading is written as a `-- Query N: title` comment. SHA-256 `4170bf99c6c1ad5cb2305ff0ecab0d00d7f98ecdc94caf1606a277ea42cdaf78`. |
| `results/recovered_original_outputs/*.csv` | Table cells from the revision notes, parsed programmatically: the header row is matched to the query's column list, and values are kept as text. Tests check their internal consistency, for example that every Query 5 row satisfies price ÷ mileage = price_per_mile. |
| `docs/er_diagram_original.jpg` | The image embedded in the report. |

## Added in October 2026 (AI-assisted)

These files are new work. They are not part of the 2025 project.

- `sql/queries_corrected.sql`: fixes for queries 3, 5, 6 and 9, and a portability change to query 7. The reasons are in the README.
- `run_queries.py`: runs the MySQL files on DuckDB through sqlglot.
- `sample_data/synthetic_edge_cases.sql`: **invented** rows chosen to exercise edge cases; not project data.
- `tests/test_queries.py`: 42 tests.

## Not recovered

- the cleaned dataset (300 listings, per the Query 15 output) and the Vehicle and Manufacturer rows;
- the data-cleaning and loading scripts;
- outputs of queries 1, 2, 4, 6, 7, 8, 10, 12, 13 and 14;
- the presentation slides.

## Statements in the report that the recovered material does not support

- **"We utilized joins, aggregates, subqueries, and a view":** no view appears in the recovered SQL.
- **"Listings with non-clean titles were rare or absent":** the Query 15 output shows they were absent, with 300 of 300 clean.
