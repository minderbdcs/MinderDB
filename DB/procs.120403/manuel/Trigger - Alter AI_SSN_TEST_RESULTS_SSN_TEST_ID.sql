SET TERM ^ ;
alter trigger AI_SSN_TEST_RESULTS_SSN_TEST_ID
ACTIVE Before Insert position 0
AS
BEGIN
  IF (NEW.SSN_TEST_ID IS NULL) THEN
      NEW.SSN_TEST_ID = GEN_ID(SSN_TEST_ID_GEN, 1);
/* Ensure that this record is processed in the PROCESS_TEST_RESULTS procedure
   if there is no criteria to process */
  if (NEW.inspect_pass_criteria = '') then
    NEW.processed = 'X';
  Else
    New.processed = 'O';
END
^
SET TERM ; ^
