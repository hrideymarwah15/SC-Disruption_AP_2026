-- @Q001
-- Type: READ
-- Category: Supply-chain
-- Purpose: Retrieve all supply chains, newest first.
-- Parameters: None

SELECT
    "id",
    "name",
    "createdAt"
FROM "SupplyChain"
ORDER BY "createdAt" DESC;

-- @Q002
-- Type: READ
-- Category: Graph
-- Purpose: Retrieve all nodes belonging to a supply chain.
-- Parameters: $1 = supplyChainId

SELECT
    "id",
    "name",
    "type"
FROM "Node"
WHERE "supplyChainId" = $1
ORDER BY "name" ASC;


-- @Q003
-- Type: READ
-- Category: Graph
-- Purpose: Retrieve outgoing edges from a node with destination details.
-- Parameters: $1 = fromNodeId

SELECT
    e."id",
    e."fromNodeId",
    e."toNodeId",
    n."name" AS "destinationNode",
    e."distance",
    e."travelTime"
FROM "Edge" e
JOIN "Node" n
    ON n."id" = e."toNodeId"
WHERE e."fromNodeId" = $1
ORDER BY n."name" ASC;


-- @Q004
-- Type: READ
-- Category: Product
-- Purpose: Retrieve all products with their SKU details.
-- Parameters: None

SELECT
    "id",
    "name",
    "sku",
    "createdAt"
FROM "Product"
ORDER BY "name" ASC;


-- @Q005
-- Type: READ
-- Category: Inventory
-- Purpose: Retrieve product-wise inventory available at a node.
-- Parameters: $1 = nodeId

SELECT
    i."id",
    i."nodeId",
    i."productId",
    p."name" AS "productName",
    p."sku",
    i."quantity"
FROM "Inventory" i
JOIN "Product" p
    ON p."id" = i."productId"
WHERE i."nodeId" = $1
ORDER BY p."name" ASC;




-- @Q006
-- Type: READ
-- Category: Inventory
-- Purpose: Retrieve stock of a product across all nodes in a supply chain.
-- Parameters: $1 = supplyChainId, $2 = productId

SELECT
    n."id" AS "nodeId",
    n."name" AS "nodeName",
    n."type" AS "nodeType",
    i."quantity"
FROM "Inventory" i
JOIN "Node" n
    ON n."id" = i."nodeId"
WHERE n."supplyChainId" = $1
  AND i."productId" = $2
ORDER BY n."name" ASC;



-- @Q007
-- Type: READ
-- Category: Order
-- Purpose: Retrieve all orders placed at a specific node.
-- Parameters: $1 = nodeId

SELECT
    "id",
    "nodeId",
    "status",
    "dueStep",
    "createdAt"
FROM "Order"
WHERE "nodeId" = $1
ORDER BY "createdAt" DESC;


-- @Q008
-- Type: READ
-- Category: Order
-- Purpose: Retrieve an order with its product-wise item details.
-- Parameters: $1 = orderId

SELECT
    o."id" AS "orderId",
    o."status",
    o."dueStep",
    oi."productId",
    p."name" AS "productName",
    p."sku",
    oi."quantity"
FROM "Order" o
JOIN "OrderItem" oi
    ON oi."orderId" = o."id"
JOIN "Product" p
    ON p."id" = oi."productId"
WHERE o."id" = $1
ORDER BY p."name" ASC;


-- @Q009
-- Type: READ
-- Category: Order
-- Purpose: Retrieve pending orders ordered by their due step.
-- Parameters: $1 = nodeId

SELECT
    "id",
    "nodeId",
    "status",
    "dueStep",
    "createdAt"
FROM "Order"
WHERE "nodeId" = $1
  AND "status" = 'PENDING'
ORDER BY "dueStep" ASC, "createdAt" ASC;

-- @Q010
-- Type: READ
-- Category: Simulation
-- Purpose: Retrieve all scenarios belonging to a supply chain.
-- Parameters: $1 = supplyChainId

