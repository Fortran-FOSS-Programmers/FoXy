program solver
!< Tutorial, chapter 5: writing the results.
use foxy
implicit none
type(xml_writer)   :: results
integer(I4P)       :: iostat, step, i
character(len=256) :: iomsg
character(len=16)  :: value

call results%open(filename='results.xml', iostat=iostat, iomsg=iomsg)
call results%declaration(encoding='UTF-8')
call results%start('results')
call results%attribute('case', 'cavity')
call results%attribute('steps', 500_I4P)
do step=100, 500, 200
   call results%start('snapshot')
   call results%attribute('step', step)
   call results%attribute('time', real(step, R8P)*1.0e-3_R8P, fmt='(F5.3)')
   call results%start('residual')
   call results%text('converged & stable')
   call results%end('residual')
   call results%start('pressure')
   call results%attribute('format', 'ascii')
   do i=1, 3                                              ! data written in pieces, as they are
      write(value, '(F6.3)') 1.0_R8P/real(i*step, R8P)*100.0_R8P
      if (i>1) call results%raw(' ')
      call results%raw(trim(adjustl(value)))
   enddo
   call results%end('pressure')
   call results%end('snapshot')
enddo
call results%comment(' 3 snapshots ')
call results%close(iostat=iostat, iomsg=iomsg)           ! closes the open elements, reports the first error
print '(A,I0)', 'results.xml written, iostat = ', iostat
endprogram solver
