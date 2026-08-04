-- Eclipse Realms - Database Schema (PostgreSQL Production)
-- This file initializes the production database

CREATE TABLE IF NOT EXISTS players (
    id SERIAL PRIMARY KEY,
    peer_id INTEGER UNIQUE NOT NULL,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT,
    email TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    level INTEGER DEFAULT 1,
    experience INTEGER DEFAULT 0,
    gold INTEGER DEFAULT 0,
    health INTEGER DEFAULT 100,
    max_health INTEGER DEFAULT 100,
    mana INTEGER DEFAULT 50,
    max_mana INTEGER DEFAULT 50,
    attack INTEGER DEFAULT 10,
    defense INTEGER DEFAULT 5,
    position_x REAL DEFAULT 300.0,
    position_y REAL DEFAULT 360.0,
    species TEXT DEFAULT 'human',
    appearance JSONB,
    inventory JSONB DEFAULT '[]'::jsonb,
    equipment JSONB DEFAULT '{}'::jsonb,
    active_quests JSONB DEFAULT '[]'::jsonb,
    completed_quests JSONB DEFAULT '[]'::jsonb
);

CREATE TABLE IF NOT EXISTS sessions (
    session_token TEXT PRIMARY KEY,
    player_id INTEGER REFERENCES players(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_players_username ON players(username);
CREATE INDEX idx_sessions_token ON sessions(session_token);
CREATE INDEX idx_sessions_expires ON sessions(expires_at);

-- World state table for dynamic world events
CREATE TABLE IF NOT EXISTS world_state (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Guilds table
CREATE TABLE IF NOT EXISTS guilds (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    leader_id INTEGER REFERENCES players(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    member_count INTEGER DEFAULT 1
);

-- Guild members junction table
CREATE TABLE IF NOT EXISTS guild_members (
    guild_id INTEGER REFERENCES guilds(id) ON DELETE CASCADE,
    player_id INTEGER REFERENCES players(id) ON DELETE CASCADE,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    role TEXT DEFAULT 'member',
    PRIMARY KEY (guild_id, player_id)
);

-- Chat log (for moderation and replay)
CREATE TABLE IF NOT EXISTS chat_log (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER REFERENCES players(id),
    channel TEXT DEFAULT 'global',
    message TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_sent_at ON chat_log(sent_at);
CREATE INDEX idx_chat_channel ON chat_log(channel);
