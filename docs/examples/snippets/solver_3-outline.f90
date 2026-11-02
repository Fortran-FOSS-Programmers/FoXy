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
