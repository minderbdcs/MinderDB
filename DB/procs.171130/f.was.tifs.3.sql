update export_map_var set emv_fieldname='SPECIAL_INSTRUCTIONS1' where emv_sequence=25 and emv_rules_name='PICK_ORDER';
update export_map set em_include_header_line='T' where em_rules_name='PICK_ORDER';
