COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;

ALTER PROCEDURE ADD_SSN_ISSN_GRNV 
(
  WH_ID VARCHAR(2),
  LOCN_ID VARCHAR(10),
  OBJECT VARCHAR(30),
  TRANS_DATE TIMESTAMP,
  QTY INTEGER,
  GRN VARCHAR(10),
  REFERENCE VARCHAR(40),
  SOURCE VARCHAR(9),
  RECORD_ID INTEGER
)
AS 
DECLARE VARIABLE SSN_ID INTEGER;
DECLARE VARIABLE P_SSN_ID INTEGER;
DECLARE VARIABLE W_SSN_ID VARCHAR(20);
DECLARE VARIABLE I_SSN_ID VARCHAR(20);
DECLARE VARIABLE LEN_SSN_ID INTEGER;
DECLARE VARIABLE I_LEN_SSN_ID INTEGER;
DECLARE VARIABLE SSN_LENGTH INTEGER;
DECLARE VARIABLE LABEL_NO INTEGER;
DECLARE VARIABLE WK_LABEL_CURQTY INTEGER;
DECLARE VARIABLE WK_SSN_CURQTY INTEGER;
DECLARE VARIABLE WK_LABELQTY1 VARCHAR(10);
DECLARE VARIABLE WK_LABELQTY2 VARCHAR(10);
DECLARE VARIABLE WK_SSNQTY1 VARCHAR(10);
DECLARE VARIABLE WK_SSNQTY2 VARCHAR(10);

DECLARE VARIABLE WK_GRN_TYPE CHAR(2);
DECLARE VARIABLE WK_PRINTER CHAR(2);
DECLARE VARIABLE WK_DIRECTORY VARCHAR(75);
DECLARE VARIABLE WK_FILENAME VARCHAR(255);
DECLARE VARIABLE WK_LABEL_LINE VARCHAR(250);
DECLARE VARIABLE WK_LOADNO VARCHAR(10);
DECLARE VARIABLE WK_LOAD_LINE_NO VARCHAR(10);
DECLARE VARIABLE WK_RESULT INTEGER;
DECLARE VARIABLE WK_DATE VARCHAR(20);
DECLARE VARIABLE WK_TIME VARCHAR(10);
DECLARE VARIABLE WK_PROD_DESC VARCHAR(50);
DECLARE VARIABLE WK_A_PROD INTEGER;
DECLARE VARIABLE WK_A_PO INTEGER;
DECLARE VARIABLE WK_PROD_EXISTS INTEGER;

DECLARE VARIABLE WK_REF_LEN INTEGER;
DECLARE VARIABLE WK_REF2_LAST INTEGER;
DECLARE VARIABLE WK_OLD_METHOD CHAR(1);
DECLARE VARIABLE WK_PRINTER_2 VARCHAR(5);
DECLARE VARIABLE WK_REF VARCHAR(40);
DECLARE VARIABLE WK_SUPPLIER VARCHAR(10);
DECLARE VARIABLE WK_OWNER VARCHAR(10);
DECLARE VARIABLE WK_STATUS CHAR(2);
DECLARE VARIABLE WK_PROD_STATUS CHAR(2);
DECLARE VARIABLE WK_HAVE_FILE_1 INTEGER;
DECLARE VARIABLE WK_HAVE_FILE_2 INTEGER;
DECLARE VARIABLE WK_FILENAME2 VARCHAR(255);
DECLARE VARIABLE W_PRODUCT_SSN_ID VARCHAR(20);

DECLARE VARIABLE WK_PO_FOUND INTEGER;
DECLARE VARIABLE WK_PO_QTY INTEGER;
DECLARE VARIABLE WK_PO_ORIG_QTY INTEGER;
DECLARE VARIABLE WK_PO_NEW_QTY INTEGER;
DECLARE VARIABLE WK_PO_STATUS CHAR(2);
DECLARE VARIABLE WK_USER VARCHAR(10);
DECLARE VARIABLE WK_PROD_TYPE CHAR(2);

DECLARE VARIABLE LABEL_NO2 INTEGER;
DECLARE VARIABLE WK_LABEL_CURQTY2 INTEGER;
DECLARE VARIABLE WK_DEVICE_ID CHAR(2);
DECLARE VARIABLE WK_TRN_TYPE CHAR(4);
DECLARE VARIABLE WK_TRN_CODE CHAR(1);
DECLARE VARIABLE WK_REASON VARCHAR(70);
DECLARE VARIABLE WK_PUTLOCN_1 VARCHAR(10);
DECLARE VARIABLE WK_PUTLOCN_2 VARCHAR(10);
DECLARE VARIABLE WK_WEIGHT_X VARCHAR(10);
DECLARE VARIABLE WK_WEIGHT_UOM VARCHAR(10);
DECLARE VARIABLE WK_ALTPROD VARCHAR(30);
DECLARE VARIABLE WK_STD_PALLET_CFG VARCHAR(2);
DECLARE VARIABLE WK_NON_PALLET_CFG VARCHAR(2);
DECLARE VARIABLE WK_ISSUE_UOM VARCHAR(2);
DECLARE VARIABLE WK_INSTR VARCHAR(50);
DECLARE VARIABLE WK_INNER_UNITS INTEGER;
DECLARE VARIABLE WK_ORDER_UNITS INTEGER;
DECLARE VARIABLE WK_TOT_INNER INTEGER;
DECLARE VARIABLE WK_TOT_OUTER INTEGER;
DECLARE VARIABLE WK_STD_PALLET_DESC VARCHAR(50);
DECLARE VARIABLE WK_STD_PALLET_CARTONS INTEGER;
DECLARE VARIABLE WK_STD_PALLET_LAYERS INTEGER;
DECLARE VARIABLE WK_NON_PALLET_DESC VARCHAR(50);
/* Sumeer Shoree : 5th July 2007: Added FOUR more fields */
DECLARE VARIABLE WK_LAST_LINE_NO INTEGER;
DECLARE VARIABLE WK_LAST_PALLET_NO INTEGER;
DECLARE VARIABLE I_PALLET_NO INTEGER;
DECLARE VARIABLE WK_TEMPERATURE_ZONE VARCHAR(2);
DECLARE VARIABLE WK_GENERATE_SSN_METHOD VARCHAR(25);
DECLARE VARIABLE P_LAST_LINE_NO VARCHAR(2);
DECLARE VARIABLE P_LAST_PALLET_NO VARCHAR(3);
DECLARE VARIABLE WK_GENERATE_LABEL_TEXT CHAR(1);
DECLARE VARIABLE WK_COUNT_SSN INTEGER; /* to handle primary key when the line number is h  */
DECLARE VARIABLE WK_RESPONSE_TXT VARCHAR(70);
DECLARE VARIABLE WK_RESPONSE_TXT1 VARCHAR(70);
DECLARE VARIABLE WK_RESPONSE_TXT2 VARCHAR(70);
DECLARE VARIABLE WK_RESPONSE_FINAL VARCHAR(70);

   /* for P response 170707 */
DECLARE VARIABLE WK_1ST_ISSN VARCHAR(20);
   /* for P response 170707 */
DECLARE VARIABLE WK_GRN_OWNER VARCHAR(10); /* 220807 overide prods company */
DECLARE VARIABLE WK_CMP_FROM VARCHAR(40); /* 220807 overide prods company */

