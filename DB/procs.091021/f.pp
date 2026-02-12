alter table prod_profile add size_type code;

create index prod_profile_size_idx on prod_profile(size_type, temperature_zone, prod_id);

