program set_numbers
use foxy
implicit none
type(xml_file) :: doc
integer(I4P)   :: grid

call doc%parse(string='<mesh><grid/><domain/><origin/></mesh>')
grid = doc%find(name='grid')
call doc%set_attribute(id=grid, name='ni', value=128_I4P)                     ! an integer
call doc%set_attribute(id=grid, name='spacing', value=0.1_R8P)                ! a real: its shortest text
call doc%set_attribute(id=grid, name='periodic', value=.true.)                ! a logical
call doc%set_content(id=doc%find(name='domain'), values=[0._R8P, 1._R8P, 0._R8P, 0.5_R8P]) ! a list
call doc%set_content(id=doc%find(name='origin'), values=[0._R8P, 0.25_R8P], fmt='(F5.2)')  ! formatted
print '(A)', doc%stringify()
endprogram set_numbers
