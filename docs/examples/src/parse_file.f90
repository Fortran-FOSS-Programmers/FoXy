program parse_file
use foxy
implicit none
type(xml_file)     :: doc
integer(I4P)       :: iostat
character(len=256) :: iomsg

call doc%parse(filename='case.xml', iostat=iostat, iomsg=iomsg)
if (iostat/=0) error stop 'case.xml: '//trim(iomsg)
print '(A,I0,A)', 'case.xml: ', doc%tags_number(), ' tags'
endprogram parse_file
!run parse_file parse_file
