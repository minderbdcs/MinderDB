COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;
 
DROP TRIGGER RUN_TRANSACTION_PKAL2 ^
COMMIT^

CREATE TRIGGER RUN_TRANSACTION_PKAL2 FOR TRANSACTIONS 
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
DECLARE VARIABLE WK_WHO_FOR VARCHAR(40);
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
        WK_CN_PRIORITY = 0;
        WK_BUFFER = '';
        SELECT DEFAULT_PICK_PRIORITY, PICK_IMPORT_SSN_STATUS , WARN_PICK_PRIORITY
        FROM CONTROL 
        INTO :WK_CN_PRIORITY, :WK_IMPORTSTATUS, :WK_MOVE_PRIORITY;
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
     IF (NEW.TRN_CODE = 'F') THEN
     BEGIN
        /* allocate a product or issns of a product for a specific label */
        WK_USER = NEW.PERSON_ID;
        /* WK_WHO_FOR = NEW.REFERENCE; */
        WK_RECORD = NEW.RECORD_ID;
        WK_DEVICE = NEW.WH_ID;
        WK_PI_LABEL = NEW.OBJECT;
        EXECUTE PROCEDURE GET_REFERENCE_FIELD NEW.REFERENCE, 1  RETURNING_VALUES :WK_WHO_FOR ; 
        EXECUTE PROCEDURE GET_REFERENCE_FIELD NEW.REFERENCE, 2  RETURNING_VALUES :WK_WORK_PROD ; 
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
        EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'T','Processed successfully');
        /* EXECUTE PROCEDURE TRAN_ARCHIVE; */
     END /* code F */
  END /* PKAL */
 END /* autorun */
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
