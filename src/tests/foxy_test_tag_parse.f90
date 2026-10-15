!< FoXy test.
program foxy_test_tag_parse
!< FoXy test.
!<
!< Single tag parsing (*xml_tag%parse*, *get_content* of nested tags, attributes streams) by the document tokenizer: the
!< cases the former parser got wrong, and the agreement with the index on every tag of a document.
use foxy, only : I4P, I8P, xml_index, xml_tag

implicit none
character(len=1), parameter   :: NL = new_line('a')            !< New line.
character(*),     parameter   :: QUAKEML = 'src/tests/data/quakeml_ci38457511.xml' !< Test document.
type(xml_tag)                 :: tag                           !< XML tag.
type(xml_index)               :: xindex                        !< XML index.
character(len=:), allocatable :: source                        !< Source.
character(len=:), allocatable :: content                       !< Content.
integer(I8P)                  :: tstart                        !< Starting index of the tag.
integer(I8P)                  :: tend                          !< Ending index of the tag.
integer(I8P)                  :: pos(3)                        !< Tag positions.
integer(I8P)                  :: first                         !< First position of a content.
integer(I8P)                  :: last                          !< Last position of a content.
integer(I8P)                  :: p                             !< Position.
integer(I8P)                  :: e                             !< Relative position.
integer(I8P)                  :: clock(3)                      !< Clock counts (start, end) and rate.
integer(I4P)                  :: id                            !< Tag ID.
integer(I4P)                  :: mismatches                    !< Number of tags not agreeing with the index.
integer(I4P)                  :: copies=100000_I4P             !< Number of tags before the target one (a variable:
                                                               !< a constant repeat is folded by nvfortran, which fails).
integer                       :: unit                          !< File unit.
integer                       :: file_size                     !< File size.
logical                       :: test_passed(12)               !< List of passed tests.

test_passed = .false.

