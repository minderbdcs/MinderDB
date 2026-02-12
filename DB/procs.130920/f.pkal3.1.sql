COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;
 
/*
pkal
D
E
G

pkal2
H
I
J

pkal3
'F' 
'K' 
'L' 
'M' 

*/

CREATE OR ALTER TRIGGER RUN_TRANSACTION_PKAL3 FOR TRANSACTIONS 
ACTIVE AFTER INSERT POSITION 49 
AS
DECLARE VARIABLE WK_AUTORUN INTEGER;
DECLARE VARIABLE WK_PICK_QTY INTEGER;
DECLARE VARIABLE WK_PICK_CNT INTEGER;
DECLARE VARIABLE WK_LABEL VARCHAR(7);
DECLARE VARIABLE WK_DEVICE CHAR(2);
DECLARE VARIABLE WK_USER VARCHAR(10);
DECLARE VARIABLE WK_ORDER VARCHAR(30);
DECLARE VARIABLE WK_ORDER_STATUS CHAR(2);
DECLARE VARIABLE WK_ORDER_START TIMESTAMP;
DECLARE VARIABLE WK_DATE TIMESTAMP;
DECLARE VARIABLE WK_RECORD INTEGER;
DECLARE VARIABLE WK_PI_LABEL VARCHAR(7);
DECLARE VARIABLE WK_PI_SSN VARCHAR(20);
DECLARE VARIABLE WK_PI_PROD VARCHAR(30);
DECLARE VARIABLE WK_PI_WH CHAR(2);
DECLARE VARIABLE WK_PI_LOCN VARCHAR(10);
DECLARE VARIABLE WK_PI_LASTLOCN VARCHAR(10);
DECLARE VARIABLE WK_PI_QTY INTEGER;
DECLARE VARIABLE WK_PI_STATUS CHAR(2);
DECLARE VARIABLE WK_PI_STATUS_2 CHAR(2);
DECLARE VARIABLE WK_PI_DESCRIPTION VARCHAR(40);
DECLARE VARIABLE WK_PI_ORDER VARCHAR(15);
DECLARE VARIABLE WK_PI_ORDER_QTY INTEGER;
DECLARE VARIABLE WK_PI_DESPATCH_LOCN VARCHAR(10);
DECLARE VARIABLE WK_PI_TYPE   VARCHAR(10);
DECLARE VARIABLE WK_DIRECTORY VARCHAR(80);
DECLARE VARIABLE WK_FILENAME VARCHAR(80);
DECLARE VARIABLE WK_LABEL_LINE VARCHAR(330);
DECLARE VARIABLE WK_RESULT INTEGER;
DECLARE VARIABLE WK_PROD_SSN VARCHAR(20);
DECLARE VARIABLE WK_UOM CHAR(2);
DECLARE VARIABLE WK_PICK_TYPE CHAR(1);
DECLARE VARIABLE WK_FOUND_PICK INTEGER;
DECLARE VARIABLE WK_SEQ INTEGER;
DECLARE VARIABLE WK_DESPATCH_GROUP VARCHAR(10);
DECLARE VARIABLE WK_TOT_GROUP_LOCNS INTEGER;
DECLARE VARIABLE WK_TOT_GROUP_PRODUCTS_USED INTEGER;
DECLARE VARIABLE WK_TOT_GROUPS_PRODUCTS_USED INTEGER;
DECLARE VARIABLE WK_TOT_GROUP_EMPTY INTEGER;
DECLARE VARIABLE WK_TOT_ORDER_PRODUCTS INTEGER;
DECLARE VARIABLE WK_MAX_ORDERS INTEGER;
DECLARE VARIABLE WK_MAX_PRODUCTS INTEGER;
DECLARE VARIABLE WK_TOT_GROUPS_ORDERS INTEGER;
/* DECLARE VARIABLE WK_WHO_FOR VARCHAR(40); */
DECLARE VARIABLE WK_WHO_FOR VARCHAR(1024);
DECLARE VARIABLE WK_WHO_FOR2 VARCHAR(40);
DECLARE VARIABLE WK_FOUND INTEGER;
DECLARE VARIABLE WK_GM_MESSAGE VARCHAR(10);
DECLARE VARIABLE WK_T4_DELIM CHAR(1);
DECLARE VARIABLE WK_T4_TRAN_DATA VARCHAR(1024);
DECLARE VARIABLE WK_T4_SOURCE VARCHAR(512);
DECLARE VARIABLE WK_NEW_RECORD INTEGER;
DECLARE VARIABLE WK_CN_PRIORITY SMALLINT;
DECLARE VARIABLE WK_DO_UCIS CHAR(1);
DECLARE VARIABLE WK_DO_GSMD CHAR(1);
DECLARE VARIABLE WK_PROD_OK VARCHAR(80);
DECLARE VARIABLE WK_BUFFER VARCHAR(80);
DECLARE VARIABLE WK_WORK_PROD VARCHAR(30);
DECLARE VARIABLE WK_WORK_PROD2 VARCHAR(30);
DECLARE VARIABLE WK_WORK_TOPICK_QTY INTEGER;
DECLARE VARIABLE WK_WORK_PICKED_QTY INTEGER;
DECLARE VARIABLE WK_WORK_ORDER_QTY INTEGER;
DECLARE VARIABLE WK_WORK_LABEL VARCHAR(7);
DECLARE VARIABLE WK_AVAILABLE_QTY INTEGER;
DECLARE VARIABLE WK_ALLOC_ORDER_QTY INTEGER;
DECLARE VARIABLE WK_ORDER_QTY INTEGER;
DECLARE VARIABLE WK_PICKED_QTY INTEGER;
DECLARE VARIABLE WK_IMPORTSTATUS VARCHAR(40); 
DECLARE VARIABLE WK_TOT_ORDER_PRODUCTS_GROUP INTEGER;
DECLARE VARIABLE WK_MOVE_PRIORITY INTEGER;
DECLARE VARIABLE WK_HELD_STATUS VARCHAR(2); 
DECLARE VARIABLE WK_PROD_SIZE_TYPE VARCHAR(40);
DECLARE VARIABLE WK_ALLOW_EMPTY VARCHAR(50);
DECLARE VARIABLE WK_PO_WH_ID VARCHAR(10);
DECLARE VARIABLE WK_PO_COMPANY_ID VARCHAR(20);
DECLARE VARIABLE WK_DO_BY_LABEL VARCHAR(40);
DECLARE VARIABLE WK_PARTIAL_ORDER VARCHAR(1);
DECLARE VARIABLE WK_ALLOCATE_OK VARCHAR(1);
BEGIN
 WK_AUTORUN = GEN_ID(AUTOEXEC_TRANSACTIONS,0); 
 IF (WK_AUTORUN = 1) THEN
 BEGIN
  IF (NEW.TRN_TYPE = 'PKAL') THEN
  BEGIN
     IF (NEW.TRN_CODE = 'F') THEN
     BEGIN
        WK_BUFFER = '';
        WK_BUFFER = 'Processed successfully';
        /* allocate a product or issns of a product for a specific label */
        WK_USER = NEW.PERSON_ID;
        /* WK_WHO_FOR = NEW.REFERENCE; */
        WK_RECORD = NEW.RECORD_ID;
        WK_DEVICE = NEW.WH_ID;
        WK_PI_LABEL = NEW.OBJECT;
        WK_DATE = NEW.TRN_DATE;
