COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;

ALTER PROCEDURE RPT_BUSINESS_MONTHLY_2_DATA 
(
  THISCOMPANY VARCHAR(20),
  THISSTART TIMESTAMP,
  THISEND TIMESTAMP
)
RETURNS
(
  WH_ID1 VARCHAR(30),
  LOCN_ID1 VARCHAR(30),
  LOC_QTY_1 INTEGER,
  WH_ID2 VARCHAR(30),
  LOCN_ID2 VARCHAR(30),
  LOC_QTY_2 INTEGER,
  PROD_ID VARCHAR(30),
  DESCRIPTION VARCHAR(50)
)
AS
   DECLARE VARIABLE    WK_WH_ID    CHAR(2);
   DECLARE VARIABLE    WK_LOCN_ID  VARCHAR(10);
   DECLARE VARIABLE    WK_SSN_ID   VARCHAR(30); 
   DECLARE VARIABLE    WK_QTY      INTEGER;
   DECLARE VARIABLE    WK_PROD_ID  VARCHAR(30);
   DECLARE VARIABLE    WK_DESC1    VARCHAR(50);
   DECLARE VARIABLE    WK_DESC2    VARCHAR(50);
   DECLARE VARIABLE    WK_TRNTYPE  VARCHAR(4);
   DECLARE VARIABLE    WK_TRNCODE  CHAR(1);
   DECLARE VARIABLE    WK_HAVE_DATA  CHAR(1);
   DECLARE VARIABLE    WK_FIRST_DATA  CHAR(1);
   DECLARE VARIABLE    WK_CURRENT_FROM_WH_ID  CHAR(2);
   DECLARE VARIABLE    WK_CURRENT_FROM_LOCN_ID  VARCHAR(10);
   DECLARE VARIABLE    WK_CURRENT_PROD_ID  VARCHAR(30);
   DECLARE VARIABLE    WK_CURRENT_DESC  VARCHAR(50);
   DECLARE VARIABLE    WK_CURRENT_TO_WH_ID  CHAR(2);
   DECLARE VARIABLE    WK_CURRENT_TO_LOCN_ID  VARCHAR(10);
   DECLARE VARIABLE    WK_CURRENT_FROM_QTY  INTEGER;
   DECLARE VARIABLE    WK_CURRENT_TO_QTY  INTEGER;
   DECLARE VARIABLE    WK_COMP1  VARCHAR(20);
   DECLARE VARIABLE    WK_COMP2  VARCHAR(20);
   DECLARE VARIABLE    WK_SSN_ID2  VARCHAR(20);
   DECLARE VARIABLE    WK_PROD_ID2  VARCHAR(30);
   DECLARE VARIABLE    WK_PROD_ID3  VARCHAR(30);
   DECLARE VARIABLE    WK_CHANGE  VARCHAR(10);
   DECLARE VARIABLE    WK_DUMMY  CHAR(1);
   DECLARE VARIABLE    WK_DEVICE  VARCHAR(3);
   DECLARE VARIABLE    WK_LAST_FROM_WH_ID  CHAR(2);
   DECLARE VARIABLE    WK_LAST_FROM_LOCN_ID  VARCHAR(10);
   DECLARE VARIABLE    WK_LAST_TO_WH_ID  CHAR(2);
   DECLARE VARIABLE    WK_LAST_TO_LOCN_ID  VARCHAR(10);
   DECLARE VARIABLE    WK_LAST_FROM_QTY  INTEGER;
   DECLARE VARIABLE    WK_LAST_TO_QTY  INTEGER;
   DECLARE VARIABLE    WK_TRANSFER_QTY      INTEGER;
   DECLARE VARIABLE    WK_REC_ID      INTEGER;
   DECLARE VARIABLE    WK_FOUND      INTEGER;

