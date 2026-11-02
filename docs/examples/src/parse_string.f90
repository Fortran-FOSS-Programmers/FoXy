program parse_string
use foxy
implicit none
type(xml_file) :: doc

call doc%parse(string='<point x="1" y="2">origin</point>')
print '(A)', doc%content('point')//' at '//doc%attribute(1, 'x')//','//doc%attribute(1, 'y')
endprogram parse_string
!run parse_string parse_string
