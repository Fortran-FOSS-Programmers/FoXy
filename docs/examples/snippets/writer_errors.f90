program writer_errors
use foxy
implicit none
type(xml_writer)   :: w
integer(I4P)       :: iostat
character(len=256) :: iomsg

call w%open()
call w%start('data')
call w%attribute('n', 1_I4P)
call w%attribute('n', 2_I4P)          ! a duplicate: the first error, kept; the next calls do nothing
call w%start('more')
call w%close(iostat=iostat, iomsg=iomsg)
print '(A,L1,A)', 'malformed: ', iostat==XML_MALFORMED, ', '//trim(iomsg)
endprogram writer_errors
