program writer_file
use foxy
implicit none
type(xml_writer) :: w
integer(I4P)     :: iostat, i

call w%open(filename='series.xml', iostat=iostat)
call w%declaration()
call w%start('series')
do i=1, 3
   call w%start('point')
   call w%attribute('i', i)
   call w%attribute('x', 0.5_R8P*i, fmt='(F4.2)')
   call w%end('point')
enddo
call w%close(iostat=iostat)
print '(A,I0)', 'iostat = ', iostat
endprogram writer_file
!run writer_file writer_file
!run writer_file_cat cat series.xml
