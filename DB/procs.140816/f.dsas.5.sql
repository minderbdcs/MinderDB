COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;
 
/* create a asn for a group of sscc records   */
/* dsot must update the pack_sscc ps_despatched_date */

CREATE OR ALTER TRIGGER RUN_TRANSACTION_DSAS FOR TRANSACTIONS 
ACTIVE AFTER INSERT POSITION 166 
AS
DECLARE VARIABLE WK_AUTORUN INTEGER;
DECLARE VARIABLE WK_DEVICE_ID CHAR(2);
DECLARE VARIABLE WK_USER VARCHAR(10);
DECLARE VARIABLE WK_RECORD INTEGER;
DECLARE VARIABLE WK_WH_ID CHAR(2);
DECLARE VARIABLE WK_LOCN_ID VARCHAR(10);
DECLARE VARIABLE WK_OBJECT VARCHAR(30);
DECLARE VARIABLE WK_REF VARCHAR(1024);
DECLARE VARIABLE WK_QTY INTEGER;
DECLARE VARIABLE WK_DATE TIMESTAMP;

DECLARE VARIABLE WK_FILENAME VARCHAR(255);
DECLARE VARIABLE WK_FILENAME2 VARCHAR(255);
DECLARE VARIABLE WK_FILENAME3 VARCHAR(255);
DECLARE VARIABLE WK_LOG_FILENAME VARCHAR(255);
DECLARE VARIABLE WK_LOG_RESULT INTEGER;
DECLARE VARIABLE WK_RESULT INTEGER;
DECLARE VARIABLE WK_RESPONSE_FINAL VARCHAR(255);
DECLARE VARIABLE WK_ERROR_TEXT VARCHAR(1024);
DECLARE VARIABLE WK_DATE_X VARCHAR(30);
DECLARE VARIABLE WK_TIME_X VARCHAR(30);

DECLARE VARIABLE WK_PD_ID INTEGER;

DECLARE VARIABLE WK_PS_ORDER VARCHAR(25);
DECLARE VARIABLE WK_PS_SSCC_ID VARCHAR(20);
DECLARE VARIABLE WK_PS_ASN_VENDOR_NO VARCHAR(35);
DECLARE VARIABLE WK_PS_CUSTOMER_EDI_NO VARCHAR(35);
DECLARE VARIABLE WK_PS_AWB_CONSIGNMENT_NO VARCHAR(20);
DECLARE VARIABLE WK_PS_DESPATCHED_DATE VARCHAR(8);
DECLARE VARIABLE WK_PS_SCHED_DEL_DATE VARCHAR(8);
DECLARE VARIABLE WK_PS_DEL_TO_DC_NO VARCHAR(20);
DECLARE VARIABLE WK_PS_PICK_ORDER VARCHAR(25);
DECLARE VARIABLE WK_PS_PICK_ORDER_DATE VARCHAR(8);
DECLARE VARIABLE WK_PS_DEL_TO_STORE_NO VARCHAR(20);
DECLARE VARIABLE WK_PS_PRODUCT_IN_HOUSE_CODE VARCHAR(30);
DECLARE VARIABLE WK_PS_PRODUCT_GTIN VARCHAR(30);
DECLARE VARIABLE WK_PS_QTY_SHIPPED  INTEGER;
DECLARE VARIABLE WK_PS_BATCH_NO VARCHAR(20);
DECLARE VARIABLE WK_PS_SCHED_DEL_TIME VARCHAR(5);
DECLARE VARIABLE WK_PS_CARRIER_ID VARCHAR(20);
DECLARE VARIABLE WK_PS_SSCC_WEIGHT DECIMAL(9,3);
DECLARE VARIABLE WK_PS_SSCC_CUBIC DOUBLE PRECISION;
DECLARE VARIABLE WK_PS_SSCC_CUBIC_OUT DECIMAL(9,5); 
/* DECLARE VARIABLE WK_PS_SSCC_CUBIC_OUT DECIMAL(18,5); */
DECLARE VARIABLE WK_PS_TOTAL_OUTERS  INTEGER;
DECLARE VARIABLE WK_PS_OUTER_BARCODE VARCHAR(16);
DECLARE VARIABLE WK_PS_QTY_ORDERED   INTEGER;
DECLARE VARIABLE WK_PS_USE_BY_DATE VARCHAR(8);
DECLARE VARIABLE WK_PS_ORDERED_BY_UOM_GTIN INTEGER;
DECLARE VARIABLE WK_PS_PICK_LABEL_NO VARCHAR(8);
DECLARE VARIABLE WK_PS_RECORD_ID  INTEGER;
DECLARE VARIABLE WK_PS_LEGACY_PICK_ORDER VARCHAR(25);
DECLARE VARIABLE WK_PS_OUT_SSCC_ID VARCHAR(20);

DECLARE VARIABLE WK_PO_CREATE_DATE TIMESTAMP;
DECLARE VARIABLE WK_PO_EXPORTED_DATE VARCHAR(8);
DECLARE VARIABLE WK_CA_PARENT_CARRIER_ID VARCHAR(10);
DECLARE VARIABLE WK_CO_EDI_VENDOR VARCHAR(35);
DECLARE VARIABLE WK_CO_EXPORT_DIRECTORY VARCHAR(75);
DECLARE VARIABLE WK_PID_QTY_SHIPPED  INTEGER;

DECLARE VARIABLE WK_IS_OK    INTEGER;
DECLARE VARIABLE WK_IS_ERROR VARCHAR(1024);

DECLARE VARIABLE WK_LEGACY_PARAM_ID VARCHAR(20);
DECLARE VARIABLE WK_LEGACY_ID       VARCHAR(20);
DECLARE VARIABLE WK_PS_ASN_ID       VARCHAR(20);
DECLARE VARIABLE WK_NEW_RECORD INTEGER;
DECLARE VARIABLE WK_GM_MESSAGE VARCHAR(10);
DECLARE VARIABLE WK_T4_DELIM CHAR(1);
DECLARE VARIABLE WK_T4_TRAN_DATA VARCHAR(1024);
DECLARE VARIABLE WK_T4_SOURCE VARCHAR(512);
DECLARE VARIABLE WK_DUMMY    INTEGER;
DECLARE VARIABLE WK_C4_DELIM CHAR(1);
DECLARE VARIABLE WK_C4_TRAN_DATA VARCHAR(1024);
DECLARE VARIABLE WK_PP_NET_WEIGHT DECIMAL(9,3);
DECLARE VARIABLE WK_PP_VOLUME DOUBLE PRECISION;
DECLARE VARIABLE WK_PS_SSCC_VOLUME DOUBLE PRECISION;
DECLARE VARIABLE WK_PS_SSCC_VOLUME_OUT DECIMAL(9,5); 
BEGIN
 WK_AUTORUN = GEN_ID(AUTOEXEC_TRANSACTIONS,0); 
 IF (WK_AUTORUN = 1) THEN
 BEGIN
  IF (NEW.TRN_TYPE = 'DSAS') THEN
  BEGIN
     WK_DEVICE_ID = NEW.DEVICE_ID;
     WK_OBJECT = NEW.OBJECT;
     WK_WH_ID = NEW.WH_ID;
     WK_LOCN_ID = NEW.LOCN_ID;
     WK_USER = NEW.PERSON_ID;
     WK_REF = ALLTRIM(NEW.REFERENCE);
     WK_QTY = NEW.QTY;
     WK_DATE = NEW.TRN_DATE;
     WK_RECORD = NEW.RECORD_ID;
     WK_LOG_FILENAME = '/tmp/DSAS.log';
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'DSAS start');
/*
     WK_FILENAME = '/tmp/DSAS.';
     WK_FILENAME2 = '/tmp/DSAS.';
     WK_FILENAME3 = '/tmp/DSAS.';
     -* include the company name of the order in the file name *-
     WK_FILENAME = WK_FILENAME || NEW.COMPANY_ID;
     WK_FILENAME2 = WK_FILENAME2 || NEW.COMPANY_ID;
     WK_FILENAME3 = WK_FILENAME3 || NEW.COMPANY_ID;
     WK_FILENAME = WK_FILENAME || '.csv';
     WK_FILENAME2 = WK_FILENAME2 || '.csv2';
     WK_FILENAME3 = WK_FILENAME3 || '.csv3';
*/
     /* write the file in the import folder of the company  /asn */
     /* object holds the despatch id to work on  */
     /* qty has qty of packs for ASN  */
     /* company_id has the company to work on */
