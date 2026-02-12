SET TERM ^;
CREATE PROCEDURE PC_LABEL_BARCODE (
  REFERENCE VARCHAR(40)  
) RETURNS (
   RES INTEGER
) AS
    
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
  
  sFilePath2 = sFilePath || 'Barcode.txt';
       
  sLabel = DQUOTEDSTR(:sRef) || ',' || DQUOTEDSTR(:sPrinterName);
  
  RES = FILE_WRITELN(:sFilePath2, :sLabel);
  if (RES <> 0) then
  begin
     sFilePath2 = sFilePath || 'Barcode.2xt';
     RES = FILE_WRITELN(:sFilePath2, :sLabel);
  end   
  
END^

CREATE PROCEDURE PC_LABEL_ISSN (
  REFERENCE VARCHAR(40)  
) RETURNS (
   RES INTEGER
) AS
    
  DECLARE VARIABLE sFilePath VARCHAR(70);
  DECLARE VARIABLE sFilePath2 VARCHAR(70);
  DECLARE VARIABLE sPrinterName CHAR(2);
  DECLARE VARIABLE sRef VARCHAR(40);
  DECLARE VARIABLE sLoadNo VARCHAR(10);
  DECLARE VARIABLE sLabel VARCHAR(256);
  
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
  
  sLabel = DQUOTEDSTR(:sRef) || ',' || DQUOTEDSTR(:sLoadNo) || ',' || 
           DQUOTEDSTR('1') || ',' || DQUOTEDSTR(:sPrinterName);
  
  RES = FILE_WRITELN(:sFilePath2, :sLabel);
  if (RES <> 0) then
  begin
     sFilePath2 = sFilePath || 'ISSN.2xt';
     RES = FILE_WRITELN(:sFilePath2, :sLabel);
  end   

END^

CREATE PROCEDURE PC_LABEL_LOCATION (
  REFERENCE VARCHAR(40)  
) RETURNS (
   RES INTEGER
) AS
    
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
  
  RES = FILE_WRITELN(:sFilePath, :sLabel);
  if (RES <> 0) then
  begin
     sFilePath2 = sFilePath || 'Location.2xt';
     RES = FILE_WRITELN(:sFilePath2, :sLabel);
  end   

  
END^

CREATE PROCEDURE PC_LABEL_PICK (
  REFERENCE VARCHAR(40)  
) RETURNS (
   RES INTEGER
) AS
    
  DECLARE VARIABLE sFilePath VARCHAR(70);
  DECLARE VARIABLE sFilePath2 VARCHAR(70);
  DECLARE VARIABLE sPrinterName CHAR(2);
  DECLARE VARIABLE sRef VARCHAR(40);  
  DECLARE VARIABLE sLabel VARCHAR(256);
  
  DECLARE VARIABLE sPickLabel VARCHAR(7);
  DECLARE VARIABLE iOrderQty INTEGER;
  DECLARE VARIABLE sPickOrder VARCHAR(15);
  DECLARE VARIABLE sPersonId VARCHAR(10);
  DECLARE VARIABLE sProductId VARCHAR(30);
  DECLARE VARIABLE sDesc VARCHAR(50);
  DECLARE VARIABLE sContactName VARCHAR(50);
  DECLARE VARIABLE sAdd1 VARCHAR(50);
  DECLARE VARIABLE sLoc VARCHAR(10);
  
  
  
BEGIN 
  
  /* Get the printer dir */
  sPrinterName = SUBSTR(:REFERENCE,1,2);
  sRef = SUBSTR(:REFERENCE,3,STRLEN(:REFERENCE));
  
  /* Need the directory for this label set */
  SELECT WORKING_DIRECTORY FROM SYS_EQUIP 
  WHERE DEVICE_ID = :sPrinterName
  INTO :sFilePath;
  
  sFilePath2 = sFilePath || 'Pick.txt';
       
  /* Get Pick data */
  SELECT Pick_item.PICK_LABEL_NO,
         Pick_item.PICK_ORDER_QTY,
         Pick_item.PICK_ORDER,
         Pick_order.PERSON_ID,
         Pick_item.PROD_ID,
         Prod_profile.SHORT_DESC,
         Pick_item.CONTACT_NAME,
         Person.ADDRESS_LINE1,
         Pick_item.DESPATCH_LOCATION
    FROM ((PICK_ITEM
         LEFT OUTER JOIN PROD_PROFILE
                      ON Pick_item.PROD_ID = Prod_profile.PROD_ID)
         INNER JOIN PICK_ORDER
                 ON Pick_item.PICK_ORDER = Pick_order.PICK_ORDER)
         LEFT OUTER JOIN PERSON
                      ON Pick_order.PERSON_ID = Person.PERSON_ID
   WHERE Pick_item.PICK_LABEL_NO = :sRef
   INTO :sPickLabel, :iOrderQty, :sPickOrder, :sPersonId, :sProductId,
        :sDesc, :sContactName, :sAdd1, :sLoc;
  
  
  sLabel = DQUOTEDSTR(:sRef) || ',' || 
  	   DQUOTEDSTR(:iOrderQty) || ',' || 
  	   DQUOTEDSTR(:sPickOrder) || ',' || 
  	   DQUOTEDSTR(:sPersonId) || ',' || 
  	   DQUOTEDSTR(:sProductId) || ',' || 
  	   DQUOTEDSTR(:sDesc) || ',' || 
  	   DQUOTEDSTR(:sContactName) || ',' || 
  	   DQUOTEDSTR(:sAdd1) || ',' || 
  	   DQUOTEDSTR(:sLoc) || ',' ||            
  
           DQUOTEDSTR(:sPrinterName);
  
  RES = FILE_WRITELN(:sFilePath2, :sLabel);
  if (RES <> 0) then
  begin
     sFilePath2 = sFilePath || 'Pick.2xt';
     RES = FILE_WRITELN(:sFilePath2, :sLabel);
  end   

  
