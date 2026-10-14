!< FoXy XML tag class.
module foxy_xml_tag
!< FoXy XML tag class.
use foxy_xml_entities, only : xml_unescape
use foxy_xml_tokenizer, only : xml_builder, xml_tokenizer
use penf
use stringifor

implicit none
private
public :: xml_tag

type :: xml_tag
   !< XML tag class.
   !<
   !< A valid XML tag must have the following syntax for a tag without a content (with only attributes):
   !<```xml
   !<   <Tag_Name att#1_Name="att#1_val" att#2_Name="att#2_val"... att#Nt_Name="att#Nt_val"/>
   !<```
   !< while a tag with a content must have the following syntax:
   !<```xml
   !<   <Tag_Name att#1_Name="att#1_val" att#2_Name="att#2_val"... att#Nt_Name="att#Nt_val">Tag_Content</Tag_Name>
   !<```
   !<
   !< It is worth noting that the syntax is case sensitive and that the attributes are optional. Sources (*parse*,
   !< *get_content*, attributes streams) are read by the document tokenizer: attribute values are single or double quoted,
   !< blanks are allowed around `=`.
   private
   type(string)                      :: tag_name                   !< Tag name.
   type(string)                      :: tag_content                !< Tag content.
   type(string)                      :: tag_tail                   !< Text after the end tag, up to the next sibling or the
                                                                   !< parent end tag (mixed content).
   integer(I8P)                      :: pos(3)=[0_I8P,0_I8P,0_I8P] !< Characters position (in source) indexes (start, content, end).
   type(string), allocatable         :: attribute(:,:)             !< Attributes names/values pairs, [1:2, 1:].
   integer(I4P)                      :: attributes_number=0_I4P    !< Number of defined attributes.
   integer(I4P)                      :: indent=0_I4P               !< Number of indent-white-spaces.
   logical                           :: is_self_closing=.false.    !< Self closing tag flag.
   integer(I4P)                      :: level=0_I4P                !< Tag hierarchy level.
   integer(I4P)                      :: id=0_I4P                   !< Uniq tag ID.
   integer(I4P)                      :: parent_id=0_I4P            !< Uniq ID of parent tag.
   integer(I4P), public              :: children_number=0_I4P      !< Number of children tags.
   integer(I4P), public, allocatable :: child_id(:)                !< Uniq ID of children tags.
   contains
      ! public methods
      generic               :: add_attributes =>        &
                               add_single_attribute,    &
                               add_multiple_attributes, &
                               add_stream_attributes       !< Add attributes name/value pairs.
      procedure, pass(self) :: add_child_id                !< Add child ID to children IDs list.
      procedure, pass(self) :: attributes                  !< Return attributes name/value pairs as string.
      generic               :: delete_attributes =>     &
                               delete_single_attribute, &
                               delete_multiple_attributes  !< Delete attributes name/value pairs.
      procedure, pass(self) :: delete_content              !< Delete tag conent.
      procedure, pass(self) :: end_tag                     !< Return `</tag_name>` end tag.
      procedure, pass(self) :: free                        !< Free (reset) tag.
      procedure, pass(self) :: get_content                 !< Return tag content.
      procedure, pass(self) :: get_attribute               !< Return the value of the attribute named *name*.
      procedure, pass(self) :: get_id                      !< Return tag uniq ID.
      procedure, pass(self) :: get_indent                  !< Return tag indentation.
      procedure, pass(self) :: get_level                   !< Return tag hierarchy level.
      procedure, pass(self) :: get_parent_id               !< Return parent tag uniq ID.
      procedure, pass(self) :: get_pos                     !< Return tag positions in the source.
      procedure, pass(self) :: get_tail                    !< Return the text after the end tag.
      procedure, pass(self) :: is_attribute_present        !< Return .true. it the queried attribute name is defined.
      procedure, pass(self) :: is_parsed                   !< Check is tag is correctly parsed, i.e. its *tag_name* is allocated.
      procedure, pass(self) :: name                        !< Return tag name.
      procedure, pass(self) :: parse                       !< Parse the tag contained into a source string.
      procedure, pass(self) :: self_closing_tag            !< Return `<tag_name.../>` self closing tag.
      procedure, pass(self) :: set                         !< Set tag data.
      procedure, pass(self) :: start_tag                   !< Return `<tag_name...>` start tag.
      procedure, pass(self) :: stringify                   !< Convert the whole tag into a string.
      procedure, pass(self) :: write => write_tag          !< Write tag to unit file.
      generic               :: assignment(=) => assign_tag !< Assignment operator overloading.
      ! private methods
      procedure, pass(self), private :: add_single_attribute       !< Add one attribute name/value pair.
      procedure, pass(self), private :: add_attribute_value        !< Add one attribute, value stored exactly.
      procedure, pass(self), private :: add_multiple_attributes    !< Add list of attributes name/value pairs.
      procedure, pass(self), private :: add_stream_attributes      !< Add list of attributes name/value pairs passed as stream.
      procedure, pass(self), private :: delete_single_attribute    !< Delete one attribute name/value pair.
      procedure, pass(self), private :: delete_multiple_attributes !< Delete list of attributes name/value pairs.
      ! operators
      procedure, pass(lhs), private :: assign_tag !< Assignment between two tags.
      final                         :: finalize   !< Free dynamic memory when finalizing.
endtype xml_tag

interface xml_tag
   !< Overload *xml_tag* with creator procedures.
   module procedure create_tag_flat, create_tag_nested
endinterface

