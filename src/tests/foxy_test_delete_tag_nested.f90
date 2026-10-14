!< FoXy test.
program foxy_test_delete_tag_nested
!< FoXy test.
use foxy, only: xml_file, xml_tag

implicit none
character(len=1), parameter   :: NL = new_line('a') !< New line.
character(len=:), allocatable :: source             !< String containing the source XML data.
character(len=:), allocatable :: expected           !< String containing the expected XML data.
type(xml_file)                :: xfile              !< XML file handler.
logical                       :: test_passed(6)     !< List of passed tests.

test_passed = .false.

source = '<a>1</a>'//NL//'<b>'//NL//'  <c>2</c>'//NL//'  <d>3</d>'//NL//'</b>'//NL//'<e>4</e>'
print "(A)", 'Input XML data:'
print "(A)", source
call xfile%parse(string=source)

! deleting a tag placed before nested tags must keep the hierarchy consistent
call xfile%delete_tag(name='a')
expected = '<b>'//NL//'  <c>2</c>'//NL//'  <d>3</d>'//NL//'</b>'//NL//'<e>4</e>'
test_passed(1) = is_stringify_correct(expected)

! deleting a nested tag must remove it from its parent children
call xfile%delete_tag(name='c')
expected = '<b>'//NL//'  <d>3</d>'//NL//'</b>'//NL//'<e>4</e>'
test_passed(2) = is_stringify_correct(expected)

! deleting a tag must delete its whole subtree
call xfile%delete_tag(name='b')
expected = '<e>4</e>'
test_passed(3) = is_stringify_correct(expected)
test_passed(4) = xfile%content(name='d')==''.and.xfile%content(name='e')=='4'
print "(A,L1)", 'Is subtree content deleted? ', test_passed(4)

! tags IDs must be renumbered as the tags indexes
test_passed(5) = index(xfile%stringify(linearize=.true.), 'id:              "+1"')>0
print "(A,L1)", 'Is the remaining tag renumbered? ', test_passed(5)

! tags added must have the ID of their index
call xfile%free
call xfile%add_tag(tag=xml_tag(name='x', content='1'))
call xfile%add_tag(tag=xml_tag(name='y', content='2'))
test_passed(6) = index(xfile%stringify(linearize=.true.), 'id:              "+2"')>0
print "(A,L1)", 'Has the added tag its index as ID? ', test_passed(6)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   function is_stringify_correct(expected) result(is_correct)
   !< Check the stringified XML data.
   character(*), intent(in)      :: expected   !< Expected XML data.
   logical                       :: is_correct !< Check result.
   character(len=:), allocatable :: parsed     !< String containing the parsed XML data.

   parsed = xfile%stringify()
   print "(A)", 'Parsed data after deletion:'
   print "(A)", parsed
   is_correct = parsed==expected
   print "(A,L1)", 'Is correct? ', is_correct
   endfunction is_stringify_correct
endprogram foxy_test_delete_tag_nested
