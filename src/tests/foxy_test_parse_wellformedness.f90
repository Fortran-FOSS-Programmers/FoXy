!< FoXy test.
program foxy_test_parse_wellformedness
!< FoXy test.
!<
!< Well-formedness problems beyond the tags structure, reported as the first problem (XML_MALFORMED, iomsg with the line)
!< by the DOM (string, file in chunks) and the index: invalid tag or attribute names, duplicate attributes, character
!< data outside the root tag, no root tag, more root tags; parsing stays tolerant; a byte order mark and blanks around
!< the root are fine.
use foxy, only: I4P, I8P, XML_MALFORMED, xml_file, xml_index

implicit none
character(len=1), parameter   :: NL = new_line('a') !< New line.
character(len=3), parameter   :: BOM = achar(239)//achar(187)//achar(191) !< UTF-8 byte order mark.
character(len=:), allocatable :: tmp_dir            !< Temporary directory.
character(len=:), allocatable :: filename           !< File name.
type(xml_file)                :: xfile              !< XML file handler.
type(xml_index)               :: xindex             !< XML index.
integer(I4P)                  :: iostat             !< IO status.
character(len=256)            :: iomsg              !< IO message.
integer                       :: tmp_dir_len        !< Length of the TMPDIR environment variable.
integer                       :: status             !< Status of the environment variable query.
logical                       :: test_passed(11)    !< List of passed tests.
character(len=:), allocatable :: cjk                !< U+540D U+524D, a CJK name.
character(len=:), allocatable :: times              !< U+00D7, the multiplication sign, not a name character.
character(len=:), allocatable :: acute              !< U+0301, a combining acute accent: a name character, not a start.
character(len=:), allocatable :: greek_qm           !< U+037E, the Greek question mark: not a name character.