/* have           
        order no has the order to select 
        order_type  - unknown
        order_sub_type - unknown 
        company_id - that the order belongs to 
*/
     WK_IS_OK = 0;
     WK_IS_ERROR = '';
     WK_RESULT = 0;
     BEGIN
        WK_PD_ID = CAST(:WK_OBJECT AS INTEGER);
        WHEN SQLCODE -413
        DO
        BEGIN
           /* No Despatch Id */
           WK_PD_ID = NULL;
           WK_IS_OK = 1;
           WK_IS_ERROR = "Non Numeric Despatch ID";
        END
     END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after check object');

     WK_PS_ORDER = NEW.ORDER_NO;

     IF (NEW.TRN_CODE = 'C' AND WK_IS_OK = 0) THEN
     BEGIN
        /* get next ASN */
        SELECT GS1_ASN_PARAM_ID , COMPANY_EDI_VENDOR_NO, IMPORT_DIRECTORY 
        FROM COMPANY 
        WHERE COMPANY_ID = NEW.COMPANY_ID
        INTO :WK_LEGACY_PARAM_ID, :WK_CO_EDI_VENDOR, :WK_CO_EXPORT_DIRECTORY;
        IF (WK_CO_EXPORT_DIRECTORY IS NULL) THEN
        BEGIN
           WK_CO_EXPORT_DIRECTORY = '/tmp';
        END
        ELSE
        BEGIN
           WK_CO_EXPORT_DIRECTORY = WK_CO_EXPORT_DIRECTORY || '/asn';
        END
        WK_FILENAME = WK_CO_EXPORT_DIRECTORY || '/DSAS.';
        WK_FILENAME2 = '/tmp/DSAS.';
        WK_FILENAME3 = WK_CO_EXPORT_DIRECTORY || '/DSAS.';
        /* include the company name of the order in the file name */
        IF (NEW.COMPANY_ID IS NOT NULL) THEN
        BEGIN
           WK_FILENAME = WK_FILENAME || NEW.COMPANY_ID;
           WK_FILENAME2 = WK_FILENAME2 || NEW.COMPANY_ID;
           WK_FILENAME3 = WK_FILENAME3 || NEW.COMPANY_ID;
        END
        WK_DATE_X = MER_DAY('NOW') || '.' || MER_MONTH('NOW') || '.' || SUBSTR(CAST(MER_YEAR('NOW') AS VARCHAR(4)) , 3,4);
        WK_TIME_X = MER_HOUR('NOW') || '.' || MER_MINUTE('NOW') ;
        WK_DATE_X = WK_DATE_X || '-' || WK_TIME_X;
        WK_FILENAME = WK_FILENAME || WK_DATE_X;
        WK_FILENAME2 = WK_FILENAME2 || WK_DATE_X;
        WK_FILENAME3 = WK_FILENAME3 || WK_DATE_X;
        WK_FILENAME = WK_FILENAME || '.csv';
        WK_FILENAME2 = WK_FILENAME2 || '.csv2';
        WK_FILENAME3 = WK_FILENAME3 || '.csv3';
        WK_LEGACY_ID  = '';
        WK_PS_ASN_ID = WK_LEGACY_ID ;
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after get filename');
/*
        SELECT LEGACY_ID 
        FROM GET_NEXT_LEGACY (:WK_LEGACY_PARAM_ID) 
        INTO :WK_LEGACY_ID;
        WK_PS_ASN_ID = WK_LEGACY_ID ;
*/
        /* only select those sscc's for the despatch with PACK_SSCC.PS_EDI_ASN null */
        FOR SELECT PACK_SSCC.PS_SSCC, 
                   PACK_SSCC.PS_ASN_VENDOR_NO, 
                   PACK_SSCC.PS_CUSTOMER_EDI_NO, 
         /*        PACK_SSCC.PS_AWB_CONSIGNMENT_NO,  */    
                   PACK_SSCC.PS_OUT_AWB_CONSIGNMENT_NO,        
                   PACK_SSCC.PS_DESPATCHED_DATE,
                   PACK_SSCC.PS_SCHED_DEL_DATE,
                   PACK_SSCC.PS_DEL_TO_DC_NO,
                   PACK_SSCC.PS_PICK_ORDER,
                   PACK_SSCC.PS_PICK_ORDER_DATE,
                   PACK_SSCC.PS_DEL_TO_STORE_NO,
                   PACK_SSCC.PS_PRODUCT_CODE,
                   PACK_SSCC.PS_PRODUCT_GTIN,
                   PACK_SSCC.PS_QTY_SHIPPED,
                   PACK_SSCC.PS_BATCH_NO,
                   PACK_SSCC.PS_SCHED_DEL_TIME,
         /*        PACK_SSCC.PS_CARRIER_ID, */
                   PACK_SSCC.PS_OUT_CARRIER_ID,   
                   PACK_SSCC.PS_SSCC_WEIGHT,
                   PACK_SSCC.PS_SSCC_CUBIC,
                   PACK_SSCC.PS_TOTAL_OUTERS,
                   PACK_SSCC.PS_OUTER_BARCODE,
                   PACK_SSCC.PS_QTY_ORDERED,
                   PACK_SSCC.PS_USE_BY_DATE,
                   PACK_SSCC.PS_ORDERED_BY_UOM_GTIN,
                   PACK_SSCC.PS_PICK_LABEL_NO,
                   PACK_SSCC.PS_LEGACY_PICK_ORDER,
                   PACK_SSCC.PS_OUT_SSCC,
                   PICK_ORDER.CREATE_DATE,
                   CARRIER.CARRIER_PARENT_ID ,
                   (SELECT SUM(PICK_ITEM_DETAIL.QTY_PICKED) FROM PICK_ITEM_DETAIL WHERE PICK_ITEM_DETAIL.DESPATCH_ID = PACK_SSCC.PS_OUT_DESPATCH_ID AND PICK_ITEM_DETAIL.PICK_LABEL_NO = PACK_SSCC.PS_PICK_LABEL_NO AND PICK_ITEM_DETAIL.PICK_DETAIL_STATUS NOT IN ('XX', 'AS') ),
                   PROD_PROFILE.NET_WEIGHT,
                   (PROD_PROFILE.DIMENSION_X *  PROD_PROFILE.DIMENSION_Y * PROD_PROFILE.DIMENSION_Z) 
            FROM PACK_SSCC
            JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PACK_SSCC.PS_PICK_ORDER 
            JOIN CARRIER ON CARRIER.CARRIER_ID = PACK_SSCC.PS_OUT_CARRIER_ID
            JOIN PICK_ITEM  ON PICK_ITEM.PICK_LABEL_NO = PACK_SSCC.PS_PICK_LABEL_NO
            /* LEFT OUTER JOIN PROD_PROFILE ON PACK_SSCC.PS_PRODUCT_GTIN = PROD_PROFILE.PROD_ID AND PICK_ORDER.COMPANY_ID = PROD_PROFILE.COMPANY_ID */
            LEFT OUTER JOIN PROD_PROFILE ON PICK_ITEM.PROD_ID = PROD_PROFILE.PROD_ID AND PICK_ORDER.COMPANY_ID = PROD_PROFILE.COMPANY_ID
       /*     WHERE PS_DESPATCH_ID = :WK_PD_ID */
       /*     AND PACK_SSCC.PS_SSCC_STATUS IN ('GO','DC','DX','CL','DN','NF') */
            WHERE PS_OUT_DESPATCH_ID = :WK_PD_ID
              AND PS_EDI_ASN IS NULL
              AND PACK_SSCC.PS_SSCC_STATUS IN ('DC','DX','CL','DN','NF')
              AND  (COALESCE(PS_QTY_SHIPPED,0) > 0) 
            INTO :WK_PS_SSCC_ID, 
                 :WK_PS_ASN_VENDOR_NO, 
                 :WK_PS_CUSTOMER_EDI_NO, 
                 :WK_PS_AWB_CONSIGNMENT_NO, 
                 :WK_PS_DESPATCHED_DATE,
                 :WK_PS_SCHED_DEL_DATE,
                 :WK_PS_DEL_TO_DC_NO,
                 :WK_PS_PICK_ORDER,
                 :WK_PS_PICK_ORDER_DATE,
                 :WK_PS_DEL_TO_STORE_NO,
                 :WK_PS_PRODUCT_IN_HOUSE_CODE,
                 :WK_PS_PRODUCT_GTIN,
                 :WK_PS_QTY_SHIPPED,
                 :WK_PS_BATCH_NO,
                 :WK_PS_SCHED_DEL_TIME,
                 :WK_PS_CARRIER_ID,
                 :WK_PS_SSCC_WEIGHT,
                 :WK_PS_SSCC_CUBIC,
                 :WK_PS_TOTAL_OUTERS,
                 :WK_PS_OUTER_BARCODE,
                 :WK_PS_QTY_ORDERED,
                 :WK_PS_USE_BY_DATE,
                 :WK_PS_ORDERED_BY_UOM_GTIN,
                 :WK_PS_PICK_LABEL_NO,
                 :WK_PS_LEGACY_PICK_ORDER,
                 :WK_PS_OUT_SSCC_ID,
                 :WK_PO_CREATE_DATE,
                 :WK_CA_PARENT_CARRIER_ID,
                 :WK_PID_QTY_SHIPPED,
                 :WK_PP_NET_WEIGHT,
                 :WK_PP_VOLUME
        DO
        BEGIN
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME,'read loop');
           IF (WK_PS_ASN_ID = '') THEN
           BEGIN
              SELECT LEGACY_ID 
              FROM GET_NEXT_LEGACY (:WK_LEGACY_PARAM_ID) 
              INTO :WK_LEGACY_ID;
              WK_PS_ASN_ID = WK_LEGACY_ID ;
           END
           /* create csv record */
           IF (COALESCE(WK_PS_DESPATCHED_DATE,'') = '') THEN
           BEGIN
              WK_PS_DESPATCHED_DATE = MER_YEAR('NOW') ||  LPAD(MER_MONTH('NOW'),'0',2) ||  LPAD(MER_DAY('NOW'),'0',2) ;  
           END
           IF (COALESCE(WK_PS_PICK_ORDER_DATE,'') = '') THEN
           BEGIN
              /* SELECT CREATE_DATE FROM PICK_ORDER WHERE PICK_ORDER = :WK_PS_PICK_ORDER INTO :WK_PO_CREATE_DATE; */
              WK_PS_PICK_ORDER_DATE = MER_YEAR(:WK_PO_CREATE_DATE) ||  LPAD(MER_MONTH(:WK_PO_CREATE_DATE),'0',2) ||  LPAD(MER_DAY(:WK_PO_CREATE_DATE),'0',2) ;  
           END
           IF (COALESCE(WK_PS_QTY_SHIPPED,0) = 0) THEN
           BEGIN
              WK_PS_QTY_SHIPPED = 0;
              /* need to calculate this from the pick item detail qty_picked */
