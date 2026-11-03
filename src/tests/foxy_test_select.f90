!< FoXy test.
program foxy_test_select
!< FoXy test.
!<
!< Path selector: *select* gives the same tags as *find_all* plus a loop doing the same by hand (children, descendants,
!< any name, attributes, regular expressions, positions among siblings, namespaces) on the QuakeML and VTK reference
!< files, for the DOM and the index; a malformed expression selects nothing and returns XML_MALFORMED with its column.
use foxy, only : I4P, regex, xml_file, xml_index, xml_tag, XML_MALFORMED

implicit none
character(*), parameter   :: QUAKEML = 'src/tests/data/quakeml_ci38457511.xml' !< QuakeML reference file.
character(*), parameter   :: VTK_DIR = 'src/tests/data/vtk/'                   !< VTK reference files directory.
character(*), parameter   :: BED = 'http://quakeml.org/xmlns/bed/1.2'          !< QuakeML default namespace.
type(xml_file)            :: doc            !< Document.
type(xml_index)           :: idx            !< Index of the same file.
type(regex)               :: re             !< Regular expression.
integer(I4P), allocatable :: expected(:)    !< Expected IDs.
integer(I4P), allocatable :: ids(:)         !< IDs.
integer(I4P)              :: iostat         !< IO status.
integer(I4P)              :: t              !< Counter.
integer(I4P)              :: c              !< Counter.
logical                   :: test_passed(7) !< List of passed tests.

test_passed = .false.

call doc%parse(filename=QUAKEML, iostat=iostat)
call idx%scan(filename=QUAKEML)
test_passed(1) = iostat==0
! names and paths, as find_all
test_passed(1) = test_passed(1).and.is_same('//value', doc%find_all(name='value'))
test_passed(1) = test_passed(1).and.is_same('value', doc%find_all(name='value'))
test_passed(1) = test_passed(1).and.is_same('origin/latitude/value', doc%find_all(path='origin/latitude/value'))
test_passed(1) = test_passed(1).and.is_same('/q:quakeml/eventParameters/event', &
                                            doc%find_all(path='q:quakeml/eventParameters/event'))
test_passed(1) = test_passed(1).and.is_same('/eventParameters', [integer(I4P) ::])
! any name: every tag, the roots, the children of the events
test_passed(1) = test_passed(1).and.is_same('//*', [(t, t=1, doc%tags_number())])
test_passed(1) = test_passed(1).and.is_same('/*', doc%children(0))
expected = [integer(I4P) ::]
ids = doc%find_all(name='event')
do t=1, size(ids)
   expected = [expected, doc%children(ids(t))]
enddo
test_passed(1) = test_passed(1).and.is_same('event/*', sorted(expected))
! descendants: values with an event ancestor
expected = [integer(I4P) ::]
ids = doc%find_all(name='value')
do t=1, size(ids)
   if (has_ancestor(ids(t), 'event')) expected = [expected, ids(t)]
enddo
test_passed(1) = test_passed(1).and.size(expected)>0.and.is_same('//event//value', expected)
test_passed(1) = test_passed(1).and.is_same('q:quakeml//origin//value', doc%find_all(path='origin/latitude/value'), &
                                            superset=.true.)
print "(A,L1)", 'Are names, any name and descendants selected as find_all? ', test_passed(1)

! attributes: presence, decoded value, regular expression
expected = [integer(I4P) ::]
ids = doc%find_all(name='event')
do t=1, size(ids)
   if (doc%attribute(ids(t), 'catalog:eventsource')=='ci') expected = [expected, ids(t)]
enddo
test_passed(2) = size(expected)>0.and.is_same('//event[@catalog:eventsource="ci"]', expected)
test_passed(2) = test_passed(2).and.is_same("//event[ @catalog:eventsource = 'ci' ]", expected)
test_passed(2) = test_passed(2).and.is_same('//*[@catalog:eventsource="ci"]', &
                                            attribute_is([(t, t=1, doc%tags_number())], 'catalog:eventsource', 'ci'))
