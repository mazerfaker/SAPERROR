CREATE TABLE IF NOT EXISTS sessions (
 id TEXT PRIMARY KEY,
 version TEXT NOT NULL,
 mode TEXT NOT NULL,
 difficulty INTEGER NOT NULL,
 seconds INTEGER NOT NULL,
 wins INTEGER NOT NULL,
 losses INTEGER NOT NULL,
 sector INTEGER NOT NULL,
 started INTEGER NOT NULL,
 updated INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS sessions_updated ON sessions(updated);
