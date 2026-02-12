COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;
 
CREATE OR ALTER TRIGGER RUN_TRANSACTION_PKAL2 FOR TRANSACTIONS 
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
DECLARE VARIABLE WK_PI_PROD_ID VARCHAR(30);
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
DECLARE VARIABLE WK_PO_WH_ID CHAR(2);
DECLARE VARIABLE WK_PO_COMPANY_ID VARCHAR(20);
DECLARE VARIABLE WK_PO_ALTERNATE_COMPANYS COMPANY_GROUP;
DECLARE VARIABLE WK_PO_SALE_CHANNEL VARCHAR(40);
DECLARE VARIABLE WK_PO_PARTIAL CHAR(1);
DECLARE VARIABLE WK_PARTIAL_PROD_OK VARCHAR(1);
DECLARE VARIABLE WK_DO_SALE_CHANNEL CHAR(1);
DECLARE VARIABLE WK_PR_RECORD_ID  INTEGER;
DECLARE VARIABLE WK_PR_AVAILABLE_QTY  INTEGER;
DECLARE VARIABLE WK_PSUR_QTY  INTEGER;
DECLARE VARIABLE WK_PSUR_REFERENCE VARCHAR(1024);
BEGIN
 WK_AUTORUN = GEN_ID(AUTOEXEC_TRANSACTIONS,0); 
 IF (WK_AUTORUN = 1) THEN
 BEGIN
  IF (NEW.TRN_TYPE = 'PKAL') THEN
  BEGIN
     IF (NEW.TRN_CODE = 'H') THEN
     BEGIN
        WK_USER = NEW.PERSON_ID;
        WK_WHO_FOR = NEW.REFERENCE;
        WK_RECORD = NEW.RECORD_ID;
        WK_CN_PRIORITY = 0;
        WK_BUFFER = '';
        SELECT DEFAULT_PICK_PRIORITY, PICK_IMPORT_SSN_STATUS , WARN_PICK_PRIORITY
        FROM CONTROL 
        INTO :WK_CN_PRIORITY, :WK_IMPORTSTATUS, :WK_MOVE_PRIORITY;
