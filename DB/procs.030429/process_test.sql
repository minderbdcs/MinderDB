
ALTER PROCEDURE PROCESS_TEST_RESULTS (CATEGORY VARCHAR(1),
SSNID VARCHAR(20))
AS 
 

 declare variable strPassCriteria VARCHAR(6);
 declare variable strPassFail VARCHAR(6);
 declare variable intTestID Integer;
 declare variable ProcessFailed Integer;
 declare variable ProcessPassed Integer;
 declare variable strRESPONSE VARCHAR(50);
 declare variable strResult CHAR(1);
 declare variable WK_QUESTION Integer;
BEGIN
  strPassFail = 'PASSED';
  /* Remove this SSN from the Incomlete test list */
     DELETE FROM RESUME_TEST WHERE SSN_ID = :SSNID;
     ProcessFailed = 0;
     ProcessPassed = 0;
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
     do 
     Begin
        if (Category = 'E') then 
        Begin
              UPDATE SSN
              SET OTHER5 = :strResponse
              WHERE SSN_ID = :SSNID;
        end
        ELSE
        BEGIN
            if (strPassCriteria = 'FAILED') then 
            Begin
                StrPassFail = 'FAILED';
                EXECUTE PROCEDURE ADD_PROD_COND_STATUS :SSNID, :Category, :strResponse 
                  RETURNING_VALUES :strResult;
                /* Found at least on record */
                ProcessFailed = 1;
            end
            else
            Begin
                if (strPassCriteria = 'PASSED') then 
                Begin
                    /* Found at least on record */
                    ProcessPassed = 1;
                end
            end
        end
          
        UPDATE SSN_TEST_RESULTS SET PROCESSED = 'P'
        WHERE SSN_TEST_ID = :intTestID;
     End
     
     if (ProcessFailed = 1) then 
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
     ELSE
     BEGIN
             if (ProcessPassed = 1) then 
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
     End
             /* must update passed ssn answer_id = null
                question_id = sequence 0 question for type
             */
             /* get seq 0 question */
             SELECT TQ.QUESTION_ID
                FROM SSN SN 
                     JOIN TEST_QUESTIONS TQ ON TQ.SSN_TYPE = SN.SSN_TYPE
                WHERE SN.SSN_ID = :SSNID
                     AND TQ.SEQUENCE = 0
                INTO :WK_QUESTION;
            UPDATE SSN SET ANSWER_ID = NULL,QUESTION_ID=:WK_QUESTION, STATUS_SSN ='PA' WHERE SSN_ID = :SSNID;
            UPDATE ISSN SET ISSN_STATUS ='PA' WHERE SSN_ID = :SSNID;

END ^

