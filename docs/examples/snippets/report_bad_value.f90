program report_bad_value
use foxy
implicit none
type(xml_file)     :: doc
integer(I4P)       :: iostat, n
character(len=256) :: iomsg

call doc%parse(string='<run><steps>5OO</steps></run>')
call doc%get_content(id=doc%find(name='steps'), value=n, iostat=iostat, iomsg=iomsg)
if (iostat==XML_BAD_VALUE) print '(A)', trim(iomsg)
call doc%get_content(id=doc%find(name='step'), value=n, iostat=iostat, iomsg=iomsg)
if (iostat==XML_NOT_FOUND) print '(A)', trim(iomsg)
endprogram report_bad_value
