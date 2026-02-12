SET TERM ^ ;

ALTER PROCEDURE PC_AULO (RECORD_ID INTEGER,
WH_ID CHAR(2),
LOCN_ID VARCHAR(10),
TRN_DATE TIMESTAMP)
AS 
 
           
  DECLARE VARIABLE LOCN_EXIST INTEGER; 
  DECLARE VARIABLE WH_EXIST INTEGER;    
  DECLARE VARIABLE LOCN_NAME VARCHAR(50); 
BEGIN
  LOCN_EXIST = 0;   
  WH_EXIST = 0;
  LOCN_NAME = "Created during audit " || :TRN_DATE;

  /* Check if Location exists */
  LOCN_EXIST = 0;
  SELECT 1 
  FROM LOCATION
  WHERE WH_ID = :WH_ID
  AND LOCN_ID = :LOCN_ID 
  INTO :LOCN_EXIST;  
  
  /* Location exists, then update transaction and Last_Audited */
  IF (LOCN_EXIST <> 0) THEN
  BEGIN  
        /* Update transactions table */
        UPDATE TRANSACTIONS
        SET COMPLETE = 'T', ERROR_TEXT = 'Processed successfully'
        WHERE RECORD_ID = :RECORD_ID; 

       /* Update Last_Audited in LOCATION table */
       UPDATE LOCATION
       SET LAST_AUDITED_DATE = :TRN_DATE
       WHERE WH_ID = :WH_ID
       AND LOCN_ID = :LOCN_ID;
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
              INSERT INTO LOCATION (LOCN_ID, WH_ID, LOCN_NAME, LAST_AUDITED_DATE)
              VALUES (:LOCN_ID, :WH_ID, :LOCN_NAME, :TRN_DATE);

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

