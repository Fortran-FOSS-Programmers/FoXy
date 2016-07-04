!< FoXy test.
program write_tag
!-----------------------------------------------------------------------------------------------------------------------------------
!< FoXy test.
!-----------------------------------------------------------------------------------------------------------------------------------
use foxy
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
character(len=:), allocatable :: source         !< String containing the source XML data.
character(len=:), allocatable :: parsed         !< String containing the parsed XML data.
type(xml_tag)                 :: a_tag          !< XML tag handler.
type(xml_file)                :: xfile          !< XML file handler.
integer                       :: xunit          !< XML file unit.
logical                       :: test_passed(1) !< List of passed tests.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
test_passed = .false.

print "(A)", 'Input XML data:'
source = '<first x="1" y="c" z="2">lorem ipsum...</first>'
print "(A)", source
a_tag = xml_tag(name='first', content='lorem ipsum...', attributes=reshape([['x', '1'], ['y', 'c'], ['z', '2']], [2,3]))
open(newunit=xunit, file='parse_file_simple.xml', access='STREAM', form='UNFORMATTED')
print "(A)", 'write tag'
call a_tag%write(unit=xunit, form='unformatted')
close(unit=xunit)

call xfile%parse(filename='parse_file_simple.xml')
print "(A)", 'Parsed data'
parsed = xfile%stringify()
print "(A)", parsed
test_passed(1) = trim(source)==trim(parsed)
print "(A,L1)", 'Is parsed data correct? ', test_passed(1)

open(newunit=xunit, file='parse_file_simple.xml')
close(unit=xunit, status='DELETE')

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
stop
!-----------------------------------------------------------------------------------------------------------------------------------
endprogram write_tag
