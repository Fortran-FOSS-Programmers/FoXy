print '(A)', 'thermal dt: '//coupled%content(id=ids(1))
t = coupled%find(path='f:coupled/f:case/f:dt', namespaces='xmlns:f="https://example.org/flow"')   ! your own prefixes
print '(A)', 'flow dt:    '//coupled%content(id=t)
t = coupled%find(name='m:conductivity', namespaces='xmlns:m="https://example.org/materials"')
print '(A)', 'k:          '//coupled%content(id=t)
print '(A,I0)', 'literal "dt" matches: ', size(coupled%find_all(name='dt'))       ! names without a map: literal
