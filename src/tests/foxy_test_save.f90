!< FoXy test.
program foxy_test_save
!< FoXy test.
!<
!< Save the document to a file: prolog plus stringify, optional XML declaration, errors through iostat/iomsg.
use foxy, only: I4P, xml_file, xml_tag

implicit none
character(len=1), parameter   :: NL = new_line('a')                       !< New line.
character(len=*), parameter   :: DECLARATION = '<?xml version="1.0"?>'    !< XML declaration written by save.
character(len=:), allocatable :: tmp_dir                                  !< Temporary directory.
character(len=:), allocatable :: filename                                 !< Saved file name.
character(len=:), allocatable :: source                                   !< String containing the source XML data.
type(xml_file)                :: xfile                                    !< XML file handler.
type(xml_file)                :: xfile_reparsed                           !< XML file handler, saved file parsed again.
integer(I4P)                  :: iostat                                   !< IO status.
character(len=256)            :: iomsg                                    !< IO message.
integer                       :: tmp_dir_len                              !< Length of the TMPDIR environment variable.
integer                       :: tmp_dir_status                           !< Status of the TMPDIR environment variable query.
logical                       :: test_passed(9)                           !< List of passed tests.

test_passed = .false.

call get_environment_variable('TMPDIR', length=tmp_dir_len, status=tmp_dir_status)
if (tmp_dir_status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
else
   tmp_dir = '/tmp'
endif
filename = tmp_dir//'/foxy_test_save.xml'

! parsed document: the file is the prolog plus stringify, ended by a new line, and parses back to the same document
source = '<?xml version="1.0" encoding="UTF-8"?>'//NL//'<!-- c -->'//NL//'<a>'//NL//'  <b k="1">2</b>'//NL//'</a>'
call xfile%parse(string=source)
call xfile%save(filename=filename, iostat=iostat, iomsg=iomsg)
test_passed(1) = iostat==0.and.file_content(filename)==source//NL
call xfile_reparsed%parse(filename=filename)
test_passed(2) = xfile_reparsed%stringify()==xfile%stringify()
call xfile%save(filename=filename, is_declared=.true.) ! a declaration already in the prolog is not repeated
test_passed(3) = file_content(filename)==source//NL
print "(A,L1)", 'Is a parsed document saved? ', all(test_passed(1:3))

! document built in code: no declaration unless asked
call xfile%free
call xfile%add_tag(xml_tag(name='config'))
call xfile%add_tag(xml_tag(name='dt', content='0.01'))
call xfile%save(filename=filename)
test_passed(4) = file_content(filename)==xfile%stringify()//NL
call xfile%save(filename=filename, is_declared=.true.)
test_passed(5) = file_content(filename)==DECLARATION//NL//xfile%stringify()//NL
call xfile%parse(string='<!-- c -->'//NL//'<a/>') ! a prolog without declaration gets it before the prolog
call xfile%save(filename=filename, is_declared=.true.)
test_passed(6) = file_content(filename)==DECLARATION//NL//'<!-- c -->'//NL//'<a/>'//NL
call xfile%parse(string='<?xml-stylesheet href="s.xsl"?>'//NL//'<a/>') ! a PI named xml-... is not a declaration
call xfile%save(filename=filename, is_declared=.true.)
test_passed(7) = index(file_content(filename), DECLARATION//NL//'<?xml-stylesheet')==1
print "(A,L1)", 'Is a built document saved, with the declaration if asked? ', all(test_passed(4:7))

! errors: the runtime iostat/iomsg are passed through
iomsg = ''
call xfile%save(filename=tmp_dir//'/foxy_test_save_missing_dir/a.xml', iostat=iostat, iomsg=iomsg)
print "(A,I0,A)", 'Missing directory: iostat=', iostat, ' iomsg='//trim(iomsg)
test_passed(8) = iostat/=0.and.len_trim(iomsg)>0
iomsg = 'unchanged'
call xfile%save(filename=filename, iostat=iostat, iomsg=iomsg)
test_passed(9) = iostat==0.and.iomsg=='unchanged'
print "(A,L1)", 'Are file errors reported? ', all(test_passed(8:9))

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   function file_content(filename) result(content)
   !< Return the whole content of a file, bytes as they are.
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
endprogram foxy_test_save
