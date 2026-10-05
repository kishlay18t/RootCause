-- seed_rules.sql : starter rules for RootCause
-- Run AFTER schema.sql and seed.sql (it looks templates up by title).
--
-- One row = "if the bug's <match_field> <match_type> <match_value>, suggest <template> with this weight".
-- Same title-lookup JOIN pattern as seed.sql: a typo in template_title drops the row silently,
-- so check the count at the bottom.
--
-- Weights are first guesses on a 1-10 scale:
--   category rules        : low  (3)   - a broad hint, every bug has one
--   weak/ambiguous clues  : 4-5        - several templates could explain it
--   precise clues         : 7-9        - an error code or a fixed message phrase
-- Tune them once you see real suggestions.
--
-- Many leaf templates have NO rule on purpose. They are reached by branching
-- down the tree after evidence supports their parent, not by direct matching.

INSERT INTO rules (template_id, match_field, match_value, match_type, weight)
SELECT t.id, v.match_field, v.match_value, v.match_type, v.weight
FROM (VALUES
  -- ---------- category -> root template (EQUALS) ----------
  ('Database issue',                      'category', 'Database',                      'EQUALS', 3),
  ('Backend and API issue',               'category', 'Backend and API',               'EQUALS', 3),
  ('Frontend rendering issue',            'category', 'Frontend Rendering',            'EQUALS', 3),
  ('Logic error',                         'category', 'Logic',                         'EQUALS', 3),
  ('Layout and styling issue',            'category', 'Layout and Styling',            'EQUALS', 3),
  ('Network and connectivity issue',      'category', 'Network and Connectivity',      'EQUALS', 3),
  ('Environment and configuration issue', 'category', 'Environment and Configuration', 'EQUALS', 3),

  -- ---------- error_code (EQUALS) ----------
  -- PostgreSQL SQLSTATE codes
  ('Foreign key violation',               'error_code', '23503', 'EQUALS', 9),
  ('Unique violation',                    'error_code', '23505', 'EQUALS', 9),
  ('Not-null violation',                  'error_code', '23502', 'EQUALS', 9),
  ('Syntax error in SQL',                 'error_code', '42601', 'EQUALS', 9),
  ('Undefined table or column',           'error_code', '42P01', 'EQUALS', 9),
  ('Undefined table or column',           'error_code', '42703', 'EQUALS', 9),
  ('Wrong credentials',                   'error_code', '28P01', 'EQUALS', 9),
  ('Wrong credentials',                   'error_code', '3D000', 'EQUALS', 7),
  -- Node.js / HTTP codes
  ('Database server not running',         'error_code', 'ECONNREFUSED', 'EQUALS', 5),
  ('Wrong URL or port',                   'error_code', 'ECONNREFUSED', 'EQUALS', 5),
  ('Port already in use',                 'error_code', 'EADDRINUSE', 'EQUALS', 9),
  ('Unhandled promise rejection',         'error_code', 'ERR_UNHANDLED_REJECTION', 'EQUALS', 9),
  ('Route not registered or wrong path',  'error_code', '404', 'EQUALS', 5),
  ('Invalid or expired token',            'error_code', '401', 'EQUALS', 4),

  -- ---------- error_message (CONTAINS, compared case-insensitively by the engine) ----------
  ('Foreign key violation',               'error_message', 'violates foreign key constraint', 'CONTAINS', 8),
  ('Unique violation',                    'error_message', 'violates unique constraint',      'CONTAINS', 8),
  ('Not-null violation',                  'error_message', 'violates not-null constraint',    'CONTAINS', 8),
  ('Syntax error in SQL',                 'error_message', 'syntax error at or near',         'CONTAINS', 8),
  ('Undefined table or column',           'error_message', 'does not exist',                  'CONTAINS', 4),
  ('Wrong credentials',                   'error_message', 'password authentication failed',  'CONTAINS', 8),
  ('Port already in use',                 'error_message', 'address already in use',          'CONTAINS', 8),
  ('Missing CORS headers on server',      'error_message', 'blocked by CORS policy',          'CONTAINS', 9),
  ('Missing CORS headers on server',      'error_message', 'Access-Control-Allow-Origin',     'CONTAINS', 7),
  ('Invalid or expired token',            'error_message', 'jwt expired',                     'CONTAINS', 9),
  ('Invalid or expired token',            'error_message', 'jwt malformed',                   'CONTAINS', 8),
  ('Route not registered or wrong path',  'error_message', 'Cannot GET',                      'CONTAINS', 7),
  ('Route not registered or wrong path',  'error_message', 'Cannot POST',                     'CONTAINS', 7),
  ('Script runs before DOM loads',        'error_message', 'Cannot read properties of null',  'CONTAINS', 4),
  ('Wrong selector or id',                'error_message', 'Cannot read properties of null',  'CONTAINS', 4),
  ('Wrong URL or port',                   'error_message', 'ERR_CONNECTION_REFUSED',          'CONTAINS', 7)
) AS v(template_title, match_field, match_value, match_type, weight)
JOIN hypothesis_template t ON t.title = v.template_title;

-- ---------------------------------------------------------------
-- SANITY CHECKS
-- ---------------------------------------------------------------
SELECT COUNT(*) AS total_rules FROM rules;   -- expect 37

-- Rules next to the template they point at (strongest first)
SELECT t.title AS template, r.match_field, r.match_type, r.match_value, r.weight
FROM rules r
JOIN hypothesis_template t ON t.id = r.template_id
ORDER BY r.weight DESC, t.title;