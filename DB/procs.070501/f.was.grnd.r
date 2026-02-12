        WK_GRN = '';
        WK_OBJECT = NEW.OBJECT;
        WK_AWB = substr(WK_OBJECT,1, 20);
        WK_POSN = POS(:WK_OBJECT,'|',0,1);
        IF (WK_POSN > -1) THEN
        BEGIN
           WK_AWB = SUBSTR(WK_OBJECT, 1, WK_POSN);
           EXECUTE PROCEDURE GET_REFERENCE_FIELD :WK_OBJECT, 2  RETURNING_VALUES :WK_SHIP_DATE2_X ; 
           WK_SHIP_DATE_X = SUBSTR(WK_SHIP_DATE2_X, 1, 4) || '-' ||
           SUBSTR(WK_SHIP_DATE2_X, 5, 6) || '-' ||
           SUBSTR(WK_SHIP_DATE2_X, 7, 8);
        END
        WK_WH_ID = NEW.WH_ID;
        WK_LOCN_ID = NEW.LOCN_ID;
        WK_CARRIER_X = WK_WH_ID || WK_LOCN_ID;
        WK_CARRIER = substr(WK_CARRIER_X,1,10);
        WK_SUBLOCN = NEW.SUB_LOCN_ID;
        WK_VECHICLE = substr(WK_SUBLOCN,1,8);
        WK_REFERENCE = NEW.REFERENCE;
        WK_GRN_TYPE = substr(WK_REFERENCE,1,2);
        EXECUTE PROCEDURE GET_REFERENCE_FIELD :WK_REFERENCE, 2  RETURNING_VALUES :WK_LOADNO ; 
        EXECUTE PROCEDURE GET_REFERENCE_FIELD :WK_REFERENCE, 3  RETURNING_VALUES :WK_LOAD_LINE_NO ; 
        EXECUTE PROCEDURE GET_REFERENCE_FIELD :WK_REFERENCE, 4  RETURNING_VALUES :WK_CONTAINERS ; 
        EXECUTE PROCEDURE GET_REFERENCE_FIELD :WK_REFERENCE, 5  RETURNING_VALUES :WK_OWNER ; 
        EXECUTE PROCEDURE GET_REFERENCE_FIELD :WK_REFERENCE, 6  RETURNING_VALUES :WK_PALLET_QTY_X ; 
        WK_PALLET_QTY = CAST(WK_PALLET_QTY_X AS INTEGER);
        WK_QTY = NEW.QTY;
        WK_USER = NEW.PERSON_ID;
        WK_DEVICE = NEW.DEVICE_ID;
        WK_DATE = NEW.TRN_DATE;
        IF (WK_GRN_TYPE = 'LD') THEN
        BEGIN
           IF (WK_LOADNO = '') THEN
           BEGIN
              EXECUTE PROCEDURE GET_LOAD_NO RETURNING_VALUES :WK_LOADNO;
           END
        END
        IF (WK_POSN > -1) THEN
        BEGIN
           WK_SHIP_DATE = CAST(:WK_SHIP_DATE_X AS TIMESTAMP);
           WHEN SQLCODE -413
           DO
           BEGIN
              /* No Ship date */
              WK_SHIP_DATE = NULL;
           END
        END
        /*
	if the order no is empty
	must calc the next order no to use

	for the screens ?? also have a table
	for companys allowed orders
	with a status
	company
	order
	status

	can I use the purchase_order for this ?? ***
	(ie is the order no on its own unique ??)
	I shall assume that it is
        */
        EXECUTE PROCEDURE ADD_GRN :WK_GRN, :WK_GRN_TYPE, :WK_QTY, '', 
                                  :WK_CARRIER, :WK_VECHICLE, :WK_AWB,
                                  :WK_PALLET_QTY, '', :WK_CONTAINERS,
                                  :WK_OWNER, :WK_USER, :WK_DEVICE,
                                  :WK_DATE, :WK_LOADNO, :WK_LOAD_LINE_NO,
                                  '', '', :WK_SHIP_DATE RETURNING_VALUES :WK_GRN_ID;
/*
        IF (WK_POSN > -1) THEN
        BEGIN
           UPDATE GRN SET SHIPPED_DATE = CAST(:WK_SHIP_DATE_X AS TIMESTAMP)
           WHERE GRN = :WK_GRN_ID;
           WHEN SQLCODE -413
           DO
           BEGIN
              -* No Ship date *-
              WK_SHIP = 0;
           END
        END
*/
        WK_ERROR_TEXT = 'GRN:' || WK_GRN_ID || ':LOAD:' || WK_LOADNO || ':message:' || WK_ERROR_TEXT;

        WK_DIRECTORY = '';
        SELECT FTP_DIRECTORY
           FROM CONTROL
           INTO :WK_DIRECTORY;
        WK_FILENAME = WK_DIRECTORY || WK_DEVICE || '.rp';
        /* clear devices file */
        WK_RESULT = FILE_DELETE(WK_FILENAME);
        WK_RESULT = FILE_WRITELN(WK_FILENAME, WK_ERROR_TEXT); 
        UPDATE TRANSACTIONS SET COMPLETE='T',ERROR_TEXT=:WK_ERROR_TEXT WHERE RECORD_ID = :WK_RECORD;
