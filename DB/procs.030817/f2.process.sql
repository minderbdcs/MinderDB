
ALTER PROCEDURE PROCESS_TEST_RESULTS (CATEGORY VARCHAR(1) ,
SSNID VARCHAR(20) )
AS 
 
 
 

 DECLARE VARIABLE strPassCriteria VARCHAR(6);
 DECLARE VARIABLE strPassFail VARCHAR(6);
 DECLARE VARIABLE intTestID Integer;
 DECLARE VARIABLE ProcessFailed Integer;
 DECLARE VARIABLE ProcessPassed Integer;
 DECLARE VARIABLE strRESPONSE VARCHAR(50);
 DECLARE VARIABLE strTextResponse VARCHAR(30);
 DECLARE VARIABLE numNumResponse FLOAT;
 DECLARE VARIABLE dateDateResponse TIMESTAMP;
 DECLARE VARIABLE numFieldType Integer;
 DECLARE VARIABLE strResult CHAR(1);
 DECLARE VARIABLE WK_QUESTION Integer;
 DECLARE VARIABLE wkOriginal varchar(1);
 DECLARE VARIABLE WK_TEST_EXISTS INTEGER;
 DECLARE VARIABLE WK_TEST_ID INTEGER;
 DECLARE VARIABLE wkTestID  INTEGER;
 DECLARE VARIABLE WK_WHEN  TIMESTAMP;
 DECLARE VARIABLE strDesc VARCHAR(30);
BEGIN
  strPassFail = 'PASSED';
  /* Remove this SSN from the Incomlete test list */
     DELETE FROM RESUME_TEST WHERE SSN_ID = :SSNID;
     ProcessFailed = 0;
     ProcessPassed = 0;
     wkTestID = -1;
     FOR SELECT
          INSPECT_PASS_CRITERIA,
          SSN_TEST_ID,
          RESPONSE,
          TEXT_RESPONSE,
          NUMBER_RESPONSE,
          DATE_RESPONSE,
          FIELD_TYPE,
          ORIGINAL_TEST,
          TEST_ID,
          TIME_STAMP
          FROM
          SSN_TEST_RESULTS
          WHERE
          SSN_ID = :SSNID
          AND INSPECT_CATEGORY = :CATEGORY
          AND PROCESSED = 'O'
        INTO
          :StrPassCriteria, :intTestID, :strResponse, :strTextResponse, :numNumResponse, :dateDateResponse, :numFieldType , :wkOriginal, :wkTestID, :WK_WHEN
     do 
     Begin
        IF (wkTestID = -1) THEN
        BEGIN
          WK_TEST_EXISTS = 0;
          SELECT 1, TEST_ID FROM SSN_TEST
              WHERE SSN_ID = :SSNID AND
                    STATUS_TEST = 'OP'
              INTO :WK_TEST_EXISTS, :WK_TEST_ID;
          IF (WK_TEST_EXISTS = 0) THEN
          BEGIN
              /* must get the next test id */
              WK_TEST_ID = GEN_ID(TEST_ID, 1);
              INSERT INTO SSN_TEST(TEST_ID, SSN_ID, START_DATE, STATUS_TEST)
                     VALUES (:WK_TEST_ID, :SSNID, :WK_WHEN, 'OP');
          END 
          wkTestID = WK_TEST_ID;
        END 
/*
        if (numFieldType = 1) then
        BEGIN
  -* memo type *-
        END
*/
        if (numFieldType = 2) then
        BEGIN
  /* number type */
  strResponse = numNumResponse;
        END
        if (numFieldType = 3) then
        BEGIN
  /* date type */
  strResponse = cast(:dateDateResponse as char(22));
        END
        if (numFieldType = 4) then
        BEGIN
  /* text type */
  strResponse = strTextResponse;
        END

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
                EXECUTE PROCEDURE ADD_PROD_COND_STATUS_TEST :SSNID, :Category, :strResponse, :wkOriginal 
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
          
        UPDATE SSN_TEST_RESULTS SET PROCESSED = 'P', TEST_ID = :wkTestID
        WHERE SSN_TEST_ID = :intTestID;
        wkTestID = -1;
     End
     
     if (ProcessFailed = 1) then 
     Begin
                       if (Category = 'A') then Begin
                         EXECUTE PROCEDURE GET_GLOBAL_CONDITION 1, 'F' RETURNING_VALUES :strDesc;
                         UPDATE SSN
                         /*SET OTHER1 = 'NOT NEW CONDITION'*/
                         SET OTHER1 = :strDesc
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = 'B') then Begin
                         EXECUTE PROCEDURE GET_GLOBAL_CONDITION 2, 'F' RETURNING_VALUES :strDesc;
                         UPDATE SSN
                         /*SET OTHER2 = 'TESTED - FAULTY'*/
                         SET OTHER2 = :strDesc
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = 'C') then Begin
                         EXECUTE PROCEDURE GET_GLOBAL_CONDITION 3, 'F' RETURNING_VALUES :strDesc;
                         UPDATE SSN
                         /*SET OTHER3 = 'INCOMPLETE'*/
                         SET OTHER3 = :strDesc
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = 'D') then Begin
                         EXECUTE PROCEDURE GET_GLOBAL_CONDITION 4, 'F' RETURNING_VALUES :strDesc;
                         UPDATE SSN
                         /*SET OTHER4 = 'SERVICE PROVIDED'*/
                         SET OTHER4 = :strDesc
                         WHERE SSN_ID = :SSNID;
                       end
     End
     ELSE
     BEGIN
             if (ProcessPassed = 1) then 
             Begin
                       if (Category = 'A') then Begin
                         EXECUTE PROCEDURE GET_GLOBAL_CONDITION 1, 'P' RETURNING_VALUES :strDesc;
                         UPDATE SSN
                         /*SET OTHER1 = 'AS NEW CONDITION'*/
                         SET OTHER1 = :strDesc
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = 'B') then Begin
                         EXECUTE PROCEDURE GET_GLOBAL_CONDITION 2, 'P' RETURNING_VALUES :strDesc;
                         UPDATE SSN
                         /*SET OTHER2 = 'TESTED - OK'*/
                         SET OTHER2 = :strDesc
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = 'C') then Begin
                         EXECUTE PROCEDURE GET_GLOBAL_CONDITION 3, 'P' RETURNING_VALUES :strDesc;
                         UPDATE SSN
                         /*SET OTHER3 = 'COMPLETE'*/
                         SET OTHER3 = :strDesc
                         WHERE SSN_ID = :SSNID;
                       end
                       if (Category = 'D') then Begin
                         EXECUTE PROCEDURE GET_GLOBAL_CONDITION 4, 'P' RETURNING_VALUES :strDesc;
                         UPDATE SSN
                         /*SET OTHER4 = 'NO SERVICE'*/
                         SET OTHER4 = :strDesc
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
            UPDATE SSN_TEST SET STATUS_TEST = 'CL',END_DATE='NOW' 
                WHERE SSN_ID=:SSNID AND STATUS_TEST = 'OP';

END ^

