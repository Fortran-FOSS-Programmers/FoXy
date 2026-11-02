program default_value
use foxy
implicit none
type(xml_file) :: doc
integer(I4P)   :: iostat, nk, cfl_steps

call doc%parse(filename='case.xml')
cfl_steps = 10                                                  ! the default
call doc%get_content(id=doc%find(path='case/time/cfl_steps'), value=cfl_steps, iostat=iostat)
print '(A,I0,A,L1)', 'cfl_steps = ', cfl_steps, ', from the file: ', iostat==0
nk = 1
call doc%get_attribute(id=doc%find(name='grid'), name='nk', value=nk, iostat=iostat)
print '(A,I0,A,L1)', 'nk = ', nk, ', from the file: ', iostat==0
endprogram default_value
