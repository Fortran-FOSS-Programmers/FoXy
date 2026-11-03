module pressure_handler
!< A handler summing the values of every <pressure> of a results file, in one pass.
use foxy
implicit none
private
public :: pressure_sum

type, extends(xml_handler) :: pressure_sum
   character(len=:), allocatable :: text          !< Text of the current <pressure>, collected in pieces.
   logical                       :: is_inside = .false.
   real(R8P)                     :: total = 0._R8P
   integer                       :: values_number = 0
   contains
      procedure :: start_element => on_start
      procedure :: characters    => on_text
      procedure :: end_element   => on_end
endtype pressure_sum

contains
   subroutine on_start(self, name, attributes)
   class(pressure_sum), intent(inout) :: self
   character(*),        intent(in)    :: name
   type(xml_attribute), intent(in)    :: attributes(:)
   self%is_inside = name=='pressure'
   if (self%is_inside) self%text = ''
   endsubroutine on_start

   subroutine on_text(self, text)                  ! the text may come in pieces: collect it
   class(pressure_sum), intent(inout) :: self
   character(*),        intent(in)    :: text
   if (self%is_inside) self%text = self%text//text
   endsubroutine on_text

   subroutine on_end(self, name)                   ! the text is complete: convert it
   class(pressure_sum), intent(inout) :: self
   character(*),        intent(in)    :: name
   real(R8P), allocatable             :: values(:)
   integer(I4P)                       :: iostat
   character(len=:), allocatable      :: iomsg
   if (name/='pressure') return
   call to_values(self%text, values, iostat, iomsg)
   if (iostat==0) then
      self%total = self%total + sum(values)
      self%values_number = self%values_number + size(values)
   endif
   self%is_inside = .false.
   endsubroutine on_end
endmodule pressure_handler

program stream_handler
use foxy
use pressure_handler, only : pressure_sum
implicit none
type(pressure_sum) :: summer
integer(I4P)       :: iostat

call summer%parse(filename='results.xml', iostat=iostat)   ! written by the tutorial, chapter 5
print '(A,I0,A,F8.3,A,I0)', 'values: ', summer%values_number, ', sum: ', summer%total, ', iostat: ', iostat
endprogram stream_handler
