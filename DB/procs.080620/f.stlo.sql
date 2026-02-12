COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;
 

ALTER PROCEDURE PC_STLO (RECORD_ID INTEGER,
WH_ID CHAR(2) CHARACTER SET NONE,
LOCN_ID VARCHAR(10) CHARACTER SET NONE,
DEVICE VARCHAR(10) CHARACTER SET NONE,
TRN_DATE TIMESTAMP)
AS 
DECLARE VARIABLE LOCN_EXIST INTEGER;
  DECLARE VARIABLE WH_EXIST INTEGER;    
  DECLARE VARIABLE LOCN_NAME VARCHAR(50); 
  DECLARE VARIABLE LOCN_STAT CHAR(2); 
  DECLARE VARIABLE LOCN_OWNER VARCHAR(10); 
  DECLARE VARIABLE COUNT_ISSN_IN_LOCN INTEGER;

BEGIN
  LOCN_EXIST = 0;   
  WH_EXIST = 0;
  COUNT_ISSN_IN_LOCN = 0;
  LOCN_NAME = LEFTS(LOCN_ID || ' Created during audit ' || :TRN_DATE,50);

  /* Check if Location exists */
  LOCN_EXIST = 0;
  SELECT 1,LOCN_STAT,LOCN_OWNER
  FROM LOCATION
  WHERE WH_ID = :WH_ID
  AND LOCN_ID = :LOCN_ID 
  INTO :LOCN_EXIST, :LOCN_STAT, :LOCN_OWNER;  
  
  
  /* Location exists, then update transaction and Last_Audited */
  IF (LOCN_EXIST <> 0) THEN
  BEGIN  
       IF (LOCN_STAT = 'OK') THEN
       BEGIN

            /* TRACK 216
            ASK GLEN if WHERE CLAUSE RELATED TO AUDIT IS NOT NULL CORRECT? BECAUSE I BELIEVE
            THAT if (AUDIT IS NOT NULL) then THE ISSN IS UNDERGOING SOME AUDIT PROCESS AND HENCE SHOULD
            NOT BE CONSIDERED. REFER THIS TO GLEN... */
              SELECT COUNT(*) FROM ISSN
              WHERE WH_ID = :WH_ID
              AND   LOCN_ID = :LOCN_ID
              INTO :COUNT_ISSN_IN_LOCN;
              
               
               UPDATE ISSN
               SET AUDITED = 'M', AUDIT_DATE = :TRN_DATE
               WHERE WH_ID = :WH_ID
               AND LOCN_ID = :LOCN_ID;
               
               /* END OF TRACK 216 */
       
              /* Update Last_Audited in LOCATION table */
              UPDATE LOCATION
              SET LAST_AUDITED_DATE = :TRN_DATE,
                  LOCN_STAT = 'ST',
                  LOCN_OWNER = :DEVICE
              WHERE WH_ID = :WH_ID
              AND LOCN_ID = :LOCN_ID;
              
                             /* Update transactions table */
               UPDATE TRANSACTIONS
               SET COMPLETE = 'T', ERROR_TEXT = 'Processed successfully' || '|' || :COUNT_ISSN_IN_LOCN || '|'
               WHERE RECORD_ID = :RECORD_ID;

       END
       ELSE
       BEGIN
               IF (LOCN_STAT = 'ST' AND LOCN_OWNER = DEVICE) THEN
               BEGIN
                  /* TRACK 216
            ASK GLEN if WHERE CLAUSE RELATED TO AUDIT IS NOT NULL CORRECT? BECAUSE I BELIEVE
            THAT if (AUDIT IS NOT NULL) then THE ISSN IS UNDERGOING SOME AUDIT PROCESS AND HENCE SHOULD
            NOT BE CONSIDERED. REFER THIS TO GLEN... */
            
            /* I THINK THERE COULD BE A CASE WHERE IN THE LOCN_STAT = 'ST' AND USER TRIES TO INITIATE STOCK TAKE AGAIN
            MAYBE MORE RECORDS HAVE BEEN ADDED TO THE LOCN BY THEN.. AND THIS TIME EVEN THOUGH THE STATUS IS OF THE LOCATION IS UNDER STOCKTAKE
            WE WOULD LIKE TO UPDATE THE PENDING ISSN WITH AUDITED = 'M' AS PER GLENS 216 TRACK NUMBER */

              SELECT COUNT(*) FROM ISSN
              WHERE WH_ID = :WH_ID
              AND   LOCN_ID = :LOCN_ID
              AND   AUDITED = 'M'
              INTO :COUNT_ISSN_IN_LOCN;


