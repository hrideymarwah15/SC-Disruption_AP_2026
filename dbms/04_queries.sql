-- SC-Disruption AP database queries (PostgreSQL)
-- CP3: Catalogue of verified application queries derived from source code.
-- Each query is labeled with a stable ID (Rxx for reads, Wxx for writes),
-- marked as -- READ or -- WRITE, and documented with purpose and parameters.
-- Table and column names exactly match dbms/03_schema.sql.
-- Audit footer lists the application source files reviewed.

BEGIN;
SET search_path TO public;

-- =====================================================================
-- READ queries — Core supply chain operations
-- =====================================================================

-- R01 -- READ
-- Purpose: List all supply chains with their node count for the dashboard.
-- Source: supplyChainRepository.getAllSupplyChains()
-- Called by: simulationService.listSupplyChains()
SELECT "SupplyChain"."id",
       "SupplyChain"."name",
       "SupplyChain"."createdAt",
       COUNT("Node"."id") AS node_count
FROM "SupplyChain"
LEFT JOIN "Node" ON "Node"."supplyChainId" = "SupplyChain"."id"
GROUP BY "SupplyChain"."id", "SupplyChain"."name", "SupplyChain"."createdAt"
ORDER BY "SupplyChain"."createdAt" DESC;

-- R02 -- READ
-- Purpose: Load a single supply chain by ID.
-- Source: supplyChainRepository.getSupplyChain(id)
-- Called by: simulationService.startSimulation() -> loadSimulationInput()
-- Parameter: $1 = supplyChainId (TEXT)
SELECT "SupplyChain"."id",
       "SupplyChain"."name",
       "SupplyChain"."createdAt"
FROM "SupplyChain"
WHERE "SupplyChain"."id" = $1;

-- R03 -- READ
-- Purpose: Load all nodes for a supply chain (used by getSupplyChain include).
-- Source: supplyChainRepository.getSupplyChain(id) -> nodes include
-- Parameter: $1 = supplyChainId (TEXT)
SELECT "Node"."id",
       "Node"."supplyChainId",
       "Node"."name",
       "Node"."type"
FROM "Node"
WHERE "Node"."supplyChainId" = $1
ORDER BY "Node"."id";

-- R04 -- READ
-- Purpose: Load all edges for a supply chain's nodes (outgoing edges per node).
-- Source: supplyChainRepository.getSupplyChain(id) -> nodes.outgoing include
-- Parameter: $1 = supplyChainId (TEXT)
SELECT "Edge"."id",
       "Edge"."fromNodeId",
       "Edge"."toNodeId",
       "Edge"."distance",
       "Edge"."travelTime"
FROM "Edge"
JOIN "Node" ON "Node"."id" = "Edge"."fromNodeId"
WHERE "Node"."supplyChainId" = $1
ORDER BY "Edge"."fromNodeId", "Edge"."id";

-- R05 -- READ
-- Purpose: Load all inventory items for a supply chain's nodes with product details.
-- Source: supplyChainRepository.getSupplyChain(id) -> nodes.inventory.product include
-- Parameter: $1 = supplyChainId (TEXT)
SELECT "Inventory"."id",
       "Inventory"."nodeId",
       "Inventory"."productId",
       "Inventory"."quantity",
       "Product"."name"  AS product_name,
       "Product"."sku"   AS product_sku
FROM "Inventory"
JOIN "Product" ON "Product"."id" = "Inventory"."productId"
JOIN "Node" ON "Node"."id" = "Inventory"."nodeId"
WHERE "Node"."supplyChainId" = $1
ORDER BY "Inventory"."nodeId", "Inventory"."productId";

-- R06 -- READ
-- Purpose: Load all orders for a supply chain's nodes with order items and product details.
-- Source: supplyChainRepository.getSupplyChain(id) -> nodes.orders.items.product include
-- Parameter: $1 = supplyChainId (TEXT)
SELECT "Order"."id",
       "Order"."nodeId",
       "Order"."status",
       "Order"."dueStep",
       "Order"."createdAt",
       "OrderItem"."id"        AS item_id,
       "OrderItem"."productId",
       "OrderItem"."quantity",
       "Product"."name"  AS product_name,
       "Product"."sku"   AS product_sku
