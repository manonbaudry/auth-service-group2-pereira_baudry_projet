CREATE TABLE "Member"
(
    id UUID PRIMARY KEY NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL,
    hash TEXT NOT NULL,
    username TEXT
);

ALTER TABLE "Member"
ADD role string;