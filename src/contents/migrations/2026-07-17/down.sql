--- SPDX-License-Identifier: GPL-3.0-or-later
--- SPDX-FileCopyrightText: 2026 Micro <microgamercz@proton.me>

ALTER TABLE accounts DROP is_primary;

-- Changing tags_history
CREATE TABLE IF NOT EXISTS tags_history_downgrade (
    tag_id INTEGER PRIMARY KEY,
    user_id INTEGER,
    frequency INTEGER DEFAULT 1,
    FOREIGN KEY(tag_id) REFERENCES tags(id),
    FOREIGN KEY(user_id) REFERENCES accounts(id)
);

INSERT INTO tags_history_downgrade (tag_id, user_id, frequency)
SELECT * FROM tags_history;

DROP TABLE tags_history;
ALTER TABLE tags_history_downgrade RENAME TO tags_history;
