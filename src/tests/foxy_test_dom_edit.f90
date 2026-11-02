!< FoXy test.
program foxy_test_dom_edit
!< FoXy test.
!<
!< Editing a parsed document by tag ID: tags number, attributes listed by index, set and delete attributes (values escaped,
!< read back decoded), set the content (children replaced), delete a tag by ID (subtree included, IDs renumbered); bad IDs
!< and names reported (XML_NOT_FOUND, XML_MALFORMED); the same read accessors on the index.
use foxy, only: I4P, XML_MALFORMED, XML_NOT_FOUND, xml_file, xml_index

implicit none
character(len=1), parameter   :: NL = new_line('a') !< New line.
character(len=*), parameter   :: SOURCE = '<cfg>'//NL//'  <dt unit="s" min="0">0.1</dt>'//NL//'  <solver kind="cg">'//NL// &
                                          '    <tol>1e-6</tol>'//NL//'    <it>10</it>'//NL//'  </solver>'//NL//'</cfg>' !< Source.
character(len=:), allocatable :: tmp_dir            !< Temporary directory.
character(len=:), allocatable :: filename           !< File name.
type(xml_file)                :: xfile              !< XML file handler.
type(xml_file)                :: xback              !< XML file parsed back.
type(xml_index)               :: xindex             !< XML index.
integer(I4P)                  :: dt                 !< Tag "dt" ID.
integer(I4P)                  :: solver             !< Tag "solver" ID.
integer(I4P)                  :: iostat             !< IO status.
character(len=256)            :: iomsg              !< IO message.
integer                       :: unit               !< File unit.
integer                       :: tmp_dir_len        !< Length of the TMPDIR environment variable.
integer                       :: status             !< Status of the environment variable query.
logical                       :: test_passed(8)     !< List of passed tests.

test_passed = .false.
call xfile%parse(string=SOURCE)
dt = xfile%find(name='dt')
solver = xfile%find(name='solver')

! reading every tag and attribute without knowing the names
test_passed(1) = xfile%tags_number()==5.and.xfile%attributes_number(dt)==2.and.xfile%attribute_name(dt, 1)=='unit'.and. &
                 xfile%attribute_name(dt, 2)=='min'.and.xfile%attribute_name(dt, 3)==''.and.xfile%attributes_number(99)==0
print "(A,L1)", 'Are tags and attributes listed? ', test_passed(1)

! attributes: replaced, added (escaped, read back decoded), deleted
call xfile%set_attribute(id=dt, name='unit', value='ms', iostat=iostat)
test_passed(2) = iostat==0
call xfile%set_attribute(id=dt, name='note', value='a<b & "c"', iostat=iostat)
test_passed(2) = test_passed(2).and.iostat==0.and.xfile%attribute(dt, 'unit')=='ms'.and. &
                 xfile%attribute(dt, 'note')=='a<b & "c"'.and.xfile%attributes_number(dt)==3
call xfile%delete_attribute(id=dt, name='min', iostat=iostat)
test_passed(2) = test_passed(2).and.iostat==0.and.xfile%attributes_number(dt)==2.and.xfile%attribute(dt, 'min')==''
print "(A,L1)", 'Are attributes set and deleted? ', test_passed(2)

! content: text replaced; children replaced by the new content
call xfile%set_content(id=dt, content='0.2', iostat=iostat)
test_passed(3) = iostat==0.and.xfile%content(dt)=='0.2'
call xfile%set_content(id=solver, content='none', iostat=iostat)
test_passed(3) = test_passed(3).and.iostat==0.and.xfile%content(solver)=='none'.and.xfile%tags_number()==3.and. &
                 size(xfile%children(solver))==0.and.xfile%find(name='tol')==0
print "(A,L1)", 'Is content set? ', test_passed(3)

! the edited document is written and parsed back
call xback%parse(string=xfile%stringify(), iostat=iostat)
test_passed(4) = iostat==0.and.xback%attribute(xback%find(name='dt'), 'note')=='a<b & "c"'.and. &
                 xback%content('dt')=='0.2'.and.xback%content('solver')=='none'.and.xback%tags_number()==3
print "(A,L1)", 'Is the edited document written back? ', test_passed(4)

! a self closing tag gets a content; delete a tag by ID (subtree included, IDs renumbered)
call xfile%parse(string='<r><a/><b><c/></b><d>4</d></r>')
call xfile%set_content(id=xfile%find(name='a'), content='1')
test_passed(5) = index(xfile%stringify(), '<a>1</a>')>0
call xfile%delete_tag(id=xfile%find(name='b'))
test_passed(5) = test_passed(5).and.xfile%tags_number()==3.and.xfile%find(name='c')==0.and.xfile%content('d')=='4'.and. &
                 xfile%parent(xfile%find(name='d'))==1.and.size(xfile%children(1))==2
call xfile%delete_tag(name='a')
test_passed(5) = test_passed(5).and.xfile%tags_number()==2
print "(A,L1)", 'Are tags deleted by ID? ', test_passed(5)

! errors: bad IDs, invalid names, missing attributes
call xfile%set_content(id=99, content='x', iostat=iostat)
test_passed(6) = iostat==XML_NOT_FOUND
call xfile%set_attribute(id=0, name='x', value='1', iostat=iostat)
test_passed(6) = test_passed(6).and.iostat==XML_NOT_FOUND
call xfile%set_attribute(id=1, name='1x', value='1', iostat=iostat, iomsg=iomsg)
test_passed(6) = test_passed(6).and.iostat==XML_MALFORMED.and.index(iomsg, '1x')>0.and.xfile%attributes_number(1)==0
call xfile%delete_attribute(id=1, name='missing', iostat=iostat)
test_passed(6) = test_passed(6).and.iostat==XML_NOT_FOUND
call xfile%delete_tag(id=99)
test_passed(6) = test_passed(6).and.xfile%tags_number()==2
print "(A,L1)", 'Are errors reported? ', test_passed(6)

! an empty document
call xfile%free()
test_passed(7) = xfile%tags_number()==0.and.xfile%attributes_number(1)==0.and.xfile%attribute_name(1, 1)==''
print "(A,L1)", 'Is an empty document handled? ', test_passed(7)

! the index lists tags and attributes too
call get_environment_variable('TMPDIR', length=tmp_dir_len, status=status)
if (status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
else
   tmp_dir = '/tmp'
endif
filename = tmp_dir//'/foxy_test_dom_edit.xml'
open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE')
write(unit) SOURCE
close(unit)
call xindex%scan(filename=filename, iostat=iostat)
test_passed(8) = iostat==0.and.xindex%tags_number()==5.and.xindex%attributes_number(xindex%find(name='dt'))==2.and. &
                 xindex%attribute_name(xindex%find(name='dt'), 2)=='min'
open(newunit=unit, file=filename, status='OLD')
close(unit, status='DELETE')
print "(A,L1)", 'Does the index list tags and attributes? ', test_passed(8)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_dom_edit
