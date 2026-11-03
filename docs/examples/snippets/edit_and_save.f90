program edit_and_save
use foxy
implicit none
type(xml_file) :: doc
integer(I4P)   :: steps, iostat

call doc%parse(filename='case.xml')
steps = doc%find(path='case/time/steps')
call doc%set_content(id=steps, value=2000_I4P)
call doc%set_attribute(id=steps, name='edited', value='yes')
call doc%save(filename='case_edited.xml', iostat=iostat)
call doc%parse(filename='case_edited.xml')
print '(A)', 'steps = '//doc%content('steps')//', edited = '//doc%attribute(doc%find(name='steps'), 'edited')
endprogram edit_and_save
