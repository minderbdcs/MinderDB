COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;


CREATE OR ALTER PROCEDURE PICK_MODE_P4 (WK_ORDER_TYPES VARCHAR(255) ,
WK_ORDER_MODES VARCHAR(255) ,
WK_ORDERS VARCHAR(255) ,
WK_ORDER_STATUSES VARCHAR(255) ,
WK_ORDER_PRIORITYS VARCHAR(255) ,
WK_PARAM_IDS VARCHAR(255) )
RETURNS (WK_ORDER PICK_ORDER )
AS 
 
DECLARE VARIABLE WK_DELIM CHAR(1);
DECLARE VARIABLE WK_FOUND INTEGER;
DECLARE VARIABLE WK_ORDER_TYPE1 VARCHAR(10);
DECLARE VARIABLE WK_TYPE_CNT INTEGER;
DECLARE VARIABLE WK_ORDER_STATUS1 VARCHAR(10);
DECLARE VARIABLE WK_STATUS_CNT INTEGER;
DECLARE VARIABLE WK_PRIORITY1 INTEGER;
DECLARE VARIABLE WK_PRIORITY_CNT INTEGER;
DECLARE VARIABLE WK_ORDER_CNT INTEGER;
DECLARE VARIABLE WK_IDX INTEGER;
DECLARE VARIABLE WK_COND VARCHAR(35);
/* DECLARE VARIABLE WK_ORDER1 VARCHAR(15); */
DECLARE VARIABLE WK_ORDER1 PICK_ORDER;
DECLARE VARIABLE WK_PROD_CNT INTEGER;
DECLARE VARIABLE WK_PROD1 PRODUCT;
DECLARE VARIABLE WK_PROD2 PRODUCT;
DECLARE VARIABLE WK_PROD3 PRODUCT;
DECLARE VARIABLE WK_PROD4 PRODUCT;
DECLARE VARIABLE WK_PROD5 PRODUCT;
DECLARE VARIABLE WK_PROD6 PRODUCT;
DECLARE VARIABLE WK_PROD7 PRODUCT;
DECLARE VARIABLE WK_PROD8 PRODUCT;
DECLARE VARIABLE WK_PROD9 PRODUCT;
DECLARE VARIABLE WK_PROD10 PRODUCT;
DECLARE VARIABLE WK_PROD11 PRODUCT;
DECLARE VARIABLE WK_PROD12 PRODUCT;
DECLARE VARIABLE WK_PROD13 PRODUCT;
DECLARE VARIABLE WK_PROD14 PRODUCT;
DECLARE VARIABLE WK_PROD15 PRODUCT;
DECLARE VARIABLE WK_PROD16 PRODUCT;
DECLARE VARIABLE WK_PROD17 PRODUCT;
DECLARE VARIABLE WK_PROD18 PRODUCT;
DECLARE VARIABLE WK_PROD19 PRODUCT;
DECLARE VARIABLE WK_PROD20 PRODUCT;

