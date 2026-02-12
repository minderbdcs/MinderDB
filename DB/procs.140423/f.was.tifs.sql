/*
select pid.despatch_id,pid.company_id,pid.pick_order,pid.qty_picked,pick_detail_status, pid.pick_label_no from pick_item_detail pid where pid.company_id='PSGROUP' and pid.pick_order starting '45' and pid.despatch_id is not null;
*/
/* so for these pids to get the original pack_sscc */

select pid.company_id,pid.pick_order,pid.qty_picked,pick_detail_status, pid.pick_label_no ,pid.despatch_id, pd.pickd_carrier_id, pd.awb_consignment_no, ps.ps_despatch_id, ps.ps_awb_consignment_no, ps.ps_carrier_id
from pick_item_detail pid  
join pack_sscc ps on pid.pick_label_no=ps.ps_pick_label_no 
join pick_despatch pd  on pid.despatch_id  =pd.despatch_id      
where pid.company_id='PSGROUP' and pid.pick_order starting '45' and pid.despatch_id is not null
and ps.ps_out_despatch_id is null
;

select 'update pack_sscc set ps_out_despatch_id=' ||  pid.despatch_id ||
' ,ps_out_awb_consignment_no=' || '"' ||  alltrim(pd.awb_consignment_no) || '"' ||
' ,ps_out_carrier_id=' || '"' ||  pd.pickd_carrier_id || '"' ||
' where ps_sscc = ' || '"' || ps.ps_sscc || '"^'
from  pack_sscc ps  
join  pick_item_detail pid on  ps.ps_pick_label_no = pid.pick_label_no
join pick_despatch pd  on pid.despatch_id  =pd.despatch_id      
where pid.company_id='PSGROUP' and pid.pick_order starting '45' and pid.despatch_id is not null
and ps.ps_out_despatch_id is null
;
