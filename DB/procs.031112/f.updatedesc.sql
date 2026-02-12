
ALTER PROCEDURE UPDATE_SSN_DESC AS 
                       

DECLARE VARIABLE sSSN VARCHAR(20);
DECLARE VARIABLE sSSN_DESC VARCHAR(80);

BEGIN    
    
    /* Get SSN to update */
/*
    FOR 
      SELECT SSN_ID, LEFTS(
         ALLTRIM(NONULL(SSN_TYPE)) || ' ' || 
         ALLTRIM(NONULL(GENERIC)) || ' ' || 
         ALLTRIM(NONULL(BRAND)) || ' ' || 
         ALLTRIM(NONULL(MODEL)) || '[' || 
         ALLTRIM(NONULL(SERIAL_NUMBER)) || ']' || 
         ALLTRIM(NONULL(OTHER1) ) || ' ' || 
         ALLTRIM(NONULL(OTHER2) ) || ' ' || 
         ALLTRIM(NONULL(OTHER3) ) || ' ' || 
         ALLTRIM(NONULL(OTHER4) ) || ' ' ||
         ALLTRIM(NONULL(OTHER5) ) || ' ' || 
         ALLTRIM(NONULL(OTHER6) ) || ' ' || 
         ALLTRIM(NONULL(OTHER7) ) || ' ' || 
         ALLTRIM(NONULL(OTHER8) ) || ' ' || 
         ALLTRIM(NONULL(OTHER9) ) || ' ' || 
         ALLTRIM(NONULL(OTHER10)), 80) AS SSN_DESC
      FROM SSN
      WHERE (SSN_DESCRIPTION IS NULL OR SSN_DESCRIPTION = '')
      AND (STATUS_SSN = 'PA' OR STATUS_SSN = 'ST' OR STATUS_SSN = 'TS')
      AND WH_ID <> 'XX'
      INTO :sSSN, :sSSN_DESC
    DO
    BEGIN      
      -* Update SSN Description *-
      UPDATE SSN
      SET SSN_DESCRIPTION = :sSSN_DESC
      WHERE SSN_ID = :sSSN;
              
    END                     
*/
   sSSN = '';
END ^

