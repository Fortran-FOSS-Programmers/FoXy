!< FoXy XML tag class.
module foxy_xml_tag
!-----------------------------------------------------------------------------------------------------------------------------------
!< FoXy XML tag class.
!-----------------------------------------------------------------------------------------------------------------------------------
use penf
use stringifor, only : string
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
public :: tag
public :: xml_tag
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
type :: xml_tag
  !< XML tag class.
  !<
  !< A valid XML tag must have the following syntax for a tag without a value (with only attributes):
  !<```xml
  !<   <Tag_Name att#1_Name="att#1_val" att#2_Name="att#2_val"... att#Nt_Name="att#Nt_val"/>
  !<```
  !< while a tag with a value must have the following syntax:
  !<```xml
  !<   <Tag_Name att#1_Name="att#1_val" att#2_Name="att#2_val"... att#Nt_Name="att#Nt_val">Tag_value</Tag_Name>
  !<```
  !<
  !< It is worth noting that the syntax is case sensitive and that the attributes are optional. Each attribute name must be followed
  !< by '="' without any additional white spaces and its value must be termined by '"'. Each attribute is separated by a white
  !< space. If the string member does not contain the tag_name no attributes are parsed.
  private
  type(string)              :: tag_name                !< Tag name.
  type(string)              :: tag_val                 !< Tag value.
  type(string), allocatable :: att_name(:)             !< Attributes names.
  type(string), allocatable :: att_val(:)              !< Attributes values.
  integer(I4P)              :: attributes_number=0     !< Number of defined attributes.
  logical                   :: is_self_closing=.false. !< Self closing tag flag.
  contains
    ! public methods
    procedure :: free                        !< Free dynamic memory.
    final     :: finalize                    !< Free dynamic memory when finalizing.
    procedure :: set                         !< Set tag data.
    procedure :: parse                       !< Parse the tag contained into a source string.
    procedure :: is_parsed                   !< Check is tag is correctly parsed, i.e. its *tag_name* is allocated.
    procedure :: tag_value                   !< Return tag value of is sefl (or its nested tags) is named *tag_name*.
    procedure :: stringify                   !< Convert the whole tag into a string.
    generic   :: assignment(=) => assign_tag !< Assignment operator overloading.
    ! private methods
    procedure, private :: add_attribute          !< Add one attribute name/value pair.
    procedure, private :: add_attributes         !< Add list of attributes name/value pairs.
    procedure, private :: alloc_attributes       !< Allocate (prepare for filling) dynamic memory of attributes.
    procedure, private :: get                    !< Get the tag value and attributes from source.
    procedure, private :: get_value              !< Get the tag value from source after tag_name has been set.
    procedure, private :: get_attributes         !< Get the attributes values from source.
    procedure, private :: parse_tag_name         !< Parse the tag name contained into a string.
    procedure, private :: parse_attributes_names !< Parse the tag attributes names contained into a string.
    procedure, private :: search                 !< Search tag named *tag_name* into a string.
    procedure, private :: assign_tag             !< Assignment between two tags.
