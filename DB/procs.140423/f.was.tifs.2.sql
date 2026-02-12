/* after do the DSAS for pick despatches whoout asns */

select p1.ps_out_despatch_id, p1.ps_pick_order 
from pack_sscc p1  
where (p1.ps_out_despatch_id is not null) and (p1.ps_edi_asn is null) 
;

select p1.ps_out_despatch_id, p1.ps_pick_order ,(select response_text from add_tran_response_v6('MV','',p1.ps_out_despatch_id,'DSAS','C','NOW','',1,'F','','MASTER   ',0,'','SSSSSSSSS','BDCS','XX','','PSGROUP',p1.ps_pick_order,'SO','GO',''))
from pack_sscc p1  
where (p1.ps_out_despatch_id is not null) and (p1.ps_edi_asn is null) 
;