END^

CREATE PROCEDURE PC_LABEL_SPLIT (
  WH_ID VARCHAR(2),
  PRINTED_BY VARCHAR(10),
  LABEL_NO INTEGER,
  SSN_LENGTH INTEGER,
  PRINTER_NAME VARCHAR(2)
) RETURNS (
  ISSN VARCHAR(20),
  RES INTEGER
) AS         

DECLARE VARIABLE SSN_ID INTEGER;
DECLARE VARIABLE P_SSN_ID INTEGER;
DECLARE VARIABLE W_SSN_ID VARCHAR(20);
DECLARE VARIABLE I_SSN_ID VARCHAR(20);
DECLARE VARIABLE LEN_SSN_ID INTEGER;
DECLARE VARIABLE I_LEN_SSN_ID INTEGER;

DECLARE VARIABLE sFilePath VARCHAR(70);
DECLARE VARIABLE sFilePath2 VARCHAR(70);
DECLARE VARIABLE sLabel VARCHAR(256);

BEGIN          
   SSN_ID = GEN_ID(ISSN_SSN_ID, :LABEL_NO);
   P_SSN_ID = SSN_ID - :LABEL_NO;
   LEN_SSN_ID = STRLEN(P_SSN_ID);     
         
   W_SSN_ID = '';
   /* Padding leading with 0 */
   WHILE (LEN_SSN_ID < :SSN_LENGTH) DO
   BEGIN
      W_SSN_ID = W_SSN_ID || '0';      
      LEN_SSN_ID = LEN_SSN_ID + 1;
   END
   W_SSN_ID = W_SSN_ID || P_SSN_ID;
   
   /* Insert data into SSN table */   
   INSERT INTO SSN (SSN_ID, WH_ID, LOCN_ID, STATUS_SSN, LABEL_DATE, PRINTED_BY)
   VALUES (:W_SSN_ID, :WH_ID, 'NEWLABEL', 'LB', 'NOW', :PRINTED_BY);     
   
   /* Return ISSN value to the caller */
   ISSN = W_SSN_ID;
        
   
   /* Insert data into ISSN table */
   WHILE (P_SSN_ID < SSN_ID) DO
   BEGIN
      I_SSN_ID = '';
      I_LEN_SSN_ID = STRLEN(P_SSN_ID);
      
      /* Padding leading with 0 */
      WHILE (I_LEN_SSN_ID < :SSN_LENGTH) DO
      BEGIN
      	I_SSN_ID = I_SSN_ID || '0';
      	I_LEN_SSN_ID = I_LEN_SSN_ID + 1;
      END
      I_SSN_ID = I_SSN_ID || P_SSN_ID;
      
      INSERT INTO ISSN (SSN_ID, ORIGINAL_SSN, WH_ID, LOCN_ID, ISSN_STATUS)
      VALUES (:I_SSN_ID, :W_SSN_ID, :WH_ID, 'NEWLABEL', 'LB'); 
      
      P_SSN_ID = P_SSN_ID + 1;
   END
   
   /* Export data to text file */    
   
   /* Need the directory for this label set */
   SELECT WORKING_DIRECTORY FROM SYS_EQUIP 
   WHERE DEVICE_ID = :PRINTER_NAME
   INTO :sFilePath;   
   
   sFilePath2 = sFilePath || 'Split.txt';
          
   sLabel = DQUOTEDSTR(:ISSN) || ',' || DQUOTEDSTR(:LABEL_NO) || ',' || 
            DQUOTEDSTR(:PRINTER_NAME);
     
   RES = FILE_WRITELN(:sFilePath2, :sLabel);
  if (RES <> 0) then
  begin
     sFilePath2 = sFilePath || 'Split.2xt';
     RES = FILE_WRITELN(:sFilePath2, :sLabel);
  end   
                
END^

