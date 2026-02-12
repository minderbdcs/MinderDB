COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;
 
CREATE OR ALTER PROCEDURE PC_DSDX (RECORD_ID RECORD_ID,
WH_ID WH_ID ,
LOCN_ID LOCN_ID ,
OBJECT OBJECT ,
TRN_TYPE TRN_TYPE ,
TRN_CODE TRN_CODE ,
TRN_DATE TIMESTAMP,
REFERENCE REFERENCE ,
QTY QTY,
PERSON_ID PERSON ,
DEVICE_ID DEVICE_ID ,
SUB_LOCN LOCN_ID )
AS 
/* DECLARE VARIABLE WK_CONSIGNMENT VARCHAR(40); */
DECLARE VARIABLE WK_CONSIGNMENT VARCHAR(1024);
DECLARE VARIABLE WK_DESPATCH INTEGER;
DECLARE VARIABLE WK_SSN VARCHAR(20);
DECLARE VARIABLE WK_SSN_SSN VARCHAR(20);
DECLARE VARIABLE WK_LABEL VARCHAR(8);
DECLARE VARIABLE WK_SALES_PRICE NUMERIC(9, 3);
DECLARE VARIABLE WK_WARRANTY VARCHAR(50);
DECLARE VARIABLE WK_DETAIL_STATUS CHAR(2);
DECLARE VARIABLE WK_DAYS INTEGER;
DECLARE VARIABLE WK_EXPIRY_DATE TIMESTAMP;
DECLARE VARIABLE WK_QTY_TOGET INTEGER;
DECLARE VARIABLE WK_LOCN VARCHAR(10);
DECLARE VARIABLE WK_REASON VARCHAR(70);
DECLARE VARIABLE WK_DETAIL_ID INTEGER;
DECLARE VARIABLE WK_FOUND INTEGER;
DECLARE VARIABLE WK_PICKED_QTY INTEGER;
DECLARE VARIABLE WK_ORDER_QTY INTEGER;
DECLARE VARIABLE WK_PRICE_EXT INTEGER;
/* DECLARE VARIABLE WK_ORDER VARCHAR(15); */
DECLARE VARIABLE WK_ORDER PICK_ORDER;
DECLARE VARIABLE WK_ORDER_TYPE CHAR(2);
DECLARE VARIABLE WK_RETURN_DATE TIMESTAMP;
/* DECLARE VARIABLE WK_PERSON VARCHAR(10); */
DECLARE VARIABLE WK_PERSON PERSON;
DECLARE VARIABLE WK_WH_ID CHAR(2);
DECLARE VARIABLE WK_INSTRUCTION1 VARCHAR(8196);
DECLARE VARIABLE WK_APPROVED_BY VARCHAR(10);
DECLARE VARIABLE WK_ORDER_RETURN_DATE TIMESTAMP;
DECLARE VARIABLE LO_NUMBER INTEGER;
DECLARE VARIABLE LOAN_TYPE VARCHAR(2);
DECLARE VARIABLE LO_LINE VARCHAR(4);
DECLARE VARIABLE WK_PI_PROD_ID VARCHAR(30);
DECLARE VARIABLE WK_PI_SSN_ID VARCHAR(20);
DECLARE VARIABLE LOAN_QTY Integer;
DECLARE VARIABLE LOAN_COMMENTS VARCHAR(255);
DECLARE VARIABLE WK_DESPATCH_DATE TIMESTAMP;
DECLARE VARIABLE WK_GM_MESSAGE VARCHAR(10);
DECLARE VARIABLE WK_T4_DELIM CHAR(1);
DECLARE VARIABLE WK_T4_TRAN_DATA TRN_DATA;
DECLARE VARIABLE WK_T4_SOURCE VARCHAR(512);
DECLARE VARIABLE WK_NEW_RECORD INTEGER;
DECLARE VARIABLE WK_CN_PRIORITY SMALLINT;
DECLARE VARIABLE WK_DATE TIMESTAMP;
DECLARE VARIABLE WK_DO_UCIS CHAR(1);
DECLARE VARIABLE WK_DO_EXPORT_DESPATCH CHAR(1);
DECLARE VARIABLE WK_PRINTER CHAR(2);
DECLARE VARIABLE WK_PARTIAL_PICK CHAR(2);
DECLARE VARIABLE WK_PARTIAL_DESPATCH CHAR(2);
DECLARE VARIABLE WK_DSDX_DETAIL_STATUS VARCHAR(40);
DECLARE VARIABLE WK_IS_WH_ID CHAR(2);
DECLARE VARIABLE WK_LOCN_MOVEABLE CHAR(1);
DECLARE VARIABLE WK_PI_PICK_LINE_STATUS VARCHAR(2);
DECLARE VARIABLE WK_PO_WH_ID VARCHAR(2);
/* DECLARE VARIABLE WK_PO_COMPANY_ID VARCHAR(20); */
DECLARE VARIABLE WK_PO_COMPANY_ID COMPANY;
DECLARE VARIABLE WK_PROD_AVAILABLE_QTY INTEGER;
DECLARE VARIABLE WK_RECORD  INTEGER;
/* DECLARE VARIABLE WK_IS_PROD_ID VARCHAR(30); */
DECLARE VARIABLE WK_IS_PROD_ID PRODUCT;
/* DECLARE VARIABLE WK_IS_COMPANY_ID VARCHAR(20); */
DECLARE VARIABLE WK_IS_COMPANY_ID COMPANY;
DECLARE VARIABLE WK_OP_DO_EMAIL_PACK VARCHAR(50);
DECLARE VARIABLE WK_OP_REPORT_NO VARCHAR(50);
DECLARE VARIABLE WK_OP_RPT_CODE  VARCHAR(40);
/* DECLARE VARIABLE WK_PO_PERSON_ID VARCHAR(10); */
DECLARE VARIABLE WK_PO_PERSON_ID PERSON;
DECLARE VARIABLE WK_PO_CUSTOMER_PO_WO CUSTOMER_PO_WO;
DECLARE VARIABLE WK_PE_EMAIL VARCHAR(50);
DECLARE VARIABLE WK_PE_INVOICE_PS VARCHAR(1);
DECLARE VARIABLE WK_PE_INVOICE_PI VARCHAR(1);
DECLARE VARIABLE WK_PE_INVOICE_TI VARCHAR(1);
DECLARE VARIABLE WK_CN_EVENT_DIRECTORY VARCHAR(75);
DECLARE VARIABLE WK_EMAIL_FILENAME VARCHAR(255);
DECLARE VARIABLE WK_EMAIL_RESULT INTEGER;
DECLARE VARIABLE WK_EMAIL_BUFFER VARCHAR(255);
DECLARE VARIABLE WK_LOG_FILENAME VARCHAR(255);
DECLARE VARIABLE WK_LOG_RESULT INTEGER;
DECLARE VARIABLE WK_CM_PS_REPORT_ID INTEGER;
DECLARE VARIABLE WK_CM_PI_REPORT_ID INTEGER;
DECLARE VARIABLE WK_CM_TI_REPORT_ID INTEGER;
DECLARE VARIABLE WK_CM_CC_EMAIL VARCHAR(50);
DECLARE VARIABLE WK_RT_URI      VARCHAR(255);
DECLARE VARIABLE WK_PO_PICK_ORDER_NO PICK_ORDER;

