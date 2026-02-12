COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;
 
CREATE OR ALTER TRIGGER UPDATE_ISSN_LOCATION FOR ISSN 
ACTIVE BEFORE UPDATE POSITION 0 
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
     
BEGIN
   /* Update ISSN table */   
         
   WK_NEW_WH_ID = NEW.WH_ID;
   WK_NEW_LOCN_ID = NEW.LOCN_ID;
   WK_OLD_WH_ID = OLD.WH_ID;
   WK_OLD_LOCN_ID = OLD.LOCN_ID;
   WK_USER = NEW.USER_ID;
   IF ( (WK_NEW_WH_ID <> WK_OLD_WH_ID) OR
        (WK_NEW_LOCN_ID <> WK_OLD_LOCN_ID)) THEN
   BEGIN
      /* location changed */
      WK_FROM_STATUS = NEW.ISSN_STATUS;
      WK_SSN = NEW.SSN_ID;
      WK_SSN_QTY = NEW.CURRENT_QTY;
      WK_TO_STATUS = 'ST';
      /* does the new location exist */
      WK_FOUND = 0;
      SELECT 1 FROM LOCATION 
         WHERE WH_ID = :WK_NEW_WH_ID AND LOCN_ID = :WK_NEW_LOCN_ID
         INTO :WK_FOUND;
      IF (WK_FOUND IS NULL) THEN
      BEGIN
         WK_FOUND = 0;
      END
      IF (WK_FOUND = 0) THEN
      BEGIN
         IF (WK_NEW_WH_ID < 'X' OR WK_NEW_WH_ID > 'X~') THEN
         BEGIN
            /* location not found - so add it */
            WK_MOVE_STAT = NULL;
            SELECT DESCRIPTION FROM OPTIONS WHERE GROUP_CODE = 'WH_ST_MV' AND  CODE = :WK_NEW_WH_ID INTO :WK_MOVE_STAT;
            INSERT INTO LOCATION (WH_ID, LOCN_ID, LOCN_NAME, MOVE_STAT) VALUES (:WK_NEW_WH_ID, :WK_NEW_LOCN_ID, :WK_NEW_LOCN_ID, :WK_MOVE_STAT);
         END
      END

      /* SELECT MOVE_STAT FROM LOCATION  */
      /*   INTO :WK_TO_STATUS; */
      SELECT MOVE_STAT, MOVEABLE_LOCN, STORE_TYPE FROM LOCATION 
         WHERE WH_ID = :WK_NEW_WH_ID AND LOCN_ID = :WK_NEW_LOCN_ID
         INTO :WK_TO_STATUS, :WK_TO_MOVEABLE, :WK_TO_STORE_TYPE;
