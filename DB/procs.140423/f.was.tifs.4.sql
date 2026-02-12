/* after do the DSAS for pick despatches whoout asns */


select first 1 p1.ps_out_despatch_id, p1.ps_pick_order ,(select response_text from add_tran_response_v6('MV','DS000001',p1.ps_sscc,'DSPS','R','NOW','|SYS_EQUIP.DEVICE_ID=PB|',1,'F','','MASTER   ',0,'','SSSSSSSSS','BDCS','XX','','PSGROUP',p1.ps_pick_order,'SO','GO',''))
from pack_sscc p1  
join pick_order p2 on p1.ps_pick_order=p2.pick_order
where (p1.ps_out_despatch_id is not null) and (p1.ps_edi_asn is not null)  
and p2.company_id='PSGROUP'
;
