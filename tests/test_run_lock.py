"""Tests for the single-run lock in scripts/run_daily.sh (Decision 1).

These exercise the lock block *extracted from the shipped script*, not a copy of it, so the test
fails if someone edits the real thing. Running the whole script is not an option — it would call a
model — and copying the block into the test would only assert that the copy still works.

Two paths matter, and the second is the one people get wrong: a lock that outlives its holder turns
a crash into a permanent outage, which is worse than the race it was added to prevent.
"""
import os
import pathlib
import re
import signal
import subprocess
import sys
import time

import pytest

ROOT = pathlib.Path(__file__).resolve().parent.parent
RUNNER = ROOT / "scripts" / "run_daily.sh"

if sys.platform.startswith("win"):
    pytest.skip("POSIX shell lock", allow_module_level=True)


def lock_block() -> str:
    """The lock, lifted verbatim from the runner — from its banner to the trap that releases it."""
    text = RUNNER.read_text(encoding="utf-8")
    m = re.search(r"# --- single-run lock ---.*?^trap .*?$", text, re.S | re.M)
    assert m, "lock block not found in run_daily.sh — did it move, or get removed?"
    return m.group(0)


def harness(tmp_path, body: str, name: str = "harness") -> pathlib.Path:
    script = tmp_path / f"{name}.sh"
    script.write_text("#!/bin/zsh\nLOGDIR=\"$1\"\n" + lock_block() + "\n" + body + "\n",
                      encoding="utf-8")
    script.chmod(0o755)
    return script


def test_the_lock_block_is_still_in_the_runner():
    assert "single-run lock" in RUNNER.read_text(encoding="utf-8")


def test_a_second_run_aborts_while_the_first_holds_the_lock(tmp_path):
    logdir = tmp_path
    first = harness(tmp_path, 'echo held; sleep 3', "first")
    second = harness(tmp_path, 'echo "SHOULD NOT RUN"', "second")

    a = subprocess.Popen(["/bin/zsh", str(first), str(logdir)],
                         stdout=subprocess.PIPE, text=True)
    for _ in range(50):                       # wait for the lock to be taken, not a fixed sleep
        if (logdir / ".run_daily.lock" / "pid").exists():
            break
        time.sleep(0.05)
    else:
        a.kill()
        pytest.fail("first run never took the lock")

    b = subprocess.run(["/bin/zsh", str(second), str(logdir)], capture_output=True, text=True)
    a.wait(timeout=15)

    assert b.returncode == 0, "a blocked run exits cleanly; it is not an error"
    assert "SHOULD NOT RUN" not in b.stdout, "the second run did work while the first held the lock"
    assert "run already in progress" in (logdir / "failures.log").read_text(encoding="utf-8")


def test_a_stale_lock_from_a_dead_process_is_reclaimed(tmp_path):
    """A lock left by a crashed run must not block every future run — that is an outage, not a guard."""
    logdir = tmp_path
    lock = logdir / ".run_daily.lock"
    lock.mkdir()
    dead = 999_999
    with pytest.raises(OSError):              # prove the pid really is not running
        os.kill(dead, 0)
    (lock / "pid").write_text(str(dead), encoding="utf-8")

    out = subprocess.run(["/bin/zsh", str(harness(tmp_path, 'echo reclaimed')), str(logdir)],
                         capture_output=True, text=True)
    assert out.returncode == 0
    assert "reclaimed" in out.stdout, "the run should have proceeded after reclaiming a stale lock"
    assert "stale lock" in (logdir / "failures.log").read_text(encoding="utf-8")


def test_the_lock_is_released_when_the_run_finishes(tmp_path):
    logdir = tmp_path
    subprocess.run(["/bin/zsh", str(harness(tmp_path, 'echo done')), str(logdir)],
                   capture_output=True, text=True)
    assert not (logdir / ".run_daily.lock").exists(), "the lock outlived the run that took it"


def test_the_lock_is_released_when_the_run_is_killed(tmp_path):
    """The trap covers TERM, because the runner's own watchdog kills a stalled run that way."""
    logdir = tmp_path
    p = subprocess.Popen(["/bin/zsh", str(harness(tmp_path, 'sleep 10')), str(logdir)])
    for _ in range(50):
        if (logdir / ".run_daily.lock" / "pid").exists():
            break
        time.sleep(0.05)
    p.send_signal(signal.SIGTERM)
    p.wait(timeout=10)
    time.sleep(0.2)
    assert not (logdir / ".run_daily.lock").exists(), "a killed run left its lock behind"
