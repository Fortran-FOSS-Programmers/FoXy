!< FoXy test.
program foxy_test_parse_comments
!< FoXy test.
!<
!< Comments and processing instructions inside the document are kept and written back by stringify, while the read
!< accessors skip them (as they skip markup in CDATA sections).
use foxy, only: xml_file

implicit none
character(len=1), parameter   :: NL = new_line('a') !< New line.
character(len=:), allocatable :: source             !< String containing the source XML data.
type(xml_file)                :: xfile              !< XML file handler.
logical                       :: test_passed(11)    !< List of passed tests.

test_passed = .false.

! written back
source = '<a>1<!-- c -->2</a>'
call xfile%parse(string=source)
test_passed(1) = xfile%stringify()==source.and.xfile%content('a')=='12'
source = '<a>'//NL//'  <!-- c -->'//NL//'  <b>1</b>'//NL//'  <?pi x?>'//NL//'</a>'
call xfile%parse(string=source)
test_passed(2) = xfile%stringify()==source.and.xfile%content('a')==''.and.xfile%content('b')=='1'
source = '<p>x <b>y</b><!-- c --> z</p>'
call xfile%parse(string=source)
test_passed(3) = xfile%stringify()==source.and.xfile%content('p')=='x  z'
source = '<a/>'//NL//'<!-- end -->' ! after the root tag
call xfile%parse(string=source)
test_passed(4) = xfile%stringify()==source
print "(A,L1)", 'Are comments and PIs written back? ', all(test_passed(1:4))

! skipped by the accessors
call xfile%parse(string='<a> 1 <!-- c --> </a>')
test_passed(5) = xfile%content('a')=='1'
call xfile%parse(string='<a><?pi <b>?>1</a>')
test_passed(6) = xfile%content('a')=='1'
call xfile%parse(string='<a><![CDATA[<!-- x -->]]></a>') ! markup in CDATA is data
test_passed(7) = xfile%content('a')=='<!-- x -->'
print "(A,L1)", 'Do the accessors skip comments and PIs? ', all(test_passed(5:7))

! tags inside comments, PIs and CDATA sections are not tags
call xfile%parse(string='<a><!-- <b>old</b> --><b>new</b></a>')
test_passed(8) = xfile%content('b')=='new'.and.size(xfile%find_all(name='b'), dim=1)==1
call xfile%parse(string='<a><![CDATA[<b>old</b>]]><b>new</b></a>')
test_passed(9) = xfile%content('b')=='new'
call xfile%parse(string='<a><!-- <b>old</b> --></a>')
test_passed(10) = xfile%content('b')==''.and.xfile%find(name='b')==0
call xfile%parse(string='<a><?pi <b>old</b>?></a>')
test_passed(11) = xfile%content('b')==''
print "(A,L1)", 'Are tags inside comments, PIs and CDATA ignored? ', all(test_passed(8:11))

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_parse_comments