type, extends(xml_builder) :: tag_builder
   !< Builder of a single tag of a source, driven by the tokenizer: the first tag or, if *name* is allocated, the first tag
   !< with that name (tags inside CDATA sections, comments and PIs excluded); the tokenizer stops once it is complete.
   character(len=:), allocatable :: name                   !< Name of the searched tag, unallocated for the first tag.
   logical                       :: sanitize=.false.       !< Trim leading and trailing spaces of attribute values.
   type(xml_tag)                 :: tag                    !< Found tag: name and attributes.
   integer(I4P)                  :: id=0_I4P               !< Tokenizer ID of the found tag, 0 if none.
   integer(I8P)                  :: start=0_I8P            !< Position of the start tag `<`.
   integer(I8P)                  :: open_end=0_I8P         !< Position of the start tag `>`, 0 if unterminated.
   integer(I8P)                  :: end_start=0_I8P        !< Position of the end tag `<`, 0 if none.
   integer(I8P)                  :: end_end=0_I8P          !< Position of the end tag `>`, 0 if none.
   logical                       :: is_self_closing=.false. !< The found tag is self closing.
   contains
      procedure, pass(self) :: start_tag     => tag_start_tag     !< A start tag begins.
      procedure, pass(self) :: attribute     => tag_attribute     !< An attribute of the current start tag.
      procedure, pass(self) :: start_tag_end => tag_start_tag_end !< The current start tag is complete.
      procedure, pass(self) :: end_tag       => tag_end_tag       !< An open tag is closed by its end tag.
      procedure, pass(self) :: data          => tag_data          !< Character data or other markup: ignored.
      procedure, pass(self) :: problem       => tag_problem       !< A problem of malformed input: ignored.
