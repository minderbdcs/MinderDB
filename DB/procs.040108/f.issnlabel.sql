
ALTER PROCEDURE PC_LABEL_ISSN (REFERENCE VARCHAR(40) CHARACTER SET NONE)
RETURNS (RES INTEGER)
AS 

    
  DECLARE VARIABLE sFilePath VARCHAR(70);
  DECLARE VARIABLE sFilePath2 VARCHAR(70);
  DECLARE VARIABLE sPrinterName CHAR(2);
  DECLARE VARIABLE sRef VARCHAR(40);
  DECLARE VARIABLE sLoadNo VARCHAR(10);
  DECLARE VARIABLE sLabel VARCHAR(1020);
  DECLARE VARIABLE sDesc VARCHAR(255);
  
BEGIN 
  
  /* Get the printer dir */
  sPrinterName = SUBSTR(:REFERENCE,1,2);
  sRef = SUBSTR(:REFERENCE,3,STRLEN(:REFERENCE));
  
  /* Need the directory for this label set */
  SELECT WORKING_DIRECTORY FROM SYS_EQUIP 
  WHERE DEVICE_ID = :sPrinterName
  INTO :sFilePath;
  
  sFilePath2 = sFilePath || 'ISSN.txt';
       
  SELECT G.ORDER_NO
  FROM GRN G, SSN S, ISSN I
  WHERE G.GRN = S.GRN
  AND S.SSN_ID = I.ORIGINAL_SSN
  AND I.SSN_ID = :sRef
  INTO :sLoadNo;
  
  SELECT SSN.SSN_DESCRIPTION 
  FROM SSN , ISSN
  WHERE SSN.SSN_ID = ISSN.ORIGINAL_SSN
  AND ISSN.SSN_ID = :sRef
  INTO :sDesc;

  sLabel = DQUOTEDSTR(:sRef) || ',' || DQUOTEDSTR(:sLoadNo) || ',' || 
           DQUOTEDSTR('1') || ',' || DQUOTEDSTR(:sPrinterName) || ',' ||
           DQUOTEDSTR(:sDesc);
  
  RES = FILE_WRITELN(:sFilePath2, :sLabel);
  if (RES <> 0) then
  begin
     sFilePath2 = sFilePath || 'ISSN.2xt';
     RES = FILE_WRITELN(:sFilePath2, :sLabel);
  end   

END ^