FROM "Order"
JOIN "Node" ON "Node"."id" = "Order"."nodeId"
JOIN "OrderItem" ON "OrderItem"."orderId" = "Order"."id"
JOIN "Product" ON "Product"."id" = "OrderItem"."productId"
WHERE "Node"."supplyChainId" = $1
ORDER BY "Order"."nodeId", "Order"."id", "OrderItem"."id";

-- R07 -- READ
-- Purpose: Load all products (referenced by inventory and order items).
-- Source: supplyChainRepository.getSupplyChain(id) -> nodes.inventory.product, nodes.orders.items.product
SELECT "Product"."id",
       "Product"."name",
       "Product"."sku",
       "Product"."createdAt"
FROM "Product"
ORDER BY "Product"."id";

-- R08 -- READ
-- Purpose: Load simulation input for a supply chain (network nodes/edges, inventory, orders).
-- This is a composite operation; the application assembles it from R02-R06.
-- Source: supplyChainRepository.loadSimulationInput(supplyChainId)
-- Called by: simulationService.startSimulation()
-- Parameter: $1 = supplyChainId (TEXT)
-- The application executes R02-R06 and transforms results in JavaScript.

-- =====================================================================
-- WRITE queries — Core supply chain creation
-- =====================================================================

-- W01 -- WRITE
-- Purpose: Create a new supply chain.
-- Source: supplyChainRepository.createSupplyChain(data)
-- Parameters: $1 = id (TEXT), $2 = name (TEXT), $3 = createdAt (TIMESTAMPTZ, optional, defaults to now)
INSERT INTO "SupplyChain" ("id", "name", "createdAt")
VALUES ($1, $2, COALESCE($3, CURRENT_TIMESTAMP));

-- W02 -- WRITE
-- Purpose: Create a new node in a supply chain.
-- Source: Application creates nodes when building a supply chain (not in reviewed repositories directly).
-- Parameters: $1 = id (TEXT), $2 = supplyChainId (TEXT), $3 = name (TEXT), $4 = type (TEXT)
INSERT INTO "Node" ("id", "supplyChainId", "name", "type")
VALUES ($1, $2, $3, $4);

-- W03 -- WRITE
-- Purpose: Create a new edge between nodes.
-- Source: Application creates edges when building a supply chain.
-- Parameters: $1 = id (TEXT), $2 = fromNodeId (TEXT), $3 = toNodeId (TEXT), $4 = distance (DOUBLE PRECISION, optional), $5 = travelTime (DOUBLE PRECISION, optional)
INSERT INTO "Edge" ("id", "fromNodeId", "toNodeId", "distance", "travelTime")
VALUES ($1, $2, $3, $4, $5);

-- W04 -- WRITE
-- Purpose: Create a new product.
-- Source: Application creates products when building a supply chain.
-- Parameters: $1 = id (TEXT), $2 = name (TEXT), $3 = sku (TEXT), $4 = createdAt (TIMESTAMPTZ, optional, defaults to now)
INSERT INTO "Product" ("id", "name", "sku", "createdAt")
VALUES ($1, $2, $3, COALESCE($4, CURRENT_TIMESTAMP));

-- W05 -- WRITE
-- Purpose: Create or update inventory for a node/product (upsert by unique nodeId+productId).
-- Source: Application sets initial inventory when building a supply chain.
-- Parameters: $1 = id (TEXT), $2 = nodeId (TEXT), $3 = productId (TEXT), $4 = quantity (INTEGER)
INSERT INTO "Inventory" ("id", "nodeId", "productId", "quantity")
VALUES ($1, $2, $3, $4)
ON CONFLICT ("nodeId", "productId") DO UPDATE SET "quantity" = EXCLUDED."quantity";

