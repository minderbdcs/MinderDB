ALTER TABLE CONTROL ADD DEFAULT_WARRANTY WARRANTY_TERM^
ALTER TABLE PICK_ORDER ADD
        APPROVED_DESP_DATE TIMESTAMP^
ALTER TABLE PICK_ORDER ADD
        APPROVED_DESP_BY PERSON^

CREATE PROCEDURE NEXT_PICK_LABEL RETURNS (LABEL_NO VARCHAR(7) )
AS 
BEGIN EXIT; END ^

ALTER PROCEDURE NEXT_PICK_LABEL RETURNS (LABEL_NO VARCHAR(7) )
AS 

DECLARE VARIABLE WK_PICK_LABEL_NO CHAR(8);
DECLARE VARIABLE WK_PICK_LABEL_START INTEGER;
DECLARE VARIABLE WK_PICK_LABEL_STOP INTEGER;
DECLARE VARIABLE WK_PICK_LABEL_PREFIX INTEGER;
DECLARE VARIABLE WK_LABEL_LENGTH INTEGER;
DECLARE VARIABLE WK_PICK_ADJUSTMENT INTEGER;
DECLARE VARIABLE WK_LEN_LABEL_NO INTEGER;
DECLARE VARIABLE WK_L_PICK_LABEL_NO  VARCHAR(7);
BEGIN
     SELECT MAX_LENGTH
     FROM PARAM
     WHERE DATA_ID = 'PICK'
     INTO :WK_LABEL_LENGTH;
     WK_PICK_LABEL_NO = GEN_ID(PICK_LABEL_GEN, 1);
     WK_PICK_LABEL_START = GEN_ID(PICK_LABEL_START, 0);
     WK_PICK_LABEL_STOP = GEN_ID(PICK_LABEL_STOP, 0);
     WK_PICK_LABEL_PREFIX = GEN_ID(PICK_LABEL_PREFIX , 0);
     IF (WK_PICK_LABEL_NO > WK_PICK_LABEL_STOP) THEN
     BEGIN
        WK_PICK_ADJUSTMENT = WK_PICK_LABEL_START - WK_PICK_LABEL_STOP;
        WK_PICK_LABEL_NO = GEN_ID(PICK_LABEL_GEN, WK_PICK_ADJUSTMENT);
        WK_PICK_LABEL_PREFIX = GEN_ID(PICK_LABEL_PREFIX , 1);
        WK_PICK_LABEL_NO = WK_PICK_LABEL_START;
     END
     WK_LEN_LABEL_NO = STRLEN(ALLTRIM(WK_PICK_LABEL_NO)) + 1;
     /* Get Label prefix */
     WK_L_PICK_LABEL_NO = chr(WK_PICK_LABEL_PREFIX);
     /* Padding leading with 0 */
     WHILE (WK_LEN_LABEL_NO < WK_LABEL_LENGTH) DO
     BEGIN
        WK_L_PICK_LABEL_NO = WK_L_PICK_LABEL_NO || '0';
        WK_LEN_LABEL_NO = WK_LEN_LABEL_NO + 1;
     END
     WK_L_PICK_LABEL_NO = WK_L_PICK_LABEL_NO || ALLTRIM(WK_PICK_LABEL_NO);
     LABEL_NO = WK_L_PICK_LABEL_NO;
     SUSPEND;
END ^

CREATE TRIGGER PICK_ITEM_BI FOR PICK_ITEM 
ACTIVE BEFORE INSERT POSITION 0 
AS
DECLARE VARIABLE LABEL_NO VARCHAR(7);
BEGIN
   IF (NEW.PICK_LABEL_NO IS NULL) THEN
   BEGIN
      EXECUTE PROCEDURE NEXT_PICK_LABEL RETURNING_VALUES :LABEL_NO;
      NEW.PICK_LABEL_NO = LABEL_NO;
   END
END ^
 
ALTER PROCEDURE GET_SALE_LINES_NO (PICK_ORDER VARCHAR(10) )
RETURNS (PICK_ORDER_LINE_NO VARCHAR(4) )
AS 

  DECLARE VARIABLE LINE_NO INTEGER; 
  DECLARE VARIABLE iLenPickLineNo INTEGER;
  DECLARE VARIABLE sPickLineNo VARCHAR(4);
