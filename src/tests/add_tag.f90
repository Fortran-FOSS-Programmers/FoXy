!< FoXy test.
program add_tag
!-----------------------------------------------------------------------------------------------------------------------------------
!< FoXy test.
!-----------------------------------------------------------------------------------------------------------------------------------
use foxy, only: tag, tag_nested, xml_file, xml_tag
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
character(len=:), allocatable :: source         !< String containing the source XML data.
character(len=:), allocatable :: parsed         !< String containing the parsed XML data.
type(xml_file)                :: a_file         !< XML tag handler.
type(xml_tag)                 :: a_tag          !< XML tag handler.
type(xml_tag)                 :: another_tag    !< XML tag handler.
logical                       :: test_passed(1) !< List of passed tests.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
test_passed = .false.

print "(A)", 'source'
source = '<first x="1" y="c" z="2">lorem ipsum...</first>'//new_line('a')//&
         '<second a1="2 "/>'//new_line('a')//&
         '<third>bye</third>'//new_line('a')//&
         '<fourth a="3">bye bye Mrs. Robinson</fourth>'//new_line('a')//&
         '<fift>'//new_line('a')//&
         '  <nested l="1">I am supported! Nested tag at level 1</nested>'//new_line('a')//&
         '</fift>'
print "(A)", source
print "(A)", 'created'
a_tag = tag(name='first', value='lorem ipsum...', attributes=reshape([['x', '1'], ['y', 'c'], ['z', '2']], [2,3]))
call a_file%add_tag(tag=a_tag)
a_tag = tag(name='second', attribute=['a1', '2 '], is_self_closing=.true.)
call a_file%add_tag(tag=a_tag)
a_tag = tag(name='third', value='bye')
call a_file%add_tag(tag=a_tag)
a_tag = tag(name='fourth', value='bye bye Mrs. Robinson', attribute=['a', '3'])
call a_file%add_tag(tag=a_tag)
another_tag = tag(name='nested', value='I am supported! Nested tag at level 1', attribute=['l', '1'])
a_tag = tag_nested(name='fift', value=another_tag, is_value_indented=.true.)
call a_file%add_tag(tag=a_tag)

parsed = a_file%stringify()
test_passed(1) = trim(adjustl(source))==trim(adjustl(parsed))
print "(A,L1)", parsed//' Is correct? ', test_passed(1)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
stop
!-----------------------------------------------------------------------------------------------------------------------------------
endprogram add_tag
