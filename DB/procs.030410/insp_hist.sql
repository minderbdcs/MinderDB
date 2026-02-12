drop procedure add_ssn_type_cond;
drop procedure add_insp_hist;
alter table insp_hist add description varchar(100);
update insp_hist set description=desctiption;
alter table insp_hist drop desctiption;
