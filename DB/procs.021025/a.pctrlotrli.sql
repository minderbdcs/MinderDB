SET TERM ^ ;

CREATE PROCEDURE PC_TRLO_TRLI (RECORD_ID INTEGER,
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
  DECLARE VARIABLE strOBJECT VARCHAR(20);
       
BEGIN
  
  strAUDIT_DESC = ""; 
    
  IF (:TRN_TYPE = 'TRLO') THEN
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
        SSN_EXIST = 0;
        iCURRENT_QTY = -1; 

        /* Check SSN */
        FOR
           SELECT  SSN_ID, CURRENT_QTY
           FROM ISSN
           WHERE LOCN_ID = :LOCN_ID 
             AND WH_ID = :WH_ID
           INTO :strOBJECT, :iCURRENT_QTY
        DO
        BEGIN
                
           SSN_EXIST = 1;
	   /* must transfer all of qty always */
           /* Update SSN */ 
           EXECUTE PROCEDURE UPDATE_SSN_TROL_A (:strOBJECT, :strWH_ID, :LOCN_ID, :TRN_DATE, :DEVICE_ID);

           strAUDIT_DESC = "Transfered all qty  " || :iCURRENT_QTY || " into transit location"; 
           /* Add transaction history */                                                                                     
           EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :strOBJECT, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                                          :strAUDIT_DESC, :REFERENCE, :QTY,  :PERSON_ID, :DEVICE_ID);
        END /* for */

        /* SSN not exists, then exit */
        IF (SSN_EXIST = 0) THEN
        BEGIN 
          /* Update transactions table */        
          EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'SSN is not in the database');
          EXIT;
        END 
        /* Update transactions table */               
        EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');

     END  /* else */
  END /* TRN_TYPE = 'TRLO' */
      
  ELSE IF (:TRN_TYPE = 'TRLI') THEN
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
        SSN_EXIST = 0;
        iCURRENT_QTY = -1; 
        iSUB_QTY = (-1) * :QTY;

        /* Check SSN */
        FOR
           SELECT  SSN_ID, CURRENT_QTY
           FROM ISSN
           WHERE LOCN_ID = :LOCN_ID 
             AND WH_ID = :WH_ID
           INTO :strOBJECT, :iCURRENT_QTY
        DO
        BEGIN
                
           SSN_EXIST = 1;
	   /* must transfer all of qty always */
           /* Update SSN */ 
           EXECUTE PROCEDURE UPDATE_SSN_TRIL_A (:strOBJECT, :WH_ID, :LOCN_ID, :TRN_DATE, :QTY);          

           strAUDIT_DESC = "Transfered all qty  " || :iCURRENT_QTY || " into " || :LOCN_ID; 
           /* Add transaction history */                                                                                     
           EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :strOBJECT, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                                          :strAUDIT_DESC, :REFERENCE, :QTY,  :PERSON_ID, :DEVICE_ID);
        END /* for */
     END /* else */
  END /* TRN_TYPE = 'TRLI' */

  SUSPEND;  
END ^

