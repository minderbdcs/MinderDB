update control set db_version='091204';
alter table control add license_no varchar(40);
update control set license_no = 'BDCS 15 User License';