/*
              SELECT SUM(QTY_PICKED) FROM PICK_ITEM_DETAIL
              WHERE DESPATCH_ID = :WK_PD_ID
              AND PICK_LABEL_NO = :WK_PS_PICK_LABEL_NO
              AND PICK_DETAIL_STATUS <> 'XX' 
              AND PICK_DETAIL_STATUS <> 'AS' 
              INTO :WK_PID_QTY_SHIPPED;
*/
              IF (WK_PID_QTY_SHIPPED IS NOT NULL) THEN
              BEGIN
                 WK_PS_QTY_SHIPPED = WK_PID_QTY_SHIPPED ;
              END
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after date');
           WK_PO_EXPORTED_DATE = MER_YEAR('NOW') ||  LPAD(MER_MONTH('NOW'),'0',2) ||  LPAD(MER_DAY('NOW'),'0',2) ;  
           /* SELECT COALESCE(CARRIER_PARENT_ID,:WK_PS_CARRIER_ID) FROM CARRIER WHERE CARRIER_ID = :WK_PS_CARRIER_ID INTO :WK_CA_PARENT_CARRIER_ID; */
           IF (COALESCE(WK_CA_PARENT_CARRIER_ID,'') = '') THEN
           BEGIN
              WK_CA_PARENT_CARRIER_ID = WK_PS_CARRIER_ID;
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after carrier parent');
           IF (COALESCE(WK_PS_USE_BY_DATE,'') = '') THEN
           BEGIN
              WK_PS_USE_BY_DATE = '';
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after use by date');
           IF (COALESCE(WK_PS_ORDERED_BY_UOM_GTIN,0) = 0) THEN
           BEGIN
              WK_PS_ORDERED_BY_UOM_GTIN = 0;
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after uom gtin');
           /* IF (COALESCE(WK_PS_SSCC_CUBIC,0.0) > 0.0) THEN
              WK_PS_SSCC_CUBIC_OUT = CAST(WK_PS_SSCC_CUBIC AS DECIMAL(9,5));
           END
           ELSE
           BEGIN
              WK_PS_SSCC_CUBIC_OUT = 0.0;
           END
*/
           IF (WK_PS_SSCC_CUBIC IS NULL) THEN
           BEGIN
              WK_PS_SSCC_CUBIC_OUT = 0.0;
           END
           ELSE
           BEGIN
              IF (WK_PS_SSCC_CUBIC = 0) THEN
              BEGIN
                 WK_PS_SSCC_CUBIC_OUT = 0.0;
              END
              ELSE
              BEGIN
                 /* WK_PS_SSCC_CUBIC_OUT = CAST(WK_PS_SSCC_CUBIC AS DECIMAL(18,5)); */
                 IF (WK_PS_SSCC_CUBIC > 9999) THEN
                 BEGIN
                    WK_PS_SSCC_CUBIC_OUT = 9999;
                 END
                 ELSE
                 BEGIN
                    WK_PS_SSCC_CUBIC_OUT = CAST(WK_PS_SSCC_CUBIC AS DECIMAL(9,5)); 
                 END
              END
           END

           /* write it to the transactions4 table */
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'write it');
           WK_GM_MESSAGE = '';
           SELECT MESSAGE_ID 
           FROM GET_NEXT_MESSAGE 
           INTO :WK_GM_MESSAGE;
           WK_T4_DELIM = '|';
           WK_C4_DELIM = ',';
           WK_T4_TRAN_DATA = WK_USER || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = '' ;
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || WK_DEVICE_ID || WK_T4_DELIM ;
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || WK_GM_MESSAGE || WK_T4_DELIM ;
           IF (COALESCE(WK_PS_ASN_VENDOR_NO,'') = '') THEN
           BEGIN
              WK_DUMMY = 1;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_asn_vendor_no>' ||  WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||   WK_C4_DELIM ;
           END
           ELSE
           BEGIN
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_asn_vendor_no>' || WK_PS_ASN_VENDOR_NO || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_ASN_VENDOR_NO || WK_C4_DELIM ;
           END
           IF (COALESCE(WK_PS_CUSTOMER_EDI_NO,'') = '') THEN
           BEGIN
              WK_DUMMY = 1;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_customer_edi_no>' ||  WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||   WK_C4_DELIM ;
           END
           ELSE
           BEGIN
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_customer_edi_no>' || WK_PS_CUSTOMER_EDI_NO || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_CUSTOMER_EDI_NO || WK_C4_DELIM ;
           END
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_edi_asn>' || WK_PS_ASN_ID || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_ASN_ID || WK_C4_DELIM ;
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_awb_consignment_no>' || WK_PS_AWB_CONSIGNMENT_NO || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_AWB_CONSIGNMENT_NO || WK_C4_DELIM ;
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_despatched_date>' || WK_PS_DESPATCHED_DATE || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_DESPATCHED_DATE || WK_C4_DELIM ;
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after despatched date');
           IF (COALESCE(WK_PS_SCHED_DEL_DATE,'') = '') THEN
           BEGIN
              WK_DUMMY = 1;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sched_del_date>' || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_C4_DELIM ;
           END
           ELSE
           BEGIN
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sched_del_date>' || WK_PS_SCHED_DEL_DATE || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_SCHED_DEL_DATE || WK_C4_DELIM ;
           END
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_del_to_dc_no>' || WK_PS_DEL_TO_DC_NO || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_DEL_TO_DC_NO || WK_C4_DELIM ;
/*
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_pick_order>' || WK_PS_PICK_ORDER || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_PICK_ORDER || WK_C4_DELIM ;
*/
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_pick_order>' || WK_PS_LEGACY_PICK_ORDER || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_LEGACY_PICK_ORDER || WK_C4_DELIM ;
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_pick_order_date>' || WK_PS_PICK_ORDER_DATE || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_PICK_ORDER_DATE || WK_C4_DELIM ;
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_del_to_store_no>' || WK_PS_DEL_TO_STORE_NO || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_DEL_TO_STORE_NO || WK_C4_DELIM ;
/*
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_pick_order2>' || WK_PS_PICK_ORDER || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_PICK_ORDER || WK_C4_DELIM ;
*/
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_pick_order2>' || WK_PS_LEGACY_PICK_ORDER || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_LEGACY_PICK_ORDER || WK_C4_DELIM ;
/*
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc>' || WK_PS_SSCC_ID || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_SSCC_ID || WK_C4_DELIM ;
*/
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc>' || WK_PS_OUT_SSCC_ID || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_OUT_SSCC_ID || WK_C4_DELIM ;
           IF (COALESCE(WK_PS_PRODUCT_IN_HOUSE_CODE,'') = '') THEN
           BEGIN
              WK_DUMMY = 1;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_product_code>' || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_C4_DELIM ;
           END
           ELSE
           BEGIN
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_product_code>' || WK_PS_PRODUCT_IN_HOUSE_CODE || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_PRODUCT_IN_HOUSE_CODE || WK_C4_DELIM ;
           END
           IF (COALESCE(WK_PS_PRODUCT_GTIN,'') = '') THEN
           BEGIN
              WK_DUMMY = 1;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_product_gtin>' || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_C4_DELIM ;
           END
           ELSE
           BEGIN
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_product_gtin>' || WK_PS_PRODUCT_GTIN || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_PRODUCT_GTIN || WK_C4_DELIM ;
           END
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_shipped_qty>' || WK_PS_QTY_SHIPPED || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_QTY_SHIPPED || WK_C4_DELIM ;
/*
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<po_exported_date>' || WK_PO_EXPORTED_DATE || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PO_EXPORTED_DATE || WK_C4_DELIM ;
*/
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<po_expiry_date>' || WK_PS_USE_BY_DATE || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_USE_BY_DATE || WK_C4_DELIM ;
           IF (COALESCE(WK_PS_BATCH_NO,'') = '') THEN
           BEGIN
              WK_DUMMY = 1;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_batch_no>' || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_C4_DELIM ;
           END
           ELSE
           BEGIN
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_batch_no>' || WK_PS_BATCH_NO || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_BATCH_NO || WK_C4_DELIM ;
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after use by date');
           IF (COALESCE(WK_PS_SCHED_DEL_TIME,'') = '') THEN
           BEGIN
              WK_DUMMY = 1;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sched_del_time>' || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_C4_DELIM ;
           END
           ELSE
           BEGIN
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sched_del_time>' || WK_PS_SCHED_DEL_TIME || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_SCHED_DEL_TIME || WK_C4_DELIM ;
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after sched del time');
           IF (COALESCE(WK_CA_PARENT_CARRIER_ID,'') = '') THEN
           BEGIN
              WK_DUMMY = 1;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_carrier_id>' ||  WK_PS_CARRIER_ID || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_CARRIER_ID || WK_C4_DELIM ;
           END
           ELSE
           BEGIN
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_carrier_id>' || WK_CA_PARENT_CARRIER_ID || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_CA_PARENT_CARRIER_ID || WK_C4_DELIM ;
           END
           IF (COALESCE(WK_PS_SSCC_WEIGHT,0.0) = 0.0) THEN
           BEGIN
              IF (COALESCE(WK_PP_NET_WEIGHT,0.0) = 0.0) THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_weight>' || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_C4_DELIM ;
              END
              ELSE
              BEGIN 
                 WK_PS_SSCC_WEIGHT = WK_PS_QTY_SHIPPED * WK_PP_NET_WEIGHT ;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_weight>' || WK_PS_SSCC_WEIGHT || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_SSCC_WEIGHT || WK_C4_DELIM ;
              END
           END
           ELSE
           BEGIN
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_weight>' || WK_PS_SSCC_WEIGHT || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_SSCC_WEIGHT || WK_C4_DELIM ;
/* check that this is dddd.ddd */
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after weight');
           IF (COALESCE(WK_PS_SSCC_CUBIC,0.0) = 0.0) THEN
           BEGIN
              WK_DUMMY = 1;
              IF (COALESCE(WK_PP_VOLUME,0.0) = 0.0) THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_cubic>' || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_C4_DELIM ;
              END
              ELSE
              BEGIN 
                 WK_PS_SSCC_VOLUME = WK_PS_QTY_SHIPPED * WK_PP_VOLUME /1000000;
                 IF (WK_PS_SSCC_VOLUME IS NULL) THEN
                 BEGIN
                    WK_PS_SSCC_VOLUME_OUT = 0.0;
                 END
                 ELSE
                 BEGIN
                    IF (WK_PS_SSCC_VOLUME = 0) THEN
                    BEGIN
                       WK_PS_SSCC_VOLUME_OUT = 0.0;
                    END
                    ELSE
                    BEGIN
                       IF (WK_PS_SSCC_VOLUME > 9999) THEN
                       BEGIN
                          WK_PS_SSCC_VOLUME_OUT = 9999;
                       END
                       ELSE
                       BEGIN
                          WK_PS_SSCC_VOLUME_OUT = CAST(WK_PS_SSCC_VOLUME AS DECIMAL(9,5)); 
                       END
                    END
                 END
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_weight>' || WK_PS_SSCC_VOLUME_OUT || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_SSCC_VOLUME_OUT || WK_C4_DELIM ;
              END
           END
           ELSE
           BEGIN
              /* WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_cubic>' || WK_PS_SSCC_CUBIC || WK_T4_DELIM ; */
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_cubic>' || WK_PS_SSCC_CUBIC_OUT || WK_T4_DELIM ;
              /* WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_SSCC_CUBIC || WK_C4_DELIM ; */
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_SSCC_CUBIC_OUT || WK_C4_DELIM ;
/* check that this is a float */
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after cubic');
           IF (COALESCE(WK_CO_EDI_VENDOR,'') = '') THEN
           BEGIN
              WK_DUMMY = 1;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<co_edi_vendor>' || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_C4_DELIM ;
           END
           ELSE
           BEGIN
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<co_edi_vendor>' || WK_CO_EDI_VENDOR || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_CO_EDI_VENDOR || WK_C4_DELIM ;
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after vendor');
           IF (COALESCE(WK_PS_TOTAL_OUTERS,0) = 0) THEN
           BEGIN
              WK_DUMMY = 1;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_shipped_outers>' || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_C4_DELIM ;
           END
           ELSE
           BEGIN
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_shipped_outers>' || WK_PS_TOTAL_OUTERS || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_TOTAL_OUTERS || WK_C4_DELIM ;
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after shipped outers');
           IF (COALESCE(WK_PS_OUTER_BARCODE,'') = '') THEN
           BEGIN
              WK_DUMMY = 1;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_outer_barcode>' ||  WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_C4_DELIM ;
           END
           ELSE
           BEGIN
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_outer_barcode>' || WK_PS_OUTER_BARCODE || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_OUTER_BARCODE || WK_C4_DELIM ;
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after outer barcode');
           IF (COALESCE(WK_PS_QTY_ORDERED,0) = 0) THEN
           BEGIN
              WK_DUMMY = 1;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_order_by_uom>' || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_C4_DELIM ;
           END
           ELSE
           BEGIN
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_order_by_uom>' || WK_PS_QTY_ORDERED || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_QTY_ORDERED || WK_C4_DELIM ;
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after qty ordered');
           /* qty shipped */
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_order_by_qty_shipped>' || WK_PS_QTY_SHIPPED || WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_QTY_SHIPPED || WK_C4_DELIM ;
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after qty shipped');
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_order_by_uom_gtin>' || WK_PS_ORDERED_BY_UOM_GTIN ||  WK_T4_DELIM ;
           WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_ORDERED_BY_UOM_GTIN  || WK_C4_DELIM ;
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after uom gtin');
           WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_order_by_gtin>' ||  WK_T4_DELIM ;
           /* WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || last field   ; */

           WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_C4_TRAN_DATA);
           IF (WK_RESULT <> 0) THEN
           BEGIN
              WK_ERROR_TEXT = 'Failed to write DSAS.csv';
              /* try the 2nd file */
              WK_RESULT = FILE_WRITELN(WK_FILENAME2, WK_C4_TRAN_DATA);
              IF (WK_RESULT <> 0) THEN
              BEGIN
                 WK_ERROR_TEXT = 'Failed to write DSAS.csv and DSAS.csv2';
                 /* try the 3rd file */
                 WK_RESULT = FILE_WRITELN(WK_FILENAME3, WK_C4_TRAN_DATA);
                 IF (WK_RESULT <> 0) THEN
                 BEGIN
                    WK_ERROR_TEXT = 'Failed to write DSAS.csv and DSAS.csv2 and DSAS.csv3';
                END
              END
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'before DSNA');
           WK_T4_SOURCE = 'SSSSSSSSSSS' ;
           SELECT REC_ID FROM ADD_TRAN_V4 ( 'V4', 'DSNA','P',
              :WK_DATE,
              :WK_T4_DELIM,
              :WK_USER,
              :WK_DEVICE_ID,
              :WK_GM_MESSAGE,
              :WK_T4_TRAN_DATA,
              'F','','MASTER',0,
              :WK_T4_SOURCE)
           INTO :WK_NEW_RECORD;
           IF (WK_RESULT <> 0) THEN
           BEGIN
              WK_IS_OK = WK_RESULT;
              WK_IS_ERROR = WK_IS_ERROR || WK_ERROR_TEXT;
           END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after loop');
        END /* end of for loop */
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'end   loop');
        IF (WK_IS_OK = 0) THEN
        BEGIN
           /* PS_SSCC_STATUS = 'DC', */
           /* AND PS_SSCC_STATUS IN ('GO','DC','DX','CL'); */
           UPDATE PACK_SSCC SET PS_EDI_ASN = :WK_PS_ASN_ID,
           PS_SSCC_STATUS = 'DN',
           PS_LAST_UPDATE_DATE = :WK_DATE,
           PS_LAST_UPDATE_BY = :WK_USER
       /*  WHERE PS_DESPATCH_ID = :WK_PD_ID */
           WHERE PS_OUT_DESPATCH_ID = :WK_PD_ID
           AND PS_EDI_ASN IS NULL
           AND PS_SSCC_STATUS IN ('DC','DX','CL','NF')
           AND  (COALESCE(PS_QTY_SHIPPED,0) > 0);
           WK_ERROR_TEXT = 'PACK_SSCC.PS_EDI_ASN=' || :WK_PS_ASN_ID || '|';
           IF (STRLEN(WK_ERROR_TEXT) <= 232) THEN 
           BEGIN
              WK_RESPONSE_FINAL = 'Processed successfully|' || WK_ERROR_TEXT;
           END
           ELSE
           BEGIN
              WK_RESPONSE_FINAL = 'Processed successfully|' || V6SUBSTRING(:WK_ERROR_TEXT,1,232);
           END
        END
        ELSE
        BEGIN
           IF (STRLEN(WK_IS_ERROR) <= 254) THEN 
           BEGIN
              WK_RESPONSE_FINAL =  WK_IS_ERROR;
           END
           ELSE
           BEGIN
              WK_RESPONSE_FINAL =  V6SUBSTRING(WK_IS_ERROR,1,254);
           END
        END
     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME, 'after get error text');
     END
     ELSE
     BEGIN

        IF (NEW.TRN_CODE = 'R' AND WK_IS_OK = 0) THEN
        BEGIN
           /* get next ASN */
           SELECT GS1_ASN_PARAM_ID , COMPANY_EDI_VENDOR_NO, IMPORT_DIRECTORY 
           FROM COMPANY 
           WHERE COMPANY_ID = NEW.COMPANY_ID
           INTO :WK_LEGACY_PARAM_ID, :WK_CO_EDI_VENDOR, :WK_CO_EXPORT_DIRECTORY;
           IF (WK_CO_EXPORT_DIRECTORY IS NULL) THEN
           BEGIN
              WK_CO_EXPORT_DIRECTORY = '/tmp';
           END
           ELSE
           BEGIN
              WK_CO_EXPORT_DIRECTORY = WK_CO_EXPORT_DIRECTORY || '/asn';
           END
           WK_FILENAME = WK_CO_EXPORT_DIRECTORY || '/DSAS.';
           WK_FILENAME2 = '/tmp/DSAS.';
           WK_FILENAME3 = WK_CO_EXPORT_DIRECTORY || '/DSAS.';
           /* include the company name of the order in the file name */
           IF (NEW.COMPANY_ID IS NOT NULL) THEN
           BEGIN
              WK_FILENAME = WK_FILENAME || NEW.COMPANY_ID;
              WK_FILENAME2 = WK_FILENAME2 || NEW.COMPANY_ID;
              WK_FILENAME3 = WK_FILENAME3 || NEW.COMPANY_ID;
           END
           WK_DATE_X = MER_DAY('NOW') || '.' || MER_MONTH('NOW') || '.' || SUBSTR(CAST(MER_YEAR('NOW') AS VARCHAR(4)) , 3,4);
           WK_TIME_X = MER_HOUR('NOW') || '.' || MER_MINUTE('NOW') ;
           WK_DATE_X = WK_DATE_X || '-' || WK_TIME_X;
           WK_FILENAME = WK_FILENAME || WK_DATE_X;
           WK_FILENAME2 = WK_FILENAME2 || WK_DATE_X;
           WK_FILENAME3 = WK_FILENAME3 || WK_DATE_X;
           WK_FILENAME = WK_FILENAME || '.csv';
           WK_FILENAME2 = WK_FILENAME2 || '.csv2';
           WK_FILENAME3 = WK_FILENAME3 || '.csv3';
           WK_LEGACY_ID  = '';
