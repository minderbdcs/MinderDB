create view person_subtype 
as
select person_id, person_type, first_name from person where person_type in ('LE');
