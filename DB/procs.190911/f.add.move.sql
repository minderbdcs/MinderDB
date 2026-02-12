COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;
 
CREATE OR ALTER TRIGGER ADD_ISSN_LOCATION FOR ISSN 
ACTIVE BEFORE INSERT POSITION 0 
AS
                                                       
  DECLARE VARIABLE WK_FROM_STATUS VARCHAR(2);
  DECLARE VARIABLE WK_TO_STATUS VARCHAR(2);
  DECLARE VARIABLE WK_NEW_WH_ID WH_ID;
  DECLARE VARIABLE WK_NEW_LOCN_ID LOCN_ID;
  DECLARE VARIABLE WK_OLD_WH_ID WH_ID;
  DECLARE VARIABLE WK_OLD_LOCN_ID LOCN_ID;
  DECLARE VARIABLE WK_IS_OK CHAR(1);
  DECLARE VARIABLE WK_DOIT CHAR(1);
  DECLARE VARIABLE WK_SSN SSN_ID;
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
     
BEGIN
   /* add to ISSN table */   
         
   WK_NEW_WH_ID = NEW.WH_ID;
   WK_NEW_LOCN_ID = NEW.LOCN_ID;
   WK_OLD_WH_ID = NULL;
   WK_OLD_LOCN_ID = NULL;
   WK_USER = NEW.USER_ID;
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
         /* location not found - so add it */
         WK_MOVE_STAT = NULL;
         SELECT DESCRIPTION FROM OPTIONS WHERE GROUP_CODE = 'WH_ST_MV' AND  CODE = :WK_NEW_WH_ID INTO :WK_MOVE_STAT;
         INSERT INTO LOCATION (WH_ID, LOCN_ID, LOCN_NAME, MOVE_STAT) VALUES (:WK_NEW_WH_ID, :WK_NEW_LOCN_ID, :WK_NEW_LOCN_ID, :WK_MOVE_STAT);
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
      BEGIN
         /* a change in status possible - so check sys_moves */
         WK_IS_OK = 'N';
         SELECT UPDATE_FLAG FROM SYS_MOVES
            WHERE FROM_STATUS = :WK_FROM_STATUS AND INTO_STATUS = :WK_TO_STATUS
            INTO :WK_IS_OK;
         IF (WK_IS_OK = 'T') THEN
         BEGIN
            /* NEW.ISSN_STATUS = WK_TO_STATUS; */
            WK_ALLOWED_STATUS = NULL;
            SELECT PICK_IMPORT_SSN_STATUS
            FROM CONTROL
            INTO :WK_ALLOWED_STATUS;
            IF (WK_ALLOWED_STATUS IS NULL) THEN
            BEGIN
               WK_ALLOWED_STATUS = ',,,';
            END

/*               (POS(:WK_ALLOWED_STATUS, 'PA', 0, 1)  >  -1)) OR  
                 (POS(:WK_ALLOWED_STATUS, 'ST', 0, 1)  >  -1))) THEN  */
            IF (((WK_TO_STATUS = 'RC') AND 
                 (WK_FROM_STATUS = 'PA') AND
                 (POSITION( 'PA', :WK_ALLOWED_STATUS, 1)  >  0)) OR  
                ((WK_TO_STATUS = 'RC') AND 
                 (WK_FROM_STATUS = 'ST') AND
                 (POSITION( 'ST', :WK_ALLOWED_STATUS, 1)  >  0))) THEN
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
   END
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