BEGIN
  /* PROCEDURE BODY */
  WK_HAVE_DATA = 'N';
  WK_FIRST_DATA = 'Y';
  PROD_ID = '';
  WH_ID1 = '';
  LOCN_ID1 = '';
  LOC_QTY_1 = 0;
  WH_ID2 = '';
  LOCN_ID2 = '';
  LOC_QTY_2 = 0;
  DESCRIPTION = '';
  WK_CURRENT_PROD_ID = '';
  WK_CURRENT_FROM_QTY = 0;
  WK_CURRENT_FROM_WH_ID = '';
  WK_CURRENT_FROM_LOCN_ID = '';
  WK_CURRENT_TO_QTY = 0;
  WK_CURRENT_TO_WH_ID = '';
  WK_CURRENT_TO_LOCN_ID = '';
  WK_LAST_FROM_QTY = 0;
  WK_LAST_FROM_WH_ID = '';
  WK_LAST_FROM_LOCN_ID = '';
  WK_LAST_TO_QTY = 0;
  WK_LAST_TO_WH_ID = '';
  WK_LAST_TO_LOCN_ID = '';
  WK_REC_ID = GEN_ID(TRANSACTION_ID, 1);    
  /*  LEFT OUTER JOIN PROD_PROFILE P2 ON P2.PROD_ID = SSN_HIST.SSN_ID 
       P2.SHORT_DESC,
       P2.COMPANY_ID,
       P2.PROD_ID,
     (P2.COMPANY_ID = :THISCOMPANY AND P2.COMPANY_ID IS NOT NULL) ) */
  FOR
    SELECT SSN_HIST.TRN_TYPE, 
       SSN_HIST.TRN_CODE,
       SSN_HIST.WH_ID ,
       SSN_HIST.LOCN_ID ,
       SSN_HIST.SSN_ID , 
       ISSN.CURRENT_QTY,
       ISSN.PROD_ID,
       P1.SHORT_DESC,
       P1.COMPANY_ID,
       ISSN.SSN_ID,
       P1.PROD_ID,
       SSN_HIST.DEVICE_ID,
       SSN_HIST.QTY
    FROM SSN_HIST
    LEFT OUTER JOIN ISSN ON ISSN.SSN_ID = SSN_HIST.SSN_ID 
    LEFT OUTER JOIN PROD_PROFILE P1 ON P1.PROD_ID = ISSN.PROD_ID
    WHERE SSN_HIST.TRN_TYPE IN ('TROL','TRLO','TRIL','TRLI') AND
    SSN_HIST.TRN_CODE IN ('A','P') AND 
    (SSN_HIST.TRN_DATE BETWEEN ZEROTIME(:THISSTART) AND MAXTIME(:THISEND)) AND
    (P1.COMPANY_ID = :THISCOMPANY AND P1.COMPANY_ID IS NOT NULL) 

    ORDER BY SSN_HIST.DEVICE_ID, ISSN.PROD_ID, ISSN.ORIGINAL_SSN, SSN_HIST.TRN_DATE 
/* need sorting by prod, device and date 
   ie device before ssn_hist.ssn_id except when ssn_id is a product 
   so must use the transactions_work for this
*/

  INTO
:WK_TRNTYPE,
:WK_TRNCODE,
:WK_WH_ID,
:WK_LOCN_ID,
:WK_SSN_ID,
:WK_QTY,
:WK_PROD_ID,
:WK_DESC1,
:WK_COMP1,
:WK_SSN_ID2,
:WK_PROD_ID2,
:WK_DEVICE,
:WK_TRANSFER_QTY
 
  DO
  BEGIN
/*
    insert into log(description) values ('WH' || :WK_WH_ID || 'LOCN' || :WK_LOCN_ID || ' type ' || :WK_TRNTYPE || ' code ' || :WK_TRNCODE || ' ssn ' || :WK_SSN_ID || ' device ' || :WK_DEVICE);
    insert into log(description) values ('comp' || :WK_COMP1);
    insert into log(description) values ('comp2' || :WK_COMP2);
    insert into log(description) values ('ssn2' || :WK_SSN_ID2);
    insert into log(description) values ('prod2' || :WK_PROD_ID);
    insert into log(description) values ('prod3' || :WK_PROD_ID2);
    insert into log(description) values ('prod4' || :WK_PROD_ID3);
*/
     /* needs
     on change of product set from and to wh & locn = ''
     if either is '' at a suspend stage must not write yet
     */
     /* IF (WK_COMP1 = :THISCOMPANY OR WK_COMP2 = :THISCOMPANY) THEN */
     BEGIN
        WK_HAVE_DATA = 'Y';

        IF (WK_TRNTYPE = 'TROL' OR WK_TRNTYPE = 'TRLO') THEN
        BEGIN
           WK_LAST_FROM_WH_ID = WK_CURRENT_FROM_WH_ID;
           WK_LAST_FROM_LOCN_ID = WK_CURRENT_FROM_LOCN_ID;
           WK_LAST_FROM_QTY = WK_CURRENT_FROM_QTY;
           WK_CURRENT_FROM_WH_ID = WK_WH_ID;
           WK_CURRENT_FROM_LOCN_ID = WK_LOCN_ID;
           WK_CURRENT_FROM_QTY = WK_CURRENT_FROM_QTY + WK_TRANSFER_QTY;
           WK_CHANGE = 'FROM';
           WK_LAST_TO_WH_ID = WK_CURRENT_TO_WH_ID;
           WK_LAST_TO_LOCN_ID = WK_CURRENT_TO_LOCN_ID;
           WK_LAST_TO_QTY = WK_CURRENT_TO_QTY;
           WK_CURRENT_TO_WH_ID = '';
           WK_CURRENT_TO_LOCN_ID = '';
           WK_CURRENT_TO_QTY = 0;
    /* insert into log(description) values ('changed from'); */

        END
        IF (WK_TRNTYPE = 'TRIL' OR WK_TRNTYPE = 'TRLI') THEN
        BEGIN
           WK_LAST_TO_WH_ID = WK_CURRENT_TO_WH_ID;
           WK_LAST_TO_LOCN_ID = WK_CURRENT_TO_LOCN_ID;
           WK_LAST_TO_QTY = WK_CURRENT_TO_QTY;
           WK_CURRENT_TO_WH_ID = WK_WH_ID;
           WK_CURRENT_TO_LOCN_ID = WK_LOCN_ID;
           WK_CURRENT_TO_QTY = WK_CURRENT_TO_QTY + WK_TRANSFER_QTY;
           WK_CHANGE = 'TO';
    /* insert into log(description) values ('changed to'); */
        END
