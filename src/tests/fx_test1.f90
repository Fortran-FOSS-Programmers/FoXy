program test_xml_parser
USE IR_Precision
USE Data_Type_XML_Tag, only: Type_XML_Tag
USE Lib_IO_Misc
USE Lib_XML_Parser

implicit none
character(len=:), allocatable:: stream
type(Type_XML_tag):: tag
integer(I4P):: tend

call read_file_as_stream(filename='test.xml',stream=stream)
tag%tag_name = 'third'
call tag%search(string=stream)
print*,tag%tag_val
stop

call tag%parse(string=stream,tend=tend)
print*,tag%tag_name
print*,tag%tag_val
print*,tag%att_val(1)
print*,tag%att_val(2)
print*,tag%att_val(3)
stream = stream(tend+1:)
call tag%parse(string=stream,tend=tend)
print*,tag%tag_name
print*,tag%att_val(1)
stream = stream(tend+1:)
call tag%parse(string=stream,tend=tend)
print*,tag%tag_name
print*,tag%tag_val
stream = stream(tend+1:)
call tag%parse(string=stream,tend=tend)
stream = stream(tend+1:)
call tag%parse(string=stream,tend=tend)
print*,tag%tag_name
print*,tag%tag_val
stop
endprogram test_xml_parser
