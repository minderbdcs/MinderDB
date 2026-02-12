create domain order_no varchar(10);
create domain order_line char(4);
alter table grn add order_no order_no;
alter table grn add order_line_no order_line;