/*
           SELECT LEGACY_ID 
           FROM GET_NEXT_LEGACY (:WK_LEGACY_PARAM_ID) 
           INTO :WK_LEGACY_ID;
           WK_PS_ASN_ID = WK_LEGACY_ID ;
*/
           /* only select those sscc's for the despatch with PACK_SSCC.PS_EDI_ASN null */
           FOR SELECT PACK_SSCC.PS_SSCC, 
                      PACK_SSCC.PS_ASN_VENDOR_NO, 
                      PACK_SSCC.PS_CUSTOMER_EDI_NO, 
            /*        PACK_SSCC.PS_AWB_CONSIGNMENT_NO,  */    
                      PACK_SSCC.PS_OUT_AWB_CONSIGNMENT_NO,        
                      PACK_SSCC.PS_DESPATCHED_DATE,
                      PACK_SSCC.PS_SCHED_DEL_DATE,
                      PACK_SSCC.PS_DEL_TO_DC_NO,
                      PACK_SSCC.PS_PICK_ORDER,
                      PACK_SSCC.PS_PICK_ORDER_DATE,
                      PACK_SSCC.PS_DEL_TO_STORE_NO,
                      PACK_SSCC.PS_PRODUCT_CODE,
                      PACK_SSCC.PS_PRODUCT_GTIN,
                      PACK_SSCC.PS_QTY_SHIPPED,
                      PACK_SSCC.PS_BATCH_NO,
                      PACK_SSCC.PS_SCHED_DEL_TIME,
             /*       PACK_SSCC.PS_CARRIER_ID, */
                      PACK_SSCC.PS_OUT_CARRIER_ID,
                      PACK_SSCC.PS_SSCC_WEIGHT,
                      PACK_SSCC.PS_SSCC_CUBIC,
                      PACK_SSCC.PS_TOTAL_OUTERS,
                      PACK_SSCC.PS_OUTER_BARCODE,
                      PACK_SSCC.PS_QTY_ORDERED,
                      PACK_SSCC.PS_EDI_ASN,
                      PACK_SSCC.PS_USE_BY_DATE,
                      PACK_SSCC.PS_ORDERED_BY_UOM_GTIN,
                      PACK_SSCC.PS_PICK_LABEL_NO,
                      PACK_SSCC.PS_LEGACY_PICK_ORDER,
                      PACK_SSCC.PS_OUT_SSCC,
                      PICK_ORDER.CREATE_DATE,
                      CARRIER.CARRIER_PARENT_ID ,
                      (SELECT SUM(PICK_ITEM_DETAIL.QTY_PICKED) FROM PICK_ITEM_DETAIL WHERE PICK_ITEM_DETAIL.DESPATCH_ID = PACK_SSCC.PS_OUT_DESPATCH_ID AND PICK_ITEM_DETAIL.PICK_LABEL_NO = PACK_SSCC.PS_PICK_LABEL_NO AND PICK_ITEM_DETAIL.PICK_DETAIL_STATUS NOT IN ('XX', 'AS') ) ,
                      PACK_SSCC.RECORD_ID,
                      PROD_PROFILE.NET_WEIGHT,
                      (PROD_PROFILE.DIMENSION_X *  PROD_PROFILE.DIMENSION_Y * PROD_PROFILE.DIMENSION_Z) 
               FROM PACK_SSCC
              JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PACK_SSCC.PS_PICK_ORDER 
              JOIN CARRIER ON CARRIER.CARRIER_ID = PACK_SSCC.PS_OUT_CARRIER_ID
              JOIN PICK_ITEM  ON PICK_ITEM.PICK_LABEL_NO = PACK_SSCC.PS_PICK_LABEL_NO
              /* LEFT OUTER JOIN PROD_PROFILE ON PACK_SSCC.PS_PRODUCT_GTIN = PROD_PROFILE.PROD_ID AND PICK_ORDER.COMPANY_ID = PROD_PROFILE.COMPANY_ID */
              LEFT OUTER JOIN PROD_PROFILE ON PICK_ITEM.PROD_ID = PROD_PROFILE.PROD_ID AND PICK_ORDER.COMPANY_ID = PROD_PROFILE.COMPANY_ID
          /*     WHERE PS_DESPATCH_ID = :WK_PD_ID */
          /*     AND PACK_SSCC.PS_SSCC_STATUS IN ('GO','DC','DX','CL','DN','NF') */
               WHERE PACK_SSCC.PS_OUT_DESPATCH_ID = :WK_PD_ID
                 AND (PACK_SSCC.PS_EDI_ASN IS NOT NULL)
                 AND PACK_SSCC.PS_SSCC_STATUS IN ('DC','DX','CL','DN','NF')
                 AND  (COALESCE(PS_QTY_SHIPPED,0) > 0) 
               INTO :WK_PS_SSCC_ID, 
                    :WK_PS_ASN_VENDOR_NO, 
                    :WK_PS_CUSTOMER_EDI_NO, 
                    :WK_PS_AWB_CONSIGNMENT_NO, 
                    :WK_PS_DESPATCHED_DATE,
                    :WK_PS_SCHED_DEL_DATE,
                    :WK_PS_DEL_TO_DC_NO,
                    :WK_PS_PICK_ORDER,
                    :WK_PS_PICK_ORDER_DATE,
                    :WK_PS_DEL_TO_STORE_NO,
                    :WK_PS_PRODUCT_IN_HOUSE_CODE,
                    :WK_PS_PRODUCT_GTIN,
                    :WK_PS_QTY_SHIPPED,
                    :WK_PS_BATCH_NO,
                    :WK_PS_SCHED_DEL_TIME,
                    :WK_PS_CARRIER_ID,
                    :WK_PS_SSCC_WEIGHT,
                    :WK_PS_SSCC_CUBIC,
                    :WK_PS_TOTAL_OUTERS,
                    :WK_PS_OUTER_BARCODE,
                    :WK_PS_QTY_ORDERED,
                    :WK_PS_ASN_ID ,
                    :WK_PS_USE_BY_DATE,
                    :WK_PS_ORDERED_BY_UOM_GTIN,
                    :WK_PS_PICK_LABEL_NO,
                    :WK_PS_LEGACY_PICK_ORDER,
                    :WK_PS_OUT_SSCC_ID,
                    :WK_PO_CREATE_DATE,
                    :WK_CA_PARENT_CARRIER_ID,
                    :WK_PID_QTY_SHIPPED,
                    :WK_PS_RECORD_ID,
                    :WK_PP_NET_WEIGHT,
                    :WK_PP_VOLUME
           DO
           BEGIN
              /* create csv record */
              IF (COALESCE(WK_PS_DESPATCHED_DATE,'') = '') THEN
              BEGIN
                 WK_PS_DESPATCHED_DATE = MER_YEAR('NOW') ||  LPAD(MER_MONTH('NOW'),'0',2) ||  LPAD(MER_DAY('NOW'),'0',2) ;  
              END
              IF (COALESCE(WK_PS_PICK_ORDER_DATE,'') = '') THEN
              BEGIN
                 /* SELECT CREATE_DATE FROM PICK_ORDER WHERE PICK_ORDER = :WK_PS_PICK_ORDER INTO :WK_PO_CREATE_DATE; */
                 WK_PS_PICK_ORDER_DATE = MER_YEAR(:WK_PO_CREATE_DATE) ||  LPAD(MER_MONTH(:WK_PO_CREATE_DATE),'0',2) ||  LPAD(MER_DAY(:WK_PO_CREATE_DATE),'0',2) ;  
              END
              IF (COALESCE(WK_PS_QTY_SHIPPED,0) = 0) THEN
              BEGIN
                 WK_PS_QTY_SHIPPED = 0;
                 /* need to calculate this from the pick item detail qty_picked */
