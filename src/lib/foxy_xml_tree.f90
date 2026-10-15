!< FoXy tree queries: lookups over a linearized array of tags, shared by the DOM (*xml_file*) and the index (*xml_index*).
module foxy_xml_tree
!< FoXy tree queries: lookups over a linearized array of tags, shared by the DOM (*xml_file*) and the index (*xml_index*).
!<
!< The tags are stored in document order (start tags order); each tag knows its ID (its index), its parent ID (0 for a
!< root tag) and, once *tree_build_children* is called, its children IDs.
use foxy_xml_tag, only : xml_tag
use foxy_xml_values, only : XML_NOT_FOUND
use penf

implicit none
private
public :: tree_attribute
public :: tree_attribute_text
public :: tree_build_children
public :: tree_children
public :: tree_find_all
public :: tree_level
public :: tree_name
public :: tree_parent
public :: tags_indexes

contains
   pure function tree_attribute(tag, nt, id, name) result(value)
   !< Return the value of the attribute named *name* of the tag with ID *id*.
   !<
   !< @note If the tag or the attribute does not exist, an empty string is returned.
   type(xml_tag), allocatable, intent(in) :: tag(:) !< Tags.
   integer(I4P),               intent(in) :: nt     !< Number of tags.
   integer(I4P),               intent(in) :: id     !< Tag ID.
   character(*),               intent(in) :: name   !< Attribute name.
   character(len=:), allocatable          :: value  !< Attribute value.

   if (id<1.or.id>nt) then
      value = ''
   else
      value = tag(id)%get_attribute(name=name)
   endif
   endfunction tree_attribute

   pure subroutine tree_attribute_text(tag, nt, id, name, value, iostat, iomsg)
   !< Return the value of the attribute named *name* of the tag with ID *id* (as *tree_attribute*); *iostat* is
   !< *XML_NOT_FOUND* if the tag or the attribute does not exist.
   type(xml_tag), allocatable,    intent(in)  :: tag(:) !< Tags.
   integer(I4P),                  intent(in)  :: nt     !< Number of tags.
   integer(I4P),                  intent(in)  :: id     !< Tag ID.
   character(*),                  intent(in)  :: name   !< Attribute name.
   character(len=:), allocatable, intent(out) :: value  !< Attribute value, empty if it does not exist.
   integer(I4P),                  intent(out) :: iostat !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg  !< IO message.

   iostat = 0
   iomsg = ''
   value = ''
   if (id<1.or.id>nt) then
      iostat = XML_NOT_FOUND
      iomsg = 'no tag with ID '//trim(str(id, no_sign=id>=0))
   elseif (.not.tag(id)%is_attribute_present(name=name)) then
      iostat = XML_NOT_FOUND
      iomsg = 'no attribute "'//name//'" in tag "'//tag(id)%name()//'"'
   else
      value = tag(id)%get_attribute(name=name)
   endif
   endsubroutine tree_attribute_text

   pure subroutine tree_build_children(tag, nt)
   !< Build the children IDs lists (in document order) of all tags from their parents IDs, in O(n).
   !<
   !< @note Appending each child to its parent list while parsing costs O(children^2) for a parent with many children.
   type(xml_tag), allocatable, intent(inout) :: tag(:)    !< Tags.
   integer(I4P),               intent(in)    :: nt        !< Number of tags.
   integer(I4P), allocatable                 :: filled(:) !< Number of children IDs already stored, per tag.
   integer(I4P)                              :: parent_id !< Parent ID.
   integer(I4P)                              :: t         !< Counter.

   do t=1, nt
      tag(t)%children_number = 0_I4P
      if (allocated(tag(t)%child_id)) deallocate(tag(t)%child_id)
   enddo
   do t=1, nt
      parent_id = tag(t)%get_parent_id()
      if (parent_id>0) tag(parent_id)%children_number = tag(parent_id)%children_number + 1
   enddo
   do t=1, nt
      if (tag(t)%children_number>0) allocate(tag(t)%child_id(tag(t)%children_number))
   enddo
   allocate(filled(nt), source=0_I4P)
   do t=1, nt
      parent_id = tag(t)%get_parent_id()
      if (parent_id>0) then
         filled(parent_id) = filled(parent_id) + 1
         tag(parent_id)%child_id(filled(parent_id)) = t
      endif
   enddo
   endsubroutine tree_build_children

   pure function tree_children(tag, nt, id) result(ids)
   !< Return the IDs of the direct children of the tag with ID *id*, in document order.
   !<
   !< @note The ID 0 is the document root: its children are the root tags.
   type(xml_tag), allocatable, intent(in) :: tag(:) !< Tags.
   integer(I4P),               intent(in) :: nt     !< Number of tags.
   integer(I4P),               intent(in) :: id     !< Tag ID.
   integer(I4P), allocatable              :: ids(:)      !< Children IDs, empty if there are none.
   logical,      allocatable              :: is_child(:) !< Flag of children.
   integer(I4P)                           :: t           !< Counter.

   if (id<0.or.id>nt) then
      allocate(ids(0))
      return
   endif
   allocate(is_child(nt)) ! a loop, not an implied-do mask: nvfortran evaluates the latter out of bounds
   do t=1, nt
      is_child(t) = tag(t)%get_parent_id()==id
   enddo
   ids = pack(tags_indexes(nt), is_child)
   endfunction tree_children

   pure function tree_find_all(tag, nt, name, path, parent) result(ids)
   !< Return the IDs of all tags (in document order) matching *name* or *path*.
   !<
   !< Matching rules:
   !<
   !< + *name*: tags named *name* at any depth or, if *parent* is passed, only the direct children of *parent*;
   !< + *path*: `/`-separated tags names; the first one is matched as *name*, each following one must be a direct child
   !<   of the previous one; all the tags matching a segment are explored, thus repeated parents are handled.
   !<
   !< @note If both *name* and *path* are passed, *path* is used; if none is passed, no tag is returned.
   type(xml_tag), allocatable, intent(in)           :: tag(:)      !< Tags.
   integer(I4P),               intent(in)           :: nt          !< Number of tags.
   character(*),               intent(in), optional :: name        !< Tag name.
   character(*),               intent(in), optional :: path        !< Tags path, e.g. `origin/latitude/value`.
   integer(I4P),               intent(in), optional :: parent      !< Parent tag ID, 0 for the document root.
   integer(I4P), allocatable                        :: ids(:)      !< Matching tags IDs, empty if there are none.
   character(len=:), allocatable                    :: rest        !< Path segments still to match.
   character(len=:), allocatable                    :: segment     !< Current path segment.
   logical,      allocatable                        :: is_match(:) !< Flag of matching tags.
   integer(I4P)                                     :: t           !< Counter.

   allocate(ids(0))
   if (present(parent)) then
      if (parent<0.or.parent>nt) return
   endif
   if (present(path)) then
      rest = path
      call next_path_segment(rest=rest, segment=segment)
   elseif (present(name)) then
      rest = ''
      segment = name
   else
      return
   endif
   if (len(segment)==0) return
   ! first segment
   if (present(parent)) then
      ids = children_named(tag=tag, nt=nt, parents=[parent], name=segment)
   else
      allocate(is_match(nt)) ! a loop, not an implied-do mask: nvfortran evaluates the latter out of bounds
      do t=1, nt
         is_match(t) = tag(t)%name()==segment
      enddo
      ids = pack(tags_indexes(nt), is_match)
   endif
   ! following segments, direct children of the previous ones
   do while (len(rest)>0.and.size(ids)>0)
      call next_path_segment(rest=rest, segment=segment)
      if (len(segment)==0) exit
      ids = children_named(tag=tag, nt=nt, parents=ids, name=segment)
   enddo
   endfunction tree_find_all

   pure function tree_level(tag, nt, id) result(level)
   !< Return the level of the tag with ID *id* (1 for a root tag), 0 if it does not exist.
   type(xml_tag), allocatable, intent(in) :: tag(:) !< Tags.
   integer(I4P),               intent(in) :: nt     !< Number of tags.
   integer(I4P),               intent(in) :: id     !< Tag ID.
   integer(I4P)                           :: level  !< Tag level.

   level = 0
   if (id>=1.and.id<=nt) level = tag(id)%get_level()
   endfunction tree_level

   pure function tree_name(tag, nt, id) result(name)
   !< Return the name of the tag with ID *id*, an empty string if it does not exist.
   type(xml_tag), allocatable, intent(in) :: tag(:) !< Tags.
   integer(I4P),               intent(in) :: nt     !< Number of tags.
   integer(I4P),               intent(in) :: id     !< Tag ID.
   character(len=:), allocatable          :: name   !< Tag name.

   name = ''
   if (id>=1.and.id<=nt) name = tag(id)%name()
   endfunction tree_name

   pure function tree_parent(tag, nt, id) result(parent)
   !< Return the parent ID of the tag with ID *id* (0 for a root tag or if the tag does not exist).
   type(xml_tag), allocatable, intent(in) :: tag(:) !< Tags.
   integer(I4P),               intent(in) :: nt     !< Number of tags.
   integer(I4P),               intent(in) :: id     !< Tag ID.
   integer(I4P)                           :: parent !< Parent ID.

   parent = 0
   if (id>=1.and.id<=nt) parent = tag(id)%get_parent_id()
   endfunction tree_parent

   pure function tags_indexes(nt) result(indexes)
   !< Return the tags indexes [1:nt].
   integer(I4P), intent(in)  :: nt         !< Number of tags.
   integer(I4P), allocatable :: indexes(:) !< Tags indexes.
   integer(I4P)              :: t          !< Counter.

   indexes = [(t, t=1, nt)]
   endfunction tags_indexes

   ! private procedures
   pure function children_named(tag, nt, parents, name) result(ids)
   !< Return the IDs (in document order) of the tags named *name* that are direct children of any of *parents*.
   type(xml_tag), allocatable, intent(in) :: tag(:)       !< Tags.
   integer(I4P),               intent(in) :: nt           !< Number of tags.
   integer(I4P),               intent(in) :: parents(:)   !< Parents IDs, 0 for the document root.
   character(*),               intent(in) :: name         !< Tag name.
   integer(I4P), allocatable              :: ids(:)       !< Children IDs.
   logical,      allocatable              :: is_parent(:) !< Flag of parents, [0:nt].
   logical,      allocatable              :: is_match(:)  !< Flag of matching tags.
   integer(I4P)                           :: t            !< Counter.

   allocate(is_parent(0:nt), source=.false.)
   do t=1, size(parents, dim=1)
      is_parent(parents(t)) = .true.
   enddo
   allocate(is_match(nt), source=.false.)
   do t=1, nt
      if (is_parent(tag(t)%get_parent_id())) is_match(t) = tag(t)%name()==name
   enddo
   ids = pack(tags_indexes(nt), is_match)
   endfunction children_named

   pure subroutine next_path_segment(rest, segment)
   !< Pop the next not empty `/`-separated segment from a tags path.
   character(len=:), allocatable, intent(inout) :: rest    !< Path segments still to pop.
   character(len=:), allocatable, intent(out)   :: segment !< Popped segment, empty if there are no more.
   integer(I4P)                                 :: s       !< Separator position.

   segment = ''
   do while (len(rest)>0.and.len(segment)==0)
      s = index(rest, '/')
      if (s==0) then
         segment = rest
         rest = ''
      else
         segment = rest(:s-1)
         rest = rest(s+1:)
      endif
   enddo
   endsubroutine next_path_segment
endmodule foxy_xml_tree