-- W06 -- WRITE
-- Purpose: Create a new order.
-- Source: Application creates orders when building a supply chain.
-- Parameters: $1 = id (TEXT), $2 = nodeId (TEXT), $3 = status (TEXT, default 'PENDING'), $4 = dueStep (INTEGER, default 0), $5 = createdAt (TIMESTAMPTZ, optional, defaults to now)
INSERT INTO "Order" ("id", "nodeId", "status", "dueStep", "createdAt")
VALUES ($1, $2, COALESCE($3, 'PENDING'), COALESCE($4, 0), COALESCE($5, CURRENT_TIMESTAMP));

-- W07 -- WRITE
-- Purpose: Create an order item.
-- Source: Application creates order items when building a supply chain.
-- Parameters: $1 = id (TEXT), $2 = orderId (TEXT), $3 = productId (TEXT), $4 = quantity (INTEGER)
INSERT INTO "OrderItem" ("id", "orderId", "productId", "quantity")
VALUES ($1, $2, $3, $4);

-- =====================================================================
-- READ queries — Simulation scenario, disruption, and run operations
-- =====================================================================

-- R09 -- READ
-- Purpose: Get a scenario by ID with its disruptions ordered by startStep.
-- Source: simulationRepository.getScenario(id)
-- Parameter: $1 = scenarioId (TEXT)
SELECT "Scenario"."id",
       "Scenario"."supplyChainId",
       "Scenario"."name",
       "Scenario"."createdAt"
FROM "Scenario"
WHERE "Scenario"."id" = $1;

-- R10 -- READ
-- Purpose: Get disruptions for a scenario ordered by startStep.
-- Source: simulationRepository.getScenario(id) -> disruptions include
-- Parameter: $1 = scenarioId (TEXT)
SELECT "Disruption"."id",
       "Disruption"."scenarioId",
       "Disruption"."type",
       "Disruption"."targetId",
       "Disruption"."startStep",
       "Disruption"."duration"
FROM "Disruption"
WHERE "Disruption"."scenarioId" = $1
ORDER BY "Disruption"."startStep" ASC;

-- R11 -- READ
-- Purpose: Get simulation runs for a scenario ordered by startedAt descending.
-- Source: simulationRepository.getScenario(id) -> runs include
-- Parameter: $1 = scenarioId (TEXT)
SELECT "SimulationRun"."id",
       "SimulationRun"."scenarioId",
       "SimulationRun"."status",
       "SimulationRun"."totalSteps",
       "SimulationRun"."startedAt",
       "SimulationRun"."completedAt"
FROM "SimulationRun"
WHERE "SimulationRun"."scenarioId" = $1
ORDER BY "SimulationRun"."startedAt" DESC;

-- R12 -- READ
-- Purpose: Load a simulation run with its scenario, disruptions, events, and metrics.
-- Source: simulationRepository.getRun(id)
-- Called by: simulationService.getSimulation(), simulationRepository.getImpactSummary()
-- Parameter: $1 = runId (TEXT)
SELECT "SimulationRun"."id",
       "SimulationRun"."scenarioId",
       "SimulationRun"."status",
       "SimulationRun"."totalSteps",
       "SimulationRun"."startedAt",
       "SimulationRun"."completedAt"
FROM "SimulationRun"
WHERE "SimulationRun"."id" = $1;

-- R13 -- READ
-- Purpose: Get scenario for a run (with disruptions ordered by startStep).
-- Source: simulationRepository.getRun(id) -> scenario.disruptions include
-- Parameter: $1 = runId (TEXT)
SELECT "Scenario"."id",
       "Scenario"."supplyChainId",
       "Scenario"."name",
       "Scenario"."createdAt"
FROM "Scenario"
JOIN "SimulationRun" ON "SimulationRun"."scenarioId" = "Scenario"."id"
WHERE "SimulationRun"."id" = $1;

