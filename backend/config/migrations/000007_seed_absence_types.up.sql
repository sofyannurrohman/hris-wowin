-- Seed Absence Types
INSERT INTO leave_types (id, name, is_paid, default_quota) VALUES 
    (gen_random_uuid(), 'Sakit (Dibayar)', true, 12),
    (gen_random_uuid(), 'Izin (Potong Gaji)', false, 0)
ON CONFLICT DO NOTHING;

-- Seed balances for all existing employees for the new types
INSERT INTO leave_balances (id, employee_id, leave_type_id, year, balance_total, balance_used)
SELECT 
    gen_random_uuid(), 
    e.id, 
    lt.id, 
    EXTRACT(YEAR FROM NOW())::INT, 
    lt.default_quota, 
    0
FROM employees e
CROSS JOIN leave_types lt
WHERE lt.name IN ('Sakit (Dibayar)', 'Izin (Potong Gaji)')
ON CONFLICT (employee_id, leave_type_id, year) DO NOTHING;
