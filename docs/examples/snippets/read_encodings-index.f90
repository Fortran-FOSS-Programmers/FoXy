call idx%scan(filename='station-utf16.xml', iostat=iostat, iomsg=iomsg) ! the index reads the file bytes
print '(L1,1X,A)', iostat==XML_MALFORMED, trim(iomsg)
