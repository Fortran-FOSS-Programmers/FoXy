program delete_tags
use foxy
implicit none
type(xml_file) :: doc

call doc%parse(string='<r><keep/><drop><child/></drop><keep/><drop/></r>')
call doc%delete_tag(id=doc%find(name='drop'))       ! the first one, with its child
call doc%delete_tag(name='drop')                    ! the next first one
print '(A)', doc%stringify()
endprogram delete_tags
!run delete_tags delete_tags
