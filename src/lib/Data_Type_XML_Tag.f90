!< Definition of Type_XML_Tag for FoXy XML Parser.
module Data_Type_XML_Tag
!-----------------------------------------------------------------------------------------------------------------------------------
!< Definition of Type_XML_Tag for FoXy XML Parser.
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision ! Integers and reals precision definition.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
type :: Type_VString_Wrapper
  !< Deferred length allocatable string wrapped for allowing array of varying strings with different lenghts.
  character(len=:), allocatable :: vs !< Wrapped varying lenght string.
  contains
    generic   :: free => free_vs_wrapper
    procedure :: free_vs_wrapper
    final     :: finalize_vs_wrapper
endtype Type_VString_Wrapper

type, public:: Type_XML_Tag
  !< Derived type defining Type_XML_Tag, a useful type for parsing XML file.
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
  character(len=:),           allocatable :: tag_name    !< Tag name.
  character(len=:),           allocatable :: tag_val     !< Tag value.
  type(Type_VString_Wrapper), allocatable :: att_name(:) !< Attributes names.
  type(Type_VString_Wrapper), allocatable :: att_val(:)  !< Attributes values.
  contains
    ! public type-bound procedures
    procedure :: free
    final     :: finalize
    procedure :: parse
    procedure :: is_parsed
    procedure :: tag_value
    procedure :: stringify
    generic   :: assignment(=) => assign_tag
    ! private type-bound procedures
    procedure, private :: alloc_attributes
    procedure, private :: get
    procedure, private :: get_value
    procedure, private :: get_attributes
    procedure, private :: parse_tag_name
    procedure, private :: parse_attributes_names
    procedure, private :: search
    procedure, private :: assign_tag