/*
    if move_stat is null and moveable_locn is true
    and store_type is TR 
    then treat this as a move to a PL
*/
      IF (WK_TO_STATUS IS NULL) THEN
      BEGIN
         IF (WK_TO_MOVEABLE = 'T' AND WK_TO_STORE_TYPE = 'TR') THEN
         BEGIN
            WK_TO_STATUS = 'PL';
         END
      END
      IF (WK_FROM_STATUS <> WK_TO_STATUS) THEN
      BEGIN
         /* a change in status possible - so check sys_moves */
         WK_IS_OK = 'N';
         SELECT UPDATE_FLAG FROM SYS_MOVES
            WHERE FROM_STATUS = :WK_FROM_STATUS AND INTO_STATUS = :WK_TO_STATUS
            INTO :WK_IS_OK;
         IF (WK_IS_OK = 'T') THEN
         BEGIN
            NEW.ISSN_STATUS = WK_TO_STATUS;
            WK_ALLOWED_STATUS = NULL;
            SELECT PICK_IMPORT_SSN_STATUS
            FROM CONTROL
            INTO :WK_ALLOWED_STATUS;
            IF (WK_ALLOWED_STATUS IS NULL) THEN
            BEGIN
               WK_ALLOWED_STATUS = ',,,';
            END
            IF (WK_FROM_STATUS = 'DI') THEN
            BEGIN
               /* move from Despatch on loan
                  so remove from confimation of previous order */
               NEW.PREV_PREV_PICK_ORDER = OLD.PREV_PICK_ORDER;
               NEW.PREV_PICK_ORDER = OLD.PICK_ORDER;
               NEW.PICK_ORDER = NULL;
               NEW.PREV_PREV_PACK_ID = OLD.PREV_PACK_ID;
               NEW.PREV_PACK_ID = OLD.PACK_ID;
               NEW.PACK_ID = NULL;
               NEW.PREV_PREV_DESPATCH_ID = OLD.PREV_DESPATCH_ID;
               NEW.PREV_DESPATCH_ID = OLD.DESPATCH_ID;
               NEW.DESPATCH_ID = NULL;
            END

            IF (WK_TO_STATUS = 'DS') THEN
            BEGIN
               WK_SSN_PICK_ORDER = NEW.PICK_ORDER;
               WK_DOIT = 'N';
               IF (WK_FROM_STATUS = 'PA') THEN
               BEGIN
                  WK_DOIT = 'Y';
               END
               IF (WK_FROM_STATUS = 'ST') THEN
               BEGIN
                  WK_DOIT = 'Y';
               END
               IF (WK_FROM_STATUS = 'RS') THEN
               BEGIN
                  WK_DOIT = 'Y';
               END
               IF (WK_FROM_STATUS = 'OP') THEN
               BEGIN
                  WK_DOIT = 'Y';
               END
               IF (WK_DOIT = 'Y') THEN
               BEGIN
                 WK_FOUND = 0;
                  /* AND (PICK_ITEM.SSN_CONFIRM = 'T' OR PICK_ITEM.SSN_CONFIRM IS NULL) */
                 /* if we do confirm of order
                    then 
                         want to match the correct line in issn versus pick_item
                    else
                         we import order as confirmed
                         but nothing in issns pick_order
                         so can only take the 1st pick_item for this issn
                 */
                 SELECT FIRST 1 1, PICK_ITEM.PICK_LABEL_NO 
                        FROM PICK_ITEM
                        JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PICK_ITEM.PICK_ORDER
                  WHERE PICK_ITEM.SSN_ID = :WK_SSN
                  AND   PICK_ITEM.PICK_LABEL_NO = :WK_SSN_PICK_ORDER 
                  AND (PICK_ITEM.SSN_CONFIRM = 'T' OR PICK_ITEM.SSN_CONFIRM = 'I' OR PICK_ITEM.SSN_CONFIRM IS NULL)
                  AND (PICK_ITEM.PICK_LINE_STATUS IN ('OP','UP','RS'))
                  AND (PICK_ORDER.PICK_STATUS IN ('OP','DA'))
                        INTO :WK_FOUND,
                             :WK_LABEL_NO;
                  IF (WK_FOUND IS NULL) THEN
                  BEGIN
                     WK_FOUND = 0;
                  END
                  /* disable using the older method - until someone wants to 
                     pick by transfer an unconfirmed order */
                  IF (WK_FOUND = 2) THEN
                  BEGIN
                     /* no pick item for this issn that is confirmed */
                     /* old method */
                     SELECT FIRST 1 1, PICK_ITEM.PICK_LABEL_NO 
                        FROM PICK_ITEM
                        JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PICK_ITEM.PICK_ORDER
                     WHERE PICK_ITEM.SSN_ID = :WK_SSN
                     AND (PICK_ITEM.SSN_CONFIRM = 'T' OR PICK_ITEM.SSN_CONFIRM = 'I' OR PICK_ITEM.SSN_CONFIRM IS NULL)
                     AND (PICK_ITEM.PICK_LINE_STATUS IN ('OP','UP','RS'))
                     AND (PICK_ORDER.PICK_STATUS IN ('OP','DA'))
                        INTO :WK_FOUND,
                             :WK_LABEL_NO;
                  END
                  IF (WK_FOUND = 1) THEN
                  BEGIN
                     UPDATE PICK_ITEM 
                     SET PICK_LINE_STATUS = 'DS',
                         PICKED_QTY = :WK_SSN_QTY,
                         DESPATCH_LOCATION = :WK_NEW_LOCN_ID 
                     WHERE SSN_ID = :WK_SSN
                     AND PICK_LABEL_NO = :WK_LABEL_NO;
                     WK_PID_FOUND = 0;
                     SELECT 1, PICK_DETAIL_ID 
                            FROM PICK_ITEM_DETAIL
                            WHERE PICK_LABEL_NO = :WK_LABEL_NO
                            AND SSN_ID = :WK_SSN
                            INTO :WK_PID_FOUND, :WK_DETAIL_ID;
                     IF (WK_PID_FOUND = 0) THEN
                     BEGIN
                        /* no detail record */
                        INSERT INTO PICK_ITEM_DETAIL 
                            (PICK_LABEL_NO, 
                             SSN_ID, 
                             PICK_DETAIL_STATUS, 
                             DESPATCH_LOCATION,
                             QTY_PICKED,
                             USER_ID, 
                             CREATE_DATE)
                        VALUES (:WK_LABEL_NO, 
                             :WK_SSN,
                             'DS',
                             :WK_NEW_LOCN_ID ,
                             :WK_SSN_QTY,
                             :WK_USER,
                             'NOW');
                     END
                     ELSE
                     BEGIN
                        UPDATE PICK_ITEM_DETAIL 
                        SET  PICK_DETAIL_STATUS =
                             'DS',
                             QTY_PICKED =
                             :WK_SSN_QTY ,
                             DESPATCH_LOCATION =
                             :WK_NEW_LOCN_ID ,
                             USER_ID =
                             :WK_USER
                        WHERE PICK_DETAIL_ID = :WK_DETAIL_ID;
                     END
                  END
               END
            END

            IF (WK_TO_STATUS = 'ST') THEN
            BEGIN
               IF (NEW.PROD_ID IS NOT NULL) THEN
               BEGIN
