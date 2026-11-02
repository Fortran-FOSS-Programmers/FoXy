do s=1, size(snapshots)
   call results%get_attribute(id=snapshots(s), name='step', value=step)
   call results%get_content(id=results%find(name='pressure', parent=snapshots(s)), values=pressure)  ! read now
   call results%content_range(id=results%find(name='pressure', parent=snapshots(s)), first=first, last=last)
   print '(A,I3,A,3F7.3,A,I0,A,I0)', 'step ', step, ': p =', pressure, ', bytes ', first, '-', last
enddo
