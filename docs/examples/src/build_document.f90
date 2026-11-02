program build_document
use foxy
implicit none
type(xml_file) :: doc
integer(I4P)   :: root, solver

call doc%add_tag(xml_tag(name='config'), id=root)
call doc%add_tag(xml_tag(name='dt', content='0.01', attributes_stream='unit="s"'), parent=root)
call doc%add_tag(xml_tag(name='solver', attributes_stream='kind="cg" tol="1e-6"'), parent=root, id=solver)
call doc%add_tag(xml_tag(name='restart', is_self_closing=.true.), parent=solver)
print '(A)', doc%stringify()
endprogram build_document
!run build_document build_document
