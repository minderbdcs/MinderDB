insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('PICKORDER','PICK_ORDER','PICK_ORDER',10);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('PICKORDER','PICK_ORDER','MIRROR_DATA',15);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('PICKORDER','PICK_ORDER','SPECIAL_INSTRUCTIONS1',20);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('PICKORDER','PICK_ORDER','PICK_STATUS',25);

insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('PACK','PACK_ID','PACK_ID',10);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('PACK','PACK_ID','MIRROR_DATA',15);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('PACK','PACK_ID','DESPATCH_ID',20);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('PACK','PACK_ID','DESPATCH_LABEL_NO',25);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('PACK','PACK_ID','DIMENSION_X',30);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('PACK','PACK_ID','DIMENSION_Y',35);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('PACK','PACK_ID','DIMENSION_Z',40);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('PACK','PACK_ID','PACK_WEIGHT',45);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('PACK','PACK_ID','PACK_STATUS',50);

insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('DESPATCH','PICK_DESPATCH','DESPATCH_ID',10);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('DESPATCH','PICK_DESPATCH','MIRROR_DATA',15);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('DESPATCH','PICK_DESPATCH','AWB_CONSIGNMENT_NO',20);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('DESPATCH','PICK_DESPATCH','PICKD_CARRIER_ID',25);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('DESPATCH','PICK_DESPATCH','PICKD_SERVICE_TYPE',30);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('DESPATCH','PICK_DESPATCH','PICKD_PICK_ORDER1',35);
insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('DESPATCH','PICK_DESPATCH','DESPATCH_STATUS',40);

update sys_mirror_var set create_by='bdcs' where create_by is null;
update sys_mirror_var set last_update_by='bdcs' where last_update_by is null;