BEGIN 

   WK_COUNT_SSN = 0;
   WK_HAVE_FILE_1 = 0;
   WK_HAVE_FILE_2 = 0;
   WK_REF = ALLTRIM(REFERENCE);
   REFERENCE = WK_REF;
   WK_REF_LEN = STRLEN(REFERENCE);
   WK_REF2_LAST = WK_REF_LEN;
   WK_OLD_METHOD = 'Y';
   WK_RESPONSE_TXT = '';
      WK_RESPONSE_TXT1 = '';
   WK_RESPONSE_TXT2 = '';
   WK_RESPONSE_FINAL = '';

   /* for P response 170707 */
   /* 170707 */ 
   WK_1ST_ISSN = '';

   SELECT PERSON_ID, DEVICE_ID, TRN_TYPE, TRN_CODE 
   FROM TRANSACTIONS 
   WHERE RECORD_ID = :RECORD_ID
   INTO :WK_USER, :WK_DEVICE_ID, :WK_TRN_TYPE, :WK_TRN_CODE;
   
   
   /* ADDED CODE 8TH JUL 2007 FOR WK_GENERATE_LABEL_TEXT */
   SELECT GENERATE_LABEL_TEXT FROM CONTROL INTO :WK_GENERATE_LABEL_TEXT;
   IF (WK_GENERATE_LABEL_TEXT IS NULL) THEN
   BEGIN
        WK_GENERATE_LABEL_TEXT = 'F';
   END
   

   /*
   do a loop 
   until char is '|' or have the new method
      if char <'0' or > '9'
      then have the new method
   */
   WHILE ((SUBSTR(REFERENCE,WK_REF2_LAST,WK_REF2_LAST) <> '|') AND
          (WK_OLD_METHOD = 'Y')) DO
   BEGIN
      IF (SUBSTR(REFERENCE,WK_REF2_LAST,WK_REF2_LAST) < '0' OR
          SUBSTR(REFERENCE,WK_REF2_LAST,WK_REF2_LAST) > '9') THEN
      BEGIN      
         WK_OLD_METHOD = 'N';
      END
      WK_REF2_LAST = WK_REF2_LAST - 1;
   END
   
   /* Get the STatus to use for the inserts */
   SELECT NEW_SSN_STATUS, NEW_PROD_STATUS FROM CONTROL
   INTO :WK_STATUS, :WK_PROD_STATUS;

   /* Get length for Barcode */   
   EXECUTE PROCEDURE GET_BARCODE_LENGTH RETURNING_VALUES SSN_LENGTH;
   /* Read Reference field to get Label No 
   EXECUTE PROCEDURE GET_QTY_LABEL :REFERENCE  RETURNING_VALUES LABEL_NO;
*/
   EXECUTE PROCEDURE GET_REFERENCE_FIELD :REFERENCE, 2  RETURNING_VALUES :WK_LOADNO ; 
   EXECUTE PROCEDURE GET_REFERENCE_FIELD :REFERENCE, 3  RETURNING_VALUES :WK_LOAD_LINE_NO ; 
   EXECUTE PROCEDURE GET_REFERENCE_FIELD :REFERENCE, 4  RETURNING_VALUES :WK_SSNQTY1 ; 
   EXECUTE PROCEDURE GET_REFERENCE_FIELD :REFERENCE, 5  RETURNING_VALUES :WK_LABELQTY1 ; 
   EXECUTE PROCEDURE GET_REFERENCE_FIELD :REFERENCE, 6  RETURNING_VALUES :WK_SSNQTY2 ; 
   EXECUTE PROCEDURE GET_REFERENCE_FIELD :REFERENCE, 7  RETURNING_VALUES :WK_LABELQTY2 ; 

   LABEL_NO = CAST(WK_SSNQTY1 AS INTEGER);
   WK_LABEL_CURQTY = CAST(WK_LABELQTY1 AS INTEGER);

   /* find type of grn PO LD or */
   WK_GRN_TYPE = substr(REFERENCE, 1, 2);

   LABEL_NO2 = CAST(WK_SSNQTY2 AS INTEGER);
   WK_LABEL_CURQTY2 = CAST(WK_LABELQTY2 AS INTEGER);
   IF ((LABEL_NO <= 0) AND (LABEL_NO2 <= 0)) THEN
   BEGIN
      /* no labels so stop */
      EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'No Labels to Print/Create');
      EXIT;
   END
   
   
   /* CODE ADDED BY SUMEER TO HANDLE THE NEW SSN GENERATION METHOD 5TH JULY 2007 */
   /* THE SSN GENERATION METHOD IS BASED ON THE CONTROL TABLE FIELD. */
   
   SELECT GENERATE_SSN_METHOD FROM CONTROL INTO :WK_GENERATE_SSN_METHOD;
   


   IF ((WK_GENERATE_SSN_METHOD IS NULL) OR (WK_GENERATE_SSN_METHOD <> '|GRN=4|LINE=2|SUFFIX=2,3|')) THEN
   BEGIN

      SSN_ID = GEN_ID(ISSN_SSN_ID, :LABEL_NO);
      P_SSN_ID = SSN_ID - :LABEL_NO;
      LEN_SSN_ID = STRLEN(P_SSN_ID);
         
      W_SSN_ID = '';
         /* Padding leading with 0 */
      WHILE (LEN_SSN_ID < :SSN_LENGTH) DO
      BEGIN
          W_SSN_ID = W_SSN_ID || '0';
          LEN_SSN_ID = LEN_SSN_ID + 1;
       END
       W_SSN_ID = W_SSN_ID || P_SSN_ID;
   
   END
   


   IF (WK_GENERATE_SSN_METHOD = '|GRN=4|LINE=2|SUFFIX=2,3|' ) THEN
   BEGIN

        SELECT LAST_LINE_NO, LAST_PALLET_NO FROM GRN WHERE GRN = :GRN INTO :WK_LAST_LINE_NO, :WK_LAST_PALLET_NO;

        IF (:WK_LAST_LINE_NO IS NULL) THEN
        BEGIN
               /* i AM UNSURE ABOUT THIS AS LINE NUMBER ACCORDING TO ME SHOULD NOT BE INCREMENTED.S */
              WK_LAST_LINE_NO = 0;
        END

        /* 6th july I have observed that get_reference_field uses the alltrim function */
        /* AFTER DISCUSSING WITH GLEN LAST_LINE_NO GETS INCREMENTED ONLY WHEN LOAD LINE NO IS BLANK */
        IF (WK_LOAD_LINE_NO = '') THEN
        BEGIN
             WK_LAST_LINE_NO = WK_LAST_LINE_NO + 1;
             UPDATE GRN SET LAST_LINE_NO = :WK_LAST_LINE_NO WHERE GRN = :GRN;
        END
        ELSE
        BEGIN
        /* THE LAST LINE NUMBER HAS BEEN PASSED FROM THE FRONT END SCREEN. NO UPDATE TO GRN REQUIRED. */
             WK_LAST_LINE_NO = WK_LOAD_LINE_NO;
        END
        
        IF (WK_LAST_LINE_NO < 10) THEN
        BEGIN
             P_LAST_LINE_NO = '0' || WK_LAST_LINE_NO;
        END
        ELSE
        BEGIN
             P_LAST_LINE_NO = WK_LAST_LINE_NO;
        END
        
        
        
        /* ANOTHER INTERESTING POINT. LAST_PALLET_NO DOES NOT INCREMENT FOR SSN EXCEPT FOR 'LD' */
        
        IF (WK_LAST_PALLET_NO IS NULL) THEN
        BEGIN
             WK_LAST_PALLET_NO = 0;
        END
        
        IF (WK_LAST_PALLET_NO < 10) THEN
        BEGIN
             P_LAST_PALLET_NO = '0' || WK_LAST_PALLET_NO;
        END
        ELSE
        BEGIN
             P_LAST_PALLET_NO = WK_LAST_PALLET_NO;
        END
        
        UPDATE GRN SET LAST_PALLET_NO = :WK_LAST_PALLET_NO WHERE GRN = :GRN;
        
        /* tHE FIRST TIME THE LAST_PALLET_NO IS ALWAYS 0 */
        /* 8th July - After speaking to Glenn if the transaction is sent in the second time the original should still end in '00'  */
        
        W_SSN_ID = GRN || P_LAST_LINE_NO || '00';
        
   END /* if ssn method is |GRN=4|LINE=2|SUFFIX=2,3| */

   
   IF (WK_OLD_METHOD = 'Y') THEN
   BEGIN
      WK_PRINTER = 'P' || SUBSTR(SOURCE,5,5);
   END
   ELSE
   BEGIN
      EXECUTE PROCEDURE GET_REFERENCE_FIELD :REFERENCE, 8  RETURNING_VALUES :WK_PRINTER_2 ; 
      IF (STRLEN(WK_PRINTER_2) > 1) THEN
      BEGIN
         WK_PRINTER = WK_PRINTER_2;
      END
      ELSE
      BEGIN
         WK_PRINTER = 'P' || WK_PRINTER_2;
      END
      IF (WK_GRN_TYPE = 'LD') THEN
      BEGIN
         /* EXECUTE PROCEDURE GET_REFERENCE_FIELD :OBJECT, 1  RETURNING_VALUES :WK_SUPPLIER ;  */
         WK_SUPPLIER = SUBSTR(OBJECT,1,10);
         WK_OWNER = SUBSTR(OBJECT,11,20);
         UPDATE GRN 
         SET RETURN_ID = :WK_SUPPLIER
         WHERE GRN = :GRN;
      END
   END
   WK_A_PROD = 0;
   WK_A_PO = 0;
   IF ((WK_GRN_TYPE = 'PO') OR
       (WK_GRN_TYPE = 'RA') OR  
       (WK_GRN_TYPE = 'TR') OR
       (WK_GRN_TYPE = 'WO')) THEN
   BEGIN
       IF (OBJECT <> '') THEN
       BEGIN
           WK_A_PROD = 1;
           WK_PROD_EXISTS = 0;
           WK_A_PO = 1;
           SELECT 1, 
              SHORT_DESC ,
              HOME_LOCN_ID,
              ALTERNATE_ID,
              PALLET_CFG_INNER,
              PALLET_CFG_ALTERNATE,
              ISSUE_UOM,
              ISSUE_PER_ORDER_UNIT,
              ISSUE_PER_INNER_UNIT,
              SPECIAL_INSTR,
              TEMPERATURE_ZONE
              FROM PROD_PROFILE
              WHERE PROD_ID = :OBJECT
              INTO :WK_PROD_EXISTS, 
              :WK_PROD_DESC,
              :WK_PUTLOCN_1,
              :WK_ALTPROD,
              :WK_STD_PALLET_CFG,
              :WK_NON_PALLET_CFG,
              :WK_ISSUE_UOM,
              :WK_ORDER_UNITS,
              :WK_INNER_UNITS,
              :WK_INSTR,
              :WK_TEMPERATURE_ZONE;
              
           IF (WK_PROD_EXISTS = 0) THEN
           BEGIN
               /* Insert into prod_profile */
               INSERT INTO PROD_PROFILE (PROD_ID, SHORT_DESC, LAST_UPDATE_DATE)
                   VALUES (:OBJECT, :OBJECT, 'NOW');
               WK_PROD_DESC = OBJECT;
           END
           IF (WK_PUTLOCN_1 IS NULL) THEN
           BEGIN
              WK_PUTLOCN_1 = '';
           END
           SELECT FIRST 1 WH_ID || LOCN_ID
           FROM LOCATION
           WHERE PROD_ID = :OBJECT
           AND :WK_PUTLOCN_1 <> (WH_ID || LOCN_ID)
           INTO :WK_PUTLOCN_2;
           IF (WK_PUTLOCN_2 IS NULL) THEN
           BEGIN
              WK_PUTLOCN_2 = '';
           END
           IF (WK_PUTLOCN_1 = '' AND WK_PUTLOCN_2 <> '') THEN
           BEGIN
              SELECT FIRST 1 WH_ID || LOCN_ID
              FROM LOCATION
              WHERE PROD_ID = :OBJECT
              AND :WK_PUTLOCN_2 <> (WH_ID || LOCN_ID)
              INTO :WK_PUTLOCN_1;
              IF (WK_PUTLOCN_1 IS NULL) THEN
              BEGIN
                 WK_PUTLOCN_1 = '';
              END
           END
           WK_WEIGHT_X = '';
           WK_WEIGHT_UOM = '';
           IF (WK_ALTPROD IS NULL) THEN
           BEGIN
              WK_ALTPROD = '';
           END
           IF (WK_STD_PALLET_CFG IS NULL) THEN
           BEGIN
              WK_STD_PALLET_CFG = '';
           END
           IF (WK_NON_PALLET_CFG IS NULL) THEN
           BEGIN
              WK_NON_PALLET_CFG = '';
           END
           IF (WK_ISSUE_UOM IS NULL) THEN
           BEGIN
              WK_ISSUE_UOM = '';
           END
           IF (WK_INNER_UNITS IS NULL) THEN
           BEGIN
              WK_INNER_UNITS = 1;
           END
           IF (WK_ORDER_UNITS IS NULL) THEN
           BEGIN
              WK_ORDER_UNITS = 1;
           END
           IF (WK_INSTR IS NULL) THEN
           BEGIN
              WK_INSTR = '';
           END

           /* 6TH JULY - CODE ADDED TO HANDLE TEMPERATURE ZONE */
           IF (WK_TEMPERATURE_ZONE IS NULL) THEN
           BEGIN
                WK_TEMPERATURE_ZONE = '';
           END
           
           SELECT 
              PALLET_CFG_DESCRIPTION,
              TOTAL_CARTONS_LAYER,
              TOTAL_LAYERS
           FROM PALLET_CFG
           WHERE PALLET_CFG_CODE = :WK_STD_PALLET_CFG
           INTO :WK_STD_PALLET_DESC, :WK_STD_PALLET_CARTONS, :WK_STD_PALLET_LAYERS;
           SELECT 
              PALLET_CFG_DESCRIPTION
           FROM PALLET_CFG
           WHERE PALLET_CFG_CODE = :WK_NON_PALLET_CFG
           INTO :WK_NON_PALLET_DESC ;
           IF (WK_STD_PALLET_DESC IS NULL) THEN
           BEGIN
              WK_STD_PALLET_DESC = WK_STD_PALLET_CFG;
           END
           IF (WK_STD_PALLET_CARTONS IS NULL) THEN
           BEGIN
              WK_STD_PALLET_CARTONS = 1;
           END
           IF (WK_STD_PALLET_LAYERS IS NULL) THEN
           BEGIN
              WK_STD_PALLET_LAYERS = 1;
           END
           IF (WK_NON_PALLET_DESC IS NULL) THEN
           BEGIN
              WK_NON_PALLET_DESC = WK_NON_PALLET_CFG;
           END
           WK_TOT_INNER = WK_ORDER_UNITS / WK_INNER_UNITS;
           WK_TOT_OUTER = WK_STD_PALLET_LAYERS * WK_STD_PALLET_CARTONS;
           WK_SSN_CURQTY = LABEL_NO  * WK_LABEL_CURQTY ;
           SELECT COMPANY_ID 
           FROM PURCHASE_ORDER 
           WHERE PURCHASE_ORDER = :WK_LOADNO
           INTO :WK_OWNER;
           IF (WK_OWNER IS NULL) THEN
           BEGIN
              SELECT COMPANY_ID FROM CONTROL INTO :WK_OWNER; 
           END
          /* Insert data into SSN table */   
          SELECT COUNT(*) AS CNT FROM SSN WHERE SSN_ID = :W_SSN_ID INTO :WK_COUNT_SSN;

          IF (WK_COUNT_SSN = 0) THEN
          BEGIN
                    INSERT INTO SSN (SSN_ID, WH_ID, LOCN_ID, GRN, STATUS_SSN, LABEL_DATE, ORIGINAL_QTY,
                    CURRENT_QTY, PURCHASE_DATE, PO_ORDER, PO_RECEIVE_DATE, PROD_ID, SSN_DESCRIPTION, PO_LINE, COMPANY_ID)
                    VALUES (:W_SSN_ID, :WH_ID, :LOCN_ID, :GRN, :WK_PROD_STATUS, 'NOW', :WK_SSN_CURQTY, :WK_SSN_CURQTY, 'NOW',:WK_LOADNO, 'NOW', :OBJECT,:WK_PROD_DESC,:WK_LOAD_LINE_NO, :WK_OWNER);
          END
          ELSE
          BEGIN
               UPDATE SSN SET ORIGINAL_QTY = ORIGINAL_QTY + :WK_SSN_CURQTY, CURRENT_QTY = CURRENT_QTY + :WK_SSN_CURQTY
               WHERE SSN_ID = :W_SSN_ID;
          
          END
          
          W_PRODUCT_SSN_ID = W_SSN_ID;
          WK_REASON = 'Received ' || :WK_SSN_CURQTY || ' by User ' || :WK_USER || ' SSN ' || :W_SSN_ID ;
          EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :W_SSN_ID, 
                          :WK_TRN_TYPE, :WK_TRN_CODE, :TRANS_DATE,
                          :WK_REASON, '' , :WK_SSN_CURQTY, :WK_USER, :WK_DEVICE_ID); 
          UPDATE GRN 
          SET ORDER_NO = :WK_LOADNO,
              ORDER_LINE_NO = :WK_LOAD_LINE_NO
          WHERE GRN = :GRN;
          /* update the po outstanding qty and status */
          WK_PO_FOUND = 0;
          SELECT 1 , PO_LINE_QTY, ORIGINAL_QTY 
          FROM PURCHASE_ORDER_LINE
          WHERE PURCHASE_ORDER = :WK_LOADNO
          AND   PO_LINE = :WK_LOAD_LINE_NO
          INTO :WK_PO_FOUND, :WK_PO_QTY, :WK_PO_ORIG_QTY ;
          IF (WK_PO_FOUND = 1) THEN
          BEGIN
             WK_PO_STATUS = 'OP';
             WK_PO_NEW_QTY = WK_PO_QTY - WK_SSN_CURQTY; 
             IF (WK_PO_NEW_QTY = 0) THEN
             BEGIN
                WK_PO_STATUS = 'CL';
             END
             ELSE
             BEGIN
                IF (WK_PO_NEW_QTY < 0) THEN
                BEGIN
                   WK_PO_STATUS = 'OS';
                END
             END

             IF (WK_PO_ORIG_QTY IS NULL) THEN
             BEGIN
                UPDATE PURCHASE_ORDER_LINE
                SET ORIGINAL_QTY = :WK_PO_QTY,
                    PO_LINE_QTY = :WK_PO_NEW_QTY,
                    PO_LINE_STATUS = :WK_PO_STATUS
                WHERE PURCHASE_ORDER = :WK_LOADNO
                AND   PO_LINE = :WK_LOAD_LINE_NO;
             END
             ELSE
             BEGIN
                UPDATE PURCHASE_ORDER_LINE
                SET PO_LINE_QTY = :WK_PO_NEW_QTY,
                    PO_LINE_STATUS = :WK_PO_STATUS
                WHERE PURCHASE_ORDER = :WK_LOADNO
                AND   PO_LINE = :WK_LOAD_LINE_NO;
             END
          END
      END
   END
             
   IF (WK_GRN_TYPE = 'LP') THEN
   BEGIN
       IF (OBJECT <> '') THEN
       BEGIN
           WK_A_PROD = 1;
           /* 220807 overide company */
           WK_GRN_OWNER = '';
           SELECT OWNER_ID 
           FROM GRN 
           WHERE GRN = :GRN
           INTO :WK_GRN_OWNER;
           WK_CMP_FROM = '';
           SELECT DESCRIPTION
           FROM OPTIONS
           WHERE GROUP_CODE = 'CMP'
           AND CODE = 'GRNV'
           INTO :WK_CMP_FROM;
           IF (WK_CMP_FROM IS NULL) THEN
           BEGIN
              WK_CMP_FROM = 'PROD';
           END
           /* end 220807 */

           WK_PROD_EXISTS = 0;
           SELECT 1, 
              PROD_TYPE, 
              COMPANY_ID, 
              SHORT_DESC ,
              HOME_LOCN_ID,
              ALTERNATE_ID,
              PALLET_CFG_INNER,
              PALLET_CFG_ALTERNATE,
              ISSUE_UOM,
              ISSUE_PER_ORDER_UNIT,
              ISSUE_PER_INNER_UNIT,
              SPECIAL_INSTR,
              TEMPERATURE_ZONE
              FROM PROD_PROFILE
              WHERE PROD_ID = :OBJECT
              INTO :WK_PROD_EXISTS, :WK_PROD_TYPE, :WK_OWNER,
              :WK_PROD_DESC,
              :WK_PUTLOCN_1,
              :WK_ALTPROD,
              :WK_STD_PALLET_CFG,
              :WK_NON_PALLET_CFG,
              :WK_ISSUE_UOM,
              :WK_ORDER_UNITS,
              :WK_INNER_UNITS,
              :WK_INSTR,
              :WK_TEMPERATURE_ZONE;
           IF (WK_PROD_EXISTS = 0) THEN
           BEGIN
               /* Insert into prod_profile */
               INSERT INTO PROD_PROFILE (PROD_ID, SHORT_DESC, LAST_UPDATE_DATE)
                   VALUES (:OBJECT, :OBJECT, 'NOW');
               WK_PROD_DESC = OBJECT;
           END
           IF (WK_PUTLOCN_1 IS NULL) THEN
           BEGIN
              WK_PUTLOCN_1 = '';
           END
           SELECT FIRST 1 WH_ID || LOCN_ID
           FROM LOCATION
           WHERE PROD_ID = :OBJECT
           AND :WK_PUTLOCN_1 <> (WH_ID || LOCN_ID)
           INTO :WK_PUTLOCN_2;
           IF (WK_PUTLOCN_2 IS NULL) THEN
           BEGIN
              WK_PUTLOCN_2 = '';
           END
           IF (WK_PUTLOCN_1 = '' AND WK_PUTLOCN_2 <> '') THEN
           BEGIN
              SELECT FIRST 1 WH_ID || LOCN_ID
              FROM LOCATION
              WHERE PROD_ID = :OBJECT
              AND :WK_PUTLOCN_2 <> (WH_ID || LOCN_ID)
              INTO :WK_PUTLOCN_1;
              IF (WK_PUTLOCN_1 IS NULL) THEN
              BEGIN
                 WK_PUTLOCN_1 = '';
              END
           END
           IF (WK_ALTPROD IS NULL) THEN
           BEGIN
              WK_ALTPROD = '';
           END
           WK_WEIGHT_X = '';
           WK_WEIGHT_UOM = '';
           IF (WK_STD_PALLET_CFG IS NULL) THEN
           BEGIN
              WK_STD_PALLET_CFG = '';
           END
           IF (WK_NON_PALLET_CFG IS NULL) THEN
           BEGIN
              WK_NON_PALLET_CFG = '';
           END
           IF (WK_ISSUE_UOM IS NULL) THEN
           BEGIN
              WK_ISSUE_UOM = '';
           END
           IF (WK_INNER_UNITS IS NULL) THEN
           BEGIN
              WK_INNER_UNITS = 1;
           END
           IF (WK_ORDER_UNITS IS NULL) THEN
           BEGIN
              WK_ORDER_UNITS = 1;
           END
           IF (WK_INSTR IS NULL) THEN
           BEGIN
              WK_INSTR = '';
           END
           /* 6TH JULY 2007 - HANDLING WK_TEMPERATURE_ZONE */
           IF (WK_TEMPERATURE_ZONE IS NULL) THEN
           BEGIN
                WK_TEMPERATURE_ZONE = '';
           END
           SELECT 
              PALLET_CFG_DESCRIPTION,
              TOTAL_CARTONS_LAYER,
              TOTAL_LAYERS
           FROM PALLET_CFG
           WHERE PALLET_CFG_CODE = :WK_STD_PALLET_CFG
           INTO :WK_STD_PALLET_DESC, :WK_STD_PALLET_CARTONS, :WK_STD_PALLET_LAYERS;
           SELECT 
              PALLET_CFG_DESCRIPTION
           FROM PALLET_CFG
           WHERE PALLET_CFG_CODE = :WK_NON_PALLET_CFG
           INTO :WK_NON_PALLET_DESC ;
           IF (WK_STD_PALLET_DESC IS NULL) THEN
           BEGIN
              WK_STD_PALLET_DESC = WK_STD_PALLET_CFG;
           END
           IF (WK_STD_PALLET_CARTONS IS NULL) THEN
           BEGIN
              WK_STD_PALLET_CARTONS = 1;
           END
           IF (WK_STD_PALLET_LAYERS IS NULL) THEN
           BEGIN
              WK_STD_PALLET_LAYERS = 1;
           END
           IF (WK_NON_PALLET_DESC IS NULL) THEN
           BEGIN
              WK_NON_PALLET_DESC = WK_NON_PALLET_CFG;
           END
           WK_TOT_INNER = WK_ORDER_UNITS / WK_INNER_UNITS;
           WK_TOT_OUTER = WK_STD_PALLET_LAYERS * WK_STD_PALLET_CARTONS;
           WK_SSN_CURQTY = LABEL_NO  * WK_LABEL_CURQTY ;
           /* calc loadno, supplier and default company */
           WK_SUPPLIER = WK_LOADNO;
           /* 220807 overide company */
           IF (WK_CMP_FROM = 'GRN') THEN
           BEGIN
              WK_OWNER = WK_GRN_OWNER;
           END
           /* end 220807 */
           IF (WK_OWNER IS NULL) THEN
           BEGIN
              SELECT COMPANY_ID FROM CONTROL INTO :WK_OWNER; 
           END
           SELECT ORDER_NO FROM GRN WHERE GRN = :GRN INTO :WK_LOADNO;
           UPDATE GRN 
           SET RETURN_ID = :WK_SUPPLIER
           WHERE GRN = :GRN;
          /* Insert data into SSN table */   

          SELECT COUNT(*) AS CNT FROM SSN WHERE SSN_ID = :W_SSN_ID INTO :WK_COUNT_SSN;
          IF (WK_COUNT_SSN = 0) THEN
          BEGIN
                    INSERT INTO SSN (SSN_ID, WH_ID, LOCN_ID, GRN, STATUS_SSN, LABEL_DATE, ORIGINAL_QTY,
                    CURRENT_QTY, PO_ORDER, PO_RECEIVE_DATE, PROD_ID, SSN_DESCRIPTION, PO_LINE, SUPPLIER_ID, COMPANY_ID, SSN_TYPE)
                    VALUES (:W_SSN_ID, :WH_ID, :LOCN_ID, :GRN, :WK_PROD_STATUS, 'NOW', :WK_SSN_CURQTY, :WK_SSN_CURQTY, :WK_LOADNO, 'NOW', :OBJECT,:WK_PROD_DESC,:WK_LOAD_LINE_NO, :WK_SUPPLIER, :WK_OWNER, :WK_PROD_TYPE);
          END
          ELSE
          BEGIN
               UPDATE SSN SET ORIGINAL_QTY = ORIGINAL_QTY + :WK_SSN_CURQTY, CURRENT_QTY = CURRENT_QTY + :WK_SSN_CURQTY
               WHERE SSN_ID = :W_SSN_ID;

          END



          W_PRODUCT_SSN_ID = W_SSN_ID;
          WK_REASON = 'Received ' || :WK_SSN_CURQTY || ' by User ' || :WK_USER || ' SSN ' || :W_SSN_ID ;
          EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :W_SSN_ID, 
                          :WK_TRN_TYPE, :WK_TRN_CODE, :TRANS_DATE,
                          :WK_REASON, '' , :WK_SSN_CURQTY, :WK_USER, :WK_DEVICE_ID); 
      END
   END
             
   /* Insert data into ISSN table */
   IF ((WK_GENERATE_SSN_METHOD IS NULL) OR (WK_GENERATE_SSN_METHOD <> '|GRN=4|LINE=2|SUFFIX=2,3|')) THEN
   BEGIN
        WHILE (P_SSN_ID < SSN_ID) DO
        BEGIN
          I_SSN_ID = '';
          I_LEN_SSN_ID = STRLEN(P_SSN_ID);
      
             /* Padding leading with 0 */
          WHILE (I_LEN_SSN_ID < :SSN_LENGTH) DO
          BEGIN
           I_SSN_ID = I_SSN_ID || '0';
           I_LEN_SSN_ID = I_LEN_SSN_ID + 1;
          END
          I_SSN_ID = I_SSN_ID || P_SSN_ID;
          /* 170707 1st issn */
          IF (WK_1ST_ISSN = '') THEN
          BEGIN
             WK_1ST_ISSN = I_SSN_ID;
          END

          IF (WK_A_PROD = 0) THEN
          BEGIN
         /* Insert data into SSN table */   
