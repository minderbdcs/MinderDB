/*
*/
drop external function v4parse;
drop external function v4alltrim;

declare external function v4parse cstring(1024), cstring(1), integer returns cstring(1024) free_it 
	entry_point  'fudlib_parse' module_name 'fudlib';

declare external function v4alltrim cstring(1024) returns cstring(1024) free_it 
	entry_point  'fudlib_alltrim' module_name 'fudlib';

