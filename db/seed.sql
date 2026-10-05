-- seed.sql : starter knowledge base for RootCause
-- Run AFTER schema.sql (schema.sql drops and recreates the tables, so ids start fresh).
--
-- Pattern: one INSERT per tree level. Each row names its parent by TITLE and the
-- JOIN looks up the parent's id, so we never hard-code ids.
-- Parents must be inserted in an EARLIER statement than their children.
-- WARNING: if a parent_title has a typo, the INNER JOIN silently drops that row.
-- The count checks at the bottom exist to catch that.
-- ---------------------------------------------------------------
-- LEVEL 1 : roots (parent_id stays NULL)
-- ---------------------------------------------------------------
INSERT INTO hypothesis_template (title, domain, hyp_description, recommendation) 
VALUES
    ('Database issue', 'Database', 'The fault originates in the database layer: queries, constraints or the connection.', 'Check the error code, then inspect the failing query and the table definition.'),
    ('Backend and API issue', 'Backend', 'The fault is in server-side code: routes, request handling or async flow.', 'Reproduce the request in Postman and read the server console output.'),
    ('Frontend rendering issue', 'Frontend', 'The page shows wrong, missing or stale content because of client-side code.', 'Open the browser console and inspect the DOM and the network tab.'),
    ('Logic error', 'Logic', 'The code runs without crashing but produces a wrong result.', 'Log intermediate values and compare them with what you expect at each step.'),
    ('Layout and styling issue', 'Layout', 'Elements are positioned, sized or styled incorrectly.', 'Use the browser inspector to see which CSS rules apply and which are overridden.'),
    ('Network and connectivity issue', 'Network', 'Requests between client, server or services fail to complete.', 'Check the network tab and confirm the URL, port and server status.'),
    ('Environment and configuration issue', 'Environment', 'The code is fine but the setup around it is not: variables, ports or dependencies.', 'Compare your setup with the documentation and re-check configuration files.');

-- ---------------------------------------------------------------
-- LEVEL 2 : categories under each root
-- ---------------------------------------------------------------
INSERT INTO hypothesis_template (parent_id, title, domain, hyp_description, recommendation)
-- 
SELECT p.id, v.title, v.domain, v.hyp_description, v.recommendation
FROM (
    VALUES
        ('Database issue', 'Constraint violation', 'Database', 'Data being written breaks a rule defined on the table.', 'Read the constraint name in the error message and check the data against the table definition.'),
        ('Database issue', 'Query error', 'Database', 'The SQL itself is malformed or refers to things that do not exist.', 'Run the exact query in pgAdmin or psql and read the position marker in the error.'),
        ('Database issue', 'Connection failure', 'Database', 'The application cannot establish or keep a connection to PostgreSQL.', 'Confirm the server is running and test the same credentials with psql.'),

        ('Backend and API issue', 'Routing and request handling', 'Backend', 'The request never reaches the intended handler or arrives without the expected data.', 'Log the method, path and body at the top of the handler.'),
        ('Backend and API issue', 'Async handling error', 'Backend', 'Asynchronous code runs in a different order than assumed or fails silently.', 'Check that every promise is awaited and every await is inside try/catch.'),
        ('Backend and API issue', 'Authentication issue', 'Backend', 'Login, token or session checks reject valid users or accept invalid ones.', 'Inspect the token or cookie being sent and trace the auth middleware step by step.'),

        ('Frontend rendering issue', 'DOM access problem', 'Frontend', 'JavaScript cannot find or modify the element it expects.', 'Log the result of the selector and check when the script runs relative to page load.'),
        ('Frontend rendering issue', 'Stale or missing data in UI', 'Frontend', 'The interface shows old data or renders before data has arrived.', 'Log the data at the moment of rendering and check the order of fetch and render.'),

        ('Logic error', 'Boundary error', 'Logic', 'The code mishandles the first, last or empty case.', 'Test with empty input, one item and the maximum size, and print loop bounds.'),
        ('Logic error', 'Wrong condition', 'Logic', 'A comparison or branch condition does not mean what the programmer intended.', 'Print both sides of the condition and check the operator and operand types.'),

        ('Layout and styling issue', 'Cascade and specificity conflict', 'Layout', 'A different CSS rule wins over the one you wrote.', 'Inspect the element and look for crossed-out declarations in the styles panel.'),
        ('Layout and styling issue', 'Box model and sizing', 'Layout', 'Padding, borders or box-sizing make elements larger or smaller than expected.', 'Check box-sizing and the computed width and height in the inspector.'),

        ('Network and connectivity issue', 'Cross-origin (CORS) block', 'Network', 'The browser blocks a request to a different origin.', 'Read the exact CORS message in the console and compare the origin with the server settings.'),
        ('Network and connectivity issue', 'Unreachable server', 'Network', 'The request cannot reach the server or gets no response.', 'Call the endpoint directly with curl or Postman to separate client problems from server problems.'),

        ('Environment and configuration issue', 'Missing configuration', 'Environment', 'A required setting or secret is absent or has the wrong value.', 'Print the variable at startup (never log secrets) and check how it is loaded.'),
        ('Environment and configuration issue', 'Port conflict', 'Environment', 'Another process is already using the port the application wants.', 'Find the process using the port and stop it, or change the port.')
) AS v(parent_title, title, domain, hyp_description, recommendation)
JOIN hypothesis_template p -- parent
ON p.title = v.parent_title;

