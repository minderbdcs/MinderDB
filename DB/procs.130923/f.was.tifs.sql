select * from query_layout;
select * from query_layout where code='1ssn';
delete from query_layout where code='1ssn' and sequence=4;
select * from query_layout where code='1ssn';
update query_layout set description="coalesce(ssn.ssn_description,'') || coalesce(prod_profile.short_desc,'')" where code='1ssn' and sequence=10;
select * from query_layout where code='1ssn';
commit;
