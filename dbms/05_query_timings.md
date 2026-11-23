# AP CP4 Query Timings and Scan Analysis

**Environment:** PostgreSQL 18.6 (Homebrew), local sequential microbenchmarks  
**Fixture:** `dbms/fixture_data.sql` — 3 supply chains, 50 nodes, 52 edges, 10 products,
107 inventory rows, 25 orders, 70 order items, 5 scenarios, 15 disruptions, 20 runs,
500 events, 20 metrics  
**Method:** Every directly executable query run three times with
`EXPLAIN (ANALYZE, BUFFERS)`; average of three runs reported.  
**Writes:** Executed inside `BEGIN` / `ROLLBACK`; rollback verified by comparing
full row contents (not just counts) before and after, including
`SimulationRun.status` and `SimulationRun.completedAt`.  
**Note:** These are local sequential measurements, not concurrent-load guarantees.
All averages derived from committed raw plans in `dbms/plans/`.  
**R08:** Composite simulation input — assembled in JavaScript from R02–R06 by the
application. Not directly executable as SQL. Not measured. No timing claimed.

---

## Timing Table

| Query | Type | Purpose | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) | Scan Type |
|-------|------|---------|------------|------------|------------|--------------|-----------|
| R01 | READ | List all supply chains with node counts | 0.104 | 0.083 | 0.077 | 0.088 | Seq Scan + Hash Right Join + HashAggregate |
| R02 | READ | Load single supply chain by ID | 0.023 | 0.034 | 0.023 | 0.027 | Index Scan (PK) |
| R03 | READ | Load nodes for a supply chain | 0.138 | 0.041 | 0.041 | 0.073 | Seq Scan + Sort |
| R04 | READ | Load edges for supply chain nodes | 0.068 | 0.061 | 0.060 | 0.063 | Sort + (plan varies) |
| R05 | READ | Load inventory with product details | 0.084 | 0.083 | 0.080 | 0.082 | Seq Scan (Inventory, Node) + Hash Join + Index Scan (Product) |
| R06 | READ | Load orders with items and products | 0.095 | 0.095 | 0.094 | 0.095 | Seq Scan (Order, Node) + Index Scan (OrderItem, Product) |
| R07 | READ | Load all products | 0.029 | 0.027 | 0.025 | 0.027 | Seq Scan + Sort |
| R08 | READ | Composite simulation input (JS-assembled) | N/A | N/A | N/A | N/A | N/A (composite — not measured) |
| R09 | READ | Get scenario by ID | 0.025 | 0.019 | 0.019 | 0.021 | Index Scan (PK) |
| R10 | READ | Get disruptions for scenario | 0.038 | 0.035 | 0.040 | 0.038 | Sort |
| R11 | READ | Get runs for scenario (DESC) | 0.038 | 0.035 | 0.034 | 0.036 | Sort |
| R12 | READ | Load simulation run by ID | 0.019 | 0.020 | 0.020 | 0.020 | Index Scan (PK) |
| R13 | READ | Get scenario for a run | 0.027 | 0.024 | 0.023 | 0.025 | Index Scan (PK) + Nested Loop |
| R14 | READ | Get disruptions for run's scenario | 0.041 | 0.037 | 0.039 | 0.039 | Sort |
| R15 | READ | Get events for run (step, sequence) | 0.043 | 0.040 | 0.054 | 0.046 | Sort |
| R16 | READ | Get metrics for run | 0.023 | 0.020 | 0.018 | 0.020 | Index Scan (Unique) |
| R17 | READ | List runs by supplyChainId with cursor pagination | 0.061 | 0.048 | 0.072 | 0.060 | Seq Scan (SimulationRun) + Hash Join + Bitmap Heap/Index Scan (Scenario) |
| R18 | READ | First page of runs for supply chain | 0.046 | 0.048 | 0.045 | 0.046 | Sort (no LIMIT in extracted SQL) |
| W01 | WRITE | Create supply chain | 0.086 | 0.078 | 0.083 | 0.082 | Insert (PK) |
| W02 | WRITE | Create node | 0.332 | 0.316 | 0.290 | 0.313 | Insert (PK + FK) |
| W03 | WRITE | Create edge | 0.313 | 0.325 | 0.311 | 0.316 | Insert (PK + 2 FK) |
| W04 | WRITE | Create product | 0.199 | 0.094 | 0.094 | 0.129 | Insert (PK + Unique) |
| W05 | WRITE | Upsert inventory (nodeId+productId) | 0.298 | 0.126 | 0.106 | 0.177 | Insert + ON CONFLICT |
| W06 | WRITE | Create order | 0.279 | 0.285 | 0.288 | 0.284 | Insert (PK + FK) |
| W07 | WRITE | Create order item | 0.393 | 0.423 | 0.610 | 0.475 | Insert (PK + FK + Unique) |
| W08 | WRITE | Create scenario | 0.311 | 0.274 | 0.270 | 0.285 | Insert (PK + FK) |
| W09 | WRITE | Create disruption | 0.336 | 0.351 | 0.328 | 0.338 | Insert (PK + FK) |
| W10 | WRITE | Create simulation run | 0.315 | 0.341 | 0.309 | 0.322 | Insert (PK + FK) |
| W11 | WRITE | Delete previous events for run | 0.070 | 0.089 | 0.068 | 0.076 | Delete (FK) |
| W12 | WRITE | Insert simulation events (bulk) | 0.369 | 0.343 | 0.373 | 0.362 | Insert (PK + FK + Unique) |
| W13 | WRITE | Upsert simulation metrics | 0.118 | 0.114 | 0.110 | 0.114 | Insert + ON CONFLICT |
| W14 | WRITE | Mark run completed/failed | 0.131 | 0.109 | 0.097 | 0.112 | Update (PK) |
| W15 | WRITE | Mark run failed (exception path) | 0.099 | 0.142 | 0.100 | 0.114 | Update (PK) |

