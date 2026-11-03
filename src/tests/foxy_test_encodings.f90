!< FoXy test.
module foxy_test_encodings_handler
!< A handler with the default (no-op) callbacks.
use foxy, only : xml_handler
implicit none
private
public :: silent_handler

type, extends(xml_handler) :: silent_handler
   !< No callbacks: only the status of parse is checked.
endtype silent_handler
endmodule foxy_test_encodings_handler

program foxy_test_encodings
!< FoXy test.
!<
!< Encodings: files in UTF-16, UTF-32 (both endiannesses, with their byte order mark), ISO-8859-1, windows-1252 and
!< US-ASCII (fixtures written by Python codecs, checked against iconv) give the document of their UTF-8 copy, whose
!< declaration says UTF-8: parsed from the file in chunks of 1 to 17 bytes and 1 MiB, from a string, and by the streaming
!< parser; problems (an unpaired surrogate, no byte order mark, a declaration contradicting it, an encoding not
!< supported) are reported with their line; the index refuses UTF-16/UTF-32 and reads single byte encodings as UTF-8; the
!< writer declares UTF-8 only.
use foxy, only : I4P, I8P, xml_file, xml_index, xml_writer, XML_MALFORMED
use foxy_test_encodings_handler, only : silent_handler

implicit none
character(*), parameter   :: DATA_DIR = 'src/tests/data/encodings/' !< Fixtures.
character(*), parameter   :: CONVERTED(7) = [character(len=7) :: 'utf16le', 'utf16be', 'utf32le', 'utf32be', 'latin1', &
                                             'cp1252', 'ascii']    !< Fixtures converted, with an expected UTF-8 copy.
type(xml_file)            :: doc            !< Document.
type(xml_file)            :: expected       !< Document of the UTF-8 copy.
type(xml_index)           :: idx            !< Index.
type(silent_handler)      :: handler        !< Streaming parser (no callbacks).
type(xml_writer)          :: writer         !< Writer.
character(len=:), allocatable :: tmp_dir    !< Temporary directory.
character(len=:), allocatable :: saved      !< Saved file name.
character(len=:), allocatable :: text       !< Text written by the writer.
character(len=500)        :: iomsg          !< IO message.
integer(I4P)              :: iostat         !< IO status.
integer(I8P)              :: chunk          !< Chunk size.
integer                   :: f              !< Counter.
integer                   :: tmp_dir_len    !< Length of the TMPDIR environment variable.
integer                   :: status         !< Status of the environment variable query.
logical                   :: is_same        !< The documents are the same.
logical                   :: test_passed(6) !< List of passed tests.

