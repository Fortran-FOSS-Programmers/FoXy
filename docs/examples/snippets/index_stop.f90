program index_stop
use foxy
implicit none
type(xml_index) :: idx
integer(I8P)    :: start

call idx%scan(filename='appended.xml', stop_at='AppendedData')   ! never reads the binary data
start = idx%stop_position()                                      ! the byte after <AppendedData ...>
print '(A,I0,A,I0)', 'tags: ', idx%tags_number(), ', binary data from byte ', start + 1
print '(A)', 'encoding: '//idx%attribute(idx%find(name='AppendedData'), 'encoding')
endprogram index_stop