/*
         VALUES (:I_SSN_ID, :WH_ID, :LOCN_ID, :GRN, 'TS', 'NOW', :WK_LABEL_CURQTY, :WK_LABEL_CURQTY, :WK_LOADNO, 'NOW',:WK_LOAD_LINE_NO,:OBJECT);     
         VALUES (:I_SSN_ID, :I_SSN_ID, :WH_ID, :LOCN_ID, :WK_LABEL_CURQTY, 'TS'); 
*/
          INSERT INTO SSN (SSN_ID, WH_ID, LOCN_ID, GRN, STATUS_SSN, LABEL_DATE, ORIGINAL_QTY,
                    CURRENT_QTY, PO_ORDER, PO_RECEIVE_DATE, PO_LINE, SUPPLIER_ID, COMPANY_ID)
          VALUES (:I_SSN_ID, :WH_ID, :LOCN_ID, :GRN, :WK_STATUS, 'NOW', :WK_LABEL_CURQTY, :WK_LABEL_CURQTY, :WK_LOADNO, 'NOW',:WK_LOAD_LINE_NO,:WK_SUPPLIER, :WK_OWNER);
          INSERT INTO ISSN (SSN_ID, ORIGINAL_SSN, WH_ID, LOCN_ID, CURRENT_QTY,ISSN_STATUS, LABEL_DATE, COMPANY_ID, ORIGINAL_QTY, CREATE_DATE, USER_ID, INTO_DATE)
          VALUES (:I_SSN_ID, :I_SSN_ID, :WH_ID, :LOCN_ID, :WK_LABEL_CURQTY, :WK_STATUS, :TRANS_DATE, :WK_OWNER, :WK_LABEL_CURQTY, :TRANS_DATE, :WK_USER, :TRANS_DATE);
         END

         IF (WK_A_PROD = 1) THEN
         BEGIN
           INSERT INTO ISSN (SSN_ID, ORIGINAL_SSN, WH_ID, LOCN_ID, CURRENT_QTY,ISSN_STATUS, PROD_ID, LABEL_DATE, COMPANY_ID, ORIGINAL_QTY, CREATE_DATE,USER_ID, INTO_DATE)
           VALUES (:I_SSN_ID, :W_SSN_ID, :WH_ID, :LOCN_ID, :WK_LABEL_CURQTY, :WK_PROD_STATUS, :OBJECT, 'NOW', :WK_OWNER, :WK_LABEL_CURQTY, :TRANS_DATE, :WK_USER, :TRANS_DATE );
         END
      
         P_SSN_ID = P_SSN_ID + 1;
    END /* THIS IS WHERE GENERATION OF ISSN AND SSN ENDS WHEN P_SSN_ID < SSN_ID */
   END /* IF NOT OF TYPE |GRN=4|LINE=2|SUFFIX=2,3| */
   
   
   /* THIS CODE WAS ADDED BY SUMEER ON 6TH OF JULY 2007 */
   
   IF (WK_GENERATE_SSN_METHOD = '|GRN=4|LINE=2|SUFFIX=2,3|' ) THEN
   BEGIN

        /* THIS TIME THE LAST LINE NUMBER WILL REMAIN THE SAME. ONLY PALLET NO WILL KEEP CHANGING FOR NEW ISSNS */
        /* WK_LAST_PALLET_NO HAS ALREADY BEEN INITIALIZED TO ZERO */
        /* P_LAST_LINE_NO CONTAINS THE LAST VALUE OF WK_LAST_LINE_NO */
        /* W_SSN_ID CONTAINS THE ORIGINAL VALUE OF SSN. */

        I_PALLET_NO = 0;
        WHILE (I_PALLET_NO < LABEL_NO) DO
        BEGIN

           /* DURING UPDATES THIS UPDATE WILL BE WITHIN A SESSION. THERE IS A MINOR CHANCE OF TWO PALLETS HAVING THE SAME NUMBER AS THIS CHANGE CANNOT BE COMMITTED IN A TRIGGER */
           SELECT LAST_PALLET_NO FROM GRN WHERE GRN = :GRN INTO :WK_LAST_PALLET_NO;
           WK_LAST_PALLET_NO = WK_LAST_PALLET_NO + 1;
           UPDATE GRN SET LAST_PALLET_NO = :WK_LAST_PALLET_NO WHERE GRN = :GRN;

           IF (WK_LAST_PALLET_NO < 10) THEN
           BEGIN
              P_LAST_PALLET_NO = '0' || WK_LAST_PALLET_NO;
           END
           ELSE
           BEGIN
             P_LAST_PALLET_NO = WK_LAST_PALLET_NO;
           END


        /* tHE FIRST TIME THE LAST_PALLET_NO IS ALWAYS 0 */

          I_SSN_ID = GRN || P_LAST_LINE_NO || P_LAST_PALLET_NO;
          /* 170707 1st issn */
          IF (WK_1ST_ISSN = '') THEN
          BEGIN
             WK_1ST_ISSN = I_SSN_ID;
          END
        
          IF (WK_A_PROD = 0) THEN /* IF LD */
          BEGIN
         /* Insert data into SSN table */
          INSERT INTO SSN (SSN_ID, WH_ID, LOCN_ID, GRN, STATUS_SSN, LABEL_DATE, ORIGINAL_QTY,
                    CURRENT_QTY, PO_ORDER, PO_RECEIVE_DATE, PO_LINE, SUPPLIER_ID, COMPANY_ID)
          VALUES (:I_SSN_ID, :WH_ID, :LOCN_ID, :GRN, :WK_STATUS, 'NOW', :WK_LABEL_CURQTY, :WK_LABEL_CURQTY, :WK_LOADNO, 'NOW',:WK_LOAD_LINE_NO,:WK_SUPPLIER, :WK_OWNER);
          INSERT INTO ISSN (SSN_ID, ORIGINAL_SSN, WH_ID, LOCN_ID, CURRENT_QTY,ISSN_STATUS, LABEL_DATE, COMPANY_ID, ORIGINAL_QTY, CREATE_DATE, USER_ID, INTO_DATE)
          VALUES (:I_SSN_ID, :I_SSN_ID, :WH_ID, :LOCN_ID, :WK_LABEL_CURQTY, :WK_STATUS, :TRANS_DATE, :WK_OWNER, :WK_LABEL_CURQTY, :TRANS_DATE, :WK_USER, :TRANS_DATE);
         END

         IF (WK_A_PROD = 1) THEN /* IF <> LD */
         BEGIN
           INSERT INTO ISSN (SSN_ID, ORIGINAL_SSN, WH_ID, LOCN_ID, CURRENT_QTY,ISSN_STATUS, PROD_ID, LABEL_DATE, COMPANY_ID, ORIGINAL_QTY, CREATE_DATE,USER_ID, INTO_DATE)
           VALUES (:I_SSN_ID, :W_SSN_ID, :WH_ID, :LOCN_ID, :WK_LABEL_CURQTY, :WK_PROD_STATUS, :OBJECT, 'NOW', :WK_OWNER, :WK_LABEL_CURQTY, :TRANS_DATE, :WK_USER, :TRANS_DATE );
         END

         I_PALLET_NO = I_PALLET_NO + 1;
        END /* WHILE I_PALLETNO < LABEL_NO */
   END /* if ssn method is |GRN=4|LINE=2|SUFFIX=2,3| */

   /* for P response 170707 */
   WK_RESPONSE_TXT = WK_RESPONSE_TXT || :WK_1ST_ISSN || '|' || :WK_SSNQTY1 || '|' || :WK_LABELQTY1 || '|';   
   WK_RESPONSE_TXT1 = :WK_1ST_ISSN || '|' || :WK_SSNQTY1 || '|' || :WK_LABELQTY1 ;

   