-- R14 -- READ
-- Purpose: Get disruptions for a run's scenario ordered by startStep.
-- Source: simulationRepository.getRun(id) -> scenario.disruptions include
-- Parameter: $1 = runId (TEXT)
SELECT "Disruption"."id",
       "Disruption"."scenarioId",
       "Disruption"."type",
       "Disruption"."targetId",
       "Disruption"."startStep",
       "Disruption"."duration"
FROM "Disruption"
JOIN "SimulationRun" ON "SimulationRun"."scenarioId" = "Disruption"."scenarioId"
WHERE "SimulationRun"."id" = $1
ORDER BY "Disruption"."startStep" ASC;

-- R15 -- READ
-- Purpose: Get simulation events for a run ordered by step then sequence.
-- Source: simulationRepository.getRun(id) -> events include
-- Parameter: $1 = runId (TEXT)
SELECT "SimulationEvent"."id",
       "SimulationEvent"."runId",
       "SimulationEvent"."sequence",
       "SimulationEvent"."step",
       "SimulationEvent"."type",
       "SimulationEvent"."targetType",
       "SimulationEvent"."targetId",
       "SimulationEvent"."message"
FROM "SimulationEvent"
WHERE "SimulationEvent"."runId" = $1
ORDER BY "SimulationEvent"."step" ASC, "SimulationEvent"."sequence" ASC;

-- R16 -- READ
-- Purpose: Get simulation metrics for a run.
-- Source: simulationRepository.getRun(id) -> metrics include
-- Parameter: $1 = runId (TEXT)
SELECT "SimulationMetric"."id",
       "SimulationMetric"."runId",
       "SimulationMetric"."totalOrders",
       "SimulationMetric"."totalDemand",
       "SimulationMetric"."fulfilledQuantity",
       "SimulationMetric"."remainingQuantity",
       "SimulationMetric"."stockoutEvents",
       "SimulationMetric"."stockouts",
       "SimulationMetric"."delayedOrders",
       "SimulationMetric"."additionalCost",
       "SimulationMetric"."recoveryTime",
       "SimulationMetric"."affectedNodes",
       "SimulationMetric"."affectedEdges",
       "SimulationMetric"."finalState"
FROM "SimulationMetric"
WHERE "SimulationMetric"."runId" = $1;

-- R17 -- READ
-- Purpose: List simulation runs by supplyChainId (via Scenario) with optional status filter,
-- using cursor-based pagination (keyset on startedAt, id).
-- Source: Application API endpoint (not directly in reviewed files; inferred from
-- simulationService.startSimulation creating runs and the need to list them by supply chain).
-- The application filters through Scenario.supplyChainId, not by scenarioId directly.
-- Parameters: $1 = supplyChainId (TEXT), $2 = status (TEXT, optional), $3 = cursor_startedAt (TIMESTAMPTZ, optional), $4 = cursor_id (TEXT, optional), $5 = limit (INTEGER)
-- Cursor condition: (startedAt, id) < (cursor_startedAt, cursor_id) for "next page" with DESC ordering.
SELECT "SimulationRun"."id",
       "SimulationRun"."scenarioId",
       "SimulationRun"."status",
       "SimulationRun"."totalSteps",
       "SimulationRun"."startedAt",
       "SimulationRun"."completedAt",
       "Scenario"."supplyChainId",
       "Scenario"."name" AS scenario_name
FROM "SimulationRun"
JOIN "Scenario" ON "Scenario"."id" = "SimulationRun"."scenarioId"
WHERE "Scenario"."supplyChainId" = $1
  AND ($2::TEXT IS NULL OR "SimulationRun"."status" = $2)
  AND (
        $3::TIMESTAMPTZ IS NULL
     OR "SimulationRun"."startedAt" < $3
     OR ("SimulationRun"."startedAt" = $3 AND "SimulationRun"."id" < $4::TEXT)
      )
ORDER BY "SimulationRun"."startedAt" DESC, "SimulationRun"."id" DESC
LIMIT $5;

