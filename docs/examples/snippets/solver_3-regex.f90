call walls%compile('^(wall|outflow)$', iostat=iostat)          ! a regular expression (StringiFor engine)
ids = case_file%matching(walls, ids=case_file%find_all(path='case/boundary'), attribute='type')
print '(A,I0,A)', 'closed boundaries: ', size(ids), ' ('//case_file%attribute(ids(1), 'side')//', ...)'