/*
=====================================================================
 for all unallocated orders of today

 product from pick_item
 device from the zone 
        if the product is specified in a location within a zone
        otherwise use the zone for the company of the order
 then allocate to device 
====================================================================
*/
        WK_ORDER = '';
        FOR SELECT PI.PICK_ORDER 
            FROM PICK_ITEM PI
            JOIN PICK_ORDER PO ON PO.PICK_ORDER = PI.PICK_ORDER
            WHERE 
            PI.PICK_LINE_STATUS IN ('OP','UP')
            AND PO.PICK_STATUS IN ('OP','DA')
            GROUP BY PO.PICK_PRIORITY, PI.PICK_ORDER
            INTO :WK_ORDER 
        DO
        BEGIN
           SELECT WH_ID, COMPANY_ID, ALTERNATE_COMPANYS
           FROM PICK_ORDER
           WHERE PICK_ORDER.PICK_ORDER = :WK_ORDER
           INTO :WK_PO_WH_ID, :WK_PO_COMPANY_ID, :WK_PO_ALTERNATE_COMPANYS;
           IF (WK_PO_WH_ID IS NULL) THEN
           BEGIN
              WK_PO_WH_ID = 'ALL';
           END
           IF (WK_PO_COMPANY_ID IS NULL) THEN
           BEGIN
              WK_PO_COMPANY_ID = 'ALL';
           END
           IF (WK_PO_ALTERNATE_COMPANYS = '') THEN
           BEGIN
              WK_PO_ALTERNATE_COMPANYS  = NULL;
           END
           IF (WK_PO_ALTERNATE_COMPANYS IS NULL) THEN
           BEGIN
              WK_PO_ALTERNATE_COMPANYS  = :WK_PO_COMPANY_ID;
           END
           WK_HELD_STATUS = '';
           SELECT OPTIONS.DESCRIPTION
           FROM PICK_ORDER
           JOIN OPTIONS ON OPTIONS.GROUP_CODE = 'CMPPKHELD' AND OPTIONS.CODE = (PICK_ORDER.COMPANY_ID || '|' || PICK_ORDER.P_COUNTRY)
           WHERE PICK_ORDER.PICK_ORDER = :WK_ORDER
           INTO :WK_HELD_STATUS;
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
           WK_PROD_OK = '';
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
                 WK_AVAILABLE_QTY = 0;
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
                             AND (ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                             OR   (V4POS(:WK_PO_ALTERNATE_COMPANYS,ISSN.COMPANY_ID,0,1) > -1))
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
                             AND (ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                             OR   (V4POS(:WK_PO_ALTERNATE_COMPANYS,ISSN.COMPANY_ID,0,1) > -1))
                             AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                             GROUP BY ISSN.PROD_ID
                       INTO :WK_AVAILABLE_QTY;
                    END
                 END
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
                           DEVICE_ID = (SELECT ZONE.DEFAULT_DEVICE_ID
                              FROM LOCATION
                              JOIN ZONE ON ZONE.CODE = LOCATION.ZONE_C
                              WHERE LOCATION.WH_ID = PICK_ITEM.WH_ID
                              AND LOCATION.LOCN_ID = PICK_ITEM.PICK_LOCATION), 
                           PICK_LINE_STATUS = 'AL', 
                           PICK_STARTED = 'NOW'
                        WHERE PICK_ORDER = :WK_ORDER
                        AND PICK_LINE_STATUS IN ('OP','UP');
                    /*     PICK_STATUS = 'PG' */ 
                    UPDATE PICK_ORDER
                       SET PICK_STARTED = 'NOW'
                        WHERE PICK_ORDER = :WK_ORDER
                        AND PICK_STARTED IS NULL;

                 END
                 ELSE
                 BEGIN
                    /* no lines left to allocate */
             /* UPDATE PICK_ORDER SET PICK_PRIORITY = :WK_MOVE_PRIORITY,PICK_STATUS = 'HD' 
             WHERE PICK_ORDER = :WK_ORDER; */
                 END
              END
           END
        END
        EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'T','Processed successfully');
        /* EXECUTE PROCEDURE TRAN_ARCHIVE; */

     END /* code H */

     IF (NEW.TRN_CODE = 'I') THEN
     BEGIN
        /* allocate an order */
        WK_USER = NEW.PERSON_ID;
        WK_WHO_FOR = NEW.REFERENCE;
        WK_RECORD = NEW.RECORD_ID;
        WK_DEVICE = NEW.WH_ID;
        WK_ORDER = NEW.OBJECT;
        WK_DATE = NEW.TRN_DATE;
        WK_CN_PRIORITY = 0;
        WK_BUFFER = '';
        WK_DO_SALE_CHANNEL = 'F';
        SELECT DEFAULT_PICK_PRIORITY, PICK_IMPORT_SSN_STATUS , WARN_PICK_PRIORITY, USE_SALE_CHANNEL
        FROM CONTROL 
        INTO :WK_CN_PRIORITY, :WK_IMPORTSTATUS, :WK_MOVE_PRIORITY, :WK_DO_SALE_CHANNEL;
