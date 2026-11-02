program read_list
use foxy
implicit none
type(xml_file)         :: doc
real(R8P), allocatable :: domain(:)

call doc%parse(filename='case.xml')
call doc%get_content(id=doc%find(path='case/mesh/domain'), values=domain)   ! allocated to the list size
print '(I0,A,6F5.2)', size(domain), ' values:', domain
endprogram read_list
