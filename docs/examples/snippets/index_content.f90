program index_content
use foxy
implicit none
type(xml_index)        :: idx
real(R8P), allocatable :: domain(:)
integer(I8P)           :: first, last

call idx%scan(filename='case.xml')
print '(A)', 'dt: '//idx%content(idx%find(path='case/time/dt'))
call idx%get_content(id=idx%find(name='domain'), values=domain)
call idx%text_range(id=idx%find(name='domain'), first=first, last=last)
print '(A,I0,A,I0,A,I0)', 'domain: ', size(domain), ' values at bytes ', first, '-', last
endprogram index_content
