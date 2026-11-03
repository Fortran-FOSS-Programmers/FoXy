!< FoXy test.
program foxy_test_write_tag
!< FoXy test.
use foxy

implicit none
character(len=:), allocatable :: source         !< String containing the source XML data.
character(len=:), allocatable :: parsed         !< String containing the parsed XML data.
type(xml_tag)                 :: a_tag          !< XML tag handler.
type(xml_file)                :: xfile          !< XML file handler.
integer                       :: xunit          !< XML file unit.
integer(I4P)                  :: iostat         !< IO status.
character(len=128)            :: iomsg          !< IO message.
integer(I8P)                  :: file_size      !< Size of the written file.
logical                       :: test_passed(5) !< List of passed tests.

test_passed = .false.

print "(A)", 'source'
source = '<first x="1" y="c" z="2">lorem ipsum...</first>'
print "(A)", source
a_tag = xml_tag(name='first', content='lorem ipsum...', attributes=reshape([['x', '1'], ['y', 'c'], ['z', '2']], [2,3]))
open(newunit=xunit, file='parse_file_simple.xml', access='STREAM', form='UNFORMATTED', status='REPLACE')
print "(A)", 'write tag'
call a_tag%write(unit=xunit, form='unformatted')
close(unit=xunit)
call xfile%parse(filename='parse_file_simple.xml')
print "(A)", 'parsed data'
parsed = xfile%stringify()
print "(A)", parsed
test_passed(1) = trim(source)==trim(parsed)
print "(A,L1)", 'Is parsed data correct? ', test_passed(1)

print "(A)", 'source'
source = '<first x="1" y="c" z="2">'//new_line('a')//'  lorem ipsum...'//new_line('a')//'</first>'
print "(A)", source
a_tag = xml_tag(name='first', content='lorem ipsum...', attributes=reshape([['x', '1'], ['y', 'c'], ['z', '2']], [2,3]))
open(newunit=xunit, file='parse_file_simple.xml', access='STREAM', form='UNFORMATTED', status='REPLACE')
print "(A)", 'write tag'
call a_tag%write(unit=xunit, form='unformatted', is_indented=.true., is_content_indented=.true.)
close(unit=xunit)
call xfile%parse(filename='parse_file_simple.xml')
print "(A)", 'parsed data'
parsed = xfile%stringify()
print "(A)", parsed
test_passed(2) = trim(source)==trim(parsed)
print "(A,L1)", 'Is parsed data correct? ', test_passed(2)

open(newunit=xunit, file='parse_file_simple.xml', access='STREAM', form='UNFORMATTED', status='REPLACE')
print "(A)", 'write tag'
call a_tag%write(unit=xunit, form='unformatted', is_indented=.true., only_start=.true., end_record=new_line('a'))
call a_tag%write(unit=xunit, form='unformatted', is_content_indented=.true., only_content=.true., end_record=new_line('a'))
call a_tag%write(unit=xunit, form='unformatted', is_indented=.true., only_end=.true.)
close(unit=xunit)
call xfile%parse(filename='parse_file_simple.xml')
print "(A)", 'parsed data'
parsed = xfile%stringify()
print "(A)", parsed
test_passed(3) = trim(source)==trim(parsed)
print "(A,L1)", 'Is parsed data correct? ', test_passed(3)

! an unknown form: nothing written, XML_BAD_VALUE; a known one: iostat 0, iomsg blank
open(newunit=xunit, file='parse_file_simple.xml', access='STREAM', form='UNFORMATTED', status='REPLACE')
iomsg = 'not touched'
call a_tag%write(unit=xunit, form='formated', iostat=iostat, iomsg=iomsg)
inquire(unit=xunit, size=file_size)
test_passed(4) = iostat==XML_BAD_VALUE.and.index(iomsg, '"FORMATED"')>0.and.file_size==0
call a_tag%write(unit=xunit, iostat=iostat, iomsg=iomsg)
test_passed(4) = test_passed(4).and.iostat==0.and.iomsg==''
close(unit=xunit)
print "(A,L1)", 'Is an unknown form reported? ', test_passed(4)

! a tag without attributes or content: empty strings, not unallocated results
a_tag = xml_tag(name='empty')
test_passed(5) = a_tag%attributes()==''.and.len(a_tag%attributes())==0.and. &
                 a_tag%stringify(only_content=.true.)==''.and.len(a_tag%stringify(only_content=.true.))==0
print "(A,L1)", 'Are no attributes and no content empty strings? ', test_passed(5)

open(newunit=xunit, file='parse_file_simple.xml')
close(unit=xunit, status='DELETE')

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_write_tag
