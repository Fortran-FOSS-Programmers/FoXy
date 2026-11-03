call doc%parse(filename='station-utf16.xml', iostat=iostat)    ! UTF-16, little endian, with its byte order mark
print '(A,I0,1X,A)', 'UTF-16: ', iostat, doc%attribute(doc%find(name='station'), 'name')
call doc%parse(filename='station-latin1.xml', iostat=iostat)   ! declared encoding="ISO-8859-1"
print '(A,I0,1X,A)', 'ISO-8859-1: ', iostat, doc%attribute(doc%find(name='station'), 'name')// &
                     ' '//doc%content(name='reading')//' '//doc%attribute(doc%find(name='reading'), 'unit')
call doc%save(filename='station.xml')                          ! written in UTF-8, declared so
