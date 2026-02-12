
CREATE PROCEDURE PC_LABEL_PRODUCT (
  REFERENCE VARCHAR(40)  
) RETURNS (
   RES INTEGER
) AS
    
  DECLARE VARIABLE sFilePath VARCHAR(70);
  DECLARE VARIABLE sFilePath2 VARCHAR(70);
  DECLARE VARIABLE sPrinterName CHAR(2);
  DECLARE VARIABLE sRef VARCHAR(40);  
  DECLARE VARIABLE sLabel VARCHAR(256);
  
  DECLARE VARIABLE sSSNId VARCHAR(20);
  DECLARE VARIABLE iCurQty INTEGER;
  DECLARE VARIABLE sProductId VARCHAR(30);    
  DECLARE VARIABLE sDesc VARCHAR(50);  
  DECLARE VARIABLE tLabelDate TIMESTAMP;  
  DECLARE VARIABLE WK_DATE VARCHAR(20);  
  DECLARE VARIABLE WK_TIME VARCHAR(10);  
     
BEGIN 
  
  /* Get the printer dir */
  sPrinterName = SUBSTR(:REFERENCE,1,2);
  sRef = SUBSTR(:REFERENCE,3,STRLEN(:REFERENCE));
  
  /* Need the directory for this label set */
  SELECT WORKING_DIRECTORY FROM SYS_EQUIP 
  WHERE DEVICE_ID = :sPrinterName
  INTO :sFilePath;
  
  sFilePath2 = sFilePath || 'Product.txt';
       
  /* Get Product data */
  SELECT Issn.SSN_ID,
         Issn.CURRENT_QTY,
         Issn.PROD_ID,
         Prod_profile.SHORT_DESC,
         Ssn.LABEL_DATE
  FROM (ISSN
         LEFT OUTER JOIN PROD_PROFILE
                      ON Issn.PROD_ID = Prod_profile.PROD_ID)
         INNER JOIN SSN
                 ON Issn.ORIGINAL_SSN = Ssn.SSN_ID
  WHERE Issn.SSN_ID = :sRef  
  INTO :sSSNId, :iCurQty, :sProductId, :sDesc, :tLabelDate;        
  
  
  WK_DATE = MER_DAY(tLabelDate) || '/' || MER_MONTH(tLabelDate) || '/' || SUBSTR(CAST(MER_YEAR(tLabelDate) AS CHAR(4)) , 3,4);
  WK_TIME = MER_HOUR(tLabelDate) || ':' || MER_MINUTE(tLabelDate) ;
  WK_DATE = WK_DATE || ' ' || WK_TIME;
  sLabel = DQUOTEDSTR(:sRef) || ',' || 
  	   DQUOTEDSTR(:iCurQty) || ',' || 
  	   DQUOTEDSTR(:sProductId) || ',' || 
  	   DQUOTEDSTR(:sDesc) || ',' || 
  	   DQUOTEDSTR( WK_DATE) || ',' ||   	             
           DQUOTEDSTR(:sPrinterName);
  
  RES = FILE_WRITELN(:sFilePath2, :sLabel);
  if (RES <> 0) then
  begin
     sFilePath2 = sFilePath || 'Product.2xt';
     RES = FILE_WRITELN(:sFilePath2, :sLabel);
  end   

  
END^

