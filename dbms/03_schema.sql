-- SC-Disruption AP database schema (PostgreSQL)
-- CP2: final 3NF/BCNF relations documented in dbms/01_normalization.md.

BEGIN;

CREATE TABLE "SupplyChain" (
    "id"        TEXT PRIMARY KEY,
    "name"      TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "Node" (
    "id"            TEXT PRIMARY KEY,
    "supplyChainId" TEXT NOT NULL,
    "name"          TEXT NOT NULL,
    "type"          TEXT NOT NULL,
    CONSTRAINT "Node_supplyChainId_fkey"
        FOREIGN KEY ("supplyChainId") REFERENCES "SupplyChain" ("id")
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE "Edge" (
    "id"         TEXT PRIMARY KEY,
    "fromNodeId" TEXT NOT NULL,
    "toNodeId"   TEXT NOT NULL,
    "distance"   DOUBLE PRECISION,
    "travelTime" DOUBLE PRECISION,
    CONSTRAINT "Edge_fromNodeId_fkey"
        FOREIGN KEY ("fromNodeId") REFERENCES "Node" ("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Edge_toNodeId_fkey"
        FOREIGN KEY ("toNodeId") REFERENCES "Node" ("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Edge_distinct_nodes_check" CHECK ("fromNodeId" <> "toNodeId"),
    CONSTRAINT "Edge_distance_check" CHECK ("distance" IS NULL OR "distance" >= 0),
    CONSTRAINT "Edge_travelTime_check" CHECK ("travelTime" IS NULL OR "travelTime" >= 0)
);

CREATE TABLE "Product" (
    "id"        TEXT PRIMARY KEY,
    "name"      TEXT NOT NULL,
    "sku"       TEXT NOT NULL UNIQUE,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "Inventory" (
    "id"        TEXT PRIMARY KEY,
    "nodeId"    TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "quantity"  INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "Inventory_nodeId_fkey"
        FOREIGN KEY ("nodeId") REFERENCES "Node" ("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Inventory_productId_fkey"
        FOREIGN KEY ("productId") REFERENCES "Product" ("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Inventory_nodeId_productId_key" UNIQUE ("nodeId", "productId"),
    CONSTRAINT "Inventory_quantity_check" CHECK ("quantity" >= 0)
);

CREATE TABLE "Order" (
    "id"        TEXT PRIMARY KEY,
    "nodeId"    TEXT NOT NULL,
    "status"    TEXT NOT NULL DEFAULT 'PENDING',
    "dueStep"   INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Order_nodeId_fkey"
        FOREIGN KEY ("nodeId") REFERENCES "Node" ("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Order_dueStep_check" CHECK ("dueStep" >= 0)
);

CREATE TABLE "OrderItem" (
    "id"        TEXT PRIMARY KEY,
    "orderId"   TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "quantity"  INTEGER NOT NULL,
    CONSTRAINT "OrderItem_orderId_fkey"
        FOREIGN KEY ("orderId") REFERENCES "Order" ("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "OrderItem_productId_fkey"
        FOREIGN KEY ("productId") REFERENCES "Product" ("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "OrderItem_orderId_productId_key" UNIQUE ("orderId", "productId"),
    CONSTRAINT "OrderItem_quantity_check" CHECK ("quantity" > 0)
);

CREATE TABLE "Scenario" (
    "id"            TEXT PRIMARY KEY,
    "supplyChainId" TEXT NOT NULL,
    "name"          TEXT NOT NULL,
    "createdAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Scenario_supplyChainId_fkey"
        FOREIGN KEY ("supplyChainId") REFERENCES "SupplyChain" ("id")
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE "Disruption" (
    "id"         TEXT PRIMARY KEY,
    "scenarioId" TEXT NOT NULL,
    "type"       TEXT NOT NULL,
    "targetId"   TEXT NOT NULL,
    "startStep"  INTEGER NOT NULL,
    "duration"   INTEGER NOT NULL,
    CONSTRAINT "Disruption_scenarioId_fkey"
        FOREIGN KEY ("scenarioId") REFERENCES "Scenario" ("id")
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Disruption_startStep_check" CHECK ("startStep" >= 0),
    CONSTRAINT "Disruption_duration_check" CHECK ("duration" > 0)
);

CREATE TABLE "SimulationRun" (
    "id"          TEXT PRIMARY KEY,
    "scenarioId"  TEXT NOT NULL,
    "status"      TEXT NOT NULL DEFAULT 'PENDING',
    "totalSteps"  INTEGER NOT NULL,
    "startedAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completedAt" TIMESTAMP(3),
    CONSTRAINT "SimulationRun_scenarioId_fkey"
        FOREIGN KEY ("scenarioId") REFERENCES "Scenario" ("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "SimulationRun_totalSteps_check" CHECK ("totalSteps" > 0),
    CONSTRAINT "SimulationRun_completedAt_check"
        CHECK ("completedAt" IS NULL OR "completedAt" >= "startedAt")
);

CREATE TABLE "SimulationEvent" (
    "id"         TEXT PRIMARY KEY,
    "runId"      TEXT NOT NULL,
    "sequence"   INTEGER NOT NULL,
    "step"       INTEGER NOT NULL,
    "type"       TEXT NOT NULL,
    "targetType" TEXT NOT NULL,
    "targetId"   TEXT NOT NULL,
    "message"    TEXT NOT NULL,
    CONSTRAINT "SimulationEvent_runId_fkey"
        FOREIGN KEY ("runId") REFERENCES "SimulationRun" ("id")
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "SimulationEvent_runId_sequence_key" UNIQUE ("runId", "sequence"),
    CONSTRAINT "SimulationEvent_sequence_check" CHECK ("sequence" >= 0),
    CONSTRAINT "SimulationEvent_step_check" CHECK ("step" >= 0)
);

CREATE TABLE "SimulationMetric" (
    "id"                TEXT PRIMARY KEY,
    "runId"             TEXT NOT NULL UNIQUE,
    "totalOrders"       INTEGER NOT NULL,
    "totalDemand"       INTEGER NOT NULL,
    "fulfilledQuantity" INTEGER NOT NULL,
    "remainingQuantity" INTEGER NOT NULL,
    "stockoutEvents"    INTEGER NOT NULL,
    "stockouts"         INTEGER NOT NULL,
    "delayedOrders"     INTEGER NOT NULL,
    "additionalCost"    DOUBLE PRECISION NOT NULL,
    "recoveryTime"      INTEGER NOT NULL,
    "affectedNodes"     JSONB NOT NULL,
    "affectedEdges"     JSONB NOT NULL,
    "finalState"        JSONB,
    CONSTRAINT "SimulationMetric_runId_fkey"
        FOREIGN KEY ("runId") REFERENCES "SimulationRun" ("id")
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "SimulationMetric_nonnegative_check" CHECK (
        "totalOrders" >= 0
        AND "totalDemand" >= 0
        AND "fulfilledQuantity" >= 0
        AND "remainingQuantity" >= 0
        AND "stockoutEvents" >= 0
        AND "stockouts" >= 0
        AND "delayedOrders" >= 0
        AND "additionalCost" >= 0
        AND "recoveryTime" >= 0
    )
);

CREATE INDEX "Scenario_supplyChainId_createdAt_idx"
    ON "Scenario" ("supplyChainId", "createdAt");
CREATE INDEX "Disruption_scenarioId_startStep_idx"
    ON "Disruption" ("scenarioId", "startStep");
CREATE INDEX "SimulationRun_scenarioId_startedAt_idx"
    ON "SimulationRun" ("scenarioId", "startedAt");
CREATE INDEX "SimulationEvent_runId_step_sequence_idx"
    ON "SimulationEvent" ("runId", "step", "sequence");

COMMIT;
