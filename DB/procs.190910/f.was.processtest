SET TERM ^ ;
ALTER PROCEDURE ADD_TEST_RESULTS (
    SSN VARCHAR (20),
    TESTTIME DATE,
    QUESTION VARCHAR (70),
    RESPONSE VARCHAR (50),
    NOTES BLOB sub_type 0 segment size 80,
    TEXTRESPONSE VARCHAR (30),
    NUMBERRESPONSE FLOAT,
    DATERESPONSE DATE,
    UPDATEFIELD VARCHAR (30),
    RUNPROCEDURE VARCHAR (30),
    FIELDTYPE INTEGER,
    CATEGORY VARCHAR (1),
    PASS VARCHAR (6),
    ORIGINAL VARCHAR (1),
    USERID VARCHAR(10))
AS
BEGIN

   INSERT INTO ssn_test_results
        (SSN_ID, TIME_STAMP, question, RESPONSE, NOTES, NUMBER_RESPONSE,
         DATE_RESPONSE, FIELD_TYPE, TEXT_RESPONSE, UPDATE_FIELD, RUN_PROCEDURE,
         INSPECT_CATEGORY, INSPECT_PASS_CRITERIA, ORIGINAL_TEST, USER_ID)

   VALUES (:SSN, :TESTTIME, :QUESTION, :RESPONSE,:NOTES, :NUMBERRESPONSE, :DATERESPONSE,
           :FIELDTYPE, :TEXTRESPONSE, :UPDATEFIELD, :RUNPROCEDURE, :CATEGORY, :PASS, :ORIGINAL, :USERID );
           
  SUSPEND;
END
^
CREATE PROCEDURE PROCESS_TEST_RESULTS (
    CATEGORY VARCHAR (1),
    SSNID VARCHAR (20))
AS
 declare variable strPassCriteria VARCHAR(6);
 declare variable strPassFail VARCHAR(6);
 declare variable intTestID Integer;
 declare variable ProcessOK Integer;
BEGIN
  strPassFail = 'PASSED';
     ProcessOK = 0;
     for select
          INSPECT_PASS_CRITERIA,
          SSN_TEST_ID
          from
          SSN_TEST_RESULTS
          where
          INSPECT_CATEGORY = :CATEGORY
          and PROCESSED = 'O'
          And SSN_ID = :SSNID
        into
          :StrPassCriteria, :intTestID
     do Begin
        if (strPassCriteria <> 'PASSED') then
          StrPassFail = 'FAILED';
          
        Update SSN_TEST_RESULTS SET Processed = 'P'
        Where SSN_TEST_ID = :intTestID;
/* Found at least on record */
        ProcessOK = 1;
     End
     
     if (ProcessOK = 1) then Begin
             if (strPassFail = 'PASSED') then
             Begin
                       if (Category = '5') then Begin
                         UPDATE SSN
                         SET OTHER1 = 'AS NEW CONDITION'
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = '4') then Begin
                         UPDATE SSN
                         SET OTHER2 = 'TESTED - OK'
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = '3') then Begin
                         UPDATE SSN
                         SET OTHER3 = 'COMPLETE'
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = '6') then Begin
                         UPDATE SSN
                         SET OTHER4 = ''
                         WHERE SSN_ID = :SSNID;
                       end
             End
             Else Begin
                     if (strPassFail = 'FAILED') then
                     Begin
                       if (Category = '5') then Begin
                         UPDATE SSN
                         SET OTHER1 = 'NOT NEW CONDITION'
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = '4') then Begin
                         UPDATE SSN
                         SET OTHER2 = 'TESTED - FAULTY'
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = '3') then Begin
                         UPDATE SSN
                         SET OTHER3 = 'INCOMPLETE'
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = '6') then Begin
                         UPDATE SSN
                         SET OTHER4 = 'SERVICE PROVIDED'
                         WHERE SSN_ID = :SSNID;
                       end
                     End
             End
     End
     suspend;
END
^
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
