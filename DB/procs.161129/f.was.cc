/*
 
 CREATE TABLE COST_CENTRE (CODE CODE NOT NULL,
         DESCRIPTION DESCRIPTION,
 PRIMARY KEY (CODE));
CONSTRAINT INTEG_10:
  Primary key (CODE)
 
*/


alter table cost_centre add wh_id wh_id not null;
alter table cost_centre add company_id company not null;


/*
update cost_centre set wh_id = (select default_wh_id from control);
update cost_centre set company_id = (select company_id from control);
*/
update cost_centre set wh_id = (select default_wh_id from control), company_id=(select company_id from control);


/*
 delete from COST_CENTRE where WH_ID is null;
  commit;
  delete from COST_CENTRE where COMPANY_ID is null;
  commit;
*/


alter table cost_centre drop constraint integ_10;

  commit;

/*
  UPDATE RDB$RELATION_FIELDS SET RDB$NULL_FLAG = 1
  WHERE RDB$FIELD_NAME = 'WH_ID' AND RDB$RELATION_NAME = 'COST_CENTRE';
  commit;
  UPDATE RDB$RELATION_FIELDS SET RDB$NULL_FLAG = 1
  WHERE RDB$FIELD_NAME = 'COMPANY_ID' AND RDB$RELATION_NAME = 'COST_CENTRE';
  commit;
  alter table COST_CENTRE  ADD CONSTRAINT COST_CENTRE_PKEY PRIMARY KEY (WH_ID, COMPANY_ID, CODE)
*/

 alter table COST_CENTRE ADD CONSTRAINT COST_CENTRE_PKEY PRIMARY KEY (WH_ID, COMPANY_ID, CODE );
commit;

alter table COST_CENTRE add  foreign key (WH_ID) references WAREHOUSE(WH_ID);
alter table COST_CENTRE add  foreign key (COMPANY_id) references COMPANY(COMPANY_ID);

