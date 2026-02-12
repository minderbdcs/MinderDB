SET TERM ^ ;

ALTER PROCEDURE PC_WMAR (RECORD_ID INTEGER,
WH_ID CHAR(2),
LOCN_ID VARCHAR(10),
OBJECT VARCHAR(30),
TRN_TYPE VARCHAR(4),
TRN_CODE CHAR(1),
TRN_DATE TIMESTAMP,
REFERENCE VARCHAR(40),
QTY INTEGER,
PERSON_ID VARCHAR(10),
DEVICE_ID CHAR(2),
SUBLOCN_ID VARCHAR(10))
AS 
 
   
           
  DECLARE VARIABLE SSN_EXIST INTEGER; 
  DECLARE VARIABLE PARENT_SSN VARCHAR(22);
  DECLARE VARIABLE strAUDIT_DESC VARCHAR(50);
  
BEGIN
   SSN_EXIST = 0;
   PARENT_SSN = :WH_ID || :LOCN_ID || :SUBLOCN_ID;     
  
   /* Check SSN */
   SELECT 1
   FROM SSN
   WHERE SSN_ID = :OBJECT
   INTO :SSN_EXIST;

   /* If SSN does not exists, then exit */
   IF (SSN_EXIST = 0) THEN
   BEGIN
       /* Update transactions table */        
       EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'SSN is not in the database');
       EXIT;         
   END
   ELSE
   BEGIN
      /* Update Parent SSN */
      UPDATE SSN
      SET PARENT_SSN_ID = :PARENT_SSN
      WHERE SSN_ID = :OBJECT;

      /* Update transactions table */        
      EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');

      strAUDIT_DESC = 'Add parent barcode ' || :PARENT_SSN;
      /* Add transaction history */                                                                                     
      EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :OBJECT, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                                     :strAUDIT_DESC, :REFERENCE, :QTY, :PERSON_ID, :DEVICE_ID);

   END

   SUSPEND;
END ^

ALTER PROCEDURE TRAN_ARCHIVE AS 
 
      
BEGIN
  
  /* Add record to TRANSACTIONS_ARCHIVE table first */

  INSERT INTO TRANSACTIONS_ARCHIVE 
     (WH_ID, LOCN_ID, OBJECT, TRN_TYPE, TRN_CODE, TRN_DATE, REFERENCE,
      QTY, ERROR_TEXT, INSTANCE_ID, EXPORTED, SUB_LOCN_ID, INPUT_SOURCE,
      PERSON_ID, DEVICE_ID)
       
  SELECT WH_ID, LOCN_ID, OBJECT, TRN_TYPE, TRN_CODE, TRN_DATE, REFERENCE,
      QTY, ERROR_TEXT, INSTANCE_ID, EXPORTED, SUB_LOCN_ID, INPUT_SOURCE,
      PERSON_ID, DEVICE_ID 
  FROM TRANSACTIONS
  WHERE COMPLETE = 'T';
  
  /* Delete records from TRANSACTIONS table with COMPLETE is True */
  DELETE FROM TRANSACTIONS
  WHERE COMPLETE = 'T'; 
  
END ^

