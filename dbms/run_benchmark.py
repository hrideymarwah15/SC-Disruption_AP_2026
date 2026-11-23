#!/usr/bin/env python3
"""
AP CP4 Benchmark Runner

Runs every directly executable query in dbms/04_queries.sql three times with
EXPLAIN (ANALYZE, BUFFERS) and saves raw plans to dbms/plans/<query_id>_run<N>.txt.

Usage:
    python3 run_benchmark.py <database_name>

Design rules:
- Each query is extracted from the catalogue by its `-- Rxx -- READ` / `-- Wxx -- WRITE`
  marker. Trailing transaction-control statements (COMMIT, ROLLBACK, BEGIN) and the
  audit footer are stripped. No query may contain BEGIN/COMMIT/ROLLBACK/SET.
- Every WRITE executes inside `BEGIN; EXPLAIN ANALYZE ...; ROLLBACK;`.
- A SQL error, nonzero process exit, missing timing, or incomplete run fails the run.
- Rollback is verified by comparing row contents (not just counts) before and after,
  including SimulationRun.status and SimulationRun.completedAt.
- R08 is a composite JavaScript-assembled operation and is explicitly skipped.
"""

import json
import os
import re
import subprocess
import sys

QUERIES_FILE = "dbms/04_queries.sql"
PLANS_DIR = os.environ.get("AP_PLANS_DIR", "dbms/plans")
SKIP_QUERIES = {"R08"}  # Composite simulation input, assembled in JS from R02-R06

# Parameter values (from the catalogue comment blocks).
PARAMS = {
    "R01": [],
    "R02": ["'sc_01'"],
    "R03": ["'sc_01'"],
    "R04": ["'sc_01'"],
    "R05": ["'sc_01'"],
    "R06": ["'sc_01'"],
    "R07": [],
    "R09": ["'scn_01'"],
    "R10": ["'scn_01'"],
    "R11": ["'scn_01'"],
    "R12": ["'run_01'"],
    "R13": ["'run_01'"],
    "R14": ["'run_01'"],
    "R15": ["'run_01'"],
    "R16": ["'run_01'"],
    "R17": ["'sc_01'", "NULL", "NULL", "NULL", "10"],
    "R18": ["'sc_01'", "NULL", "10"],
    "W01": ["'sc_new'", "'New Chain'", "NULL"],
    "W02": ["'n_new'", "'sc_01'", "'New Node'", "'FACTORY'"],
    "W03": ["'e_new'", "'n_01'", "'n_02'", "100.0", "5.0"],
    "W04": ["'p_new'", "'New Product'", "'NEW-SKU-001'", "NULL"],
    "W05": ["'inv_new'", "'n_01'", "'p_01'", "100"],
    "W06": ["'o_new'", "'n_01'", "'PENDING'", "0", "NULL"],
    "W07": ["'oi_new'", "'o_25'", "'p_10'", "10"],
    "W08": ["'scn_new'", "'sc_01'", "'New Scenario'", "NULL"],
    "W09": ["'dis_new'", "'scn_01'", "'SUPPLIER_FAILURE'", "'n_01'", "5", "10"],
    "W10": ["'run_new'", "'scn_01'", "30", "'RUNNING'", "NULL"],
    "W11": ["'run_01'"],
    "W12": ["'evt_new'", "'run_01'", "9999", "1", "'TYPE'", "'NODE'", "'n_01'", "'Test event'"],
    "W13": ["'met_new'", "'run_01'", "10", "1000", "800", "200", "2", "1", "1", "1000.0", "5", "'[]'", "'[]'", "NULL"],
    "W14": ["'run_01'", "'COMPLETED'", "NULL"],
    "W15": ["'run_01'", "NULL"],
}

# Transaction-control statements that must never appear as standalone statements
# inside an extracted query. Embedded keywords like UPDATE ... SET are fine.
TXN_STATEMENTS = re.compile(
    r"(?:^|;\s*)\s*(?:BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE|DECLARE)\b",
    re.IGNORECASE,
)


