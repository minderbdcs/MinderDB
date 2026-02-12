
ALTER PROCEDURE PC_ISSN_TRANSFER (SSN_ID CHAR(20) CHARACTER SET NONE,
TO_WH_ID CHAR(2) CHARACTER SET NONE,
TO_LOCN_ID CHAR(10) CHARACTER SET NONE,
UPDATE_SSN CHAR(1) CHARACTER SET NONE,
STATUS CHAR(2) CHARACTER SET NONE)
AS 
     
              
BEGIN   
   /* Update ISSN */
/*
   UPDATE ISSN
   SET WH_ID = :TO_WH_ID,
       PREV_LOCN_ID = LOCN_ID,
       LOCN_ID = :TO_LOCN_ID,
       PREV_DATE = INTO_DATE,
       INTO_DATE = 'NOW',
       ISSN_STATUS = :STATUS
   WHERE SSN_ID = :SSN_ID;
*/
   UPDATE ISSN
   SET WH_ID = :TO_WH_ID,
       PREV_LOCN_ID = LOCN_ID,
       LOCN_ID = :TO_LOCN_ID,
       PREV_DATE = INTO_DATE,
       INTO_DATE = 'NOW'
   WHERE SSN_ID = :SSN_ID;

   /* Update SSN */
   if (:UPDATE_SSN = 'T') then
   begin
/*
     UPDATE SSN
     SET WH_ID = :TO_WH_ID,
         PREV_LOCN_ID = LOCN_ID, 
         LOCN_ID = :TO_LOCN_ID,
         PREV_LOCN_DATE = INTO_DATE,
         INTO_DATE = 'NOW',
         STATUS_SSN = :STATUS
     WHERE SSN_ID = :SSN_ID;
*/
     UPDATE SSN
     SET WH_ID = :TO_WH_ID,
         PREV_LOCN_ID = LOCN_ID, 
         LOCN_ID = :TO_LOCN_ID,
         PREV_LOCN_DATE = INTO_DATE,
         INTO_DATE = 'NOW'
     WHERE SSN_ID = :SSN_ID;
   end
   
END ^

