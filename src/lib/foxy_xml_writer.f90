!< FoXy XML writer class: stream well-formed XML to a file, a unit or memory.
module foxy_xml_writer
!< FoXy XML writer class: stream well-formed XML to a file, a unit or memory.
!<
!< The document is written sequentially, element by element: *start* opens an element (its start tag stays pending, so
!< attributes can be added, until its first content), *end* closes it (written self closing if it has no content). The
!< writer keeps the stack of the open elements, escapes text and attribute values and writes each piece as soon as it is
!< complete: the memory used does not depend on the document size (a memory target grows its buffer geometrically).
!<
!< Layout: with *indent*>0 (default 2) every element holding elements has its start and end tags on their own lines,
!< indented by depth; an element holding text is written inline (`<a>text</a>`), as its children; a block payload
!< (`raw(..., is_block=.true.)`) is written on its own line. With *indent*=0 no blank is added.
!<
!< Errors are sticky: the first one (an I/O error, or a misuse reported as *XML_MALFORMED*) is kept, every following call
!< does nothing; each call can return it (*iostat*, *iomsg*), *close* always does.
use foxy_xml_entities, only : xml_escape
use foxy_xml_file, only : XML_MALFORMED
use penf

implicit none
private
public :: xml_writer

integer(I8P), parameter :: INITIAL_BUFFER_LEN = 4096_I8P !< Initial length of the memory buffer, doubled when full.
integer(I4P), parameter :: INITIAL_DEPTH      = 32_I4P   !< Initial capacity of the open elements stack, doubled when full.

type :: open_element
   !< An open element.
   character(len=:), allocatable :: name              !< Element name.
   logical                       :: is_inline=.false. !< It holds text: its content and end tag are written inline.
   logical                       :: in_inline=.false. !< It is inside an inline element: no layout around it.
endtype open_element

type :: xml_writer
   !< XML writer.
   private
   integer                         :: unit=0                !< Output unit (file or unit target).
   logical                         :: is_memory=.false.     !< The target is memory.
   logical                         :: is_open=.false.       !< The writer is open.
   logical                         :: is_unit_owned=.false. !< The unit is opened (and closed) by the writer.
   character(len=:), allocatable   :: buffer                !< Memory target buffer.
   integer(I8P)                    :: n=0_I8P               !< Used length of the memory buffer.
   integer(I4P)                    :: indent=2_I4P          !< Spaces per indentation level, 0 for no layout.
   type(open_element), allocatable :: stack(:)              !< Open elements.
   integer(I4P)                    :: depth=0_I4P           !< Number of open elements.
   character(len=:), allocatable   :: pending               !< Pending start tag (`<name attributes`), unallocated if none.
   logical                         :: is_empty=.true.       !< Nothing written yet.
   integer(I4P)                    :: error=0_I4P           !< First error status, 0 if none.
   character(len=:), allocatable   :: error_message         !< First error message.
   contains
      ! public methods
      generic               :: attribute =>         &
                               attribute_character, &
                               attribute_i1p,       &
                               attribute_i2p,       &
                               attribute_i4p,       &
                               attribute_i8p,       &
                               attribute_r4p,       &
                               attribute_r8p,       &
                               attribute_logical      !< Add an attribute to the pending start tag.
      procedure, pass(self) :: cdata                  !< Write a CDATA section.
      procedure, pass(self) :: close                  !< Close all the open elements and the writer.
      procedure, pass(self) :: comment                !< Write a comment.
      procedure, pass(self) :: declaration            !< Write the XML declaration.
      procedure, pass(self) :: end                    !< Close the innermost open element.
      procedure, pass(self) :: open                   !< Open the writer on a file, a unit or memory.
      procedure, pass(self) :: pi                     !< Write a processing instruction.
      procedure, pass(self) :: raw                    !< Write characters as they are.
      procedure, pass(self) :: start                  !< Open an element.
      procedure, pass(self) :: string                 !< Return the memory target content.
      procedure, pass(self) :: text                   !< Write escaped character data.
      ! private methods
      procedure, pass(self), private :: attribute_character !< Add a character attribute.
      procedure, pass(self), private :: attribute_i1p       !< Add an integer attribute.
      procedure, pass(self), private :: attribute_i2p       !< Add an integer attribute.
      procedure, pass(self), private :: attribute_i4p       !< Add an integer attribute.
      procedure, pass(self), private :: attribute_i8p       !< Add an integer attribute.
      procedure, pass(self), private :: attribute_r4p       !< Add a real attribute.
      procedure, pass(self), private :: attribute_r8p       !< Add a real attribute.
      procedure, pass(self), private :: attribute_logical   !< Add a logical attribute.
      procedure, pass(self), private :: fail                !< Record the first error.
      procedure, pass(self), private :: flush_pending       !< Complete the pending start tag.
      procedure, pass(self), private :: is_writable         !< Check that the writer is open and without errors.
      procedure, pass(self), private :: markup_line         !< Write a comment or PI.
      procedure, pass(self), private :: put                 !< Write characters to the target.
      procedure, pass(self), private :: report              !< Return the error status.
      procedure, pass(self), private :: start_content       !< Prepare the innermost element for inline content.
