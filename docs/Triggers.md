# markup redcarpet
# @title Trigger Overview

h1. Trigger Overview

Tags represent meta-data as well as behavioural data that can be added to
documentation through the `@tag` style syntax. As mentioned, there are two
basic types of tags in YARD, "meta-data tags" and "behavioural tags", the
latter is more often known as "directives". These two tag types can be
visually identified by their prefix. Meta-data tags have a `@` prefix,
while directives have a prefix of `@!` to indicate that the directive
performs some potentially mutable action on or with the docstring. The
two tag types would be used in the following way, respectively:

@markup textile

| a | a | c |
|---|---|---|
| a | a | c |

@markup markdown

Text with a link to some reference[#mylabel]

This document describes how tags can be specified, how they affect your
documentation, and how to use specific built-in tags in YARD, as well
as how to define custom tags.

note#mylabel Explanation as an auto-numbered endnote


h2. Meta-Data Tags

Text with a link to some reference[1]

fn1. Footnote explanation

h3. MySQL _INFORMATION_SCHEMA.TRIGGERS_ Table

|_. INFORMATION_SCHEMA Name|_. SHOW Name|_. Remarks|
|TRIGGER_CATALOG| |NULL|
|TRIGGER_SCHEMA| | |
|TRIGGER_NAME|Trigger| |
|EVENT_MANIPULATION|Event| |
|EVENT_OBJECT_CATALOG| |NULL|
|EVENT_OBJECT_SCHEMA| | |
|EVENT_OBJECT_TABLE|Table| |
|ACTION_ORDER| |0|
|ACTION_CONDITION| |NULL|
|ACTION_STATEMENT|Statement| |
|ACTION_ORIENTATION| |ROW|
|ACTION_TIMING|Timing| |
|ACTION_REFERENCE_OLD_TABLE| |NULL|
|ACTION_REFERENCE_NEW_TABLE| |NULL|
|ACTION_REFERENCE_OLD_ROW| |OLD|
|ACTION_REFERENCE_NEW_ROW| |NEW|
|CREATED| |NULL (0)|
|SQL_MODE| |MySQL extension|
|DEFINER| |MySQL extension|

h3. PostgreSQL Information Schema Triggers Column

|_. Name|_. Data Type|_. Description|
|trigger_catalog|sql_identifier|Name of the database that contains the trigger (always the current database)|
|trigger_schema|sql_identifier|Name of the schema that contains the trigger|
|trigger_name|sql_identifier|Name of the trigger|
|event_manipulation|character_data|Event that fires the trigger (INSERT, UPDATE, or DELETE)|
|event_object_catalog|sql_identifier|Name of the database that contains the table that the trigger is defined on (always the current database)|
|event_object_schema|sql_identifier|Name of the schema that contains the table that the trigger is defined on|
|event_object_table|sql_identifier|Name of the table that the trigger is defined on|
|action_order|cardinal_number|Not yet implemented|
|action_condition|character_data|WHEN condition of the trigger, null if none (also null if the table is not owned by a currently enabled role)|
|action_statement|character_data|Statement that is executed by the trigger (currently always EXECUTE PROCEDURE function(...))|
|action_orientation|character_data|Identifies whether the trigger fires once for each processed row or once for each statement (ROW or STATEMENT)|
|action_timing|character_data|Time at which the trigger fires (BEFORE, AFTER, or INSTEAD OF)|
|action_reference_old_table|sql_identifier|Applies to a feature not available in PostgreSQL|
|action_reference_new_table|sql_identifier|Applies to a feature not available in PostgreSQL|
|action_reference_old_row|sql_identifier|Applies to a feature not available in PostgreSQL|
|action_reference_new_row|sql_identifier|Applies to a feature not available in PostgreSQL|
|created|time_stamp|Applies to a feature not available in PostgreSQL|

h3. Sqlite3

    select * from sqlite_master where type in ('trigger')


First Header  | Second Header
------------- | -------------
Content Cell  | Content Cell
Content Cell  | Content Cell
