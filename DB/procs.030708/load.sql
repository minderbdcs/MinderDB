ALTER TABLE CONTROL ADD LOAD_PREFIX CHAR(3)^

UPDATE CONTROL SET LOAD_PREFIX = 'RPC'^

ALTER PROCEDURE GET_LOAD_NO RETURNS (LOAD_ID VARCHAR(10) )
AS 

DECLARE VARIABLE iLoadNo INTEGER;
DECLARE VARIABLE iLengthLoadNo INTEGER;
DECLARE VARIABLE sLoadNo VARCHAR(10);
     
BEGIN
  iLoadNo = GEN_ID(LOAD_NO_GEN, 1) ;
  iLengthLoadNo = STRLEN(iLoadNo);
  
  /* Get Load Prefix from Control */
  /* sLoadNo = 'RPC'; */
  SELECT LOAD_PREFIX
  FROM CONTROL
  INTO :sLoadNo;  

  /* Padding leading with 0 */
  WHILE (iLengthLoadNo < 6) DO
  BEGIN
        sLoadNo = sLoadNo || '0';      
        iLengthLoadNo = iLengthLoadNo + 1;
  END
  sLoadNo = sLoadNo || iLoadNo;
  
  /* Return LoadNo to the caller */
  LOAD_ID = sLoadNo;
  
END ^

