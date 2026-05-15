-- Migration: Remove visit_id from sales_orders
-- Version: 000040

DROP INDEX IF EXISTS idx_sales_orders_visit_id;
ALTER TABLE sales_orders DROP COLUMN IF EXISTS visit_id;
