time = case_file%find(path='case/time')
call case_file%set_content(id=case_file%find(name='steps', parent=time), content='1000')
call case_file%set_attribute(id=case_file%find(name='dt', parent=time), name='unit', value='ms')
call case_file%set_content(id=case_file%find(name='dt', parent=time), content='0.5')
call case_file%delete_attribute(id=case_file%find(name='output'), name='every')
call case_file%delete_tag(name='notes')                      ! the tag and its subtree
call case_file%add_tag(xml_tag(name='restart'), parent=1, id=restart)
call case_file%add_tag(xml_tag(name='from', content='results.xml'), parent=restart)
call case_file%add_tag(xml_tag(name='step', content='500'), parent=restart)
