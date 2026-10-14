!< FoXy test.
program foxy_test_entities
!< FoXy test.
use foxy, only: xml_escape, xml_file, xml_unescape

implicit none
character(len=1), parameter   :: NL = new_line('a') !< New line.
character(len=:), allocatable :: source             !< String containing the source XML data.
type(xml_file)                :: xfile              !< XML file handler.
logical                       :: test_passed(15)    !< List of passed tests.

test_passed = .false.

! predefined references
test_passed(1) = xml_unescape('&lt;a&gt; &amp; &quot;b&quot; &apos;c&apos;')=='<a> & "b" ''c'''
! numeric references, decimal and hexadecimal, UTF-8 encoded
test_passed(2) = xml_unescape('&#65;&#x42;&#x43;')=='ABC'
test_passed(3) = xml_unescape('caf&#233;')=='caf'//char(195)//char(169)                ! U+00E9, 2 bytes
test_passed(4) = xml_unescape('&#x20AC;')==char(226)//char(130)//char(172)             ! U+20AC, 3 bytes
test_passed(5) = xml_unescape('&#x1F600;')==char(240)//char(159)//char(152)//char(128) ! U+1F600, 4 bytes
! single pass: a decoded "&" does not start a new reference
test_passed(6) = xml_unescape('&amp;lt;')=='&lt;'
! unknown, malformed or invalid (surrogate, null) references are left verbatim
test_passed(7) = xml_unescape('&nbsp; & x; &amp &#; &#xZ; &#xD800; &#0;')=='&nbsp; & x; &amp &#; &#xZ; &#xD800; &#0;'
test_passed(8) = xml_unescape('no references')=='no references'.and.xml_unescape('')==''
print "(A,L1)", 'Is unescaping correct? ', all(test_passed(1:8))

! escaping and round trip
test_passed(9) = xml_escape('a<b && "c"')=='a&lt;b &amp;&amp; &quot;c&quot;'
test_passed(10) = xml_unescape(xml_escape('<x a="1">&amp;</x>'))=='<x a="1">&amp;</x>'
test_passed(11) = xml_escape('plain')=='plain'
print "(A,L1)", 'Is escaping correct? ', all(test_passed(9:11))

! the accessors return decoded values, the stored data (stringify) keeps the source references
source = '<a k="x&amp;y">1 &lt; 2</a>'//NL//'<b>'//NL//'&#32;padded&#32;'//NL//'</b>'
print "(A)", 'Input XML data:'
print "(A)", source
call xfile%parse(string=source)
test_passed(12) = xfile%content('a')=='1 < 2'.and.xfile%content(id=xfile%find(name='a'))=='1 < 2'
test_passed(13) = xfile%attribute(id=xfile%find(name='a'), name='k')=='x&y'
test_passed(14) = xfile%content('b')==' padded ' ! layout blanks are stripped before decoding: encoded blanks are data
test_passed(15) = xfile%stringify()==source
print "(A,L1)", 'Are accessors decoding and stringify preserving? ', all(test_passed(12:15))

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_entities
