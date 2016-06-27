!< FoXy test.
program create_tag
!-----------------------------------------------------------------------------------------------------------------------------------
!< FoXy test.
!-----------------------------------------------------------------------------------------------------------------------------------
use foxy, only: tag, xml_tag
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
character(len=:), allocatable :: source         !< String containing the source XML data.
character(len=:), allocatable :: parsed         !< String containing the parsed XML data.
type(xml_tag)                 :: a_tag          !< XML tag handler.
logical                       :: test_passed(1) !< List of passed tests.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
test_passed = .false.

print "(A)", 'Input XML data:'
source = '<first x="1" y="c" z="2">lorem ipsum...</first>'
print "(A)", source

print "(A)", 'Create tag'
a_tag = tag(name='first', value='lorem ipsum...', attributes=reshape([['x', '1'], ['y', 'c'], ['z', '2']], [2,3]))
print "(A)", 'Parsed data'
parsed = a_tag%stringify()
print "(A)", parsed
test_passed(1) = trim(source)==trim(parsed)
print "(A,L1)", 'Is parsed data correct? ', test_passed(1)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
stop
!-----------------------------------------------------------------------------------------------------------------------------------
endprogram create_tag
