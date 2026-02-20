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

### Query tag content

```fortran
character(len=:), allocatable :: val

val = xfile%content('a')   ! returns 'hello'
```

### Linearised output (debug)

```fortran
print *, xfile%stringify(linearize=.true.)
! prints each tag's internal fields (name, attributes, level, id, parent_id, …)
```

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
