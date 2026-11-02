program binary_appended
use foxy
implicit none
type(xml_writer) :: w
integer          :: unit

open(newunit=unit, file='appended.xml', access='stream', form='unformatted', status='replace')
call w%open(unit=unit)
call w%start('VTKFile')
call w%start('AppendedData')
call w%attribute('encoding', 'raw')
call w%flush()                         ! the start tag is complete: write to the unit directly
write(unit) '_', 3_I4P, 1.0_R4P
call w%end('AppendedData')
call w%close()
close(unit)
print '(A)', 'appended.xml written'
endprogram binary_appended
!run binary_appended binary_appended
