set term ^;
CREATE PROCEDURE PC_TRLO_TRLI (RECORD_ID INTEGER,
WH_ID CHAR(2),
LOCN_ID VARCHAR(10),
OBJECT VARCHAR(30),
TRN_TYPE VARCHAR(4),
TRN_CODE CHAR(1),
TRN_DATE TIMESTAMP,
REFERENCE VARCHAR(40),
QTY INTEGER,
PERSON_ID VARCHAR(10),
DEVICE_ID CHAR(2))
AS 
  DECLARE VARIABLE strWH_ID CHAR(2);
  DECLARE VARIABLE strLOCN_ID VARCHAR(10);
  DECLARE VARIABLE strAUDIT_DESC VARCHAR(70);
BEGIN
  strAUDIT_DESC = '';
  IF (:TRN_TYPE = 'TRLO') THEN
  BEGIN       
     strWH_ID = '';
     strLOCN_ID = '';
     /* Check transit location */
     SELECT LOCN_ID, WH_ID 
     FROM LOCATION
     WHERE LOCN_ID = :DEVICE_ID
     INTO :strLOCN_ID, :strWH_ID;
     IF (strLOCN_ID = '') THEN /* Transit Location not found */
     BEGIN
        /* Update transactions table */        
        EXECUTE PROCEDURE UPDATE_TRAN (RECORD_ID, 'F', 'Transit Location not found');
        EXIT;
     END
     ELSE
     BEGIN                         
         /* for SSNs in location */
         FOR
           SELECT SSN_ID 
           FROM ISSN
           WHERE LOCN_ID = :LOCN_ID AND WH_ID = :WH_ID
           INTO :OBJECT
         DO
         BEGIN
           /* Update SSN */
           EXECUTE PROCEDURE UPDATE_SSN_TROL_A (OBJECT, strWH_ID, strLOCN_ID, TRN_DATE, DEVICE_ID);
           strAUDIT_DESC = 'Transfered all qty  ' || :QTY || ' into transit location';
           /* Add transaction history */                                                                                     
           EXECUTE PROCEDURE ADD_SSN_HIST(WH_ID, LOCN_ID, OBJECT, TRN_TYPE, TRN_CODE, TRN_DATE,
                                          strAUDIT_DESC, REFERENCE, QTY,  PERSON_ID, DEVICE_ID);
         END /* FOR ISSN */
         /* Update transactions table */               
         EXECUTE PROCEDURE UPDATE_TRAN (RECORD_ID, 'T', 'Processed successfully');
     END /* else */
  END /* TRN_TYPE = 'TRLO' */
  ELSE IF (:TRN_TYPE = 'TRLI') THEN
  BEGIN
     strWH_ID = '';
     strLOCN_ID = '';
     /* Check transit location */
     SELECT LOCN_ID, WH_ID 
     FROM LOCATION
     WHERE LOCN_ID = :DEVICE_ID
     INTO :strLOCN_ID, :strWH_ID;
     IF (strLOCN_ID = '') THEN /* Transit Location not found */
     BEGIN
        /* Update transactions table */        
        EXECUTE PROCEDURE UPDATE_TRAN (RECORD_ID, 'F', 'Transit Location not found');
        EXIT;
     END
     ELSE
     BEGIN                         
         /* for SSNs in location */
         FOR
           SELECT SSN_ID 
           FROM ISSN
           WHERE LOCN_ID = :strLOCN_ID AND WH_ID = :strWH_ID
           INTO :OBJECT
         DO
         BEGIN
          /* Update SSN */
          EXECUTE PROCEDURE UPDATE_SSN_TRIL_A (OBJECT, WH_ID, LOCN_ID, TRN_DATE, QTY);
          strAUDIT_DESC = 'Transfered qty of ' || :QTY || ' into location'; 
          /* Add transaction history */                                                                                     
          EXECUTE PROCEDURE ADD_SSN_HIST(WH_ID, LOCN_ID, OBJECT, TRN_TYPE, TRN_CODE, TRN_DATE,
                                         strAUDIT_DESC, REFERENCE, QTY,  PERSON_ID, DEVICE_ID);
         END /* for */
         /* Update transactions table */               
         EXECUTE PROCEDURE UPDATE_TRAN (RECORD_ID, 'T', 'Processed successfully');
     END /* else */
  END /* TRN_TYPE = 'TRLI' */
END ^

