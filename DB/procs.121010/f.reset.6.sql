COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;
 
CREATE OR ALTER PROCEDURE RESET_ISSN_ORDERS (PROCESS_TYPE VARCHAR(40), IN_PROD_ID VARCHAR(30)) RETURNS(CNT INTEGER)
AS
                                                       
  DECLARE VARIABLE WK_FROM_STATUS VARCHAR(2);
  DECLARE VARIABLE WK_TO_STATUS VARCHAR(2);
  DECLARE VARIABLE WK_NEW_WH_ID VARCHAR(2);
  DECLARE VARIABLE WK_NEW_LOCN_ID VARCHAR(10);
  DECLARE VARIABLE WK_OLD_WH_ID VARCHAR(2);
  DECLARE VARIABLE WK_OLD_LOCN_ID VARCHAR(10);
  DECLARE VARIABLE WK_IS_OK CHAR(1);
  DECLARE VARIABLE WK_DOIT CHAR(1);
  DECLARE VARIABLE WK_SSN VARCHAR(20);
  DECLARE VARIABLE WK_SSN_QTY INTEGER;
  DECLARE VARIABLE WK_FOUND INTEGER;
  DECLARE VARIABLE WK_PID_FOUND INTEGER;
  DECLARE VARIABLE WK_LABEL_NO VARCHAR(7);
  DECLARE VARIABLE WK_USER VARCHAR(10);
  DECLARE VARIABLE WK_DETAIL_ID INTEGER;
  DECLARE VARIABLE WK_SSN_PICK_ORDER VARCHAR(20);
  DECLARE VARIABLE WK_MOVE_STAT CHAR(2);
  DECLARE VARIABLE WK_TO_MOVEABLE VARCHAR(2);
  DECLARE VARIABLE WK_TO_STORE_TYPE  VARCHAR(2);
  DECLARE VARIABLE WK_ALLOWED_STATUS VARCHAR(40);
  DECLARE VARIABLE WK_PI_LABEL_NO VARCHAR(10);
  DECLARE VARIABLE WK_PI_TOPICK_QTY INTEGER;
  DECLARE VARIABLE WK_IS_TOPICK_QTY INTEGER;
  DECLARE VARIABLE WK_PO_PARTIAL_PICK VARCHAR(2);
  DECLARE VARIABLE WK_DUMMY  INTEGER;
  DECLARE VARIABLE WK_IS_QTY INTEGER;
  DECLARE VARIABLE WK_IS_SSN_ID VARCHAR(20);
  DECLARE VARIABLE WK_IS_WH_ID VARCHAR(2);
  DECLARE VARIABLE WK_IS_LOCN_ID VARCHAR(10);
  DECLARE VARIABLE WK_IS_PROD_ID VARCHAR(30);
  DECLARE VARIABLE WK_IS_COMPANY_ID VARCHAR(20);
  DECLARE VARIABLE WK_IS_AVAILABLE_QTY INTEGER;
  DECLARE VARIABLE WK_IS_UNPICKED_QTY INTEGER;
  DECLARE VARIABLE WK_PD_PROD_ID VARCHAR(30);
  DECLARE VARIABLE WK_PD_AVAILABLE_QTY INTEGER;
  DECLARE VARIABLE WK_PR_RECORD_ID     INTEGER;
  DECLARE VARIABLE WK_PR_RESERVED_QTY  INTEGER;
  DECLARE VARIABLE WK_PR_NET_RESERVED_QTY  INTEGER;
  DECLARE VARIABLE WK_THIS_QTY  INTEGER;
  DECLARE VARIABLE WK_EFFECTIVE_QTY  INTEGER;
  DECLARE VARIABLE WK_PROD_LIKE VARCHAR(30);
     
