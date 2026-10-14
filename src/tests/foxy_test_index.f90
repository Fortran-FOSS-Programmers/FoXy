!< FoXy test.
program foxy_test_index
!< FoXy test.
!<
!< The index of a file (tags without content, read on demand) agrees with the DOM of the same file, with any chunk size;
!< VTK files with raw appended data are scanned up to `AppendedData`.
use foxy, only: I4P, I8P, xml_file, xml_index

implicit none
type :: document
   character(len=:), allocatable :: source !< Source.
endtype document
character(len=1), parameter   :: NL = new_line('a') !< New line.
character(len=*), parameter   :: VTK_DIR = 'src/tests/data/vtk/' !< VTK reference files directory.
character(len=*), parameter   :: ATTRIBUTES(*) = [character(len=18) :: 'k', 'j', 'x', 'a', 'type', 'version',          &
                                 'byte_order', 'header_type', 'compressor', 'Name', 'NumberOfComponents', 'format',      &
                                 'offset', 'encoding', 'NumberOfPoints', 'NumberOfCells', 'WholeExtent', 'Extent',        &
                                 'RangeMin', 'RangeMax', 'publicID', 'catalog:eventid'] !< Attributes names compared.
type(document), allocatable   :: documents(:)        !< Documents.
character(len=:), allocatable :: tmp_dir             !< Temporary directory.
character(len=:), allocatable :: filename            !< File name.
character(len=:), allocatable :: chars               !< Characters read from a file.
type(xml_file)                :: dom                 !< DOM of a file.
type(xml_index)               :: idx                 !< Index of a file.
integer(I4P)                  :: iostat_dom          !< IO status, DOM.
integer(I4P)                  :: iostat_idx          !< IO status, index.
character(len=256)            :: iomsg_dom           !< IO message, DOM.
character(len=256)            :: iomsg_idx           !< IO message, index.
integer(I8P)                  :: first               !< First position of a range.
integer(I8P)                  :: last                !< Last position of a range.
integer(I4P)                  :: id                  !< Tag ID.
integer                       :: unit                !< File unit.
integer                       :: tmp_dir_len         !< Length of the TMPDIR environment variable.
integer                       :: status              !< Status of the environment variable query.
integer                       :: d                   !< Counter.
integer                       :: c                   !< Counter.
logical                       :: is_same             !< Same results.
logical                       :: test_passed(9)      !< List of passed tests.

test_passed = .false.

