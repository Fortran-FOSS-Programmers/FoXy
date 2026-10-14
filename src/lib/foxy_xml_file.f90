!< FoXy XML file class.
module foxy_xml_file
!< FoXy XML file class.
use foxy_xml_entities, only : xml_unescape
use foxy_xml_tag, only : xml_tag
use foxy_xml_tree, only : tree_attribute, tree_build_children, tree_children, tree_find_all
use penf

implicit none
private

integer(I4P), parameter, public :: XML_MALFORMED = 9001_I4P !< *iostat* of parse for malformed XML input.
integer(I4P), parameter :: INITIAL_CAPACITY   = 64_I4P   !< Initial capacity of the tags array, doubled when full.
integer(I8P), parameter :: INITIAL_BUFFER_LEN = 4096_I8P !< Initial length of the stringify buffer, doubled when full.
character(*), parameter :: BLANKS   = ' '//achar(9)//achar(10)//achar(13) !< XML blanks: space, tab, new line, CR.
character(*), parameter :: NAME_END = BLANKS//'/>=' !< Characters ending a tag or attribute name.
character(*), parameter :: CDATA_START = '<![CDATA[' !< CDATA section start.
character(*), parameter :: CDATA_END   = ']]>'       !< CDATA section end.
character(*), parameter :: XML_DECLARATION = '<?xml version="1.0"?>' !< XML declaration written by *save*.

type, public:: xml_file
   !< XML file class.
   private
   type(xml_tag), allocatable    :: tag(:)   !< XML tags array.
   integer(I4P)                  :: nt=0_I4P !< Number of XML tags.
   character(len=:), allocatable :: prolog   !< Markup before the root tag (XML declaration, DOCTYPE, comments, PIs),
                                             !< verbatim; written back by *stringify*.
   contains
      ! public methods
      procedure, pass(self) :: add_tag    !< Add tag to XML file.
      procedure, pass(self) :: attribute  !< Return the value of an attribute of the tag with a given ID.
      procedure, pass(self) :: children   !< Return the IDs of the children of the tag with a given ID.
      generic               :: content => &
                               content_by_name, &
                               content_by_id      !< Return tag content, by tag name or ID.
      procedure, pass(self) :: delete_tag !< Add tag from XML file.
      procedure, pass(self) :: find       !< Return the ID of the first tag matching a name or a path.
      procedure, pass(self) :: find_all   !< Return the IDs of all tags matching a name or a path.
      procedure, pass(self) :: free       !< Free dynamic memory.
      procedure, pass(self) :: parse      !< Parse xml file.
      procedure, pass(self) :: save       !< Save the whole file data into a file.
      procedure, pass(self) :: stringify  !< Convert the whole file data into a string.
      ! private methods
      procedure, pass(self), private :: append_inline       !< Append a tag with its subtree, without layout.
      procedure, pass(self), private :: append_inline_body  !< Append a tag text, children and their tails, without layout.
      procedure, pass(self), private :: direct_text         !< Return a tag text plus its children tails (raw).
      procedure, pass(self), private :: is_mixed            !< Check if a tag has mixed content.
      procedure, pass(self), private :: raw_text            !< Return a tag stored text (raw).
      procedure, pass(self), private :: content_by_id       !< Return tag content of the tag with a given ID.
      procedure, pass(self), private :: content_by_name     !< Return tag content of tag named *name*.
      procedure, pass(self), private :: parse_from_string   !< Parse xml data from string.
      procedure, pass(self), private :: stringify_recursive !< Convert recursively tags with children into a string.
      ! operators
      final :: finalize !< Free dynamic memory when finalizing.
