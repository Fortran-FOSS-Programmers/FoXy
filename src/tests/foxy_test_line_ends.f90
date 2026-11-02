!< FoXy test.
program foxy_test_line_ends
!< FoXy test.
!<
!< Line ends (XML 1.0 2.11): CR LF and a lone CR are read as LF in contents (CDATA included), by the DOM and the index,
!< also typed; the stored source keeps them (`stringify` round trip); a CR written as `&#13;` is data.
use foxy, only: I4P, xml_file, xml_index

implicit none
character(len=1), parameter   :: CR = achar(13)     !< Carriage return.
character(len=1), parameter   :: LF = achar(10)     !< Line feed.
character(len=:), allocatable :: source             !< Source XML data.
character(len=:), allocatable :: tmp_dir            !< Temporary directory.
character(len=:), allocatable :: filename           !< File name.
type(xml_file)                :: xfile              !< XML file handler.
type(xml_index)               :: xindex             !< XML index.
integer(I4P), allocatable     :: values(:)          !< Typed values.
integer(I4P)                  :: iostat             !< IO status.
integer                       :: unit               !< File unit.
integer                       :: tmp_dir_len        !< Length of the TMPDIR environment variable.
integer                       :: status             !< Status of the environment variable query.
logical                       :: test_passed(5)     !< List of passed tests.

test_passed = .false.

source = '<r><a>x'//CR//LF//'y'//CR//'z</a><b><![CDATA[p'//CR//LF//'q]]>&#13;</b><c>1'//CR//LF//'2'//CR//'3</c></r>'
call xfile%parse(string=source)
test_passed(1) = xfile%content('a')=='x'//LF//'y'//LF//'z'
test_passed(2) = xfile%content('b')=='p'//LF//'q'//CR
call xfile%get_content(id=xfile%find(name='c'), values=values, iostat=iostat)
test_passed(3) = iostat==0.and.size(values)==3
if (test_passed(3)) test_passed(3) = all(values==[1, 2, 3])
test_passed(4) = &
                 index(xfile%stringify(), 'x'//CR//LF//'y'//CR//'z')>0
print "(A,L1)", 'Are line ends normalized on read, kept in the source? ', all(test_passed(1:4))

call get_environment_variable('TMPDIR', length=tmp_dir_len, status=status)
if (status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
else
   tmp_dir = '/tmp'
endif
filename = tmp_dir//'/foxy_test_line_ends.xml'
open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE')
write(unit) source
close(unit)
call xindex%scan(filename=filename, iostat=iostat)
test_passed(5) = iostat==0.and.xindex%content(xindex%find(name='a'))=='x'//LF//'y'//LF//'z'.and. &
                 xindex%content(xindex%find(name='b'))=='p'//LF//'q'//CR
open(newunit=unit, file=filename, status='OLD')
close(unit, status='DELETE')
print "(A,L1)", 'Are line ends normalized by the index? ', test_passed(5)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_line_ends
