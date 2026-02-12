/*
select 0,ssn_id from issn where original_ssn in (select ssn_id from ssn where grn = '' and ssn_id <> '00083500');
select 0,ssn_id from ssn where grn = '' and ssn_id <> '00083500';
*/
/*
delete from issn where original_ssn in (select ssn_id from ssn where grn= '' and ssn_id <> '00083500');
delete from ssn where grn= '' and ssn_id <> '00083500';
*/
/*
select 1,ssn_id from ssn where grn <> '' and len(ssn_id) <> 8;
select 1,ssn_id from issn where original_ssn in (select ssn_id from ssn where grn <> '' and len(ssn_id) <> 8);
*/
/*
delete from issn where original_ssn in (select ssn_id from ssn where grn<> '' and len(ssn_id) <> 8);
delete from ssn where grn<> '' and len(ssn_id) <> 8;
*/
/*
select 21,ssn_id,grn from ssn where substr(ssn_id,1,1) < '0' or  substr(ssn_id,1,1) > '9';
select 22,ssn_id,grn from ssn where substr(ssn_id,2,2) < '0' or  substr(ssn_id,2,2) > '9';
select 23,ssn_id,grn from ssn where substr(ssn_id,3,3) < '0' or  substr(ssn_id,3,3) > '9';
select 24,ssn_id,grn from ssn where substr(ssn_id,4,4) < '0' or  substr(ssn_id,4,4) > '9';
select 25,ssn_id,grn from ssn where substr(ssn_id,5,5) < '0' or  substr(ssn_id,5,5) > '9';
select 26,ssn_id,grn from ssn where substr(ssn_id,6,6) < '0' or  substr(ssn_id,6,6) > '9';
select 27,ssn_id,grn from ssn where substr(ssn_id,7,7) < '0' or  substr(ssn_id,7,7) > '9';
select 28,ssn_id,grn from ssn where substr(ssn_id,8,8) < '0' or  substr(ssn_id,8,8) > '9';
*/
/*
delete from issn where original_ssn in (select ssn_id from ssn where substr(ssn_id,1,1) < '0' or  substr(ssn_id,1,1) > '9');
delete from issn where original_ssn in (select ssn_id from ssn where substr(ssn_id,2,2) < '0' or  substr(ssn_id,2,2) > '9');
delete from issn where original_ssn in (select ssn_id from ssn where substr(ssn_id,3,3) < '0' or  substr(ssn_id,3,3) > '9');
delete from issn where original_ssn in (select ssn_id from ssn where substr(ssn_id,4,4) < '0' or  substr(ssn_id,4,4) > '9');
delete from issn where original_ssn in (select ssn_id from ssn where substr(ssn_id,5,5) < '0' or  substr(ssn_id,5,5) > '9');
delete from issn where original_ssn in (select ssn_id from ssn where substr(ssn_id,6,6) < '0' or  substr(ssn_id,6,6) > '9');
delete from issn where original_ssn in (select ssn_id from ssn where substr(ssn_id,7,7) < '0' or  substr(ssn_id,7,7) > '9');
delete from issn where original_ssn in (select ssn_id from ssn where substr(ssn_id,8,8) < '0' or  substr(ssn_id,8,8) > '9');
delete from ssn where substr(ssn_id,1,1) < '0' or  substr(ssn_id,1,1) > '9';
delete from ssn where substr(ssn_id,2,2) < '0' or  substr(ssn_id,2,2) > '9';
delete from ssn where substr(ssn_id,3,3) < '0' or  substr(ssn_id,3,3) > '9';
delete from ssn where substr(ssn_id,4,4) < '0' or  substr(ssn_id,4,4) > '9';
delete from ssn where substr(ssn_id,5,5) < '0' or  substr(ssn_id,5,5) > '9';
delete from ssn where substr(ssn_id,6,6) < '0' or  substr(ssn_id,6,6) > '9';
delete from ssn where substr(ssn_id,7,7) < '0' or  substr(ssn_id,7,7) > '9';
delete from ssn where substr(ssn_id,8,8) < '0' or  substr(ssn_id,8,8) > '9';
*/

/*
select 3,ssn_id from issn where original_ssn in (select ssn_id from ssn where (grn is null) and (ssn_id > '00000100')); 
select 3,ssn_id from ssn where (grn is null) and (ssn_id > '00000100'); 
*/
/*
update issn set PREV_PREV_LOCN_ID=PREV_LOCN_ID,PREV_PREV_WH_ID=PREV_WH_ID,PREV_LOCN_ID=LOCN_ID,WH_ID='XX',LOCN_ID='00000000',issn_status='CN' where original_ssn in (select ssn_id from ssn where (grn is null) and (ssn_id > '00000100')); 
update ssn set PREV_WH_ID=WH_ID,PREV_LOCN_ID=LOCN_ID,WH_ID='XX',LOCN_ID='00000000', PO_ORDER=NULL, status_ssn='CN' where (grn is null) and (ssn_id > '00000100'); 
*/


