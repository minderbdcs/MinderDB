drop external function v4pos ;

declare external function v4pos cstring(32767), cstring(256), integer, integer returns integer by value 
	entry_point  'fudlib_pos' module_name 'fudlib';