/*
                 SELECT SUM(QTY_PICKED) FROM PICK_ITEM_DETAIL
                 WHERE DESPATCH_ID = :WK_PD_ID
                 AND PICK_LABEL_NO = :WK_PS_PICK_LABEL_NO
                 AND PICK_DETAIL_STATUS <> 'XX' 
                 AND PICK_DETAIL_STATUS <> 'AS' 
                 INTO :WK_PID_QTY_SHIPPED;
*/
                 IF (WK_PID_QTY_SHIPPED IS NOT NULL) THEN
                 BEGIN
                    WK_PS_QTY_SHIPPED = WK_PID_QTY_SHIPPED ;
                 END
              END
              WK_PO_EXPORTED_DATE = MER_YEAR('NOW') ||  LPAD(MER_MONTH('NOW'),'0',2) ||  LPAD(MER_DAY('NOW'),'0',2) ;  
              /* SELECT CARRIER_PARENT_ID FROM CARRIER WHERE CARRIER_ID = :WK_PS_CARRIER_ID INTO :WK_CA_PARENT_CARRIER_ID; */
              IF (WK_CA_PARENT_CARRIER_ID IS NULL) THEN
              BEGIN
                 WK_CA_PARENT_CARRIER_ID = WK_PS_CARRIER_ID;
              END
              IF (COALESCE(WK_PS_USE_BY_DATE,'') = '') THEN
              BEGIN
                 WK_PS_USE_BY_DATE = '';
              END
              IF (COALESCE(WK_PS_ORDERED_BY_UOM_GTIN,0) = 0) THEN
              BEGIN
                 WK_PS_ORDERED_BY_UOM_GTIN = 0;
              END
