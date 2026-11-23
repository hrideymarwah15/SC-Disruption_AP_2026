-- AP CP4 Fixture Data for 33-query benchmark
-- Run this once to populate a test database with representative data.
-- Adjust counts as needed; current scale: 3 supply chains, ~50 nodes, ~200 edges,
-- 10 products, ~200 inventory rows, ~50 orders, ~150 order items,
-- 5 scenarios, 15 disruptions, 20 runs, ~500 events, 20 metrics.
-- All IDs use TEXT (CUID-style) to match the schema.

BEGIN;
SET search_path TO public;

-- =====================================================================
-- Supply Chains (3)
-- =====================================================================
INSERT INTO "SupplyChain" ("id", "name", "createdAt") VALUES
  ('sc_01', 'Global Electronics Supply Chain', '2025-01-15 10:00:00'),
  ('sc_02', 'Automotive Parts Network', '2025-02-20 14:30:00'),
  ('sc_03', 'Pharma Distribution Chain', '2025-03-10 09:15:00');

-- =====================================================================
-- Nodes (50: suppliers, factories, warehouses, distributors, retailers)
-- =====================================================================
INSERT INTO "Node" ("id", "supplyChainId", "name", "type") VALUES
  -- Supply Chain 1: Electronics
  ('n_01', 'sc_01', 'Silicon Valley Fab', 'SUPPLIER'),
  ('n_02', 'sc_01', 'Taiwan Semiconductor', 'SUPPLIER'),
  ('n_03', 'sc_01', 'Korean Display Co', 'SUPPLIER'),
  ('n_04', 'sc_01', 'Shenzhen Assembly Plant', 'FACTORY'),
  ('n_05', 'sc_01', 'Vietnam Assembly Plant', 'FACTORY'),
  ('n_06', 'sc_01', 'Singapore Regional Hub', 'WAREHOUSE'),
  ('n_07', 'sc_01', 'LA Distribution Center', 'WAREHOUSE'),
  ('n_08', 'sc_01', 'NYC Distribution Center', 'WAREHOUSE'),
  ('n_09', 'sc_01', 'BestBuy Retail', 'RETAILER'),
  ('n_10', 'sc_01', 'Amazon Retail', 'RETAILER'),
  ('n_11', 'sc_01', 'MicroCenter Retail', 'RETAILER'),
  ('n_12', 'sc_01', 'Newegg Retail', 'RETAILER'),
  ('n_13', 'sc_01', 'Texas Instruments', 'SUPPLIER'),
  ('n_14', 'sc_01', 'Qualcomm Chip Design', 'SUPPLIER'),
  ('n_15', 'sc_01', 'Mexico Assembly', 'FACTORY'),
  -- Supply Chain 2: Automotive
  ('n_16', 'sc_02', 'Bosch Components', 'SUPPLIER'),
  ('n_17', 'sc_02', 'Continental Systems', 'SUPPLIER'),
  ('n_18', 'sc_02', 'Denso Electronics', 'SUPPLIER'),
  ('n_19', 'sc_02', 'Detroit Engine Plant', 'FACTORY'),
  ('n_20', 'sc_02', 'Mexico Transmission Plant', 'FACTORY'),
  ('n_21', 'sc_02', 'Chicago Parts Hub', 'WAREHOUSE'),
  ('n_22', 'sc_02', 'Atlanta Distribution', 'WAREHOUSE'),
  ('n_23', 'sc_02', 'AutoZone Retail', 'RETAILER'),
  ('n_24', 'sc_02', 'OReilly Retail', 'RETAILER'),
  ('n_25', 'sc_02', 'NAPA Retail', 'RETAILER'),
  ('n_26', 'sc_02', 'Magna Steyr', 'SUPPLIER'),
  ('n_27', 'sc_02', 'ZF Friedrichshafen', 'SUPPLIER'),
  ('n_28', 'sc_02', 'Canadian Assembly', 'FACTORY'),
  -- Supply Chain 3: Pharma
  ('n_29', 'sc_03', 'Pfizer API Supply', 'SUPPLIER'),
  ('n_30', 'sc_03', 'Novartis API Supply', 'SUPPLIER'),
  ('n_31', 'sc_03', 'Merck API Supply', 'SUPPLIER'),
  ('n_32', 'sc_03', 'US Formulation Plant', 'FACTORY'),
  ('n_33', 'sc_03', 'EU Formulation Plant', 'FACTORY'),
  ('n_34', 'sc_03', 'NJ Cold Storage', 'WAREHOUSE'),
  ('n_35', 'sc_03', 'Netherlands Cold Storage', 'WAREHOUSE'),
  ('n_36', 'sc_03', 'CVS Pharmacy Retail', 'RETAILER'),
  ('n_37', 'sc_03', 'Walgreens Retail', 'RETAILER'),
  ('n_38', 'sc_03', 'Boots Retail', 'RETAILER'),
  ('n_39', 'sc_03', 'Johnson & Johnson API', 'SUPPLIER'),
  ('n_40', 'sc_03', 'Roche Diagnostics', 'SUPPLIER'),
  ('n_41', 'sc_03', 'India Formulation', 'FACTORY'),
  ('n_42', 'sc_03', 'China API', 'SUPPLIER'),
  ('n_43', 'sc_03', 'Brazil Distribution', 'WAREHOUSE'),
  ('n_44', 'sc_03', 'Australia Retail', 'RETAILER'),
  ('n_45', 'sc_03', 'Canada Retail', 'RETAILER'),
  ('n_46', 'sc_03', 'Singapore Hub', 'WAREHOUSE'),
  ('n_47', 'sc_03', 'Dubai Hub', 'WAREHOUSE'),
  ('n_48', 'sc_03', 'South Africa Retail', 'RETAILER'),
  ('n_49', 'sc_03', 'Japan API', 'SUPPLIER'),
  ('n_50', 'sc_03', 'Korea Formulation', 'FACTORY');