BEGIN
   /* open al pick item lines */   
         
   WK_IS_SSN_ID = NULL; 
   WK_IS_WH_ID = NULL; 
   WK_IS_LOCN_ID = NULL; 
   WK_IS_PROD_ID = NULL; 
   WK_IS_QTY = NULL;
   WK_IS_AVAILABLE_QTY = NULL;
   WK_IS_UNPICKED_QTY = NULL;
   WK_IS_COMPANY_ID = NULL;
   CNT = 0;
   IF (PROCESS_TYPE = 'OP TO AS OVER PICK') THEN
   BEGIN
   /* op to al - over ordered pick item lines */   
      WK_IS_WH_ID = 'RZ';
      WK_IS_COMPANY_ID = 'PINPOINT';
      /* FROM PRODUCT_COMPANY_WH_STOCK_STATUS('%','PINPOINT','RZ','Admin') AS P1  */
      FOR SELECT P1.PROD_ID,P1.AVAILABLE_QTY, P1.UNPICKED_ORDER_QTY
      FROM PRODUCT_CMP_WH_STOCK_STATUS_V('%','PINPOINT','RZ','Admin','|PROD_ID|AVAILABLE_QTY|UNPICKED_ORDER_QTY|') AS P1  
      WHERE P1.AVAILABLE_QTY < P1.UNPICKED_ORDER_QTY
      INTO :WK_IS_PROD_ID, :WK_IS_AVAILABLE_QTY, :WK_IS_UNPICKED_QTY
      DO
      BEGIN
         /* want to only update the 1st qty of pick items that match */
         WK_IS_TOPICK_QTY = WK_IS_AVAILABLE_QTY;
         FOR SELECT PICK_ITEM.PICK_LABEL_NO, (COALESCE(PICK_ITEM.PICK_ORDER_QTY, 0) - COALESCE(PICK_ITEM.PICKED_QTY,0)) AS  TOPICK_QTY, PICK_ORDER.PARTIAL_PICK_ALLOWED
         FROM  PICK_ITEM
         JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PICK_ITEM.PICK_ORDER
         WHERE PICK_ITEM.PROD_ID = :WK_IS_PROD_ID 
         AND   PICK_ITEM.PICK_LINE_STATUS = 'OP'
         AND PICK_ORDER.WH_ID = :WK_IS_WH_ID
         AND PICK_ORDER.COMPANY_ID = :WK_IS_COMPANY_ID
         ORDER BY  PICK_ORDER.PICK_PRIORITY, PICK_ORDER.PICK_DUE_DATE 
         INTO :WK_PI_LABEL_NO, :WK_PI_TOPICK_QTY, :WK_PO_PARTIAL_PICK
         DO
         BEGIN
            IF (WK_IS_TOPICK_QTY > 0 AND WK_PI_TOPICK_QTY > 0  ) THEN
            BEGIN
               IF (WK_PO_PARTIAL_PICK = 'T' OR WK_PI_TOPICK_QTY <= WK_IS_TOPICK_QTY) THEN
               BEGIN
   /*
                  UPDATE PICK_ITEM
                  SET PICK_LINE_STATUS = 'OP'
                  WHERE PICK_ITEM.PICK_LABEL_NO = :WK_PI_LABEL_NO ;
                  CNT = CNT + 1;
   */
                  WK_IS_TOPICK_QTY = WK_IS_TOPICK_QTY - WK_PI_TOPICK_QTY;
               END
            END
            ELSE
            BEGIN
               IF (WK_IS_TOPICK_QTY <= 0) THEN
               BEGIN
                  UPDATE PICK_ITEM
                  SET PICK_LINE_STATUS = 'AS'
                  WHERE PICK_ITEM.PICK_LABEL_NO = :WK_PI_LABEL_NO ;
                  CNT = CNT + 1;
               END
            END
         END
      END
   END
   IF (PROCESS_TYPE = 'AS TO OP HAVE STOCK') THEN
   BEGIN
   /* al to op - have some stock pick item lines */   
      WK_IS_WH_ID = 'RZ';
      WK_IS_COMPANY_ID = 'PINPOINT';

      /* FROM PRODUCT_COMPANY_WH_STOCK_STATUS('%','PINPOINT','RZ','Admin') AS P1  */
      FOR SELECT P2.PICK_LABEL_NO
      FROM PRODUCT_CMP_WH_STOCK_STATUS_V('%','PINPOINT','RZ','Admin','|PROD_ID|AVAILABLE_QTY|UNPICKED_ORDER_QTY|') AS P1  
      JOIN PICK_ITEM P2 ON P2.PROD_ID = P1.PROD_ID AND P2.PICK_LINE_STATUS = 'AS' AND COALESCE(P2.PICK_ORDER_QTY,0) > COALESCE(P2.PICKED_QTY,0) 
      WHERE P1.AVAILABLE_QTY > P1.UNPICKED_ORDER_QTY AND P1.AVAILABLE_QTY > 0
      INTO :WK_PI_LABEL_NO 
      DO
      BEGIN
         UPDATE PICK_ITEM
         SET PICK_LINE_STATUS = 'OP'
         WHERE PICK_ITEM.PICK_LABEL_NO = :WK_PI_LABEL_NO ;
         CNT = CNT + 1;
      END
   END
   IF (PROCESS_TYPE = 'OP TO AS NO STOCK') THEN
   BEGIN
   /* al to op - have some stock pick item lines */   
      WK_IS_WH_ID = 'RZ';
      WK_IS_COMPANY_ID = 'PINPOINT';

      /* FROM PRODUCT_COMPANY_WH_STOCK_STATUS('%','PINPOINT','RZ','Admin') AS P1  */
      FOR SELECT P2.PICK_LABEL_NO
      FROM PRODUCT_CMP_WH_STOCK_STATUS_V('%','PINPOINT','RZ','Admin','|PROD_ID|AVAILABLE_QTY|') AS P1  
      JOIN PICK_ITEM P2 ON P2.PROD_ID = P1.PROD_ID AND P2.PICK_LINE_STATUS = 'OP' AND COALESCE(P2.PICK_ORDER_QTY,0) > COALESCE(P2.PICKED_QTY,0) 
      WHERE P1.AVAILABLE_QTY = 0
      INTO :WK_PI_LABEL_NO 
      DO
      BEGIN
         UPDATE PICK_ITEM
         SET PICK_LINE_STATUS = 'AS'
         WHERE PICK_ITEM.PICK_LABEL_NO = :WK_PI_LABEL_NO ;
         CNT = CNT + 1;
      END
   END
   IF (PROCESS_TYPE = 'RECALC CHANNEL') THEN
   BEGIN
   /* using current stock levels assign to sale changes orders by priority */   
      WK_IS_WH_ID = 'RZ';
      WK_IS_COMPANY_ID = 'PINPOINT';

      IF (IN_PROD_ID IS NULL) THEN
      BEGIN
         WK_PROD_LIKE = '%';
      END
      ELSE
      BEGIN
         IF (IN_PROD_ID = '') THEN
         BEGIN
            WK_PROD_LIKE = '%';
         END
         IF (IN_PROD_ID > '') THEN
         BEGIN
            WK_PROD_LIKE = IN_PROD_ID;
         END
      END
      /*
      FOR SELECT P1.PROD_ID, P1.AVAILABLE_QTY
      FROM PRODUCT_CMP_WH_STOCK_STATUS_V('%','PINPOINT','RZ','Admin','|PROD_ID|AVAILABLE_QTY|') AS P1  
      */
      /*
      FOR SELECT P1.PROD_ID, P1.AVAILABLE_QTY
      FROM PRODUCT_CMP_WH_STOCK_STATUS_V(:WK_PROD_LIKE,'PINPOINT','RZ','Admin','|PROD_ID|AVAILABLE_QTY|') AS P1  
      WHERE P1.AVAILABLE_QTY = 0
      INTO :WK_PD_PROD_ID, :WK_PD_AVAILABLE_QTY
      */
      FOR SELECT P1.PROD_ID, P1.AVAILABLE_QTY
      FROM (SELECT ISSN.PROD_ID, SUM(ISSN.CURRENT_QTY) AS AVAILABLE_QTY
            FROM ISSN 
            JOIN CONTROL ON CONTROL.RECORD_ID = 1
            WHERE ISSN.WH_ID = 'RZ'
            AND ISSN.PROD_ID LIKE :WK_PROD_LIKE
            AND ISSN.COMPANY_ID = 'PINPOINT'
            AND (POS(CONTROL.PICK_IMPORT_SSN_STATUS,ISSN.ISSN_STATUS,0,1) > -1)
            GROUP BY ISSN.PROD_ID) AS P1
      INTO :WK_PD_PROD_ID, :WK_PD_AVAILABLE_QTY
      DO
      BEGIN
         IF (WK_PD_AVAILABLE_QTY IS NULL OR WK_PD_AVAILABLE_QTY = 0) THEN
         BEGIN
            UPDATE PROD_RESERVATION
            SET PR_LAST_AVAILABLE_QTY = PR_AVAILABLE_QTY ,
                PR_AVAILABLE_QTY = 0 
            WHERE PR_PROD_ID = :WK_PD_PROD_ID ;
         END
         ELSE
         BEGIN
            WK_EFFECTIVE_QTY = WK_PD_AVAILABLE_QTY;
            /* get the wanted qty */
            /*
            WK_PR_NET_RESERVED_QTY = 0;
            SELECT SUM( PR_RESERVED_QTY)
            FROM PROD_RESERVATION
            WHERE PR_PROD_ID = :WK_PD_PROD_ID
            AND PR_RESERVATION_STATUS = 'OP'
            AND WH_ID = 'RZ'
            AND COMPANY_ID = 'PINPOINT'
            INTO :WK_PR_NET_RESERVED_QTY;
            IF (WK_PR_NET_RESERVED_QTY IS NULL) THEN
            BEGIN
               WK_PR_NET_RESERVED_QTY = 0;
            END
            */
            FOR SELECT RECORD_ID, PR_RESERVED_QTY
            FROM PROD_RESERVATION
            WHERE PR_PROD_ID = :WK_PD_PROD_ID
            AND PR_RESERVATION_STATUS = 'OP'
            AND WH_ID = 'RZ'
            AND COMPANY_ID = 'PINPOINT'
            ORDER BY PR_RESERVATION_PRIORITY, PR_SALE_CHANNEL_CODE
            INTO :WK_PR_RECORD_ID, :WK_PR_RESERVED_QTY
            DO
            BEGIN
               /* now can use min (reserved qty, available qty) */
               /* for a weighted apply use  wk_effective_qty * this qty / wk_net_reserved_qty 
                  where this qty is the current min(reserved_qty, effective_qty) */
