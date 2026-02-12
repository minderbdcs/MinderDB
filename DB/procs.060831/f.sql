/*
select issn_status,wh_id,locn_id,sum(current_qty) from issn where prod_id='R473' group by wh_id,locn_id,issn_status;
select issn_status,wh_id,locn_id,sum(current_qty) from issn where prod_id='R473' group by wh_id,locn_id,issn_status;
*/
select count(*),pick_detail_status,device_id from pick_item_detail where pick_detail_status  in ('PL','PG') group by pick_detail_status,device_id;
select count(*),pick_detail_status,pick_item_detail.device_id,pick_line_status from pick_item_detail  join pick_item on pick_item.pick_label_no=pick_item_detail.pick_label_no where pick_detail_status  in ('PL','PG') group by pick_detail_status,pick_item.pick_line_status,pick_item_detail.device_id;
