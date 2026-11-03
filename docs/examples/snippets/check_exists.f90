program check_exists
use foxy
implicit none
type(xml_file) :: doc
integer(I4P)   :: id

call doc%parse(filename='case.xml')
id = doc%find(path='case/time/dt')                              ! 0 if there is no such tag
if (id>0) print '(A)', 'dt is set: '//doc%content(id=id)
id = doc%find(path='case/time/cfl')
if (id==0) print '(A)', 'no cfl: the default is used'
print '(A,L1)', 'the west boundary has a velocity: ', size(doc%select('case/boundary[@side="west"]/velocity'))>0
print '(A,L1)', 'the case has a name: ', doc%attribute(id=doc%find(name='case'), name='name')/=''
endprogram check_exists