! attribute values with `>`, `<`, `=`, the other quote kind, blanks around `=`
call tag%parse(source='<a x="1>2" y='//"'q"//'"q'//"'"//' z = "p=q" w="a<b">c</a>')
test_passed(1) = tag%name()=='a'.and.tag%get_attribute('x')=='1>2'.and.tag%get_attribute('y')=='q"q'.and. &
                 tag%get_attribute('z')=='p=q'.and.tag%get_attribute('w')=='a<b'
call tag%get_content(name='a', content=content)
test_passed(1) = test_passed(1).and.content=='c'
print "(A,L1)", 'Are attribute values with markup characters and quotes parsed? ', test_passed(1)

! an attribute name ending another one
call tag%parse(source='<a ba="1" a="2"/>')
test_passed(2) = tag%get_attribute('a')=='2'.and.tag%get_attribute('ba')=='1'.and.tag%stringify()=='<a ba="1" a="2"/>'
print "(A,L1)", 'Is an attribute name ending another one parsed? ', test_passed(2)

! nested tags with the same name, one character content
call tag%parse(source='<a><a>i</a>t</a>')
call tag%get_content(name='a', content=content)
test_passed(3) = content=='<a>i</a>t'
call tag%parse(source='<b>x</b>')
call tag%get_content(name='b', content=content)
test_passed(3) = test_passed(3).and.content=='x'.and.tag%stringify()=='<b>x</b>'
print "(A,L1)", 'Are nested same name tags and one character contents parsed? ', test_passed(3)

! unclosed tag: content up to the source end
source = '<a k="v">text'
call tag%parse(source=source, tstart=tstart, tend=tend)
call tag%get_content(name='a', content=content)
pos = tag%get_pos()
test_passed(4) = content=='text'.and.pos(3)==0.and.tstart==1.and.tend==len(source)
print "(A,L1)", 'Is an unclosed tag parsed? ', test_passed(4)

! end tag before the first start tag, positions, no tag
call tag%parse(source='</z><b>1</b>', tstart=tstart, tend=tend)
test_passed(5) = tag%name()=='b'.and.tstart==5.and.tend==12
call tag%parse(source='xx<a/>yy', tstart=tstart, tend=tend)
pos = tag%get_pos()
test_passed(5) = test_passed(5).and.tag%name()=='a'.and.tstart==3.and.tend==6.and.all(pos==[3_I8P, 6_I8P, -1_I8P])
call tag%parse(source='plain text', tstart=tstart, tend=tend)
test_passed(5) = test_passed(5).and.(.not.tag%is_parsed()).and.tstart==0.and.tend==0
print "(A,L1)", 'Are positions right (end tag first, self closing, no tag)? ', test_passed(5)

! nested tag set as content: tags in comments and CDATA ignored, missing tag
tag = xml_tag(name='p', content='<!-- <b>no</b> --><![CDATA[<b>no</b>]]><b k="1">yes</b>')
call tag%get_content(name='b', content=content)
test_passed(6) = content=='yes'
call tag%get_content(name='c', content=content)
test_passed(6) = test_passed(6).and.(.not.allocated(content))
print "(A,L1)", 'Is a nested tag found, ignoring comments and CDATA? ', test_passed(6)

! attributes streams: quotes, markup characters, update, sanitize
tag = xml_tag(name='s', attributes_stream="x = '1' y=""a > b"" z=""p=q""")
test_passed(7) = tag%get_attribute('x')=='1'.and.tag%get_attribute('y')=='a > b'.and.tag%get_attribute('z')=='p=q'
call tag%add_attributes(attributes_stream='x="2" w=" s "', sanitize_values=.true.)
test_passed(7) = test_passed(7).and.tag%get_attribute('x')=='2'.and.tag%get_attribute('w')=='s'.and. &
                 tag%stringify()=='<s x="2" y="a > b" z="p=q" w="s"></s>'
call tag%add_attributes(attributes_stream='abc="1"')
test_passed(7) = test_passed(7).and.index(tag%stringify(), ' abc="1">')>0 ! value not padded to the name length
print "(A,L1)", 'Are attributes streams parsed? ', test_passed(7)
if (.not.test_passed(7)) print "(A)", tag%stringify()

! a nested tag at the end of a large content: found in linear time
tag = xml_tag(name='big', content=repeat('<x a="1">1</x>', copies)//'<target>v</target>')
call system_clock(clock(1), clock(3))
call tag%get_content(name='target', content=content)
call system_clock(clock(2))
test_passed(8) = content=='v'
print "(A,F7.3,A)", 'Nested tag after 100000 tags found in ', real(clock(2) - clock(1)) / real(clock(3)), ' s'
print "(A,L1)", 'Is a nested tag found in a large content? ', test_passed(8)

! every tag of a document parsed alone agrees with the index (name, content positions)
source = file_content(QUAKEML)
call xindex%scan(filename=QUAKEML)
id = 0
mismatches = 0
p = 1
do while (p<len(source, kind=I8P))
   e = index(source(p:), '<', kind=I8P)
   if (e==0) exit
   p = p + e - 1
   if (source(p:min(len(source, kind=I8P), p+3))=='<!--') then
      p = p + index(source(p:), '-->', kind=I8P) + 2
   elseif (source(p:min(len(source, kind=I8P), p+8))=='<![CDATA[') then
      p = p + index(source(p:), ']]>', kind=I8P) + 2
   elseif (source(p+1:p+1)=='?'.or.source(p+1:p+1)=='!'.or.source(p+1:p+1)=='/') then
      p = p + index(source(p:), '>', kind=I8P)
   else
      id = id + 1
      call tag%parse(source=source(p:))
      pos = tag%get_pos() + p - 1
      call xindex%content_range(id=id, first=first, last=last)
      if (tag%name()/=xindex%name(id)) then
         mismatches = mismatches + 1
      elseif (pos(3)==p-2) then ! self closing: pos(3) was -1
         if (last>=first) mismatches = mismatches + 1
      elseif (pos(2)/=first-1.or.pos(3)/=last+1) then
         mismatches = mismatches + 1
      endif
      p = p + 1
   endif
enddo
test_passed(9) = mismatches==0.and.id>100
print "(A,I0,A,I0)", 'Tags of the document parsed alone: ', id, ', not agreeing with the index: ', mismatches
print "(A,L1)", 'Does every tag parsed alone agree with the index? ', test_passed(9)

! stringify round trip of parsed tags
source = '<v a="1" b="x y">some <i>nested</i> text</v>'
call tag%parse(source=source)
test_passed(10) = tag%stringify()==source
source = '<e x="1"/>'
call tag%parse(source=source)
test_passed(11) = tag%stringify()==source
source = '<q a=''say "hi"''>t</q>'
call tag%parse(source=source)
test_passed(12) = tag%stringify()=='<q a="say &quot;hi&quot;">t</q>'.and.tag%get_attribute('a')=='say "hi"'
print "(A,L1)", 'Are parsed tags written back? ', all(test_passed(10:12))

print "(A,L1)", NL//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   function file_content(filename) result(content)
   !< Return the whole content of a file.
   character(*), intent(in)      :: filename !< File name.
   character(len=:), allocatable :: content  !< File content.

   open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='OLD')
   inquire(unit=unit, size=file_size)
   allocate(character(len=file_size) :: content)
   if (file_size>0) read(unit) content
   close(unit)
   endfunction file_content
endprogram foxy_test_tag_parse