endtype Type_XML_Tag
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  ! Type_VString_Wrapper
  elemental subroutine free_vs_wrapper(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_VString_Wrapper), intent(INOUT) :: self !< Wrapped varying string
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self%vs)) deallocate(self%vs)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free_vs_wrapper

  subroutine finalize_vs_wrapper(vstring)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory when finalizing.
  !---------------------------------------------------------------------------------------------------------------------------------
  type(Type_VString_Wrapper), intent(INOUT) :: vstring !< Wrapped varying string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call vstring%free
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize_vs_wrapper

  ! Type_XML_Tag
  ! public
  elemental subroutine free(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_Tag), intent(INOUT) :: self !< XML tag.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self%tag_name)) deallocate(self%tag_name)
  if (allocated(self%tag_val )) deallocate(self%tag_val )
  if (allocated(self%att_name)) deallocate(self%att_name)
  if (allocated(self%att_val )) deallocate(self%att_val)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free

  subroutine finalize(tag)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory when finalizing.
  !---------------------------------------------------------------------------------------------------------------------------------
  type(Type_XML_tag), intent(INOUT) :: tag !< XML tag.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call tag%free
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize

  elemental subroutine parse(self, string, tstart, tend)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Parse the tag contained into a string.
  !<
  !< It is assumed that the first tag contained into the string is parsed, the others eventually present are omitted.
  !< Valid syntax are:
  !< + `<tag_name att1="att1 val" att2="att2 val"...>...</tag_name>`
  !< + `<tag_name att1="att1 val" att2="att2 val".../>`
  !< @note Inside the attributes value the symbols `<` and `>` are not allowed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_Tag),    intent(INOUT) :: self      !< XML tag.
  character(*),           intent(IN)    :: string    !< String containing the input.
  integer(I4P), optional, intent(OUT)   :: tstart    !< Starting index of tag inside the string.
  integer(I4P), optional, intent(OUT)   :: tend      !< Ending index of tag inside the string.
  integer(I4P)                          :: tstartd   !< Starting index of tag inside the string.
  integer(I4P)                          :: tendd     !< Ending index of tag inside the string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  tstartd = 0
  tendd   = 0
  call self%parse_tag_name(string=string, tstart=tstartd, tend=tendd)
  if (allocated(self%tag_name)) then
    if (index(string=string(tstartd:tendd), substring='=')>0) call self%parse_attributes_names(string=string(tstartd:tendd))
    if (index(string=string, substring='</'//self%tag_name//'>')>0) &
      tendd = index(string=string, substring='</'//self%tag_name//'>') + len('</'//self%tag_name//'>') - 1
    call self%get(string=string(tstartd:tendd))
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
  class(Type_XML_Tag), intent(IN) :: self      !< XML tag.
  logical                         :: is_parsed !< Result of check.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  is_parsed = allocated(self%tag_name)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction is_parsed

  pure subroutine tag_value(self, tag_name, tag_val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Return tag value of is sefl (or its nested tags) is named *tag_name*.
  !<
  !< @note If there is no value, the *tag_value* string is returned deallocated.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_Tag),           intent(IN)    :: self     !< XML tag.
  character(*),                  intent(IN)    :: tag_name !< Searched tag name.
  character(len=:), allocatable, intent(INOUT) :: tag_val  !< Tag value.
  type(Type_XML_Tag)                           :: tag      !< Dummy XML tag.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(tag_val)) deallocate(tag_val)
  if (allocated(self%tag_name)) then
    if (self%tag_name==tag_name) then
      if (allocated(self%tag_val)) tag_val = self%tag_val
    else
      if (allocated(self%tag_val)) then
        call tag%search(tag_name=tag_name, string=self%tag_val)
        if (allocated(tag%tag_val)) tag_val = tag%tag_val
      endif
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine tag_value

  pure function stringify(self) result(string)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Convert the whole tag into a string.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_Tag), intent(IN) :: self   !< XML tag.
  character(len=:), allocatable   :: string !< Output string containing the whole tag.
  integer(I4P)                    :: a      !< Counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  string = ''
  if (allocated(self%tag_name)) then
    string = string//'<'//self%tag_name
    if (allocated(self%att_name).and.allocated(self%att_val)) then
      if (size(self%att_name)==size(self%att_val)) then ! consistency check
        do a=1, size(self%att_name)
          if (allocated(self%att_name(a)%vs).and.allocated(self%att_val(a)%vs)) &
            string = string//' '//self%att_name(a)%vs//'="'//self%att_val(a)%vs//'"'
        enddo
      endif
    endif
    if (allocated(self%tag_val)) then
      string = string//'>'//self%tag_val//'</'//self%tag_name//'>'
    else
      string = string//'/>'
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction stringify

  ! private
  elemental subroutine alloc_attributes(self, Na, att_name, att_val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Allocate (prepare for filling) dynamic memory of attributes.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_Tag), intent(INOUT) :: self     !< XML tag.
  integer(I4P),        intent(IN)    :: Na       !< Number of attributes.
  logical, optional,   intent(IN)    :: att_name !< Flag for freeing attributes names array.
  logical, optional,   intent(IN)    :: att_val  !< Flag for freeing attributes values array.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(att_name)) then
    if (att_name) then
      if (allocated(self%att_name)) deallocate(self%att_name) ; allocate(self%att_name(1:Na))
    endif
  endif
  if (present(att_val)) then
    if (att_val) then
      if (allocated(self%att_val)) deallocate(self%att_val) ; allocate(self%att_val(1:Na))
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine alloc_attributes

  elemental subroutine get(self, string)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get the tag value and attributes from self%string after tag_name and att_name have been set.
  !<
  !< @note It is worth noting that the leading and trailing white spaces of tag value and attributes are removed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_Tag), intent(INOUT) :: self   !< XML tag.
  character(*),        intent(IN)    :: string !< String containing data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%get_value(string=string)
  call self%get_attributes(string=string)
  ! call self%get_nested()
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get

  elemental subroutine get_value(self, string)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get the tag value from string after tag_name has been set.
  !<
  !< @note It is worth noting that the leading and trailing white spaces of tag value are removed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_Tag), intent(INOUT) :: self   !< XML tag.
  character(*),        intent(IN)    :: string !< String containing data.
  integer                            :: c1, c2 !< Counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (index(string=string, substring='<'//self%tag_name)>0) then
    c2 = index(string=string, substring='</'//self%tag_name//'>')
    if (c2>0) then ! parsing tag value
      c1 = index(string=string, substring='>')
      self%tag_val = trim(adjustl(string(c1+1:c2-1)))
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_value

  elemental subroutine get_attributes(self, string)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get the attributes values from string after tag_name and att_name have been set.
  !<
  !< @note It is worth noting that the leading and trailing white spaces of attributes values are removed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_Tag), intent(INOUT) :: self      !< XML tag.
  character(*),        intent(IN)    :: string    !< String containing data.
  integer                            :: a, c1, c2 !< Counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (index(string=string, substring='<'//self%tag_name)>0) then
    if (allocated(self%att_name)) then ! parsing attributes
      call self%alloc_attributes(att_val=.true., Na=size(self%att_name, dim=1))
      do a=1, size(self%att_name, dim=1)
        c1 = index(string=string, substring=self%att_name(a)%vs//'="') + len(self%att_name(a)%vs) + 2
        if (c1>len(self%att_name(a)%vs) + 2) then
          c2 = index(string=string(c1:), substring='"')
          if (c2>0) then
            self%att_val(a)%vs = trim(adjustl(string(c1:c1+c2-2)))
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

  elemental subroutine parse_tag_name(self, string, tstart, tend)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Parse the tag name contained into a string.
  !<
  !< It is assumed that the first tag contained into the string is parsed, the others eventually present are omitted.
  !< Valid syntax are:
  !< + `<tag_name att1="att1 val" att2="att2 val"...>...</tag_name>`
  !< + `<tag_name att1="att1 val" att2="att2 val".../>`
  !< @note Inside the attributes value the symbols `<` and `>` are not allowed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_Tag),    intent(INOUT) :: self    !< XML tag.
  character(*),           intent(IN)    :: string  !< String containing the input.
  integer(I4P), optional, intent(OUT)   :: tstart  !< Starting index of tag inside the string.
  integer(I4P), optional, intent(OUT)   :: tend    !< Ending index of tag inside the string.
  integer(I4P)                          :: tstartd !< Starting index of tag inside the string.
  integer(I4P)                          :: tendd   !< Ending index of tag inside the string.
  character(len=1)                      :: c1      !< Dummy string for parsing file.
  character(len=:), allocatable         :: c2      !< Dummy string for parsing file.
  integer(I4P)                          :: c, s    !< Counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  tstartd = 0
  tendd   = 0
  c = 1
  Tag_Search: do while(c<=len(string))
    c1 = string(c:c)
    if (c1=='<') then
      tstartd = c
      c2 = c1
      Tag_Name: do while(c<len(string))
        c = c + 1 ; c1 = string(c:c)
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

  elemental subroutine parse_attributes_names(self, string)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Parse the tag attributes names contained into a string.
  !<
  !< Valid syntax is:
  !< + `att1="att1 val" att2="att2 val"...`
  !< @note Inside the attributes value the symbols `<` and `>` are not allowed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_Tag), intent(INOUT) :: self     !< XML tag.
  character(*),        intent(IN)    :: string   !< String containing the input.
  character(len=:), allocatable      :: att      !< Dummy string for parsing file.
  integer(I4P)                       :: c, a, Na !< Counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  Na = 0
  c = 1
  Att_Count: do while(c<=len(string))
    if (string(c:c)=='=') Na = Na + 1
    c = c + 1
  enddo Att_Count
  if (Na>0) then
    call self%alloc_attributes(att_name=.true., Na=Na)
    c = index(string=string, substring=' ')
    att = trim(adjustl(string(c + 1:)))
    c = 1
    a = 1
    Att_Search: do while(c<=len(att))
      if (att(c:c)=='=') then
        self%att_name(a)%vs = trim(adjustl(att(:c-1)))
        att = att(c:)
        c = 1
        a = a + 1
      endif
      c = c + 1
    enddo Att_Search
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine parse_attributes_names

  elemental subroutine search(self, tag_name, string, tstart, tend)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Search tag named *tag_name* into a string and, in case it is found, store into self.
  !<
  !< @note If *tag_name* is not found, self is returned empty.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_Tag),    intent(INOUT) :: self     !< XML tag.
  character(*),           intent(IN)    :: tag_name !< Searched tag name.
  character(*),           intent(IN)    :: string   !< String containing the input.
  integer(I4P), optional, intent(OUT)   :: tstart   !< Starting index of tag inside the string.
  integer(I4P), optional, intent(OUT)   :: tend     !< Ending index of tag inside the string.
  type(Type_XML_Tag)                    :: tag      !< Dummy XML tag.
  integer(I4P)                          :: tstartd  !< Starting index of tag inside the string.
  integer(I4P)                          :: tendd    !< Ending index of tag inside the string.
  logical                               :: found    !< Flag for inquiring search result.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%free
  self%tag_name = tag_name
  tstartd = 1
  tendd   = 0
  found = .false.
  Tag_Search: do while ((.not.found).or.(len(string(tendd + 1:))<len(self%tag_name)))
    call tag%parse(string=string(tendd + 1:), tstart=tstartd, tend=tendd)
    if (tstartd==0.and.tendd==0) then
      exit Tag_Search ! no tag found
    else
      if (allocated(tag%tag_name)) then
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
  !< Assignment between two selfs.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_Tag), intent(INOUT) :: lhs
  type(Type_XML_Tag),  intent(IN)    :: rhs
  integer(I4P)                       :: a
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(rhs%tag_name)) lhs%tag_name = rhs%tag_name
  if (allocated(rhs%tag_val )) lhs%tag_val  = rhs%tag_val
  if (allocated(rhs%att_name)) then
    if (allocated(lhs%att_name)) deallocate(lhs%att_name) ; allocate(lhs%att_name(1:size(rhs%att_name)))
    do a=1, size(rhs%att_name)
      if (allocated(rhs%att_name(a)%vs)) lhs%att_name(a)%vs = rhs%att_name(a)%vs
    enddo
  endif
  if (allocated(rhs%att_val)) then
    if (allocated(lhs%att_val)) deallocate(lhs%att_val) ; allocate(lhs%att_val(1:size(rhs%att_val)))
    do a=1, size(rhs%att_val)
      if (allocated(rhs%att_val(a)%vs)) lhs%att_val(a)%vs = rhs%att_val(a)%vs
    enddo
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_tag
endmodule Data_Type_XML_Tag