IF (WK_GENERATE_LABEL_TEXT = 'T') THEN
BEGIN
   /* need the directory for this label set */
   SELECT WORKING_DIRECTORY FROM SYS_EQUIP 
       WHERE DEVICE_ID = :WK_PRINTER
       INTO :WK_DIRECTORY;
   /* append the file name to the directory*/
   IF (WK_A_PROD = 0) THEN
   BEGIN
      WK_FILENAME = WK_DIRECTORY || 'LOAD.1xt';
      WK_LABEL_LINE = '"' || W_SSN_ID || '","' ||
          WK_LOADNO || '","' ||
          LABEL_NO || '"';
      WK_HAVE_FILE_1 = 1;
      WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_LABEL_LINE);
      IF (WK_RESULT <> 0) THEN
      BEGIN
         WK_FILENAME = WK_DIRECTORY || 'LOAD.2xt';
         WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_LABEL_LINE);
         WK_HAVE_FILE_1 = -1;
      END
      
   END
   IF (WK_A_PROD = 1) THEN
   BEGIN
      /* must get products desc  */
      WK_DATE = MER_DAY(TRANS_DATE) || '/' || MER_MONTH(TRANS_DATE) || '/' || SUBSTR(CAST(MER_YEAR(TRANS_DATE) AS CHAR(4)) , 3,4);
      WK_TIME = MER_HOUR(TRANS_DATE) || ':' || MER_MINUTE(TRANS_DATE) ;
      WK_DATE = WK_DATE || ' ' || WK_TIME;
      WK_FILENAME = WK_DIRECTORY || 'Product.1xt';
      WK_HAVE_FILE_1 = 1;
