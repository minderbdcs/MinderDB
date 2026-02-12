alter table control add pick_allocate_qty qty;
alter table control add ftp_directory descr;
update control set pick_allocate_qty=5;
update control set ftp_directory='d:\sysdata\iis\default\ftproot\';


