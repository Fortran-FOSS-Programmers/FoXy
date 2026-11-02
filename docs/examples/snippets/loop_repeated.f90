program loop_repeated
use foxy
implicit none
type(xml_file)            :: doc
integer(I4P), allocatable :: walls(:)
integer(I4P)              :: b

call doc%parse(filename='case.xml')
walls = doc%find_all(path='case/boundary')
do b=1, size(walls)
   if (doc%attribute(walls(b), 'type')=='wall') print '(A)', doc%attribute(walls(b), 'side')//' is a wall'
enddo
endprogram loop_repeated
