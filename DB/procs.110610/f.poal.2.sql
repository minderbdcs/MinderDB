COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;
 
CREATE OR ALTER TRIGGER RUN_TRANSACTION_POAL FOR TRANSACTIONS 
ACTIVE AFTER INSERT POSITION 152 
AS
/* Transfer of mobile location to an order  */
DECLARE VARIABLE WK_AUTORUN INTEGER;
DECLARE VARIABLE WK_DEVICE CHAR(2);
DECLARE VARIABLE WK_USER VARCHAR(10);
DECLARE VARIABLE WK_RECORD INTEGER;
DECLARE VARIABLE WK_DATE TIMESTAMP;
DECLARE VARIABLE WK_ORDER VARCHAR(30);
DECLARE VARIABLE WK_WH_ID CHAR(2);
DECLARE VARIABLE WK_LOCN_ID VARCHAR(10);
DECLARE VARIABLE WK_REFERENCE VARCHAR(40);

DECLARE VARIABLE WK_ALLOCATE_DEVICE VARCHAR(40);
DECLARE VARIABLE WK_PICK_USER VARCHAR(40);
DECLARE VARIABLE WK_LOCN_GROUP VARCHAR(10);
DECLARE VARIABLE WK_LOCN_MOVEABLE CHAR(1);
DECLARE VARIABLE WK_CURRENT_WH_ID CHAR(2);
DECLARE VARIABLE WK_CURRENT_PARENT VARCHAR(10);
DECLARE VARIABLE WK_TROLLEY_WH_ID CHAR(2);
DECLARE VARIABLE WK_TROLLEY_LOCN_ID VARCHAR(10);
DECLARE VARIABLE WK_ERROR_TEXT VARCHAR(255);
DECLARE VARIABLE WK_FOUND INTEGER;
DECLARE VARIABLE WK_PL_PICK_ORDER  VARCHAR(15);
DECLARE VARIABLE WK_PL_DEVICE_ID   VARCHAR(2);

