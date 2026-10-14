!< FoXy XML index class: scan a file once and read the content of its tags on demand.
module foxy_xml_index
!< FoXy XML index class: scan a file once and read the content of its tags on demand.
!<
!< The index stores, for each tag of a file, its name, attributes, hierarchy and the positions of its markup in the file,
!< never its content: the memory used does not depend on the data held in the file, which is read in chunks. The content
!< is read afterwards, on demand. The scan can stop after the start tag of a given tag (e.g. `AppendedData` of VTK files,
!< whose content is raw binary). The queries are the same as *xml_file* ones (*find*, *find_all*, *children*, ...).
use foxy_xml_entities, only : text_value
use foxy_xml_file, only : XML_MALFORMED
use foxy_xml_tag, only : xml_tag
use foxy_xml_tokenizer, only : xml_builder, xml_tokenizer, located_in_file
use foxy_xml_tree, only : tree_attribute, tree_attribute_text, tree_build_children, tree_children, tree_find_all, &
                          tree_level, tree_name, tree_parent
use foxy_xml_values, only : report, to_value, to_values, XML_NOT_FOUND
use penf

implicit none
private
public :: xml_index

integer(I8P), parameter :: FILE_CHUNK_SIZE  = 65536_I8P !< Default size of the chunks read from the file (64 KiB).
integer(I4P), parameter :: INITIAL_CAPACITY = 64_I4P    !< Initial capacity of the tags arrays, doubled when full.

type :: xml_index
   !< Index of the tags of an XML file.
   private
   type(xml_tag), allocatable    :: tag(:)         !< Tags (no content): name, attributes, hierarchy, positions.
   integer(I8P),  allocatable    :: last(:)        !< Position of the last character of each tag (`>`), 0 if unclosed.
   integer(I4P)                  :: nt=0_I4P       !< Number of tags.
   character(len=:), allocatable :: filename       !< Indexed file name.
   integer(I8P)                  :: stop_pos=0_I8P !< Position after the start tag where the scan stopped, 0 if none.
   contains
      ! public methods
      procedure, pass(self) :: attribute     !< Return the value of an attribute of the tag with a given ID.
      procedure, pass(self) :: children      !< Return the IDs of the children of the tag with a given ID.
      procedure, pass(self) :: content       !< Return the content of the tag with a given ID, read from the file.
      procedure, pass(self) :: content_range !< Return the positions in the file of the content of a tag.
      procedure, pass(self) :: find          !< Return the ID of the first tag matching a name or a path.
      procedure, pass(self) :: find_all      !< Return the IDs of all tags matching a name or a path.
      procedure, pass(self) :: free          !< Free dynamic memory.
      generic               :: get_attribute => &
                               get_attribute_I1P, get_attribute_I2P, get_attribute_I4P, get_attribute_I8P, &
                               get_attribute_R4P, get_attribute_R8P, get_attribute_logical, get_attribute_I1P_1, &
                               get_attribute_I2P_1, get_attribute_I4P_1, get_attribute_I8P_1, get_attribute_R4P_1, &
                               get_attribute_R8P_1 !< Get the value of an attribute as number(s) or logical.
      generic               :: get_content => &
                               get_content_I1P, get_content_I2P, get_content_I4P, get_content_I8P, &
                               get_content_R4P, get_content_R8P, get_content_logical, get_content_I1P_1, &
                               get_content_I2P_1, get_content_I4P_1, get_content_I8P_1, get_content_R4P_1, &
                               get_content_R8P_1 !< Get the content of a tag as number(s) or logical.
      procedure, pass(self) :: level         !< Return the level of the tag with a given ID.
      procedure, pass(self) :: name          !< Return the name of the tag with a given ID.
      procedure, pass(self) :: parent        !< Return the parent ID of the tag with a given ID.
      procedure, pass(self) :: scan          !< Scan a file, indexing its tags.
      procedure, pass(self) :: stop_position !< Return the position after the start tag where the scan stopped.
      procedure, pass(self) :: text_range    !< Return the positions in the file of the text of a tag.
      ! private methods
      procedure, pass(self), private :: attribute_text !< Return an attribute value, reporting a missing one.
      procedure, pass(self), private :: content_text !< Return a tag content, reporting a missing tag.
      procedure, pass(self), private :: get_attribute_I1P
      procedure, pass(self), private :: get_attribute_I2P
      procedure, pass(self), private :: get_attribute_I4P
      procedure, pass(self), private :: get_attribute_I8P
      procedure, pass(self), private :: get_attribute_R4P
      procedure, pass(self), private :: get_attribute_R8P
      procedure, pass(self), private :: get_attribute_logical
      procedure, pass(self), private :: get_attribute_I1P_1
      procedure, pass(self), private :: get_attribute_I2P_1
      procedure, pass(self), private :: get_attribute_I4P_1
      procedure, pass(self), private :: get_attribute_I8P_1
      procedure, pass(self), private :: get_attribute_R4P_1
      procedure, pass(self), private :: get_attribute_R8P_1
      procedure, pass(self), private :: get_content_I1P
      procedure, pass(self), private :: get_content_I2P
      procedure, pass(self), private :: get_content_I4P
      procedure, pass(self), private :: get_content_I8P
      procedure, pass(self), private :: get_content_R4P
      procedure, pass(self), private :: get_content_R8P
      procedure, pass(self), private :: get_content_logical
      procedure, pass(self), private :: get_content_I1P_1
      procedure, pass(self), private :: get_content_I2P_1
      procedure, pass(self), private :: get_content_I4P_1
      procedure, pass(self), private :: get_content_I8P_1
      procedure, pass(self), private :: get_content_R4P_1
      procedure, pass(self), private :: get_content_R8P_1
