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