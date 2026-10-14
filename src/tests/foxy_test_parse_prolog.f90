!< FoXy test.
program foxy_test_parse_prolog
!< FoXy test.
!<
!< The prolog (XML declaration, DOCTYPE, comments and PIs before the root tag) is kept and written back by stringify.
use foxy, only: xml_file

implicit none
character(len=1), parameter   :: NL = new_line('a')                                !< New line.
character(len=*), parameter   :: DECLARATION = '<?xml version="1.0" encoding="UTF-8"?>' !< XML declaration.
character(len=:), allocatable :: source                                            !< String containing the source XML data.
type(xml_file)                :: xfile                                             !< XML file handler.
logical                       :: test_passed(7)                                    !< List of passed tests.

test_passed = .false.

source = DECLARATION//NL//'<a>1</a>'
call xfile%parse(string=source)
test_passed(1) = xfile%stringify()==source
source = DECLARATION//NL//'<!DOCTYPE a [ <!ENTITY e "x>y"> ]>'//NL//'<!-- c -->'//NL//'<?pi x?>'//NL// &
         '<a>'//NL//'  <b>1</b>'//NL//'</a>'
call xfile%parse(string=source)
test_passed(2) = xfile%stringify()==source.and.xfile%content('b')=='1'
print "(A,L1)", 'Is the prolog written back? ', all(test_passed(1:2))

! comments inside the document are still dropped, a prolog of only blanks is layout
call xfile%parse(string='<a>1<!-- c -->2</a>')
test_passed(3) = xfile%stringify()=='<a>12</a>'
call xfile%parse(string=NL//'  <a>1</a>')
test_passed(4) = xfile%stringify()=='<a>1</a>'
print "(A,L1)", 'Are inner comments and blank prologs dropped? ', all(test_passed(3:4))

! real file, re-parse and linearized form
call xfile%parse(filename='src/tests/data/quakeml_ci38457511.xml')
test_passed(5) = index(xfile%stringify(), DECLARATION//NL//'<q:quakeml ')==1
test_passed(6) = index(xfile%stringify(linearize=.true.), '<?xml')==0 ! linearized form lists tags only
call xfile%parse(string='<a/>')
test_passed(7) = xfile%stringify()=='<a/>' ! a new parse discards the previous prolog
print "(A,L1)", 'Is the prolog consistent? ', all(test_passed(5:7))

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_parse_prolog