/*
        EXECUTE PROCEDURE GET_REFERENCE_FIELD NEW.REFERENCE, 1  RETURNING_VALUES :WK_WHO_FOR ; 
        EXECUTE PROCEDURE GET_REFERENCE_FIELD NEW.REFERENCE, 2  RETURNING_VALUES :WK_WORK_PROD ; 
*/
        /* cannot trust the product or who for - use the pick_label and sys_equip for this */
        WK_CN_PRIORITY = 0;
        SELECT CURRENT_PERSON, LAST_PERSON
        FROM SYS_EQUIP
        WHERE DEVICE_ID = :WK_DEVICE
        INTO :WK_WHO_FOR, :WK_WHO_FOR2;
        IF (WK_WHO_FOR IS NULL) THEN
        BEGIN
           WK_WHO_FOR = WK_WHO_FOR2;
        END
        SELECT DEFAULT_PICK_PRIORITY, PICK_IMPORT_SSN_STATUS , WARN_PICK_PRIORITY
        FROM CONTROL 
        INTO :WK_CN_PRIORITY, :WK_IMPORTSTATUS, :WK_MOVE_PRIORITY;
/*
=====================================================================
 for all unallocated orders 
 with the product from pick_item
 then allocate to device 
====================================================================
*/
        WK_DO_BY_LABEL = 'T';
        SELECT DESCRIPTION
        FROM OPTIONS
        WHERE GROUP_CODE = 'PKAL'
        AND CODE = 'F|BYLABEL'
        INTO :WK_DO_BY_LABEL;
        IF (WK_DO_BY_LABEL IS NULL) THEN
        BEGIN
           WK_DO_BY_LABEL = 'T';
        END
        IF (WK_DO_BY_LABEL = 'T') THEN
        BEGIN
           WK_ORDER  = '';
           WK_WORK_ORDER_QTY = 0;
           WK_WORK_PICKED_QTY = 0;
           FOR SELECT PICK_ITEM.PICK_ORDER,
               PICK_ITEM.PROD_ID,
               PICK_ITEM.PICK_ORDER_QTY , 
               PICK_ITEM.PICKED_QTY 
               FROM PICK_ITEM
               JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PICK_ITEM.PICK_ORDER
               WHERE PICK_ITEM.PICK_LABEL_NO = :WK_PI_LABEL
               AND PICK_ITEM.PICK_LINE_STATUS IN ('OP','UP')
               AND PICK_ORDER.PICK_STATUS IN ('OP','DA')
               INTO :WK_ORDER, :WK_WORK_PROD, :WK_WORK_ORDER_QTY, :WK_WORK_PICKED_QTY
           DO
           BEGIN
              IF (WK_WORK_ORDER_QTY IS NULL) THEN
              BEGIN
                 WK_WORK_ORDER_QTY = 0;
              END
              IF (WK_WORK_PICKED_QTY IS NULL) THEN
              BEGIN
                 WK_WORK_PICKED_QTY = 0;
              END
              IF (WK_WORK_PROD IS NOT NULL) THEN
              BEGIN
                 WK_WORK_PROD = ALLTRIM(WK_WORK_PROD);
                 IF (STRLEN(WK_WORK_PROD) = 0) THEN
                 BEGIN
                    WK_WORK_PROD = NULL;
                 END
              END
              SELECT WH_ID, COMPANY_ID
              FROM PICK_ORDER
              WHERE PICK_ORDER.PICK_ORDER = :WK_ORDER
              INTO :WK_PO_WH_ID, :WK_PO_COMPANY_ID;
              IF (WK_PO_WH_ID IS NULL) THEN
              BEGIN
                 WK_PO_WH_ID = 'ALL';
              END
              IF (WK_PO_COMPANY_ID IS NULL) THEN
              BEGIN
                 WK_PO_COMPANY_ID = 'ALL';
              END
              WK_HELD_STATUS = '';
              SELECT OPTIONS.DESCRIPTION, PICK_ORDER.PICK_STATUS
              FROM PICK_ORDER
              LEFT OUTER JOIN OPTIONS ON OPTIONS.GROUP_CODE = 'CMPPKHELD' AND OPTIONS.CODE = (PICK_ORDER.COMPANY_ID || '|' || PICK_ORDER.P_COUNTRY)
              WHERE PICK_ORDER.PICK_ORDER = :WK_ORDER
              INTO :WK_HELD_STATUS, :WK_ORDER_STATUS;
              IF (WK_HELD_STATUS IS NULL) THEN
              BEGIN
                 SELECT OPTIONS.DESCRIPTION
                 FROM PICK_ORDER
                 JOIN OPTIONS ON OPTIONS.GROUP_CODE = 'CMPPKHELD' AND OPTIONS.CODE = PICK_ORDER.COMPANY_ID 
                 WHERE PICK_ORDER.PICK_ORDER = :WK_ORDER
                 INTO :WK_HELD_STATUS;
              END
              IF (WK_HELD_STATUS IS NULL) THEN
              BEGIN
                 WK_HELD_STATUS = 'HD';
              END
              IF (WK_ORDER_STATUS IS NULL) THEN
              BEGIN
                 WK_ORDER_STATUS = 'UC';
              END
              WK_PROD_OK = '';
              IF (WK_ORDER_STATUS = 'OP' OR WK_ORDER_STATUS = 'DA') THEN
              BEGIN
                 BEGIN
                    WK_WORK_TOPICK_QTY = WK_WORK_ORDER_QTY - WK_WORK_PICKED_QTY;
                    WK_AVAILABLE_QTY = 0;
                    IF (WK_WORK_PROD IS NOT NULL) THEN
                    BEGIN
                       /* get available qty */
                       IF (WK_PO_WH_ID = 'ALL') THEN
                       BEGIN
                          /* allow all wh_id */
                          IF (WK_PO_COMPANY_ID = 'ALL') THEN
                          BEGIN
                             /* allow all wh_id and all company_id */
                             SELECT SUM( ISSN.CURRENT_QTY ) 
                                   FROM ISSN
                                   WHERE ISSN.PROD_ID = :WK_WORK_PROD
                                   AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                   GROUP BY ISSN.PROD_ID
                             INTO :WK_AVAILABLE_QTY;
                          END
                          ELSE
                          BEGIN
                             /* allow all wh_id and required company_id */
                             SELECT SUM( ISSN.CURRENT_QTY ) 
                                   FROM ISSN
                                   WHERE ISSN.PROD_ID = :WK_WORK_PROD
                                   AND ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                                   AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                   GROUP BY ISSN.PROD_ID
                             INTO :WK_AVAILABLE_QTY;
                          END
                       END
                       ELSE
                       BEGIN
                          /* only required wh_id */
                          IF (WK_PO_COMPANY_ID = 'ALL') THEN
                          BEGIN
                             /* only required wh_id and  all company_id */
                             SELECT SUM( ISSN.CURRENT_QTY ) 
                                   FROM ISSN
                                   WHERE ISSN.PROD_ID = :WK_WORK_PROD
                                   AND ISSN.WH_ID = :WK_PO_WH_ID
                                   AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                   GROUP BY ISSN.PROD_ID
                             INTO :WK_AVAILABLE_QTY;
                          END
                          ELSE
                          BEGIN
                             /* only required wh_id and  required company_id */
                             SELECT SUM( ISSN.CURRENT_QTY ) 
                                   FROM ISSN
                                   WHERE ISSN.PROD_ID = :WK_WORK_PROD
                                   AND ISSN.WH_ID = :WK_PO_WH_ID
                                   AND ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                                   AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                   GROUP BY ISSN.PROD_ID
                             INTO :WK_AVAILABLE_QTY;
                          END
                       END
                    END
                    IF (WK_AVAILABLE_QTY IS NULL) THEN
                    BEGIN
                       WK_AVAILABLE_QTY = 0;
                    END
                    /* now must get qty allocated on order not picked */
                    WK_PICKED_QTY = 0;
                    WK_ORDER_QTY = 0;
                    IF (WK_WORK_PROD IS NOT NULL) THEN
                    BEGIN
                       SELECT SUM( PICK_ITEM.PICK_ORDER_QTY ), 
                              SUM( PICK_ITEM.PICKED_QTY ) 
                              FROM PICK_ITEM
                              LEFT OUTER JOIN ISSN ON ISSN.SSN_ID = PICK_ITEM.SSN_ID
                              WHERE (PICK_ITEM.PROD_ID = :WK_WORK_PROD
                              OR  ISSN.PROD_ID = :WK_WORK_PROD)
                              AND ('AL' = PICK_ITEM.PICK_LINE_STATUS)
                            INTO :WK_ORDER_QTY, :WK_PICKED_QTY;
                    END
                    IF (WK_ORDER_QTY IS NULL) THEN
                    BEGIN
                       WK_ORDER_QTY = 0;
                    END
                    IF (WK_PICKED_QTY IS NULL) THEN
                    BEGIN
                       WK_PICKED_QTY = 0;
                    END
                    WK_ALLOC_ORDER_QTY = WK_ORDER_QTY - WK_PICKED_QTY;
                    WK_AVAILABLE_QTY = WK_AVAILABLE_QTY - WK_ALLOC_ORDER_QTY;
                    IF (WK_WORK_PROD IS NULL) THEN
                    BEGIN
                       /* for an ssn decision already made in the confirm */
                       WK_AVAILABLE_QTY = WK_WORK_TOPICK_QTY;
                    END
                    IF (WK_AVAILABLE_QTY < WK_WORK_TOPICK_QTY ) THEN
                    BEGIN
                       IF (LEN(WK_PROD_OK) < 53) THEN
                       BEGIN
                          WK_PROD_OK = WK_PROD_OK || ' ' || WK_WORK_PROD;
                       END
                       /* IF (WK_HELD_STATUS = 'HD') THEN */
                       /* IF ((WK_HELD_STATUS = 'HD') OR (WK_HELD_STATUS = 'CN')) THEN */
                       IF ((WK_HELD_STATUS = 'HD') OR (WK_HELD_STATUS = 'CN') OR (WK_HELD_STATUS = 'AS')) THEN
                       BEGIN
                          UPDATE PICK_ITEM 
                          SET PICK_LINE_STATUS = :WK_HELD_STATUS,
                          REASON = 'NOT ENOUGH STOCK'
                          WHERE PICK_LABEL_NO = :WK_PI_LABEL
                             AND PICK_LINE_STATUS IN ('OP','UP');
                       END
                       ELSE
                       BEGIN
                          UPDATE PICK_ITEM 
                          SET REASON = 'NOT ENOUGH STOCK'
                          WHERE PICK_LABEL_NO = :WK_PI_LABEL
                             AND PICK_LINE_STATUS IN ('OP','UP');
                       END
                    END
                 END /* if - was end of for */
                 BEGIN
                    IF (WK_PROD_OK <> '') THEN
                    BEGIN
                       UPDATE PICK_ORDER SET PICK_PRIORITY = :WK_MOVE_PRIORITY 
                       WHERE PICK_ORDER = :WK_ORDER;
                    END
                    WK_FOUND = 0;
                    SELECT FIRST 1 1
                    FROM PICK_ITEM
                    WHERE PICK_ITEM.PICK_LABEL_NO = :WK_PI_LABEL
                    AND PICK_ITEM.PICK_LINE_STATUS IN ('OP','UP')
                    INTO :WK_FOUND;
                    IF (WK_FOUND = 1) THEN
                    BEGIN
                       /* ok we can allocate this */
                       UPDATE PICK_ITEM 
                          SET USER_ID = :WK_WHO_FOR, 
                              DEVICE_ID = NULL, 
                              PICK_LINE_STATUS = 'CN' 
                           WHERE PICK_ORDER = :WK_ORDER
                           AND PICK_LINE_STATUS IN ('OP','UP')
                           AND PICK_ORDER_QTY = 0;
                       UPDATE PICK_ITEM 
                          SET USER_ID = :WK_WHO_FOR, 
                              DEVICE_ID = :WK_DEVICE,
                              PICK_LINE_STATUS = 'AL', 
                              PICK_STARTED = 'NOW'
                           WHERE PICK_LABEL_NO = :WK_PI_LABEL
                           AND PICK_LINE_STATUS IN ('OP','UP');
                       UPDATE PICK_ORDER
                          SET PICK_STARTED = 'NOW'
                           WHERE PICK_ORDER = :WK_ORDER
                           AND PICK_STARTED IS NULL;
                    END
                    ELSE
                    BEGIN
                       /* no lines left to allocate */
   /*           UPDATE PICK_ORDER SET PICK_PRIORITY = :WK_MOVE_PRIORITY,PICK_STATUS = 'HD'
                WHERE PICK_ORDER = :WK_ORDER; */
                    END
                 END
              END
           END /* end for */
        END /* end if do label only  */
        ELSE
        BEGIN
           /* do by order for this label no */
           WK_ORDER  = '';
           WK_PARTIAL_ORDER  = '';
           WK_WORK_ORDER_QTY = 0;
           WK_WORK_PICKED_QTY = 0;
           SELECT PICK_ITEM.PICK_ORDER, PICK_ORDER.PARTIAL_PICK_ALLOWED
               FROM PICK_ITEM
               JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PICK_ITEM.PICK_ORDER
               WHERE PICK_ITEM.PICK_LABEL_NO = :WK_PI_LABEL
               AND PICK_ITEM.PICK_LINE_STATUS IN ('OP','UP')
               AND PICK_ORDER.PICK_STATUS IN ('OP','DA')
               INTO :WK_ORDER, :WK_PARTIAL_ORDER ;
            IF (WK_ORDER IS NULL) THEN
            BEGIN
               WK_ORDER = '';
            END
            IF (WK_PARTIAL_ORDER IS NULL) THEN
            BEGIN
               WK_PARTIAL_ORDER = 'F';
            END