endtype xml_tag
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  ! public procedure
  pure function tag(name, attribute, attributes, value, is_self_closing)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Return an instance of xml tag.
  !---------------------------------------------------------------------------------------------------------------------------------
  character(*), intent(in)           :: name              !< Tag name.
  character(*), intent(in), optional :: attribute(1:)     !< Attribute name/value pair [1:2].
  character(*), intent(in), optional :: attributes(1:,1:) !< Attributes list of name/value pairs [1:2,1:].
  character(*), intent(in), optional :: value             !< Tag value.
  logical,      intent(in), optional :: is_self_closing   !< The tag is self closing.
  type(xml_tag)                      :: tag               !< XML tag.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call tag%set(name=name, attribute=attribute, attributes=attributes, value=value, is_self_closing=is_self_closing)
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction tag

  ! public methods
  elemental subroutine free(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag), intent(inout) :: self !< XML tag.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%tag_name%free
  call self%tag_val%free
  if (allocated(self%att_name)) then
    call self%att_name%free
    deallocate(self%att_name)
  endif
  if (allocated(self%att_val )) then
    call self%att_val%free
    deallocate(self%att_val)
  endif
  self%attributes_number = 0
  self%is_self_closing = .false.
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free

  elemental subroutine finalize(tag)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory when finalizing.
  !---------------------------------------------------------------------------------------------------------------------------------
  type(xml_tag), intent(inout) :: tag !< XML tag.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call tag%free
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize

  pure subroutine set(self, name, attribute, attributes, value, is_self_closing)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Set tag data.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag), intent(inout)        :: self              !< XML tag.
  character(*),   intent(in), optional :: name              !< Tag name.
  character(*),   intent(in), optional :: attribute(1:)     !< Attribute name/value pair [1:2].
  character(*),   intent(in), optional :: attributes(1:,1:) !< Attributes list of name/value pairs [1:2,1:].
  character(*),   intent(in), optional :: value             !< Tag value.
  logical,        intent(in), optional :: is_self_closing   !< The tag is self closing.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(name)) self%tag_name = name
  if (present(attribute)) call self%add_attribute(attribute=attribute)
  if (present(attributes)) call self%add_attributes(attributes=attributes)
  if (present(value)) self%tag_val = value
  if (present(is_self_closing)) self%is_self_closing = is_self_closing
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine set

  pure subroutine add_attribute(self, attribute)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Add one attribute name/value pair.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag), intent(inout) :: self          !< XML tag.
  character(*),   intent(in)    :: attribute(1:) !< Attribute name/value pair [1:2].
  type(string), allocatable     :: att_name(:)   !< Temporary storage of previous attributes names.
  type(string), allocatable     :: att_val(:)    !< Temporary storage of previous attributes values.
  logical                       :: is_updated    !< Flag to check if the attribute has been updeted.
  integer(I4P)                  :: a             !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (self%attributes_number>0) then
    is_updated = .false.
    update_if_already_present: do a=1, self%attributes_number
      if (self%att_name(a)==attribute(1)) then
        self%att_val = attribute(2)
        is_updated = .true.
        exit update_if_already_present
      endif
    enddo update_if_already_present
    if (.not.is_updated) then
      allocate(att_name(1:self%attributes_number+1))
      allocate(att_val(1:self%attributes_number+1))
      att_name(1:self%attributes_number) = self%att_name
      att_val(1:self%attributes_number) = self%att_val
      att_name(self%attributes_number+1) = attribute(1)
      att_val(self%attributes_number+1) = attribute(2)
      call move_alloc(from=att_name, to=self%att_name)
      call move_alloc(from=att_val, to=self%att_val)
      self%attributes_number = self%attributes_number + 1
    endif
  else
    call self%alloc_attributes(Na=1, att_name=.true., att_val=.true.)
    self%att_name(1) = attribute(1)
    self%att_val(1) = attribute(2)
  endif
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add_attribute

  pure subroutine add_attributes(self, attributes)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Add list of attributes name/value pairs.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag), intent(inout) :: self              !< XML tag.
  character(*),   intent(in)    :: attributes(1:,1:) !< Attribute name/value pair list [1:2,1:].
  integer(I4P)                  :: a                 !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  do a=1, size(attributes, dim=2)
    call self%add_attribute(attribute=attributes(1:,a)) ! not efficient: many reallocation, but safe
  enddo
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add_attributes

  elemental subroutine parse(self, source, tstart, tend)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Parse the tag contained into a source string.
  !<
  !< It is assumed that the first tag contained into the source string is parsed, the others eventually present are omitted.
  !< Valid syntax are:
  !< + `<tag_name att1="att1 val" att2="att2 val"...>...</tag_name>`
  !< + `<tag_name att1="att1 val" att2="att2 val".../>`
  !< @note Inside the attributes value the symbols `<` and `>` are not allowed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag),         intent(inout) :: self      !< XML tag.
  character(*),           intent(in)    :: source    !< String containing the input.
  integer(I4P), optional, intent(out)   :: tstart    !< Starting index of tag inside the string.
  integer(I4P), optional, intent(out)   :: tend      !< Ending index of tag inside the string.
  integer(I4P)                          :: tstartd   !< Starting index of tag inside the string.
  integer(I4P)                          :: tendd     !< Ending index of tag inside the string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  tstartd = 0
  tendd   = 0
  call self%parse_tag_name(source=source, tstart=tstartd, tend=tendd)
  if (self%tag_name%is_allocated()) then
    if (index(string=source(tstartd:tendd), substring='=')>0) call self%parse_attributes_names(source=source(tstartd:tendd))
    if (index(string=source, substring='</'//self%tag_name//'>')>0) &
      tendd = index(string=source, substring='</'//self%tag_name//'>') + len('</'//self%tag_name//'>') - 1
    call self%get(source=source(tstartd:tendd))
  endif
  if (present(tstart)) tstart = tstartd
  if (present(tend  )) tend   = tendd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine parse

  elemental function is_parsed(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check is tag is correctly parsed, i.e. its *tag_name* is allocated.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag), intent(in) :: self      !< XML tag.
  logical                    :: is_parsed !< Result of check.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  is_parsed = self%tag_name%is_allocated()
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction is_parsed

  pure subroutine tag_value(self, tag_name, tag_val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Return tag value of is sefl (or its nested tags) is named *tag_name*.
  !<
  !< @note If there is no value, the *tag_value* string is returned deallocated.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag),                intent(in)    :: self     !< XML tag.
  character(*),                  intent(in)    :: tag_name !< Searched tag name.
  character(len=:), allocatable, intent(inout) :: tag_val  !< Tag value.
  type(xml_tag)                                :: tag      !< Dummy XML tag.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(tag_val)) deallocate(tag_val)
  if (self%tag_name%is_allocated()) then
    if (self%tag_name==tag_name) then
      if (self%tag_val%is_allocated()) tag_val = self%tag_val%chars()
    else
      if (self%tag_val%is_allocated()) then
        call tag%search(tag_name=tag_name, source=self%tag_val%chars())
        if (tag%tag_val%is_allocated()) tag_val = tag%tag_val%chars()
      endif
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine tag_value

  pure function stringify(self) result(stringed)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Convert the whole tag into a string.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag), intent(in)    :: self     !< XML tag.
  character(len=:), allocatable :: stringed !< Output string containing the whole tag.
  integer(I4P)                  :: a        !< Counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  stringed = ''
  if (self%tag_name%is_allocated()) then
    stringed = stringed//'<'//self%tag_name
    if (self%attributes_number>0) then
      if (size(self%att_name, dim=1)==size(self%att_val, dim=1)) then ! consistency check
        do a=1, size(self%att_name)
          if (self%att_name(a)%is_allocated().and.self%att_val(a)%is_allocated()) &
            stringed = stringed//' '//self%att_name(a)//'="'//self%att_val(a)//'"'
        enddo
      endif
    endif
    if (self%is_self_closing) then
      stringed = stringed//'/>'
    else
      if (self%tag_val%is_allocated()) then
        stringed = stringed//'>'//self%tag_val//'</'//self%tag_name//'>'
      else
        stringed = stringed//'></'//self%tag_name//'>'
      endif
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction stringify

  ! private methods
  elemental subroutine alloc_attributes(self, Na, att_name, att_val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Allocate (prepare for filling) dynamic memory of attributes.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag),    intent(inout) :: self     !< XML tag.
  integer(I4P),      intent(in)    :: Na       !< Number of attributes.
  logical, optional, intent(in)    :: att_name !< Flag for freeing attributes names array.
  logical, optional, intent(in)    :: att_val  !< Flag for freeing attributes values array.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(att_name)) then
    if (att_name) then
      if (allocated(self%att_name)) then
        call self%att_name%free
        deallocate(self%att_name)
      endif
      allocate(self%att_name(1:Na))
    endif
  endif
  if (present(att_val)) then
    if (att_val) then
      if (allocated(self%att_val)) then
        call self%att_val%free
        deallocate(self%att_val)
      endif
      allocate(self%att_val(1:Na))
    endif
  endif
  self%attributes_number = Na
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine alloc_attributes

  elemental subroutine get(self, source)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get the tag value and attributes from source after tag_name and att_name have been set.
  !<
  !< @note It is worth noting that the leading and trailing white spaces of tag value and attributes are removed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag), intent(inout) :: self   !< XML tag.
  character(*),   intent(in)    :: source !< String containing data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%get_value(source=source)
  call self%get_attributes(source=source)
  ! call self%get_nested()
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get

  elemental subroutine get_value(self, source)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get the tag value from source after tag_name has been set.
  !<
  !< @note It is worth noting that the leading and trailing white spaces of tag value are removed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag), intent(inout) :: self   !< XML tag.
  character(*),   intent(in)    :: source !< String containing data.
  integer                       :: c1     !< Counter.
  integer                       :: c2     !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%tag_val%free
  self%is_self_closing = .false.
  if (index(string=source, substring='<'//self%tag_name)>0) then
    c2 = index(string=source, substring='</'//self%tag_name//'>')
    if (c2>0) then ! parsing tag value
      c1 = index(string=source, substring='>')
      if (c1+1<c2-1) self%tag_val = trim(adjustl(source(c1+1:c2-1)))
    else
      self%is_self_closing = .true.
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_value

  elemental subroutine get_attributes(self, source)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get the attributes values from source after tag_name and att_name have been set.
  !<
  !< @note It is worth noting that the leading and trailing white spaces of attributes values are removed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag), intent(inout) :: self   !< XML tag.
  character(*),   intent(in)    :: source !< String containing data.
  integer                       :: a      !< Counter.
  integer                       :: c1     !< Counter.
  integer                       :: c2     !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (index(string=source, substring='<'//self%tag_name)>0) then
    if (allocated(self%att_name)) then ! parsing attributes
      call self%alloc_attributes(att_val=.true., Na=size(self%att_name, dim=1))
      do a=1, size(self%att_name, dim=1)
        c1 = index(string=source, substring=self%att_name(a)//'="') + self%att_name(a)%len() + 2
        if (c1>self%att_name(a)%len() + 2) then
          c2 = index(string=source(c1:), substring='"')
          if (c2>0) then
            self%att_val(a) = trim(adjustl(source(c1:c1+c2-2)))
          else
            call self%att_val(a)%free
          endif
        else
          call self%att_val(a)%free
        endif
      enddo
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_attributes

  elemental subroutine parse_tag_name(self, source, tstart, tend)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Parse the tag name contained into a string.
  !<
  !< It is assumed that the first tag contained into the source is parsed, the others eventually present are omitted.
  !< Valid syntax are:
  !< + `<tag_name att1="att1 val" att2="att2 val"...>...</tag_name>`
  !< + `<tag_name att1="att1 val" att2="att2 val".../>`
  !< @note Inside the attributes value the symbols `<` and `>` are not allowed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag),         intent(inout) :: self    !< XML tag.
  character(*),           intent(in)    :: source  !< String containing the input.
  integer(I4P), optional, intent(out)   :: tstart  !< Starting index of tag inside the source.
  integer(I4P), optional, intent(out)   :: tend    !< Ending index of tag inside the source.
  integer(I4P)                          :: tstartd !< Starting index of tag inside the source.
  integer(I4P)                          :: tendd   !< Ending index of tag inside the source.
  character(len=1)                      :: c1      !< Dummy string for parsing file.
  character(len=:), allocatable         :: c2      !< Dummy string for parsing file.
  integer(I4P)                          :: c       !< Counter.
  integer(I4P)                          :: s       !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  tstartd = 0
  tendd   = 0
  c = 1
  Tag_Search: do while(c<=len(source))
    c1 = source(c:c)
    if (c1=='<') then
      tstartd = c
      c2 = c1
      Tag_Name: do while(c<len(source))
        c = c + 1 ; c1 = source(c:c)
        c2 = c2//c1
        if (c1=='>') then
          tendd = c
          exit Tag_Name
        endif
      enddo Tag_Name
      s = index(string=c2, substring=' ')
      if (s>0) then ! there are attributes
        self%tag_name = c2(2:s-1)
      else
        if (index(string=c2, substring='/>')>0) then ! self closing tag
          self%tag_name = c2(2:len(c2)-2)
        else
          self%tag_name = c2(2:len(c2)-1)
        endif
      endif
      exit Tag_Search
    endif
    c = c + 1
  enddo Tag_Search
  if (present(tstart)) tstart = tstartd
  if (present(tend  )) tend   = tendd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine parse_tag_name

  elemental subroutine parse_attributes_names(self, source)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Parse the tag attributes names contained into a string.
  !<
  !< Valid syntax is:
  !< + `att1="att1 val" att2="att2 val"...`
  !< @note Inside the attributes value the symbols `<` and `>` are not allowed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag), intent(inout) :: self   !< XML tag.
  character(*),   intent(in)    :: source !< String containing the input.
  character(len=:), allocatable :: att    !< Dummy string for parsing file.
  integer(I4P)                  :: c      !< Counter.
  integer(I4P)                  :: s      !< Counter.
  integer(I4P)                  :: a      !< Counter.
  integer(I4P)                  :: Na     !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  Na = 0
  c = 1
  Att_Count: do while(c<=len(source))
    if (source(c:c)=='=') Na = Na + 1
    c = c + 1
  enddo Att_Count
  if (Na>0) then
    call self%alloc_attributes(att_name=.true., Na=Na)
    c = index(string=source, substring=' ')
    att = source(c:)
    c = 1
    a = 1
    Att_Search: do while(c<=len(att))
      if (att(c:c)=='=') then
        s = max(0, index(string=att, substring=' '))
        self%att_name(a) = trim(adjustl(att(s+1:c-1)))
        att = att(c+1:)
        c = 1
        a = a + 1
      endif
      c = c + 1
    enddo Att_Search
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine parse_attributes_names

  elemental subroutine search(self, tag_name, source, tstart, tend)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Search tag named *tag_name* into a string and, in case it is found, store into self.
  !<
  !< @note If *tag_name* is not found, self is returned empty.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag),         intent(inout) :: self     !< XML tag.
  character(*),           intent(in)    :: tag_name !< Searched tag name.
  character(*),           intent(in)    :: source   !< String containing the input.
  integer(I4P), optional, intent(out)   :: tstart   !< Starting index of tag inside the source.
  integer(I4P), optional, intent(out)   :: tend     !< Ending index of tag inside the source.
  type(xml_tag)                         :: tag      !< Dummy XML tag.
  integer(I4P)                          :: tstartd  !< Starting index of tag inside the source.
  integer(I4P)                          :: tendd    !< Ending index of tag inside the source.
  logical                               :: found    !< Flag for inquiring search result.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%free
  self%tag_name = tag_name
  tstartd = 1
  tendd   = 0
  found = .false.
  Tag_Search: do while ((.not.found).or.(len(source(tendd + 1:))<self%tag_name%len()))
    call tag%parse(source=source(tendd + 1:), tstart=tstartd, tend=tendd)
    if (tstartd==0.and.tendd==0) then
      exit Tag_Search ! no tag found
    else
      if (tag%tag_name%is_allocated()) then
        if (tag%tag_name==self%tag_name) then
          found = .true.
        endif
      endif
    endif
  enddo Tag_Search
  if (found) then
    self = tag
  else
    call self%free
  endif
  if (present(tstart)) tstart = tstartd
  if (present(tend  )) tend   = tendd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine search

  ! assignment (=)
  elemental subroutine assign_tag(lhs, rhs)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Assignment between two tags.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(xml_tag), intent(inout) :: lhs !< Left hand side.
  type(xml_tag),  intent(in)    :: rhs !< Right hand side.
  integer(I4P)                  :: a   !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call lhs%free
  if (rhs%tag_name%is_allocated()) lhs%tag_name = rhs%tag_name
  if (rhs%tag_val%is_allocated()) lhs%tag_val = rhs%tag_val
  if (allocated(rhs%att_name)) then
    if (allocated(lhs%att_name)) deallocate(lhs%att_name) ; allocate(lhs%att_name(1:size(rhs%att_name)))
    do a=1, size(rhs%att_name)
      if (rhs%att_name(a)%is_allocated()) lhs%att_name(a) = rhs%att_name(a)
    enddo
  endif
  if (allocated(rhs%att_val)) then
    if (allocated(lhs%att_val)) deallocate(lhs%att_val) ; allocate(lhs%att_val(1:size(rhs%att_val)))
    do a=1, size(rhs%att_val)
      if (rhs%att_val(a)%is_allocated()) lhs%att_val(a) = rhs%att_val(a)
    enddo
  endif
  lhs%attributes_number = rhs%attributes_number
  lhs%is_self_closing = rhs%is_self_closing
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_tag
endmodule foxy_xml_tag
