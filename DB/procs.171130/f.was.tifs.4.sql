 insert into export_map(em_rules_name,em_path,em_filename_extensn,em_where,create_by,last_update_by) values('PACK_CUSTOMER','/data/tmp','csv',"",'bdcs','bdcs');
 insert into export_map_var(emv_rules_name,emv_export_col_name,emv_sequence,emv_table,emv_fieldname,emv_fieldtype,emv_format,emv_primary_field,emv_status,create_by,last_update_by) 
values('PACK_CUSTOMER','Id','0','PACK_CUSTOMER','RECORD_ID','S','%s','T','OK','bdcs','bdcs');
 insert into export_map_var(emv_rules_name,emv_export_col_name,emv_sequence,emv_table,emv_fieldname,emv_fieldtype,emv_format,emv_primary_field,emv_status,create_by,last_update_by) 
values('PACK_CUSTOMER','Due Date','10','PACK_CUSTOMER','LAST_UPDATE_DATE','D','%s','F','OK','bdcs','bdcs');
 insert into export_map_var(emv_rules_name,emv_export_col_name,emv_sequence,emv_table,emv_fieldname,emv_fieldtype,emv_format,emv_primary_field,emv_status,create_by,last_update_by) 
values('PACK_CUSTOMER','Notes','25','PACK_CUSTOMER','PC_NOTES','B','%s','F','OK','bdcs','bdcs');
