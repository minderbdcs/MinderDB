DROP   TRIGGER RUN_TRANSACTION_GRNV  ^
COMMIT^

 
CREATE TRIGGER RUN_TRANSACTION_GRNV FOR TRANSACTIONS 
ACTIVE AFTER INSERT POSITION 42 
AS
DECLARE VARIABLE WK_AUTORUN INTEGER;
BEGIN
   WK_AUTORUN = GEN_ID(AUTOEXEC_TRANSACTIONS,0); 
   IF (WK_AUTORUN = 1) THEN
   BEGIN
      IF (NEW.TRN_TYPE = 'GRNV') THEN
      BEGIN
         IF (NEW.TRN_CODE = 'S') THEN
         BEGIN
            EXECUTE PROCEDURE ADD_NAMED_SSN_ISSN_GRNV
            NEW.WH_ID,
            NEW.LOCN_ID,
            NEW.OBJECT,
            NEW.TRN_DATE,
            NEW.QTY,
            NEW.SUB_LOCN_ID,    
            NEW.REFERENCE,    
            NEW.INPUT_SOURCE,    
            NEW.RECORD_ID,    
            NEW.TRN_CODE;    
         END
         ELSE
         BEGIN
            IF (NEW.TRN_CODE = 'I') THEN
            BEGIN
               EXECUTE PROCEDURE ADD_NAMED_SSN_ISSN_GRNV
               NEW.WH_ID,
               NEW.LOCN_ID,
               NEW.OBJECT,
               NEW.TRN_DATE,
               NEW.QTY,
               NEW.SUB_LOCN_ID,    
               NEW.REFERENCE,    
               NEW.INPUT_SOURCE,    
               NEW.RECORD_ID,    
               NEW.TRN_CODE;    
            END
            ELSE
            BEGIN
               EXECUTE PROCEDURE ADD_SSN_ISSN_GRNV     
               NEW.WH_ID,
               NEW.LOCN_ID,
               NEW.OBJECT,
               NEW.TRN_DATE,
               NEW.QTY,
               NEW.SUB_LOCN_ID,    
               NEW.REFERENCE,    
               NEW.INPUT_SOURCE,    
               NEW.RECORD_ID;    
            END
         END
         EXECUTE PROCEDURE TRAN_ARCHIVE;
      END
   END
END ^