/*
      WK_LABEL_LINE = DQUOTEDSTR(W_SSN_ID) || ',' ||
          DQUOTEDSTR(WK_LABEL_CURQTY ) || ',' ||
          DQUOTEDSTR(OBJECT) || ',' ||
          DQUOTEDSTR(WK_PROD_DESC) || ',' ||
          DQUOTEDSTR(WK_DATE);
*/
      IF (WK_A_PO = 0) THEN
      BEGIN
/*
         WK_LABEL_LINE = '"' || W_SSN_ID || '","' || 
             WK_LABELQTY1 || '","' || 
             OBJECT || '","' || 
             WK_PROD_DESC || '","' || 
             WK_DATE || '","' || 
             WK_SSNQTY1 || '"' ;
*/
         WK_LABEL_LINE = '"' || W_SSN_ID || '","' || 
             WK_LABELQTY1 || '","' || 
             OBJECT || '","' || 
             WK_PROD_DESC || '","' || 
             WK_DATE || '","' || 
             WK_SSNQTY1 || '","' || 
             WK_WEIGHT_X || '","' ||
             WK_WEIGHT_UOM || '","' ||
             WK_PUTLOCN_1 || '","' ||
             WK_PUTLOCN_2 || '","' ||
             WK_LOADNO || '","' ||
             GRN || '","' ||
             W_PRODUCT_SSN_ID || '","' ||
             WK_ALTPROD || '","' ||
             WK_STD_PALLET_DESC || '","' ||
             WK_NON_PALLET_DESC || '","' ||
             WK_ISSUE_UOM || '","' ||
             WK_TOT_INNER || '","' ||
             WK_TOT_OUTER || '","' ||
             WK_INSTR || '","' ||
             WK_PRINTER  || '","' ||
             WK_TEMPERATURE_ZONE || '"'  ;
      END
      ELSE
      BEGIN
         WK_LABEL_LINE = '"' || W_SSN_ID || '","' || 
             WK_LABELQTY1 || '","' || 
             OBJECT || '","' || 
             WK_PROD_DESC || '","' || 
             WK_DATE || '","' || 
             WK_SSNQTY1 || '","' ||
             WK_WEIGHT_X || '","' ||
             WK_WEIGHT_UOM || '","' ||
             WK_PUTLOCN_1 || '","' ||
             WK_PUTLOCN_2 || '","' ||
             WK_LOADNO || '","' ||
             GRN || '","' ||
             W_PRODUCT_SSN_ID || '","' ||
             WK_ALTPROD || '","' ||
             WK_STD_PALLET_DESC || '","' ||
             WK_NON_PALLET_DESC || '","' ||
             WK_ISSUE_UOM || '","' ||
              WK_TOT_INNER || '","' ||
             WK_TOT_OUTER || '","' ||
             WK_INSTR || '","' ||
             WK_PRINTER || '","' ||
             WK_TEMPERATURE_ZONE || '"' ;

      END
      WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_LABEL_LINE);
      IF (WK_RESULT <> 0) THEN
      BEGIN
         WK_FILENAME = WK_DIRECTORY || 'Product.2xt';
         WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_LABEL_LINE);
         WK_HAVE_FILE_1 = -1;
      END
   END
