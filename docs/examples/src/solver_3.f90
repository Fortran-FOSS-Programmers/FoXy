program solver
!< Tutorial, chapter 3: walking the tree.
use foxy
implicit none
type(xml_file)            :: case_file
integer(I4P), allocatable :: ids(:)
integer(I4P)              :: b

call case_file%parse(filename='case.xml')
print '(A,I0,A)', 'case.xml has ', case_file%tags_number(), ' tags'
call outline(id=1, depth=0)
!region find_all
ids = case_file%find_all(path='case/boundary')       ! every match, in document order
do b=1, size(ids)
   print '(A)', 'boundary '//case_file%attribute(ids(b), 'side')//': '//case_file%attribute(ids(b), 'type')
enddo
!endregion find_all
contains
   !region outline
   recursive subroutine outline(id, depth)
   !< Print a tag, its attributes and, indented, its children.
   integer(I4P), intent(in)      :: id, depth
   character(len=:), allocatable :: line
   integer(I4P), allocatable     :: kids(:)
   integer(I4P)                  :: a, k

   line = repeat('  ', depth)//case_file%name(id)
   do a=1, case_file%attributes_number(id)            ! the attributes, without knowing their names
      line = line//' '//case_file%attribute_name(id, a)//'='//case_file%attribute(id, case_file%attribute_name(id, a))
   enddo
   if (len(case_file%content(id=id))>0) line = line//': '//case_file%content(id=id)
   print '(A)', line
   kids = case_file%children(id)
   do k=1, size(kids)
      call outline(id=kids(k), depth=depth+1)
   enddo
   endsubroutine outline
   !endregion outline
endprogram solver
!as solver
!run solver_3 solver
