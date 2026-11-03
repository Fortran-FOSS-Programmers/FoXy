program read_encodings
use foxy
implicit none
type(xml_file)     :: doc
type(xml_index)    :: idx
integer(I4P)       :: iostat
character(len=200) :: iomsg

!region read
call doc%parse(filename='station-utf16.xml', iostat=iostat)    ! UTF-16, little endian, with its byte order mark
print '(A,I0,1X,A)', 'UTF-16: ', iostat, doc%attribute(doc%find(name='station'), 'name')
call doc%parse(filename='station-latin1.xml', iostat=iostat)   ! declared encoding="ISO-8859-1"
print '(A,I0,1X,A)', 'ISO-8859-1: ', iostat, doc%attribute(doc%find(name='station'), 'name')// &
                     ' '//doc%content(name='reading')//' '//doc%attribute(doc%find(name='reading'), 'unit')
call doc%save(filename='station.xml')                          ! written in UTF-8, declared so
!endregion read
!region index
call idx%scan(filename='station-utf16.xml', iostat=iostat, iomsg=iomsg) ! the index reads the file bytes
print '(L1,1X,A)', iostat==XML_MALFORMED, trim(iomsg)
!endregion index
endprogram read_encodings
!run read_encodings read_encodings
!run read_encodings-head head -1 station.xml
