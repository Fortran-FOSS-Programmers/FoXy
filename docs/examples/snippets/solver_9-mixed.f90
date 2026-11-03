call case_file%parse(string='<p>the <b>lid</b> moves at <v>1</v> m/s</p>')
print '(A)', 'mixed:  '//case_file%content('p')                     ! the direct text of p, children excluded
print '(A)', case_file%stringify()                                   ! written back as it was
