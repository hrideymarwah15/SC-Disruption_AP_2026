#!/usr/bin/env bash
# AP CP4 Benchmark Runner
# Runs all 33 catalogued queries with EXPLAIN (ANALYZE, BUFFERS) three times each.
# Saves raw plans to dbms/plans/<query_id>_run<N>.txt
#
# Usage:
#   ./benchmark.sh <database_name> [schema_file] [fixture_file] [queries_file]
#
# Example:
#   ./benchmark.sh sc_disruption_test dbms/03_schema.sql dbms/fixture_data.sql dbms/04_queries.sql

set -euo pipefail

DB_NAME="${1:-sc_disruption_test}"
SCHEMA_FILE="${2:-dbms/03_schema.sql}"
FIXTURE_FILE="${3:-dbms/fixture_data.sql}"
QUERIES_FILE="${4:-dbms/04_queries.sql}"
PLANS_DIR="dbms/plans"

if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "ERROR: Schema file not found: $SCHEMA_FILE"
  exit 1
fi
if [[ ! -f "$FIXTURE_FILE" ]]; then
  echo "ERROR: Fixture file not found: $FIXTURE_FILE"
  exit 1
fi
if [[ ! -f "$QUERIES_FILE" ]]; then
  echo "ERROR: Queries file not found: $QUERIES_FILE"
  exit 1
fi

mkdir -p "$PLANS_DIR"

echo "========================================="
echo "AP CP4 Benchmark"
echo "Database: $DB_NAME"
echo "Schema: $SCHEMA_FILE"
echo "Fixture: $FIXTURE_FILE"
echo "Queries: $QUERIES_FILE"
echo "Plans dir: $PLANS_DIR"
echo "PostgreSQL version: $(psql --version)"
echo "========================================="

# Create fresh database
echo "Creating database $DB_NAME..."
dropdb --if-exists "$DB_NAME" >/dev/null 2>&1 || true
createdb "$DB_NAME"

# Apply schema
echo "Applying schema..."
psql -d "$DB_NAME" -f "$SCHEMA_FILE" -q

# Load fixture data
echo "Loading fixture data..."
psql -d "$DB_NAME" -f "$FIXTURE_FILE" -q

# Record fixture counts
echo "Recording fixture counts..."
psql -d "$DB_NAME" -c "
  SELECT 'SupplyChain' AS table_name, COUNT(*) FROM \"SupplyChain\"
  UNION ALL SELECT 'Node', COUNT(*) FROM \"Node\"
  UNION ALL SELECT 'Edge', COUNT(*) FROM \"Edge\"
  UNION ALL SELECT 'Product', COUNT(*) FROM \"Product\"
  UNION ALL SELECT 'Inventory', COUNT(*) FROM \"Inventory\"
  UNION ALL SELECT 'Order', COUNT(*) FROM \"Order\"
  UNION ALL SELECT 'OrderItem', COUNT(*) FROM \"OrderItem\"
  UNION ALL SELECT 'Scenario', COUNT(*) FROM \"Scenario\"
  UNION ALL SELECT 'Disruption', COUNT(*) FROM \"Disruption\"
  UNION ALL SELECT 'SimulationRun', COUNT(*) FROM \"SimulationRun\"
  UNION ALL SELECT 'SimulationEvent', COUNT(*) FROM \"SimulationEvent\"
  UNION ALL SELECT 'SimulationMetric', COUNT(*) FROM \"SimulationMetric\";
" > "$PLANS_DIR/fixture_counts.txt"
cat "$PLANS_DIR/fixture_counts.txt"

# Extract individual queries from the queries file
# The queries file uses -- Rxx -- READ / -- Wxx -- WRITE markers
echo "Extracting queries..."

# Create a temporary file with each query separated
QUERY_TEMP=$(mktemp)
cat "$QUERIES_FILE" > "$QUERY_TEMP"

# Run benchmark for each query
run_benchmark() {
  local query_id="$1"
  local query_type="$2"  # READ or WRITE
  local query_sql="$3"
  local param_values="$4"  # Optional parameter values for $1, $2, etc.
  
  echo "  Benchmarking $query_id ($query_type)..."
  
  for run in 1 2 3; do
    local plan_file="$PLANS_DIR/${query_id}_run${run}.txt"
    
    if [[ "$query_type" == "WRITE" ]]; then
      # For writes: wrap in BEGIN/EXPLAIN/ROLLBACK
      psql -d "$DB_NAME" -q -c "
        BEGIN;
        EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
        $query_sql;
        ROLLBACK;
      " > "$plan_file" 2>&1
    else
      # For reads: just EXPLAIN ANALYZE
      psql -d "$DB_NAME" -q -c "
        EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
        $query_sql;
      " > "$plan_file" 2>&1
    fi
    
    # Check if query succeeded
    if grep -q "ERROR" "$plan_file"; then
      echo "    WARNING: Run $run for $query_id had errors"
      head -20 "$plan_file"
    else
      local exec_time=$(grep "Execution Time:" "$plan_file" | head -1 | awk '{print $3}')
      echo "    Run $run: ${exec_time:-?} ms"
    fi
  done
}

