-- Compare external report by ISBN to ISBN 
-- or URL or DOI (not included in search yet; 
-- currently will not finish with ISBN or comparison)
with isbns as (
	select
		ids.instance_id as instance_id,
		ids.instance_hrid as instance_hrid,
		ids.identifier_type_name as identifier_type_name,
		ids.identifier AS raw_identifier,
		NULLIF(regexp_replace(upper(trim(ids.identifier)), '( .*)|[^0-9X]', '', 'g'), '') as identifier
	from
		folio_derived.instance_identifiers as ids
	where
		ids.identifier_type_name in ('ISBN', 'Invalid ISBN')),
hol_agg as (
	select
		hext.instance_id as instance_id,
		string_agg(hext.type_name, ',') as hol_types
	from folio_derived.holdings_ext hext
	group by hext.instance_id),
hol_url_agg as (
	select
		hea.holdings_id as holdings_id,
		string_agg(hea.uri, ',') as hol_urls,
		string_agg(hea.link_text, ',') as hol_link_text,
		string_agg(hea.material_specification, ',') as hol_mat_spec,
		string_agg(hea.public_note, ',') as hol_pub_note
	from folio_derived.holdings_electronic_access hea
	group by hea.holdings_id),
inst_url_agg as (
	select
		hexu.instance_id as instance_id,
		string_agg(hua.hol_urls, ',') as hol_urls,
		string_agg(hua.hol_link_text, ',') as hol_link_text,
		string_agg(hua.hol_mat_spec, ',') as hol_mat_spec,
		string_agg(hua.hol_pub_note, ',') as hol_pub_notes
	from hol_url_agg hua
	left join folio_derived.holdings_ext hexu on hua.holdings_id = hexu.holdings_id
	group by hexu.instance_id)
select 
	oso.*,
	isbns.identifier as isbn_matched_id,
	isbns.identifier_type_name as isbn_matched_id_type,
	iexi.instance_hrid as isbn_matched_instance,
	iexi.status_name as instance_status, 
	iexi.discovery_suppress as instance_ds,
	hai.hol_types as hol_types,
	iua.hol_urls as hol_urls,
	iua.hol_link_text as platforms,
	iua.hol_pub_notes as hol_pub_notes
from cthom.oso_unowned oso
left join isbns on oso.isbn = isbns.identifier or oso.opisbn = isbns.identifier
left join folio_derived.instance_ext iexi on isbns.instance_id = iexi.instance_id
left join hol_agg hai on iexi.instance_id = hai.instance_id
left join inst_url_agg iua on iexi.instance_id = iua.instance_id
;

