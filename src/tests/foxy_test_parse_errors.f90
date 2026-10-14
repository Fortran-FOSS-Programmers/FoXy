!< FoXy test.
program foxy_test_parse_errors
!< FoXy test.
!<
!< Malformed input and file errors reported by parse through iostat/iomsg (the first problem), the document still built.
use foxy, only: I4P, XML_MALFORMED, xml_file

implicit none
character(len=1), parameter :: NL = new_line('a') !< New line.
type(xml_file)              :: xfile              !< XML file handler.
integer(I4P)                :: iostat             !< IO status.
character(len=256)          :: iomsg              !< IO message.
logical                     :: test_passed(12)    !< List of passed tests.

test_passed = .false.

! valid input: iostat 0
test_passed(1) = is_valid('<a k="1>0" j=''2''>1<!-- c > d --><![CDATA[<x>]]><b/></a>')
test_passed(2) = is_valid('<?xml version="1.0"?>'//NL//'<!DOCTYPE a [ <!ENTITY e "x>y"> ]>'//NL// &
                          '<a>'//NL//'  <b>1</b>'//NL//'</a>')
test_passed(3) = is_valid('<a>1</a>'//NL//'<b>2</b>') ! more root tags are allowed
print "(A,L1)", 'Is valid input accepted? ', all(test_passed(1:3))

! malformed input: XML_MALFORMED, iomsg locates the first problem, the document is still built (tolerant parsing)
test_passed(4) = is_malformed('<a>'//NL//'<b>1</a>', ['line 2      ', '</a>        ', '<b>         '])
test_passed(5) = is_malformed('<a>1</x></a>', ['line 1      ', '</x>        ', 'without     '])
test_passed(6) = is_malformed('<a>'//NL//'<b>1</b>', ['line 1      ', 'unclosed    ', '<a>         '])
test_passed(7) = is_malformed('<a><!-- x</a>', ['unterminated', 'comment     ', 'line 1      '])
test_passed(8) = is_malformed('<a>1 < 2</a>', ['<           ', 'line 1      ', 'tag         '])
test_passed(9) = is_malformed('<a k=1>2</a>', ['unquoted    ', '"k"         ', '<a>         '])
test_passed(10) = xfile%content('a')=='2' ! still built
print "(A,L1)", 'Is malformed input reported? ', all(test_passed(4:10))

! file errors: the runtime iostat/iomsg are passed through
call xfile%parse(filename='foxy_test_parse_errors_missing_file.xml', iostat=iostat, iomsg=iomsg)
print "(A,I0,A)", 'Missing file: iostat=', iostat, ' iomsg='//trim(iomsg)
test_passed(11) = iostat/=0.and.iostat/=XML_MALFORMED.and.len_trim(iomsg)>0.and.xfile%stringify()==''
! iostat and iomsg are optional: without them parsing is silent, as before
call xfile%parse(string='<a>1</x></a>')
test_passed(12) = xfile%content('a')=='1'
print "(A,L1)", 'Are file errors reported, and reporting optional? ', all(test_passed(11:12))

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   function is_valid(source)
   !< Check that source is parsed without errors.
   character(*), intent(in) :: source   !< String containing the source XML data.
   logical                  :: is_valid !< Check result.

   iomsg = 'not set'
   call xfile%parse(string=source, iostat=iostat, iomsg=iomsg)
   is_valid = iostat==0
   print "(A,I0,A)", 'Valid input: iostat=', iostat, ' for '//source
   endfunction is_valid

   function is_malformed(source, expected)
   !< Check that source is reported as malformed, with iomsg containing all the expected substrings.
   character(*), intent(in) :: source       !< String containing the source XML data.
   character(*), intent(in) :: expected(1:) !< Substrings expected into iomsg.
   logical                  :: is_malformed !< Check result.
   integer                  :: e            !< Counter.

   call xfile%parse(string=source, iostat=iostat, iomsg=iomsg)
   print "(A,I0,A)", 'Malformed input: iostat=', iostat, ' iomsg='//trim(iomsg)
   is_malformed = iostat==XML_MALFORMED
   do e=1, size(expected, dim=1)
      is_malformed = is_malformed.and.index(iomsg, trim(expected(e)))>0
   enddo
   endfunction is_malformed
endprogram foxy_test_parse_errors
