select 
   a.ksppinm "Parameter|Name", 
   c.ksppstvl "Instance Value"
from 
   x$ksppi a, 
   x$ksppcv b, 
   x$ksppsv c
where 
   a.indx = b.indx 
and 
   a.indx = c.indx
and 
   ksppinm like '%asm%'
order by 
   a.ksppinm;