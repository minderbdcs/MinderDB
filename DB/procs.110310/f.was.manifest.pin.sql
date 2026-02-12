select
/* pick_despatch.despatch_id, */
pick_despatch.awb_consignment_no,
substr(pack_id.despatch_label_no,9,24) as article_suffix,
(select first 1 pick_order.p_first_name  from
 pick_item_detail
 join pick_item on pick_item_detail.pick_label_no = pick_item.pick_label_no
 join pick_order on pick_item.pick_order  = pick_order.pick_order
 where pick_item_detail.despatch_id = pick_despatch.despatch_id) as first_name,
pick_despatch.pickd_post_code,
(select first 1 pick_order.p_country  from
 pick_item_detail
 join pick_item on pick_item_detail.pick_label_no = pick_item.pick_label_no
 join pick_order on pick_item.pick_order  = pick_order.pick_order
 where pick_item_detail.despatch_id = pick_despatch.despatch_id) as country,
carrier_service.description as charge_code_description,
/* charging zone from post codes table - use that with lowest cost */
( select first 1 case when (carrier.post_code_depot_id  = 'DEPOT_01' )
then postcode_depot.depot_01
when (carrier.post_code_depot_id  = 'DEPOT_02' )
then postcode_depot.depot_02
when (carrier.post_code_depot_id  = 'DEPOT_03' )
then postcode_depot.depot_03
when (carrier.post_code_depot_id  = 'DEPOT_04' )
then postcode_depot.depot_04
when (carrier.post_code_depot_id  = 'DEPOT_05' )
then postcode_depot.depot_05
when (carrier.post_code_depot_id  = 'DEPOT_06' )
then postcode_depot.depot_06
when (carrier.post_code_depot_id  = 'DEPOT_07' )
then postcode_depot.depot_07
when (carrier.post_code_depot_id  = 'DEPOT_08' )
then postcode_depot.depot_08
when (carrier.post_code_depot_id  = 'DEPOT_09' )
then postcode_depot.depot_09
when (carrier.post_code_depot_id  = 'DEPOT_10' )
then postcode_depot.depot_10
else postcode_depot.parcel_zone
end
from postcode_depot where  pick_despatch.pickd_post_code = postcode_depot.post_code  ) as charging_zone,
'N' as Dangerous_goods,
/* total pack_ids in awb_connote_no */
(select count(*) from pack_id p2
 where p2.despatch_id = pick_despatch.despatch_id) as connote_total_packs,
'N' as Transit_Cover_Required,
(select first 1 pick_item.pick_order from
 pick_item_detail
 join pick_item on pick_item_detail.pick_label_no = pick_item.pick_label_no
 where pick_item_detail.despatch_id = pick_despatch.despatch_id) as picked_order,
/* sum prod_profile.volume * pick_item_detail.qty_picked / 250 as cubic_weight */
(select sum(p4.volume * p3.picked_qty * 250 ) from
 pick_item_detail
 join pick_item on pick_item_detail.pick_label_no = pick_item.pick_label_no
 join pick_item p3 on pick_item.pick_order = p3.pick_order
 join prod_profile p4 on p3.prod_id = p4.prod_id
 where pick_item_detail.despatch_id = pick_despatch.despatch_id
 and p3.exported_despatch in ('T','F')) as cubic_weight,
/* sum prod_profile.net_weight * pick_item_detail.qty_picked as actual_weight */
(select sum(p4.net_weight * p3.picked_qty  ) from
 pick_item_detail
 join pick_item on pick_item_detail.pick_label_no = pick_item.pick_label_no
 join pick_item p3 on pick_item.pick_order = p3.pick_order
 join prod_profile p4 on p3.prod_id = p4.prod_id
 where pick_item_detail.despatch_id = pick_despatch.despatch_id
 and p3.exported_despatch in ('T','F')) as actual_weight,
/* sum prod_profile.net_weight * pick_item_detail.qty_picked as chargeable_weight */
(select sum(p4.net_weight * p3.picked_qty  ) from
 pick_item_detail
 join pick_item on pick_item_detail.pick_label_no = pick_item.pick_label_no
 join pick_item p3 on pick_item.pick_order = p3.pick_order
 join prod_profile p4 on p3.prod_id = p4.prod_id
 where pick_item_detail.despatch_id = pick_despatch.despatch_id
 and p3.exported_despatch in ('T','F')) as chargeable_weight

from pick_despatch
join pack_id on pick_despatch.despatch_id = pack_id.despatch_id
/* join carrier_service on pick_despatch.pickd_carrier_id = carrier_service.carrier_id and pick_despatch.pickd_service_type = carrier_service.service_type */
join carrier_service on pick_despatch.pickd_service_record_id = carrier_service.record_id 
join carrier on pick_despatch.pickd_carrier_id = carrier.carrier_id
/* and pick_despatch.pickd_country = postcode_depot.country
*/
where pick_despatch.pickd_carrier_id='EPARCEL'
/* and pick_despatch.pickd_exit >= 'TODAY' */
order by 
pick_despatch.awb_consignment_no,
article_suffix;

