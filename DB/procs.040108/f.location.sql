
ALTER PROCEDURE PC_LABEL_LOCATION (REFERENCE VARCHAR(40) CHARACTER SET NONE)
RETURNS (RES INTEGER)
AS 

    
  DECLARE VARIABLE sFilePath VARCHAR(70);
  DECLARE VARIABLE sFilePath2 VARCHAR(70);
  DECLARE VARIABLE sPrinterName CHAR(2);
  DECLARE VARIABLE sRef VARCHAR(40);  
  DECLARE VARIABLE sLabel VARCHAR(256);
  
BEGIN 
  
  /* Get the printer dir */
  sPrinterName = SUBSTR(:REFERENCE,1,2);
  sRef = SUBSTR(:REFERENCE,3,STRLEN(:REFERENCE));
  
  /* Need the directory for this label set */
  SELECT WORKING_DIRECTORY FROM SYS_EQUIP 
  WHERE DEVICE_ID = :sPrinterName
  INTO :sFilePath;
  
  sFilePath2 = sFilePath || 'Location.txt';
       
  sLabel = DQUOTEDSTR(:sRef) || ',' || DQUOTEDSTR(:sPrinterName);
  
  RES = FILE_WRITELN(:sFilePath2, :sLabel);
  if (RES <> 0) then
  begin
     sFilePath2 = sFilePath || 'Location.2xt';
     RES = FILE_WRITELN(:sFilePath2, :sLabel);
  end   

  
END ^