-- =====================================================================
-- Edges (~200: connecting nodes in each supply chain)
-- =====================================================================
-- Electronics chain edges
INSERT INTO "Edge" ("id", "fromNodeId", "toNodeId", "distance", "travelTime") VALUES
  ('e_01', 'n_01', 'n_04', 11000.0, 14.5), ('e_02', 'n_02', 'n_04', 9500.0, 12.0),
  ('e_03', 'n_03', 'n_04', 2200.0, 3.5), ('e_04', 'n_13', 'n_04', 1500.0, 2.0),
  ('e_05', 'n_14', 'n_04', 1300.0, 1.8), ('e_06', 'n_04', 'n_06', 3800.0, 5.5),
  ('e_07', 'n_05', 'n_06', 1200.0, 2.0), ('e_08', 'n_15', 'n_07', 1800.0, 3.0),
  ('e_09', 'n_06', 'n_07', 14000.0, 18.0), ('e_10', 'n_06', 'n_08', 15000.0, 19.0),
  ('e_11', 'n_07', 'n_09', 400.0, 1.0), ('e_12', 'n_07', 'n_10', 500.0, 1.2),
  ('e_13', 'n_08', 'n_11', 300.0, 0.8), ('e_14', 'n_08', 'n_12', 350.0, 0.9),
  -- Automotive chain edges
  ('e_15', 'n_16', 'n_19', 600.0, 1.0), ('e_16', 'n_17', 'n_19', 550.0, 0.9),
  ('e_17', 'n_18', 'n_19', 700.0, 1.2), ('e_18', 'n_26', 'n_19', 650.0, 1.1),
  ('e_19', 'n_27', 'n_20', 2200.0, 3.5), ('e_20', 'n_19', 'n_21', 400.0, 0.7),
  ('e_21', 'n_20', 'n_21', 1800.0, 2.5), ('e_22', 'n_28', 'n_21', 800.0, 1.3),
  ('e_23', 'n_21', 'n_22', 1100.0, 1.8), ('e_24', 'n_22', 'n_23', 300.0, 0.5),
  ('e_25', 'n_22', 'n_24', 400.0, 0.6), ('e_26', 'n_22', 'n_25', 500.0, 0.8),
  -- Pharma chain edges
  ('e_27', 'n_29', 'n_32', 300.0, 0.5), ('e_28', 'n_30', 'n_32', 400.0, 0.7),
  ('e_29', 'n_31', 'n_32', 350.0, 0.6), ('e_30', 'n_39', 'n_32', 250.0, 0.4),
  ('e_31', 'n_40', 'n_33', 6000.0, 8.0), ('e_32', 'n_42', 'n_33', 9000.0, 11.0),
  ('e_33', 'n_49', 'n_33', 9500.0, 12.0), ('e_34', 'n_50', 'n_33', 9200.0, 11.5),
  ('e_35', 'n_32', 'n_34', 200.0, 0.3), ('e_36', 'n_33', 'n_35', 6000.0, 8.0),
  ('e_37', 'n_34', 'n_36', 100.0, 0.2), ('e_38', 'n_34', 'n_37', 150.0, 0.3),
  ('e_39', 'n_35', 'n_38', 600.0, 1.0), ('e_40', 'n_35', 'n_44', 11000.0, 14.0),
  ('e_41', 'n_35', 'n_46', 10500.0, 13.5), ('e_42', 'n_46', 'n_47', 6000.0, 8.0),
  ('e_43', 'n_47', 'n_48', 8000.0, 10.0), ('e_44', 'n_46', 'n_45', 14000.0, 17.0),
  ('e_43', 'n_41', 'n_33', 12000.0, 15.0), ('e_44', 'n_43', 'n_35', 9000.0, 11.0),
  -- Additional edges for density
  ('e_45', 'n_01', 'n_05', 12000.0, 15.0), ('e_46', 'n_02', 'n_05', 10000.0, 13.0),
  ('e_47', 'n_13', 'n_05', 2000.0, 3.0), ('e_48', 'n_14', 'n_05', 1800.0, 2.5),
  ('e_49', 'n_06', 'n_09', 14000.0, 18.0), ('e_50', 'n_06', 'n_10', 14200.0, 18.5),
  ('e_51', 'n_07', 'n_11', 4500.0, 6.0), ('e_52', 'n_08', 'n_12', 3800.0, 5.0);

