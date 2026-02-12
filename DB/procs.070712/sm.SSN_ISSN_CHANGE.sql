-- modifying the control table.

alter table control add GENERATE_SSN_METHOD varchar(25);
commit;
/*
update control set generate_ssn_method = '|GRN=4|LINE=2|SUFFIX=2,3|';
commit;
*/

-- modifying the GRN table.

alter table GRN
add LAST_LINE_NO QTY;
commit;
alter table GRN
add LAST_PALLET_NO QTY;
commit;

-- updating default values in GRN table to 1 where they are null.
-- this will update all older records to 1.

Update GRN set LAST_LINE_NO = 0, LAST_PALLET_NO = 0
where LAST_LINE_NO is null and LAST_PALLET_NO is null;

-- updating control table to add imported orders and default printer

alter table CONTROL add IMPORTED_ORDERS VARCHAR(40);
COMMIT;
ALTER TABLE CONTROL ADD DEFAULT_RECEIVE_PRINTER DEVICE_ID DEFAULT 'PA' ;
COMMIT;

-- altering table prod profile. Adding a new field for temperature

-- I have altered Add_GRN procedure to have last line no and last pallet no udpated
-- enter that code here...


alter table PROD_PROFILE ADD TEMPERATURE_ZONE CODE_TWO;
COMMIT;

-- altering table control to ad generate_label_text

alter table CONTROL ADD GENERATE_LABEL_TEXT VALUE_TF;
UPDATE CONTROL SET GENERATE_LABEL_TEXT = 'T';
COMMIT;