/*
               UPDATE ISSN
               SET AUDITED = 'M', AUDIT_DATE = :TRN_DATE
               WHERE WH_ID = :WH_ID
               AND LOCN_ID = :LOCN_ID;
*/

               /* END OF TRACK 216 */
                       /* Update transactions table */
                       UPDATE TRANSACTIONS
                       SET COMPLETE = 'T', ERROR_TEXT = 'Processed successfully'
                       || '|'  || :COUNT_ISSN_IN_LOCN || '|'
                       WHERE RECORD_ID = :RECORD_ID; 
               END
               ELSE
               BEGIN
                       /* Update transactions table */
                       UPDATE TRANSACTIONS
                       SET COMPLETE = 'F', ERROR_TEXT = 'Cannot Stocktake - Not an Open Location'
                       WHERE RECORD_ID = :RECORD_ID; 
       
               END
       END
  END
  ELSE
  BEGIN
        /* Check WH_ID */     
       WH_EXIST = 0;
       SELECT 1 
       FROM WAREHOUSE
       WHERE WH_ID = :WH_ID       
       INTO :WH_EXIST; 

       IF (WH_EXIST <> 0) THEN
       BEGIN
              /* Add new Location record */
              INSERT INTO LOCATION (LOCN_ID, WH_ID, LOCN_NAME, LAST_AUDITED_DATE,LOCN_STAT,LOCN_OWNER)
              VALUES (:LOCN_ID, :WH_ID, :LOCN_NAME, :TRN_DATE,'ST',:DEVICE);

              /* Update transactions table */
              UPDATE TRANSACTIONS
              SET COMPLETE = 'T', ERROR_TEXT = 'New location created'
              WHERE RECORD_ID = :RECORD_ID; 
       END
       ELSE
       BEGIN
              /* Update transactions table */
              UPDATE TRANSACTIONS
              SET COMPLETE = 'F', ERROR_TEXT = 'Warehouse master not found'
              WHERE RECORD_ID = :RECORD_ID;
       END    
  END
END ^

ALTER PROCEDURE PC_STLX (RECORD_ID INTEGER,
WH_ID CHAR(2) CHARACTER SET NONE,
LOCN_ID VARCHAR(10) CHARACTER SET NONE,
DEVICE VARCHAR(10) CHARACTER SET NONE,
TRN_DATE TIMESTAMP)
AS 
           
  DECLARE VARIABLE LOCN_EXIST INTEGER; 
  DECLARE VARIABLE WH_EXIST INTEGER;    
  DECLARE VARIABLE LOCN_STAT CHAR(2); 
  DECLARE VARIABLE LOCN_OWNER VARCHAR(10); 
  DECLARE VARIABLE WK_WH_ID CHAR(2); 
  DECLARE VARIABLE WK_LOCN_ID VARCHAR(10); 
  DECLARE VARIABLE WK_USER VARCHAR(10); 
  DECLARE VARIABLE WK_ISSN_SSN VARCHAR(20); 
  DECLARE VARIABLE WK_ISSN_COMPANY_ID VARCHAR(20); 
  DECLARE VARIABLE WK_ISSN_QTY INTEGER; 
  DECLARE VARIABLE WK_ISSN_VARIANCE INTEGER; 
  DECLARE VARIABLE WK_NEW_RECORD_ID INTEGER; 
  DECLARE VARIABLE WK_TRN_TYPE VARCHAR(4); 
  DECLARE VARIABLE WK_TRN_CODE CHAR(1); 
  DECLARE VARIABLE WK_UPDATED CHAR(1); 

