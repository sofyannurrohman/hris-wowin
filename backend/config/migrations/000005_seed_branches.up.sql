-- Seed Wowin Cabang Solo
INSERT INTO branches (id, name, created_at, updated_at)
VALUES (gen_random_uuid(), 'Wowin Cabang Solo', now(), now())
ON CONFLICT DO NOTHING;
