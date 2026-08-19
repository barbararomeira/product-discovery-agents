"""Tests for the post-run matrix validator.

The merge is a judgement and is not tested here — see `tools/validate_matrix.py` for why. What is
tested is every rule that is arithmetic or set membership, because those have one right answer and
a run that breaks one produces a matrix that looks finished and is wrong.
"""
import json
import pathlib
import subprocess
import sys

import pytest

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import validate_matrix as V  # noqa: E402

HEADER = ["Rank", "Signal", "Type", "Audience", "Roadmap status",
          "Customers (importance 1-2)", "Mentions", "Priority", "Pain point / request",
          "Customer quotes", "First seen", "Last mentioned", "Owner", "Sources"]


def row(line=4, **over):
    base = {"Rank": 1, "Signal": "Act on a stop from the phone", "Type": "Enhancement — Gap",
            "Audience": "Prospect", "Roadmap status": "Not planned",
            "Customers (importance 1-2)": "Acme Foods: 2, Vertex Motors: 2",
            "Mentions": 2, "Priority": 8, "Pain point / request": "…",
            "Customer quotes": "…", "First seen": "2026-03-02", "Last mentioned": "2026-03-03",
            "Owner": None, "Sources": "https://example.com/calls/1"}
    base.update(over)
    return (line, base)


def problems(*rows):
    return V.validate(HEADER, list(rows))


# --- the shipped example run is the fixture, and it must stay clean --------------------------

def test_example_run_matrix_is_clean():
    out = subprocess.run([sys.executable, str(ROOT / "tools" / "validate_matrix.py"),
                          str(ROOT / "example-run" / "signal-matrix.xlsx")],
                         capture_output=True, text=True)
    assert out.returncode == 0, out.stderr
    assert "rows clean" in out.stdout


def test_unreadable_matrix_exits_two_not_one():
    """A missing file is a different failure from a matrix with violations, and the run needs to
    tell them apart — one is 'fix the data', the other is 'the file is not there'."""
    out = subprocess.run([sys.executable, str(ROOT / "tools" / "validate_matrix.py"),
                          str(ROOT / "example-run" / "does-not-exist.xlsx")],
                         capture_output=True, text=True)
    assert out.returncode == 2


# --- positive case ---------------------------------------------------------------------------

def test_a_well_formed_row_raises_nothing():
    assert problems(row()) == []


# --- evidence integrity ----------------------------------------------------------------------

@pytest.mark.parametrize("cell", ["Acme Foods: 3, Vertex Motors: 2", "Acme Foods: 0"])
def test_importance_outside_the_scale_is_caught(cell):
    found = problems(row(**{"Customers (importance 1-2)": cell, "Priority": 999}))
    assert any("scale is 1 or 2 only" in p for p in found)


def test_the_same_account_twice_is_caught():
    """Counting a returning customer twice inflates both the sum and the priority."""
    found = problems(row(**{"Customers (importance 1-2)": "Acme Foods: 2, Acme Foods: 1",
                            "Priority": 6}))
    assert any("listed more than once" in p for p in found)


def test_a_row_with_no_evidence_is_caught():
    found = problems(row(**{"Customers (importance 1-2)": "", "Priority": 0}))
    assert any("no evidence" in p for p in found)


def test_a_row_with_no_source_call_is_caught():
    found = problems(row(Sources=""))
    assert any("no source call cited" in p for p in found)


# --- the priority formula, recomputed independently of the agent ------------------------------

def test_priority_that_does_not_match_the_formula_is_caught():
    found = problems(row(Priority=12))
    assert any("expected 8" in p for p in found)


def test_mentions_must_be_a_positive_whole_number():
    found = problems(row(Mentions=0, Priority=0))
    assert any("positive whole number" in p for p in found)


# --- ranking ----------------------------------------------------------------------------------

def test_ranks_must_be_contiguous_from_one():
    found = problems(row(4, Rank=1), row(5, Rank=3, Signal="Second"))
    assert any("not 1..2 exactly once" in p for p in found)


def test_ranking_must_follow_priority():
    """A silent renumber is the failure here: the numbers stay plausible and the order stops
    meaning anything."""
    low = row(4, Rank=1, Priority=4, **{"Customers (importance 1-2)": "Acme Foods: 2", "Mentions": 2})
    high = row(5, Rank=2, Priority=8, Signal="Second")
    found = problems(low, high)
    assert any("ranking is not by priority" in p for p in found)


# --- human ownership ---------------------------------------------------------------------------

def test_an_overwritten_manual_field_is_caught():
    before = {"Act on a stop from the phone": {"Owner": "Ana"}}
    found = V.compare_manual(before, HEADER, [row(Owner="Ben")])
    assert any("belong to the PM" in p for p in found)


def test_filling_an_empty_manual_field_is_allowed():
    """Setting an owner that was never set is the agent doing its job, not overwriting a human."""
    before = {"Act on a stop from the phone": {"Owner": None}}
    assert V.compare_manual(before, HEADER, [row(Owner="Ana")]) == []


def test_a_merged_away_signal_is_not_reported_as_data_loss():
    """Rows legitimately disappear when two signals turn out to be one need."""
    before = {"A signal that got merged": {"Owner": "Ana"}}
    assert V.compare_manual(before, HEADER, [row()]) == []


def test_snapshot_round_trips(tmp_path):
    snap = tmp_path / "manual.json"
    snap.write_text(json.dumps(V.manual_snapshot(HEADER, [row(Owner="Ana")])), encoding="utf-8")
    before = json.loads(snap.read_text(encoding="utf-8"))
    assert before["Act on a stop from the phone"]["Owner"] == "Ana"
    assert V.compare_manual(before, HEADER, [row(Owner="Ana")]) == []
