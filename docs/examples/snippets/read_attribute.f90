program read_attribute
use foxy
implicit none
type(xml_file) :: doc
integer(I4P)   :: grid, ni, nj

call doc%parse(filename='case.xml')
grid = doc%find(name='grid')
print '(A)', 'ni as text: '//doc%attribute(grid, 'ni')
call doc%get_attribute(id=grid, name='ni', value=ni)
call doc%get_attribute(id=grid, name='nj', value=nj)
print '(A,I0)', 'cells: ', ni*nj
endprogram read_attribute