/*
in receive status becomes PA in a RC move stat location
     this uses an insert not an update
     then the issn.prev_prev_locn and issn.prev_locn_id  are null
     if (PA in control.pick_import_ssn_status  and from status is PA )  
     or (ST in control.pick_import_ssn_status  and from status is ST) then 
        want to release the next pick items
        use an insert trigger similar to this one for that
*/

/*
move via a hh or screen to a ST move stat location
if allowed_status includes PA  and from status is PA
then already released  in receives insert trigger 
else
     if from status <> DS
         want to release the next pick items                        - yes
*/

	          /* if old status is  in control.pick_import_ssn_status  */
                  IF ( (POS(:WK_ALLOWED_STATUS, 'PA', 0, 1)  >   -1) AND  
                       (WK_FROM_STATUS =  'PA') ) THEN
                  BEGIN
                     WK_DUMMY = 1;
                     /* already done */
                  END
                  ELSE
                  BEGIN
                     IF  (WK_FROM_STATUS <>  'DS')  THEN
                     BEGIN
/*
                        UPDATE PICK_ITEM
                        SET PICK_LINE_STATUS = 'OP'
                        WHERE PICK_ITEM.PROD_ID = NEW.PROD_ID 
                        AND   PICK_ITEM.PICK_LINE_STATUS = 'AS';
*/
                        /* want to only update the 1st qty of pick items that match */
                        WK_IS_TOPICK_QTY = NEW.CURRENT_QTY;
                        FOR SELECT PICK_ITEM.PICK_LABEL_NO, (COALESCE(PICK_ITEM.PICK_ORDER_QTY, 0) - COALESCE(PICK_ITEM.PICKED_QTY,0)) AS  TOPICK_QTY, PICK_ORDER.PARTIAL_PICK_ALLOWED
                        FROM  PICK_ITEM
                        JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PICK_ITEM.PICK_ORDER
                        WHERE PICK_ITEM.PROD_ID = NEW.PROD_ID 
                        AND   PICK_ITEM.PICK_LINE_STATUS = 'AS'
                        AND PICK_ORDER.WH_ID = NEW.WH_ID
                        AND PICK_ORDER.COMPANY_ID = NEW.COMPANY_ID
                        ORDER BY  PICK_ORDER.PICK_PRIORITY, PICK_ORDER.PICK_DUE_DATE 
                        INTO :WK_PI_LABEL_NO, :WK_PI_TOPICK_QTY, :WK_PO_PARTIAL_PICK
                        DO
                        BEGIN
                           IF (WK_IS_TOPICK_QTY > 0 AND WK_PI_TOPICK_QTY > 0  ) THEN
                           BEGIN
                              IF (WK_PO_PARTIAL_PICK = 'T' OR WK_PI_TOPICK_QTY <= WK_IS_TOPICK_QTY) THEN
                              BEGIN
                                 UPDATE PICK_ITEM
                                 SET PICK_LINE_STATUS = 'OP'
                                 WHERE PICK_ITEM.PICK_LABEL_NO = :WK_PI_LABEL_NO ;
                                 WK_IS_TOPICK_QTY = WK_IS_TOPICK_QTY - WK_PI_TOPICK_QTY;
                              END
                           END
                        END
                     END
                  END
               END
            END
            IF (WK_FROM_STATUS = 'DS' AND WK_TO_STATUS = 'ST') THEN
            BEGIN
