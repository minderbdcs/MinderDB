SET TERM ^ ;

ALTER  PROCEDURE PC_TRMI (RECORD_ID INTEGER,
WH_ID CHAR(2),
LOCN_ID VARCHAR(10),
SUBLOCN_ID VARCHAR(10),
OBJECT VARCHAR(30),
TRN_TYPE VARCHAR(4),
TRN_CODE CHAR(1),
TRN_DATE TIMESTAMP,
REFERENCE VARCHAR(40),
QTY INTEGER,
PERSON_ID VARCHAR(10),
DEVICE_ID CHAR(2))
AS 
 
                                                    
      
  DECLARE VARIABLE strWH_ID CHAR(2);
  DECLARE VARIABLE strLOCN_ID VARCHAR(10);
  DECLARE VARIABLE str_mobile_WH_ID CHAR(2);
  DECLARE VARIABLE str_orig_mobile_WH_ID CHAR(2);
  DECLARE VARIABLE str_mobile_LOCN_ID VARCHAR(10);
  DECLARE VARIABLE str_OBJECT VARCHAR(20);
  DECLARE VARIABLE strAUDIT_DESC VARCHAR(70);
  DECLARE VARIABLE LOCN_NAME VARCHAR(50); 
  DECLARE VARIABLE str_last_parent_LOCN_ID varchar(10);
  DECLARE VARIABLE str_parent_LOCN_ID varchar(10);
  DECLARE VARIABLE int_updated INTEGER;
       
BEGIN
  
  strAUDIT_DESC = ''; 
    
  IF (:TRN_TYPE = 'TRMI') THEN
  BEGIN       
     /* 
	move mobile location to be a son of location
	and update wh_id of mobile location and goods within
     */
     /* Check too location exists */
     /* else create the new location */

     strWH_ID = '';
     strLOCN_ID = '';
    
     /* Check too location */
     SELECT LOCN_ID, WH_ID 
     FROM LOCATION
     WHERE LOCN_ID = :LOCN_ID
       AND WH_ID = :WH_ID
     INTO :strLOCN_ID, :strWH_ID; 

     IF (strLOCN_ID = '') THEN /* Location not found */
     BEGIN
        LOCN_NAME = 'Created during Mobile Transfer ' || :TRN_DATE;
        /* Add new Location record */
        INSERT INTO LOCATION (LOCN_ID, WH_ID, LOCN_NAME , LAST_UPDATE_DATE, LAST_UPDATE_BY )
        VALUES (:LOCN_ID, :WH_ID, :LOCN_NAME, :TRN_DATE, :PERSON_ID);

     END
     /* get current wh_id for mobile */
     str_mobile_WH_ID = '';
     str_orig_mobile_WH_ID = '';
     str_orig_mobile_WH_ID = substr(SUBLOCN_ID, 1,2);
     str_mobile_LOCN_ID = substr(SUBLOCN_ID, 3,strlen(SUBLOCN_ID) - 2);
     FOR SELECT WH_ID
         FROM LOCATION 
         WHERE LOCN_ID = :str_mobile_LOCN_ID
           AND ORIG_WH_ID = :str_orig_mobile_WH_ID
         INTO :str_mobile_WH_ID 
     DO
     BEGIN
        /* for all ssn's in mobile update the wh_id */
        UPDATE SSN
           SET WH_ID = :WH_ID      
           WHERE WH_ID = :str_mobile_WH_ID
             AND LOCN_ID = :str_mobile_LOCN_ID;
        UPDATE ISSN
           SET WH_ID = :WH_ID      
           WHERE WH_ID = :str_mobile_WH_ID
             AND LOCN_ID = :str_mobile_LOCN_ID;
	   
        /* update the mobiles wh_id */
        UPDATE LOCATION
           SET WH_ID = :WH_ID , 
               PARENT_LOCN_ID = :LOCN_ID,      
               LAST_UPDATE_DATE = :TRN_DATE,    
               LAST_UPDATE_BY = :PERSON_ID    
           WHERE WH_ID = :str_mobile_WH_ID
             AND LOCN_ID = :str_mobile_LOCN_ID;
     END

     str_last_parent_LOCN_ID = str_mobile_LOCN_ID;
     int_updated = 1;
     WHILE (int_updated = 1) DO
     BEGIN
        int_updated = 0;
        FOR SELECT LOCN_ID
            FROM LOCATION 
            WHERE PARENT_LOCN_ID = :str_last_parent_LOCN_ID
              AND WH_ID = :str_mobile_WH_ID
            INTO :str_parent_LOCN_ID
        DO
        BEGIN
           /* for all ssn's in mobile update the wh_id */
           UPDATE SSN
              SET WH_ID = :WH_ID      
              WHERE WH_ID = :str_mobile_WH_ID
                AND LOCN_ID = :str_parent_LOCN_ID;
           UPDATE ISSN
              SET WH_ID = :WH_ID      
              WHERE WH_ID = :str_mobile_WH_ID
                AND LOCN_ID = :str_parent_LOCN_ID;
   	   
           /* update the mobiles wh_id */
           UPDATE LOCATION
              SET WH_ID = :WH_ID , 
                  LAST_UPDATE_DATE = :TRN_DATE,    
                  LAST_UPDATE_BY = :PERSON_ID    
              WHERE WH_ID = :str_mobile_WH_ID
                AND LOCN_ID = :str_parent_LOCN_ID;
           int_updated = 1;    
        END
        str_last_parent_LOCN_ID = str_parent_LOCN_ID;
     END

     /* Update transactions table */               
     EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');

  END /* TRN_TYPE = 'TRMI' */
      

END ^

