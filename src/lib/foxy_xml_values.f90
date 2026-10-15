!< FoXy typed values: conversion of attribute values and tag contents into numbers and logicals.
module foxy_xml_values
!< FoXy typed values: conversion of attribute values and tag contents into numbers and logicals.
!<
!< A text is a list of tokens separated by XML blanks. Each token is first checked against the characters of the
!< requested type: list-directed input gives a meaning to `,`, `/`, `r*` repeat counts and quotes, never accepted here.
!< The tokens are then converted by list-directed input, in segments of about *SEGMENT_LEN* characters (one read
!< statement per segment, records of bounded length).
!<
!< Logical values are the XML Schema ones: `true`, `false`, `1`, `0`.
use foxy_xml_entities, only : strip_blanks
use penf

implicit none
private
public :: report
public :: to_value
public :: to_values
public :: XML_BAD_VALUE
public :: XML_NOT_FOUND

integer(I4P), parameter :: XML_NOT_FOUND = 9002_I4P   !< *iostat* of a missing tag or attribute.
integer(I4P), parameter :: XML_BAD_VALUE = 9003_I4P   !< *iostat* of a value that is not of the requested type.
integer(I8P), parameter :: SEGMENT_LEN   = 65536_I8P  !< Length of the text segments converted by one read statement.
integer(I8P), parameter :: EXCERPT_LEN   = 32_I8P     !< Max length of a token quoted in a message.
character(*), parameter :: BLANKS        = ' '//achar(9)//achar(10)//achar(13) !< XML blanks: space, tab, new line, CR.
character(*), parameter :: INTEGER_CHARS = '+-0123456789' !< Characters of integer tokens.
character(*), parameter :: REAL_CHARS    = INTEGER_CHARS//'.eEdD'//'iInNfFaAtTyY' !< Characters of real tokens (Inf, NaN).

interface to_value
   !< Convert a text holding one value.
   module procedure to_value_I1P, to_value_I2P, to_value_I4P, to_value_I8P, to_value_R4P, to_value_R8P, to_value_logical
endinterface to_value

interface to_values
   !< Convert a text holding a list of values.
   module procedure to_values_I1P, to_values_I2P, to_values_I4P, to_values_I8P, to_values_R4P, to_values_R8P
endinterface to_values

