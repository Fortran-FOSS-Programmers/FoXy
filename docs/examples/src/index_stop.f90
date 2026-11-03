program index_stop
use foxy
implicit none
type(xml_index) :: idx
integer(I8P)    :: start

call idx%scan(filename='appended.xml', stop_at='AppendedData')   ! the binary data are not parsed
start = idx%stop_position()                                      ! the byte after <AppendedData ...>
print '(A,I0,A,I0)', 'tags: ', idx%tags_number(), ', binary data from byte ', start + 1 ! after the new line of flush
print '(A)', 'encoding: '//idx%attribute(idx%find(name='AppendedData'), 'encoding')
endprogram index_stop
!run index_stop index_stop
