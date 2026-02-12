/*
drop external function v6parse;
drop external function v6alltrim;
*/

declare external function v6parse cstring(7168), cstring(1), integer returns cstring(7168) free_it 
	entry_point  'fudlib_parse' module_name 'fudlib';

declare external function v6alltrim cstring(7168) returns cstring(7168) free_it 
	entry_point  'fudlib_alltrim' module_name 'fudlib';

