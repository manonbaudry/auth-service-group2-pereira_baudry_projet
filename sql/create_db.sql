CREATE TABLE "Member"
(
    id UUID PRIMARY KEY NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL,
    hash TEXT NOT NULL,
    username TEXT
);

INSERT INTO "Member" (id, email, role, hash) 
VALUES ("09ee2832-6aea-4163-acc4-442a80472171", "announcer@test.com", "announcer", "$2y$06$TEfjGEXnalLyGFPjZg/rYO0rgaxI262qZksbJJfpcJkDdmdYEnWKS");

INSERT INTO "Member" (id, email, role, hash) 
VALUES ("09ee2832-6aea-4163-acc4-442a80472189", "member@test.com", "member", "$2y$06$TEfjGEXnalLyGFPjZg/rYO0rgaxI262qZksbJJfpcJkDdmdYEnWKS");