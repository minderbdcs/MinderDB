SET TERM ^ ;

ALTER PROCEDURE PC_NIXX_P (RECORD_ID INTEGER,
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
  DECLARE VARIABLE LOCN_EXIST INTEGER; 
  DECLARE VARIABLE LOCN_NAME VARCHAR(50);
  DECLARE VARIABLE SSN_EXIST INTEGER;
  DECLARE VARIABLE strAUDIT_DESC VARCHAR(50);
  DECLARE VARIABLE strSSN_ID VARCHAR(20);
  
BEGIN /* Main */
    strWH_ID = "";
    strINSTANCE = "";
    LOCN_EXIST = 0;
    LOCN_NAME = "Created during audit " || :TRN_DATE;
    SSN_EXIST = 0;
    strAUDIT_DESC = ""; 

    /* Check if warehouse exists */
    SELECT WH_ID, INSTANCE_ID 
    FROM WAREHOUSE
    WHERE WH_ID = :WH_ID
    INTO :strWH_ID, :strINSTANCE;

    /* Check warehouse*/
    IF (strWH_ID = '') THEN
    BEGIN
       /* Update transactions table */               
       EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'Invalid Warehouse');
       EXIT;
    END
    ELSE
    BEGIN /* WH */
        /* Check instance */
        IF (strINSTANCE <> :INSTANCE_ID) THEN  
        BEGIN
          /* Update transactions table */               
          EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'Invalid InstanceID');
          EXIT;
        END
        ELSE
        BEGIN /* Location */
           /* Check Location */                 
           SELECT 1 
           FROM LOCATION
           WHERE WH_ID = :WH_ID
           AND LOCN_ID = :LOCN_ID 
           INTO :LOCN_EXIST; 
           
           /* Location not exists, then add new location */
           IF (LOCN_EXIST = 0) THEN
           BEGIN
              /* Add new Location record */
       INSERT INTO LOCATION (LOCN_ID, WH_ID, LOCN_NAME, LAST_AUDITED_DATE)
              VALUES (:LOCN_ID, :WH_ID, :LOCN_NAME, :TRN_DATE);
           END
                      
           IF (:TRN_TYPE <> 'NIUI') THEN
           BEGIN
              /* Check SSN */
              SELECT COUNT(*)
              FROM SSN
              WHERE PROD_ID = :OBJECT
		AND WH_ID = :WH_ID 
		AND LOCN_ID = :LOCN_ID
              INTO :SSN_EXIST;
              
              /* If SSN does not exists, then can create it */
              IF (SSN_EXIST = 0) THEN
              BEGIN
                 /* new SSN */ 
          	EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'F', 'Product Not In Location - Use Asset Audit to Create');
          	EXIT;
              END
              
              /* Update fields of SSN */

 	      FOR SELECT SSN_ID
  	      FROM SSN
              WHERE PROD_ID = :OBJECT
		AND WH_ID = :WH_ID 
		AND LOCN_ID = :LOCN_ID
  	      INTO :strSSN_ID
 	      DO
  	      BEGIN
		IF (:TRN_TYPE = 'NITP') THEN  
	        BEGIN
	          EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NITP', :REFERENCE);  /* Update Type */
	          EXECUTE PROCEDURE ADD_MASTER_DATA(:TRN_TYPE, :TRN_DATE, :REFERENCE); 
	          strAUDIT_DESC = "SSN Type was modified";
	       	END
	       	ELSE IF (:TRN_TYPE = 'NIOB') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIOB', :REFERENCE); /* Update Generic */
	                 EXECUTE PROCEDURE ADD_MASTER_DATA(:TRN_TYPE, :TRN_DATE, :REFERENCE); 
	                 strAUDIT_DESC = "Generic description modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIBC') THEN
	        BEGIN
	          EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIBC', :REFERENCE); /* Update Brand */
	          EXECUTE PROCEDURE ADD_MASTER_DATA(:TRN_TYPE, :TRN_DATE, :REFERENCE); 
	                 strAUDIT_DESC = "Brand description modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIMO') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIMO', :REFERENCE); /* Update Model */
	                 EXECUTE PROCEDURE ADD_MASTER_DATA(:TRN_TYPE, :TRN_DATE, :REFERENCE); 
	                 strAUDIT_DESC = "Model description modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NICC') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NICC', :REFERENCE); /* Update Cost Center */
	                 EXECUTE PROCEDURE ADD_MASTER_DATA(:TRN_TYPE, :TRN_DATE, :REFERENCE); 
	                 strAUDIT_DESC = "Cost Center modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NILG') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NILG', :REFERENCE); /* Update LegacyID */
	                 EXECUTE PROCEDURE ADD_MASTER_DATA(:TRN_TYPE, :TRN_DATE, :REFERENCE); 
	                 strAUDIT_DESC = "Legacy ID modified";
	        END
	        ELSE IF (:TRN_TYPE = 'PSRF') THEN
	        BEGIN
	          EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'PSRF', :REFERENCE); /* Update GRN */
	          strAUDIT_DESC = "Product Serial Reference Number modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NISN') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NISN', :REFERENCE); /* Update Serial Number */
	                 strAUDIT_DESC = "Serial Number modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIO1') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO1', :REFERENCE); /* Update Other1 */
	                 strAUDIT_DESC = "Custom Field 1 modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIO2') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO2', :REFERENCE); /* Update Other2 */
	                 strAUDIT_DESC = "Custom Field 2 modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIO3') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO3', :REFERENCE); /* Update Other3 */
	                 strAUDIT_DESC = "Custom Field 3 modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIO4') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO4', :REFERENCE); /* Update Other4 */
	                 strAUDIT_DESC = "Custom Field 4 modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIO5') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO5', :REFERENCE); /* Update Other5 */
	                 strAUDIT_DESC = "Custom Field 5 modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIO6') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO6', :REFERENCE); /* Update Other6 */
	                 strAUDIT_DESC = "Type Custom Field 1 modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIO7') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO7', :REFERENCE); /* Update Other7 */
	                 strAUDIT_DESC = "Type Custom Field 2 modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIO8') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO8', :REFERENCE); /* Update Other8 */
	                 strAUDIT_DESC = "Type Custom Field 3 modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIO9') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIO9', :REFERENCE); /* Update Other9 */
	                 strAUDIT_DESC = "Type Custom Field 4 modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIOA') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIOA', :REFERENCE); /* Update Other10 */
	                 strAUDIT_DESC = "Type Custom Field 5 modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIOK') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIOK', :REFERENCE); /* Update Other19 */
	                 strAUDIT_DESC = "Maintenance Support No modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIPC') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIPC', :REFERENCE); /* Update Product */
	                 strAUDIT_DESC = "Product No modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIOL') THEN 
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIOL', :REFERENCE); /* Update Other20 */       
	                 strAUDIT_DESC = "Other 20 modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIST') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIST', :REFERENCE); /* Update Status Code */
	                 strAUDIT_DESC = "Status modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NILX') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NILX', :REFERENCE); /* Update Label Location */
	                 strAUDIT_DESC = "Label location modified";
	        END
	        ELSE IF (:TRN_TYPE = 'NIGC') THEN
	        BEGIN
	                 EXECUTE PROCEDURE UPDATE_SSN(:strSSN_ID, 'NIGC', :REFERENCE); /* Group copy */                  
	                 strAUDIT_DESC = "Copy fields from group " || :REFERENCE;
	        END
	        /* Add transaction history */                                                                                     
	        EXECUTE PROCEDURE ADD_SSN_HIST(:WH_ID, :LOCN_ID, :strSSN_ID, :TRN_TYPE, :TRN_CODE, :TRN_DATE,
                                              :strAUDIT_DESC, :REFERENCE, :QTY, :PERSON_ID, :DEVICE_ID); 
  	      END /* for */
       
       /* Update transactions table */               
              EXECUTE PROCEDURE UPDATE_TRAN (:RECORD_ID, 'T', 'Processed successfully'); 
               
                           
           END /* SSN */
                                
        END /* Location */
    END /* WH */
  SUSPEND;
END ^

