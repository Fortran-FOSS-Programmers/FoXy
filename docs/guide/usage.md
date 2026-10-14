---
title: Usage
---

# Usage

Always import from the `foxy` wrapper module, which re-exports `xml_tag`, `xml_file`, and the PENF kind parameters.

```fortran
use foxy, only: xml_tag, xml_file
```

---

## Creating Tags

Tags are created with the `xml_tag` constructor function (an overloaded interface).

### Simple tag with content

```fortran
use foxy, only: xml_tag
type(xml_tag) :: tag

tag = xml_tag(name='velocity', content='1.5')
print *, tag%stringify()
! → <velocity>1.5</velocity>
```

### Tag with attributes

```fortran
tag = xml_tag(name='point', &
              attributes=reshape([['x', '1'], ['y', '2'], ['z', '3']], [2,3]))
print *, tag%stringify()
! → <point x="1" y="2" z="3"/>
```

### Tag with content and attributes

```fortran
tag = xml_tag(name='first', &
              content='lorem ipsum...', &
              attributes=reshape([['x', '1'], ['y', 'c'], ['z', '2']], [2,3]))
print *, tag%stringify()
! → <first x="1" y="c" z="2">lorem ipsum...</first>
```

### Self-closing tag

```fortran
tag = xml_tag(name='empty', &
              attributes=reshape([['id', '42']], [2,1]), &
              is_self_closing=.true.)
print *, tag%stringify()
! → <empty id="42"/>
```

### Nested tag as content

```fortran
type(xml_tag) :: inner, outer

inner = xml_tag(name='child', content='value')
outer = xml_tag(name='parent', content=inner)
print *, outer%stringify()
! → <parent><child>value</child></parent>
```

### Parsing a tag from a string

```fortran
call tag%parse(source='<speed unit="m/s">42.0</speed>')
print *, tag%name()           ! → speed
print *, tag%stringify()      ! → <speed unit="m/s">42.0</speed>
```

---

## Modifying Tags

### Adding attributes

```fortran
call tag%add_attributes(attribute=['color', 'red'])
```

### Deleting attributes

```fortran
call tag%delete_attributes(name='color')
```

### Deleting content

```fortran
call tag%delete_content()
```

### Checking attribute presence

```fortran
if (tag%is_attribute_present('unit')) then
  ! ...
endif
```

---

## Writing Documents (streaming)

`xml_writer` writes a document element by element, keeping the stack of the open elements, escaping text and attribute
values and laying the document out; nothing is kept in memory but the open elements (a file can be any size).

```fortran
use foxy, only: I4P, xml_writer
type(xml_writer) :: w
integer(I4P)     :: iostat

call w%open(filename='mesh.vtu', iostat=iostat)   ! or open(unit=u), or open() for memory (w%string())
call w%declaration()
call w%start('VTKFile')
call w%attribute('type', 'UnstructuredGrid')
call w%start('Piece')
call w%attribute('NumberOfPoints', 27_I4P)
call w%start('DataArray')
call w%attribute('format', 'ascii')
call w%raw('0.0 1.0 2.0', is_block=.true.)       ! data on its own line, may be written in many pieces
call w%end('DataArray')
call w%start('Empty')
call w%end()                                       ! no content: <Empty/>
call w%close(iostat=iostat)                        ! closes Piece and VTKFile, reports the first error
```

```xml
<?xml version="1.0"?>
<VTKFile type="UnstructuredGrid">
  <Piece NumberOfPoints="27">
    <DataArray format="ascii">
      0.0 1.0 2.0
    </DataArray>
    <Empty/>
  </Piece>
</VTKFile>
```

An element holding text (`w%text`) is written inline (`<a>text</a>`); `open(..., indent=0)` writes compact output.

---

## Writing Tags to File

Use `tag%write()` to emit XML directly to a file unit without building an intermediate string.

```fortran
use foxy, only: xml_tag, xml_file
type(xml_tag)  :: tag
type(xml_file) :: xfile
integer        :: unit

tag = xml_tag(name='result', content='3.14', &
              attributes=reshape([['precision', 'double']], [2,1]))

! Write atomically (unformatted stream)
open(newunit=unit, file='output.xml', access='STREAM', form='UNFORMATTED', status='REPLACE')
call tag%write(unit=unit, form='unformatted')
close(unit)

! Write with indentation and line endings
open(newunit=unit, file='output.xml', access='STREAM', form='UNFORMATTED', status='REPLACE')
call tag%write(unit=unit, form='unformatted', is_indented=.true., is_content_indented=.true.)
close(unit)

! Write start / content / end separately
open(newunit=unit, file='output.xml', access='STREAM', form='UNFORMATTED', status='REPLACE')
call tag%write(unit=unit, form='unformatted', only_start=.true.,   end_record=new_line('a'))
call tag%write(unit=unit, form='unformatted', only_content=.true., end_record=new_line('a'), is_content_indented=.true.)
call tag%write(unit=unit, form='unformatted', only_end=.true.)
close(unit)
```

