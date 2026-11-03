!< FoXy streaming parser: the document as a sequence of events, reported to a handler of yours.
module foxy_xml_events
!< FoXy streaming parser: the document as a sequence of events, reported to a handler of yours.
!<
!< Extend *xml_handler*, override the callbacks you need (each one does nothing by default) and call *parse* on a string
!< or a file: the callbacks come in source order (`start_element`, `characters`, `end_element`, ...), the source is read
!< in chunks and the memory used does not depend on its size. The callbacks are ordinary procedures (they may write
!< files, print, keep any state in your type).
!<
!< @note The pure tokenizer drives an *event_builder*, which queues the events of one chunk; *parse* then decodes them
!< and calls the handler. Character data (and CDATA) is reported in pieces, decoded (references, line ends), never
!< splitting a reference, a CR LF pair or a UTF-8 character; attribute values are normalized and decoded as
!< `xml_file%attribute` returns them. Elements are always balanced: an element closed implicitly (malformed input, or
!< open at the source end) gets its `end_element`. Problems are reported in source order among the other events; a
!< problem inside character data may come between two pieces of that text (where depends on the chunks).
use foxy_xml_entities, only : attribute_value, character_data, line_ends_normalized, utf8_tail_len
use foxy_xml_file, only : XML_MALFORMED
use foxy_xml_tokenizer, only : xml_builder, xml_tokenizer, located, &
                               DATA_TEXT, DATA_CDATA, DATA_COMMENT, DATA_PI, DATA_DECLARATION
use penf

implicit none
private
public :: xml_attribute
public :: xml_handler

integer(I8P), parameter :: DEFAULT_CHUNK  = 1048576_I8P !< Default size of the chunks read (1 MiB).
integer(I8P), parameter :: MAX_REFERENCE  = 64_I8P      !< Longest reference start kept for the next piece.
integer(I4P), parameter :: EVENT_START    = 1_I4P       !< A start tag (with its attributes).
integer(I4P), parameter :: EVENT_END      = 2_I4P       !< An end tag (or the end of a self closing tag).
integer(I4P), parameter :: EVENT_TEXT     = 3_I4P       !< Character data, raw.
integer(I4P), parameter :: EVENT_CDATA    = 4_I4P       !< CDATA content, raw.
integer(I4P), parameter :: EVENT_COMMENT  = 5_I4P       !< A comment, whole.
integer(I4P), parameter :: EVENT_PI       = 6_I4P       !< A processing instruction, whole.
integer(I4P), parameter :: EVENT_DOCTYPE  = 7_I4P       !< A declaration (DOCTYPE), whole.
integer(I4P), parameter :: EVENT_PROBLEM  = 8_I4P       !< A problem of malformed input.

type :: xml_attribute
   !< An attribute of a start element: its name, as written, and its value, normalized and decoded.
   character(len=:), allocatable :: name  !< Name (prefix included).
   character(len=:), allocatable :: value !< Value (blanks as spaces, references decoded).
endtype xml_attribute

type, abstract :: xml_handler
   !< Handler of the events of a document: extend it, override the callbacks you need, call *parse*.
   integer(I4P)         :: level=0_I4P       !< Depth of the current element (1 for the root), set by *parse*.
   integer(I8P)         :: pos=0_I8P         !< Position (byte) in the source of the current event, set by *parse*.
   logical, private     :: is_stopped=.false. !< *stop_parsing* was called.
   contains
      ! callbacks, overridden by your handler
      procedure, pass(self) :: start_element          !< A start tag, with its attributes.
      procedure, pass(self) :: end_element            !< An end tag (also right after a self closing start tag).
      procedure, pass(self) :: characters             !< Character data, decoded (maybe in pieces).
      procedure, pass(self) :: cdata                  !< CDATA content, literal (maybe in pieces).
      procedure, pass(self) :: comment                !< A comment, without its markup.
      procedure, pass(self) :: processing_instruction !< A processing instruction: target and data.
      procedure, pass(self) :: doctype                !< A declaration (DOCTYPE), as in the source.
      procedure, pass(self) :: problem                !< A problem of malformed input, with its line.
      ! called by you
      procedure, pass(self) :: parse                  !< Parse a string or a file, calling the callbacks.
      procedure, pass(self) :: stop_parsing           !< No more callbacks: *parse* returns.