endtype tag_builder
contains
   ! creator procedures overloading *xml_tag* name
   pure function create_tag_flat(name, attribute, attributes, attributes_stream, sanitize_attributes_value, pos, content,     &
                                 indent, is_content_indented, is_self_closing, id, level, parent_id, attributes_stream_alloc, &
                                 content_alloc) result(tag)
   !< Return an instance of xml tag.
   character(*),              intent(in)           :: name                      !< Tag name.
   character(*),              intent(in), optional :: attribute(1:)             !< Attribute name/value pair [1:2].
   character(*),              intent(in), optional :: attributes(1:,1:)         !< Attributes list of name/value pairs [1:2,1:].
   character(*),              intent(in), optional :: attributes_stream         !< Attributes list as single stream.
   logical,                   intent(in), optional :: sanitize_attributes_value !< Sanitize attributes value.
   integer(I8P),              intent(in), optional :: pos(1:)                   !< Characters position (in source) indexes.
   character(*),              intent(in), optional :: content                   !< Tag value.
   integer(I4P),              intent(in), optional :: indent                    !< Number of indent-white-spaces.
   logical,                   intent(in), optional :: is_content_indented       !< Activate content indentation.
   logical,                   intent(in), optional :: is_self_closing           !< The tag is self closing.
   integer(I4P),              intent(in), optional :: id                        !< Uniq ID.
   integer(I4P),              intent(in), optional :: level                     !< Tag hierarchy level.
   integer(I4P),              intent(in), optional :: parent_id                 !< Parent uniq ID.
   character(:), allocatable, intent(in), optional :: attributes_stream_alloc   !< Attributes list stream, allocatable input.
   character(:), allocatable, intent(in), optional :: content_alloc             !< Tag value, allocatable input.
   type(xml_tag)                                   :: tag                       !< XML tag.

   call tag%set(name=name,                                           &
                attribute=attribute,                                 &
                attributes=attributes,                               &
                attributes_stream=attributes_stream,                 &
                sanitize_attributes_value=sanitize_attributes_value, &
                content=content,                                     &
                pos=pos,                                             &
                indent=indent,                                       &
                is_content_indented=is_content_indented,             &
                is_self_closing=is_self_closing,                     &
                id=id,                                               &
                level=level,                                         &
                parent_id=parent_id,                                 &
                attributes_stream_alloc=attributes_stream_alloc,     &
                content_alloc=content_alloc)
   endfunction create_tag_flat

   pure function create_tag_nested(name, content, attribute, attributes, attributes_stream, sanitize_attributes_value, pos, indent,&
                                   is_content_indented, id, level, parent_id, attributes_stream_alloc, content_alloc) result(tag)
   !< Return an instance of xml tag with value being a nested tag.
   character(*),              intent(in)           :: name                      !< Tag name.
   type(xml_tag),             intent(in)           :: content                   !< Tag value as nested tag..
   character(*),              intent(in), optional :: attribute(1:)             !< Attribute name/value pair [1:2].
   character(*),              intent(in), optional :: attributes(1:,1:)         !< Attributes list of name/value pairs [1:2,1:].
   character(*),              intent(in), optional :: attributes_stream         !< Attributes list as single stream.
   logical,                   intent(in), optional :: sanitize_attributes_value !< Sanitize attributes value.
   integer(I8P),              intent(in), optional :: pos(1:)                   !< Characters position (in source) indexes.
   integer(I4P),              intent(in), optional :: indent                    !< Number of indent-white-spaces.
   logical,                   intent(in), optional :: is_content_indented       !< Activate value indentation.
   integer(I4P),              intent(in), optional :: id                        !< Uniq ID.
   integer(I4P),              intent(in), optional :: level                     !< Tag hierarchy level.
   integer(I4P),              intent(in), optional :: parent_id                 !< Parent uniq ID.
   character(:), allocatable, intent(in), optional :: attributes_stream_alloc   !< Attributes list stream, allocatable input.
   character(:), allocatable, intent(in), optional :: content_alloc             !< Tag value, allocatable input.
   type(xml_tag)                                   :: tag                       !< XML tag.

   call tag%set(name=name,                                           &
                attribute=attribute,                                 &
                attributes=attributes,                               &
                content=content%stringify(),                         &
                sanitize_attributes_value=sanitize_attributes_value, &
                attributes_stream=attributes_stream,                 &
                pos=pos,                                             &
                indent=indent,                                       &
                is_content_indented=is_content_indented,             &
                id=id,                                               &
                level=level,                                         &
                parent_id=parent_id,                                 &
                attributes_stream_alloc=attributes_stream_alloc,     &
                content_alloc=content_alloc)
   endfunction create_tag_nested

   ! public methods
   pure subroutine add_child_id(self, child_id)
   !< Add child ID to children IDs list.
   class(xml_tag), intent(inout) :: self     !< XML tag.
   integer(I4P),   intent(in)    :: child_id !< Child ID.

   if (allocated(self%child_id)) then
      self%child_id = [self%child_id, child_id]
   else
      self%child_id = [child_id]
   endif
   self%children_number = size(self%child_id)
   endsubroutine add_child_id

   pure function attributes(self) result(att_)
   !< Return attributes name/value pairs as string.
   class(xml_tag), intent(in)    :: self !< XML tag.
   character(len=:), allocatable :: att_ !< The attributes string.
   integer(I4P)                  :: a    !< Counter.

   if (self%attributes_number>0) then
      att_ = ''
      do a=1, self%attributes_number
         att_ = att_//' '//self%attribute(1, a)//'="'//self%attribute(2, a)//'"'
      enddo
      att_ = trim(adjustl(att_))
   endif
   endfunction attributes

   pure function end_tag(self, is_indented) result(tag_)
   !< Return `</tag_name>` end tag.
   class(xml_tag), intent(in)           :: self        !< XML tag.
   logical,        intent(in), optional :: is_indented !< Activate content indentation.
   character(len=:), allocatable        :: tag_        !< The end tag string.

   tag_ = '</'//self%tag_name//'>'
   if (present(is_indented)) then
      if (is_indented) tag_ = repeat(' ', self%indent)//tag_
   endif
   endfunction end_tag

   elemental subroutine free(self)
   !< Free (reset) tag.
   class(xml_tag), intent(inout) :: self !< XML tag.
   integer(I4P)                  :: i,j  !< Counter.

   call self%tag_name%free
   call self%tag_content%free
   call self%tag_tail%free
   self%pos = 0_I8P
   if (allocated(self%attribute)) then
      do j=1, size(self%attribute, dim=2)
         do i=1, size(self%attribute, dim=1)
            call self%attribute(i,j)%free
         enddo
      enddo
      deallocate(self%attribute)
      self%attributes_number = 0_I4P
   endif
   self%indent = 0_I4P
   self%is_self_closing = .false.
   self%level = 0_I4P
   self%id = 0_I4P
   self%parent_id = 0_I4P
   self%children_number = 0_I4P
   if (allocated(self%child_ID)) deallocate(self%child_ID)
   endsubroutine free

   pure subroutine get_content(self, name, content)
   !< Return tag content of self (or its nested tags) if named *name*.
   !<
   !< @note A nested tag is the first tag named *name* in the content string (tags inside CDATA sections, comments and
   !< PIs excluded); its content is returned raw, as in the string.
   !< @note If there is no value, the *content* string is returned deallocated.
   class(xml_tag),                intent(in)  :: self    !< XML tag.
   character(*),                  intent(in)  :: name    !< Searched tag name.
   character(len=:), allocatable, intent(out) :: content !< Tag content.
   type(tag_builder)                          :: builder !< Single tag builder.

   if (self%tag_name%is_allocated()) then
      if (self%tag_name==name) then
         if (self%tag_content%is_allocated()) content = self%tag_content%chars()
      else
         if (self%tag_content%is_allocated()) then
            call scan_tag(source=self%tag_content%chars(), name=name, sanitize=.false., builder=builder)
            if (builder%id>0) call tag_content(source=self%tag_content%chars(), builder=builder, content=content)
         endif
      endif
   endif
   endsubroutine get_content

   pure function get_attribute(self, name) result(value)
   !< Return the value of the attribute named *name*.
   !<
   !< @note If the attribute is not defined (or has no value), an empty string is returned. The value is normalized as by
   !< XML 1.0 (3.3.3), for attributes of CDATA type: each literal blank (tab, new line, carriage return, a CR LF pair as one)
   !< becomes a space, then character references are decoded (blanks written as references are kept).
   class(xml_tag), intent(in)    :: self  !< XML tag.
   character(*),   intent(in)    :: name  !< Attribute name.
   character(len=:), allocatable :: value !< Attribute value.
   integer(I4P)                  :: a     !< Counter.

   value = ''
   do a=1, self%attributes_number
      if (self%attribute(1, a)==name) then
         if (self%attribute(2, a)%is_allocated()) value = xml_unescape(blanks_as_spaces(self%attribute(2, a)%chars()))
         exit
      endif
   enddo
   endfunction get_attribute

   elemental function get_id(self) result(id)
   !< Return tag uniq ID.
   class(xml_tag), intent(in) :: self !< XML tag.
   integer(I4P)               :: id   !< Tag uniq ID.

   id = self%id
   endfunction get_id

   pure function get_tail(self) result(tail)
   !< Return the text after the end tag (mixed content), an empty string if none.
   class(xml_tag), intent(in)    :: self !< XML tag.
   character(len=:), allocatable :: tail !< Text after the end tag.

   tail = ''
   if (self%tag_tail%is_allocated()) tail = self%tag_tail%chars()
   endfunction get_tail

   elemental function get_parent_id(self) result(parent_id)
   !< Return parent tag uniq ID.
   class(xml_tag), intent(in) :: self      !< XML tag.
   integer(I4P)               :: parent_id !< Parent tag uniq ID, 0 for a root tag.

   parent_id = self%parent_id
   endfunction get_parent_id

   elemental function get_indent(self) result(indent)
   !< Return tag indentation (number of spaces).
   class(xml_tag), intent(in) :: self   !< XML tag.
   integer(I4P)               :: indent !< Tag indentation.

   indent = self%indent
   endfunction get_indent

   elemental function get_level(self) result(level)
   !< Return tag hierarchy level.
   class(xml_tag), intent(in) :: self  !< XML tag.
   integer(I4P)               :: level !< Tag hierarchy level, 1 for a root tag.

   level = self%level
   endfunction get_level

   pure function get_pos(self) result(pos)
   !< Return tag positions in the source: start tag `<`, start tag `>`, end tag `<` (-1 if self closing, 0 if unclosed).
   class(xml_tag), intent(in) :: self   !< XML tag.
   integer(I8P)               :: pos(3) !< Positions.

   pos = self%pos
   endfunction get_pos

   pure function is_attribute_present(self, name) result(is_present)
   !< Return .true. it the queried attribute name is defined, .false. otherwise.
   class(xml_tag), intent(in) :: self       !< XML tag.
   character(*),   intent(in) :: name       !< Attribute name.
   logical                    :: is_present !< Inquire result.
   integer(I4P)               :: a          !< Counter.

   is_present = .false.
   if (self%attributes_number>0) then
      do a=1, self%attributes_number
         if (self%attribute(1, a)==name) then
            is_present = .true.
            exit
         endif
      enddo
   endif
   endfunction is_attribute_present

   elemental function is_parsed(self)
   !< Check is tag is correctly parsed, i.e. its *tag_name* is allocated.
   class(xml_tag), intent(in) :: self      !< XML tag.
   logical                    :: is_parsed !< Result of check.

   is_parsed = self%tag_name%is_allocated()
   endfunction is_parsed

   pure function name(self)
   !< Return tag name.
   class(xml_tag), intent(in)    :: self !< XML tag.
   character(len=:), allocatable :: name !< XML tag name.

   name = self%tag_name%chars()
   endfunction name

   elemental subroutine parse(self, source, tstart, tend)
   !< Parse the first tag contained into a source string: its name, attributes (values as in the source) and content (raw,
   !< nested tags included); the other tags eventually present are omitted.
   !<
   !< Valid syntax are:
   !< + `<tag_name att1="att1 val" att2='att2 val'...>...</tag_name>`
   !< + `<tag_name att1="att1 val" att2='att2 val'.../>`
   !<
   !< @note The source is read by the document tokenizer: `<`, `>`, `=` and the other quote kind are allowed in attribute
   !< values, the content ends at the matching end tag (nested tags with the same name included) or, if the tag is
   !< unclosed, at the source end. The tag positions *pos* are set; the name, attributes and content are replaced (the
   !< name is unallocated if there is no tag).
   class(xml_tag),         intent(inout) :: self    !< XML tag.
   character(*),           intent(in)    :: source  !< String containing the input.
   integer(I8P), optional, intent(out)   :: tstart  !< Starting index of tag inside the string, 0 if there is no tag.
   integer(I8P), optional, intent(out)   :: tend    !< Ending index of tag inside the string, 0 if there is no tag.
   type(tag_builder)                     :: builder !< Single tag builder.
   character(len=:), allocatable         :: content !< Tag content.
   integer(I8P)                          :: tend_   !< Ending index of tag inside the string, local variable.

   call scan_tag(source=source, sanitize=.false., builder=builder)
   call self%tag_name%free
   call self%tag_content%free
   if (allocated(self%attribute)) deallocate(self%attribute)
   self%attributes_number = 0_I4P
   self%is_self_closing = .false.
   tend_ = 0_I8P
   if (builder%id>0) then
      self%tag_name = builder%tag%tag_name
      if (builder%tag%attributes_number>0) self%attribute = builder%tag%attribute(:, 1:builder%tag%attributes_number)
      self%attributes_number = builder%tag%attributes_number
      self%is_self_closing = builder%is_self_closing
      call tag_content(source=source, builder=builder, content=content)
      if (allocated(content)) self%tag_content = content
      if (builder%is_self_closing) then
         self%pos = [builder%start, builder%open_end, -1_I8P]
         tend_ = builder%open_end
      elseif (builder%end_end>0) then
         self%pos = [builder%start, builder%open_end, builder%end_start]
         tend_ = builder%end_end
      else
         self%pos = [builder%start, builder%open_end, 0_I8P]
         tend_ = len(source, kind=I8P)
      endif
   endif
   if (present(tstart)) tstart = builder%start
   if (present(tend  )) tend   = tend_
   endsubroutine parse


   pure subroutine set(self, name, attribute, attributes, attributes_stream, sanitize_attributes_value, content, &
                       pos, indent, is_content_indented, is_self_closing, id, level, parent_id,                  &
                       attributes_stream_alloc, content_alloc, tail, attribute_name, attribute_value)
   !< Set tag data.
   class(xml_tag),            intent(inout)        :: self                      !< XML tag.
   character(*),              intent(in), optional :: name                      !< Tag name.
   character(*),              intent(in), optional :: attribute(1:)             !< Attribute name/value pair [1:2].
   character(*),              intent(in), optional :: attributes(1:,1:)         !< Attributes list of name/value pairs [1:2,1:].
   character(*),              intent(in), optional :: attributes_stream         !< Attributes list of name/value pairs as stream.
   logical,                   intent(in), optional :: sanitize_attributes_value !< Sanitize attributes value.
   character(*),              intent(in), optional :: content                   !< Tag value.
   integer(I8P),              intent(in), optional :: pos(1:)                   !< Characters position (in source) indexes.
   integer(I4P),              intent(in), optional :: indent                    !< Number of indent-white-spaces.
   logical,                   intent(in), optional :: is_content_indented       !< Activate value indentation.
   logical,                   intent(in), optional :: is_self_closing           !< The tag is self closing.
   integer(I4P),              intent(in), optional :: id                        !< Uniq ID.
   integer(I4P),              intent(in), optional :: level                     !< Tag hierarchy level.
   integer(I4P),              intent(in), optional :: parent_id                 !< Parent uniq ID.
   character(:), allocatable, intent(in), optional :: attributes_stream_alloc   !< Attributes list stream, allocatable input.
   character(:), allocatable, intent(in), optional :: content_alloc             !< Tag value, allocatable input.
   character(*),              intent(in), optional :: tail                      !< Text after the end tag.
   character(*),              intent(in), optional :: attribute_name            !< Attribute name, with *attribute_value*.
   character(*),              intent(in), optional :: attribute_value           !< Attribute value, stored exactly (unless
                                                                                !< sanitized), no padding as in *attribute*.
   logical                                         :: is_content_indented_      !< Activate value indentation.

   is_content_indented_ = .false. ; if (present(is_content_indented)) is_content_indented_ = is_content_indented
   if (present(name)) self%tag_name = name
   if (present(attribute)) call self%add_single_attribute(attribute=attribute, sanitize_value=sanitize_attributes_value)
   if (present(attribute_name).and.present(attribute_value)) &
      call self%add_attribute_value(name=attribute_name, value=attribute_value, sanitize_value=sanitize_attributes_value)
   if (present(attributes)) call self%add_multiple_attributes(attributes=attributes, sanitize_values=sanitize_attributes_value)
   if (present(attributes_stream)) call self%add_stream_attributes(attributes_stream=attributes_stream, &
                                                                   sanitize_values=sanitize_attributes_value)
   if (present(pos)) self%pos = pos
   if (present(indent)) self%indent = indent
   if (present(content)) then
      if (is_content_indented_) then
         self%tag_content = new_line('a')//repeat(' ', self%indent+2)//content//new_line('a')
      else
         self%tag_content = content
      endif
   endif
   if (present(is_self_closing)) self%is_self_closing = is_self_closing
   if (present(id)) self%id = id
   if (present(level)) self%level = level
   if (present(parent_id)) self%parent_id = parent_id
   if (present(attributes_stream_alloc)) then
      if (allocated(attributes_stream_alloc)) call self%add_stream_attributes(attributes_stream=attributes_stream_alloc, &
                                                                              sanitize_values=sanitize_attributes_value)
   endif
   if (present(content_alloc)) then
      if (allocated(content_alloc)) then
         if (is_content_indented_) then
            self%tag_content = new_line('a')//repeat(' ', self%indent+2)//content_alloc//new_line('a')
         else
            self%tag_content = content_alloc
         endif
      endif
   endif
   if (present(tail)) self%tag_tail = tail
   endsubroutine set

   pure function self_closing_tag(self, is_indented) result(tag_)
   !< Return `<tag_name.../>` self closing tag.
   class(xml_tag), intent(in)           :: self        !< XML tag.
   logical,        intent(in), optional :: is_indented !< Flag to check if tag is indented.
   character(len=:), allocatable        :: tag_        !< The self closing tag string.

   tag_ = '<'//self%tag_name
   if (self%attributes_number>0) tag_ = tag_//' '//self%attributes()
   tag_ = tag_//'/>'
   if (present(is_indented)) then
      if (is_indented) tag_ = repeat(' ', self%indent)//tag_
   endif
   endfunction self_closing_tag

   pure function start_tag(self, is_indented) result(tag_)
   !< Return `<tag_name...>` start tag.
   class(xml_tag), intent(in)           :: self        !< XML tag.
   logical,        intent(in), optional :: is_indented !< Flag to check if tag is indented.
   character(len=:), allocatable        :: tag_        !< The start tag string.

   tag_ = '<'//self%tag_name
   if (self%attributes_number>0) tag_ = tag_//' '//self%attributes()
   tag_ = tag_//'>'
   if (present(is_indented)) then
      if (is_indented) tag_ = repeat(' ', self%indent)//tag_
   endif
   endfunction start_tag

   pure function stringify(self, is_indented, is_content_indented, only_start, only_content, only_end, linearize) result(stringed)
   !< Convert the whole tag into a string.
   class(xml_tag), intent(in)           :: self                 !< XML tag.
   logical,        intent(in), optional :: is_indented          !< Activate content indentation.
   logical,        intent(in), optional :: is_content_indented  !< Activate content indentation.
   logical,        intent(in), optional :: only_start           !< Write only start tag.
   logical,        intent(in), optional :: only_content         !< Write only content.
   logical,        intent(in), optional :: only_end             !< Write only end tag.
   logical,        intent(in), optional :: linearize            !< Return a "linearized" string of tags without the XML hieararchy.
   logical                              :: linearize_           !< Linearize sentinel, local var.
   character(len=:), allocatable        :: stringed             !< Output string containing the whole tag.
   logical                              :: is_content_indented_ !< Activate content indentation.
   logical                              :: only_start_          !< Write only start tag.
   logical                              :: only_content_        !< Write only content.
   logical                              :: only_end_            !< Write only end tag.

   linearize_ = .false. ; if (present(linearize)) linearize_ = linearize
   if (linearize_) then
      stringed = ''
                                    stringed = stringed//'name:            "'//self%tag_name                  //'"'//new_line('a')
      if (self%attributes_number>0) stringed = stringed//'attributes:      "'//self%attributes()              //'"'//new_line('a')
                                    stringed = stringed//'char pos indexes:"'//trim(str(self%pos))            //'"'//new_line('a')
                                    stringed = stringed//'content:         "'//self%tag_content               //'"'//new_line('a')
                                    stringed = stringed//'indent:          "'//trim(str(self%indent))         //'"'//new_line('a')
                                    stringed = stringed//'is self closing: "'//trim(str(self%is_self_closing))//'"'//new_line('a')
                                    stringed = stringed//'level:           "'//trim(str(self%level))          //'"'//new_line('a')
                                    stringed = stringed//'id:              "'//trim(str(self%id))             //'"'//new_line('a')
                                    stringed = stringed//'parent id:       "'//trim(str(self%parent_id))      //'"'//new_line('a')
                                    stringed = stringed//'children number: "'//trim(str(self%children_number))//'"'//new_line('a')
      if (allocated(self%child_id)) stringed = stringed//'children ids:    "'//trim(str(self%child_id))       //'"'//new_line('a')
   else
      is_content_indented_ = .false. ; if (present(is_content_indented)) is_content_indented_ = is_content_indented
      only_start_ = .false. ; if (present(only_start)) only_start_ = only_start
      only_content_ = .false. ; if (present(only_content)) only_content_ = only_content
      only_end_ = .false. ; if (present(only_end)) only_end_ = only_end
      if (only_start_) then
         stringed = self%start_tag(is_indented=is_indented)
      elseif (only_content_) then
         if (self%tag_content%is_allocated()) then
           if (is_content_indented_) then
              stringed = repeat(' ', self%indent+2)//self%tag_content
           else
              stringed = self%tag_content%chars()
           endif
         endif
      elseif (only_end_) then
         stringed = self%end_tag(is_indented=is_indented)
      else
         stringed = ''
         if (self%tag_name%is_allocated()) then
            if (self%is_self_closing) then
               stringed = self%self_closing_tag(is_indented=is_indented)
            else
               stringed = self%start_tag(is_indented=is_indented)
               if (self%tag_content%is_allocated()) then
                  if (is_content_indented_) then
                     stringed = stringed//new_line('a')//repeat(' ', self%indent+2)//&
                                self%tag_content//new_line('a')//repeat(' ', self%indent)
                  else
                     stringed = stringed//self%tag_content
                  endif
               endif
               stringed = stringed//self%end_tag()
            endif
         endif
      endif
   endif
   endfunction stringify

   subroutine write_tag(self, unit, is_indented, is_content_indented, form, end_record, only_start, only_content, only_end, &
                        iostat, iomsg)
   !< Write tag to unit file.
   class(xml_tag), intent(in)            :: self                !< XML tag.
   integer(I4P),   intent(in)            :: unit                !< File unit.
   logical,        intent(in),  optional :: is_indented         !< Activate content indentation.
   logical,        intent(in),  optional :: is_content_indented !< Activate content indentation.
   character(*),   intent(in),  optional :: form                !< Format.
   character(*),   intent(in),  optional :: end_record          !< Ending record.
   logical,        intent(in),  optional :: only_start          !< Write only start tag.
   logical,        intent(in),  optional :: only_content        !< Write only content.
   logical,        intent(in),  optional :: only_end            !< Write only end tag.
   integer(I4P),   intent(out), optional :: iostat              !< IO status.
   character(*),   intent(out), optional :: iomsg               !< IO message.
   type(string)                          :: form_               !< Format.
   type(string)                          :: end_record_         !< Ending record.
   integer(I4P)                          :: iostat_             !< IO status.
   character(500)                        :: iomsg_              !< IO message.

   form_ = 'UNFORMATTED'
   if (present(form)) then
      form_ = form
      form_ = form_%upper()
   endif
   end_record_ = '' ; if (present(end_record)) end_record_ = end_record
   select case(form_%chars())
   case('UNFORMATTED')
      write(unit=unit, iostat=iostat_, iomsg=iomsg_)self%stringify(is_indented=is_indented,                 &
                                                                   is_content_indented=is_content_indented, &
                                                                   only_start=only_start,                   &
                                                                   only_content=only_content,               &
                                                                   only_end=only_end)//end_record_
   case('FORMATTED')
      write(unit=unit, fmt='(A)', iostat=iostat_, iomsg=iomsg_)self%stringify(is_indented=is_indented,                 &
                                                                              is_content_indented=is_content_indented, &
                                                                              only_start=only_start,                   &
                                                                              only_content=only_content,               &
                                                                              only_end=only_end)//end_record_
   endselect
   if (present(iostat)) iostat = iostat_
   if (present(iomsg)) iomsg = iomsg_
   endsubroutine write_tag

   ! private methods
   pure subroutine add_single_attribute(self, attribute, sanitize_value)
   !< Add one attribute name/value pair.
   !<
   !< @note Leading and trailing white spaces are trimmed out by attribute's name.
   !< @note The pair elements have the same length: a value shorter than the name is padded with trailing spaces (use
   !< *add_attribute_value* to store a value exactly).
   class(xml_tag), intent(inout)        :: self           !< XML tag.
   character(*),   intent(in)           :: attribute(1:)  !< Attribute name/value pair [1:2].
   logical,        intent(in), optional :: sanitize_value !< Sanitize attribute value.

   call self%add_attribute_value(name=trim(adjustl(attribute(1))), value=attribute(2), sanitize_value=sanitize_value)
   endsubroutine add_single_attribute

   pure subroutine add_attribute_value(self, name, value, sanitize_value)
   !< Add one attribute, or update its value if already present; the value is stored exactly, unless sanitized (leading and
   !< trailing spaces trimmed).
   class(xml_tag), intent(inout)        :: self               !< XML tag.
   character(*),   intent(in)           :: name               !< Attribute name.
   character(*),   intent(in)           :: value              !< Attribute value.
   logical,        intent(in), optional :: sanitize_value     !< Sanitize attribute value.
   type(string), allocatable            :: new_attribute(:,:) !< Temporary storage for attributes.
   logical                              :: sanitize_value_    !< Sanitize attribute value.
   integer(I4P)                         :: a                  !< Counter.

   sanitize_value_ = .false. ; if (present(sanitize_value)) sanitize_value_ = sanitize_value
   do a=1, self%attributes_number
      if (self%attribute(1, a)==name) exit
   enddo
   if (a>self%attributes_number) then ! not present: append it
      allocate(new_attribute(1:2, 1:self%attributes_number+1))
      if (self%attributes_number>0) new_attribute(1:2, 1:self%attributes_number) = self%attribute
      call move_alloc(from=new_attribute, to=self%attribute)
      self%attributes_number = self%attributes_number + 1
      a = self%attributes_number
      self%attribute(1, a) = name
   endif
   if (sanitize_value_) then
      self%attribute(2, a) = trim(adjustl(value))
   else
      self%attribute(2, a) = value
   endif
   endsubroutine add_attribute_value

   pure subroutine add_multiple_attributes(self, attributes, sanitize_values)
   !< Add list of attributes name/value pairs.
   class(xml_tag), intent(inout)        :: self              !< XML tag.
   character(*),   intent(in)           :: attributes(1:,1:) !< Attribute name/value pair list [1:2,1:].
   logical,        intent(in), optional :: sanitize_values   !< Sanitize attribute values.
   integer(I4P)                         :: a                 !< Counter.

   do a=1, size(attributes, dim=2)
      ! not efficient: many reallocation, but safe
      call self%add_single_attribute(attribute=attributes(1:,a), sanitize_value=sanitize_values)
   enddo
   endsubroutine add_multiple_attributes

   pure subroutine add_stream_attributes(self, attributes_stream, sanitize_values)
   !< Add list of attributes name/value pairs passed as stream, e.g. `x="1" y='a > b'`.
   !<
   !< @note The stream is read by the document tokenizer as the attributes of a start tag: values are single or double
   !< quoted (`<`, `>`, `=` and the other quote kind allowed), blanks are allowed around `=`; values are stored as in the
   !< stream (unless sanitized), an existing attribute is updated.
   class(xml_tag), intent(inout)        :: self              !< XML tag.
   character(*),   intent(in)           :: attributes_stream !< Attribute name/value pair list passed as stream.
   logical,        intent(in), optional :: sanitize_values   !< Sanitize attribute values.
   type(tag_builder)                    :: builder           !< Single tag builder.
   logical                              :: sanitize_values_  !< Sanitize attribute values, local variable.
   integer(I4P)                         :: a                 !< Counter.

   sanitize_values_ = .false. ; if (present(sanitize_values)) sanitize_values_ = sanitize_values
   call scan_tag(source='<_ '//attributes_stream//'/>', sanitize=sanitize_values_, builder=builder)
   do a=1, builder%tag%attributes_number
      call self%add_attribute_value(name=builder%tag%attribute(1, a)%chars(), value=builder%tag%attribute(2, a)%chars())
   enddo
   endsubroutine add_stream_attributes


   pure subroutine delete_content(self)
   !< Delete tag content.
   class(xml_tag), intent(inout) :: self !< XML tag.

   call self%tag_content%free
   endsubroutine delete_content

   pure subroutine delete_single_attribute(self, name)
   !< Delete one attribute name/value pair.
   class(xml_tag), intent(inout) :: self               !< XML tag.
   character(*),   intent(in)    :: name               !< Attribute name.
   type(string), allocatable     :: new_attribute(:,:) !< Temporary storage for attributes.
   integer(I4P)                  :: a                  !< Counter.

   if (self%attributes_number>0) then
      search_tag: do a=1, self%attributes_number
         if (self%attribute(1, a)==name) then
            if (self%attributes_number>1) then
               allocate(new_attribute(1:2, 1:self%attributes_number-1))
               if (a==1) then
                  new_attribute(:, a:) = self%attribute(:, a+1:)
               elseif (a==self%attributes_number) then
                  new_attribute(:, :a-1) = self%attribute(:, :a-1)
               else
                  new_attribute(:, :a-1) = self%attribute(:, :a-1)
                  new_attribute(:, a:) = self%attribute(:, a+1:)
               endif
               call move_alloc(from=new_attribute, to=self%attribute)
            else
               call self%attribute%free
               deallocate(self%attribute)
            endif
            self%attributes_number = self%attributes_number - 1
            exit search_tag
         endif
      enddo search_tag
   endif
   endsubroutine delete_single_attribute

   pure subroutine delete_multiple_attributes(self, name)
   !< Delete list of attributes name/value pairs.
   class(xml_tag), intent(inout) :: self     !< XML tag.
   character(*),   intent(in)    :: name(1:) !< Attributes names.
   integer(I4P)                  :: a        !< Counter.

   do a=1, size(name, dim=1)
      call self%delete_single_attribute(name=name(a))
   enddo
   endsubroutine delete_multiple_attributes






   ! non type-bound procedures
   pure subroutine scan_tag(source, sanitize, builder, name)
   !< Scan a source for its first tag or, if *name* is passed, its first tag with that name.
   character(*),      intent(in)           :: source    !< Source.
   logical,           intent(in)           :: sanitize  !< Trim leading and trailing spaces of attribute values.
   type(tag_builder), intent(out)          :: builder   !< Single tag builder, the found tag.
   character(*),      intent(in), optional :: name      !< Name of the searched tag.
   type(xml_tokenizer)                     :: tokenizer !< Tokenizer.
   integer(I8P)                            :: consumed  !< Characters consumed by the tokenizer.

   if (present(name)) builder%name = name
   builder%sanitize = sanitize
   call tokenizer%feed(chars=source, offset=0_I8P, is_last=.true., builder=builder, consumed=consumed)
   endsubroutine scan_tag

   pure subroutine tag_content(source, builder, content)
   !< Return the content (raw) of the tag found by a builder: up to its end tag or, if unclosed, to the source end;
   !< unallocated if it is self closing or empty.
   character(*),                  intent(in)  :: source  !< Source.
   type(tag_builder),             intent(in)  :: builder !< Single tag builder, the found tag.
   character(len=:), allocatable, intent(out) :: content !< Tag content.
   integer(I8P)                               :: last    !< Last position of the content.

   if (builder%is_self_closing.or.builder%open_end==0) return
   if (builder%end_start>0) then
      last = builder%end_start - 1
   else
      last = len(source, kind=I8P)
   endif
   if (last>builder%open_end) content = source(builder%open_end+1:last)
   endsubroutine tag_content

   pure function blanks_as_spaces(string) result(normalized)
   !< Return string with each blank (tab, new line, carriage return) replaced by a space, a CR LF pair by one space.
   character(*), intent(in)      :: string     !< String.
   character(len=:), allocatable :: normalized !< Normalized string.
   character(len=len(string))    :: buffer     !< Normalized characters.
   integer(I4P)                  :: n          !< Length of normalized string.
   integer(I4P)                  :: c          !< Counter.

   if (scan(string, achar(9)//achar(10)//achar(13))==0) then
      normalized = string
      return
   endif
   n = 0
   do c=1, len(string)
      if (string(c:c)==achar(10).and.c>1) then
         if (string(c-1:c-1)==achar(13)) cycle ! CR LF: the CR is already a space
      endif
      n = n + 1
      if (scan(string(c:c), achar(9)//achar(10)//achar(13))>0) then
         buffer(n:n) = ' '
      else
         buffer(n:n) = string(c:c)
      endif
   enddo
   normalized = buffer(1:n)
   endfunction blanks_as_spaces

   ! tag_builder methods
   pure subroutine tag_start_tag(self, id, parent_id, level, name, start)
   !< A start tag begins: it is the found tag if none is found yet and it is the searched one.
   class(tag_builder), intent(inout) :: self      !< Single tag builder.
   integer(I4P),       intent(in)    :: id        !< Tag ID (start tags count).
   integer(I4P),       intent(in)    :: parent_id !< Parent tag ID, 0 for a root tag.
   integer(I4P),       intent(in)    :: level     !< Tag level, 1 for a root tag.
   character(*),       intent(in)    :: name      !< Tag name.
   integer(I8P),       intent(in)    :: start     !< Position of `<`.

   if (self%id>0) return
   if (allocated(self%name)) then
      if (name/=self%name) return
   endif
   self%id = id
   self%start = start
   self%tag%tag_name = name
   endsubroutine tag_start_tag

   pure subroutine tag_attribute(self, id, name, value)
   !< An attribute of the current start tag: stored if it is of the found tag.
   class(tag_builder), intent(inout) :: self  !< Single tag builder.
   integer(I4P),       intent(in)    :: id    !< Tag ID.
   character(*),       intent(in)    :: name  !< Attribute name.
   character(*),       intent(in)    :: value !< Attribute value.

   if (id==self%id) call self%tag%add_attribute_value(name=name, value=value, sanitize_value=self%sanitize)
   endsubroutine tag_attribute

   pure subroutine tag_start_tag_end(self, id, start, open_end, is_self_closing)
   !< The current start tag is complete: a found self closing tag is complete, the tokenizer stops.
   class(tag_builder), intent(inout) :: self            !< Single tag builder.
   integer(I4P),       intent(in)    :: id              !< Tag ID.
   integer(I8P),       intent(in)    :: start           !< Position of `<`.
   integer(I8P),       intent(in)    :: open_end        !< Position of `>`.
   logical,            intent(in)    :: is_self_closing !< The tag is self closing.

   if (id/=self%id) return
   self%open_end = open_end
   self%is_self_closing = is_self_closing
   if (is_self_closing) self%is_stopped = .true.
   endsubroutine tag_start_tag_end

   pure subroutine tag_end_tag(self, id, start, open_end, end_start, end_end)
   !< An open tag is closed by its end tag: the found tag is complete, the tokenizer stops.
   class(tag_builder), intent(inout) :: self      !< Single tag builder.
   integer(I4P),       intent(in)    :: id        !< Tag ID.
   integer(I8P),       intent(in)    :: start     !< Position of the start tag `<`.
   integer(I8P),       intent(in)    :: open_end  !< Position of the start tag `>`.
   integer(I8P),       intent(in)    :: end_start !< Position of the end tag `<`.
   integer(I8P),       intent(in)    :: end_end   !< Position of the end tag `>`.

   if (id/=self%id) return
   self%end_start = end_start
   self%end_end = end_end
   self%is_stopped = .true.
   endsubroutine tag_end_tag

   pure subroutine tag_data(self, kind, chars, first)
   !< Character data or other markup: ignored (the content is cut from the source).
   class(tag_builder), intent(inout) :: self  !< Single tag builder.
   integer(I4P),       intent(in)    :: kind  !< Data kind, DATA_*.
   character(*),       intent(in)    :: chars !< Characters, as in the source.
   integer(I8P),       intent(in)    :: first !< Position of the first character.
   endsubroutine tag_data

   pure subroutine tag_problem(self, pos, message)
   !< A problem of malformed input: ignored (parsing is tolerant).
   class(tag_builder), intent(inout) :: self    !< Single tag builder.
   integer(I8P),       intent(in)    :: pos     !< Position of the problem.
   character(*),       intent(in)    :: message !< Problem description.
   endsubroutine tag_problem

   ! assignment (=)
   elemental subroutine assign_tag(lhs, rhs)
   !< Assignment between two tags.
   class(xml_tag), intent(inout) :: lhs !< Left hand side.
   type(xml_tag),  intent(in)    :: rhs !< Right hand side.
   integer(I4P)                  :: a   !< Counter.

   call lhs%free
   if (rhs%tag_name%is_allocated()) lhs%tag_name = rhs%tag_name
   if (rhs%tag_content%is_allocated()) lhs%tag_content = rhs%tag_content
   if (rhs%tag_tail%is_allocated()) lhs%tag_tail = rhs%tag_tail
   lhs%pos = rhs%pos
   if (rhs%attributes_number>0) then
      allocate(lhs%attribute(1:2, 1:rhs%attributes_number))
      do a=1, rhs%attributes_number
         lhs%attribute(1:2, a) = rhs%attribute(1:2, a)
      enddo
   endif
   lhs%attributes_number = rhs%attributes_number
   lhs%indent = rhs%indent
   lhs%is_self_closing = rhs%is_self_closing
   lhs%level = rhs%level
   lhs%id = rhs%id
   lhs%parent_id = rhs%parent_id
   lhs%children_number = rhs%children_number
   if (allocated(rhs%child_ID)) lhs%child_ID = rhs%child_ID
   endsubroutine assign_tag

   ! finalize
   elemental subroutine finalize(tag)
   !< Free dynamic memory when finalizing.
   type(xml_tag), intent(inout) :: tag !< XML tag.

   call tag%free
   endsubroutine finalize
endmodule foxy_xml_tag
