!< FoXy XML file class.
module foxy_xml_file
!< FoXy XML file class.
use foxy_xml_entities, only : xml_unescape
use foxy_xml_tag, only : xml_tag
use foxy_xml_tokenizer, only : xml_builder, xml_tokenizer, DATA_TEXT, DATA_PI
use foxy_xml_tree, only : tree_attribute, tree_build_children, tree_children, tree_find_all
use penf

implicit none
private

integer(I4P), parameter, public :: XML_MALFORMED = 9001_I4P !< *iostat* of parse for malformed XML input.
integer(I4P), parameter :: INITIAL_CAPACITY   = 64_I4P   !< Initial capacity of the tags array, doubled when full.
integer(I8P), parameter :: INITIAL_BUFFER_LEN = 4096_I8P !< Initial length of the stringify buffer, doubled when full.
integer(I8P), parameter :: FILE_CHUNK_SIZE = 1048576_I8P !< Default size of the chunks read from a file (1 MiB).
character(*), parameter :: BLANKS   = ' '//achar(9)//achar(10)//achar(13) !< XML blanks: space, tab, new line, CR.
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
      procedure, pass(self), private :: parse_from_file     !< Parse xml data from a file, read in chunks.
      procedure, pass(self), private :: parse_from_string   !< Parse xml data from string.
      procedure, pass(self), private :: stringify_recursive !< Convert recursively tags with children into a string.
      ! operators
      final :: finalize !< Free dynamic memory when finalizing.
endtype xml_file

type, extends(xml_builder) :: dom_builder
   !< Builder of the DOM of an XML file, driven by the tokenizer.
   !<
   !< The text of a tag ends at its first child or at its end tag; the tail of a tag (mixed content) is the character data
   !< after its end tag, up to the next sibling or the parent end tag. Tails and the text of a tag with children are stored
   !< raw (they are written back verbatim by mixed content tags), the text of a leaf tag is trimmed of spaces. CDATA
   !< sections, comments and processing instructions are part of the text; the markup before the first tag is the prolog.
   type(xml_file)                :: doc               !< Document being built.
   logical                       :: sanitize=.true.   !< Trim leading and trailing spaces of attribute values.
   integer(I4P)                  :: owner=0_I4P       !< ID of the tag owning the current character data, 0 if none.
   logical                       :: is_tail=.false.   !< The current character data is the owner tail, not its text.
   character(len=:), allocatable :: text              !< Current character data (buffer).
   integer(I8P)                  :: text_n=0_I8P      !< Length of the current character data.
   character(len=:), allocatable :: prolog            !< Markup before the first tag (buffer).
   integer(I8P)                  :: prolog_n=0_I8P    !< Length of the markup before the first tag.
   character(len=:), allocatable :: first_problem     !< First problem of malformed input, unallocated if none.
   integer(I8P)                  :: problem_pos=0_I8P !< Position of the first problem.
   contains
      procedure, pass(self) :: start_tag     => dom_start_tag     !< A start tag begins.
      procedure, pass(self) :: attribute     => dom_attribute     !< An attribute of the current start tag.
      procedure, pass(self) :: start_tag_end => dom_start_tag_end !< The current start tag is complete.
      procedure, pass(self) :: end_tag       => dom_end_tag       !< An open tag is closed by its end tag.
      procedure, pass(self) :: data          => dom_data          !< Character data or other markup.
      procedure, pass(self) :: problem       => dom_problem       !< A problem of malformed input.
      procedure, pass(self) :: finish        => dom_finish        !< Complete the DOM at the source end.
      procedure, pass(self) :: flush         => dom_flush         !< Store the current character data into its owner.