SELECT
    "id",
    "supplyChainId",
    "name",
    "createdAt"
FROM "Scenario"
WHERE "supplyChainId" = $1
ORDER BY "createdAt" DESC;


-- @Q011
-- Type: READ
-- Category: Simulation
-- Purpose: Retrieve all disruptions configured for a scenario.
-- Parameters: $1 = scenarioId

SELECT
    "id",
    "scenarioId",
    "type",
    "targetId",
    "startStep",
    "duration"
FROM "Disruption"
WHERE "scenarioId" = $1
ORDER BY "startStep" ASC;



-- @Q012
-- Type: READ
-- Category: Simulation
-- Purpose: Retrieve all simulation runs for a scenario, newest first.
-- Parameters: $1 = scenarioId

SELECT
    "id",
    "scenarioId",
    "status",
    "totalSteps",
    "startedAt",
    "completedAt"
FROM "SimulationRun"
WHERE "scenarioId" = $1
ORDER BY "startedAt" DESC;


-- @Q013
-- Type: READ
-- Category: Simulation
-- Purpose: Retrieve events for a simulation run in sequence order.
-- Parameters: $1 = runId

SELECT
    "id",
    "runId",
    "sequence",
    "step",
    "type",
    "targetType",
    "targetId",
    "message"
FROM "SimulationEvent"
WHERE "runId" = $1
ORDER BY "sequence" ASC;


-- @Q014
-- Type: READ
-- Category: Simulation
-- Purpose: Retrieve events of a specific type within a simulation step range.
-- Parameters: $1 = runId, $2 = eventType, $3 = startStep, $4 = endStep

SELECT
    "id",
    "runId",
    "sequence",
    "step",
    "type",
    "targetType",
    "targetId",
    "message"
FROM "SimulationEvent"
WHERE "runId" = $1
  AND "type" = $2
  AND "step" BETWEEN $3 AND $4
ORDER BY "step" ASC, "sequence" ASC;


-- @Q015
-- Type: READ
-- Category: Simulation
-- Purpose: Retrieve simulation metrics for a specific run.
-- Parameters: $1 = runId

SELECT
    "runId",
    "totalOrders",
    "totalDemand",
    "fulfilledQuantity",
    "remainingQuantity",
    "stockoutEvents",
    "stockouts",
    "delayedOrders",
    "recoveryTime",
    "additionalCost",
    "affectedNodes",
    "affectedEdges",
    "finalState"
FROM "SimulationMetric"
WHERE "runId" = $1;


-- @Q016
-- Type: READ
-- Category: Simulation
-- Purpose: Retrieve simulation events for a specific target.
-- Parameters: $1 = runId, $2 = targetType, $3 = targetId

SELECT
    "id",
    "sequence",
    "step",
    "type",
    "targetType",
    "targetId",
    "message"
FROM "SimulationEvent"
WHERE "runId" = $1
  AND "targetType" = $2
  AND "targetId" = $3
ORDER BY "step" ASC, "sequence" ASC;


-- @Q017
-- Type: READ
-- Category: Simulation
-- Purpose: Retrieve events with pagination for a simulation run.
-- Parameters: $1 = runId, $2 = pageSize, $3 = offset

SELECT
    "id",
    "sequence",
    "step",
    "type",
    "targetType",
    "targetId",
    "message"
FROM "SimulationEvent"
WHERE "runId" = $1
ORDER BY "sequence" ASC
LIMIT $2
OFFSET $3;


-- @Q018
-- Type: READ
-- Category: Simulation
-- Purpose: Count simulation events grouped by event type.
-- Parameters: $1 = runId

SELECT
    "type",
    COUNT(*) AS "eventCount"
FROM "SimulationEvent"
WHERE "runId" = $1
GROUP BY "type"
ORDER BY "eventCount" DESC, "type" ASC;


