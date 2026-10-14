!< FoXy test.
program foxy_test_parse_mixed_content
!< FoXy test.
!<
!< Mixed content (text around child tags) and CDATA sections.
use foxy, only: I4P, xml_file

implicit none
character(len=1), parameter   :: NL = new_line('a') !< New line.
character(len=:), allocatable :: source             !< String containing the source XML data.
type(xml_file)                :: xfile              !< XML file handler.
integer(I4P)                  :: a                  !< Tag "a" ID.
logical                       :: test_passed(10)    !< List of passed tests.

test_passed = .false.

! the direct text of a tag is its text plus the text after each child (tail), children text excluded
call parse('<a>x<b>1</b>y<c/>z</a>')
test_passed(1) = xfile%content(id=a)=='xyz'.and.xfile%content('a')=='xyz'.and.xfile%content('b')=='1'.and. &
                 size(xfile%children(a))==2
test_passed(2) = xfile%stringify()==source ! mixed content tags are written inline, not reformatted
call parse('<a>x <b>1</b> y</a>')
test_passed(3) = xfile%content(id=a)=='x  y'.and.xfile%stringify()==source
print "(A,L1)", 'Is mixed content kept? ', all(test_passed(1:3))

! a mixed content tag inside a formatted document: only the mixed one is inline
call parse('<r>'//NL//'  <p>see <b>this</b> now</p>'//NL//'  <q>1</q>'//NL//'</r>')
test_passed(4) = xfile%stringify()==source.and.xfile%content('p')=='see  now'.and.xfile%content('q')=='1'
! tags without mixed content are formatted as before, blank tails are layout
call parse('<r><q>1</q>  <s/></r>')
test_passed(5) = xfile%stringify()=='<r>'//NL//'  <q>1</q>'//NL//'  <s/>'//NL//'</r>'.and.xfile%content('r')==''
print "(A,L1)", 'Is mixed content written inline only where needed? ', all(test_passed(4:5))

! CDATA is literal: not decoded, its blanks are data
call parse('<a> <![CDATA[ 1 < 2 &amp; ]]> </a>')
test_passed(6) = xfile%content(id=a)==' 1 < 2 &amp; '
call parse('<a>x &amp; <![CDATA[&amp;]]></a>')
test_passed(7) = xfile%content(id=a)=='x & &amp;'
call parse('<a><![CDATA[x]]><b/><![CDATA[y]]></a>')
test_passed(8) = xfile%content(id=a)=='xy'.and.xfile%stringify()==source
print "(A,L1)", 'Is CDATA literal? ', all(test_passed(6:8))

! deleting a child deletes its tail too
call parse('<a>x<b>1</b>y</a>')
call xfile%delete_tag(name='b')
test_passed(9) = xfile%content('a')=='x'.and.xfile%stringify()=='<a>x</a>'
! text between root tags is not part of any tag content
call parse('<a>1</a>stray<c>2</c>')
test_passed(10) = xfile%content('a')=='1'.and.xfile%content('c')=='2'
print "(A,L1)", 'Are tails consistent? ', all(test_passed(9:10))

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   subroutine parse(string)
   !< Parse string (saved as source) and get tag "a" ID.
   character(*), intent(in) :: string !< String containing the source XML data.

   source = string
   print "(A)", 'Input XML data: '//source
   call xfile%parse(string=source)
   a = xfile%find(name='a')
   endsubroutine parse
endprogram foxy_test_parse_mixed_content
