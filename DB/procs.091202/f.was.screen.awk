BEGIN {
	#insert into sys_screen_var(ssv_name,ssv_sequence,ssv_title,ssv_field_type,ssv_field_status,ss_name,ssv_table) values('WH_ID','1','WH','SR','OK','FPGISSN','ISSN');
	insert = "insert into sys_screen_var(ssv_name,ssv_sequence,ssv_title,ssv_field_type,ssv_field_status,ss_name,ssv_table) values('%s','%s','%s','SR','OK','%s','%s');\n";
	screen = "FPGGRN";
	table = "GRN";
}
{
	title = $1;
	seq = NR;
	#print "title", title
	#print "seq", seq
	#print "screen", screen
	#print "table", table
	printf( insert, $1, seq, title, screen, table);
}
