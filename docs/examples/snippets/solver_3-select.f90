ids = case_file%select('case/boundary[@type="wall"]')           ! a path expression: the same in one call
print '(A,*(1X,A))', 'walls:', (case_file%attribute(ids(b), 'side'), b=1, size(ids))