---

## Parsing XML Files and Strings

`xml_file` holds the parsed DOM as a flat array of `xml_tag` records with parent/child ID links.

### Parse from string

```fortran
use foxy, only: xml_file
type(xml_file)                :: xfile
character(len=:), allocatable :: output

call xfile%parse(string= &
  '<root>'//new_line('a')// &
  '  <a x="1">hello</a>'//new_line('a')// &
  '  <b/>'//new_line('a')// &
  '</root>')

output = xfile%stringify()
print *, output
```

### Parse from file

```fortran
call xfile%parse(filename='data.xml')
output = xfile%stringify()
```

The prolog (XML declaration, DOCTYPE, comments and processing instructions before the root tag) is kept verbatim and
written back first by `stringify()`. Comments and processing instructions inside the document are kept too (a tag
holding one is written inline, as parsed), while `content()` skips them.

### Errors

Parsing is tolerant: malformed input is parsed as far as possible. Pass `iostat`/`iomsg` to know whether it was valid:

```fortran
use foxy, only: I4P, XML_MALFORMED, xml_file
integer(I4P)       :: iostat
character(len=256) :: iomsg

call xfile%parse(filename='data.xml', iostat=iostat, iomsg=iomsg)
if (iostat==XML_MALFORMED) then
  print *, trim(iomsg)   ! first problem, e.g. 'line 2: end tag </a> closes open tag <b>'
elseif (iostat/=0) then
  print *, trim(iomsg)   ! the file cannot be read
endif
```

Without `iostat`/`iomsg`, errors are not reported.

### Attribute values spaces

By default the leading and trailing spaces of attribute values are trimmed when parsing (`k=" 1.5 "` reads and is written
back as `k="1.5"`). XML considers them data: keep them with

```fortran
call xfile%parse(filename='data.xml', sanitize_attributes_value=.false.)
```

### Query tag content

```fortran
character(len=:), allocatable :: val

val = xfile%content('a')   ! returns 'hello'
```

`content(name)` returns the content of the **first** tag named `name` anywhere in the document. When the same name
appears under different parents, look tags up by path or parent and read them by ID.

### Typed values: numbers and logicals

Attributes and contents are read as numbers or logicals with `get_attribute` and `get_content`, scalars or blank
separated lists; a missing tag or attribute and a malformed value are reported by `iostat`:

```fortran
use foxy, only: I4P, R8P, xml_file, XML_NOT_FOUND
integer(I4P)              :: id, n, iostat
integer(I4P), allocatable :: extent(:)
real(R8P),    allocatable :: points(:)
logical                   :: is_on
character(len=256)        :: iomsg

! <Piece NumberOfPoints="27" Extent="0 2 0 2 0 2"> <DataArray format="ascii">0 0 0 1 0 0 ...</DataArray>
id = xfile%find(name='Piece')
call xfile%get_attribute(id=id, name='NumberOfPoints', value=n, iostat=iostat, iomsg=iomsg)
call xfile%get_attribute(id=id, name='Extent', values=extent)           ! [0, 2, 0, 2, 0, 2]
call xfile%get_content(id=xfile%find(path='Piece/Points/DataArray'), values=points)
is_on = .false.                                                         ! default, kept if missing or malformed
call xfile%get_attribute(id=id, name='Active', value=is_on, iostat=iostat)
if (iostat==XML_NOT_FOUND) print *, 'Active not set'
```

Integers accept digits and signs only, reals also `.`, exponents and `NaN`/`Inf`; separators such as `,` and repeat
counts (`2*5`) are rejected. Logicals are `true`, `false`, `1`, `0`.

### Find tags by path, parent, or name

Tags are identified by an integer ID (their index in the document, `0` meaning the document root):

```fortran
use penf, only : I4P
integer(I4P), allocatable :: ids(:)
integer(I4P)              :: id

! <origin><latitude><value>36.5</value></latitude></origin>
! <magnitude publicID="m1"><mag><value>1.5</value></mag></magnitude>
id  = xfile%find(path='origin/latitude/value')    ! first segment at any depth, the others direct children
val = xfile%content(id=id)                        ! '36.5'

id  = xfile%find(name='magnitude')                ! first tag named 'magnitude', 0 if none
val = xfile%attribute(id=id, name='publicID')     ! 'm1', '' if not defined
ids = xfile%find_all(name='value')                ! all matches, in document order
ids = xfile%find_all(name='mag', parent=id)       ! only direct children of tag `id`
ids = xfile%children(id)                          ! direct children IDs; children(0) are the root tags
val = xfile%name(id)                              ! 'magnitude'; xfile%parent(id), xfile%level(id) (1: root tag)
```