/* must check this order for partial picks
   if partial pick is F
   can only allocate if all lines are not 'AS'
   and have stock
*/

              WK_ALLOCATE_OK = 'T';
              WK_PROD_OK = '';
              IF (WK_ORDER = '') THEN
              BEGIN
                 WK_ALLOCATE_OK = 'F';
                 /* no order to allocate */
                 WK_BUFFER = 'No Order to Allocate ' ;
                 EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'F',:WK_BUFFER );
              END
                 
              IF ( (WK_ORDER <> '') AND (WK_PARTIAL_ORDER = 'F') ) THEN
              BEGIN
                 FOR SELECT PROD_ID, 
                     SUM( PICK_ITEM.PICK_ORDER_QTY ), 
                     SUM( PICK_ITEM.PICKED_QTY ) 
                     FROM PICK_ITEM
                     WHERE PICK_ORDER = :WK_ORDER
                     AND PICK_LINE_STATUS IN ('OP','UP')
                     GROUP BY PROD_ID
                     INTO :WK_WORK_PROD, :WK_WORK_ORDER_QTY, :WK_WORK_PICKED_QTY
                 DO
                 BEGIN
                    IF (WK_WORK_ORDER_QTY IS NULL) THEN
                    BEGIN
                       WK_WORK_ORDER_QTY = 0;
                    END
                    IF (WK_WORK_PICKED_QTY IS NULL) THEN
                    BEGIN
                       WK_WORK_PICKED_QTY = 0;
                    END
                    WK_WORK_TOPICK_QTY = WK_WORK_ORDER_QTY - WK_WORK_PICKED_QTY;
                    SELECT SUM( ISSN.CURRENT_QTY ) 
                          FROM ISSN
                          WHERE ISSN.PROD_ID = :WK_WORK_PROD
                          AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
   /* what about wh and company */
                          GROUP BY ISSN.PROD_ID
                       INTO :WK_AVAILABLE_QTY;
                    IF (WK_AVAILABLE_QTY IS NULL) THEN
                    BEGIN
                       WK_AVAILABLE_QTY = 0;
                    END
                    /* now must get qty allocated on order not picked */
                    WK_PICKED_QTY = 0;
                    WK_ORDER_QTY = 0;
                    SELECT SUM( PICK_ITEM.PICK_ORDER_QTY ), 
                           SUM( PICK_ITEM.PICKED_QTY ) 
                            FROM PICK_ITEM
                            WHERE PICK_ITEM.PROD_ID = :WK_WORK_PROD
                            AND ('AL' = PICK_ITEM.PICK_LINE_STATUS)
                            GROUP BY PICK_ITEM.PROD_ID
                         INTO :WK_ORDER_QTY, :WK_PICKED_QTY;
                    IF (WK_ORDER_QTY IS NULL) THEN
                    BEGIN
                       WK_ORDER_QTY = 0;
                    END
                    IF (WK_PICKED_QTY IS NULL) THEN
                    BEGIN
                       WK_PICKED_QTY = 0;
                    END
                    WK_ALLOC_ORDER_QTY = WK_ORDER_QTY - WK_PICKED_QTY;
                    WK_AVAILABLE_QTY = WK_AVAILABLE_QTY - WK_ALLOC_ORDER_QTY;
                    IF (WK_AVAILABLE_QTY < WK_WORK_TOPICK_QTY ) THEN
                    BEGIN
                       IF (LEN(WK_PROD_OK) < 53) THEN
                       BEGIN
                          WK_PROD_OK = WK_PROD_OK || ' ' || WK_WORK_PROD;
                       END
                    END
                 END /* end of for */
                 IF (WK_PROD_OK <> '') THEN
                 BEGIN
                    WK_BUFFER = 'Not enough Stock ' || :WK_PROD_OK;
                    WK_ALLOCATE_OK = 'F';
                    UPDATE PICK_ORDER SET PICK_PRIORITY = :WK_MOVE_PRIORITY
                    WHERE PICK_ORDER = :WK_ORDER;
                 END
                 ELSE
                 BEGIN
                    WK_FOUND = 0;
                    SELECT FIRST 1 1, PROD_ID
                    FROM PICK_ITEM
                    WHERE PICK_ORDER = :WK_ORDER
                    AND PICK_LINE_STATUS IN ('AS')
                    INTO :WK_FOUND, :WK_PROD_OK;
                    IF (WK_FOUND = 1) THEN
                    BEGIN
                       /* ok we cannot allocate this */
                       WK_ALLOCATE_OK = 'F';
                       WK_BUFFER = 'Not All lines have Stock ' || :WK_PROD_OK;
                    END
                 END
              END

           IF (WK_ALLOCATE_OK = 'T') THEN
           BEGIN
              /* now do pkal for this */
              EXECUTE PROCEDURE ADD_TRAN(
                    :WK_DEVICE,
                    'T|      ',
                    :WK_ORDER,
                    'PKAL',
                    'I',
                    :WK_DATE,
                    :WK_WHO_FOR,
                    0, /* qty */
                    'F',
                    '',
                    'MASTER',
                    0,
                    '          ', /* sub locn id */
                    NEW.INPUT_SOURCE,
                    :WK_USER,
                    NEW.DEVICE_ID);
           END
        END
        /* EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'T','Processed successfully'); */
        IF (WK_BUFFER = 'Processed successfully') THEN 
        BEGIN
           EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'T',WK_BUFFER);
        END
        ELSE
        BEGIN
           EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'F',WK_BUFFER);
        END
        /* EXECUTE PROCEDURE TRAN_ARCHIVE; */
     END /* code F */

     IF ((NEW.TRN_CODE = 'K') OR
         (NEW.TRN_CODE = 'L')) THEN
     BEGIN
