BEGIN {
	lineno = 55;	
	table="PICK_DESPATCH";
	rule="DESPATCH";
	table="PICK_ORDER";
	rule="PICKORDER";
}
{ printf "%s%s%s%s%s%s%s%d%s\n", " insert into sys_mirror_var(smv_rules_name,smv_table,smv_fieldname,smv_sequence) values('",rule,"','",table,"','",$1,"',",lineno,");";
lineno += 5;
}