def parse_queries(path):
    """Split the catalogue into per-query dicts, stripping COMMIT and audit footer.

    Extraction stops at the first line that is exactly `COMMIT;` or at the
    audit-footer separator. No extracted query may contain BEGIN/COMMIT/
    ROLLBACK/SAVEPOINT/RELEASE/DECLARE as standalone statements (embedded
    keywords like UPDATE ... SET are allowed).
    """
    with open(path, "r") as f:
        lines = f.readlines()

    queries = []
    current_marker = None
    current_sql = []

    def flush():
        nonlocal current_marker, current_sql
        if current_marker and current_sql:
            raw = "\n".join(current_sql).strip()
            raw = raw.strip().rstrip(";").strip()
            if TXN_STATEMENTS.search(raw):
                raise SystemExit(
                    f"ERROR: extracted query {current_marker[0]} contains a "
                    f"transaction-control statement:\n{raw[:200]}"
                )
            queries.append({
                "id": current_marker[0],
                "type": current_marker[1],
                "sql": raw,
            })
        current_marker = None
        current_sql = []

    for line in lines:
        stripped = line.strip()
        # Stop at COMMIT; or audit-footer separator.
        if stripped == "COMMIT;" or stripped.startswith("-- ====================================================================="):
            flush()
            continue
        m = re.match(r"-- ([RW]\d+) -- (READ|WRITE)", stripped)
        if m:
            flush()
            current_marker = m.groups()
            current_sql = []
        elif current_marker:
            current_sql.append(line.rstrip("\n"))

    flush()

    return queries


def substitute_params(sql, param_list):
    """Substitute $1, $2, ... with actual values, highest index first."""
    for i in range(len(param_list), 0, -1):
        sql = sql.replace(f"${i}", param_list[i - 1])
    return sql


def run_single(db_name, qid, qtype, sql_with_params, run_no, plans_dir):
    """Run one EXPLAIN ANALYZE for one query and one run."""
    plan_file = os.path.join(plans_dir, f"{qid}_run{run_no}.txt")

    if qtype == "WRITE":
        wrapped = f"BEGIN;\nEXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)\n{sql_with_params};\nROLLBACK;"
    else:
        wrapped = f"EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)\n{sql_with_params};"

    try:
        result = subprocess.run(
            ["psql", "-X", "-v", "ON_ERROR_STOP=1", "-d", db_name, "-q", "-c", wrapped],
            capture_output=True, text=True, timeout=120,
        )
    except subprocess.TimeoutExpired as exc:
        raise SystemExit(f"ERROR: {qid} run {run_no} timed out: {exc}")

    if result.returncode != 0:
        raise SystemExit(
            f"ERROR: {qid} run {run_no} exited {result.returncode}\n"
            f"STDERR: {result.stderr[:500]}"
        )

    with open(plan_file, "w") as f:
        f.write(result.stdout)
        if result.stderr:
            f.write("\n--- STDERR ---\n")
            f.write(result.stderr)

    if "ERROR" in result.stdout or "ERROR" in result.stderr:
        raise SystemExit(
            f"ERROR: {qid} run {run_no} produced an SQL error:\n"
            f"{result.stdout[:500]}\n{result.stderr[:500]}"
        )

    exec_time = None
    for line in result.stdout.splitlines():
        if "Execution Time:" in line:
            match = re.search(r"Execution Time:\s+([\d.]+)\s*ms", line)
            if match:
                exec_time = float(match.group(1))
            break

    if exec_time is None:
        raise SystemExit(
            f"ERROR: {qid} run {run_no} has no Execution Time in plan output"
        )

    return exec_time


def snapshot(db_name):
    """Capture every application row; failed reads must never count as evidence."""
    tables = ["SupplyChain", "Node", "Edge", "Product", "Inventory", "Order",
              "OrderItem", "Scenario", "Disruption", "SimulationRun",
              "SimulationEvent", "SimulationMetric"]
    state = {}
    for table in tables:
        sql = f'SELECT row_to_json(t)::text FROM "{table}" t ORDER BY id;'
        result = subprocess.run(
            ["psql", "-X", "-v", "ON_ERROR_STOP=1", "-d", db_name,
             "-t", "-A", "-c", sql], capture_output=True, text=True, timeout=120,
        )
        if result.returncode != 0 or "ERROR" in result.stderr:
            raise SystemExit(f"ERROR: snapshot of {table} failed: {result.stderr}")
        state[table] = result.stdout
    if not state["SimulationRun"].strip():
        raise SystemExit("ERROR: rollback verification requires populated SimulationRun")
    return state