/*
         copied from code I 
         allocate an order 
         either do issn / ssn lines code K
           or product only lines  code L 
*/
        WK_USER = NEW.PERSON_ID;
        WK_WHO_FOR = NEW.REFERENCE;
        WK_RECORD = NEW.RECORD_ID;
        WK_DEVICE = NEW.WH_ID;
        WK_ORDER = NEW.OBJECT;
        WK_PI_TYPE = '';
        IF (NEW.TRN_CODE = 'K') THEN
        BEGIN
           WK_PI_TYPE = 'I' ; 
        END
        IF (NEW.TRN_CODE = 'L') THEN
        BEGIN
           WK_PI_TYPE = 'P' ; 
        END
        WK_CN_PRIORITY = 0;
        WK_BUFFER = '';
        SELECT DEFAULT_PICK_PRIORITY, PICK_IMPORT_SSN_STATUS , WARN_PICK_PRIORITY
        FROM CONTROL 
        INTO :WK_CN_PRIORITY, :WK_IMPORTSTATUS, :WK_MOVE_PRIORITY;
/*
=====================================================================
  for product lines
  need to add orders for products with a size class (size_type)
  then include any product for that size class - rather than putting to 'HD' - no stock
====================================================================
*/
        WK_ORDER = NEW.OBJECT;
        BEGIN
           SELECT WH_ID, COMPANY_ID
           FROM PICK_ORDER
           WHERE PICK_ORDER.PICK_ORDER = :WK_ORDER
           INTO :WK_PO_WH_ID, :WK_PO_COMPANY_ID;
           IF (WK_PO_WH_ID IS NULL) THEN
           BEGIN
              WK_PO_WH_ID = 'ALL';
           END
           IF (WK_PO_COMPANY_ID IS NULL) THEN
           BEGIN
              WK_PO_COMPANY_ID = 'ALL';
           END
           WK_HELD_STATUS = '';
           SELECT OPTIONS.DESCRIPTION, PICK_ORDER.PICK_STATUS
           FROM PICK_ORDER
           LEFT OUTER JOIN OPTIONS ON OPTIONS.GROUP_CODE = 'CMPPKHELD' AND OPTIONS.CODE = (PICK_ORDER.COMPANY_ID || '|' || PICK_ORDER.P_COUNTRY)
           WHERE PICK_ORDER.PICK_ORDER = :WK_ORDER
           INTO :WK_HELD_STATUS, :WK_ORDER_STATUS;
           IF (WK_HELD_STATUS IS NULL) THEN
           BEGIN
              SELECT OPTIONS.DESCRIPTION
              FROM PICK_ORDER
              JOIN OPTIONS ON OPTIONS.GROUP_CODE = 'CMPPKHELD' AND OPTIONS.CODE = PICK_ORDER.COMPANY_ID 
              WHERE PICK_ORDER.PICK_ORDER = :WK_ORDER
              INTO :WK_HELD_STATUS;
           END
           IF (WK_HELD_STATUS IS NULL) THEN
           BEGIN
              WK_HELD_STATUS = 'HD';
           END
           IF (WK_ORDER_STATUS IS NULL) THEN
           BEGIN
              WK_ORDER_STATUS = 'UC';
           END
           WK_PROD_OK = '';
           IF ((WK_ORDER_STATUS = 'OP' OR WK_ORDER_STATUS = 'DA') AND (WK_PI_TYPE = 'P')) THEN
           BEGIN
              WK_WORK_PROD = '';
              WK_WORK_ORDER_QTY = 0;
              WK_WORK_PICKED_QTY = 0;
              FOR SELECT PROD_ID, 
                  SUM( PICK_ITEM.PICK_ORDER_QTY ), 
                  SUM( PICK_ITEM.PICKED_QTY )
                  FROM PICK_ITEM
                  WHERE PICK_ORDER = :WK_ORDER
                  AND PICK_LINE_STATUS IN ('OP','UP')
                  AND (PROD_ID IS NOT NULL)
                  GROUP BY PROD_ID
                  INTO :WK_WORK_PROD, :WK_WORK_ORDER_QTY, :WK_WORK_PICKED_QTY
              DO
              BEGIN
                 IF (WK_WORK_ORDER_QTY IS NULL) THEN
                 BEGIN
                    WK_WORK_ORDER_QTY = 0;
                 END
                 IF (WK_WORK_PICKED_QTY IS NULL) THEN
                 BEGIN
                    WK_WORK_PICKED_QTY = 0;
                 END
                 WK_PROD_SIZE_TYPE = '';
                 SELECT SIZE_TYPE
                 FROM PROD_PROFILE
                 WHERE PROD_ID = :WK_WORK_PROD 
                 AND COMPANY_ID = :WK_PO_COMPANY_ID
                 INTO :WK_PROD_SIZE_TYPE;
                 IF (WK_PROD_SIZE_TYPE IS NULL) THEN
                 BEGIN
                    WK_PROD_SIZE_TYPE = '';
                 END
                 WK_WORK_TOPICK_QTY = WK_WORK_ORDER_QTY - WK_WORK_PICKED_QTY;
                 WK_AVAILABLE_QTY = 0;
                 IF (WK_PROD_SIZE_TYPE = '') THEN
                 BEGIN
                    /* use only this product */
                    IF (WK_PO_WH_ID = 'ALL') THEN
                    BEGIN
                       /* allow all wh_id */
                       IF (WK_PO_COMPANY_ID = 'ALL') THEN
                       BEGIN
                          /* allow all wh_id and all company_id */
                          SELECT SUM( ISSN.CURRENT_QTY ) 
                                FROM ISSN
                                WHERE ISSN.PROD_ID = :WK_WORK_PROD
                                AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                GROUP BY ISSN.PROD_ID
                          INTO :WK_AVAILABLE_QTY;
                       END
                       ELSE
                       BEGIN
                          /* allow all wh_id and required company_id */
                          SELECT SUM( ISSN.CURRENT_QTY ) 
                                FROM ISSN
                                WHERE ISSN.PROD_ID = :WK_WORK_PROD
                                AND ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                                AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                GROUP BY ISSN.PROD_ID
                          INTO :WK_AVAILABLE_QTY;
                       END
                    END
                    ELSE
                    BEGIN
                       /* only required wh_id */
                       IF (WK_PO_COMPANY_ID = 'ALL') THEN
                       BEGIN
                          /* only required wh_id and  all company_id */
                          SELECT SUM( ISSN.CURRENT_QTY ) 
                                FROM ISSN
                                WHERE ISSN.PROD_ID = :WK_WORK_PROD
                                AND ISSN.WH_ID = :WK_PO_WH_ID
                                AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                GROUP BY ISSN.PROD_ID
                          INTO :WK_AVAILABLE_QTY;
                       END
                       ELSE
                       BEGIN
                          /* only required wh_id and  required company_id */
                          SELECT SUM( ISSN.CURRENT_QTY ) 
                                FROM ISSN
                                WHERE ISSN.PROD_ID = :WK_WORK_PROD
                                AND ISSN.WH_ID = :WK_PO_WH_ID
                                AND ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                                AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                GROUP BY ISSN.PROD_ID
                          INTO :WK_AVAILABLE_QTY;
                       END
                    END
                 END
                 ELSE
                 BEGIN
                    /* use products in this size type */
                    IF (WK_PO_WH_ID = 'ALL') THEN
                    BEGIN
                       /* allow all wh_id */
                       IF (WK_PO_COMPANY_ID = 'ALL') THEN
                       BEGIN
                          /* allow all wh_id and all company_id */
                          SELECT SUM( ISSN.CURRENT_QTY ) 
                                FROM PROD_PROFILE
                                JOIN ISSN ON ISSN.PROD_ID = PROD_PROFILE.PROD_ID
                                WHERE PROD_PROFILE.SIZE_TYPE  = :WK_PROD_SIZE_TYPE
                                AND PROD_PROFILE.COMPANY_ID = :WK_PO_COMPANY_ID
                                AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                GROUP BY PROD_PROFILE.SIZE_TYPE
                          INTO :WK_AVAILABLE_QTY;
                       END
                       ELSE
                       BEGIN
                          /* allow all wh_id and required company_id */
                          SELECT SUM( ISSN.CURRENT_QTY ) 
                                FROM PROD_PROFILE
                                JOIN ISSN ON ISSN.PROD_ID = PROD_PROFILE.PROD_ID
                                WHERE PROD_PROFILE.SIZE_TYPE  = :WK_PROD_SIZE_TYPE
                                AND PROD_PROFILE.COMPANY_ID = :WK_PO_COMPANY_ID
                                AND ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                                AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                GROUP BY PROD_PROFILE.SIZE_TYPE
                          INTO :WK_AVAILABLE_QTY;
                       END
                    END
                    ELSE
                    BEGIN
                       /* only required wh_id */
                       IF (WK_PO_COMPANY_ID = 'ALL') THEN
                       BEGIN
                          /* only required wh_id and  all company_id */
                          SELECT SUM( ISSN.CURRENT_QTY ) 
                                FROM PROD_PROFILE
                                JOIN ISSN ON ISSN.PROD_ID = PROD_PROFILE.PROD_ID
                                WHERE PROD_PROFILE.SIZE_TYPE  = :WK_PROD_SIZE_TYPE
                                AND PROD_PROFILE.COMPANY_ID = :WK_PO_COMPANY_ID
                                AND ISSN.WH_ID = :WK_PO_WH_ID
                                AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                GROUP BY PROD_PROFILE.SIZE_TYPE
                          INTO :WK_AVAILABLE_QTY;
                       END
                       ELSE
                       BEGIN
                          /* only required wh_id and  required company_id */
                          SELECT SUM( ISSN.CURRENT_QTY ) 
                                FROM PROD_PROFILE
                                JOIN ISSN ON ISSN.PROD_ID = PROD_PROFILE.PROD_ID
                                WHERE PROD_PROFILE.SIZE_TYPE  = :WK_PROD_SIZE_TYPE
                                AND PROD_PROFILE.COMPANY_ID = :WK_PO_COMPANY_ID
                                AND ISSN.WH_ID = :WK_PO_WH_ID
                                AND ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                                AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                GROUP BY PROD_PROFILE.SIZE_TYPE
                          INTO :WK_AVAILABLE_QTY;
                       END
                    END
                 END
                 IF (WK_AVAILABLE_QTY IS NULL) THEN
                 BEGIN
                    WK_AVAILABLE_QTY = 0;
                 END
                 /* now must get qty allocated on order not picked */
                 WK_PICKED_QTY = 0;
                 WK_ORDER_QTY = 0;
                 IF (WK_PROD_SIZE_TYPE = '') THEN
                 BEGIN
                    /* use only this product */
                    SELECT SUM( PICK_ITEM.PICK_ORDER_QTY ), 
                           SUM( PICK_ITEM.PICKED_QTY ) 
                            FROM PICK_ITEM
                            WHERE PICK_ITEM.PROD_ID = :WK_WORK_PROD
                            AND ('AL' = PICK_ITEM.PICK_LINE_STATUS)
                            GROUP BY PICK_ITEM.PROD_ID
                         INTO :WK_ORDER_QTY, :WK_PICKED_QTY;
                 END
                 ELSE
                 BEGIN
                    /* use products in this size type */
                    SELECT SUM( PICK_ITEM.PICK_ORDER_QTY ), 
                           SUM( PICK_ITEM.PICKED_QTY ) 
                            FROM PROD_PROFILE
                            JOIN PICK_ITEM ON PICK_ITEM.PROD_ID = PROD_PROFILE.PROD_ID
                            WHERE PROD_PROFILE.SIZE_TYPE  = :WK_PROD_SIZE_TYPE
                            AND PROD_PROFILE.COMPANY_ID = :WK_PO_COMPANY_ID
                            AND ('AL' = PICK_ITEM.PICK_LINE_STATUS)
                            GROUP BY PROD_PROFILE.SIZE_TYPE
                         INTO :WK_ORDER_QTY, :WK_PICKED_QTY;
                 END
                 IF (WK_ORDER_QTY IS NULL) THEN
                 BEGIN
                    WK_ORDER_QTY = 0;
                 END
                 IF (WK_PICKED_QTY IS NULL) THEN
                 BEGIN
                    WK_PICKED_QTY = 0;
                 END
                 WK_ALLOC_ORDER_QTY = WK_ORDER_QTY - WK_PICKED_QTY;
                 WK_AVAILABLE_QTY = WK_AVAILABLE_QTY - WK_ALLOC_ORDER_QTY;
                 IF (WK_AVAILABLE_QTY < WK_WORK_TOPICK_QTY ) THEN
                 BEGIN
                    IF (LEN(WK_PROD_OK) < 53) THEN
                    BEGIN
                       WK_PROD_OK = WK_PROD_OK || ' ' || WK_WORK_PROD;
                    END
                    /* IF (WK_HELD_STATUS = 'HD') THEN */
                    /* IF ((WK_HELD_STATUS = 'HD') OR (WK_HELD_STATUS = 'CN')) THEN */
                    IF ((WK_HELD_STATUS = 'HD') OR (WK_HELD_STATUS = 'CN') OR (WK_HELD_STATUS = 'AS')) THEN
                    BEGIN
                       UPDATE PICK_ITEM 
                       SET PICK_LINE_STATUS = :WK_HELD_STATUS,
                       REASON = 'NOT ENOUGH STOCK'
                       WHERE PROD_ID = :WK_WORK_PROD
                       AND PICK_ORDER = :WK_ORDER
                       AND PICK_LINE_STATUS IN ('OP','UP');
                    END
                    ELSE
                    BEGIN
                       UPDATE PICK_ITEM 
                       SET REASON = 'NOT ENOUGH STOCK'
                       WHERE PROD_ID = :WK_WORK_PROD
                       AND PICK_ORDER = :WK_ORDER
                       AND PICK_LINE_STATUS IN ('OP','UP');
                    END
                 END
              END /* end of for */
              BEGIN
                 IF (WK_PROD_OK <> '') THEN
                 BEGIN
                    UPDATE PICK_ORDER SET PICK_PRIORITY = :WK_MOVE_PRIORITY 
                    WHERE PICK_ORDER = :WK_ORDER;
                 END
                 WK_FOUND = 0;
                 SELECT FIRST 1 1
                 FROM PICK_ITEM
                 WHERE PICK_ORDER = :WK_ORDER
                 AND PICK_LINE_STATUS IN ('OP','UP')
                 AND (PROD_ID IS NOT NULL)
                 INTO :WK_FOUND;
                 IF (WK_FOUND = 1) THEN
                 BEGIN
                    /* ok we can allocate this */
                    UPDATE PICK_ITEM 
                       SET USER_ID = :WK_WHO_FOR, 
                           DEVICE_ID = NULL, 
                           PICK_LINE_STATUS = 'CN' 
                        WHERE PICK_ORDER = :WK_ORDER
                        AND PICK_LINE_STATUS IN ('OP','UP')
                        AND PICK_ORDER_QTY = 0
                        AND (PROD_ID IS NOT NULL);
                    UPDATE PICK_ITEM 
                       SET USER_ID = :WK_WHO_FOR, 
                           DEVICE_ID = :WK_DEVICE,
                           PICK_LINE_STATUS = 'AL', 
                           PICK_STARTED = 'NOW'
                        WHERE PICK_ORDER = :WK_ORDER
                        AND PICK_LINE_STATUS IN ('OP','UP')
                        AND (PROD_ID IS NOT NULL);
                    /*     PICK_STATUS = 'PG' */ 
                    UPDATE PICK_ORDER
                       SET PICK_STARTED = 'NOW'
                        WHERE PICK_ORDER = :WK_ORDER
                        AND PICK_STARTED IS NULL;
                 END
                 ELSE
                 BEGIN
                    /* no lines left to allocate */
