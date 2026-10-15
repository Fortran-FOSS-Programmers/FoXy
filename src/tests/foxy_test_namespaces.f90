!< FoXy test.
program foxy_test_namespaces
!< FoXy test.
use foxy, only: xml_file, xml_index
use penf, only: I4P, I8P

implicit none
character(len=1), parameter   :: NL = new_line('a')                            !< New line.
character(*),     parameter   :: BED = 'http://quakeml.org/xmlns/bed/1.2'        !< Default namespace.
character(*),     parameter   :: Q = 'http://quakeml.org/xmlns/quakeml/1.2'      !< Namespace of the *q* prefix.
character(*),     parameter   :: XML_NS = 'http://www.w3.org/XML/1998/namespace' !< Namespace of the *xml* prefix.
integer(I4P),     parameter   :: NT = 16_I4P                                    !< Number of tags of the source.
character(len=:), allocatable :: source                                        !< String containing the source XML data.
character(len=:), allocatable :: tmp_dir                                       !< Temporary directory.
character(len=:), allocatable :: filename                                      !< Temporary file name.
type(xml_file)                :: xfile                                         !< XML file handler.
type(xml_index)               :: idx                                           !< XML index.
integer(I4P), allocatable     :: ids(:)                                        !< Tags IDs.
integer(I4P)                  :: id                                            !< Tag ID.
integer(I4P)                  :: event                                         !< Event tag ID.
integer                       :: tmp_dir_len                                   !< Length of the TMPDIR environment variable.
integer                       :: status                                        !< Status of get_environment_variable.
integer                       :: file_unit                                     !< File unit.
integer                       :: c                                             !< Chunk size counter.
logical                       :: is_same                                       !< Index and DOM agree.
logical                       :: test_passed(22)                               !< List of passed tests.

test_passed = .false.

source = '<q:quakeml xmlns="'//BED//'" xmlns:q="'//Q//'">'//NL//&
         '  <eventParameters>'//NL//&
         '    <event>'//NL//&
         '      <origin><latitude><value>35.7</value></latitude></origin>'//NL//&
         '      <b:origin xmlns:b="'//BED//'"><latitude><value>36.5</value></latitude></b:origin>'//NL//&
         '      <q:origin xmlns:q="urn:other"><latitude/></q:origin>'//NL//&
         '      <x:extra><x:value>1</x:value></x:extra>'//NL//&
         '      <plain xmlns=""><value>no-ns</value></plain>'//NL//&
         '      <xml:note>reserved prefix</xml:note>'//NL//&
         '    </event>'//NL//&
         '  </eventParameters>'//NL//&
         '</q:quakeml>'
print "(A)", 'Input XML data:'
print "(A)", source
call xfile%parse(string=source)

! names split as prefix and local name, the namespace resolved in the scope of the tag
id = xfile%find(name='q:quakeml')
test_passed(1) = xfile%prefix(id=id)=='q'.and.xfile%local_name(id=id)=='quakeml'.and.xfile%namespace(id=id)==Q
id = xfile%find(name='eventParameters')
test_passed(2) = xfile%prefix(id=id)==''.and.xfile%local_name(id=id)=='eventParameters'.and.xfile%namespace(id=id)==BED
id = xfile%find(name='b:origin')
test_passed(3) = xfile%local_name(id=id)=='origin'.and.xfile%namespace(id=id)==BED
id = xfile%find(name='q:origin') ! q redeclared in its own start tag
test_passed(4) = xfile%namespace(id=id)=='urn:other'.and.xfile%namespace(id=xfile%find(name='latitude', parent=id))==BED
id = xfile%find(name='x:extra') ! undeclared prefix: a prefix without namespace
test_passed(5) = xfile%prefix(id=id)=='x'.and.xfile%namespace(id=id)==''
id = xfile%find(name='plain') ! default namespace undeclared
test_passed(6) = xfile%namespace(id=id)==''.and.xfile%namespace(id=xfile%find(name='value', parent=id))==''
test_passed(7) = xfile%namespace(id=xfile%find(name='xml:note'))==XML_NS
test_passed(8) = xfile%namespace(id=0_I4P)==''.and.xfile%local_name(id=0_I4P)==''.and.xfile%prefix(id=NT+1)==''
print "(A,L1)", 'Are prefixes, local names and namespaces correct? ', all(test_passed(1:8))

