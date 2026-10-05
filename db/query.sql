-- List every template next to its parent's title

-- SELECT
--     p.title AS parent_title,
--     c.title,
--     c.hyp_description
-- FROM hypothesis_template c
-- LEFT JOIN hypothesis_template p
--     ON c.parent_id = p.id
-- ORDER BY c.domain, c.parent_id NULLS FIRST, c.id;

-- Testing rules table
INSERT INTO rules (template_id, match_field, match_value, weight) VALUES (1, 'error_code', 'Database', 5);
INSERT INTO rules (template_id, match_field, match_value, weight) VALUES (1, 'error_code', 'Database', 5);