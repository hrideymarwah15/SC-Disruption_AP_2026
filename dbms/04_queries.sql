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