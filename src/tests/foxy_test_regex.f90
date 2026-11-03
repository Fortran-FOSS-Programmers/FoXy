!< FoXy test.
program foxy_test_regex
!< FoXy test.
!<
!< Regular expression queries (StringiFor engine): matching filters tags by name, content or attribute value, a part or
!< the whole text, chained with find_all; the index filters names and attributes the same; a tag without the attribute
!< and a regex not compiled match nothing.
use foxy, only : I4P, I8P, regex, xml_file, xml_index

implicit none
type(xml_file)            :: doc            !< Document.
type(xml_index)           :: idx            !< Index.
type(regex)               :: re             !< Regular expression.
type(regex)               :: not_compiled   !< A regex never compiled.
integer(I4P), allocatable :: ids(:)         !< IDs.
character(len=:), allocatable :: tmp_dir    !< Temporary directory.
character(len=:), allocatable :: filename   !< File name.
character(len=:), allocatable :: source     !< Source.
integer(I4P)              :: iostat         !< IO status.
integer                   :: unit           !< File unit.
integer                   :: tmp_dir_len    !< Length of the TMPDIR environment variable.
integer                   :: status         !< Status of the environment variable query.
logical                   :: test_passed(5) !< List of passed tests.

test_passed = .false.
source = '<case><p1_x u="m/s">1.5</p1_x><p2_y u="m/s">2</p2_y><p3_z>caf&#233;</p3_z>'// &
         '<boundary side="west" type="inflow"/><boundary side="east" type="wall"/><boundary side="north" type="wall"/>'// &
         '<boundary side="south"/></case>'
call doc%parse(string=source)

! names: a part, or the whole name
call re%compile('^p[0-9]+_(x|y)$', iostat=iostat)
ids = doc%matching(re)
test_passed(1) = iostat==0.and.size(ids)==2
if (test_passed(1)) test_passed(1) = all(ids==[2, 3])
call re%compile('_', iostat=iostat)
ids = doc%matching(re)
test_passed(1) = test_passed(1).and.size(ids)==3
call re%compile('p1', iostat=iostat)
ids = doc%matching(re, whole=.true.)
test_passed(1) = test_passed(1).and.size(ids)==0
print "(A,L1)", 'Are names matched? ', test_passed(1)

! contents, decoded (UTF-8 classes)
call re%compile('^[0-9.]+$', iostat=iostat)
ids = doc%matching(re, on='content')
test_passed(2) = size(ids)==2
call re%compile('caf[é]', iostat=iostat)
ids = doc%matching(re, on='content')
test_passed(2) = test_passed(2).and.size(ids)==1
if (test_passed(2)) test_passed(2) = doc%name(ids(1))=='p3_z'
print "(A,L1)", 'Are contents matched? ', test_passed(2)

! attributes, chained with find_all; a tag without the attribute never matches
call re%compile('^(wall|outflow)$', iostat=iostat)
ids = doc%matching(re, ids=doc%find_all(name='boundary'), attribute='type')
test_passed(3) = size(ids)==2
if (test_passed(3)) test_passed(3) = doc%attribute(ids(1), 'side')=='east'.and.doc%attribute(ids(2), 'side')=='north'
call re%compile('', iostat=iostat)                     ! matches every text, but not a missing attribute
ids = doc%matching(re, ids=doc%find_all(name='boundary'), attribute='type')
test_passed(3) = test_passed(3).and.size(ids)==3
print "(A,L1)", 'Are attributes matched, missing ones excluded? ', test_passed(3)

! a regex not compiled matches nothing
ids = doc%matching(not_compiled)
test_passed(4) = size(ids)==0.and..not.not_compiled%is_compiled()
print "(A,L1)", 'Does a regex not compiled match nothing? ', test_passed(4)

! the index: names and attributes, as the DOM
call get_environment_variable('TMPDIR', length=tmp_dir_len, status=status)
if (status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
else
   tmp_dir = '/tmp'
endif
filename = tmp_dir//'/foxy_test_regex.xml'
open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE')
write(unit) source
close(unit)
call idx%scan(filename=filename)
call re%compile('^p[0-9]+_(x|y)$', iostat=iostat)
ids = idx%matching(re)
test_passed(5) = size(ids)==2
call re%compile('wall', iostat=iostat)
ids = idx%matching(re, attribute='type')
test_passed(5) = test_passed(5).and.size(ids)==2
ids = idx%matching(re, on='content')                    ! the index holds no content
test_passed(5) = test_passed(5).and.size(ids)==0
open(newunit=unit, file=filename, status='OLD')
close(unit, status='DELETE')
print "(A,L1)", 'Does the index match names and attributes? ', test_passed(5)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_regex
