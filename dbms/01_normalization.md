# SC-Disruption Database Normalization

## 1. Scope and assumptions

SC-Disruption simulates a supply-chain network, applies disruption scenarios, and stores the resulting events and metrics. This normalization follows the database used by the application. Identifiers such as `supply_chain_id`, `node_id`, and `run_id` are stable surrogate keys.

The main business rules are:

- A supply chain contains many nodes and scenarios.
- A directed edge connects one origin node to one destination node.
- Inventory records the quantity of one product at one node.
- An order belongs to one node and contains one or more products.
- A scenario belongs to one supply chain and contains disruptions.
- A simulation run executes one scenario and produces ordered events and one metrics record.

## 2. Unnormalized form (UNF)

A single simulation record could initially be written as:

```text
SIMULATION_RECORD(
  supply_chain_id, supply_chain_name, supply_chain_created_at,
  nodes[{node_id, node_name, node_type,
         inventory[{product_id, product_name, sku, quantity}],
         orders[{order_id, status, due_step, created_at,
                 items[{product_id, product_name, quantity}]}]}],
  edges[{edge_id, from_node_id, to_node_id, distance, travel_time}],
  scenario_id, scenario_name, scenario_created_at,
  disruptions[{disruption_id, type, target_id, start_step, duration}],
  run_id, run_status, total_steps, started_at, completed_at,
  events[{sequence, step, type, target_type, target_id, message}],
  metrics{total_orders, total_demand, fulfilled_quantity,
          remaining_quantity, stockout_events, stockouts,
          delayed_orders, additional_cost, recovery_time,
          affected_nodes, affected_edges, final_state}
)
```

This is not in 1NF because nodes, inventory, orders, order items, disruptions, and events are repeating groups. Product and node facts would also be duplicated across orders and runs.

## 3. First normal form (1NF)

Repeating groups are separated into relations. Each row represents one occurrence and every key is explicit.

```text
SUPPLY_CHAIN(supply_chain_id PK, name, created_at)
NODE(node_id PK, supply_chain_id FK, name, type)
EDGE(edge_id PK, from_node_id FK, to_node_id FK, distance, travel_time)
PRODUCT(product_id PK, name, sku)
INVENTORY(node_id PK/FK, product_id PK/FK, quantity)
ORDER_HEADER(order_id PK, node_id FK, status, due_step, created_at)
ORDER_ITEM(order_id PK/FK, product_id PK/FK, quantity)
SCENARIO(scenario_id PK, supply_chain_id FK, name, created_at)
DISRUPTION(disruption_id PK, scenario_id FK, type, target_id, start_step, duration)
SIMULATION_RUN(run_id PK, scenario_id FK, status, total_steps, started_at, completed_at)
SIMULATION_EVENT(run_id PK/FK, sequence PK, step, type, target_type, target_id, message)
SIMULATION_METRIC(run_id PK/FK, total_orders, total_demand,
  fulfilled_quantity, remaining_quantity, stockout_events, stockouts,
  delayed_orders, additional_cost, recovery_time,
  affected_nodes, affected_edges, final_state)
```

The application stores `affected_nodes`, `affected_edges`, and `final_state` as PostgreSQL JSON values. They are immutable result snapshots treated as atomic documents by the application, not as source entities used for relational joins. If individual snapshot members later need independent querying, they should be moved to child tables.

## 4. Second normal form (2NF)

Relations with a single-attribute key are already in 2NF. The relations with natural composite keys require explicit review.

### Inventory

Functional dependencies before decomposition:

```text
(node_id, product_id) -> quantity
node_id -> node_name, node_type, supply_chain_id
product_id -> product_name, sku
```

`node_name`, `node_type`, and `product_name` depend on only part of the composite key, so they must not be stored in `INVENTORY`. The 2NF design is:

```text
NODE(node_id, supply_chain_id, name, type)
PRODUCT(product_id, name, sku)
INVENTORY(node_id, product_id, quantity)
```

### Order items

Functional dependencies before decomposition:

```text
(order_id, product_id) -> quantity
order_id -> node_id, status, due_step, created_at
product_id -> product_name, sku
```

Order-level and product-level attributes are partial dependencies. The 2NF design is:

```text
ORDER_HEADER(order_id, node_id, status, due_step, created_at)
PRODUCT(product_id, name, sku)
ORDER_ITEM(order_id, product_id, quantity)
```