/*
if old issn status was DS and move to ST move stat location
then we release from the old location and update the pick items - yes
*/
               /* move from Despatch location back to stock
                  so remove from confimation of previous order */
               NEW.PREV_PREV_PICK_ORDER = OLD.PREV_PICK_ORDER;
               NEW.PREV_PICK_ORDER = OLD.PICK_ORDER;
               NEW.PICK_ORDER = NULL;
               NEW.PREV_PREV_PACK_ID = OLD.PREV_PACK_ID;
               NEW.PREV_PACK_ID = OLD.PACK_ID;
               NEW.PACK_ID = NULL;
               NEW.PREV_PREV_DESPATCH_ID = OLD.PREV_DESPATCH_ID;
               NEW.PREV_DESPATCH_ID = OLD.DESPATCH_ID;
               NEW.DESPATCH_ID = NULL;
               /* has done an unpick - but dont want to release any more orders - since order is still op/up */
            END
            IF (WK_FROM_STATUS = 'DS' AND WK_TO_STATUS = 'RC') THEN
            BEGIN
/*
if old issn status was DS and move to RC move stat location
then we release from the old location and update the pick items - yes
     if PA in control.pick_import_ssn_status   then 
     want to release the next pick items                        - yes
*/
               /* move from Despatch location back to stock
                  so remove from confimation of previous order */
               NEW.ISSN_STATUS = 'PA';
               NEW.PREV_PREV_PICK_ORDER = OLD.PREV_PICK_ORDER;
               NEW.PREV_PICK_ORDER = OLD.PICK_ORDER;
               NEW.PICK_ORDER = NULL;
               NEW.PREV_PREV_PACK_ID = OLD.PREV_PACK_ID;
               NEW.PREV_PACK_ID = OLD.PACK_ID;
               NEW.PACK_ID = NULL;
               NEW.PREV_PREV_DESPATCH_ID = OLD.PREV_DESPATCH_ID;
               NEW.PREV_DESPATCH_ID = OLD.DESPATCH_ID;
               NEW.DESPATCH_ID = NULL;
               NEW.ISSN_STATUS = 'PA';
               /* has done an unpick - but dont want to release any more orders - since order is still op/up */
            END
            IF (WK_FROM_STATUS = 'ST' AND WK_TO_STATUS = 'RC') THEN
            BEGIN
               NEW.ISSN_STATUS = 'ST';
            END
            IF (WK_FROM_STATUS = 'PA' AND WK_TO_STATUS = 'RC') THEN
            BEGIN
               NEW.ISSN_STATUS = 'PA';
            END

            IF (WK_TO_STATUS = 'PL') THEN
            BEGIN
               WK_SSN_PICK_ORDER = NEW.PICK_ORDER;
               WK_DOIT = 'N';
               IF (WK_FROM_STATUS = 'PA') THEN
               BEGIN
                  WK_DOIT = 'Y';
               END
               IF (WK_FROM_STATUS = 'ST') THEN
               BEGIN
                  WK_DOIT = 'Y';
               END
               IF (WK_FROM_STATUS = 'RS') THEN
               BEGIN
                  WK_DOIT = 'Y';
               END
               IF (WK_FROM_STATUS = 'OP') THEN
               BEGIN
                  WK_DOIT = 'Y';
               END
               IF (WK_DOIT = 'Y') THEN
               BEGIN
                 WK_FOUND = 0;
                  /* AND (PICK_ITEM.SSN_CONFIRM = 'T' OR PICK_ITEM.SSN_CONFIRM IS NULL) */
                 /* if we do confirm of order
                    then 
                         want to match the correct line in issn versus pick_item
                    else
                         we import order as confirmed
                         but nothing in issns pick_order
                         so can only take the 1st pick_item for this issn
                 */
                 SELECT FIRST 1 1, PICK_ITEM.PICK_LABEL_NO 
                        FROM PICK_ITEM
                        JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PICK_ITEM.PICK_ORDER
                  WHERE PICK_ITEM.SSN_ID = :WK_SSN
                  AND   PICK_ITEM.PICK_LABEL_NO = :WK_SSN_PICK_ORDER 
                  AND (PICK_ITEM.SSN_CONFIRM = 'T' OR PICK_ITEM.SSN_CONFIRM = 'I' OR PICK_ITEM.SSN_CONFIRM IS NULL)
                  AND (PICK_ITEM.PICK_LINE_STATUS IN ('OP','UP','RS'))
                  AND (PICK_ORDER.PICK_STATUS IN ('OP','DA'))
                        INTO :WK_FOUND,
                             :WK_LABEL_NO;
                  IF (WK_FOUND IS NULL) THEN
                  BEGIN
                     WK_FOUND = 0;
                  END
                  /* disable using the older method - until someone wants to 
                     pick by transfer an unconfirmed order */
                  IF (WK_FOUND = 2) THEN
                  BEGIN
                     /* no pick item for this issn that is confirmed */
                     /* old method */
                     SELECT FIRST 1 1, PICK_ITEM.PICK_LABEL_NO 
                        FROM PICK_ITEM
                        JOIN PICK_ORDER ON PICK_ORDER.PICK_ORDER = PICK_ITEM.PICK_ORDER
                     WHERE PICK_ITEM.SSN_ID = :WK_SSN
                     AND (PICK_ITEM.SSN_CONFIRM = 'T' OR PICK_ITEM.SSN_CONFIRM = 'I' OR PICK_ITEM.SSN_CONFIRM IS NULL)
                     AND (PICK_ITEM.PICK_LINE_STATUS IN ('OP','UP','RS'))
                     AND (PICK_ORDER.PICK_STATUS IN ('OP','DA'))
                        INTO :WK_FOUND,
                             :WK_LABEL_NO;
                  END
                  IF (WK_FOUND = 1) THEN
                  BEGIN
                     UPDATE PICK_ITEM 
                     SET PICK_LINE_STATUS = 'PL',
                         PICKED_QTY = :WK_SSN_QTY,
                         DESPATCH_LOCATION = :WK_NEW_LOCN_ID 
                     WHERE SSN_ID = :WK_SSN
                     AND PICK_LABEL_NO = :WK_LABEL_NO;
                     WK_PID_FOUND = 0;
                     SELECT 1, PICK_DETAIL_ID 
                            FROM PICK_ITEM_DETAIL
                            WHERE PICK_LABEL_NO = :WK_LABEL_NO
                            AND SSN_ID = :WK_SSN
                            INTO :WK_PID_FOUND, :WK_DETAIL_ID;
                     IF (WK_PID_FOUND = 0) THEN
                     BEGIN
                        /* no detail record */
                        INSERT INTO PICK_ITEM_DETAIL 
                            (PICK_LABEL_NO, 
                             SSN_ID, 
                             PICK_DETAIL_STATUS, 
                             DESPATCH_LOCATION,
                             QTY_PICKED,
                             USER_ID, 
                             CREATE_DATE)
                        VALUES (:WK_LABEL_NO, 
                             :WK_SSN,
                             'PL',
                             :WK_NEW_LOCN_ID ,
                             :WK_SSN_QTY,
                             :WK_USER,
                             'NOW');
                     END
                     ELSE
                     BEGIN
                        UPDATE PICK_ITEM_DETAIL 
                        SET  PICK_DETAIL_STATUS =
                             'PL',
                             QTY_PICKED =
                             :WK_SSN_QTY ,
                             DESPATCH_LOCATION =
                             :WK_NEW_LOCN_ID ,
                             USER_ID =
                             :WK_USER
                        WHERE PICK_DETAIL_ID = :WK_DETAIL_ID;
                     END
                  END
               END
            END
         END
      END
   END
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