-- R18 -- READ
-- Purpose: Get the first page of runs for a supply chain (no cursor).
-- Special case of R17 with no cursor parameters.
-- Parameters: $1 = supplyChainId (TEXT), $2 = status (TEXT, optional), $3 = limit (INTEGER)
SELECT "SimulationRun"."id",
       "SimulationRun"."scenarioId",
       "SimulationRun"."status",
       "SimulationRun"."totalSteps",
       "SimulationRun"."startedAt",
       "SimulationRun"."completedAt",
       "Scenario"."supplyChainId",
       "Scenario"."name" AS scenario_name
FROM "SimulationRun"
JOIN "Scenario" ON "Scenario"."id" = "SimulationRun"."scenarioId"
WHERE "Scenario"."supplyChainId" = $1
  AND ($2::TEXT IS NULL OR "SimulationRun"."status" = $2)
ORDER BY "SimulationRun"."startedAt" DESC, "SimulationRun"."id" DESC
LIMIT $3;

-- =====================================================================
-- WRITE queries — Simulation scenario, disruption, run, and result operations
-- =====================================================================

-- W08 -- WRITE
-- Purpose: Create a new scenario with disruptions.
-- Source: simulationRepository.createScenario({ supplyChainId, name, disruptions })
-- Called by: simulationService.startSimulation()
-- Parameters: $1 = id (TEXT), $2 = supplyChainId (TEXT), $3 = name (TEXT), $4 = createdAt (TIMESTAMPTZ, optional, defaults to now)
-- Disruptions are inserted separately via W09.
INSERT INTO "Scenario" ("id", "supplyChainId", "name", "createdAt")
VALUES ($1, $2, $3, COALESCE($4, CURRENT_TIMESTAMP));

-- W09 -- WRITE
-- Purpose: Create a disruption for a scenario.
-- Source: simulationRepository.createScenario() -> disruptions create mapping
-- Parameters: $1 = id (TEXT), $2 = scenarioId (TEXT), $3 = type (TEXT), $4 = targetId (TEXT), $5 = startStep (INTEGER), $6 = duration (INTEGER)
INSERT INTO "Disruption" ("id", "scenarioId", "type", "targetId", "startStep", "duration")
VALUES ($1, $2, $3, $4, $5, $6);

-- W10 -- WRITE
-- Purpose: Create a new simulation run.
-- Source: simulationRepository.createRun({ id, scenarioId, totalSteps })
-- Called by: simulationService.startSimulation()
-- Parameters: $1 = id (TEXT), $2 = scenarioId (TEXT), $3 = totalSteps (INTEGER), $4 = status (TEXT, default 'RUNNING'), $5 = startedAt (TIMESTAMPTZ, optional, defaults to now)
INSERT INTO "SimulationRun" ("id", "scenarioId", "totalSteps", "status", "startedAt")
VALUES ($1, $2, $3, COALESCE($4, 'RUNNING'), COALESCE($5, CURRENT_TIMESTAMP));

-- W11 -- WRITE
-- Purpose: Delete all previous events for a run before saving replacement events.
-- Source: simulationRepository.saveRunResult() -> tx.simulationEvent.deleteMany({ where: { runId } })
-- Called by: simulationService.startSimulation() after simulation completes
-- Parameter: $1 = runId (TEXT)
DELETE FROM "SimulationEvent"
WHERE "runId" = $1;

-- W12 -- WRITE
-- Purpose: Insert simulation events for a run (bulk insert with sequence).
-- Source: simulationRepository.saveRunResult() -> tx.simulationEvent.createMany()
-- Called by: simulationService.startSimulation() after simulation completes
-- Parameters (per event): $1 = id (TEXT), $2 = runId (TEXT), $3 = sequence (INTEGER), $4 = step (INTEGER), $5 = type (TEXT), $6 = targetType (TEXT), $7 = targetId (TEXT), $8 = message (TEXT)
-- The application generates IDs and sequences in JavaScript before inserting.
INSERT INTO "SimulationEvent" ("id", "runId", "sequence", "step", "type", "targetType", "targetId", "message")
VALUES ($1, $2, $3, $4, $5, $6, $7, $8);

