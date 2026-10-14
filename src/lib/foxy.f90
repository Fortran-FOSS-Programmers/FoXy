!< FoXy, Fortran XML parser for poor people
module foxy
!< FoXy, Fortran XML parser for poor people
use foxy_xml_entities, only : xml_escape, xml_unescape
use foxy_xml_file, only : xml_file, XML_MALFORMED
use foxy_xml_index, only : xml_index
use foxy_xml_tag, only : xml_tag
use foxy_xml_values, only : XML_BAD_VALUE, XML_NOT_FOUND
use foxy_xml_writer, only : xml_writer
use penf

implicit none
private
public :: I1P, I2P, I4P, I8P, R4P, R8P
public :: xml_escape
public :: xml_file
public :: xml_index
public :: xml_unescape
public :: XML_BAD_VALUE
public :: XML_MALFORMED
public :: XML_NOT_FOUND
public :: xml_tag
public :: xml_writer
endmodule foxy
