-- Migration: Add visit_id to sales_orders
-- Version: 000040

ALTER TABLE sales_orders ADD COLUMN IF NOT EXISTS visit_id UUID REFERENCES sales_visits(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_sales_orders_visit_id ON sales_orders(visit_id);
