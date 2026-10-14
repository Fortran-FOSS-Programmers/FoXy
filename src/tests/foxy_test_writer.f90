!< FoXy test.
program foxy_test_writer
!< FoXy test.
!<
!< The streaming writer: the same bytes to a file, a unit and memory; layout (indented or compact), escaping, typed
!< attributes, self closing and inline elements, block payloads, CDATA, comments, PIs; misuse and I/O errors reported.
use foxy, only: I1P, I2P, I4P, I8P, R4P, R8P, xml_file, xml_writer, XML_MALFORMED

implicit none
character(len=1), parameter   :: NL = new_line('a') !< New line.
character(len=*), parameter   :: EXPECTED = &
   '<?xml version="1.0"?>'//NL//                                       &
   '<VTKFile type="UnstructuredGrid" version="1.0">'//NL//             &
   '  <Piece NumberOfPoints="27" NumberOfCells="-3">'//NL//            &
   '    <DataArray Name="p&amp;q &quot;x&quot;" format="ascii">'//NL// &
   '      1 2 3'//NL//                                                 &
   '    </DataArray>'//NL//                                            &
   '    <Empty flag="true" off="false"/>'//NL//                         &
   '    <Note>a &lt; b &amp; c</Note>'//NL//                             &
   '    <!-- c -->'//NL//                                              &
   '  </Piece>'//NL//                                                  &
   '</VTKFile>'//NL                                                    !< Expected indented document.
character(len=*), parameter   :: COMPACT = '<?xml version="1.0"?><VTKFile type="UnstructuredGrid" version="1.0">'// &
   '<Piece NumberOfPoints="27" NumberOfCells="-3"><DataArray Name="p&amp;q &quot;x&quot;" format="ascii">1 2 3'// &
   '</DataArray><Empty flag="true" off="false"/><Note>a &lt; b &amp; c</Note><!-- c --></Piece></VTKFile>' !< Compact.
type(xml_writer)              :: writer             !< XML writer.
type(xml_file)                :: xfile              !< XML file, to parse the output back.
character(len=:), allocatable :: tmp_dir            !< Temporary directory.
character(len=:), allocatable :: filename           !< File name.
character(len=:), allocatable :: output             !< Output.
character(len=:), allocatable :: output_r8          !< Real attribute written.
character(len=64)             :: iomsg              !< IO message.
integer(I4P)                  :: iostat             !< IO status.
real(R8P)                     :: x                  !< Real value read back.
integer                       :: unit               !< File unit.
integer                       :: tmp_dir_len        !< Length of the TMPDIR environment variable.
integer                       :: status             !< Status of the environment variable query.
integer                       :: p                  !< Counter.
logical                       :: test_passed(15)    !< List of passed tests.

test_passed = .false.

