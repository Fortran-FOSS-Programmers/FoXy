program solver
!< Tutorial, chapter 7: namespaces.
use foxy
implicit none
type(xml_file)            :: coupled
integer(I4P), allocatable :: ids(:)
integer(I4P)              :: t

call coupled%parse(filename='coupled.xml')
!region resolve
ids = coupled%find_all(name='{https://example.org/thermal}dt')   ! Clark notation: {namespace}local name
do t=1, coupled%tags_number()
   print '(A)', coupled%name(t)//' -> prefix "'//coupled%prefix(t)//'", local "'//coupled%local_name(t)// &
                '", namespace "'//coupled%namespace(t)//'"'
enddo
!endregion resolve
!region queries
print '(A)', 'thermal dt: '//coupled%content(id=ids(1))
t = coupled%find(path='f:coupled/f:case/f:dt', namespaces='xmlns:f="https://example.org/flow"')   ! your own prefixes
print '(A)', 'flow dt:    '//coupled%content(id=t)
t = coupled%find(name='m:conductivity', namespaces='xmlns:m="https://example.org/materials"')
print '(A)', 'k:          '//coupled%content(id=t)
print '(A,I0)', 'literal "dt" matches: ', size(coupled%find_all(name='dt'))       ! names without a map: literal
!endregion queries
endprogram solver
!as solver
!run solver_7 solver
