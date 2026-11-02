call case_file%parse(filename='case.xml', iostat=iostat, iomsg=iomsg)
if (iostat/=0) then
   print '(A)', 'cannot read case.xml: '//trim(iomsg)
   stop 1
endif
