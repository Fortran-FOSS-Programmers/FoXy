program solver
!< Tutorial, chapter 8: robust input and text.
use foxy
implicit none
type(xml_file)     :: case_file
integer(I4P)       :: iostat
character(len=256) :: iomsg

call case_file%parse(filename='broken.xml', iostat=iostat, iomsg=iomsg)
if (iostat==XML_MALFORMED) print '(A)', 'broken.xml: '//trim(iomsg)
print '(A)', 'dt is still read: '//case_file%content('dt')          ! tolerant: the document is built anyway
call case_file%parse(filename='case.xml')
print '(A)', 'notes:  '//case_file%content('notes')                  ! references decoded, CDATA literal
print '(A)', 'escape: '//xml_escape('a < b & "c"')
print '(A)', 'raw:    '//xml_unescape('1 &lt; 2 &#x26; &#233;t&#233;')
call case_file%parse(string='<p>the <b>lid</b> moves at <v>1</v> m/s</p>')
print '(A)', 'mixed:  '//case_file%content('p')                     ! the direct text of p, children excluded
print '(A)', case_file%stringify()                                   ! written back as it was
endprogram solver