call get_environment_variable('TMPDIR', length=tmp_dir_len, status=status)
if (status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
else
   tmp_dir = '/tmp'
endif
filename = tmp_dir//'/foxy_test_writer.xml'

! the same document to memory, to a file and to a unit opened by the caller
call writer%open()
call write_document(writer)
call writer%close(iostat=iostat)
test_passed(1) = iostat==0.and.writer%string()==EXPECTED
if (.not.test_passed(1)) print "(A)", '['//writer%string()//']'
call writer%open(filename=filename, iostat=iostat)
call write_document(writer)
call writer%close(iostat=iostat)
test_passed(2) = iostat==0.and.file_content(filename)==EXPECTED
open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE')
write(unit) '<!-- before -->'
call writer%open(unit=unit)
call writer%start('a')
call writer%close(iostat=iostat)
write(unit) '<!-- after -->' ! the unit is left open
close(unit)
test_passed(3) = iostat==0.and.file_content(filename)=='<!-- before --><a/>'//NL//'<!-- after -->'
print "(A,L1)", 'Is the same document written to memory, a file and a unit? ', all(test_passed(1:3))

! compact layout, and the output parsed back
call writer%open(indent=0)
call write_document(writer)
call writer%close()
test_passed(4) = writer%string()==COMPACT
if (.not.test_passed(4)) print "(A)", '['//writer%string()//']'
call xfile%parse(string=EXPECTED)
test_passed(5) = xfile%attribute(id=xfile%find(name='DataArray'), name='Name')=='p&q "x"'.and. &
                 xfile%content('Note')=='a < b & c'.and.xfile%content('DataArray')=='1 2 3'
print "(A,L1)", 'Are the compact layout and parsing back right? ', all(test_passed(4:5))

! typed attributes, formats, CDATA, PIs, auto closing
call writer%open(indent=0)
call writer%start('t')
call writer%attribute('i1', -1_I1P)
call writer%attribute('i2', 2_I2P)
call writer%attribute('i8', 9000000000_I8P)
call writer%attribute('r4', 0.5_R4P)
call writer%attribute('r8', 1.5_R8P)
call writer%attribute('f', 2.25_R8P, fmt='(F6.3)')
call writer%attribute('n', 7_I4P, fmt='(I3.3)')
call writer%start('c')
call writer%cdata('a]]>b')
call writer%end('c')
call writer%pi('target', 'data')
call writer%start('open')
call writer%close(iostat=iostat)
output = writer%string()
call xfile%parse(string=output)
output_r8 = xfile%attribute(id=1, name='r8')
read(output_r8, *) x
test_passed(6) = index(output, ' i1="-1" i2="2" i8="9000000000" ')>0.and.index(output, ' f="2.250" n="007"')>0.and. &
                 abs(x-1.5_R8P)<epsilon(1._R8P)
test_passed(7) = xfile%content('c')=='a]]>b'.and.index(output, '<?target data?>')>0
test_passed(8) = iostat==0.and.index(output, '<open/></t>')==len(output)-len('<open/></t>')+1
if (.not.all(test_passed(6:8))) print "(A)", '['//output//']'
print "(A,L1)", 'Are typed attributes, CDATA, PIs and auto closing right? ', all(test_passed(6:8))

! misuse: reported (sticky, the output stops at the first error)
call writer%open()
call writer%start('a')
call writer%end('b')
call writer%start('c')
call writer%close(iostat=iostat, iomsg=iomsg)
test_passed(9) = iostat==XML_MALFORMED.and.index(iomsg, 'b')>0.and.index(writer%string(), '<c')==0
call writer%open()
call writer%start('a')
call writer%text('t')
call writer%attribute('k', 'v', iostat=iostat)
test_passed(10) = iostat==XML_MALFORMED
call writer%close()
call writer%open()
call writer%start('a')
call writer%declaration(iostat=iostat)
test_passed(11) = iostat==XML_MALFORMED
call writer%close()
call writer%open()
call writer%start('a')
call writer%comment('x -- y', iostat=iostat)
test_passed(12) = iostat==XML_MALFORMED
call writer%close()
print "(A,L1)", 'Is misuse reported? ', all(test_passed(9:12))

! I/O errors: the runtime iostat/iomsg are passed through
call writer%open(filename=tmp_dir//'/foxy_test_writer_missing_dir/a.xml', iostat=iostat, iomsg=iomsg)
test_passed(13) = iostat/=0.and.iostat/=XML_MALFORMED.and.len_trim(iomsg)>0
print "(A,L1)", 'Are I/O errors reported? ', test_passed(13)

! a large payload written in pieces
call writer%open(filename=filename)
call writer%start('data')
do p=1, 64
   call writer%raw(repeat('x', 1048576))
enddo
call writer%close(iostat=iostat)
test_passed(14) = iostat==0.and.len(file_content(filename))==64*1048576+len('<data></data>'//NL)
print "(A,L1)", 'Is a large payload written in pieces? ', test_passed(14)

! flush: the pending start tag is completed, the caller writes directly to the unit (e.g. binary data)
open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE')
call writer%open(unit=unit)
call writer%start('V')
call writer%start('AppendedData')
call writer%attribute('encoding', 'raw')
call writer%flush()
write(unit) '_'//achar(0)//achar(255)//NL
call writer%end('AppendedData')
call writer%close(iostat=iostat)
close(unit)
test_passed(15) = iostat==0.and.file_content(filename)=='<V>'//NL//'  <AppendedData encoding="raw">'//NL// &
                  '_'//achar(0)//achar(255)//NL//'  </AppendedData>'//NL//'</V>'//NL
print "(A,L1)", 'Is the pending start tag flushed for direct writes? ', test_passed(15)

open(newunit=unit, file=filename, status='OLD')
close(unit, status='DELETE')
print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   subroutine write_document(writer)
   !< Write the test document.
   type(xml_writer), intent(inout) :: writer !< XML writer.

   call writer%declaration()
   call writer%start('VTKFile')
   call writer%attribute('type', 'UnstructuredGrid')
   call writer%attribute('version', '1.0')
   call writer%start('Piece')
   call writer%attribute('NumberOfPoints', 27_I4P)
   call writer%attribute('NumberOfCells', -3_I4P)
   call writer%start('DataArray')
   call writer%attribute('Name', 'p&q "x"')
   call writer%attribute('format', 'ascii')
   call writer%raw('1 2 3', is_block=.true.)
   call writer%end('DataArray')
   call writer%start('Empty')
   call writer%attribute('flag', .true.)
   call writer%attribute('off', .false.)
   call writer%end()
   call writer%start('Note')
   call writer%text('a < b & c')
   call writer%end('Note')
   call writer%comment(' c ')
   call writer%end('Piece')
   call writer%end('VTKFile')
   endsubroutine write_document

   function file_content(filename) result(content)
   !< Return the whole content of a file.
   character(*), intent(in)      :: filename !< File name.
   character(len=:), allocatable :: content  !< File content.
   integer                       :: unit     !< File unit.
   integer                       :: filesize !< File size.

   open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='OLD')
   inquire(unit=unit, size=filesize)
   allocate(character(len=filesize) :: content)
   if (filesize>0) read(unit) content
   close(unit)
   endfunction file_content
endprogram foxy_test_writer
