!< FoXy XML tokenizer: a single pass, quotes-aware and resumable tokenizer driving a builder.
module foxy_xml_tokenizer
!< FoXy XML tokenizer: a single pass, quotes-aware and resumable tokenizer driving a builder.
!<
!< The tokenizer recognizes the markup in source order: start, self closing and end tags (any blank separates names and
!< attributes, attribute values single or double quoted), CDATA sections, comments, processing instructions and
!< declarations (e.g. DOCTYPE). It keeps the stack of the open tags (an end tag closes up to its matching start tag, inner
!< open tags are closed implicitly, a stray end tag is ignored) and reports each token to a *builder*, which builds what
!< it needs (e.g. the DOM of *xml_file*).
!<
!< The source is fed in pieces (*feed*): each call processes the complete tokens of the piece and returns how many
!< characters it consumed; the caller passes the rest again, followed by more characters. Character data, comments, CDATA
!< sections and processing instructions are reported in pieces (a long one never has to fit in memory), tags and
!< declarations whole. All positions are absolute (1 is the first character of the source).
use penf

implicit none
private
public :: located
public :: located_in_file
public :: xml_builder
public :: xml_tokenizer
public :: DATA_TEXT, DATA_CDATA, DATA_COMMENT, DATA_PI, DATA_DECLARATION, DATA_IGNORED

integer(I4P), parameter :: DATA_TEXT        = 1_I4P !< Character data.
integer(I4P), parameter :: DATA_CDATA       = 2_I4P !< CDATA section (markup included).
integer(I4P), parameter :: DATA_COMMENT     = 3_I4P !< Comment (markup included).
integer(I4P), parameter :: DATA_PI          = 4_I4P !< Processing instruction (markup included).
integer(I4P), parameter :: DATA_DECLARATION = 5_I4P !< Declaration, e.g. DOCTYPE (markup included).
integer(I4P), parameter :: DATA_IGNORED     = 6_I4P !< Ignored markup, e.g. a stray end tag.

integer(I4P), parameter :: INITIAL_DEPTH = 64_I4P !< Initial capacity of the open tags stack, doubled when full.
integer(I8P), parameter :: LOOKAHEAD     = 9_I8P  !< Characters needed to classify a markup (`<![CDATA[`).
character(*), parameter :: BLANKS   = ' '//achar(9)//achar(10)//achar(13) !< XML blanks: space, tab, new line, CR.
character(*), parameter :: NAME_END = BLANKS//'/>=' !< Characters ending a tag or attribute name.

type, abstract :: xml_builder
   !< Builder driven by the tokenizer: one call per token (character data and similar in pieces).
   logical :: is_stopped=.false. !< Set by the builder to stop the tokenizer (checked after each complete start or end tag).
   contains
      procedure(start_tag_interface),     pass(self), deferred :: start_tag     !< A start tag begins.
      procedure(attribute_interface),     pass(self), deferred :: attribute     !< An attribute of the current start tag.
      procedure(start_tag_end_interface), pass(self), deferred :: start_tag_end !< The current start tag is complete.
      procedure(end_tag_interface),       pass(self), deferred :: end_tag       !< An open tag is closed by its end tag.
      procedure(data_interface),          pass(self), deferred :: data          !< Character data or other markup.
      procedure(problem_interface),       pass(self), deferred :: problem       !< A problem of malformed input.
endtype xml_builder

