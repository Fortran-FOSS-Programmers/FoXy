!< FoXy test.
program foxy_test_typed_writes
!< FoXy test.
!<
!< Typed writes: set_content and set_attribute with integers (every kind), reals (R4P, R8P), logicals and lists; the text
!< is the shortest that reads back, so a round trip through get_content/get_attribute is exact (extremes, -0, subnormals,
!< NaN and infinities included); fmt= is honoured; a bad format is reported.
use, intrinsic :: ieee_arithmetic, only : ieee_is_nan, ieee_value, ieee_positive_inf, ieee_negative_inf, ieee_quiet_nan
use foxy, only : I1P, I2P, I4P, I8P, R4P, R8P, xml_file, xml_tag, XML_BAD_VALUE

implicit none
type(xml_file)            :: doc                !< Document.
type(xml_file)            :: back               !< Document parsed back.
real(R8P)                 :: r8(9)              !< Reals to write.
real(R4P)                 :: r4(5)              !< Reals to write.
real(R8P)                 :: x8                 !< Real read back.
real(R4P)                 :: x4                 !< Real read back.
real(R8P), allocatable    :: list8(:)           !< List read back.
integer(I8P), allocatable :: list_i8(:)         !< List read back.
integer(I1P)              :: i1                 !< Integer read back.
integer(I2P)              :: i2                 !< Integer read back.
integer(I4P)              :: i4                 !< Integer read back.
integer(I8P)              :: i8                 !< Integer read back.
logical                   :: l                  !< Logical read back.
integer(I4P)              :: iostat             !< IO status.
character(len=128)        :: iomsg              !< IO message.
integer                   :: k                  !< Counter.
logical                   :: test_passed(6)     !< List of passed tests.

test_passed = .false.
r8 = [0.1_R8P, -2.5_R8P, 1.0e-5_R8P, huge(1._R8P), tiny(1._R8P), transfer(1_I8P, 1._R8P), -0._R8P, &
      ieee_value(1._R8P, ieee_positive_inf), 1._R8P/3._R8P]
r4 = [0.1_R4P, huge(1._R4P), -1.5e-7_R4P, 1._R4P/3._R4P, ieee_value(1._R4P, ieee_negative_inf)]

! reals: the shortest text, read back exactly
test_passed(1) = .true.
do k=1, size(r8)
   call doc%free() ; call doc%add_tag(xml_tag(name='v'))
   call doc%set_content(id=1_I4P, value=r8(k))
   call back%parse(string=doc%stringify())
   call back%get_content(id=1_I4P, value=x8, iostat=iostat)
   test_passed(1) = test_passed(1).and.iostat==0.and.transfer(x8, 1_I8P)==transfer(r8(k), 1_I8P)
enddo
do k=1, size(r4)
   call doc%free() ; call doc%add_tag(xml_tag(name='v'))
   call doc%set_attribute(id=1_I4P, name='x', value=r4(k))
   call back%parse(string=doc%stringify())
   call back%get_attribute(id=1_I4P, name='x', value=x4, iostat=iostat)
   test_passed(1) = test_passed(1).and.iostat==0.and.transfer(x4, 1_I4P)==transfer(r4(k), 1_I4P)
enddo
call doc%free() ; call doc%add_tag(xml_tag(name='v'))
call doc%set_content(id=1_I4P, value=0.1_R8P)
test_passed(1) = test_passed(1).and.doc%content('v')=='0.1'
call doc%set_content(id=1_I4P, value=ieee_value(1._R8P, ieee_quiet_nan))
call back%parse(string=doc%stringify())
call back%get_content(id=1_I4P, value=x8, iostat=iostat)
test_passed(1) = test_passed(1).and.iostat==0.and.ieee_is_nan(x8)
print "(A,L1)", 'Do reals read back exactly? ', test_passed(1)