/*
=====================================================================
 for all unallocated orders of today
 product from pick_item
 then allocate to device 
====================================================================
  need to add orders for produtcs with a size class (size_type)
  then include any product for that size class - rather than putting to 'HD' - no stock
====================================================================
*/
        WK_ORDER = NEW.OBJECT;
        BEGIN
           WK_PO_PARTIAL = 'F';
           SELECT WH_ID, COMPANY_ID, PARTIAL_PICK_ALLOWED, OTHER2, ALTERNATE_COMPANYS
           FROM PICK_ORDER
           WHERE PICK_ORDER.PICK_ORDER = :WK_ORDER
           INTO :WK_PO_WH_ID, :WK_PO_COMPANY_ID, :WK_PO_PARTIAL, :WK_PO_SALE_CHANNEL, :WK_PO_ALTERNATE_COMPANYS;
           IF (WK_PO_WH_ID IS NULL) THEN
           BEGIN
              WK_PO_WH_ID = 'ALL';
           END
           IF (WK_PO_COMPANY_ID IS NULL) THEN
           BEGIN
              WK_PO_COMPANY_ID = 'ALL';
           END
           IF (WK_PO_PARTIAL IS NULL) THEN
           BEGIN
              WK_PO_PARTIAL = 'F';
           END
           IF (WK_PO_ALTERNATE_COMPANYS = '') THEN
           BEGIN
              WK_PO_ALTERNATE_COMPANYS  = NULL;
           END
           IF (WK_PO_ALTERNATE_COMPANYS IS NULL) THEN
           BEGIN
              WK_PO_ALTERNATE_COMPANYS  = :WK_PO_COMPANY_ID;
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
              WK_PARTIAL_PROD_OK = '';
              WK_WORK_PROD = '';
              WK_WORK_ORDER_QTY = 0;
              WK_WORK_PICKED_QTY = 0;
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
                 WK_PROD_SIZE_TYPE = '';
                 SELECT SIZE_TYPE
                 FROM PROD_PROFILE
                 WHERE PROD_ID = :WK_WORK_PROD 
                 AND COMPANY_ID =  :WK_PO_COMPANY_ID
                 INTO :WK_PROD_SIZE_TYPE;
                 IF (WK_PROD_SIZE_TYPE IS NULL) THEN
                 BEGIN
                    WK_PROD_SIZE_TYPE = '';
                 END
                 WK_WORK_TOPICK_QTY = WK_WORK_ORDER_QTY - WK_WORK_PICKED_QTY;
                 WK_AVAILABLE_QTY = 0;
                 /* calc available qty */
                 /* must use prod_reservation */
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
                                AND (ISSN.COMPANY_ID = :WK_PO_COMPANY_ID 
                                OR  (V4POS(:WK_PO_ALTERNATE_COMPANYS,ISSN.COMPANY_ID,0,1) > -1))
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
                                AND (ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                                OR  (V4POS(:WK_PO_ALTERNATE_COMPANYS,ISSN.COMPANY_ID,0,1) > -1))
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
                                AND (ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                                OR  (V4POS(:WK_PO_ALTERNATE_COMPANYS,ISSN.COMPANY_ID,0,1) > -1))
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
                                AND (ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                                OR  (V4POS(:WK_PO_ALTERNATE_COMPANYS,ISSN.COMPANY_ID,0,1) > -1))
                                AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                                GROUP BY PROD_PROFILE.SIZE_TYPE
                          INTO :WK_AVAILABLE_QTY;
                       END
                    END
                 END
                 /* end of calc available qty */
                 IF (WK_AVAILABLE_QTY IS NULL) THEN
                 BEGIN
                    WK_AVAILABLE_QTY = 0;
                 END
