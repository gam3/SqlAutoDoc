# @title Table

h1. Table

SELECT table_comment 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE table_schema='my_cool_database' 
        AND table_name='user_skill';


h2. Sqlite3

    PRAGMA table_info(album)
    ["cid", "name", "type", "notnull", "dflt_value", "pk"]

