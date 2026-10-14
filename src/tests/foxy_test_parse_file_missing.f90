!< FoXy test.
program foxy_test_parse_file_missing
!< FoXy test.
use foxy, only: xml_file

implicit none
type(xml_file) :: xfile          !< XML file handler.
logical        :: test_passed(1) !< List of passed tests.

test_passed = .false.

print "(A)", 'Parsing a non existent file'
call xfile%parse(string='<a>previous data</a>')
call xfile%parse(filename='foxy_test_parse_file_missing_does_not_exist.xml')
test_passed(1) = xfile%stringify()==''
print "(A,L1)", 'Is parsed data empty? ', test_passed(1)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_parse_file_missing
