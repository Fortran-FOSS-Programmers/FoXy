subroutine on_start(self, name, attributes)
class(snapshot_stats), intent(inout) :: self
character(*),          intent(in)    :: name
type(xml_attribute),   intent(in)    :: attributes(:)
integer                              :: a
select case(name)
case('snapshot')
   do a=1, size(attributes)                        ! attributes come with the start of the element
      if (attributes(a)%name=='step') read(attributes(a)%value, *) self%step
   enddo
case('pressure')
   self%is_inside = .true.
   self%text = ''
endselect
endsubroutine on_start

subroutine on_text(self, text)                    ! the text may come in pieces: collect it
class(snapshot_stats), intent(inout) :: self
character(*),          intent(in)    :: text
if (self%is_inside) self%text = self%text//text
endsubroutine on_text

subroutine on_end(self, name)
class(snapshot_stats), intent(inout) :: self
character(*),          intent(in)    :: name
real(R8P), allocatable               :: p(:)
integer(I4P)                         :: iostat
character(len=:), allocatable        :: iomsg
select case(name)
case('pressure')                                   ! the text is complete: convert it
   self%is_inside = .false.
   call to_values(self%text, p, iostat, iomsg)
   if (iostat==0) print '(A,I3,A,F6.3,A,F6.3)', 'step ', self%step, ': mean p = ', sum(p)/size(p), ', max = ', maxval(p)
case('snapshot')
   if (self%step>=self%last_step) call self%stop_parsing()   ! the rest of the file is not read
endselect
endsubroutine on_end
