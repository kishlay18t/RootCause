DROP TABLE IF EXISTS rules;
DROP TABLE IF EXISTS hypotheses;
DROP TABLE IF EXISTS hypothesis_template;
DROP TABLE IF EXISTS bugs;
DROP TABLE IF EXISTS users;

-- Create table users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email varchar(100) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL
);

-- Create table bugs
CREATE TABLE bugs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    observed_behaviour TEXT NOT NULL,
    expected_behaviour TEXT NOT NULL,
    repro_steps TEXT NOT NULL,
    environment TEXT,
    error_message TEXT,
    error_code TEXT,
    category TEXT NOT NULL CHECK (category IN ('Database', 'Backend and API', 'Frontend Rendering', 'Logic', 'Layout and Styling', 'Network and Connectivity', 'Environment and Configuration', 'Unknown')),
    bug_status TEXT  NOT NULL DEFAULT 'REPORTED' CHECK (bug_status IN 
        ('REPORTED', 'INVESTIGATING', 'RESOLVED', 'CLOSED')
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- create table hypothesis_template
CREATE TABLE hypothesis_template (
    id SERIAL PRIMARY KEY,
    parent_id INTEGER REFERENCES hypothesis_template(id) ON DELETE SET NULL,
    title VARCHAR(50) NOT NULL UNIQUE,
    domain VARCHAR(50) NOT NULL,
    hyp_description TEXT NOT NULL,
    recommendation TEXT NOT NULL
);

-- create table hypotheses
CREATE TABLE hypotheses (
    id SERIAL PRIMARY KEY,
    bug_id INTEGER NOT NULL REFERENCES bugs(id) ON DELETE CASCADE,
    parent_id INTEGER REFERENCES hypotheses(id),
    template_id INTEGER REFERENCES hypothesis_template(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    hyp_status VARCHAR(30) NOT NULL DEFAULT 'OPEN' CHECK (hyp_status IN ('OPEN', 'SUPPORTED', 'REJECTED', 'INCONCLUSIVE', 'CONFIRMED')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- create table rules
CREATE TABLE rules (
    id SERIAL PRIMARY KEY,
    template_id INTEGER NOT NULL REFERENCES hypothesis_template(id) ON DELETE CASCADE,
    match_field TEXT NOT NULL CHECK (match_field IN ('error_code', 'category', 'error_message')),
    match_value TEXT NOT NULL,
    match_type TEXT NOT NULL DEFAULT 'EQUALS' CHECK (match_type IN ('EQUALS', 'CONTAINS')),
    weight INTEGER NOT NULL CHECK (weight BETWEEN 1 AND 10)
);

-- UNIQUE constraint for rules table
ALTER TABLE rules
ADD CONSTRAINT unique_rule
UNIQUE (template_id, match_field, match_value, match_type);