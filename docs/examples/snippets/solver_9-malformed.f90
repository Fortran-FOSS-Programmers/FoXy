call case_file%parse(filename='broken.xml', iostat=iostat, iomsg=iomsg)
if (iostat==XML_MALFORMED) print '(A)', 'broken.xml: '//trim(iomsg)
print '(A)', 'dt is still read: '//case_file%content('dt')          ! tolerant: the document is built anyway
