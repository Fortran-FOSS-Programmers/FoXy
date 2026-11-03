time = case_file%find(path='case/time')
call case_file%set_content(id=case_file%find(name='steps', parent=time), value=1000_I4P)   ! numbers as they read back
call case_file%set_attribute(id=case_file%find(name='dt', parent=time), name='unit', value='ms')
call case_file%set_content(id=case_file%find(name='dt', parent=time), value=0.5_R8P)
call case_file%delete_attribute(id=case_file%find(name='output'), name='every')
call case_file%delete_tag(name='notes')                      ! the tag and its subtree
call case_file%set_name(id=case_file%find(name='output'), name='results')     ! rename
call case_file%add_tag(xml_tag(name='restart'), after=time, id=restart)    ! right after <time>
call case_file%add_tag(xml_tag(name='from', content='results.xml'), parent=restart)
call case_file%add_tag(xml_tag(name='step', content='500'), parent=restart)