BEGIN
  LINE_NO = 0;
  sPickLineNo = '';

  /* Get the maximum number of line no */
  SELECT LAST_LINE_NO + 1 AS LAST_LINE_NO
  FROM PICK_ITEM_LINE_NO
  WHERE PICK_ORDER = :PICK_ORDER  
  INTO :LINE_NO; 
  
  iLenPickLineNo = STRLEN(LINE_NO);
    
  /* Padding leading with 0 */
    WHILE (iLenPickLineNo < 4) DO
    BEGIN
       sPickLineNo = sPickLineNo || '0';      
       iLenPickLineNo = iLenPickLineNo + 1;
    END
    sPickLineNo = sPickLineNo || LINE_NO;       
    
    /* Return LoadNo to the caller */
   PICK_ORDER_LINE_NO = sPickLineNo;
   
   /* update last line no */
   UPDATE PICK_ITEM_LINE_NO
   SET LAST_LINE_NO = :LINE_NO
   WHERE PICK_ORDER = :PICK_ORDER; 
   SUSPEND;
END ^

ALTER PROCEDURE PC_NIXX_P (RECORD_ID INTEGER,
WH_ID CHAR(2) ,
LOCN_ID VARCHAR(10) ,
OBJECT VARCHAR(30) ,
TRN_TYPE VARCHAR(4) ,
TRN_CODE CHAR(1) ,
TRN_DATE TIMESTAMP,
REFERENCE VARCHAR(40) ,
QTY INTEGER,
PERSON_ID VARCHAR(10) ,
DEVICE_ID CHAR(2) ,
INSTANCE_ID VARCHAR(10) )
AS 
 
  DECLARE VARIABLE strWH_ID CHAR(2); 
  DECLARE VARIABLE strINSTANCE VARCHAR(10);
  DECLARE VARIABLE LOCN_EXIST INTEGER; 
  DECLARE VARIABLE LOCN_NAME VARCHAR(50);
  DECLARE VARIABLE SSN_EXIST INTEGER;
  DECLARE VARIABLE strAUDIT_DESC VARCHAR(50);
  DECLARE VARIABLE strSSN_ID VARCHAR(20);
  DECLARE VARIABLE strTYPE VARCHAR(40);
  
