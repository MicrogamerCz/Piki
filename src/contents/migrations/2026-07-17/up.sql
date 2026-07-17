--- SPDX-License-Identifier: GPL-3.0-or-later
--- SPDX-FileCopyrightText: 2026 Micro <microgamercz@proton.me>

ALTER TABLE accounts ADD is_primary INTEGER DEFAULT 0;

-- Changing tags_history
CREATE TABLE IF NOT EXISTS tags_history_update (
    tag_id INTEGER,
    user_id INTEGER,
    frequency INTEGER DEFAULT 1,
    PRIMARY KEY(tag_id, user_id),
    FOREIGN KEY(tag_id) REFERENCES tags(id),
    FOREIGN KEY(user_id) REFERENCES accounts(id)
);

INSERT INTO tags_history_update (tag_id, user_id, frequency)
SELECT * FROM tags_history;

DROP TABLE tags_history;

ALTER TABLE tags_history_update RENAME TO tags_history;
