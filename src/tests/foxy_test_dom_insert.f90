!< FoXy test.
program foxy_test_dom_insert
!< FoXy test.
!<
!< Inserting a tag before or after a sibling (the following IDs renumbered, document order and children lists kept, the
!< document written and parsed back the same), renaming a tag; bad IDs and names reported.
use foxy, only : I4P, xml_file, xml_tag, XML_MALFORMED, XML_NOT_FOUND

implicit none
character(len=1), parameter :: NL = new_line('a') !< New line.
type(xml_file)              :: doc                !< Document.
type(xml_file)              :: back               !< Document parsed back.
integer(I4P)                :: id                 !< ID of an added tag.
integer(I4P)                :: iostat             !< IO status.
character(len=128)          :: iomsg              !< IO message.
logical                     :: test_passed(6)     !< List of passed tests.

test_passed = .false.

! before: it takes the place of the sibling, the following tags move by one
call doc%parse(string='<r><a><x/></a><b/></r>')                     ! r1 a2 x3 b4
call doc%add_tag(xml_tag(name='n', content='1'), before=doc%find(name='b'), id=id)
test_passed(1) = id==4.and.doc%name(4)=='n'.and.doc%name(5)=='b'.and.doc%parent(4)==1.and.doc%parent(5)==1.and. &
                 all(doc%children(1)==[2, 4, 5]).and.doc%level(4)==2.and. &
                 doc%stringify()=='<r>'//NL//'  <a>'//NL//'    <x/>'//NL//'  </a>'//NL//'  <n>1</n>'//NL//'  <b/>'//NL//'</r>'
print "(A,L1)", 'Is a tag inserted before a sibling? ', test_passed(1)

! after: after the sibling and its whole subtree
call doc%add_tag(xml_tag(name='m'), after=doc%find(name='a'), id=id)
test_passed(2) = id==4.and.doc%name(3)=='x'.and.doc%name(4)=='m'.and.all(doc%children(1)==[2, 4, 5, 6]).and. &
                 all(doc%find_all(name='n')==[5]).and.doc%parent(3)==2
print "(A,L1)", 'Is a tag inserted after a sibling subtree? ', test_passed(2)

! the document order is kept: written and parsed back, the same tags in the same order
call back%parse(string=doc%stringify(), iostat=iostat)
test_passed(3) = iostat==0.and.back%tags_number()==doc%tags_number().and.back%stringify()==doc%stringify()
do id=1, doc%tags_number() ! a loop, not an implied-do mask (nvfortran)
   test_passed(3) = test_passed(3).and.back%name(id)==doc%name(id)
enddo
call doc%delete_tag(name='a')                                        ! the invariants delete_tag needs still hold
test_passed(3) = test_passed(3).and.doc%tags_number()==4.and.doc%find(name='x')==0.and.all(doc%children(1)==[2, 3, 4])
print "(A,L1)", 'Is the document order kept? ', test_passed(3)

! insertion among the root tags, and into a built document
call doc%free()
call doc%add_tag(xml_tag(name='first'), id=id)
call doc%add_tag(xml_tag(name='last'))
call doc%add_tag(xml_tag(name='middle'), before=2_I4P, id=id)
test_passed(4) = id==2.and.doc%name(1)=='first'.and.doc%name(2)=='middle'.and.doc%name(3)=='last'.and.doc%level(2)==1
print "(A,L1)", 'Is a root tag inserted? ', test_passed(4)

! rename
call doc%parse(string='<r><old k="1">t</old></r>')
call doc%set_name(id=2_I4P, name='new', iostat=iostat)
test_passed(5) = iostat==0.and.doc%stringify()=='<r>'//NL//'  <new k="1">t</new>'//NL//'</r>'.and.doc%find(name='new')==2
print "(A,L1)", 'Is a tag renamed? ', test_passed(5)

! errors: nothing added or changed
call doc%add_tag(xml_tag(name='z'), before=99_I4P, id=id)
test_passed(6) = id==0
call doc%add_tag(xml_tag(name='z'), before=2_I4P, after=2_I4P, id=id)
test_passed(6) = test_passed(6).and.id==0
call doc%add_tag(xml_tag(name='z'), parent=2_I4P, before=1_I4P, id=id)  ! 1 is not a child of 2
test_passed(6) = test_passed(6).and.id==0.and.doc%tags_number()==2
call doc%set_name(id=99_I4P, name='x', iostat=iostat)
test_passed(6) = test_passed(6).and.iostat==XML_NOT_FOUND
call doc%set_name(id=2_I4P, name='1bad', iostat=iostat, iomsg=iomsg)
test_passed(6) = test_passed(6).and.iostat==XML_MALFORMED.and.index(iomsg, '1bad')>0.and.doc%name(2)=='new'
print "(A,L1)", 'Are bad IDs and names reported? ', test_passed(6)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_dom_insert
