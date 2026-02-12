COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;

/*
CREATE OR ALTER PROCEDURE ADD_SSN_TYPE_COND (SSN_ID VARCHAR(20) ,
STATUS CHAR(1) ,
TYPE_CODE VARCHAR(40) ,
PERSON_ID VARCHAR(10) ,
DEVICE_ID VARCHAR(2) )
*/

CREATE OR ALTER PROCEDURE ADD_SSN_TYPE_COND (SSN_ID SSN_ID ,
STATUS CHAR(1) ,
TYPE_CODE VARCHAR(40) ,
PERSON_ID PERSON ,
DEVICE_ID DEVICE_ID )
AS 
    

DECLARE VARIABLE REC_EXIST INTEGER; 
DECLARE VARIABLE sTypeCode VARCHAR(40);
DECLARE VARIABLE sTypeHeaderCode VARCHAR(40);
DECLARE VARIABLE sTypeLineCode VARCHAR(40);
DECLARE VARIABLE sMandatory CHAR(1);
DECLARE VARIABLE sDesc VARCHAR(100);

BEGIN
   IF (:STATUS = 'A') THEN
   BEGIN
      FOR 
         SELECT TYPE_CODE, TYPE_HEADER_CODE, MANDATORY 
         FROM TYPE_HEADER
         WHERE TYPE_CODE = :TYPE_CODE         
         INTO sTypeCode, :sTypeHeaderCode, :sMandatory
      DO
      BEGIN 
         REC_EXIST = 0;
         sDesc = 'Record check first arrival ' || :sTypeHeaderCode || ' created';                 
         
         SELECT 1
         FROM SSN_TYPE_COND
         WHERE SSN_ID = :SSN_ID
         AND STATUS = :STATUS
         AND TYPE_CODE = :TYPE_CODE
         AND TYPE_HEADER_CODE = :sTypeHeaderCode
         INTO :REC_EXIST;
         
         IF (REC_EXIST = 0) THEN
         BEGIN      
           INSERT INTO SSN_TYPE_COND (SSN_ID, STATUS, TYPE_CODE, TYPE_HEADER_CODE, MANDATORY)
           VALUES (:SSN_ID, :STATUS, :TYPE_CODE, :sTypeHeaderCode, :sMandatory);
           
           /* Add inspection history for status 'A' */                                                                                     
    EXECUTE PROCEDURE ADD_INSP_HIST(:SSN_ID, :STATUS, 'NOW', :TYPE_CODE,
                                          :sTypeHeaderCode, '', :sDesc, :PERSON_ID, :DEVICE_ID);
                      
         END
      END                           
   END
   ELSE IF (:STATUS = 'B') THEN
   BEGIN
      FOR 
         SELECT TYPE_HEADER_CODE, MANDATORY, TYPE_LINE_CODE 
         FROM SSN_TYPE_COND
         WHERE SSN_ID = :SSN_ID
         AND STATUS = 'A'
         AND TYPE_CODE = :TYPE_CODE         
         INTO :sTypeHeaderCode, :sMandatory, :sTypeLineCode
      DO
      BEGIN
         REC_EXIST = 0;
  sDesc = 'Record asset condition ' || :sTypeHeaderCode || ' created';                 
           
  SELECT 1
  FROM SSN_TYPE_COND
  WHERE SSN_ID = :SSN_ID
  AND STATUS = :STATUS
  AND TYPE_CODE = :TYPE_CODE
  AND TYPE_HEADER_CODE = :sTypeHeaderCode  
  INTO :REC_EXIST;
           
  IF (REC_EXIST = 0) THEN
  BEGIN      
     INSERT INTO SSN_TYPE_COND (SSN_ID, STATUS, TYPE_CODE, TYPE_HEADER_CODE, 
                                MANDATORY, TYPE_LINE_CODE)
     VALUES (:SSN_ID, :STATUS, :TYPE_CODE, :sTypeHeaderCode, :sMandatory, :sTypeLineCode);
             
     /* Add inspection history for status 'B' */                                                                                     
     EXECUTE PROCEDURE ADD_INSP_HIST(:SSN_ID, :STATUS, 'NOW', :TYPE_CODE,
                 :sTypeHeaderCode, :sTypeLineCode, :sDesc, :PERSON_ID, :DEVICE_ID);
                        
         END
      END      
   END
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
