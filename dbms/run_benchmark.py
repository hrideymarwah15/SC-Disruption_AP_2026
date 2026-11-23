#!/usr/bin/env python3
"""
AP CP4 Benchmark Runner
Runs all 33 catalogued queries with EXPLAIN (ANALYZE, BUFFERS) three times each.
Saves raw plans to dbms/plans/<query_id>_run<N>.txt

Usage:
  python3 run_benchmark.py <database_name>
"""

import subprocess
import re
import os
import sys
import json

def parse_queries(queries_file):
    """Parse the queries file into a list of query dicts."""
    with open(queries_file, 'r') as f:
        content = f.read()
    
    # Split by query markers
    parts = re.split(r'(-- [RW]\d+ -- (?:READ|WRITE))', content)
    queries = []
    current_marker = None
    current_query = []
    
    for part in parts:
        part = part.strip()
        if not part:
            continue
        marker_match = re.match(r'-- ([RW]\d+) -- (READ|WRITE)', part)
        if marker_match:
            if current_marker and current_query:
                queries.append({
                    'id': current_marker[0],
                    'type': current_marker[1],
                    'sql': '\n'.join(current_query).strip()
                })
            current_marker = marker_match.groups()
            current_query = []
        elif current_marker:
            current_query.append(part)
    
    if current_marker and current_query:
        queries.append({
            'id': current_marker[0],
            'type': current_marker[1],
            'sql': '\n'.join(current_query).strip()
        })
    
    return queries

