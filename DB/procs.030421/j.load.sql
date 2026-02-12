DROP PROCEDURE PC_LABEL_LOAD^
COMMIT^

CREATE PROCEDURE PC_LABEL_LOAD (
  WH_ID VARCHAR(2),
  REFERENCE VARCHAR(40),
  LABEL_NO INTEGER
) RETURNS (
   RES INTEGER
) AS
    
  
  DECLARE VARIABLE iSSN_ID INTEGER;
  DECLARE VARIABLE P_SSN_ID INTEGER;
  DECLARE VARIABLE sORI_SSN_ID VARCHAR(20);
  DECLARE VARIABLE I_SSN_ID VARCHAR(20);
  DECLARE VARIABLE LEN_SSN_ID INTEGER;
  DECLARE VARIABLE I_LEN_SSN_ID INTEGER;
  DECLARE VARIABLE iSSN_LENGTH INTEGER;
  DECLARE VARIABLE iFIRST INTEGER;
  DECLARE VARIABLE sFIRST_SSN_ID VARCHAR(20);
  DECLARE VARIABLE GRN VARCHAR(10);
  DECLARE VARIABLE WK_PO_LINE CHAR(4);
  DECLARE VARIABLE WK_SUPPLIER VARCHAR(10);
  
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
  
  sFilePath2 = sFilePath || 'Load.txt';
       
  /* Get length for Barcode */   
   EXECUTE PROCEDURE GET_BARCODE_LENGTH RETURNING_VALUES iSSN_LENGTH;

  iSSN_ID = GEN_ID(ISSN_SSN_ID, :LABEL_NO);
  P_SSN_ID = iSSN_ID - :LABEL_NO;
  LEN_SSN_ID = STRLEN(P_SSN_ID);
       
   /* Get the first matching SSN */
   SELECT FIRST 1 S.SSN_ID, S.GRN, S.PO_LINE, S.SUPPLIER_ID
   FROM SSN S, GRN G
   WHERE S.GRN = G.GRN
   AND G.ORDER_NO = :sRef
   INTO :sORI_SSN_ID, :GRN, :WK_PO_LINE, :WK_SUPPLIER;
                 
   iFIRST = P_SSN_ID;
   
   /* Insert data into ISSN table */
   WHILE (P_SSN_ID < iSSN_ID) DO
   BEGIN
      I_SSN_ID = '';
      I_LEN_SSN_ID = STRLEN(P_SSN_ID);
      
      /* Padding leading with 0 */
      WHILE (I_LEN_SSN_ID < :iSSN_LENGTH) DO
      BEGIN
      	I_SSN_ID = I_SSN_ID || '0';
      	I_LEN_SSN_ID = I_LEN_SSN_ID + 1;
      END
      I_SSN_ID = I_SSN_ID || P_SSN_ID;
      
      /* Get the first SSNId */
      if (iFIRST = P_SSN_ID) then
      begin
         sFIRST_SSN_ID = I_SSN_ID;
      end
      
/*
      INSERT INTO ISSN (SSN_ID, ORIGINAL_SSN, WH_ID, LOCN_ID)
      VALUES (:I_SSN_ID, :sORI_SSN_ID, :WH_ID, 'RPNEWLABEL'); 
*/
      
      INSERT INTO SSN (SSN_ID, WH_ID, LOCN_ID, GRN, STATUS_SSN, LABEL_DATE, ORIGINAL_QTY,
                 CURRENT_QTY, PO_ORDER, PO_RECEIVE_DATE, PO_LINE, SUPPLIER_ID)
      VALUES (:I_SSN_ID, :WH_ID, 'NEWLABEL', :GRN, 'TS', 'NOW', 1, 1, :sRef, 'NOW', :WK_PO_LINE, :WK_SUPPLIER);     
      INSERT INTO ISSN (SSN_ID, ORIGINAL_SSN, WH_ID, LOCN_ID, CURRENT_QTY,ISSN_STATUS)
      VALUES (:I_SSN_ID, :I_SSN_ID, :WH_ID, 'NEWLABEL', 1, 'TS'); 
      P_SSN_ID = P_SSN_ID + 1;
   END  
     
  
  /* Write data to file */
  sLabel = DQUOTEDSTR(:sFIRST_SSN_ID) || ',' || 
  	   DQUOTEDSTR(:sRef) || ',' ||   	             
  	   DQUOTEDSTR(:LABEL_NO) || ',' ||   	             
  
           DQUOTEDSTR(:sPrinterName);
  
  RES = FILE_WRITELN(:sFilePath2, :sLabel);
  if (RES <> 0) then
  begin
     sFilePath2 = sFilePath || 'Load.2xt';
     RES = FILE_WRITELN(:sFilePath2, :sLabel);
  end   

  
END^

