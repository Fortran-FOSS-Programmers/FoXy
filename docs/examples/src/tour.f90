!as fx
!run tour-tree fx tree case.xml
!run tour-get fx get case.xml case/time/dt
!run tour-select fx select case.xml '//boundary[@type="wall"]'
!run tour-match fx match case.xml 'e-[0-9]+$'
!run tour-check fx check broken.xml
!run tour-events fx events station-utf16.xml
!cast tour tour-tree tour-get tour-select tour-match tour-check tour-events
module tour_printer
!< A streaming handler printing each event, indented by its depth.
use foxy
implicit none
private
public :: printer

type, extends(xml_handler) :: printer
   contains
      procedure :: start_element => on_start
      procedure :: characters    => on_text
      procedure :: end_element   => on_end
endtype printer

contains
   subroutine on_start(self, name, attributes)
   class(printer),      intent(inout) :: self
   character(*),        intent(in)    :: name
   type(xml_attribute), intent(in)    :: attributes(:)
   integer                            :: a
   write(*, '(A)', advance='no') repeat('  ', self%level-1)//'start '//name
   do a = 1, size(attributes)
      write(*, '(A)', advance='no') ' '//attributes(a)%name//'="'//attributes(a)%value//'"'
   enddo
   print '(A)', ''
   endsubroutine on_start

   subroutine on_text(self, text)
   class(printer), intent(inout) :: self
   character(*),   intent(in)    :: text
   character(*), parameter       :: BLANKS = ' '//achar(9)//achar(10)//achar(13)
   integer                       :: first, last
   first = verify(text, BLANKS)                  ! layout between the tags is not printed
   if (first==0) return
   last = verify(text, BLANKS, back=.true.)
   print '(A)', repeat('  ', self%level)//'text  '//text(first:last)
   endsubroutine on_text

   subroutine on_end(self, name)
   class(printer), intent(inout) :: self
   character(*),   intent(in)    :: name
   print '(A)', repeat('  ', self%level-1)//'end   '//name
   endsubroutine on_end
endmodule tour_printer

program tour
!< fx: a small command line tool built on FoXy.
use foxy
use tour_printer, only : printer
implicit none
type(xml_file)                :: doc
type(printer)                 :: handler
type(regex)                   :: re
character(len=256)            :: command, file, arg
character(len=300)            :: iomsg
integer(I4P), allocatable     :: ids(:)
integer(I4P)                  :: iostat, id, i
real(R8P)                     :: value

call get_command_argument(1, command)
call get_command_argument(2, file)
call get_command_argument(3, arg)
select case(trim(command))
case('tree')                                                   ! the outline: every tag, indented by its level
   call doc%parse(filename=trim(file))
   do id = 1, doc%tags_number()
      print '(A)', repeat('  ', doc%level(id)-1)//doc%name(id)
   enddo
case('get')                                                    ! a content, read as a number
   call doc%parse(filename=trim(file))
   id = doc%find(path=trim(arg))
   call doc%get_content(id=id, value=value, iostat=iostat, iomsg=iomsg)
   if (iostat==0) then
      print '(A,ES10.3,1X,A)', trim(arg)//' =', value, doc%attribute(id, 'unit')
   else
      print '(A)', trim(iomsg)
   endif
case('select')                                                 ! a path expression
   call doc%parse(filename=trim(file))
   ids = doc%select(trim(arg), iostat=iostat, iomsg=iomsg)
   if (iostat/=0) print '(A)', trim(iomsg)
   do i = 1, size(ids)
      print '(I3,1X,A)', ids(i), doc%name(ids(i))//' side='//doc%attribute(ids(i), 'side')
   enddo
case('match')                                                  ! contents matching a regular expression
   call doc%parse(filename=trim(file))
   call re%compile(trim(arg), iostat=iostat)
   ids = doc%matching(re, on='content')
   do i = 1, size(ids)
      print '(A)', doc%name(ids(i))//' = '//doc%content(id=ids(i))
   enddo
case('check')                                                  ! well-formed, or the first problem and its line
   call doc%parse(filename=trim(file), iostat=iostat, iomsg=iomsg)
   if (iostat==0) then
      print '(A)', trim(file)//': well-formed'
   else
      print '(A)', trim(file)//': '//trim(iomsg)
   endif
case('events')                                                 ! the streaming parser: callbacks, nothing stored
   call handler%parse(filename=trim(file), iostat=iostat, iomsg=iomsg)
   if (iostat/=0) print '(A)', trim(iomsg)
endselect
endprogram tour
