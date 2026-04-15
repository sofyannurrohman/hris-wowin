-- Seed Musibah Type
INSERT INTO leave_types (id, name, is_paid, default_quota) VALUES 
    (gen_random_uuid(), 'Izin Musibah / Duka (Dibayar)', true, 3)
ON CONFLICT DO NOTHING;

-- Seed balances for existing employees
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
WHERE lt.name = 'Izin Musibah / Duka (Dibayar)'
ON CONFLICT (employee_id, leave_type_id, year) DO NOTHING;
