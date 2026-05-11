-- Update sales_orders table for warehouse flow
ALTER TABLE sales_orders 
    ALTER COLUMN status TYPE VARCHAR(30),
    ADD COLUMN IF NOT EXISTS delivery_order_no VARCHAR(50) UNIQUE,
    ADD COLUMN IF NOT EXISTS shipped_at TIMESTAMPTZ;

-- Update sales_order_items for actual quantity tracking
ALTER TABLE sales_order_items 
    ADD COLUMN IF NOT EXISTS actual_quantity INT NOT NULL DEFAULT 0;
