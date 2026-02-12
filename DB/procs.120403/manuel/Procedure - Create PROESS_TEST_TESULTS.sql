SET TERM ^ ;
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
SET TERM ^
