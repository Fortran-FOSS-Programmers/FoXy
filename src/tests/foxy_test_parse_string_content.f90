!< FoXy test.
program foxy_test_parse_string_content
!< FoXy test.
use foxy, only: xml_file

implicit none
character(len=*), parameter   :: FIRST = '<first x="1" y="c" z="2">lorem ipsum...</first>' !< First tag.
character(len=*), parameter   :: SECOND = '<second a1="2"/>'                               !< Second tag, self closing.
character(len=*), parameter   :: THIRD = '<third>bye</third>'                              !< Third tag.
character(len=1), parameter   :: NL = new_line('a')                                       !< New line.
character(len=:), allocatable :: source                                                   !< String containing the source XML data.
type(xml_file)                :: xfile                                                    !< XML file handler.
logical                       :: test_passed(6)                                           !< List of passed tests.

test_passed = .false.

! content must not depend on the tags order, a self closing tag has no content (issue #7)
test_passed(1) = is_content_correct(FIRST//NL//SECOND//NL//THIRD)
test_passed(2) = is_content_correct(SECOND//NL//FIRST//NL//THIRD)
test_passed(3) = is_content_correct(THIRD//NL//SECOND//NL//FIRST)
test_passed(4) = is_content_correct('<zero>'//NL//'  '//THIRD//NL//'  '//SECOND//NL//'  '//FIRST//NL//'</zero>')

! a tag containing only nested tags has no content, blanks (new lines included) are not content
source = '<origin>'//NL//'  <value>-121.1885</value>'//NL//'</origin>'
print "(A)", 'Input XML data:'
print "(A)", source
call xfile%parse(string=source)
print "(A)", 'Content of tag "origin": "'//xfile%content(name='origin')//'"'
print "(A)", 'Content of tag "value": "'//xfile%content(name='value')//'"'
test_passed(5) = xfile%content(name='origin')==''
test_passed(6) = xfile%content(name='value')=='-121.1885'
print "(A,L1)", 'Is content correct? ', all(test_passed(5:6))

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   function is_content_correct(source) result(is_correct)
   !< Parse source and check the content of tags first, second and third.
   character(*), intent(in) :: source     !< String containing the source XML data.
   logical                  :: is_correct !< Check result.
   type(xml_file)           :: xfile      !< XML file handler.

   print "(A)", 'Input XML data:'
   print "(A)", source
   call xfile%parse(string=source)
   print "(A)", 'Content of tags "first", "second", "third": "'//xfile%content(name='first')//'", "'// &
                xfile%content(name='second')//'", "'//xfile%content(name='third')//'"'
   is_correct = xfile%content(name='first')=='lorem ipsum...'.and. &
                xfile%content(name='second')==''.and.              &
                xfile%content(name='third')=='bye'
   print "(A,L1)", 'Is content correct? ', is_correct
   endfunction is_content_correct
endprogram foxy_test_parse_string_content