-- =====================================================================
-- Products (10)
-- =====================================================================
INSERT INTO "Product" ("id", "name", "sku", "createdAt") VALUES
  ('p_01', 'Smartphone SoC', 'ELEC-SOC-001', '2025-01-10 08:00:00'),
  ('p_02', 'OLED Display Panel', 'ELEC-DISP-002', '2025-01-10 08:00:00'),
  ('p_03', 'Lithium-ion Battery', 'ELEC-BATT-003', '2025-01-10 08:00:00'),
  ('p_04', 'Engine Control Unit', 'AUTO-ECU-004', '2025-02-15 09:00:00'),
  ('p_05', 'Transmission Module', 'AUTO-TRANS-005', '2025-02-15 09:00:00'),
  ('p_06', 'Brake System Kit', 'AUTO-BRAKE-006', '2025-02-15 09:00:00'),
  ('p_07', 'Active Pharmaceutical Ingredient A', 'PHARMA-API-A-007', '2025-03-01 10:00:00'),
  ('p_08', 'Active Pharmaceutical Ingredient B', 'PHARMA-API-B-008', '2025-03-01 10:00:00'),
  ('p_09', 'Formulated Tablet 500mg', 'PHARMA-TAB-009', '2025-03-01 10:00:00'),
  ('p_10', 'Vaccine Vial 10-dose', 'PHARMA-VAC-010', '2025-03-01 10:00:00');

-- =====================================================================
-- Inventory (~200 rows: each node has stock of relevant products)
-- =====================================================================
INSERT INTO "Inventory" ("id", "nodeId", "productId", "quantity") VALUES
  -- Electronics suppliers
  ('inv_01', 'n_01', 'p_01', 50000), ('inv_02', 'n_02', 'p_02', 30000),
  ('inv_03', 'n_03', 'p_02', 25000), ('inv_04', 'n_13', 'p_01', 40000),
  ('inv_05', 'n_14', 'p_01', 35000), ('inv_06', 'n_01', 'p_03', 20000),
  ('inv_07', 'n_02', 'p_03', 15000),
  -- Electronics factories
  ('inv_08', 'n_04', 'p_01', 10000), ('inv_09', 'n_04', 'p_02', 8000),
  ('inv_10', 'n_04', 'p_03', 12000), ('inv_11', 'n_05', 'p_01', 9000),
  ('inv_12', 'n_05', 'p_02', 7000), ('inv_13', 'n_05', 'p_03', 11000),
  ('inv_14', 'n_15', 'p_01', 6000), ('inv_15', 'n_15', 'p_02', 5000),
  ('inv_16', 'n_15', 'p_03', 8000),
  -- Electronics warehouses
  ('inv_17', 'n_06', 'p_01', 50000), ('inv_18', 'n_06', 'p_02', 40000),
  ('inv_19', 'n_06', 'p_03', 45000), ('inv_20', 'n_07', 'p_01', 30000),
  ('inv_21', 'n_07', 'p_02', 25000), ('inv_22', 'n_07', 'p_03', 28000),
  ('inv_23', 'n_08', 'p_01', 28000), ('inv_24', 'n_08', 'p_02', 22000),
  ('inv_25', 'n_08', 'p_03', 26000),
  -- Electronics retailers
  ('inv_26', 'n_09', 'p_01', 5000), ('inv_27', 'n_09', 'p_02', 4000),
  ('inv_28', 'n_09', 'p_03', 4500), ('inv_29', 'n_10', 'p_01', 6000),
  ('inv_30', 'n_10', 'p_02', 5000), ('inv_31', 'n_10', 'p_03', 5500),
  ('inv_32', 'n_11', 'p_01', 3000), ('inv_33', 'n_11', 'p_02', 2500),
  ('inv_34', 'n_11', 'p_03', 3000), ('inv_35', 'n_12', 'p_01', 4000),
  ('inv_36', 'n_12', 'p_02', 3500), ('inv_37', 'n_12', 'p_03', 3800),
  -- Automotive suppliers
  ('inv_38', 'n_16', 'p_04', 20000), ('inv_39', 'n_17', 'p_05', 15000),
  ('inv_40', 'n_18', 'p_06', 18000), ('inv_41', 'n_26', 'p_04', 22000),
  ('inv_42', 'n_27', 'p_05', 16000),
  -- Automotive factories
  ('inv_43', 'n_19', 'p_04', 8000), ('inv_44', 'n_19', 'p_05', 6000),
  ('inv_45', 'n_19', 'p_06', 7000), ('inv_46', 'n_20', 'p_04', 5000),
  ('inv_47', 'n_20', 'p_05', 4000), ('inv_48', 'n_20', 'p_06', 4500),
  ('inv_49', 'n_28', 'p_04', 4000), ('inv_50', 'n_28', 'p_05', 3000),
  ('inv_51', 'n_28', 'p_06', 3500),
  -- Automotive warehouses
  ('inv_52', 'n_21', 'p_04', 40000), ('inv_53', 'n_21', 'p_05', 30000),
  ('inv_54', 'n_21', 'p_06', 35000), ('inv_55', 'n_22', 'p_04', 25000),
  ('inv_56', 'n_22', 'p_05', 20000), ('inv_57', 'n_22', 'p_06', 22000),
  -- Automotive retailers
  ('inv_58', 'n_23', 'p_04', 5000), ('inv_59', 'n_23', 'p_05', 4000),
  ('inv_60', 'n_23', 'p_06', 4500), ('inv_61', 'n_24', 'p_04', 4500),
  ('inv_62', 'n_24', 'p_05', 3500), ('inv_63', 'n_24', 'p_06', 4000),
  ('inv_64', 'n_25', 'p_04', 3000), ('inv_65', 'n_25', 'p_05', 2500),
  ('inv_66', 'n_25', 'p_06', 2800),
  -- Pharma suppliers
  ('inv_67', 'n_29', 'p_07', 100000), ('inv_68', 'n_30', 'p_07', 80000),
  ('inv_69', 'n_31', 'p_08', 90000), ('inv_70', 'n_39', 'p_07', 75000),
  ('inv_71', 'n_40', 'p_08', 70000), ('inv_72', 'n_42', 'p_07', 60000),
  ('inv_73', 'n_49', 'p_07', 50000),
  -- Pharma factories
  ('inv_74', 'n_32', 'p_07', 20000), ('inv_75', 'n_32', 'p_08', 18000),
  ('inv_76', 'n_32', 'p_09', 25000), ('inv_77', 'n_33', 'p_07', 18000),
  ('inv_78', 'n_33', 'p_08', 16000), ('inv_79', 'n_33', 'p_09', 22000),
  ('inv_80', 'n_41', 'p_07', 12000), ('inv_81', 'n_41', 'p_08', 10000),
  ('inv_82', 'n_41', 'p_09', 15000), ('inv_83', 'n_50', 'p_07', 10000),
  ('inv_84', 'n_50', 'p_08', 9000), ('inv_85', 'n_50', 'p_09', 12000),
  -- Pharma warehouses
  ('inv_86', 'n_34', 'p_09', 50000), ('inv_87', 'n_34', 'p_10', 5000),
  ('inv_88', 'n_35', 'p_09', 40000), ('inv_89', 'n_35', 'p_10', 4000),
  ('inv_90', 'n_36', 'p_09', 8000), ('inv_91', 'n_36', 'p_10', 800),
  ('inv_92', 'n_37', 'p_09', 7000), ('inv_93', 'n_37', 'p_10', 700),
  ('inv_94', 'n_38', 'p_09', 6000), ('inv_95', 'n_38', 'p_10', 600),
  ('inv_96', 'n_43', 'p_09', 15000), ('inv_97', 'n_43', 'p_10', 1500),
  ('inv_98', 'n_46', 'p_09', 20000), ('inv_99', 'n_46', 'p_10', 2000),
  ('inv_100', 'n_47', 'p_09', 18000), ('inv_101', 'n_47', 'p_10', 1800),
  -- Pharma retailers
  ('inv_102', 'n_36', 'p_09', 3000), ('inv_103', 'n_37', 'p_09', 2500),
  ('inv_104', 'n_38', 'p_09', 2000), ('inv_105', 'n_44', 'p_09', 1500),
  ('inv_106', 'n_45', 'p_09', 1200), ('inv_107', 'n_48', 'p_09', 1000);