endtype xml_handler

type :: event_record
   !< An event of the queue.
   integer(I4P)                     :: kind=0_I4P  !< Event kind, EVENT_*.
   integer(I4P)                     :: level=0_I4P !< Element depth.
   integer(I8P)                     :: pos=0_I8P   !< Position in the source.
   character(len=:), allocatable    :: name        !< Element name (start, end), or the message (problem).
   character(len=:), allocatable    :: text        !< Raw text (character data, CDATA, comment, PI, declaration).
   type(xml_attribute), allocatable :: attributes(:) !< Attributes (start).
endtype event_record

type, extends(xml_builder) :: event_builder
   !< Builder queuing the events of one chunk (pure, as the tokenizer requires).
   logical                          :: sanitize=.true.   !< Trim leading and trailing spaces of attribute values.
   type(event_record), allocatable  :: events(:)          !< Events queued.
   integer(I4P)                     :: ne=0_I4P           !< Number of events queued.
   character(len=:), allocatable    :: open_name          !< Name of the start tag being read.
   integer(I8P)                     :: open_pos=0_I8P     !< Its position.
   integer(I4P)                     :: open_level=0_I4P   !< Its level.
   type(xml_attribute), allocatable :: open_attributes(:) !< Its attributes.
   integer(I4P)                     :: na=0_I4P           !< Number of its attributes.
   integer(I4P), allocatable        :: stack_id(:)        !< IDs of the open elements.
   type(xml_attribute), allocatable :: stack_name(:)      !< Names of the open elements (in *name*).
   integer(I4P)                     :: depth=0_I4P        !< Number of open elements.
   logical                          :: in_cdata=.false.   !< A CDATA section continues in the next piece.
   integer(I4P)                     :: markup_kind=0_I4P  !< Kind of the comment/PI being collected, 0 if none.
   character(len=:), allocatable    :: markup             !< Comment/PI being collected.
   integer(I8P)                     :: markup_pos=0_I8P   !< Its position.
   contains
      procedure, pass(self) :: start_tag     => events_start_tag     !< A start tag begins.
      procedure, pass(self) :: attribute     => events_attribute     !< An attribute of the current start tag.
      procedure, pass(self) :: start_tag_end => events_start_tag_end !< The current start tag is complete.
      procedure, pass(self) :: end_tag       => events_end_tag       !< An open tag is closed by its end tag.
      procedure, pass(self) :: data          => events_data          !< Character data or other markup.
      procedure, pass(self) :: problem       => events_problem       !< A problem of malformed input.
      procedure, pass(self) :: finish        => events_finish        !< The source is ended.
endtype event_builder

type :: text_decoder
   !< Decoder of character data (or CDATA) given in pieces: a final part that may continue in the next piece (a
   !< reference without its `;`, a CR, an incomplete UTF-8 character) is carried.
   character(len=:), allocatable :: carry        !< Raw characters carried.
   integer(I8P)                  :: pos=0_I8P    !< Position of the first character carried.
   logical                       :: is_cdata=.false. !< CDATA: references are not decoded.
endtype text_decoder

