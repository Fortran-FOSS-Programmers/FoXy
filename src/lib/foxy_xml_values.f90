!< FoXy typed values: conversion of attribute values and tag contents into numbers and logicals.
module foxy_xml_values
!< FoXy typed values: conversion of attribute values and tag contents into numbers and logicals.
!<
!< A text is a list of tokens separated by XML blanks. Each token is converted by StringiFor (`string%read_number`:
!< correctly rounded, exact range checks, no `read` statement, the same results with every compiler). An integer token
!< must also be digits with an optional sign, as an XML integer: StringiFor would read `1e3` as 1000.
!<
!< Logical values are the XML Schema ones: `true`, `false`, `1`, `0`.
use foxy_xml_entities, only : strip_blanks
use penf
use stringifor, only : shortest, string

implicit none
private
public :: report
public :: to_text
public :: to_value
public :: to_values
public :: XML_BAD_VALUE
public :: XML_NOT_FOUND

integer(I4P), parameter :: XML_NOT_FOUND = 9002_I4P   !< *iostat* of a missing tag or attribute.
integer(I4P), parameter :: XML_BAD_VALUE = 9003_I4P   !< *iostat* of a value that is not of the requested type.
integer(I8P), parameter :: EXCERPT_LEN   = 32_I8P     !< Max length of a token quoted in a message.
character(*), parameter :: BLANKS        = ' '//achar(9)//achar(10)//achar(13) !< XML blanks: space, tab, new line, CR.
integer,      parameter :: FORMATTED_LEN = 128      !< Length of the buffer of a value formatted by *fmt*.
character(*), parameter :: INTEGER_CHARS = '+-0123456789' !< Characters of integer tokens (XML integers).

interface to_value
   !< Convert a text holding one value.
   module procedure to_value_I1P, to_value_I2P, to_value_I4P, to_value_I8P, to_value_R4P, to_value_R8P, to_value_logical
endinterface to_value

interface to_values
   !< Convert a text holding a list of values.
   module procedure to_values_I1P, to_values_I2P, to_values_I4P, to_values_I8P, to_values_R4P, to_values_R8P
endinterface to_values

interface to_text
   !< Convert a value, or a list of values, into text.
   module procedure to_text_I1P, to_text_I2P, to_text_I4P, to_text_I8P, to_text_R4P, to_text_R8P, to_text_logical, &
                    to_text_I1P_1, to_text_I2P_1, to_text_I4P_1, to_text_I8P_1, to_text_R4P_1, to_text_R8P_1
