! Checks of the typed accessors on *doc* (an xml_file or an xml_index of SOURCE), included by foxy_test_typed_values.f90
! once for each type.
a = doc%find(name='a')

! scalars of every kind, logicals
l = [.false., .true., .true.]
call doc%get_attribute(id=a, name='i1', value=i1, iostat=iostats(1))
call doc%get_attribute(id=a, name='i2', value=i2, iostat=iostats(2))
call doc%get_attribute(id=a, name='i4', value=i4, iostat=iostats(3))
call doc%get_attribute(id=a, name='i8', value=i8, iostat=iostats(4))
call doc%get_attribute(id=a, name='r4', value=r4, iostat=iostats(5))
call doc%get_attribute(id=a, name='r8', value=r8, iostat=iostats(6))
call doc%get_attribute(id=a, name='b1', value=l(1), iostat=iostats(7))
call doc%get_attribute(id=a, name='b2', value=l(2), iostat=iostats(8))
call doc%get_attribute(id=a, name='b3', value=l(3), iostat=iostats(9)) ! not a logical: unchanged
is_passed(1) = all(iostats(1:8)==0).and.iostats(9)==XML_BAD_VALUE.and.                              &
               i1==-7_I1P.and.i2==300_I2P.and.i4==-70000_I4P.and.i8==9000000000_I8P.and.             &
               r4==0.5_R4P.and.r8==1.25e-3_R8P.and.l(1).and.(.not.l(2)).and.l(3)
if (.not.is_passed(1)) print "(A,9I6)", 'scalars: ', iostats(1:9)

! lists of every kind (blanks as separators, references decoded), empty list, NaN and infinities
call doc%get_attribute(id=a, name='ext', values=i1s, iostat=iostats(1))
call doc%get_attribute(id=a, name='ext', values=i2s, iostat=iostats(2))
call doc%get_attribute(id=a, name='ext', values=i4s, iostat=iostats(3))
call doc%get_attribute(id=a, name='ext', values=i8s, iostat=iostats(4))
call doc%get_attribute(id=a, name='reals', values=r4s, iostat=iostats(5))
call doc%get_attribute(id=a, name='reals', values=r8s, iostat=iostats(6))
is_passed(2) = all(iostats(1:6)==0).and.                                                             &
               all(i1s==[0_I1P, 10_I1P, 0_I1P, 10_I1P, 0_I1P, 0_I1P]).and.                           &
               all(i2s==[0_I2P, 10_I2P, 0_I2P, 10_I2P, 0_I2P, 0_I2P]).and.                           &
               all(i4s==[0_I4P, 10_I4P, 0_I4P, 10_I4P, 0_I4P, 0_I4P]).and.                           &
               all(i8s==[0_I8P, 10_I8P, 0_I8P, 10_I8P, 0_I8P, 0_I8P]).and.                           &
               all(r4s==[1.5_R4P, 2.5_R4P, -300._R4P]).and.all(r8s==[1.5_R8P, 2.5_R8P, -300._R8P])
call doc%get_attribute(id=a, name='empty', values=i4s, iostat=iostats(7))
call doc%get_attribute(id=a, name='special', values=r8s, iostat=iostats(8))
is_passed(2) = is_passed(2).and.iostats(7)==0.and.size(i4s, dim=1)==0.and.iostats(8)==0
if (is_passed(2)) is_passed(2) = size(r8s, dim=1)==3
if (is_passed(2)) is_passed(2) = ieee_is_nan(r8s(1)).and.r8s(2)>huge(1._R8P).and.r8s(3)<-huge(1._R8P)
if (.not.is_passed(2)) print "(A,8I6)", 'lists: ', iostats(1:8)

! malformed values (value unchanged, list empty), missing attribute and tags
i4 = 1_I4P
iomsgs = ''
call doc%get_attribute(id=a, name='comma', value=i4, iostat=iostats(1), iomsg=iomsgs(1))
call doc%get_attribute(id=a, name='slash', value=i4, iostat=iostats(2))
call doc%get_attribute(id=a, name='repeat', value=i4, iostat=iostats(3))
call doc%get_attribute(id=a, name='text', value=r8, iostat=iostats(4))
call doc%get_attribute(id=a, name='float', value=i4, iostat=iostats(5))
call doc%get_attribute(id=a, name='big', value=i1, iostat=iostats(6), iomsg=iomsgs(2))
call doc%get_attribute(id=a, name='pair', value=i4, iostat=iostats(7))
call doc%get_attribute(id=a, name='empty', value=i4, iostat=iostats(8))
call doc%get_attribute(id=a, name='comma', values=i4s, iostat=iostats(9))
call doc%get_attribute(id=a, name='nope', value=i4, iostat=iostats(10), iomsg=iomsgs(3))
call doc%get_attribute(id=99_I4P, name='i4', value=i4, iostat=iostats(11), iomsg=iomsgs(4))
call doc%get_attribute(id=0_I4P, name='i4', values=i4s, iostat=iostats(12))
is_passed(3) = all(iostats(1:9)==XML_BAD_VALUE).and.all(iostats(10:12)==XML_NOT_FOUND).and.          &
               i4==1_I4P.and.i1==-7_I1P.and.r8==1.25e-3_R8P.and.size(i4s, dim=1)==0.and.             &
               index(iomsgs(1), 'invalid character "," in "1,2" in attribute "comma" of tag "a"')>0.and. &
               index(iomsgs(2), 'invalid integer "300"')>0.and.                                      &
               index(iomsgs(3), 'no attribute "nope" in tag "a"')>0.and.                             &
               index(iomsgs(4), 'no tag with ID 99')>0
if (.not.is_passed(3)) print "(A,12I6/4(A/))", 'errors: ', iostats(1:12), (trim(iomsgs(i)), i=1, 4)

! contents: layout blanks, comments removed, CDATA literal; empty content; missing tag
i4 = 0_I4P
l(1) = .true.
call doc%get_content(id=doc%find(name='v'), value=i4, iostat=iostats(1))
call doc%get_content(id=doc%find(name='arr'), values=r8s, iostat=iostats(2))
call doc%get_content(id=doc%find(name='flag'), value=l(1), iostat=iostats(3))
call doc%get_content(id=doc%find(name='none'), values=i8s, iostat=iostats(4))
call doc%get_content(id=doc%find(name='none'), value=i8, iostat=iostats(5))
call doc%get_content(id=0_I4P, values=i8s, iostat=iostats(6), iomsg=iomsgs(1))
is_passed(4) = all(iostats(1:4)==0).and.iostats(5)==XML_BAD_VALUE.and.iostats(6)==XML_NOT_FOUND.and.  &
               i4==42_I4P.and.(.not.l(1)).and.size(i8s, dim=1)==0.and.i8==9000000000_I8P.and.        &
               index(iomsgs(1), 'no tag with ID 0')>0
if (is_passed(4)) is_passed(4) = all(r8s==[1._R8P, 2._R8P, 3._R8P, 4._R8P, 5._R8P])
if (.not.is_passed(4)) print "(A,6I6)", 'contents: ', iostats(1:6)