expected = [integer(I4P) ::]
do t=1, doc%tags_number()
   if (doc%attributes_number(t)>0) then
      do c=1, doc%attributes_number(t)
         if (doc%attribute_name(t, c)=='publicID') then
            expected = [expected, t]
            exit
         endif
      enddo
   endif
enddo
test_passed(2) = test_passed(2).and.is_same('//*[@publicID]', expected)
call re%compile('eventid=ci38457511&format', iostat=iostat) ! decoded: the source has &amp;
expected = doc%matching(re, ids=[(t, t=1, doc%tags_number())], attribute='publicID')
test_passed(2) = test_passed(2).and.size(expected)>0.and.is_same('//*[@publicID~="eventid=ci38457511&format"]', expected)
call re%compile('^[0-9]+$', iostat=iostat)
expected = doc%matching(re, ids=doc%find_all(name='event'), attribute='catalog:eventid')
test_passed(2) = test_passed(2).and.size(expected)>0.and.is_same('//event[@catalog:eventid~="^[0-9]+$"]', expected)
print "(A,L1)", 'Are attributes predicates as a loop? ', test_passed(2)

! positions among siblings, after the previous predicates
test_passed(3) = is_same('//origin/*[1]', first_children(doc%find_all(name='origin')))
test_passed(3) = test_passed(3).and.is_same('//value[1]', nth_named(doc%find_all(name='value'), 1_I4P))
test_passed(3) = test_passed(3).and.is_same('//value[2]', nth_named(doc%find_all(name='value'), 2_I4P))
test_passed(3) = test_passed(3).and.is_same('//event[@catalog:datasource][2]', &
                                            nth_named(attribute_is(doc%find_all(name='event'), 'catalog:datasource'), 2_I4P))
test_passed(3) = test_passed(3).and.is_same('//event[2][@catalog:datasource]', &
                                            attribute_is(nth_named(doc%find_all(name='event'), 2_I4P), 'catalog:datasource'))
test_passed(3) = test_passed(3).and.is_same('//event[999]', [integer(I4P) ::])
print "(A,L1)", 'Are positions counted among siblings? ', test_passed(3)