/*
===============================================================================
               if use_sale_channels
               then
               begin
                    if product and sales channel exist and OP
                    then 
                    begin
                       the available qty is the qty available in the prod_reservation
                    end
                    else
                    begin
                       the available qty is wk_available_qty - 
                            sum(prod_reservations.available_qty OP for all channels for this product)
                    end
               end
===============================================================================
*/
                 IF (WK_DO_SALE_CHANNEL = 'T') THEN
                 BEGIN
                    /* ================================================================== */
                    /* have WK_ORDER WK_WORK_PROD WK_WORK_TOPICK_QTY  WK_PO_WH_ID WK_PO_COMPANY_ID */
                    WK_PR_RECORD_ID = NULL;
                    BEGIN
                       IF (WK_PO_SALE_CHANNEL = '') THEN
                       BEGIN
                          WK_PO_SALE_CHANNEL = NULL;
                       END
                       IF ((WK_WORK_TOPICK_QTY > 0) AND (WK_WORK_PROD IS NOT NULL) AND (WK_PO_SALE_CHANNEL IS NOT NULL)) THEN
                       BEGIN
                          WK_PR_RECORD_ID = NULL;
                          SELECT RECORD_ID, PR_AVAILABLE_QTY
                          FROM PROD_RESERVATION
                          WHERE PR_PROD_ID = :WK_WORK_PROD
                          AND   PR_SALE_CHANNEL_CODE = :WK_PO_SALE_CHANNEL
                          AND   PR_RESERVATION_STATUS = 'OP'
                          INTO :WK_PR_RECORD_ID, :WK_PR_AVAILABLE_QTY;
                          IF (WK_PR_RECORD_ID IS NOT NULL) THEN
                          BEGIN      
                             IF (WK_PR_AVAILABLE_QTY IS NULL) THEN
                             BEGIN
                                WK_PR_AVAILABLE_QTY = 0;
                             END
                             WK_AVAILABLE_QTY = WK_PR_AVAILABLE_QTY;
                          END
                       END
                    END 
                    IF (WK_PR_RECORD_ID IS NULL) THEN
                    BEGIN
                       SELECT SUM( PR_AVAILABLE_QTY)
                       FROM PROD_RESERVATION
                       WHERE PR_PROD_ID = :WK_WORK_PROD
                       AND   PR_RESERVATION_STATUS = 'OP'
                       INTO :WK_PR_AVAILABLE_QTY;
                       IF (WK_PR_AVAILABLE_QTY IS NULL) THEN
                       BEGIN
                          WK_PR_AVAILABLE_QTY = 0;
                       END
                       WK_AVAILABLE_QTY = WK_AVAILABLE_QTY - WK_PR_AVAILABLE_QTY;
                    END
                    /* ================================================================== */
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
                            JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PICK_ITEM.PICK_ORDER
                            WHERE PICK_ITEM.PROD_ID = :WK_WORK_PROD
                            AND PICK_ORDER.COMPANY_ID = :WK_PO_COMPANY_ID
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
                 /* if not a partial pick  must have all the pick
                    else  if have some of the qty then continue */
                 /* IF (WK_AVAILABLE_QTY < WK_WORK_TOPICK_QTY ) THEN */
                 IF (((WK_PO_PARTIAL = 'F' ) AND 
                      (WK_AVAILABLE_QTY < WK_WORK_TOPICK_QTY )) OR 
                     ((WK_PO_PARTIAL = 'T' ) AND 
                      (WK_AVAILABLE_QTY <= 0 ))) THEN
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
                 IF ((WK_PO_PARTIAL = 'T' ) AND 
                     (WK_AVAILABLE_QTY > 0 )) THEN
                 BEGIN
                    WK_PARTIAL_PROD_OK = 'T';
                 END
              END /* end of for */
              BEGIN
                 IF (WK_PARTIAL_PROD_OK = 'T') THEN
                 BEGIN
                    WK_PROD_OK = '';
                 END
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
                        WHERE PICK_ORDER = :WK_ORDER
                        AND PICK_LINE_STATUS IN ('OP','UP');
                    /*     PICK_STATUS = 'PG' */ 
                    UPDATE PICK_ORDER
                       SET PICK_STARTED = 'NOW'
                        WHERE PICK_ORDER = :WK_ORDER
                        AND PICK_STARTED IS NULL;
                     /* do psur for prod and sales channel to reduce available qty */
                     /* ================================================================== */
               
                    IF (WK_DO_SALE_CHANNEL = 'T') THEN
                    BEGIN
                       FOR   SELECT PI.PROD_ID ,SUM(PI.PICK_ORDER_QTY - COALESCE(PI.PICKED_QTY,0)), PO.OTHER2, PO.WH_ID
                             FROM PICK_ORDER PO 
                             JOIN PICK_ITEM PI ON PI.PICK_ORDER = PO.PICK_ORDER
                             WHERE PO.PICK_ORDER = :WK_ORDER 
                             AND PI.PICK_LINE_STATUS = 'AL'
                             AND PI.DEVICE_ID = :WK_DEVICE 
                             AND (PI.PROD_ID IS NOT NULL)
                             GROUP BY PI.PROD_ID, PO.OTHER2, PO.WH_ID
                             INTO :WK_PI_PROD_ID, :WK_PI_QTY, :WK_PO_SALE_CHANNEL, :WK_PO_WH_ID
                       DO
                       BEGIN
                          IF (WK_PI_QTY IS NULL) THEN
                          BEGIN
                             WK_PI_QTY = 0;
                          END
                          IF (WK_PI_PROD_ID = '') THEN
                          BEGIN
                             WK_PI_PROD_ID = NULL;
                          END
                          IF (WK_PO_SALE_CHANNEL = '') THEN
                          BEGIN
                             WK_PO_SALE_CHANNEL = NULL;
                          END
                          IF ((WK_PI_QTY > 0) AND (WK_PI_PROD_ID IS NOT NULL) AND (WK_PO_SALE_CHANNEL IS NOT NULL)) THEN
                          BEGIN
                             WK_PR_RECORD_ID = NULL;
                             SELECT RECORD_ID
                             FROM PROD_RESERVATION
                             WHERE PR_PROD_ID = :WK_PI_PROD_ID
                             AND   PR_SALE_CHANNEL_CODE = :WK_PO_SALE_CHANNEL
                             AND   PR_RESERVATION_STATUS = 'OP'
                             INTO :WK_PR_RECORD_ID;
                             IF (WK_PR_RECORD_ID IS NOT NULL) THEN
                             BEGIN
                                WK_PSUR_REFERENCE = WK_PO_SALE_CHANNEL || '|' || WK_PR_RECORD_ID || '|';
                                WK_PSUR_QTY = 0 - WK_PI_QTY;
                                EXECUTE PROCEDURE ADD_TRAN(
                                   :WK_PO_WH_ID,
                                   '',
                                   :WK_PI_PROD_ID,
                                   'PSUR',
                                   'A',
                                   :WK_DATE,
                                   :WK_PSUR_REFERENCE,
                                   :WK_PSUR_QTY,
                                   'F',
                                   '',
                                   'MASTER',
                                   0,
                                   '',
                                   'SSSSSSSSS',
                                   :WK_USER,
                                   :WK_DEVICE);
                                   /* have the adjustment qty passed in the qty field */
                                   /* have the product in the object field */
                                   /* have the channel code in the reference field */
                                   /* have the record_id passed in the reference field */
                             END
                          END
                       END
                    END
                    /* ================================================================== */
                 END
                 ELSE
                 BEGIN
                    /* no lines left to allocate */