endinterface to_text

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

   pure subroutine to_value_I1P(text, value, iostat, iomsg)
   !< Convert a text holding one integer(I1P) value; *value* is unchanged on error.
   character(*),                  intent(in)    :: text      !< Text.
   integer(I1P),                 intent(inout) :: value     !< Value.
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

   pure subroutine to_value_I2P(text, value, iostat, iomsg)
   !< Convert a text holding one integer(I2P) value; *value* is unchanged on error.
   character(*),                  intent(in)    :: text      !< Text.
   integer(I2P),                 intent(inout) :: value     !< Value.
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

   pure subroutine to_value_I4P(text, value, iostat, iomsg)
   !< Convert a text holding one integer(I4P) value; *value* is unchanged on error.
   character(*),                  intent(in)    :: text      !< Text.
   integer(I4P),                 intent(inout) :: value     !< Value.
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

   pure subroutine to_value_I8P(text, value, iostat, iomsg)
   !< Convert a text holding one integer(I8P) value; *value* is unchanged on error.
   character(*),                  intent(in)    :: text      !< Text.
   integer(I8P),                 intent(inout) :: value     !< Value.
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

   pure subroutine to_value_R4P(text, value, iostat, iomsg)
   !< Convert a text holding one real(R4P) value; *value* is unchanged on error.
   character(*),                  intent(in)    :: text      !< Text.
   real(R4P),                    intent(inout) :: value     !< Value.
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

   pure subroutine to_value_R8P(text, value, iostat, iomsg)
   !< Convert a text holding one real(R8P) value; *value* is unchanged on error.
   character(*),                  intent(in)    :: text      !< Text.
   real(R8P),                    intent(inout) :: value     !< Value.
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

   pure subroutine to_values_I1P(text, values, iostat, iomsg)
   !< Convert a text holding a list of integer(I1P) values; *values* is empty on error.
   character(*),                  intent(in)  :: text        !< Text.
   integer(I1P), allocatable,    intent(out) :: values(:)   !< Values.
   integer(I4P),                  intent(out) :: iostat      !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg       !< IO message.
   type(string)                               :: token       !< Current token.
   integer                                    :: read_status !< Status of a token conversion.
   integer(I8P)                               :: n           !< Number of values.
   integer(I8P)                               :: first       !< First position of a token.
   integer(I8P)                               :: last        !< Last position of a token.

   iostat = 0
   iomsg = ''
   allocate(values(tokens_number(text)))
   n = 0
   last = 0
   do
      call next_token(text=text, last=last, first=first)
      if (first==0) exit
      n = n + 1
      if (verify(text(first:last), INTEGER_CHARS)>0) then ! an XML integer: digits and a sign only
         call fail(text=text(first:last), what='integer', iostat=iostat, iomsg=iomsg)
         deallocate(values)
         allocate(values(0))
         return
      endif
      token = text(first:last)
      call token%read_number(values(n), iostat=read_status)
      if (read_status/=0) then
         call fail(text=text(first:last), what='integer', iostat=iostat, iomsg=iomsg)
         deallocate(values)
         allocate(values(0))
         return
      endif
   enddo
   endsubroutine to_values_I1P

   pure subroutine to_values_I2P(text, values, iostat, iomsg)
   !< Convert a text holding a list of integer(I2P) values; *values* is empty on error.
   character(*),                  intent(in)  :: text        !< Text.
   integer(I2P), allocatable,    intent(out) :: values(:)   !< Values.
   integer(I4P),                  intent(out) :: iostat      !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg       !< IO message.
   type(string)                               :: token       !< Current token.
   integer(I4P)                               :: wide        !< Value read as I4P, range checked.
   integer                                    :: read_status !< Status of a token conversion.
   integer(I8P)                               :: n           !< Number of values.
   integer(I8P)                               :: first       !< First position of a token.
   integer(I8P)                               :: last        !< Last position of a token.

   iostat = 0
   iomsg = ''
   allocate(values(tokens_number(text)))
   n = 0
   last = 0
   do
      call next_token(text=text, last=last, first=first)
      if (first==0) exit
      n = n + 1
      if (verify(text(first:last), INTEGER_CHARS)>0) then ! an XML integer: digits and a sign only
         call fail(text=text(first:last), what='integer', iostat=iostat, iomsg=iomsg)
         deallocate(values)
         allocate(values(0))
         return
      endif
      token = text(first:last)
      call token%read_number(wide, iostat=read_status)   ! I2P through I4P: StringiFor has no I2P reader with nvfortran
      if (read_status==0.and.(wide>huge(values).or.wide<-huge(values)-1_I2P)) read_status = 1
      if (read_status==0) values(n) = int(wide, I2P)
      if (read_status/=0) then
         call fail(text=text(first:last), what='integer', iostat=iostat, iomsg=iomsg)
         deallocate(values)
         allocate(values(0))
         return
      endif
   enddo
   endsubroutine to_values_I2P

   pure subroutine to_values_I4P(text, values, iostat, iomsg)
   !< Convert a text holding a list of integer(I4P) values; *values* is empty on error.
   character(*),                  intent(in)  :: text        !< Text.
   integer(I4P), allocatable,    intent(out) :: values(:)   !< Values.
   integer(I4P),                  intent(out) :: iostat      !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg       !< IO message.
   type(string)                               :: token       !< Current token.
   integer                                    :: read_status !< Status of a token conversion.
   integer(I8P)                               :: n           !< Number of values.
   integer(I8P)                               :: first       !< First position of a token.
   integer(I8P)                               :: last        !< Last position of a token.

   iostat = 0
   iomsg = ''
   allocate(values(tokens_number(text)))
   n = 0
   last = 0
   do
      call next_token(text=text, last=last, first=first)
      if (first==0) exit
      n = n + 1
      if (verify(text(first:last), INTEGER_CHARS)>0) then ! an XML integer: digits and a sign only
         call fail(text=text(first:last), what='integer', iostat=iostat, iomsg=iomsg)
         deallocate(values)
         allocate(values(0))
         return
      endif
      token = text(first:last)
      call token%read_number(values(n), iostat=read_status)
      if (read_status/=0) then
         call fail(text=text(first:last), what='integer', iostat=iostat, iomsg=iomsg)
         deallocate(values)
         allocate(values(0))
         return
      endif
   enddo
   endsubroutine to_values_I4P

   pure subroutine to_values_I8P(text, values, iostat, iomsg)
   !< Convert a text holding a list of integer(I8P) values; *values* is empty on error.
   character(*),                  intent(in)  :: text        !< Text.
   integer(I8P), allocatable,    intent(out) :: values(:)   !< Values.
   integer(I4P),                  intent(out) :: iostat      !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg       !< IO message.
   type(string)                               :: token       !< Current token.
   integer                                    :: read_status !< Status of a token conversion.
   integer(I8P)                               :: n           !< Number of values.
   integer(I8P)                               :: first       !< First position of a token.
   integer(I8P)                               :: last        !< Last position of a token.

   iostat = 0
   iomsg = ''
   allocate(values(tokens_number(text)))
   n = 0
   last = 0
   do
      call next_token(text=text, last=last, first=first)
      if (first==0) exit
      n = n + 1
      if (verify(text(first:last), INTEGER_CHARS)>0) then ! an XML integer: digits and a sign only
         call fail(text=text(first:last), what='integer', iostat=iostat, iomsg=iomsg)
         deallocate(values)
         allocate(values(0))
         return
      endif
      token = text(first:last)
      call token%read_number(values(n), iostat=read_status)
      if (read_status/=0) then
         call fail(text=text(first:last), what='integer', iostat=iostat, iomsg=iomsg)
         deallocate(values)
         allocate(values(0))
         return
      endif
   enddo
   endsubroutine to_values_I8P

   pure subroutine to_values_R4P(text, values, iostat, iomsg)
   !< Convert a text holding a list of real(R4P) values; *values* is empty on error.
   character(*),                  intent(in)  :: text        !< Text.
   real(R4P), allocatable,       intent(out) :: values(:)   !< Values.
   integer(I4P),                  intent(out) :: iostat      !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg       !< IO message.
   type(string)                               :: token       !< Current token.
   integer                                    :: read_status !< Status of a token conversion.
   integer(I8P)                               :: n           !< Number of values.
   integer(I8P)                               :: first       !< First position of a token.
   integer(I8P)                               :: last        !< Last position of a token.

   iostat = 0
   iomsg = ''
   allocate(values(tokens_number(text)))
   n = 0
   last = 0
   do
      call next_token(text=text, last=last, first=first)
      if (first==0) exit
      n = n + 1
      token = text(first:last)
      call token%read_number(values(n), iostat=read_status)
      if (read_status/=0) then
         call fail(text=text(first:last), what='real', iostat=iostat, iomsg=iomsg)
         deallocate(values)
         allocate(values(0))
         return
      endif
   enddo
   endsubroutine to_values_R4P

   pure subroutine to_values_R8P(text, values, iostat, iomsg)
   !< Convert a text holding a list of real(R8P) values; *values* is empty on error.
   character(*),                  intent(in)  :: text        !< Text.
   real(R8P), allocatable,       intent(out) :: values(:)   !< Values.
   integer(I4P),                  intent(out) :: iostat      !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg       !< IO message.
   type(string)                               :: token       !< Current token.
   integer                                    :: read_status !< Status of a token conversion.
   integer(I8P)                               :: n           !< Number of values.
   integer(I8P)                               :: first       !< First position of a token.
   integer(I8P)                               :: last        !< Last position of a token.

   iostat = 0
   iomsg = ''
   allocate(values(tokens_number(text)))
   n = 0
   last = 0
   do
      call next_token(text=text, last=last, first=first)
      if (first==0) exit
      n = n + 1
      token = text(first:last)
      call token%read_number(values(n), iostat=read_status)
      if (read_status/=0) then
         call fail(text=text(first:last), what='real', iostat=iostat, iomsg=iomsg)
         deallocate(values)
         allocate(values(0))
         return
      endif
   enddo
   endsubroutine to_values_R8P

   pure subroutine to_text_I1P(value, text, fmt, iostat, iomsg)
   !< Convert an integer(I1P) value into text: its digits, with a sign only if negative, or as formatted by *fmt*.
   integer(I1P),         intent(in)  :: value     !< Value.
   character(len=:), allocatable, intent(out) :: text      !< Text.
   character(*), optional,        intent(in)  :: fmt       !< Format, e.g. `(F6.3)`.
   integer(I4P),                  intent(out) :: iostat    !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg     !< IO message.
   character(len=FORMATTED_LEN)               :: buffer    !< Formatted value.
   integer                                    :: ios       !< Status of the formatted write.

   iostat = 0
   iomsg = ''
   if (present(fmt)) then
      write(buffer, fmt, iostat=ios) value
      if (ios==0) ios = merge(1, 0, is_overflow(buffer)) ! asterisks: the value does not fit (ifx also writes them
      if (ios/=0) then                                    ! for a real with an I edit descriptor)
         iostat = XML_BAD_VALUE
         iomsg = 'cannot write a integer with the format "'//fmt//'"'
         text = ''
         return
      endif
      text = trim(adjustl(buffer))
   else
      text = trim(adjustl(str(value, no_sign=value>=0_I1P)))
   endif
   endsubroutine to_text_I1P

   pure subroutine to_text_I2P(value, text, fmt, iostat, iomsg)
   !< Convert an integer(I2P) value into text: its digits, with a sign only if negative, or as formatted by *fmt*.
   integer(I2P),         intent(in)  :: value     !< Value.
   character(len=:), allocatable, intent(out) :: text      !< Text.
   character(*), optional,        intent(in)  :: fmt       !< Format, e.g. `(F6.3)`.
   integer(I4P),                  intent(out) :: iostat    !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg     !< IO message.
   character(len=FORMATTED_LEN)               :: buffer    !< Formatted value.
   integer                                    :: ios       !< Status of the formatted write.

   iostat = 0
   iomsg = ''
   if (present(fmt)) then
      write(buffer, fmt, iostat=ios) value
      if (ios==0) ios = merge(1, 0, is_overflow(buffer)) ! asterisks: the value does not fit (ifx also writes them
      if (ios/=0) then                                    ! for a real with an I edit descriptor)
         iostat = XML_BAD_VALUE
         iomsg = 'cannot write a integer with the format "'//fmt//'"'
         text = ''
         return
      endif
      text = trim(adjustl(buffer))
   else
      text = trim(adjustl(str(value, no_sign=value>=0_I2P)))
   endif
   endsubroutine to_text_I2P

   pure subroutine to_text_I4P(value, text, fmt, iostat, iomsg)
   !< Convert an integer(I4P) value into text: its digits, with a sign only if negative, or as formatted by *fmt*.
   integer(I4P),         intent(in)  :: value     !< Value.
   character(len=:), allocatable, intent(out) :: text      !< Text.
   character(*), optional,        intent(in)  :: fmt       !< Format, e.g. `(F6.3)`.
   integer(I4P),                  intent(out) :: iostat    !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg     !< IO message.
   character(len=FORMATTED_LEN)               :: buffer    !< Formatted value.
   integer                                    :: ios       !< Status of the formatted write.

   iostat = 0
   iomsg = ''
   if (present(fmt)) then
      write(buffer, fmt, iostat=ios) value
      if (ios==0) ios = merge(1, 0, is_overflow(buffer)) ! asterisks: the value does not fit (ifx also writes them
      if (ios/=0) then                                    ! for a real with an I edit descriptor)
         iostat = XML_BAD_VALUE
         iomsg = 'cannot write a integer with the format "'//fmt//'"'
         text = ''
         return
      endif
      text = trim(adjustl(buffer))
   else
      text = trim(adjustl(str(value, no_sign=value>=0_I4P)))
   endif
   endsubroutine to_text_I4P

   pure subroutine to_text_I8P(value, text, fmt, iostat, iomsg)
   !< Convert an integer(I8P) value into text: its digits, with a sign only if negative, or as formatted by *fmt*.
   integer(I8P),         intent(in)  :: value     !< Value.
   character(len=:), allocatable, intent(out) :: text      !< Text.
   character(*), optional,        intent(in)  :: fmt       !< Format, e.g. `(F6.3)`.
   integer(I4P),                  intent(out) :: iostat    !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg     !< IO message.
   character(len=FORMATTED_LEN)               :: buffer    !< Formatted value.
   integer                                    :: ios       !< Status of the formatted write.

   iostat = 0
   iomsg = ''
   if (present(fmt)) then
      write(buffer, fmt, iostat=ios) value
      if (ios==0) ios = merge(1, 0, is_overflow(buffer)) ! asterisks: the value does not fit (ifx also writes them
      if (ios/=0) then                                    ! for a real with an I edit descriptor)
         iostat = XML_BAD_VALUE
         iomsg = 'cannot write a integer with the format "'//fmt//'"'
         text = ''
         return
      endif
      text = trim(adjustl(buffer))
   else
      text = trim(adjustl(str(value, no_sign=value>=0_I8P)))
   endif
   endsubroutine to_text_I8P

   pure subroutine to_text_R4P(value, text, fmt, iostat, iomsg)
   !< Convert a real(R4P) value into text: the shortest one that reads back exactly (StringiFor `shortest`), or as
   !< formatted by *fmt*.
   real(R4P),            intent(in)  :: value     !< Value.
   character(len=:), allocatable, intent(out) :: text      !< Text.
   character(*), optional,        intent(in)  :: fmt       !< Format, e.g. `(F6.3)`.
   integer(I4P),                  intent(out) :: iostat    !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg     !< IO message.
   character(len=FORMATTED_LEN)               :: buffer    !< Formatted value.
   type(string)                               :: as_string !< Shortest text, as a string.
   integer                                    :: ios       !< Status of the formatted write.

   iostat = 0
   iomsg = ''
   if (present(fmt)) then
      write(buffer, fmt, iostat=ios) value
      if (ios==0) ios = merge(1, 0, is_overflow(buffer)) ! asterisks: the value does not fit (ifx also writes them
      if (ios/=0) then                                    ! for a real with an I edit descriptor)
         iostat = XML_BAD_VALUE
         iomsg = 'cannot write a real with the format "'//fmt//'"'
         text = ''
         return
      endif
      text = trim(adjustl(buffer))
   else
      as_string = shortest(value)
      text = as_string%chars()
   endif
   endsubroutine to_text_R4P

   pure subroutine to_text_R8P(value, text, fmt, iostat, iomsg)
   !< Convert a real(R8P) value into text: the shortest one that reads back exactly (StringiFor `shortest`), or as
   !< formatted by *fmt*.
   real(R8P),            intent(in)  :: value     !< Value.
   character(len=:), allocatable, intent(out) :: text      !< Text.
   character(*), optional,        intent(in)  :: fmt       !< Format, e.g. `(F6.3)`.
   integer(I4P),                  intent(out) :: iostat    !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg     !< IO message.
   character(len=FORMATTED_LEN)               :: buffer    !< Formatted value.
   type(string)                               :: as_string !< Shortest text, as a string.
   integer                                    :: ios       !< Status of the formatted write.

   iostat = 0
   iomsg = ''
   if (present(fmt)) then
      write(buffer, fmt, iostat=ios) value
      if (ios==0) ios = merge(1, 0, is_overflow(buffer)) ! asterisks: the value does not fit (ifx also writes them
      if (ios/=0) then                                    ! for a real with an I edit descriptor)
         iostat = XML_BAD_VALUE
         iomsg = 'cannot write a real with the format "'//fmt//'"'
         text = ''
         return
      endif
      text = trim(adjustl(buffer))
   else
      as_string = shortest(value)
      text = as_string%chars()
   endif
   endsubroutine to_text_R8P

   pure subroutine to_text_logical(value, text, iostat, iomsg)
   !< Convert a logical value into text: `true` or `false`.
   logical,                       intent(in)  :: value  !< Value.
   character(len=:), allocatable, intent(out) :: text   !< Text.
   integer(I4P),                  intent(out) :: iostat !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg  !< IO message.

   iostat = 0
   iomsg = ''
   if (value) then
      text = 'true'
   else
      text = 'false'
   endif
   endsubroutine to_text_logical

   pure subroutine to_text_I1P_1(value, text, fmt, iostat, iomsg)
   !< Convert a list of integer(I1P) values into text, separated by one space (each as *to_text* of a scalar).
   integer(I1P),         intent(in)  :: value(:) !< Values.
   character(len=:), allocatable, intent(out) :: text     !< Text.
   character(*), optional,        intent(in)  :: fmt      !< Format of each value, e.g. `(F6.3)`.
   integer(I4P),                  intent(out) :: iostat   !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg    !< IO message.
   character(len=:), allocatable              :: item     !< Text of one value.
   character(len=:), allocatable              :: buffer   !< Text being built, grown geometrically.
   integer(I8P)                               :: n        !< Used length of the buffer.
   integer(I8P)                               :: v        !< Counter.

   iostat = 0
   iomsg = ''
   allocate(character(len=max(1_I8P, 8_I8P*size(value, kind=I8P))) :: buffer)
   n = 0
   do v=1, size(value, kind=I8P)
      call to_text(value=value(v), text=item, fmt=fmt, iostat=iostat, iomsg=iomsg)
      if (iostat/=0) then
         text = ''
         return
      endif
      if (v>1) item = ' '//item
      if (n+len(item, kind=I8P)>len(buffer, kind=I8P)) buffer = buffer//repeat(' ', max(len(buffer, kind=I8P), len(item, kind=I8P)))
      buffer(n+1:n+len(item, kind=I8P)) = item
      n = n + len(item, kind=I8P)
   enddo
   text = buffer(1:n)
   endsubroutine to_text_I1P_1

   pure subroutine to_text_I2P_1(value, text, fmt, iostat, iomsg)
   !< Convert a list of integer(I2P) values into text, separated by one space (each as *to_text* of a scalar).
   integer(I2P),         intent(in)  :: value(:) !< Values.
   character(len=:), allocatable, intent(out) :: text     !< Text.
   character(*), optional,        intent(in)  :: fmt      !< Format of each value, e.g. `(F6.3)`.
   integer(I4P),                  intent(out) :: iostat   !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg    !< IO message.
   character(len=:), allocatable              :: item     !< Text of one value.
   character(len=:), allocatable              :: buffer   !< Text being built, grown geometrically.
   integer(I8P)                               :: n        !< Used length of the buffer.
   integer(I8P)                               :: v        !< Counter.

   iostat = 0
   iomsg = ''
   allocate(character(len=max(1_I8P, 8_I8P*size(value, kind=I8P))) :: buffer)
   n = 0
   do v=1, size(value, kind=I8P)
      call to_text(value=value(v), text=item, fmt=fmt, iostat=iostat, iomsg=iomsg)
      if (iostat/=0) then
         text = ''
         return
      endif
      if (v>1) item = ' '//item
      if (n+len(item, kind=I8P)>len(buffer, kind=I8P)) buffer = buffer//repeat(' ', max(len(buffer, kind=I8P), len(item, kind=I8P)))
      buffer(n+1:n+len(item, kind=I8P)) = item
      n = n + len(item, kind=I8P)
   enddo
   text = buffer(1:n)
   endsubroutine to_text_I2P_1

   pure subroutine to_text_I4P_1(value, text, fmt, iostat, iomsg)
   !< Convert a list of integer(I4P) values into text, separated by one space (each as *to_text* of a scalar).
   integer(I4P),         intent(in)  :: value(:) !< Values.
   character(len=:), allocatable, intent(out) :: text     !< Text.
   character(*), optional,        intent(in)  :: fmt      !< Format of each value, e.g. `(F6.3)`.
   integer(I4P),                  intent(out) :: iostat   !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg    !< IO message.
   character(len=:), allocatable              :: item     !< Text of one value.
   character(len=:), allocatable              :: buffer   !< Text being built, grown geometrically.
   integer(I8P)                               :: n        !< Used length of the buffer.
   integer(I8P)                               :: v        !< Counter.

   iostat = 0
   iomsg = ''
   allocate(character(len=max(1_I8P, 8_I8P*size(value, kind=I8P))) :: buffer)
   n = 0
   do v=1, size(value, kind=I8P)
      call to_text(value=value(v), text=item, fmt=fmt, iostat=iostat, iomsg=iomsg)
      if (iostat/=0) then
         text = ''
         return
      endif
      if (v>1) item = ' '//item
      if (n+len(item, kind=I8P)>len(buffer, kind=I8P)) buffer = buffer//repeat(' ', max(len(buffer, kind=I8P), len(item, kind=I8P)))
      buffer(n+1:n+len(item, kind=I8P)) = item
      n = n + len(item, kind=I8P)
   enddo
   text = buffer(1:n)
   endsubroutine to_text_I4P_1

   pure subroutine to_text_I8P_1(value, text, fmt, iostat, iomsg)
   !< Convert a list of integer(I8P) values into text, separated by one space (each as *to_text* of a scalar).
   integer(I8P),         intent(in)  :: value(:) !< Values.
   character(len=:), allocatable, intent(out) :: text     !< Text.
   character(*), optional,        intent(in)  :: fmt      !< Format of each value, e.g. `(F6.3)`.
   integer(I4P),                  intent(out) :: iostat   !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg    !< IO message.
   character(len=:), allocatable              :: item     !< Text of one value.
   character(len=:), allocatable              :: buffer   !< Text being built, grown geometrically.
   integer(I8P)                               :: n        !< Used length of the buffer.
   integer(I8P)                               :: v        !< Counter.

   iostat = 0
   iomsg = ''
   allocate(character(len=max(1_I8P, 8_I8P*size(value, kind=I8P))) :: buffer)
   n = 0
   do v=1, size(value, kind=I8P)
      call to_text(value=value(v), text=item, fmt=fmt, iostat=iostat, iomsg=iomsg)
      if (iostat/=0) then
         text = ''
         return
      endif
      if (v>1) item = ' '//item
      if (n+len(item, kind=I8P)>len(buffer, kind=I8P)) buffer = buffer//repeat(' ', max(len(buffer, kind=I8P), len(item, kind=I8P)))
      buffer(n+1:n+len(item, kind=I8P)) = item
      n = n + len(item, kind=I8P)
   enddo
   text = buffer(1:n)
   endsubroutine to_text_I8P_1

   pure subroutine to_text_R4P_1(value, text, fmt, iostat, iomsg)
   !< Convert a list of real(R4P) values into text, separated by one space (each as *to_text* of a scalar).
   real(R4P),            intent(in)  :: value(:) !< Values.
   character(len=:), allocatable, intent(out) :: text     !< Text.
   character(*), optional,        intent(in)  :: fmt      !< Format of each value, e.g. `(F6.3)`.
   integer(I4P),                  intent(out) :: iostat   !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg    !< IO message.
   character(len=:), allocatable              :: item     !< Text of one value.
   character(len=:), allocatable              :: buffer   !< Text being built, grown geometrically.
   integer(I8P)                               :: n        !< Used length of the buffer.
   integer(I8P)                               :: v        !< Counter.

   iostat = 0
   iomsg = ''
   allocate(character(len=max(1_I8P, 8_I8P*size(value, kind=I8P))) :: buffer)
   n = 0
   do v=1, size(value, kind=I8P)
      call to_text(value=value(v), text=item, fmt=fmt, iostat=iostat, iomsg=iomsg)
      if (iostat/=0) then
         text = ''
         return
      endif
      if (v>1) item = ' '//item
      if (n+len(item, kind=I8P)>len(buffer, kind=I8P)) buffer = buffer//repeat(' ', max(len(buffer, kind=I8P), len(item, kind=I8P)))
      buffer(n+1:n+len(item, kind=I8P)) = item
      n = n + len(item, kind=I8P)
   enddo
   text = buffer(1:n)
   endsubroutine to_text_R4P_1

   pure subroutine to_text_R8P_1(value, text, fmt, iostat, iomsg)
   !< Convert a list of real(R8P) values into text, separated by one space (each as *to_text* of a scalar).
   real(R8P),            intent(in)  :: value(:) !< Values.
   character(len=:), allocatable, intent(out) :: text     !< Text.
   character(*), optional,        intent(in)  :: fmt      !< Format of each value, e.g. `(F6.3)`.
   integer(I4P),                  intent(out) :: iostat   !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg    !< IO message.
   character(len=:), allocatable              :: item     !< Text of one value.
   character(len=:), allocatable              :: buffer   !< Text being built, grown geometrically.
   integer(I8P)                               :: n        !< Used length of the buffer.
   integer(I8P)                               :: v        !< Counter.

   iostat = 0
   iomsg = ''
   allocate(character(len=max(1_I8P, 8_I8P*size(value, kind=I8P))) :: buffer)
   n = 0
   do v=1, size(value, kind=I8P)
      call to_text(value=value(v), text=item, fmt=fmt, iostat=iostat, iomsg=iomsg)
      if (iostat/=0) then
         text = ''
         return
      endif
      if (v>1) item = ' '//item
      if (n+len(item, kind=I8P)>len(buffer, kind=I8P)) buffer = buffer//repeat(' ', max(len(buffer, kind=I8P), len(item, kind=I8P)))
      buffer(n+1:n+len(item, kind=I8P)) = item
      n = n + len(item, kind=I8P)
   enddo
   text = buffer(1:n)
   endsubroutine to_text_R8P_1

   ! private procedures
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

   pure subroutine fail(text, what, iostat, iomsg)
   !< Report a token that is not a value: its first character not allowed, or the whole token.
   character(*),                  intent(in)  :: text          !< Token.
   character(*),                  intent(in)  :: what          !< Kind of value, `integer` or `real`.
   integer(I4P),                  intent(out) :: iostat        !< IO status.
   character(len=:), allocatable, intent(out) :: iomsg         !< IO message.
   integer(I8P)                               :: c             !< Position of the first character not allowed.

   iostat = XML_BAD_VALUE
   c = 0
   if (what=='integer') c = verify(text, INTEGER_CHARS, kind=I8P)
   if (c>0) then
      iomsg = 'invalid character "'//text(c:c)//'" in "'//excerpt(text)//'"'
   else
      iomsg = 'invalid '//what//' "'//excerpt(text)//'"'
   endif
   endsubroutine fail

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

   pure function tokens_number(text) result(n)
   !< Return the number of blank-separated tokens of a text.
   character(*), intent(in) :: text  !< Text.
   integer(I8P)             :: n     !< Number of tokens.
   integer(I8P)             :: first !< First position of a token.
   integer(I8P)             :: last  !< Last position of a token.

   n = 0
   last = 0
   do
      call next_token(text=text, last=last, first=first)
      if (first==0) exit
      n = n + 1
   enddo
   endfunction tokens_number
   pure function is_overflow(buffer) result(is_over)
   !< Return true if a formatted value is all asterisks: the value does not fit the field of the format.
   character(*), intent(in) :: buffer  !< Formatted value.
   logical                  :: is_over !< Check result.

   is_over = len_trim(buffer)>0.and.verify(trim(adjustl(buffer)), '*')==0
   endfunction is_overflow
endmodule foxy_xml_values
