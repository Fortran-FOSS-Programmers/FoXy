!< FoXy XML file class.
module foxy_xml_file
!< FoXy XML file class.
use foxy_xml_tag, only : xml_tag
use penf

implicit none
private

type, public:: xml_file
   !< XML file class.
   private
   type(xml_tag), allocatable :: tag(:)   !< XML tags array.
   integer(I4P)               :: nt=0_I4P !< Number of XML tags.
   contains
      ! public methods
      procedure, pass(self) :: add_tag    !< Add tag to XML file.
      procedure, pass(self) :: content    !< Return tag content of tag named *name*.
      procedure, pass(self) :: delete_tag !< Add tag from XML file.
      procedure, pass(self) :: free       !< Free dynamic memory.
      procedure, pass(self) :: parse      !< Parse xml file.
      procedure, pass(self) :: stringify  !< Convert the whole file data into a string.
      ! private methods
      procedure, pass(self), private :: add_child           !< Add child ID to tag children list.
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
   class(xml_file), intent(inout) :: self       !< XML file.
   type(xml_tag),   intent(in)    :: tag        !< XML tag.
   type(xml_tag), allocatable     :: tag_new(:) !< New (extended) tags array.

   if (self%nt>0_I4P) then
      allocate(tag_new(1:self%nt + 1))
      tag_new(1:self%nt) = self%tag(1:self%nt)
      tag_new(self%nt + 1) = tag
   else
      allocate(tag_new(1:1))
      tag_new(1) = tag
   endif
   call tag_new(self%nt + 1)%set(id=self%nt + 1, parent_id=0_I4P)
   if (allocated(tag_new(self%nt + 1)%child_id)) deallocate(tag_new(self%nt + 1)%child_id)
   tag_new(self%nt + 1)%children_number = 0_I4P

   call move_alloc(from=tag_new, to=self%tag)
   self%nt = self%nt + 1
   endsubroutine add_tag

   pure function content(self, name)
   !< Return tag content of tag named *name*.
   !<
   !< @note If there is no value, the *tag_content* string is returned empty, but allocated.
   !< @note Leading and trailing blanks (new lines included) are layout, not data: they are stripped from the returned
   !< content, while the stored content keeps them for a faithful *stringify*.
   class(xml_file), intent(in)   :: self    !< XML file.
   character(*),    intent(in)   :: name    !< Tag name.
   character(len=:), allocatable :: content !< Tag content.
   integer(I4P)                  :: t       !< Counter.

   if (allocated(content)) deallocate(content)
   if (self%nt>0) then
      do t=1, self%nt
         call self%tag(t)%get_content(name=name, content=content)
         if (allocated(content)) exit
      enddo
   endif
   if (allocated(content)) then
      content = strip_blanks(content)
   else
      content = ''
   endif
   endfunction content

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
   endsubroutine free

   subroutine parse(self, string, filename)
   !< Parse xml data from string or file.
   !< XML data is linearized, a DOM structured is used.
   !<
   !< @note Self data are free before trying to parse new xml data: all previously parsed data are lost.
   class(xml_file),        intent(inout) :: self     !< XML file.
   character(*), optional, intent(in)    :: string   !< String containing xml data.
   character(*), optional, intent(in)    :: filename !< File name containing xml data.
   character(len=:), allocatable         :: source   !< String containing xml data.

   call self%free
   if (present(string)) then
      call self%parse_from_string(source_string=string)
   elseif (present(filename)) then
      source = load_file_as_stream(filename=filename, fast_read=.true.)
      if (allocated(source)) call self%parse_from_string(source_string=source) ! unallocated if file is missing/unreadable
   endif
   endsubroutine parse

   pure function stringify(self, linearize) result(string)
   !< Convert the whole file data into a string.
   class(xml_file), intent(in)           :: self       !< XML file.
   logical,         intent(in), optional :: linearize  !< Return a "linearized" string of tags without the XML hieararchy.
   logical                               :: linearize_ !< Linearize sentinel, local var.
   character(len=:), allocatable         :: string     !< Output string containing the whole xml file.
   character(len=:), allocatable         :: tag_string !< Output string containing the current tag.
   integer(I4P)                          :: t          !< Counter.
   logical, allocatable                  :: is_done(:) !< List of stringified tags.

   linearize_ = .false. ; if (present(linearize)) linearize_ = linearize
   string = ''
   if (linearize_) then
      if (self%nt>0) then
         do t=1, self%nt
            string = string//self%tag(t)%stringify(linearize=.true.)//new_line('a')
         enddo
      endif
   else
      if (self%nt>0) then
         allocate(is_done(self%nt)) ; is_done = .false.
         do t=1, self%nt
            if (is_done(t)) cycle
            if (self%tag(t)%children_number>0) then
               tag_string = ''
               call self%stringify_recursive(tag=self%tag(t), is_done=is_done, tag_string=tag_string)
               if (tag_string(1:1)==new_line('a')) tag_string = tag_string(2:)
            else
               tag_string = self%tag(t)%stringify(is_indented=.true.)
            endif
            string = string//tag_string//new_line('a')
            is_done(t) = .true.
         enddo
      endif
   endif
   if (string(len(string):len(string))==new_line('a')) string = string(:len(string)-1)
   endfunction stringify

   ! private methods
   pure subroutine add_child(self, parent_id, child_id)
   !< Add child ID to tag children list.
   class(xml_file), intent(inout) :: self      !< XML file handler.
   integer(I4P),    intent(in)    :: child_id  !< Child ID.
   integer(I4P),    intent(in)    :: parent_id !< Parent ID.

   if (parent_id > 0 .and. parent_id <= self%nt) call self%tag(parent_id)%add_child_id(child_id=child_id)
   endsubroutine add_child

   pure subroutine parse_from_string(self, source_string)
   !< Parse xml data from a chunk of source string (file stringified for IO on device).
   class(xml_file), intent(inout) :: self                                     !< XML file handler.
   character(*),    intent(in)    :: source_string                            !< String containing xml data.
   integer(I4P)                   :: pos, start_pos, end_pos, end_content_pos !< Position indexes.
   character(:), allocatable      :: tag_name                                 !< Tag name buffer.
   character(:), allocatable      :: attributes_str                           !< Tag attributes string buffer.
   character(:), allocatable      :: tag_content                              !< Tag content string buffer.
   integer(I4P)                   :: current_level                            !< Nesting level counter.
   logical                        :: is_closing_tag                           !< Sentinel for closing tag.
   logical                        :: is_self_closing                          !< Sentinel for self closing tag.
   type(xml_tag)                  :: tag                                      !< XML tag handler.
   integer(I4P)                   :: parent_id                                !< Uniq parent tag ID.
   integer(I4P), allocatable      :: parent_stack(:)                          !< Stack of parents ID.

   call self%free
   pos = 1_I4P
   current_level = 0_I4P
   allocate(parent_stack(1))
   parent_stack = 0_I4P
   do while (pos <= len_trim(source_string))
      ! next tag start
      start_pos = index(source_string(pos:), '<')
      if (start_pos == 0) exit
      start_pos = pos + start_pos - 1

      ! skip comment, XML header
      if (start_pos + 3 <= len_trim(source_string)) then
         if (source_string(start_pos:start_pos+3) == '<!--'.or.source_string(start_pos:start_pos+1) == '<?') then
            end_pos = index(source_string(start_pos+1:), '>')
            if (end_pos == 0) exit
            pos = start_pos + end_pos + 1
            cycle
         endif
      endif
      ! close current tag
      end_pos = index(source_string(start_pos:), '>')
      if (end_pos == 0) exit
      end_pos = start_pos + end_pos - 1

      ! parse tag
      call parse_tag_name(tag_str         = source_string(start_pos:end_pos), &
                          tag_name        = tag_name,                         &
                          attributes_str  = attributes_str,                   &
                          is_closing      = is_closing_tag,                   &
                          is_self_closing = is_self_closing)
      if (allocated(tag_name)) then
         if (is_closing_tag) then
            current_level = current_level - 1
         else
            ! add new tag to XML tags list
            call tag%free
            call self%add_tag(tag=tag)
            current_level = current_level + 1
            ! get parent/child id
            parent_id = 0_I4P ! root tag, unless a parent is found: never the previous tag parent
            if (current_level>1) then
               if (parent_stack(current_level-1)>0)  then
                  parent_id = parent_stack(current_level-1)
                  call self%add_child(parent_id=parent_stack(current_level - 1), child_id=self%nt)
               endif
            endif
            ! parent_stack(current_level) = self%nt
            if (current_level==1) then
               parent_stack(1) = self%nt
            else
               if (current_level>1) parent_stack = [parent_stack(1:current_level-1),self%nt]
            endif
            end_content_pos = -1 ! initialize position for self closing tag
            if (allocated(tag_content)) deallocate(tag_content) ! a self closing tag has no content, not the previous one
            if (.not.is_self_closing) then
               ! get tag content
               call get_tag_content(source=source_string, tag_name=tag_name, start_pos=end_pos + 1, content=tag_content, &
                                    end_pos=end_content_pos)
            endif
            call self%tag(self%nt)%set(name                      = tag_name,                              &
                                       sanitize_attributes_value = .true.,                                &
                                       pos                       = [start_pos, end_pos, end_content_pos], &
                                       indent                    = (current_level-1)*2,                   &
                                       is_self_closing           = is_self_closing,                       &
                                       id                        = self%nt,                               &
                                       level                     = current_level,                         &
                                       parent_id                 = parent_id,                             &
                                       attributes_stream_alloc   = attributes_str,                        &
                                       content_alloc             = tag_content)
            if (is_self_closing) current_level = current_level - 1
         endif
      endif
      pos = end_pos + 1
   enddo
   endsubroutine parse_from_string

   recursive pure subroutine stringify_recursive(self, tag, is_done, tag_string)
   !< Convert recursively tags with children into a string.
   class(xml_file),               intent(in)    :: self       !< XML file.
   type(xml_tag),                 intent(in)    :: tag        !< XML tag with children.
   logical,                       intent(inout) :: is_done(:) !< List of stringified tags.
   character(len=:), allocatable, intent(inout) :: tag_string !< Output string containing the current tag.
   integer(I4P)                                 :: t          !< Counter.

   if (tag%children_number>0) then
      tag_string = tag_string//new_line('a')//tag%stringify(is_indented=.true., only_start=.true.)
      do t=1, tag%children_number
         call self%stringify_recursive(tag=self%tag(tag%child_id(t)), is_done=is_done, tag_string=tag_string)
         is_done(tag%child_id(t)) = .true.
      enddo
      tag_string = tag_string//new_line('a')//tag%stringify(is_indented=.true., only_end=.true.)
   else
      tag_string = tag_string//new_line('a')//tag%stringify(is_indented=.true.)
   endif
   endsubroutine stringify_recursive

   ! operators
   subroutine finalize(self)
   !< Free dynamic memory when finalizing.
   type(xml_file), intent(inout) :: self !< XML file.

   call self%free
   endsubroutine finalize

   ! non TBP
   pure subroutine find_matching_end_tag(source, start_pos, tag_name, end_pos)
   !< Find the end tag matching an open tag, accounting for nested tags with the same name.
   !<
   !< @note Open and end tags are processed in source order; self closing tags are skipped. If no matching end tag exists,
   !< *end_pos* is returned as 0.
   character(*), intent(in)  :: source    !< Source containing tag content.
   character(*), intent(in)  :: tag_name  !< Tag name.
   integer(I4P), intent(in)  :: start_pos !< Start tag content position.
   integer(I4P), intent(out) :: end_pos   !< End tag position.
   character(*), parameter   :: NAME_END = ' >/'//achar(9)//achar(10)//achar(13) !< Characters terminating a tag name.
   character(:), allocatable :: open_tag  !< Open tag.
   character(:), allocatable :: end_tag   !< End tag.
   integer(I4P)              :: pos       !< Position counter.
   integer(I4P)              :: pos_open  !< Next open tag position.
   integer(I4P)              :: pos_end   !< Next end tag position.
   integer(I4P)              :: tag_close !< Closing `>` position of an open tag.
   integer(I4P)              :: tag_count !< Tags counter.

   open_tag = '<'//trim(tag_name)
   end_tag = '</'//trim(tag_name)//'>'
   tag_count = 1
   pos = start_pos
   end_pos = 0
   do while (pos <= len(source))
      pos_end = index(source(pos:), end_tag) ! relative position
      if (pos_end == 0) return ! no matching end tag
      pos_end = pos + pos_end - 1 ! absolute position
      pos_open = index(source(pos:pos_end), open_tag) ! relative position, only before the next end tag
      if (pos_open > 0) then
         pos_open = pos + pos_open - 1 ! absolute position
         ! pos_open < pos_end, thus the character after the tag name exists
         if (index(NAME_END, source(pos_open+len(open_tag):pos_open+len(open_tag))) > 0) then
            ! open tag, unless self closing: it has no matching end tag
            tag_close = index(source(pos_open:), '>') ! relative position
            if (tag_close == 0) return ! malformed open tag
            tag_close = pos_open + tag_close - 1 ! absolute position
            if (source(tag_close-1:tag_close-1) /= '/') tag_count = tag_count + 1
            pos = tag_close + 1
         else
            pos = pos_open + len(open_tag) ! other tag whose name starts with tag_name, e.g. <ab> for <a>
         endif
      else
         tag_count = tag_count - 1
         if (tag_count == 0) then
            end_pos = pos_end ! found matching end tag
            return
         endif
         pos = pos_end + len(end_tag)
      endif
   enddo
   endsubroutine find_matching_end_tag

   pure subroutine get_tag_content(source, tag_name, start_pos, content, end_pos)
   !< Get tag content.
   character(*),              intent(in)            :: source       !< Source containing tag content.
   character(*),              intent(in)            :: tag_name     !< Tag name.
   integer,                   intent(in)            :: start_pos    !< Start tag content position.
   character(:), allocatable, intent(out)           :: content      !< Extracted tag content.
   integer(I4P),              intent(out), optional :: end_pos      !< End tag content position.
   character(:), allocatable                        :: end_tag      !< End tag.
   integer(I4P)                                     :: end_pos_     !< End tag content position, local var.
   integer(I4P)                                     :: next_pos     !< Next tag start position.
   character(:), allocatable                        :: temp_content !< Buffer.

   end_tag = '</'//trim(tag_name)//'>'
   content = ''

   call find_matching_end_tag(source=source, start_pos=start_pos, tag_name=tag_name, end_pos=end_pos_)

   if (present(end_pos)) end_pos = end_pos_
   if (end_pos_ > start_pos) then
      ! search first nested tag, if any
      next_pos = index(source(start_pos:end_pos_-1), '<')

      if (next_pos > 0) then
         ! find nested tag
         next_pos = start_pos + next_pos - 2
         temp_content = trim(adjustl(source(start_pos:next_pos)))
         if (len(temp_content) > 0) content = temp_content
      else
         ! no nested tag
         temp_content = trim(adjustl(source(start_pos:end_pos_-1)))
         if (len(temp_content) > 0) content = temp_content
      endif
   endif
   endsubroutine get_tag_content

   pure function strip_blanks(string) result(stripped)
   !< Return string without leading and trailing blanks: spaces, tabs, new lines and carriage returns.
   character(*), intent(in)      :: string   !< String to strip.
   character(len=:), allocatable :: stripped !< Stripped string.
   character(*), parameter       :: BLANKS = ' '//achar(9)//achar(10)//achar(13) !< Blank characters.
   integer(I4P)                  :: first    !< First not blank character position.
   integer(I4P)                  :: last     !< Last not blank character position.

   first = verify(string, BLANKS)
   if (first == 0) then
      stripped = ''
   else
      last = verify(string, BLANKS, back=.true.)
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
   endfunction load_file_as_stream

   pure subroutine parse_tag_name(tag_str, tag_name, attributes_str, is_closing, is_self_closing)
   !< Parse current tag, only name and attributes.
   character(*),              intent(in)  :: tag_str         !< Tag string.
   character(:), allocatable, intent(out) :: tag_name        !< Parsed tag name.
   character(:), allocatable, intent(out) :: attributes_str  !< Parsed attributes list.
   logical,                   intent(out) :: is_closing      !< Sentinel for closing tag.
   logical,                   intent(out) :: is_self_closing !< Sentinel for self closing tag.
   character(:), allocatable              :: clean_tag       !< Clean tag string.
   integer(I4P)                           :: space_pos       !< Blank space position.

   clean_tag = trim(adjustl(tag_str))
   if (len(clean_tag) < 3) return

   ! trim < and >
   clean_tag = clean_tag(2:len(clean_tag)-1)

   is_self_closing = (clean_tag(len(clean_tag):len(clean_tag)) == '/')
   if (is_self_closing) then
      is_closing = .false.
   else
      is_closing = (clean_tag(1:1) == '/')
   endif

   if (is_closing) clean_tag = clean_tag(2:)

   if (is_self_closing) clean_tag = clean_tag(1:len(clean_tag)-1)

   ! parse name and attributes
   space_pos = index(clean_tag, ' ')
   if (space_pos > 0) then
      tag_name = clean_tag(1:space_pos-1)
      attributes_str = clean_tag(space_pos+1:)
   else
      tag_name = clean_tag
   endif
   endsubroutine parse_tag_name
endmodule foxy_xml_file
