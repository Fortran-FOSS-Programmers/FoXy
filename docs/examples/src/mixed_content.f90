program mixed_content
use foxy
implicit none
type(xml_file) :: doc

call doc%parse(string='<p>Use <code>dt</code> &lt; 1e-2, see <![CDATA[<ref/>]]><!-- todo -->.</p>')
print '(A)', '['//doc%content('p')//']'           ! direct text: children excluded, comment removed, CDATA literal
print '(A)', '['//doc%content('code')//']'
print '(A)', doc%stringify()                       ! written back as read
endprogram mixed_content
!run mixed_content mixed_content