abstract interface
   pure subroutine start_tag_interface(self, id, parent_id, level, name, start)
   !< A start tag begins: its attributes follow, then *start_tag_end* if it is complete.
   import :: xml_builder, I4P, I8P
   class(xml_builder), intent(inout) :: self      !< Builder.
   integer(I4P),       intent(in)    :: id        !< Tag ID (start tags count).
   integer(I4P),       intent(in)    :: parent_id !< Parent tag ID, 0 for a root tag.
   integer(I4P),       intent(in)    :: level     !< Tag level, 1 for a root tag.
   character(*),       intent(in)    :: name      !< Tag name.
   integer(I8P),       intent(in)    :: start     !< Position of `<`.
   endsubroutine start_tag_interface

   pure subroutine attribute_interface(self, id, name, value)
   !< An attribute of the current start tag; the value is as in the source, with `"` escaped (values are double quoted).
   import :: xml_builder, I4P
   class(xml_builder), intent(inout) :: self  !< Builder.
   integer(I4P),       intent(in)    :: id    !< Tag ID.
   character(*),       intent(in)    :: name  !< Attribute name.
   character(*),       intent(in)    :: value !< Attribute value.
   endsubroutine attribute_interface

   pure subroutine start_tag_end_interface(self, id, start, open_end, is_self_closing)
   !< The current start tag is complete.
   import :: xml_builder, I4P, I8P
   class(xml_builder), intent(inout) :: self            !< Builder.
   integer(I4P),       intent(in)    :: id              !< Tag ID.
   integer(I8P),       intent(in)    :: start           !< Position of `<`.
   integer(I8P),       intent(in)    :: open_end        !< Position of `>`.
   logical,            intent(in)    :: is_self_closing !< The tag is self closing.
   endsubroutine start_tag_end_interface

   pure subroutine end_tag_interface(self, id, start, open_end, end_start, end_end)
   !< An open tag is closed by its end tag (its inner open tags, if any, are closed implicitly).
   import :: xml_builder, I4P, I8P
   class(xml_builder), intent(inout) :: self      !< Builder.
   integer(I4P),       intent(in)    :: id        !< Tag ID.
   integer(I8P),       intent(in)    :: start     !< Position of the start tag `<`.
   integer(I8P),       intent(in)    :: open_end  !< Position of the start tag `>`.
   integer(I8P),       intent(in)    :: end_start !< Position of the end tag `<`.
   integer(I8P),       intent(in)    :: end_end   !< Position of the end tag `>`.
   endsubroutine end_tag_interface

   pure subroutine data_interface(self, kind, chars, first)
   !< Character data or other markup (see the DATA_* kinds), possibly a piece of it.
   import :: xml_builder, I4P, I8P
   class(xml_builder), intent(inout) :: self  !< Builder.
   integer(I4P),       intent(in)    :: kind  !< Data kind, DATA_*.
   character(*),       intent(in)    :: chars !< Characters, as in the source.
   integer(I8P),       intent(in)    :: first !< Position of the first character.
   endsubroutine data_interface

   pure subroutine problem_interface(self, pos, message)
   !< A problem of malformed input.
   import :: xml_builder, I8P
   class(xml_builder), intent(inout) :: self    !< Builder.
   integer(I8P),       intent(in)    :: pos     !< Position of the problem.
   character(*),       intent(in)    :: message !< Problem description.
   endsubroutine problem_interface
endinterface

type :: open_tag
   !< An open tag of the stack.
   integer(I4P)                  :: id=0_I4P       !< Tag ID.
   integer(I8P)                  :: start=0_I8P    !< Position of `<`.
   integer(I8P)                  :: open_end=0_I8P !< Position of `>`.
   character(len=:), allocatable :: name           !< Tag name.
endtype open_tag

type :: attribute_pair
   !< An attribute of the current start tag.
   character(len=:), allocatable :: name  !< Attribute name.
   character(len=:), allocatable :: value !< Attribute value.
endtype attribute_pair

type :: xml_tokenizer
   !< Resumable tokenizer.
   private
   type(open_tag), allocatable :: stack(:)         !< Open tags.
   integer(I4P)                :: depth=0_I4P      !< Number of open tags.
   integer(I4P)                :: nt=0_I4P         !< Number of start tags.
   integer(I4P)                :: open_kind=0_I4P  !< Kind of the comment/CDATA/PI continuing in the next piece, 0 if none.
   integer(I8P)                :: open_start=0_I8P !< Position of the comment/CDATA/PI continuing in the next piece.
   logical                     :: is_done=.false.  !< The source is ended (or parsing is stopped).
   contains
      procedure, pass(self) :: feed  !< Feed a piece of the source.
      procedure, pass(self) :: reset !< Reset the tokenizer, ready for a new source.
