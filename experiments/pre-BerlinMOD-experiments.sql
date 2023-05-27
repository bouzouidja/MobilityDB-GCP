SELECT create_reference_table('vehicles');
SELECT truncate_local_data_after_distributing_table($$public.vehicles$$)
SELECT create_reference_table('instants');
SELECT truncate_local_data_after_distributing_table($$public.instants$$)
SELECT create_reference_table('licences');
SELECT truncate_local_data_after_distributing_table($$public.licences$$)
SELECT create_reference_table('periods');
SELECT truncate_local_data_after_distributing_table($$public.periods$$)
SELECT create_reference_table('points');
SELECT truncate_local_data_after_distributing_table($$public.points$$)
SELECT create_reference_table('regions');
SELECT truncate_local_data_after_distributing_table($$public.regions$$)
SELECT create_distributed_table('trips', 'tripid');
SELECT truncate_local_data_after_distributing_table($$public.trips$$)
