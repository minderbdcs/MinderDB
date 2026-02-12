COMMIT WORK;
SET AUTODDL OFF;
SET TERM ^ ;
 

CREATE OR ALTER TRIGGER INSERT_SSN_PO_PRICE FOR SSN 
ACTIVE BEFORE INSERT POSITION 0 
AS
DECLARE VARIABLE WK_QTY INTEGER;
DECLARE VARIABLE WK_QTYF FLOAT;
/* DECLARE VARIABLE WK_REASON VARCHAR(40); */
DECLARE VARIABLE WK_REASON VARCHAR(1024);
DECLARE VARIABLE WK_DO_NIPP VARCHAR(1);
BEGIN
   WK_DO_NIPP = 'F';
   SELECT SSN_PO_PRICE_NIPP  
   FROM CONTROL
   INTO :WK_DO_NIPP;
   IF (WK_DO_NIPP IS NULL) THEN
   BEGIN
      WK_DO_NIPP = 'F';
   END
   IF (WK_DO_NIPP = 'F') THEN
   BEGIN
      IF (NOT NEW.PURCHASE_PRICE IS NULL) THEN
      BEGIN
         IF (NEW.LOAN_COST_BASE IS NULL) THEN
         BEGIN
            NEW.LOAN_COST_BASE = NEW.PURCHASE_PRICE;
         END
         IF (NEW.LOAN_COST_BASE = 0 ) THEN
         BEGIN
            NEW.LOAN_COST_BASE = NEW.PURCHASE_PRICE;
         END
      END
   END
   ELSE
   BEGIN
      IF (NOT NEW.PURCHASE_PRICE IS NULL) THEN
      BEGIN
         WK_QTY = NEW.PURCHASE_PRICE * 100;
         WK_REASON =  'No Price Yet';
/*
         EXECUTE PROCEDURE ADD_TRAN(
           NEW.WH_ID,
           NEW.LOCN_ID,
           NEW.SSN_ID,
           'NIPP',
           'A',
           'NOW',
           'No Price Yet',
           :WK_QTY,
           'F',
           '',
           'MASTER',
           0,
           '',
           'SSSSSSSSS',
           'DB',
           'DB');
*/
      END
      ELSE
      BEGIN
         /* no price so retrive from control */
         SELECT DEFAULT_PRICE FROM CONTROL INTO :WK_QTYF;
         NEW.PURCHASE_PRICE  = WK_QTYF;
         WK_QTY = WK_QTYF * 100;
         WK_REASON =  'Defaulted Price - No Price Yet';
/*
         EXECUTE PROCEDURE ADD_TRAN(
           NEW.WH_ID,
           NEW.LOCN_ID,
           NEW.SSN_ID,
           'NIPP',
           'A',
           'NOW',
           'Defaulted Price - No Price Yet',
           :WK_QTY,
           'F',
           '',
           'MASTER',
           0,
           '',
           'SSSSSSSSS',
           'DB',
           'DB');
*/
      END
      EXECUTE PROCEDURE ADD_SSN_HIST(NEW.WH_ID, NEW.LOCN_ID, NEW.SSN_ID, 
         'nipp', 'A', 'NOW',
         'insert ssn with a price' , :WK_REASON, :WK_QTY, 'DB', 'DB'); 
   END
END ^


SET TERM ; ^
COMMIT WORK;
SET AUTODDL ON;