BEGIN
   WK_DELIM = '|';
   WK_ORDER_TYPE1 = '';
   WK_ORDER_STATUS1 = '';
   WK_ORDER1 = '';
   WK_PRIORITY1 = -32000;
   WK_PROD1 = '';
   WK_PROD2 = '';
   WK_PROD3 = '';
   WK_PROD4 = '';
   WK_PROD5 = '';
   WK_PROD6 = '';
   WK_PROD7 = '';
   WK_PROD8 = '';
   WK_PROD9 = '';
   WK_PROD10 = '';
   WK_PROD11 = '';
   WK_PROD12 = '';
   WK_PROD13 = '';
   WK_PROD14 = '';
   WK_PROD15 = '';
   WK_PROD16 = '';
   WK_PROD17 = '';
   WK_PROD18 = '';
   WK_PROD19 = '';
   WK_PROD20 = '';
   /* normally only one order type but glen wants several or GETALL */
   /* IF (WK_ORDER_TYPES = 'GETALL') THEN */
   BEGIN
      WK_ORDER_TYPE1 = 'GETALL';
      WK_TYPE_CNT = 1;
   END

   /* normally GETALL in the mode - unused field */

   /* order statuses - why this ?? - must be confirmed lines OP or UP */
   /* IF (WK_ORDER_STATUSES = 'GETALL') THEN */
   BEGIN
      WK_ORDER_STATUS1 = 'GETALL';
      WK_STATUS_CNT = 1;
   END

   /* ordno is a list of orders or GETALL */
   /* orders are length 9 or 10 for internal */
   /* so can have a maximum of 255 = (1 + n*10) */   
   /* thus n = 25 */
   /* calc orders 1 - 25 */
   /* but only allow upto 20 */
   /* IF (WK_ORDERS = 'GETALL') THEN */
   BEGIN
      WK_ORDER1 = 'GETALL';
      WK_ORDER_CNT = 1;
   END

   /* order priorities 0 = GETALL or a specific priority */
   /* priorities are small int - range -32768 - +32767 */
   /* but really 0 - 9 and -9 - -1 since a 1 char display */
   /* so a max of 19 */
   /* but only allow upto 2 */

   /* IF (WK_ORDER_PRIORITYS = 'GETALL') THEN */
   BEGIN
      WK_PRIORITY1 = 0;
      WK_STATUS_CNT = 1;
   END

   /* parms for a specifiy procedure either GETALL or a LIST */
   /* for P4 this is GETALL */
   /* pre pack orders ie kits only */
   /* so can have a maximum of 255 = (1 + n*14) */   
   /* thus n = 18 */
   /* calc prods 1 - 18 */
   /* but only allow upto 20 */
   IF (WK_PARAM_IDS = 'GETALL') THEN
   BEGIN
      WK_PROD1 = 'GETALL';
      WK_PROD_CNT = 1;
   END
   ELSE
   BEGIN
      WK_PROD_CNT = 0;
      WK_IDX = 1;
/*    WK_COND = ALLTRIM(PARSE(:WK_PARAM_IDS,:WK_DELIM,:WK_IDX)); */
/*    WK_COND = V6ALLTRIM(V6PARSE(:WK_PARAM_IDS,:WK_DELIM,:WK_IDX)); */
      WK_COND = TRIM(V6PARSE(:WK_PARAM_IDS,:WK_DELIM,:WK_IDX));
      WHILE (WK_COND <> 'Token to long in parse') DO 
      BEGIN
         WK_PROD_CNT = WK_PROD_CNT + 1;
         IF (WK_PROD_CNT = 1) THEN
            WK_PROD1 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 2) THEN
            WK_PROD2 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 3) THEN
            WK_PROD3 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 4) THEN
            WK_PROD4 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 5) THEN
            WK_PROD5 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 6) THEN
            WK_PROD6 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 7) THEN
            WK_PROD7 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 8) THEN
            WK_PROD8 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 9) THEN
            WK_PROD9 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 10) THEN
            WK_PROD10 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 11) THEN
            WK_PROD11 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 12) THEN
            WK_PROD12 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 13) THEN
            WK_PROD13 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 14) THEN
            WK_PROD14 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 15) THEN
            WK_PROD15 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 16) THEN
            WK_PROD16 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 17) THEN
            WK_PROD17 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 18) THEN
            WK_PROD18 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 19) THEN
            WK_PROD19 = WK_COND;
         ELSE
         IF (WK_PROD_CNT = 20) THEN
            WK_PROD20 = WK_COND;
         /* get next PROD */
         WK_IDX = WK_IDX + 1;