-- W13 -- WRITE
-- Purpose: Upsert simulation metrics for a run (create or update).
-- Source: simulationRepository.saveRunResult() -> tx.simulationMetric.upsert({ where: { runId }, update: ..., create: ... })
-- Called by: simulationService.startSimulation() after simulation completes
-- Parameters: $1 = id (TEXT), $2 = runId (TEXT), $3 = totalOrders (INTEGER), $4 = totalDemand (INTEGER),
-- $5 = fulfilledQuantity (INTEGER), $6 = remainingQuantity (INTEGER), $7 = stockoutEvents (INTEGER),
-- $8 = stockouts (INTEGER), $9 = delayedOrders (INTEGER), $10 = additionalCost (DOUBLE PRECISION),
-- $11 = recoveryTime (INTEGER), $12 = affectedNodes (JSONB), $13 = affectedEdges (JSONB), $14 = finalState (JSONB, optional)
INSERT INTO "SimulationMetric" ("id", "runId", "totalOrders", "totalDemand", "fulfilledQuantity", "remainingQuantity",
                                "stockoutEvents", "stockouts", "delayedOrders", "additionalCost", "recoveryTime",
                                "affectedNodes", "affectedEdges", "finalState")
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
ON CONFLICT ("runId") DO UPDATE SET
    "totalOrders"       = EXCLUDED."totalOrders",
    "totalDemand"       = EXCLUDED."totalDemand",
    "fulfilledQuantity" = EXCLUDED."fulfilledQuantity",
    "remainingQuantity" = EXCLUDED."remainingQuantity",
    "stockoutEvents"    = EXCLUDED."stockoutEvents",
    "stockouts"         = EXCLUDED."stockouts",
    "delayedOrders"     = EXCLUDED."delayedOrders",
    "additionalCost"    = EXCLUDED."additionalCost",
    "recoveryTime"      = EXCLUDED."recoveryTime",
    "affectedNodes"     = EXCLUDED."affectedNodes",
    "affectedEdges"     = EXCLUDED."affectedEdges",
    "finalState"        = EXCLUDED."finalState";

-- W14 -- WRITE
-- Purpose: Mark a simulation run as completed with completedAt timestamp.
-- Source: simulationRepository.saveRunResult() -> tx.simulationRun.update({ where: { id: runId }, data: { status: ..., completedAt: new Date() } })
-- Called by: simulationService.startSimulation() on successful completion
-- Parameters: $1 = runId (TEXT), $2 = status (TEXT, 'COMPLETED' or 'FAILED'), $3 = completedAt (TIMESTAMPTZ, optional, defaults to now)
UPDATE "SimulationRun"
SET "status" = $2,
    "completedAt" = COALESCE($3, CURRENT_TIMESTAMP)
WHERE "id" = $1;

-- W15 -- WRITE
-- Purpose: Mark a simulation run as failed (alternative path when simulation throws).
-- Source: simulationRepository.markRunFailed(runId)
-- Called by: simulationService.startSimulation() catch block
-- Parameter: $1 = runId (TEXT), $2 = completedAt (TIMESTAMPTZ, optional, defaults to now)
UPDATE "SimulationRun"
SET "status" = 'FAILED',
    "completedAt" = COALESCE($2, CURRENT_TIMESTAMP)
WHERE "id" = $1;

COMMIT;

-- =====================================================================
-- Audit footer
-- =====================================================================
-- Application source files reviewed for this catalogue:
-- 1. database/prisma/schema.prisma
-- 2. database/repositories/supplyChainRepository.js
-- 3. database/repositories/simulationRepository.js
-- 4. backend/services/simulationService.js
-- 5. dbms/03_schema.sql (AP submission repository)
-- No fabricated execution results or timings included.