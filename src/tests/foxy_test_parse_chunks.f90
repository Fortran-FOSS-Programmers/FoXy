!< FoXy test.
program foxy_test_parse_chunks
!< FoXy test.
!<
!< Files are parsed in chunks: with any chunk size (down to 1 character, so that every token is split at every point) the
!< result is the same as parsing the whole source as a string, problems of malformed input included.
use foxy, only: I4P, I8P, xml_file

implicit none
type :: document
   character(len=:), allocatable :: source !< Source.
endtype document
character(len=1), parameter   :: NL = new_line('a')     !< New line.
integer(I8P),     parameter   :: CHUNKS(*) = [1_I8P, 2_I8P, 3_I8P, 5_I8P, 7_I8P, 11_I8P, 64_I8P, 4096_I8P] !< Sizes.
type(document), allocatable   :: documents(:)           !< Documents.
character(len=:), allocatable :: tmp_dir                !< Temporary directory.
character(len=:), allocatable :: filename               !< File name.
type(xml_file)                :: by_string              !< Document parsed from a string.
type(xml_file)                :: by_chunks              !< Document parsed from a file, in chunks.
integer(I4P)                  :: iostat_string          !< IO status, parsed from a string.
integer(I4P)                  :: iostat_chunks          !< IO status, parsed in chunks.
character(len=256)            :: iomsg_string           !< IO message, parsed from a string.
character(len=256)            :: iomsg_chunks           !< IO message, parsed in chunks.
integer                       :: unit                   !< File unit.
integer                       :: tmp_dir_len            !< Length of the TMPDIR environment variable.
integer                       :: status                 !< Status of the environment variable query.
integer                       :: d                      !< Counter.
integer                       :: c                      !< Counter.
logical                       :: is_same                !< Same results for all documents and chunk sizes.
logical                       :: test_passed(3)         !< List of passed tests.

test_passed = .false.

call get_environment_variable('TMPDIR', length=tmp_dir_len, status=status)
if (status==0.and.tmp_dir_len>0) then
   allocate(character(len=tmp_dir_len) :: tmp_dir)
   call get_environment_variable('TMPDIR', value=tmp_dir)
else
   tmp_dir = '/tmp'
endif
filename = tmp_dir//'/foxy_test_parse_chunks.xml'

allocate(documents(14))
documents(1)%source = '<?xml version="1.0" encoding="UTF-8"?>'//NL//'<!DOCTYPE a [ <!ENTITY e "x>y"> ]>'//NL// &
                      '<!-- head -->'//NL//'<a k="1>0" j=''2"3''>'//NL//'  <b/>'//NL//'  <c x="&amp;">t &lt; u</c>'//NL// &
                      '</a>'//NL//'<!-- tail -->'
documents(2)%source = '<p>see <b>this</b> and <i>that</i><!-- c --> now<?pi x?></p>'
documents(3)%source = '<a><![CDATA[x ]] ]> <b>y</b> ]]]]><b>z</b></a>'
documents(4)%source = '<a><!-- - -- ->-->1<?p ? >?>2<![CDATA[]]>3</a>'
documents(5)%source = '<r>'//repeat('<v k="1" j=''x''>value</v><e/>'//NL, 40)//'</r>'
documents(6)%source = '<a     k  =  "1"'//NL//'  j="2"   />'
documents(7)%source = '<a>1 < 2</a>'
documents(8)%source = '<a>'//NL//'<b>1</a>'
documents(9)%source = '<a>1</x></a>'
documents(10)%source = '<a><!-- x</a>'
documents(11)%source = '<a k=1>2</a>'
documents(12)%source = '<a k="1'
documents(13)%source = ''
documents(14)%source = 'just text'

is_same = .true.
do d=1, size(documents, dim=1)
   iomsg_string = 'unset'
   call by_string%parse(string=documents(d)%source, iostat=iostat_string, iomsg=iomsg_string)
   open(newunit=unit, file=filename, access='STREAM', form='UNFORMATTED', status='REPLACE')
   write(unit) documents(d)%source
   close(unit)
   do c=1, size(CHUNKS, dim=1)
      iomsg_chunks = 'unset'
      call by_chunks%parse(filename=filename, iostat=iostat_chunks, iomsg=iomsg_chunks, chunk_size=CHUNKS(c))
      if (by_chunks%stringify()/=by_string%stringify().or.                                   &
          by_chunks%stringify(linearize=.true.)/=by_string%stringify(linearize=.true.).or. &
          iostat_chunks/=iostat_string.or.iomsg_chunks/=iomsg_string) then
         is_same = .false.
         print "(A,I0,A,I0)", 'Different result for document ', d, ' with chunk size ', CHUNKS(c)
         print "(A,I0,A)", '  string: iostat=', iostat_string, ' iomsg='//trim(iomsg_string)
         print "(A,I0,A)", '  chunks: iostat=', iostat_chunks, ' iomsg='//trim(iomsg_chunks)
      endif
   enddo
enddo
test_passed(1) = is_same
print "(A,L1)", 'Is parsing in chunks the same as parsing the string? ', test_passed(1)

! a real file, default and tiny chunks
call by_string%parse(filename='src/tests/data/quakeml_ci38457511.xml')
call by_chunks%parse(filename='src/tests/data/quakeml_ci38457511.xml', chunk_size=13_I8P)
test_passed(2) = by_chunks%stringify(linearize=.true.)==by_string%stringify(linearize=.true.).and. &
                 by_chunks%stringify()==by_string%stringify()
print "(A,L1)", 'Is a real file the same with any chunk size? ', test_passed(2)

open(newunit=unit, file=filename, status='OLD')
close(unit, status='DELETE')
call by_chunks%parse(filename=filename, iostat=iostat_chunks, iomsg=iomsg_chunks)
test_passed(3) = iostat_chunks/=0
print "(A,L1)", 'Is a missing file still reported? ', test_passed(3)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_parse_chunks
