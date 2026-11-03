!< FoXy test.
program foxy_test_parse_utf8
!< FoXy test.
!<
!< The source must be well-formed UTF-8 (Unicode Table 3-7): an overlong form, a surrogate, a value above U+10FFFF, a
!< truncated sequence or a stray continuation byte is reported (XML_MALFORMED, its line), the document still built; the
!< problems come in source order with the other ones; a string, a file read in chunks of 1 to 3 bytes (a sequence split
!< by the chunks) and the index agree.
use foxy, only: I4P, I8P, XML_MALFORMED, xml_file, xml_index

implicit none
character(len=1), parameter   :: NL = new_line('a') !< New line.
character(len=:), allocatable :: tmp_dir            !< Temporary directory.
character(len=:), allocatable :: filename           !< File name.
character(len=:), allocatable :: e_acute            !< U+00E9, 2 bytes.
character(len=:), allocatable :: euro               !< U+20AC, 3 bytes.
character(len=:), allocatable :: smile              !< U+1F600, 4 bytes.
type(xml_file)                :: xfile              !< XML file handler.
type(xml_index)               :: xindex             !< XML index.
integer(I4P)                  :: iostat             !< IO status.
character(len=256)            :: iomsg              !< IO message.
integer                       :: tmp_dir_len        !< Length of the TMPDIR environment variable.
integer                       :: status             !< Status of the environment variable query.
logical                       :: test_passed(6)     !< List of passed tests.

test_passed = .false.
call get_environment_variable('TMPDIR', length=tmp_dir_len, status=status)
if (status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
else
   tmp_dir = '/tmp'
endif
filename = tmp_dir//'/foxy_test_parse_utf8.xml'
e_acute = achar(195)//achar(169)
euro = achar(226)//achar(130)//achar(172)
smile = achar(240)//achar(159)//achar(152)//achar(128)

test_passed(1) = is_valid('<p v="'//euro//'">caf'//e_acute//' '//smile//'<!-- '//euro//' --></p>')
print "(A,L1)", 'Is well-formed UTF-8 accepted? ', test_passed(1)

test_passed(2) = is_malformed('<p>'//NL//'a'//achar(192)//achar(175)//'</p>', 'line 2')  .and. & ! overlong '/'
                 is_malformed('<p>'//achar(237)//achar(160)//achar(128)//'</p>', 'line 1')  .and. & ! surrogate U+D800
                 is_malformed('<p>'//achar(244)//achar(144)//achar(128)//achar(128)//'</p>', 'line 1') .and. & ! > U+10FFFF
                 is_malformed('<p>'//achar(226)//achar(130)//'</p>', 'line 1')              .and. & ! truncated
                 is_malformed('<p>'//achar(128)//'</p>', 'line 1')                          .and. & ! stray continuation
                 is_malformed('<p a="'//achar(255)//'"/>', 'line 1')                         .and. & ! in an attribute
                 is_malformed('<p><!-- '//achar(193)//' --></p>', 'line 1')                       ! in a comment
print "(A,L1)", 'Is ill-formed UTF-8 reported? ', test_passed(2)

call xfile%parse(string='<p>ok '//achar(128)//' <b>t</b></p>', iostat=iostat, iomsg=iomsg)
test_passed(3) = iostat==XML_MALFORMED.and.xfile%content('b')=='t'.and.xfile%content('p')=='ok '//achar(128)
print "(A,L1)", 'Is the document still built? ', test_passed(3)

! source order: the first problem is the one met first in the source
call xfile%parse(string='<a><b></a>'//achar(128)//'</x>', iostat=iostat, iomsg=iomsg)
test_passed(4) = iostat==XML_MALFORMED.and.index(iomsg, 'closes open tag')>0
call xfile%parse(string='<a>'//achar(128)//'<b></a>', iostat=iostat, iomsg=iomsg)
test_passed(4) = test_passed(4).and.iostat==XML_MALFORMED.and.index(iomsg, 'UTF-8')>0
print "(A,L1)", 'Are the problems in source order? ', test_passed(4)

! a sequence at the end of the source is checked whole (truncated: reported)
test_passed(5) = is_malformed('<p>'//NL//achar(240)//achar(159), 'line 2') ! before 'unclosed tag', found at the end
print "(A,L1)", 'Is a truncated sequence at the source end reported? ', test_passed(5)

call write_file('<p>'//smile//euro//e_acute//'</p>')
call xindex%scan(filename=filename, chunk_size=1_I8P, iostat=iostat)
test_passed(6) = iostat==0
call write_file('<p>'//achar(240)//achar(159)//'x</p>')
call xindex%scan(filename=filename, chunk_size=1_I8P, iostat=iostat, iomsg=iomsg)
test_passed(6) = test_passed(6).and.iostat==XML_MALFORMED.and.index(iomsg, 'UTF-8')>0
print "(A,L1)", 'Does the index check UTF-8 too? ', test_passed(6)

open(newunit=status, file=filename, status='OLD')
close(status, status='DELETE')
print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   function is_valid(source)
   !< Check that source is parsed without errors, as a string and as a file in chunks of 1, 2 and 3 bytes.
   character(*), intent(in) :: source   !< Source XML data.
   logical                  :: is_valid !< Check result.
   integer(I8P)             :: c        !< Chunk size.

   call xfile%parse(string=source, iostat=iostat, iomsg=iomsg)
   is_valid = iostat==0
   call write_file(source)
   do c=1, 3
      call xfile%parse(filename=filename, chunk_size=c, iostat=iostat, iomsg=iomsg)
      is_valid = is_valid.and.iostat==0
   enddo
   endfunction is_valid

   function is_malformed(source, expected)
   !< Check that source is reported as ill-formed UTF-8 (string, and file in chunks of 1, 2 and 3 bytes, same message).
   character(*), intent(in) :: source       !< Source XML data.
   character(*), intent(in) :: expected     !< Substring expected into iomsg, besides "UTF-8".
   logical                  :: is_malformed !< Check result.
   character(len=256)       :: iomsg_file   !< IO message of the file parse.
   integer(I8P)             :: c            !< Chunk size.

   call xfile%parse(string=source, iostat=iostat, iomsg=iomsg)
   print "(A,I0,A)", 'Malformed: iostat=', iostat, ' iomsg='//trim(iomsg)
   is_malformed = iostat==XML_MALFORMED.and.index(iomsg, 'UTF-8')>0.and.index(iomsg, expected)>0
   call write_file(source)
   do c=1, 3
      call xfile%parse(filename=filename, chunk_size=c, iostat=iostat, iomsg=iomsg_file)
      is_malformed = is_malformed.and.iostat==XML_MALFORMED.and.iomsg_file==iomsg
   enddo
   endfunction is_malformed

   subroutine write_file(source)
   !< Write source into the test file.
   character(*), intent(in) :: source !< Source XML data.
   integer                  :: unit   !< File unit.

   open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE')
   write(unit) source
   close(unit)
   endsubroutine write_file
endprogram foxy_test_parse_utf8
