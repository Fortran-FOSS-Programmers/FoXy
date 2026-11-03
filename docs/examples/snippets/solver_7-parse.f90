call stats%parse(filename='results.xml', iostat=iostat)        ! every snapshot, in one pass
print '(A,I0)', 'iostat = ', iostat
stats%last_step = 300
call stats%parse(filename='results.xml')                       ! up to the snapshot of step 300