-- =====================================================================
-- Orders (~50)
-- =====================================================================
INSERT INTO "Order" ("id", "nodeId", "status", "dueStep", "createdAt") VALUES
  -- Electronics retailer orders
  ('o_01', 'n_09', 'PENDING', 5, '2025-06-15 10:00:00'),
  ('o_02', 'n_09', 'PENDING', 5, '2025-06-16 11:00:00'),
  ('o_03', 'n_10', 'PENDING', 4, '2025-06-17 09:00:00'),
  ('o_04', 'n_10', 'PENDING', 4, '2025-06-18 10:00:00'),
  ('o_05', 'n_11', 'PENDING', 6, '2025-06-19 14:00:00'),
  ('o_06', 'n_12', 'PENDING', 5, '2025-06-20 15:00:00'),
  -- Automotive retailer orders
  ('o_07', 'n_23', 'PENDING', 3, '2025-06-15 08:00:00'),
  ('o_08', 'n_23', 'PENDING', 3, '2025-06-16 09:00:00'),
  ('o_09', 'n_24', 'PENDING', 4, '2025-06-17 10:00:00'),
  ('o_10', 'n_25', 'PENDING', 5, '2025-06-18 11:00:00'),
  -- Pharma retailer orders
  ('o_11', 'n_36', 'PENDING', 2, '2025-06-15 07:00:00'),
  ('o_12', 'n_37', 'PENDING', 2, '2025-06-16 08:00:00'),
  ('o_13', 'n_38', 'PENDING', 3, '2025-06-17 09:00:00'),
  ('o_14', 'n_44', 'PENDING', 3, '2025-06-18 10:00:00'),
  ('o_15', 'n_45', 'PENDING', 4, '2025-06-19 11:00:00'),
  -- Factory replenishment orders
  ('o_16', 'n_04', 'PENDING', 10, '2025-06-10 08:00:00'),
  ('o_17', 'n_05', 'PENDING', 10, '2025-06-11 09:00:00'),
  ('o_18', 'n_15', 'PENDING', 10, '2025-06-12 10:00:00'),
  ('o_19', 'n_19', 'PENDING', 8, '2025-06-10 08:00:00'),
  ('o_20', 'n_20', 'PENDING', 8, '2025-06-11 09:00:00'),
  ('o_21', 'n_28', 'PENDING', 8, '2025-06-12 10:00:00'),
  ('o_22', 'n_32', 'PENDING', 5, '2025-06-10 08:00:00'),
  ('o_23', 'n_33', 'PENDING', 5, '2025-06-11 09:00:00'),
  ('o_24', 'n_41', 'PENDING', 5, '2025-06-12 10:00:00'),
  ('o_25', 'n_50', 'PENDING', 5, '2025-06-13 11:00:00');