END /* LABEL TEXT FILES ONLY IF GENERATE_LABEL_TEXT = 'T' */


   EXECUTE PROCEDURE GET_REFERENCE_FIELD :REFERENCE, 6  RETURNING_VALUES :WK_SSNQTY2 ; 
   EXECUTE PROCEDURE GET_REFERENCE_FIELD :REFERENCE, 7  RETURNING_VALUES :WK_LABELQTY2 ; 
   LABEL_NO = CAST(WK_SSNQTY2 AS INTEGER);
   WK_LABEL_CURQTY = CAST(WK_LABELQTY2 AS INTEGER);
   /* 170707 */ 
   WK_1ST_ISSN = '';

   /* IF (LABEL_NO > 0) THEN - 07/08/07 also used the ssn qty */
   IF ((LABEL_NO * WK_LABEL_CURQTY) > 0) THEN
   BEGIN

   IF ((WK_GENERATE_SSN_METHOD IS NULL) or (WK_GENERATE_SSN_METHOD <> '|GRN=4|LINE=2|SUFFIX=2,3|')) THEN
   BEGIN
      SSN_ID = GEN_ID(ISSN_SSN_ID, :LABEL_NO);
      P_SSN_ID = SSN_ID - :LABEL_NO;
      LEN_SSN_ID = STRLEN(P_SSN_ID);     
            
      W_SSN_ID = '';
      /* Padding leading with 0 */
      WHILE (LEN_SSN_ID < :SSN_LENGTH) DO
      BEGIN
         W_SSN_ID = W_SSN_ID || '0';      
         LEN_SSN_ID = LEN_SSN_ID + 1;
      END
      W_SSN_ID = W_SSN_ID || P_SSN_ID;
   END
   
   IF (WK_GENERATE_SSN_METHOD = '|GRN=4|LINE=2|SUFFIX=2,3|' ) THEN
   BEGIN

        SELECT LAST_LINE_NO, LAST_PALLET_NO FROM GRN WHERE GRN = :GRN INTO :WK_LAST_LINE_NO, :WK_LAST_PALLET_NO;

        IF (:WK_LAST_LINE_NO IS NULL) THEN
        BEGIN
               /* i AM UNSURE ABOUT THIS AS LINE NUMBER ACCORDING TO ME SHOULD NOT BE INCREMENTED.S */
              WK_LAST_LINE_NO = 0;
        END

        /* 6th july I have observed that get_reference_field uses the alltrim function */
        /* AFTER DISCUSSING WITH GLEN LAST_LINE_NO GETS INCREMENTED ONLY WHEN LOAD LINE NO IS BLANK */
        /* in qty 2 - 8th july after discussing with Glenn, we cannot increment the last_line_no */
        /* glenn will take care that on the PHP screens, qty2 cannot be entered without qty1 so that line number remains the same. */
        
        IF (WK_LOAD_LINE_NO = '') THEN
        BEGIN
             WK_LAST_LINE_NO = WK_LAST_LINE_NO; /* no increment of the line no */
             UPDATE GRN SET LAST_LINE_NO = :WK_LAST_LINE_NO WHERE GRN = :GRN;
        END
        ELSE
        BEGIN
        /* THE LAST LINE NUMBER HAS BEEN PASSED FROM THE FRONT END SCREEN. NO UPDATE TO GRN REQUIRED. */
             WK_LAST_LINE_NO = WK_LOAD_LINE_NO;
        END

        IF (WK_LAST_LINE_NO < 10) THEN
        BEGIN
             P_LAST_LINE_NO = '0' || WK_LAST_LINE_NO;
        END
        ELSE
        BEGIN
             P_LAST_LINE_NO = WK_LAST_LINE_NO;
        END




        IF (WK_LAST_PALLET_NO IS NULL) THEN
        BEGIN
             WK_LAST_PALLET_NO = 0;
        END

        IF (WK_LAST_PALLET_NO < 10) THEN
        BEGIN
             P_LAST_PALLET_NO = '0' || WK_LAST_PALLET_NO;
        END
        ELSE
        BEGIN
             P_LAST_PALLET_NO = WK_LAST_PALLET_NO;
        END

        UPDATE GRN SET LAST_PALLET_NO = :WK_LAST_PALLET_NO WHERE GRN = :GRN;

        /* tHE FIRST TIME THE LAST_PALLET_NO IS ALWAYS 0 */
        /* 8th of july - after speaking to Glenn the orignal ssn always ends with 00 */

        W_SSN_ID = GRN || P_LAST_LINE_NO || '00';

   END /* if ssn method is |GRN=4|LINE=2|SUFFIX=2,3| */


      IF (WK_A_PROD = 1) THEN
      BEGIN
           WK_SSN_CURQTY = LABEL_NO  * WK_LABEL_CURQTY ;
          /* Insert data into SSN table */   
