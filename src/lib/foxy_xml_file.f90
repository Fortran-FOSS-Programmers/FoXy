!< FoXy XML file class.
module foxy_xml_file
!< FoXy XML file class.
use foxy_xml_entities, only : is_name, text_value, without_markup, xml_escape
use foxy_xml_source, only : DETECT_LEN, MAX_PIECE, decode_piece, decoded, detect_encoding, detect_file_encoding, &
                            source_encoding, with_utf8_declaration
use foxy_xml_tag, only : xml_tag
use foxy_xml_tokenizer, only : xml_builder, xml_tokenizer, located, located_in_file, DATA_TEXT, DATA_PI
use foxy_xml_tree, only : tree_attribute, tree_attribute_name, tree_attribute_text, tree_attributes_number, &
                          tree_build_children, tree_children, tree_find, tree_find_all, tree_level, tree_local_name, &
                          tree_matching, tree_select, regex_matches, tags_indexes, tree_name, &
                          tree_namespace, tree_parent, tree_prefix
use foxy_xml_values, only : report, to_text, to_value, to_values, XML_NOT_FOUND
use penf
use stringifor, only : regex

implicit none
private

integer(I4P), parameter, public :: XML_MALFORMED = 9001_I4P !< *iostat* of parse for malformed XML input.
integer(I4P), parameter :: INITIAL_CAPACITY   = 64_I4P   !< Initial capacity of the tags array, doubled when full.
integer(I8P), parameter :: INITIAL_BUFFER_LEN = 4096_I8P !< Initial length of the stringify buffer, doubled when full.
integer(I8P), parameter :: FILE_CHUNK_SIZE = 1048576_I8P !< Default size of the chunks read from a file (1 MiB).
character(*), parameter :: BLANKS   = ' '//achar(9)//achar(10)//achar(13) !< XML blanks: space, tab, new line, CR.
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
      procedure, pass(self) :: attribute_name    !< Return the name of the attribute with a given index of a tag.
      procedure, pass(self) :: attributes_number !< Return the number of attributes of the tag with a given ID.
      procedure, pass(self) :: children   !< Return the IDs of the children of the tag with a given ID.
      generic               :: content => &
                               content_by_name, &
                               content_by_id      !< Return tag content, by tag name or ID.
      procedure, pass(self) :: delete_attribute !< Delete an attribute of the tag with a given ID.
      procedure, pass(self) :: delete_tag !< Delete a tag (by name or ID) with its subtree.
      procedure, pass(self) :: find       !< Return the ID of the first tag matching a name or a path.
      procedure, pass(self) :: find_all   !< Return the IDs of all tags matching a name or a path.
      procedure, pass(self) :: select     !< Return the IDs of the tags selected by a path expression.
      procedure, pass(self) :: free       !< Free dynamic memory.
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
      procedure, pass(self) :: level      !< Return the level of the tag with a given ID.
      procedure, pass(self) :: local_name !< Return the local name of the tag with a given ID.
      procedure, pass(self) :: matching   !< Filter tags by a regular expression (name, content, attribute).
      procedure, pass(self) :: name       !< Return the name of the tag with a given ID.
      procedure, pass(self) :: namespace  !< Return the namespace of the tag with a given ID.
      procedure, pass(self) :: parent     !< Return the parent ID of the tag with a given ID.
      procedure, pass(self) :: prefix     !< Return the name prefix of the tag with a given ID.
      procedure, pass(self) :: parse      !< Parse xml file.
      procedure, pass(self) :: save       !< Save the whole file data into a file.
      generic               :: set_attribute => &
                               set_attribute_character, &
                               set_attribute_I1P, &
                               set_attribute_I2P, &
                               set_attribute_I4P, &
                               set_attribute_I8P, &
                               set_attribute_R4P, &
                               set_attribute_R8P, &
                               set_attribute_logical, &
                               set_attribute_I1P_1, &
                               set_attribute_I2P_1, &
                               set_attribute_I4P_1, &
                               set_attribute_I8P_1, &
                               set_attribute_R4P_1, &
                               set_attribute_R8P_1 !< Set an attribute of a tag (text, number, list).
      generic               :: set_content => &
                               set_content_character, &
                               set_content_I1P, &
                               set_content_I2P, &
                               set_content_I4P, &
                               set_content_I8P, &
                               set_content_R4P, &
                               set_content_R8P, &
                               set_content_logical, &
                               set_content_I1P_1, &
                               set_content_I2P_1, &
                               set_content_I4P_1, &
                               set_content_I8P_1, &
                               set_content_R4P_1, &
                               set_content_R8P_1 !< Set the content of a tag (text, number, list).
      procedure, pass(self) :: set_name   !< Rename the tag with a given ID.
      procedure, pass(self) :: stringify  !< Convert the whole file data into a string.
      procedure, pass(self) :: tags_number !< Return the number of tags.
      ! private methods
      procedure, pass(self), private :: append_inline       !< Append a tag with its subtree, without layout.
      procedure, pass(self), private :: set_attribute_character
      procedure, pass(self), private :: set_attribute_I1P
      procedure, pass(self), private :: set_attribute_I2P
      procedure, pass(self), private :: set_attribute_I4P
      procedure, pass(self), private :: set_attribute_I8P
      procedure, pass(self), private :: set_attribute_R4P
      procedure, pass(self), private :: set_attribute_R8P
      procedure, pass(self), private :: set_attribute_logical
      procedure, pass(self), private :: set_attribute_I1P_1
      procedure, pass(self), private :: set_attribute_I2P_1
      procedure, pass(self), private :: set_attribute_I4P_1
      procedure, pass(self), private :: set_attribute_I8P_1
      procedure, pass(self), private :: set_attribute_R4P_1
      procedure, pass(self), private :: set_attribute_R8P_1
      procedure, pass(self), private :: set_content_character
      procedure, pass(self), private :: set_content_I1P
      procedure, pass(self), private :: set_content_I2P
      procedure, pass(self), private :: set_content_I4P
      procedure, pass(self), private :: set_content_I8P
      procedure, pass(self), private :: set_content_R4P
      procedure, pass(self), private :: set_content_R8P
      procedure, pass(self), private :: set_content_logical
      procedure, pass(self), private :: set_content_I1P_1
      procedure, pass(self), private :: set_content_I2P_1
      procedure, pass(self), private :: set_content_I4P_1
      procedure, pass(self), private :: set_content_I8P_1
      procedure, pass(self), private :: set_content_R4P_1
      procedure, pass(self), private :: set_content_R8P_1
      procedure, pass(self), private :: delete_subtree      !< Delete a tag and its subtree, renumbering the others.
      procedure, pass(self), private :: last_in_subtree     !< Return the greatest ID of a subtree.
      procedure, pass(self), private :: make_room           !< Move the tags from an ID on by one place.
      procedure, pass(self), private :: append_inline_body  !< Append a tag text, children and their tails, without layout.
      procedure, pass(self), private :: direct_text         !< Return a tag text plus its children tails (raw).
      procedure, pass(self), private :: is_mixed            !< Check if a tag has mixed content.
      procedure, pass(self), private :: raw_text            !< Return a tag stored text (raw).
      procedure, pass(self), private :: content_by_id       !< Return tag content of the tag with a given ID.
      procedure, pass(self), private :: content_by_name     !< Return tag content of tag named *name*.
      procedure, pass(self), private :: parse_from_file     !< Parse xml data from a file, read in chunks.
      procedure, pass(self), private :: parse_from_string   !< Parse xml data from string.
      procedure, pass(self), private :: stringify_recursive !< Convert recursively tags with children into a string.
      procedure, pass(self), private :: attribute_text      !< Return an attribute value, reporting a missing one.
      procedure, pass(self), private :: content_text        !< Return a tag content, reporting a missing tag.
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
   elemental subroutine add_tag(self, tag, parent, id, before, after)
   !< Add tag to XML file: as the last child of the tag with ID *parent* or, if *parent* is not passed (or 0), as a root tag;
   !< with *before* (or *after*), as the sibling right before (after) the tag with that ID. Its own children (if any) are
   !< not kept.
   !<
   !< @note Tags IDs are the tags indexes into the tags array. Appended, the tag gets the new number of tags as ID: in a
   !< built document IDs follow the insertion order. Inserted (*before*, *after*), it takes the place of the sibling (or
   !< the place after the sibling subtree) and the following tags are renumbered, so that a parsed document keeps the
   !< document order; a child ID is always greater than its parent one, as *delete_tag* requires.
   !< @note The tags array capacity is doubled when full, thus adding n tags costs O(n) tags copies, not O(n^2): only the
   !< first *nt* elements are tags, the others are spare capacity.
   !< @note The tag is not added (*id* is 0) if *parent* is not a tag ID, if *before* (or *after*) is not a tag ID or not a
   !< child of *parent* (when passed), or if both *before* and *after* are passed.
   class(xml_file), intent(inout)         :: self       !< XML file.
   type(xml_tag),   intent(in)            :: tag        !< XML tag.
   integer(I4P),    intent(in),  optional :: parent     !< Parent tag ID, 0 for a root tag.
   integer(I4P),    intent(out), optional :: id         !< ID of the added tag, 0 if not added.
   integer(I4P),    intent(in),  optional :: before     !< ID of the sibling the tag is inserted before.
   integer(I4P),    intent(in),  optional :: after      !< ID of the sibling the tag is inserted after.
   type(xml_tag), allocatable             :: tag_new(:) !< New (extended) tags array.
   integer(I4P)                           :: parent_    !< Parent tag ID, local variable.
   integer(I4P)                           :: sibling    !< Sibling ID.
   integer(I4P)                           :: k          !< ID (place) of the new tag.

   if (present(id)) id = 0_I4P
   if (present(before).and.present(after)) return
   parent_ = 0_I4P ; if (present(parent)) parent_ = parent
   if (parent_<0.or.parent_>self%nt) return
   k = self%nt + 1
   sibling = 0
   if (present(before).or.present(after)) then
      if (present(before)) sibling = before
      if (present(after)) sibling = after
      if (sibling<1.or.sibling>self%nt) return
      if (present(parent)) then
         if (parent/=self%tag(sibling)%get_parent_id()) return
      endif
      parent_ = self%tag(sibling)%get_parent_id()
      if (present(before)) then
         k = sibling
      else
         k = self%last_in_subtree(sibling) + 1
      endif
   endif
   if (.not.allocated(self%tag)) then
      allocate(self%tag(1:INITIAL_CAPACITY))
   elseif (self%nt==size(self%tag, dim=1)) then
      allocate(tag_new(1:2 * size(self%tag, dim=1)))
      tag_new(1:self%nt) = self%tag(1:self%nt)
      call move_alloc(from=tag_new, to=self%tag)
   endif
   if (k<=self%nt) call self%make_room(k)
   self%nt = self%nt + 1
   self%tag(k) = tag
   call self%tag(k)%set(id=k, parent_id=parent_)
   if (allocated(self%tag(k)%child_id)) deallocate(self%tag(k)%child_id)
   self%tag(k)%children_number = 0_I4P
   if (parent_>0) then
      call self%tag(k)%set(level=self%tag(parent_)%get_level()+1, indent=self%tag(parent_)%get_indent()+2)
      if (sibling==0) then
         call self%tag(parent_)%add_child_id(child_id=k)
      elseif (present(before)) then
         call insert_child(self%tag(parent_), child=k, at=sibling+1, is_before=.true.)
      else
         call insert_child(self%tag(parent_), child=k, at=sibling, is_before=.false.)
      endif
   else
      call self%tag(k)%set(level=1_I4P)
   endif
   if (present(id)) id = k
   endsubroutine add_tag

   pure function last_in_subtree(self, id) result(last)
   !< Return the greatest ID of the subtree of the tag with ID *id* (the tag included): children IDs are greater than their
   !< parent one, so a forward sweep collects the subtree.
   class(xml_file), intent(in) :: self       !< XML file.
   integer(I4P),    intent(in) :: id         !< Tag ID.
   integer(I4P)                :: last       !< Greatest ID of the subtree.
   logical, allocatable        :: is_in(:)   !< Flag of the subtree tags.
   integer(I4P)                :: t          !< Counter.
   integer(I4P)                :: parent_id  !< Parent ID.

   allocate(is_in(self%nt), source=.false.)
   is_in(id) = .true.
   last = id
   do t=id+1, self%nt
      parent_id = self%tag(t)%get_parent_id()
      if (parent_id>=id.and.parent_id<t) then
         if (is_in(parent_id)) then
            is_in(t) = .true.
            last = t
         endif
      endif
   enddo
   endfunction last_in_subtree

   pure subroutine make_room(self, k)
   !< Move the tags from ID *k* on by one place, renumbering every reference to them (IDs, parents, children lists).
   class(xml_file), intent(inout) :: self !< XML file (with spare capacity for one more tag).
   integer(I4P),    intent(in)    :: k    !< First ID moved.
   integer(I4P)                   :: t    !< Counter.
   integer(I4P)                   :: p    !< Parent ID.

   do t=self%nt, k, -1
      self%tag(t+1) = self%tag(t)
   enddo
   do t=1, self%nt+1
      if (t==k) cycle
      if (t>k) call self%tag(t)%set(id=t)
      p = self%tag(t)%get_parent_id()
      if (p>=k) call self%tag(t)%set(parent_id=p+1)
      if (self%tag(t)%children_number>0) where (self%tag(t)%child_id>=k) self%tag(t)%child_id = self%tag(t)%child_id + 1
   enddo
   endsubroutine make_room


   pure subroutine insert_child(parent, child, at, is_before)
   !< Insert *child* in the children list of *parent*, before (or after) the child with ID *at*.
   type(xml_tag), intent(inout) :: parent    !< Parent tag.
   integer(I4P),  intent(in)    :: child     !< Child ID.
   integer(I4P),  intent(in)    :: at        !< ID of the sibling.
   logical,       intent(in)    :: is_before !< Insert before the sibling, otherwise after.
   integer(I4P)                 :: c         !< Position of the sibling in the list.

   do c=1, parent%children_number
      if (parent%child_id(c)==at) exit
   enddo
   if (.not.is_before) c = c + 1
   parent%child_id = [parent%child_id(1:c-1), child, parent%child_id(c:parent%children_number)]
   parent%children_number = parent%children_number + 1
   endsubroutine insert_child

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

   pure function find(self, name, path, parent, namespaces) result(id)
   !< Return the ID of the first tag (in document order) matching *name* or *path*, 0 if there is none.
   !<
   !< @note See *find_all* for the matching rules.
   class(xml_file), intent(in)           :: self       !< XML file.
   character(*),    intent(in), optional :: name       !< Tag name.
   character(*),    intent(in), optional :: path       !< Tags path, e.g. `origin/latitude/value`.
   integer(I4P),    intent(in), optional :: parent     !< Parent tag ID, 0 for the document root.
   character(*),    intent(in), optional :: namespaces !< Declarations of the names prefixes.
   integer(I4P)                          :: id         !< Tag ID.

   id = tree_find(tag=self%tag, nt=self%nt, name=name, path=path, parent=parent, namespaces=namespaces)
   endfunction find

   pure function find_all(self, name, path, parent, namespaces) result(ids)
   !< Return the IDs of all tags (in document order) matching *name* or *path*.
   !<
   !< Matching rules:
   !<
   !< + *name*: tags named *name* at any depth or, if *parent* is passed, only the direct children of *parent*;
   !< + *path*: `/`-separated tags names; the first one is matched as *name*, each following one must be a direct child
   !<   of the previous one; all the tags matching a segment are explored, thus repeated parents are handled.
   !<
   !< @note If both *name* and *path* are passed, *path* is used; if none is passed, no tag is returned.
   class(xml_file), intent(in)           :: self       !< XML file.
   character(*),    intent(in), optional :: name       !< Tag name.
   character(*),    intent(in), optional :: path       !< Tags path, e.g. `origin/latitude/value`.
   integer(I4P),    intent(in), optional :: parent     !< Parent tag ID, 0 for the document root.
   character(*),    intent(in), optional :: namespaces !< Declarations of the names prefixes.
   integer(I4P), allocatable             :: ids(:)     !< Matching tags IDs, empty if there are none.

   ids = tree_find_all(tag=self%tag, nt=self%nt, name=name, path=path, parent=parent, namespaces=namespaces)
   endfunction find_all

   function select(self, expression, namespaces, iostat, iomsg) result(ids)
   !< Return the IDs (in document order) of the tags selected by the path *expression*, an XPath subset:
   !<
   !< + steps separated by `/` (direct children) or `//` (descendants at any depth); a leading `/` anchors the first step
   !<   to the root tags, a leading `//` or none searches it at any depth (as *find_all* with a path);
   !< + a step is a name (`*` for any, `{uri}local`, prefixes resolved by *namespaces* as *find_all*) and predicates:
   !<   `[@a]` (the attribute exists), `[@a="v"]` (its decoded value is *v*), `[@a~="re"]` (its value matches the
   !<   regular expression *re* anywhere), `[n]` (the *n*-th among its siblings that passed the previous predicates).
   !<
   !< A malformed expression selects nothing and returns `iostat=XML_MALFORMED`, *iomsg* giving the problem and its column.
   !<
   !< @note Not pure (the regular expressions are compiled): *find* and *find_all* are the pure lookups.
   class(xml_file), intent(in)              :: self       !< XML file.
   character(*),    intent(in)              :: expression !< Path expression, e.g. `//event[@type="x"]/origin`.
   character(*),    intent(in),    optional :: namespaces !< Namespaces declarations of the names prefixes.
   integer(I4P),    intent(out),   optional :: iostat     !< IO status, `XML_MALFORMED` for a malformed expression.
   character(*),    intent(inout), optional :: iomsg      !< IO message.
   integer(I4P), allocatable                :: ids(:)     !< Selected tags IDs, empty if there are none.
   integer(I4P)                             :: column     !< Column of a problem, 0 if there is none.
   character(len=:), allocatable            :: message    !< Problem message.

   call tree_select(tag=self%tag, nt=self%nt, expression=expression, namespaces=namespaces, ids=ids, column=column, &
                    message=message)
   call report(iostat_=merge(XML_MALFORMED, 0_I4P, column>0), iomsg_=message, iostat=iostat, iomsg=iomsg)
   endfunction select

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
      if (self%tag(t)%is_named(name)) then
         content = self%direct_text(t)
      elseif (self%tag(t)%is_content_markup()) then ! checked without copying the content
         if (index(without_markup(self%raw_text(t), is_cdata_removed=.true.), '<', kind=I8P)>0) &
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

   elemental subroutine delete_tag(self, name, id)
   !< Delete from XML file the first tag named *name* or, if *id* is passed, the tag with ID *id*, together with its whole
   !< subtree (nothing is deleted if there is no such tag).
   !<
   !< @note Tags IDs are the tags indexes into the tags array: the remaining tags are renumbered, parent and children IDs
   !< included (the IDs before the deleted tag do not change).
   class(xml_file), intent(inout)        :: self !< XML file.
   character(*),    intent(in), optional :: name !< XML tag name.
   integer(I4P),    intent(in), optional :: id   !< XML tag ID.
   integer(I4P)                          :: t    !< Counter.

   if (present(id)) then
      if (id>=1.and.id<=self%nt) call self%delete_subtree(id=id, is_root_deleted=.true.)
   elseif (present(name)) then
      do t=1, self%nt
         if (name==self%tag(t)%name()) then
            call self%delete_subtree(id=t, is_root_deleted=.true.)
            exit
         endif
      enddo
   endif
   endsubroutine delete_tag

   pure function attribute_name(self, id, a) result(name)
   !< Return the name of the attribute with index *a* (1 for the first one, in source order) of the tag with ID *id*, an
   !< empty string if it does not exist; with *attributes_number*, the attributes of a tag can be listed.
   class(xml_file), intent(in)   :: self !< XML file.
   integer(I4P),    intent(in)   :: id   !< Tag ID.
   integer(I4P),    intent(in)   :: a    !< Attribute index.
   character(len=:), allocatable :: name !< Attribute name.

   name = tree_attribute_name(tag=self%tag, nt=self%nt, id=id, a=a)
   endfunction attribute_name

   pure function attributes_number(self, id) result(number)
   !< Return the number of attributes of the tag with ID *id*, 0 if it does not exist.
   class(xml_file), intent(in) :: self   !< XML file.
   integer(I4P),    intent(in) :: id     !< Tag ID.
   integer(I4P)                :: number !< Number of attributes.

   number = tree_attributes_number(tag=self%tag, nt=self%nt, id=id)
   endfunction attributes_number

   pure subroutine delete_attribute(self, id, name, iostat, iomsg)
   !< Delete the attribute named *name* of the tag with ID *id*.
   !<
   !< @note *iostat* is *XML_NOT_FOUND* if the tag or the attribute does not exist (*iomsg* unchanged on success).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   iostat_ = 0
   iomsg_ = ''
   if (id<1.or.id>self%nt) then
      iostat_ = XML_NOT_FOUND
      iomsg_ = 'tag with ID '//trim(str(id, no_sign=.true.))//' not found'
   elseif (.not.self%tag(id)%is_attribute_present(name=name)) then
      iostat_ = XML_NOT_FOUND
      iomsg_ = 'attribute "'//name//'" not found in tag "'//self%tag(id)%name()//'"'
   else
      call self%tag(id)%delete_attributes(name=name)
   endif
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
   endsubroutine delete_attribute

   pure subroutine set_attribute_character(self, id, name, value, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id*: added (last) or, if present, its value replaced; *value* is
   !< escaped (markup characters, tab, new line and CR), *attribute* returns it as passed.
   !<
   !< @note *iostat* is *XML_NOT_FOUND* if the tag does not exist, *XML_MALFORMED* if *name* is not an XML name (nothing is
   !< set); *iomsg* is unchanged on success.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   character(*),           intent(in)    :: value   !< Attribute value.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   iostat_ = 0
   iomsg_ = ''
   if (id<1.or.id>self%nt) then
      iostat_ = XML_NOT_FOUND
      iomsg_ = 'tag with ID '//trim(str(id, no_sign=.true.))//' not found'
   elseif (.not.is_name(name)) then
      iostat_ = XML_MALFORMED
      iomsg_ = 'attribute name "'//name//'" is not an XML name'
   else
      call self%tag(id)%set(attribute_name=name, attribute_value=xml_escape(value, attribute=.true.))
   endif
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_character

   pure subroutine set_content_character(self, id, content, iostat, iomsg)
   !< Set the content of the tag with ID *id*: its children (with their subtrees) are deleted, *content* becomes its whole
   !< content (a self closing tag gets an end tag).
   !<
   !< @note As for *xml_tag* contents, *content* is stored as it is (it may hold markup): character data from the user must
   !< be escaped first with *xml_escape*. The children deleted renumber the following tags, as *delete_tag*.
   !< @note *iostat* is *XML_NOT_FOUND* if the tag does not exist (*iomsg* unchanged on success).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: content !< Tag content.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   iostat_ = 0
   iomsg_ = ''
   if (id<1.or.id>self%nt) then
      iostat_ = XML_NOT_FOUND
      iomsg_ = 'tag with ID '//trim(str(id, no_sign=.true.))//' not found'
   else
      if (self%tag(id)%children_number>0) call self%delete_subtree(id=id, is_root_deleted=.false.)
      call self%tag(id)%set(content=content, is_self_closing=.false.)
   endif
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_character

   pure subroutine set_attribute_I1P(self, id, name, value, fmt, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id* to integer(I1P) value (as *to_text*).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   integer(I1P),           intent(in)    :: value   !< Value.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_attribute_character(id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_I1P

   pure subroutine set_attribute_I2P(self, id, name, value, fmt, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id* to integer(I2P) value (as *to_text*).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   integer(I2P),           intent(in)    :: value   !< Value.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_attribute_character(id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_I2P

   pure subroutine set_attribute_I4P(self, id, name, value, fmt, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id* to integer(I4P) value (as *to_text*).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   integer(I4P),           intent(in)    :: value   !< Value.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_attribute_character(id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_I4P

   pure subroutine set_attribute_I8P(self, id, name, value, fmt, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id* to integer(I8P) value (as *to_text*).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   integer(I8P),           intent(in)    :: value   !< Value.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_attribute_character(id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_I8P

   pure subroutine set_attribute_R4P(self, id, name, value, fmt, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id* to real(R4P) value (as *to_text*).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   real(R4P),              intent(in)    :: value   !< Value.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_attribute_character(id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_R4P

   pure subroutine set_attribute_R8P(self, id, name, value, fmt, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id* to real(R8P) value (as *to_text*).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   real(R8P),              intent(in)    :: value   !< Value.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_attribute_character(id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_R8P

   pure subroutine set_attribute_logical(self, id, name, value, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id* to logical value (as *to_text*).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   logical,                intent(in)    :: value   !< Value.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_attribute_character(id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_logical

   pure subroutine set_attribute_I1P_1(self, id, name, values, fmt, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id* to a list of integer(I1P) values (as *to_text*).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   integer(I1P),           intent(in)    :: values(:)!< Values.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=values, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_attribute_character(id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_I1P_1

   pure subroutine set_attribute_I2P_1(self, id, name, values, fmt, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id* to a list of integer(I2P) values (as *to_text*).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   integer(I2P),           intent(in)    :: values(:)!< Values.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=values, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_attribute_character(id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_I2P_1

   pure subroutine set_attribute_I4P_1(self, id, name, values, fmt, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id* to a list of integer(I4P) values (as *to_text*).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   integer(I4P),           intent(in)    :: values(:)!< Values.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=values, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_attribute_character(id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_I4P_1

   pure subroutine set_attribute_I8P_1(self, id, name, values, fmt, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id* to a list of integer(I8P) values (as *to_text*).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   integer(I8P),           intent(in)    :: values(:)!< Values.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=values, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_attribute_character(id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_I8P_1

   pure subroutine set_attribute_R4P_1(self, id, name, values, fmt, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id* to a list of real(R4P) values (as *to_text*).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   real(R4P),              intent(in)    :: values(:)!< Values.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=values, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_attribute_character(id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_R4P_1

   pure subroutine set_attribute_R8P_1(self, id, name, values, fmt, iostat, iomsg)
   !< Set the attribute named *name* of the tag with ID *id* to a list of real(R8P) values (as *to_text*).
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< Attribute name.
   real(R8P),              intent(in)    :: values(:)!< Values.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=values, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_attribute_character(id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_attribute_R8P_1

   pure subroutine set_content_I1P(self, id, value, fmt, iostat, iomsg)
   !< Set the content of the tag with ID *id* to integer(I1P) value (as *to_text*: integers with their digits, reals the shortest
   !< text that reads back, logicals `true`/`false`, lists separated by a space), replacing its children.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   integer(I1P),           intent(in)    :: value   !< Value.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_content_character(id=id, content=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_I1P

   pure subroutine set_content_I2P(self, id, value, fmt, iostat, iomsg)
   !< Set the content of the tag with ID *id* to integer(I2P) value (as *to_text*: integers with their digits, reals the shortest
   !< text that reads back, logicals `true`/`false`, lists separated by a space), replacing its children.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   integer(I2P),           intent(in)    :: value   !< Value.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_content_character(id=id, content=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_I2P

   pure subroutine set_content_I4P(self, id, value, fmt, iostat, iomsg)
   !< Set the content of the tag with ID *id* to integer(I4P) value (as *to_text*: integers with their digits, reals the shortest
   !< text that reads back, logicals `true`/`false`, lists separated by a space), replacing its children.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   integer(I4P),           intent(in)    :: value   !< Value.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_content_character(id=id, content=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_I4P

   pure subroutine set_content_I8P(self, id, value, fmt, iostat, iomsg)
   !< Set the content of the tag with ID *id* to integer(I8P) value (as *to_text*: integers with their digits, reals the shortest
   !< text that reads back, logicals `true`/`false`, lists separated by a space), replacing its children.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   integer(I8P),           intent(in)    :: value   !< Value.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_content_character(id=id, content=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_I8P

   pure subroutine set_content_R4P(self, id, value, fmt, iostat, iomsg)
   !< Set the content of the tag with ID *id* to real(R4P) value (as *to_text*: integers with their digits, reals the shortest
   !< text that reads back, logicals `true`/`false`, lists separated by a space), replacing its children.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   real(R4P),              intent(in)    :: value   !< Value.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_content_character(id=id, content=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_R4P

   pure subroutine set_content_R8P(self, id, value, fmt, iostat, iomsg)
   !< Set the content of the tag with ID *id* to real(R8P) value (as *to_text*: integers with their digits, reals the shortest
   !< text that reads back, logicals `true`/`false`, lists separated by a space), replacing its children.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   real(R8P),              intent(in)    :: value   !< Value.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_content_character(id=id, content=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_R8P

   pure subroutine set_content_logical(self, id, value, iostat, iomsg)
   !< Set the content of the tag with ID *id* to logical value (as *to_text*: integers with their digits, reals the shortest
   !< text that reads back, logicals `true`/`false`, lists separated by a space), replacing its children.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   logical,                intent(in)    :: value   !< Value.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=value, text=text, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_content_character(id=id, content=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_logical

   pure subroutine set_content_I1P_1(self, id, values, fmt, iostat, iomsg)
   !< Set the content of the tag with ID *id* to a list of integer(I1P) values (as *to_text*: integers with their
   !< digits, reals the shortest
   !< text that reads back, logicals `true`/`false`, lists separated by a space), replacing its children.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   integer(I1P),           intent(in)    :: values(:)!< Values.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=values, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_content_character(id=id, content=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_I1P_1

   pure subroutine set_content_I2P_1(self, id, values, fmt, iostat, iomsg)
   !< Set the content of the tag with ID *id* to a list of integer(I2P) values (as *to_text*: integers with their
   !< digits, reals the shortest
   !< text that reads back, logicals `true`/`false`, lists separated by a space), replacing its children.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   integer(I2P),           intent(in)    :: values(:)!< Values.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=values, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_content_character(id=id, content=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_I2P_1

   pure subroutine set_content_I4P_1(self, id, values, fmt, iostat, iomsg)
   !< Set the content of the tag with ID *id* to a list of integer(I4P) values (as *to_text*: integers with their
   !< digits, reals the shortest
   !< text that reads back, logicals `true`/`false`, lists separated by a space), replacing its children.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   integer(I4P),           intent(in)    :: values(:)!< Values.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=values, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_content_character(id=id, content=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_I4P_1

   pure subroutine set_content_I8P_1(self, id, values, fmt, iostat, iomsg)
   !< Set the content of the tag with ID *id* to a list of integer(I8P) values (as *to_text*: integers with their
   !< digits, reals the shortest
   !< text that reads back, logicals `true`/`false`, lists separated by a space), replacing its children.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   integer(I8P),           intent(in)    :: values(:)!< Values.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=values, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_content_character(id=id, content=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_I8P_1

   pure subroutine set_content_R4P_1(self, id, values, fmt, iostat, iomsg)
   !< Set the content of the tag with ID *id* to a list of real(R4P) values (as *to_text*: integers with their digits,
   !< reals the shortest
   !< text that reads back, logicals `true`/`false`, lists separated by a space), replacing its children.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   real(R4P),              intent(in)    :: values(:)!< Values.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=values, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_content_character(id=id, content=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_R4P_1

   pure subroutine set_content_R8P_1(self, id, values, fmt, iostat, iomsg)
   !< Set the content of the tag with ID *id* to a list of real(R8P) values (as *to_text*: integers with their digits,
   !< reals the shortest
   !< text that reads back, logicals `true`/`false`, lists separated by a space), replacing its children.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   real(R8P),              intent(in)    :: values(:)!< Values.
   character(*), optional, intent(in)    :: fmt     !< Format (of each value), e.g. `(F6.3)`.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(len=:), allocatable         :: text    !< Value as text.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   call to_text(value=values, text=text, fmt=fmt, iostat=iostat_, iomsg=iomsg_)
   if (iostat_/=0) then
      call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
      return
   endif
   call self%set_content_character(id=id, content=text, iostat=iostat, iomsg=iomsg)
   endsubroutine set_content_R8P_1

   pure subroutine set_name(self, id, name, iostat, iomsg)
   !< Rename the tag with ID *id* (its end tag follows); its namespace is resolved again from the new prefix.
   !<
   !< @note *iostat* is *XML_NOT_FOUND* if the tag does not exist, *XML_MALFORMED* if *name* is not an XML name (nothing is
   !< changed); *iomsg* is unchanged on success.
   class(xml_file),        intent(inout) :: self    !< XML file.
   integer(I4P),           intent(in)    :: id      !< Tag ID.
   character(*),           intent(in)    :: name    !< New name.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   integer(I4P)                          :: iostat_ !< IO status, local variable.
   character(len=:), allocatable         :: iomsg_  !< IO message, local variable.

   iostat_ = 0
   iomsg_ = ''
   if (id<1.or.id>self%nt) then
      iostat_ = XML_NOT_FOUND
      iomsg_ = 'tag with ID '//trim(str(id, no_sign=.true.))//' not found'
   elseif (.not.is_name(name)) then
      iostat_ = XML_MALFORMED
      iomsg_ = 'tag name "'//name//'" is not an XML name'
   else
      call self%tag(id)%set(name=name)
   endif
   call report(iostat_=iostat_, iomsg_=iomsg_, iostat=iostat, iomsg=iomsg)
   endsubroutine set_name

   elemental function tags_number(self) result(number)
   !< Return the number of tags (IDs are 1 to the number of tags).
   class(xml_file), intent(in) :: self   !< XML file.
   integer(I4P)                :: number !< Number of tags.

   number = self%nt
   endfunction tags_number

   pure function level(self, id) result(level_)
   !< Return the level of the tag with ID *id* (1 for a root tag), 0 if it does not exist.
   class(xml_file), intent(in) :: self   !< XML file.
   integer(I4P),    intent(in) :: id     !< Tag ID.
   integer(I4P)                :: level_ !< Tag level.

   level_ = tree_level(tag=self%tag, nt=self%nt, id=id)
   endfunction level

   pure function local_name(self, id) result(local_name_)
   !< Return the local name (without prefix) of the tag with ID *id*, an empty string if it does not exist.
   class(xml_file), intent(in)   :: self        !< XML file.
   integer(I4P),    intent(in)   :: id          !< Tag ID.
   character(len=:), allocatable :: local_name_ !< Tag local name.

   local_name_ = tree_local_name(tag=self%tag, nt=self%nt, id=id)
   endfunction local_name

   pure function matching(self, re, ids, on, attribute, whole) result(matched)
   !< Return the IDs of the tags (of *ids*, in their order, or all of them) whose name, content or attribute value matches
   !< the compiled regular expression *re* (StringiFor `regex`): a part of the text, or the whole of it with *whole*.
   !<
   !< @note *on* is `name` (default), `content` or `attribute` (implied by *attribute*). Names are matched as written,
   !< contents and attribute values decoded (as *content* and
   !< *attribute* return them); a tag without the attribute never matches; a regex not compiled matches nothing.
   class(xml_file), intent(in)           :: self       !< XML file.
   type(regex),     intent(in)           :: re         !< Compiled regular expression.
   integer(I4P),    intent(in), optional :: ids(:)     !< Tags IDs to filter (default: all the tags).
   character(*),    intent(in), optional :: on         !< What is matched.
   character(*),    intent(in), optional :: attribute  !< Attribute name.
   logical,         intent(in), optional :: whole      !< Match the whole text.
   integer(I4P), allocatable             :: matched(:) !< Matching IDs.
   integer(I4P), allocatable             :: ids_(:)    !< Tags IDs to filter, local variable.
   character(len=:), allocatable         :: on_        !< What is matched, local variable.
   character(len=:), allocatable         :: attribute_ !< Attribute name, local variable.
   logical                               :: whole_     !< Match the whole text, local variable.
   integer(I4P), allocatable             :: buffer(:)  !< Matching IDs found (contents).
   integer(I4P)                          :: n          !< Number of matching IDs.
   integer(I4P)                          :: i          !< Counter.

   if (present(ids)) then
      ids_ = ids
   else
      ids_ = tags_indexes(self%nt)
   endif
   attribute_ = '' ; if (present(attribute)) attribute_ = attribute
   on_ = 'name'
   if (present(attribute)) on_ = 'attribute'
   if (present(on)) on_ = on
   whole_ = .false. ; if (present(whole)) whole_ = whole
   if (on_=='name'.or.on_=='attribute') then
      matched = tree_matching(tag=self%tag, nt=self%nt, ids=ids_, re=re, on=on_, attribute=attribute_, whole=whole_)
      elseif (on_=='content') then
         allocate(buffer(size(ids_, dim=1)))
         n = 0
         if (re%is_compiled()) then
            do i=1, size(ids_, dim=1)
               if (ids_(i)<1.or.ids_(i)>self%nt) cycle
               if (regex_matches(re=re, subject=self%content(id=ids_(i)), whole=whole_)) then
                  n = n + 1
                  buffer(n) = ids_(i)
               endif
            enddo
         endif
         matched = buffer(1:n)
   else
      allocate(matched(0))
   endif
   endfunction matching

   pure function name(self, id) result(name_)
   !< Return the name of the tag with ID *id*, an empty string if it does not exist.
   class(xml_file), intent(in)   :: self  !< XML file.
   integer(I4P),    intent(in)   :: id    !< Tag ID.
   character(len=:), allocatable :: name_ !< Tag name.

   name_ = tree_name(tag=self%tag, nt=self%nt, id=id)
   endfunction name

   pure function namespace(self, id) result(namespace_)
   !< Return the namespace of the tag with ID *id*, declared by the nearest `xmlns:prefix` (`xmlns` for an unprefixed
   !< name) attribute of the tag or of its ancestors.
   !<
   !< @note An empty string is returned for a tag in no namespace, for a prefix not declared (a prefixed tag without
   !< namespace) and if the tag does not exist; the *xml* prefix is bound to its namespace.
   class(xml_file), intent(in)   :: self       !< XML file.
   integer(I4P),    intent(in)   :: id         !< Tag ID.
   character(len=:), allocatable :: namespace_ !< Tag namespace.

   namespace_ = tree_namespace(tag=self%tag, nt=self%nt, id=id)
   endfunction namespace

   pure function parent(self, id) result(parent_)
   !< Return the parent ID of the tag with ID *id* (0 for a root tag or if the tag does not exist).
   class(xml_file), intent(in) :: self    !< XML file.
   integer(I4P),    intent(in) :: id      !< Tag ID.
   integer(I4P)                :: parent_ !< Parent ID.

   parent_ = tree_parent(tag=self%tag, nt=self%nt, id=id)
   endfunction parent

   pure function prefix(self, id) result(prefix_)
   !< Return the name prefix of the tag with ID *id*, an empty string if it has none or it does not exist.
   class(xml_file), intent(in)   :: self    !< XML file.
   integer(I4P),    intent(in)   :: id      !< Tag ID.
   character(len=:), allocatable :: prefix_ !< Tag name prefix.

   prefix_ = tree_prefix(tag=self%tag, nt=self%nt, id=id)
   endfunction prefix

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
   !< @note If *iostat* is passed, it returns 0 on success, the runtime I/O error code, or *XML_MALFORMED* for a document
   !< with more root tags (not well-formed XML, written anyway), and *iomsg* (unchanged on success) describes the error;
   !< without *iostat* an I/O error stops the program, as Fortran I/O statements do (more root tags are not reported).
   class(xml_file),        intent(in)    :: self        !< XML file.
   character(*),           intent(in)    :: filename    !< File name.
   logical,      optional, intent(in)    :: is_declared !< Write the XML declaration, if missing.
   integer(I4P), optional, intent(out)   :: iostat      !< IO status.
   character(*), optional, intent(inout) :: iomsg       !< IO message.
   logical                               :: is_declared_ !< Write the XML declaration, local variable.
   integer(I4P)                          :: iostat_     !< IO status, local variable.
   character(len=500)                    :: iomsg_      !< IO message, local variable.
   integer(I4P)                          :: unit        !< File unit.
   integer(I4P)                          :: roots       !< Number of root tags.
   integer(I4P)                          :: t           !< Counter.

   is_declared_ = .false. ; if (present(is_declared)) is_declared_ = is_declared
   if (is_declared_.and.allocated(self%prolog)) is_declared_ = .not.starts_with_declaration(self%prolog)
   open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE', iostat=iostat_, iomsg=iomsg_)
   if (iostat_==0) then
      if (is_declared_) write(unit=unit, iostat=iostat_, iomsg=iomsg_) XML_DECLARATION//new_line('a')
      if (iostat_==0) write(unit=unit, iostat=iostat_, iomsg=iomsg_) self%stringify()//new_line('a')
      close(unit)
   endif
   if (present(iostat)) then
      roots = 0
      do t=1, self%nt
         if (self%tag(t)%get_parent_id()==0) roots = roots + 1
      enddo
      if (iostat_==0.and.roots>1) then
         iostat_ = XML_MALFORMED
         iomsg_ = 'the document has '//trim(str(roots, no_sign=.true.))//' root tags, XML allows one'
      endif
      iostat = iostat_
      if (present(iomsg).and.iostat_/=0) iomsg = trim(iomsg_)
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

   pure subroutine delete_subtree(self, id, is_root_deleted)
   !< Delete the subtree of the tag with ID *id* (the tag included if *is_root_deleted*), renumbering the other tags.
   !<
   !< @note A child index is always greater than its parent one (document order for parsed tags, insertion order for added
   !< ones), thus the subtree is collected by a single forward sweep.
   class(xml_file), intent(inout) :: self            !< XML file.
   integer(I4P),    intent(in)    :: id              !< Tag ID.
   logical,         intent(in)    :: is_root_deleted !< The tag itself is deleted too.
   type(xml_tag), allocatable     :: tag_new(:)      !< New (reduced) tags array.
   logical,       allocatable     :: is_deleted(:)   !< Flag of deleted tags.
   logical,       allocatable     :: is_in_subtree(:) !< Flag of the subtree tags (the tag included).
   integer(I4P),  allocatable     :: new_id(:)       !< New ID of each tag, 0 if deleted.
   integer(I4P),  allocatable     :: child_id(:)     !< Children IDs, renumbered.
   integer(I4P)                   :: parent_id       !< Parent ID.
   integer(I4P)                   :: t               !< Counter.
   integer(I4P)                   :: n               !< Counter.

   allocate(is_in_subtree(self%nt), source=.false.)
   is_in_subtree(id) = .true.
   do t=id+1, self%nt
      parent_id = self%tag(t)%get_parent_id()
      if (parent_id>=id.and.parent_id<t) then
         if (is_in_subtree(parent_id)) is_in_subtree(t) = .true.
      endif
   enddo
   is_deleted = is_in_subtree
   if (.not.is_root_deleted) is_deleted(id) = .false.

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
   endsubroutine delete_subtree

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
   type(source_encoding)                        :: encoding   !< Encoding of the file.
   character(len=:), allocatable                :: raw        !< Chunk read, to convert.
   character(len=:), allocatable                :: utf8       !< Chunk converted.

   call self%free
   builder%sanitize = sanitize
   open(newunit=unit, file=trim(adjustl(filename)), access='STREAM', form='UNFORMATTED', action='READ', status='OLD', &
        iostat=iostat, iomsg=iomsg)
   if (iostat/=0) return
   inquire(unit=unit, size=file_size)
   call detect_file_encoding(unit=unit, file_size=file_size, encoding=encoding, iostat=iostat, iomsg=iomsg)
   if (iostat/=0) then
      close(unit)
      return
   endif
   if (encoding%is_converted) call tokenizer%set_source(name=encoding%name, is_converted=.true.)
   read_size = encoding%skip
   offset = 0
   rest = ''
   do
      piece = max(0_I8P, min(chunk_size, file_size - read_size))
      if (encoding%is_converted) piece = min(piece, MAX_PIECE)
      if (encoding%is_converted.and.piece>0) then
         allocate(character(len=piece) :: raw)
         read(unit=unit, pos=read_size+1, iostat=iostat, iomsg=iomsg) raw
         if (iostat/=0) then
            close(unit)
            return
         endif
         read_size = read_size + piece
         call decode_piece(encoding=encoding, raw=raw, is_last=read_size>=file_size, utf8=utf8)
         deallocate(raw)
         window = rest//utf8
      else
         allocate(character(len=len(rest, kind=I8P)+piece) :: window)
         window(1:len(rest, kind=I8P)) = rest
         if (piece>0) then
            read(unit=unit, pos=read_size+1, iostat=iostat, iomsg=iomsg) window(len(rest, kind=I8P)+1:)
            if (iostat/=0) then
               close(unit)
               return
            endif
            read_size = read_size + piece
         endif
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
   if (encoding%is_converted.and.allocated(self%prolog)) self%prolog = with_utf8_declaration(self%prolog)
   if (len(encoding%problem)>0) then ! at the source start: the first problem
      problem = 'line 1: '//encoding%problem
   elseif (allocated(builder%first_problem)) then
      problem = located_in_file(filename=filename, pos=builder%problem_pos, message=builder%first_problem, &
                                chunk_size=chunk_size, encoding=encoding)
   endif
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
   type(source_encoding)                        :: encoding      !< Encoding of the string.
   character(len=:), allocatable                :: utf8          !< String converted.

   call self%free
   builder%sanitize = sanitize
   call detect_encoding(prefix=source_string(1:min(len(source_string, kind=I8P), DETECT_LEN)), encoding=encoding)
   if (encoding%is_converted) then
      call tokenizer%set_source(name=encoding%name, is_converted=.true.)
      utf8 = decoded(source=source_string, encoding=encoding)
      call tokenizer%feed(chars=utf8, offset=0_I8P, is_last=.true., builder=builder, consumed=consumed)
   else
      call tokenizer%feed(chars=source_string, offset=0_I8P, is_last=.true., builder=builder, consumed=consumed)
   endif
   call builder%finish
   call move_alloc(from=builder%doc%tag, to=self%tag)
   self%nt = builder%doc%nt
   if (allocated(builder%doc%prolog)) call move_alloc(from=builder%doc%prolog, to=self%prolog)
   if (encoding%is_converted.and.allocated(self%prolog)) self%prolog = with_utf8_declaration(self%prolog)
   if (len(encoding%problem)>0) then ! at the source start: the first problem
      problem = 'line 1: '//encoding%problem
   elseif (allocated(builder%first_problem)) then
      if (encoding%is_converted) then
         problem = located(source=utf8, pos=builder%problem_pos, message=builder%first_problem)
      else
         problem = located(source=source_string, pos=builder%problem_pos, message=builder%first_problem)
      endif
   endif
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

   ! typed accessors
   subroutine attribute_text(self, id, name, text, iostat, iomsg)
   !< Return the value of the attribute named *name* of the tag with ID *id*; *iostat* is *XML_NOT_FOUND* if the tag or the
   !< attribute does not exist.
   class(xml_file),               intent(in)  :: self   !< XML file.
   integer(I4P),                  intent(in)  :: id     !< Tag ID.
   character(*),                  intent(in)  :: name   !< Attribute name.
   character(len=:), allocatable, intent(out) :: text   !< Attribute value.
   integer(I4P),                  intent(out) :: iostat !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg  !< IO message.

   call tree_attribute_text(tag=self%tag, nt=self%nt, id=id, name=name, value=text, iostat=iostat, iomsg=iomsg)
   endsubroutine attribute_text

   subroutine content_text(self, id, text, iostat, iomsg)
   !< Return the content of the tag with ID *id* (see *content*); *iostat* is *XML_NOT_FOUND* if the tag does not exist.
   class(xml_file),               intent(in)  :: self   !< XML file.
   integer(I4P),                  intent(in)  :: id     !< Tag ID.
   character(len=:), allocatable, intent(out) :: text   !< Tag content.
   integer(I4P),                  intent(out) :: iostat !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg  !< IO message.

   iostat = 0
   iomsg = ''
   if (id>=1.and.id<=self%nt) then
      text = self%content(id)
   else
      text = ''
      iostat = XML_NOT_FOUND
      iomsg = 'no tag with ID '//trim(str(id, no_sign=id>=0))
   endif
   endsubroutine content_text

   subroutine get_attribute_I1P(self, id, name, value, iostat, iomsg)
   !< Get the attribute named *name* of the tag with ID *id* as a integer(I1P) value.
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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
   class(xml_file),       intent(in)    :: self      !< XML file.
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

   ! operators
   subroutine finalize(self)
   !< Free dynamic memory when finalizing.
   type(xml_file), intent(inout) :: self !< XML file.

   call self%free
   endsubroutine finalize

   ! dom_builder methods
   pure subroutine dom_start_tag(self, id, parent_id, level, name, start)
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

   pure subroutine dom_attribute(self, id, name, value)
   !< An attribute of the current start tag.
   class(dom_builder), intent(inout) :: self  !< DOM builder.
   integer(I4P),       intent(in)    :: id    !< Tag ID.
   character(*),       intent(in)    :: name  !< Attribute name.
   character(*),       intent(in)    :: value !< Attribute value.

   call self%doc%tag(id)%set(attribute_name=name, attribute_value=value, sanitize_attributes_value=self%sanitize)
   endsubroutine dom_attribute

   pure subroutine dom_start_tag_end(self, id, start, open_end, is_self_closing)
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

   pure subroutine dom_end_tag(self, id, start, open_end, end_start, end_end)
   !< An open tag is closed: the text so far ends, the following character data are its tail.
   class(dom_builder), intent(inout) :: self      !< DOM builder.
   integer(I4P),       intent(in)    :: id        !< Tag ID.
   integer(I8P),       intent(in)    :: start     !< Position of the start tag `<`.
   integer(I8P),       intent(in)    :: open_end  !< Position of the start tag `>`.
   integer(I8P),       intent(in)    :: end_start !< Position of the end tag `<`.
   integer(I8P),       intent(in)    :: end_end   !< Position of the end tag `>`.

   call self%flush(is_parent=.false.)
   call self%doc%tag(id)%set(pos=[start, open_end, end_start])
   self%owner = id
   self%is_tail = .true.
   endsubroutine dom_end_tag

   pure subroutine dom_data(self, kind, chars, first)
   !< Character data or other markup: part of the prolog before the first tag, of the owner text afterwards (CDATA,
   !< comments and PIs included, declarations and ignored markup excluded).
   class(dom_builder), intent(inout) :: self  !< DOM builder.
   integer(I4P),       intent(in)    :: kind  !< Data kind, DATA_*.
   character(*),       intent(in)    :: chars !< Characters, as in the source.
   integer(I8P),       intent(in)    :: first !< Position of the first character.

   if (self%doc%nt==0) call append(buffer=self%prolog, n=self%prolog_n, piece=chars)
   if (self%owner>0.and.kind>=DATA_TEXT.and.kind<=DATA_PI) call append(buffer=self%text, n=self%text_n, piece=chars)
   endsubroutine dom_data

   pure subroutine dom_problem(self, pos, message)
   !< A problem of malformed input: only the first one is kept.
   class(dom_builder), intent(inout) :: self    !< DOM builder.
   integer(I8P),       intent(in)    :: pos     !< Position of the problem.
   character(*),       intent(in)    :: message !< Problem description.

   if (allocated(self%first_problem)) return
   self%first_problem = message
   self%problem_pos = pos
   endsubroutine dom_problem

   pure subroutine dom_finish(self)
   !< Complete the DOM at the source end: store the last character data, build the children lists.
   class(dom_builder), intent(inout) :: self !< DOM builder.

   call self%flush(is_parent=.false.)
   call tree_build_children(tag=self%doc%tag, nt=self%doc%nt)
   endsubroutine dom_finish

   pure subroutine dom_flush(self, is_parent)
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

   pure function starts_with_declaration(prolog) result(is_declaration)
   !< Check if a prolog starts with the XML declaration (`<?xml` followed by a blank, not a PI named `xml-...`).
   character(*), intent(in) :: prolog         !< Prolog.
   logical                  :: is_declaration !< Check result.

   is_declaration = .false.
   if (len(prolog, kind=I8P)>5) is_declaration = prolog(1:5)=='<?xml'.and.scan(prolog(6:6), BLANKS)>0
   endfunction starts_with_declaration

endmodule foxy_xml_file
