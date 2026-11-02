ids = case_file%find_all(path='case/boundary')       ! every match, in document order
do b=1, size(ids)
   print '(A)', 'boundary '//case_file%attribute(ids(b), 'side')//': '//case_file%attribute(ids(b), 'type')
enddo