/*
for total 380
for net total 280
line 1 priority 10 reserved 10
line 2 priority 5  reserved 20
line 3 priority 20 reserved 100
line 4 priority 25 reserved 150
     line 2 this qty = 380 * 20/280 = 27.1 - but is bigger than 20 so use 20
     line 1 this qty = 360 * 10/280 = 12.8 - but is bigger than 10 so use 10
     line 3 this qty = 350 * 100/280 = 125 - but is bigger than 100 so use 100
     line 4 this qty = 250 * 150/280 = 133.9 - so use 133
     that leaves 17 going into none
for total 280
     line 2 this qty = 280 * 20/280 = 20 -  so use 20
     line 1 this qty = 260 * 10/280 = 9.2 - so use 9
     line 3 this qty = 251 * 100/280 = 89.6 - so use 89 
     line 4 this qty = 162 * 150/280 = 86.7  - so use 86
     that leaves 76 going into none
for total 200
     line 2 this qty = 200 * 20/280 = 14.2 -  so use 14
     line 1 this qty = 186 * 10/280 = 6.6 - so use 6
     line 3 this qty = 180 * 100/280 = 64.2 - so use 64 
     line 4 this qty = 116 * 150/280 = 62.1  - so use 62
     that leaves 54 going into none
compare that with a take all calc
for total 380
     line 2 this qty  reserved 20  -  so use 20  left is 360
     line 1 this qty reserved 10 - so  use 10  left is 350 
     line 3 this qty reserved 100 - so use 100 left is 250 
     line 4 this qty reserved 150 - so use 150 left is 100 
     that leaves 100 going into none
for total 280
     line 2 this qty  reserved 20  -  so use 20  left is 260
     line 1 this qty reserved 10 - so  use 10  left is 250 
     line 3 this qty reserved 100 - so use 100 left is 150 
     line 4 this qty reserved 150 - so use 150 left is 0 
     that leaves 0 going into none
for total 200
     line 2 this qty  reserved 20  -  so use 20  left is 180
     line 1 this qty reserved 10 - so  use 10  left is 170 
     line 3 this qty reserved 100 - so use 100 left is 70 
     line 4 this qty reserved 150 - so use 70 left is 0 
     that leaves 0 going into none
*/
               WK_THIS_QTY = WK_PR_RESERVED_QTY;
               IF (WK_THIS_QTY > WK_EFFECTIVE_QTY) THEN
               BEGIN
                  WK_THIS_QTY = WK_EFFECTIVE_QTY;
               END
               IF (WK_THIS_QTY < 0) THEN
               BEGIN
                  WK_THIS_QTY = 0;
               END
               UPDATE PROD_RESERVATION
               SET PR_LAST_AVAILABLE_QTY = PR_AVAILABLE_QTY ,
                   PR_AVAILABLE_QTY = :WK_THIS_QTY 
               WHERE RECORD_ID  = :WK_PR_RECORD_ID;
               WK_EFFECTIVE_QTY = WK_EFFECTIVE_QTY - WK_THIS_QTY;
            END
         END
         CNT = CNT + 1;
      END
   END
  
   SUSPEND;
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
