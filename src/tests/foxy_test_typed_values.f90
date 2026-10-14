!< FoXy test.
program foxy_test_typed_values
!< FoXy test.
!<
!< Typed accessors: attributes and contents as numbers (every kind, scalars and lists) and logicals, from the DOM and from
!< the index (the same checks, in *foxy_test_typed_values.inc*); malformed values, missing tags and attributes reported;
!< a large list read from a file.
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan
use foxy, only : I1P, I2P, I4P, I8P, R4P, R8P, xml_file, xml_index, xml_writer, XML_BAD_VALUE, XML_NOT_FOUND

implicit none
character(len=1), parameter   :: NL = new_line('a') !< New line.
character(*),     parameter   :: SOURCE =                                                                          &
   '<a i1="-7" i2="300" i4="-70000" i8="9000000000" r4="0.5" r8="1.25e-3" b1="true" b2=" 0 " b3="yes"'//NL//       &
   '   ext="0 10 0 10 0 0" reals=" 1.5&#10;2.5'//achar(9)//'-3e2 " empty="" special="nan inf -Infinity"'//NL//       &
   '   comma="1,2" slash="3/" repeat="2*5" text="abc" float="1.5" big="300" pair="1 2">'//NL//                     &
   '  <v>  42 </v>'//NL//                                                                                          &
   '  <arr>1 2 3<!-- 9 --> 4 <![CDATA[5]]>'//NL//'  </arr>'//NL//                                                  &
   '  <flag>false</flag>'//NL//                                                                                    &
   '  <none/>'//NL//                                                                                               &
   '</a>'                                                !< Source.
integer(I4P), parameter       :: N_LARGE = 1000000_I4P   !< Number of values of the large list.
type(xml_file)                :: xfile                   !< XML file.
type(xml_index)               :: xindex                  !< XML index.
type(xml_writer)              :: writer                  !< XML writer.
character(len=:), allocatable :: tmp_dir                 !< Temporary directory.
character(len=:), allocatable :: filename                !< File name.
character(len=32)             :: buffer                  !< Buffer of a written value.
real(R8P),    allocatable     :: large(:)                !< Large list.
real(R8P),    allocatable     :: expected(:)             !< Expected large list.
integer(I8P)                  :: clock(3)                !< Clock counts (start, end) and rate.
integer(I4P)                  :: iostat                  !< IO status.
integer                       :: unit                    !< File unit.
integer                       :: tmp_dir_len             !< Length of the TMPDIR environment variable.
integer                       :: status                  !< Status of the environment variable query.
integer                       :: i                       !< Counter.
logical                       :: test_passed(9)          !< List of passed tests.

test_passed = .false.

call get_environment_variable('TMPDIR', length=tmp_dir_len, status=status)
if (status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
else
   tmp_dir = '/tmp'
endif
filename = tmp_dir//'/foxy_test_typed_values.xml'

call xfile%parse(string=SOURCE)
test_passed(1:4) = checks(xfile)
print "(A,L1)", 'Are the DOM typed accessors right? ', all(test_passed(1:4))

open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE')
write(unit) SOURCE
close(unit)
call xindex%scan(filename=filename)
test_passed(5:8) = checks(xindex)
print "(A,L1)", 'Are the index typed accessors right (as the DOM ones)? ', all(test_passed(5:8))

! a large list, read from the file through the index
allocate(expected(N_LARGE))
call writer%open(filename=filename)
call writer%start('DataArray')
do i=1, N_LARGE
   expected(i) = real(i, R8P) / 3._R8P
   write(buffer, '(ES24.16E3)') expected(i)
   call writer%raw(trim(buffer)//' ')
enddo
call writer%close()
call xindex%scan(filename=filename)
call system_clock(clock(1), clock(3))
call xindex%get_content(id=1_I4P, values=large, iostat=iostat)
call system_clock(clock(2))
test_passed(9) = iostat==0.and.size(large, dim=1)==N_LARGE
if (test_passed(9)) test_passed(9) = all(abs(large - expected)<=spacing(expected))
print "(A,I0,A,F7.3,A)", 'Large list: ', N_LARGE, ' reals read in ', real(clock(2) - clock(1)) / real(clock(3)), ' s'
print "(A,L1)", 'Is a large list read from the file? ', test_passed(9)

open(newunit=unit, file=filename, status='OLD')
close(unit, status='DELETE')
print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   function checks(doc) result(is_passed)
   !< Run the checks on a DOM or an index of *SOURCE*: the same calls, included for each type.
   class(*), intent(in)       :: doc          !< XML file or index.
   logical                    :: is_passed(4) !< Checks results: scalars, lists, errors, contents.
   integer(I1P)               :: i1           !< Value.
   integer(I2P)               :: i2           !< Value.
   integer(I4P)               :: i4           !< Value.
   integer(I8P)               :: i8           !< Value.
   real(R4P)                  :: r4           !< Value.
   real(R8P)                  :: r8           !< Value.
   logical                    :: l(3)         !< Values.
   integer(I1P), allocatable  :: i1s(:)       !< Values.
   integer(I2P), allocatable  :: i2s(:)       !< Values.
   integer(I4P), allocatable  :: i4s(:)       !< Values.
   integer(I8P), allocatable  :: i8s(:)       !< Values.
   real(R4P),    allocatable  :: r4s(:)       !< Values.
   real(R8P),    allocatable  :: r8s(:)       !< Values.
   integer(I4P)               :: iostats(16)  !< IO statuses.
   character(len=128)         :: iomsgs(4)    !< IO messages.
   integer(I4P)               :: a            !< Root tag ID.
   integer                    :: i            !< Counter.

   is_passed = .false.
   select type(doc)
   type is(xml_file)
      include 'foxy_test_typed_values.inc'
   type is(xml_index)
      include 'foxy_test_typed_values.inc'
   endselect
   endfunction checks
endprogram foxy_test_typed_values
