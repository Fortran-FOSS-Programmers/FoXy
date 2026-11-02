program list_attributes
use foxy
implicit none
type(xml_file) :: doc
integer(I4P)   :: grid, a

call doc%parse(filename='case.xml')
grid = doc%find(name='grid')
do a=1, doc%attributes_number(grid)
   print '(A)', doc%attribute_name(grid, a)//' = '//doc%attribute(grid, doc%attribute_name(grid, a))
enddo
endprogram list_attributes
!run list_attributes list_attributes
