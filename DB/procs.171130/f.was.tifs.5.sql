/*
 insert into export_map(em_rules_name,em_path,em_filename_extensn,em_where,create_by,last_update_by) values('PICK_ORDER','/data/tmp','csv',"where exported_import_date is null",'bdcs','bdcs');
*/
 insert into export_map_var(emv_rules_name,emv_export_col_name,emv_sequence,emv_table,emv_fieldname,emv_fieldtype,emv_format,emv_primary_field,emv_status,create_by,last_update_by) 
values('PICK_ORDER','Address 2','6','PICK_ORDER','D_ADDRESS_LINE2','S','%s','F','OK','bdcs','bdcs');
 insert into export_map_var(emv_rules_name,emv_export_col_name,emv_sequence,emv_table,emv_fieldname,emv_fieldtype,emv_format,emv_primary_field,emv_status,create_by,last_update_by) 
values('PICK_ORDER','Contact','30','PICK_ORDER','CONTACT_NAME','S','%s','F','OK','bdcs','bdcs');
 insert into export_map_var(emv_rules_name,emv_export_col_name,emv_sequence,emv_table,emv_fieldname,emv_fieldtype,emv_format,emv_primary_field,emv_status,create_by,last_update_by) 
values('PICK_ORDER','Email','35','PICK_ORDER','D_EMAIL','S','%s','F','OK','bdcs','bdcs');
