call results%scan(filename='results.xml', iostat=iostat)   ! tags and attributes only, no content
snapshots = results%find_all(path='results/snapshot')
print '(A,I0,A,I0,A)', 'indexed ', results%tags_number(), ' tags, ', size(snapshots), ' snapshots'
