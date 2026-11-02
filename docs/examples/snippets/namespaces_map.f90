program namespaces_map
use foxy
implicit none
type(xml_file)            :: doc
integer(I4P), allocatable :: ids(:)

call doc%parse(filename='coupled.xml')
ids = doc%find_all(path='flow:case/thermal:case', namespaces='xmlns:flow="https://example.org/flow" '// &
                                                             'xmlns:thermal="https://example.org/thermal"')
print '(A)', 'found '//doc%name(ids(1))//' named '//doc%attribute(ids(1), 'name')
endprogram namespaces_map