When a path segment matches several tags (e.g. many `origin` tags), all of them are explored, so
`find_all(path='origin/latitude/value')` returns the latitudes of every origin.

### Text values: references, CDATA and mixed content

`content()` and `attribute()` return **values**: layout blanks stripped, character references decoded, CDATA sections
literal. The stored data keeps the source text, so `stringify()` writes it back unchanged.

```fortran
call xfile%parse(string='<a k="x&amp;y">1 &lt; 2</a><b><![CDATA[1 < 2 && 3 > 2]]></b>')
val = xfile%content('a')                                  ! '1 < 2'
val = xfile%attribute(id=xfile%find(name='a'), name='k')  ! 'x&y'
val = xfile%content('b')                                  ! '1 < 2 && 3 > 2'

! mixed content: the text of a tag is the text around its children, children text excluded
call xfile%parse(string='<p>see <b>this</b> now</p>')
val = xfile%content('p')                                  ! 'see  now'
val = xfile%content('b')                                  ! 'this'
output = xfile%stringify()                                ! '<p>see <b>this</b> now</p>': written inline
```

A tag with mixed content is written inline, exactly as parsed; every other tag is formatted with one tag per line.

Content set programmatically may contain markup (e.g. a nested tag), so it is **not** escaped on output: escape user
data with `xml_escape` before setting it.

```fortran
use foxy, only: xml_escape, xml_tag
type(xml_tag) :: a_tag

a_tag = xml_tag(name='note', content=xml_escape('a < b & c'))  ! <note>a &lt; b &amp; c</note>
```

### Linearised output (debug)

```fortran
print *, xfile%stringify(linearize=.true.)
! prints each tag's internal fields (name, attributes, level, id, parent_id, …)
```

### Large files: the index

`xml_index` scans a file and keeps only its tags (names, attributes, hierarchy, positions), reading the content of a
tag from the file only when asked: the memory used does not depend on the data in the file. The queries are the same as
`xml_file`.

```fortran
use foxy, only: I4P, I8P, xml_index
type(xml_index) :: idx
integer(I4P)    :: id
integer(I8P)    :: first, last

call idx%scan(filename='mesh.vtu', stop_at='AppendedData', iostat=iostat, iomsg=iomsg)
id = idx%find(path='Piece/Points/DataArray')
print *, idx%attribute(id=id, name='type')    ! e.g. 'Float64'
val = idx%content(id=id)                      ! the data, read now from the file
call idx%get_content(id=id, values=points)    ! or as numbers (see typed values)
call idx%text_range(id=id, first=first, last=last) ! or their byte range, to read them yourself
print *, idx%stop_position()                  ! first byte after <AppendedData ...>: the raw data follow
```

`stop_at` ends the scan after the start tag of the first tag with that name: the raw binary data that VTK files append
after `<AppendedData encoding="raw">` are never read as XML.

---

## Building a DOM Programmatically

```fortran
use foxy, only: xml_tag, xml_file
type(xml_tag)  :: tag
type(xml_file) :: xfile

call xfile%add_tag(xml_tag(name='config'))
call xfile%add_tag(xml_tag(name='dt',    content='0.01'))
call xfile%add_tag(xml_tag(name='nstep', content='1000'))

print *, xfile%stringify()
```

### Saving to a file

```fortran
call xfile%save(filename='config.xml', is_declared=.true., iostat=iostat, iomsg=iomsg)
```

`save` writes the prolog, the tags as `stringify()` and a final new line. With `is_declared=.true.` it writes
`<?xml version="1.0"?>` first, unless the prolog already starts with a declaration. Without `iostat`, an I/O error
stops the program.

### Deleting a tag by name

```fortran
call xfile%delete_tag(name='nstep')
```

### Freeing memory

```fortran
call xfile%free()   ! resets DOM
call tag%free()     ! resets a single tag
```

---

## Indentation

Both `xml_tag` and `xml_file` support automatic indentation. Set `indent` (number of leading spaces) and `is_content_indented` when creating or writing tags:

```fortran
tag = xml_tag(name='value', content='42', indent=4, is_content_indented=.true.)
print *, tag%stringify(is_indented=.true., is_content_indented=.true.)
! →     <value>
! →       42
! →     </value>
```

When parsing, `xml_file` automatically computes `indent = (level - 1) * 2`.
