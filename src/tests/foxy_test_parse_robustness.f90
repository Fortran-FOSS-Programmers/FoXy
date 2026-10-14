!< FoXy test.
program foxy_test_parse_robustness
!< FoXy test.
!<
!< Valid XML that string-search parsing gets wrong: blanks inside tags, quoting, markup chars in attribute values,
!< comments, processing instructions, DOCTYPE, CDATA, malformed nesting.
use foxy, only: I4P, xml_file

implicit none
character(len=1), parameter   :: NL = new_line('a') !< New line.
character(len=1), parameter   :: TAB = achar(9)     !< Tab.
type(xml_file)                :: xfile              !< XML file handler.
integer(I4P)                  :: a                  !< Tag "a" ID.
logical                       :: test_passed(14)    !< List of passed tests.

test_passed = .false.

! blanks (new lines, tabs) inside tags
call parse('<a'//NL//'  k="1">1</a>')
test_passed(1) = a>0.and.xfile%attribute(id=a, name='k')=='1'.and.xfile%content(id=a)=='1'
call parse('<a'//TAB//'k="1">1</a>')
test_passed(2) = a>0.and.xfile%attribute(id=a, name='k')=='1'.and.xfile%content(id=a)=='1'
call parse('<a k="1"'//NL//'   j="2">1</a>')
test_passed(3) = xfile%attribute(id=a, name='k')=='1'.and.xfile%attribute(id=a, name='j')=='2'
print "(A,L1)", 'Are blanks inside tags handled? ', all(test_passed(1:3))

! quoting: single quotes, quotes of the other kind and markup characters inside values
call parse("<a k='1'>1</a>")
test_passed(4) = xfile%attribute(id=a, name='k')=='1'
call parse('<a k=''say "hi"''>1</a>')
test_passed(5) = xfile%attribute(id=a, name='k')=='say "hi"'.and.xfile%stringify()=='<a k="say &quot;hi&quot;">1</a>'
call parse('<a k="1>0" j="<">1</a>')
test_passed(6) = xfile%attribute(id=a, name='k')=='1>0'.and.xfile%attribute(id=a, name='j')=='<'.and. &
                 xfile%content(id=a)=='1'
print "(A,L1)", 'Is attributes quoting handled? ', all(test_passed(4:6))

! comments, processing instructions and DOCTYPE are skipped, the text around them is kept
call parse('<a>1<!-- a > b -->2</a>')
test_passed(7) = xfile%content(id=a)=='12'.and.size(xfile%children(a))==0
call parse('<a>1<?pi x > y?>2</a>')
test_passed(8) = xfile%content(id=a)=='12'
call parse('<?xml version="1.0"?>'//NL//'<!DOCTYPE a [ <!ENTITY e "x>y"> ]>'//NL//'<!-- c -->'//NL//'<a>1</a>')
test_passed(9) = a==1.and.size(xfile%children(0_I4P))==1.and.xfile%content(id=a)=='1'
print "(A,L1)", 'Are comments, PIs and DOCTYPE skipped? ', all(test_passed(7:9))

! CDATA is text, not markup
call parse('<a><![CDATA[1 < 2 && <b>not a tag</b>]]></a>')
test_passed(10) = size(xfile%children(a))==0.and.xfile%find(name='b')==0.and. &
                  xfile%stringify()=='<a><![CDATA[1 < 2 && <b>not a tag</b>]]></a>'
print "(A,L1)", 'Is CDATA not parsed as markup? ', test_passed(10)

! malformed nesting: an end tag closes up to its matching start tag, a stray end tag is ignored
call parse('<a><b>1</a>')
test_passed(11) = size(xfile%children(0_I4P))==1.and.size(xfile%children(a))==1.and.xfile%content('b')=='1'
call parse('<a>1</x></a>')
test_passed(12) = xfile%content(id=a)=='1'.and.size(xfile%children(0_I4P))==1
! spaces around "=" and tags names prefixes
call parse('<a k = "1"><ab>2</ab></a>')
test_passed(13) = xfile%attribute(id=a, name='k')=='1'.and.xfile%content('ab')=='2'
! end tag with blanks before ">"
call parse('<a>1</a  >')
test_passed(14) = xfile%content(id=a)=='1'.and.xfile%stringify()=='<a>1</a>'
print "(A,L1)", 'Is malformed nesting tolerated? ', all(test_passed(11:14))

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   subroutine parse(source)
   !< Parse source and get tag "a" ID.
   character(*), intent(in) :: source !< String containing the source XML data.

   print "(A)", 'Input XML data: '//source
   call xfile%parse(string=source)
   a = xfile%find(name='a')
   endsubroutine parse
endprogram foxy_test_parse_robustness
