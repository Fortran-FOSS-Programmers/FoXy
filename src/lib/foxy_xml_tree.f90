!< FoXy tree queries: lookups over a linearized array of tags, shared by the DOM (*xml_file*) and the index (*xml_index*).
module foxy_xml_tree
!< FoXy tree queries: lookups over a linearized array of tags, shared by the DOM (*xml_file*) and the index (*xml_index*).
!<
!< The tags are stored in document order (start tags order); each tag knows its ID (its index), its parent ID (0 for a
!< root tag) and, once *tree_build_children* is called, its children IDs.
!<
!< Namespaces (Namespaces in XML 1.0) are resolved on demand, nothing is stored: the namespace of a tag is declared by
!< the nearest `xmlns:prefix` (or `xmlns`, for an unprefixed name) attribute of the tag or of its ancestors.
use foxy_xml_tag, only : xml_tag
use foxy_xml_values, only : XML_NOT_FOUND
use penf
use stringifor, only : regex, regex_match

implicit none
private
public :: tree_attribute
public :: tree_attribute_name
public :: tree_attributes_number
public :: tree_attribute_text
public :: tree_build_children
public :: tree_children
public :: tree_find
public :: tree_find_all
public :: tree_level
public :: tree_local_name
public :: tree_matching
public :: regex_matches
public :: tree_name
public :: tree_namespace
public :: tree_parent
public :: tree_prefix
public :: tags_indexes

character(*), parameter :: XML_NAMESPACE = 'http://www.w3.org/XML/1998/namespace' !< Namespace bound to the *xml* prefix.

type :: name_pattern
   !< A tag name to match: a literal name or, if *is_expanded*, a namespace and a local name.
   character(len=:), allocatable :: name                !< Literal name, or local name if *is_expanded*.
   character(len=:), allocatable :: uri                 !< Namespace (empty for no namespace) if *is_expanded*.
   logical                       :: is_expanded=.false. !< The name is expanded (namespace and local name).
   logical                       :: is_valid=.true.     !< The name can match (its prefix is declared).
endtype name_pattern

