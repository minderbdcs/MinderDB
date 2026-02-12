SELECT group_code,code,description 
FROM options  
WHERE group_code='PUTAWAY' ;
 
insert into options(group_code,code,description) values('PUTAWAY','PROD_PROFILE.SHORT_DESC','M');
insert into options(group_code,code,description) values('PUTAWAY','PROD_PROFILE.ISSUE_PER_PALLET','M');
insert into options(group_code,code,description) values('PUTAWAY','PROD_PROFILE.ISSUE_PER_OUTER_CARTON','M');
delete from options where group_code='PUTAWAY' and code = 'PROD_PROFILE.ISSUE_QTY';
insert into options(group_code,code,description) values('PUTAWAY','PROD_PROFILE.ISSUE','M');


