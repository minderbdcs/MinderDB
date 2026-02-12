/*
re-apply primary keys
CREATE TABLE PURCHASE_ORDER (PURCHASE_ORDER PURCHASE_ORDER NOT NULL,
5898:PRIMARY KEY (PURCHASE_ORDER));
CREATE TABLE PURCHASE_ORDER_LINE (PURCHASE_ORDER PURCHASE_ORDER NOT NULL,
5933:PRIMARY KEY (PURCHASE_ORDER, PO_LINE));
*/

alter table purchase_order_line add constraint purchase_order_line_pkey 
 PRIMARY KEY (PURCHASE_ORDER, PO_LINE);
alter table purchase_order add constraint purchase_order_pkey 
 PRIMARY KEY (PURCHASE_ORDER);

