!< FoXy test.
program foxy_test_parse_string_self_closing_nested
!< FoXy test.
use foxy, only: xml_file

implicit none
character(len=:), allocatable :: source         !< String containing the source XML data.
type(xml_file)                :: xfile          !< XML file handler.
logical                       :: test_passed(3) !< List of passed tests.

test_passed = .false.

print "(A)", 'Input XML data (self closing child named as its parent):'
source = '<a>outer<a x="1"/></a>'
print "(A)", source
call xfile%parse(string=source)
print "(A)", 'Content of tag "a": "'//xfile%content(name='a')//'"'
test_passed(1) = xfile%content(name='a')=='outer'
print "(A,L1)", 'Is content correct? ', test_passed(1)

print "(A)", 'Input XML data (attribute-less self closing child named as its parent):'
source = '<a>outer<a/></a>'
print "(A)", source
call xfile%parse(string=source)
print "(A)", 'Content of tag "a": "'//xfile%content(name='a')//'"'
test_passed(2) = xfile%content(name='a')=='outer'
print "(A,L1)", 'Is content correct? ', test_passed(2)

print "(A)", 'Input XML data (nested tag and following sibling named as the parent):'
source = '<a><a>x</a></a><a>y</a>'
print "(A)", source
call xfile%parse(string=source)
! the outer end tag "</a>" starts at character 12, not at the sibling end tag (character 20)
test_passed(3) = index(xfile%stringify(linearize=.true.), 'char pos indexes:"+1,+3,+12"')>0
print "(A,L1)", 'Is outer end tag position correct? ', test_passed(3)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_parse_string_self_closing_nested
