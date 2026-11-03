program regex_filter
use foxy
implicit none
type(xml_file)            :: doc
type(regex)               :: re
integer(I4P), allocatable :: ids(:)
integer(I4P)              :: iostat, i

call doc%parse(filename='case.xml')
call re%compile('^(density|viscosity)$', iostat=iostat)        ! StringiFor syntax, as Python re
ids = doc%matching(re)                                         ! on names
print '(A,*(1X,A))', 'fluid properties:', (doc%name(ids(i)), i=1, size(ids))
call re%compile('^(wall|outflow)$', iostat=iostat)
ids = doc%matching(re, ids=doc%find_all(name='boundary'), attribute='type')
print '(A,*(1X,A))', 'closed sides:', (doc%attribute(ids(i), 'side'), i=1, size(ids))
call re%compile('e-[0-9]+$', iostat=iostat)
ids = doc%matching(re, on='content')                           ! contents, decoded
print '(A,*(1X,A))', 'small values:', (doc%name(ids(i))//'='//doc%content(id=ids(i)), i=1, size(ids))
endprogram regex_filter
!run regex_filter regex_filter
