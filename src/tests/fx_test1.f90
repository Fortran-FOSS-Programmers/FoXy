program test_xml_parser
USE IR_Precision
USE Data_Type_XML_File, only: Type_XML_File

implicit none
character(len=:), allocatable :: string
character(len=:), allocatable :: parsed
type(Type_XML_File)           :: xml_file

print "(A)", 'Input XML data:'
string = '<first x="1" y="c" z="2">lorem ipsum...</first>'//new_line('a')//&
         '<second a1="2"/>'//new_line('a')//&
         '<third>bye</third>'//new_line('a')//&
         '<fourth a="3">bye bye Mrs. Robinson</fourth>'//new_line('a')//&
         '<fift>'//new_line('a')//&
         '  <nested level="1">I am supported! Nested tag at level 1</nested>'//new_line('a')//&
         '  <nested2 level="1">'//new_line('a')//&
         '    <nested3 level="2">Nested tag at level 2</nested3>'//new_line('a')//&
         '  </nested2>'//new_line('a')//&
         '</fift>'
print "(A)", string

print "(A)", 'Parsing file'
call xml_file%parse(string=string)
print "(A)", 'Parsed data'
parsed = xml_file%stringify()
print "(A)", parsed
print "(A,L1)", 'Is parsed data correct? ', trim(string)==trim(parsed)

call xml_file%tag_value(tag_name='first', tag_val=parsed)
if (allocated(parsed)) then
  print "(A)", 'Value of tag "first"'
  print "(A)", parsed
endif

call xml_file%tag_value(tag_name='third', tag_val=parsed)
if (allocated(parsed)) then
  print "(A)", 'Value of tag "third"'
  print "(A)", parsed
endif

call xml_file%tag_value(tag_name='fourth', tag_val=parsed)
if (allocated(parsed)) then
  print "(A)", 'Value of tag "fourth"'
  print "(A)", parsed
endif

call xml_file%tag_value(tag_name='nested', tag_val=parsed)
if (allocated(parsed)) then
  print "(A)", 'Value of tag "nested"'
  print "(A)", parsed
endif

call xml_file%tag_value(tag_name='nested2', tag_val=parsed)
if (allocated(parsed)) then
  print "(A)", 'Value of tag "nested2"'
  print "(A)", parsed
endif

call xml_file%tag_value(tag_name='nested3', tag_val=parsed)
if (allocated(parsed)) then
  print "(A)", 'Value of tag "nested3"'
  print "(A)", parsed
endif
stop
endprogram test_xml_parser
