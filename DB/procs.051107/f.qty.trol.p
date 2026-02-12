
ALTER PROCEDURE PC_QTY_TROL_TRIL_P (RECORD_ID INTEGER,
WH_ID CHAR(2) ,
LOCN_ID VARCHAR(10) ,
PREV_LOCN_ID VARCHAR(10) ,
PROD_ID VARCHAR(30) ,
TRN_TYPE VARCHAR(4) ,
REFERENCE VARCHAR(40) ,
QTY INTEGER,
PERSON_ID VARCHAR(10) ,
DEVICE_ID CHAR(2) ,
TRN_CODE CHAR(1) ,
TRN_DATE TIMESTAMP ,
HIST_DESC VARCHAR(70) )
RETURNS (PROCESS_OK CHAR(1) )
AS 
 

  DECLARE VARIABLE PROD_EXIST INTEGER;
  DECLARE VARIABLE strSSN VARCHAR(20); 
  DECLARE VARIABLE strOrigSSN VARCHAR(20); 
  DECLARE VARIABLE iSUB_QTY INTEGER;
  DECLARE VARIABLE iSUB_QTY_WK INTEGER;
  DECLARE VARIABLE iCURRENT_QTY INTEGER;
  DECLARE VARIABLE strISSN_STATUS CHAR(2);
  DECLARE VARIABLE strISSN_STATUS_CODE VARCHAR(10);
  DECLARE VARIABLE strPREV_LOCN VARCHAR(10);
  DECLARE VARIABLE WK_NEW_SSN VARCHAR(20); 

