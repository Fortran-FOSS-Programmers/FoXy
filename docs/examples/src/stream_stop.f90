module wall_finder
!< A handler looking for the first wall boundary: it stops there, and prints the problems it meets.
use foxy
implicit none
private
public :: first_wall

type, extends(xml_handler) :: first_wall
   character(len=:), allocatable :: side
   contains
      procedure :: start_element => on_start
      procedure :: problem       => on_problem
endtype first_wall

contains
   subroutine on_start(self, name, attributes)
   class(first_wall),   intent(inout) :: self
   character(*),        intent(in)    :: name
   type(xml_attribute), intent(in)    :: attributes(:)
   integer                            :: a
   logical                            :: is_wall
   if (name/='boundary') return
   is_wall = .false.
   do a = 1, size(attributes)
      if (attributes(a)%name=='type') is_wall = attributes(a)%value=='wall'
      if (attributes(a)%name=='side') self%side = attributes(a)%value
   enddo
   if (is_wall) call self%stop_parsing()                  ! found: no more callbacks, the rest is not read
   endsubroutine on_start

   subroutine on_problem(self, message)
   class(first_wall), intent(inout) :: self
   character(*),      intent(in)    :: message
   print '(A)', 'problem: '//message                      ! parsing goes on after a problem
   endsubroutine on_problem
endmodule wall_finder

program stream_stop
use foxy
use wall_finder, only : first_wall
implicit none
type(first_wall) :: finder
integer(I4P)     :: iostat

call finder%parse(filename='case.xml', iostat=iostat)
print '(A,I0)', 'first wall: '//finder%side//', iostat ', iostat
call finder%parse(filename='broken.xml', iostat=iostat)
print '(A,L1)', 'broken.xml malformed: ', iostat==XML_MALFORMED
endprogram stream_stop
!run stream_stop stream_stop
