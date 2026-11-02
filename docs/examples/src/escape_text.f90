program escape_text
use foxy
implicit none
type(xml_file)                :: doc
character(len=:), allocatable :: user_text

user_text = 'p < 1 & "fast"'
call doc%add_tag(xml_tag(name='note', content=xml_escape(user_text)))   ! contents are stored as they are
print '(A)', doc%stringify()
print '(A)', doc%content('note')                                          ! read back decoded
endprogram escape_text
!run escape_text escape_text