/*
              IF (COALESCE(WK_PS_SSCC_CUBIC,0.0) > 0.0) THEN
              BEGIN
                 WK_PS_SSCC_CUBIC_OUT = CAST(WK_PS_SSCC_CUBIC AS DECIMAL(9,5));
              END
              ELSE
              BEGIN
                 WK_PS_SSCC_CUBIC_OUT = 0.0;
              END
*/
              IF (WK_PS_SSCC_CUBIC IS NULL) THEN
              BEGIN
                 WK_PS_SSCC_CUBIC_OUT = 0.0;
              END
              ELSE
              BEGIN
                 IF (WK_PS_SSCC_CUBIC = 0) THEN
                 BEGIN
                    WK_PS_SSCC_CUBIC_OUT = 0.0;
                 END
                 ELSE
                 BEGIN
                    IF (WK_PS_SSCC_CUBIC > 9999) THEN
                    BEGIN
                       WK_PS_SSCC_CUBIC_OUT = 9999;
                    END
                    ELSE
                    BEGIN
                       WK_PS_SSCC_CUBIC_OUT = CAST(WK_PS_SSCC_CUBIC AS DECIMAL(9,5)); 
                    END
                 END
              END
   
              /* write it to the transactions4 table */
              WK_GM_MESSAGE = '';
              SELECT MESSAGE_ID 
              FROM GET_NEXT_MESSAGE 
              INTO :WK_GM_MESSAGE;
              WK_T4_DELIM = '|';
              WK_C4_DELIM = ',';
              WK_T4_TRAN_DATA = WK_USER || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = '' ;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || WK_DEVICE_ID || WK_T4_DELIM ;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || WK_GM_MESSAGE || WK_T4_DELIM ;
              IF (COALESCE(WK_PS_ASN_VENDOR_NO,'') = '') THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_asn_vendor_no>' ||  WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||   WK_C4_DELIM ;
              END
              ELSE
              BEGIN
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_asn_vendor_no>' || WK_PS_ASN_VENDOR_NO || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_ASN_VENDOR_NO || WK_C4_DELIM ;
              END
              IF (COALESCE(WK_PS_CUSTOMER_EDI_NO,'') = '') THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_customer_edi_no>' ||  WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||   WK_C4_DELIM ;
              END
              ELSE
              BEGIN
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_customer_edi_no>' || WK_PS_CUSTOMER_EDI_NO || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_CUSTOMER_EDI_NO || WK_C4_DELIM ;
              END
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_edi_asn>' || WK_PS_ASN_ID || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_ASN_ID || WK_C4_DELIM ;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_awb_consignment_no>' || WK_PS_AWB_CONSIGNMENT_NO || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_AWB_CONSIGNMENT_NO || WK_C4_DELIM ;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_despatched_date>' || WK_PS_DESPATCHED_DATE || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_DESPATCHED_DATE || WK_C4_DELIM ;
              IF (COALESCE(WK_PS_SCHED_DEL_DATE,'') = '') THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sched_del_date>' ||  WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_C4_DELIM ;
              END
              ELSE
              BEGIN
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sched_del_date>' || WK_PS_SCHED_DEL_DATE || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_SCHED_DEL_DATE || WK_C4_DELIM ;
              END
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_del_to_dc_no>' || WK_PS_DEL_TO_DC_NO || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_DEL_TO_DC_NO || WK_C4_DELIM ;
/*
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_pick_order>' || WK_PS_PICK_ORDER || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_PICK_ORDER || WK_C4_DELIM ;
*/
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_pick_order>' || WK_PS_LEGACY_PICK_ORDER || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_LEGACY_PICK_ORDER || WK_C4_DELIM ;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_pick_order_date>' || WK_PS_PICK_ORDER_DATE || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_PICK_ORDER_DATE || WK_C4_DELIM ;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_del_to_store_no>' || WK_PS_DEL_TO_STORE_NO || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_DEL_TO_STORE_NO || WK_C4_DELIM ;
/*
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_pick_order2>' || WK_PS_PICK_ORDER || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_PICK_ORDER || WK_C4_DELIM ;
*/
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_pick_order2>' || WK_PS_LEGACY_PICK_ORDER || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_LEGACY_PICK_ORDER || WK_C4_DELIM ;
/*
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc>' || WK_PS_SSCC_ID || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_SSCC_ID || WK_C4_DELIM ;
*/
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc>' || WK_PS_OUT_SSCC_ID || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_OUT_SSCC_ID || WK_C4_DELIM ;
              IF (COALESCE(WK_PS_PRODUCT_IN_HOUSE_CODE,'') = '') THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_product_code>' || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_C4_DELIM ;
              END
              ELSE
              BEGIN
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_product_code>' || WK_PS_PRODUCT_IN_HOUSE_CODE || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_PRODUCT_IN_HOUSE_CODE || WK_C4_DELIM ;
              END
              IF (COALESCE(WK_PS_PRODUCT_GTIN,'') = '') THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_product_gtin>' ||  WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_C4_DELIM ;
              END
              ELSE
              BEGIN
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_product_gtin>' || WK_PS_PRODUCT_GTIN || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_PRODUCT_GTIN || WK_C4_DELIM ;
              END
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_shipped_qty>' || WK_PS_QTY_SHIPPED || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_QTY_SHIPPED || WK_C4_DELIM ;
/*
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<po_exported_date>' || WK_PO_EXPORTED_DATE || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PO_EXPORTED_DATE || WK_C4_DELIM ;
*/
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<po_expiry_date>' || WK_PS_USE_BY_DATE || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_USE_BY_DATE || WK_C4_DELIM ;
              IF (COALESCE(WK_PS_BATCH_NO,'') = '') THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_batch_no>' ||  WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_C4_DELIM ;
              END
              ELSE
              BEGIN
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_batch_no>' || WK_PS_BATCH_NO || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_BATCH_NO || WK_C4_DELIM ;
              END
              IF (COALESCE(WK_PS_SCHED_DEL_TIME,'') = '') THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sched_del_time>' ||  WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_C4_DELIM ;
              END
              ELSE
              BEGIN
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sched_del_time>' || WK_PS_SCHED_DEL_TIME || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_SCHED_DEL_TIME || WK_C4_DELIM ;
              END
              IF (COALESCE(WK_CA_PARENT_CARRIER_ID,'') = '') THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_carrier_id>' || WK_PS_CARRIER_ID || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_CARRIER_ID || WK_C4_DELIM ;
              END
              ELSE
              BEGIN
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_carrier_id>' || WK_CA_PARENT_CARRIER_ID || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_CA_PARENT_CARRIER_ID || WK_C4_DELIM ;
              END
              IF (COALESCE(WK_PS_SSCC_WEIGHT,0.0) = 0.0) THEN
              BEGIN
                 IF (COALESCE(WK_PP_NET_WEIGHT,0.0) = 0.0) THEN
                 BEGIN
                    WK_DUMMY = 1;
                    WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_weight>' || WK_T4_DELIM ;
                    WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_C4_DELIM ;
                 END
                 ELSE
                 BEGIN 
                    WK_PS_SSCC_WEIGHT = WK_PS_QTY_SHIPPED * WK_PP_NET_WEIGHT ;
                    WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_weight>' || WK_PS_SSCC_WEIGHT || WK_T4_DELIM ;
                    WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_SSCC_WEIGHT || WK_C4_DELIM ;
                 END
              END
              ELSE
              BEGIN
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_weight>' || WK_PS_SSCC_WEIGHT || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_SSCC_WEIGHT || WK_C4_DELIM ;
   /* check that this is dddd.ddd */
              END
              IF (COALESCE(WK_PS_SSCC_CUBIC,0.0) = 0.0) THEN
              BEGIN
                 WK_DUMMY = 1;
                 IF (COALESCE(WK_PP_VOLUME,0.0) = 0.0) THEN
                 BEGIN
                    WK_DUMMY = 1;
                    WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_cubic>' || WK_T4_DELIM ;
                    WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_C4_DELIM ;
                 END
                 ELSE
                 BEGIN 
                    WK_PS_SSCC_VOLUME = WK_PS_QTY_SHIPPED * WK_PP_VOLUME / 1000000 ;
                    IF (WK_PS_SSCC_VOLUME IS NULL) THEN
                    BEGIN
                       WK_PS_SSCC_VOLUME_OUT = 0.0;
                    END
                    ELSE
                    BEGIN
                       IF (WK_PS_SSCC_VOLUME = 0) THEN
                       BEGIN
                          WK_PS_SSCC_VOLUME_OUT = 0.0;
                       END
                       ELSE
                       BEGIN
                          IF (WK_PS_SSCC_VOLUME > 9999) THEN
                          BEGIN
                             WK_PS_SSCC_VOLUME_OUT = 9999;
                          END
                       END
                    END
                    WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_weight>' || WK_PS_SSCC_VOLUME_OUT || WK_T4_DELIM ;
                    WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_SSCC_VOLUME_OUT || WK_C4_DELIM ;
                 END
              END
              ELSE
              BEGIN
                 /* WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_cubic>' || WK_PS_SSCC_CUBIC || WK_T4_DELIM ; */
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_sscc_cubic>' || WK_PS_SSCC_CUBIC_OUT || WK_T4_DELIM ;
                 /* WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_SSCC_CUBIC || WK_C4_DELIM ; */
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_SSCC_CUBIC_OUT || WK_C4_DELIM ;
   /* check that this is a float */
              END
              IF (COALESCE(WK_CO_EDI_VENDOR,'') = '') THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<co_edi_vendor>' ||  WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_C4_DELIM ;
              END
              ELSE
              BEGIN
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<co_edi_vendor>' || WK_CO_EDI_VENDOR || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_CO_EDI_VENDOR || WK_C4_DELIM ;
              END
              IF (COALESCE(WK_PS_TOTAL_OUTERS,0) = 0) THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_shipped_outers>' ||  WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_C4_DELIM ;
              END
              ELSE
              BEGIN
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_shipped_outers>' || WK_PS_TOTAL_OUTERS || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_TOTAL_OUTERS || WK_C4_DELIM ;
              END
              IF (COALESCE(WK_PS_OUTER_BARCODE,'') = '') THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_outer_barcode>' ||  WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_C4_DELIM ;
              END
              ELSE
              BEGIN
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_outer_barcode>' || WK_PS_OUTER_BARCODE || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_OUTER_BARCODE || WK_C4_DELIM ;
              END
              IF (COALESCE(WK_PS_QTY_ORDERED,0) = 0) THEN
              BEGIN
                 WK_DUMMY = 1;
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_order_by_uom>' ||  WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_C4_DELIM ;
              END
              ELSE
              BEGIN
                 WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_order_by_uom>' || WK_PS_QTY_ORDERED || WK_T4_DELIM ;
                 WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_QTY_ORDERED || WK_C4_DELIM ;
              END
              /* qty shipped */
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_order_by_qty_shipped>' || WK_PS_QTY_SHIPPED || WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_QTY_SHIPPED || WK_C4_DELIM ;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_order_by_uom_gtin>' || WK_PS_ORDERED_BY_UOM_GTIN ||  WK_T4_DELIM ;
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA ||  WK_PS_ORDERED_BY_UOM_GTIN  || WK_C4_DELIM ;
              WK_T4_TRAN_DATA = WK_T4_TRAN_DATA || '<ps_order_by_gtin>' ||  WK_T4_DELIM ;
              /* WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || last field   ; */
