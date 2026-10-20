-- PROVA (sola lettura): record che cambierebbero da "Michele Poveste" a "Mihai Poveste".
-- Tocca solo rapporti_v1 (operaio, colleghi) e cantieri_v1 (giornate legacy).
-- Non tocca: email di accesso, note_v1 (Michele Gentile e' un'altra persona), chiavi di backup.
select d.chiave, e->>'id' as id, e->>'data' as data, e->>'operaio' as operaio,
       e->'colleghi' as colleghi_prima,
       replace(e::text, '"Michele Poveste"', '"Mihai Poveste"')::jsonb->'colleghi' as colleghi_dopo
from dati d, jsonb_array_elements(d.valore) e
where d.chiave in ('rapporti_v1','cantieri_v1')
  and e::text like '%"Michele Poveste"%'
order by 1, 3;
