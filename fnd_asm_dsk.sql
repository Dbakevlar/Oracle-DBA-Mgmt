--Find ASM disk
select d.name disk, dg.name diskgroup
from v$asm_disk d, v$asm_diskgroup dg
where dg.group_number=d.group_number
and d.name like '%$node%';