-- @Q019
-- Type: READ
-- Category: Simulation
-- Purpose: Retrieve event counts grouped by simulation step.
-- Parameters: $1 = runId

SELECT
    "step",
    COUNT(*) AS "eventCount"
FROM "SimulationEvent"
WHERE "runId" = $1
GROUP BY "step"
ORDER BY "step" ASC;


-- @Q020
-- Type: READ
-- Category: Simulation
-- Purpose: Retrieve simulation runs filtered by status with pagination.
-- Parameters: $1 = scenarioId, $2 = status, $3 = pageSize, $4 = offset

SELECT
    "id",
    "scenarioId",
    "status",
    "totalSteps",
    "startedAt",
    "completedAt"
FROM "SimulationRun"
WHERE "scenarioId" = $1
  AND "status" = $2
ORDER BY "startedAt" DESC
LIMIT $3
OFFSET $4;



-- @W001
-- Type: WRITE
-- Category: Graph
-- Purpose: Create a directed edge between two nodes.
-- Parameters: $1 = id, $2 = fromNodeId, $3 = toNodeId, $4 = distance, $5 = travelTime
INSERT INTO "Edge" ("id", "fromNodeId", "toNodeId", "distance", "travelTime")
VALUES ($1, $2, $3, $4, $5)
RETURNING "id", "fromNodeId", "toNodeId", "distance", "travelTime";


-- @W002
-- Type: WRITE
-- Category: Graph
-- Purpose: Update the distance and travel time of an edge.
-- Parameters: $1 = edgeId, $2 = distance, $3 = travelTime
UPDATE "Edge"
SET "distance" = $2,
    "travelTime" = $3
WHERE "id" = $1
RETURNING "id", "fromNodeId", "toNodeId", "distance", "travelTime";


-- @W003
-- Type: WRITE
-- Category: Graph
-- Purpose: Delete an edge between two nodes.
-- Parameters: $1 = edgeId
DELETE FROM "Edge"
WHERE "id" = $1
RETURNING "id", "fromNodeId", "toNodeId";


-- @W004
-- Type: WRITE
-- Category: Inventory
-- Purpose: Add inventory for a node and product or update existing inventory.
-- Parameters: $1 = id, $2 = nodeId, $3 = productId, $4 = quantity
INSERT INTO "Inventory" ("id", "nodeId", "productId", "quantity")
VALUES ($1, $2, $3, $4)
ON CONFLICT ("nodeId", "productId")
DO UPDATE SET "quantity" = EXCLUDED."quantity"
RETURNING "id", "nodeId", "productId", "quantity";


-- @W005
-- Type: WRITE
-- Category: Inventory
-- Purpose: Adjust inventory quantity while preventing negative stock.
-- Parameters: $1 = inventoryId, $2 = quantityChange
UPDATE "Inventory"
SET "quantity" = "quantity" + $2
WHERE "id" = $1
  AND "quantity" + $2 >= 0
RETURNING "id", "nodeId", "productId", "quantity";


-- @W006
-- Type: WRITE
-- Category: Order
-- Purpose: Create a new order for a node.
-- Parameters: $1 = id, $2 = nodeId, $3 = dueStep
INSERT INTO "Order" ("id", "nodeId", "dueStep")
VALUES ($1, $2, $3)
RETURNING "id", "nodeId", "status", "dueStep", "createdAt";


-- @W007
-- Type: WRITE
-- Category: Order
-- Purpose: Add a product item to an existing order.
-- Parameters: $1 = id, $2 = orderId, $3 = productId, $4 = quantity
INSERT INTO "OrderItem" ("id", "orderId", "productId", "quantity")
VALUES ($1, $2, $3, $4)
RETURNING "id", "orderId", "productId", "quantity";


-- @W008
-- Type: WRITE
-- Category: Order
-- Purpose: Update the status of an existing order.
-- Parameters: $1 = orderId, $2 = newStatus
UPDATE "Order"
SET "status" = $2
WHERE "id" = $1
RETURNING "id", "nodeId", "status", "dueStep";



