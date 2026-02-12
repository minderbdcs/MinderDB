CREATE DOMAIN device_TYPE AS CHAR(2);
alter table sys_equip add device_type device_type;
update sys_equip set device_type='PR' where device_id starting 'P';
update sys_equip set device_type='HH' where device_id starting 'M';

