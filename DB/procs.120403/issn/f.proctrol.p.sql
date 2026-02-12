CREATE PROCEDURE PC_QTY_TROL_TRIL_P (RECORD_ID INTEGER,
WH_ID CHAR(2) ,
LOCN_ID VARCHAR(10) ,
PREV_LOCN_ID VARCHAR(10) ,
PROD_ID VARCHAR(30) ,
TRN_TYPE VARCHAR(4) ,
REFERENCE VARCHAR(40) ,
QTY INTEGER,
PERSON_ID VARCHAR(10) ,
DEVICE_ID CHAR(2) )
RETURNS (PROCESS_OK CHAR(1) )
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
     IF (:TRN_TYPE = 'TRIL') THEN
     BEGIN
       SELECT SSN_ID
       FROM SSN
       WHERE PROD_ID = :PROD_ID
       AND AUDIT_DATE = (
         SELECT MIN(LAST_UPDATE_DATE)
         FROM SSN
         WHERE PROD_ID = :PROD_ID
         )       
       INTO :strSSN;
       
       IF (strSSN = '') THEN
       BEGIN
          /* Update transactions table */        
   EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'SSN is not in the database');
          EXIT;
       END     
       ELSE IF (strSSN <> '') THEN
       BEGIN
         /* Update Current_Qty */
         EXECUTE PROCEDURE UPDATE_SSN_QTY_TROL (:strSSN, :QTY);
       
         /* Update transactions table */               
         EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');
                    
         PROCESS_OK = 'T';
       END       
     END /* TRN_TYPE = 'TRIL' */    
     
     ELSE     
     
     IF (:TRN_TYPE = 'TROL') THEN
     BEGIN
       iSUB_QTY = (-1) * :QTY;
       iCURRENT_QTY = -1;
       strISSN_STATUS = '';
       strISSN_STATUS_CODE = ''; 
       
       SELECT SSN_ID, CURRENT_QTY, STATUS_SSN, STATUS_CODE
       FROM SSN
       WHERE PROD_ID = :PROD_ID
       AND AUDIT_DATE = (
                SELECT MIN(LAST_UPDATE_DATE)
                FROM SSN
                WHERE PROD_ID = :REFERENCE
                )       
       INTO :strSSN, :iCURRENT_QTY, :strISSN_STATUS, :strISSN_STATUS_CODE;
       
       IF (strSSN = '') THEN
       BEGIN
          /* Update transactions table */        
          EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'SSN is not in the database');
          EXIT;
       END            
       ELSE IF (strSSN <> '') THEN
       BEGIN
          IF (:QTY < :iCURRENT_QTY) THEN
   BEGIN
      /* Add new record to ISSN table */
      EXECUTE PROCEDURE ADD_ISSN (:strSSN, :WH_ID, :LOCN_ID,
                           :PREV_LOCN_ID, :iCURRENT_QTY, :QTY, 'NOW', 
                           :strISSN_STATUS, :strISSN_STATUS_CODE, 'NOW', :PERSON_ID, :PROD_ID, 1 ); 
                                         
      /* Update Current_Qty */
      EXECUTE PROCEDURE UPDATE_SSN_QTY_TROL (:strSSN, :iSUB_QTY);
         
   END   
   ELSE IF (:QTY >= :iCURRENT_QTY) THEN   
   BEGIN
      /* Update SSN */ 
      EXECUTE PROCEDURE UPDATE_SSN_TROL_A (:strSSN, :WH_ID, :PREV_LOCN_ID, 'NOW', :DEVICE_ID);      
          END                       
              
          /* Update transactions table */               
          EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');
                           
          PROCESS_OK = 'T';
       END
     
     END /* TRN_TYPE = 'TROL' */
     
   END /* ELSE */
    
   SUSPEND;
END ^

