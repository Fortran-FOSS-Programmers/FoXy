program solver
!< Tutorial, chapter 1: a first document.
use foxy
implicit none
type(xml_file)                :: case_file
character(len=:), allocatable :: dt
integer(I4P)                  :: time

call case_file%parse(string='<case name="cavity">'// &
                              '<time><dt unit="s">1.0e-3</dt><steps>500</steps></time>'// &
                            '</case>')
!region content
dt = case_file%content('dt')               ! the text of the first tag named dt
print '(A)', 'dt    = '//dt
time = case_file%find(path='case/time')    ! a tag ID, 0 if there is none
print '(A,I0)', 'time  = tag ', time
print '(A)', 'steps = '//case_file%content(id=case_file%find(name='steps', parent=time))
print '(A)', 'name  = '//case_file%attribute(id=1, name='name')
!endregion content
print '(A)', case_file%stringify()
endprogram solver
!as solver
!run solver_1 solver
