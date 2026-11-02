program children
use foxy
implicit none
type(xml_file)            :: doc
integer(I4P), allocatable :: kids(:)
integer(I4P)              :: k, time

call doc%parse(filename='case.xml')
time = doc%find(path='case/time')
kids = doc%children(time)
do k=1, size(kids)
   print '(A)', doc%name(kids(k))//' = '//doc%content(id=kids(k))
enddo
print '(A,I0,A,I0)', 'parent of dt: ', doc%parent(doc%find(name='dt')), ', level of dt: ', doc%level(doc%find(name='dt'))
endprogram children
!run children children