! integers of every kind, at their extremes, and logicals
call doc%free() ; call doc%add_tag(xml_tag(name='v'))
call doc%set_attribute(id=1_I4P, name='a', value=-huge(1_I1P)-1_I1P)
call doc%set_attribute(id=1_I4P, name='b', value=huge(1_I2P))
call doc%set_attribute(id=1_I4P, name='c', value=-huge(1_I4P)-1_I4P)
call doc%set_attribute(id=1_I4P, name='d', value=huge(1_I8P))
call doc%set_attribute(id=1_I4P, name='e', value=.true.)
call doc%set_content(id=1_I4P, value=.false.)
call back%parse(string=doc%stringify())
call back%get_attribute(id=1_I4P, name='a', value=i1)
call back%get_attribute(id=1_I4P, name='b', value=i2)
call back%get_attribute(id=1_I4P, name='c', value=i4)
call back%get_attribute(id=1_I4P, name='d', value=i8)
call back%get_attribute(id=1_I4P, name='e', value=l)
test_passed(2) = i1==-huge(1_I1P)-1_I1P.and.i2==huge(1_I2P).and.i4==-huge(1_I4P)-1_I4P.and.i8==huge(1_I8P).and.l.and. &
                 back%content('v')=='false'.and.back%attribute(1_I4P, 'b')=='32767'
print "(A,L1)", 'Do integers and logicals read back exactly? ', test_passed(2)

! lists: one space between the values, read back exactly
call doc%free() ; call doc%add_tag(xml_tag(name='v'))
call doc%set_content(id=1_I4P, values=r8(1:7))
call doc%set_attribute(id=1_I4P, name='ext', values=[0_I8P, 10_I8P, -3_I8P])
call back%parse(string=doc%stringify())
call back%get_content(id=1_I4P, values=list8)
call back%get_attribute(id=1_I4P, name='ext', values=list_i8)
test_passed(3) = size(list8)==7.and.back%attribute(1_I4P, 'ext')=='0 10 -3'
if (test_passed(3)) test_passed(3) = all(transfer(list8, 1_I8P, 7)==transfer(r8(1:7), 1_I8P, 7)).and.all(list_i8==[0, 10, -3])
call doc%set_content(id=1_I4P, values=[real(R4P) ::])
test_passed(3) = test_passed(3).and.doc%content('v')==''
print "(A,L1)", 'Do lists read back exactly? ', test_passed(3)

! fmt=, and a format that cannot write the value
call doc%set_content(id=1_I4P, value=3.14159_R8P, fmt='(F6.3)')
call doc%set_attribute(id=1_I4P, name='n', value=7_I4P, fmt='(I3.3)')
call doc%set_content(id=1_I4P, values=[1.5_R8P, 2.25_R8P], fmt='(F5.2)')
test_passed(4) = doc%content('v')=='1.50 2.25'.and.doc%attribute(1_I4P, 'n')=='007'
call doc%set_content(id=1_I4P, value=3.14159_R8P, fmt='(F6.3)')
test_passed(4) = test_passed(4).and.doc%content('v')=='3.142'
call doc%set_content(id=1_I4P, value=1._R8P, fmt='(I5)', iostat=iostat, iomsg=iomsg)
test_passed(4) = test_passed(4).and.iostat==XML_BAD_VALUE.and.index(iomsg, '(I5)')>0.and.doc%content('v')=='3.142'
print "(A,L1)", 'Is fmt= honoured, a bad format reported? ', test_passed(4)

! the typed set_content replaces the children, as the text one
call doc%parse(string='<r><a>1</a><b/></r>')
call doc%set_content(id=1_I4P, value=42_I4P)
test_passed(5) = doc%tags_number()==1.and.doc%stringify()=='<r>42</r>'
print "(A,L1)", 'Does a typed content replace the children? ', test_passed(5)

! a missing tag is reported
call doc%set_attribute(id=99_I4P, name='x', value=1._R4P, iostat=iostat)
test_passed(6) = iostat/=0
print "(A,L1)", 'Is a missing tag reported? ', test_passed(6)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_typed_writes
