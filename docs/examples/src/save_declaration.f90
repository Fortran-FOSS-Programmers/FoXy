program save_declaration
use foxy
implicit none
type(xml_file) :: doc
character(len=64) :: line
integer :: unit

call doc%add_tag(xml_tag(name='empty', is_self_closing=.true.))
call doc%save(filename='declared.xml', is_declared=.true.)     ! adds <?xml version="1.0"?> if missing
open(newunit=unit, file='declared.xml')
read(unit, '(A)') line ; print '(A)', trim(line)
read(unit, '(A)') line ; print '(A)', trim(line)
close(unit)
endprogram save_declaration
!run save_declaration save_declaration
