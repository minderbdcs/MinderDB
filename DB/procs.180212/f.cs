ALTER TABLE CARRIER_SERVICE ADD SERVICE_TRANSIT_INTERNATIONAL VALUE_FT ;
update carrier_service set service_transit_international='T';
update carrier_service set service_transit_international='F' where carrier_id='EPARCEL';

