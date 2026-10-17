"""Tests for the recovered schema and queries, the corrected queries, and the recovered original outputs.

The SQL is MySQL; it is translated with sqlglot and executed on DuckDB against SYNTHETIC data
(sample_data/synthetic_edge_cases.sql). These tests show that the SQL is valid and behaves as described.
They do not reproduce the project's original results: the original dataset was not recovered.
"""
import csv
from pathlib import Path

import duckdb
import pytest

import run_queries as rq

ROOT = Path(__file__).resolve().parents[1]
ORIGINAL = rq.load_queries()
CORRECTED = rq.load_queries(corrected=True)
CHANGED = {3, 5, 6, 7, 9}


@pytest.fixture()
def con():
    c = rq.connect()
    yield c
    c.close()


def run(con, n, queries=ORIGINAL):
    return rq.run(con, queries[n - 1])


# --- recovered schema and queries -----------------------------------------------------------------

def test_fifteen_queries_in_each_file():
    assert len(ORIGINAL) == 15 and len(CORRECTED) == 15
    assert all(rq.query_title(q).startswith(f"Query {i}:") for i, q in enumerate(ORIGINAL, 1))


def test_schema_has_four_tables(con):
    names = {r[0] for r in con.execute("SELECT table_name FROM information_schema.tables").fetchall()}
    assert names == {"Manufacturer", "Vehicle", "ListingCondition", "UsedCarListing"}


def test_foreign_keys_are_enforced(con):
    with pytest.raises(duckdb.ConstraintException):
        con.execute("INSERT INTO UsedCarListing VALUES (99,999,2020,1,1,'Automatic','x','y',1)")


@pytest.mark.parametrize("n", range(1, 16))
def test_every_original_query_executes(con, n):
    columns, rows = run(con, n)
    assert columns and isinstance(rows, list)


def test_q1_average_price_by_fuel_type(con):
    columns, rows = run(con, 1)
    got = dict(rows)
    assert columns == ["fuel_type", "avg_price"]
    assert got["Hybrid"] == pytest.approx(17500)
    assert got["Gasoline"] == pytest.approx((15000 + 14000 + 25000 + 9000 + 12000) / 5)  # NULL price ignored


def test_q9_mileage_bracket_boundaries(con):
    got = dict(run(con, 9)[1])
    assert got["Under 30k"] == pytest.approx((18000 + 12000) / 2)  # 29,999 and 0 miles
    assert got["30k–60k"] == pytest.approx((17000 + 15000) / 2)    # 30,000 and 60,000 (45,000 has no price)
    assert got["60k–100k"] == pytest.approx((14000 + 25000) / 2)   # 60,001 and 100,000
    assert got["Over 100k"] == pytest.approx(9000)                 # 100,001


def test_q15_counts_by_title_status(con):
    assert dict(run(con, 15)[1]) == {True: 7, False: 1}


# --- defects in the original queries, and their corrections ----------------------------------------

def test_original_q3_and_q6_drop_vehicles_whose_make_text_differs(con):
    for n in (3, 6):
        assert all(r[1] != "Focus" for r in run(con, n)[1])


def test_corrected_q3_and_q6_keep_them(con):
    assert any(r[1] == "Focus" for r in run(con, 3, CORRECTED)[1])  # 30 mpg is above the 28.75 average
    assert any(r[1] == "Focus" for r in run(con, 6, CORRECTED)[1])


def test_original_q5_ranks_a_zero_mileage_listing_first(con):
    rows = run(con, 5)[1]
    assert rows[0][0] == 7 and rows[0][-1] is None  # NULL price_per_mile sorts first, as in MySQL
    assert 8 not in [r[0] for r in rows]            # NULL price filtered out


def test_corrected_q5_ranks_by_true_price_per_mile(con):
    rows = run(con, 5, CORRECTED)[1]
    assert 7 not in [r[0] for r in rows]
    ratios = [r[5] / r[4] for r in rows]
    assert ratios == sorted(ratios)
    assert rows[0][0] == 6  # 9,000 / 100,001 miles


def test_original_q9_counts_unknown_mileage_as_over_100k(con):
    con.execute("INSERT INTO UsedCarListing VALUES (9,1,2015,NULL,50000,'Automatic','Red','Black',1)")
    assert dict(run(con, 9)[1])["Over 100k"] == pytest.approx((9000 + 50000) / 2)
    got = dict(run(con, 9, CORRECTED)[1])
    assert got["Over 100k"] == pytest.approx(9000) and got["Unknown"] == pytest.approx(50000)


def test_corrected_q7_matches_regardless_of_case(con):
    con.execute("INSERT INTO ListingCondition VALUES (4,'Accident reported',TRUE)")
    con.execute("INSERT INTO UsedCarListing VALUES (9,3,2012,50000,30000,'Manual','Blue','Black',4)")
    assert 9 not in [r[0] for r in run(con, 7)[1]]  # DuckDB LIKE is case-sensitive
    assert 9 in [r[0] for r in run(con, 7, CORRECTED)[1]]


@pytest.mark.parametrize("n", sorted(set(range(1, 16)) - CHANGED))
def test_unchanged_queries_are_identical(n):
    assert ORIGINAL[n - 1].sql(dialect="mysql", comments=False) == CORRECTED[n - 1].sql(dialect="mysql", comments=False)


# --- the original outputs saved in the project documents -------------------------------------------

def recovered(name):
    with open(ROOT / "results" / "recovered_original_outputs" / name, encoding="utf-8") as f:
        return list(csv.DictReader(f))


def test_recovered_q3_is_twenty_rows_in_descending_mpg():
    rows = recovered("q03_above_average_fuel_economy.csv")
    mpg = [float(r["mpg"]) for r in rows]
    assert len(rows) == 20 and mpg == sorted(mpg, reverse=True)


def test_recovered_q5_price_per_mile_is_price_over_mileage():
    rows = recovered("q05_price_per_mile.csv")
    assert len(rows) == 15
    for r in rows:
        assert round(float(r["price"]) / float(r["milage"]), 2) == float(r["price_per_mile"])
    ratios = [float(r["price_per_mile"]) for r in rows]
    assert ratios == sorted(ratios)
    assert all(float(r["milage"]) > 0 for r in rows)  # no zero-mileage listing reached the top 15


def test_recovered_q9_price_falls_with_mileage():
    rows = recovered("q09_mileage_brackets.csv")
    assert [r["mileage_bracket"] for r in rows] == ["Under 30k", "30k–60k", "60k–100k", "Over 100k"]


def test_recovered_q11_is_cheapest_first_and_under_60k_miles():
    rows = recovered("q11_cheapest_low_mileage.csv")
    prices = [float(r["price"]) for r in rows]
    assert len(rows) == 10 and prices == sorted(prices)
    assert all(int(r["milage"]) <= 60000 for r in rows)


def test_recovered_q15_every_listing_has_a_clean_title():
    assert recovered("q15_title_status.csv") == [{"clean_title": "1", "total_listings": "300"}]
