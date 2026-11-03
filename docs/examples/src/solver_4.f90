program solver
!< Tutorial, chapter 4: editing and saving.
use foxy
implicit none
type(xml_file) :: case_file
integer(I4P)   :: time, restart, iostat

call case_file%parse(filename='case.xml')
!region edit
time = case_file%find(path='case/time')
call case_file%set_content(id=case_file%find(name='steps', parent=time), value=1000_I4P)   ! numbers as they read back
call case_file%set_attribute(id=case_file%find(name='dt', parent=time), name='unit', value='ms')
call case_file%set_content(id=case_file%find(name='dt', parent=time), value=0.5_R8P)
call case_file%delete_attribute(id=case_file%find(name='output'), name='every')
call case_file%delete_tag(name='notes')                      ! the tag and its subtree
call case_file%add_tag(xml_tag(name='restart'), parent=1, id=restart)
call case_file%add_tag(xml_tag(name='from', content='results.xml'), parent=restart)
call case_file%add_tag(xml_tag(name='step', content='500'), parent=restart)
!endregion edit
!region save
call case_file%save(filename='restart.xml', iostat=iostat)
!endregion save
print '(A,I0)', 'saved restart.xml, iostat = ', iostat
endprogram solver
!as solver
!run solver_4 solver
!run solver_4_cat cat restart.xml