/*       WK_COND = ALLTRIM(PARSE(:WK_PARAM_IDS,:WK_DELIM,:WK_IDX)); */
/*       WK_COND = V6ALLTRIM(V6PARSE(:WK_PARAM_IDS,:WK_DELIM,:WK_IDX)); */
         WK_COND = TRIM(V6PARSE(:WK_PARAM_IDS,:WK_DELIM,:WK_IDX));
      END
   END

   IF ((WK_ORDER1 = 'GETALL') AND
       (WK_ORDER_TYPE1 = 'GETALL') AND
       (WK_ORDER_STATUS1 = 'GETALL') AND
       (WK_PRIORITY1 = 0) AND
       (WK_PROD1 = 'GETALL')) THEN
   BEGIN
      FOR 
         /*  GROUP BY P1.PICK_ORDER */
         SELECT DISTINCT(P1.PICK_ORDER) 
         FROM PICK_ITEM P1 
             JOIN PICK_ORDER P2 ON P2.PICK_ORDER = P1.PICK_ORDER 
             JOIN KIT P3 ON P3.KIT_ID = P1.PROD_ID 
         WHERE P1.PICK_LINE_STATUS IN ('OP','UP') 
           AND  P1.PICK_ORDER_QTY > 0   
           AND P2.PICK_STATUS IN ('OP','DA')
           ORDER BY P2.PICK_PRIORITY, P2.WIP_ORDERING, P1.WIP_PRELOCN_ORDERING, P1.PICK_LOCATION, P1.WIP_POSTLOCN_ORDERING 
         INTO :WK_ORDER 
      DO
      BEGIN
         /* OK now have orders with at least 1 kitted product */
         WK_FOUND = 0;
         SELECT 1 
         FROM PICK_ITEM P1
         LEFT OUTER JOIN KIT P3 ON P3.KIT_ID = P1.PROD_ID 
         WHERE P1.PICK_ORDER = :WK_ORDER
         GROUP BY P1.PICK_ORDER
         HAVING COUNT(*) = COUNT(P3.KIT_ID)
         INTO :WK_FOUND;
         IF (WK_FOUND = 1) THEN
         BEGIN
            /* ok have only kitted products here */
            SUSPEND;
         END
      END
   END
   ELSE
   IF ((WK_ORDER1 = 'GETALL') AND
       (WK_ORDER_TYPE1 = 'GETALL') AND
       (WK_ORDER_STATUS1 = 'GETALL') AND
       (WK_PRIORITY1 = 0) AND
       (WK_PROD_CNT > 0)) THEN
   BEGIN
      FOR 
         /*  GROUP BY P1.PICK_ORDER */
         SELECT DISTINCT(P1.PICK_ORDER) 
         FROM PICK_ITEM P1 
             JOIN PICK_ORDER P2 ON P2.PICK_ORDER = P1.PICK_ORDER 
             JOIN KIT P3 ON P3.KIT_ID = P1.PROD_ID 
         WHERE P1.PICK_LINE_STATUS IN ('OP','UP') 
           AND  P1.PICK_ORDER_QTY > 0   
           AND (P1.PROD_ID = :WK_PROD1
                OR P1.PROD_ID = :WK_PROD2
                OR P1.PROD_ID = :WK_PROD3
                OR P1.PROD_ID = :WK_PROD4
                OR P1.PROD_ID = :WK_PROD5
                OR P1.PROD_ID = :WK_PROD6
                OR P1.PROD_ID = :WK_PROD7
                OR P1.PROD_ID = :WK_PROD8
                OR P1.PROD_ID = :WK_PROD9
                OR P1.PROD_ID = :WK_PROD10
                OR P1.PROD_ID = :WK_PROD11
                OR P1.PROD_ID = :WK_PROD12
                OR P1.PROD_ID = :WK_PROD13
                OR P1.PROD_ID = :WK_PROD14
                OR P1.PROD_ID = :WK_PROD15
                OR P1.PROD_ID = :WK_PROD16
                OR P1.PROD_ID = :WK_PROD17
                OR P1.PROD_ID = :WK_PROD18
                OR P1.PROD_ID = :WK_PROD19
                OR P1.PROD_ID = :WK_PROD20)
           AND P2.PICK_STATUS IN ('OP','DA')
           ORDER BY P2.PICK_PRIORITY, P2.WIP_ORDERING, P1.WIP_PRELOCN_ORDERING, P1.PICK_LOCATION, P1.WIP_POSTLOCN_ORDERING 
         INTO :WK_ORDER 
      DO
      BEGIN
         /* OK now have orders for the named product */
         WK_FOUND = 0;
         SELECT 1 
         FROM PICK_ITEM P1
         LEFT OUTER JOIN KIT P3 ON P3.KIT_ID = P1.PROD_ID 
         WHERE P1.PICK_ORDER = :WK_ORDER
         GROUP BY P1.PICK_ORDER
         HAVING COUNT(*) = COUNT(P3.KIT_ID)
         INTO :WK_FOUND;
         IF (WK_FOUND = 1) THEN
         BEGIN
            /* ok have only kitted products here */
            SUSPEND;
         END
      END
   END
   EXIT;
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
