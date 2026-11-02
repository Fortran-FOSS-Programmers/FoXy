program namespaces_clark
use foxy
implicit none
type(xml_file) :: doc
integer(I4P)   :: t

call doc%parse(filename='coupled.xml')
t = doc%find(name='{https://example.org/thermal}dt')
print '(A)', doc%name(t)//' in '//doc%namespace(t)//' = '//doc%content(id=t)
endprogram namespaces_clark
!run namespaces_clark namespaces_clark
