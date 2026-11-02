density = 1.0_R8P                                                           ! a default, kept on error
call case_file%get_content(id=case_file%find(path='case/fluid/densty'), value=density, iostat=iostat, iomsg=iomsg)
if (iostat==XML_NOT_FOUND) print '(A,F6.3)', 'not found, density kept: ', density
call case_file%get_attribute(id=case_file%find(name='density'), name='unit', value=steps, iostat=iostat, iomsg=iomsg)
if (iostat==XML_BAD_VALUE) print '(A)', trim(iomsg)
