ALTER PROCEDURE PROCESS_TEST_RESULTS (CATEGORY VARCHAR(1),
SSNID VARCHAR(20))
AS 

 declare variable strPassCriteria VARCHAR(6);
 declare variable strPassFail VARCHAR(6);
 declare variable intTestID Integer;
 declare variable ProcessOK Integer;
 declare variable strRESPONSE VARCHAR(50);
 declare variable strResult CHAR(1);
BEGIN
  strPassFail = 'PASSED';
  /* Remove this SSN from the Incomlete test list */
     DELETE FROM RESUME_TEST WHERE SSN_ID = :SSNID;
     ProcessOK = 0;
     FOR SELECT
          INSPECT_PASS_CRITERIA,
          SSN_TEST_ID,
          RESPONSE
          FROM
          SSN_TEST_RESULTS
          WHERE
          INSPECT_CATEGORY = :CATEGORY
          AND PROCESSED = 'O'
          AND SSN_ID = :SSNID
        INTO
          :StrPassCriteria, :intTestID, :strResponse
     do Begin
        if (strPassCriteria = 'FAILED') then 
	Begin
          StrPassFail = 'FAILED';
          EXECUTE PROCEDURE ADD_PROD_COND_STATUS :SSNID, :Category, :strResponse 
		RETURNING_VALUES :strResult;

        End
          
        UPDATE SSN_TEST_RESULTS SET Processed = 'P'
        WHERE SSN_TEST_ID = :intTestID;
/* Found at least on record */
        ProcessOK = 1;
     End
     
     if (ProcessOK = 1) then Begin
             if (strPassFail = 'PASSED') then
             Begin
                       if (Category = 'A') then Begin
                         UPDATE SSN
                         SET OTHER1 = 'AS NEW CONDITION'
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = 'B') then Begin
                         UPDATE SSN
                         SET OTHER2 = 'TESTED - OK'
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = 'C') then Begin
                         UPDATE SSN
                         SET OTHER3 = 'COMPLETE'
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = 'D') then Begin
                         UPDATE SSN
                         SET OTHER4 = 'NO SERVICING'
                         WHERE SSN_ID = :SSNID;
                       end
             End
             Else Begin
                     if (strPassFail = 'FAILED') then
                     Begin
                       if (Category = 'A') then Begin
                         UPDATE SSN
                         SET OTHER1 = 'NOT NEW CONDITION'
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = 'B') then Begin
                         UPDATE SSN
                         SET OTHER2 = 'TESTED - FAULTY'
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = 'C') then Begin
                         UPDATE SSN
                         SET OTHER3 = 'INCOMPLETE'
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = 'D') then Begin
                         UPDATE SSN
                         SET OTHER4 = 'SERVICE PROVIDED'
                         WHERE SSN_ID = :SSNID;
                       end
                     End
             End
             UPDATE SSN SET STATUS_SSN = 'PA'
             WHERE SSN_ID = :SSNID;
     End
END ^