endtype xml_tokenizer

contains
   pure subroutine feed(self, chars, offset, is_last, builder, consumed)
   !< Feed a piece of the source: tokenize its complete tokens, reporting them to the builder.
   !<
   !< @note The characters not consumed (an incomplete token at the end of the piece) must be passed again, followed by
   !< more characters; with *is_last* true the source ends with this piece and everything is consumed. Parsing stops at an
   !< unterminated markup of the source.
   class(xml_tokenizer), intent(inout) :: self            !< Tokenizer.
   character(*),         intent(in)    :: chars           !< Piece of the source.
   integer(I8P),         intent(in)    :: offset          !< Position of the character before the piece (0 if first).
   logical,              intent(in)    :: is_last         !< The source ends with this piece.
   class(xml_builder),   intent(inout) :: builder         !< Builder.
   integer(I8P),         intent(out)   :: consumed        !< Number of characters consumed.
   type(open_tag)                      :: tag             !< Current start tag.
   type(attribute_pair), allocatable   :: attributes(:)   !< Attributes of the current start tag.
   character(len=:),     allocatable   :: name            !< Tag or attribute name.
   character(len=:),     allocatable   :: problem         !< First problem of the current start tag.
   integer(I8P)                        :: problem_pos     !< Position of the first problem of the current start tag.
   integer(I4P)                        :: na              !< Number of attributes of the current start tag.
   integer(I8P)                        :: n               !< Piece length.
   integer(I8P)                        :: pos             !< Current position, in the piece.
   integer(I8P)                        :: k               !< Scan position, in the piece.
   integer(I8P)                        :: e               !< Relative position of a delimiter.
   integer(I4P)                        :: l               !< Stack level.
   integer(I4P)                        :: a               !< Counter.
   logical                             :: is_self_closing !< Self closing tag flag.
   logical                             :: is_terminated   !< Terminated start tag flag.
   logical                             :: is_closed       !< The comment, CDATA section or PI is closed.

   n = len(chars, kind=I8P)
   if (self%is_done) then
      consumed = n
      return
   endif
   if (.not.allocated(self%stack)) allocate(self%stack(INITIAL_DEPTH))
   pos = 1
   do while (pos<=n)
      if (self%open_kind>0) then
         ! a comment, CDATA section or PI continuing from the previous piece
         call report_markup(self=self, chars=chars, offset=offset, from=pos, search_from=pos, is_last=is_last, &
                            builder=builder, pos=pos, is_closed=is_closed)
         if (.not.is_closed) exit
      elseif (chars(pos:pos)/='<') then
         ! character data
         e = index(chars(pos:), '<', kind=I8P)
         if (e==0) then
            k = n
         else
            k = pos + e - 2
         endif
         call builder%data(kind=DATA_TEXT, chars=chars(pos:k), first=offset+pos)
         pos = k + 1
      elseif ((.not.is_last).and.n-pos+1<LOOKAHEAD) then
         exit ! more characters needed to classify the markup
      elseif (chars(pos:min(n, pos+3))=='<!--') then
         self%open_kind = DATA_COMMENT
         self%open_start = offset + pos
         call report_markup(self=self, chars=chars, offset=offset, from=pos, search_from=pos+4, is_last=is_last, &
                            builder=builder, pos=pos, is_closed=is_closed)
         if (.not.is_closed) exit
      elseif (chars(pos:min(n, pos+8))=='<![CDATA[') then
         self%open_kind = DATA_CDATA
         self%open_start = offset + pos
         call report_markup(self=self, chars=chars, offset=offset, from=pos, search_from=pos+9, is_last=is_last, &
                            builder=builder, pos=pos, is_closed=is_closed)
         if (.not.is_closed) exit
      elseif (chars(pos:min(n, pos+1))=='<?') then
         self%open_kind = DATA_PI
         self%open_start = offset + pos
         call report_markup(self=self, chars=chars, offset=offset, from=pos, search_from=pos+2, is_last=is_last, &
                            builder=builder, pos=pos, is_closed=is_closed)
         if (.not.is_closed) exit
      elseif (chars(pos:min(n, pos+1))=='<!') then
         k = after_declaration(source=chars, start=pos)
         if (k==0) then
            if (.not.is_last) exit
            call builder%problem(pos=offset+pos, message='unterminated declaration')
            self%is_done = .true.
            exit
         endif
         call builder%data(kind=DATA_DECLARATION, chars=chars(pos:k-1), first=offset+pos)
         pos = k
      elseif (chars(pos:min(n, pos+1))=='</') then
         k = pos + 2
         call read_name(source=chars, pos=k, name=name)
         e = 0 ; if (k<=n) e = index(chars(k:), '>', kind=I8P)
         if (e==0) then
            if (.not.is_last) exit
            call builder%problem(pos=offset+pos, message='unterminated end tag </'//name//'>')
            self%is_done = .true.
            exit
         endif
         ! close up to the matching open tag, if any
         do l=self%depth, 1, -1
            if (self%stack(l)%name==name) exit
         enddo
         if (l==0) then
            call builder%problem(pos=offset+pos, message='end tag </'//name//'> without matching start tag')
            call builder%data(kind=DATA_IGNORED, chars=chars(pos:k+e-1), first=offset+pos)
         else
            if (l<self%depth) call builder%problem(pos=offset+pos, message='end tag </'//name//'> closes open tag <'// &
                                                   self%stack(self%depth)%name//'>')
            call builder%end_tag(id=self%stack(l)%id, start=self%stack(l)%start, open_end=self%stack(l)%open_end, &
                                 end_start=offset+pos, end_end=offset+k+e-1)
            self%depth = l - 1
         endif
         pos = k + e
         if (builder%is_stopped) then ! the builder needs no more tokens
            self%is_done = .true.
            exit
         endif
      else
         ! start or self closing tag: parsed whole before being reported (it may continue in the next piece)
         k = pos + 1
         call read_name(source=chars, pos=k, name=name)
         if (len(name)==0) then ! not a tag, e.g. "a < b"
            call builder%problem(pos=offset+pos, message="character '<' not starting a tag")
            call builder%data(kind=DATA_TEXT, chars='<', first=offset+pos)
            pos = pos + 1
            cycle
         endif
         tag%name = name
         tag%start = offset + pos
         na = 0
         if (allocated(problem)) deallocate(problem)
         problem_pos = 0
         is_terminated = .false.
         is_self_closing = .false.
         do
            call skip_blanks(source=chars, pos=k)
            if (k>n) exit
            if (chars(k:k)=='>') then
               is_terminated = .true.
               k = k + 1
               exit
            elseif (chars(k:min(n, k+1))=='/>') then
               is_terminated = .true.
               is_self_closing = .true.
               k = k + 2
               exit
            elseif ((.not.is_last).and.k==n.and.chars(k:k)=='/') then
               exit ! maybe `/>` split by the piece end
            endif
            call read_name(source=chars, pos=k, name=name)
            if (len(name)==0) then ! stray character
               call first_problem(problem, problem_pos, offset+k, "invalid character '"//chars(k:k)//"' in tag <"// &
                                  tag%name//'>')
               k = k + 1
               cycle
            endif
            call skip_blanks(source=chars, pos=k)
            if (k>n) exit
            if (chars(k:k)/='=') then ! attribute without value, ignored
               call first_problem(problem, problem_pos, offset+k, 'attribute "'//name//'" without value in tag <'// &
                                  tag%name//'>')
               cycle
            endif
            k = k + 1
            call skip_blanks(source=chars, pos=k)
            if (k>n) exit
            if (chars(k:k)/='"'.and.chars(k:k)/="'") then ! unquoted value, ignored
               call first_problem(problem, problem_pos, offset+k, 'unquoted value of attribute "'//name//'" in tag <'// &
                                  tag%name//'>')
               cycle
            endif
            e = index(chars(k+1:), chars(k:k), kind=I8P)
            if (e==0) then
               if (is_last) call first_problem(problem, problem_pos, offset+k, 'unterminated value of attribute "'// &
                                               name//'" in tag <'//tag%name//'>')
               k = n + 1
               exit
            endif
            call add_attribute(attributes=attributes, na=na, name=name, value=chars(k+1:k+e-1), quote=chars(k:k))
            k = k + e + 1
         enddo
         if ((.not.is_terminated).and.(.not.is_last)) exit ! the tag continues in the next piece
         ! report the tag
         self%nt = self%nt + 1
         tag%id = self%nt
         l = 0 ; if (self%depth>0) l = self%stack(self%depth)%id
         call builder%start_tag(id=tag%id, parent_id=l, level=self%depth+1, name=tag%name, start=tag%start)
         do a=1, na
            call builder%attribute(id=tag%id, name=attributes(a)%name, value=attributes(a)%value)
         enddo
         if (allocated(problem)) call builder%problem(pos=problem_pos, message=problem)
         if (.not.is_terminated) then
            call builder%problem(pos=tag%start, message='unterminated start tag <'//tag%name//'>')
            self%is_done = .true.
            exit
         endif
         tag%open_end = offset + k - 1
         call builder%start_tag_end(id=tag%id, start=tag%start, open_end=tag%open_end, is_self_closing=is_self_closing)
         if (.not.is_self_closing) then
            if (self%depth==size(self%stack, dim=1)) self%stack = [self%stack, self%stack]
            self%depth = self%depth + 1
            self%stack(self%depth) = tag
         endif
         pos = k
         if (builder%is_stopped) then ! the builder needs no more tokens
            self%is_done = .true.
            exit
         endif
      endif
   enddo
   if (is_last.or.self%is_done) then
      consumed = n
      if (.not.self%is_done) then
         if (self%depth>0) call builder%problem(pos=self%stack(1)%start, message='unclosed tag <'//self%stack(1)%name//'>')
         self%is_done = .true.
      endif
   else
      consumed = pos - 1
   endif
   endsubroutine feed

   elemental subroutine reset(self)
   !< Reset the tokenizer, ready for a new source.
   class(xml_tokenizer), intent(inout) :: self !< Tokenizer.

   if (allocated(self%stack)) deallocate(self%stack)
   self%depth = 0_I4P
   self%nt = 0_I4P
   self%open_kind = 0_I4P
   self%open_start = 0_I8P
   self%is_done = .false.
   endsubroutine reset

   pure function located(source, pos, message) result(problem)
   !< Return a problem description prefixed by its line in the source.
   character(*), intent(in)      :: source  !< Source.
   integer(I8P), intent(in)      :: pos     !< Position of the problem.
   character(*), intent(in)      :: message !< Problem description.
   character(len=:), allocatable :: problem !< Located problem description.
   integer(I8P)                  :: line    !< Line of the problem.
   integer(I8P)                  :: c       !< Counter.

   line = 1
   do c=1, min(pos, len(source, kind=I8P)) - 1
      if (source(c:c)==new_line('a')) line = line + 1
   enddo
   problem = 'line '//trim(str(line, no_sign=.true.))//': '//message
   endfunction located

   function located_in_file(filename, pos, message, chunk_size) result(problem)
   !< Return a problem description prefixed by its line in a file (read again in chunks, counting the new lines).
   character(*), intent(in)      :: filename   !< File name.
   integer(I8P), intent(in)      :: pos        !< Position of the problem.
   character(*), intent(in)      :: message    !< Problem description.
   integer(I8P), intent(in)      :: chunk_size !< Size of the chunks read from the file.
   character(len=:), allocatable :: problem    !< Located problem description.
   character(len=:), allocatable :: chunk      !< Chunk read.
   integer(I8P)                  :: line       !< Line of the problem.
   integer(I8P)                  :: read_size  !< Characters read so far.
   integer(I8P)                  :: piece      !< Size of the chunk to read.
   integer(I8P)                  :: c          !< Counter.
   integer(I4P)                  :: unit       !< File unit.
   integer(I4P)                  :: iostat     !< IO status.

   line = 1
   open(newunit=unit, file=trim(adjustl(filename)), access='STREAM', form='UNFORMATTED', action='READ', status='OLD', &
        iostat=iostat)
   if (iostat==0) then
      read_size = 0
      do while (read_size<pos-1)
         piece = min(chunk_size, pos - 1 - read_size)
         if (allocated(chunk)) deallocate(chunk)
         allocate(character(len=piece) :: chunk)
         read(unit=unit, iostat=iostat) chunk
         if (iostat/=0) exit
         do c=1, piece
            if (chunk(c:c)==new_line('a')) line = line + 1
         enddo
         read_size = read_size + piece
      enddo
      close(unit)
   endif
   problem = 'line '//trim(str(line, no_sign=.true.))//': '//message
   endfunction located_in_file

   ! private procedures
   pure subroutine report_markup(self, chars, offset, from, search_from, is_last, builder, pos, is_closed)
   !< Report an open comment, CDATA section or PI up to its end, or up to the piece end if it continues in the next piece.
   !<
   !< @note When the end is not in the piece, the last characters that may start the terminator are not consumed (never
   !< those before *search_from*, i.e. the opening markup). An unterminated markup is reported up to the source end.
   class(xml_tokenizer), intent(inout) :: self        !< Tokenizer.
   character(*),         intent(in)    :: chars       !< Piece of the source.
   integer(I8P),         intent(in)    :: offset      !< Position of the character before the piece.
   integer(I8P),         intent(in)    :: from        !< First character to report.
   integer(I8P),         intent(in)    :: search_from !< First character where the terminator is searched.
   logical,              intent(in)    :: is_last     !< The source ends with this piece.
   class(xml_builder),   intent(inout) :: builder     !< Builder.
   integer(I8P),         intent(inout) :: pos         !< Position after the reported characters.
   logical,              intent(out)   :: is_closed   !< The markup is closed: tokenizing goes on in this piece.
   character(len=:), allocatable       :: terminator  !< Markup terminator.
   integer(I8P)                        :: n           !< Piece length.
   integer(I8P)                        :: e           !< Relative position of the terminator.
   integer(I8P)                        :: last        !< Last reported character.

   select case(self%open_kind)
   case(DATA_COMMENT)
      terminator = '-->'
   case(DATA_CDATA)
      terminator = ']]>'
   case default
      terminator = '?>'
   endselect
   n = len(chars, kind=I8P)
   is_closed = .false.
   e = 0
   if (search_from<=n) e = index(chars(search_from:), terminator, kind=I8P)
   if (e>0) then
      last = search_from + e - 2 + len(terminator, kind=I8P)
      call builder%data(kind=self%open_kind, chars=chars(from:last), first=offset+from)
      self%open_kind = 0
      pos = last + 1
      is_closed = .true.
   elseif (is_last) then
      ! unterminated: kept as it is up to the source end (as the pieces already reported, if any), parsing stops
      if (n>=from) call builder%data(kind=self%open_kind, chars=chars(from:n), first=offset+from)
      select case(self%open_kind)
      case(DATA_COMMENT)
         call builder%problem(pos=self%open_start, message='unterminated comment')
      case(DATA_CDATA)
         call builder%problem(pos=self%open_start, message='unterminated CDATA section')
      case default
         call builder%problem(pos=self%open_start, message='unterminated processing instruction')
      endselect
      self%is_done = .true.
   else
      ! report all but the last characters that may start the terminator, kept for the next piece
      last = max(search_from - 1, n - len(terminator, kind=I8P) + 1)
      if (last>=from) call builder%data(kind=self%open_kind, chars=chars(from:last), first=offset+from)
      pos = last + 1
   endif
   endsubroutine report_markup

   pure subroutine add_attribute(attributes, na, name, value, quote)
   !< Add an attribute to the list of the current start tag (values are double quoted: `"` escaped in single quoted ones).
   type(attribute_pair), allocatable, intent(inout) :: attributes(:) !< Attributes.
   integer(I4P),                      intent(inout) :: na            !< Number of attributes.
   character(*),                      intent(in)    :: name          !< Attribute name.
   character(*),                      intent(in)    :: value         !< Attribute value.
   character(len=1),                  intent(in)    :: quote         !< Attribute value quote.
   type(attribute_pair), allocatable                :: grown(:)      !< Grown list.

   if (.not.allocated(attributes)) allocate(attributes(8))
   if (na==size(attributes, dim=1)) then
      allocate(grown(2*na))
      grown(1:na) = attributes(1:na)
      call move_alloc(from=grown, to=attributes)
   endif
   na = na + 1
   attributes(na)%name = name
   if (quote=="'") then
      attributes(na)%value = escaped_double_quotes(value)
   else
      attributes(na)%value = value
   endif
   endsubroutine add_attribute

   pure function after_declaration(source, start) result(after)
   !< Return the position after a `<!...>` declaration (e.g. DOCTYPE) starting at *start*, 0 if it is unterminated.
   !<
   !< @note Quoted strings and the `[...]` internal subset may contain `>`.
   character(*), intent(in) :: source   !< Source.
   integer(I8P), intent(in) :: start    !< Declaration start (`<`) position.
   integer(I8P)             :: after    !< Position after the declaration.
   integer(I4P)             :: brackets !< Internal subset nesting.
   integer(I8P)             :: e        !< Relative position of closing quote.
   character(len=1)         :: c        !< Current character.

   after = start + 2
   brackets = 0
   do while (after<=len(source, kind=I8P))
      c = source(after:after)
      if (c=='"'.or.c=="'") then
         e = index(source(after+1:), c, kind=I8P)
         if (e==0) exit
         after = after + e
      elseif (c=='[') then
         brackets = brackets + 1
      elseif (c==']') then
         brackets = brackets - 1
      elseif (c=='>'.and.brackets<=0) then
         after = after + 1
         return
      endif
      after = after + 1
   enddo
   after = 0
   endfunction after_declaration

   pure function escaped_double_quotes(string) result(escaped)
   !< Return string with `"` replaced by `&quot;`.
   character(*), intent(in)      :: string  !< String.
   character(len=:), allocatable :: escaped !< Escaped string.
   integer(I8P)                  :: c       !< Counter.

   if (index(string, '"')==0) then
      escaped = string
      return
   endif
   escaped = ''
   do c=1, len(string, kind=I8P)
      if (string(c:c)=='"') then
         escaped = escaped//'&quot;'
      else
         escaped = escaped//string(c:c)
      endif
   enddo
   endfunction escaped_double_quotes

   pure subroutine first_problem(problem, problem_pos, pos, message)
   !< Keep a problem only if it is the first one.
   character(len=:), allocatable, intent(inout) :: problem     !< First problem, unallocated if none yet.
   integer(I8P),                  intent(inout) :: problem_pos !< Position of the first problem.
   integer(I8P),                  intent(in)    :: pos         !< Position of the problem.
   character(*),                  intent(in)    :: message     !< Problem description.

   if (allocated(problem)) return
   problem = message
   problem_pos = pos
   endsubroutine first_problem

   pure subroutine read_name(source, pos, name)
   !< Read a (tag or attribute) name starting at *pos*, ended by a blank, `/`, `>`, `=` or the source end; *pos* is moved
   !< after the name.
   character(*),                  intent(in)    :: source !< Source.
   integer(I8P),                  intent(inout) :: pos    !< Current position.
   character(len=:), allocatable, intent(out)   :: name   !< Name, empty if none.
   integer(I8P)                                 :: start  !< Name start.

   start = pos
   do while (pos<=len(source, kind=I8P))
      if (scan(source(pos:pos), NAME_END)>0) exit
      pos = pos + 1
   enddo
   name = source(start:pos-1)
   endsubroutine read_name

   pure subroutine skip_blanks(source, pos)
   !< Move *pos* after the blanks (space, tab, new line, carriage return) starting at it.
   character(*), intent(in)    :: source !< Source.
   integer(I8P), intent(inout) :: pos    !< Current position.

   do while (pos<=len(source, kind=I8P))
      if (scan(source(pos:pos), BLANKS)==0) exit
      pos = pos + 1
   enddo
   endsubroutine skip_blanks
endmodule foxy_xml_tokenizer
