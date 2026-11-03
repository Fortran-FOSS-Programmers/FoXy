!< FoXy test.
module foxy_test_events_recorder
!< FoXy test: a handler recording the events of a document.
use foxy, only : I4P, xml_attribute, xml_handler

implicit none
private
public :: recorder, rec_reset

character(len=1), parameter :: NL = new_line('a') !< New line.

type, extends(xml_handler) :: recorder
   !< Records the events as text lines, and per element its name, attributes and direct text.
   character(len=:), allocatable :: log           !< Events log (problems excepted).
   character(len=:), allocatable :: problems      !< Problems, in order (their place among text pieces depends on the
                                                  !< chunks: a problem inside character data comes between its pieces).
   character(len=:), allocatable :: text          !< Text not logged yet (pieces merged).
   character(len=1)              :: text_kind=' ' !< Kind of that text: T (characters) or C (CDATA).
   character(len=:), allocatable :: names         !< Names of the elements, in start order, separated by new lines.
   character(len=:), allocatable :: attrs         !< Attributes of the elements, one line per element.
   character(len=:), allocatable :: direct        !< Direct text (characters and CDATA) of the elements, each piece
                                                  !< after a header with its element number and length (one string:
                                                  !< nvfortran miscompiles an array of strings in a derived type here).
   integer(I4P),     allocatable :: open_ids(:)   !< IDs (start order) of the open elements.
   integer(I4P)                  :: n_open=0      !< Number of open elements.
   integer(I4P)                  :: n_elements=0  !< Number of elements started.
   integer(I4P)                  :: stop_after=0  !< Stop after this many start elements (0: never).
   contains
      procedure :: start_element => rec_start
      procedure :: end_element => rec_end
      procedure :: characters => rec_characters
      procedure :: cdata => rec_cdata
      procedure :: comment => rec_comment
      procedure :: processing_instruction => rec_pi
      procedure :: doctype => rec_doctype
      procedure :: problem => rec_problem
endtype recorder

contains
   subroutine rec_reset(self)
   !< Reset a recorder.
   type(recorder), intent(inout) :: self !< Recorder.

   self%log = ''
   self%problems = ''
   self%text = ''
   self%names = ''
   self%attrs = ''
   self%direct = ''
   if (allocated(self%open_ids)) deallocate(self%open_ids)
   allocate(self%open_ids(1000))
   self%n_open = 0
   self%n_elements = 0
   self%stop_after = 0
   endsubroutine rec_reset
   subroutine flush(self)
   !< Log the text collected.
   class(recorder), intent(inout) :: self !< Recorder.

   if (len(self%text)>0) self%log = self%log//self%text_kind//' '//self%text//NL
   self%text = ''
   self%text_kind = ' '
   endsubroutine flush
  subroutine append_direct(self, text)
   !< Add text to the direct text of the innermost open element.
   class(recorder), intent(inout) :: self !< Recorder.
   character(*),    intent(in)    :: text !< Text.

   character(len=24)              :: id   !< Header of the piece: element number and text length.

   if (self%n_open==0) return
   write(id, '(2I12)') self%open_ids(self%n_open), len(text) ! a fixed size header: element number, text length
   self%direct = self%direct//id(1:24)//text
   endsubroutine append_direct
   subroutine rec_start(self, name, attributes)
   class(recorder),     intent(inout) :: self
   character(*),        intent(in)    :: name
   type(xml_attribute), intent(in)    :: attributes(:)
   character(len=:), allocatable      :: line
   integer                            :: a
   call flush(self)
   line = ''
   do a=1, size(attributes)
      line = line//' '//attributes(a)%name//'='//attributes(a)%value
   enddo
   self%log = self%log//'S '//name//line//NL
   self%names = self%names//name//NL
   self%attrs = self%attrs//line//NL
   self%n_elements = self%n_elements + 1
   self%n_open = self%n_open + 1
   self%open_ids(self%n_open) = self%n_elements
   if (self%level/=self%n_open) self%log = self%log//'level mismatch'//NL
   if (self%stop_after>0.and.self%n_elements==self%stop_after) call self%stop_parsing()
   endsubroutine rec_start
   subroutine rec_end(self, name)
   class(recorder), intent(inout) :: self
   character(*),    intent(in)    :: name
   call flush(self)
   self%log = self%log//'E '//name//NL
   self%n_open = self%n_open - 1
   endsubroutine rec_end
   subroutine rec_characters(self, text)
   class(recorder), intent(inout) :: self
   character(*),    intent(in)    :: text
   if (self%text_kind=='C') call flush(self)
   self%text_kind = 'T'
   self%text = self%text//text
   call append_direct(self, text)
   endsubroutine rec_characters
   subroutine rec_cdata(self, text)
   class(recorder), intent(inout) :: self
   character(*),    intent(in)    :: text
   if (self%text_kind=='T') call flush(self)
   self%text_kind = 'C'
   self%text = self%text//text
   call append_direct(self, text)
   endsubroutine rec_cdata
   subroutine rec_comment(self, text)
   class(recorder), intent(inout) :: self
   character(*),    intent(in)    :: text
   call flush(self)
   self%log = self%log//'M '//text//NL
   endsubroutine rec_comment
   subroutine rec_pi(self, target, data)
   class(recorder), intent(inout) :: self
   character(*),    intent(in)    :: target
   character(*),    intent(in)    :: data
   call flush(self)
   self%log = self%log//'P '//target//'|'//data//NL
   endsubroutine rec_pi
   subroutine rec_doctype(self, text)
   class(recorder), intent(inout) :: self
   character(*),    intent(in)    :: text
   call flush(self)
   self%log = self%log//'D '//text//NL
   endsubroutine rec_doctype
   subroutine rec_problem(self, message)
   class(recorder), intent(inout) :: self
   character(*),    intent(in)    :: message
   self%problems = self%problems//message//NL
   endsubroutine rec_problem
