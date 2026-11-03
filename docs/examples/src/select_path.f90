program select_path
use foxy
implicit none
type(xml_file)            :: doc
integer(I4P), allocatable :: ids(:)
integer(I4P)              :: iostat, i
character(len=200)        :: iomsg

call doc%parse(filename='case.xml')
ids = doc%select('case/boundary[@type="wall"]')                ! attribute value
print '(A,*(1X,A))', 'walls:', (doc%attribute(ids(i), 'side'), i=1, size(ids))
ids = doc%select('//*[@unit]')                                 ! any name, at any depth
print '(A,*(1X,A))', 'with a unit:', (doc%name(ids(i)), i=1, size(ids))
ids = doc%select('/case/boundary[2]')                          ! the second boundary child
print '(A,*(1X,A))', 'second boundary:', (doc%attribute(ids(i), 'side'), i=1, size(ids))
ids = doc%select('//boundary[@side~="^(east|west)$"]/velocity') ! regular expression
print '(A,*(1X,A))', 'east/west velocity:', (doc%content(id=ids(i)), i=1, size(ids))
ids = doc%select('case/boundary[@type=wall]', iostat=iostat, iomsg=iomsg)
print '(A,L1,1X,A)', 'malformed: ', iostat==XML_MALFORMED, trim(iomsg)
endprogram select_path
!run select_path select_path