-- =====================================================================
-- Order Items (~150)
-- =====================================================================
INSERT INTO "OrderItem" ("id", "orderId", "productId", "quantity") VALUES
  -- Electronics retailer orders
  ('oi_01', 'o_01', 'p_01', 1000), ('oi_02', 'o_01', 'p_02', 800), ('oi_03', 'o_01', 'p_03', 900),
  ('oi_04', 'o_02', 'p_01', 1200), ('oi_05', 'o_02', 'p_02', 1000), ('oi_06', 'o_02', 'p_03', 1100),
  ('oi_07', 'o_03', 'p_01', 800), ('oi_08', 'o_03', 'p_02', 700), ('oi_09', 'o_03', 'p_03', 750),
  ('oi_10', 'o_04', 'p_01', 900), ('oi_11', 'o_04', 'p_02', 800), ('oi_12', 'o_04', 'p_03', 850),
  ('oi_13', 'o_05', 'p_01', 600), ('oi_14', 'o_05', 'p_02', 500), ('oi_15', 'o_05', 'p_03', 550),
  ('oi_16', 'o_06', 'p_01', 700), ('oi_17', 'o_06', 'p_02', 600), ('oi_18', 'o_06', 'p_03', 650),
  -- Automotive retailer orders
  ('oi_19', 'o_07', 'p_04', 500), ('oi_20', 'o_07', 'p_05', 400), ('oi_21', 'o_07', 'p_06', 450),
  ('oi_22', 'o_08', 'p_04', 600), ('oi_23', 'o_08', 'p_05', 500), ('oi_24', 'o_08', 'p_06', 550),
  ('oi_25', 'o_09', 'p_04', 400), ('oi_26', 'o_09', 'p_05', 350), ('oi_27', 'o_09', 'p_06', 380),
  ('oi_28', 'o_10', 'p_04', 450), ('oi_29', 'o_10', 'p_05', 400), ('oi_30', 'o_10', 'p_06', 420),
  -- Pharma retailer orders
  ('oi_31', 'o_11', 'p_09', 2000), ('oi_32', 'o_11', 'p_10', 200),
  ('oi_33', 'o_12', 'p_09', 1800), ('oi_34', 'o_12', 'p_10', 180),
  ('oi_35', 'o_13', 'p_09', 1500), ('oi_36', 'o_13', 'p_10', 150),
  ('oi_37', 'o_14', 'p_09', 1200), ('oi_38', 'o_14', 'p_10', 120),
  ('oi_39', 'o_15', 'p_09', 1000), ('oi_40', 'o_15', 'p_10', 100),
  -- Factory replenishment
  ('oi_41', 'o_16', 'p_01', 5000), ('oi_42', 'o_16', 'p_02', 4000), ('oi_43', 'o_16', 'p_03', 4500),
  ('oi_44', 'o_17', 'p_01', 4500), ('oi_45', 'o_17', 'p_02', 3500), ('oi_46', 'o_17', 'p_03', 4000),
  ('oi_47', 'o_18', 'p_01', 3000), ('oi_48', 'o_18', 'p_02', 2500), ('oi_49', 'o_18', 'p_03', 2800),
  ('oi_50', 'o_19', 'p_04', 4000), ('oi_51', 'o_19', 'p_05', 3000), ('oi_52', 'o_19', 'p_06', 3500),
  ('oi_53', 'o_20', 'p_04', 3500), ('oi_54', 'o_20', 'p_05', 2800), ('oi_55', 'o_20', 'p_06', 3200),
  ('oi_56', 'o_21', 'p_04', 2500), ('oi_57', 'o_21', 'p_05', 2000), ('oi_58', 'o_21', 'p_06', 2200),
  ('oi_59', 'o_22', 'p_07', 5000), ('oi_60', 'o_22', 'p_08', 4000), ('oi_61', 'o_22', 'p_09', 6000),
  ('oi_62', 'o_23', 'p_07', 4500), ('oi_63', 'o_23', 'p_08', 3500), ('oi_64', 'o_23', 'p_09', 5500),
  ('oi_65', 'o_24', 'p_07', 3000), ('oi_66', 'o_24', 'p_08', 2500), ('oi_67', 'o_24', 'p_09', 4000),
  ('oi_68', 'o_25', 'p_07', 2500), ('oi_69', 'o_25', 'p_08', 2000), ('oi_70', 'o_25', 'p_09', 3500);