endtype xml_writer

contains
   ! public methods
   subroutine cdata(self, string, iostat, iomsg)
   !< Write a CDATA section (`]]>` in *string* is split across two sections).
   class(xml_writer),      intent(inout) :: self   !< XML writer.
   character(*),           intent(in)    :: string !< Characters.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.
   character(len=:), allocatable         :: rest   !< Characters still to write.
   integer(I8P)                          :: e      !< Position of `]]>`.

   if (self%start_content(what='a CDATA section')) then
      call self%put('<![CDATA[')
      rest = string
      do
         e = index(rest, ']]>', kind=I8P)
         if (e==0) exit
         call self%put(rest(1:e+1)//']]><![CDATA[')
         rest = rest(e+2:)
      enddo
      call self%put(rest//']]>')
   endif
   call self%report(iostat=iostat, iomsg=iomsg)
   endsubroutine cdata

   subroutine close(self, iostat, iomsg)
   !< Close all the open elements and the writer (a file opened by the writer is closed, a unit passed is left open; the
   !< memory target content stays available to *string*).
   class(xml_writer),      intent(inout) :: self    !< XML writer.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status: 0, the runtime I/O error code or *XML_MALFORMED*.
   character(*), optional, intent(inout) :: iomsg   !< IO message, unchanged if no error.
   integer(I4P)                          :: iostat_ !< IO status, local variable.

   do while (self%depth>0.and.self%error==0)
      call self%end()
   enddo
   if (self%is_unit_owned.and.self%is_open) then
      close(self%unit, iostat=iostat_)
      if (iostat_/=0) call self%fail(iostat_, 'cannot close the file')
   endif
   self%is_open = .false.
   self%is_unit_owned = .false.
   call self%report(iostat=iostat, iomsg=iomsg)
   endsubroutine close

   subroutine comment(self, string, iostat, iomsg)
   !< Write a comment (`<!--string-->`); *string* cannot contain `--` nor end with `-`.
   class(xml_writer),      intent(inout) :: self   !< XML writer.
   character(*),           intent(in)    :: string !< Comment.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.

   if (index(string, '--')>0.or.string(max(1, len(string)):)=='-') then
      call self%fail(XML_MALFORMED, 'comment "'//string//'" contains "--" or ends with "-"')
   else
      call self%markup_line('<!--'//string//'-->')
   endif
   call self%report(iostat=iostat, iomsg=iomsg)
   endsubroutine comment

   subroutine declaration(self, version, encoding, iostat, iomsg)
   !< Write the XML declaration, only as the first thing of the document.
   class(xml_writer),      intent(inout) :: self     !< XML writer.
   character(*), optional, intent(in)    :: version  !< XML version (default `1.0`).
   character(*), optional, intent(in)    :: encoding !< Encoding (not written if not passed).
   integer(I4P), optional, intent(out)   :: iostat   !< IO status.
   character(*), optional, intent(inout) :: iomsg    !< IO message.
   character(len=:), allocatable         :: decl     !< Declaration.

   if (self%is_writable()) then
      if (.not.self%is_empty) then
         call self%fail(XML_MALFORMED, 'the XML declaration must be the first thing of the document')
      else
         decl = '<?xml version="1.0"'
         if (present(version)) decl = '<?xml version="'//version//'"'
         if (present(encoding)) decl = decl//' encoding="'//encoding//'"'
         call self%put(decl//'?>'//new_line_(self))
         self%is_empty = .false.
      endif
   endif
   call self%report(iostat=iostat, iomsg=iomsg)
   endsubroutine declaration

   subroutine end(self, name, iostat, iomsg)
   !< Close the innermost open element (self closing if it has no content); *name*, if passed, must be its name.
   class(xml_writer),      intent(inout) :: self   !< XML writer.
   character(*), optional, intent(in)    :: name   !< Name of the element to close.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.
   logical                               :: is_matching !< The name matches the open element.

   if (self%is_writable()) then
      if (self%depth==0) then
         call self%fail(XML_MALFORMED, 'end of an element, but no element is open')
      else
         is_matching = .true.
         if (present(name)) is_matching = name==self%stack(self%depth)%name
         if (.not.is_matching) then
            call self%fail(XML_MALFORMED, 'end of element <'//name//'>, but the open element is <'// &
                           self%stack(self%depth)%name//'>')
         else
            associate(element=>self%stack(self%depth))
               if (allocated(self%pending)) then
                  call self%put(self%pending//'/>')
                  deallocate(self%pending)
                  if (.not.element%in_inline) call self%put(new_line_(self))
               elseif (element%is_inline.or.element%in_inline) then
                  call self%put('</'//element%name//'>')
                  if (.not.element%in_inline) call self%put(new_line_(self))
               else
                  call self%put(indentation(self, self%depth-1)//'</'//element%name//'>'//new_line_(self))
               endif
            endassociate
            self%depth = self%depth - 1
         endif
      endif
   endif
   call self%report(iostat=iostat, iomsg=iomsg)
   endsubroutine end

   subroutine open(self, filename, unit, indent, iostat, iomsg)
   !< Open the writer: on a file (created, replaced if it exists), on a unit (already open for stream unformatted access,
   !< left open by *close*) or, if neither is passed, on memory (see *string*).
   class(xml_writer),      intent(inout) :: self     !< XML writer.
   character(*), optional, intent(in)    :: filename !< File name.
   integer,      optional, intent(in)    :: unit     !< Unit, open for stream unformatted access.
   integer(I4P), optional, intent(in)    :: indent   !< Spaces per indentation level (default 2), 0 for no layout.
   integer(I4P), optional, intent(out)   :: iostat   !< IO status.
   character(*), optional, intent(inout) :: iomsg    !< IO message.
   integer(I4P)                          :: iostat_  !< IO status, local variable.
   character(len=500)                    :: iomsg_   !< IO message, local variable.

   if (self%is_unit_owned.and.self%is_open) close(self%unit)
   self%unit = 0
   self%is_memory = .false.
   self%is_unit_owned = .false.
   self%n = 0
   self%depth = 0
   if (allocated(self%pending)) deallocate(self%pending)
   self%is_empty = .true.
   self%error = 0
   if (allocated(self%error_message)) deallocate(self%error_message)
   self%indent = 2 ; if (present(indent)) self%indent = max(0_I4P, indent)
   if (.not.allocated(self%stack)) allocate(self%stack(INITIAL_DEPTH))
   self%is_open = .true.
   if (present(filename)) then
      open(newunit=self%unit, file=filename, access='STREAM', form='UNFORMATTED', action='WRITE', status='REPLACE', &
           iostat=iostat_, iomsg=iomsg_)
      if (iostat_/=0) then
         self%is_open = .false.
         call self%fail(iostat_, trim(iomsg_))
      else
         self%is_unit_owned = .true.
      endif
   elseif (present(unit)) then
      self%unit = unit
   else
      self%is_memory = .true.
   endif
   call self%report(iostat=iostat, iomsg=iomsg)
   endsubroutine open

   subroutine pi(self, target, string, iostat, iomsg)
   !< Write a processing instruction (`<?target string?>`); *string* cannot contain `?>`.
   class(xml_writer),      intent(inout) :: self   !< XML writer.
   character(*),           intent(in)    :: target !< PI target.
   character(*), optional, intent(in)    :: string !< PI content.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.

   if (present(string)) then
      if (index(string, '?>')>0) then
         call self%fail(XML_MALFORMED, 'processing instruction "'//string//'" contains "?>"')
      else
         call self%markup_line('<?'//target//' '//string//'?>')
      endif
   else
      call self%markup_line('<?'//target//'?>')
   endif
   call self%report(iostat=iostat, iomsg=iomsg)
   endsubroutine pi

   subroutine raw(self, string, is_block, iostat, iomsg)
   !< Write characters as they are (e.g. pre-formatted numbers, base64 data): inline, or with *is_block* on their own line
   !< (indented, the end tag of the element on its own line too). Large data can be written in pieces, with many calls.
   class(xml_writer),      intent(inout) :: self      !< XML writer.
   character(*),           intent(in)    :: string    !< Characters.
   logical,      optional, intent(in)    :: is_block  !< Write on their own line.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   logical                               :: is_block_ !< Write on their own line, local variable.

   is_block_ = .false. ; if (present(is_block)) is_block_ = is_block
   if (is_block_.and.self%indent>0.and.self%depth>0) then
      is_block_ = .not.(self%stack(self%depth)%is_inline.or.self%stack(self%depth)%in_inline)
   else
      is_block_ = .false.
   endif
   if (is_block_) then
      if (self%is_writable()) then
         if (allocated(self%pending)) call self%flush_pending
         call self%put(indentation(self, self%depth)//string//new_line_(self))
      endif
   elseif (self%start_content(what='data')) then
      call self%put(string)
   endif
   call self%report(iostat=iostat, iomsg=iomsg)
   endsubroutine raw

   subroutine start(self, name, iostat, iomsg)
   !< Open an element: its start tag stays pending (attributes can be added) up to its first content or its end.
   class(xml_writer),      intent(inout) :: self    !< XML writer.
   character(*),           intent(in)    :: name    !< Element name.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   type(open_element)                    :: element !< New element.

   if (self%is_writable()) then
      if (len_trim(name)==0) then
         call self%fail(XML_MALFORMED, 'element without name')
      else
         element%name = trim(name)
         if (self%depth>0) then
            element%in_inline = self%stack(self%depth)%is_inline.or.self%stack(self%depth)%in_inline
            if (allocated(self%pending)) call self%flush_pending
         endif
         if (.not.element%in_inline) call self%put(indentation(self, self%depth))
         if (self%depth==size(self%stack, dim=1)) self%stack = [self%stack, self%stack]
         self%depth = self%depth + 1
         self%stack(self%depth) = element
         self%pending = '<'//element%name
         self%is_empty = .false.
      endif
   endif
   call self%report(iostat=iostat, iomsg=iomsg)
   endsubroutine start

   pure function string(self) result(content)
   !< Return the content of the memory target (empty for a file or unit target).
   class(xml_writer), intent(in) :: self    !< XML writer.
   character(len=:), allocatable :: content !< Content.

   content = ''
   if (self%is_memory.and.allocated(self%buffer)) content = self%buffer(1:self%n)
   endfunction string

   subroutine text(self, string, iostat, iomsg)
   !< Write character data, escaped (`&`, `<`, `"`); the element is written inline.
   class(xml_writer),      intent(inout) :: self   !< XML writer.
   character(*),           intent(in)    :: string !< Character data.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.

   if (self%start_content(what='text')) call self%put(xml_escape(string))
   call self%report(iostat=iostat, iomsg=iomsg)
   endsubroutine text

   ! private methods
   subroutine attribute_character(self, name, value, iostat, iomsg)
   !< Add an attribute to the pending start tag (the value is escaped).
   class(xml_writer),      intent(inout) :: self   !< XML writer.
   character(*),           intent(in)    :: name   !< Attribute name.
   character(*),           intent(in)    :: value  !< Attribute value.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.

   if (self%is_writable()) then
      if (.not.allocated(self%pending)) then
         if (self%depth>0) then
            call self%fail(XML_MALFORMED, 'attribute "'//name//'" after the content of <'//self%stack(self%depth)%name//'>')
         else
            call self%fail(XML_MALFORMED, 'attribute "'//name//'" without an open element')
         endif
      else
         self%pending = self%pending//' '//name//'="'//xml_escape(value)//'"'
      endif
   endif
   call self%report(iostat=iostat, iomsg=iomsg)
   endsubroutine attribute_character

   subroutine attribute_i1p(self, name, value, fmt, iostat, iomsg)
   !< Add an integer attribute (no sign for positive values, or as formatted by *fmt*).
   class(xml_writer),      intent(inout) :: self   !< XML writer.
   character(*),           intent(in)    :: name   !< Attribute name.
   integer(I1P),           intent(in)    :: value  !< Attribute value.
   character(*), optional, intent(in)    :: fmt    !< Format, e.g. `(I3.3)`.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.
   character(len=64)                     :: chars  !< Formatted value.

   if (present(fmt)) then
      write(chars, fmt) value
   else
      chars = str(value, no_sign=value>=0) ! no_sign drops the minus too
   endif
   call self%attribute_character(name=name, value=trim(adjustl(chars)), iostat=iostat, iomsg=iomsg)
   endsubroutine attribute_i1p

   subroutine attribute_i2p(self, name, value, fmt, iostat, iomsg)
   !< Add an integer attribute (no sign for positive values, or as formatted by *fmt*).
   class(xml_writer),      intent(inout) :: self   !< XML writer.
   character(*),           intent(in)    :: name   !< Attribute name.
   integer(I2P),           intent(in)    :: value  !< Attribute value.
   character(*), optional, intent(in)    :: fmt    !< Format, e.g. `(I3.3)`.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.
   character(len=64)                     :: chars  !< Formatted value.

   if (present(fmt)) then
      write(chars, fmt) value
   else
      chars = str(value, no_sign=value>=0) ! no_sign drops the minus too
   endif
   call self%attribute_character(name=name, value=trim(adjustl(chars)), iostat=iostat, iomsg=iomsg)
   endsubroutine attribute_i2p

   subroutine attribute_i4p(self, name, value, fmt, iostat, iomsg)
   !< Add an integer attribute (no sign for positive values, or as formatted by *fmt*).
   class(xml_writer),      intent(inout) :: self   !< XML writer.
   character(*),           intent(in)    :: name   !< Attribute name.
   integer(I4P),           intent(in)    :: value  !< Attribute value.
   character(*), optional, intent(in)    :: fmt    !< Format, e.g. `(I3.3)`.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.
   character(len=64)                     :: chars  !< Formatted value.

   if (present(fmt)) then
      write(chars, fmt) value
   else
      chars = str(value, no_sign=value>=0) ! no_sign drops the minus too
   endif
   call self%attribute_character(name=name, value=trim(adjustl(chars)), iostat=iostat, iomsg=iomsg)
   endsubroutine attribute_i4p

   subroutine attribute_i8p(self, name, value, fmt, iostat, iomsg)
   !< Add an integer attribute (no sign for positive values, or as formatted by *fmt*).
   class(xml_writer),      intent(inout) :: self   !< XML writer.
   character(*),           intent(in)    :: name   !< Attribute name.
   integer(I8P),           intent(in)    :: value  !< Attribute value.
   character(*), optional, intent(in)    :: fmt    !< Format, e.g. `(I3.3)`.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.
   character(len=64)                     :: chars  !< Formatted value.

   if (present(fmt)) then
      write(chars, fmt) value
   else
      chars = str(value, no_sign=value>=0) ! no_sign drops the minus too
   endif
   call self%attribute_character(name=name, value=trim(adjustl(chars)), iostat=iostat, iomsg=iomsg)
   endsubroutine attribute_i8p

   subroutine attribute_r4p(self, name, value, fmt, iostat, iomsg)
   !< Add a real attribute (full precision, exponent form, or as formatted by *fmt*).
   class(xml_writer),      intent(inout) :: self   !< XML writer.
   character(*),           intent(in)    :: name   !< Attribute name.
   real(R4P),              intent(in)    :: value  !< Attribute value.
   character(*), optional, intent(in)    :: fmt    !< Format, e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.
   character(len=64)                     :: chars  !< Formatted value.

   if (present(fmt)) then
      write(chars, fmt) value
   else
      chars = str(value, no_sign=value>=0) ! no_sign drops the minus too
   endif
   call self%attribute_character(name=name, value=trim(adjustl(chars)), iostat=iostat, iomsg=iomsg)
   endsubroutine attribute_r4p

   subroutine attribute_r8p(self, name, value, fmt, iostat, iomsg)
   !< Add a real attribute (full precision, exponent form, or as formatted by *fmt*).
   class(xml_writer),      intent(inout) :: self   !< XML writer.
   character(*),           intent(in)    :: name   !< Attribute name.
   real(R8P),              intent(in)    :: value  !< Attribute value.
   character(*), optional, intent(in)    :: fmt    !< Format, e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.
   character(len=64)                     :: chars  !< Formatted value.

   if (present(fmt)) then
      write(chars, fmt) value
   else
      chars = str(value, no_sign=value>=0) ! no_sign drops the minus too
   endif
   call self%attribute_character(name=name, value=trim(adjustl(chars)), iostat=iostat, iomsg=iomsg)
   endsubroutine attribute_r8p

   subroutine attribute_logical(self, name, value, iostat, iomsg)
   !< Add a logical attribute, as `true` or `false`.
   class(xml_writer),      intent(inout) :: self   !< XML writer.
   character(*),           intent(in)    :: name   !< Attribute name.
   logical,                intent(in)    :: value  !< Attribute value.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.

   if (value) then
      call self%attribute_character(name=name, value='true', iostat=iostat, iomsg=iomsg)
   else
      call self%attribute_character(name=name, value='false', iostat=iostat, iomsg=iomsg)
   endif
   endsubroutine attribute_logical

   subroutine fail(self, error, message)
   !< Record an error, if it is the first one.
   class(xml_writer), intent(inout) :: self    !< XML writer.
   integer(I4P),      intent(in)    :: error   !< Error status.
   character(*),      intent(in)    :: message !< Error message.

   if (self%error/=0) return
   self%error = error
   self%error_message = message
   endsubroutine fail

   subroutine flush_pending(self)
   !< Complete the pending start tag of the innermost element, before its first content (a new line follows, unless the
   !< element is inline).
   class(xml_writer), intent(inout) :: self !< XML writer.

   call self%put(self%pending//'>')
   if (.not.(self%stack(self%depth)%is_inline.or.self%stack(self%depth)%in_inline)) call self%put(new_line_(self))
   deallocate(self%pending)
   endsubroutine flush_pending

   function is_writable(self)
   !< Check that the writer is open and without errors (a call on a writer not open is an error).
   class(xml_writer), intent(inout) :: self        !< XML writer.
   logical                          :: is_writable !< Check result.

   is_writable = .false.
   if (self%error/=0) return
   if (.not.self%is_open) then
      call self%fail(XML_MALFORMED, 'the writer is not open')
      return
   endif
   is_writable = .true.
   endfunction is_writable

   subroutine markup_line(self, markup)
   !< Write a comment or PI: on its own line, or inline inside an inline element.
   class(xml_writer), intent(inout) :: self   !< XML writer.
   character(*),      intent(in)    :: markup !< Markup.

   if (.not.self%is_writable()) return
   if (self%depth>0) then
      if (self%stack(self%depth)%is_inline.or.self%stack(self%depth)%in_inline) then
         call self%put(markup)
         return
      endif
      if (allocated(self%pending)) call self%flush_pending
   endif
   call self%put(indentation(self, self%depth)//markup//new_line_(self))
   self%is_empty = .false.
   endsubroutine markup_line

   subroutine put(self, string)
   !< Write characters to the target (unit or memory).
   class(xml_writer), intent(inout) :: self   !< XML writer.
   character(*),      intent(in)    :: string !< Characters.
   character(len=:), allocatable    :: grown  !< Grown buffer.
   integer(I4P)                     :: iostat !< IO status.
   character(len=500)               :: iomsg  !< IO message.

   if (self%error/=0.or.len(string)==0) return
   if (.not.self%is_memory) then
      write(self%unit, iostat=iostat, iomsg=iomsg) string
      if (iostat/=0) call self%fail(iostat, trim(iomsg))
   else
      if (.not.allocated(self%buffer)) allocate(character(len=max(INITIAL_BUFFER_LEN, len(string, kind=I8P))) :: self%buffer)
      if (self%n+len(string, kind=I8P)>len(self%buffer, kind=I8P)) then
         allocate(character(len=max(2_I8P*len(self%buffer, kind=I8P), self%n+len(string, kind=I8P))) :: grown)
         grown(1:self%n) = self%buffer(1:self%n)
         call move_alloc(from=grown, to=self%buffer)
      endif
      self%buffer(self%n+1:self%n+len(string, kind=I8P)) = string
      self%n = self%n + len(string, kind=I8P)
   endif
   endsubroutine put

   subroutine report(self, iostat, iomsg)
   !< Return the error status (*iomsg* only if there is an error).
   class(xml_writer),      intent(in)    :: self   !< XML writer.
   integer(I4P), optional, intent(out)   :: iostat !< IO status.
   character(*), optional, intent(inout) :: iomsg  !< IO message.

   if (present(iostat)) iostat = self%error
   if (present(iomsg).and.self%error/=0) iomsg = self%error_message
   endsubroutine report

   function start_content(self, what) result(is_ready)
   !< Prepare the innermost element for inline content (text, data, CDATA): its start tag is completed, it becomes inline.
   class(xml_writer), intent(inout) :: self     !< XML writer.
   character(*),      intent(in)    :: what     !< Content kind, for the error message.
   logical                          :: is_ready !< The content can be written.

   is_ready = .false.
   if (.not.self%is_writable()) return
   if (self%depth==0) then
      call self%fail(XML_MALFORMED, what//' outside the root element')
   else
      self%stack(self%depth)%is_inline = .true.
      if (allocated(self%pending)) call self%flush_pending
      is_ready = self%error==0
   endif
   endfunction start_content

   ! non type-bound procedures
   pure function indentation(self, depth) result(blanks)
   !< Return the indentation of a depth.
   type(xml_writer), intent(in)  :: self   !< XML writer.
   integer(I4P),     intent(in)  :: depth  !< Depth.
   character(len=:), allocatable :: blanks !< Indentation.

   blanks = repeat(' ', self%indent*depth)
   endfunction indentation

   pure function new_line_(self) result(nl)
   !< Return a new line, or nothing without layout.
   type(xml_writer), intent(in)  :: self !< XML writer.
   character(len=:), allocatable :: nl   !< New line.

   nl = ''
   if (self%indent>0) nl = new_line('a')
   endfunction new_line_
endmodule foxy_xml_writer