BEGIN
  LOCN_EXIST = 0;   
  WH_EXIST = 0;
  LOCN_OWNER = DEVICE;
  WK_USER = '';
  WK_TRN_CODE = '';
  WK_TRN_TYPE = '';
  WK_UPDATED = 'F';

  SELECT  PERSON_ID, TRN_TYPE, TRN_CODE 
  FROM TRANSACTIONS
  WHERE RECORD_ID = :RECORD_ID 
  INTO :WK_USER, :WK_TRN_TYPE, :WK_TRN_CODE;
  /* Check if Location exists */


  /* try the passed location */
  LOCN_EXIST = 0;
  FOR SELECT 1,LOCN_STAT,WH_ID,LOCN_ID
  FROM LOCATION
  WHERE WH_ID = :WH_ID AND LOCN_ID = :LOCN_ID
  INTO :LOCN_EXIST, :LOCN_STAT, :WK_WH_ID, :WK_LOCN_ID
  DO
  BEGIN
  
          IF (:LOCN_STAT IS NULL) THEN 
          BEGIN
             LOCN_STAT = '';
          END
          /* Location exists, then update transaction and Last_Audited */
          IF (LOCN_STAT = 'ST') THEN
          BEGIN
                  /* Update transactions table */
                  IF (WK_TRN_TYPE = 'STLX') THEN
                  BEGIN
                     UPDATE TRANSACTIONS
                     SET COMPLETE = 'T', 
                         ERROR_TEXT = 'Processed successfully',
                         WH_ID = :WK_WH_ID,
                         LOCN_ID = :WK_LOCN_ID
                     WHERE RECORD_ID = :RECORD_ID ;
                     WK_UPDATED = 'T';
                  END
                  ELSE
                  BEGIN
                     INSERT INTO TRANSACTIONS_ARCHIVE
                        (WH_ID, LOCN_ID, OBJECT, TRN_TYPE, TRN_CODE, TRN_DATE, REFERENCE,
                         QTY, ERROR_TEXT, INSTANCE_ID, EXPORTED, SUB_LOCN_ID, INPUT_SOURCE,
                         PERSON_ID, DEVICE_ID)
       
                     SELECT :WK_WH_ID, :WK_LOCN_ID, OBJECT, TRN_TYPE, TRN_CODE, TRN_DATE, REFERENCE,
                         QTY, 'Processed successfully', INSTANCE_ID, EXPORTED, SUB_LOCN_ID, INPUT_SOURCE,
                         PERSON_ID, DEVICE_ID 
                      FROM TRANSACTIONS
                      WHERE RECORD_ID = :RECORD_ID;
                      WK_UPDATED = 'T';
                  END
               
                 /* Update Last_Audited in LOCATION table */
                 UPDATE LOCATION
                 SET LOCN_STAT = 'OK',
                     LOCN_OWNER = ''
                 WHERE WH_ID = :WK_WH_ID
                 AND LOCN_ID = :WK_LOCN_ID;
                 /* want to add stocktake records for all 'M' audit issns for the location */
                 FOR SELECT SSN_ID, COMPANY_ID, CURRENT_QTY
                 FROM ISSN
                 WHERE WH_ID = :WK_WH_ID
                 AND LOCN_ID = :WK_LOCN_ID
                 AND AUDITED = 'M'
                 INTO :WK_ISSN_SSN, :WK_ISSN_COMPANY_ID, :WK_ISSN_QTY
                 DO
                 BEGIN
                    WK_ISSN_VARIANCE = 0 - WK_ISSN_QTY;
                    SELECT NEW_RECORD_ID FROM ADD_UPDATE_STOCKTAKE (
                       0, :WK_ISSN_SSN, :WK_WH_ID, :WK_LOCN_ID, 0, :WK_ISSN_VARIANCE , :TRN_DATE, :WK_USER, :DEVICE, 'MI', 'RC', NULL, NULL, NULL,:WK_ISSN_COMPANY_ID )
                    INTO :WK_NEW_RECORD_ID;
                 END
          END
          ELSE
          BEGIN
                  /* Update transactions table */
