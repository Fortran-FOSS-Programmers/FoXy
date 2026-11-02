program walk_tree
use foxy
implicit none
type(xml_file) :: doc
integer(I4P)   :: t

call doc%parse(filename='case.xml')
do t=1, doc%tags_number()                 ! every tag, in document order
   print '(A)', repeat('. ', doc%level(t)-1)//doc%name(t)
enddo
endprogram walk_tree
