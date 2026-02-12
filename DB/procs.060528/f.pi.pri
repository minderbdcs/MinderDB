drop trigger run_transaction_trpk;
drop trigger run_transaction_pkbs;
drop index pick_item_device_idx;
alter table pick_item add save_priority integer;
update pick_item set save_priority = pick_line_priority;
commit;
alter table pick_item drop pick_line_priority;
commit;

create domain pick_line_priority integer;
alter table pick_item add pick_line_priority pick_line_priority;
CREATE INDEX PICK_ITEM_DEVICE_IDX ON PICK_ITEM(DEVICE_ID, PICK_LINE_PRIORITY);
update pick_item set pick_line_priority = save_priority;

in f.trpk;
in f.pkbs;
exit;


