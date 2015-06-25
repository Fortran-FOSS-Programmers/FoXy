!< Definition of Type_XML_File for FoXy XML Parser.
module Data_Type_XML_File
!-----------------------------------------------------------------------------------------------------------------------------------
!< Definition of Type_XML_File for FoXy XML Parser.
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision      ! Integers and reals precision definition.
USE Data_Type_XML_Tag ! Definition of Type_XML_Tag.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
type, public:: Type_XML_File
  !< Derived type defining Type_XML_File, the base type of FoXy XML parser.
  private
  integer(I4P)                    :: Nt = 0 !< Number of XML tags.
  type(Type_XML_Tag), allocatable :: tag(:) !< XML tags array.
  contains
    ! public type-bound procedures
    procedure         :: free
    final             :: finalize
    procedure         :: parse
    procedure         :: tag_value
    procedure         :: stringify
    procedure, nopass :: load_file_as_stream
    ! private type-bound procedures
    procedure, private :: add_tag
endtype Type_XML_File
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  ! public
  elemental subroutine free(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_File), intent(INOUT) :: self !< XML file.
  integer(I4P)                        :: t    !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (self%Nt>0) then
    do t=1, self%Nt
      call self%tag(t)%free
    enddo
    deallocate(self%tag)
    self%Nt = 0
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free

  subroutine finalize(xml_file)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory when finalizing.
  !---------------------------------------------------------------------------------------------------------------------------------
  type(Type_XML_File), intent(INOUT) :: xml_file !< XML file.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call xml_file%free
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize

  subroutine parse(self, string, filename)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Parse xml data from string or file.
  !<
  !< @note Self data are free before trying to parse new xml data: all previously parsed data are lost.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_File),   intent(INOUT) :: self         !< XML file.
  character(*), optional, intent(IN)    :: string       !< String containing xml data.
  character(*), optional, intent(IN)    :: filename     !< File name containing xml data.
  type(Type_XML_Tag)                    :: tag          !< Dummy xml tag.
  integer(I4P)                          :: tstart, tend !< Counters for tracking string parsing.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%free
  if (present(string)) then
    tstart = 1
    tend = 0
    do while(tstart<len(string))
      call tag%free
      call tag%parse(string=string(tstart:), tend=tend)
      if (tend==0) exit
      if (tag%is_parsed()) call self%add_tag(tag)
      tstart = tstart + tend
    enddo
  elseif (present(filename)) then
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine parse

  pure subroutine tag_value(self, tag_name, tag_val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Return tag value of tag named *tag_name*.
  !<
  !< @note If there is no value, the *tag_value* string is returned deallocated.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_File),          intent(IN)    :: self     !< XML file.
  character(*),                  intent(IN)    :: tag_name !< Tag name.
  character(len=:), allocatable, intent(INOUT) :: tag_val  !< Tag value.
  integer(I4P)                                 :: t        !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(tag_val)) deallocate(tag_val)
  if (self%Nt>0) then
    do t=1, self%Nt
      call self%tag(t)%tag_value(tag_name=tag_name, tag_val=tag_val)
      if (allocated(tag_val)) exit
    enddo
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine tag_value

  pure function stringify(self) result(string)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Convert the whole file data into a string.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_File), intent(IN) :: self       !< XML file.
  character(len=:), allocatable    :: string     !< Output string containing the whole xml file.
  character(len=:), allocatable    :: tag_string !< Output string containing the current tag.
  integer(I4P)                     :: t          !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  string = ''
  if (self%Nt>0) then
    do t=1, self%Nt - 1
      tag_string = self%tag(t)%stringify()
      string = string//tag_string//new_line('a')
    enddo
    tag_string = self%tag(self%Nt)%stringify()
    string = string//tag_string
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction stringify

  function load_file_as_stream(iostat, iomsg, delimiter_start, delimiter_end, fast_read, filename) result(stream)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Load file contents and store as single characters stream.
  !---------------------------------------------------------------------------------------------------------------------------------
  integer(I4P), optional, intent(OUT) :: iostat          !< IO error.
  character(*), optional, intent(OUT) :: iomsg           !< IO error message.
  character(*), optional, intent(IN)  :: delimiter_start !< Delimiter from which start the stream.
  character(*), optional, intent(IN)  :: delimiter_end   !< Delimiter to which end the stream.
  logical,      optional, intent(IN)  :: fast_read       !< Flag for activating efficient reading with one single read.
  character(*),           intent(IN)  :: filename        !< File name.
  character(len=:), allocatable       :: stream          !< Output string containing the file data as a single stream.
  logical                             :: is_file         !< Flag for inquiring the presence of the file.
  integer(I4P)                        :: unit            !< Unit file.
  integer(I4P)                        :: iostatd         !< IO error.
  character(500)                      :: iomsgd          !< IO error message.
  character(1)                        :: c1              !< Single character.
  character(len=:), allocatable       :: string          !< Dummy string.
  logical                             :: cstart          !< Flag for stream capturing trigging.
  logical                             :: cend            !< Flag for stream capturing trigging.
  logical                             :: fast            !< Flag for activating efficient reading with one single read.
  integer(I4P)                        :: filesize        !< Size of the file for fast reading.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  fast = .false. ; if (present(fast_read)) fast = fast_read
  ! inquire file existance
  inquire(file=adjustl(trim(filename)), exist=is_file, iostat=iostatd, iomsg=iomsgd)
  if (.not.is_file) then
    if (present(iostat)) iostat = iostatd
    if (present(iomsg )) iomsg  = iomsgd
    return
  endif
  ! open file
  open(newunit=unit, file=adjustl(trim(filename)), access='STREAM', form='UNFORMATTED', iostat=iostatd, iomsg=iomsgd)
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
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction load_file_as_stream

  ! private
  elemental subroutine add_tag(self, tag)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Add tag to self%tag array.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(Type_XML_File),   intent(INOUT) :: self       !< XML file.
  type(Type_XML_Tag),     intent(IN)    :: tag        !< XML tag.
  type(Type_XML_Tag), allocatable       :: tag_new(:) !< New (extended) tags array.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (self%Nt>0_I4P) then
    allocate(tag_new(1:self%Nt + 1))
    tag_new(1:self%Nt) = self%tag(1:self%Nt)
    tag_new(self%Nt + 1) = tag
  else
    allocate(tag_new(1:1))
    tag_new(1) = tag
  endif
  call move_alloc(from=tag_new, to=self%tag)
  self%Nt = self%Nt + 1
  if (allocated(tag_new)) deallocate(tag_new)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add_tag
endmodule Data_Type_XML_File
