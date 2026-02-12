
CREATE PROCEDURE CREATE_PICK_DETAIL_FROM_ISSN 
AS
                                                       
  DECLARE VARIABLE WK_SSN VARCHAR(20);
  DECLARE VARIABLE WK_SSN_QTY INTEGER;
  DECLARE VARIABLE WK_FOUND INTEGER;
  DECLARE VARIABLE WK_PID_FOUND INTEGER;
  DECLARE VARIABLE WK_LABEL_NO VARCHAR(7);
  DECLARE VARIABLE WK_USER VARCHAR(10);
  DECLARE VARIABLE WK_LOCN_ID VARCHAR(10);
  DECLARE VARIABLE WK_DETAIL_ID INTEGER;
     
BEGIN
         
   FOR SELECT SSN_ID, CURRENT_QTY, USER_ID, LOCN_ID
       FROM ISSN
       WHERE ISSN_STATUS = 'DS'
       INTO :WK_SSN, :WK_SSN_QTY, :WK_USER, :WK_LOCN_ID
   DO
   BEGIN
     WK_FOUND = 0;
     SELECT 1, PICK_LABEL_NO 
            FROM PICK_ITEM
     	WHERE SSN_ID = :WK_SSN
     	AND PICK_LINE_STATUS IN ('OP','CN','HD')
            INTO :WK_FOUND,
                 :WK_LABEL_NO;
      IF (WK_FOUND = 1) THEN
      BEGIN
         UPDATE PICK_ITEM 
			SET PICK_LINE_STATUS = 'DS',
			PICKED_QTY = :WK_SSN_QTY,
			DESPATCH_LOCATION = :WK_LOCN_ID 
     	WHERE SSN_ID = :WK_SSN
     	AND PICK_LABEL_NO = :WK_LABEL_NO;
         WK_PID_FOUND = 0;
         SELECT 1, PICK_DETAIL_ID 
                FROM PICK_ITEM_DETAIL
                WHERE PICK_LABEL_NO = :WK_LABEL_NO
                AND SSN_ID = :WK_SSN
                INTO :WK_PID_FOUND, :WK_DETAIL_ID;
         IF (WK_PID_FOUND = 0) THEN
         BEGIN
            /* no detail record */
            INSERT INTO PICK_ITEM_DETAIL 
                (PICK_LABEL_NO, 
                 SSN_ID, 
                 PICK_DETAIL_STATUS, 
   			     DESPATCH_LOCATION,
                 QTY_PICKED,
                 USER_ID, 
                 CREATE_DATE)
            VALUES (:WK_LABEL_NO, 
                 :WK_SSN,
                 'DS',
                 :WK_LOCN_ID ,
                 :WK_SSN_QTY,
                 :WK_USER,
                 "NOW");
         END
         ELSE
         BEGIN
            UPDATE PICK_ITEM_DETAIL 
            SET  PICK_DETAIL_STATUS =
                 'DS',
                 QTY_PICKED =
                 :WK_SSN_QTY ,
                 DESPATCH_LOCATION =
                 :WK_LOCN_ID ,
                 USER_ID =
                 :WK_USER
            WHERE PICK_DETAIL_ID = :WK_DETAIL_ID;
         END
      END
   END
END ^
 
EXECUTE PROCEDURE CREATE_PICK_DETAIL_FROM_ISSN^ 
