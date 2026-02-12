
DROP TRIGGER RUN_TRANSACTION_PKCN^
COMMIT^


CREATE TRIGGER RUN_TRANSACTION_PKCN FOR TRANSACTIONS 
ACTIVE AFTER INSERT POSITION 52 
AS
DECLARE VARIABLE WK_AUTORUN INTEGER;
DECLARE VARIABLE WK_DEVICE CHAR(2);
DECLARE VARIABLE WK_PI_PICKED_QTY INTEGER;
DECLARE VARIABLE WK_PID_PICKED_QTY INTEGER;
DECLARE VARIABLE WK_LABEL_NO VARCHAR(10);
DECLARE VARIABLE WK_LABEL_NO2 VARCHAR(10);
DECLARE VARIABLE WK_PI_STATUS CHAR(2);
DECLARE VARIABLE WK_RECORD INTEGER;
DECLARE VARIABLE WK_PID_SSN VARCHAR(20);
DECLARE VARIABLE WK_FOUND INTEGER;
DECLARE VARIABLE WK_DATE TIMESTAMP;
DECLARE VARIABLE WK_USER VARCHAR(10);

BEGIN
 WK_AUTORUN = GEN_ID(AUTOEXEC_TRANSACTIONS,0); 
 IF (WK_AUTORUN = 1) THEN
 BEGIN
  IF (NEW.TRN_TYPE = 'PKCN') THEN
  BEGIN
     WK_DEVICE = NEW.DEVICE_ID;
     WK_LABEL_NO = NEW.SUB_LOCN_ID;
     WK_RECORD = NEW.RECORD_ID;
     WK_DATE = NEW.TRN_DATE;
     WK_USER = NEW.PERSON_ID;
     WK_FOUND = 0;
     /* get the current label no to cancel */
     SELECT FIRST 1 1, PICK_LABEL_NO   
     FROM PICK_ITEM 
     WHERE PICK_LINE_STATUS IN ('AL','PG') 
       AND DEVICE_ID = :WK_DEVICE
       AND PICK_LABEL_NO = :WK_LABEL_NO
     ORDER BY PICK_LOCATION
     INTO :WK_FOUND, :WK_LABEL_NO;

     IF (WK_FOUND = 1) THEN
     BEGIN
        /* save prev status in issn for move back */
        FOR SELECT SSN_ID FROM PICK_ITEM_DETAIL
            WHERE DEVICE_ID = :WK_DEVICE 
              AND PICK_LABEL_NO = :WK_LABEL_NO
              AND PICK_DETAIL_STATUS IN ('AL', 'PG')
            INTO :WK_PID_SSN
        DO
        BEGIN
           UPDATE ISSN SET ISSN_STATUS = 'RS',
               WH_ID = PREV_WH_ID,
               LOCN_ID = PREV_LOCN_ID
            WHERE SSN_ID = :WK_PID_SSN;
        END
        FOR SELECT SUM(QTY_PICKED)
            FROM PICK_ITEM_DETAIL
            WHERE DEVICE_ID = :WK_DEVICE 
              AND PICK_LABEL_NO = :WK_LABEL_NO
              AND PICK_DETAIL_STATUS IN ('PG')
            INTO :WK_PID_PICKED_QTY
        DO
        BEGIN
           SELECT PICKED_QTY 
           FROM PICK_ITEM
           WHERE PICK_LABEL_NO = :WK_LABEL_NO
            INTO :WK_PI_PICKED_QTY;
           WK_PI_PICKED_QTY = WK_PI_PICKED_QTY - WK_PID_PICKED_QTY; 
           /* recalc pick_item status */
           IF (WK_PI_PICKED_QTY = 0) THEN
           BEGIN
              WK_PI_STATUS = 'OP';
           END
           ELSE
           BEGIN
              WK_PI_STATUS = 'PG';
           END
           UPDATE PICK_ITEM
           SET  PICK_LINE_STATUS = :WK_PI_STATUS,
                PICKED_QTY = :WK_PI_PICKED_QTY
           WHERE PICK_LABEL_NO = :WK_LABEL_NO;
        END
        FOR SELECT PICK_LABEL_NO 
            FROM PICK_ITEM
            WHERE DEVICE_ID = :WK_DEVICE 
              AND PICK_LABEL_NO = :WK_LABEL_NO
              AND PICK_LINE_STATUS IN ('PG')
            INTO :WK_LABEL_NO2
        DO
        BEGIN
           WK_FOUND = 0;
           SELECT COUNT(*) FROM PICK_ITEM_DETAIL
              WHERE PICK_DETAIL_STATUS IN ('PG')
                AND PICK_LABEL_NO = :WK_LABEL_NO
              INTO :WK_FOUND;
           IF (WK_FOUND = 0) THEN
           BEGIN
              /* no details for pick item */
              UPDATE PICK_ITEM
              SET  PICK_LINE_STATUS = 'CN',
                   DEVICE_ID = NULL
              WHERE DEVICE_ID = :WK_DEVICE 
                AND PICK_LABEL_NO = :WK_LABEL_NO;
           END
        END
        UPDATE PICK_ITEM
        SET  PICK_LINE_STATUS = 'CN',
             DEVICE_ID = NULL
        WHERE DEVICE_ID = :WK_DEVICE 
          AND PICK_LABEL_NO = :WK_LABEL_NO
          AND PICK_LINE_STATUS IN ('AL');
        UPDATE PICK_ITEM_DETAIL
        SET  PICK_DETAIL_STATUS = 'XX'
        WHERE DEVICE_ID = :WK_DEVICE 
          AND PICK_LABEL_NO = :WK_LABEL_NO
          AND PICK_DETAIL_STATUS IN ('PG');
        
      EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'T','Processed successfully');
      EXECUTE PROCEDURE ADD_TRAN(
           :WK_DEVICE,
           '',
           '',
           'PKUA',
           'I',
           :WK_DATE,
           '',
           0,
           'F',
           '',
           'MASTER',
           0,
           '',
           'SSSSSSSSS',
           :WK_USER,
           :WK_DEVICE);
      EXECUTE PROCEDURE TRAN_ARCHIVE;
   END
  END
 END
END ^
 
