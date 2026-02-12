SET TERM ^ ;

ALTER PROCEDURE PC_AUOB (RECORD_ID INTEGER,
WH_ID CHAR(2),
LOCN_ID VARCHAR(10),
OBJECT VARCHAR(30),
TRN_TYPE VARCHAR(4),
TRN_CODE CHAR(1),
TRN_DATE TIMESTAMP,
REFERENCE VARCHAR(40),
QTY INTEGER,
PERSON_ID VARCHAR(10),
DEVICE_ID CHAR(2),
INSTANCE_ID VARCHAR(10))
AS 
 
                             
  DECLARE VARIABLE strWH_ID CHAR(2); 
  DECLARE VARIABLE strINSTANCE VARCHAR(10); 
  DECLARE VARIABLE strSSN VARCHAR(20);  
  DECLARE VARIABLE strLOCN_ID VARCHAR(10);  
  DECLARE VARIABLE strGRN VARCHAR(40);  
  DECLARE VARIABLE strCurrentGRN VARCHAR(40);  
  DECLARE VARIABLE strNewGRN VARCHAR(40);  
  DECLARE VARIABLE strAUDIT_DESC VARCHAR(40); 
  DECLARE VARIABLE REC_ID INTEGER;    
  
BEGIN
    strWH_ID = "";
    strINSTANCE = "";
    strSSN = "";
    strWH_ID = "";
    strLOCN_ID = "";   
    strGRN = "";
    strAUDIT_DESC = "";  

    /* Check trasaction code */
    IF (:TRN_CODE = 'P') THEN
    BEGIN
       /* Update transactions table */               
       EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'Invalid code');
       EXIT;
    END 

    /* Assign GRN */
    IF (:TRN_TYPE = 'NIID') THEN
    BEGIN
       strGRN = :REFERENCE;
    END
    
    /* Check if warehouse exists */
    SELECT WH_ID, INSTANCE_ID 
    FROM WAREHOUSE
    WHERE WH_ID = :WH_ID
    INTO :strWH_ID, :strINSTANCE;

    /* Check warehouse*/
    IF (strWH_ID = '') THEN
    BEGIN
       SUSPEND;
    END
    ELSE
    BEGIN
          /* Check instance */
          IF (strINSTANCE <> :INSTANCE_ID) THEN  
          BEGIN
              SUSPEND;
          END
          ELSE
          BEGIN
                /* Check ObjectLocation */
		/* please check issn first */
		/* since it may not be in ssn table then update
		original_ssn */
		SELECT SD.ORIGINAL_SSN, SN.WH_ID, SN.LOCN_ID, SN.GRN
		FROM ISSN SD JOIN SSN SN ON SN.SSN_ID = SD.ORIGINAL_SSN
                WHERE SD.SSN_ID = :OBJECT
                INTO :strSSN, :strWH_ID, :strLOCN_ID, :strCurrentGRN;
		/*
                SELECT SSN_ID, WH_ID, LOCN_ID
                FROM SSN
                WHERE SSN_ID = :OBJECT
                INTO :strSSN, :strWH_ID, :strLOCN_ID;
		*/
                
                /* Check SSN */
                IF (strSSN = "") THEN
                BEGIN
                /* Object not found */
                       /* Add SSN */
                       INSERT INTO SSN (SSN_ID, WH_ID, LOCN_ID, INTO_DATE, AUDITED, GRN, AUDIT_DATE, AUDITED_QTY)
                       VALUES (:OBJECT, :WH_ID, :LOCN_ID, :TRN_DATE, 'N', :strGRN, :TRN_DATE, :QTY);
                       INSERT INTO ISSN (SSN_ID, ORIGINAL_SSN, WH_ID, LOCN_ID, CURRENT_QTY)
                       VALUES (:OBJECT, :OBJECT, :WH_ID, :LOCN_ID, :QTY);

                       strAUDIT_DESC = "New object record created during audit";
		       strSSN = OBJECT;
		       strCurrentGRN = strGRN;
                END
                ELSE
                BEGIN
		      IF (strGRN = "") THEN
		      BEGIN
		         strNewGRN = strCurrentGRN;
		      END
		      ELSE
		      BEGIN
		         strNewGRN = strGRN;
		      END
                      IF ((strWH_ID <> :WH_ID) OR (strLOCN_ID <> :LOCN_ID)) THEN
                      BEGIN          
                            /* item found in different location, update object relocated */
                            UPDATE SSN
                            SET WH_ID = :WH_ID, LOCN_ID = :LOCN_ID, INTO_DATE = :TRN_DATE,
                                AUDITED = 'C', GRN = :strNewGRN, AUDIT_DATE = :TRN_DATE, AUDITED_QTY = :QTY
                            WHERE SSN_ID = :strSSN;
                            
                            strAUDIT_DESC = "Item found in different location";  
                      END
                      ELSE
                      BEGIN                           
                            /* object found in expected location, upload object found */
                            UPDATE SSN
                            SET INTO_DATE = :TRN_DATE, AUDITED = 'F',  
                                GRN = :strNewGRN, AUDIT_DATE = :TRN_DATE, AUDITED_QTY = :QTY
                            WHERE SSN_ID = :strSSN;

                            strAUDIT_DESC = "Item found in correct location";
                      END
                END

               /* Update transactions table */               
               EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully'); 
               
               /* Add transaction history */                                                                                     
               EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :strSSN, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                                              :strAUDIT_DESC, :REFERENCE, :QTY,  :PERSON_ID, :DEVICE_ID);
          END
    END
  SUSPEND;
END ^

ALTER PROCEDURE PC_DELETE_ONE_PROD_COND_STATUS (RECORD_ID INTEGER,
WH_ID CHAR(2),
LOCN_ID VARCHAR(10),
OBJECT VARCHAR(30),
TRN_TYPE VARCHAR(4),
TRN_CODE CHAR(1),
TRN_DATE TIMESTAMP,
REFERENCE VARCHAR(40),
QTY INTEGER,
PERSON_ID VARCHAR(10),
DEVICE_ID CHAR(2))
AS 
 
   
        
  DECLARE VARIABLE CODE CHAR(1);
  DECLARE VARIABLE strAUDIT_DESC VARCHAR(50);

BEGIN
  
  CODE = ''; 

  /* Assign CODE value */
  IF (:TRN_TYPE = 'NXAP') THEN
  BEGIN
     CODE = 'A';
     strAUDIT_DESC = 'Delete Appearance: ' || :REFERENCE;
  END
  ELSE IF (:TRN_TYPE = 'NXOP') THEN
  BEGIN
     CODE = 'B';
     strAUDIT_DESC = 'Delete Operating: ' || :REFERENCE;
  END
  ELSE IF (:TRN_TYPE = 'NXCP') THEN
  BEGIN
     CODE = 'C';
     strAUDIT_DESC = 'Delete Completeness: ' || :REFERENCE;
  END   
  
   
    /* Delete record */
    DELETE FROM PRODUCT_COND_STATUS
    WHERE SSN_ID = :OBJECT
    AND   CODE = :CODE
    AND   DESCRIPTION = :REFERENCE;
    
    /* Add transaction history */                                                                                     
    EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :OBJECT, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                                   :strAUDIT_DESC, :REFERENCE, :QTY, :PERSON_ID, :DEVICE_ID);           
  
    /* Update transactions table */        
    EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully');

  SUSPEND;
END ^

