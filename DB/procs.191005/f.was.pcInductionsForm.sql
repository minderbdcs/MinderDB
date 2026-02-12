COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;

/*
CREATE OR ALTER PROCEDURE PC_INDUCTION_FORM (
  QTY INTEGER,
  PERSON_ID VARCHAR(10)
) RETURNS (
  RES INTEGER
) AS        
*/

CREATE OR ALTER PROCEDURE PC_INDUCTION_FORM (
  QTY INTEGER,
  PERSON_ID PERSON
) RETURNS (
  RES INTEGER
) AS        
  
  DECLARE VARIABLE WK_IGEN INTEGER;    
  DECLARE VARIABLE WK_SFILE_PATH VARCHAR(70);  
  DECLARE VARIABLE WK_SPRINTER_NAME CHAR(2);   
  DECLARE VARIABLE WK_SFORM VARCHAR(256);
  DECLARE VARIABLE WK_SFIRST_FORM_ID VARCHAR(8);  
       
BEGIN 
  
  WK_SPRINTER_NAME = 'PD';
/* where is this set */
  
  /* Need the directory for this label set */
  SELECT WORKING_DIRECTORY FROM SYS_EQUIP 
  WHERE DEVICE_ID = :WK_SPRINTER_NAME
  INTO :WK_SFILE_PATH;
  
  WK_SFILE_PATH = WK_SFILE_PATH || 'Induction.txt';         
  
  /* Get the first Form ID */
  EXECUTE PROCEDURE GET_FORM_NO RETURNING_VALUES :WK_SFIRST_FORM_ID;
  
  /* Resever Form ID with Qty */
  WK_IGEN = GEN_ID(FORM_NO_GEN, :QTY-1);
           
  
  /* Write data to file */
/*
  WK_SFORM = DQUOTEDSTR(:QTY) || ',' ||
          DQUOTEDSTR(:WK_SFIRST_FORM_ID) || ',' ||
          DQUOTEDSTR(:PERSON_ID) || ',' ||
          DQUOTEDSTR(:WK_SPRINTER_NAME);
*/
  WK_SFORM = '"' || :QTY || '","' ||
          :WK_SFIRST_FORM_ID || '","' ||
          :PERSON_ID || '","' ||
          :WK_SPRINTER_NAME || '"';
  
  RES = FILE_WRITELN(:WK_SFILE_PATH, :WK_SFORM);    
  
END^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