/*
          INSERT INTO SSN (SSN_ID, WH_ID, LOCN_ID, GRN, STATUS_SSN, LABEL_DATE, ORIGINAL_QTY,
                    CURRENT_QTY, PURCHASE_DATE, PO_ORDER, PO_RECEIVE_DATE, PROD_ID, SSN_DESCRIPTION, PO_LINE)
          VALUES (:W_SSN_ID, :WH_ID, :LOCN_ID, :GRN, 'PA', 'NOW', :WK_SSN_CURQTY, :WK_SSN_CURQTY, 'NOW',:WK_LOADNO, 'NOW', :OBJECT,:WK_PROD_DESC,:WK_LOAD_LINE_NO);     
*/
            UPDATE SSN SET CURRENT_QTY = CURRENT_QTY + :WK_SSN_CURQTY, ORIGINAL_QTY = ORIGINAL_QTY + :WK_SSN_CURQTY WHERE SSN_ID = :W_PRODUCT_SSN_ID ; 
            WK_REASON = 'Received ' || :WK_SSN_CURQTY || ' by User ' || :WK_USER || ' SSN ' || :W_PRODUCT_SSN_ID ;
            EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :W_PRODUCT_SSN_ID, 
                          :WK_TRN_TYPE, :WK_TRN_CODE, :TRANS_DATE,
                          :WK_REASON, '' , :WK_SSN_CURQTY, :WK_USER, :WK_DEVICE_ID); 
         IF ((WK_GRN_TYPE = 'PO') OR
             (WK_GRN_TYPE = 'RA') OR  
             (WK_GRN_TYPE = 'TR') OR
             (WK_GRN_TYPE = 'WO')) THEN
         BEGIN
          /* update the po outstanding qty and status */
          WK_PO_QTY = WK_PO_NEW_QTY;
          IF (WK_PO_FOUND = 1) THEN
          BEGIN
             WK_PO_NEW_QTY = WK_PO_QTY - WK_SSN_CURQTY; 
             IF (WK_PO_NEW_QTY = 0) THEN
             BEGIN
                WK_PO_STATUS = 'CL';
             END
             ELSE
             BEGIN
                IF (WK_PO_NEW_QTY < 0) THEN
                BEGIN
                   WK_PO_STATUS = 'OS';
                END
             END

             UPDATE PURCHASE_ORDER_LINE
             SET PO_LINE_QTY = :WK_PO_NEW_QTY,
                 PO_LINE_STATUS = :WK_PO_STATUS
             WHERE PURCHASE_ORDER = :WK_LOADNO
             AND   PO_LINE = :WK_LOAD_LINE_NO;
          END
         END
      END
      
      /* Insert data into ISSN table */
   IF ((WK_GENERATE_SSN_METHOD IS NULL) or (WK_GENERATE_SSN_METHOD <> '|GRN=4|LINE=2|SUFFIX=2,3|')) THEN
   BEGIN
      WHILE (P_SSN_ID < SSN_ID) DO
      BEGIN
         I_SSN_ID = '';
         I_LEN_SSN_ID = STRLEN(P_SSN_ID);
         
         /* Padding leading with 0 */
         WHILE (I_LEN_SSN_ID < :SSN_LENGTH) DO
         BEGIN
          I_SSN_ID = I_SSN_ID || '0';
          I_LEN_SSN_ID = I_LEN_SSN_ID + 1;
         END
         I_SSN_ID = I_SSN_ID || P_SSN_ID;
         /* 170707 1st issn */
         IF (WK_1ST_ISSN = '') THEN
         BEGIN
            WK_1ST_ISSN = I_SSN_ID;
         END
         
         IF (WK_A_PROD = 0) THEN
         BEGIN
/*
            VALUES (:I_SSN_ID, :WH_ID, :LOCN_ID, :GRN, 'TS', 'NOW', :WK_LABEL_CURQTY, :WK_LABEL_CURQTY, :WK_LOADNO, 'NOW', :WK_LOAD_LINE_NO, :OBJECT);     
            VALUES (:I_SSN_ID, :I_SSN_ID, :WH_ID, :LOCN_ID, :WK_LABEL_CURQTY, 'TS'); 
*/
            /* Insert data into SSN table */   
            INSERT INTO SSN (SSN_ID, WH_ID, LOCN_ID, GRN, STATUS_SSN, LABEL_DATE, ORIGINAL_QTY,
                    CURRENT_QTY, PO_ORDER, PO_RECEIVE_DATE, PO_LINE, SUPPLIER_ID, COMPANY_ID)
            VALUES (:I_SSN_ID, :WH_ID, :LOCN_ID, :GRN, :WK_STATUS, 'NOW', :WK_LABEL_CURQTY, :WK_LABEL_CURQTY, :WK_LOADNO, 'NOW', :WK_LOAD_LINE_NO, :WK_SUPPLIER, :WK_OWNER);     
            INSERT INTO ISSN (SSN_ID, ORIGINAL_SSN, WH_ID, LOCN_ID, CURRENT_QTY, ISSN_STATUS, LABEL_DATE, COMPANY_ID, ORIGINAL_QTY, CREATE_DATE, USER_ID, INTO_DATE)
            VALUES (:I_SSN_ID, :I_SSN_ID, :WH_ID, :LOCN_ID, :WK_LABEL_CURQTY, :WK_STATUS, 'NOW', :WK_OWNER, :WK_LABEL_CURQTY, :TRANS_DATE, :WK_USER, :TRANS_DATE); 
         END
         IF (WK_A_PROD = 1) THEN
         BEGIN
            INSERT INTO ISSN (SSN_ID, ORIGINAL_SSN, WH_ID, LOCN_ID, CURRENT_QTY, ISSN_STATUS, PROD_ID, LABEL_DATE, COMPANY_ID, ORIGINAL_QTY, CREATE_DATE, USER_ID, INTO_DATE)
            VALUES (:I_SSN_ID, :W_PRODUCT_SSN_ID, :WH_ID, :LOCN_ID, :WK_LABEL_CURQTY, :WK_PROD_STATUS, :OBJECT, 'NOW', :WK_OWNER, :WK_LABEL_CURQTY, :TRANS_DATE, :WK_USER, :TRANS_DATE); 
         END
      
         P_SSN_ID = P_SSN_ID + 1;

         END
      END /* IF SSN_METHOD */

   IF (WK_GENERATE_SSN_METHOD = '|GRN=4|LINE=2|SUFFIX=2,3|' ) THEN
   BEGIN

        /* THIS TIME THE LAST LINE NUMBER WILL REMAIN THE SAME. ONLY PALLET NO WILL KEEP CHANGING FOR NEW ISSNS */
        /* WK_LAST_PALLET_NO HAS ALREADY BEEN INITIALIZED TO ZERO */
        /* P_LAST_LINE_NO CONTAINS THE LAST VALUE OF WK_LAST_LINE_NO */
        /* W_SSN_ID CONTAINS THE ORIGINAL VALUE OF SSN. */

        I_PALLET_NO = 0;
        WHILE (I_PALLET_NO < LABEL_NO) DO
        BEGIN

           /* DURING UPDATES THIS UPDATE WILL BE WITHIN A SESSION. THERE IS A MINOR CHANCE OF TWO PALLETS HAVING THE SAME NUMBER AS THIS CHANGE CANNOT BE COMMITTED IN A TRIGGER */
           SELECT LAST_PALLET_NO FROM GRN WHERE GRN = :GRN INTO :WK_LAST_PALLET_NO;
           WK_LAST_PALLET_NO = WK_LAST_PALLET_NO + 1;
           UPDATE GRN SET LAST_PALLET_NO = :WK_LAST_PALLET_NO WHERE GRN = :GRN;

           IF (WK_LAST_PALLET_NO < 10) THEN
           BEGIN
              P_LAST_PALLET_NO = '0' || WK_LAST_PALLET_NO;
           END
           ELSE
           BEGIN
             P_LAST_PALLET_NO = WK_LAST_PALLET_NO;
           END


        /* tHE FIRST TIME THE LAST_PALLET_NO IS ALWAYS 0 */

          I_SSN_ID = GRN || P_LAST_LINE_NO || P_LAST_PALLET_NO;
          /* 170707 1st issn */
          IF (WK_1ST_ISSN = '') THEN
          BEGIN
             WK_1ST_ISSN = I_SSN_ID;
          END

         IF (WK_A_PROD = 0) THEN
         BEGIN
/*
            VALUES (:I_SSN_ID, :WH_ID, :LOCN_ID, :GRN, 'TS', 'NOW', :WK_LABEL_CURQTY, :WK_LABEL_CURQTY, :WK_LOADNO, 'NOW', :WK_LOAD_LINE_NO, :OBJECT);
            VALUES (:I_SSN_ID, :I_SSN_ID, :WH_ID, :LOCN_ID, :WK_LABEL_CURQTY, 'TS');
*/
            /* Insert data into SSN table */
            INSERT INTO SSN (SSN_ID, WH_ID, LOCN_ID, GRN, STATUS_SSN, LABEL_DATE, ORIGINAL_QTY,
                    CURRENT_QTY, PO_ORDER, PO_RECEIVE_DATE, PO_LINE, SUPPLIER_ID, COMPANY_ID)
            VALUES (:I_SSN_ID, :WH_ID, :LOCN_ID, :GRN, :WK_STATUS, 'NOW', :WK_LABEL_CURQTY, :WK_LABEL_CURQTY, :WK_LOADNO, 'NOW', :WK_LOAD_LINE_NO, :WK_SUPPLIER, :WK_OWNER);
            INSERT INTO ISSN (SSN_ID, ORIGINAL_SSN, WH_ID, LOCN_ID, CURRENT_QTY, ISSN_STATUS, LABEL_DATE, COMPANY_ID, ORIGINAL_QTY, CREATE_DATE, USER_ID, INTO_DATE)
            VALUES (:I_SSN_ID, :I_SSN_ID, :WH_ID, :LOCN_ID, :WK_LABEL_CURQTY, :WK_STATUS, 'NOW', :WK_OWNER, :WK_LABEL_CURQTY, :TRANS_DATE, :WK_USER, :TRANS_DATE);
         END
         IF (WK_A_PROD = 1) THEN
         BEGIN
            INSERT INTO ISSN (SSN_ID, ORIGINAL_SSN, WH_ID, LOCN_ID, CURRENT_QTY, ISSN_STATUS, PROD_ID, LABEL_DATE, COMPANY_ID, ORIGINAL_QTY, CREATE_DATE, USER_ID, INTO_DATE)
            VALUES (:I_SSN_ID, :W_PRODUCT_SSN_ID, :WH_ID, :LOCN_ID, :WK_LABEL_CURQTY, :WK_PROD_STATUS, :OBJECT, 'NOW', :WK_OWNER, :WK_LABEL_CURQTY, :TRANS_DATE, :WK_USER, :TRANS_DATE);
         END

         I_PALLET_NO = I_PALLET_NO + 1;
        END /* WHILE I_PALLETNO < LABEL_NO */
   END /* if ssn method is |GRN=4|LINE=2|SUFFIX=2,3| */

   /* for P response 170707 */
   WK_RESPONSE_TXT = :WK_RESPONSE_TXT || :WK_1ST_ISSN || '|' || :WK_SSNQTY2 || '|' || :WK_LABELQTY2 || '|' || :WK_PRINTER || '|' ;   
   WK_RESPONSE_TXT2 = '|' || :WK_1ST_ISSN || '|' || :WK_SSNQTY2 || '|' || :WK_LABELQTY2 ;


      
      /* append the file name to the directory*/
      
   IF (WK_GENERATE_LABEL_TEXT = 'T') THEN
   BEGIN
      IF (WK_A_PROD = 0) THEN
      BEGIN
         WK_FILENAME = WK_DIRECTORY || 'LOAD2.1xt';
         WK_LABEL_LINE = '"' || W_SSN_ID || '","' ||
             WK_LOADNO || '","' ||
             LABEL_NO || '"';
         WK_HAVE_FILE_2 = 1;
         WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_LABEL_LINE);
         IF (WK_RESULT <> 0) THEN
         BEGIN
            WK_FILENAME = WK_DIRECTORY || 'LOAD2.2xt';
            WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_LABEL_LINE);
            WK_HAVE_FILE_2 = -1;
         END
      END
      IF (WK_A_PROD = 1) THEN
      BEGIN
         WK_FILENAME = WK_DIRECTORY || 'Product2.1xt';
