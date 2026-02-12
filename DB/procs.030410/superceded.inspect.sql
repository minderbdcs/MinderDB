create domain inspect_category char(1);
create domain inspect_description varchar(25);
create domain inspect_pass_criteria varchar(6);

alter table valid_responses add inspect_category  inspect_category;

create table inspect_criteria (
inspect_category inspect_category not null,
inspect_description inspect_description,
inspect_pass_criteria inspect_pass_criteria,
primary key(inspect_category));

