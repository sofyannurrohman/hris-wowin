-- Add new metadata and financial fields to products table
ALTER TABLE products ADD COLUMN IF NOT EXISTS category VARCHAR(100);
ALTER TABLE products ADD COLUMN IF NOT EXISTS brand VARCHAR(100);
ALTER TABLE products ADD COLUMN IF NOT EXISTS weight_unit VARCHAR(10) DEFAULT 'KG';
ALTER TABLE products ADD COLUMN IF NOT EXISTS cost_price DECIMAL(15, 2) DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS selling_price DECIMAL(15, 2) DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS specs TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE products ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Migration to ensure weight is decimal for precision
ALTER TABLE products ALTER COLUMN weight TYPE DECIMAL(10, 2);
