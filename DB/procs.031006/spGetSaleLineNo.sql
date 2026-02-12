/*
ALTER  PROCEDURE GET_SALE_LINES_NO (
*/
CREATE PROCEDURE GET_SALE_LINES_NO (
  PICK_ORDER VARCHAR(10)
) RETURNS (
  PICK_ORDER_LINE_NO VARCHAR(4)
) AS      
 
  DECLARE VARIABLE LINE_NO INTEGER; 
  DECLARE VARIABLE iLenPickLineNo INTEGER;
  DECLARE VARIABLE sPickLineNo VARCHAR(4);

BEGIN
  LINE_NO = 0;
  sPickLineNo = '';

  /* Get the maximum number of line no */
  SELECT LAST_LINE_NO
  FROM PICK_ORDER_ITEM
  WHERE PICK_ORDER = :PICK_ORDER  
  INTO :LINE_NO; 
  
  LINE_NO = LINE_NO + 1;
  
  iLenPickLineNo = STRLEN(LINE_NO);
    
  /* Padding leading with 0 */
    WHILE (iLenPickLineNo < 4) DO
    BEGIN
          sPickLineNo = sPickLineNo || '0';      
          iLenPickLineNo = iLenPickLineNo + 1;
    END
    sPickLineNo = sPickLineNo || LINE_NO;       
    
    /* Return LoadNo to the caller */
   PICK_ORDER_LINE_NO = sPickLineNo;
   
   /* update last line no */
   UPDATE PICK_ORDER_ITEM
   SET LAST_LINE_NO = :LINE_NO
   WHERE PICK_ORDER = :PICK_ORDER; 
      
END^
