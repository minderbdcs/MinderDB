alter table ssn add question_id record_id;
alter table ssn add answer_id record_id;

alter table ssn drop printed_by;
alter table work_file drop printed_by;
commit;
drop domain printed_by;
commit;

create domain printed_by varchar(10);

alter table ssn add printed_by printed_by;
alter table work_file add printed_by printed_by;