/*           UPDATE PICK_ORDER SET PICK_PRIORITY = :WK_MOVE_PRIORITY,PICK_STATUS = 'HD'
             WHERE PICK_ORDER = :WK_ORDER; */
                 END
              END
           END /* end of product lines for order and OP or DA order status */
           IF ((WK_ORDER_STATUS = 'OP' OR WK_ORDER_STATUS = 'DA') AND (WK_PI_TYPE = 'I')) THEN
           BEGIN
              WK_WORK_PROD = '';
              WK_WORK_ORDER_QTY = 0;
              WK_WORK_PICKED_QTY = 0;
              FOR SELECT SSN_ID, 
                   PICK_ITEM.PICK_ORDER_QTY , 
                   PICK_ITEM.PICKED_QTY,
                   PICK_ITEM.PICK_LABEL_NO 
                  FROM PICK_ITEM
                  WHERE PICK_ORDER = :WK_ORDER
                  AND PICK_LINE_STATUS IN ('OP','UP')
                  AND (SSN_ID IS NOT NULL)
                  INTO :WK_WORK_PROD, :WK_WORK_ORDER_QTY, :WK_WORK_PICKED_QTY, :WK_WORK_LABEL
              DO
              BEGIN
                 IF (WK_WORK_ORDER_QTY IS NULL) THEN
                 BEGIN
                    WK_WORK_ORDER_QTY = 0;
                 END
                 IF (WK_WORK_PICKED_QTY IS NULL) THEN
                 BEGIN
                    WK_WORK_PICKED_QTY = 0;
                 END
                 /* order is already confirmed */
                 IF (WK_WORK_ORDER_QTY <= 0) THEN
                 BEGIN
                    UPDATE PICK_ITEM 
                       SET USER_ID = :WK_WHO_FOR, 
                           DEVICE_ID = NULL, 
                           PICK_LINE_STATUS = 'CN' 
                        WHERE PICK_LABEL_NO  = :WK_WORK_LABEL;
                 END
                 ELSE
                 BEGIN
                    UPDATE PICK_ITEM 
                       SET USER_ID = :WK_WHO_FOR, 
                           DEVICE_ID = :WK_DEVICE,
                           PICK_LINE_STATUS = 'AL', 
                           PICK_STARTED = 'NOW'
                        WHERE PICK_LABEL_NO  = :WK_WORK_LABEL;
                 END
                    UPDATE PICK_ORDER
                       SET PICK_STARTED = 'NOW'
                        WHERE PICK_ORDER = :WK_ORDER
                        AND PICK_STARTED IS NULL;
              END
           END
        END
        EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'T','Processed successfully');
        /* EXECUTE PROCEDURE TRAN_ARCHIVE; */

     END /* code K or  L */

     IF (NEW.TRN_CODE = 'M') THEN
     BEGIN
        /* allocate a product or issns of a product for a specific label 
           with no overide for PKAL I */
        WK_USER = NEW.PERSON_ID;
        /* WK_WHO_FOR = NEW.REFERENCE; */
        WK_RECORD = NEW.RECORD_ID;
        WK_DEVICE = NEW.WH_ID;
        WK_PI_LABEL = NEW.OBJECT;
        WK_DATE = NEW.TRN_DATE;
