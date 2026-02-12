/*
ALTER  PROCEDURE PC_STLX (RECORD_ID INTEGER,
*/
CREATE PROCEDURE PC_STLX (RECORD_ID INTEGER,
WH_ID CHAR(2) ,
LOCN_ID VARCHAR(10) ,
DEVICE VARCHAR(10) ,
TRN_DATE TIMESTAMP)
AS 
 
 
           
  DECLARE VARIABLE LOCN_EXIST INTEGER; 
  DECLARE VARIABLE WH_EXIST INTEGER;    
  DECLARE VARIABLE LOCN_STAT CHAR(2); 
  DECLARE VARIABLE LOCN_OWNER VARCHAR(10); 
  DECLARE VARIABLE WK_WH_ID CHAR(2); 
  DECLARE VARIABLE WK_LOCN_ID VARCHAR(10); 

BEGIN
  LOCN_EXIST = 0;   
  WH_EXIST = 0;
  LOCN_OWNER = DEVICE;

  /* Check if Location exists */
  LOCN_EXIST = 0;
  FOR SELECT 1,LOCN_STAT,WH_ID,LOCN_ID
  FROM LOCATION
  WHERE LOCN_OWNER = :DEVICE
  INTO :LOCN_EXIST, :LOCN_STAT, :WK_WH_ID, :WK_LOCN_ID
  DO
  BEGIN
  
          /* Location exists, then update transaction and Last_Audited */
          IF (LOCN_STAT = 'ST') THEN
          BEGIN
                  /* Update transactions table */
                  UPDATE TRANSACTIONS
                  SET COMPLETE = 'T', ERROR_TEXT = 'Processed successfully'
                  WHERE RECORD_ID = :RECORD_ID; 
               
                 /* Update Last_Audited in LOCATION table */
                 UPDATE LOCATION
                 SET LOCN_STAT = 'OK',
                     LOCN_OWNER = ''
                 WHERE WH_ID = :WK_WH_ID
                 AND LOCN_ID = :WK_LOCN_ID;
          END
          ELSE
          BEGIN
                  /* Update transactions table */
                  UPDATE TRANSACTIONS
                  SET COMPLETE = 'F', ERROR_TEXT = 'Cannot Close Stocktake - Not being Stocktaked'
                  WHERE RECORD_ID = :RECORD_ID; 
               
          END
  END
END ^