contains
   pure function tree_attribute_name(tag, nt, id, a) result(name)
   !< Return the name of the attribute with index *a* (source order) of the tag with ID *id*, empty if it does not exist.
   type(xml_tag), allocatable, intent(in) :: tag(:) !< Tags.
   integer(I4P),               intent(in) :: nt     !< Number of tags.
   integer(I4P),               intent(in) :: id     !< Tag ID.
   integer(I4P),               intent(in) :: a      !< Attribute index.
   character(len=:), allocatable          :: name   !< Attribute name.

   name = ''
   if (id>=1.and.id<=nt) name = tag(id)%get_attribute_name(a)
   endfunction tree_attribute_name

   pure function tree_attributes_number(tag, nt, id) result(number)
   !< Return the number of attributes of the tag with ID *id*, 0 if it does not exist.
   type(xml_tag), allocatable, intent(in) :: tag(:) !< Tags.
   integer(I4P),               intent(in) :: nt     !< Number of tags.
   integer(I4P),               intent(in) :: id     !< Tag ID.
   integer(I4P)                           :: number !< Number of attributes.

   number = 0
   if (id>=1.and.id<=nt) number = tag(id)%get_attributes_number()
   endfunction tree_attributes_number

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

   pure function tree_find_all(tag, nt, name, path, parent, namespaces) result(ids)
   !< Return the IDs of all tags (in document order) matching *name* or *path*.
   !<
   !< Matching rules:
   !<
   !< + *name*: tags named *name* at any depth or, if *parent* is passed, only the direct children of *parent*;
   !< + *path*: `/`-separated tags names; the first one is matched as *name*, each following one must be a direct child
   !<   of the previous one; all the tags matching a segment are explored, thus repeated parents are handled.
   !<
   !< Names are matched literally (prefix included), except:
   !<
   !< + `{uri}local` (Clark notation): tags with local name *local* in the namespace *uri* (`{}local`: in no namespace),
   !<   whatever their prefix;
   !< + if *namespaces* is passed, every name: its prefix is resolved by the declarations of *namespaces*, written as in
   !<   XML (e.g. `xmlns="uri1" xmlns:p="uri2"`), not by the document ones; an unprefixed name without a default
   !<   declaration is in no namespace, a prefix not declared matches nothing.
   !<
   !< @note If both *name* and *path* are passed, *path* is used; if none is passed, no tag is returned.
   type(xml_tag), allocatable, intent(in)           :: tag(:)     !< Tags.
   integer(I4P),               intent(in)           :: nt         !< Number of tags.
   character(*),               intent(in), optional :: name       !< Tag name.
   character(*),               intent(in), optional :: path       !< Tags path, e.g. `origin/latitude/value`.
   integer(I4P),               intent(in), optional :: parent     !< Parent tag ID, 0 for the document root.
   character(*),               intent(in), optional :: namespaces !< Namespaces declarations of the names prefixes.
   integer(I4P), allocatable                        :: ids(:)     !< Matching tags IDs, empty if there are none.

   ids = find_tags(tag=tag, nt=nt, name=name, path=path, parent=parent, namespaces=namespaces, is_first=.false.)
   endfunction tree_find_all

   pure function tree_find(tag, nt, name, path, parent, namespaces) result(id)
   !< Return the ID of the first tag (in document order) matching *name* or *path* (see *tree_find_all*), 0 if none; a
   !< name is searched up to its first match only.
   type(xml_tag), allocatable, intent(in)           :: tag(:)     !< Tags.
   integer(I4P),               intent(in)           :: nt         !< Number of tags.
   character(*),               intent(in), optional :: name       !< Tag name.
   character(*),               intent(in), optional :: path       !< Tags path, e.g. `origin/latitude/value`.
   integer(I4P),               intent(in), optional :: parent     !< Parent tag ID, 0 for the document root.
   character(*),               intent(in), optional :: namespaces !< Namespaces declarations of the names prefixes.
   integer(I4P)                                     :: id         !< First matching tag ID.
   integer(I4P), allocatable                        :: ids(:)     !< Matching tags IDs.

   ids = find_tags(tag=tag, nt=nt, name=name, path=path, parent=parent, namespaces=namespaces, is_first=.true.)
   id = 0_I4P
   if (size(ids)>0) id = ids(1)
   endfunction tree_find

   pure function tree_level(tag, nt, id) result(level)
   !< Return the level of the tag with ID *id* (1 for a root tag), 0 if it does not exist.
   type(xml_tag), allocatable, intent(in) :: tag(:) !< Tags.
   integer(I4P),               intent(in) :: nt     !< Number of tags.
   integer(I4P),               intent(in) :: id     !< Tag ID.
   integer(I4P)                           :: level  !< Tag level.

   level = 0
   if (id>=1.and.id<=nt) level = tag(id)%get_level()
   endfunction tree_level

   pure function tree_local_name(tag, nt, id) result(local_name)
   !< Return the local name (the name without prefix) of the tag with ID *id*, an empty string if it does not exist.
   type(xml_tag), allocatable, intent(in) :: tag(:)     !< Tags.
   integer(I4P),               intent(in) :: nt         !< Number of tags.
   integer(I4P),               intent(in) :: id         !< Tag ID.
   character(len=:), allocatable          :: local_name !< Tag local name.

   local_name = name_local(tree_name(tag=tag, nt=nt, id=id))
   endfunction tree_local_name

   pure function tree_matching(tag, nt, ids, re, on, attribute, whole) result(matched)
   !< Return the IDs of *ids* (in their order) whose name (*on*=`name`) or the value of *attribute* (*on*=`attribute`)
   !< matches the compiled regular expression *re* (anywhere, or the whole text with *whole*); a tag without the attribute
   !< never matches, a regex not compiled matches nothing.
   type(xml_tag), allocatable, intent(in) :: tag(:)     !< Tags.
   integer(I4P),               intent(in) :: nt         !< Number of tags.
   integer(I4P),               intent(in) :: ids(:)     !< Tags IDs to filter.
   type(regex),                intent(in) :: re         !< Compiled regular expression.
   character(*),               intent(in) :: on         !< What is matched: `name` or `attribute`.
   character(*),               intent(in) :: attribute  !< Attribute name (with *on*=`attribute`).
   logical,                    intent(in) :: whole      !< Match the whole text, not a part of it.
   integer(I4P), allocatable              :: matched(:) !< Matching IDs.
   integer(I4P), allocatable              :: buffer(:)  !< Matching IDs found.
   integer(I4P)                           :: n          !< Number of matching IDs.
   integer(I4P)                           :: i          !< Counter.
   logical                                :: is_match   !< The current tag matches.

   allocate(buffer(size(ids, dim=1)))
   n = 0
   if (re%is_compiled()) then
      do i=1, size(ids, dim=1)
         if (ids(i)<1.or.ids(i)>nt) cycle
         is_match = .false.
         if (on=='name') then
            is_match = regex_matches(re=re, subject=tag(ids(i))%name(), whole=whole)
         elseif (on=='attribute') then
            if (tag(ids(i))%is_attribute_present(name=attribute)) &
               is_match = regex_matches(re=re, subject=tag(ids(i))%get_attribute(name=attribute), whole=whole)
         endif
         if (is_match) then
            n = n + 1
            buffer(n) = ids(i)
         endif
      enddo
   endif
   matched = buffer(1:n)
   endfunction tree_matching

   pure function regex_matches(re, subject, whole) result(is_match)
   !< Return true if the compiled regular expression *re* matches a part of *subject* (the whole of it with *whole*).
   type(regex),  intent(in) :: re       !< Compiled regular expression.
   character(*), intent(in) :: subject  !< Subject.
   logical,      intent(in) :: whole    !< Match the whole subject.
   logical                  :: is_match !< Check result.
   type(regex_match)        :: found    !< Match.

   if (whole) then
      found = re%fullmatch(subject)
   else
      found = re%search(subject)
   endif
   is_match = found%found
   endfunction regex_matches

   pure function tree_name(tag, nt, id) result(name)
   !< Return the name of the tag with ID *id*, an empty string if it does not exist.
   type(xml_tag), allocatable, intent(in) :: tag(:) !< Tags.
   integer(I4P),               intent(in) :: nt     !< Number of tags.
   integer(I4P),               intent(in) :: id     !< Tag ID.
   character(len=:), allocatable          :: name   !< Tag name.

   name = ''
   if (id>=1.and.id<=nt) name = tag(id)%name()
   endfunction tree_name

   pure function tree_namespace(tag, nt, id) result(uri)
   !< Return the namespace of the tag with ID *id*: the value of the nearest declaration of its prefix (`xmlns:prefix`,
   !< or `xmlns` for an unprefixed name) on the tag or on its ancestors; the *xml* prefix is bound to its namespace.
   !<
   !< @note An empty string is returned for a tag in no namespace (unprefixed, without a default namespace declaration
   !< or with `xmlns=""`), for a prefix not declared and if the tag does not exist. A prefix cannot be declared empty
   !< (XML 1.0), thus a prefixed tag without namespace has its prefix not declared.
   type(xml_tag), allocatable, intent(in) :: tag(:)      !< Tags.
   integer(I4P),               intent(in) :: nt          !< Number of tags.
   integer(I4P),               intent(in) :: id          !< Tag ID.
   character(len=:), allocatable          :: uri         !< Namespace.
   logical                                :: is_declared !< The namespace is declared.

   call resolve_namespace(tag=tag, nt=nt, id=id, uri=uri, is_declared=is_declared)
   endfunction tree_namespace

   pure function tree_parent(tag, nt, id) result(parent)
   !< Return the parent ID of the tag with ID *id* (0 for a root tag or if the tag does not exist).
   type(xml_tag), allocatable, intent(in) :: tag(:) !< Tags.
   integer(I4P),               intent(in) :: nt     !< Number of tags.
   integer(I4P),               intent(in) :: id     !< Tag ID.
   integer(I4P)                           :: parent !< Parent ID.

   parent = 0
   if (id>=1.and.id<=nt) parent = tag(id)%get_parent_id()
   endfunction tree_parent

   pure function tree_prefix(tag, nt, id) result(prefix)
   !< Return the prefix of the name of the tag with ID *id*, an empty string if it has none or it does not exist.
   type(xml_tag), allocatable, intent(in) :: tag(:) !< Tags.
   integer(I4P),               intent(in) :: nt     !< Number of tags.
   integer(I4P),               intent(in) :: id     !< Tag ID.
   character(len=:), allocatable          :: prefix !< Tag name prefix.

   prefix = name_prefix(tree_name(tag=tag, nt=nt, id=id))
   endfunction tree_prefix

   pure function tags_indexes(nt) result(indexes)
   !< Return the tags indexes [1:nt].
   integer(I4P), intent(in)  :: nt         !< Number of tags.
   integer(I4P), allocatable :: indexes(:) !< Tags indexes.
   integer(I4P)              :: t          !< Counter.

   indexes = [(t, t=1, nt)]
   endfunction tags_indexes

   ! private procedures
   pure function find_tags(tag, nt, name, path, parent, namespaces, is_first) result(ids)
   !< Return the IDs of the tags (in document order) matching *name* or *path* (see *tree_find_all*), only the first one
   !< if *is_first*.
   type(xml_tag), allocatable, intent(in)           :: tag(:)       !< Tags.
   integer(I4P),               intent(in)           :: nt           !< Number of tags.
   character(*),               intent(in), optional :: name         !< Tag name.
   character(*),               intent(in), optional :: path         !< Tags path, e.g. `origin/latitude/value`.
   integer(I4P),               intent(in), optional :: parent       !< Parent tag ID, 0 for the document root.
   character(*),               intent(in), optional :: namespaces   !< Namespaces declarations of the names prefixes.
   logical,                    intent(in)           :: is_first     !< Only the first match is needed.
   integer(I4P), allocatable                        :: ids(:)       !< Matching tags IDs, empty if there are none.
   type(xml_tag)                                    :: declarations !< Namespaces declarations, as attributes.
   logical                                          :: is_first_    !< Stop at the first match of the first segment.
   type(name_pattern)                               :: pattern      !< Current name to match.
   character(len=:), allocatable                    :: rest         !< Path segments still to match.
   character(len=:), allocatable                    :: segment      !< Current path segment.
   integer(I4P), allocatable                        :: buffer(:)    !< Matching tags IDs found.
   integer(I4P)                                     :: n            !< Number of matching tags found.
   integer(I4P)                                     :: t            !< Counter.

   allocate(ids(0))
   if (present(namespaces)) declarations = xml_tag(name='_', attributes_stream=namespaces)
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
   pattern = name_pattern_of(name=segment, declarations=declarations, is_mapped=present(namespaces))
   is_first_ = is_first.and.len(rest)==0 ! a path needs all the candidates of its first segment
   if (present(parent)) then
      ids = children_named(tag=tag, nt=nt, parents=[parent], pattern=pattern, is_first=is_first_)
   else
      allocate(buffer(nt))
      n = 0
      do t=1, nt
         if (is_matching(tag=tag, nt=nt, id=t, pattern=pattern)) then
            n = n + 1
            buffer(n) = t
            if (is_first_) exit
         endif
      enddo
      ids = buffer(1:n)
   endif
   ! following segments, direct children of the previous ones
   do while (len(rest)>0.and.size(ids)>0)
      call next_path_segment(rest=rest, segment=segment)
      if (len(segment)==0) exit
      pattern = name_pattern_of(name=segment, declarations=declarations, is_mapped=present(namespaces))
      ids = children_named(tag=tag, nt=nt, parents=ids, pattern=pattern, is_first=.false.)
   enddo
   endfunction find_tags

   pure function children_named(tag, nt, parents, pattern, is_first) result(ids)
   !< Return the IDs (in document order) of the tags matching *pattern* that are direct children of any of *parents* (only
   !< the first one if *is_first*, for a single parent).
   !<
   !< @note The children lists of the parents are walked (the roots, for parent 0, by a sweep): the cost is the number of
   !< children, not of tags. Children of different parents are sorted if needed (nested parents interleave them).
   type(xml_tag), allocatable, intent(in) :: tag(:)     !< Tags.
   integer(I4P),               intent(in) :: nt         !< Number of tags.
   integer(I4P),               intent(in) :: parents(:) !< Parents IDs (in document order, distinct), 0 for the root.
   type(name_pattern),         intent(in) :: pattern    !< Tag name to match.
   logical,                    intent(in) :: is_first   !< Only the first match is needed.
   integer(I4P), allocatable              :: ids(:)     !< Children IDs.
   integer(I4P), allocatable              :: buffer(:)  !< Matching children IDs found.
   integer(I4P)                           :: n          !< Number of matching children found.
   integer(I4P)                           :: total      !< Number of children to check.
   integer(I4P)                           :: p          !< Counter.
   integer(I4P)                           :: c          !< Counter.
   integer(I4P)                           :: t          !< Tag ID.

   total = 0
   do p=1, size(parents, dim=1)
      if (parents(p)==0) then
         total = total + nt
      elseif (parents(p)>0.and.parents(p)<=nt) then
         total = total + tag(parents(p))%children_number
      endif
   enddo
   allocate(buffer(total))
   n = 0
   parents_loop: do p=1, size(parents, dim=1)
      if (parents(p)==0) then
         do t=1, nt
            if (tag(t)%get_parent_id()/=0) cycle
            if (is_matching(tag=tag, nt=nt, id=t, pattern=pattern)) then
               n = n + 1
               buffer(n) = t
               if (is_first) exit parents_loop
            endif
         enddo
      elseif (parents(p)>0.and.parents(p)<=nt) then
         do c=1, tag(parents(p))%children_number
            t = tag(parents(p))%child_id(c)
            if (is_matching(tag=tag, nt=nt, id=t, pattern=pattern)) then
               n = n + 1
               buffer(n) = t
               if (is_first) exit parents_loop
            endif
         enddo
      endif
   enddo parents_loop
   ids = buffer(1:n)
   if (size(parents, dim=1)>1) then
      if (any(ids(2:n)<ids(1:n-1))) call merge_sort(ids)
   endif
   endfunction children_named

   pure recursive subroutine merge_sort(ids)
   !< Sort IDs in increasing order (merge sort, O(n log n)).
   integer(I4P), intent(inout) :: ids(:)   !< IDs.
   integer(I4P), allocatable   :: merged(:) !< Merged halves.
   integer(I4P)                :: n        !< Number of IDs.
   integer(I4P)                :: h        !< Half size.
   integer(I4P)                :: i        !< First half counter.
   integer(I4P)                :: j        !< Second half counter.
   integer(I4P)                :: k        !< Merged counter.

   n = size(ids, dim=1)
   if (n<2) return
   h = n / 2
   call merge_sort(ids(1:h))
   call merge_sort(ids(h+1:n))
   allocate(merged(n))
   i = 1
   j = h + 1
   do k=1, n
      if (j>n) then
         merged(k) = ids(i) ; i = i + 1
      elseif (i>h) then
         merged(k) = ids(j) ; j = j + 1
      elseif (ids(i)<=ids(j)) then
         merged(k) = ids(i) ; i = i + 1
      else
         merged(k) = ids(j) ; j = j + 1
      endif
   enddo
   ids = merged
   endsubroutine merge_sort

   pure function declaration_name(prefix) result(name)
   !< Return the name of the attribute declaring the namespace of *prefix* (`xmlns` for no prefix).
   character(*), intent(in)      :: prefix !< Prefix.
   character(len=:), allocatable :: name   !< Declaration attribute name.

   if (len(prefix)==0) then
      name = 'xmlns'
   else
      name = 'xmlns:'//prefix
   endif
   endfunction declaration_name

   pure function is_matching(tag, nt, id, pattern) result(is_match)
   !< Return true if the tag with ID *id* matches *pattern*; an expanded name is checked on the local name first, the
   !< namespace (resolved through the ancestors) only if the local name matches.
   type(xml_tag), allocatable, intent(in) :: tag(:)      !< Tags.
   integer(I4P),               intent(in) :: nt          !< Number of tags.
   integer(I4P),               intent(in) :: id          !< Tag ID.
   type(name_pattern),         intent(in) :: pattern     !< Tag name to match.
   logical                                :: is_match    !< Matching flag.
   character(len=:), allocatable          :: uri         !< Tag namespace.
   logical                                :: is_declared !< The tag namespace is declared.

   if (.not.pattern%is_valid) then
      is_match = .false.
   elseif (.not.pattern%is_expanded) then
      is_match = tag(id)%is_named(pattern%name)
   else
      is_match = name_local(tag(id)%name())==pattern%name
      if (is_match) then
         call resolve_namespace(tag=tag, nt=nt, id=id, uri=uri, is_declared=is_declared)
         is_match = is_declared.and.uri==pattern%uri
      endif
   endif
   endfunction is_matching

   pure function name_local(name) result(local_name)
   !< Return the local name of a (qualified) name, `prefix:local`.
   character(*), intent(in)      :: name       !< Name.
   character(len=:), allocatable :: local_name !< Local name.

   local_name = name(index(name, ':')+1:)
   endfunction name_local

   pure function name_pattern_of(name, declarations, is_mapped) result(pattern)
   !< Return the pattern matching *name*: expanded if *name* is in Clark notation (`{uri}local`) or if *is_mapped* (its
   !< prefix resolved by *declarations*), literal otherwise.
   character(*),  intent(in)     :: name         !< Name (not empty).
   type(xml_tag), intent(in)     :: declarations !< Namespaces declarations, as attributes (used if *is_mapped*).
   logical,       intent(in)     :: is_mapped    !< Resolve the name prefix by *declarations*.
   type(name_pattern)            :: pattern      !< Name pattern.
   character(len=:), allocatable :: prefix       !< Name prefix.
   integer(I4P)                  :: c            !< Closing brace position.

   if (name(1:1)=='{') then
      pattern%is_expanded = .true.
      c = index(name, '}')
      pattern%is_valid = c>0
      pattern%uri = name(2:max(1, c-1))
      pattern%name = name(c+1:)
      if (c==0) pattern%name = ''
   elseif (is_mapped) then
      pattern%is_expanded = .true.
      prefix = name_prefix(name)
      pattern%name = name_local(name)
      if (prefix=='xml') then
         pattern%uri = XML_NAMESPACE
      else
         pattern%uri = declarations%get_attribute(name=declaration_name(prefix))
         if (len(prefix)>0) pattern%is_valid = declarations%is_attribute_present(name=declaration_name(prefix))
      endif
   else
      pattern%name = name
   endif
   endfunction name_pattern_of

   pure function name_prefix(name) result(prefix)
   !< Return the prefix of a (qualified) name, `prefix:local`, empty if it has none.
   character(*), intent(in)      :: name   !< Name.
   character(len=:), allocatable :: prefix !< Prefix.

   prefix = name(:index(name, ':')-1)
   endfunction name_prefix

   pure subroutine resolve_namespace(tag, nt, id, uri, is_declared)
   !< Resolve the namespace of the tag with ID *id* (see *tree_namespace*); *is_declared* is false for a prefix not
   !< declared or a tag that does not exist.
   type(xml_tag), allocatable,    intent(in)  :: tag(:)      !< Tags.
   integer(I4P),                  intent(in)  :: nt          !< Number of tags.
   integer(I4P),                  intent(in)  :: id          !< Tag ID.
   character(len=:), allocatable, intent(out) :: uri         !< Namespace, empty for no namespace.
   logical,                       intent(out) :: is_declared !< The namespace is declared.
   character(len=:), allocatable              :: prefix      !< Tag name prefix.
   character(len=:), allocatable              :: declaration !< Name of the declaration attribute.
   integer(I4P)                               :: a           !< Current ancestor ID.
   integer(I4P)                               :: s           !< Steps counter (bounds the walk).

   uri = ''
   is_declared = .false.
   if (id<1.or.id>nt) return
   prefix = name_prefix(tag(id)%name())
   if (prefix=='xml') then
      uri = XML_NAMESPACE
      is_declared = .true.
      return
   elseif (prefix=='xmlns') then ! reserved for declarations, not a tag prefix
      return
   endif
   declaration = declaration_name(prefix)
   a = id
   do s=1, nt
      if (a<1.or.a>nt) exit
      if (tag(a)%is_attribute_present(name=declaration)) then
         uri = tag(a)%get_attribute(name=declaration)
         is_declared = .true.
         return
      endif
      a = tag(a)%get_parent_id()
   enddo
   is_declared = len(prefix)==0 ! no default namespace declaration: no namespace
   endsubroutine resolve_namespace

   pure subroutine next_path_segment(rest, segment)
   !< Pop the next not empty `/`-separated segment from a tags path; a `/` between braces (a namespace in Clark notation)
   !< is not a separator.
   character(len=:), allocatable, intent(inout) :: rest    !< Path segments still to pop.
   character(len=:), allocatable, intent(out)   :: segment !< Popped segment, empty if there are no more.
   integer(I4P)                                 :: s       !< Separator position.

   segment = ''
   do while (len(rest)>0.and.len(segment)==0)
      s = separator_position(rest)
      if (s==0) then
         segment = rest
         rest = ''
      else
         segment = rest(:s-1)
         rest = rest(s+1:)
      endif
   enddo
   endsubroutine next_path_segment

   pure function separator_position(path) result(s)
   !< Return the position of the first `/` of *path* not between braces, 0 if there is none.
   character(*), intent(in) :: path        !< Tags path.
   integer(I4P)             :: s           !< Separator position.
   logical                  :: is_in_brace !< The current character is between braces.

   is_in_brace = .false.
   do s=1, len(path)
      select case(path(s:s))
      case('{')
         is_in_brace = .true.
      case('}')
         is_in_brace = .false.
      case('/')
         if (.not.is_in_brace) return
      endselect
   enddo
   s = 0
   endfunction separator_position
endmodule foxy_xml_tree