/*
        EXECUTE PROCEDURE GET_REFERENCE_FIELD NEW.REFERENCE, 1  RETURNING_VALUES :WK_WHO_FOR ; 
        EXECUTE PROCEDURE GET_REFERENCE_FIELD NEW.REFERENCE, 2  RETURNING_VALUES :WK_WORK_PROD ; 
*/
        /* cannot trust the product or who for - use the pick_label and sys_equip for this */
        WK_CN_PRIORITY = 0;
        WK_BUFFER = '';
        SELECT CURRENT_PERSON, LAST_PERSON
        FROM SYS_EQUIP
        WHERE DEVICE_ID = :WK_DEVICE
        INTO :WK_WHO_FOR, :WK_WHO_FOR2;
        IF (WK_WHO_FOR IS NULL) THEN
        BEGIN
           WK_WHO_FOR = WK_WHO_FOR2;
        END
        SELECT DEFAULT_PICK_PRIORITY, PICK_IMPORT_SSN_STATUS , WARN_PICK_PRIORITY
        FROM CONTROL 
        INTO :WK_CN_PRIORITY, :WK_IMPORTSTATUS, :WK_MOVE_PRIORITY;
/*
=====================================================================
 for all unallocated orders 
 with the product from pick_item
 then allocate to device 
====================================================================
*/
        WK_DO_BY_LABEL = 'T';
        SELECT DESCRIPTION
        FROM OPTIONS
        WHERE GROUP_CODE = 'PKAL'
        AND CODE = 'M|BYLABEL'
        INTO :WK_DO_BY_LABEL;
        IF (WK_DO_BY_LABEL IS NULL) THEN
        BEGIN
           WK_DO_BY_LABEL = 'T';
        END
        IF (WK_DO_BY_LABEL = 'T') THEN
        BEGIN
           WK_ORDER  = '';
           WK_WORK_ORDER_QTY = 0;
           WK_WORK_PICKED_QTY = 0;
           FOR SELECT PICK_ITEM.PICK_ORDER,
               PICK_ITEM.PROD_ID,
               PICK_ITEM.PICK_ORDER_QTY , 
               PICK_ITEM.PICKED_QTY 
               FROM PICK_ITEM
               JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PICK_ITEM.PICK_ORDER
               WHERE PICK_ITEM.PICK_LABEL_NO = :WK_PI_LABEL
               AND PICK_ITEM.PICK_LINE_STATUS IN ('OP','UP')
               AND PICK_ORDER.PICK_STATUS IN ('OP','DA')
               INTO :WK_ORDER, :WK_WORK_PROD, :WK_WORK_ORDER_QTY, :WK_WORK_PICKED_QTY
           DO
           BEGIN
              IF (WK_WORK_ORDER_QTY IS NULL) THEN
              BEGIN
                 WK_WORK_ORDER_QTY = 0;
              END
              IF (WK_WORK_PICKED_QTY IS NULL) THEN
              BEGIN
                 WK_WORK_PICKED_QTY = 0;
              END
              IF (WK_WORK_PROD IS NOT NULL) THEN
              BEGIN
                 WK_WORK_PROD = ALLTRIM(WK_WORK_PROD);
                 IF (STRLEN(WK_WORK_PROD) = 0) THEN
                 BEGIN
                    WK_WORK_PROD = NULL;
                 END
              END
              SELECT WH_ID, COMPANY_ID
              FROM PICK_ORDER
              WHERE PICK_ORDER.PICK_ORDER = :WK_ORDER
              INTO :WK_PO_WH_ID, :WK_PO_COMPANY_ID;
              IF (WK_PO_WH_ID IS NULL) THEN
              BEGIN
                 WK_PO_WH_ID = 'ALL';
              END
              IF (WK_PO_COMPANY_ID IS NULL) THEN
              BEGIN
                 WK_PO_COMPANY_ID = 'ALL';
              END
              WK_HELD_STATUS = '';
              SELECT OPTIONS.DESCRIPTION, PICK_ORDER.PICK_STATUS
              FROM PICK_ORDER
              LEFT OUTER JOIN OPTIONS ON OPTIONS.GROUP_CODE = 'CMPPKHELD' AND OPTIONS.CODE = (PICK_ORDER.COMPANY_ID || '|' || PICK_ORDER.P_COUNTRY)
              WHERE PICK_ORDER.PICK_ORDER = :WK_ORDER
              INTO :WK_HELD_STATUS, :WK_ORDER_STATUS;
              IF (WK_HELD_STATUS IS NULL) THEN
              BEGIN
                 SELECT OPTIONS.DESCRIPTION
                 FROM PICK_ORDER
                 JOIN OPTIONS ON OPTIONS.GROUP_CODE = 'CMPPKHELD' AND OPTIONS.CODE = PICK_ORDER.COMPANY_ID 
                 WHERE PICK_ORDER.PICK_ORDER = :WK_ORDER
                 INTO :WK_HELD_STATUS;
              END
              IF (WK_HELD_STATUS IS NULL) THEN
              BEGIN
                 WK_HELD_STATUS = 'HD';
              END
              IF (WK_ORDER_STATUS IS NULL) THEN
              BEGIN
                 WK_ORDER_STATUS = 'UC';
              END
              WK_PROD_OK = '';
              IF (WK_ORDER_STATUS = 'OP' OR WK_ORDER_STATUS = 'DA') THEN
              BEGIN
                 BEGIN
                    WK_WORK_TOPICK_QTY = WK_WORK_ORDER_QTY - WK_WORK_PICKED_QTY;
                    WK_AVAILABLE_QTY = 0;
                    IF (WK_WORK_PROD IS NOT NULL) THEN
                    BEGIN
                       /* get available qty */
                       IF (WK_PO_WH_ID = 'ALL') THEN
                       BEGIN
                          /* allow all wh_id */
                          IF (WK_PO_COMPANY_ID = 'ALL') THEN
                          BEGIN
                             /* allow all wh_id and all company_id */
                             SELECT SUM( ISSN.CURRENT_QTY ) 
                                   FROM ISSN
                                   WHERE ISSN.PROD_ID = :WK_WORK_PROD
                                   AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                   GROUP BY ISSN.PROD_ID
                             INTO :WK_AVAILABLE_QTY;
                          END
                          ELSE
                          BEGIN
                             /* allow all wh_id and required company_id */
                             SELECT SUM( ISSN.CURRENT_QTY ) 
                                   FROM ISSN
                                   WHERE ISSN.PROD_ID = :WK_WORK_PROD
                                   AND ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                                   AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                   GROUP BY ISSN.PROD_ID
                             INTO :WK_AVAILABLE_QTY;
                          END
                       END
                       ELSE
                       BEGIN
                          /* only required wh_id */
                          IF (WK_PO_COMPANY_ID = 'ALL') THEN
                          BEGIN
                             /* only required wh_id and  all company_id */
                             SELECT SUM( ISSN.CURRENT_QTY ) 
                                   FROM ISSN
                                   WHERE ISSN.PROD_ID = :WK_WORK_PROD
                                   AND ISSN.WH_ID = :WK_PO_WH_ID
                                   AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                   GROUP BY ISSN.PROD_ID
                             INTO :WK_AVAILABLE_QTY;
                          END
                          ELSE
                          BEGIN
                             /* only required wh_id and  required company_id */
                             SELECT SUM( ISSN.CURRENT_QTY ) 
                                   FROM ISSN
                                   WHERE ISSN.PROD_ID = :WK_WORK_PROD
                                   AND ISSN.WH_ID = :WK_PO_WH_ID
                                   AND ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                                   AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                   GROUP BY ISSN.PROD_ID
                             INTO :WK_AVAILABLE_QTY;
                          END
                       END
                    END
                    IF (WK_AVAILABLE_QTY IS NULL) THEN
                    BEGIN
                       WK_AVAILABLE_QTY = 0;
                    END
                    /* now must get qty allocated on order not picked */
                    WK_PICKED_QTY = 0;
                    WK_ORDER_QTY = 0;
                    IF (WK_WORK_PROD IS NOT NULL) THEN
                    BEGIN
                       SELECT SUM( PICK_ITEM.PICK_ORDER_QTY ), 
                              SUM( PICK_ITEM.PICKED_QTY ) 
                              FROM PICK_ITEM
                              LEFT OUTER JOIN ISSN ON ISSN.SSN_ID = PICK_ITEM.SSN_ID
                              WHERE (PICK_ITEM.PROD_ID = :WK_WORK_PROD
                              OR  ISSN.PROD_ID = :WK_WORK_PROD)
                              AND ('AL' = PICK_ITEM.PICK_LINE_STATUS)
                            INTO :WK_ORDER_QTY, :WK_PICKED_QTY;
                    END
                    IF (WK_ORDER_QTY IS NULL) THEN
                    BEGIN
                       WK_ORDER_QTY = 0;
                    END
                    IF (WK_PICKED_QTY IS NULL) THEN
                    BEGIN
                       WK_PICKED_QTY = 0;
                    END
                    WK_ALLOC_ORDER_QTY = WK_ORDER_QTY - WK_PICKED_QTY;
                    WK_AVAILABLE_QTY = WK_AVAILABLE_QTY - WK_ALLOC_ORDER_QTY;
                    IF (WK_WORK_PROD IS NULL) THEN
                    BEGIN
                       /* for an ssn decision already made in the confirm */
                       WK_AVAILABLE_QTY = WK_WORK_TOPICK_QTY;
                    END
                    IF (WK_AVAILABLE_QTY < WK_WORK_TOPICK_QTY ) THEN
                    BEGIN
                       IF (LEN(WK_PROD_OK) < 53) THEN
                       BEGIN
                          WK_PROD_OK = WK_PROD_OK || ' ' || WK_WORK_PROD;
                       END
                       /* IF (WK_HELD_STATUS = 'HD') THEN */
                       /* IF ((WK_HELD_STATUS = 'HD') OR (WK_HELD_STATUS = 'CN')) THEN */
                       IF ((WK_HELD_STATUS = 'HD') OR (WK_HELD_STATUS = 'CN') OR (WK_HELD_STATUS = 'AS')) THEN
                       BEGIN
                          UPDATE PICK_ITEM 
                          SET PICK_LINE_STATUS = :WK_HELD_STATUS,
                          REASON = 'NOT ENOUGH STOCK'
                          WHERE PICK_LABEL_NO = :WK_PI_LABEL
                             AND PICK_LINE_STATUS IN ('OP','UP');
                       END
                       ELSE
                       BEGIN
                          UPDATE PICK_ITEM 
                          SET REASON = 'NOT ENOUGH STOCK'
                          WHERE PICK_LABEL_NO = :WK_PI_LABEL
                             AND PICK_LINE_STATUS IN ('OP','UP');
                       END
                    END
                 END /* if - was end of for */
                 BEGIN
                    IF (WK_PROD_OK <> '') THEN
                    BEGIN
                       UPDATE PICK_ORDER SET PICK_PRIORITY = :WK_MOVE_PRIORITY 
                       WHERE PICK_ORDER = :WK_ORDER;
                    END
                    WK_FOUND = 0;
                    SELECT FIRST 1 1
                    FROM PICK_ITEM
                    WHERE PICK_ITEM.PICK_LABEL_NO = :WK_PI_LABEL
                    AND PICK_ITEM.PICK_LINE_STATUS IN ('OP','UP')
                    INTO :WK_FOUND;
                    IF (WK_FOUND = 1) THEN
                    BEGIN
                       /* ok we can allocate this */
                       UPDATE PICK_ITEM 
                          SET USER_ID = :WK_WHO_FOR, 
                              DEVICE_ID = NULL, 
                              PICK_LINE_STATUS = 'CN' 
                           WHERE PICK_ORDER = :WK_ORDER
                           AND PICK_LINE_STATUS IN ('OP','UP')
                           AND PICK_ORDER_QTY = 0;
                       UPDATE PICK_ITEM 
                          SET USER_ID = :WK_WHO_FOR, 
                              DEVICE_ID = :WK_DEVICE,
                              PICK_LINE_STATUS = 'AL', 
                              PICK_STARTED = 'NOW'
                           WHERE PICK_LABEL_NO = :WK_PI_LABEL
                           AND PICK_LINE_STATUS IN ('OP','UP');
                       UPDATE PICK_ORDER
                          SET PICK_STARTED = 'NOW'
                           WHERE PICK_ORDER = :WK_ORDER
                           AND PICK_STARTED IS NULL;
                    END
                    ELSE
                    BEGIN
                       /* no lines left to allocate */
   /*           UPDATE PICK_ORDER SET PICK_PRIORITY = :WK_MOVE_PRIORITY,PICK_STATUS = 'HD'
                WHERE PICK_ORDER = :WK_ORDER; */
                    END
                 END
              END
           END /* end for */
        END /* end if do label only  */
        ELSE
        BEGIN
           /* do by order for this label no */
           WK_ORDER  = '';
           WK_WORK_ORDER_QTY = 0;
           WK_WORK_PICKED_QTY = 0;
           SELECT PICK_ITEM.PICK_ORDER
               FROM PICK_ITEM
               JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PICK_ITEM.PICK_ORDER
               WHERE PICK_ITEM.PICK_LABEL_NO = :WK_PI_LABEL
               AND PICK_ITEM.PICK_LINE_STATUS IN ('OP','UP')
               AND PICK_ORDER.PICK_STATUS IN ('OP','DA')
               INTO :WK_ORDER ;
            IF (WK_ORDER IS NULL) THEN
            BEGIN
               WK_ORDER = '';
            END
           /* now do pkal for this */
           EXECUTE PROCEDURE ADD_TRAN(
                    :WK_DEVICE,
                    'T|      ',
                    :WK_ORDER,
                    'PKAL',
                    'I',
                    :WK_DATE,
                    :WK_WHO_FOR,
                    0, /* qty */
                    'F',
                    '',
                    'MASTER',
                    0,
                    '          ', /* sub locn id */
                    NEW.INPUT_SOURCE,
                    :WK_USER,
                    NEW.DEVICE_ID);
        END
        EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'T','Processed successfully');
        /* EXECUTE PROCEDURE TRAN_ARCHIVE; */
     END /* code M */

  END /* PKAL */
 END /* autorun */
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