### Simulation events

```text
(run_id, sequence) -> step, type, target_type, target_id, message
```

All non-key attributes depend on the whole event key. Run-level fields are kept in `SIMULATION_RUN`, so `SIMULATION_EVENT` is in 2NF.

## 5. Third normal form (3NF)

Transitive dependencies are removed so non-key attributes describe only their relation's key.

| Relation | Important functional dependencies | 3NF decision |
|---|---|---|
| `SUPPLY_CHAIN` | `supply_chain_id -> name, created_at` | Supply-chain facts stay here. |
| `NODE` | `node_id -> supply_chain_id, name, type` | Supply-chain name is not copied into nodes. |
| `EDGE` | `edge_id -> from_node_id, to_node_id, distance, travel_time` | Node names are resolved through the two foreign keys. |
| `PRODUCT` | `product_id -> name, sku`; `sku -> product_id, name` | Product facts are stored once. |
| `INVENTORY` | `(node_id, product_id) -> quantity` | No node or product description is duplicated. |
| `ORDER_HEADER` | `order_id -> node_id, status, due_step, created_at` | Node details are obtained through `node_id`. |
| `ORDER_ITEM` | `(order_id, product_id) -> quantity` | Order and product facts remain in their parent tables. |
| `SCENARIO` | `scenario_id -> supply_chain_id, name, created_at` | Supply-chain details are not repeated. |
| `DISRUPTION` | `disruption_id -> scenario_id, type, target_id, start_step, duration` | Scenario details are obtained through `scenario_id`. |
| `SIMULATION_RUN` | `run_id -> scenario_id, status, total_steps, started_at, completed_at` | Scenario name is not copied into runs. |
| `SIMULATION_EVENT` | `(run_id, sequence) -> step, type, target_type, target_id, message` | Run and scenario facts are not repeated. |
| `SIMULATION_METRIC` | `run_id -> all metric attributes` | The one-to-one result is keyed by its run. |

For example, storing `supply_chain_name` in `SCENARIO` would introduce the transitive dependency `scenario_id -> supply_chain_id -> supply_chain_name`. Keeping the name only in `SUPPLY_CHAIN` removes that update anomaly.

## 6. BCNF review

A relation is in BCNF when every determinant is a candidate key.

- `SUPPLY_CHAIN`, `NODE`, `EDGE`, `ORDER_HEADER`, `SCENARIO`, `DISRUPTION`, and `SIMULATION_RUN` use their identifiers as candidate keys.
- `PRODUCT` has two candidate keys: `product_id` and the unique `sku`. Both determinants are candidate keys.
- `INVENTORY` uses `(node_id, product_id)` as its candidate key.
- `ORDER_ITEM` uses `(order_id, product_id)` as its logical candidate key.
- `SIMULATION_EVENT` uses `(run_id, sequence)` as its candidate key, guaranteeing a stable event order within each run.
- `SIMULATION_METRIC` uses `run_id` as its candidate key, enforcing at most one metric row per run.

Under the stated business rules, all final relations satisfy BCNF. The implementation additionally uses surrogate `id` columns for ORM convenience. It already enforces the natural uniqueness constraints for inventory, product SKU, event sequence within a run, and one metrics record per run. To make the implementation fully match the logical BCNF design, `ORDER_ITEM` should also enforce a unique constraint on `(order_id, product_id)`; otherwise duplicate product lines remain possible within one order.

## 7. Final normalized schema summary

```text
SUPPLY_CHAIN 1 --- N NODE
NODE N --- N PRODUCT              through INVENTORY
NODE 1 --- N ORDER_HEADER
ORDER_HEADER N --- N PRODUCT      through ORDER_ITEM
NODE 1 --- N EDGE                 as origin
NODE 1 --- N EDGE                 as destination
SUPPLY_CHAIN 1 --- N SCENARIO
SCENARIO 1 --- N DISRUPTION
SCENARIO 1 --- N SIMULATION_RUN
SIMULATION_RUN 1 --- N SIMULATION_EVENT
SIMULATION_RUN 1 --- 0..1 SIMULATION_METRIC
```

This structure prevents repeated master data, avoids partial and transitive dependencies, and supports the application without insert, update, or delete anomalies.