call get_environment_variable('TMPDIR', length=tmp_dir_len, status=status)
if (status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
else
   tmp_dir = '/tmp'
endif
filename = tmp_dir//'/foxy_test_index.xml'

! well formed documents: same tags, attributes and content of the DOM, with any chunk size
allocate(documents(6))
documents(1)%source = '<?xml version="1.0" encoding="UTF-8"?>'//NL//'<!DOCTYPE a [ <!ENTITY e "x>y"> ]>'//NL// &
                      '<!-- head -->'//NL//'<a k="1>0" j=''2"3''>'//NL//'  <b/>'//NL//'  <c x="&amp;">t &lt; u</c>'//NL// &
                      '</a>'//NL//'<!-- tail -->'
documents(2)%source = '<p>see <b>this</b> and <i>that</i><!-- c --> now<?pi x?></p>'
documents(3)%source = '<a><![CDATA[x ]] ]> <b>y</b> ]]]]><b>z</b></a>'
documents(4)%source = '<a><!-- - -- ->-->1<?p ? >?>2<![CDATA[]]>3</a>'
documents(5)%source = '<r>'//repeat('<v k="1" j=''x''>value</v><e/>'//NL, 40)//'</r>'
documents(6)%source = '<a     k  =  "1"'//NL//'  j="2"   >'//NL//'<b>1</b>t1<b>2</b>  t2  </a>'//NL//'<z/>'
is_same = .true.
do d=1, size(documents, dim=1)
   call write_file(filename, documents(d)%source)
   is_same = is_index_as_dom(filename, [1_I8P, 2_I8P, 7_I8P, 65536_I8P]).and.is_same
enddo
test_passed(1) = is_same
print "(A,L1)", 'Does the index agree with the DOM? ', test_passed(1)

! real files
test_passed(2) = is_index_as_dom('src/tests/data/quakeml_ci38457511.xml', [5_I8P, 65536_I8P])
test_passed(3) = is_index_as_dom(VTK_DIR//'XML_UNST-ascii.vtu', [3_I8P, 65536_I8P])
test_passed(3) = is_index_as_dom(VTK_DIR//'XML_UNST-binary.vtu', [3_I8P, 65536_I8P]).and.test_passed(3)
test_passed(3) = is_index_as_dom(VTK_DIR//'XML_RECT-ascii.vtr', [64_I8P, 65536_I8P]).and.test_passed(3)
test_passed(3) = is_index_as_dom(VTK_DIR//'XML_RECT-binary.vtr', [64_I8P, 65536_I8P]).and.test_passed(3)
test_passed(3) = is_index_as_dom(VTK_DIR//'XML_STRG-binary.vts', [64_I8P, 65536_I8P]).and.test_passed(3)
print "(A,L1)", 'Does the index agree with the DOM on real files? ', all(test_passed(2:3))

! malformed input: the same problem of the DOM
is_same = .true.
do d=1, 5
   select case(d)
   case(1) ; call write_file(filename, '<a>'//NL//'<b>1</a>')
   case(2) ; call write_file(filename, '<a>1</x></a>')
   case(3) ; call write_file(filename, '<a>'//NL//'<b>1</b>')
   case(4) ; call write_file(filename, '<a><!-- x</a>')
   case(5) ; call write_file(filename, '<a k=1>2</a>')
   endselect
   iomsg_dom = 'unset'
   call dom%parse(filename=filename, iostat=iostat_dom, iomsg=iomsg_dom)
   do c=1, 2
      iomsg_idx = 'unset'
      call idx%scan(filename=filename, chunk_size=merge(1_I8P, 65536_I8P, c==1), iostat=iostat_idx, iomsg=iomsg_idx)
      if (iostat_idx/=iostat_dom.or.iomsg_idx/=iomsg_dom) then
         is_same = .false.
         print "(A,I0,A)", 'Different problem for malformed document ', d, ': '//trim(iomsg_idx)//' vs '//trim(iomsg_dom)
      endif
   enddo
enddo
test_passed(4) = is_same
print "(A,L1)", 'Is malformed input reported as by the DOM? ', test_passed(4)

! raw appended data: the scan stops after the AppendedData start tag, before the binary data
is_same = .true.
do d=1, 3
   select case(d)
   case(1) ; filename = VTK_DIR//'XML_UNST-raw.vtu'
   case(2) ; filename = VTK_DIR//'XML_RECT-raw.vtr'
   case(3) ; filename = tmp_dir//'/foxy_test_index.xml'
   endselect
   if (d==3) call write_file(filename, '<V><A n="1"/><AppendedData encoding="raw">'//NL//'   _'//achar(0)//'<<</'//achar(1))
   do c=1, 2
      call idx%scan(filename=filename, stop_at='AppendedData', chunk_size=merge(5_I8P, 65536_I8P, c==1), iostat=iostat_idx)
      id = idx%find(name='AppendedData')
      chars = read_chars(filename, idx%stop_position(), idx%stop_position()+40_I8P)
      if (.not.(iostat_idx==0.and.id>0)) then
         is_same = .false.
         print "(A,I0)", 'Scan not stopped at AppendedData for '//filename//', iostat=', iostat_idx
         cycle
      endif
      if (.not.(idx%attribute(id=id, name='encoding')=='raw'.and.index(chars, '_')>0)) then
         is_same = .false.
         print "(A)", 'Wrong stop position for '//filename//': ['//chars//']'
         cycle
      endif
      if (.not.(verify(chars(:index(chars, '_')-1), ' '//NL)==0.and.                                         &
                size(idx%find_all(name='DataArray'))==count_substring(read_chars(filename, 1_I8P,             &
                                                                 idx%stop_position()), '<DataArray').and.      &
                idx%content(id=id)==''.and.idx%content(id=1_I4P)=='')) then
         is_same = .false.
         print "(A)", 'Wrong index before the raw data of '//filename
      endif
   enddo
enddo
test_passed(5) = is_same
print "(A,L1)", 'Does the scan stop before the raw appended data? ', test_passed(5)

! text range of an ASCII DataArray: the bytes VTK readers decode
filename = VTK_DIR//'XML_UNST-ascii.vtu'
call dom%parse(filename=filename)
call idx%scan(filename=filename)
id = idx%find(path='Points/DataArray')
call idx%text_range(id=id, first=first, last=last)
chars = read_chars(filename, first, last)
test_passed(6) = id>0.and.last>first.and.trim(adjustl(strip_new_lines(chars)))==dom%content(id=id)
print "(A,L1)", 'Is the text range the DataArray data? ', test_passed(6)

! content range of a tag with children: its whole content
id = idx%find(name='Points')
call idx%content_range(id=id, first=first, last=last)
chars = read_chars(filename, first, last)
test_passed(7) = index(chars, '<DataArray')>0.and.index(chars, '</DataArray>')>0.and.index(chars, '</Points>')==0
print "(A,L1)", 'Is the content range the tag content? ', test_passed(7)

! missing file and free
call idx%scan(filename=tmp_dir//'/foxy_test_index_missing.xml', iostat=iostat_idx, iomsg=iomsg_idx)
test_passed(8) = iostat_idx/=0.and.idx%name(1)==''
call idx%scan(filename=VTK_DIR//'XML_UNST-ascii.vtu')
call idx%free
test_passed(9) = idx%find(name='VTKFile')==0.and.idx%content(id=1)==''
print "(A,L1)", 'Are a missing file and free handled? ', all(test_passed(8:9))

open(newunit=unit, file=tmp_dir//'/foxy_test_index.xml', status='OLD')
close(unit, status='DELETE')
print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   function is_index_as_dom(filename, chunks) result(is_same)
   !< Check that the index of a file has the same tags (names, hierarchy, attributes, content) of its DOM.
   character(*), intent(in) :: filename  !< File name.
   integer(I8P), intent(in) :: chunks(:) !< Chunk sizes of the scan.
   logical                  :: is_same   !< Check result.
   integer(I4P)             :: t         !< Tag ID.
   integer                  :: k         !< Counter.
   integer                  :: a         !< Counter.

   is_same = .true.
   call dom%parse(filename=filename)
   do k=1, size(chunks, dim=1)
      call idx%scan(filename=filename, chunk_size=chunks(k))
      t = 0
      do
         t = t + 1
         if (dom%name(t)=='' .and. idx%name(t)=='') exit
         if (idx%name(t)/=dom%name(t).or.idx%parent(t)/=dom%parent(t).or.idx%level(t)/=dom%level(t).or. &
             idx%content(id=t)/=dom%content(id=t).or..not.same_ids(idx%children(t), dom%children(t))) then
            is_same = .false.
            print "(A,I0,A,I0)", 'Index differs from DOM for '//filename//' at tag ', t, ' with chunk size ', chunks(k)
            print "(A)", '  index: '//idx%name(t)//' ['//idx%content(id=t)//']'
            print "(A)", '  DOM  : '//dom%name(t)//' ['//dom%content(id=t)//']'
            exit
         endif
         do a=1, size(ATTRIBUTES, dim=1)
            if (idx%attribute(id=t, name=trim(ATTRIBUTES(a)))/=dom%attribute(id=t, name=trim(ATTRIBUTES(a)))) then
               is_same = .false.
               print "(A,I0)", 'Attribute '//trim(ATTRIBUTES(a))//' differs for '//filename//' at tag ', t
            endif
         enddo
      enddo
      if (.not.same_ids(idx%children(0), dom%children(0))) is_same = .false.
   enddo
   endfunction is_index_as_dom

   pure function same_ids(a, b) result(is_same)
   !< Check that two IDs lists are equal.
   integer(I4P), intent(in) :: a(:)    !< First list.
   integer(I4P), intent(in) :: b(:)    !< Second list.
   logical                  :: is_same !< Check result.

   is_same = size(a, dim=1)==size(b, dim=1)
   if (is_same) is_same = all(a==b)
   endfunction same_ids

   pure function count_substring(string, substring) result(n)
   !< Count the occurrences of a substring.
   character(*), intent(in) :: string    !< String.
   character(*), intent(in) :: substring !< Substring.
   integer                  :: n         !< Occurrences.
   integer                  :: p         !< Position.
   integer                  :: e         !< Relative position.

   n = 0
   p = 1
   do
      e = index(string(p:), substring)
      if (e==0) exit
      n = n + 1
      p = p + e
   enddo
   endfunction count_substring

   pure function strip_new_lines(string) result(stripped)
   !< Return a string with new lines replaced by spaces.
   character(*), intent(in)   :: string   !< String.
   character(len=len(string)) :: stripped !< String without new lines.
   integer                    :: c        !< Counter.

   stripped = string
   do c=1, len(string)
      if (stripped(c:c)==NL) stripped(c:c) = ' '
   enddo
   endfunction strip_new_lines

   function read_chars(filename, first, last) result(chars)
   !< Read the characters of a file between two positions (clipped to the file size).
   character(*), intent(in)      :: filename !< File name.
   integer(I8P), intent(in)      :: first    !< First position.
   integer(I8P), intent(in)      :: last     !< Last position.
   character(len=:), allocatable :: chars    !< Characters.
   integer(I8P)                  :: size_    !< File size.
   integer                       :: unit     !< File unit.

   open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='OLD')
   inquire(unit=unit, size=size_)
   allocate(character(len=max(0_I8P, min(last, size_)-first+1)) :: chars)
   if (len(chars)>0) read(unit, pos=first) chars
   close(unit)
   endfunction read_chars

   subroutine write_file(filename, source)
   !< Write a source into a file.
   character(*), intent(in) :: filename !< File name.
   character(*), intent(in) :: source   !< Source.
   integer                  :: unit     !< File unit.

   open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE')
   write(unit) source
   close(unit)
   endsubroutine write_file
endprogram foxy_test_index
