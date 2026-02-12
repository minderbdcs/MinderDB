SET TERM ^ ;

CREATE PROCEDURE PC_QTY_TROL_TRIL_P (RECORD_ID INTEGER,
WH_ID CHAR(2),
LOCN_ID VARCHAR(10),
PREV_WH_ID CHAR(2),
PREV_LOCN_ID VARCHAR(10),
PROD_ID VARCHAR(30),
TRN_TYPE VARCHAR(4),
REFERENCE VARCHAR(40),
QTY INTEGER,
PERSON_ID VARCHAR(10),
DEVICE_ID CHAR(2))
RETURNS (PROCESS_OK CHAR(1))
AS 
 
        

  DECLARE VARIABLE PROD_EXIST INTEGER;
  DECLARE VARIABLE strSSN VARCHAR(20); 
  DECLARE VARIABLE iSUB_QTY INTEGER;
  DECLARE VARIABLE iCURRENT_QTY INTEGER;
  DECLARE VARIABLE strISSN_STATUS CHAR(2);
  DECLARE VARIABLE strISSN_STATUS_CODE VARCHAR(10);

BEGIN

   PROD_EXIST = 0;
   strSSN = '';   
   PROCESS_OK = 'F';
   
   /* Check PROD_ID in SSN */                                                                      
   SELECT COUNT(1)
   FROM SSN
   WHERE PROD_ID = :PROD_ID
   INTO :PROD_EXIST;
   
   /* PROD_ID not exist, then exit */
   IF (PROD_EXIST = 0) THEN
   BEGIN
      /* Update transactions table */        
      EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'PROD_ID is not in the SSN table');
      EXIT;   
   END
   
   ELSE
   
   BEGIN
       iSUB_QTY = (-1) * :QTY;
       iCURRENT_QTY = -1;
       strISSN_STATUS = '';
       strISSN_STATUS_CODE = ''; 
       
       /* must select upto qty from location where prod=prod 
           i.e while picking last update date for issn imove issn */
       FOR SELECT SSN_ID, CURRENT_QTY, ISSN_STATUS, STATUS_CODE
       FROM ISSN
       WHERE PROD_ID = :PROD_ID 
         AND WH_ID = :PREV_WH_ID
         AND LOCN_ID = :PREV_LOCN_ID
         ORDER BY INTO_DATE 
       INTO :strSSN, :iCURRENT_QTY, :strISSN_STATUS, :strISSN_STATUS_CODE
       DO
       BEGIN
          IF (iSUB_QTY < 0) THEN
          BEGIN
             /* Update SSN */ 
             EXECUTE PROCEDURE UPDATE_SSN_TROL_A (:strSSN, :WH_ID, :PREV_LOCN_ID, 'NOW', :DEVICE_ID);      
             iSUB_QTY = iSUB_QTY + iCURRENT_QTY;    
          END
       END
       IF (iSUB_QTY = - QTY) THEN
       BEGIN
          /* Update transactions table */        
          EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'SSN is not in the database');
          EXIT;
       END            
       EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');
       PROCESS_OK = 'T';
     
   END /* ELSE */
    
   SUSPEND;
END ^

