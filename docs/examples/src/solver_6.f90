program solver
!< Tutorial, chapter 6: large outputs, the index.
use foxy
implicit none
type(xml_index)           :: results
integer(I4P), allocatable :: snapshots(:)
real(R8P),    allocatable :: pressure(:)
integer(I4P)              :: s, iostat, step
integer(I8P)              :: first, last

!region scan
call results%scan(filename='results.xml', iostat=iostat)   ! tags and attributes only, no content
snapshots = results%find_all(path='results/snapshot')
print '(A,I0,A,I0,A)', 'indexed ', results%tags_number(), ' tags, ', size(snapshots), ' snapshots'
!endregion scan
!region on_demand
do s=1, size(snapshots)
   call results%get_attribute(id=snapshots(s), name='step', value=step)
   call results%get_content(id=results%find(name='pressure', parent=snapshots(s)), values=pressure)  ! read now
   call results%content_range(id=results%find(name='pressure', parent=snapshots(s)), first=first, last=last)
   print '(A,I3,A,3F7.3,A,I0,A,I0)', 'step ', step, ': p =', pressure, ', bytes ', first, '-', last
enddo
!endregion on_demand
!region stop_at
call results%scan(filename='results.xml', stop_at='pressure')   ! stop after the first <pressure ...>
print '(A,I0,A,I0)', 'stopped at byte ', results%stop_position(), ', tags indexed: ', results%tags_number()
!endregion stop_at
endprogram solver
!as solver
!run solver_6 solver
