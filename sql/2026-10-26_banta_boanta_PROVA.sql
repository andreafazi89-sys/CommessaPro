-- PROVA (sola lettura): record che cambierebbero da "Vasile Banta" a "Vasile Boanta".
-- Tocca solo rapporti_v1 (operaio, colleghi) e cantieri_v1 (giornate legacy).
-- Non tocca: email di accesso, note_v1.
select d.chiave, e->>'id' as id, e->>'data' as data, e->>'operaio' as operaio,
       e->'colleghi' as colleghi_prima,
       replace(e::text, '"Vasile Banta"', '"Vasile Boanta"')::jsonb->'colleghi' as colleghi_dopo
from dati d, jsonb_array_elements(d.valore) e
where d.chiave in ('rapporti_v1','cantieri_v1')
  and e::text like '%"Vasile Banta"%'
order by 1, 3;