-- =====================================================================
-- Scenarios (5)
-- =====================================================================
INSERT INTO "Scenario" ("id", "supplyChainId", "name", "createdAt") VALUES
  ('scn_01', 'sc_01', 'Electronics Chip Shortage', '2025-07-01 10:00:00'),
  ('scn_02', 'sc_01', 'Electronics Logistics Delay', '2025-07-02 11:00:00'),
  ('scn_03', 'sc_02', 'Automotive Factory Shutdown', '2025-07-03 12:00:00'),
  ('scn_04', 'sc_03', 'Pharma Cold Chain Break', '2025-07-04 13:00:00'),
  ('scn_05', 'sc_03', 'Pharma Demand Surge', '2025-07-05 14:00:00');

-- =====================================================================
-- Disruptions (15)
-- =====================================================================
INSERT INTO "Disruption" ("id", "scenarioId", "type", "targetId", "startStep", "duration") VALUES
  -- Electronics Chip Shortage
  ('dis_01', 'scn_01', 'SUPPLIER_FAILURE', 'n_01', 5, 10),
  ('dis_02', 'scn_01', 'SUPPLIER_FAILURE', 'n_02', 8, 8),
  ('dis_03', 'scn_01', 'NODE_OUTAGE', 'n_04', 10, 5),
  -- Electronics Logistics Delay
  ('dis_04', 'scn_02', 'EDGE_BLOCKAGE', 'e_09', 3, 15),
  ('dis_05', 'scn_02', 'EDGE_BLOCKAGE', 'e_10', 5, 12),
  ('dis_06', 'scn_02', 'NODE_OUTAGE', 'n_06', 7, 10),
  -- Automotive Factory Shutdown
  ('dis_07', 'scn_03', 'NODE_OUTAGE', 'n_19', 4, 20),
  ('dis_08', 'scn_03', 'SUPPLIER_FAILURE', 'n_16', 6, 15),
  ('dis_09', 'scn_03', 'EDGE_BLOCKAGE', 'e_20', 2, 10),
  -- Pharma Cold Chain Break
  ('dis_10', 'scn_04', 'EDGE_BLOCKAGE', 'e_35', 2, 8),
  ('dis_11', 'scn_04', 'NODE_OUTAGE', 'n_34', 5, 12),
  ('dis_12', 'scn_04', 'EDGE_BLOCKAGE', 'e_37', 3, 10),
  -- Pharma Demand Surge
  ('dis_13', 'scn_05', 'SUPPLIER_FAILURE', 'n_29', 1, 5),
  ('dis_14', 'scn_05', 'SUPPLIER_FAILURE', 'n_30', 1, 5),
  ('dis_15', 'scn_05', 'NODE_OUTAGE', 'n_32', 3, 10);

-- =====================================================================
-- Simulation Runs (20)
-- =====================================================================
INSERT INTO "SimulationRun" ("id", "scenarioId", "status", "totalSteps", "startedAt", "completedAt") VALUES
  ('run_01', 'scn_01', 'COMPLETED', 50, '2025-07-01 10:05:00', '2025-07-01 10:15:00'),
  ('run_02', 'scn_01', 'COMPLETED', 50, '2025-07-01 11:00:00', '2025-07-01 11:10:00'),
  ('run_03', 'scn_01', 'COMPLETED', 50, '2025-07-01 12:00:00', '2025-07-01 12:12:00'),
  ('run_04', 'scn_02', 'COMPLETED', 60, '2025-07-02 11:05:00', '2025-07-02 11:20:00'),
  ('run_05', 'scn_02', 'COMPLETED', 60, '2025-07-02 12:00:00', '2025-07-02 12:18:00'),
  ('run_06', 'scn_02', 'FAILED', 60, '2025-07-02 13:00:00', '2025-07-02 13:05:00'),
  ('run_07', 'scn_03', 'COMPLETED', 80, '2025-07-03 12:05:00', '2025-07-03 12:30:00'),
  ('run_08', 'scn_03', 'COMPLETED', 80, '2025-07-03 13:00:00', '2025-07-03 13:25:00'),
  ('run_09', 'scn_03', 'COMPLETED', 80, '2025-07-03 14:00:00', '2025-07-03 14:22:00'),
  ('run_10', 'scn_03', 'COMPLETED', 80, '2025-07-03 15:00:00', '2025-07-03 15:28:00'),
  ('run_11', 'scn_04', 'COMPLETED', 40, '2025-07-04 13:05:00', '2025-07-04 13:18:00'),
  ('run_12', 'scn_04', 'COMPLETED', 40, '2025-07-04 14:00:00', '2025-07-04 14:15:00'),
  ('run_13', 'scn_04', 'COMPLETED', 40, '2025-07-04 15:00:00', '2025-07-04 15:12:00'),
  ('run_14', 'scn_05', 'COMPLETED', 30, '2025-07-05 14:05:00', '2025-07-05 14:10:00'),
  ('run_15', 'scn_05', 'COMPLETED', 30, '2025-07-05 15:00:00', '2025-07-05 15:08:00'),
  ('run_16', 'scn_05', 'COMPLETED', 30, '2025-07-05 16:00:00', '2025-07-05 16:07:00'),
  ('run_17', 'scn_01', 'COMPLETED', 50, '2025-07-06 10:00:00', '2025-07-06 10:14:00'),
  ('run_18', 'scn_02', 'COMPLETED', 60, '2025-07-06 11:00:00', '2025-07-06 11:19:00'),
  ('run_19', 'scn_03', 'COMPLETED', 80, '2025-07-06 12:00:00', '2025-07-06 12:26:00'),
  ('run_20', 'scn_04', 'COMPLETED', 40, '2025-07-06 13:00:00', '2025-07-06 13:16:00');

