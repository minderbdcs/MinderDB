SELECT description 
FROM options  
WHERE group_code='PUTAWAY' and code='COMPANY.HOME_LOCN_ID';
 
insert into options(group_code,code,description) values('PUTAWAY','COMPANY.HOME_LOCN_ID','T');