def verify_rollback(db_name, plans_dir):
    """Check W15 against full row snapshots, including quoted JSON field names."""
    before = snapshot(db_name)
    query = next(q for q in parse_queries(QUERIES_FILE) if q["id"] == "W15")
    sql = substitute_params(query["sql"], PARAMS["W15"])
    run_single(db_name, "W15_rollback_check", "WRITE", sql, 1, plans_dir)
    if before != snapshot(db_name):
        raise SystemExit("ERROR: W15 rollback changed database contents")
    print("Rollback verification passed: W15 left all application rows unchanged.")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 run_benchmark.py <database_name>", file=sys.stderr)
        sys.exit(1)

    db_name = sys.argv[1]
    plans_dir = PLANS_DIR
    os.makedirs(plans_dir, exist_ok=True)

    queries = parse_queries(QUERIES_FILE)
    print(f"Found {len(queries)} queries in catalogue ({len(SKIP_QUERIES)} to skip).")

    missing_params = [q["id"] for q in queries
                      if q["id"] not in PARAMS and q["id"] not in SKIP_QUERIES]
    if missing_params:
        raise SystemExit(f"ERROR: Missing params for: {missing_params}")

    # Verify W15 extraction excludes COMMIT before running anything.
    for q in queries:
        if q["id"] == "W15":
            if "COMMIT" in q["sql"].upper():
                raise SystemExit("ERROR: W15 extracted SQL still contains COMMIT")
            break
    print("Regression check passed: W15 extraction excludes COMMIT.")

    expected = {f"R{i:02d}" for i in range(1, 19)} | {f"W{i:02d}" for i in range(1, 16)}
    ids = [q["id"] for q in queries]
    if len(ids) != len(expected) or set(ids) != expected:
        raise SystemExit("ERROR: catalogue must contain each of the 33 query IDs exactly once")
    before = snapshot(db_name)
    results = []
    for q in queries:
        qid = q["id"]
        qtype = q["type"]

        if qid in SKIP_QUERIES:
            print(f"\nSkipping {qid} ({qtype}) — composite operation (JS-assembled).")
            results.append({"id": qid, "type": qtype, "runs": [], "skipped": True})
            continue

        sql_raw = q["sql"]
        sql_with_params = substitute_params(sql_raw, PARAMS[qid])

        print(f"\nBenchmarking {qid} ({qtype})...")
        query_results = {"id": qid, "type": qtype, "runs": []}

        for run_no in range(1, 4):
            exec_time = run_single(db_name, qid, qtype, sql_with_params, run_no, plans_dir)
            query_results["runs"].append({
                "run": run_no,
                "plan_file": os.path.join(plans_dir, f"{qid}_run{run_no}.txt"),
                "execution_time_ms": exec_time,
            })
            print(f"  Run {run_no}: {exec_time:.3f} ms")
            if qtype == "WRITE" and snapshot(db_name) != before:
                raise SystemExit(f"ERROR: {qid} run {run_no} changed database contents")

        results.append(query_results)

    # Verify rollback for W15.
    verify_rollback(db_name, plans_dir)

    # Save summary.
    summary_file = os.path.join(plans_dir, "benchmark_summary.json")
    with open(summary_file, "w") as f:
        json.dump(results, f, indent=2)

    print(f"\n\nBenchmark complete. Summary saved to {summary_file}")
    print(f"Individual plans in {plans_dir}/")

    print("\n=== SUMMARY ===")
    print(f"{'Query':<6} {'Type':<5} {'Run1':>8} {'Run2':>8} {'Run3':>8} {'Avg':>8} {'Status'}")
    print("-" * 60)
    for r in results:
        if r.get("skipped"):
            print(f"{r['id']:<6} {r['type']:<5} {'SKIP':>8} {'SKIP':>8} {'SKIP':>8} {'SKIP':>8} SKIP")
            continue
        times = [run["execution_time_ms"] for run in r["runs"]
                 if run["execution_time_ms"] is not None]
        avg = sum(times) / len(times) if times else None
        t1 = f"{times[0]:.3f}" if len(times) > 0 else "ERROR"
        t2 = f"{times[1]:.3f}" if len(times) > 1 else "ERROR"
        t3 = f"{times[2]:.3f}" if len(times) > 2 else "ERROR"
        avg_str = f"{avg:.3f}" if avg else "ERROR"
        print(f"{r['id']:<6} {r['type']:<5} {t1:>8} {t2:>8} {t3:>8} {avg_str:>8} {'OK'}")


if __name__ == "__main__":
    main()