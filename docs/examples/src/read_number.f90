program read_number
use foxy
implicit none
type(xml_file) :: doc
real(R8P)      :: dt
integer(I4P)   :: steps
logical        :: adaptive

call doc%parse(filename='case.xml')
call doc%get_content(id=doc%find(path='case/time/dt'), value=dt)
call doc%get_content(id=doc%find(path='case/time/steps'), value=steps)
call doc%get_content(id=doc%find(path='case/time/adaptive'), value=adaptive)
print '(ES10.3,1X,I0,1X,L1)', dt, steps, adaptive
endprogram read_number
!run read_number read_number