contains
   pure subroutine report(iostat_, iomsg_, iostat, iomsg, context)
   !< Report a status (local variables) through the optional *iostat* and *iomsg* of a public procedure; the *context* of
   !< a value not converted (e.g. the attribute name) is appended to its message.
   !<
   !< @note *iomsg* is left unchanged on success.
   integer(I4P),           intent(in)    :: iostat_ !< IO status, local variable.
   character(*),           intent(in)    :: iomsg_  !< IO message, local variable.
   integer(I4P), optional, intent(out)   :: iostat  !< IO status.
   character(*), optional, intent(inout) :: iomsg   !< IO message.
   character(*), optional, intent(in)    :: context !< Context of the converted value.

   if (present(iostat)) iostat = iostat_
   if (present(iomsg).and.iostat_/=0) then
      if (present(context).and.iostat_==XML_BAD_VALUE) then
         iomsg = iomsg_//context
      else
         iomsg = iomsg_
      endif
   endif
   endsubroutine report

   pure subroutine to_value_logical(text, value, iostat, iomsg)
   !< Convert a text holding one logical value (`true`, `false`, `1`, `0`, blanks around); *value* is unchanged on error.
   character(*),                  intent(in)    :: text   !< Text.
   logical,                       intent(inout) :: value  !< Value.
   integer(I4P),                  intent(out)   :: iostat !< IO status.
   character(len=:), allocatable, intent(out)   :: iomsg  !< IO message.

   iostat = 0
   iomsg = ''
   select case(strip_blanks(text))
   case('true', '1')
      value = .true.
   case('false', '0')
      value = .false.
   case default
      iostat = XML_BAD_VALUE
      iomsg = 'invalid logical "'//excerpt(strip_blanks(text))//'"'
   endselect
   endsubroutine to_value_logical

   subroutine to_value_I1P(text, value, iostat, iomsg)
   !< Convert a text holding one integer(I1P) value; *value* is unchanged on error.
   character(*),                  intent(in)    :: text      !< Text.
   integer(I1P),                  intent(inout) :: value     !< Value.
   integer(I4P),                  intent(out)   :: iostat    !< IO status.
   character(len=:), allocatable, intent(out)   :: iomsg     !< IO message.
   integer(I1P), allocatable                    :: values(:) !< Values.

   call to_values(text=text, values=values, iostat=iostat, iomsg=iomsg)
   if (iostat/=0) return
   if (size(values, dim=1)==1) then
      value = values(1)
   else
      iostat = XML_BAD_VALUE
      iomsg = 'one integer value expected, found '//trim(str(size(values, dim=1), no_sign=.true.))
   endif
   endsubroutine to_value_I1P

   subroutine to_value_I2P(text, value, iostat, iomsg)
   !< Convert a text holding one integer(I2P) value; *value* is unchanged on error.
   character(*),                  intent(in)    :: text      !< Text.
   integer(I2P),                  intent(inout) :: value     !< Value.
   integer(I4P),                  intent(out)   :: iostat    !< IO status.
   character(len=:), allocatable, intent(out)   :: iomsg     !< IO message.
   integer(I2P), allocatable                    :: values(:) !< Values.

   call to_values(text=text, values=values, iostat=iostat, iomsg=iomsg)
   if (iostat/=0) return
   if (size(values, dim=1)==1) then
      value = values(1)
   else
      iostat = XML_BAD_VALUE
      iomsg = 'one integer value expected, found '//trim(str(size(values, dim=1), no_sign=.true.))
   endif
   endsubroutine to_value_I2P

   subroutine to_value_I4P(text, value, iostat, iomsg)
   !< Convert a text holding one integer(I4P) value; *value* is unchanged on error.
   character(*),                  intent(in)    :: text      !< Text.
   integer(I4P),                  intent(inout) :: value     !< Value.
   integer(I4P),                  intent(out)   :: iostat    !< IO status.
   character(len=:), allocatable, intent(out)   :: iomsg     !< IO message.
   integer(I4P), allocatable                    :: values(:) !< Values.

   call to_values(text=text, values=values, iostat=iostat, iomsg=iomsg)
   if (iostat/=0) return
   if (size(values, dim=1)==1) then
      value = values(1)
   else
      iostat = XML_BAD_VALUE
      iomsg = 'one integer value expected, found '//trim(str(size(values, dim=1), no_sign=.true.))
   endif
   endsubroutine to_value_I4P

   subroutine to_value_I8P(text, value, iostat, iomsg)
   !< Convert a text holding one integer(I8P) value; *value* is unchanged on error.
   character(*),                  intent(in)    :: text      !< Text.
   integer(I8P),                  intent(inout) :: value     !< Value.
   integer(I4P),                  intent(out)   :: iostat    !< IO status.
   character(len=:), allocatable, intent(out)   :: iomsg     !< IO message.
   integer(I8P), allocatable                    :: values(:) !< Values.

   call to_values(text=text, values=values, iostat=iostat, iomsg=iomsg)
   if (iostat/=0) return
   if (size(values, dim=1)==1) then
      value = values(1)
   else
      iostat = XML_BAD_VALUE
      iomsg = 'one integer value expected, found '//trim(str(size(values, dim=1), no_sign=.true.))
   endif
   endsubroutine to_value_I8P

   subroutine to_value_R4P(text, value, iostat, iomsg)
   !< Convert a text holding one real(R4P) value; *value* is unchanged on error.
   character(*),                  intent(in)    :: text      !< Text.
   real(R4P),                     intent(inout) :: value     !< Value.
   integer(I4P),                  intent(out)   :: iostat    !< IO status.
   character(len=:), allocatable, intent(out)   :: iomsg     !< IO message.
   real(R4P), allocatable                       :: values(:) !< Values.

   call to_values(text=text, values=values, iostat=iostat, iomsg=iomsg)
   if (iostat/=0) return
   if (size(values, dim=1)==1) then
      value = values(1)
   else
      iostat = XML_BAD_VALUE
      iomsg = 'one real value expected, found '//trim(str(size(values, dim=1), no_sign=.true.))
   endif
   endsubroutine to_value_R4P

   subroutine to_value_R8P(text, value, iostat, iomsg)
   !< Convert a text holding one real(R8P) value; *value* is unchanged on error.
   character(*),                  intent(in)    :: text      !< Text.
   real(R8P),                     intent(inout) :: value     !< Value.
   integer(I4P),                  intent(out)   :: iostat    !< IO status.
   character(len=:), allocatable, intent(out)   :: iomsg     !< IO message.
   real(R8P), allocatable                       :: values(:) !< Values.

   call to_values(text=text, values=values, iostat=iostat, iomsg=iomsg)
   if (iostat/=0) return
   if (size(values, dim=1)==1) then
      value = values(1)
   else
      iostat = XML_BAD_VALUE
      iomsg = 'one real value expected, found '//trim(str(size(values, dim=1), no_sign=.true.))
   endif
   endsubroutine to_value_R8P

   subroutine to_values_I1P(text, values, iostat, iomsg)
   !< Convert a text holding a list of integer(I1P) values; *values* is empty on error.
   character(*),                  intent(in)  :: text         !< Text.
   integer(I1P), allocatable,     intent(out) :: values(:)    !< Values.
   integer(I4P),                  intent(out) :: iostat       !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg        !< IO message.
   integer(I8P), allocatable                  :: segment(:,:) !< Segments: first, last position and number of tokens.
   integer(I1P)                               :: value        !< Value of a single token.
   integer(I8P), allocatable                  :: wide(:)      !< Values read as I8P, range checked (not all compilers
                                                              !< report an integer overflow in list-directed input).
   integer(I8P)                               :: wide_value   !< Value of a single token read as I8P.
   integer(I8P)                               :: n            !< Number of values.
   integer(I8P)                               :: first        !< First position of a token.
   integer(I8P)                               :: last         !< Last position of a token.
   integer(I8P)                               :: s            !< Counter.
   character(len=:), allocatable              :: chunk        !< Segment, blanks as spaces.

   call split(text=text, chars=INTEGER_CHARS, segment=segment, n=n, iostat=iostat, iomsg=iomsg)
   allocate(values(n))
   if (iostat/=0) return
   allocate(wide(max(1_I8P, maxval(segment(3, :)))))
   n = 0
   do s=1, size(segment, dim=2)
      if (segment(3, s)==0) cycle
      chunk = blanks_as_spaces(text(segment(1, s):segment(2, s)))
      read(chunk, *, iostat=iostat) wide(1:segment(3, s))
      if (iostat==0) then
         if (any(wide(1:segment(3, s))>huge(value).or.wide(1:segment(3, s))<-huge(value)-1_I1P)) then
            iostat = XML_BAD_VALUE
         else
            values(n+1:n+segment(3, s)) = int(wide(1:segment(3, s)), I1P)
         endif
      endif
      if (iostat/=0) then
         ! find the token not converted
         last = segment(1, s) - 1
         do
            call next_token(text=text(:segment(2, s)), last=last, first=first)
            if (first==0) exit
            read(text(first:last), *, iostat=iostat) wide_value
            if (iostat==0.and.(wide_value>huge(value).or.wide_value<-huge(value)-1_I1P)) iostat = XML_BAD_VALUE
            if (iostat/=0) exit
         enddo
         iostat = XML_BAD_VALUE
         if (first>0) then
            iomsg = 'invalid integer "'//excerpt(text(first:last))//'"'
         else
            iomsg = 'invalid integer values'
         endif
         deallocate(values)
         allocate(values(0))
         return
      endif
      n = n + segment(3, s)
   enddo
   endsubroutine to_values_I1P

   subroutine to_values_I2P(text, values, iostat, iomsg)
   !< Convert a text holding a list of integer(I2P) values; *values* is empty on error.
   character(*),                  intent(in)  :: text         !< Text.
   integer(I2P), allocatable,     intent(out) :: values(:)    !< Values.
   integer(I4P),                  intent(out) :: iostat       !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg        !< IO message.
   integer(I8P), allocatable                  :: segment(:,:) !< Segments: first, last position and number of tokens.
   integer(I2P)                               :: value        !< Value of a single token.
   integer(I8P), allocatable                  :: wide(:)      !< Values read as I8P, range checked (not all compilers
                                                              !< report an integer overflow in list-directed input).
   integer(I8P)                               :: wide_value   !< Value of a single token read as I8P.
   integer(I8P)                               :: n            !< Number of values.
   integer(I8P)                               :: first        !< First position of a token.
   integer(I8P)                               :: last         !< Last position of a token.
   integer(I8P)                               :: s            !< Counter.
   character(len=:), allocatable              :: chunk        !< Segment, blanks as spaces.

   call split(text=text, chars=INTEGER_CHARS, segment=segment, n=n, iostat=iostat, iomsg=iomsg)
   allocate(values(n))
   if (iostat/=0) return
   allocate(wide(max(1_I8P, maxval(segment(3, :)))))
   n = 0
   do s=1, size(segment, dim=2)
      if (segment(3, s)==0) cycle
      chunk = blanks_as_spaces(text(segment(1, s):segment(2, s)))
      read(chunk, *, iostat=iostat) wide(1:segment(3, s))
      if (iostat==0) then
         if (any(wide(1:segment(3, s))>huge(value).or.wide(1:segment(3, s))<-huge(value)-1_I2P)) then
            iostat = XML_BAD_VALUE
         else
            values(n+1:n+segment(3, s)) = int(wide(1:segment(3, s)), I2P)
         endif
      endif
      if (iostat/=0) then
         ! find the token not converted
         last = segment(1, s) - 1
         do
            call next_token(text=text(:segment(2, s)), last=last, first=first)
            if (first==0) exit
            read(text(first:last), *, iostat=iostat) wide_value
            if (iostat==0.and.(wide_value>huge(value).or.wide_value<-huge(value)-1_I2P)) iostat = XML_BAD_VALUE
            if (iostat/=0) exit
         enddo
         iostat = XML_BAD_VALUE
         if (first>0) then
            iomsg = 'invalid integer "'//excerpt(text(first:last))//'"'
         else
            iomsg = 'invalid integer values'
         endif
         deallocate(values)
         allocate(values(0))
         return
      endif
      n = n + segment(3, s)
   enddo
   endsubroutine to_values_I2P

   subroutine to_values_I4P(text, values, iostat, iomsg)
   !< Convert a text holding a list of integer(I4P) values; *values* is empty on error.
   character(*),                  intent(in)  :: text         !< Text.
   integer(I4P), allocatable,     intent(out) :: values(:)    !< Values.
   integer(I4P),                  intent(out) :: iostat       !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg        !< IO message.
   integer(I8P), allocatable                  :: segment(:,:) !< Segments: first, last position and number of tokens.
   integer(I4P)                               :: value        !< Value of a single token.
   integer(I8P), allocatable                  :: wide(:)      !< Values read as I8P, range checked (not all compilers
                                                              !< report an integer overflow in list-directed input).
   integer(I8P)                               :: wide_value   !< Value of a single token read as I8P.
   integer(I8P)                               :: n            !< Number of values.
   integer(I8P)                               :: first        !< First position of a token.
   integer(I8P)                               :: last         !< Last position of a token.
   integer(I8P)                               :: s            !< Counter.
   character(len=:), allocatable              :: chunk        !< Segment, blanks as spaces.

   call split(text=text, chars=INTEGER_CHARS, segment=segment, n=n, iostat=iostat, iomsg=iomsg)
   allocate(values(n))
   if (iostat/=0) return
   allocate(wide(max(1_I8P, maxval(segment(3, :)))))
   n = 0
   do s=1, size(segment, dim=2)
      if (segment(3, s)==0) cycle
      chunk = blanks_as_spaces(text(segment(1, s):segment(2, s)))
      read(chunk, *, iostat=iostat) wide(1:segment(3, s))
      if (iostat==0) then
         if (any(wide(1:segment(3, s))>huge(value).or.wide(1:segment(3, s))<-huge(value)-1_I4P)) then
            iostat = XML_BAD_VALUE
         else
            values(n+1:n+segment(3, s)) = int(wide(1:segment(3, s)), I4P)
         endif
      endif
      if (iostat/=0) then
         ! find the token not converted
         last = segment(1, s) - 1
         do
            call next_token(text=text(:segment(2, s)), last=last, first=first)
            if (first==0) exit
            read(text(first:last), *, iostat=iostat) wide_value
            if (iostat==0.and.(wide_value>huge(value).or.wide_value<-huge(value)-1_I4P)) iostat = XML_BAD_VALUE
            if (iostat/=0) exit
         enddo
         iostat = XML_BAD_VALUE
         if (first>0) then
            iomsg = 'invalid integer "'//excerpt(text(first:last))//'"'
         else
            iomsg = 'invalid integer values'
         endif
         deallocate(values)
         allocate(values(0))
         return
      endif
      n = n + segment(3, s)
   enddo
   endsubroutine to_values_I4P

   subroutine to_values_I8P(text, values, iostat, iomsg)
   !< Convert a text holding a list of integer(I8P) values; *values* is empty on error.
   character(*),                  intent(in)  :: text         !< Text.
   integer(I8P), allocatable,     intent(out) :: values(:)    !< Values.
   integer(I4P),                  intent(out) :: iostat       !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg        !< IO message.
   integer(I8P), allocatable                  :: segment(:,:) !< Segments: first, last position and number of tokens.
   integer(I8P)                               :: value        !< Value of a single token.
   integer(I8P)                               :: n            !< Number of values.
   integer(I8P)                               :: first        !< First position of a token.
   integer(I8P)                               :: last         !< Last position of a token.
   integer(I8P)                               :: s            !< Counter.
   character(len=:), allocatable              :: chunk        !< Segment, blanks as spaces.

   call split(text=text, chars=INTEGER_CHARS, segment=segment, n=n, iostat=iostat, iomsg=iomsg)
   allocate(values(n))
   if (iostat/=0) return
   n = 0
   do s=1, size(segment, dim=2)
      if (segment(3, s)==0) cycle
      chunk = blanks_as_spaces(text(segment(1, s):segment(2, s)))
      read(chunk, *, iostat=iostat) values(n+1:n+segment(3, s))
      if (iostat/=0) then
         ! find the token not converted
         last = segment(1, s) - 1
         do
            call next_token(text=text(:segment(2, s)), last=last, first=first)
            if (first==0) exit
            read(text(first:last), *, iostat=iostat) value
            if (iostat/=0) exit
         enddo
         iostat = XML_BAD_VALUE
         if (first>0) then
            iomsg = 'invalid integer "'//excerpt(text(first:last))//'"'
         else
            iomsg = 'invalid integer values'
         endif
         deallocate(values)
         allocate(values(0))
         return
      endif
      n = n + segment(3, s)
   enddo
   endsubroutine to_values_I8P

   subroutine to_values_R4P(text, values, iostat, iomsg)
   !< Convert a text holding a list of real(R4P) values; *values* is empty on error.
   character(*),                  intent(in)  :: text         !< Text.
   real(R4P), allocatable,        intent(out) :: values(:)    !< Values.
   integer(I4P),                  intent(out) :: iostat       !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg        !< IO message.
   integer(I8P), allocatable                  :: segment(:,:) !< Segments: first, last position and number of tokens.
   real(R4P)                                  :: value        !< Value of a single token.
   integer(I8P)                               :: n            !< Number of values.
   integer(I8P)                               :: first        !< First position of a token.
   integer(I8P)                               :: last         !< Last position of a token.
   integer(I8P)                               :: s            !< Counter.
   character(len=:), allocatable              :: chunk        !< Segment, blanks as spaces.

   call split(text=text, chars=REAL_CHARS, segment=segment, n=n, iostat=iostat, iomsg=iomsg)
   allocate(values(n))
   if (iostat/=0) return
   n = 0
   do s=1, size(segment, dim=2)
      if (segment(3, s)==0) cycle
      chunk = blanks_as_spaces(text(segment(1, s):segment(2, s)))
      read(chunk, *, iostat=iostat) values(n+1:n+segment(3, s))
      if (iostat/=0) then
         ! find the token not converted
         last = segment(1, s) - 1
         do
            call next_token(text=text(:segment(2, s)), last=last, first=first)
            if (first==0) exit
            read(text(first:last), *, iostat=iostat) value
            if (iostat/=0) exit
         enddo
         iostat = XML_BAD_VALUE
         if (first>0) then
            iomsg = 'invalid real "'//excerpt(text(first:last))//'"'
         else
            iomsg = 'invalid real values'
         endif
         deallocate(values)
         allocate(values(0))
         return
      endif
      n = n + segment(3, s)
   enddo
   endsubroutine to_values_R4P

   subroutine to_values_R8P(text, values, iostat, iomsg)
   !< Convert a text holding a list of real(R8P) values; *values* is empty on error.
   character(*),                  intent(in)  :: text         !< Text.
   real(R8P), allocatable,        intent(out) :: values(:)    !< Values.
   integer(I4P),                  intent(out) :: iostat       !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg        !< IO message.
   integer(I8P), allocatable                  :: segment(:,:) !< Segments: first, last position and number of tokens.
   real(R8P)                                  :: value        !< Value of a single token.
   integer(I8P)                               :: n            !< Number of values.
   integer(I8P)                               :: first        !< First position of a token.
   integer(I8P)                               :: last         !< Last position of a token.
   integer(I8P)                               :: s            !< Counter.
   character(len=:), allocatable              :: chunk        !< Segment, blanks as spaces.

   call split(text=text, chars=REAL_CHARS, segment=segment, n=n, iostat=iostat, iomsg=iomsg)
   allocate(values(n))
   if (iostat/=0) return
   n = 0
   do s=1, size(segment, dim=2)
      if (segment(3, s)==0) cycle
      chunk = blanks_as_spaces(text(segment(1, s):segment(2, s)))
      read(chunk, *, iostat=iostat) values(n+1:n+segment(3, s))
      if (iostat/=0) then
         ! find the token not converted
         last = segment(1, s) - 1
         do
            call next_token(text=text(:segment(2, s)), last=last, first=first)
            if (first==0) exit
            read(text(first:last), *, iostat=iostat) value
            if (iostat/=0) exit
         enddo
         iostat = XML_BAD_VALUE
         if (first>0) then
            iomsg = 'invalid real "'//excerpt(text(first:last))//'"'
         else
            iomsg = 'invalid real values'
         endif
         deallocate(values)
         allocate(values(0))
         return
      endif
      n = n + segment(3, s)
   enddo
   endsubroutine to_values_R8P

   ! private procedures
   pure function blanks_as_spaces(string) result(spaced)
   !< Return a string with its tabs, new lines and carriage returns as spaces: list-directed input separates values by
   !< blanks only (other characters are processor dependent, e.g. new lines are not separators for ifx).
   character(*), intent(in)      :: string !< String.
   character(len=:), allocatable :: spaced !< String with spaces as blanks.
   integer(I8P)                  :: p      !< Position.

   spaced = string
   if (scan(string, BLANKS(2:), kind=I8P)==0) return
   do p=1, len(spaced, kind=I8P)
      if (spaced(p:p)==achar(9).or.spaced(p:p)==achar(10).or.spaced(p:p)==achar(13)) spaced(p:p) = ' '
   enddo
   endfunction blanks_as_spaces

   pure function excerpt(token) result(quoted)
   !< Return a token, cut to *EXCERPT_LEN* characters, to quote it in a message.
   character(*), intent(in)      :: token  !< Token.
   character(len=:), allocatable :: quoted !< Token excerpt.

   if (len(token, kind=I8P)>EXCERPT_LEN) then
      quoted = token(1:EXCERPT_LEN)//'...'
   else
      quoted = token
   endif
   endfunction excerpt

   pure subroutine next_token(text, last, first)
   !< Find the next token of a text after the position *last*: *first* and *last* are its positions, *first* is 0 if there
   !< are no more tokens.
   character(*), intent(in)    :: text  !< Text.
   integer(I8P), intent(inout) :: last  !< Last position of the previous token on input, of the next token on output.
   integer(I8P), intent(out)   :: first !< First position of the next token, 0 if none.
   integer(I8P)                :: p     !< Position.

   first = 0
   if (last>=len(text, kind=I8P)) return
   p = verify(text(last+1:), BLANKS, kind=I8P)
   if (p==0) return
   first = last + p
   p = scan(text(first:), BLANKS, kind=I8P)
   if (p==0) then
      last = len(text, kind=I8P)
   else
      last = first + p - 2
   endif
   endsubroutine next_token

   pure subroutine split(text, chars, segment, n, iostat, iomsg)
   !< Check the characters of the tokens of a text and split it in segments of about *SEGMENT_LEN* characters, cut at
   !< blanks, counting their tokens (a single pass over the text).
   character(*),                  intent(in)  :: text            !< Text.
   character(*),                  intent(in)  :: chars           !< Characters allowed in the tokens.
   integer(I8P), allocatable,     intent(out) :: segment(:,:)    !< Segments: first, last position and number of tokens.
   integer(I8P),                  intent(out) :: n               !< Number of tokens.
   integer(I4P),                  intent(out) :: iostat          !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg           !< IO message.
   logical                                    :: is_blank(0:255) !< Table of the blank characters.
   logical                                    :: is_token(0:255) !< Table of the characters allowed in the tokens.
   logical                                    :: is_in_token     !< The current character is in a token.
   integer(I8P)                               :: text_len        !< Text length.
   integer(I8P)                               :: first           !< First position of the token not allowed.
   integer(I8P)                               :: last            !< Last position of the token not allowed.
   integer(I8P)                               :: p               !< Position.
   integer(I8P)                               :: s               !< Counter.
   integer(I4P)                               :: code            !< Character code.

   iostat = 0
   iomsg = ''
   is_blank = .false.
   do p=1, len(BLANKS)
      is_blank(iand(ichar(BLANKS(p:p)), 255)) = .true.
   enddo
   is_token = .false.
   do p=1, len(chars)
      is_token(iand(ichar(chars(p:p)), 255)) = .true.
   enddo
   text_len = len(text, kind=I8P)
   allocate(segment(3, text_len / SEGMENT_LEN + 1))
   segment = 0
   n = 0
   s = 1
   segment(1, s) = 1
   is_in_token = .false.
   do p=1, text_len
      code = iand(ichar(text(p:p)), 255)
      if (is_blank(code)) then
         is_in_token = .false.
         if (p - segment(1, s)>=SEGMENT_LEN) then ! the segment is long enough: cut it at this blank
            segment(2, s) = p
            s = s + 1
            segment(1, s) = p + 1
         endif
      elseif (is_token(code)) then
         if (.not.is_in_token) then
            is_in_token = .true.
            segment(3, s) = segment(3, s) + 1
            n = n + 1
         endif
      else
         first = scan(text(:p), BLANKS, back=.true., kind=I8P) + 1
         last = scan(text(p:), BLANKS, kind=I8P)
         if (last==0) then
            last = text_len
         else
            last = p + last - 2
         endif
         iostat = XML_BAD_VALUE
         iomsg = 'invalid character "'//text(p:p)//'" in "'//excerpt(text(first:last))//'"'
         n = 0
         deallocate(segment)
         allocate(segment(3, 0))
         return
      endif
   enddo
   segment(2, s) = text_len
   segment = segment(:, 1:s)
   endsubroutine split
endmodule foxy_xml_values