BEGIN 
 /* 
           reference is connote

 for SO type Orders
        in DSDX calc warranty date based on warranty_term and 
  the days specified in the table warranty 
  and save the sales price from the pick item into the ssn

  if the current_qty <> 0
   move current qty to zero and prev_qty has the current_qty
  move to XD repository and status to DX

  check pick items complete
  if not complete must create a new line for it

 for TO type Orders
        in DSDX create/update loan order from the pick_order  

  update the loan fields in the ssn

  move to repository of order (via person to repositorys person)
 location 'INTRANST'
 and status to DI

  check pick items complete
  if not complete must create a new line for it
08/11/16 add a record to transactions archive for DSDX I
         with the order no and company populated.
*/
    WK_RECORD = RECORD_ID;
    /* DELETE FROM TRANSACTIONS_WORK
       WHERE RECORD_ID = :WK_RECORD; */
    WK_DESPATCH_DATE = ZEROTIME(TRN_DATE);
    WK_DATE = TRN_DATE;
    WK_CN_PRIORITY = 0;
    WK_CN_EVENT_DIRECTORY = '';
    WK_LOG_FILENAME = '/data/tmp/DSDX.log';
           WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'DSDX start'); 
    SELECT DEFAULT_PICK_PRIORITY, 
       SEND_UCIS_V4, 
       EXPORT_DESPATCH, 
       EXPORT_DESPATCH_PRINTER,
       PICK_DETAIL_DSDX_STATUS ,
       DB_EVENT_DIRECTORY
    FROM CONTROL 
    INTO :WK_CN_PRIORITY, 
       :WK_DO_UCIS, 
       :WK_DO_EXPORT_DESPATCH, 
       :WK_PRINTER,
       :WK_DSDX_DETAIL_STATUS,
       :WK_CN_EVENT_DIRECTORY;
    /* get whether to email a packing slip */
    /* 'DSDX','EMAIL-PACKINGSLIP','F' */
    WK_OP_DO_EMAIL_PACK = 'F';
    SELECT DESCRIPTION FROM OPTIONS WHERE GROUP_CODE = 'DSDX' AND CODE = 'EMAIL-PACKING_SLIP'
    INTO :WK_OP_DO_EMAIL_PACK;
    IF (WK_OP_DO_EMAIL_PACK IS NULL) THEN
    BEGIN
       WK_OP_DO_EMAIL_PACK = 'F';
    END
    /* must get the consignment */
    WK_CONSIGNMENT = V4ALLTRIM(REFERENCE);
           WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'trimed reference = connote'); 
    FOR SELECT DESPATCH_ID 
        FROM PICK_DESPATCH 
        WHERE AWB_CONSIGNMENT_NO = :WK_CONSIGNMENT
          AND DESPATCH_STATUS = 'DC'
        INTO :WK_DESPATCH
    DO
    BEGIN
           WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'got pick_despatch'); 
           WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, :WK_DESPATCH); 
       FOR SELECT PID.SSN_ID, PID.PICK_LABEL_NO , PI.WARRANTY_TERM, PID.PICK_DETAIL_STATUS, PID.PICK_DETAIL_ID, PI.PICKED_QTY, PI.PICK_ORDER_QTY, PO.PICK_ORDER_TYPE, PO.PICK_ORDER 
           FROM PICK_ITEM_DETAIL PID
           JOIN PICK_ITEM PI ON PI.PICK_LABEL_NO = PID.PICK_LABEL_NO
           JOIN PICK_ORDER PO ON PO.PICK_ORDER = PI.PICK_ORDER
           WHERE PID.DESPATCH_ID = :WK_DESPATCH
           INTO :WK_SSN, :WK_LABEL, :WK_WARRANTY, :WK_DETAIL_STATUS, :WK_DETAIL_ID, :WK_PICKED_QTY, :WK_ORDER_QTY, :WK_ORDER_TYPE, :WK_PO_PICK_ORDER_NO 
       DO
       BEGIN
           WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'got pick_item_detail'); 
           WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'SSN'); 
           WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, :WK_SSN); 
           WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, :WK_DETAIL_ID); 
           WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'Order'); 
           WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, :WK_PO_PICK_ORDER_NO); 
          IF (WK_DETAIL_STATUS = 'DC') THEN
          BEGIN
             IF (WK_ORDER_TYPE = 'SO') THEN
             BEGIN
                WK_DAYS = 0;
                SELECT WARRANTY_DAYS FROM WARRANTY
                WHERE WARRANTY_CODE = :WK_WARRANTY
                INTO :WK_DAYS;
                IF (WK_DAYS IS NULL) THEN
                   WK_DAYS = 0;
                IF (WK_DAYS = 0) THEN
                   /* WK_EXPIRY_DATE = TRN_DATE; */
                   WK_EXPIRY_DATE = WK_DESPATCH_DATE;
                ELSE
                   WK_EXPIRY_DATE = ADD_TIME(:WK_DESPATCH_DATE, :WK_DAYS, 0,0,0,0);
                WK_IS_PROD_ID = NULL;
                WK_IS_COMPANY_ID = NULL;
                SELECT ORIGINAL_SSN, CURRENT_QTY,LOCN_ID, PROD_ID, COMPANY_ID FROM ISSN
                WHERE SSN_ID = :WK_SSN
                INTO :WK_SSN_SSN, :WK_QTY_TOGET, :WK_LOCN, :WK_IS_PROD_ID, :WK_IS_COMPANY_ID;
                /* ok now have the ssn */
                SELECT SALE_PRICE, PICK_ORDER FROM PICK_ITEM 
                WHERE PICK_LABEL_NO = :WK_LABEL
                INTO :WK_SALES_PRICE, :WK_ORDER;
                 INSERT INTO TRANSACTIONS_WORK(
                    RECORD_ID,
                    OBJECT,
                    QTY)
                    VALUES(
                    :WK_RECORD,
                    :WK_ORDER ,
                    :WK_DESPATCH
                    );
   
                IF (WK_QTY_TOGET <> 0) THEN
                BEGIN
                   UPDATE ISSN SET ISSN_STATUS = 'DX',
                       PREV_PREV_WH_ID = PREV_WH_ID,
                       PREV_PREV_LOCN_ID = PREV_LOCN_ID,
                       PREV_WH_ID = WH_ID,
                       PREV_LOCN_ID = LOCN_ID,
                       WH_ID = 'XD',
                       LOCN_ID = '00000000',
                       PREV_QTY = CURRENT_QTY,
                       INTO_DATE = :TRN_DATE,
                       DESPATCHED_DATE = :WK_DESPATCH_DATE,
                       CURRENT_QTY = 0
                   WHERE SSN_ID = :WK_SSN;
                END
                ELSE
                BEGIN
                   /* zero qty item */
                   UPDATE ISSN SET ISSN_STATUS = 'DX',
                       PREV_PREV_WH_ID = PREV_WH_ID,
                       PREV_PREV_LOCN_ID = PREV_LOCN_ID,
                       PREV_WH_ID = WH_ID,
                       PREV_LOCN_ID = LOCN_ID,
                       INTO_DATE = :TRN_DATE,
                       DESPATCHED_DATE = :WK_DESPATCH_DATE,
                       WH_ID = 'XD',
                       LOCN_ID = '00000000'
                   WHERE SSN_ID = :WK_SSN;
                END
                WK_PRICE_EXT = WK_SALES_PRICE * WK_QTY_TOGET;
                WK_FOUND = 0;
                SELECT 1 FROM SSN 
                WHERE SSN_ID = :WK_SSN_SSN
                  AND DISPOSAL_PRICE IS NULL
                INTO :WK_FOUND;
                IF (WK_FOUND IS NULL) THEN
                   WK_FOUND = 0;
                IF (WK_FOUND = 0) THEN
                BEGIN
                   UPDATE SSN SET DISPOSAL_PRICE = DISPOSAL_PRICE + :WK_PRICE_EXT,
                               WARRANTY_EXPIRY_DATE = :WK_EXPIRY_DATE,
                               CURRENT_QTY = CURRENT_QTY - :WK_QTY_TOGET
                   WHERE SSN_ID = :WK_SSN_SSN;
                END
                ELSE
                BEGIN
                   UPDATE SSN SET DISPOSAL_PRICE = :WK_PRICE_EXT,
                               WARRANTY_EXPIRY_DATE = :WK_EXPIRY_DATE,
                               CURRENT_QTY = CURRENT_QTY - :WK_QTY_TOGET
                   WHERE SSN_ID = :WK_SSN_SSN;
                END
                WK_REASON = 'Despatched ' || :WK_QTY_TOGET || ' to User ' || :PERSON_ID || ' ISSN ' || :WK_SSN ;
                IF (WK_SSN_SSN IS NOT NULL) THEN
                BEGIN
                   EXECUTE PROCEDURE ADD_SSN_HIST('XD', :WK_LOCN, :WK_SSN_SSN, 
                          :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                          :WK_REASON, 'ON TO TRUCK' , :WK_QTY_TOGET, :PERSON_ID, :DEVICE_ID); 
                END
                BEGIN
                   /* now add transactions archive for this ssn_id */
                   INSERT INTO TRANSACTIONS_ARCHIVE
                      (WH_ID, LOCN_ID, OBJECT, TRN_TYPE, TRN_CODE, TRN_DATE, REFERENCE,
                       QTY, ERROR_TEXT, INSTANCE_ID, EXPORTED, SUB_LOCN_ID, INPUT_SOURCE,
                       PERSON_ID, DEVICE_ID, RECORD_ID, PROD_ID, COMPANY_ID, ORDER_NO)
                    SELECT 'XD', :WK_LOCN, :WK_SSN, :TRN_TYPE, 'I', :TRN_DATE, :REFERENCE,
                       :WK_QTY_TOGET, 'Processed successfully', INSTANCE_ID, EXPORTED, :SUB_LOCN, INPUT_SOURCE,
                       :PERSON_ID, :DEVICE_ID, :RECORD_ID , :WK_IS_PROD_ID, :WK_IS_COMPANY_ID, :WK_PO_PICK_ORDER_NO
                    FROM TRANSACTIONS
                    WHERE RECORD_ID = :RECORD_ID;
                END
             END /* end of order type SO */
             ELSE
             BEGIN
                IF (WK_ORDER_TYPE = 'TO') THEN
                BEGIN
                   WK_IS_PROD_ID = NULL;
                   WK_IS_COMPANY_ID = NULL;
                   SELECT ORIGINAL_SSN, CURRENT_QTY,LOCN_ID, WH_ID , PROD_ID, COMPANY_ID
                   FROM ISSN
                   WHERE SSN_ID = :WK_SSN
                   INTO :WK_SSN_SSN, :WK_QTY_TOGET, :WK_LOCN, :WK_IS_WH_ID, :WK_IS_PROD_ID, :WK_IS_COMPANY_ID;
                   WK_LOCN_MOVEABLE = 'F';
                   SELECT MOVEABLE_LOCN
                   FROM LOCATION
                   WHERE WH_ID = :WK_IS_WH_ID
                   AND   LOCN_ID = :WK_LOCN
                   INTO :WK_LOCN_MOVEABLE;
                   IF (WK_LOCN_MOVEABLE IS NULL) THEN
                   BEGIN
                      WK_LOCN_MOVEABLE = 'F';
                   END
                   /* ok now have the ssn */
                   SELECT RETURN_DATE, PICK_ORDER FROM PICK_ITEM 
                   WHERE PICK_LABEL_NO = :WK_LABEL
                   INTO :WK_RETURN_DATE, :WK_ORDER;
                   SELECT PERSON_ID FROM PICK_ORDER 
                   WHERE PICK_ORDER = :WK_ORDER
                   INTO :WK_PERSON;
                   WK_WH_ID = NULL;
                 INSERT INTO TRANSACTIONS_WORK(
                    RECORD_ID,
                    OBJECT,
                    QTY)
                    VALUES(
                    :WK_RECORD,
                    :WK_ORDER ,
                    :WK_DESPATCH
                    );
                   SELECT D_WH_ID FROM PICK_ORDER
                   WHERE PICK_ORDER = :WK_ORDER
                   INTO :WK_WH_ID;
                   IF (WK_WH_ID IS NULL) THEN
                   BEGIN
                      SELECT FIRST 1 WH_ID FROM WAREHOUSE
                      WHERE  PERSON_ID = :WK_PERSON
                      INTO :WK_WH_ID;
                      UPDATE PICK_ORDER 
                      SET D_WH_ID = :WK_WH_ID
                      WHERE PICK_ORDER = :WK_ORDER;
                   END
                   /* need wk_days as diff between wk_return_date
                      and trn_date */
                   WK_DAYS = DIFFDATE(TRN_DATE, WK_RETURN_DATE, 4);
                   /* if despatch location is a mobile then leave in that location
                         and shift the location into the new warehouse 
                      otherwise do the transfer */
                   /* update location */
                   IF (WK_LOCN_MOVEABLE = 'T') THEN
                   BEGIN
                      UPDATE LOCATION SET CURRENT_WH_ID = :WK_WH_ID
                      WHERE WH_ID = :WK_IS_WH_ID
                      AND   LOCN_ID = :WK_LOCN;
                      UPDATE ISSN SET ISSN_STATUS = 'DI'
                      WHERE SSN_ID = :WK_SSN;
                   END
                   ELSE
                   BEGIN
                      UPDATE ISSN SET ISSN_STATUS = 'DI',
                          PREV_PREV_WH_ID = PREV_WH_ID,
                          PREV_PREV_LOCN_ID = PREV_LOCN_ID,
                          PREV_WH_ID = WH_ID,
                          PREV_LOCN_ID = LOCN_ID,
                          WH_ID = :WK_WH_ID,
                          LOCN_ID = 'INTRANST'
                      WHERE SSN_ID = :WK_SSN;
                   END
                   UPDATE SSN SET 
                               LEASE_EXPIRY_DATE = :WK_RETURN_DATE,
                               LOAN_PERIOD = 'D',
                               LOAN_PERIOD_NO = :WK_DAYS,
                               LOAN_STATUS = 'L'
                   WHERE SSN_ID = :WK_SSN_SSN;
                   WK_REASON = 'Despatched ' || :WK_QTY_TOGET || ' to User ' || :PERSON_ID || ' ISSN ' || :WK_SSN ;
                   IF (WK_SSN_SSN IS NOT NULL) THEN
                   BEGIN
                      EXECUTE PROCEDURE ADD_SSN_HIST(:WK_WH_ID, 'INTRANST', :WK_SSN_SSN, 
                             :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                             :WK_REASON, 'ON TO TRUCK' , :WK_QTY_TOGET, :PERSON_ID, :DEVICE_ID); 
                   END
                   BEGIN
                      IF (WK_LOCN_MOVEABLE = 'T') THEN
                      BEGIN
                         /* now add transactions archive for this ssn_id */
                         INSERT INTO TRANSACTIONS_ARCHIVE
                            (WH_ID, LOCN_ID, OBJECT, TRN_TYPE, TRN_CODE, TRN_DATE, REFERENCE,
                             QTY, ERROR_TEXT, INSTANCE_ID, EXPORTED, SUB_LOCN_ID, INPUT_SOURCE,
                             PERSON_ID, DEVICE_ID, RECORD_ID, PROD_ID, COMPANY_ID, ORDER_NO)
                          SELECT :WK_WH_ID, :WK_LOCN, :WK_SSN, :TRN_TYPE, 'I', :TRN_DATE, :REFERENCE,
                             :WK_QTY_TOGET, 'Processed successfully', INSTANCE_ID, EXPORTED, :SUB_LOCN, INPUT_SOURCE,
                             :PERSON_ID, :DEVICE_ID, :RECORD_ID ,:WK_IS_PROD_ID, :WK_IS_COMPANY_ID, :WK_PO_PICK_ORDER_NO
                          FROM TRANSACTIONS
                          WHERE RECORD_ID = :RECORD_ID;
                       END
                       ELSE
                       BEGIN
                         /* now add transactions archive for this ssn_id */
                         INSERT INTO TRANSACTIONS_ARCHIVE
                            (WH_ID, LOCN_ID, OBJECT, TRN_TYPE, TRN_CODE, TRN_DATE, REFERENCE,
                             QTY, ERROR_TEXT, INSTANCE_ID, EXPORTED, SUB_LOCN_ID, INPUT_SOURCE,
                             PERSON_ID, DEVICE_ID, RECORD_ID, PROD_ID, COMPANY_ID, ORDER_NO)
                          SELECT :WK_WH_ID, 'INTRANST', :WK_SSN, :TRN_TYPE, 'I', :TRN_DATE, :REFERENCE,
                             :WK_QTY_TOGET, 'Processed successfully', INSTANCE_ID, EXPORTED, :SUB_LOCN, INPUT_SOURCE,
                             :PERSON_ID, :DEVICE_ID, :RECORD_ID ,:WK_IS_PROD_ID, :WK_IS_COMPANY_ID, :WK_PO_PICK_ORDER_NO
                          FROM TRANSACTIONS
                          WHERE RECORD_ID = :RECORD_ID;
                       END
                   END
                   /* check loan order */
                   SELECT LOAN_ORDER_NO FROM LOAN_ORDER
                   WHERE PICK_ORDER = :WK_ORDER
                   INTO :LO_NUMBER;
                   IF (LO_NUMBER IS NULL) THEN
                   BEGIN
                      SELECT SPECIAL_INSTRUCTIONS1, APPROVED_DESP_BY, RETURN_DATE
                      FROM PICK_ORDER
                      WHERE PICK_ORDER = :WK_ORDER
                      INTO :WK_INSTRUCTION1, :WK_APPROVED_BY, :WK_ORDER_RETURN_DATE;
                     
                      EXECUTE PROCEDURE GET_LOAN_ID RETURNING_VALUES :LO_NUMBER;
                      LOAN_TYPE = 'TO'; /* Transfer Order */
                      INSERT INTO LOAN_ORDER (LOAN_ORDER_NO, LOAN_ORDER_DATE, STATUS, JOB_NO, COMMENTS, PICK_ORDER, RETURN_DATE, USER_ID, LOAN_TYPE)
                      VALUES (:LO_NUMBER, :TRN_DATE, 'OP', :WK_ORDER, :WK_INSTRUCTION1, :WK_ORDER, :WK_ORDER_RETURN_DATE, :WK_APPROVED_BY, :LOAN_TYPE);
                   END
                   SELECT PICK_ORDER_LINE_NO, PROD_ID, SSN_ID, PICKED_QTY, SPECIAL_INSTRUCTIONS1 
                   FROM PICK_ITEM WHERE PICK_LABEL_NO = :WK_LABEL
                   INTO :LO_LINE, :WK_PI_PROD_ID, :WK_PI_SSN_ID, :LOAN_QTY, :LOAN_COMMENTS;
                   /* check loan line  */
                   WK_FOUND = 0;
                   SELECT 1 FROM LOAN_ORDER_LINE
                   WHERE LOAN_ORDER_NO = :LO_NUMBER
                   AND LOAN_ORDER_LINE_NO = :LO_LINE
                   INTO :WK_FOUND;
                   IF ((WK_FOUND IS NULL) OR (WK_FOUND = 0)) THEN
                   BEGIN
                      INSERT INTO LOAN_ORDER_LINE (LOAN_ORDER_NO, LOAN_ORDER_LINE_NO, SSN_ID, STATUS, PROD_ID, LOAN_QTY, LOAN_TYPE, LOAN_RETURN_DATE, COMMENTS)
                      VALUES (:LO_NUMBER, :LO_LINE, :WK_PI_SSN_ID, 'OP', :WK_PI_PROD_ID, :LOAN_QTY, 'TO', :WK_RETURN_DATE, :LOAN_COMMENTS );
                   END
                   /* check loan history  */
                   WK_FOUND = 0;
                   SELECT 1 FROM LOAN_HISTORY
                   WHERE LOAN_ORDER_NO = :LO_NUMBER
                   AND LOAN_ORDER_LINE_NO = :LO_LINE
                   AND SSN_ID = :WK_PI_SSN_ID
                   INTO :WK_FOUND;
                   IF ((WK_FOUND IS NULL) OR (WK_FOUND = 0)) THEN
                   BEGIN
                      INSERT INTO LOAN_HISTORY (LOAN_ORDER_NO, LOAN_ORDER_LINE_NO, SSN_ID, STATUS, PROD_ID, LOAN_QTY, LOAN_TYPE, RETURN_DATE, COMMENTS)
                      VALUES (:LO_NUMBER, :LO_LINE, :WK_PI_SSN_ID, 'OP', :WK_PI_PROD_ID, :LOAN_QTY, 'TO', :WK_RETURN_DATE, :LOAN_COMMENTS );
                   END
                   ELSE
                   BEGIN
                      UPDATE LOAN_HISTORY SET 
                         STATUS = 'OP', 
                         PROD_ID = :WK_PI_PROD_ID, 
                         LOAN_QTY = :LOAN_QTY, 
                         LOAN_TYPE = 'TO', 
                         RETURN_DATE = :WK_RETURN_DATE, 
                         COMMENTS = :LOAN_COMMENTS 
                      WHERE LOAN_ORDER_NO = :LO_NUMBER
                      AND LOAN_ORDER_LINE_NO = :LO_LINE
                      AND SSN_ID = :WK_PI_SSN_ID;
                   END
                END /* end of order type 'TO' */
             END /* end order order types */
             /* update detail status to stop rerun */
