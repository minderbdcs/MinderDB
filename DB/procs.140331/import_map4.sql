/* 
current import_map table
RECORD_ID                       (RECORD_ID) INTEGER Not Null 
MAP_TYPE                        CHAR(1) Not Null 
MAP_IMPORT_PATH                 (FILESYSTEM_PATH) VARCHAR(80) Nullable 
MAP_IMPORT_FILENAME             VARCHAR(50) Not Null 
MAP_IMPORT_SHEET                VARCHAR(40) Not Null 
MAP_IMPORT_COL                  VARCHAR(30) Not Null 
MAP_IMS_SEQUENCE                (SEQUENCE_NO) INTEGER Nullable DEFAULT 0
MAP_IMS_TABLE                   VARCHAR(40) Not Null 
MAP_IMS_FIELDNAME               VARCHAR(40) Not Null 
MAP_IMS_FIELDTYPE               INTEGER Nullable 
MAP_IMS_FORMAT                  VARCHAR(40) Not Null 
CREATED_BY                      (PERSON) VARCHAR(10) Nullable 
CREATED_DATE                    TIMESTAMP Nullable 
MAP_IMS_PREFIX                  VARCHAR(40) Nullable 
MAP_IMS_SUFFIX                  VARCHAR(40) Nullable 
MAP_IMS_DEFAULT                 VARCHAR(40) Nullable 
MAP_IMS_FIND                    VARCHAR(40) Nullable 
MAP_IMS_REPLACE                 VARCHAR(40) Nullable 
MAP_IMS_DATA_ID                 (CODE_128) VARCHAR(128) Nullable 
CONSTRAINT RECRD_ID:
  Primary key (RECORD_ID)
new layout from Glen
  RECORD_ID            RECORD_ID NOT NULL,
  IMPORT_RULES_NAME    VARCHAR(20) NOT NULL,
  MAP_IMPORT_COL       VARCHAR(30) NOT NULL,
  MAP_IMS_SEQUENCE     SEQUENCE_NO DEFAULT 0,
  MAP_IMS_TABLE        VARCHAR(40) NOT NULL,
  MAP_IMS_FIELDNAME    VARCHAR(40) NOT NULL,
  MAP_IMS_FIELDTYPE    INTEGER,
  MAP_IMS_FORMAT       VARCHAR(40) NOT NULL,
  MAP_IMS_SUFFIX       VARCHAR(40),
  MAP_IMS_PREFIX       VARCHAR(40),
  MAP_IMS_FIND         VARCHAR(40),
  MAP_IMS_REPLACE      VARCHAR(40),
  CREATED_BY           PERSON,
  CREATED_DATE         TIMESTAMP,
  MAP_IMS_DEFAULT      VARCHAR(40),
  MAP_IMS_DATA_ID      CODE_128,
  CONSTRAINT RECRD_ID
    PRIMARY KEY (IMPORT_RULES_NAME)
*/

alter table import_map drop MAP_IMPORT_PATH ;               
alter table import_map drop MAP_IMPORT_FILENAME ;               
alter table import_map drop MAP_IMPORT_SHEET    ;               

alter table import_map alter map_type to IMPORT_RULES_NAME   ;               
alter table import_map alter IMPORT_RULES_NAME TYPE RULES_NAME  ;               
alter table import_map drop  constraint recrd_id ;
alter table import_map add constraint rules_name primary key (import_rules_name);

CREATE UNIQUE INDEX IMPORT_MAP_RECORD_IDX ON  IMPORT_MAP(RECORD_ID);