endmodule foxy_test_events_recorder

!< FoXy test.
program foxy_test_events
!< FoXy test.
!<
!< The streaming parser: the events of a handler (start and end elements, decoded text, CDATA, comments, PIs, DOCTYPE,
!< problems) are the same for a string and for a file read in chunks of 1, 2, 3, 7 and 4096 bytes (no piece splits a
!< reference or a character), and they agree with the DOM (names, attributes, contents, first problem) on the test
!< files; elements are balanced on malformed input; stop_parsing stops.
use foxy, only : I4P, I8P, xml_file, XML_MALFORMED
use foxy_test_events_recorder, only : recorder, rec_reset

implicit none
character(len=1), parameter   :: NL = new_line('a')    !< New line.
character(len=:), allocatable :: tmp_dir               !< Temporary directory.
character(len=:), allocatable :: filename              !< File name.
character(len=:), allocatable :: source                !< Source.
character(len=:), allocatable :: files(:)              !< Test files.
type(recorder)                :: rec                   !< Recorder.
integer                       :: tmp_dir_len           !< Length of the TMPDIR environment variable.
integer                       :: status                !< Status of the environment variable query.
integer                       :: f                     !< Counter.
logical                       :: test_passed(5)        !< List of passed tests.

test_passed = .false.
call get_environment_variable('TMPDIR', length=tmp_dir_len, status=status)
if (status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
else
   tmp_dir = '/tmp'
endif
filename = tmp_dir//'/foxy_test_events.xml'

! the same events for a string and for a file in chunks, and the DOM agrees
source = '<?xml version="1.0"?>'//NL//'<!DOCTYPE r>'//NL//'<!-- head -->'//NL// &
         '<r a="1 &amp; 2" b=''x"y''>'//NL//'  <p k="&#233;">caf&#233; &lt;b&gt; t'//achar(13)//achar(10)//'u</p>'// &
         '<![CDATA[<raw & keep>]]>'//NL//'  <q/>mixed <i>tail</i> end<?pi do this?>'//NL//'</r>'//NL//'<!-- after -->'
test_passed(1) = is_consistent(source, 'inline')
files = [character(len=64) :: 'src/tests/data/quakeml_ci38457511.xml', 'src/tests/data/vtk/XML_RECT-ascii.vtr', &
         'src/tests/data/vtk/XML_UNST-ascii.vtu', 'src/tests/data/vtk/XML_STRG-binary.vts', &
         'src/tests/data/vtk/XML_UNST-raw.vtu']
do f=1, size(files)
   test_passed(1) = test_passed(1).and.is_consistent(file_content(trim(files(f))), trim(files(f)))
enddo
print "(A,L1)", 'Are the events the same for strings and chunked files, and as the DOM? ', test_passed(1)

! the events themselves
call rec_reset(rec)
call rec%parse(string=source)
test_passed(2) = rec%log=='P xml|version="1.0"'//NL//'T '//NL//NL//'D <!DOCTYPE r>'//NL//'T '//NL//NL//'M  head '//NL// &
                 'T '//NL//NL//'S r a=1 & 2 b=x"y'//NL//'T '//NL//'  '//NL//'S p k=é'//NL//'T café <b> t'//NL//'u'//NL// &
                 'E p'//NL//'C <raw & keep>'//NL//'T '//NL//'  '//NL//'S q'//NL//'E q'//NL//'T mixed '//NL//'S i'//NL// &
                 'T tail'//NL//'E i'//NL//'T  end'//NL//'P pi|do this'//NL//'T '//NL//NL//'E r'//NL//'T '//NL//NL// &
                 'M  after '//NL.and.rec%problems==''
if (.not.test_passed(2)) print "(A)", rec%log
print "(A,L1)", 'Are the events right? ', test_passed(2)

! malformed input: problems with their lines, elements balanced, the first problem returned
call rec_reset(rec)
call rec%parse(string='<a>'//NL//'<b><c></a>', iostat=status)
test_passed(3) = status==XML_MALFORMED.and.rec%log=='S a'//NL//'T '//NL//NL//'S b'//NL//'S c'//NL//'E c'//NL//'E b'//NL// &
                 'E a'//NL.and.rec%problems=='line 2: end tag </a> closes open tag <c>'//NL
call rec_reset(rec)
call rec%parse(string='<a><b>t', iostat=status)
test_passed(3) = test_passed(3).and.status==XML_MALFORMED.and.rec%log=='S a'//NL//'S b'//NL//'T t'//NL//'E b'//NL// &
                 'E a'//NL.and.rec%problems=='line 1: unclosed tag <a>'//NL
print "(A,L1)", 'Are malformed input events balanced? ', test_passed(3)

! stop_parsing
call rec_reset(rec)
rec%stop_after = 2
call rec%parse(string='<a><b/><c/><d/></a>', iostat=status)
test_passed(4) = status==0.and.rec%log=='S a'//NL//'S b'//NL
print "(A,L1)", 'Does stop_parsing stop? ', test_passed(4)

! a missing file
call rec_reset(rec)
call rec%parse(filename=tmp_dir//'/foxy_test_events_missing.xml', iostat=status)
test_passed(5) = status/=0.and.status/=XML_MALFORMED
print "(A,L1)", 'Is a missing file reported? ', test_passed(5)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   function is_consistent(text, label)
   !< Check that the events of a source are the same as a string and as a file in chunks, and that they agree with the
   !< DOM of the source.
   character(*), intent(in)      :: text          !< Source.
   character(*), intent(in)      :: label         !< Label for the messages.
   logical                       :: is_consistent !< Check result.
   character(len=:), allocatable :: reference     !< Log of the string.
   type(xml_file)                :: dom           !< DOM of the source.
   integer(I8P)                  :: chunks(5)     !< Chunk sizes.
   integer(I4P)                  :: iostat_string !< Status of the string parse.
   integer(I4P)                  :: iostat_dom    !< Status of the DOM parse.
   character(len=256)            :: iomsg_string  !< First problem of the string parse.
   character(len=256)            :: iomsg_dom     !< First problem of the DOM parse.
   integer(I4P)                  :: iostat        !< Status.
   character(len=256)            :: iomsg         !< Message.
   integer                       :: c, t, a       !< Counters.
   character(len=:), allocatable :: line          !< Attributes line.
   character(len=:), allocatable :: problems      !< Problems of the string.

   is_consistent = .true.
   call rec_reset(rec)
   iomsg_string = ''
   call rec%parse(string=text, iostat=iostat_string, iomsg=iomsg_string)
   reference = rec%log
   problems = rec%problems
   ! the DOM
   iomsg_dom = ''
   call dom%parse(string=text, iostat=iostat_dom, iomsg=iomsg_dom)
   if (iostat_dom/=iostat_string.or.iomsg_dom/=iomsg_string) then
      print "(A)", label//': problems differ: '//trim(iomsg_string)//' | '//trim(iomsg_dom)
      is_consistent = .false.
   endif
   if (rec%n_elements/=dom%tags_number()) then
      print "(A,2I8)", label//': elements differ ', rec%n_elements, dom%tags_number()
      is_consistent = .false.
      return
   endif
   do t=1, dom%tags_number()
      line = ''
      do a=1, dom%attributes_number(t)
         line = line//' '//dom%attribute_name(t, a)//'='//dom%attribute(t, dom%attribute_name(t, a))
      enddo
      if (nth_line(rec%names, t)/=dom%name(t).or.nth_line(rec%attrs, t)/=line.or. &
          stripped(direct_text(rec%direct, t))/=dom%content(id=t)) then
         print "(A,I0,A)", label//': element ', t, ' differs: '//dom%name(t)
         is_consistent = .false.
         return
      endif
   enddo
   ! chunked files
   call write_file(text)
   chunks = [1_I8P, 2_I8P, 3_I8P, 7_I8P, 4096_I8P]
   do c=1, size(chunks)
      call rec_reset(rec)
      iomsg = ''
      call rec%parse(filename=filename, chunk_size=chunks(c), iostat=iostat, iomsg=iomsg)
      if (rec%log/=reference.or.rec%problems/=problems.or.iostat/=iostat_string.or.iomsg/=iomsg_string) then
         print "(A,I0)", label//': events differ with chunks of ', chunks(c)
         is_consistent = .false.
      endif
   enddo
   endfunction is_consistent
   function file_content(name) result(content)
   !< Return the whole content of a file.
   character(*), intent(in)      :: name     !< File name.
   character(len=:), allocatable :: content  !< File content.
   integer                       :: unit     !< File unit.
   integer                       :: filesize !< File size.

   open(newunit=unit, file=name, access='STREAM', form='UNFORMATTED', status='OLD')
   inquire(unit=unit, size=filesize)
   allocate(character(len=filesize) :: content)
   if (filesize>0) read(unit) content
   close(unit)
   endfunction file_content
   subroutine write_file(text)
   !< Write the test file.
   character(*), intent(in) :: text !< Source.
   integer                  :: unit !< File unit.

   open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE')
   if (len(text)>0) write(unit) text
   close(unit)
   endsubroutine write_file
   function direct_text(log, n) result(text)
   !< Return the direct text of the element number *n*: its pieces in the log (each one a 24 characters header, element
   !< number and length, then the text).
   character(*), intent(in)      :: log  !< Pieces.
   integer,      intent(in)      :: n    !< Element number.
   character(len=:), allocatable :: text !< Direct text.
   integer                       :: p, id, length

   text = ''
   p = 1
   do while (p+23<=len(log))
      read(log(p:p+23), '(2I12)') id, length
      if (id==n) text = text//log(p+24:p+23+length)
      p = p + 24 + length
   enddo
   endfunction direct_text

   function nth_line(text, n) result(line)
   !< Return the n-th line of a text.
   character(*), intent(in)      :: text !< Text.
   integer,      intent(in)      :: n    !< Line number.
   character(len=:), allocatable :: line !< Line.
   integer                       :: k, first, e

   first = 1
   do k=1, n-1
      e = index(text(first:), NL)
      first = first + e
   enddo
   e = index(text(first:), NL)
   line = text(first:first+e-2)
   endfunction nth_line
   function stripped(text) result(s)
   !< Return a text without leading and trailing XML blanks.
   character(*), intent(in)      :: text !< Text.
   character(len=:), allocatable :: s    !< Stripped text.
   integer                       :: first, last
   first = verify(text, ' '//achar(9)//achar(10)//achar(13))
   if (first==0) then
      s = ''
   else
      last = verify(text, ' '//achar(9)//achar(10)//achar(13), back=.true.)
      s = text(first:last)
   endif
   endfunction stripped
endprogram foxy_test_events