# Parse queries from the queries file
# This is a simplified parser - in practice you might want a more robust one
# The queries file has format:
# -- R01 -- READ
# -- Purpose: ...
# SELECT ...
# 
# -- W01 -- WRITE
# -- Purpose: ...
# INSERT ...

# Use awk to split queries by the marker lines
awk '
  /^-- R[0-9]+ -- READ/ || /^-- W[0-9]+ -- WRITE/ {
    if (in_query && query != "") {
      print "QUERY_START:" query_type ":" query_id
      print query
      print "QUERY_END"
    }
    query = ""
    if ($0 ~ /-- READ/) query_type = "READ"
    else query_type = "WRITE"
    match($0, /-- (R|W)([0-9]+)/, m)
    query_id = m[1] m[2]
    next
  }
  {
    if (query_type != "") {
      query = query $0 "\n"
    }
  }
  END {
    if (in_query && query != "") {
      print "QUERY_START:" query_type ":" query_id
      print query
      print "QUERY_END"
    }
  }
' "$QUERIES_FILE" > "$PLANS_DIR/parsed_queries.txt"

# Now run each parsed query
# For simplicity, we'll hardcode the parameter values for each query
# In a production setup, you'd extract these from the comments

echo "Running benchmarks..."

# Define parameter values for each query (from the catalog comments)
# This maps query_id -> parameter values for $1, $2, etc.

# We'll create a more complete benchmark runner in Python for better parsing
cat > "$PLANS_DIR/run_benchmark.py" << 'PYEOF'
#!/usr/bin/env python3
import subprocess
import re
import os
import sys

DB_NAME = sys.argv[1] if len(sys.argv) > 1 else "sc_disruption_test"
PLANS_DIR = "dbms/plans"
QUERIES_FILE = "dbms/04_queries.sql"

os.makedirs(PLANS_DIR, exist_ok=True)

# Read queries file
with open(QUERIES_FILE, 'r') as f:
    content = f.read()

# Parse queries
# Pattern: -- Rxx -- READ or -- Wxx -- WRITE followed by query until next marker or COMMIT
queries = []
# Split by query markers
parts = re.split(r'(-- [RW]\d+ -- (?:READ|WRITE))', content)
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
                'id': current_marker[1],
                'type': current_marker[2],
                'sql': '\n'.join(current_query).strip()
            })
        current_marker = marker_match.groups()
        current_query = []
    elif current_marker:
        current_query.append(part)

if current_marker and current_query:
    queries.append({
        'id': current_marker[1],
        'type': current_marker[2],
        'sql': '\n'.join(current_query).strip()
    })

# Parameter values for each query (from the catalog)
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

def substitute_params(sql, param_list):
    """Substitute $1, $2, etc. with actual values"""
    for i, val in enumerate(param_list, 1):
        sql = sql.replace(f'${i}', val)
    return sql

# Run benchmarks
for q in queries:
    qid = q['id']
    qtype = q['type']
    sql = q['sql']
    
    # Remove trailing semicolon if present
    sql = sql.rstrip(';').strip()
    
    param_list = params.get(qid, [])
    sql_with_params = substitute_params(sql, param_list)
    
    print(f"Benchmarking {qid} ({qtype})...")
    
    for run in range(1, 4):
        plan_file = os.path.join(PLANS_DIR, f"{qid}_run{run}.txt")
        
        if qtype == "WRITE":
            wrapped_sql = f"BEGIN;\nEXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)\n{sql_with_params};\nROLLBACK;"
        else:
            wrapped_sql = f"EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)\n{sql_with_params};"
        
        try:
            result = subprocess.run(
                ['psql', '-d', DB_NAME, '-q', '-c', wrapped_sql],
                capture_output=True, text=True, timeout=60
            )
            with open(plan_file, 'w') as f:
                f.write(result.stdout)
                if result.stderr:
                    f.write("\n--- STDERR ---\n")
                    f.write(result.stderr)
            
            # Check for errors
            if "ERROR" in result.stdout or "ERROR" in result.stderr:
                print(f"  Run {run}: ERROR")
                if result.stderr:
                    print(f"    {result.stderr[:200]}")
            else:
                # Extract execution time
                for line in result.stdout.split('\n'):
                    if 'Execution Time:' in line:
                        print(f"  Run {run}: {line.strip()}")
                        break
                else:
                    print(f"  Run {run}: (no timing found)")
        except subprocess.TimeoutExpired:
            print(f"  Run {run}: TIMEOUT")
        except Exception as e:
            print(f"  Run {run}: EXCEPTION - {e}")

print("Done.")

PYEOF

chmod +x "$PLANS_DIR/run_benchmark.py"

# Run the Python benchmark
echo "Running Python benchmark script..."
python3 "$PLANS_DIR/run_benchmark.py" "$DB_NAME"

echo "========================================="
echo "Benchmark complete. Plans saved to $PLANS_DIR/"
echo "========================================="

# Summary
echo ""
echo "Plan files created:"
ls -la "$PLANS_DIR"/*.txt | head -40

PYEOF