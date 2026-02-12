/*
 insert into export_map(em_rules_name,em_path,em_filename_extensn,em_where,create_by,last_update_by) values('PICK_ORDER','/data/tmp','csv',"where exported_import_date is null",'bdcs','bdcs');
*/
 insert into export_map_var(emv_rules_name,emv_export_col_name,emv_sequence,emv_table,emv_fieldname,emv_fieldtype,emv_format,emv_primary_field,emv_status,create_by,last_update_by) 
values('PICK_ORDER','ORDER','0','PICK_ORDER','PICK_ORDER','S','%s','T','OK','bdcs','bdcs');
 insert into export_map_var(emv_rules_name,emv_export_col_name,emv_sequence,emv_table,emv_fieldname,emv_fieldtype,emv_format,emv_primary_field,emv_status,create_by,last_update_by) 
values('PICK_ORDER','Address 1','5','PICK_ORDER','D_ADDRESS_LINE1','S','%s','F','OK','bdcs','bdcs');
 insert into export_map_var(emv_rules_name,emv_export_col_name,emv_sequence,emv_table,emv_fieldname,emv_fieldtype,emv_format,emv_primary_field,emv_status,create_by,last_update_by) 
values('PICK_ORDER','Due Date','10','PICK_ORDER','PICK_DUE_DATE','D','%s','F','OK','bdcs','bdcs');
 insert into export_map_var(emv_rules_name,emv_export_col_name,emv_sequence,emv_table,emv_fieldname,emv_fieldtype,emv_format,emv_primary_field,emv_status,create_by,last_update_by) 
values('PICK_ORDER','Special Instructions 1','25','PICK_ORDER','SPECIAL_INSTRCUTIONS1','B','%s','F','OK','bdcs','bdcs');