-- @W009
-- Type: WRITE
-- Category: Simulation
-- Purpose: Create a scenario for a supply chain.
-- Parameters: $1 = id, $2 = supplyChainId, $3 = name
INSERT INTO "Scenario" ("id", "supplyChainId", "name")
VALUES ($1, $2, $3)
RETURNING "id", "supplyChainId", "name", "createdAt";


-- @W010
-- Type: WRITE
-- Category: Simulation
-- Purpose: Add a disruption to a scenario.
-- Parameters: $1 = id, $2 = scenarioId, $3 = type, $4 = targetId, $5 = startStep, $6 = duration
INSERT INTO "Disruption"
("id", "scenarioId", "type", "targetId", "startStep", "duration")
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING *;


-- @W011
-- Type: WRITE
-- Category: Simulation
-- Purpose: Create a simulation run for a scenario.
-- Parameters: $1 = id, $2 = scenarioId, $3 = totalSteps
INSERT INTO "SimulationRun" ("id", "scenarioId", "totalSteps")
VALUES ($1, $2, $3)
RETURNING *;


-- @W012
-- Type: WRITE
-- Category: Simulation
-- Purpose: Update the status and completion time of a simulation run.
-- Parameters: $1 = runId, $2 = status, $3 = completedAt
UPDATE "SimulationRun"
SET "status" = $2,
    "completedAt" = $3
WHERE "id" = $1
RETURNING *;


-- @W013
-- Type: WRITE
-- Category: Simulation
-- Purpose: Record an event for a simulation run.
-- Parameters: $1 = id, $2 = runId, $3 = sequence, $4 = step, $5 = type, $6 = targetType, $7 = targetId, $8 = message
INSERT INTO "SimulationEvent"
("id", "runId", "sequence", "step", "type", "targetType", "targetId", "message")
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
RETURNING *;


-- @W014
-- Type: WRITE
-- Category: Simulation
-- Purpose: Insert or update metrics for a simulation run.
-- Parameters: $1 = id, $2 = runId, $3 = totalOrders, $4 = totalDemand, $5 = fulfilledQuantity, $6 = remainingQuantity, $7 = stockoutEvents, $8 = stockouts, $9 = delayedOrders, $10 = recoveryTime, $11 = additionalCost, $12 = affectedNodes, $13 = affectedEdges, $14 = finalState
INSERT INTO "SimulationMetric"
("id", "runId", "totalOrders", "totalDemand", "fulfilledQuantity",
 "remainingQuantity", "stockoutEvents", "stockouts", "delayedOrders",
 "recoveryTime", "additionalCost", "affectedNodes", "affectedEdges", "finalState")
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
ON CONFLICT ("runId")
DO UPDATE SET
    "totalOrders" = EXCLUDED."totalOrders",
    "totalDemand" = EXCLUDED."totalDemand",
    "fulfilledQuantity" = EXCLUDED."fulfilledQuantity",
    "remainingQuantity" = EXCLUDED."remainingQuantity",
    "stockoutEvents" = EXCLUDED."stockoutEvents",
    "stockouts" = EXCLUDED."stockouts",
    "delayedOrders" = EXCLUDED."delayedOrders",
    "recoveryTime" = EXCLUDED."recoveryTime",
    "additionalCost" = EXCLUDED."additionalCost",
    "affectedNodes" = EXCLUDED."affectedNodes",
    "affectedEdges" = EXCLUDED."affectedEdges",
    "finalState" = EXCLUDED."finalState"
RETURNING *;


-- @W015
-- Type: WRITE
-- Category: Simulation
-- Purpose: Delete a disruption from a scenario.
-- Parameters: $1 = disruptionId
DELETE FROM "Disruption"
WHERE "id" = $1
RETURNING *;