BEGIN
 WK_AUTORUN = GEN_ID(AUTOEXEC_TRANSACTIONS,0); 
 IF (WK_AUTORUN = 1) THEN
 BEGIN
  IF (NEW.TRN_TYPE = 'POAL') THEN
  BEGIN
     IF (NEW.TRN_CODE = 'O') THEN
     BEGIN
   /*
   transfer mobile location to location of the trolley
   update the order to have that despatch_locn_group (trolley)
   add/update pick_location    for that order to have the location
   */
        WK_WH_ID = NEW.WH_ID;
        WK_LOCN_ID = NEW.LOCN_ID;
        WK_USER = NEW.PERSON_ID;
        WK_DEVICE = NEW.DEVICE_ID;
        WK_DATE = NEW.TRN_DATE;
        WK_RECORD = NEW.RECORD_ID;
        WK_LOCN_GROUP = NEW.SUB_LOCN_ID;
        WK_ORDER = NEW.OBJECT;
        WK_REFERENCE = NEW.REFERENCE;
        WK_ERROR_TEXT = '';
   
        EXECUTE PROCEDURE GET_REFERENCE_FIELD :WK_REFERENCE, 1  RETURNING_VALUES :WK_PICK_USER ; 
        EXECUTE PROCEDURE GET_REFERENCE_FIELD :WK_REFERENCE, 2  RETURNING_VALUES :WK_ALLOCATE_DEVICE ; 
        IF (WK_PICK_USER = '') THEN
        BEGIN
           WK_PICK_USER = WK_USER;
        END
        IF (WK_ALLOCATE_DEVICE = '') THEN
        BEGIN
           WK_ALLOCATE_DEVICE = WK_DEVICE;
        END
        WK_CURRENT_WH_ID = NULL;
        WK_CURRENT_PARENT = NULL;
        WK_LOCN_MOVEABLE = NULL; 
        WK_TROLLEY_WH_ID = NULL;
        WK_TROLLEY_LOCN_ID = NULL;
        /* get mobile  location */
        SELECT CURRENT_WH_ID, PARENT_LOCN_ID, MOVEABLE_LOCN
        FROM LOCATION
        WHERE WH_ID = :WK_WH_ID
        AND   LOCN_ID = :WK_LOCN_ID
        INTO :WK_CURRENT_WH_ID, :WK_CURRENT_PARENT, :WK_LOCN_MOVEABLE;
        IF (WK_LOCN_MOVEABLE = 'T' ) THEN
        BEGIN
           WK_FOUND = 2;
        END
        ELSE
        BEGIN
           /* not a mobile location */
           /* WK_ERROR_TEXT = WK_ERROR_TEXT || ' Location is Not a Moveable Location'; */
           WK_ERROR_TEXT = WK_ERROR_TEXT || ' Location ' || WK_WH_ID || ' ' || WK_LOCN_ID || ' is Not a Moveable Location';
        END
        /* get trolleys fixed location */
        SELECT LOCN_ID 
        FROM SYS_EQUIP
        WHERE DEVICE_ID = :WK_LOCN_GROUP
        INTO :WK_TROLLEY_LOCN_ID;
        IF (WK_TROLLEY_LOCN_ID IS NULL) THEN
        BEGIN
           SELECT DEFAULT_EQUIP_LOCN_ID
           FROM CONTROL
           INTO :WK_TROLLEY_LOCN_ID;
        END
        /* now get the wh_id for the trolley location */
        SELECT FIRST 1 WH_ID 
        FROM LOCATION
        WHERE LOCN_ID = :WK_TROLLEY_LOCN_ID
        INTO :WK_TROLLEY_WH_ID ;
        IF (WK_TROLLEY_WH_ID IS NULL) THEN
        BEGIN
           /* not a trolley location */
           WK_ERROR_TEXT = WK_ERROR_TEXT || ' Trolley has No Fixed WH_ID';
        END
        IF (WK_TROLLEY_LOCN_ID IS NULL) THEN
        BEGIN
           /* not a trolley location */
           WK_ERROR_TEXT = WK_ERROR_TEXT || ' Trolley has No Fixed LOCN_ID';
        END
        BEGIN
           WK_FOUND = 0;
           WK_PL_PICK_ORDER = NULL;
           WK_PL_DEVICE_ID = NULL;
           SELECT FIRST 1 1, PICK_ORDER, DEVICE_ID
           FROM PICK_LOCATION
           WHERE  WH_ID = :WK_WH_ID
           AND LOCN_ID = :WK_LOCN_ID
           AND PICK_LOCATION_STATUS = 'OP'
           INTO :WK_FOUND, :WK_PL_PICK_ORDER, :WK_PL_DEVICE_ID;
           IF (WK_FOUND IS NULL) THEN
           BEGIN
              WK_FOUND = 0;
           END
           IF (WK_FOUND = 1) THEN
           BEGIN
              /* location already in use */
              IF (WK_PL_PICK_ORDER IS NULL) THEN
              BEGIN
                 WK_PL_PICK_ORDER = '';
              END
              IF (WK_PL_DEVICE_ID  IS NULL) THEN
              BEGIN
                 WK_PL_DEVICE_ID  = '';
              END
              IF (WK_PL_DEVICE_ID = :WK_WH_ID ) THEN
              BEGIN
                 /* on this device */
              END
              ELSE
              BEGIN
                 /* WK_ERROR_TEXT = WK_ERROR_TEXT || ' Already in use by ' || WK_PL_PICK_ORDER || ':' || WK_PL_DEVICE_ID ; */
                 WK_ERROR_TEXT = WK_ERROR_TEXT || ' Location ' || WK_WH_ID || ' ' || WK_LOCN_ID || ':' || WK_ORDER || ' Already in use by ' || WK_PL_PICK_ORDER || ':' || WK_PL_DEVICE_ID ;
              END
           END
        END
        IF (WK_ERROR_TEXT = '') THEN
        BEGIN
           /* move the mobile location */
           UPDATE LOCATION
           SET CURRENT_WH_ID = :WK_TROLLEY_WH_ID, PARENT_LOCN_ID = :WK_TROLLEY_LOCN_ID
           WHERE WH_ID = :WK_WH_ID
           AND   LOCN_ID = :WK_LOCN_ID;
           /* update the orders locn group */
           UPDATE PICK_ITEM
           SET DESPATCH_LOCATION_GROUP = :WK_LOCN_GROUP
           WHERE PICK_ORDER = :WK_ORDER
           AND   DEVICE_ID = :WK_ALLOCATE_DEVICE;
           UPDATE PICK_ORDER
           SET DESPATCH_LOCATION_GROUP = :WK_LOCN_GROUP
           WHERE PICK_ORDER = :WK_ORDER;
           WK_FOUND = 0;
           SELECT FIRST 1 1
           FROM PICK_LOCATION
           WHERE WH_ID = :WK_WH_ID
           AND LOCN_ID = :WK_LOCN_ID
           AND PICK_LOCATION_STATUS = 'OP'
           INTO :WK_FOUND;
           IF (WK_FOUND IS NULL) THEN
           BEGIN
              WK_FOUND = 0;
           END
           IF (WK_FOUND = 0) THEN
           BEGIN
              INSERT INTO PICK_LOCATION (
                  PICK_ORDER,            
                  WH_ID,                
                  LOCN_ID,             
                  PICK_LOCATION_STATUS,
                  CREATED_DATE,        
                  CREATED_BY,          
                  LAST_UPDATE_DATE,    
                  LAST_UPDATED_BY,
                  DEVICE_ID)     
              VALUES (
                  :WK_ORDER,
                  :WK_WH_ID,
                  :WK_LOCN_ID,
                  'OP',
                  :WK_DATE,
                  :WK_PICK_USER,
                  :WK_DATE,
                  :WK_PICK_USER, 
                  :WK_ALLOCATE_DEVICE);
           END
           ELSE
           BEGIN
              UPDATE  PICK_LOCATION
              SET 
              LAST_UPDATED_BY = :WK_PICK_USER,
              DEVICE_ID =  :WK_ALLOCATE_DEVICE,
              PICK_ORDER = :WK_ORDER
              WHERE WH_ID = :WK_WH_ID
              AND LOCN_ID = :WK_LOCN_ID 
              AND PICK_LOCATION_STATUS = 'OP';
           END
           EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'T','Processed successfully');
        END
        ELSE
        BEGIN
           EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'F',:WK_ERROR_TEXT);
        END
        /*
        EXECUTE PROCEDURE TRAN_ARCHIVE;
      */
     END /* code O */
     IF (NEW.TRN_CODE = 'U') THEN
     BEGIN
   /*
   remove pick location for the  order and  location passed 
   update pick_location    for that order to not have the location any more
   */
        WK_WH_ID = NEW.WH_ID;
        WK_LOCN_ID = NEW.LOCN_ID;
        WK_USER = NEW.PERSON_ID;
        WK_DEVICE = NEW.DEVICE_ID;
        WK_DATE = NEW.TRN_DATE;
        WK_RECORD = NEW.RECORD_ID;
        WK_LOCN_GROUP = NEW.SUB_LOCN_ID;
        WK_ORDER = NEW.OBJECT;
        WK_REFERENCE = NEW.REFERENCE;
        WK_ERROR_TEXT = '';
   
        EXECUTE PROCEDURE GET_REFERENCE_FIELD :WK_REFERENCE, 1  RETURNING_VALUES :WK_PICK_USER ; 
        EXECUTE PROCEDURE GET_REFERENCE_FIELD :WK_REFERENCE, 2  RETURNING_VALUES :WK_ALLOCATE_DEVICE ; 
        IF (WK_PICK_USER = '') THEN
        BEGIN
           WK_PICK_USER = WK_USER;
        END
        IF (WK_ALLOCATE_DEVICE = '') THEN
        BEGIN
           WK_ALLOCATE_DEVICE = WK_DEVICE;
        END
        IF (WK_ERROR_TEXT = '') THEN
        BEGIN
              UPDATE  PICK_LOCATION
              SET PICK_LOCATION_STATUS = 'CN',
              LAST_UPDATED_BY = :WK_PICK_USER
              WHERE WH_ID = :WK_WH_ID
              AND LOCN_ID = :WK_LOCN_ID 
              AND PICK_LOCATION_STATUS = 'OP' 
              AND DEVICE_ID =  :WK_ALLOCATE_DEVICE
              AND PICK_ORDER = :WK_ORDER;
           EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'T','Processed successfully');
        END
        ELSE
        BEGIN
           EXECUTE PROCEDURE UPDATE_TRAN (WK_RECORD, 'F',:WK_ERROR_TEXT);
        END
        /*
        EXECUTE PROCEDURE TRAN_ARCHIVE;
      */
     END /* code O */
  END
 END
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