BEGIN

   PROD_EXIST = 0;
   strSSN = '';   
   PROCESS_OK = 'F';
   
   /* Check PROD_ID in SSN */                                                                      
   SELECT FIRST 1 1
   FROM ISSN
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
       /* must transfer QTY of product (object)
          from location LOCN_ID (= device)
          to location (WH_ID and PREV_LOCN)
       */
       
       iSUB_QTY =  :QTY;
       iCURRENT_QTY = -1;
       strISSN_STATUS = '';
       
       SELECT SUM(CURRENT_QTY)  
       FROM ISSN
       WHERE PROD_ID = :PROD_ID
       AND LOCN_ID = :LOCN_ID
       AND CURRENT_QTY <> 0
       INTO :iCURRENT_QTY; 
       IF (iCURRENT_QTY IS NULL) THEN
       BEGIN
          iCURRENT_QTY = 0;
       END
       IF (iCURRENT_QTY = 0) THEN
       BEGIN
          /* Update transactions table */        
          EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'None of Product found in Location');
          EXIT;
       END            
       ELSE
       BEGIN
          IF (iCURRENT_QTY < QTY) THEN
          BEGIN
             /* Update transactions table */        
             EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'Not Enough Product is in the Location');
             EXIT;
          END            
          ELSE 
          BEGIN
             /* want qty to take */
             FOR SELECT SSN_ID, CURRENT_QTY, ISSN_STATUS, ORIGINAL_SSN, STATUS_CODE, PREV_LOCN_ID 
             FROM ISSN
             WHERE PROD_ID = :PROD_ID
             AND LOCN_ID = :LOCN_ID
             AND CURRENT_QTY <> 0
             INTO :strSSN, :iCURRENT_QTY, :strISSN_STATUS, :strOrigSSN, :strISSN_STATUS_CODE , :strPREV_LOCN
             DO
             BEGIN
                IF (iSUB_QTY > 0) THEN
                BEGIN
                   IF (:iSUB_QTY < :iCURRENT_QTY) THEN
                   BEGIN
                      /* must do a split and take this newer issn */
                      /* Add new record to ISSN table */
                      EXECUTE PROCEDURE ADD_ISSN (:strOrigSSN, :WH_ID, :PREV_LOCN_ID, :strPREV_LOCN,
                                 iSUB_QTY, 0, 'NOW', 
                                 :strISSN_STATUS, :strISSN_STATUS_CODE, 'NOW', :PERSON_ID, :PROD_ID, 1 ); 
                                               
                      SELECT MAX(SSN_ID) 
                      FROM ISSN 
                      WHERE ORIGINAL_SSN = :strOrigSSN AND 
                         WH_ID = :WH_ID AND 
                         LOCN_ID = :PREV_LOCN_ID AND 
                         CURRENT_QTY = :iSUB_QTY
                      INTO :WK_NEW_SSN;
                      /* Update Current_Qty */
                      iSUB_QTY_WK = 0 - iSUB_QTY;
                      EXECUTE PROCEDURE UPDATE_SSN_QTY_TROL (:strSSN, :iSUB_QTY_WK);
                      EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :PREV_LOCN_ID, :WK_NEW_SSN, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                              :HIST_DESC, :REFERENCE, :iSUB_QTY,  :PERSON_ID, :DEVICE_ID);
                      iSUB_QTY = 0;
                   END   
                   ELSE IF (:iSUB_QTY >= :iCURRENT_QTY) THEN   
                   BEGIN
                      /* take all of this issn */
                      /* Update SSN */ 
                      EXECUTE PROCEDURE UPDATE_SSN_TROL_A (:strSSN, :WH_ID, :PREV_LOCN_ID, 'NOW', :DEVICE_ID);      
                      iSUB_QTY = iSUB_QTY - iCURRENT_QTY;
                      EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :PREV_LOCN_ID, :strSSN, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                              :HIST_DESC, :REFERENCE, :iCURRENT_QTY,  :PERSON_ID, :DEVICE_ID);
                   END                       
                END /* end of is qty positive */                       
             END /* end for */
                 
             /* Update transactions table */               
             EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');
             PROCESS_OK = 'T';
                    
          END /* end else */
       END  /* end else */      
     END /* TRN_TYPE = 'TRIL' */    
     
     ELSE     
     
     IF (:TRN_TYPE = 'TROL') THEN
     BEGIN
       iSUB_QTY =  :QTY;
       iCURRENT_QTY = -1;
       strISSN_STATUS = '';
       
       SELECT SUM(CURRENT_QTY)  
       FROM ISSN
       WHERE PROD_ID = :PROD_ID
       AND WH_ID = :PREV_LOCN_ID
       AND LOCN_ID = :LOCN_ID
       AND CURRENT_QTY <> 0
       INTO :iCURRENT_QTY; 
       IF (iCURRENT_QTY IS NULL) THEN
       BEGIN
          iCURRENT_QTY = 0;
       END
       IF (iCURRENT_QTY = 0) THEN
       BEGIN
          /* Update transactions table */        
          EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'None of Product found in Location');
          EXIT;
       END            
       ELSE
       BEGIN
          IF (iCURRENT_QTY < QTY) THEN
          BEGIN
             /* Update transactions table */        
             EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'Not Enough Product is in the Location');
             EXIT;
          END            
          ELSE 
          BEGIN
             /* want qty to take */
             FOR SELECT SSN_ID, CURRENT_QTY, ISSN_STATUS, ORIGINAL_SSN, STATUS_CODE 
             FROM ISSN
             WHERE PROD_ID = :PROD_ID
             AND WH_ID = :PREV_LOCN_ID
             AND LOCN_ID = :LOCN_ID
             AND CURRENT_QTY <> 0
             INTO :strSSN, :iCURRENT_QTY, :strISSN_STATUS, :strOrigSSN, :strISSN_STATUS_CODE 
             DO
             BEGIN
                IF (iSUB_QTY > 0) THEN
                BEGIN
                   IF (:iSUB_QTY < :iCURRENT_QTY) THEN
                   BEGIN
                      /* must do a split and take this newer issn */
                      /* Add new record to ISSN table */
                      EXECUTE PROCEDURE ADD_ISSN (:strOrigSSN, :WH_ID, :DEVICE_ID, :LOCN_ID,
                                 iSUB_QTY, 0, 'NOW', 
                                 :strISSN_STATUS, :strISSN_STATUS_CODE, 'NOW', :PERSON_ID, :PROD_ID, 1 ); 
                                               
                      SELECT MAX(SSN_ID) 
                      FROM ISSN 
                      WHERE ORIGINAL_SSN = :strOrigSSN AND 
                         WH_ID = :WH_ID AND 
                         LOCN_ID = :DEVICE_ID AND 
                         CURRENT_QTY = :iSUB_QTY
                      INTO :WK_NEW_SSN;
                      /* Update Current_Qty */
                      iSUB_QTY_WK = 0 - iSUB_QTY;
                      EXECUTE PROCEDURE UPDATE_SSN_QTY_TROL (:strSSN, :iSUB_QTY_WK);
                      EXECUTE PROCEDURE ADD_SSN_HIST(:PREV_LOCN_ID, :LOCN_ID, :WK_NEW_SSN, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                              :HIST_DESC, :REFERENCE, :iSUB_QTY,  :PERSON_ID, :DEVICE_ID);
                      iSUB_QTY = 0;
                   END   
                   ELSE IF (:iSUB_QTY >= :iCURRENT_QTY) THEN   
                   BEGIN
                      /* take all of this issn */
                      /* Update SSN */ 
                      EXECUTE PROCEDURE UPDATE_SSN_TROL_A (:strSSN, :WH_ID, :LOCN_ID, 'NOW', :DEVICE_ID);      
                      iSUB_QTY = iSUB_QTY - iCURRENT_QTY;
                      EXECUTE PROCEDURE ADD_SSN_HIST(:PREV_LOCN_ID, :LOCN_ID, :strSSN, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                              :HIST_DESC, :REFERENCE, :iCURRENT_QTY,  :PERSON_ID, :DEVICE_ID);
                   END                       
                END /* end of is qty positive */                       
             END /* end for */
          
                 
             /* Update transactions table */               
             EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');
                              
             PROCESS_OK = 'T';
          END
       END
     
     END /* TRN_TYPE = 'TROL' */
     
   END /* ELSE */
    
   SUSPEND;
END ^