endtype xml_file
contains
   ! public methods
   elemental subroutine add_tag(self, tag)
   !< Add tag to XML file, as a root tag (without parent and children).
   !<
   !< @note Tags IDs are the tags indexes into the tags array: the added tag ID is the new number of tags.
   !< @note The tags array capacity is doubled when full, thus adding n tags costs O(n) tags copies, not O(n^2): only the
   !< first *nt* elements are tags, the others are spare capacity.
   class(xml_file), intent(inout) :: self       !< XML file.
   type(xml_tag),   intent(in)    :: tag        !< XML tag.
   type(xml_tag), allocatable     :: tag_new(:) !< New (extended) tags array.

   if (.not.allocated(self%tag)) then
      allocate(self%tag(1:INITIAL_CAPACITY))
   elseif (self%nt==size(self%tag, dim=1)) then
      allocate(tag_new(1:2 * size(self%tag, dim=1)))
      tag_new(1:self%nt) = self%tag(1:self%nt)
      call move_alloc(from=tag_new, to=self%tag)
   endif
   self%nt = self%nt + 1
   self%tag(self%nt) = tag
   call self%tag(self%nt)%set(id=self%nt, parent_id=0_I4P)
   if (allocated(self%tag(self%nt)%child_id)) deallocate(self%tag(self%nt)%child_id)
   self%tag(self%nt)%children_number = 0_I4P
   endsubroutine add_tag

   pure function attribute(self, id, name) result(value)
   !< Return the value of the attribute named *name* of the tag with ID *id*.
   !<
   !< @note If the tag or the attribute does not exist, an empty string is returned.
   class(xml_file), intent(in)   :: self  !< XML file.
   integer(I4P),    intent(in)   :: id    !< Tag ID.
   character(*),    intent(in)   :: name  !< Attribute name.
   character(len=:), allocatable :: value !< Attribute value.

   value = tree_attribute(tag=self%tag, nt=self%nt, id=id, name=name)
   endfunction attribute

   pure function children(self, id) result(ids)
   !< Return the IDs of the direct children of the tag with ID *id*, in document order.
   !<
   !< @note The ID 0 is the document root: its children are the root tags.
   class(xml_file), intent(in) :: self   !< XML file.
   integer(I4P),    intent(in) :: id     !< Tag ID.
   integer(I4P), allocatable   :: ids(:) !< Children IDs, empty if there are none.

   ids = tree_children(tag=self%tag, nt=self%nt, id=id)
   endfunction children

   pure function content_by_id(self, id) result(content)
   !< Return tag content of the tag with ID *id*.
   !<
   !< @note Only the tag own content is returned, without leading and trailing blanks and with character references
   !< decoded; if the tag does not exist or has no content, an empty string is returned.
   class(xml_file), intent(in)   :: self    !< XML file.
   integer(I4P),    intent(in)   :: id      !< Tag ID.
   character(len=:), allocatable :: content !< Tag content.

   if (id>=1.and.id<=self%nt) then
      content = text_value(self%direct_text(id))
   else
      content = ''
   endif
   endfunction content_by_id

   pure function find(self, name, path, parent) result(id)
   !< Return the ID of the first tag (in document order) matching *name* or *path*, 0 if there is none.
   !<
   !< @note See *find_all* for the matching rules.
   class(xml_file), intent(in)           :: self   !< XML file.
   character(*),    intent(in), optional :: name   !< Tag name.
   character(*),    intent(in), optional :: path   !< Tags path, e.g. `origin/latitude/value`.
   integer(I4P),    intent(in), optional :: parent !< Parent tag ID, 0 for the document root.
   integer(I4P)                          :: id     !< Tag ID.
   integer(I4P), allocatable             :: ids(:) !< Matching tags IDs.

   ids = self%find_all(name=name, path=path, parent=parent)
   id = 0_I4P
   if (size(ids)>0) id = ids(1)
   endfunction find

   pure function find_all(self, name, path, parent) result(ids)
   !< Return the IDs of all tags (in document order) matching *name* or *path*.
   !<
   !< Matching rules:
   !<
   !< + *name*: tags named *name* at any depth or, if *parent* is passed, only the direct children of *parent*;
   !< + *path*: `/`-separated tags names; the first one is matched as *name*, each following one must be a direct child
   !<   of the previous one; all the tags matching a segment are explored, thus repeated parents are handled.
   !<
   !< @note If both *name* and *path* are passed, *path* is used; if none is passed, no tag is returned.
   class(xml_file), intent(in)           :: self   !< XML file.
   character(*),    intent(in), optional :: name   !< Tag name.
   character(*),    intent(in), optional :: path   !< Tags path, e.g. `origin/latitude/value`.
   integer(I4P),    intent(in), optional :: parent !< Parent tag ID, 0 for the document root.
   integer(I4P), allocatable             :: ids(:) !< Matching tags IDs, empty if there are none.

   ids = tree_find_all(tag=self%tag, nt=self%nt, name=name, path=path, parent=parent)
   endfunction find_all

   pure function content_by_name(self, name) result(content)
   !< Return tag content of tag named *name*.
   !<
   !< @note If there is no value, the *tag_content* string is returned empty, but allocated.
   !< @note Leading and trailing blanks (new lines included) are layout, not data: they are stripped from the returned
   !< content, while the stored content keeps them for a faithful *stringify*.
   !< @note Character references are decoded in the returned content, the stored content keeps them.
   class(xml_file), intent(in)   :: self    !< XML file.
   character(*),    intent(in)   :: name    !< Tag name.
   character(len=:), allocatable :: content !< Tag content.
   integer(I4P)                  :: t       !< Counter.

   if (allocated(content)) deallocate(content)
   do t=1, self%nt
      if (self%tag(t)%name()==name) then
         content = self%direct_text(t)
      elseif (index(without_markup(self%raw_text(t), is_cdata_removed=.true.), '<', kind=I8P)>0) then
         call self%tag(t)%get_content(name=name, content=content) ! nested tag set as content string
      endif
      if (allocated(content)) exit
   enddo
   if (allocated(content)) then
      content = text_value(content)
   else
      content = ''
   endif
   endfunction content_by_name

   elemental subroutine delete_tag(self, name)
   !< Delete the first tag named *name*, together with its whole subtree, from XML file.
   !<
   !< @note Tags IDs are the tags indexes into the tags array: the remaining tags are renumbered, parent and children IDs
   !< included. A child index is always greater than its parent one (document order for parsed tags, root tags for added
   !< ones), thus the subtree is collected by a single forward sweep.
   class(xml_file), intent(inout) :: self          !< XML file.
   character(*),    intent(in)    :: name          !< XML tag name.
   type(xml_tag), allocatable     :: tag_new(:)    !< New (reduced) tags array.
   logical,       allocatable     :: is_deleted(:) !< Flag of deleted tags.
   integer(I4P),  allocatable     :: new_id(:)     !< New ID of each tag, 0 if deleted.
   integer(I4P),  allocatable     :: child_id(:)   !< Children IDs, renumbered.
   integer(I4P)                   :: parent_id     !< Parent ID.
   integer(I4P)                   :: t             !< Counter.
   integer(I4P)                   :: n             !< Counter.

   if (self%nt==0_I4P) return
   allocate(is_deleted(self%nt), source=.false.)
   do t=1, self%nt
      if (name==self%tag(t)%name()) then
         is_deleted(t) = .true.
         exit
      endif
   enddo
   if (.not.any(is_deleted)) return
   do t=1, self%nt
      parent_id = self%tag(t)%get_parent_id()
      if (parent_id>0.and.parent_id<t) then
         if (is_deleted(parent_id)) is_deleted(t) = .true.
      endif
   enddo

   allocate(new_id(self%nt), source=0_I4P)
   n = 0
   do t=1, self%nt
      if (.not.is_deleted(t)) then
         n = n + 1
         new_id(t) = n
      endif
   enddo
   allocate(tag_new(1:n))
   do t=1, self%nt
      if (is_deleted(t)) cycle
      tag_new(new_id(t)) = self%tag(t)
      parent_id = self%tag(t)%get_parent_id()
      if (parent_id>0) parent_id = new_id(parent_id)
      call tag_new(new_id(t))%set(id=new_id(t), parent_id=parent_id)
      if (allocated(self%tag(t)%child_id)) then
         child_id = pack(new_id(self%tag(t)%child_id), new_id(self%tag(t)%child_id)>0)
         deallocate(tag_new(new_id(t))%child_id)
         if (size(child_id)>0) tag_new(new_id(t))%child_id = child_id
         tag_new(new_id(t))%children_number = size(child_id)
      endif
   enddo
   call move_alloc(from=tag_new, to=self%tag)
   self%nt = n
   endsubroutine delete_tag

   elemental subroutine free(self)
   !< Free dynamic memory.
   class(xml_file), intent(inout) :: self !< XML file.

   if (allocated(self%tag)) then
      call self%tag%free
      deallocate(self%tag)
   endif
   self%nt = 0_I4P
   if (allocated(self%prolog)) deallocate(self%prolog)
   endsubroutine free

   subroutine parse(self, string, filename, iostat, iomsg, sanitize_attributes_value)
   !< Parse xml data from string or file.
   !< XML data is linearized, a DOM structured is used.
   !<
   !< @note Self data are free before trying to parse new xml data: all previously parsed data are lost.
   !< @note Parsing is tolerant: malformed input is parsed as far as possible. If *iostat* is passed, it returns 0 on
   !< success, the runtime I/O error code if the file cannot be read, *XML_MALFORMED* if the input is malformed; *iomsg*
   !< (unchanged on success) describes the error, for malformed input the first problem found with its line.
   !< @note Leading and trailing spaces of attribute values are trimmed (default), unless *sanitize_attributes_value* is
   !< false: then values are kept as in the source (XML data).
   class(xml_file),        intent(inout) :: self     !< XML file.
   character(*), optional, intent(in)    :: string   !< String containing xml data.
   character(*), optional, intent(in)    :: filename !< File name containing xml data.
   integer(I4P), optional, intent(out)   :: iostat   !< IO status.
   character(*), optional, intent(inout) :: iomsg    !< IO message.
   logical,      optional, intent(in)    :: sanitize_attributes_value !< Trim attribute values spaces (default .true.).
   character(len=:), allocatable         :: source   !< String containing xml data.
   character(len=:), allocatable         :: problem  !< First problem of malformed input.
   integer(I4P)                          :: iostat_  !< IO status, local variable.
   character(len=500)                    :: iomsg_   !< IO message, local variable.
   logical                               :: sanitize !< Trim attribute values spaces, local variable.

   sanitize = .true. ; if (present(sanitize_attributes_value)) sanitize = sanitize_attributes_value
   iostat_ = 0
   iomsg_ = ''
   call self%free
   if (present(string)) then
      call self%parse_from_string(source_string=string, sanitize=sanitize, problem=problem)
   elseif (present(filename)) then
      source = load_file_as_stream(filename=filename, fast_read=.true., iostat=iostat_, iomsg=iomsg_)
      if (iostat_<0) iostat_ = 0 ! end of file is not an error
      if (iostat_==0.and.allocated(source)) call self%parse_from_string(source_string=source, sanitize=sanitize, &
                                                                        problem=problem)
   endif
   if (iostat_==0.and.allocated(problem)) then
      iostat_ = XML_MALFORMED
      iomsg_ = problem
   endif
   if (present(iostat)) iostat = iostat_
   if (present(iomsg).and.iostat_/=0) iomsg = iomsg_
   endsubroutine parse

   subroutine save(self, filename, is_declared, iostat, iomsg)
   !< Save the whole file data into a file: the prolog and the tags (as *stringify*), ended by a new line.
   !<
   !< @note If *is_declared* is true and the prolog does not start with an XML declaration (e.g. a document built in
   !< code), the declaration `<?xml version="1.0"?>` is written first.
   !< @note If *iostat* is passed, it returns 0 on success or the runtime I/O error code, and *iomsg* (unchanged on
   !< success) describes the error; without *iostat* an I/O error stops the program, as Fortran I/O statements do.
   class(xml_file),        intent(in)    :: self        !< XML file.
   character(*),           intent(in)    :: filename    !< File name.
   logical,      optional, intent(in)    :: is_declared !< Write the XML declaration, if missing.
   integer(I4P), optional, intent(out)   :: iostat      !< IO status.
   character(*), optional, intent(inout) :: iomsg       !< IO message.
   logical                               :: is_declared_ !< Write the XML declaration, local variable.
   integer(I4P)                          :: iostat_     !< IO status, local variable.
   character(len=500)                    :: iomsg_      !< IO message, local variable.
   integer(I4P)                          :: unit        !< File unit.

   is_declared_ = .false. ; if (present(is_declared)) is_declared_ = is_declared
   if (is_declared_.and.allocated(self%prolog)) is_declared_ = .not.starts_with_declaration(self%prolog)
   open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE', iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) then
      if (is_declared_) write(unit=unit, iostat=iostat_, iomsg=iomsg_) XML_DECLARATION//new_line('a')
      if (iostat_==0) write(unit=unit, iostat=iostat_, iomsg=iomsg_) self%stringify()//new_line('a')
      close(unit)
   endif
   if (present(iostat)) then
      iostat = iostat_
      if (present(iomsg).and.iostat_/=0) iomsg = iomsg_
   elseif (iostat_/=0) then
      error stop 'xml_file%save: '//trim(iomsg_)
   endif
   endsubroutine save

   pure function stringify(self, linearize) result(string)
   !< Convert the whole file data into a string.
   class(xml_file), intent(in)           :: self       !< XML file.
   logical,         intent(in), optional :: linearize  !< Return a "linearized" string of tags without the XML hieararchy.
   logical                               :: linearize_ !< Linearize sentinel, local var.
   character(len=:), allocatable         :: string     !< Output string containing the whole xml file.
   character(len=:), allocatable         :: buffer     !< Output buffer, grown geometrically (O(n) total copies).
   integer(I8P)                          :: n          !< Used length of the buffer.
   integer(I4P)                          :: t          !< Counter.
   integer(I4P)                          :: c          !< Counter.
   logical, allocatable                  :: is_done(:) !< List of stringified tags.
   character(len=:), allocatable         :: tail       !< Tail of a root tag.
   integer(I8P)                          :: last       !< Last not blank character of a root tag tail.

   linearize_ = .false. ; if (present(linearize)) linearize_ = linearize
   n = 0
   ! root tags (and, in linearized form, all tags) are separated by new lines
   if (linearize_) then
      do t=1, self%nt
         if (t>1) call append(buffer=buffer, n=n, piece=new_line('a'))
         call append(buffer=buffer, n=n, piece=self%tag(t)%stringify(linearize=.true.))
      enddo
   else
      if (allocated(self%prolog)) call append(buffer=buffer, n=n, piece=self%prolog)
      allocate(is_done(self%nt)) ; is_done = .false.
      do t=1, self%nt
         if (is_done(t)) cycle
         if (t>1) call append(buffer=buffer, n=n, piece=new_line('a'))
         if (self%is_mixed(t)) then
            call append(buffer=buffer, n=n, piece=self%tag(t)%start_tag(is_indented=.true.))
            call self%append_inline_body(t=t, is_done=is_done, buffer=buffer, n=n)
            call append(buffer=buffer, n=n, piece=self%tag(t)%end_tag())
         elseif (self%tag(t)%children_number>0) then
            call append(buffer=buffer, n=n, piece=self%tag(t)%stringify(is_indented=.true., only_start=.true.))
            do c=1, self%tag(t)%children_number
               call self%stringify_recursive(tag=self%tag(self%tag(t)%child_id(c)), is_done=is_done, buffer=buffer, n=n)
               is_done(self%tag(t)%child_id(c)) = .true.
            enddo
            call append(buffer=buffer, n=n, piece=new_line('a')//self%tag(t)%stringify(is_indented=.true., only_end=.true.))
         else
            call append(buffer=buffer, n=n, piece=self%tag(t)%stringify(is_indented=.true.))
         endif
         is_done(t) = .true.
         ! the tail of a root tag holds the markup after it (e.g. comments), trailing blanks are layout
         tail = self%tag(t)%get_tail()
         last = verify(tail, BLANKS, back=.true., kind=I8P)
         if (self%tag(t)%get_parent_id()==0.and.last>0) call append(buffer=buffer, n=n, piece=tail(1:last))
      enddo
   endif
   if (n>0) then
      string = buffer(1:n)
   else
      string = ''
   endif
   endfunction stringify

   ! private methods
   recursive pure subroutine append_inline(self, t, is_done, buffer, n)
   !< Append to buffer a tag with its whole subtree as in the source, without added layout (mixed content).
   class(xml_file),               intent(in)    :: self       !< XML file.
   integer(I4P),                  intent(in)    :: t          !< Tag ID.
   logical,                       intent(inout) :: is_done(:) !< List of stringified tags.
   character(len=:), allocatable, intent(inout) :: buffer     !< Output buffer.
   integer(I8P),                  intent(inout) :: n          !< Used length of the buffer.

   if (self%tag(t)%children_number>0) then
      call append(buffer=buffer, n=n, piece=self%tag(t)%start_tag())
      call self%append_inline_body(t=t, is_done=is_done, buffer=buffer, n=n)
      call append(buffer=buffer, n=n, piece=self%tag(t)%end_tag())
   else
      call append(buffer=buffer, n=n, piece=self%tag(t)%stringify())
   endif
   endsubroutine append_inline

   recursive pure subroutine append_inline_body(self, t, is_done, buffer, n)
   !< Append to buffer the text of a tag, then each child (inline) followed by its tail.
   class(xml_file),               intent(in)    :: self       !< XML file.
   integer(I4P),                  intent(in)    :: t          !< Tag ID.
   logical,                       intent(inout) :: is_done(:) !< List of stringified tags.
   character(len=:), allocatable, intent(inout) :: buffer     !< Output buffer.
   integer(I8P),                  intent(inout) :: n          !< Used length of the buffer.
   integer(I4P)                                 :: c          !< Counter.

   call append(buffer=buffer, n=n, piece=self%raw_text(t))
   do c=1, self%tag(t)%children_number
      call self%append_inline(t=self%tag(t)%child_id(c), is_done=is_done, buffer=buffer, n=n)
      is_done(self%tag(t)%child_id(c)) = .true.
      call append(buffer=buffer, n=n, piece=self%tag(self%tag(t)%child_id(c))%get_tail())
   enddo
   endsubroutine append_inline_body

   pure function direct_text(self, t) result(text)
   !< Return the direct (raw) text of a tag: its text plus the tails of its children, the children text excluded.
   class(xml_file), intent(in)   :: self   !< XML file.
   integer(I4P),    intent(in)   :: t      !< Tag ID.
   character(len=:), allocatable :: text   !< Direct text.
   character(len=:), allocatable :: buffer !< Text buffer.
   integer(I8P)                  :: n      !< Used length of the buffer.
   integer(I4P)                  :: c      !< Counter.

   n = 0
   call append(buffer=buffer, n=n, piece=self%raw_text(t))
   do c=1, self%tag(t)%children_number
      call append(buffer=buffer, n=n, piece=self%tag(self%tag(t)%child_id(c))%get_tail())
   enddo
   text = buffer(1:n)
   endfunction direct_text

   pure function is_mixed(self, t) result(is_mixed_)
   !< Return .true. if a tag has mixed content: children and not blank text or children tails.
   class(xml_file), intent(in) :: self      !< XML file.
   integer(I4P),    intent(in) :: t         !< Tag ID.
   logical                     :: is_mixed_ !< Check result.
   integer(I4P)                :: c         !< Counter.

   is_mixed_ = .false.
   if (self%tag(t)%children_number==0) return
   is_mixed_ = verify(self%raw_text(t), BLANKS, kind=I8P)>0
   do c=1, self%tag(t)%children_number
      if (is_mixed_) return
      is_mixed_ = verify(self%tag(self%tag(t)%child_id(c))%get_tail(), BLANKS, kind=I8P)>0
   enddo
   endfunction is_mixed

   pure function raw_text(self, t) result(text)
   !< Return the stored (raw) text of a tag, an empty string if none.
   class(xml_file), intent(in)   :: self !< XML file.
   integer(I4P),    intent(in)   :: t    !< Tag ID.
   character(len=:), allocatable :: text !< Raw text.

   call self%tag(t)%get_content(name=self%tag(t)%name(), content=text)
   if (.not.allocated(text)) text = ''
   endfunction raw_text

   pure subroutine parse_from_string(self, source_string, sanitize, problem)
   !< Parse xml data from a string, with a single pass tokenizer.
   !<
   !< Markup is recognized in source order and quotes-aware: start, self closing and end tags (any blank separates names and
   !< attributes, attribute values single or double quoted), CDATA sections, comments and processing instructions (kept as
   !< raw text of their owner tag, the prolog before the first tag), declarations as DOCTYPE (skipped, kept only in the
   !< prolog). The text of a tag is its character data (CDATA, comments and PIs included) before its first child tag. An
   !< end tag closes up to its matching start tag (inner open tags are closed implicitly), a stray end tag is ignored;
   !< parsing stops at an unterminated markup. The first problem of malformed input is returned.
   class(xml_file),               intent(inout) :: self          !< XML file handler.
   character(*),                  intent(in)    :: source_string !< String containing xml data.
   logical,                       intent(in)    :: sanitize      !< Trim leading and trailing spaces of attribute values.
   character(len=:), allocatable, intent(out)   :: problem       !< First problem of malformed input, unallocated if none.
   character(len=:), allocatable  :: tag_name            !< Name of the current start tag.
   character(len=:), allocatable  :: name                !< Tag or attribute name.
   character(len=:), allocatable  :: value               !< Attribute value.
   character(len=:), allocatable  :: text                !< Text of the tag owning the current character data.
   character(len=1)               :: quote               !< Attribute value quote.
   type(xml_tag)                  :: tag                 !< Empty tag, added and then set.
   integer(I4P), allocatable      :: stack(:)            !< IDs of open tags.
   integer(I8P), allocatable      :: stack_start(:)      !< Start (`<`) positions of open tags.
   integer(I8P), allocatable      :: stack_open_end(:)   !< End (`>`) positions of open tags start tags.
   integer(I4P)                   :: depth               !< Number of open tags.
   integer(I4P)                   :: owner               !< ID of the tag owning the current character data, 0 if none.
   logical                        :: is_tail             !< The current character data is the owner tail, not its text.
   integer(I8P)                   :: n                   !< Source length.
   integer(I8P)                   :: pos                 !< Current position.
   integer(I8P)                   :: k                   !< Scan position.
   integer(I8P)                   :: e                   !< Relative position of a delimiter.
   integer(I4P)                   :: l                   !< Stack level.
   logical                        :: is_self_closing     !< Self closing tag flag.
   logical                        :: is_terminated       !< Terminated start tag flag.

   call self%free
   n = len(source_string, kind=I8P)
   allocate(stack(INITIAL_CAPACITY), stack_start(INITIAL_CAPACITY), stack_open_end(INITIAL_CAPACITY))
   depth = 0
   owner = 0
   is_tail = .false.
   text = ''
   pos = 1
   do while (pos<=n)
      if (source_string(pos:pos)/='<') then
         ! character data
         e = index(source_string(pos:), '<', kind=I8P)
         if (e==0) then
            k = n
         else
            k = pos + e - 2
         endif
         if (owner>0) text = text//source_string(pos:k)
         pos = k + 1
      elseif (source_string(pos:min(n, pos+3))=='<!--') then
         e = index(source_string(pos+4:), '-->', kind=I8P)
         if (e==0) then
            call record_problem(problem, source_string, pos, 'unterminated comment')
            exit
         endif
         k = pos + e + 5
         if (owner>0) text = text//source_string(pos:k)
         pos = k + 1
      elseif (source_string(pos:min(n, pos+8))=='<![CDATA[') then
         e = index(source_string(pos+9:), ']]>', kind=I8P)
         if (e==0) then
            call record_problem(problem, source_string, pos, 'unterminated CDATA section')
            exit
         endif
         k = pos + e + 10
         if (owner>0) text = text//source_string(pos:k)
         pos = k + 1
      elseif (source_string(pos:min(n, pos+1))=='<?') then
         e = index(source_string(pos+2:), '?>', kind=I8P)
         if (e==0) then
            call record_problem(problem, source_string, pos, 'unterminated processing instruction')
            exit
         endif
         k = pos + e + 2
         if (owner>0) text = text//source_string(pos:k)
         pos = k + 1
      elseif (source_string(pos:min(n, pos+1))=='<!') then
         k = after_declaration(source=source_string, start=pos)
         if (k==0) then
            call record_problem(problem, source_string, pos, 'unterminated declaration')
            exit
         endif
         pos = k
      elseif (source_string(pos:min(n, pos+1))=='</') then
         k = pos + 2
         call read_name(source=source_string, pos=k, name=name)
         e = index(source_string(k:), '>', kind=I8P)
         if (e==0) then
            call record_problem(problem, source_string, pos, 'unterminated end tag </'//name//'>')
            exit
         endif
         ! close up to the matching open tag, if any
         do l=depth, 1, -1
            if (self%tag(stack(l))%name()==name) exit
         enddo
         if (l==0) then
            call record_problem(problem, source_string, pos, 'end tag </'//name//'> without matching start tag')
         elseif (l<depth) then
            call record_problem(problem, source_string, pos, 'end tag </'//name//'> closes open tag <'// &
                                self%tag(stack(depth))%name()//'>')
         endif
         if (l>0) then
            call flush_text(self=self, owner=owner, is_tail=is_tail, text=text, is_parent=.false.)
            call self%tag(stack(l))%set(pos=[stack_start(l), stack_open_end(l), pos])
            owner = stack(l) ! the following character data is its tail
            is_tail = .true.
            depth = l - 1
         endif
         pos = k + e
      else
         ! start or self closing tag
         k = pos + 1
         call read_name(source=source_string, pos=k, name=name)
         if (len(name)==0) then ! not a tag, e.g. "a < b"
            call record_problem(problem, source_string, pos, "character '<' not starting a tag")
            if (owner>0) text = text//'<'
            pos = pos + 1
            cycle
         endif
         if (self%nt==0.and.pos>1) then ! the prolog is what precedes the first tag, if not only blanks
            if (verify(source_string(1:pos-1), BLANKS, kind=I8P)>0) self%prolog = source_string(1:pos-1)
         endif
         call flush_text(self=self, owner=owner, is_tail=is_tail, text=text, is_parent=.true.)
         call tag%free
         call self%add_tag(tag=tag)
         l = 0 ; if (depth>0) l = stack(depth)
         call self%tag(self%nt)%set(name=name, id=self%nt, level=depth+1, indent=depth*2, parent_id=l)
         tag_name = name
         is_terminated = .false.
         is_self_closing = .false.
         do
            call skip_blanks(source=source_string, pos=k)
            if (k>n) exit
            if (source_string(k:k)=='>') then
               is_terminated = .true.
               k = k + 1
               exit
            elseif (source_string(k:min(n, k+1))=='/>') then
               is_terminated = .true.
               is_self_closing = .true.
               k = k + 2
               exit
            endif
            call read_name(source=source_string, pos=k, name=name)
            if (len(name)==0) then ! stray character
               call record_problem(problem, source_string, k, "invalid character '"//source_string(k:k)//"' in tag <"// &
                                   tag_name//'>')
               k = k + 1
               cycle
            endif
            call skip_blanks(source=source_string, pos=k)
            if (k>n) exit
            if (source_string(k:k)/='=') then ! attribute without value, ignored
               call record_problem(problem, source_string, k, 'attribute "'//name//'" without value in tag <'//tag_name//'>')
               cycle
            endif
            k = k + 1
            call skip_blanks(source=source_string, pos=k)
            if (k>n) exit
            quote = source_string(k:k)
            if (quote/='"'.and.quote/="'") then ! unquoted value, ignored
               call record_problem(problem, source_string, k, 'unquoted value of attribute "'//name//'" in tag <'// &
                                   tag_name//'>')
               cycle
            endif
            e = index(source_string(k+1:), quote, kind=I8P)
            if (e==0) then
               call record_problem(problem, source_string, k, 'unterminated value of attribute "'//name//'" in tag <'// &
                                   tag_name//'>')
               k = n + 1
               exit
            endif
            value = source_string(k+1:k+e-1)
            k = k + e + 1
            if (quote=="'") value = escaped_double_quotes(value) ! values are written double quoted
            call self%tag(self%nt)%set(attribute_name=name, attribute_value=value, sanitize_attributes_value=sanitize)
         enddo
         if (.not.is_terminated) then
            call record_problem(problem, source_string, pos, 'unterminated start tag <'//tag_name//'>')
            exit
         endif
         if (is_self_closing) then
            call self%tag(self%nt)%set(pos=[pos, k-1, -1_I8P], is_self_closing=.true.)
            owner = self%nt ! the following character data is its tail
            is_tail = .true.
         else
            call self%tag(self%nt)%set(pos=[pos, k-1, 0_I8P], is_self_closing=.false.)
            if (depth==size(stack, dim=1)) then
               stack = [stack, stack]
               stack_start = [stack_start, stack_start]
               stack_open_end = [stack_open_end, stack_open_end]
            endif
            depth = depth + 1
            stack(depth) = self%nt
            stack_start(depth) = pos
            stack_open_end(depth) = k - 1
            owner = self%nt ! the following character data is its text
            is_tail = .false.
         endif
         pos = k
      endif
   enddo
   if (depth>0) call record_problem(problem, source_string, stack_start(1), 'unclosed tag <'//self%tag(stack(1))%name()//'>')
   call flush_text(self=self, owner=owner, is_tail=is_tail, text=text, is_parent=.false.)
   call tree_build_children(tag=self%tag, nt=self%nt)
   endsubroutine parse_from_string

   recursive pure subroutine stringify_recursive(self, tag, is_done, buffer, n)
   !< Append to buffer, recursively, a (nested) tag with its children, each line preceded by a new line.
   class(xml_file),               intent(in)    :: self       !< XML file.
   type(xml_tag),                 intent(in)    :: tag        !< XML tag.
   logical,                       intent(inout) :: is_done(:) !< List of stringified tags.
   character(len=:), allocatable, intent(inout) :: buffer     !< Output buffer.
   integer(I8P),                  intent(inout) :: n          !< Used length of the buffer.
   integer(I4P)                                 :: t          !< Counter.

   if (self%is_mixed(tag%get_id())) then
      call append(buffer=buffer, n=n, piece=new_line('a')//tag%start_tag(is_indented=.true.))
      call self%append_inline_body(t=tag%get_id(), is_done=is_done, buffer=buffer, n=n)
      call append(buffer=buffer, n=n, piece=tag%end_tag())
   elseif (tag%children_number>0) then
      call append(buffer=buffer, n=n, piece=new_line('a')//tag%stringify(is_indented=.true., only_start=.true.))
      do t=1, tag%children_number
         call self%stringify_recursive(tag=self%tag(tag%child_id(t)), is_done=is_done, buffer=buffer, n=n)
         is_done(tag%child_id(t)) = .true.
      enddo
      call append(buffer=buffer, n=n, piece=new_line('a')//tag%stringify(is_indented=.true., only_end=.true.))
   else
      call append(buffer=buffer, n=n, piece=new_line('a')//tag%stringify(is_indented=.true.))
   endif
   endsubroutine stringify_recursive

   ! operators
   subroutine finalize(self)
   !< Free dynamic memory when finalizing.
   type(xml_file), intent(inout) :: self !< XML file.

   call self%free
   endsubroutine finalize

   ! non TBP
   pure subroutine append(buffer, n, piece)
   !< Append a piece to a buffer of used length *n*, doubling its capacity when full.
   character(len=:), allocatable, intent(inout) :: buffer !< Buffer.
   integer(I8P),                  intent(inout) :: n      !< Used length of the buffer.
   character(*),                  intent(in)    :: piece  !< Piece to append.
   character(len=:), allocatable                :: grown  !< Grown buffer.

   if (.not.allocated(buffer)) allocate(character(len=max(INITIAL_BUFFER_LEN, len(piece, kind=I8P))) :: buffer)
   if (n + len(piece, kind=I8P)>len(buffer, kind=I8P)) then
      allocate(character(len=max(2_I8P * len(buffer, kind=I8P), n + len(piece, kind=I8P))) :: grown)
      grown(1:n) = buffer(1:n)
      call move_alloc(from=grown, to=buffer)
   endif
   buffer(n+1:n+len(piece, kind=I8P)) = piece
   n = n + len(piece, kind=I8P)
   endsubroutine append

   pure function after_declaration(source, start) result(after)
   !< Return the position after a `<!...>` declaration (e.g. DOCTYPE) starting at *start*, 0 if it is unterminated.
   !<
   !< @note Quoted strings and the `[...]` internal subset may contain `>`.
   character(*), intent(in) :: source  !< Source.
   integer(I8P), intent(in) :: start   !< Declaration start (`<`) position.
   integer(I8P)             :: after   !< Position after the declaration.
   integer(I4P)             :: brackets !< Internal subset nesting.
   integer(I8P)             :: e       !< Relative position of closing quote.
   character(len=1)         :: c       !< Current character.

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

   pure subroutine record_problem(problem, source, pos, message)
   !< Record a problem of malformed input with its line, only if it is the first one.
   character(len=:), allocatable, intent(inout) :: problem !< First problem, unallocated if none yet.
   character(*),                  intent(in)    :: source  !< Source.
   integer(I8P),                  intent(in)    :: pos     !< Position of the problem.
   character(*),                  intent(in)    :: message !< Problem description.
   integer(I8P)                                 :: line    !< Line of the problem.
   integer(I8P)                                 :: c       !< Counter.

   if (allocated(problem)) return
   line = 1
   do c=1, min(pos, len(source, kind=I8P)) - 1
      if (source(c:c)==new_line('a')) line = line + 1
   enddo
   problem = 'line '//trim(str(line, no_sign=.true.))//': '//message
   endsubroutine record_problem

   pure function starts_with_declaration(prolog) result(is_declaration)
   !< Check if a prolog starts with the XML declaration (`<?xml` followed by a blank, not a PI named `xml-...`).
   character(*), intent(in) :: prolog         !< Prolog.
   logical                  :: is_declaration !< Check result.

   is_declaration = .false.
   if (len(prolog, kind=I8P)>5) is_declaration = prolog(1:5)=='<?xml'.and.scan(prolog(6:6), BLANKS)>0
   endfunction starts_with_declaration

   pure subroutine flush_text(self, owner, is_tail, text, is_parent)
   !< Store the collected character data into its owner tag, if any, and reset them.
   !<
   !< The text of a tag ends at its first child or at its end tag; the tail of a tag (mixed content) is the character data
   !< after its end tag, up to the next sibling or the parent end tag. Tails and the text of a tag with children are stored
   !< raw (they are written back verbatim by mixed content tags), the text of a leaf tag is trimmed of spaces.
   class(xml_file),               intent(inout) :: self      !< XML file handler.
   integer(I4P),                  intent(inout) :: owner     !< ID of the tag owning the text, 0 if none.
   logical,                       intent(inout) :: is_tail   !< The text is the owner tail.
   character(len=:), allocatable, intent(inout) :: text      !< Collected text.
   logical,                       intent(in)    :: is_parent !< The text ends because the owner first child starts.

   if (owner>0) then
      if (is_tail) then
         call self%tag(owner)%set(tail=text)
      elseif (is_parent) then
         call self%tag(owner)%set(content=text)
      else
         call self%tag(owner)%set(content=trim(adjustl(text)))
      endif
   endif
   owner = 0
   is_tail = .false.
   text = ''
   endsubroutine flush_text

   pure function escaped_double_quotes(string) result(escaped)
   !< Return string with `"` replaced by `&quot;`.
   character(*), intent(in)      :: string  !< String.
   character(len=:), allocatable :: escaped !< Escaped string.
   integer(I4P)                  :: c       !< Counter.

   if (index(string, '"')==0) then
      escaped = string
      return
   endif
   escaped = ''
   do c=1, len(string)
      if (string(c:c)=='"') then
         escaped = escaped//'&quot;'
      else
         escaped = escaped//string(c:c)
      endif
   enddo
   endfunction escaped_double_quotes

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

   pure function text_value(raw) result(value)
   !< Return the value of raw character data: comments and PIs removed, layout blanks stripped, character references
   !< decoded, CDATA sections literal.
   character(*), intent(in)      :: raw      !< Raw character data.
   character(len=:), allocatable :: value    !< Value.
   character(len=:), allocatable :: stripped !< Raw data without leading and trailing blanks.
   integer(I8P)                  :: p        !< Current position.
   integer(I8P)                  :: c        !< Relative position of next CDATA start.
   integer(I8P)                  :: q        !< CDATA content start.
   integer(I8P)                  :: e        !< Relative position of CDATA end.

   stripped = strip_blanks(without_markup(raw)) ! blanks first: encoded blanks and CDATA blanks are data
   if (index(stripped, CDATA_START, kind=I8P)==0) then
      value = xml_unescape(stripped)
      return
   endif
   value = ''
   p = 1
   do while (p<=len(stripped, kind=I8P))
      c = index(stripped(p:), CDATA_START, kind=I8P)
      if (c==0) then
         value = value//xml_unescape(stripped(p:))
         exit
      endif
      value = value//xml_unescape(stripped(p:p+c-2))
      q = p + c - 1 + len(CDATA_START)
      e = index(stripped(q:), CDATA_END, kind=I8P)
      if (e==0) then ! unterminated, literal up to the end
         value = value//stripped(q:)
         exit
      endif
      value = value//stripped(q:q+e-2)
      p = q + e - 1 + len(CDATA_END)
   enddo
   endfunction text_value

   pure function without_markup(raw, is_cdata_removed) result(text)
   !< Return raw character data without comments and processing instructions (and CDATA sections, if asked); markup inside
   !< a CDATA section is data, an unterminated markup is kept as it is.
   character(*),      intent(in) :: raw              !< Raw character data.
   logical, optional, intent(in) :: is_cdata_removed !< Remove CDATA sections too.
   character(len=:), allocatable :: text             !< Character data without markup.
   character(len=:), allocatable :: buffer           !< Kept characters (allocatable: no stack object as large as raw).
   logical                       :: is_cdata_removed_ !< Remove CDATA sections too, local variable.
   integer(I8P)                  :: n                !< Number of kept characters.
   integer(I8P)                  :: p                !< Current position.
   integer(I8P)                  :: k                !< End of the current markup.
   integer(I8P)                  :: e                !< Relative position of the markup end.

   if (index(raw, '<', kind=I8P)==0) then
      text = raw
      return
   endif
   is_cdata_removed_ = .false. ; if (present(is_cdata_removed)) is_cdata_removed_ = is_cdata_removed
   allocate(character(len=len(raw, kind=I8P)) :: buffer)
   n = 0
   p = 1
   do while (p<=len(raw, kind=I8P))
      k = 0
      if (raw(p:p)=='<') then
         if (raw(p:min(len(raw, kind=I8P), p+8))==CDATA_START) then
            e = index(raw(p+9:), CDATA_END, kind=I8P)
            if (e>0) k = p + e + 10
            if (k>0.and..not.is_cdata_removed_) then ! kept as it is
               buffer(n+1:n+k-p+1) = raw(p:k)
               n = n + k - p + 1
            endif
         elseif (raw(p:min(len(raw, kind=I8P), p+3))=='<!--') then
            e = index(raw(p+4:), '-->', kind=I8P)
            if (e>0) k = p + e + 5
         elseif (raw(p:min(len(raw, kind=I8P), p+1))=='<?') then
            e = index(raw(p+2:), '?>', kind=I8P)
            if (e>0) k = p + e + 2
         endif
      endif
      if (k>0) then
         p = k + 1
      else
         n = n + 1
         buffer(n:n) = raw(p:p)
         p = p + 1
      endif
   enddo
   text = buffer(1:n)
   endfunction without_markup

   pure function strip_blanks(string) result(stripped)
   !< Return string without leading and trailing blanks: spaces, tabs, new lines and carriage returns.
   character(*), intent(in)      :: string   !< String to strip.
   character(len=:), allocatable :: stripped !< Stripped string.
   integer(I8P)                  :: first    !< First not blank character position.
   integer(I8P)                  :: last     !< Last not blank character position.

   first = verify(string, BLANKS, kind=I8P)
   if (first == 0) then
      stripped = ''
   else
      last = verify(string, BLANKS, back=.true., kind=I8P)
      stripped = string(first:last)
   endif
   endfunction strip_blanks

   function load_file_as_stream(filename, delimiter_start, delimiter_end, fast_read, iostat, iomsg) result(stream)
   !< Load file contents and store as single characters stream.
   character(*),           intent(in)  :: filename        !< File name.
   character(*), optional, intent(in)  :: delimiter_start !< Delimiter from which start the stream.
   character(*), optional, intent(in)  :: delimiter_end   !< Delimiter to which end the stream.
   logical,      optional, intent(in)  :: fast_read       !< Flag for activating efficient reading with one single read.
   integer(I4P), optional, intent(out) :: iostat          !< IO error.
   character(*), optional, intent(out) :: iomsg           !< IO error message.
   character(len=:), allocatable       :: stream          !< Output string containing the file data as a single stream.
   integer(I4P)                        :: unit            !< Unit file.
   integer(I4P)                        :: iostatd         !< IO error.
   character(500)                      :: iomsgd          !< IO error message.
   character(1)                        :: c1              !< Single character.
   character(len=:), allocatable       :: string          !< Dummy string.
   logical                             :: cstart          !< Flag for stream capturing trigging.
   logical                             :: cend            !< Flag for stream capturing trigging.
   logical                             :: fast            !< Flag for activating efficient reading with one single read.
   integer(I8P)                        :: filesize        !< Size of the file for fast reading.

   fast = .false. ; if (present(fast_read)) fast = fast_read
   ! open file: a missing file is an open error, reported by iostat/iomsg
   open(newunit=unit, file=adjustl(trim(filename)), access='STREAM', form='UNFORMATTED', status='OLD', iostat=iostatd, &
        iomsg=iomsgd)
   if (iostatd/=0) then
      if (present(iostat)) iostat = iostatd
      if (present(iomsg )) iomsg  = iomsgd
      return
   endif
   ! loadg data
   stream = ''
   if (present(delimiter_start).and.present(delimiter_end)) then
      ! load only data inside delimiter_start and delimiter_end
      string = ''
      Main_Read_Loop: do
         read(unit=unit, iostat=iostatd, iomsg=iomsgd, end=10)c1
         if (c1==delimiter_start(1:1)) then
            cstart = .true.
            string = c1
            Start_Read_Loop: do while(len(string)<len(delimiter_start))
               read(unit=unit, iostat=iostatd, iomsg=iomsgd, end=10)c1
               string = string//c1
               if (.not.(index(string=delimiter_start, substring=string)>0)) then
                  cstart = .false.
                  exit Start_Read_Loop
               endif
            enddo Start_Read_Loop
            if (cstart) then
               cend = .false.
               stream = string
               do while(.not.cend)
                  read(unit=unit, iostat=iostatd, iomsg=iomsgd, end=10)c1
                  if (c1==delimiter_end(1:1)) then ! maybe the end
                     string = c1
                     End_Read_Loop: do while(len(string)<len(delimiter_end))
                        read(unit=unit, iostat=iostatd, iomsg=iomsgd, end=10)c1
                        string = string//c1
                        if (.not.(index(string=delimiter_end, substring=string)>0)) then
                           stream = stream//string
                           exit End_Read_Loop
                        elseif (len(string)==len(delimiter_end)) then
                           cend = .true.
                           stream = stream//string
                           exit Main_Read_Loop
                        endif
                     enddo End_Read_Loop
                  else
                     stream = stream//c1
                  endif
               enddo
            endif
         endif
      enddo Main_Read_Loop
   else
      ! load all data
      if (fast) then
         ! load fast
         inquire(file=adjustl(trim(filename)), size=filesize, iostat=iostatd, iomsg=iomsgd)
         if (iostatd==0) then
            if (allocated(stream)) deallocate(stream)
            allocate(character(len=filesize):: stream)
            read(unit=unit, iostat=iostatd, iomsg=iomsgd, end=10)stream
         endif
      else
         ! load slow, one character loop
         Read_Loop: do
            read(unit=unit,iostat=iostatd,iomsg=iomsgd,end=10)c1
            stream = stream//c1
         enddo Read_Loop
      endif
   endif
   10 close(unit)
   if (present(iostat)) iostat = iostatd
   if (present(iomsg))  iomsg  = iomsgd
   endfunction load_file_as_stream

endmodule foxy_xml_file
