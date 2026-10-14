!< FoXy test.
program foxy_test_attribute_values
!< FoXy test.
!<
!< Attribute values are normalized on read (XML 1.0, 3.3.3): each literal blank (tab, new line, carriage return, a CR LF
!< pair counting as one) becomes a space, while blanks written as character references are kept. Leading and trailing
!< spaces are trimmed when parsed, unless parse is asked to keep them.
use foxy, only: xml_file, xml_tag

implicit none
character(len=1), parameter   :: NL = new_line('a') !< New line.
character(len=1), parameter   :: TAB = achar(9)     !< Tab.
character(len=1), parameter   :: CR = achar(13)     !< Carriage return.
character(len=:), allocatable :: source             !< String containing the source XML data.
type(xml_file)                :: xfile              !< XML file handler.
type(xml_tag)                 :: tag                !< XML tag.
logical                       :: test_passed(9)     !< List of passed tests.

test_passed = .false.

source = '<a k="1'//TAB//'2'//NL//'3'//CR//NL//'4'//CR//'5" j="x&#10;y&#9;z" h="plain"/>'
call xfile%parse(string=source)
test_passed(1) = xfile%attribute(id=1, name='k')=='1 2 3 4 5'
test_passed(2) = xfile%attribute(id=1, name='j')=='x'//NL//'y'//TAB//'z' ! references are data, not layout
test_passed(3) = xfile%attribute(id=1, name='h')=='plain'
test_passed(4) = xfile%stringify()==source ! the stored value keeps the source text
print "(A,L1)", 'Are parsed attribute values normalized on read? ', all(test_passed(1:4))

tag = xml_tag(name='b', attributes=reshape([character(len=3) :: 'k', 'u'//NL//'v'], [2,1]))
test_passed(5) = tag%get_attribute(name='k')=='u v'
test_passed(6) = tag%get_attribute(name='missing')==''
print "(A,L1)", 'Are tag attribute values normalized on read? ', all(test_passed(5:6))

! leading and trailing spaces of values: trimmed when parsed by default, kept (they are data) on request
source = '<a k=" 1 2 " long_name="x"/>' ! a value shorter than its name is not padded
call xfile%parse(string=source)
test_passed(7) = xfile%attribute(id=1, name='k')=='1 2'.and.xfile%stringify()=='<a k="1 2" long_name="x"/>'
call xfile%parse(string=source, sanitize_attributes_value=.false.)
test_passed(8) = xfile%attribute(id=1, name='k')==' 1 2 '.and.xfile%attribute(id=1, name='long_name')=='x'.and. &
                 xfile%stringify()==source
call xfile%parse(string=source, sanitize_attributes_value=.true.)
test_passed(9) = xfile%attribute(id=1, name='k')=='1 2'
print "(A,L1)", 'Are value spaces trimmed by default and kept on request? ', all(test_passed(7:9))

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_attribute_values
