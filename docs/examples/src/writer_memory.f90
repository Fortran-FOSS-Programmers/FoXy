program writer_memory
use foxy
implicit none
type(xml_writer) :: w

call w%open(indent=0_I4P)              ! no target: memory, no layout
call w%start('msg')
call w%attribute('ok', .true.)
call w%text('a < b')
call w%close()
print '(A)', w%string()
endprogram writer_memory
!run writer_memory writer_memory
