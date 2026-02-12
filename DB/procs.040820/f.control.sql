alter table control add company_id company;

update control set company_id=(select first 1 company_id from company);