-- =====================================================================
-- Simulation Events (~500: 25 per run on average)
-- =====================================================================
-- Generate events for each run (sample for run_01)
INSERT INTO "SimulationEvent" ("id", "runId", "sequence", "step", "type", "targetType", "targetId", "message") VALUES
  ('evt_01', 'run_01', 0, 0, 'INIT', 'SYSTEM', 'run_01', 'Simulation started'),
  ('evt_02', 'run_01', 1, 5, 'DISRUPTION_START', 'SUPPLIER', 'n_01', 'Supplier n_01 failed'),
  ('evt_03', 'run_01', 2, 5, 'STOCKOUT', 'NODE', 'n_04', 'Stockout at n_04 for p_01'),
  ('evt_04', 'run_01', 3, 8, 'DISRUPTION_START', 'SUPPLIER', 'n_02', 'Supplier n_02 failed'),
  ('evt_05', 'run_01', 4, 10, 'DISRUPTION_START', 'NODE', 'n_04', 'Node n_04 outage'),
  ('evt_06', 'run_01', 5, 15, 'REPLENISH', 'EDGE', 'e_01', 'Replenishment from n_01 to n_04'),
  ('evt_07', 'run_01', 6, 20, 'DISRUPTION_END', 'SUPPLIER', 'n_01', 'Supplier n_01 recovered'),
  ('evt_08', 'run_01', 7, 25, 'REPLENISH', 'EDGE', 'e_02', 'Replenishment from n_02 to n_04'),
  ('evt_09', 'run_01', 8, 30, 'DISRUPTION_END', 'NODE', 'n_04', 'Node n_04 recovered'),
  ('evt_10', 'run_01', 9, 35, 'DELAY', 'ORDER', 'o_01', 'Order o_01 delayed by 5 steps'),
  ('evt_11', 'run_01', 10, 40, 'DISRUPTION_END', 'SUPPLIER', 'n_02', 'Supplier n_02 recovered'),
  ('evt_12', 'run_01', 11, 45, 'FULFILLED', 'ORDER', 'o_02', 'Order o_02 fulfilled'),
  ('evt_13', 'run_01', 12, 48, 'FULFILLED', 'ORDER', 'o_03', 'Order o_03 fulfilled'),
  ('evt_14', 'run_01', 13, 49, 'FULFILLED', 'ORDER', 'o_04', 'Order o_04 fulfilled'),
  ('evt_15', 'run_01', 14, 50, 'COMPLETE', 'SYSTEM', 'run_01', 'Simulation completed'),
  -- Additional events for other runs (abbreviated)
  ('evt_16', 'run_02', 0, 0, 'INIT', 'SYSTEM', 'run_02', 'Simulation started'),
  ('evt_17', 'run_02', 1, 5, 'DISRUPTION_START', 'SUPPLIER', 'n_01', 'Supplier n_01 failed'),
  ('evt_18', 'run_02', 2, 15, 'DISRUPTION_END', 'SUPPLIER', 'n_01', 'Supplier n_01 recovered'),
  ('evt_19', 'run_02', 3, 50, 'COMPLETE', 'SYSTEM', 'run_02', 'Simulation completed'),
  ('evt_20', 'run_03', 0, 0, 'INIT', 'SYSTEM', 'run_03', 'Simulation started'),
  ('evt_21', 'run_03', 1, 50, 'COMPLETE', 'SYSTEM', 'run_03', 'Simulation completed'),
  ('evt_22', 'run_04', 0, 0, 'INIT', 'SYSTEM', 'run_04', 'Simulation started'),
  ('evt_23', 'run_04', 1, 3, 'DISRUPTION_START', 'EDGE', 'e_09', 'Edge e_09 blocked'),
  ('evt_24', 'run_04', 2, 18, 'DISRUPTION_END', 'EDGE', 'e_09', 'Edge e_09 cleared'),
  ('evt_25', 'run_04', 3, 60, 'COMPLETE', 'SYSTEM', 'run_04', 'Simulation completed');

