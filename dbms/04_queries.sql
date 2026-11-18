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