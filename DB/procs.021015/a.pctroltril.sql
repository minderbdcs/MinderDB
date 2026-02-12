SET TERM ^ ;

CREATE PROCEDURE PC_TROL_TRIL (RECORD_ID INTEGER,
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
 
                                                    
      
  DECLARE VARIABLE SSN_EXIST INTEGER;
  DECLARE VARIABLE strWH_ID CHAR(2);
  DECLARE VARIABLE strLOCN_ID VARCHAR(10);
  DECLARE VARIABLE strAUDIT_DESC VARCHAR(70);
  DECLARE VARIABLE iCURRENT_QTY INTEGER;
  DECLARE VARIABLE iSUB_QTY INTEGER;
  DECLARE VARIABLE PROCESS_OK CHAR(1);
  DECLARE VARIABLE strISSN_STATUS CHAR(2);
  DECLARE VARIABLE strISSN_STATUS_CODE VARCHAR(10);
  DECLARE VARIABLE strPROD_ID VARCHAR(30);
  DECLARE VARIABLE intPRODisNULL INTEGER;
       
BEGIN
  
  strAUDIT_DESC = ""; 
    
  IF (:TRN_TYPE = 'TROL') THEN
  BEGIN       
     strWH_ID = "";
     strLOCN_ID = "";
    
     /* Check transit location */
     SELECT LOCN_ID, WH_ID 
     FROM LOCATION
     WHERE LOCN_ID = :DEVICE_ID
     INTO :strLOCN_ID, :strWH_ID; 

     IF (strLOCN_ID = "") THEN /* Transit Location not found */
     BEGIN
        /* Update transactions table */        
        EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'Transit Location not found');
        EXIT;
     END
     ELSE
     BEGIN                         
       IF (:TRN_CODE = 'A') THEN
       BEGIN
           SSN_EXIST = 0;
           iCURRENT_QTY = -1; 
           iSUB_QTY = (-1) * :QTY;
           strISSN_STATUS = '';
           strISSN_STATUS_CODE = '';

           /* Check SSN */
/*
           SELECT 1, CURRENT_QTY, STATUS_SSN, STATUS_CODE, PROD_ID
           FROM SSN
           WHERE SSN_ID = :OBJECT
           INTO :SSN_EXIST, :iCURRENT_QTY, :strISSN_STATUS, :strISSN_STATUS_CODE, :strPROD_ID intPRODisNULL;
*/
           SELECT 1, CURRENT_QTY, ISSN_STATUS, STATUS_CODE, PROD_ID
           FROM ISSN
           WHERE SSN_ID = :OBJECT
           INTO :SSN_EXIST, :iCURRENT_QTY, :strISSN_STATUS, :strISSN_STATUS_CODE, :strPROD_ID ;
                
           /* SSN not exists, then exit */
           IF (SSN_EXIST = 0) THEN
           BEGIN 
             /* Update transactions table */        
             EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'SSN is not in the database');
             EXIT;
           END 

           IF (:QTY < :iCURRENT_QTY) THEN
           BEGIN
               /* Add new record to ISSN table */
/*
               EXECUTE PROCEDURE ADD_ISSN (:OBJECT, :strWH_ID, :LOCN_ID,
                        :strLOCN_ID, :iCURRENT_QTY, :QTY, :TRN_DATE, 
                        :strISSN_STATUS, :strISSN_STATUS_CODE, 'now', :PERSON_ID, :strPROD_ID,:intPRODisNULL); 
*/
               EXECUTE PROCEDURE ADD_ISSN (:OBJECT, :strWH_ID, :strLOCN_ID, 
			:LOCN_ID, :iCURRENT_QTY, :QTY, :TRN_DATE, 
                        :strISSN_STATUS, :strISSN_STATUS_CODE, 'NOW', :PERSON_ID, :strPROD_ID); 
                                      
               /* Update Current_Qty */
               EXECUTE PROCEDURE UPDATE_SSN_QTY_TROL (:OBJECT, :iSUB_QTY);

               strAUDIT_DESC = "Transfered partial qty " || :QTY || " into transit location"; 
           END
           ELSE IF (:QTY >= :iCURRENT_QTY) THEN
           BEGIN
               /* Update SSN */ 
               EXECUTE PROCEDURE UPDATE_SSN_TROL_A (:OBJECT, :strWH_ID, :strLOCN_ID, :TRN_DATE, :DEVICE_ID);

               strAUDIT_DESC = "Transfered all qty  " || :QTY || " into transit location"; 
           END

           /* Update transactions table */               
           EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');

           /* Add transaction history */                                                                                     
           EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :OBJECT, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                                          :strAUDIT_DESC, :REFERENCE, :QTY,  :PERSON_ID, :DEVICE_ID);
       END /* TRN_CODE = 'A' */
       
       ELSE IF (:TRN_CODE = 'P') THEN
       BEGIN
          PROCESS_OK = 'F';
          
          EXECUTE PROCEDURE PC_QTY_TROL_TRIL_P (:RECORD_ID, :strWH_ID, :LOCN_ID, :strLOCN_ID,
                                         :OBJECT, :TRN_TYPE, :REFERENCE, :QTY, :PERSON_ID, :DEVICE_ID) 
                         RETURNING_VALUES :PROCESS_OK; 
   
   IF (PROCESS_OK = 'T') THEN
   BEGIN
       strAUDIT_DESC = "Transfered qty of " || :QTY || " into transit location"; 
       /* Add transaction history */                                                                                     
       EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :OBJECT, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                                      :strAUDIT_DESC, :REFERENCE, :QTY,  :PERSON_ID, :DEVICE_ID);
          END         
       END /* TRN_CODE = 'P' */
       
     END /* else */ 
  END /* TRN_TYPE = 'TROL' */
      
  ELSE IF (:TRN_TYPE = 'TRIL') THEN
  BEGIN
     IF (:TRN_CODE = 'A') THEN
     BEGIN
        /* Update SSN */ 
        EXECUTE PROCEDURE UPDATE_SSN_TRIL_A (:OBJECT, :WH_ID, :LOCN_ID, :TRN_DATE, :QTY);          

        /* Update transactions table */               
	/* this adds to locn a new issn */
	/* must remove this qty from issn in transit location */
        EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');

        strAUDIT_DESC = "Transfered qty of " || :QTY || " into location"; 

        /* Add transaction history */                                                                                     
        EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :OBJECT, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                                         :strAUDIT_DESC, :REFERENCE, :QTY,  :PERSON_ID, :DEVICE_ID); 
     END /* TRN_CODE = 'A' */
     
     ELSE IF (:TRN_CODE = 'P') THEN
     BEGIN
        PROCESS_OK = 'F';

        EXECUTE PROCEDURE PC_QTY_TROL_TRIL_P (:RECORD_ID, :WH_ID, :DEVICE_ID, :LOCN_ID, :OBJECT, :TRN_TYPE, :REFERENCE, :QTY, :PERSON_ID, :DEVICE_ID) 
                                               RETURNING_VALUES :PROCESS_OK; 

        IF (PROCESS_OK = 'T') THEN
        BEGIN
           strAUDIT_DESC = "Transfered qty of " || :QTY || " into location"; 
           /* Add transaction history */                                                                                     
           EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :OBJECT, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                                         :strAUDIT_DESC, :REFERENCE, :QTY,  :PERSON_ID, :DEVICE_ID);
        END 
      END /* TRN_CODE = 'P' */
  END /* TRN_TYPE = 'TRIL' */

  SUSPEND;  
END ^

