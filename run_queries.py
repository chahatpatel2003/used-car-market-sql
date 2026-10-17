"""Create the schema, load data and run the 15 queries on an in-memory DuckDB database.

The SQL in sql/ is MySQL, as written for the course. sqlglot translates each statement to DuckDB so the
project runs without a MySQL server. The original dataset was not recovered, so the default data file is
a small SYNTHETIC sample (sample_data/synthetic_edge_cases.sql).

Usage:
    python run_queries.py                       # recovered original queries on the synthetic sample
    python run_queries.py --corrected           # corrected queries
    python run_queries.py --query 9 --data my_inserts.sql
"""
import argparse
import logging
from pathlib import Path

import duckdb
import sqlglot

ROOT = Path(__file__).resolve().parent
SQL = ROOT / "sql"

# DuckDB has no AUTO_INCREMENT; sqlglot drops it with a warning. The data files supply every id explicitly.
logging.getLogger("sqlglot").setLevel(logging.ERROR)


def mysql_statements(path):
    """Parse a MySQL file into sqlglot expressions, keeping each statement's leading '-- Query N: title'."""
    return sqlglot.parse(Path(path).read_text(encoding="utf-8"), read="mysql")


def query_title(statement):
    for comment in statement.comments or []:
        if comment.strip().startswith("Query "):
            return comment.strip()
    return ""


def connect(data_file=ROOT / "sample_data" / "synthetic_edge_cases.sql"):
    con = duckdb.connect()
    for statement in mysql_statements(SQL / "schema.sql"):
        con.execute(statement.sql(dialect="duckdb"))
    if data_file:
        con.execute(Path(data_file).read_text(encoding="utf-8"))
    return con


def load_queries(corrected=False):
    return mysql_statements(SQL / ("queries_corrected.sql" if corrected else "queries.sql"))


def run(con, statement):
    cursor = con.execute(statement.sql(dialect="duckdb"))
    return [d[0] for d in cursor.description], cursor.fetchall()


def show(value):
    if value is None:
        return "NULL"
    if isinstance(value, float):  # FLOAT columns are single precision; print the digits they actually hold
        return f"{value:.7g}"
    return str(value)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--corrected", action="store_true", help="run sql/queries_corrected.sql")
    parser.add_argument("--data", type=Path, default=ROOT / "sample_data" / "synthetic_edge_cases.sql",
                        help="SQL file of INSERT statements to load")
    parser.add_argument("--query", type=int, help="run only this query number (1-15)")
    args = parser.parse_args(argv)

    con = connect(args.data)
    queries = load_queries(args.corrected)
    numbers = [args.query] if args.query else range(1, len(queries) + 1)
    for n in numbers:
        statement = queries[n - 1]
        columns, rows = run(con, statement)
        print(f"\n{query_title(statement) or f'Query {n}'}")
        print(" | ".join(columns))
        for row in rows:
            print(" | ".join(show(v) for v in row))


if __name__ == "__main__":
    main()