endtype dom_builder
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

   subroutine parse(self, string, filename, iostat, iomsg, sanitize_attributes_value, chunk_size)
   !< Parse xml data from string or file.
   !< XML data is linearized, a DOM structured is used.
   !<
   !< @note Self data are free before trying to parse new xml data: all previously parsed data are lost.
   !< @note Parsing is tolerant: malformed input is parsed as far as possible. If *iostat* is passed, it returns 0 on
   !< success, the runtime I/O error code if the file cannot be read, *XML_MALFORMED* if the input is malformed; *iomsg*
   !< (unchanged on success) describes the error, for malformed input the first problem found with its line.
   !< @note Leading and trailing spaces of attribute values are trimmed (default), unless *sanitize_attributes_value* is
   !< false: then values are kept as in the source (XML data).
   !< @note A file is read in chunks of *chunk_size* characters (default 1 MiB): it is never loaded whole in memory.
   class(xml_file),        intent(inout) :: self     !< XML file.
   character(*), optional, intent(in)    :: string   !< String containing xml data.
   character(*), optional, intent(in)    :: filename !< File name containing xml data.
   integer(I4P), optional, intent(out)   :: iostat   !< IO status.
   character(*), optional, intent(inout) :: iomsg    !< IO message.
   logical,      optional, intent(in)    :: sanitize_attributes_value !< Trim attribute values spaces (default .true.).
   integer(I8P), optional, intent(in)    :: chunk_size !< Size of the chunks read from a file.
   character(len=:), allocatable         :: problem  !< First problem of malformed input.
   integer(I4P)                          :: iostat_  !< IO status, local variable.
   character(len=500)                    :: iomsg_   !< IO message, local variable.
   logical                               :: sanitize !< Trim attribute values spaces, local variable.
   integer(I8P)                          :: chunk_size_ !< Size of the chunks read from a file, local variable.

   sanitize = .true. ; if (present(sanitize_attributes_value)) sanitize = sanitize_attributes_value
   chunk_size_ = FILE_CHUNK_SIZE ; if (present(chunk_size)) chunk_size_ = max(1_I8P, chunk_size)
   iostat_ = 0
   iomsg_ = ''
   call self%free
   if (present(string)) then
      call self%parse_from_string(source_string=string, sanitize=sanitize, problem=problem)
   elseif (present(filename)) then
      call self%parse_from_file(filename=filename, sanitize=sanitize, chunk_size=chunk_size_, problem=problem, &
                                iostat=iostat_, iomsg=iomsg_)
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

   subroutine parse_from_file(self, filename, sanitize, chunk_size, problem, iostat, iomsg)
   !< Parse xml data from a file, read in chunks: the tokenizer drives the DOM builder, the file is never loaded whole.
   !<
   !< @note The first problem of malformed input is returned; *iostat* and *iomsg* report the file errors (the document is
   !< left empty).
   class(xml_file),               intent(inout) :: self       !< XML file handler.
   character(*),                  intent(in)    :: filename   !< File name.
   logical,                       intent(in)    :: sanitize   !< Trim leading and trailing spaces of attribute values.
   integer(I8P),                  intent(in)    :: chunk_size !< Size of the chunks read from the file.
   character(len=:), allocatable, intent(out)   :: problem    !< First problem of malformed input, unallocated if none.
   integer(I4P),                  intent(out)   :: iostat     !< IO status.
   character(*),                  intent(inout) :: iomsg      !< IO message.
   type(xml_tokenizer)                          :: tokenizer  !< Tokenizer.
   type(dom_builder)                            :: builder    !< DOM builder.
   character(len=:), allocatable                :: window     !< Characters not consumed yet, followed by the last chunk.
   character(len=:), allocatable                :: rest       !< Characters not consumed yet.
   integer(I8P)                                 :: file_size  !< File size.
   integer(I8P)                                 :: read_size  !< Characters read so far.
   integer(I8P)                                 :: piece      !< Size of the chunk to read.
   integer(I8P)                                 :: offset     !< Position of the character before the window.
   integer(I8P)                                 :: consumed   !< Characters consumed by the tokenizer.
   integer(I4P)                                 :: unit       !< File unit.
   logical                                      :: is_last    !< The window ends the file.

   call self%free
   builder%sanitize = sanitize
   open(newunit=unit, file=trim(adjustl(filename)), access='STREAM', form='UNFORMATTED', action='READ', status='OLD', &
        iostat=iostat, iomsg=iomsg)
   if (iostat/=0) return
   inquire(unit=unit, size=file_size)
   read_size = 0
   offset = 0
   rest = ''
   do
      piece = max(0_I8P, min(chunk_size, file_size - read_size))
      allocate(character(len=len(rest, kind=I8P)+piece) :: window)
      window(1:len(rest, kind=I8P)) = rest
      if (piece>0) then
         read(unit=unit, iostat=iostat, iomsg=iomsg) window(len(rest, kind=I8P)+1:)
         if (iostat/=0) then
            close(unit)
            return
         endif
         read_size = read_size + piece
      endif
      is_last = read_size>=file_size
      call tokenizer%feed(chars=window, offset=offset, is_last=is_last, builder=builder, consumed=consumed)
      offset = offset + consumed
      rest = window(consumed+1:)
      deallocate(window)
      if (is_last) exit
   enddo
   close(unit)
   call builder%finish
   call move_alloc(from=builder%doc%tag, to=self%tag)
   self%nt = builder%doc%nt
   if (allocated(builder%doc%prolog)) call move_alloc(from=builder%doc%prolog, to=self%prolog)
   if (allocated(builder%first_problem)) problem = located_in_file(filename=filename, pos=builder%problem_pos, &
                                                                   message=builder%first_problem, chunk_size=chunk_size)
   endsubroutine parse_from_file

   subroutine parse_from_string(self, source_string, sanitize, problem)
   !< Parse xml data from a string: the tokenizer drives the DOM builder. The first problem of malformed input is returned.
   class(xml_file),               intent(inout) :: self          !< XML file handler.
   character(*),                  intent(in)    :: source_string !< String containing xml data.
   logical,                       intent(in)    :: sanitize      !< Trim leading and trailing spaces of attribute values.
   character(len=:), allocatable, intent(out)   :: problem       !< First problem of malformed input, unallocated if none.
   type(xml_tokenizer)                          :: tokenizer     !< Tokenizer.
   type(dom_builder)                            :: builder       !< DOM builder.
   integer(I8P)                                 :: consumed      !< Characters consumed by the tokenizer.

   call self%free
   builder%sanitize = sanitize
   call tokenizer%feed(chars=source_string, offset=0_I8P, is_last=.true., builder=builder, consumed=consumed)
   call builder%finish
   call move_alloc(from=builder%doc%tag, to=self%tag)
   self%nt = builder%doc%nt
   if (allocated(builder%doc%prolog)) call move_alloc(from=builder%doc%prolog, to=self%prolog)
   if (allocated(builder%first_problem)) problem = located(source=source_string, pos=builder%problem_pos, &
                                                          message=builder%first_problem)
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

   ! dom_builder methods
   subroutine dom_start_tag(self, id, parent_id, level, name, start)
   !< A start tag begins: the text so far ends, a new tag is added.
   class(dom_builder), intent(inout) :: self      !< DOM builder.
   integer(I4P),       intent(in)    :: id        !< Tag ID (start tags count).
   integer(I4P),       intent(in)    :: parent_id !< Parent tag ID, 0 for a root tag.
   integer(I4P),       intent(in)    :: level     !< Tag level, 1 for a root tag.
   character(*),       intent(in)    :: name      !< Tag name.
   integer(I8P),       intent(in)    :: start     !< Position of `<`.
   type(xml_tag)                     :: tag       !< Empty tag, added and then set.

   if (self%doc%nt==0.and.self%prolog_n>0) then ! the prolog is what precedes the first tag, if not only blanks
      if (verify(self%prolog(1:self%prolog_n), BLANKS, kind=I8P)>0) self%doc%prolog = self%prolog(1:self%prolog_n)
   endif
   call self%flush(is_parent=.true.)
   call self%doc%add_tag(tag=tag)
   call self%doc%tag(self%doc%nt)%set(name=name, id=self%doc%nt, level=level, indent=(level-1)*2, parent_id=parent_id)
   endsubroutine dom_start_tag

   subroutine dom_attribute(self, id, name, value)
   !< An attribute of the current start tag.
   class(dom_builder), intent(inout) :: self  !< DOM builder.
   integer(I4P),       intent(in)    :: id    !< Tag ID.
   character(*),       intent(in)    :: name  !< Attribute name.
   character(*),       intent(in)    :: value !< Attribute value.

   call self%doc%tag(id)%set(attribute_name=name, attribute_value=value, sanitize_attributes_value=self%sanitize)
   endsubroutine dom_attribute

   subroutine dom_start_tag_end(self, id, start, open_end, is_self_closing)
   !< The current start tag is complete: the following character data are its text (its tail if self closing).
   class(dom_builder), intent(inout) :: self            !< DOM builder.
   integer(I4P),       intent(in)    :: id              !< Tag ID.
   integer(I8P),       intent(in)    :: start           !< Position of `<`.
   integer(I8P),       intent(in)    :: open_end        !< Position of `>`.
   logical,            intent(in)    :: is_self_closing !< The tag is self closing.

   if (is_self_closing) then
      call self%doc%tag(id)%set(pos=[start, open_end, -1_I8P], is_self_closing=.true.)
   else
      call self%doc%tag(id)%set(pos=[start, open_end, 0_I8P], is_self_closing=.false.)
   endif
   self%owner = id
   self%is_tail = is_self_closing
   endsubroutine dom_start_tag_end

   subroutine dom_end_tag(self, id, start, open_end, end_start)
   !< An open tag is closed: the text so far ends, the following character data are its tail.
   class(dom_builder), intent(inout) :: self      !< DOM builder.
   integer(I4P),       intent(in)    :: id        !< Tag ID.
   integer(I8P),       intent(in)    :: start     !< Position of the start tag `<`.
   integer(I8P),       intent(in)    :: open_end  !< Position of the start tag `>`.
   integer(I8P),       intent(in)    :: end_start !< Position of the end tag `<`.

   call self%flush(is_parent=.false.)
   call self%doc%tag(id)%set(pos=[start, open_end, end_start])
   self%owner = id
   self%is_tail = .true.
   endsubroutine dom_end_tag

   subroutine dom_data(self, kind, chars, first)
   !< Character data or other markup: part of the prolog before the first tag, of the owner text afterwards (CDATA,
   !< comments and PIs included, declarations and ignored markup excluded).
   class(dom_builder), intent(inout) :: self  !< DOM builder.
   integer(I4P),       intent(in)    :: kind  !< Data kind, DATA_*.
   character(*),       intent(in)    :: chars !< Characters, as in the source.
   integer(I8P),       intent(in)    :: first !< Position of the first character.

   if (self%doc%nt==0) call append(buffer=self%prolog, n=self%prolog_n, piece=chars)
   if (self%owner>0.and.kind>=DATA_TEXT.and.kind<=DATA_PI) call append(buffer=self%text, n=self%text_n, piece=chars)
   endsubroutine dom_data

   subroutine dom_problem(self, pos, message)
   !< A problem of malformed input: only the first one is kept.
   class(dom_builder), intent(inout) :: self    !< DOM builder.
   integer(I8P),       intent(in)    :: pos     !< Position of the problem.
   character(*),       intent(in)    :: message !< Problem description.

   if (allocated(self%first_problem)) return
   self%first_problem = message
   self%problem_pos = pos
   endsubroutine dom_problem

   subroutine dom_finish(self)
   !< Complete the DOM at the source end: store the last character data, build the children lists.
   class(dom_builder), intent(inout) :: self !< DOM builder.

   call self%flush(is_parent=.false.)
   call tree_build_children(tag=self%doc%tag, nt=self%doc%nt)
   endsubroutine dom_finish

   subroutine dom_flush(self, is_parent)
   !< Store the current character data into its owner tag, if any, and reset them.
   class(dom_builder), intent(inout) :: self      !< DOM builder.
   logical,            intent(in)    :: is_parent !< The text ends because the owner first child starts.

   if (self%owner>0) then
      if (self%text_n==0) then
         if (self%is_tail) then
            call self%doc%tag(self%owner)%set(tail='')
         else
            call self%doc%tag(self%owner)%set(content='')
         endif
      elseif (self%is_tail) then
         call self%doc%tag(self%owner)%set(tail=self%text(1:self%text_n))
      elseif (is_parent) then
         call self%doc%tag(self%owner)%set(content=self%text(1:self%text_n))
      else
         call self%doc%tag(self%owner)%set(content=trim(adjustl(self%text(1:self%text_n))))
      endif
   endif
   self%owner = 0
   self%is_tail = .false.
   self%text_n = 0
   endsubroutine dom_flush

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

   pure function starts_with_declaration(prolog) result(is_declaration)
   !< Check if a prolog starts with the XML declaration (`<?xml` followed by a blank, not a PI named `xml-...`).
   character(*), intent(in) :: prolog         !< Prolog.
   logical                  :: is_declaration !< Check result.

   is_declaration = .false.
   if (len(prolog, kind=I8P)>5) is_declaration = prolog(1:5)=='<?xml'.and.scan(prolog(6:6), BLANKS)>0
   endfunction starts_with_declaration

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

endmodule foxy_xml_file