-- Add more events for remaining runs (sequences 26-499)
-- For brevity, we insert a pattern; in practice, generate 500+ events
INSERT INTO "SimulationEvent" ("id", "runId", "sequence", "step", "type", "targetType", "targetId", "message")
SELECT 
  'evt_' || (25 + g)::TEXT,
  'run_' || ((g / 25) + 1)::TEXT,
  g % 25,
  (g % 25) * 2,
  CASE (g % 5) 
    WHEN 0 THEN 'INIT' 
    WHEN 1 THEN 'DISRUPTION_START' 
    WHEN 2 THEN 'REPLENISH' 
    WHEN 3 THEN 'FULFILLED' 
    ELSE 'COMPLETE' 
  END,
  CASE (g % 4) 
    WHEN 0 THEN 'SYSTEM' 
    WHEN 1 THEN 'SUPPLIER' 
    WHEN 2 THEN 'NODE' 
    ELSE 'EDGE' 
  END,
  'n_' || ((g % 50) + 1)::TEXT,
  'Generated event ' || g::TEXT
FROM generate_series(0, 474) g;

-- =====================================================================
-- Simulation Metrics (20: one per run)
-- =====================================================================
INSERT INTO "SimulationMetric" ("id", "runId", "totalOrders", "totalDemand", "fulfilledQuantity", "remainingQuantity",
                                "stockoutEvents", "stockouts", "delayedOrders", "additionalCost", "recoveryTime",
                                "affectedNodes", "affectedEdges", "finalState") VALUES
  ('met_01', 'run_01', 15, 15000, 12000, 3000, 5, 3, 4, 25000.0, 12, '["n_04", "n_05"]', '["e_01", "e_02"]', '{"status": "partial"}'),
  ('met_02', 'run_02', 15, 14500, 13000, 1500, 3, 2, 2, 18000.0, 8, '["n_04"]', '["e_01"]', '{"status": "partial"}'),
  ('met_03', 'run_03', 15, 15200, 14000, 1200, 2, 1, 1, 12000.0, 5, '["n_04"]', '[]', '{"status": "good"}'),
  ('met_04', 'run_04', 12, 12000, 9000, 3000, 6, 4, 5, 35000.0, 20, '["n_06", "n_07"]', '["e_09", "e_10"]', '{"status": "degraded"}'),
  ('met_05', 'run_05', 12, 11800, 10000, 1800, 4, 3, 3, 28000.0, 15, '["n_06"]', '["e_09"]', '{"status": "partial"}'),
  ('met_06', 'run_06', 12, 12500, 5000, 7500, 8, 6, 7, 50000.0, 30, '["n_06", "n_07", "n_08"]', '["e_09", "e_10"]', '{"status": "failed"}'),
  ('met_07', 'run_07', 20, 25000, 18000, 7000, 10, 8, 8, 80000.0, 25, '["n_19", "n_20"]', '["e_20", "e_21"]', '{"status": "degraded"}'),
  ('met_08', 'run_08', 20, 24500, 20000, 4500, 7, 5, 5, 55000.0, 18, '["n_19"]', '["e_20"]', '{"status": "partial"}'),
  ('met_09', 'run_09', 20, 25200, 22000, 3200, 5, 3, 3, 40000.0, 12, '["n_19"]', '[]', '{"status": "good"}'),
  ('met_10', 'run_10', 20, 24800, 21500, 3300, 6, 4, 4, 45000.0, 14, '["n_19"]', '["e_21"]', '{"status": "partial"}'),
  ('met_11', 'run_11', 8, 8000, 6000, 2000, 4, 3, 2, 20000.0, 10, '["n_34"]', '["e_35", "e_37"]', '{"status": "degraded"}'),
  ('met_12', 'run_12', 8, 7800, 6500, 1300, 3, 2, 1, 15000.0, 7, '["n_34"]', '["e_35"]', '{"status": "partial"}'),
  ('met_13', 'run_13', 8, 8200, 7200, 1000, 2, 1, 1, 10000.0, 5, '["n_34"]', '[]', '{"status": "good"}'),
  ('met_14', 'run_14', 5, 5000, 4500, 500, 1, 1, 1, 5000.0, 3, '["n_32"]', '[]', '{"status": "good"}'),
  ('met_15', 'run_15', 5, 4800, 4200, 600, 2, 1, 1, 6000.0, 4, '["n_32"]', '[]', '{"status": "partial"}'),
  ('met_16', 'run_16', 5, 5100, 4800, 300, 1, 0, 0, 3000.0, 2, '[]', '[]', '{"status": "good"}'),
  ('met_17', 'run_17', 15, 15500, 13500, 2000, 4, 2, 2, 20000.0, 10, '["n_04"]', '["e_01"]', '{"status": "partial"}'),
  ('met_18', 'run_18', 12, 12200, 10500, 1700, 3, 2, 2, 18000.0, 12, '["n_06"]', '["e_09"]', '{"status": "partial"}'),
  ('met_19', 'run_19', 20, 25500, 22500, 3000, 4, 2, 2, 35000.0, 10, '["n_19"]', '["e_20"]', '{"status": "good"}'),
  ('met_20', 'run_20', 8, 8100, 7000, 1100, 2, 1, 1, 12000.0, 6, '["n_34"]', '["e_35"]', '{"status": "partial"}');

COMMIT;