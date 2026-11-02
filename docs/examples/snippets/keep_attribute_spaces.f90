program keep_attribute_spaces
use foxy
implicit none
type(xml_file) :: doc

call doc%parse(string='<a label="  padded  "/>')
print '(A)', '['//doc%attribute(1, 'label')//']'                     ! trimmed by default
call doc%parse(string='<a label="  padded  "/>', sanitize_attributes_value=.false.)
print '(A)', '['//doc%attribute(1, 'label')//']'                     ! kept, as XML requires
endprogram keep_attribute_spaces
