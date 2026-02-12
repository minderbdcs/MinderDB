SET TERM ^;

DROP TRIGGER ADD_SSN_FROM_LEGACY^
COMMIT^

CREATE TRIGGER ADD_SSN_FROM_LEGACY FOR LEGACY
ACTIVE BEFORE INSERT POSITION 0 
AS
DECLARE VARIABLE WK_FOUND INTEGER;
DECLARE VARIABLE WK_LEGACY_ID VARCHAR(20); 
DECLARE VARIABLE WK_LEGACY_DESC VARCHAR(202);
DECLARE VARIABLE WK_TYPE VARCHAR(40); 
DECLARE VARIABLE WK_GENERIC VARCHAR(40); 
DECLARE VARIABLE WK_BRAND VARCHAR(40); 
DECLARE VARIABLE WK_MODEL VARCHAR(40); 
DECLARE VARIABLE WK_SERIAL VARCHAR(30); 
DECLARE VARIABLE WK_OTHER1 VARCHAR(50); 
DECLARE VARIABLE WK_OTHER2 VARCHAR(50); 
DECLARE VARIABLE WK_OTHER3 VARCHAR(40); 
DECLARE VARIABLE WK_OTHER4 VARCHAR(40); 
DECLARE VARIABLE WK_OTHER5 VARCHAR(40); 
DECLARE VARIABLE WK_OTHER6 VARCHAR(50); 
DECLARE VARIABLE WK_OTHER7 VARCHAR(50); 
DECLARE VARIABLE WK_OTHER8 VARCHAR(50); 
DECLARE VARIABLE WK_OTHER9 VARCHAR(50); 
DECLARE VARIABLE WK_OTHER10 VARCHAR(50); 
DECLARE VARIABLE WK_STATUS CHAR(2); 
DECLARE VARIABLE WK_P_DATE TIMESTAMP; 
DECLARE VARIABLE WK_P_PRICE FLOAT; 
DECLARE VARIABLE WK_C_DATE TIMESTAMP;
DECLARE VARIABLE WK_A_COST  FLOAT;
DECLARE VARIABLE WK_CC  VARCHAR(40);
DECLARE VARIABLE WK_WH_ID  CHAR(2);
DECLARE VARIABLE WK_GRN  INTEGER;
DECLARE VARIABLE WK_LOAD  VARCHAR(10);
DECLARE VARIABLE WK_IDX  INTEGER;
DECLARE VARIABLE WK_COND_DONE  INTEGER;
DECLARE VARIABLE WK_COND_RESULT  CHAR(1);
DECLARE VARIABLE WK_COND  VARCHAR(200);
BEGIN
   WK_LEGACY_ID  = NEW.LEGACY_ID;
   WK_LEGACY_DESC = ',' || ALLTRIM(NEW.LEGACY_DESCRIPTION) || ',';
   WK_TYPE = NEW.SSN_TYPE;
   WK_GENERIC = NEW.GENERIC;
   WK_BRAND = NEW.BRAND;
   WK_MODEL = NEW.MODEL;
   WK_SERIAL = NEW.SERIAL_NUMBER;
   WK_OTHER1 = NEW.OTHER1;
   WK_OTHER2 = NEW.OTHER2;
   WK_OTHER5 = '';
   WK_OTHER6 = NEW.OTHER6;
   WK_OTHER7 = NEW.OTHER7;
   WK_OTHER8 = NEW.OTHER8;
   WK_OTHER9 = NEW.OTHER9;
   WK_OTHER10 = NEW.OTHER10;
   WK_STATUS = NEW.STATUS;
   WK_P_DATE = NEW.PURCHASE_DATE;
   WK_P_PRICE = NEW.PURCHASE_PRICE;
   WK_C_DATE = NEW.COMMISSIONED_DATE;
   WK_A_COST = NEW.ACQUISITION_COST;
   WK_CC = NEW.COST_CENTER;
   WK_WH_ID = NEW.WH_ID;
   WK_GRN = NEW.GRN;
   WK_LOAD = NEW.LOAD_NO;


   /* Check SSN */
   WK_FOUND = 0;
   SELECT 1 FROM SSN 
      WHERE SSN_ID = :WK_LEGACY_ID
      INTO :WK_FOUND;
   IF (WK_FOUND = 0) THEN
   BEGIN
      /* no ssn so insert it */

      /* calculate other 1 to 4 */
    
      IF (POS(WK_LEGACY_DESC,',AS NEW CONDITION,',0,1) = -1) THEN
      BEGIN
         WK_OTHER1 = 'NOT NEW CONDITION';
      END
      ELSE
      BEGIN
         WK_OTHER1 = 'AS NEW CONDITION';
      END
      IF (POS(WK_LEGACY_DESC,',TESTED - OK,',0,1) = -1) THEN
      BEGIN
         WK_OTHER2 = 'TESTED - FAULTY';
      END
      ELSE
      BEGIN
         WK_OTHER2 = 'TESTED - OK';
      END
      IF (POS(WK_LEGACY_DESC,',COMPLETE,',0,1) = -1) THEN
      BEGIN
         WK_OTHER3 = 'INCOMPLETE';
      END
      ELSE
      BEGIN
         WK_OTHER3 = 'COMPLETE';
      END
      IF (POS(WK_LEGACY_DESC,',NO SERVICE,',0,1) = -1) THEN
      BEGIN
         WK_OTHER4 = 'SERVICE PROVIDED';
      END
      ELSE
      BEGIN
         WK_OTHER4 = 'NO SERVICE';
      END
      /* now must get the list of conditions - to find other 5 */
      WK_IDX = 1;
      WK_COND = ALLTRIM(PARSE(WK_LEGACY_DESC,',',:WK_IDX));
      WHILE (WK_COND <> 'Token to long in parse') DO 
      BEGIN
         WK_COND_DONE = 0;
         IF (LEN(WK_COND) = 0) THEN
         BEGIN
            WK_COND_DONE = 1;
         END
         IF (WK_COND = 'AS NEW CONDITION') THEN
         BEGIN
            WK_COND_DONE = 1;
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            IF (WK_COND = 'TESTED - OK') THEN
            BEGIN
               WK_COND_DONE = 1;
            END
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            IF (WK_COND = 'COMPLETE') THEN
            BEGIN
               WK_COND_DONE = 1;
            END
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            IF (WK_COND = 'NO SERVICE') THEN
            BEGIN
               WK_COND_DONE = 1;
            END
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            IF (SUBSTR(WK_COND,1,2) = 'SV') THEN
            BEGIN
               /* add to prod cond class D */
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'D', :WK_COND , 'O'
                  RETURNING_VALUES :WK_COND_RESULT;
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'D', :WK_COND , 'S'
                  RETURNING_VALUES :WK_COND_RESULT;
               WK_COND_DONE = 1;
            END
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            IF (SUBSTR(WK_COND,1,7) = 'MISSING') THEN
            BEGIN
               /* add to prod cond class C */
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'C', :WK_COND , 'O'
                  RETURNING_VALUES :WK_COND_RESULT;
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'C', :WK_COND , 'S'
                  RETURNING_VALUES :WK_COND_RESULT;
               WK_COND_DONE = 1;
            END
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            IF (SUBSTR(WK_COND,1,7) = 'DAMAGED') THEN
            BEGIN
               /* add to prod cond class C */
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'C', :WK_COND , 'O'
                  RETURNING_VALUES :WK_COND_RESULT;
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'C', :WK_COND , 'S'
                  RETURNING_VALUES :WK_COND_RESULT;
               WK_COND_DONE = 1;
            END
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            IF (SUBSTR(WK_COND,1,6) = 'FAULTY') THEN
            BEGIN
               /* add to prod cond class B */
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'B', :WK_COND , 'O'
                  RETURNING_VALUES :WK_COND_RESULT;
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'B', :WK_COND , 'S'
                  RETURNING_VALUES :WK_COND_RESULT;
               WK_COND_DONE = 1;
            END
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            IF (WK_COND = 'NOT-TESTED') THEN
            BEGIN
               /* add to prod cond class B */
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'B', :WK_COND , 'O'
                  RETURNING_VALUES :WK_COND_RESULT;
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'B', :WK_COND , 'S'
                  RETURNING_VALUES :WK_COND_RESULT;
               WK_COND_DONE = 1;
            END
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            IF (WK_COND = 'TESTED FAULTY') THEN
            BEGIN
               /* add to prod cond class B */
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'B', :WK_COND , 'O'
                  RETURNING_VALUES :WK_COND_RESULT;
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'B', :WK_COND , 'S'
                  RETURNING_VALUES :WK_COND_RESULT;
               WK_COND_DONE = 1;
            END
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            IF (WK_COND = 'TESTED-FAULTY') THEN
            BEGIN
               /* add to prod cond class B */
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'B', :WK_COND , 'O'
                  RETURNING_VALUES :WK_COND_RESULT;
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'B', :WK_COND , 'S'
                  RETURNING_VALUES :WK_COND_RESULT;
               WK_COND_DONE = 1;
            END
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            IF (POS(WK_COND,'DAMAGE',0,1) > -1) THEN
            BEGIN
               /* add to prod cond class B */
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'B', :WK_COND , 'O'
                  RETURNING_VALUES :WK_COND_RESULT;
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'B', :WK_COND , 'S'
                  RETURNING_VALUES :WK_COND_RESULT;
               WK_COND_DONE = 1;
            END
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            IF (POS(WK_COND,'-COA',0,1) > -1) THEN
            BEGIN
               /* other 5 */
               WK_OTHER5 = WK_COND;
               WK_COND_DONE = 1;
            END
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            IF (RIGHTS(WK_COND,3) = '-CD') THEN
            BEGIN
               /* other 5 */
               WK_OTHER5 = WK_COND;
               WK_COND_DONE = 1;
            END
         END
         IF (WK_COND_DONE = 0) THEN
         BEGIN
            BEGIN
               /* add to prod cond class A */
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'A', :WK_COND , 'O'
                  RETURNING_VALUES :WK_COND_RESULT;
               EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :WK_LEGACY_ID, 'A', :WK_COND , 'S'
                  RETURNING_VALUES :WK_COND_RESULT;
               WK_COND_DONE = 1;
            END
         END
         WK_IDX = WK_IDX + 1;
         WK_COND = ALLTRIM(PARSE(WK_LEGACY_DESC,',',:WK_IDX));
      END

      INSERT INTO SSN (SSN_ID, WH_ID, LOCN_ID, GRN, STATUS_SSN, 
             ORIGINAL_QTY, CURRENT_QTY, PO_ORDER, 
             PO_RECEIVE_DATE, SSN_TYPE, GENERIC, BRAND, MODEL, 
             SERIAL_NUMBER, OTHER6, OTHER7, OTHER8, OTHER9, OTHER10,
             STORAGE_UOM, OTHER1, OTHER2, OTHER3, OTHER4, OTHER5, LEGACY_ID )
      VALUES (:WK_LEGACY_ID, :WK_WH_ID, 'INTRANST', :WK_GRN, 'TS', 1, 1,
              :WK_LOAD, 'NOW', :WK_TYPE, :WK_GENERIC, :WK_BRAND, 
              :WK_MODEL, :WK_SERIAL, :WK_OTHER6, :WK_OTHER7, :WK_OTHER8,
              :WK_OTHER9, :WK_OTHER10, 'EA' , :WK_OTHER1, :WK_OTHER2, :WK_OTHER3, :WK_OTHER4, :WK_OTHER5, :WK_LEGACY_ID);
      NEW.STATUS = 'T'; 
   END
   /* Check issn */
   WK_FOUND = 0;
   SELECT 1 FROM ISSN
      WHERE SSN_ID = :WK_LEGACY_ID
      INTO :WK_FOUND;
   IF (WK_FOUND = 0) THEN
   BEGIN
      /* no issn so insert it */
      INSERT INTO ISSN (SSN_ID, ORIGINAL_SSN, WH_ID, LOCN_ID, CURRENT_QTY,ISSN_STATUS)
      VALUES (:WK_LEGACY_ID, :WK_LEGACY_ID, :WK_WH_ID, 'INTRANST', 1, 'TS'); 
   END
   ELSE
   BEGIN
      UPDATE ISSN SET 
        ORIGINAL_SSN = :WK_LEGACY_ID 
      WHERE SSN_ID = :WK_LEGACY_ID;
   END
END ^
 
