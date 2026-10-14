!< FoXy XML character references handling.
module foxy_xml_entities
!< FoXy XML character references handling.
!<
!< Character references are the predefined entities `&lt;`, `&gt;`, `&amp;`, `&quot;`, `&apos;` and the numeric
!< references `&#N;` (decimal) and `&#xH;` (hexadecimal) of a Unicode code point, decoded as UTF-8 bytes.
use penf, only : I4P

implicit none
private
public :: xml_escape
public :: xml_unescape

integer(I4P), parameter :: MAX_REFERENCE_LEN = 10_I4P      !< Max length of a reference between `&` and `;`, `#x10FFFF`.
integer(I4P), parameter :: MAX_CODE_POINT    = 1114111_I4P !< Max Unicode code point, U+10FFFF.
integer(I4P), parameter :: SURROGATE_FIRST   = 55296_I4P   !< First UTF-16 surrogate, U+D800, not a character.
integer(I4P), parameter :: SURROGATE_LAST    = 57343_I4P   !< Last UTF-16 surrogate, U+DFFF, not a character.
character(*), parameter :: ESCAPED_CHARS     = '&<"'       !< Characters escaped by *xml_escape*.
contains
   pure function xml_escape(string) result(escaped)
   !< Return *string* with `&`, `<` and `"` replaced by their predefined references, ready to be used as XML content or
   !< (double quoted) attribute value.
   character(*), intent(in)      :: string    !< String to escape.
   character(len=:), allocatable :: escaped   !< Escaped string.
   character(len=:), allocatable :: reference !< Reference of current character.
   integer(I4P)                  :: n         !< Length of escaped string.
   integer(I4P)                  :: c         !< Counter.

   if (scan(string, ESCAPED_CHARS)==0) then
      escaped = string
      return
   endif
   n = 0
   do c=1, len(string)
      n = n + len(reference_of(string(c:c)))
   enddo
   allocate(character(len=n) :: escaped)
   n = 0
   do c=1, len(string)
      reference = reference_of(string(c:c))
      escaped(n+1:n+len(reference)) = reference
      n = n + len(reference)
   enddo
   endfunction xml_escape

   pure function xml_unescape(string) result(unescaped)
   !< Return *string* with its character references decoded.
   !<
   !< @note The string is scanned once from left to right, thus a decoded `&` never starts a new reference (`&amp;lt;` is
   !< decoded as `&lt;`). Unknown (e.g. `&nbsp;`, defined only by a DTD), malformed or invalid (e.g. surrogate code
   !< points) references are left verbatim.
   character(*), intent(in)      :: string    !< String to unescape.
   character(len=:), allocatable :: unescaped !< Unescaped string.
   character(len=:), allocatable :: decoded   !< Decoded reference.
   character(len=len(string))    :: buffer    !< Unescaped characters: a reference is never shorter than its decoding.
   integer(I4P)                  :: n         !< Length of unescaped string.
   integer(I4P)                  :: c         !< Counter.
   integer(I4P)                  :: e         !< Reference end (`;`) position, relative to `&`.
   logical                       :: is_valid  !< Flag for valid reference.

   if (index(string, '&')==0) then
      unescaped = string
      return
   endif
   n = 0
   c = 1
   do while (c<=len(string))
      if (string(c:c)=='&') then
         e = index(string(c+1:min(len(string), c+MAX_REFERENCE_LEN+1)), ';')
         if (e>1) then
            call decode_reference(reference=string(c+1:c+e-1), decoded=decoded, is_valid=is_valid)
            if (is_valid) then
               buffer(n+1:n+len(decoded)) = decoded
               n = n + len(decoded)
               c = c + e + 1
               cycle
            endif
         endif
      endif
      n = n + 1
      buffer(n:n) = string(c:c)
      c = c + 1
   enddo
   unescaped = buffer(1:n)
   endfunction xml_unescape

   ! private procedures
   pure function reference_of(char) result(reference)
   !< Return the predefined reference of an escaped character, the character itself otherwise.
   character(len=1), intent(in)  :: char      !< Character.
   character(len=:), allocatable :: reference !< Reference.

   select case(char)
   case('&')
      reference = '&amp;'
   case('<')
      reference = '&lt;'
   case('"')
      reference = '&quot;'
   case default
      reference = char
   endselect
   endfunction reference_of

   pure subroutine decode_reference(reference, decoded, is_valid)
   !< Decode a character reference, given without the delimiting `&` and `;`.
   character(*),                  intent(in)  :: reference  !< Reference, e.g. `amp`, `#233`, `#xE9`.
   character(len=:), allocatable, intent(out) :: decoded    !< Decoded characters.
   logical,                       intent(out) :: is_valid   !< Flag for valid reference.
   integer(I4P)                               :: code_point !< Unicode code point of a numeric reference.

   is_valid = .true.
   select case(reference)
   case('lt')
      decoded = '<'
   case('gt')
      decoded = '>'
   case('amp')
      decoded = '&'
   case('quot')
      decoded = '"'
   case('apos')
      decoded = "'"
   case default
      is_valid = .false.
      decoded = ''
      if (len(reference)<2) return
      if (reference(1:1)/='#') return
      if (reference(2:2)=='x') then
         code_point = parse_unsigned(digits=reference(3:), base=16_I4P)
      else
         code_point = parse_unsigned(digits=reference(2:), base=10_I4P)
      endif
      if (code_point<1.or.code_point>MAX_CODE_POINT) return
      if (code_point>=SURROGATE_FIRST.and.code_point<=SURROGATE_LAST) return
      decoded = utf8(code_point)
      is_valid = .true.
   endselect
   endsubroutine decode_reference

   pure function parse_unsigned(digits, base) result(value)
   !< Return the value of unsigned *digits* in *base* (10 or 16), -1 if empty, not valid or greater than the max code point.
   character(*), intent(in) :: digits !< Digits.
   integer(I4P), intent(in) :: base   !< Base, 10 or 16.
   integer(I4P)             :: value  !< Value.
   integer(I4P)             :: d      !< Digit value.
   integer(I4P)             :: c      !< Counter.

   value = -1
   if (len(digits)==0) return
   value = 0
   do c=1, len(digits)
      select case(digits(c:c))
      case('0':'9')
         d = iachar(digits(c:c)) - iachar('0')
      case('a':'f')
         d = iachar(digits(c:c)) - iachar('a') + 10
      case('A':'F')
         d = iachar(digits(c:c)) - iachar('A') + 10
      case default
         d = -1
      endselect
      if (d<0.or.d>=base) then
         value = -1
         return
      endif
      value = value * base + d
      if (value>MAX_CODE_POINT) then
         value = -1
         return
      endif
   enddo
   endfunction parse_unsigned

   pure function utf8(code_point) result(bytes)
   !< Return the UTF-8 encoding of a (valid) Unicode code point.
   integer(I4P), intent(in)      :: code_point !< Unicode code point.
   character(len=:), allocatable :: bytes      !< UTF-8 bytes.

   if (code_point<128) then
      bytes = char(code_point)
   elseif (code_point<2048) then
      bytes = char(192 + code_point / 64)//            &
              char(128 + mod(code_point, 64))
   elseif (code_point<65536) then
      bytes = char(224 + code_point / 4096)//          &
              char(128 + mod(code_point / 64, 64))//   &
              char(128 + mod(code_point, 64))
   else
      bytes = char(240 + code_point / 262144)//        &
              char(128 + mod(code_point / 4096, 64))// &
              char(128 + mod(code_point / 64, 64))//   &
              char(128 + mod(code_point, 64))
   endif
   endfunction utf8
endmodule foxy_xml_entities
