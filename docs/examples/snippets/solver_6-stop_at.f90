call results%scan(filename='results.xml', stop_at='pressure')   ! stop after the first <pressure ...>
print '(A,I0,A,I0)', 'stopped at byte ', results%stop_position(), ', tags indexed: ', results%tags_number()
