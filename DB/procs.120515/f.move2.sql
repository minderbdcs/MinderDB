/*
insert into sys_moves (from_status, into_status,update_flag) values('ST','RC','T');
insert into sys_moves (from_status, into_status,update_flag) values('PA','RC','T');
insert into sys_moves (from_status, into_status,update_flag) values('DS','ST','T');
insert into sys_moves (from_status, into_status,update_flag) values('DS','RC','T');
*/
update sys_moves set update_flag='T' where from_status='ST' and into_status='RC';
update sys_moves set update_flag='T' where from_status='PA' and into_status='RC';
update sys_moves set update_flag='T' where from_status='DS' and into_status='ST';
update sys_moves set update_flag='T' where from_status='DS' and into_status='RC';