/*           UPDATE PICK_ORDER SET PICK_PRIORITY = :WK_MOVE_PRIORITY,PICK_STATUS = 'HD'
             WHERE PICK_ORDER = :WK_ORDER; */
                 END
              END
           END
        END
        EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'T','Processed successfully');
        /* EXECUTE PROCEDURE TRAN_ARCHIVE; */

     END /* code I */
     IF (NEW.TRN_CODE = 'J') THEN
     BEGIN
        /* allocate a product or issns of a product */
        WK_USER = NEW.PERSON_ID;
        WK_WHO_FOR = NEW.REFERENCE;
        WK_RECORD = NEW.RECORD_ID;
        WK_DEVICE = NEW.WH_ID;
        WK_WORK_PROD = NEW.OBJECT;
        WK_CN_PRIORITY = 0;
        WK_BUFFER = '';
        SELECT DEFAULT_PICK_PRIORITY, PICK_IMPORT_SSN_STATUS , WARN_PICK_PRIORITY
        FROM CONTROL 
        INTO :WK_CN_PRIORITY, :WK_IMPORTSTATUS, :WK_MOVE_PRIORITY;
/*
=====================================================================
 for all unallocated orders 
 with the product from pick_item
 then allocate to device 
then do the issns for the product
====================================================================
*/
        WK_ORDER  = '';
        WK_WORK_ORDER_QTY = 0;
        WK_WORK_PICKED_QTY = 0;
        FOR SELECT PICK_ITEM.PICK_ORDER,
            SUM( PICK_ITEM.PICK_ORDER_QTY ), 
            SUM( PICK_ITEM.PICKED_QTY )
            FROM PICK_ITEM
            JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PICK_ITEM.PICK_ORDER
            LEFT OUTER JOIN ISSN ON ISSN.SSN_ID = PICK_ITEM.SSN_ID
            WHERE (PICK_ITEM.PROD_ID = :WK_WORK_PROD
            OR  ISSN.PROD_ID = :WK_WORK_PROD)
            AND PICK_ITEM.PICK_LINE_STATUS IN ('OP','UP')
            AND PICK_ORDER.PICK_STATUS IN ('OP','DA')
            GROUP BY PICK_ITEM.PICK_ORDER 
            INTO :WK_ORDER, :WK_WORK_ORDER_QTY, :WK_WORK_PICKED_QTY
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
           SELECT WH_ID, COMPANY_ID, ALTERNATE_COMPANYS
           FROM PICK_ORDER
           WHERE PICK_ORDER.PICK_ORDER = :WK_ORDER
           INTO :WK_PO_WH_ID, :WK_PO_COMPANY_ID, :WK_PO_ALTERNATE_COMPANYS;
           IF (WK_PO_WH_ID IS NULL) THEN
           BEGIN
              WK_PO_WH_ID = 'ALL';
           END
           IF (WK_PO_COMPANY_ID IS NULL) THEN
           BEGIN
              WK_PO_COMPANY_ID = 'ALL';
           END
           IF (WK_PO_ALTERNATE_COMPANYS = '') THEN
           BEGIN
              WK_PO_ALTERNATE_COMPANYS  = NULL;
           END
           IF (WK_PO_ALTERNATE_COMPANYS IS NULL) THEN
           BEGIN
              WK_PO_ALTERNATE_COMPANYS  = :WK_PO_COMPANY_ID;
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
                             AND (ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                             OR   (V4POS(:WK_PO_ALTERNATE_COMPANYS,ISSN.COMPANY_ID,0,1) > -1))
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
                             AND (ISSN.COMPANY_ID = :WK_PO_COMPANY_ID
                             OR   (V4POS(:WK_PO_ALTERNATE_COMPANYS,ISSN.COMPANY_ID,0,1) > -1))
                             AND (POS(:WK_IMPORTSTATUS,ISSN.ISSN_STATUS,0,1) > -1)
                             GROUP BY ISSN.PROD_ID
                       INTO :WK_AVAILABLE_QTY;
                    END
                 END
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
                        LEFT OUTER JOIN ISSN ON ISSN.SSN_ID = PICK_ITEM.SSN_ID
                        WHERE (PICK_ITEM.PROD_ID = :WK_WORK_PROD
                        OR  ISSN.PROD_ID = :WK_WORK_PROD)
                        AND ('AL' = PICK_ITEM.PICK_LINE_STATUS)
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
                       UPDATE PICK_ITEM 
                       SET PICK_LINE_STATUS = :WK_HELD_STATUS,
                       REASON = 'NOT ENOUGH STOCK'
                       WHERE PICK_ORDER = :WK_ORDER
                          AND PICK_LINE_STATUS IN ('OP','UP')
                          AND EXISTS ( SELECT ISSN.SSN_ID FROM ISSN WHERE ISSN.SSN_ID = PICK_ITEM.SSN_ID AND ISSN.PROD_ID = :WK_WORK_PROD ) ;
                    END
                    ELSE
                    BEGIN
                       UPDATE PICK_ITEM 
                       SET REASON = 'NOT ENOUGH STOCK'
                       WHERE PICK_ORDER = :WK_ORDER
                          AND PROD_ID = :WK_WORK_PROD
                          AND PICK_LINE_STATUS IN ('OP','UP');
                       UPDATE PICK_ITEM 
                       SET REASON = 'NOT ENOUGH STOCK'
                       WHERE PICK_ORDER = :WK_ORDER
                          AND PICK_LINE_STATUS IN ('OP','UP')
                          AND EXISTS ( SELECT ISSN.SSN_ID FROM ISSN WHERE ISSN.SSN_ID = PICK_ITEM.SSN_ID AND ISSN.PROD_ID = :WK_WORK_PROD ) ;
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
                 LEFT OUTER JOIN ISSN ON ISSN.SSN_ID = PICK_ITEM.SSN_ID
                 WHERE PICK_ITEM.PICK_ORDER = :WK_ORDER
                    AND (PICK_ITEM.PROD_ID = :WK_WORK_PROD
                    OR  ISSN.PROD_ID = :WK_WORK_PROD ) 
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
                        WHERE PICK_ORDER = :WK_ORDER
                        AND PROD_ID = :WK_WORK_PROD
                        AND PICK_LINE_STATUS IN ('OP','UP');
                    UPDATE PICK_ITEM 
                       SET USER_ID = :WK_WHO_FOR, 
                           DEVICE_ID = :WK_DEVICE,
                           PICK_LINE_STATUS = 'AL', 
                           PICK_STARTED = 'NOW'
                        WHERE PICK_ORDER = :WK_ORDER
                          AND EXISTS ( SELECT ISSN.SSN_ID FROM ISSN WHERE ISSN.SSN_ID = PICK_ITEM.SSN_ID AND ISSN.PROD_ID = :WK_WORK_PROD ) 
                        AND PICK_LINE_STATUS IN ('OP','UP');
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
           END
        END /* end for */
        EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'T','Processed successfully');
        /* EXECUTE PROCEDURE TRAN_ARCHIVE; */
     END /* code J */
  END /* PKAL */
 END /* autorun */
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
