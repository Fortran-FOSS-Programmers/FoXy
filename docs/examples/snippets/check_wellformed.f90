program check_wellformed
use foxy
implicit none
type(xml_file)     :: doc
integer(I4P)       :: iostat
character(len=256) :: iomsg
character(len=32)  :: sources(5), shown(5)
integer            :: s

sources = [character(len=32) :: '<a><b/></a>', '<a x="1" x="2"/>', '<a/><b/>', '<a>1 < 2</a>', '<a>'//achar(255)//'</a>']
shown = sources
shown(5) = '<a>\xFF</a>'                       ! the byte 0xFF, not UTF-8
do s=1, size(sources)
   call doc%parse(string=trim(sources(s)), iostat=iostat, iomsg=iomsg)
   if (iostat==0) then
      print '(A)', trim(shown(s))//': well-formed'
   else
      print '(A)', trim(shown(s))//': '//trim(iomsg)
   endif
enddo
endprogram check_wellformed
