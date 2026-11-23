#!/usr/bin/env bash
# AP CP4 Benchmark Runner — shell wrapper around dbms/run_benchmark.py
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "ERROR: Schema file not found: $SCHEMA_FILE" >&2
  exit 1
fi
if [[ ! -f "$FIXTURE_FILE" ]]; then
  echo "ERROR: Fixture file not found: $FIXTURE_FILE" >&2
  exit 1
fi
if [[ ! -f "$QUERIES_FILE" ]]; then
  echo "ERROR: Queries file not found: $QUERIES_FILE" >&2
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

# Create a fresh, disposable database. Never run against an application or
# production database — the caller must supply a throwaway name.
dropdb --if-exists "$DB_NAME" >/dev/null 2>&1 || true
createdb "$DB_NAME"

echo "Applying schema..."
psql -d "$DB_NAME" -f "$SCHEMA_FILE" -q

echo "Loading fixture data..."
psql -d "$DB_NAME" -f "$FIXTURE_FILE" -q

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

echo "Running benchmark..."
python3 "$SCRIPT_DIR/run_benchmark.py" "$DB_NAME"

echo "========================================="
echo "Benchmark complete. Plans saved to $PLANS_DIR/"
echo "========================================="