/*
                  UPDATE TRANSACTIONS
                  SET COMPLETE = 'F', ERROR_TEXT = 'Cannot Close Stocktake - Not being Stocktaked'
                  WHERE RECORD_ID = :RECORD_ID; 
*/
                  EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'Cannot Close Stocktake - Not being Stocktaked');
                  WK_UPDATED = 'T';
               
          END
  END

  /* now   do the locations owned by this device */
  LOCN_EXIST = 0;
  FOR SELECT 1,LOCN_STAT,WH_ID,LOCN_ID
  FROM LOCATION
  WHERE LOCN_OWNER = :DEVICE
  INTO :LOCN_EXIST, :LOCN_STAT, :WK_WH_ID, :WK_LOCN_ID
  DO
  BEGIN
  
          IF (:LOCN_STAT IS NULL) THEN 
          BEGIN
             LOCN_STAT = '';
          END
          /* Location exists, then update transaction and Last_Audited */
          IF (LOCN_STAT = 'ST') THEN
          BEGIN
                  /* Update transactions table */
                  IF (WK_TRN_TYPE = 'STLX') THEN
                  BEGIN
                     UPDATE TRANSACTIONS
                     SET COMPLETE = 'T', 
                         ERROR_TEXT = 'Processed successfully',
                         WH_ID = :WK_WH_ID,
                         LOCN_ID = :WK_LOCN_ID
                     WHERE RECORD_ID = :RECORD_ID ;
                     WK_UPDATED = 'T';
                  END
                  ELSE
                  BEGIN
                     INSERT INTO TRANSACTIONS_ARCHIVE
                        (WH_ID, LOCN_ID, OBJECT, TRN_TYPE, TRN_CODE, TRN_DATE, REFERENCE,
                         QTY, ERROR_TEXT, INSTANCE_ID, EXPORTED, SUB_LOCN_ID, INPUT_SOURCE,
                         PERSON_ID, DEVICE_ID)
       
                     SELECT :WK_WH_ID, :WK_LOCN_ID, OBJECT, TRN_TYPE, TRN_CODE, TRN_DATE, REFERENCE,
                         QTY, 'Processed successfully', INSTANCE_ID, EXPORTED, SUB_LOCN_ID, INPUT_SOURCE,
                         PERSON_ID, DEVICE_ID 
                      FROM TRANSACTIONS
                      WHERE RECORD_ID = :RECORD_ID;
                      WK_UPDATED = 'T';
                  END
               
                 /* Update Last_Audited in LOCATION table */
                 UPDATE LOCATION
                 SET LOCN_STAT = 'OK',
                     LOCN_OWNER = ''
                 WHERE WH_ID = :WK_WH_ID
                 AND LOCN_ID = :WK_LOCN_ID;
                 /* want to add stocktake records for all 'M' audit issns for the location */
                 FOR SELECT SSN_ID, COMPANY_ID, CURRENT_QTY
                 FROM ISSN
                 WHERE WH_ID = :WK_WH_ID
                 AND LOCN_ID = :WK_LOCN_ID
                 AND AUDITED = 'M'
                 INTO :WK_ISSN_SSN, :WK_ISSN_COMPANY_ID, :WK_ISSN_QTY
                 DO
                 BEGIN
                    WK_ISSN_VARIANCE = 0 - WK_ISSN_QTY;
                    SELECT NEW_RECORD_ID FROM ADD_UPDATE_STOCKTAKE (
                       0, :WK_ISSN_SSN, :WK_WH_ID, :WK_LOCN_ID, 0, :WK_ISSN_VARIANCE , :TRN_DATE, :WK_USER, :DEVICE, 'MI', 'RC', NULL, NULL, NULL,:WK_ISSN_COMPANY_ID )
                    INTO :WK_NEW_RECORD_ID;
                 END
          END
          ELSE
          BEGIN
                  /* Update transactions table */
/*
                  UPDATE TRANSACTIONS
                  SET COMPLETE = 'F', ERROR_TEXT = 'Cannot Close Stocktake - Not being Stocktaked'
                  WHERE RECORD_ID = :RECORD_ID; 
*/
                  EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'Cannot Close Stocktake - Not being Stocktaked');
                  WK_UPDATED = 'T';
               
          END
  END
  IF (WK_UPDATED = 'F') THEN
  BEGIN
     EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'Nothing Closed');
  END
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