---

## Scan Analysis

### Slowest Queries (by average execution time, measured)

| Rank | Query | Avg (ms) | Type | Primary scan operators |
|------|-------|----------|------|----------------------|
| 1 | W07 | 0.475 | WRITE | Insert (PK + FK + Unique) |
| 2 | W12 | 0.362 | WRITE | Insert (PK + FK + Unique) |
| 3 | W09 | 0.338 | WRITE | Insert (PK + FK) |
| 4 | W10 | 0.322 | WRITE | Insert (PK + FK) |
| 5 | W03 | 0.316 | WRITE | Insert (PK + 2 FK) |

### Read Query Scan Details (from raw plans)

- **R01** — Seq Scan on SupplyChain and Node, Hash Right Join, HashAggregate. No index used.
- **R03** — Seq Scan on Node with `supplyChainId = 'sc_01'` filter (35 of 50 rows removed), then Sort. No index scan used.
- **R04** — Sort on Edge.fromNodeId, Edge.id. (Plan shape varies by run; small table.)
- **R05** — Seq Scan on Inventory (all 107 rows) and Seq Scan on Node (filtered by supplyChainId), Hash Join, then Index Scan on Product_pkey per row.
- **R06** — Seq Scan on Order (all 25 rows) and Seq Scan on Node (filtered), Hash Join, then Index Scan on OrderItem_orderId_productId_key and Product_pkey.
- **R07** — Seq Scan on Product, then Sort.
- **R09** — Index Scan using Scenario_pkey.
- **R12** — Index Scan using SimulationRun_pkey.
- **R13** — Index Scan using SimulationRun_pkey, then Nested Loop to Scenario.
- **R16** — Index Scan using SimulationMetric_runId_key (unique).
- **R17** — Seq Scan on SimulationRun (all 20 rows), Hash Join, Bitmap Heap Scan + Bitmap Index Scan on Scenario_supplyChainId_createdAt_idx.
- **R18** — Same plan shape as R17 but without cursor parameters; Sort on startedAt DESC, id DESC.

### Write Queries — Rollback Verification

All 15 WRITE queries (W01–W15) executed inside `BEGIN; EXPLAIN ANALYZE ...; ROLLBACK;`.

Rollback was verified for W15 by comparing full `SimulationRun` row contents
(`id`, `status`, `completedAt`) before and after execution. The contents were
identical — no persisted update. Additionally, the W15 plan output was checked
to confirm it contains no `COMMIT` statement.

No sequence objects exist in the AP schema, so no sequence-gap claims are made.

---

## Parameters and Fixture Counts

| Table | Rows |
|-------|------|
| SupplyChain | 3 |
| Node | 50 |
| Edge | 52 |
| Product | 10 |
| Inventory | 107 |
| Order | 25 |
| OrderItem | 70 |
| Scenario | 5 |
| Disruption | 15 |
| SimulationRun | 20 |
| SimulationEvent | 500 |
| SimulationMetric | 20 |

### Environment

- PostgreSQL 18.6 (Homebrew)
- Single-threaded, sequential execution
- No concurrent workload
- Cache state varies between runs (not controlled)
- All timings in milliseconds from `Execution Time:` in `EXPLAIN (ANALYZE, BUFFERS)`

### Measured vs Skipped

- **32 queries measured** (3 runs each = 96 raw plan files)
- **1 query skipped**: R08 (composite simulation input assembled in JavaScript from R02–R06; not directly executable as SQL)

### Incomplete / Failed Measurements

None. All 32 directly executable queries produced valid `Execution Time` values
in all three runs.

---

## Procedure to Reproduce

```bash
# 1. Create a fresh, disposable test database
dropdb --if-exists sc_disruption_test || true
createdb sc_disruption_test

# 2. Apply schema
psql -d sc_disruption_test -f dbms/03_schema.sql

# 3. Load fixture data
psql -d sc_disruption_test -f dbms/fixture_data.sql

# 4. Run benchmark (requires Python 3 + psql)
python3 dbms/run_benchmark.py sc_disruption_test

# 5. Results in dbms/plans/ and dbms/plans/benchmark_summary.json
```

Raw plans for each query are saved as `dbms/plans/<query_id>_run<N>.txt` (N=1,2,3).

---

*Measured by AP CP4 benchmark procedure. Do not edit timings manually;
regenerate by re-running the benchmark.*