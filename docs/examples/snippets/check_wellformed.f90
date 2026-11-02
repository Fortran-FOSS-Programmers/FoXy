program check_wellformed
use foxy
implicit none
type(xml_file)     :: doc
integer(I4P)       :: iostat
character(len=256) :: iomsg
character(len=32)  :: sources(4)
integer            :: s

sources = [character(len=32) :: '<a><b/></a>', '<a x="1" x="2"/>', '<a/><b/>', '<a>1 < 2</a>']
do s=1, size(sources)
   call doc%parse(string=trim(sources(s)), iostat=iostat, iomsg=iomsg)
   if (iostat==0) then
      print '(A)', trim(sources(s))//': well-formed'
   else
      print '(A)', trim(sources(s))//': '//trim(iomsg)
   endif
enddo
endprogram check_wellformed
