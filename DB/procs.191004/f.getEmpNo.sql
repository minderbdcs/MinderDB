COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;

CREATE OR ALTER PROCEDURE GET_EMP_NO  RETURNS (
  EMPLOYEE_ID PERSON
) AS  
DECLARE VARIABLE WK_EMP_NO_I INTEGER;
DECLARE VARIABLE WK_EMP_NO_LEN INTEGER;
DECLARE VARIABLE WK_EMP_NO_S PERSON;
BEGIN
/*  WK_EMP_NO_I = GEN_ID(EMP_NO_GEN, 1) ; */
  WK_EMP_NO_I = NEXT VALUE FOR EMP_NO_GEN;    
/* WK_EMP_NO_LEN = STRLEN(WK_EMP_NO_I); */
  WK_EMP_NO_LEN = CHAR_LENGTH(WK_EMP_NO_I);
  
/* note hard coded prefix and length */
  /* default prefix */
  WK_EMP_NO_S = 'M7-';
  
  /* Padding leading with 0 */
  WHILE (WK_EMP_NO_LEN < 7) DO
  BEGIN
        WK_EMP_NO_S = WK_EMP_NO_S || '0';      
        WK_EMP_NO_LEN = WK_EMP_NO_LEN + 1;
  END
  WK_EMP_NO_S = WK_EMP_NO_S || WK_EMP_NO_I;
  
  /* Return LoadNo to the caller */
  EMPLOYEE_ID = WK_EMP_NO_S;
  
END^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
