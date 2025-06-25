!< FoXy test.
program foxy_test_parse_string_nested_tags
!< FoXy test.
use foxy, only: xml_file

implicit none
character(len=:), allocatable :: source         !< String containing the source XML data.
character(len=:), allocatable :: parsed         !< String containing the parsed XML data.
type(xml_file)                :: xfile          !< XML file handler.
logical                       :: test_passed(1) !< List of passed tests.
integer f

test_passed = .false.

print "(A)", 'Input XML data:'
source = '<tag1 level="1">lorem ipsum...</tag1>'//new_line('a')//&
         '<tag2 level="1" type="self_closing"/>'//new_line('a')//&
         '<tag3 level="1">bye</tag3>'//new_line('a')//&
         '<tag4 level="1">bye bye Mrs. Robinson</tag4>'//new_line('a')//&
         '<tag4 level="1" type="repeat">here we are, again</tag4>'//new_line('a')//&
         '<tag4 level="1" type="repeat_bis">and again</tag4>'//new_line('a')//&
         '<tag4 level="1" type="repeat_tris">forever</tag4>'//new_line('a')//&
         '<tag5>'//new_line('a')//&
         '  <tag6 level="2">content of tag6</tag6>'//new_line('a')//&
         '  <tag7 level="2">'//new_line('a')//&
         '    <tag7 level="3" type="nested">content of tag7 nested</tag7>'//new_line('a')//&
         '    <tag8 level="3">content of tag8</tag8>'//new_line('a')//&
         '    <tag7 level="3" type="nested repeat">content of tag7 nested repeat</tag7>'//new_line('a')//&
         '    <tag9 level="3">'//new_line('a')//&
         '      <tag10 level="4">content of tag10</tag10>'//new_line('a')//&
         '    </tag9>'//new_line('a')//&
         '    <tag7 level="3" type="nested">'//new_line('a')//&
         '      <tag7 level="4" type="nested double">content of tag7 nested double</tag7>'//new_line('a')//&
         '    </tag7>'//new_line('a')//&
         '  </tag7>'//new_line('a')//&
         '</tag5>'//new_line('a')//&
         '<tag11 level="1" type="self_closing"/>'
print "(A)", source

print "(A)", 'Parsing file'
call xfile%parse(string=source)
print "(A)", 'Parsed data'
parsed = xfile%stringify()
print "(A)", parsed
test_passed(1) = trim(adjustl(source))==trim(adjustl(parsed))
print "(A,L1)", 'Is parsed data correct? ', test_passed(1)

print "(A)", 'Parsed data linearized'
print "(A)", xfile%stringify(linearize=.true.)

open(newunit=f, file='source.xml')
write(f,'(A)') source
close(f)
open(newunit=f, file='parsed.xml')
write(f,'(A)') parsed
close(f)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
endprogram foxy_test_parse_string_nested_tags
