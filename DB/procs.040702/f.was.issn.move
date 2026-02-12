 
CREATE TRIGGER UPDATE_ISSN_LOCATION FOR ISSN 
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
      SELECT MOVE_STAT FROM LOCATION 
         WHERE WH_ID = :WK_NEW_WH_ID AND LOCN_ID = :WK_NEW_LOCN_ID
         INTO :WK_TO_STATUS;
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
            IF (WK_TO_STATUS = 'DS') THEN
            BEGIN
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
                 SELECT FIRST 1 1, PICK_LABEL_NO 
                        FROM PICK_ITEM
                  WHERE SSN_ID = :WK_SSN
                  AND (SSN_CONFIRM = 'T' OR SSN_CONFIRM IS NULL)
                  AND (PICK_LINE_STATUS IN ('OP','CN','HD','RS')
                   OR PICK_LINE_STATUS IS NULL)
                        INTO :WK_FOUND,
                             :WK_LABEL_NO;
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
                             "NOW");
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
         END
      END
   END
END ^
 
