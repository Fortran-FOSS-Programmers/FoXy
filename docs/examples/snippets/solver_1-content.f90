dt = case_file%content('dt')               ! the text of the first tag named dt
print '(A)', 'dt    = '//dt
time = case_file%find(path='case/time')    ! a tag ID, 0 if there is none
print '(A,I0)', 'time  = tag ', time
print '(A)', 'steps = '//case_file%content(id=case_file%find(name='steps', parent=time))
print '(A)', 'name  = '//case_file%attribute(id=1, name='name')