BEGIN /* Main */
    strWH_ID = "";
    strINSTANCE = "";
    LOCN_EXIST = 0;
    LOCN_NAME = "Created during audit " || :TRN_DATE;
    SSN_EXIST = 0;
    strAUDIT_DESC = ""; 

    /* Check if warehouse exists */
    SELECT WH_ID, INSTANCE_ID 
    FROM WAREHOUSE
    WHERE WH_ID = :WH_ID
    INTO :strWH_ID, :strINSTANCE;

    /* Check warehouse*/
    IF (strWH_ID = '') THEN
    BEGIN
       /* Update transactions table */               
       EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'Invalid Warehouse');
       EXIT;
    END
    ELSE
    BEGIN /* WH */
        /* Check instance */
        IF (strINSTANCE <> :INSTANCE_ID) THEN  
        BEGIN
          /* Update transactions table */               
          EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'Invalid InstanceID');
          EXIT;
        END
        ELSE
        BEGIN /* Location */
           /* Check Location */                 
           SELECT 1 
           FROM LOCATION
           WHERE WH_ID = :WH_ID
           AND LOCN_ID = :LOCN_ID 
           INTO :LOCN_EXIST; 
           
           /* Location not exists, then add new location */
           IF (LOCN_EXIST = 0) THEN
           BEGIN
              /* Add new Location record */
       INSERT INTO LOCATION (LOCN_ID, WH_ID, LOCN_NAME, LAST_AUDITED_DATE)
              VALUES (:LOCN_ID, :WH_ID, :LOCN_NAME, :TRN_DATE);
           END
                      
           IF (:TRN_TYPE <> 'NIUI') THEN
           BEGIN
              /* Check SSN */
              SELECT COUNT(*)
              FROM SSN
              WHERE PROD_ID = :OBJECT
  AND WH_ID = :WH_ID 
  AND LOCN_ID = :LOCN_ID
              INTO :SSN_EXIST;
              
              /* If SSN does not exists, then can create it */
              IF (SSN_EXIST = 0) THEN
              BEGIN
                 /* new SSN */ 
           EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'Product Not In Location - Use Asset Audit to Create');
           EXIT;
              END
              
              /* Update fields of SSN */

        FOR SELECT SSN_ID
         FROM SSN
              WHERE PROD_ID = :OBJECT
  AND WH_ID = :WH_ID 
  AND LOCN_ID = :LOCN_ID
         INTO :strSSN_ID
        DO
         BEGIN
  IF (:TRN_TYPE = 'NITP') THEN  
         BEGIN
           EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NITP', :REFERENCE);  /* Update Type */
           EXECUTE PROCEDURE ADD_MASTER_DATA(:TRN_TYPE, :TRN_DATE, :REFERENCE); 
           strAUDIT_DESC = "SSN Type was modified";
         END
         ELSE IF (:TRN_TYPE = 'NIOB') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIOB', :REFERENCE); /* Update Generic */
                  EXECUTE PROCEDURE ADD_MASTER_DATA(:TRN_TYPE, :TRN_DATE, :REFERENCE); 
                  strAUDIT_DESC = "Generic description modified";
         END
         ELSE IF (:TRN_TYPE = 'NIBC') THEN
         BEGIN
           EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIBC', :REFERENCE); /* Update Brand */
           EXECUTE PROCEDURE ADD_MASTER_DATA(:TRN_TYPE, :TRN_DATE, :REFERENCE); 
                  strAUDIT_DESC = "Brand description modified";
         END
         ELSE IF (:TRN_TYPE = 'NIMO') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIMO', :REFERENCE); /* Update Model */
                  EXECUTE PROCEDURE ADD_MASTER_DATA(:TRN_TYPE, :TRN_DATE, :REFERENCE); 
                  strAUDIT_DESC = "Model description modified";
         END
         ELSE IF (:TRN_TYPE = 'NICC') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NICC', :REFERENCE); /* Update Cost Center */
                  EXECUTE PROCEDURE ADD_MASTER_DATA(:TRN_TYPE, :TRN_DATE, :REFERENCE); 
                  strAUDIT_DESC = "Cost Center modified";
         END
         ELSE IF (:TRN_TYPE = 'NILG') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NILG', :REFERENCE); /* Update LegacyID */
                  EXECUTE PROCEDURE ADD_MASTER_DATA(:TRN_TYPE, :TRN_DATE, :REFERENCE); 
                  strAUDIT_DESC = "Legacy ID modified";
         END
         ELSE IF (:TRN_TYPE = 'PSRF') THEN
         BEGIN
           EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'PSRF', :REFERENCE); /* Update GRN */
           strAUDIT_DESC = "Product Serial Reference Number modified";
         END
         ELSE IF (:TRN_TYPE = 'NISN') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NISN', :REFERENCE); /* Update Serial Number */
                  strAUDIT_DESC = "Serial Number modified";
         END
         ELSE IF (:TRN_TYPE = 'NIO1') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO1', :REFERENCE); /* Update Other1 */
                  strAUDIT_DESC = "Custom Field 1 modified";
         END
         ELSE IF (:TRN_TYPE = 'NIO2') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO2', :REFERENCE); /* Update Other2 */
                  strAUDIT_DESC = "Custom Field 2 modified";
         END
         ELSE IF (:TRN_TYPE = 'NIO3') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO3', :REFERENCE); /* Update Other3 */
                  strAUDIT_DESC = "Custom Field 3 modified";
         END
         ELSE IF (:TRN_TYPE = 'NIO4') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO4', :REFERENCE); /* Update Other4 */
                  strAUDIT_DESC = "Custom Field 4 modified";
         END
         ELSE IF (:TRN_TYPE = 'NIO5') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO5', :REFERENCE); /* Update Other5 */
                  strAUDIT_DESC = "Custom Field 5 modified";
         END
         ELSE IF (:TRN_TYPE = 'NIO6') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO6', :REFERENCE); /* Update Other6 */
                 SELECT SSN_TYPE 
                 FROM SSN 
                 WHERE SSN_ID = :OBJECT
                 INTO :strTYPE; 
                 EXECUTE PROCEDURE ADD_GROUP_DATA('NIO6', :TRN_DATE, :REFERENCE, :strTYPE); 
                  strAUDIT_DESC = "Type Custom Field 1 modified";
         END
         ELSE IF (:TRN_TYPE = 'NIO7') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO7', :REFERENCE); /* Update Other7 */
                 SELECT SSN_TYPE 
                 FROM SSN 
                 WHERE SSN_ID = :OBJECT
                 INTO :strTYPE; 
                 EXECUTE PROCEDURE ADD_GROUP_DATA('NIO7', :TRN_DATE, :REFERENCE, :strTYPE); 
                  strAUDIT_DESC = "Type Custom Field 2 modified";
         END
         ELSE IF (:TRN_TYPE = 'NIO8') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO8', :REFERENCE); /* Update Other8 */
                 SELECT SSN_TYPE 
                 FROM SSN 
                 WHERE SSN_ID = :OBJECT
                 INTO :strTYPE; 
                 EXECUTE PROCEDURE ADD_GROUP_DATA('NIO8', :TRN_DATE, :REFERENCE, :strTYPE); 
                  strAUDIT_DESC = "Type Custom Field 3 modified";
         END
         ELSE IF (:TRN_TYPE = 'NIO9') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO9', :REFERENCE); /* Update Other9 */
                 SELECT SSN_TYPE 
                 FROM SSN 
                 WHERE SSN_ID = :OBJECT
                 INTO :strTYPE; 
                 EXECUTE PROCEDURE ADD_GROUP_DATA('NIO9', :TRN_DATE, :REFERENCE, :strTYPE); 
                  strAUDIT_DESC = "Type Custom Field 4 modified";
         END
         ELSE IF (:TRN_TYPE = 'NIOA') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIOA', :REFERENCE); /* Update Other10 */
                 SELECT SSN_TYPE 
                 FROM SSN 
                 WHERE SSN_ID = :OBJECT
                 INTO :strTYPE; 
                 EXECUTE PROCEDURE ADD_GROUP_DATA('NIOA', :TRN_DATE, :REFERENCE, :strTYPE); 
                  strAUDIT_DESC = "Type Custom Field 5 modified";
         END
         ELSE IF (:TRN_TYPE = 'NIOK') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIOK', :REFERENCE); /* Update Other19 */
                  strAUDIT_DESC = "Maintenance Support No modified";
         END
         ELSE IF (:TRN_TYPE = 'NIPC') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIPC', :REFERENCE); /* Update Product */
                  strAUDIT_DESC = "Product No modified";
         END
         ELSE IF (:TRN_TYPE = 'NIOL') THEN 
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIOL', :REFERENCE); /* Update Other20 */       
                  strAUDIT_DESC = "Other 20 modified";
         END
         ELSE IF (:TRN_TYPE = 'NIST') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIST', :REFERENCE); /* Update Status Code */
                  strAUDIT_DESC = "Status modified";
         END
         ELSE IF (:TRN_TYPE = 'NILX') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NILX', :REFERENCE); /* Update Label Location */
                  strAUDIT_DESC = "Label location modified";
         END
         ELSE IF (:TRN_TYPE = 'NIGC') THEN
         BEGIN
                  EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIGC', :REFERENCE); /* Group copy */                  
                  strAUDIT_DESC = "Copy fields from group " || :REFERENCE;
         END
         /* Add transaction history */                                                                                     
         EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :strSSN_ID, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                                              :strAUDIT_DESC, :REFERENCE, :QTY, :PERSON_ID, :DEVICE_ID); 
         END /* for */
       
       /* Update transactions table */               
              EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully'); 
               
                           
           END /* SSN */
                                
        END /* Location */
    END /* WH */
  SUSPEND;
END ^

