-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS chat;
CREATE SCHEMA IF NOT EXISTS assist;
CREATE SCHEMA IF NOT EXISTS infra;
CREATE SCHEMA IF NOT EXISTS ops;

-- Chat schema tables
CREATE TABLE IF NOT EXISTS chat.rooms (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS chat.messages (
    id SERIAL PRIMARY KEY,
    room_id INTEGER REFERENCES chat.rooms(id),
    role VARCHAR(50) NOT NULL, -- user, assistant, system
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    langfuse_trace_id VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS chat.embeddings (
    id SERIAL PRIMARY KEY,
    message_id INTEGER REFERENCES chat.messages(id),
    embedding vector(1536), -- OpenAI/similar embedding size
    model VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS chat.tool_calls (
    id SERIAL PRIMARY KEY,
    message_id INTEGER REFERENCES chat.messages(id),
    tool_name VARCHAR(100) NOT NULL,
    tool_input JSONB NOT NULL,
    tool_output JSONB,
    status VARCHAR(20) DEFAULT 'pending', -- pending, success, error
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    langfuse_trace_id VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS chat.artifacts (
    id SERIAL PRIMARY KEY,
    message_id INTEGER REFERENCES chat.messages(id),
    artifact_type VARCHAR(50), -- file, image, document, etc.
    artifact_url TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Assist schema tables
CREATE TABLE IF NOT EXISTS assist.accounts (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS assist.emails (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES assist.accounts(id),
    subject TEXT,
    content TEXT,
    sender VARCHAR(255),
    received_at TIMESTAMP,
    processed_at TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS assist.calls (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES assist.accounts(id),
    call_type VARCHAR(50), -- incoming, outgoing
    duration INTEGER, -- seconds
    transcript TEXT,
    occurred_at TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);

-- Infra schema tables
CREATE TABLE IF NOT EXISTS infra.configs (
    id SERIAL PRIMARY KEY,
    key VARCHAR(255) UNIQUE NOT NULL,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ops schema tables
CREATE TABLE IF NOT EXISTS ops.server_events (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    service_name VARCHAR(100),
    description TEXT,
    metadata JSONB DEFAULT '{}',
    langfuse_trace_id VARCHAR(255),
    occurred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_messages_room_id ON chat.messages(room_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON chat.messages(created_at);
CREATE INDEX IF NOT EXISTS idx_embeddings_message_id ON chat.embeddings(message_id);
CREATE INDEX IF NOT EXISTS idx_tool_calls_message_id ON chat.tool_calls(message_id);
CREATE INDEX IF NOT EXISTS idx_tool_calls_status ON chat.tool_calls(status);
CREATE INDEX IF NOT EXISTS idx_server_events_type ON ops.server_events(event_type);
CREATE INDEX IF NOT EXISTS idx_server_events_service ON ops.server_events(service_name);

-- Sample data
INSERT INTO chat.rooms (name, description) VALUES 
    ('General', 'General chat room'),
    ('Development', 'Development discussions');

INSERT INTO assist.accounts (email, name) VALUES 
    ('user@gmail.com', 'Admin User');