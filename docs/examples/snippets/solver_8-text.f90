call case_file%parse(filename='case.xml')
print '(A)', 'notes:  '//case_file%content('notes')                  ! references decoded, CDATA literal
print '(A)', 'escape: '//xml_escape('a < b & "c"')
print '(A)', 'raw:    '//xml_unescape('1 &lt; 2 &#x26; &#233;t&#233;')