test_passed = .false.
call get_environment_variable('TMPDIR', length=tmp_dir_len, status=status)
if (status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
else
   tmp_dir = '/tmp'
endif
filename = tmp_dir//'/foxy_test_parse_wellformedness.xml'

test_passed(1) = is_valid(BOM//NL//'<a x="1" y="2">t</a>'//NL)
test_passed(2) = is_valid('<?xml version="1.0"?>'//NL//'<!-- c --><a/>'//NL//'<?pi x?>  '//NL)
test_passed(3) = is_malformed('<a/>'//NL//'<b/><c/>', ['line 2   ', 'second   ', '<b>      ']) ! one root only
test_passed(4) = is_valid('<_:a-b.c é="1" x:y="2"/>')
print "(A,L1)", 'Is well-formed input accepted, more roots reported? ', all(test_passed(1:4))

test_passed(5) = is_malformed('<a>'//NL//'<b x="1" y="2" x="3"/></a>', ['line 2   ', 'duplicate', '"x"      ', '<b>      '])
test_passed(5) = test_passed(5).and.xfile%attribute(xfile%find(name='b'), 'y')=='2' ! still built
test_passed(6) = is_malformed('<a><1b/></a>', ['invalid  ', '<1b>     '])
test_passed(7) = is_malformed('<a x.="1" -y="2"/>', ['invalid  ', '"-y"     ', '<a>      '])
test_passed(8) = is_malformed('<a/>'//NL//'junk', ['line 1   ', 'outside  ', 'root     ']) .and. &
                 is_malformed('junk <a/>', ['outside  ']) .and. is_malformed(BOM//'x<a/>', ['outside  '])
test_passed(9) = is_malformed('', ['no root  ']) .and. is_malformed('just text', ['outside  ']) .and. &
                 is_malformed('<!-- only -->', ['no root  '])
print "(A,L1)", 'Is malformed input reported? ', all(test_passed(5:9))

test_passed(10) = is_valid_index(BOM//'<a x="1"/>'//NL).and.is_malformed_index('<a x="1" x="2"/>', 'duplicate').and. &
                  is_malformed_index('<a/>x', 'outside').and.is_malformed_index('<a/><b/>', 'second root')
print "(A,L1)", 'Does the index report the same problems? ', test_passed(10)

! names follow XML 1.0 (5th edition) NameStartChar and NameChar, beyond ASCII
cjk = achar(229)//achar(144)//achar(141)//achar(229)//achar(137)//achar(141)
times = achar(195)//achar(151)
acute = achar(204)//achar(129)
greek_qm = achar(205)//achar(190)
test_passed(11) = is_valid('<'//cjk//' e'//acute//'="1" a'//achar(194)//achar(183)//'b="2"/>') .and. &
                  is_malformed('<'//times//'a/>', ['invalid  ']) .and. is_malformed('<'//acute//'a/>', ['invalid  ']) .and. &
                  is_malformed('<a'//greek_qm//'/>', ['invalid  ']) .and. is_malformed('<a '//times//'="1"/>', ['invalid  '])
print "(A,L1)", 'Are non ASCII names checked by the XML ranges? ', test_passed(11)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   function is_valid(source)
   !< Check that source is parsed without errors, as a string and as a file in chunks of 1 and 2 characters.
   character(*), intent(in) :: source   !< Source XML data.
   logical                  :: is_valid !< Check result.

   call xfile%parse(string=source, iostat=iostat, iomsg=iomsg)
   is_valid = iostat==0
   call write_file(source)
   call xfile%parse(filename=filename, chunk_size=1_I8P, iostat=iostat, iomsg=iomsg)
   is_valid = is_valid.and.iostat==0
   call xfile%parse(filename=filename, chunk_size=2_I8P, iostat=iostat, iomsg=iomsg)
   is_valid = is_valid.and.iostat==0
   print "(A,L1,A)", 'Valid input: ', is_valid, ' for '//source
   endfunction is_valid

   function is_malformed(source, expected)
   !< Check that source is reported as malformed (string and file in 1-character chunks), iomsg containing the expected.
   character(*), intent(in) :: source       !< Source XML data.
   character(*), intent(in) :: expected(1:) !< Substrings expected into iomsg.
   logical                  :: is_malformed !< Check result.
   character(len=256)       :: iomsg_file   !< IO message of the file parse.
   integer                  :: e            !< Counter.

   call write_file(source)
   call xfile%parse(filename=filename, chunk_size=1_I8P, iostat=iostat, iomsg=iomsg_file)
   is_malformed = iostat==XML_MALFORMED
   call xfile%parse(string=source, iostat=iostat, iomsg=iomsg)
   print "(A,I0,A)", 'Malformed input: iostat=', iostat, ' iomsg='//trim(iomsg)
   is_malformed = is_malformed.and.iostat==XML_MALFORMED.and.iomsg==iomsg_file
   do e=1, size(expected, dim=1)
      is_malformed = is_malformed.and.index(iomsg, trim(expected(e)))>0
   enddo
   endfunction is_malformed

   function is_valid_index(source)
   !< Check that the index scans source without errors.
   character(*), intent(in) :: source         !< Source XML data.
   logical                  :: is_valid_index !< Check result.

   call write_file(source)
   call xindex%scan(filename=filename, chunk_size=1_I8P, iostat=iostat, iomsg=iomsg)
   is_valid_index = iostat==0
   endfunction is_valid_index

   function is_malformed_index(source, expected)
   !< Check that the index reports source as malformed, iomsg containing *expected*.
   character(*), intent(in) :: source             !< Source XML data.
   character(*), intent(in) :: expected           !< Substring expected into iomsg.
   logical                  :: is_malformed_index !< Check result.

   call write_file(source)
   call xindex%scan(filename=filename, chunk_size=1_I8P, iostat=iostat, iomsg=iomsg)
   is_malformed_index = iostat==XML_MALFORMED.and.index(iomsg, expected)>0
   endfunction is_malformed_index

   subroutine write_file(source)
   !< Write source into the test file.
   character(*), intent(in) :: source !< Source XML data.
   integer                  :: unit   !< File unit.

   open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE')
   if (len(source)>0) write(unit) source
   close(unit)
   endsubroutine write_file
endprogram foxy_test_parse_wellformedness