/*
             UPDATE PICK_ITEM_DETAIL 
                    SET PICK_DETAIL_STATUS = 'DX',
                    DEVICE_ID = 'XX'
             WHERE PICK_DETAIL_ID = :WK_DETAIL_ID;
*/
             UPDATE PICK_ITEM_DETAIL 
                    SET PICK_DETAIL_STATUS = :WK_DSDX_DETAIL_STATUS,
                    DEVICE_ID = 'XX'
             WHERE PICK_DETAIL_ID = :WK_DETAIL_ID;
             /* check despatched all of line */
             WK_FOUND = 0;
             SELECT FIRST 1 1 FROM PICK_ITEM_DETAIL
             WHERE PICK_LABEL_NO = :WK_LABEL
               AND PICK_DETAIL_STATUS <> 'DX'
               AND PICK_DETAIL_STATUS <> 'DL'
               AND PICK_DETAIL_STATUS <> 'Dl'
               AND PICK_DETAIL_STATUS <> 'XX'
               AND PICK_DETAIL_STATUS <> 'CN'
               AND PICK_DETAIL_STATUS <> 'CR'
               AND SSN_ID <> ''
               AND SSN_ID <> '0000000000'
/* ==== what about zero qtys on the same line */
               AND QTY_PICKED <> 0
             INTO :WK_FOUND;
             IF (WK_FOUND IS NULL) THEN
                WK_FOUND = 0;
             IF (WK_FOUND = 0) THEN
             BEGIN
                /* no undespatched ssns on item */
                /* UPDATE PICK_ITEM SET PICK_LINE_STATUS = 'DX'
                   WHERE PICK_LABEL_NO = :WK_LABEL; */
                IF (WK_PICKED_QTY < WK_ORDER_QTY) THEN
                BEGIN
                   /* must change line to allow picking of the remaining qty */
                   WK_PARTIAL_PICK = 'T';
                   WK_PARTIAL_DESPATCH = 'N';
                   WK_PI_PROD_ID = NULL;
                   WK_PO_WH_ID = NULL;
                   WK_PO_COMPANY_ID = NULL;
                   SELECT PICK_ORDER.PARTIAL_PICK_ALLOWED, PICK_ITEM.PROD_ID, PICK_ORDER.WH_ID, PICK_ORDER.COMPANY_ID, PICK_ORDER.PARTIAL_DESPATCH_ALLOWED
                      FROM PICK_ITEM
                      JOIN PICK_ORDER ON PICK_ITEM.PICK_ORDER = PICK_ORDER.PICK_ORDER
                      WHERE PICK_ITEM.PICK_LABEL_NO = :WK_LABEL
                      INTO :WK_PARTIAL_PICK, :WK_PI_PROD_ID, :WK_PO_WH_ID, :WK_PO_COMPANY_ID, :WK_PARTIAL_DESPATCH;
                   IF (WK_PARTIAL_PICK IS NULL) THEN
                   BEGIN
                      WK_PARTIAL_PICK = 'T';
                   END
                   IF (WK_PARTIAL_DESPATCH IS NULL) THEN
                   BEGIN
                      WK_PARTIAL_DESPATCH = WK_PARTIAL_PICK;
                   END
                   IF (WK_PARTIAL_DESPATCH = 'N') THEN
                   BEGIN
                      WK_PARTIAL_DESPATCH = WK_PARTIAL_PICK;
                   END
                   IF (WK_PARTIAL_DESPATCH = 'T') THEN
                   BEGIN
                      IF (WK_PARTIAL_PICK = 'T') THEN
                      BEGIN
                         WK_PI_PICK_LINE_STATUS = 'OP' ;
                         UPDATE PICK_ITEM SET PICK_LINE_STATUS = :WK_PI_PICK_LINE_STATUS,
                                DEVICE_ID = NULL,
                                REASON = NULL
                         WHERE PICK_LABEL_NO = :WK_LABEL;
                      END
                      ELSE
                      BEGIN
                         /* must change line to allow picking of the remaining qty */
                         /* UPDATE PICK_ITEM SET PICK_LINE_STATUS = 'DX', */
                         UPDATE PICK_ITEM SET PICK_LINE_STATUS = 'NF',
                                DEVICE_ID = NULL
                         WHERE PICK_LABEL_NO = :WK_LABEL;
                      END
                   END
                   ELSE
                   BEGIN
                      /* must change line to allow picking of the remaining qty */
                      /* UPDATE PICK_ITEM SET PICK_LINE_STATUS = 'DX', */
                      UPDATE PICK_ITEM SET PICK_LINE_STATUS = 'NF',
                             DEVICE_ID = NULL
                      WHERE PICK_LABEL_NO = :WK_LABEL;
                   END
                END
                ELSE
                BEGIN
                   /* must change line to allow picking of the remaining qty */
                   UPDATE PICK_ITEM SET PICK_LINE_STATUS = 'DX', 
                          DEVICE_ID = NULL
                   WHERE PICK_LABEL_NO = :WK_LABEL;
                END
             END
             /* check despatched all of order */
             WK_PARTIAL_PICK = 'T';
             WK_PARTIAL_DESPATCH = 'N';
             SELECT PICK_ORDER.PARTIAL_PICK_ALLOWED, PICK_ORDER.PARTIAL_DESPATCH_ALLOWED
             FROM PICK_ORDER
             WHERE PICK_ORDER.PICK_ORDER  = :WK_ORDER
             INTO :WK_PARTIAL_PICK, :WK_PARTIAL_DESPATCH;
             IF (WK_PARTIAL_PICK IS NULL) THEN
             BEGIN
                WK_PARTIAL_PICK = 'T';
             END
             IF (WK_PARTIAL_DESPATCH IS NULL) THEN
             BEGIN
                WK_PARTIAL_DESPATCH = WK_PARTIAL_PICK;
             END
             IF (WK_PARTIAL_DESPATCH = 'N') THEN
             BEGIN
                WK_PARTIAL_DESPATCH = WK_PARTIAL_PICK;
             END
             WK_FOUND = 0;
             IF (WK_PARTIAL_DESPATCH = 'T') THEN
             BEGIN
                IF (WK_PARTIAL_PICK = 'T') THEN
                BEGIN
                   SELECT FIRST 1 1 FROM PICK_ITEM
                   WHERE PICK_ORDER = :WK_ORDER
                     AND PICK_LINE_STATUS <> 'NF'
                     AND PICK_LINE_STATUS <> 'DX'
                     AND PICK_LINE_STATUS <> 'CN'
                     AND PICK_LINE_STATUS <> 'HD'
                   INTO :WK_FOUND;
                   IF (WK_FOUND IS NULL) THEN
                      WK_FOUND = 0;
                END
                ELSE
                BEGIN
                   UPDATE PICK_ITEM SET PICK_LINE_STATUS = 'NF' 
                   WHERE PICK_ORDER = :WK_ORDER
                   AND PICK_LINE_STATUS  IN (NULL,'UC','CF','OP','UP','AS','HD','AL','PG','PL','DS','DC', 'Al','Pg','Pl')
                   AND PICKED_QTY IS NULL;
                   UPDATE PICK_ITEM SET PICK_LINE_STATUS = 'NF' 
                   WHERE PICK_ORDER = :WK_ORDER
                   AND PICK_LINE_STATUS  IN (NULL,'UC','CF','OP','UP','AS','HD','AL','PG','PL','DS','DC', 'Al','Pg','Pl')
                   AND PICKED_QTY < PICK_ORDER_QTY;
                   UPDATE PICK_ITEM SET PICK_LINE_STATUS = 'DX' 
                   WHERE PICK_ORDER = :WK_ORDER
                   AND PICK_LINE_STATUS  IN (NULL,'UC','CF','OP','UP','AS','HD','AL','PG','PL','DS','DC','Al','Pg','Pl');
                END
             END
             ELSE
             BEGIN
                UPDATE PICK_ITEM SET PICK_LINE_STATUS = 'NF' 
                WHERE PICK_ORDER = :WK_ORDER
                AND PICK_LINE_STATUS  IN (NULL,'UC','CF','OP','UP','AS','AL','PG','PL','DS','DC', 'Al','Pg','Pl')
                AND PICKED_QTY IS NULL;
                UPDATE PICK_ITEM SET PICK_LINE_STATUS = 'NF' 
                WHERE PICK_ORDER = :WK_ORDER
                AND PICK_LINE_STATUS  IN (NULL,'UC','CF','OP','UP','AS','AL','PG','PL','DS','DC', 'Al','Pg','Pl')
                AND PICKED_QTY < PICK_ORDER_QTY;
                UPDATE PICK_ITEM SET PICK_LINE_STATUS = 'DX' 
                WHERE PICK_ORDER = :WK_ORDER
                AND PICK_LINE_STATUS  IN (NULL,'UC','CF','OP','UP','AS','AL','PG','PL','DS','DC', 'Al','Pg','Pl');
             END
             IF (WK_FOUND = 0) THEN
             BEGIN