/*
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_C4_DELIM || WK_PS_PICK_LABEL_NO || WK_C4_DELIM   ; 
              WK_C4_TRAN_DATA = WK_C4_TRAN_DATA || WK_PS_RECORD_ID    ; 
*/
   
              WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_C4_TRAN_DATA);
              IF (WK_RESULT <> 0) THEN
              BEGIN
                 WK_ERROR_TEXT = 'Failed to write DSAS.csv';
                 /* try the 2nd file */
                 WK_RESULT = FILE_WRITELN(WK_FILENAME2, WK_C4_TRAN_DATA);
                 IF (WK_RESULT <> 0) THEN
                 BEGIN
                    WK_ERROR_TEXT = 'Failed to write DSAS.csv and DSAS.csv2';
                    /* try the 3rd file */
                    WK_RESULT = FILE_WRITELN(WK_FILENAME3, WK_C4_TRAN_DATA);
                    IF (WK_RESULT <> 0) THEN
                    BEGIN
                       WK_ERROR_TEXT = 'Failed to write DSAS.csv and DSAS.csv2 and DSAS.csv3';
                   END
                 END
              END
              WK_T4_SOURCE = 'SSSSSSSSSSS' ;
              SELECT REC_ID FROM ADD_TRAN_V4 ( 'V4', 'DSNA','P',
                 :WK_DATE,
                 :WK_T4_DELIM,
                 :WK_USER,
                 :WK_DEVICE_ID,
                 :WK_GM_MESSAGE,
                 :WK_T4_TRAN_DATA,
                 'F','','MASTER',0,
                 :WK_T4_SOURCE)
              INTO :WK_NEW_RECORD;
              IF (WK_RESULT <> 0) THEN
              BEGIN
                 WK_IS_OK = WK_RESULT;
                 WK_IS_ERROR = WK_IS_ERROR || WK_ERROR_TEXT;
              END
              WK_ERROR_TEXT = 'PACK_SSCC.PS_EDI_ASN=' || :WK_PS_ASN_ID || '|';
           END /* end of for loop */
           IF (WK_IS_OK = 0) THEN
           BEGIN
              /* UPDATE PACK_SSCC SET PS_SSCC_STATUS = 'DC', */
              /* AND PS_SSCC_STATUS IN ('GO','DC','DX','CL'); */
              UPDATE PACK_SSCC SET PS_SSCC_STATUS = 'DN',
              PS_LAST_UPDATE_DATE = :WK_DATE,
              PS_LAST_UPDATE_BY = :WK_USER
          /*  WHERE PS_DESPATCH_ID = :WK_PD_ID */
              WHERE PS_OUT_DESPATCH_ID = :WK_PD_ID
              AND (PS_EDI_ASN IS NOT NULL)
              AND PS_SSCC_STATUS IN ('DC','DX','CL')
              AND  (COALESCE(PS_QTY_SHIPPED,0) > 0);
           /* WK_ERROR_TEXT = 'PACK_SSCC.PS_EDI_ASN=' || :WK_PS_ASN_ID || '|'; */
              IF (STRLEN(WK_ERROR_TEXT) <= 232) THEN 
              BEGIN
                 WK_RESPONSE_FINAL = 'Processed successfully|' || WK_ERROR_TEXT;
              END
              ELSE
              BEGIN
                 WK_RESPONSE_FINAL = 'Processed successfully|' || V6SUBSTRING(:WK_ERROR_TEXT,1,232);
              END
           END
           ELSE
           BEGIN
              IF (STRLEN(WK_IS_ERROR) <= 254) THEN 
              BEGIN
                 WK_RESPONSE_FINAL =  WK_IS_ERROR;
              END
              ELSE
              BEGIN
                 WK_RESPONSE_FINAL =  V6SUBSTRING(WK_IS_ERROR,1,254);
              END
           END
        END
        ELSE
        BEGIN
           WK_RESPONSE_FINAL = 'Failed in Check of TRN_CODE';
           WK_RESPONSE_FINAL = WK_RESPONSE_FINAL ||  '|||'  ;
        END
     END

     IF (WK_IS_OK = 0) THEN
     BEGIN
        EXECUTE PROCEDURE UPDATE_TRAN (:WK_RECORD, 'T', :WK_RESPONSE_FINAL);
     END
     ELSE
     BEGIN
        EXECUTE PROCEDURE UPDATE_TRAN (:WK_RECORD, 'F', :WK_RESPONSE_FINAL);
     END

     WK_LOG_RESULT = FILE_WRITELN(WK_LOG_FILENAME,'DSAS End');
   /* EXECUTE PROCEDURE TRAN_ARCHIVE; */
  END
 END
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
