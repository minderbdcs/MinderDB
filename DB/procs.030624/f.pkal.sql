DROP   TRIGGER RUN_TRANSACTION_PKAL ^
COMMIT^

CREATE TRIGGER RUN_TRANSACTION_PKAL FOR TRANSACTIONS 
ACTIVE AFTER INSERT POSITION 49 
AS
DECLARE VARIABLE WK_AUTORUN INTEGER;
DECLARE VARIABLE WK_PICK_QTY INTEGER;
DECLARE VARIABLE WK_PICK_CNT INTEGER;
DECLARE VARIABLE WK_LABEL VARCHAR(7);
DECLARE VARIABLE WK_DEVICE CHAR(2);
DECLARE VARIABLE WK_USER VARCHAR(10);
DECLARE VARIABLE WK_ORDER VARCHAR(15);
DECLARE VARIABLE WK_ORDER_STATUS CHAR(2);
DECLARE VARIABLE WK_ORDER_START TIMESTAMP;
DECLARE VARIABLE WK_RECORD INTEGER;
DECLARE VARIABLE WK_PI_LABEL VARCHAR(7);
DECLARE VARIABLE WK_PI_SSN VARCHAR(20);
DECLARE VARIABLE WK_PI_PROD VARCHAR(30);
DECLARE VARIABLE WK_PI_WH CHAR(2);
DECLARE VARIABLE WK_PI_LOCN VARCHAR(10);
DECLARE VARIABLE WK_PI_LASTLOCN VARCHAR(10);
DECLARE VARIABLE WK_PI_QTY INTEGER;
DECLARE VARIABLE WK_PI_STATUS CHAR(2);
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
BEGIN
 WK_AUTORUN = GEN_ID(AUTOEXEC_TRANSACTIONS,0); 
 IF (WK_AUTORUN = 1) THEN
 BEGIN
  IF (NEW.TRN_TYPE = 'PKAL') THEN
  BEGIN
     /* get qty to allocate */
     WK_PICK_QTY = 0;
     IF (NEW.QTY = 0) THEN
     BEGIN
        SELECT PICK_ALLOCATE_QTY
            FROM CONTROL
            INTO :WK_PICK_QTY;
     END
     ELSE
     BEGIN
        WK_PICK_QTY = NEW.QTY;
     END
     WK_DEVICE = NEW.WH_ID;
     WK_USER = NEW.PERSON_ID;
     WK_RECORD = NEW.RECORD_ID;
     WK_PICK_TYPE = NEW.TRN_CODE;
     /* want to do wk_qty picks */
     WK_PICK_CNT = 0;
     WHILE (WK_PICK_CNT < WK_PICK_QTY)
     DO
     BEGIN
        FOR 
           SELECT FIRST 5 P1.PICK_LABEL_NO, 
               P1.PICK_ORDER, 
               P2.PICK_STARTED   
           FROM PICK_ITEM P1 
               JOIN PICK_ORDER P2 ON P2.PICK_ORDER = P1.PICK_ORDER 
               LEFT OUTER JOIN ISSN P3 ON P3.SSN_ID = P1.SSN_ID 
           WHERE P1.PICK_LINE_STATUS IN ('OP','CN')
             ORDER BY P2.PICK_PRIORITY, P3.LOCN_ID, P1.PICK_LOCATION 
           INTO :WK_LABEL, :WK_ORDER, :WK_ORDER_START
        DO
        BEGIN
           IF (WK_PICK_CNT < WK_PICK_QTY) THEN
           BEGIN
              WK_PICK_CNT = WK_PICK_CNT + 1;
              UPDATE PICK_ITEM 
                 SET USER_ID = :WK_USER, 
                     DEVICE_ID = :WK_DEVICE, 
                     PICK_LINE_STATUS = 'AL', 
                     PICK_STARTED = 'NOW'
                  WHERE PICK_LABEL_NO = :WK_LABEL;
              IF (WK_ORDER_START IS NULL) THEN
              BEGIN
                 UPDATE PICK_ORDER
                    SET PICK_STARTED = 'NOW',
                        PICK_STATUS = 'PG' 
                     WHERE PICK_ORDER = :WK_ORDER;
              END
           END
        END
     END
     IF (WK_PICK_TYPE = 'B') THEN
     BEGIN
         /* from a browser */
        WK_DIRECTORY = '';
     END
     ELSE
     BEGIN
        WK_DIRECTORY = '';
        SELECT FTP_DIRECTORY
            FROM CONTROL
            INTO :WK_DIRECTORY;
         WK_FILENAME = WK_DIRECTORY || WK_DEVICE || '.pk';
        /* clear devices file */
         WK_RESULT = FILE_DELETE(WK_FILENAME);
         WK_RESULT = FILE_WRITELN(WK_FILENAME, 'DELETE FROM PICK_LOCATIONS');
         WK_RESULT = FILE_WRITELN(WK_FILENAME, 'DELETE FROM PICK_QTYS');
        FOR 
           SELECT PICK_LABEL_NO, 
                  PROD_ID,
                  SSN_ID,
                  PICK_ORDER,
                  PICK_ORDER_QTY,
                  DESPATCH_LOCATION
                  FROM PICK_ITEM
                  WHERE PICK_LINE_STATUS = 'AL'
                    AND DEVICE_ID = :WK_DEVICE
                  INTO :WK_PI_LABEL, :WK_PI_PROD, :WK_PI_SSN, :WK_PI_ORDER, :WK_PI_ORDER_QTY, :WK_PI_DESPATCH_LOCN
        DO
        BEGIN
   /*
   	must get for pick_locations
                  WH_ID,
                  LOCN_ID,
                  QTY_AVAIL,
                  ISSN_STATUS
   	must get for pick_qtys
                  DESCRIPTION
                  UOM
   */
           WK_PI_WH = '';
           WK_PI_LOCN = '';
           WK_PI_LASTLOCN = '';
           WK_PI_QTY = 0;
           WK_PI_STATUS = '';
           WK_PI_DESCRIPTION = '';
           IF (WK_PI_SSN IS NULL) THEN
           BEGIN
              /* a product */
              FOR
              SELECT ISSN.WH_ID, ISSN.LOCN_ID, ISSN.CURRENT_QTY, ISSN.ISSN_STATUS, PROD_PROFILE.SHORT_DESC, ISSN.SSN_ID, PROD_PROFILE.UOM 
              FROM ISSN 
                   JOIN PROD_PROFILE ON PROD_PROFILE.PROD_ID = ISSN.PROD_ID
              WHERE ISSN.PROD_ID = :WK_PI_PROD 
                AND ISSN.WH_ID <> 'XX' AND ISSN.ISSN_STATUS IN ('ST','PA')
              INTO :WK_PI_WH, :WK_PI_LOCN, :WK_PI_QTY, :WK_PI_STATUS, :WK_PI_DESCRIPTION, :WK_PROD_SSN, :WK_UOM
              DO
              BEGIN
                 /* update status */
                 /* UPDATE ISSN SET ISSN_STATUS = 'AL' WHERE SSN_ID = :WK_PROD_SSN; */
                  IF (WK_PI_LASTLOCN = '') THEN
                  BEGIN
                     UPDATE PICK_ITEM SET PICK_LOCATION = :WK_PI_LOCN 
                     WHERE PICK_LABEL_NO = :WK_PI_LABEL; 
                     WK_PI_LASTLOCN = WK_PI_LOCN;
                  END
                 /* add to devices file */
                 WK_LABEL_LINE = 'INSERT INTO PICK_LOCATIONS (PICK_LABEL_NO, PROD_ID , SSN_ID , WH_ID , LOCN_ID , QTY_AVAILABLE , ISSN_STATUS )  VALUES (' ||
                   SQUOTEDSTR(WK_PI_LABEL ) || ',' ||
                   SQUOTEDSTR(WK_PI_PROD ) || ',' ||
                   SQUOTEDSTR(WK_PROD_SSN ) || ',' ||
                   SQUOTEDSTR(WK_PI_WH ) || ',' ||
                   SQUOTEDSTR(WK_PI_LOCN ) || ',' ||
                   SQUOTEDSTR(ALLTRIM(CAST(WK_PI_QTY AS CHAR(6)))) || ',' ||
                   SQUOTEDSTR('AL' ) || ')';
                 WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_LABEL_LINE);
              END
           END
           ELSE
           BEGIN
              /* an ssn */
                 /* update status */
              UPDATE ISSN SET ISSN_STATUS = 'AL' WHERE SSN_ID = :WK_PI_SSN;
              SELECT ISSN.WH_ID, ISSN.LOCN_ID, ISSN.CURRENT_QTY, ISSN.ISSN_STATUS, SSN.SSN_TYPE, 'EA'
              FROM ISSN 
                   JOIN SSN ON SSN.SSN_ID = ISSN.ORIGINAL_SSN
              WHERE ISSN.SSN_ID = :WK_PI_SSN 
              INTO :WK_PI_WH, :WK_PI_LOCN, :WK_PI_QTY, :WK_PI_STATUS, :WK_PI_DESCRIPTION, :WK_UOM;
              UPDATE PICK_ITEM SET PICK_LOCATION = :WK_PI_LOCN 
              WHERE PICK_LABEL_NO = :WK_PI_LABEL; 
              /* add to devices file */
              WK_LABEL_LINE = 'INSERT INTO PICK_LOCATIONS (PICK_LABEL_NO, PROD_ID , SSN_ID , WH_ID , LOCN_ID , QTY_AVAILABLE , ISSN_STATUS )  VALUES (' ||
                SQUOTEDSTR(WK_PI_LABEL ) || ',' ||
                SQUOTEDSTR(WK_PI_PROD ) || ',' ||
                SQUOTEDSTR(WK_PI_SSN ) || ',' ||
                SQUOTEDSTR(WK_PI_WH ) || ',' ||
                SQUOTEDSTR(WK_PI_LOCN ) || ',' ||
                SQUOTEDSTR(ALLTRIM(CAST(WK_PI_QTY AS CHAR(6)))) || ',' ||
                SQUOTEDSTR(WK_PI_STATUS ) || ')';
              WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_LABEL_LINE);
           END
           /* add to devices file */
           WK_LABEL_LINE = 'INSERT INTO PICK_QTYS (PICK_LABEL_NO, PROD_ID , SSN_ID , DESCRIPTION, PICK_ORDER, PICK_ORDER_QTY, UOM, PICK_LINE_STATUS, DESPATCH_LOCATION )  VALUES (' ||
                   SQUOTEDSTR(WK_PI_LABEL ) || ',' ||
                   SQUOTEDSTR(WK_PI_PROD ) || ',' ||
                   SQUOTEDSTR(WK_PI_SSN ) || ',' ||
                   SQUOTEDSTR(WK_PI_DESCRIPTION ) || ',' ||
                   SQUOTEDSTR(WK_PI_ORDER ) || ',' ||
                   SQUOTEDSTR(ALLTRIM(CAST(WK_PI_ORDER_QTY AS CHAR(6)))) || ',' ||
                   SQUOTEDSTR(WK_UOM ) || ',' ||
                   SQUOTEDSTR('AL' ) || ',' ||
                   SQUOTEDSTR(WK_PI_DESPATCH_LOCN ) || ')';
           WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_LABEL_LINE);
        END
     END

   EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'T','Processed successfully');
   EXECUTE PROCEDURE TRAN_ARCHIVE;
  END
 END
END ^
 