! namespaces, as find_all
test_passed(4) = is_same('//{'//BED//'}origin', doc%find_all(name='{'//BED//'}origin'))
test_passed(4) = test_passed(4).and.size(doc%find_all(name='{'//BED//'}origin'))>0
ids = doc%select('//b:origin/b:depth', namespaces='xmlns:b="'//BED//'"', iostat=iostat)
test_passed(4) = test_passed(4).and.iostat==0.and. &
                 same_ids(ids, doc%find_all(path='b:origin/b:depth', namespaces='xmlns:b="'//BED//'"'))
ids = doc%select('//z:origin', namespaces='xmlns:b="'//BED//'"', iostat=iostat)
test_passed(4) = test_passed(4).and.iostat==0.and.size(ids)==0
print "(A,L1)", 'Are namespaces resolved as find_all? ', test_passed(4)

! VTK files
call doc%parse(filename=VTK_DIR//'XML_UNST-ascii.vtu', iostat=iostat)
call idx%scan(filename=VTK_DIR//'XML_UNST-ascii.vtu')
test_passed(5) = iostat==0
test_passed(5) = test_passed(5).and.is_same('//DataArray[@Name="Points"]', &
                                            attribute_is(doc%find_all(name='DataArray'), 'Name', 'Points'))
test_passed(5) = test_passed(5).and.size(doc%select('//DataArray[@Name="Points"]'))==1
test_passed(5) = test_passed(5).and.is_same('/VTKFile/UnstructuredGrid/Piece/*/DataArray[1]', &
                                            first_named(doc%children(doc%find(name='Piece')), 'DataArray'))
test_passed(5) = test_passed(5).and.is_same('Piece//DataArray[@format~="^(ascii|binary)$"]', &
                                            doc%find_all(name='DataArray'))
call doc%parse(filename=VTK_DIR//'XML_RECT-binary.vtr', iostat=iostat)
call idx%scan(filename=VTK_DIR//'XML_RECT-binary.vtr')
test_passed(5) = test_passed(5).and.iostat==0
test_passed(5) = test_passed(5).and.is_same('//Coordinates/DataArray', doc%find_all(path='Coordinates/DataArray'))
test_passed(5) = test_passed(5).and.is_same('//*[@type~="Float"][1]', &
                                            nth_named(attribute_regex([(t, t=1, doc%tags_number())], 'type', 'Float'), 1_I4P))
print "(A,L1)", 'Are VTK tags selected as a loop? ', test_passed(5)

! malformed expressions: nothing selected, XML_MALFORMED and the column
call doc%parse(string='<a b="1"><c/></a>')
test_passed(6) = is_malformed('', 1)
test_passed(6) = test_passed(6).and.is_malformed('/', 2)
test_passed(6) = test_passed(6).and.is_malformed('a/', 3)
test_passed(6) = test_passed(6).and.is_malformed('a//', 4)
test_passed(6) = test_passed(6).and.is_malformed('a/[1]', 3)
test_passed(6) = test_passed(6).and.is_malformed('a b', 1)
test_passed(6) = test_passed(6).and.is_malformed('a]b', 1)
test_passed(6) = test_passed(6).and.is_malformed('{uri', 1)
test_passed(6) = test_passed(6).and.is_malformed('a[', 2)
test_passed(6) = test_passed(6).and.is_malformed('a[@', 4)
test_passed(6) = test_passed(6).and.is_malformed('a[@b', 2)
test_passed(6) = test_passed(6).and.is_malformed('a[@b=1]', 6)
test_passed(6) = test_passed(6).and.is_malformed('a[@b="1]', 6)
test_passed(6) = test_passed(6).and.is_malformed('a[@b!="1"]', 4)
test_passed(6) = test_passed(6).and.is_malformed('a[@b="1"', 2)
test_passed(6) = test_passed(6).and.is_malformed('a[@b="1"x]', 9)
test_passed(6) = test_passed(6).and.is_malformed('a[0]', 3)
test_passed(6) = test_passed(6).and.is_malformed('a[1234567890]', 3)
test_passed(6) = test_passed(6).and.is_malformed('a[x]', 3)
test_passed(6) = test_passed(6).and.is_malformed('a[1]b', 5)
test_passed(6) = test_passed(6).and.is_malformed('a[@b~="(x"]', 7, at_least=.true.)
ids = doc%select('a[') ! no iostat: nothing selected, the program goes on
test_passed(6) = test_passed(6).and.size(ids)==0
ids = doc%select('a[@b="1"]/c', iostat=iostat)
test_passed(6) = test_passed(6).and.iostat==0.and.size(ids)==1
print "(A,L1)", 'Are malformed expressions reported with their column? ', test_passed(6)

! a built document numbers tags in insertion order: a subtree is not a range of IDs
call doc%free
call doc%add_tag(xml_tag(name='a'))                 ! 1
call doc%add_tag(xml_tag(name='b'), parent=1_I4P)   ! 2
call doc%add_tag(xml_tag(name='c'))                 ! 3, a root
call doc%add_tag(xml_tag(name='x'), parent=2_I4P)   ! 4, under a/b
call doc%add_tag(xml_tag(name='x'), parent=3_I4P)   ! 5, under c
call doc%add_tag(xml_tag(name='x'), parent=1_I4P)   ! 6, under a
ids = doc%select('a//x', iostat=iostat)
test_passed(7) = iostat==0.and.same_ids(ids, [4_I4P, 6_I4P])
ids = doc%select('/c//x', iostat=iostat)
test_passed(7) = test_passed(7).and.iostat==0.and.same_ids(ids, [5_I4P])
ids = doc%select('//x[1]', iostat=iostat)
test_passed(7) = test_passed(7).and.iostat==0.and.same_ids(ids, [4_I4P, 5_I4P, 6_I4P])
ids = doc%select('a/*', iostat=iostat)
test_passed(7) = test_passed(7).and.iostat==0.and.same_ids(ids, [2_I4P, 6_I4P])
print "(A,L1)", 'Are built documents selected as their tree? ', test_passed(7)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
contains
   function is_same(expression, expected, superset) result(is_ok)
   !< Return true if *expression* selects *expected* (or a superset of it, if *superset*), on the DOM and on the index.
   character(*), intent(in)           :: expression  !< Path expression.
   integer(I4P), intent(in)           :: expected(:) !< Expected IDs.
   logical,      intent(in), optional :: superset    !< Expected IDs are a part of the selection.
   logical                            :: is_ok       !< Check result.
   integer(I4P), allocatable          :: selected(:) !< Selected IDs.
   integer(I4P), allocatable          :: indexed(:)  !< Selected IDs of the index.
   integer(I4P)                       :: status      !< IO status.
   integer(I4P)                       :: status_idx  !< IO status of the index.
   integer(I4P)                       :: e           !< Counter.

   selected = doc%select(expression, iostat=status)
   indexed = idx%select(expression, iostat=status_idx)
   is_ok = status==0.and.status_idx==0.and.same_ids(selected, indexed)
   if (present(superset)) then
      do e=1, size(expected)
         is_ok = is_ok.and.any(selected==expected(e))
      enddo
   else
      is_ok = is_ok.and.same_ids(selected, expected)
   endif
   if (.not.is_ok) print "(A,I0,A,I0)", '  differs: '//expression//' selected ', size(selected), ', expected ', &
                                        size(expected)
   endfunction is_same

   pure function same_ids(a, b) result(is_same_)
   !< Return true if two lists of IDs are equal.
   integer(I4P), intent(in) :: a(:)     !< First list.
   integer(I4P), intent(in) :: b(:)     !< Second list.
   logical                  :: is_same_ !< Check result.

   is_same_ = size(a)==size(b)
   if (is_same_) is_same_ = all(a==b)
   endfunction same_ids

   function is_malformed(expression, column, at_least) result(is_ok)
   !< Return true if *expression* selects nothing with XML_MALFORMED and its column (or a later one, if *at_least*).
   character(*), intent(in)           :: expression !< Path expression.
   integer,      intent(in)           :: column     !< Expected column.
   logical,      intent(in), optional :: at_least   !< The column may be later (a regex problem inside the pattern).
   logical                            :: is_ok      !< Check result.
   integer(I4P), allocatable          :: selected(:) !< Selected IDs.
   integer(I4P)                       :: status     !< IO status.
   character(len=256)                 :: message    !< IO message.
   integer                            :: at         !< Position of the column in the message.
   integer                            :: reported   !< Reported column.

   message = ''
   selected = doc%select(expression, iostat=status, iomsg=message)
   is_ok = status==XML_MALFORMED.and.size(selected)==0
   at = index(message, 'at column ')
   is_ok = is_ok.and.at>0
   reported = -1
   if (is_ok) read(message(at+10:), *) reported
   if (present(at_least)) then
      is_ok = is_ok.and.reported>=column
   else
      is_ok = is_ok.and.reported==column
   endif
   if (.not.is_ok) print "(A)", '  not reported as expected: "'//expression//'": '//trim(message)
   endfunction is_malformed

   function has_ancestor(id, name) result(has)
   !< Return true if the tag *id* has an ancestor named *name*.
   integer(I4P), intent(in) :: id   !< Tag ID.
   character(*), intent(in) :: name !< Ancestor name.
   logical                  :: has  !< Check result.
   integer(I4P)             :: a    !< Ancestor ID.

   has = .false.
   a = doc%parent(id)
   do while (a>0)
      if (doc%name(a)==name) then
         has = .true.
         return
      endif
      a = doc%parent(a)
   enddo
   endfunction has_ancestor

   function attribute_is(candidates, name, value) result(kept)
   !< Return the IDs of *candidates* having the attribute *name* (valued *value*, if passed).
   integer(I4P), intent(in)           :: candidates(:) !< Candidates IDs.
   character(*), intent(in)           :: name          !< Attribute name.
   character(*), intent(in), optional :: value         !< Attribute value.
   integer(I4P), allocatable          :: kept(:)       !< Kept IDs.
   integer(I4P)                       :: k             !< Counter.
   integer(I4P)                       :: a             !< Counter.
   logical                            :: has           !< The candidate has the attribute.

   kept = [integer(I4P) ::]
   do k=1, size(candidates)
      has = .false.
      do a=1, doc%attributes_number(candidates(k))
         if (doc%attribute_name(candidates(k), a)==name) has = .true.
      enddo
      if (has.and.present(value)) has = doc%attribute(candidates(k), name)==value
      if (has) kept = [kept, candidates(k)]
   enddo
   endfunction attribute_is

   function attribute_regex(candidates, name, pattern) result(kept)
   !< Return the IDs of *candidates* whose attribute *name* matches the regular expression *pattern*.
   integer(I4P), intent(in)  :: candidates(:) !< Candidates IDs.
   character(*), intent(in)  :: name          !< Attribute name.
   character(*), intent(in)  :: pattern       !< Regular expression.
   integer(I4P), allocatable :: kept(:)       !< Kept IDs.
   type(regex)               :: re_           !< Compiled regular expression.

   call re_%compile(pattern)
   kept = doc%matching(re_, ids=candidates, attribute=name)
   endfunction attribute_regex

   function first_children(parents) result(firsts)
   !< Return the first child of each of *parents* (having children), in document order.
   integer(I4P), intent(in)  :: parents(:) !< Parents IDs.
   integer(I4P), allocatable :: firsts(:)  !< First children IDs.
   integer(I4P), allocatable :: kids(:)    !< Children IDs.
   integer(I4P)              :: p          !< Counter.

   firsts = [integer(I4P) ::]
   do p=1, size(parents)
      kids = doc%children(parents(p))
      if (size(kids)>0) firsts = [firsts, kids(1)]
   enddo
   firsts = sorted(firsts)
   endfunction first_children

   function first_named(parents, name) result(firsts)
   !< Return the first child named *name* of each of *parents*, in document order.
   integer(I4P), intent(in)  :: parents(:) !< Parents IDs.
   character(*), intent(in)  :: name       !< Child name.
   integer(I4P), allocatable :: firsts(:)  !< First children IDs.
   integer(I4P), allocatable :: kids(:)    !< Children IDs.
   integer(I4P)              :: p          !< Counter.
   integer(I4P)              :: k          !< Counter.

   firsts = [integer(I4P) ::]
   do p=1, size(parents)
      kids = doc%children(parents(p))
      do k=1, size(kids)
         if (doc%name(kids(k))==name) then
            firsts = [firsts, kids(k)]
            exit
         endif
      enddo
   enddo
   firsts = sorted(firsts)
   endfunction first_named

   function nth_named(candidates, n) result(kept)
   !< Return the IDs of *candidates* (in document order) that are the *n*-th among the candidates with the same parent.
   integer(I4P), intent(in)  :: candidates(:) !< Candidates IDs, in document order.
   integer(I4P), intent(in)  :: n             !< Position, from 1.
   integer(I4P), allocatable :: kept(:)       !< Kept IDs.
   integer(I4P)              :: k             !< Counter.
   integer(I4P)              :: j             !< Counter.
   integer(I4P)              :: before        !< Candidates with the same parent before the current one.

   kept = [integer(I4P) ::]
   do k=1, size(candidates)
      before = 0
      do j=1, k-1
         if (doc%parent(candidates(j))==doc%parent(candidates(k))) before = before + 1
      enddo
      if (before+1==n) kept = [kept, candidates(k)]
   enddo
   endfunction nth_named

   pure function sorted(list) result(ordered)
   !< Return *list* in increasing order (insertion sort, small lists).
   integer(I4P), intent(in)  :: list(:)    !< List.
   integer(I4P), allocatable :: ordered(:) !< Sorted list.
   integer(I4P)              :: i          !< Counter.
   integer(I4P)              :: j          !< Counter.
   integer(I4P)              :: v          !< Current value.

   ordered = list
   do i=2, size(ordered)
      v = ordered(i)
      j = i - 1
      do while (j>=1)
         if (ordered(j)<=v) exit
         ordered(j+1) = ordered(j)
         j = j - 1
      enddo
      ordered(j+1) = v
   enddo
   endfunction sorted
endprogram foxy_test_select