test_passed = .true.
call get_environment_variable('TMPDIR', length=tmp_dir_len, status=status)
if (status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
   tmp_dir = tmp_dir//'/'
else
   tmp_dir = '/tmp/'
endif

! converted files give the document of their UTF-8 copy, whatever the chunks, also from a string
do f=1, size(CONVERTED)
   call expected%parse(filename=DATA_DIR//trim(CONVERTED(f))//'.expected.xml', iostat=iostat)
   test_passed(1) = test_passed(1).and.iostat==0
   call doc%parse(filename=DATA_DIR//trim(CONVERTED(f))//'.xml', iostat=iostat)
   is_same = iostat==0.and.doc%stringify()==expected%stringify().and.doc%tags_number()==expected%tags_number()
   do chunk=1, 17
      call doc%parse(filename=DATA_DIR//trim(CONVERTED(f))//'.xml', chunk_size=chunk, iostat=iostat)
      is_same = is_same.and.iostat==0.and.doc%stringify()==expected%stringify()
   enddo
   call doc%parse(string=file_bytes(DATA_DIR//trim(CONVERTED(f))//'.xml'), iostat=iostat)
   is_same = is_same.and.iostat==0.and.doc%stringify()==expected%stringify()
   if (.not.is_same) print '(A)', '  differs: '//trim(CONVERTED(f))
   test_passed(1) = test_passed(1).and.is_same
enddo
call doc%parse(filename=DATA_DIR//'utf16le.xml')
test_passed(1) = test_passed(1).and.doc%attribute(doc%find(name='case'), 'name')=='café'.and. &
                 doc%content(name='note')=='€ 5 — 😀'
print "(A,L1)", 'Are converted files read as their UTF-8 copy? ', test_passed(1)

! the streaming parser reads them too, in pieces
do f=1, size(CONVERTED)
   do chunk=1, 9, 4
      call handler%parse(filename=DATA_DIR//trim(CONVERTED(f))//'.xml', chunk_size=chunk, iostat=iostat)
      test_passed(2) = test_passed(2).and.iostat==0
   enddo
   call handler%parse(string=file_bytes(DATA_DIR//trim(CONVERTED(f))//'.xml'), iostat=iostat)
   test_passed(2) = test_passed(2).and.iostat==0
enddo
print "(A,L1)", 'Does the streaming parser read converted files? ', test_passed(2)

! problems, with their line, the document still built (tolerant)
test_passed(3) = is_reported('utf16le_invalid.xml', 'line 3: invalid UTF-16LE sequence')
test_passed(3) = test_passed(3).and.is_reported('utf16le_nobom.xml', &
                                                'line 1: a UTF-16 source must start with a byte order mark')
test_passed(3) = test_passed(3).and.is_reported('utf16le_mismatch.xml', &
                                                'line 1: encoding "ISO-8859-1" declared, but the source is UTF-16LE')
test_passed(3) = test_passed(3).and.is_reported('sjis.xml', 'line 1: encoding "Shift_JIS" not supported')
call doc%parse(filename=DATA_DIR//'utf16le_invalid.xml')
test_passed(3) = test_passed(3).and.doc%tags_number()==4.and.doc%content(name='fluid')=='e'//achar(255)//'u à 20'
do chunk=1, 5
   iomsg = ''
   call handler%parse(filename=DATA_DIR//'utf16le_invalid.xml', chunk_size=chunk, iostat=iostat, iomsg=iomsg)
   test_passed(3) = test_passed(3).and.iostat==XML_MALFORMED.and.trim(iomsg)=='line 3: invalid UTF-16LE sequence'
enddo
iomsg = ''
call doc%parse(string=file_bytes(DATA_DIR//'utf16le_invalid.xml'), iostat=iostat, iomsg=iomsg)
test_passed(3) = test_passed(3).and.iostat==XML_MALFORMED.and.trim(iomsg)=='line 3: invalid UTF-16LE sequence'
print "(A,L1)", 'Are encoding problems reported with their line? ', test_passed(3)

! saved, a converted document declares UTF-8
saved = tmp_dir//'foxy_test_encodings.xml'
call doc%parse(filename=DATA_DIR//'latin1.xml')
call doc%save(filename=saved, iostat=iostat)
test_passed(4) = iostat==0.and.index(file_bytes(saved), '<?xml version="1.0" encoding="UTF-8"?>')==1
call expected%parse(filename=saved, iostat=iostat)
test_passed(4) = test_passed(4).and.iostat==0.and.expected%attribute(expected%find(name='case'), 'name')=='café'
call doc%parse(filename=DATA_DIR//'utf32be.xml')
call doc%save(filename=saved, iostat=iostat)
test_passed(4) = test_passed(4).and.iostat==0.and.index(file_bytes(saved), '<?xml version="1.0" encoding="UTF-8"?>')==1
print "(A,L1)", 'Do saved converted documents declare UTF-8? ', test_passed(4)

! the index reads the file bytes: UTF-16/UTF-32 refused, single byte encodings read as UTF-8
call idx%scan(filename=DATA_DIR//'utf16be.xml', iostat=iostat, iomsg=iomsg)
test_passed(5) = iostat==XML_MALFORMED.and.index(iomsg, 'a UTF-16BE file cannot be indexed')>0.and.idx%tags_number()==0
call idx%scan(filename=DATA_DIR//'ascii.xml', iostat=iostat)
test_passed(5) = test_passed(5).and.iostat==0.and.idx%tags_number()==2
iomsg = ''
call idx%scan(filename=DATA_DIR//'latin1.xml', iostat=iostat, iomsg=iomsg)
test_passed(5) = test_passed(5).and.iostat==XML_MALFORMED.and.idx%tags_number()==4.and. &
                 trim(iomsg)=='line 2: invalid UTF-8 byte 0xE9 (the source is ISO-8859-1, read as UTF-8)'
print "(A,L1)", 'Does the index read the file bytes only? ', test_passed(5)

! the writer writes UTF-8: it declares no other encoding
call writer%open(iostat=iostat)
call writer%declaration(encoding='ISO-8859-1', iostat=iostat, iomsg=iomsg)
test_passed(6) = iostat==XML_MALFORMED.and.index(iomsg, 'the writer writes UTF-8 only')>0
call writer%open(iostat=iostat)
call writer%declaration(encoding='utf-8', iostat=iostat)
call writer%start('a', iostat=iostat)
call writer%close(iostat=iostat)
text = writer%string()
test_passed(6) = test_passed(6).and.iostat==0.and.index(text, 'encoding="utf-8"')>0
print "(A,L1)", 'Does the writer declare UTF-8 only? ', test_passed(6)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   function file_bytes(filename) result(bytes)
   !< Return the bytes of a file.
   character(*), intent(in)      :: filename !< File name.
   character(len=:), allocatable :: bytes    !< Bytes.
   integer                       :: unit     !< File unit.
   integer                       :: size_    !< File size.

   open(newunit=unit, file=filename, access='stream', form='unformatted', action='read', status='old')
   inquire(unit=unit, size=size_)
   allocate(character(len=size_) :: bytes)
   if (size_>0) read(unit) bytes
   close(unit)
   endfunction file_bytes

   function is_reported(name, message) result(is_ok)
   !< Return true if parsing the fixture *name* reports *message* (DOM from the file, chunks of 1 to 7 bytes).
   character(*), intent(in) :: name    !< Fixture name.
   character(*), intent(in) :: message !< Expected first problem.
   logical                  :: is_ok   !< Check result.
   integer(I8P)             :: chunk_  !< Chunk size.

   is_ok = .true.
   do chunk_=1, 7
      iomsg = ''
      call doc%parse(filename=DATA_DIR//name, chunk_size=chunk_, iostat=iostat, iomsg=iomsg)
      is_ok = is_ok.and.iostat==XML_MALFORMED.and.trim(iomsg)==message
   enddo
   if (.not.is_ok) print '(A)', '  not reported as expected: '//name//': '//trim(iomsg)
   endfunction is_reported
endprogram foxy_test_encodings