/*
        IF (WK_TRNTYPE = 'TROL' AND WK_TRNCODE = 'P') THEN
        BEGIN
           -* here the ssn_id is the product *-
           WK_CURRENT_PROD_ID = WK_SSN_ID;
           WK_CURRENT_DESC = WK_DESC2;
        END
        ELSE
*/
        BEGIN
           /* here the ssn_id is the issns ssn */
           WK_CURRENT_PROD_ID = WK_PROD_ID;
           WK_CURRENT_DESC = WK_DESC1;
        END
        IF (WK_FIRST_DATA  = 'Y') THEN
        BEGIN
           PROD_ID = WK_CURRENT_PROD_ID;
           WH_ID1 = WK_CURRENT_FROM_WH_ID;
           LOCN_ID1 = WK_CURRENT_FROM_LOCN_ID;
           WH_ID2 = WK_CURRENT_TO_WH_ID;
           LOCN_ID2 = WK_CURRENT_TO_LOCN_ID;
           DESCRIPTION = WK_CURRENT_DESC;
           LOC_QTY_1 = 0;
           LOC_QTY_2 = 0;
           WK_FIRST_DATA = 'N';
    /* insert into log(description) values ('first data'); */
        END
        IF ((WK_CURRENT_PROD_ID <> PROD_ID) OR 
            (WK_CURRENT_FROM_WH_ID <> WH_ID1) OR 
            (WK_CURRENT_FROM_LOCN_ID <> LOCN_ID1) OR 
            (WK_CURRENT_TO_WH_ID <> WH_ID2) OR 
            (WK_CURRENT_TO_LOCN_ID <> LOCN_ID2))  THEN
        BEGIN
    /* insert into log(description) values ('differences'); */
           IF (WK_CHANGE = 'FROM') THEN
           BEGIN
              LOC_QTY_1 = WK_LAST_FROM_QTY;
              LOC_QTY_2 = WK_LAST_TO_QTY;
              WH_ID1 = WK_LAST_FROM_WH_ID;
              LOCN_ID1 = WK_LAST_FROM_LOCN_ID;
              WH_ID2 = WK_LAST_TO_WH_ID;
              LOCN_ID2 = WK_LAST_TO_LOCN_ID;
              WK_HAVE_DATA = 'N';
              /* SUSPEND; */
              WK_FOUND = 0;
              SELECT 1
              FROM TRANSACTIONS_WORK 
              WHERE RECORD_ID = :WK_REC_ID
                AND OBJECT = :PROD_ID
                AND WH_ID = :WK_LAST_FROM_WH_ID
                AND LOCN_ID = :WK_LAST_FROM_LOCN_ID
                AND WH_ID2 = :WK_LAST_TO_WH_ID
                AND LOCN_ID2 = :WK_LAST_TO_LOCN_ID
              INTO :WK_FOUND;
              IF (WK_FOUND = 0) THEN
              BEGIN
                 INSERT INTO TRANSACTIONS_WORK(RECORD_ID, OBJECT, DESCRIPTION, WH_ID, LOCN_ID, QTY, WH_ID2, LOCN_ID2, QTY2)
                 VALUES (:WK_REC_ID, :PROD_ID, :DESCRIPTION, :WK_LAST_FROM_WH_ID, :WK_LAST_FROM_LOCN_ID, :WK_LAST_FROM_QTY, :WK_LAST_TO_WH_ID, :WK_LAST_TO_LOCN_ID, :WK_LAST_TO_QTY);
              END
              ELSE
              BEGIN
                 UPDATE TRANSACTIONS_WORK
                    SET QTY = QTY + :WK_LAST_FROM_QTY,
                        QTY2 = QTY2 + :WK_LAST_TO_QTY
                 WHERE RECORD_ID = :WK_REC_ID
                   AND OBJECT = :PROD_ID
                   AND WH_ID = :WK_LAST_FROM_WH_ID
                   AND LOCN_ID = :WK_LAST_FROM_LOCN_ID
                   AND WH_ID2 = :WK_LAST_TO_WH_ID
                   AND LOCN_ID2 = :WK_LAST_TO_LOCN_ID;
              END
    /* insert into log(description) values ('suspended'); */
           END
           IF (WK_CURRENT_PROD_ID <> PROD_ID) THEN
           BEGIN
    /* insert into log(description) values ('prod changed'); */
              PROD_ID = WK_CURRENT_PROD_ID;
              DESCRIPTION = WK_CURRENT_DESC;
           END
           WH_ID1 = WK_CURRENT_FROM_WH_ID;
           LOCN_ID1 = WK_CURRENT_FROM_LOCN_ID;
           WH_ID2 = WK_CURRENT_TO_WH_ID;
           LOCN_ID2 = WK_CURRENT_TO_LOCN_ID;
           LOC_QTY_1 = 0;
           LOC_QTY_2 = 0;
           IF (WK_HAVE_DATA = 'N') THEN
           BEGIN
              IF (WK_CHANGE = 'FROM') THEN
              BEGIN
                 WK_CURRENT_FROM_QTY = WK_CURRENT_FROM_QTY - WK_LAST_FROM_QTY; 
                 WK_CURRENT_TO_QTY = 0;
              END
              ELSE
              BEGIN
                 WK_CURRENT_FROM_QTY = 0;
                 WK_CURRENT_TO_QTY = WK_CURRENT_TO_QTY - WK_LAST_TO_QTY;
              END
    /* insert into log(description) values ('qtys reset'); */
           END
        END
     END
  END
  IF (WK_HAVE_DATA = 'Y') THEN
  BEGIN
     LOC_QTY_1 = WK_CURRENT_FROM_QTY;
     LOC_QTY_2 = WK_CURRENT_TO_QTY;
     /* SUSPEND; */
    /* insert into log(description) values ('final record'); */
     WK_FOUND = 0;
     SELECT 1
     FROM TRANSACTIONS_WORK 
     WHERE RECORD_ID = :WK_REC_ID
       AND OBJECT = :PROD_ID
       AND WH_ID = :WK_CURRENT_FROM_WH_ID
       AND LOCN_ID = :WK_CURRENT_FROM_LOCN_ID
       AND WH_ID2 = :WK_CURRENT_TO_WH_ID
       AND LOCN_ID2 = :WK_CURRENT_TO_LOCN_ID
     INTO :WK_FOUND;
     IF (WK_FOUND = 0) THEN
     BEGIN
        INSERT INTO TRANSACTIONS_WORK(RECORD_ID, OBJECT, DESCRIPTION, WH_ID, LOCN_ID, QTY, WH_ID2, LOCN_ID2, QTY2)
        VALUES (:WK_REC_ID, :PROD_ID, :DESCRIPTION, :WK_CURRENT_FROM_WH_ID, :WK_CURRENT_FROM_LOCN_ID, :WK_CURRENT_FROM_QTY, :WK_CURRENT_TO_WH_ID, :WK_CURRENT_TO_LOCN_ID, :WK_CURRENT_TO_QTY);
     END
     ELSE
     BEGIN
        UPDATE TRANSACTIONS_WORK
           SET QTY = QTY + :WK_CURRENT_FROM_QTY,
               QTY2 = QTY2 + :WK_CURRENT_TO_QTY
        WHERE RECORD_ID = :WK_REC_ID
          AND OBJECT = :PROD_ID
          AND WH_ID = :WK_CURRENT_FROM_WH_ID
          AND LOCN_ID = :WK_CURRENT_FROM_LOCN_ID
          AND WH_ID2 = :WK_CURRENT_TO_WH_ID
          AND LOCN_ID2 = :WK_CURRENT_TO_LOCN_ID;
     END
  END
  FOR SELECT OBJECT,
    DESCRIPTION,
    WH_ID,
    LOCN_ID,
    QTY,
    WH_ID2,
    LOCN_ID2,
    QTY2 
  FROM TRANSACTIONS_WORK 
  WHERE RECORD_ID = :WK_REC_ID
  ORDER BY RECORD_ID,
    DESCRIPTION,
    WH_ID,
    LOCN_ID,
    WH_ID2,
    LOCN_ID2 
  INTO :PROD_ID,
       :DESCRIPTION,
       :WH_ID1,
       :LOCN_ID1,
       :LOC_QTY_1,
       :WH_ID2,
       :LOCN_ID2,
       :LOC_QTY_2
  DO
  BEGIN
     SUSPEND;
  END
  
END
 ^

SET TERM ; ^
COMMIT WORK;
