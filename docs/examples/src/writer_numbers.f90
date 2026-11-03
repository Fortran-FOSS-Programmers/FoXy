program writer_numbers
use foxy
implicit none
type(xml_writer) :: w

call w%open()
call w%start('cell')
call w%attribute('dt', 0.1_R8P)                        ! the shortest text that reads back: 0.1
call w%attribute('extent', [0_I4P, 63_I4P, 0_I4P, 31_I4P])
call w%start('volume')
call w%text(1._R8P/3._R8P)
call w%end('volume')
call w%start('center')
call w%text([0.5_R8P, 0.25_R8P, 0._R8P], fmt='(F5.3)')
call w%end('center')
call w%start('active')
call w%text(.true.)
call w%end('active')
call w%close()
write(*, '(A)', advance='no') w%string()        ! the string ends with a new line
endprogram writer_numbers
!run writer_numbers writer_numbers
