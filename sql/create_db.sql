CREATE TABLE "Member"
(
    id UUID PRIMARY KEY NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL,
    hash TEXT NOT NULL,
    username TEXT
);

UPDATE "Member"
SET (role) = "announcer"  WHERE id = "09ee2832-6aea-4163-acc4-442a80472171";