def substitute_params(sql, param_list):
    """Substitute $1, $2, etc. with actual values."""
    for i, val in enumerate(param_list, 1):
        sql = sql.replace(f'${i}', val)
    return sql

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 run_benchmark.py <database_name>")
        sys.exit(1)
    
    DB_NAME = sys.argv[1]
    PLANS_DIR = "dbms/plans"
    QUERIES_FILE = "dbms/04_queries.sql"
    
    os.makedirs(PLANS_DIR, exist_ok=True)
    
    # Parameter values for each query (from the catalog comments)
    params = {
        'R01': [],
        'R02': ["'sc_01'"],
        'R03': ["'sc_01'"],
        'R04': ["'sc_01'"],
        'R05': ["'sc_01'"],
        'R06': ["'sc_01'"],
        'R07': [],
        'R08': ["'sc_01'"],
        'R09': ["'scn_01'"],
        'R10': ["'scn_01'"],
        'R11': ["'scn_01'"],
        'R12': ["'run_01'"],
        'R13': ["'run_01'"],
        'R14': ["'run_01'"],
        'R15': ["'run_01'"],
        'R16': ["'run_01'"],
        'R17': ["'sc_01'", "NULL", "NULL", "NULL", "10"],
        'R18': ["'sc_01'", "NULL", "10"],
        'W01': ["'sc_new'", "'New Chain'", "NULL"],
        'W02': ["'n_new'", "'sc_01'", "'New Node'", "'FACTORY'"],
        'W03': ["'e_new'", "'n_01'", "'n_02'", "100.0", "5.0"],
        'W04': ["'p_new'", "'New Product'", "'NEW-SKU-001'", "NULL"],
        'W05': ["'inv_new'", "'n_01'", "'p_01'", "100"],
        'W06': ["'o_new'", "'n_01'", "'PENDING'", "0", "NULL"],
        'W07': ["'oi_new'", "'o_01'", "'p_01'", "10"],
        'W08': ["'scn_new'", "'sc_01'", "'New Scenario'", "NULL"],
        'W09': ["'dis_new'", "'scn_01'", "'SUPPLIER_FAILURE'", "'n_01'", "5", "10"],
        'W10': ["'run_new'", "'scn_01'", "30", "'RUNNING'", "NULL"],
        'W11': ["'run_01'"],
        'W12': ["'evt_new'", "'run_01'", "0", "1", "'TYPE'", "'NODE'", "'n_01'", "'Test event'"],
        'W13': ["'met_new'", "'run_01'", "10", "1000", "800", "200", "2", "1", "1", "1000.0", "5", "'[]'", "'[]'", "NULL"],
        'W14': ["'run_01'", "'COMPLETED'", "NULL"],
        'W15': ["'run_01'", "NULL"],
    }
    
    queries = parse_queries(QUERIES_FILE)
    print(f"Found {len(queries)} queries to benchmark")
    
    # Verify we have params for all queries
    missing = [q['id'] for q in queries if q['id'] not in params]
    if missing:
        print(f"WARNING: Missing params for: {missing}")
    
    results = []
    
    for q in queries:
        qid = q['id']
        qtype = q['type']
        sql = q['sql'].rstrip(';').strip()
        
        param_list = params.get(qid, [])
        sql_with_params = substitute_params(sql, param_list)
        
        print(f"\nBenchmarking {qid} ({qtype})...")
        
        query_results = {'id': qid, 'type': qtype, 'runs': []}
        
        for run in range(1, 4):
            plan_file = os.path.join(PLANS_DIR, f"{qid}_run{run}.txt")
            
            if qtype == "WRITE":
                wrapped_sql = f"BEGIN;\nEXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)\n{sql_with_params};\nROLLBACK;"
            else:
                wrapped_sql = f"EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)\n{sql_with_params};"
            
            try:
                result = subprocess.run(
                    ['psql', '-d', DB_NAME, '-q', '-c', wrapped_sql],
                    capture_output=True, text=True, timeout=120
                )
                with open(plan_file, 'w') as f:
                    f.write(result.stdout)
                    if result.stderr:
                        f.write("\n--- STDERR ---\n")
                        f.write(result.stderr)
                
                # Extract execution time
                exec_time = None
                for line in result.stdout.split('\n'):
                    if 'Execution Time:' in line:
                        match = re.search(r'Execution Time:\s+([\d.]+)\s*ms', line)
                        if match:
                            exec_time = float(match.group(1))
                        break
                
                has_error = "ERROR" in result.stdout or "ERROR" in result.stderr
                
                run_result = {
                    'run': run,
                    'plan_file': plan_file,
                    'execution_time_ms': exec_time,
                    'has_error': has_error,
                    'stderr': result.stderr[:500] if result.stderr else None
                }
                query_results['runs'].append(run_result)
                
                if has_error:
                    print(f"  Run {run}: ERROR")
                    if result.stderr:
                        print(f"    {result.stderr[:200]}")
                else:
                    print(f"  Run {run}: {exec_time:.3f} ms" if exec_time else f"  Run {run}: (no timing)")
                    
            except subprocess.TimeoutExpired:
                print(f"  Run {run}: TIMEOUT")
                query_results['runs'].append({
                    'run': run, 'plan_file': plan_file, 'execution_time_ms': None,
                    'has_error': True, 'stderr': 'TIMEOUT'
                })
            except Exception as e:
                print(f"  Run {run}: EXCEPTION - {e}")
                query_results['runs'].append({
                    'run': run, 'plan_file': plan_file, 'execution_time_ms': None,
                    'has_error': True, 'stderr': str(e)
                })
        
        results.append(query_results)
    
    # Save summary
    summary_file = os.path.join(PLANS_DIR, "benchmark_summary.json")
    with open(summary_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\n\nBenchmark complete. Summary saved to {summary_file}")
    print(f"Individual plans in {PLANS_DIR}/")
    
    # Print summary table
    print("\n=== SUMMARY ===")
    print(f"{'Query':<6} {'Type':<5} {'Run1':>8} {'Run2':>8} {'Run3':>8} {'Avg':>8} {'Status'}")
    print("-" * 60)
    for r in results:
        times = [run['execution_time_ms'] for run in r['runs'] if run['execution_time_ms'] is not None]
        avg = sum(times) / len(times) if times else None
        has_error = any(run['has_error'] for run in r['runs'])
        status = "ERROR" if has_error else "OK"
        t1 = f"{times[0]:.3f}" if len(times) > 0 else "ERROR"
        t2 = f"{times[1]:.3f}" if len(times) > 1 else "ERROR"
        t3 = f"{times[2]:.3f}" if len(times) > 2 else "ERROR"
        avg_str = f"{avg:.3f}" if avg else "ERROR"
        print(f"{r['id']:<6} {r['type']:<5} {t1:>8} {t2:>8} {t3:>8} {avg_str:>8} {status}")

if __name__ == '__main__':
    main()