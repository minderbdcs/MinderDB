SET TERM ^ ;

CREATE PROCEDURE ADD_SSN_LEGACY (
  SSN_ID VARCHAR(20),
  LEGACY_ID VARCHAR(20)
)  AS   
      
  DECLARE VARIABLE REC_EXIST INTEGER; 
BEGIN
  REC_EXIST = 0; 
  
  /* Check if record exists */
  SELECT 1
  FROM SSN_LEGACY
  WHERE SSN_ID = :SSN_ID
  AND LEGACY_ID = :LEGACY_ID  
  INTO :REC_EXIST;  

  /* if record exists then no insert */
  IF (REC_EXIST = 0) THEN
  BEGIN 
    INSERT INTO SSN_LEGACY (SSN_ID, LEGACY_ID)
    VALUES (:SSN_ID, :LEGACY_ID);             
  END
END ^
