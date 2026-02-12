/*
drop trigger run_transaction_pinv;

drop trigger add_pick_order_time;
drop trigger update_pick_order_time;
drop trigger add_pick_from_temp;
*/
drop trigger add_pick_item_time;
drop trigger update_pick_item_time;
 
drop trigger run_transaction_trbk;
drop trigger run_transaction_gclo;
drop trigger run_transaction_gpld;
drop procedure add_pick_ssn_items;
drop procedure add_pick_items;
commit;

alter domain percent_f       type double precision;

alter table pick_item alter tax_amount        type double precision;
alter table pick_item alter line_total        type double precision;


