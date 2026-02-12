create trigger PICK_ORDER_RAISE_PURCH_ORD for PICK_ORDER
Before Update position 2
AS
declare variable LO_NUMBER INTEGER;
declare variable JOB_NO VARCHAR(10);
declare variable LO_DATE TIMESTAMP;
declare variable COMMENTS VARCHAR(255);
declare variable USER_ID VARCHAR(10);
declare variable LOAN_TYPE VARCHAR(2);
declare variable PICK_ORDER VARCHAR(15);
declare variable RETURN_DATE TIMESTAMP;

declare variable LO_LINE VARCHAR(4);
declare variable PROD_ID VARCHAR(30);
declare variable SSN_ID VARCHAR(20);
declare variable Loan_Qty Integer;
declare variable LOAN_RETURN_DATE TIMESTAMP;
declare variable LOAN_COMMENTS VARCHAR(255);



BEGIN
/* Do only for transfer orders   */
/* When order has been approved for dispatch then raise a Loan order for the expected
   return of the items being transfered  */

   if ((OLD.pick_order_type = 'TO') And (OLD.permanent_transfer <> 'Y')) then Begin 
           IF ((OLD.pick_Status <> 'DX') And (NEW.pick_Status = 'DX')) THEN BEGIN
               Execute Procedure Get_Loan_ID Returning_Values :LO_NUMBER;
               JOB_NO = OLD.pick_order;
               LO_DATE = 'TODAY';
               COMMENTS = OLD.special_instructions1;
               USER_ID = OLD.approved_desp_by;
               LOAN_TYPE = 'TO'; /* Transfer Order */
               PICK_ORDER = OLD.pick_order;
               RETURN_DATE = OLD.return_date;
               INSERT INTO LOAN_ORDER (LOAN_ORDER_NO, LOAN_ORDER_DATE, STATUS, JOB_NO, COMMENTS, PICK_ORDER, RETURN_DATE, USER_ID, LOAN_TYPE)
               VALUES (:LO_NUMBER, :LO_DATE, 'OP', :JOB_NO, :COMMENTS, :PICK_ORDER, :RETURN_DATE, :USER_ID, :LOAN_TYPE);

               For Select PICK_ORDER_LINE_NO, PROD_ID, SSN_ID, PICKED_QTY, RETURN_DATE, SPECIAL_INSTRUCTIONS1 FROM PICK_ITEM WHERE PICK_ORDER = OLd.pick_order
               INTO :LO_LINE, :PROD_ID, :SSN_ID, :LOAN_QTY, :LOAN_RETURN_DATE, :LOAN_COMMENTS
               Do Begin
                 INSERT INTO LOAN_ORDER_LINE (LOAN_ORDER_NO, loan_order_line_no, SSN_ID, STATUS, PROD_ID, LOAN_QTY, LOAN_TYPE, LOAN_RETURN_DATE, COMMENTS)
                 VALUES (:LO_NUMBER, :LO_LINE, :SSN_ID, 'OP', :PROD_ID, :LOAN_QTY, 'TO', :LOAN_RETURN_DATE, :COMMENTS );
               End
          END 
   END
END