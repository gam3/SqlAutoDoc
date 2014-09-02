# @title Foreign Key Constraints

h1. Foreign Key Constraints Information

h2. PostgreSql

h2. mySql

h2. Sqlite3

For sqlite3 we use the _table_info_ _PRAGMA_ to get the column information

  PRAGMA foreign_key_list(table-name);

This pragma returns one row for each column in the named table. Columns in the result set include the column name, data type, whether or not the column can be NULL, and the default value for the column. The "pk" column in the result set is zero for columns that are not part of the primary key, and is the index of the column in the primary key for columns that are part of the primary key.

._PRAGMA_ _foreign_key_list(table-name)_ columns

  ["id", "seq", "table", "from", "to", "on_update", "on_delete", "match"]