contains
   ! callbacks, defaults: nothing
   subroutine start_element(self, name, attributes)
   !< A start tag, with its attributes (in source order, values normalized and decoded); does nothing unless overridden.
   class(xml_handler),  intent(inout) :: self          !< Handler.
   character(*),        intent(in)    :: name          !< Element name, as written.
   type(xml_attribute), intent(in)    :: attributes(:) !< Attributes, size 0 if none.
   endsubroutine start_element

   subroutine end_element(self, name)
   !< An end tag (also right after a self closing start tag); does nothing unless overridden.
   class(xml_handler), intent(inout) :: self !< Handler.
   character(*),       intent(in)    :: name !< Element name, as written.
   endsubroutine end_element

   subroutine characters(self, text)
   !< Character data, decoded; the text between two tags may come in pieces (never splitting a reference or a UTF-8
   !< character); does nothing unless overridden.
   class(xml_handler), intent(inout) :: self !< Handler.
   character(*),       intent(in)    :: text !< Text.
   endsubroutine characters

   subroutine cdata(self, text)
   !< CDATA content, literal (line ends normalized), maybe in pieces; does nothing unless overridden.
   class(xml_handler), intent(inout) :: self !< Handler.
   character(*),       intent(in)    :: text !< Text.
   endsubroutine cdata

   subroutine comment(self, text)
   !< A comment, without `<!--` and `-->`; does nothing unless overridden.
   class(xml_handler), intent(inout) :: self !< Handler.
   character(*),       intent(in)    :: text !< Comment.
   endsubroutine comment

   subroutine processing_instruction(self, target, data)
   !< A processing instruction `<?target data?>` (the XML declaration included); does nothing unless overridden.
   class(xml_handler), intent(inout) :: self   !< Handler.
   character(*),       intent(in)    :: target !< Target.
   character(*),       intent(in)    :: data   !< Data, after the blanks following the target.
   endsubroutine processing_instruction

   subroutine doctype(self, text)
   !< A declaration (`<!DOCTYPE ...>`), as in the source; does nothing unless overridden.
   class(xml_handler), intent(inout) :: self !< Handler.
   character(*),       intent(in)    :: text !< Declaration.
   endsubroutine doctype

   subroutine problem(self, message)
   !< A problem of malformed input, as `line N: ...`; parsing goes on; does nothing unless overridden.
   class(xml_handler), intent(inout) :: self    !< Handler.
   character(*),       intent(in)    :: message !< Problem description.
   endsubroutine problem

   ! called by you
   subroutine stop_parsing(self)
   !< Stop parsing: no more callbacks, the rest of the source is not read, *parse* returns.
   class(xml_handler), intent(inout) :: self !< Handler.

   self%is_stopped = .true.
   endsubroutine stop_parsing

   subroutine parse(self, string, filename, chunk_size, sanitize_attributes_value, iostat, iomsg)
   !< Parse a string or a file, calling the callbacks of the handler in source order.
   !<
   !< @note *iostat* is 0, the runtime I/O error code if the file cannot be read, or *XML_MALFORMED* if the input is
   !< malformed (every problem is also passed to *problem*; parsing is tolerant); *iomsg* holds the first problem, as
   !< `line N: ...`. Stopped by *stop_parsing*, *parse* returns the problems met so far.
   class(xml_handler),     intent(inout) :: self                      !< Handler.
   character(*), optional, intent(in)    :: string                    !< Source string.
   character(*), optional, intent(in)    :: filename                  !< Source file name.
   integer(I8P), optional, intent(in)    :: chunk_size                !< Size of the chunks (default 1 MiB).
   logical,      optional, intent(in)    :: sanitize_attributes_value !< Trim the spaces around values (default true).
   integer(I4P), optional, intent(out)   :: iostat                    !< IO status.
   character(*), optional, intent(inout) :: iomsg                     !< IO message.
   type(xml_tokenizer)                   :: tokenizer                 !< Tokenizer.
   type(event_builder)                   :: builder                   !< Event builder.
   type(text_decoder)                    :: text_dec                  !< Decoder of character data.
   type(text_decoder)                    :: cdata_dec                 !< Decoder of CDATA.
   character(len=:), allocatable         :: window                    !< Characters not consumed yet, then the chunk.
   character(len=:), allocatable         :: rest                      !< Characters not consumed yet.
   character(len=:), allocatable         :: first_problem             !< First problem, located.
   character(len=500)                    :: io_message                !< Message of an I/O error.
   integer(I8P)                          :: chunk                     !< Size of the chunks.
   integer(I8P)                          :: source_size               !< Size of the source.
   integer(I8P)                          :: read_size                 !< Characters read so far.
   integer(I8P)                          :: piece                     !< Size of the chunk to read.
   integer(I8P)                          :: offset                    !< Position of the character before the window.
   integer(I8P)                          :: consumed                  !< Characters consumed by the tokenizer.
   integer(I8P)                          :: lines                     !< New lines before the window.
   integer(I4P)                          :: io_status                 !< I/O status.
   integer(I4P)                          :: unit                      !< File unit.
   logical                               :: is_file                   !< The source is a file.
   logical                               :: is_last                   !< The window ends the source.

   if (present(iostat)) iostat = 0
   self%is_stopped = .false.
   self%level = 0
   self%pos = 0
   unit = -1
   is_file = present(filename).and.(.not.present(string))
   if ((.not.is_file).and.(.not.present(string))) return
   chunk = DEFAULT_CHUNK ; if (present(chunk_size)) chunk = max(1_I8P, chunk_size)
   builder%sanitize = .true. ; if (present(sanitize_attributes_value)) builder%sanitize = sanitize_attributes_value
   cdata_dec%is_cdata = .true.
   if (is_file) then
      open(newunit=unit, file=trim(adjustl(filename)), access='STREAM', form='UNFORMATTED', action='READ', status='OLD', &
           iostat=io_status, iomsg=io_message)
      if (io_status/=0) then
         if (present(iostat)) iostat = io_status
         if (present(iomsg)) iomsg = trim(io_message)
         return
      endif
      inquire(unit=unit, size=source_size)
   else
      source_size = len(string, kind=I8P)
   endif
   read_size = 0
   offset = 0
   lines = 0
   rest = ''
   do
      piece = max(0_I8P, min(chunk, source_size - read_size))
      allocate(character(len=len(rest, kind=I8P)+piece) :: window)
      window(1:len(rest, kind=I8P)) = rest
      if (piece>0) then
         if (is_file) then
            read(unit=unit, pos=read_size+1, iostat=io_status, iomsg=io_message) window(len(rest, kind=I8P)+1:)
            if (io_status/=0) then
               close(unit)
               if (present(iostat)) iostat = io_status
               if (present(iomsg)) iomsg = trim(io_message)
               return
            endif
         else
            window(len(rest, kind=I8P)+1:) = string(read_size+1:read_size+piece)
         endif
         read_size = read_size + piece
      endif
      is_last = read_size>=source_size
      call tokenizer%feed(chars=window, offset=offset, is_last=is_last, builder=builder, consumed=consumed)
      if (is_last.and.(.not.self%is_stopped)) call builder%finish
      call dispatch(self=self, builder=builder, text_dec=text_dec, cdata_dec=cdata_dec, window=window, offset=offset, &
                    lines=lines, first_problem=first_problem, is_last=is_last, is_file=is_file, chunk=chunk, &
                    unit=unit, string=string)
      lines = lines + count_new_lines(window(1:consumed))
      offset = offset + consumed
      rest = window(consumed+1:)
      deallocate(window)
      if (is_last.or.self%is_stopped) exit
   enddo
   if (is_file) close(unit)
   if (allocated(first_problem)) then
      if (present(iostat)) iostat = XML_MALFORMED
      if (present(iomsg)) iomsg = first_problem
   endif
   endsubroutine parse

   ! private procedures
   subroutine dispatch(self, builder, text_dec, cdata_dec, window, offset, lines, first_problem, is_last, is_file, chunk, &
                       unit, string)
   !< Call the handler for the events queued, then empty the queue.
   !<
   !< @note A module procedure with explicit arguments, not an internal procedure of *parse*: nvfortran 26.9 gives stale
   !< values of host-associated variables there.
   class(xml_handler),            intent(inout) :: self          !< Handler.
   type(event_builder),           intent(inout) :: builder       !< Event builder.
   type(text_decoder),            intent(inout) :: text_dec      !< Decoder of character data.
   type(text_decoder),            intent(inout) :: cdata_dec     !< Decoder of CDATA.
   character(*),                  intent(in)    :: window        !< Window fed.
   integer(I8P),                  intent(in)    :: offset        !< Position of the character before the window.
   integer(I8P),                  intent(in)    :: lines         !< New lines before the window.
   character(len=:), allocatable, intent(inout) :: first_problem !< First problem, located.
   logical,                       intent(in)    :: is_last       !< The source ended.
   logical,                       intent(in)    :: is_file       !< The source is a file.
   integer(I8P),                  intent(in)    :: chunk         !< Size of the chunks.
   integer(I4P),                  intent(in)    :: unit          !< Unit of the source file (if a file).
   character(*), optional,        intent(in)    :: string        !< Source string.
   character(len=:), allocatable                :: message       !< Problem, located.
   character(len=:), allocatable                :: target        !< PI target.
   integer(I8P)                                 :: line          !< Line of a problem.
   integer(I8P)                                 :: b             !< Position of a blank.
   integer(I4P)                                 :: e             !< Counter.
   do e=1, builder%ne
      if (self%is_stopped) exit
      associate(event=>builder%events(e))
         if (event%kind/=EVENT_TEXT) call flush_text(self=self, decoder=text_dec, is_final=.true.)
         if (event%kind/=EVENT_CDATA) call flush_text(self=self, decoder=cdata_dec, is_final=.true.)
         if (self%is_stopped) exit
         self%level = event%level
         self%pos = event%pos
         select case(event%kind)
         case(EVENT_START)
            call self%start_element(name=event%name, attributes=event%attributes)
         case(EVENT_END)
            call self%end_element(name=event%name)
         case(EVENT_TEXT)
            call add_text(decoder=text_dec, raw=event%text, pos=event%pos)
            call flush_text(self=self, decoder=text_dec, is_final=.false.)
         case(EVENT_CDATA)
            call add_text(decoder=cdata_dec, raw=event%text, pos=event%pos)
            call flush_text(self=self, decoder=cdata_dec, is_final=.false.)
         case(EVENT_COMMENT)
            call self%comment(text=line_ends_normalized(event%text))
         case(EVENT_PI)
            b = scan(event%text, ' '//achar(9)//achar(10)//achar(13), kind=I8P)
            if (b==0) then
               target = event%text
               call self%processing_instruction(target=target, data='')
            else
               target = event%text(1:b-1)
               call self%processing_instruction(target=target, data=line_ends_normalized(adjustl_blanks(event%text(b:))))
            endif
         case(EVENT_DOCTYPE)
            call self%doctype(text=event%text)
         case(EVENT_PROBLEM)
            line = 0
            if (event%pos>offset) line = lines + &
               count_new_lines(window(1:min(len(window, kind=I8P), event%pos-offset-1))) + 1
            if (line>0) then
               message = 'line '//trim(str(line, no_sign=.true.))//': '//event%name
            elseif (is_file) then ! counted on the open unit (a second open of the file may be refused)
               message = 'line '//trim(str(lines_to(unit=unit, pos=event%pos, chunk=chunk), no_sign=.true.))//': '// &
                         event%name
            else
               message = located(source=string, pos=event%pos, message=event%name)
            endif
            if (.not.allocated(first_problem)) first_problem = message
            call self%problem(message=message)
         endselect
      endassociate
   enddo
   if (is_last.and.(.not.self%is_stopped)) then
      call flush_text(self=self, decoder=text_dec, is_final=.true.)
      call flush_text(self=self, decoder=cdata_dec, is_final=.true.)
   endif
   builder%ne = 0
   if (self%is_stopped) builder%is_stopped = .true.
   endsubroutine dispatch

   pure function adjustl_blanks(text) result(adjusted)
   !< Return a text without its leading XML blanks.
   character(*), intent(in)      :: text     !< Text.
   character(len=:), allocatable :: adjusted !< Text without leading blanks.
   integer(I8P)                  :: first    !< First non blank character.

   first = verify(text, ' '//achar(9)//achar(10)//achar(13), kind=I8P)
   if (first==0) then
      adjusted = ''
   else
      adjusted = text(first:)
   endif
   endfunction adjustl_blanks

   function lines_to(unit, pos, chunk) result(line)
   !< Return the line of a position of an open stream file, counting its new lines (positioned reads, in chunks).
   integer(I4P), intent(in)      :: unit  !< File unit.
   integer(I8P), intent(in)      :: pos   !< Position.
   integer(I8P), intent(in)      :: chunk !< Size of the chunks read.
   integer(I8P)                  :: line  !< Line.
   character(len=:), allocatable :: block !< Block read.
   integer(I8P)                  :: first !< First position of a block.
   integer(I8P)                  :: size_ !< Size of a block.
   integer                       :: ios   !< I/O status.

   line = 1
   first = 1
   do while (first<pos)
      size_ = min(chunk, pos - first)
      if (allocated(block)) deallocate(block)
      allocate(character(len=size_) :: block)
      read(unit, pos=first, iostat=ios) block
      if (ios/=0) exit
      line = line + count_new_lines(block)
      first = first + size_
   enddo
   endfunction lines_to

   pure function count_new_lines(text) result(n)
   !< Return the number of new lines of a text.
   character(*), intent(in) :: text !< Text.
   integer(I8P)             :: n    !< Number of new lines.
   integer(I8P)             :: c    !< Counter.

   n = 0
   do c=1, len(text, kind=I8P)
      if (text(c:c)==new_line('a')) n = n + 1
   enddo
   endfunction count_new_lines

   pure subroutine add_text(decoder, raw, pos)
   !< Add a raw piece of text to a decoder.
   type(text_decoder), intent(inout) :: decoder !< Decoder.
   character(*),       intent(in)    :: raw     !< Raw piece.
   integer(I8P),       intent(in)    :: pos     !< Its position.

   if (.not.allocated(decoder%carry)) decoder%carry = ''
   if (len(decoder%carry)==0) decoder%pos = pos
   decoder%carry = decoder%carry//raw
   endsubroutine add_text

   subroutine flush_text(self, decoder, is_final)
   !< Pass to the handler the decoded text of a decoder: all of it if *is_final*, otherwise all but a final part that may
   !< continue in the next piece (a reference without `;`, a CR, an incomplete UTF-8 character).
   class(xml_handler), intent(inout) :: self     !< Handler.
   type(text_decoder), intent(inout) :: decoder  !< Decoder.
   logical,            intent(in)    :: is_final !< The text is complete.
   character(len=:), allocatable     :: raw      !< Raw text to decode now.
   integer(I8P)                      :: keep     !< Characters kept for the next piece.
   integer(I8P)                      :: amp      !< Position of the last `&`.
   integer(I8P)                      :: n        !< Length of the carry.

   if (.not.allocated(decoder%carry)) return
   n = len(decoder%carry, kind=I8P)
   if (n==0) return
   keep = 0
   if (.not.is_final) then
      keep = utf8_tail_len(decoder%carry)
      if (decoder%carry(n:n)==achar(13)) keep = max(keep, 1_I8P)
      if (.not.decoder%is_cdata) then
         amp = index(decoder%carry, '&', back=.true., kind=I8P)
         if (amp>0) then
            if (index(decoder%carry(amp:), ';', kind=I8P)==0.and.n-amp<MAX_REFERENCE) keep = max(keep, n-amp+1)
         endif
      endif
   endif
   if (keep>=n) return
   raw = decoder%carry(1:n-keep)
   self%pos = decoder%pos
   decoder%carry = decoder%carry(n-keep+1:)
   decoder%pos = decoder%pos + n - keep
   if (decoder%is_cdata) then
      call self%cdata(text=line_ends_normalized(raw))
   else
      call self%characters(text=character_data(raw))
   endif
   endsubroutine flush_text

   pure subroutine push_event(self, kind, level, pos, name, text)
   !< Queue an event.
   class(event_builder),   intent(inout) :: self  !< Event builder.
   integer(I4P),           intent(in)    :: kind  !< Event kind.
   integer(I4P),           intent(in)    :: level !< Element depth.
   integer(I8P),           intent(in)    :: pos   !< Position.
   character(*), optional, intent(in)    :: name  !< Element name, or message.
   character(*), optional, intent(in)    :: text  !< Raw text.
   type(event_record), allocatable       :: grown(:) !< Grown queue.

   if (.not.allocated(self%events)) allocate(self%events(64))
   if (self%ne==size(self%events, dim=1)) then
      allocate(grown(2*self%ne))
      grown(1:self%ne) = self%events(1:self%ne)
      call move_alloc(from=grown, to=self%events)
   endif
   self%ne = self%ne + 1
   associate(event=>self%events(self%ne))
      event%kind = kind
      event%level = level
      event%pos = pos
      if (present(name)) then
         event%name = name
      else
         event%name = ''
      endif
      if (present(text)) then
         event%text = text
      else
         event%text = ''
      endif
      if (allocated(event%attributes)) deallocate(event%attributes)
   endassociate
   endsubroutine push_event

   pure subroutine pop_element(self, pos)
   !< Close the innermost open element: queue its end event.
   class(event_builder), intent(inout) :: self !< Event builder.
   integer(I8P),         intent(in)    :: pos  !< Position of the end.

   call push_event(self=self, kind=EVENT_END, level=self%depth, pos=pos, name=self%stack_name(self%depth)%name)
   self%depth = self%depth - 1
   endsubroutine pop_element

   pure subroutine queue_start(self)
   !< Queue the start event of the start tag read (with its attributes).
   class(event_builder), intent(inout) :: self !< Event builder.

   call push_event(self=self, kind=EVENT_START, level=self%open_level, pos=self%open_pos, name=self%open_name)
   allocate(self%events(self%ne)%attributes(self%na))
   if (self%na>0) self%events(self%ne)%attributes(1:self%na) = self%open_attributes(1:self%na)
   endsubroutine queue_start

   pure subroutine events_start_tag(self, id, parent_id, level, name, start)
   !< A start tag begins: its attributes follow.
   class(event_builder), intent(inout) :: self      !< Event builder.
   integer(I4P),         intent(in)    :: id        !< Tag ID.
   integer(I4P),         intent(in)    :: parent_id !< Parent tag ID.
   integer(I4P),         intent(in)    :: level     !< Tag level.
   character(*),         intent(in)    :: name      !< Tag name.
   integer(I8P),         intent(in)    :: start     !< Position of `<`.

   self%open_name = name
   self%open_pos = start
   self%open_level = level
   self%na = 0
   endsubroutine events_start_tag

   pure subroutine events_attribute(self, id, name, value)
   !< An attribute of the current start tag: normalized and decoded.
   class(event_builder), intent(inout) :: self     !< Event builder.
   integer(I4P),         intent(in)    :: id       !< Tag ID.
   character(*),         intent(in)    :: name     !< Attribute name.
   character(*),         intent(in)    :: value    !< Attribute value, as in the source.
   type(xml_attribute), allocatable    :: grown(:) !< Grown list.

   if (.not.allocated(self%open_attributes)) allocate(self%open_attributes(8))
   if (self%na==size(self%open_attributes, dim=1)) then
      allocate(grown(2*self%na))
      grown(1:self%na) = self%open_attributes(1:self%na)
      call move_alloc(from=grown, to=self%open_attributes)
   endif
   self%na = self%na + 1
   self%open_attributes(self%na)%name = name
   if (self%sanitize) then
      self%open_attributes(self%na)%value = attribute_value(trim(adjustl(value)))
   else
      self%open_attributes(self%na)%value = attribute_value(value)
   endif
   endsubroutine events_attribute

   pure subroutine events_start_tag_end(self, id, start, open_end, is_self_closing)
   !< The current start tag is complete: queue its start (and, if self closing, its end).
   class(event_builder), intent(inout) :: self            !< Event builder.
   integer(I4P),         intent(in)    :: id              !< Tag ID.
   integer(I8P),         intent(in)    :: start           !< Position of `<`.
   integer(I8P),         intent(in)    :: open_end        !< Position of `>`.
   logical,              intent(in)    :: is_self_closing !< The tag is self closing.
   integer(I4P),         allocatable   :: grown_id(:)     !< Grown stack.
   type(xml_attribute),  allocatable   :: grown_name(:)   !< Grown stack.

   call queue_start(self)
   if (.not.allocated(self%stack_id)) then
      allocate(self%stack_id(64))
      allocate(self%stack_name(64))
   endif
   if (self%depth==size(self%stack_id, dim=1)) then
      allocate(grown_id(2*self%depth), grown_name(2*self%depth))
      grown_id(1:self%depth) = self%stack_id(1:self%depth)
      grown_name(1:self%depth) = self%stack_name(1:self%depth)
      call move_alloc(from=grown_id, to=self%stack_id)
      call move_alloc(from=grown_name, to=self%stack_name)
   endif
   self%depth = self%depth + 1
   self%stack_id(self%depth) = id
   self%stack_name(self%depth)%name = self%open_name
   deallocate(self%open_name)
   if (is_self_closing) call pop_element(self=self, pos=start)
   endsubroutine events_start_tag_end

   pure subroutine events_end_tag(self, id, start, open_end, end_start, end_end)
   !< An open tag is closed by its end tag: queue the end of the inner open elements (closed implicitly), then its own.
   class(event_builder), intent(inout) :: self      !< Event builder.
   integer(I4P),         intent(in)    :: id        !< Tag ID.
   integer(I8P),         intent(in)    :: start     !< Position of the start tag `<`.
   integer(I8P),         intent(in)    :: open_end  !< Position of the start tag `>`.
   integer(I8P),         intent(in)    :: end_start !< Position of the end tag `<`.
   integer(I8P),         intent(in)    :: end_end   !< Position of the end tag `>`.

   do while (self%depth>0)
      if (self%stack_id(self%depth)==id) then
         call pop_element(self=self, pos=end_start)
         exit
      endif
      call pop_element(self=self, pos=end_start)
   enddo
   endsubroutine events_end_tag

   pure subroutine events_data(self, kind, chars, first)
   !< Character data or other markup: text and CDATA queued as they come (CDATA without its markup), comments and PIs
   !< collected whole, declarations queued.
   class(event_builder), intent(inout) :: self  !< Event builder.
   integer(I4P),         intent(in)    :: kind  !< Data kind, DATA_*.
   character(*),         intent(in)    :: chars !< Characters, as in the source.
   integer(I8P),         intent(in)    :: first !< Position of the first character.
   integer(I8P)                        :: f     !< First character of the content.
   integer(I8P)                        :: l     !< Last character of the content.

   select case(kind)
   case(DATA_TEXT)
      call push_event(self=self, kind=EVENT_TEXT, level=self%depth, pos=first, text=chars)
   case(DATA_CDATA)
      f = 1
      l = len(chars, kind=I8P)
      if (.not.self%in_cdata) then
         f = 10 ! after <![CDATA[
         self%in_cdata = .true.
      endif
      if (l>=f+2) then
         if (chars(l-2:l)==']]>') then
            l = l - 3
            self%in_cdata = .false.
         endif
      endif
      if (l>=f) call push_event(self=self, kind=EVENT_CDATA, level=self%depth, pos=first+f-1, text=chars(f:l))
   case(DATA_COMMENT, DATA_PI)
      if (self%markup_kind==0) then
         self%markup_kind = kind
         self%markup = chars
         self%markup_pos = first
      else
         self%markup = self%markup//chars
      endif
      call close_markup(self=self, is_final=.false.)
   case(DATA_DECLARATION)
      call push_event(self=self, kind=EVENT_DOCTYPE, level=self%depth, pos=first, text=chars)
   endselect
   endsubroutine events_data

   pure subroutine close_markup(self, is_final)
   !< Queue the comment or PI collected, if it is complete (or, with *is_final*, as it is: unterminated).
   class(event_builder), intent(inout) :: self     !< Event builder.
   logical,              intent(in)    :: is_final !< The source ended.
   integer(I8P)                        :: n        !< Markup length.

   if (self%markup_kind==0) return
   n = len(self%markup, kind=I8P)
   if (self%markup_kind==DATA_COMMENT) then
      if (n>=7.and.self%markup(max(1_I8P, n-2):n)=='-->') then
         call push_event(self=self, kind=EVENT_COMMENT, level=self%depth, pos=self%markup_pos, text=self%markup(5:n-3))
      elseif (is_final) then
         call push_event(self=self, kind=EVENT_COMMENT, level=self%depth, pos=self%markup_pos, text=self%markup(5:))
      else
         return
      endif
   else
      if (n>=4.and.self%markup(max(1_I8P, n-1):n)=='?>') then
         call push_event(self=self, kind=EVENT_PI, level=self%depth, pos=self%markup_pos, text=self%markup(3:n-2))
      elseif (is_final) then
         call push_event(self=self, kind=EVENT_PI, level=self%depth, pos=self%markup_pos, text=self%markup(3:))
      else
         return
      endif
   endif
   self%markup_kind = 0
   deallocate(self%markup)
   endsubroutine close_markup

   pure subroutine events_problem(self, pos, message)
   !< A problem of malformed input: queued (every one, in order).
   class(event_builder), intent(inout) :: self    !< Event builder.
   integer(I8P),         intent(in)    :: pos     !< Position of the problem.
   character(*),         intent(in)    :: message !< Problem description.

   call close_markup(self=self, is_final=.true.) ! an unterminated comment/PI is reported before its problem
   call push_event(self=self, kind=EVENT_PROBLEM, level=self%depth, pos=pos, name=message)
   endsubroutine events_problem

   pure subroutine events_finish(self)
   !< The source is ended: a start tag not completed, a comment/PI not terminated and the open elements are closed.
   class(event_builder), intent(inout) :: self !< Event builder.

   if (allocated(self%open_name)) then ! an unterminated start tag: reported, as the DOM builds it
      call queue_start(self)
      call push_event(self=self, kind=EVENT_END, level=self%open_level, pos=self%open_pos, name=self%open_name)
      deallocate(self%open_name)
   endif
   call close_markup(self=self, is_final=.true.)
   do while (self%depth>0)
      call pop_element(self=self, pos=self%open_pos)
   enddo
   endsubroutine events_finish
endmodule foxy_xml_events