endtype xml_index

type, extends(xml_builder) :: index_builder
   !< Builder of the index, driven by the tokenizer: character data are not stored.
   type(xml_tag), allocatable    :: tag(:)            !< Tags.
   integer(I8P),  allocatable    :: last(:)           !< Position of the last character of each tag.
   integer(I4P)                  :: nt=0_I4P          !< Number of tags.
   logical                       :: sanitize=.true.   !< Trim leading and trailing spaces of attribute values.
   character(len=:), allocatable :: stop_at           !< Name of the tag after whose start tag the scan stops.
   integer(I8P)                  :: stop_pos=0_I8P    !< Position after the start tag where the scan stopped.
   character(len=:), allocatable :: first_problem     !< First problem of malformed input, unallocated if none.
   integer(I8P)                  :: problem_pos=0_I8P !< Position of the first problem.
   contains
      procedure, pass(self) :: start_tag     => index_start_tag     !< A start tag begins.
      procedure, pass(self) :: attribute     => index_attribute     !< An attribute of the current start tag.
      procedure, pass(self) :: start_tag_end => index_start_tag_end !< The current start tag is complete.
      procedure, pass(self) :: end_tag       => index_end_tag       !< An open tag is closed by its end tag.
      procedure, pass(self) :: data          => index_data          !< Character data or other markup: not stored.
      procedure, pass(self) :: problem       => index_problem       !< A problem of malformed input.
endtype index_builder

