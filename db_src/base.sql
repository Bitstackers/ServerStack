INSERT INTO users (id, name, extension, send_from)
VALUES (1,  'System', 0, 'noreply@example.org');

INSERT INTO groups (id, name)
VALUES (1, 'Receptionist'),
       (2, 'Administrator'),
       (3, 'Service agent');

INSERT INTO reception_dialplans (extension, dialplan) VALUES('empty','{"open":[],"note":"","active":true,"closed":[],"extraExtensions":[]}');


-- POSTGRES ONLY
SELECT setval('users_id_sequence', (SELECT max(id)+1 FROM users), FALSE);
SELECT setval('groups_id_sequence', (SELECT max(id)+1 FROM groups), FALSE);

