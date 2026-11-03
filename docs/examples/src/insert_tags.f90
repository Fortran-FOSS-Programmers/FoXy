program insert_tags
use foxy
implicit none
type(xml_file) :: doc

call doc%parse(string='<list><a/><c/></list>')
call doc%add_tag(xml_tag(name='b', is_self_closing=.true.), after=doc%find(name='a'))      ! after a sibling
call doc%add_tag(xml_tag(name='first', is_self_closing=.true.), before=doc%find(name='a'))  ! before a sibling
call doc%set_name(id=doc%find(name='c'), name='last')     ! an insertion renumbers the tags after it: find them again
print '(A)', doc%stringify()
endprogram insert_tags
!run insert_tags insert_tags
