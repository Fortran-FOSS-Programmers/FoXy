!< FoXy test.
program foxy_test_add_tag_nested
!< FoXy test.
!<
!< A document built by *add_tag* with parents: layout, hierarchy queries (IDs in insertion order), the same document parsed
!< back, an invalid parent, a subtree deleted.
use foxy, only : I4P, xml_file, xml_tag

implicit none
character(len=1), parameter :: NL = new_line('a') !< New line.
character(*),     parameter :: EXPECTED =      &
   '<VTKFile k="v">'//NL//                     &
   '  <Piece n="1">'//NL//                     &
   '    <DataArray>1 2 3</DataArray>'//NL//    &
   '  </Piece>'//NL//                          &
   '  <Piece n="2">'//NL//                     &
   '    <Empty/>'//NL//                        &
   '  </Piece>'//NL//                          &
   '</VTKFile>'                                  !< Expected document.
character(*),     parameter :: DELETED =       &
   '<VTKFile k="v">'//NL//                     &
   '  <Piece n="2">'//NL//                     &
   '    <Empty/>'//NL//                        &
   '  </Piece>'//NL//                          &
   '</VTKFile>'                                  !< Expected document after deleting the first Piece.
type(xml_file)              :: built             !< Built document.
type(xml_file)              :: parsed            !< Parsed document.
integer(I4P)                :: root              !< Root tag ID.
integer(I4P)                :: piece(2)          !< Piece tags IDs.
integer(I4P)                :: data_array        !< DataArray tag ID.
integer(I4P)                :: empty             !< Empty tag ID.
integer(I4P)                :: invalid           !< ID of a tag with an invalid parent.
logical                     :: test_passed(5)    !< List of passed tests.

test_passed = .false.

call built%add_tag(tag=xml_tag(name='VTKFile', attribute=['k', 'v']), id=root)
call built%add_tag(tag=xml_tag(name='Piece', attribute=['n', '1']), parent=root, id=piece(1))
call built%add_tag(tag=xml_tag(name='Piece', attribute=['n', '2']), parent=root, id=piece(2))
call built%add_tag(tag=xml_tag(name='DataArray', content='1 2 3'), parent=piece(1), id=data_array) ! after piece(2)
call built%add_tag(tag=xml_tag(name='Empty', is_self_closing=.true.), parent=piece(2), id=empty)
test_passed(1) = built%stringify()==EXPECTED
if (.not.test_passed(1)) print "(A)", built%stringify()
print "(A,L1)", 'Is the built document laid out? ', test_passed(1)

test_passed(2) = root==1.and.all(piece==[2, 3]).and.data_array==4.and.empty==5.and.      &
                 all(built%children(root)==piece).and.all(built%children(piece(1))==[data_array]).and. &
                 built%parent(data_array)==piece(1).and.built%level(root)==1.and.built%level(data_array)==3.and. &
                 built%find(path='VTKFile/Piece/DataArray')==data_array.and.all(built%find_all(name='Piece')==piece).and. &
                 built%content(data_array)=='1 2 3'
print "(A,L1)", 'Are the hierarchy queries right (IDs in insertion order)? ', test_passed(2)

call parsed%parse(string=EXPECTED)
test_passed(3) = parsed%stringify()==built%stringify().and.parsed%find(path='VTKFile/Piece/DataArray')==3
print "(A,L1)", 'Is the built document the parsed one (IDs in document order)? ', test_passed(3)

call built%add_tag(tag=xml_tag(name='Lost'), parent=99_I4P, id=invalid)
test_passed(4) = invalid==0.and.built%find(name='Lost')==0.and.built%stringify()==EXPECTED
print "(A,L1)", 'Is a tag with an invalid parent not added? ', test_passed(4)

call built%delete_tag(name='Piece')
test_passed(5) = built%stringify()==DELETED.and.all(built%children(1)==[2]).and.built%find(name='Empty')==3.and. &
                 built%find(name='DataArray')==0
if (.not.test_passed(5)) print "(A)", built%stringify()
print "(A,L1)", 'Is a subtree of the built document deleted? ', test_passed(5)

print "(A,L1)", NL//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_add_tag_nested