/*
             WK_SSNQTY2 || '"' || CHR(10) ;
*/
         IF (WK_A_PO = 0) THEN
         BEGIN
/*
            WK_LABEL_LINE = '"' || W_SSN_ID || '","' || 
                WK_LABELQTY2 || '","' || 
                OBJECT || '","' || 
                WK_PROD_DESC || '","' || 
                WK_DATE || '","' || 
                WK_SSNQTY2 || '"'  ;
*/
            WK_LABEL_LINE = '"' || W_SSN_ID || '","' || 
                WK_LABELQTY2 || '","' || 
                OBJECT || '","' || 
                WK_PROD_DESC || '","' || 
                WK_DATE || '","' || 
                WK_SSNQTY2 || '","' || 
                WK_WEIGHT_X || '","' ||
                WK_WEIGHT_UOM || '","' ||
                WK_PUTLOCN_1 || '","' ||
                WK_PUTLOCN_2 || '","' ||
                WK_LOADNO || '","' ||
                GRN || '","' ||
                W_PRODUCT_SSN_ID || '","' ||
                WK_ALTPROD || '","' ||
                WK_STD_PALLET_DESC || '","' ||
                WK_NON_PALLET_DESC || '","' ||
                WK_ISSUE_UOM || '","' ||
                WK_TOT_INNER || '","' ||
                WK_TOT_OUTER || '","' ||
                WK_INSTR || '","' ||
                WK_PRINTER  || '","' ||
             WK_TEMPERATURE_ZONE || '"' ;
         END
         ELSE
         BEGIN
            WK_LABEL_LINE = '"' || W_SSN_ID || '","' || 
                WK_LABELQTY2 || '","' || 
                OBJECT || '","' || 
                WK_PROD_DESC || '","' || 
                WK_DATE || '","' || 
                WK_SSNQTY2 || '","'  ||
                WK_WEIGHT_X || '","' ||
                WK_WEIGHT_UOM || '","' ||
                WK_PUTLOCN_1 || '","' ||
                WK_PUTLOCN_2 || '","' ||
                WK_LOADNO || '","' ||
                GRN || '","' ||
                W_PRODUCT_SSN_ID || '","' ||
                WK_ALTPROD || '","' ||
                WK_STD_PALLET_DESC || '","' ||
                WK_NON_PALLET_DESC || '","' ||
                WK_ISSUE_UOM || '","' ||
                WK_TOT_INNER || '","' ||
                WK_TOT_OUTER || '","' ||
                WK_INSTR || '","' ||
                WK_PRINTER || '","' ||
             WK_TEMPERATURE_ZONE || '"' ;
         END
         WK_HAVE_FILE_2 = 1;
         WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_LABEL_LINE);
         IF (WK_RESULT <> 0) THEN
         BEGIN
            WK_FILENAME = WK_DIRECTORY || 'Product2.2xt';
            WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_LABEL_LINE);
            WK_HAVE_FILE_2 = -1;
         END
      END
   END
   IF (WK_A_PROD = 0) THEN
   BEGIN
      IF (WK_HAVE_FILE_1 = 1) THEN
      BEGIN
         /* rename load.1xt to load.txt */
         WK_FILENAME = WK_DIRECTORY || 'LOAD.1xt';
         WK_FILENAME2 = WK_DIRECTORY || 'LOAD.txt';
         WK_RESULT = FILE_RENAME(WK_FILENAME, WK_FILENAME2);
      END
      IF (WK_HAVE_FILE_1 = -1) THEN
      BEGIN
         /* rename load.2xt to load.txt */
         WK_FILENAME = WK_DIRECTORY || 'LOAD.2xt';
         WK_FILENAME2 = WK_DIRECTORY || 'LOAD.txt';
         WK_RESULT = FILE_RENAME(WK_FILENAME, WK_FILENAME2);
      END
      IF (WK_HAVE_FILE_2 = 1) THEN
      BEGIN
         /* rename load2.1xt to load2.txt */
         WK_FILENAME = WK_DIRECTORY || 'LOAD2.1xt';
         WK_FILENAME2 = WK_DIRECTORY || 'LOAD2.txt';
         WK_RESULT = FILE_RENAME(WK_FILENAME, WK_FILENAME2);
      END
      IF (WK_HAVE_FILE_2 = -1) THEN
      BEGIN
         /* rename load2.2xt to load2.txt */
         WK_FILENAME = WK_DIRECTORY || 'LOAD2.2xt';
         WK_FILENAME2 = WK_DIRECTORY || 'LOAD2.txt';
         WK_RESULT = FILE_RENAME(WK_FILENAME, WK_FILENAME2);
      END
   END
   IF (WK_A_PROD = 1) THEN
   BEGIN
      IF (WK_HAVE_FILE_1 = 1) THEN
      BEGIN
         /* rename product.1xt to product.txt */
         WK_FILENAME = WK_DIRECTORY || 'Product.1xt';
         WK_FILENAME2 = WK_DIRECTORY || 'Product.txt';
         WK_RESULT = FILE_RENAME(WK_FILENAME, WK_FILENAME2);
      END
      IF (WK_HAVE_FILE_1 = -1) THEN
      BEGIN
         /* rename product.2xt to product.txt */
         WK_FILENAME = WK_DIRECTORY || 'Product.2xt';
         WK_FILENAME2 = WK_DIRECTORY || 'Product.txt';
         WK_RESULT = FILE_RENAME(WK_FILENAME, WK_FILENAME2);
      END
      IF (WK_HAVE_FILE_2 = 1) THEN
      BEGIN
         /* rename product2.1xt to product2.txt */
         WK_FILENAME = WK_DIRECTORY || 'Product2.1xt';
         WK_FILENAME2 = WK_DIRECTORY || 'Product2.txt';
         WK_RESULT = FILE_RENAME(WK_FILENAME, WK_FILENAME2);
      END
      IF (WK_HAVE_FILE_2 = -1) THEN
      BEGIN
         /* rename product2.2xt to product2.txt */
         WK_FILENAME = WK_DIRECTORY || 'Product2.2xt';
         WK_FILENAME2 = WK_DIRECTORY || 'Product2.txt';
         WK_RESULT = FILE_RENAME(WK_FILENAME, WK_FILENAME2);
      END
   END
    /* Update transactions table */        
    /* EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully'); */
    IF (WK_TRN_CODE = 'P') THEN
    BEGIN
       WK_RESPONSE_TXT = :WK_RESPONSE_TXT || 'Processed successfully';
       EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', :WK_RESPONSE_TXT);
    END
    ELSE
    BEGIN
       EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');
    END
END /* IF GENERATE LABEL TEXT. */

   if (WK_GENERATE_LABEL_TEXT = 'F') then
   BEGIN
      IF (WK_TRN_CODE = 'P') THEN
    BEGIN
         if (WK_RESPONSE_TXT2 = '') then
         BEGIN
           WK_RESPONSE_TXT2 = '|||';
         END
       WK_RESPONSE_FINAL = :WK_RESPONSE_TXT1 || :WK_RESPONSE_TXT2 || '|' || :WK_PRINTER;
       WK_RESPONSE_FINAL = :WK_RESPONSE_FINAL || '|' || 'Processed successfully';
       EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', :WK_RESPONSE_FINAL);
    END
    ELSE
    BEGIN
       EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');
    END
   END

END ^

SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
