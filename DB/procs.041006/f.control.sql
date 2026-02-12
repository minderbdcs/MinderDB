alter table control add default_wh_id wh_id;

update control set default_wh_id = (select first 1 wh_id from warehouse);

update control set db_version='061004';