-- ---------------------------------------------------------------
-- | INSERT INTO target_table (column1, column2, ...)             |
-- | SELECT column1, column2, ... FROM source_table;              |
-- ---------------------------------------------------------------

-- ---------------------------------------------------------------
-- LEVEL 3 : specific causes (leaves)
-- ---------------------------------------------------------------
INSERT INTO hypothesis_template (parent_id, title, domain, hyp_description, recommendation)
SELECT p.id, v.title, v.domain, v.hyp_description, v.recommendation
FROM (
    VALUES
        ('Constraint violation', 'Foreign key violation', 'Database', 'A row references another row that does not exist, or a referenced row is being deleted.', 'Check that the parent row exists before inserting, and review the ON DELETE rule.'),
        ('Constraint violation', 'Unique violation', 'Database', 'A value that must be unique already exists in the table.', 'Query for the existing value and decide between updating it and rejecting the duplicate.'),
        ('Constraint violation', 'Not-null violation', 'Database', 'A required column received no value.', 'Check which field is missing in the request body and where it gets dropped.'),

        ('Query error', 'Syntax error in SQL', 'Database', 'The statement is not valid SQL, often a missing comma, quote or keyword.', 'Copy the query into pgAdmin and look at the character position PostgreSQL reports.'),
        ('Query error', 'Undefined table or column', 'Database', 'The query names a table or column that does not exist.', 'Describe the table in psql and compare spelling and letter case.'),

        ('Connection failure', 'Wrong credentials', 'Database', 'The user name, password or database name is rejected by PostgreSQL.', 'Test the same values with psql and compare them with your configuration.'),
        ('Connection failure', 'Database server not running', 'Database', 'PostgreSQL is stopped or listening on a different host or port.', 'Check the PostgreSQL service status and the port in your connection settings.'),

        ('Routing and request handling', 'Route not registered or wrong path', 'Backend', 'The URL does not match any route, so the server returns 404.', 'Compare the requested path with the defined routes, including prefix and trailing slash.'),
        ('Routing and request handling', 'Missing body parser', 'Backend', 'The request body is undefined because JSON parsing middleware is not set up.', 'Make sure express.json() is registered before the routes that read the body.'),

        ('Async handling error', 'Missing await', 'Backend', 'A promise is used before it has resolved, giving undefined or a pending promise.', 'Log the value, add await, then confirm the function is declared async.'),
        ('Async handling error', 'Unhandled promise rejection', 'Backend', 'A failed async call has no catch, so the error is lost or crashes the process.', 'Wrap awaited calls in try/catch and pass errors on to the error handler.'),

        ('Authentication issue', 'Invalid or expired token', 'Backend', 'The token is malformed, signed with another secret or past its expiry.', 'Decode the token, check its expiry and confirm the signing secret matches.'),
        ('Authentication issue', 'Password hash mismatch', 'Backend', 'The stored hash is compared incorrectly, so valid passwords fail.', 'Confirm the same library and settings are used for hashing and comparing.'),

        ('DOM access problem', 'Script runs before DOM loads', 'Frontend', 'The script executes before the element exists, so the selector returns null.', 'Move the script to the end of body or use the defer attribute.'),
        ('DOM access problem', 'Wrong selector or id', 'Frontend', 'The selector does not match the actual element.', 'Run the selector in the browser console and compare it with the HTML.'),

        ('Stale or missing data in UI', 'Render before data arrives', 'Frontend', 'The page draws before the fetch finishes, so it shows empty or old content.', 'Render after the fetch resolves and show a loading state in the meantime.'),

        ('Boundary error', 'Off-by-one loop error', 'Logic', 'A loop runs one time too many or too few.', 'Print the first and last index and check whether the condition needs less-than or less-than-or-equal.'),

        ('Wrong condition', 'Wrong comparison operator', 'Logic', 'An operator such as = vs ==, == vs ===, or < vs <= gives the wrong result.', 'Evaluate the condition by hand with sample values and check the types.'),

        ('Box model and sizing', 'Padding or border changes element size', 'Layout', 'Without border-box sizing, padding and borders add to the declared width.', 'Set box-sizing to border-box and re-check the computed size.'),

        ('Cross-origin (CORS) block', 'Missing CORS headers on server', 'Network', 'The server response lacks the headers that allow the requesting origin.', 'Add CORS middleware on the server and allow the correct origin and methods.'),

        ('Unreachable server', 'Wrong URL or port', 'Network', 'The client calls an address where nothing is listening.', 'Compare the URL and port in the client code with the ones the server logs on startup.'),

        ('Missing configuration', 'Environment file not loaded', 'Environment', 'The .env file is not read, so variables are undefined.', 'Check that dotenv is loaded first and that the file is in the working directory.'),

        ('Port conflict', 'Port already in use', 'Environment', 'The server fails on startup because the address is already in use.', 'Stop the process holding the port or start the server on another port.')
) AS v(parent_title, title, domain, hyp_description, recommendation)
JOIN hypothesis_template p 
ON p.title = v.parent_title;

-- ---------------------------------------------------------------
-- SANITY CHECKS : if a number is off, a parent_title has a typo
-- ---------------------------------------------------------------
SELECT COUNT(*) AS total_templates FROM hypothesis_template;                          -- expect 46
SELECT COUNT(*) AS root_templates  FROM hypothesis_template WHERE parent_id IS NULL;  -- expect 7

