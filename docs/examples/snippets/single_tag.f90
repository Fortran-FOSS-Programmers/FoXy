program single_tag
use foxy
implicit none
type(xml_tag)                 :: tag
character(len=:), allocatable :: value

call tag%parse(source='junk <grid ni="64" nj="32"/> more')     ! the first tag of a string
print '(A)', tag%name()//': ni='//tag%get_attribute('ni')//', '//tag%stringify()
tag = xml_tag(name='dt', content='1e-3', attributes_stream='unit="s"')
call tag%add_attributes(attributes_stream='min="0" max="1"')
call tag%delete_attributes(name='min')
print '(A)', tag%stringify()
call tag%get_content(name='dt', content=value)
print '(A)', 'content: '//value
endprogram single_tag