contains
   ! public methods
   pure function attribute(self, id, name) result(value)
   !< Return the value of the attribute named *name* of the tag with ID *id* (as *xml_file%attribute*).
   class(xml_index), intent(in)  :: self  !< XML index.
   integer(I4P),     intent(in)  :: id    !< Tag ID.
   character(*),     intent(in)  :: name  !< Attribute name.
   character(len=:), allocatable :: value !< Attribute value, empty if the tag or the attribute does not exist.

   value = tree_attribute(tag=self%tag, nt=self%nt, id=id, name=name)
   endfunction attribute

   pure function children(self, id) result(ids)
   !< Return the IDs of the direct children of the tag with ID *id*, in document order (0: the root tags).
   class(xml_index), intent(in) :: self   !< XML index.
   integer(I4P),     intent(in) :: id     !< Tag ID.
   integer(I4P), allocatable    :: ids(:) !< Children IDs, empty if there are none.

   ids = tree_children(tag=self%tag, nt=self%nt, id=id)
   endfunction children

   function content(self, id, iostat, iomsg) result(value)
   !< Return the content of the tag with ID *id*, read from the file (as *xml_file%content*: the tag text plus its
   !< children tails, layout blanks stripped, references decoded, CDATA literal, comments and PIs removed).
   !<
   !< @note An empty string is returned if the tag does not exist, is self closing or unclosed (e.g. after a stopped
   !< scan), or the file cannot be read (reported by *iostat* and *iomsg*, if passed).
   class(xml_index),       intent(in)    :: self    !< XML index.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: value   !< Content.
   character(len=:), allocatable         :: raw     !< Direct text, raw.
   integer(I8P)                          :: first   !< First position of the content.
   integer(I8P)                          :: last    !< Last position of the content.
   integer(I8P)                          :: cursor  !< First position of the next text segment.
   integer(I8P)                          :: n       !< Length of the direct text.
   integer(I8P)                          :: pos(3)  !< Child positions.
   integer(I4P)                          :: unit    !< File unit.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=500)                    :: iomsg_  !< IO message, local variable.
   integer(I4P)                          :: c       !< Counter.

   value = ''
   iostat_ = 0
   call self%content_range(id=id, first=first, last=last)
   if (last>=first) then
      open(newunit=unit, file=self%filename, access='STREAM', form='UNFORMATTED', action='READ', status='OLD', &
           iostat=iostat_, iomsg=iomsg_)
      if (iostat_==0) then
         ! the direct text: the content without the children (their tails stay)
         allocate(character(len=last-first+1) :: raw)
         n = 0
         cursor = first
         do c=1, self%tag(id)%children_number
            pos = self%tag(self%tag(id)%child_id(c))%get_pos()
            call read_segment(segment_last=pos(1)-1)
            if (iostat_/=0) exit
            if (self%last(self%tag(id)%child_id(c))>0) then
               cursor = self%last(self%tag(id)%child_id(c)) + 1
            else
               cursor = last + 1 ! unclosed child: it holds the rest
            endif
         enddo
         if (iostat_==0) call read_segment(segment_last=last)
         close(unit)
         if (iostat_==0) value = text_value(raw(1:n))
      endif
   endif
   if (present(iostat)) iostat = iostat_
   if (present(iomsg).and.iostat_/=0) iomsg = iomsg_
   contains
      subroutine read_segment(segment_last)
      !< Read the text segment from *cursor* to *segment_last*, appending it to the direct text.
      integer(I8P), intent(in) :: segment_last !< Last position of the segment.

      if (segment_last<cursor) return
      read(unit=unit, pos=cursor, iostat=iostat_, iomsg=iomsg_) raw(n+1:n+segment_last-cursor+1)
      n = n + segment_last - cursor + 1
      endsubroutine read_segment
   endfunction content

   elemental subroutine content_range(self, id, first, last)
   !< Return the positions in the file of the content of the tag with ID *id* (between its start and end tags, children
   !< included); *last* < *first* if it is empty (also for a self closing or unclosed tag, or if the tag does not exist).
   class(xml_index), intent(in)  :: self   !< XML index.
   integer(I4P),     intent(in)  :: id     !< Tag ID.
   integer(I8P),     intent(out) :: first  !< First position.
   integer(I8P),     intent(out) :: last   !< Last position.
   integer(I8P)                  :: pos(3) !< Tag positions.

   first = 1
   last = 0
   if (id<1.or.id>self%nt) return
   pos = self%tag(id)%get_pos()
   first = pos(2) + 1
   if (pos(3)>0) then
      last = pos(3) - 1
   else
      last = first - 1
   endif
   endsubroutine content_range

   pure function find(self, name, path, parent) result(id)
   !< Return the ID of the first tag (in document order) matching *name* or *path*, 0 if there is none.
   !<
   !< @note See *xml_file%find_all* for the matching rules.
   class(xml_index), intent(in)           :: self   !< XML index.
   character(*),     intent(in), optional :: name   !< Tag name.
   character(*),     intent(in), optional :: path   !< Tags path, e.g. `Piece/PointData/DataArray`.
   integer(I4P),     intent(in), optional :: parent !< Parent tag ID, 0 for the document root.
   integer(I4P)                           :: id     !< Tag ID.
   integer(I4P), allocatable              :: ids(:) !< Matching tags IDs.

   ids = tree_find_all(tag=self%tag, nt=self%nt, name=name, path=path, parent=parent)
   id = 0_I4P
   if (size(ids)>0) id = ids(1)
   endfunction find

   pure function find_all(self, name, path, parent) result(ids)
   !< Return the IDs of all tags (in document order) matching *name* or *path* (see *xml_file%find_all*).
   class(xml_index), intent(in)           :: self   !< XML index.
   character(*),     intent(in), optional :: name   !< Tag name.
   character(*),     intent(in), optional :: path   !< Tags path, e.g. `Piece/PointData/DataArray`.
   integer(I4P),     intent(in), optional :: parent !< Parent tag ID, 0 for the document root.
   integer(I4P), allocatable              :: ids(:) !< Matching tags IDs, empty if there are none.

   ids = tree_find_all(tag=self%tag, nt=self%nt, name=name, path=path, parent=parent)
   endfunction find_all

   elemental subroutine free(self)
   !< Free dynamic memory.
   class(xml_index), intent(inout) :: self !< XML index.

   if (allocated(self%tag)) deallocate(self%tag)
   if (allocated(self%last)) deallocate(self%last)
   if (allocated(self%filename)) deallocate(self%filename)
   self%nt = 0_I4P
   self%stop_pos = 0_I8P
   endsubroutine free

   pure function level(self, id) result(level_)
   !< Return the level of the tag with ID *id* (1 for a root tag), 0 if it does not exist.
   class(xml_index), intent(in) :: self   !< XML index.
   integer(I4P),     intent(in) :: id     !< Tag ID.
   integer(I4P)                 :: level_ !< Tag level.

   level_ = tree_level(tag=self%tag, nt=self%nt, id=id)
   endfunction level

   pure function name(self, id) result(name_)
   !< Return the name of the tag with ID *id*, an empty string if it does not exist.
   class(xml_index), intent(in)  :: self  !< XML index.
   integer(I4P),     intent(in)  :: id    !< Tag ID.
   character(len=:), allocatable :: name_ !< Tag name.

   name_ = tree_name(tag=self%tag, nt=self%nt, id=id)
   endfunction name

   pure function parent(self, id) result(parent_)
   !< Return the parent ID of the tag with ID *id* (0 for a root tag or if the tag does not exist).
   class(xml_index), intent(in) :: self    !< XML index.
   integer(I4P),     intent(in) :: id      !< Tag ID.
   integer(I4P)                 :: parent_ !< Parent ID.

   parent_ = tree_parent(tag=self%tag, nt=self%nt, id=id)
   endfunction parent

   subroutine scan(self, filename, stop_at, chunk_size, iostat, iomsg, sanitize_attributes_value)
   !< Scan a file, indexing its tags; the file is read in chunks (default 64 KiB), its content is not stored.
   !<
   !< @note If *stop_at* is passed, the scan stops after the start tag of the first tag with that name (the tags still
   !< open stay unclosed, without content); *stop_position* returns the position after it.
   !< @note As *xml_file%parse*: the scan is tolerant; *iostat* returns 0 on success, the runtime I/O error code if the
   !< file cannot be read, *XML_MALFORMED* if the input is malformed (*iomsg*, unchanged on success, describes the first
   !< problem with its line); attribute values are trimmed unless *sanitize_attributes_value* is false.
   class(xml_index),       intent(inout) :: self        !< XML index.
   character(*),           intent(in)    :: filename    !< File name.
   character(*), optional, intent(in)    :: stop_at     !< Name of the tag after whose start tag the scan stops.
   integer(I8P), optional, intent(in)    :: chunk_size  !< Size of the chunks read from the file.
   integer(I4P), optional, intent(out)   :: iostat      !< IO status.
   character(*), optional, intent(inout) :: iomsg       !< IO message.
   logical,      optional, intent(in)    :: sanitize_attributes_value !< Trim attribute values spaces (default .true.).
   type(xml_tokenizer)                   :: tokenizer   !< Tokenizer.
   type(index_builder)                   :: builder     !< Index builder.
   character(len=:), allocatable         :: window      !< Characters not consumed yet, followed by the last chunk.
   character(len=:), allocatable         :: rest        !< Characters not consumed yet.
   integer(I8P)                          :: chunk_size_ !< Size of the chunks read from the file, local variable.
   integer(I8P)                          :: file_size   !< File size.
   integer(I8P)                          :: read_size   !< Characters read so far.
   integer(I8P)                          :: piece       !< Size of the chunk to read.
   integer(I8P)                          :: offset      !< Position of the character before the window.
   integer(I8P)                          :: consumed    !< Characters consumed by the tokenizer.
   integer(I4P)                          :: unit        !< File unit.
   integer(I4P)                          :: iostat_     !< IO status, local variable.
   character(len=500)                    :: iomsg_      !< IO message, local variable.
   logical                               :: is_last     !< The window ends the file.

   call self%free
   chunk_size_ = FILE_CHUNK_SIZE ; if (present(chunk_size)) chunk_size_ = max(1_I8P, chunk_size)
   if (present(sanitize_attributes_value)) builder%sanitize = sanitize_attributes_value
   if (present(stop_at)) builder%stop_at = stop_at
   open(newunit=unit, file=trim(adjustl(filename)), access='STREAM', form='UNFORMATTED', action='READ', status='OLD', &
        iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) then
      inquire(unit=unit, size=file_size)
      read_size = 0
      offset = 0
      rest = ''
      do
         piece = max(0_I8P, min(chunk_size_, file_size - read_size))
         allocate(character(len=len(rest, kind=I8P)+piece) :: window)
         window(1:len(rest, kind=I8P)) = rest
         if (piece>0) then
            read(unit=unit, iostat=iostat_, iomsg=iomsg_) window(len(rest, kind=I8P)+1:)
            if (iostat_/=0) exit
            read_size = read_size + piece
         endif
         is_last = read_size>=file_size
         call tokenizer%feed(chars=window, offset=offset, is_last=is_last, builder=builder, consumed=consumed)
         offset = offset + consumed
         rest = window(consumed+1:)
         deallocate(window)
         if (is_last.or.builder%is_stopped) exit
      enddo
      close(unit)
   endif
   if (iostat_==0) then
      if (allocated(builder%tag)) then
         call move_alloc(from=builder%tag, to=self%tag)
         call move_alloc(from=builder%last, to=self%last)
      endif
      self%nt = builder%nt
      call tree_build_children(tag=self%tag, nt=self%nt)
      self%filename = trim(adjustl(filename))
      self%stop_pos = builder%stop_pos
      if (allocated(builder%first_problem)) then
         iostat_ = XML_MALFORMED
         iomsg_ = located_in_file(filename=filename, pos=builder%problem_pos, message=builder%first_problem, &
                                  chunk_size=chunk_size_)
      endif
   endif
   if (present(iostat)) iostat = iostat_
   if (present(iomsg).and.iostat_/=0) iomsg = iomsg_
   endsubroutine scan

   elemental function stop_position(self) result(pos)
   !< Return the position in the file after the start tag where the scan stopped (*stop_at*), 0 if it did not stop.
   class(xml_index), intent(in) :: self !< XML index.
   integer(I8P)                 :: pos  !< Position.

   pos = self%stop_pos
   endfunction stop_position

   elemental subroutine text_range(self, id, first, last)
   !< Return the positions in the file of the text of the tag with ID *id*: from its start tag to its first child (or to
   !< its end tag); *last* < *first* if it is empty (also for a self closing or unclosed tag, or if the tag does not exist).
   class(xml_index), intent(in)  :: self   !< XML index.
   integer(I4P),     intent(in)  :: id     !< Tag ID.
   integer(I8P),     intent(out) :: first  !< First position.
   integer(I8P),     intent(out) :: last   !< Last position.
   integer(I8P)                  :: pos(3) !< First child positions.

   call self%content_range(id=id, first=first, last=last)
   if (last<first) return
   if (self%tag(id)%children_number>0) then
      pos = self%tag(self%tag(id)%child_id(1))%get_pos()
      last = pos(1) - 1
   endif
   endsubroutine text_range

   ! typed accessors
   subroutine attribute_text(self, id, name, text, iostat, iomsg)
   !< Return the value of the attribute named *name* of the tag with ID *id*; *iostat* is *XML_NOT_FOUND* if the tag or the
   !< attribute does not exist.
   class(xml_index),              intent(in)  :: self   !< XML index.
   integer(I4P),                  intent(in)  :: id     !< Tag ID.
   character(*),                  intent(in)  :: name   !< Attribute name.
   character(len=:), allocatable, intent(out) :: text   !< Attribute value.
   integer(I4P),                  intent(out) :: iostat !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg  !< IO message.

   call tree_attribute_text(tag=self%tag, nt=self%nt, id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine attribute_text

   subroutine content_text(self, id, text, iostat, iomsg)
   !< Return the content of the tag with ID *id*, read from the file (see *content*); *iostat* is *XML_NOT_FOUND* if the
   !< tag does not exist, the runtime one if the file cannot be read.
   class(xml_index),              intent(in)  :: self    !< XML index.
   integer(I4P),                  intent(in)  :: id      !< Tag ID.
   character(len=:), allocatable, intent(out) :: text    !< Tag content.
   integer(I4P),                  intent(out) :: iostat  !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg   !< IO message.
   character(len=500)                         :: iomsg_  !< IO message, local variable.

   iostat = 0
   iomsg = ''
   if (id>=1.and.id<=self%nt) then
      text = self%content(id=id, iostat=iostat, iomsg=iomsg_)
      if (iostat/=0) iomsg = trim(iomsg_)
   else
      text = ''
      iostat = XML_NOT_FOUND
      iomsg = 'no tag with ID '//trim(str(id, no_sign=id>=0))
   endif
   endsubroutine content_text

   subroutine get_attribute_I1P(self, id, name, value, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a integer(I1P) value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   character(*),           intent(in)    :: name      !< Attribute name.
   integer(I1P),          intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%attribute_text(id=id, name=name, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in attribute "'//name//'" of tag "'//self%name(id)//'"')
   endsubroutine get_attribute_I1P

   subroutine get_attribute_I2P(self, id, name, value, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a integer(I2P) value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   character(*),           intent(in)    :: name      !< Attribute name.
   integer(I2P),          intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%attribute_text(id=id, name=name, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in attribute "'//name//'" of tag "'//self%name(id)//'"')
   endsubroutine get_attribute_I2P

   subroutine get_attribute_I4P(self, id, name, value, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a integer(I4P) value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   character(*),           intent(in)    :: name      !< Attribute name.
   integer(I4P),          intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%attribute_text(id=id, name=name, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in attribute "'//name//'" of tag "'//self%name(id)//'"')
   endsubroutine get_attribute_I4P

   subroutine get_attribute_I8P(self, id, name, value, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a integer(I8P) value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   character(*),           intent(in)    :: name      !< Attribute name.
   integer(I8P),          intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%attribute_text(id=id, name=name, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in attribute "'//name//'" of tag "'//self%name(id)//'"')
   endsubroutine get_attribute_I8P

   subroutine get_attribute_R4P(self, id, name, value, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a real(R4P) value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   character(*),           intent(in)    :: name      !< Attribute name.
   real(R4P),             intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%attribute_text(id=id, name=name, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in attribute "'//name//'" of tag "'//self%name(id)//'"')
   endsubroutine get_attribute_R4P

   subroutine get_attribute_R8P(self, id, name, value, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a real(R8P) value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   character(*),           intent(in)    :: name      !< Attribute name.
   real(R8P),             intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%attribute_text(id=id, name=name, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in attribute "'//name//'" of tag "'//self%name(id)//'"')
   endsubroutine get_attribute_R8P

   subroutine get_attribute_logical(self, id, name, value, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a logical value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   character(*),           intent(in)    :: name      !< Attribute name.
   logical,               intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%attribute_text(id=id, name=name, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in attribute "'//name//'" of tag "'//self%name(id)//'"')
   endsubroutine get_attribute_logical

   subroutine get_attribute_I1P_1(self, id, name, values, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a list of integer(I1P) values (blank separated).
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   character(*),           intent(in)    :: name      !< Attribute name.
   integer(I1P), allocatable, intent(out)   :: values(:) !< Values, empty on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%attribute_text(id=id, name=name, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_values(text=text, values=values, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in attribute "'//name//'" of tag "'//self%name(id)//'"')
   endsubroutine get_attribute_I1P_1

   subroutine get_attribute_I2P_1(self, id, name, values, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a list of integer(I2P) values (blank separated).
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   character(*),           intent(in)    :: name      !< Attribute name.
   integer(I2P), allocatable, intent(out)   :: values(:) !< Values, empty on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%attribute_text(id=id, name=name, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_values(text=text, values=values, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in attribute "'//name//'" of tag "'//self%name(id)//'"')
   endsubroutine get_attribute_I2P_1

   subroutine get_attribute_I4P_1(self, id, name, values, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a list of integer(I4P) values (blank separated).
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   character(*),           intent(in)    :: name      !< Attribute name.
   integer(I4P), allocatable, intent(out)   :: values(:) !< Values, empty on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%attribute_text(id=id, name=name, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_values(text=text, values=values, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in attribute "'//name//'" of tag "'//self%name(id)//'"')
   endsubroutine get_attribute_I4P_1

   subroutine get_attribute_I8P_1(self, id, name, values, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a list of integer(I8P) values (blank separated).
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   character(*),           intent(in)    :: name      !< Attribute name.
   integer(I8P), allocatable, intent(out)   :: values(:) !< Values, empty on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%attribute_text(id=id, name=name, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_values(text=text, values=values, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in attribute "'//name//'" of tag "'//self%name(id)//'"')
   endsubroutine get_attribute_I8P_1

   subroutine get_attribute_R4P_1(self, id, name, values, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a list of real(R4P) values (blank separated).
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   character(*),           intent(in)    :: name      !< Attribute name.
   real(R4P), allocatable, intent(out)   :: values(:) !< Values, empty on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%attribute_text(id=id, name=name, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_values(text=text, values=values, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in attribute "'//name//'" of tag "'//self%name(id)//'"')
   endsubroutine get_attribute_R4P_1

   subroutine get_attribute_R8P_1(self, id, name, values, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a list of real(R8P) values (blank separated).
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   character(*),           intent(in)    :: name      !< Attribute name.
   real(R8P), allocatable, intent(out)   :: values(:) !< Values, empty on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%attribute_text(id=id, name=name, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_values(text=text, values=values, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in attribute "'//name//'" of tag "'//self%name(id)//'"')
   endsubroutine get_attribute_R8P_1

   subroutine get_content_I1P(self, id, value, iostat, iomsg)
   !< Get the content of the tag with ID *id* as a integer(I1P) value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   integer(I1P),          intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%content_text(id=id, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in the content of tag "'//self%name(id)//'"')
   endsubroutine get_content_I1P

   subroutine get_content_I2P(self, id, value, iostat, iomsg)
   !< Get the content of the tag with ID *id* as a integer(I2P) value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   integer(I2P),          intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%content_text(id=id, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in the content of tag "'//self%name(id)//'"')
   endsubroutine get_content_I2P

   subroutine get_content_I4P(self, id, value, iostat, iomsg)
   !< Get the content of the tag with ID *id* as a integer(I4P) value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   integer(I4P),          intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%content_text(id=id, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in the content of tag "'//self%name(id)//'"')
   endsubroutine get_content_I4P

   subroutine get_content_I8P(self, id, value, iostat, iomsg)
   !< Get the content of the tag with ID *id* as a integer(I8P) value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   integer(I8P),          intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%content_text(id=id, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in the content of tag "'//self%name(id)//'"')
   endsubroutine get_content_I8P

   subroutine get_content_R4P(self, id, value, iostat, iomsg)
   !< Get the content of the tag with ID *id* as a real(R4P) value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   real(R4P),             intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%content_text(id=id, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in the content of tag "'//self%name(id)//'"')
   endsubroutine get_content_R4P

   subroutine get_content_R8P(self, id, value, iostat, iomsg)
   !< Get the content of the tag with ID *id* as a real(R8P) value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   real(R8P),             intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%content_text(id=id, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in the content of tag "'//self%name(id)//'"')
   endsubroutine get_content_R8P

   subroutine get_content_logical(self, id, value, iostat, iomsg)
   !< Get the content of the tag with ID *id* as a logical value.
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   logical,               intent(inout) :: value     !< Value, unchanged on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%content_text(id=id, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_value(text=text, value=value, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in the content of tag "'//self%name(id)//'"')
   endsubroutine get_content_logical

   subroutine get_content_I1P_1(self, id, values, iostat, iomsg)
   !< Get the content of the tag with ID *id* as a list of integer(I1P) values (blank separated).
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   integer(I1P), allocatable, intent(out)   :: values(:) !< Values, empty on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%content_text(id=id, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_values(text=text, values=values, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in the content of tag "'//self%name(id)//'"')
   endsubroutine get_content_I1P_1

   subroutine get_content_I2P_1(self, id, values, iostat, iomsg)
   !< Get the content of the tag with ID *id* as a list of integer(I2P) values (blank separated).
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   integer(I2P), allocatable, intent(out)   :: values(:) !< Values, empty on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%content_text(id=id, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_values(text=text, values=values, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in the content of tag "'//self%name(id)//'"')
   endsubroutine get_content_I2P_1

   subroutine get_content_I4P_1(self, id, values, iostat, iomsg)
   !< Get the content of the tag with ID *id* as a list of integer(I4P) values (blank separated).
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   integer(I4P), allocatable, intent(out)   :: values(:) !< Values, empty on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%content_text(id=id, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_values(text=text, values=values, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in the content of tag "'//self%name(id)//'"')
   endsubroutine get_content_I4P_1

   subroutine get_content_I8P_1(self, id, values, iostat, iomsg)
   !< Get the content of the tag with ID *id* as a list of integer(I8P) values (blank separated).
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   integer(I8P), allocatable, intent(out)   :: values(:) !< Values, empty on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%content_text(id=id, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_values(text=text, values=values, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in the content of tag "'//self%name(id)//'"')
   endsubroutine get_content_I8P_1

   subroutine get_content_R4P_1(self, id, values, iostat, iomsg)
   !< Get the content of the tag with ID *id* as a list of real(R4P) values (blank separated).
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   real(R4P), allocatable, intent(out)   :: values(:) !< Values, empty on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%content_text(id=id, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_values(text=text, values=values, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in the content of tag "'//self%name(id)//'"')
   endsubroutine get_content_R4P_1

   subroutine get_content_R8P_1(self, id, values, iostat, iomsg)
   !< Get the content of the tag with ID *id* as a list of real(R8P) values (blank separated).
   class(xml_index),      intent(in)    :: self      !< XML index.
   integer(I4P),           intent(in)    :: id        !< Tag ID.
   real(R8P), allocatable, intent(out)   :: values(:) !< Values, empty on error.
   integer(I4P), optional, intent(out)   :: iostat    !< IO status.
   character(*), optional, intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable         :: text      !< Text to convert.
   integer(I4P)                          :: iostat_   !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_    !< IO message, local variable.

   call self%content_text(id=id, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) call to_values(text=text, values=values, iostat=iostat_, iomsg=iomsg_)
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg, &
               context=' in the content of tag "'//self%name(id)//'"')
   endsubroutine get_content_R8P_1

   ! index_builder methods
   pure subroutine index_start_tag(self, id, parent_id, level, name, start)
   !< A start tag begins: a new tag is added.
   class(index_builder), intent(inout) :: self          !< Index builder.
   integer(I4P),         intent(in)    :: id            !< Tag ID (start tags count).
   integer(I4P),         intent(in)    :: parent_id     !< Parent tag ID, 0 for a root tag.
   integer(I4P),         intent(in)    :: level         !< Tag level, 1 for a root tag.
   character(*),         intent(in)    :: name          !< Tag name.
   integer(I8P),         intent(in)    :: start         !< Position of `<`.
   type(xml_tag),        allocatable   :: grown_tag(:)  !< Grown tags.
   integer(I8P),         allocatable   :: grown_last(:) !< Grown last positions.

   if (.not.allocated(self%tag)) then
      allocate(self%tag(INITIAL_CAPACITY), self%last(INITIAL_CAPACITY))
   elseif (self%nt==size(self%tag, dim=1)) then
      allocate(grown_tag(2*self%nt), grown_last(2*self%nt))
      grown_tag(1:self%nt) = self%tag(1:self%nt)
      grown_last(1:self%nt) = self%last(1:self%nt)
      call move_alloc(from=grown_tag, to=self%tag)
      call move_alloc(from=grown_last, to=self%last)
   endif
   self%nt = self%nt + 1
   self%last(self%nt) = 0
   call self%tag(self%nt)%set(name=name, id=id, level=level, indent=(level-1)*2, parent_id=parent_id, &
                              pos=[start, 0_I8P, 0_I8P])
   endsubroutine index_start_tag

   pure subroutine index_attribute(self, id, name, value)
   !< An attribute of the current start tag.
   class(index_builder), intent(inout) :: self  !< Index builder.
   integer(I4P),         intent(in)    :: id    !< Tag ID.
   character(*),         intent(in)    :: name  !< Attribute name.
   character(*),         intent(in)    :: value !< Attribute value.

   call self%tag(id)%set(attribute_name=name, attribute_value=value, sanitize_attributes_value=self%sanitize)
   endsubroutine index_attribute

   pure subroutine index_start_tag_end(self, id, start, open_end, is_self_closing)
   !< The current start tag is complete; the scan stops here if the tag is the *stop_at* one.
   class(index_builder), intent(inout) :: self            !< Index builder.
   integer(I4P),         intent(in)    :: id              !< Tag ID.
   integer(I8P),         intent(in)    :: start           !< Position of `<`.
   integer(I8P),         intent(in)    :: open_end        !< Position of `>`.
   logical,              intent(in)    :: is_self_closing !< The tag is self closing.

   if (is_self_closing) then
      call self%tag(id)%set(pos=[start, open_end, -1_I8P], is_self_closing=.true.)
      self%last(id) = open_end
   else
      call self%tag(id)%set(pos=[start, open_end, 0_I8P], is_self_closing=.false.)
   endif
   if (allocated(self%stop_at)) then
      if (self%tag(id)%name()==self%stop_at) then
         self%is_stopped = .true.
         self%stop_pos = open_end + 1
      endif
   endif
   endsubroutine index_start_tag_end

   pure subroutine index_end_tag(self, id, start, open_end, end_start, end_end)
   !< An open tag is closed by its end tag.
   class(index_builder), intent(inout) :: self      !< Index builder.
   integer(I4P),         intent(in)    :: id        !< Tag ID.
   integer(I8P),         intent(in)    :: start     !< Position of the start tag `<`.
   integer(I8P),         intent(in)    :: open_end  !< Position of the start tag `>`.
   integer(I8P),         intent(in)    :: end_start !< Position of the end tag `<`.
   integer(I8P),         intent(in)    :: end_end   !< Position of the end tag `>`.

   call self%tag(id)%set(pos=[start, open_end, end_start])
   self%last(id) = end_end
   endsubroutine index_end_tag

   pure subroutine index_data(self, kind, chars, first)
   !< Character data or other markup: not stored (the content is read on demand).
   class(index_builder), intent(inout) :: self  !< Index builder.
   integer(I4P),         intent(in)    :: kind  !< Data kind, DATA_*.
   character(*),         intent(in)    :: chars !< Characters, as in the source.
   integer(I8P),         intent(in)    :: first !< Position of the first character.
   endsubroutine index_data

   pure subroutine index_problem(self, pos, message)
   !< A problem of malformed input: only the first one is kept.
   class(index_builder), intent(inout) :: self    !< Index builder.
   integer(I8P),         intent(in)    :: pos     !< Position of the problem.
   character(*),         intent(in)    :: message !< Problem description.

   if (allocated(self%first_problem)) return
   self%first_problem = message
   self%problem_pos = pos
   endsubroutine index_problem
endmodule foxy_xml_index
