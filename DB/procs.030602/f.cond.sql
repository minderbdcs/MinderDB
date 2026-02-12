ALTER PROCEDURE PC_ADD_PROD_COND_STATUS (RECORD_ID INTEGER,
WH_ID CHAR(2),
LOCN_ID VARCHAR(10),
OBJECT VARCHAR(30),
TRN_TYPE VARCHAR(4),
TRN_CODE CHAR(1),
TRN_DATE TIMESTAMP,
REFERENCE VARCHAR(40),
QTY INTEGER,
PERSON_ID VARCHAR(10),
DEVICE_ID CHAR(2))
AS 
 
 
  
      
  DECLARE VARIABLE REC_EXIST INTEGER; 
  DECLARE VARIABLE CODE CHAR(1);
  DECLARE VARIABLE strAUDIT_DESC VARCHAR(50);

BEGIN
  REC_EXIST = 0;
  CODE = ''; 

  /* Assign CODE value */
  IF (:TRN_TYPE = 'NIAP') THEN
  BEGIN
     CODE = 'A';
     strAUDIT_DESC = 'Add Appearance: ' || :REFERENCE;
  END
  ELSE IF (:TRN_TYPE = 'NIOP') THEN
  BEGIN
     CODE = 'B';
     strAUDIT_DESC = 'Add Operating: ' || :REFERENCE;
  END
  ELSE IF (:TRN_TYPE = 'NICP') THEN
  BEGIN
     CODE = 'C';
     strAUDIT_DESC = 'Add Completeness: ' || :REFERENCE;
  END   
  ELSE IF (:TRN_TYPE = 'NIDP') THEN
  BEGIN
     CODE = 'D';
     strAUDIT_DESC = 'Add Service: ' || :REFERENCE;
  END   
  ELSE IF (:TRN_TYPE = 'NIEP') THEN
  BEGIN
     CODE = 'E';
     strAUDIT_DESC = 'Add Other 5 Condition: ' || :REFERENCE;
  END   
  
  /* Check if record exists */
  SELECT 1
  FROM PRODUCT_COND_STATUS
  WHERE SSN_ID = :OBJECT
  AND CODE = :CODE
  AND DESCRIPTION = :REFERENCE  
  AND ORIGINAL_TEST = 'S'  
  INTO :REC_EXIST;  

  /* if record not exists then insert */
  IF (REC_EXIST = 0) THEN
  BEGIN     
    INSERT INTO PRODUCT_COND_STATUS (SSN_ID, CODE, DESCRIPTION, ORIGINAL_TEST)
    VALUES (:OBJECT, :CODE, :REFERENCE, 'S');  
    
    /* Add transaction history */                                                                                     
    EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :OBJECT, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                                   :strAUDIT_DESC, :REFERENCE, :QTY, :PERSON_ID, :DEVICE_ID);           
  END

  /* Update transactions table */        
  EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');

END ^

