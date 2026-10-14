!< FoXy test.
program foxy_test_find_tag
!< FoXy test.
use foxy, only: xml_file
use penf, only: I4P

implicit none
character(len=1), parameter   :: NL = new_line('a') !< New line.
character(len=:), allocatable :: source             !< String containing the source XML data.
type(xml_file)                :: xfile              !< XML file handler.
integer(I4P), allocatable     :: ids(:)             !< Tags IDs.
integer(I4P)                  :: id                 !< Tag ID.
logical                       :: test_passed(16)    !< List of passed tests.

test_passed = .false.

source = '<q:quakeml xmlns:q="http://quakeml.org/xmlns/quakeml/1.2">'//NL//&
         '  <event publicID="quakeml:us/event/1">'//NL//&
         '    <origin publicID="quakeml:us/origin/1">'//NL//&
         '      <time>'//NL//&
         '        <value>2019-10-20T15:58:21</value>'//NL//&
         '      </time>'//NL//&
         '    </origin>'//NL//&
         '    <origin publicID="quakeml:us/origin/2">'//NL//&
         '      <latitude>'//NL//&
         '        <value>36.5</value>'//NL//&
         '      </latitude>'//NL//&
         '      <longitude>'//NL//&
         '        <value>-121.1885</value>'//NL//&
         '      </longitude>'//NL//&
         '    </origin>'//NL//&
         '    <magnitude>'//NL//&
         '      <mag>'//NL//&
         '        <value>1.5</value>'//NL//&
         '      </mag>'//NL//&
         '      <type>md</type>'//NL//&
         '    </magnitude>'//NL//&
         '  </event>'//NL//&
         '</q:quakeml>'
print "(A)", 'Input XML data:'
print "(A)", source
call xfile%parse(string=source)

! path: the first segment matches at any depth, the others must be direct children; repeated parents are all explored
id = xfile%find(path='origin/latitude/value')
test_passed(1) = xfile%content(id=id)=='36.5'
id = xfile%find(path='origin/longitude/value')
test_passed(2) = xfile%content(id=id)=='-121.1885'
id = xfile%find(path='magnitude/mag/value')
test_passed(3) = xfile%content(id=id)=='1.5'
id = xfile%find(path='q:quakeml/event/magnitude/type')
test_passed(4) = xfile%content(id=id)=='md'
test_passed(5) = xfile%find(path='magnitude/value')==0 ! value is not a direct child of magnitude
test_passed(6) = xfile%find(path='origin/depth/value')==0
print "(A,L1)", 'Is path search correct? ', all(test_passed(1:6))

! name: all matches in document order
ids = xfile%find_all(name='value')
test_passed(7) = size(ids)==4
if (test_passed(7)) test_passed(7) = xfile%content(id=ids(1))=='2019-10-20T15:58:21'.and.xfile%content(id=ids(4))=='1.5'
ids = xfile%find_all(name='origin')
test_passed(8) = size(ids)==2
test_passed(9) = size(xfile%find_all(name='depth'))==0.and.xfile%find(name='depth')==0
print "(A,L1)", 'Is name search correct? ', all(test_passed(7:9))

! parent: only direct children of the parent, 0 being the document root
id = xfile%find(name='magnitude')
test_passed(10) = xfile%find(name='value', parent=id)==0
test_passed(11) = xfile%content(id=xfile%find(name='type', parent=id))=='md'
test_passed(12) = size(xfile%find_all(name='q:quakeml', parent=0_I4P))==1.and.xfile%find(name='event', parent=0_I4P)==0
ids = xfile%find_all(path='latitude/value', parent=ids(2))
test_passed(13) = size(ids)==1
if (test_passed(13)) test_passed(13) = xfile%content(id=ids(1))=='36.5'
print "(A,L1)", 'Is parent scoped search correct? ', all(test_passed(10:13))

! children and attributes
ids = xfile%children(xfile%find(name='event'))
test_passed(14) = size(ids)==3
if (test_passed(14)) test_passed(14) = xfile%attribute(id=ids(2), name='publicID')=='quakeml:us/origin/2'
test_passed(15) = xfile%attribute(id=ids(1), name='missing')==''.and.xfile%attribute(id=0_I4P, name='publicID')==''
ids = xfile%children(0_I4P)
test_passed(16) = size(ids)==1.and.xfile%content(id=-1_I4P)==''
print "(A,L1)", 'Are children and attributes correct? ', all(test_passed(14:16))

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_find_tag
