!< FoXy test.
program foxy_test_parse_large
!< FoXy test.
!<
!< Sources larger than 2 GiB (positions beyond the 32-bit range), from a string and from a file: a 2.2 GB comment (kept,
!< so the root has mixed content and is written back exactly) followed by some tags.
!<
!< @note The test needs about 9 GB of memory and 2.2 GB of disk (in TMPDIR): it runs only if the environment variable
!< FOXY_TEST_LARGE is set to 1, otherwise it passes without checking anything.
use foxy, only: I4P, I8P, xml_file

implicit none
integer(I8P), parameter       :: PADDING = 2200000000_I8P !< Blanks in the comment before the last tags, beyond 2**31 - 1.
character(len=*), parameter   :: TAIL = '<a k="v">1</a><b/>'//new_line('a')//'<c>2 &lt; 3</c></r>' !< Last tags.
character(len=:), allocatable :: source                   !< String containing the source XML data.
character(len=:), allocatable :: tmp_dir                  !< Temporary directory.
character(len=:), allocatable :: filename                 !< File name.
character(len=1)              :: is_enabled               !< FOXY_TEST_LARGE value.
type(xml_file)                :: xfile                    !< XML file handler.
integer(I4P)                  :: iostat                   !< IO status.
character(len=256)            :: iomsg                    !< IO message.
integer                       :: unit                     !< File unit.
integer                       :: tmp_dir_len              !< Length of the TMPDIR environment variable.
integer                       :: status                   !< Status of the environment variables queries.
logical                       :: test_passed(6)           !< List of passed tests.

test_passed = .false.
iomsg = ''

call get_environment_variable('FOXY_TEST_LARGE', value=is_enabled, status=status)
if (status/=0.or.is_enabled/='1') then
   print "(A)", 'Skipped: set FOXY_TEST_LARGE=1 to run it (needs ~9 GB of memory, 2.2 GB of disk).'
   print "(A,L1)", new_line('a')//'Are all tests passed? ', .true.
   stop
endif

allocate(character(len=7_I8P+PADDING+3_I8P+len(TAIL, kind=I8P)) :: source)
source(1:7) = '<r><!--'
source(8:PADDING+7_I8P) = '' ! blank padded
source(PADDING+8_I8P:) = '-->'//TAIL
print "(A,I0)", 'Source length: ', len(source, kind=I8P)

call xfile%parse(string=source, iostat=iostat, iomsg=iomsg)
test_passed(1) = iostat==0
test_passed(2) = xfile%content('c')=='2 < 3'.and.xfile%attribute(id=xfile%find(name='a'), name='k')=='v'
test_passed(3) = xfile%find(path='r/b')==3.and.xfile%stringify()==source
print "(A,L1)", 'Is a large string parsed? ', all(test_passed(1:3))

call get_environment_variable('TMPDIR', length=tmp_dir_len, status=status)
if (status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
else
   tmp_dir = '/tmp'
endif
filename = tmp_dir//'/foxy_test_parse_large.xml'
open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE')
write(unit) source
close(unit)
deallocate(source)
call xfile%parse(filename=filename, iostat=iostat, iomsg=iomsg)
print "(A,I0,A)", 'File parse: iostat=', iostat, ' iomsg='//trim(iomsg)
test_passed(4) = iostat==0
test_passed(5) = xfile%content('c')=='2 < 3'
test_passed(6) = len(xfile%stringify(), kind=I8P)==7_I8P+PADDING+3_I8P+len(TAIL, kind=I8P)
open(newunit=unit, file=filename, status='OLD')
close(unit, status='DELETE')
print "(A,3L2)", 'File checks: ', test_passed(4:6)
print "(A,L1)", 'Is a large file parsed? ', all(test_passed(4:6))

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_parse_large
