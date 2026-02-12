SET TERM ^ ;

ALTER PROCEDURE ADD_MASTER_DATA (TRN_TYPE VARCHAR(4),
TRN_DATE TIMESTAMP,
FIELD_VALUE VARCHAR(30))
AS 
 
  

DECLARE VARIABLE REC_EXIST INTEGER; 
DECLARE VARIABLE strDESC VARCHAR(50);

BEGIN

   REC_EXIST = 0;
   strDESC = "Created during audit " || :TRN_DATE;
   
   /* Check if record exists */ 
   IF (:TRN_TYPE = 'NITP') THEN
   BEGIN   /* SSN Type Table */
     SELECT 1 
     FROM SSN_TYPE
     WHERE CODE = :FIELD_VALUE   
     INTO :REC_EXIST;
   
     IF (REC_EXIST = 0) THEN
     BEGIN
       INSERT INTO SSN_TYPE (CODE, DESCRIPTION)
       VALUES (:FIELD_VALUE, :strDESC); 
     END
   END
   ELSE IF (:TRN_TYPE = 'NIOB') THEN
   BEGIN   /* Generic Table */                           
     SELECT 1 
     FROM GENERIC
     WHERE CODE = :FIELD_VALUE   
     INTO :REC_EXIST;
   
     IF (REC_EXIST = 0) THEN
     BEGIN
       INSERT INTO GENERIC (CODE, DESCRIPTION)
       VALUES (:FIELD_VALUE, :strDESC); 
     END
   END
   ELSE IF (:TRN_TYPE = 'NIBC') THEN
   BEGIN   /* Brand Table */                           
     SELECT 1 
     FROM BRAND
     WHERE CODE = :FIELD_VALUE   
     INTO :REC_EXIST;
      
     IF (REC_EXIST = 0) THEN
     BEGIN
        INSERT INTO BRAND (CODE, DESCRIPTION)
        VALUES (:FIELD_VALUE, :strDESC); 
     END
   END
   ELSE IF (:TRN_TYPE = 'NIMO') THEN
   BEGIN   /* Model Table */                           
     SELECT 1 
     FROM MODEL
     WHERE CODE = :FIELD_VALUE   
     INTO :REC_EXIST;
         
     IF (REC_EXIST = 0) THEN
     BEGIN
        INSERT INTO MODEL (CODE, DESCRIPTION)
        VALUES (:FIELD_VALUE, :strDESC); 
     END
   END
   ELSE IF (:TRN_TYPE = 'NICC') THEN
   BEGIN   /* Cost Center Table */                           
     SELECT 1 
     FROM COST_CENTRE
     WHERE CODE = :FIELD_VALUE   
     INTO :REC_EXIST;
            
     IF (REC_EXIST = 0) THEN
     BEGIN
         INSERT INTO COST_CENTRE (CODE, DESCRIPTION)
         VALUES (:FIELD_VALUE, :strDESC); 
     END
   END
   ELSE IF (:TRN_TYPE = 'NILG') THEN
   BEGIN   /* Legacy Table */                           
     SELECT 1 
     FROM LEGACY
     WHERE LEGACY_ID = :FIELD_VALUE   
     INTO :REC_EXIST;
            
     IF (REC_EXIST = 0) THEN
     BEGIN
         INSERT INTO LEGACY (LEGACY_ID, LEGACY_DESCRIPTION)
         VALUES (:FIELD_VALUE, :strDESC); 
     END
   END   
 
   SUSPEND;
END ^