! Clark notation, {uri}local: same namespace under any prefix
ids = xfile%find_all(name='{'//BED//'}origin')
test_passed(9) = size(ids)==2
if (test_passed(9)) test_passed(9) = xfile%name(id=ids(1))=='origin'.and.xfile%name(id=ids(2))=='b:origin'
ids = xfile%find_all(path='{'//BED//'}origin/{'//BED//'}latitude/{'//BED//'}value') ! URIs hold '/'
test_passed(10) = size(ids)==2
if (test_passed(10)) test_passed(10) = xfile%content(id=ids(1))=='35.7'.and.xfile%content(id=ids(2))=='36.5'
ids = xfile%find_all(name='{}value') ! no namespace (the undeclared x:value matches nothing)
test_passed(11) = size(ids)==1
if (test_passed(11)) test_passed(11) = xfile%content(id=ids(1))=='no-ns'
test_passed(12) = xfile%find(name='{'//Q//'}quakeml')==1.and.xfile%find(name='{'//Q//'}origin')==0
event = xfile%find(name='event')
test_passed(13) = size(xfile%find_all(name='{'//BED//'}origin', parent=event))==2
test_passed(14) = xfile%find(path='{'//Q//'}quakeml/{'//BED//'}eventParameters/{'//BED//'}event')==event
print "(A,L1)", 'Is Clark notation search correct? ', all(test_passed(9:14))

! namespaces map, the declarations syntax: the prefixes of the query, not of the document
ids = xfile%find_all(path='bed:origin/bed:latitude/bed:value', namespaces='xmlns:bed="'//BED//'"')
test_passed(15) = size(ids)==2
test_passed(16) = size(xfile%find_all(name='origin', namespaces='xmlns="'//BED//'"'))==2
test_passed(17) = xfile%find(name='z:origin', namespaces='xmlns="'//BED//'"')==0 ! prefix not in the map
ids = xfile%find_all(name='value', namespaces='xmlns:q="'//Q//'"') ! unprefixed, no default: no namespace
test_passed(18) = size(ids)==1
test_passed(19) = xfile%find(path='doc:quakeml/eventParameters', namespaces='xmlns="'//BED//'" xmlns:doc="'//Q//'"')==2
print "(A,L1)", 'Is namespaces map search correct? ', all(test_passed(15:19))

! without namespaces, names are matched literally as before
test_passed(20) = size(xfile%find_all(name='origin'))==1.and.xfile%find(name='b:origin')>0
print "(A,L1)", 'Is literal search unchanged? ', test_passed(20)

! the index agrees with the DOM, with any chunk size
call get_environment_variable('TMPDIR', length=tmp_dir_len, status=status)
if (status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
else
   tmp_dir = '/tmp'
endif
filename = tmp_dir//'/foxy_test_namespaces.xml'
open(newunit=file_unit, file=filename, access='stream', form='unformatted', status='replace')
write(file_unit) source
close(file_unit)
is_same = xfile%name(id=NT)/=''.and.xfile%name(id=NT+1)==''
do c=1, 2
   call idx%scan(filename=filename, chunk_size=merge(1_I8P, 65536_I8P, c==1))
   do id=0, NT + 1
      is_same = is_same.and.idx%name(id=id)==xfile%name(id=id).and.idx%prefix(id=id)==xfile%prefix(id=id).and. &
                idx%local_name(id=id)==xfile%local_name(id=id).and.idx%namespace(id=id)==xfile%namespace(id=id)
   enddo
   is_same = is_same.and.all(idx%find_all(name='{'//BED//'}origin')==xfile%find_all(name='{'//BED//'}origin'))
   is_same = is_same.and.all(idx%find_all(path='bed:origin/bed:latitude', namespaces='xmlns:bed="'//BED//'"')==&
                             xfile%find_all(path='bed:origin/bed:latitude', namespaces='xmlns:bed="'//BED//'"'))
enddo
test_passed(21) = is_same
test_passed(22) = idx%find(name='{'//BED//'}value', namespaces='xmlns="urn:ignored"')>0 ! Clark names ignore the map
open(newunit=file_unit, file=filename)
close(file_unit, status='delete')
print "(A,L1)", 'Does the index agree with the DOM? ', all(test_passed(21:22))

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_namespaces
