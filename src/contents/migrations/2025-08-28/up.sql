--- SPDX-License-Identifier: GPL-3.0-or-later
--- SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

CREATE TABLE IF NOT EXISTS accounts (
    id INTEGER PRIMARY KEY,
    name TEXT,
    account TEXT,
    pfp TEXT
);
CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    translated TEXT
);
CREATE TABLE IF NOT EXISTS tags_history (
    tag_id INTEGER PRIMARY KEY,
    user_id INTEGER,
    frequency INTEGER DEFAULT 1,
    FOREIGN KEY(tag_id) REFERENCES tags(id),
    FOREIGN KEY(user_id) REFERENCES accounts(id)
);