/*              UPDATE PICK_ORDER SET PICK_STATUS = 'DX'  */
                UPDATE PICK_ORDER SET PICK_STATUS = 'DX', DESPATCH_DATE = 'NOW'
                WHERE PICK_ORDER = :WK_ORDER;
                UPDATE PICK_ORDER_IMPORT SET PICK_STATUS = 'DX'
                WHERE PICK_ORDER = :WK_ORDER;
                UPDATE PICK_LOCATION
                SET PICK_LOCATION_STATUS = 'DC'
                WHERE PICK_ORDER = :WK_ORDER
                AND PICK_LOCATION_STATUS IN ( 'DS','OP');
                IF (WK_DO_UCIS = 'T') THEN
                BEGIN
                /* update remote order status */
                    WK_GM_MESSAGE = '';
                    SELECT MESSAGE_ID 
                    FROM GET_NEXT_MESSAGE 
                    INTO :WK_GM_MESSAGE;
                    WK_T4_DELIM = '|';
                    WK_T4_TRAN_DATA = PERSON_ID || WK_T4_DELIM ;
                    WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || DEVICE_ID || WK_T4_DELIM ;
                    WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || WK_GM_MESSAGE || WK_T4_DELIM ;
                    WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ContactInstanceID>' || WK_ORDER || WK_T4_DELIM ;
                    WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ContactInstanceStatusCode>DX' || WK_T4_DELIM ;
                    WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<UpdateDateTime>' || MER_YEAR('NOW') || '-' || LPAD(MER_MONTH('NOW'),'0',2) || '-' || LPAD(MER_DAY('NOW'),'0',2) || 'T' || LPAD(MER_HOUR('NOW'),'0',2) || ':' || LPAD(MER_MINUTE('NOW'),'0',2) || ':' || LPAD(SEC('NOW'),'0',2) || WK_T4_DELIM ;
                    WK_T4_SOURCE = 'SSSSSS' ;
                    SELECT REC_ID FROM ADD_TRAN_V4 ( 'V4', 'UCIS','S',
                       :TRN_DATE,
                       :WK_T4_DELIM,
                       :PERSON_ID,
                       :DEVICE_ID,
                       :WK_GM_MESSAGE,
                       :WK_T4_TRAN_DATA,
                       'F','','MASTER',0,
                       :WK_T4_SOURCE)
                    INTO :WK_NEW_RECORD;
                    EXECUTE PROCEDURE ADD_MESSAGE_V4 ( 
                       :WK_GM_MESSAGE,
                      'V4', 'UCIS','S',
                       :TRN_DATE,
                       :PERSON_ID,
                       :DEVICE_ID,
                       :WK_CN_PRIORITY,
                       'WS','',NULL);
                END
             END
             IF (WK_OP_DO_EMAIL_PACK = 'T') THEN
             BEGIN
                WK_PO_PERSON_ID  = '';
                WK_PO_COMPANY_ID  = '';
                WK_PO_CUSTOMER_PO_WO  = '';
                WK_PE_EMAIL  = '';
                WK_OP_REPORT_NO = NULL;
                WK_RT_URI = NULL;
                SELECT PICK_ORDER.PERSON_ID, PICK_ORDER.COMPANY_ID, PICK_ORDER.CUSTOMER_PO_WO
                FROM PICK_ORDER
                WHERE PICK_ORDER.PICK_ORDER  = :WK_ORDER
                INTO :WK_PO_PERSON_ID, :WK_PO_COMPANY_ID, :WK_PO_CUSTOMER_PO_WO ;
                IF (WK_PO_PERSON_ID IS NULL) THEN
                BEGIN
                   WK_PO_PERSON_ID  = '';
                END
                IF (WK_PO_COMPANY_ID IS NULL) THEN
                BEGIN
                   WK_PO_COMPANY_ID  = '';
                END
                IF (WK_PO_CUSTOMER_PO_WO IS NULL) THEN
                BEGIN
                   WK_PO_CUSTOMER_PO_WO  = '';
                END
                SELECT PERSON.EMAIL, PERSON.EMAIL_INVOICE_PS, PERSON.EMAIL_INVOICE_PI, PERSON.EMAIL_INVOICE_TI
                FROM PERSON
                WHERE PERSON.PERSON_ID = :WK_PO_PERSON_ID
                AND PERSON.COMPANY_ID = :WK_PO_COMPANY_ID
                INTO :WK_PE_EMAIL, :WK_PE_INVOICE_PS, :WK_PE_INVOICE_PI, :WK_PE_INVOICE_TI;
                IF (WK_PE_EMAIL IS NULL) THEN
                BEGIN
                   SELECT FIRST 1 PERSON.EMAIL
                   FROM PERSON
                   WHERE PERSON.PERSON_ID = :WK_PO_PERSON_ID
                   AND COALESCE(PERSON.EMAIL,'') <> ''
                   INTO :WK_PE_EMAIL ;
                   IF (WK_PE_EMAIL IS NULL) THEN
                   BEGIN
                      WK_PE_EMAIL  = '';
                   END
                END
                IF (WK_PE_INVOICE_PS  IS NULL) THEN
                BEGIN
                   WK_PE_INVOICE_PS = 'F';
                END
                IF (WK_PE_INVOICE_PI  IS NULL) THEN
                BEGIN
                   WK_PE_INVOICE_PI = 'F';
                END
                IF (WK_PE_INVOICE_TI  IS NULL) THEN
                BEGIN
                   WK_PE_INVOICE_TI = 'F';
                END
                IF (WK_PE_EMAIL = '.') THEN
                BEGIN
                   WK_PE_EMAIL  = '';
                END
                IF (WK_PE_EMAIL <> '') THEN
                BEGIN
                   /* get the report no to run */
                   /*
                   WK_OP_RPT_CODE = :WK_PO_COMPANY_ID || '|PS';
                   SELECT DESCRIPTION FROM OPTIONS WHERE GROUP_CODE = 'RPTINVOICE' AND CODE = :WK_OP_RPT_CODE
                   INTO :WK_OP_REPORT_NO;
                   */
                   WK_CM_PS_REPORT_ID = NULL;
                   WK_CM_PI_REPORT_ID = NULL;
                   WK_CM_TI_REPORT_ID = NULL;
                   WK_CM_CC_EMAIL = '';
                   SELECT INVOICE_PS_REPORT_ID, INVOICE_PI_REPORT_ID, INVOICE_TI_REPORT_ID, INVOICE_CC_EMAIL      
                   FROM COMPANY WHERE COMPANY_ID = :WK_PO_COMPANY_ID
                   INTO :WK_CM_PS_REPORT_ID, :WK_CM_PI_REPORT_ID, :WK_CM_TI_REPORT_ID, :WK_CM_CC_EMAIL;
                   IF (WK_CM_CC_EMAIL IS NULL) THEN
                   BEGIN
                      WK_CM_CC_EMAIL = '';
                   END
                   IF (WK_PE_INVOICE_PS = 'F') THEN
                   BEGIN
                      WK_CM_PS_REPORT_ID = NULL;
                   END
                   IF (WK_PE_INVOICE_PI = 'F') THEN
                   BEGIN
                      WK_CM_PI_REPORT_ID = NULL;
                   END
                   IF (WK_PE_INVOICE_TI = 'F') THEN
                   BEGIN
                      WK_CM_TI_REPORT_ID = NULL;
                   END
                   IF (WK_CM_PS_REPORT_ID IS NOT NULL) THEN
                   BEGIN
                      WK_RT_URI = NULL;
                      SELECT REPORT_URI FROM REPORTS WHERE REPORT_ID = :WK_CM_PS_REPORT_ID
                      INTO :WK_RT_URI;
                      IF (WK_RT_URI IS NOT NULL) THEN
                      BEGIN
                         /* write the file */
                         WK_EMAIL_FILENAME = WK_CN_EVENT_DIRECTORY ||  :WK_ORDER || '.ps.mail';
                         WK_EMAIL_BUFFER = :WK_ORDER || '|' || :WK_PO_COMPANY_ID || '|' || :WK_CM_PS_REPORT_ID || '|' || :WK_RT_URI || '|' || :WK_PE_EMAIL || '|' || WK_CM_CC_EMAIL || '|PS|' || :WK_PO_CUSTOMER_PO_WO || '|';
                         WK_EMAIL_RESULT = FILE_WRITELN(WK_EMAIL_FILENAME, :WK_EMAIL_BUFFER);
                      END
                      ELSE
                      BEGIN
                         /* no uri for this report ie not a JS or RP report */
                         WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'No URI for PS report ie not JS or RP report');
                      END
                   END
                   ELSE
                   BEGIN
                      /* no rptinvoice for this company */
                      WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'No INVOICE PS for this company');
                   END
                   IF (WK_CM_PI_REPORT_ID IS NOT NULL) THEN
                   BEGIN
                      WK_RT_URI = NULL;
                      SELECT REPORT_URI FROM REPORTS WHERE REPORT_ID = :WK_CM_PI_REPORT_ID
                      INTO :WK_RT_URI;
                      IF (WK_RT_URI IS NOT NULL) THEN
                      BEGIN
                         /* write the file */
                         WK_EMAIL_FILENAME = WK_CN_EVENT_DIRECTORY ||  :WK_ORDER || '.pi.mail';
                         WK_EMAIL_BUFFER = :WK_ORDER || '|' || :WK_PO_COMPANY_ID || '|' || :WK_CM_PI_REPORT_ID || '|' || :WK_RT_URI || '|' || :WK_PE_EMAIL || '|' || WK_CM_CC_EMAIL || '|PI|' || :WK_PO_CUSTOMER_PO_WO || '|';
                         WK_EMAIL_RESULT = FILE_WRITELN(WK_EMAIL_FILENAME, :WK_EMAIL_BUFFER);
                      END
                      ELSE
                      BEGIN
                         /* no uri for this report ie not a JS or RP report */
                         WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'No URI for PI report ie not JS or RP report');
                      END
                   END
                   ELSE
                   BEGIN
                      /* no rptinvoice for this company */
                      WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'No INVOICE PI for this company');
                   END
                   IF (WK_CM_TI_REPORT_ID IS NOT NULL) THEN
                   BEGIN
                      WK_RT_URI = NULL;
                      SELECT REPORT_URI FROM REPORTS WHERE REPORT_ID = :WK_CM_TI_REPORT_ID
                      INTO :WK_RT_URI;
                      IF (WK_RT_URI IS NOT NULL) THEN
                      BEGIN
                         /* write the file */
                         WK_EMAIL_FILENAME = WK_CN_EVENT_DIRECTORY ||  :WK_ORDER || '.ti.mail';
                         WK_EMAIL_BUFFER = :WK_ORDER || '|' || :WK_PO_COMPANY_ID || '|' || :WK_CM_TI_REPORT_ID || '|' || :WK_RT_URI || '|' || :WK_PE_EMAIL || '|' || WK_CM_CC_EMAIL || '|TI|' || :WK_PO_CUSTOMER_PO_WO || '|'  ;
                         WK_EMAIL_RESULT = FILE_WRITELN(WK_EMAIL_FILENAME, :WK_EMAIL_BUFFER);
                      END
                      ELSE
                      BEGIN
                         /* no uri for this report ie not a JS or RP report */
                         WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'No URI for TI report ie not JS or RP report');
                      END
                   END
                   ELSE
                   BEGIN
                      /* no rptinvoice for this company */
                      WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'No INVOICE TI for this company');
                   END
                END
                ELSE
                BEGIN
                   /* no email address to send to */
                   WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'No EMAIL to send to');
                END
             END
          END /* end of detail status 'DC' */
          /* check orders for DS 0000000000 or zero qty items */
          FOR SELECT OBJECT
              FROM TRANSACTIONS_WORK
              WHERE RECORD_ID = :WK_RECORD
              INTO :WK_ORDER
          DO
          BEGIN
             UPDATE PICK_ITEM_DETAIL
                    SET PICK_DETAIL_STATUS = :WK_DSDX_DETAIL_STATUS,
                    DEVICE_ID = 'XX'
                    WHERE PICK_ORDER = :WK_ORDER
                    AND QTY_PICKED = 0
                    AND PICK_DETAIL_STATUS = 'DS';

          END
       END
       UPDATE PICK_DESPATCH SET DESPATCH_STATUS = 'DX',
              PICKD_EXIT = 'NOW'
       WHERE DESPATCH_ID = :WK_DESPATCH;
       IF (WK_DO_EXPORT_DESPATCH = 'T') THEN
       BEGIN
          /* if pick order is now dx
             or multiple despatches on this order */
          /* EXECUTE PROCEDURE PC_EXPORT_DESPATCH(:WK_DESPATCH, :WK_PRINTER); */
          EXECUTE PROCEDURE PC_EXPORT_DESPATCH(:WK_DESPATCH, :WK_PRINTER, :RECORD_ID);
       END
    END
    WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'DSDX End'); 
    EXECUTE PROCEDURE UPDATE_TRAN (RECORD_ID, 'T','Processed successfully');
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
