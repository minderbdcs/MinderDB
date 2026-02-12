
ALTER PROCEDURE UPDATE_SSN_TRIL_A (OBJECT VARCHAR(30) ,
WH_ID CHAR(2) ,
LOCN_ID VARCHAR(10) ,
TRN_DATE TIMESTAMP,
QTY INTEGER,
TRN_CODE CHAR(1) )
AS 
 
                                                       
  DECLARE VARIABLE strORIGINAL_SSN VARCHAR(20);
  DECLARE VARIABLE WK_PROD_IS_NULL INTEGER;
  DECLARE VARIABLE last_date TIMESTAMP;
     
BEGIN
   /* Update SSN table */   
         
   SELECT ORIGINAL_SSN, INTO_DATE FROM ISSN 
      WHERE SSN_ID = :OBJECT
      INTO :strORIGINAL_SSN, :last_date;
    IF (last_date IS NULL) THEN
    BEGIN
       last_date = CAST('JAN-01-2000' AS DATE);
    END
   IF (last_date < TRN_DATE) THEN
   BEGIN
      UPDATE ISSN
      SET WH_ID = :WH_ID, LOCN_ID = :LOCN_ID, INTO_DATE = :TRN_DATE,
          CURRENT_QTY = CURRENT_QTY + :QTY
      WHERE SSN_ID = :OBJECT;
      IF (strORIGINAL_SSN = OBJECT) THEN
      BEGIN
         UPDATE SSN
            SET WH_ID = :WH_ID, LOCN_ID = :LOCN_ID, INTO_DATE = :TRN_DATE
         WHERE SSN_ID = :OBJECT;
      END
      IF (TRN_CODE = 'W') THEN
      BEGIN
         WK_PROD_IS_NULL = 0;
         SELECT 1 FROM ISSN 
            WHERE SSN_ID = :OBJECT
              AND PROD_ID IS NULL
            INTO :WK_PROD_IS_NULL;
         IF (WK_PROD_IS_NULL = 1) THEN
         BEGIN
            /* an ssn */
            UPDATE SSN_TYPE 
            SET PUTAWAY_LOCATION = :LOCN_ID
            WHERE CODE IN (SELECT SSN_TYPE FROM SSN WHERE SSN_ID = :strORIGINAL_SSN);
         END
         ELSE
         BEGIN
            /* a product */
            UPDATE PROD_PROFILE
            SET HOME_LOCN_ID = :LOCN_ID
            WHERE PROD_ID IN (SELECT PROD_ID FROM ISSN WHERE SSN_ID = :OBJECT);
         END
      END
   END
   ELSE
   BEGIN
      EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :strORIGINAL_SSN, '', :TRN_CODE, :TRN_DATE,
      'No Update Prior to INTO Date', '', :QTY,  '', '');
   END
END ^

