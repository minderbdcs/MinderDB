/*
Insert a new record into the OPTIONS table where:
GROUP_CODE = 'ISSN_STATU'
CODE = 'OS'
DESCRIPTION = 'Object/ISSN is located Off-Site'
COMMENTS = 'Added to help report Tools sent off-site for repair or calibration'
*/
insert into options(group_code, code, description) values('ISSN_STATU','OS','Object/ISSN is located Off-Site');
