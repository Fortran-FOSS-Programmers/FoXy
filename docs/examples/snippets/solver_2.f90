program solver
!< Tutorial, chapter 2: reading the case file.
use foxy
implicit none
type(xml_file)            :: case_file
integer(I4P)              :: iostat
character(len=256)        :: iomsg
real(R8P)                 :: dt, density
integer(I4P)              :: steps, ni, nj
logical                   :: adaptive
real(R8P),    allocatable :: domain(:)

call case_file%parse(filename='case.xml', iostat=iostat, iomsg=iomsg)
if (iostat/=0) then
   print '(A)', 'cannot read case.xml: '//trim(iomsg)
   stop 1
endif
call case_file%get_content(id=case_file%find(path='case/time/dt'), value=dt)
call case_file%get_content(id=case_file%find(path='case/time/steps'), value=steps)
call case_file%get_content(id=case_file%find(path='case/time/adaptive'), value=adaptive)
call case_file%get_content(id=case_file%find(path='case/mesh/domain'), values=domain)
call case_file%get_attribute(id=case_file%find(name='grid'), name='ni', value=ni)
call case_file%get_attribute(id=case_file%find(name='grid'), name='nj', value=nj)
print '(A,ES10.3,A,I0,A,L1)', 'dt = ', dt, ', steps = ', steps, ', adaptive = ', adaptive
print '(A,I0,A,I0,A,6F5.1)', 'grid ', ni, ' x ', nj, ', domain', domain
density = 1.0_R8P                                                           ! a default, kept on error
call case_file%get_content(id=case_file%find(path='case/fluid/densty'), value=density, iostat=iostat, iomsg=iomsg)
if (iostat==XML_NOT_FOUND) print '(A,F6.3)', 'not found, density kept: ', density
call case_file%get_attribute(id=case_file%find(name='density'), name='unit', value=steps, iostat=iostat, iomsg=iomsg)
if (iostat==XML_BAD_VALUE) print '(A)', trim(iomsg)
endprogram solver
