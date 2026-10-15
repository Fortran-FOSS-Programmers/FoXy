!< FoXy XML character references handling and character data values.
module foxy_xml_entities
!< FoXy XML character references handling and character data values.
!<
!< *text_value*, *without_markup* and *strip_blanks* (values of raw character data) are public for the other FoXy modules,
!< not re-exported by *foxy*.
!<
!< Character references are the predefined entities `&lt;`, `&gt;`, `&amp;`, `&quot;`, `&apos;` and the numeric
!< references `&#N;` (decimal) and `&#xH;` (hexadecimal) of a Unicode code point, decoded as UTF-8 bytes.
use penf, only : I4P, I8P

implicit none
private
public :: strip_blanks
public :: text_value
public :: without_markup
public :: xml_escape
public :: xml_unescape

integer(I4P), parameter :: MAX_REFERENCE_LEN = 10_I4P      !< Max length of a reference between `&` and `;`, `#x10FFFF`.
integer(I4P), parameter :: MAX_CODE_POINT    = 1114111_I4P !< Max Unicode code point, U+10FFFF.
integer(I4P), parameter :: SURROGATE_FIRST   = 55296_I4P   !< First UTF-16 surrogate, U+D800, not a character.
integer(I4P), parameter :: SURROGATE_LAST    = 57343_I4P   !< Last UTF-16 surrogate, U+DFFF, not a character.
character(*), parameter :: ESCAPED_CHARS     = '&<"'       !< Characters escaped by *xml_escape*.
character(*), parameter :: BLANKS            = ' '//achar(9)//achar(10)//achar(13) !< XML blanks: space, tab, new line, CR.
character(*), parameter :: CDATA_START       = '<![CDATA[' !< CDATA section start.
character(*), parameter :: CDATA_END         = ']]>'       !< CDATA section end.
contains
   pure function xml_escape(string) result(escaped)
   !< Return *string* with `&`, `<` and `"` replaced by their predefined references, ready to be used as XML content or
   !< (double quoted) attribute value.
   character(*), intent(in)      :: string    !< String to escape.
   character(len=:), allocatable :: escaped   !< Escaped string.
   character(len=:), allocatable :: reference !< Reference of current character.
   integer(I8P)                  :: n         !< Length of escaped string.
   integer(I8P)                  :: c         !< Counter.

   if (scan(string, ESCAPED_CHARS, kind=I8P)==0) then
      escaped = string
      return
   endif
   n = 0
   do c=1, len(string, kind=I8P)
      n = n + len(reference_of(string(c:c)), kind=I8P)
   enddo
   allocate(character(len=n) :: escaped)
   n = 0
   do c=1, len(string, kind=I8P)
      reference = reference_of(string(c:c))
      escaped(n+1:n+len(reference, kind=I8P)) = reference
      n = n + len(reference, kind=I8P)
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
   character(len=:), allocatable :: buffer    !< Unescaped characters: a reference is never shorter than its decoding.
   integer(I8P)                  :: n         !< Length of unescaped string.
   integer(I8P)                  :: c         !< Counter.
   integer(I8P)                  :: e         !< Reference end (`;`) position, relative to `&`.
   logical                       :: is_valid  !< Flag for valid reference.

   if (index(string, '&', kind=I8P)==0) then
      unescaped = string
      return
   endif
   allocate(character(len=len(string, kind=I8P)) :: buffer) ! allocatable: no stack object as large as string
   n = 0
   c = 1
   do while (c<=len(string, kind=I8P))
      if (string(c:c)=='&') then
         e = index(string(c+1:min(len(string, kind=I8P), c+MAX_REFERENCE_LEN+1)), ';', kind=I8P)
         if (e>1) then
            call decode_reference(reference=string(c+1:c+e-1), decoded=decoded, is_valid=is_valid)
            if (is_valid) then
               buffer(n+1:n+len(decoded, kind=I8P)) = decoded
               n = n + len(decoded, kind=I8P)
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

   pure function text_value(raw) result(value)
   !< Return the value of raw character data: comments and PIs removed, layout blanks stripped, character references
   !< decoded, CDATA sections literal.
   character(*), intent(in)      :: raw      !< Raw character data.
   character(len=:), allocatable :: value    !< Value.
   character(len=:), allocatable :: stripped !< Raw data without leading and trailing blanks.
   integer(I8P)                  :: p        !< Current position.
   integer(I8P)                  :: c        !< Relative position of next CDATA start.
   integer(I8P)                  :: q        !< CDATA content start.
   integer(I8P)                  :: e        !< Relative position of CDATA end.

   stripped = strip_blanks(without_markup(raw)) ! blanks first: encoded blanks and CDATA blanks are data
   if (index(stripped, CDATA_START, kind=I8P)==0) then
      value = xml_unescape(stripped)
      return
   endif
   value = ''
   p = 1
   do while (p<=len(stripped, kind=I8P))
      c = index(stripped(p:), CDATA_START, kind=I8P)
      if (c==0) then
         value = value//xml_unescape(stripped(p:))
         exit
      endif
      value = value//xml_unescape(stripped(p:p+c-2))
      q = p + c - 1 + len(CDATA_START)
      e = index(stripped(q:), CDATA_END, kind=I8P)
      if (e==0) then ! unterminated, literal up to the end
         value = value//stripped(q:)
         exit
      endif
      value = value//stripped(q:q+e-2)
      p = q + e - 1 + len(CDATA_END)
   enddo
   endfunction text_value

   pure function without_markup(raw, is_cdata_removed) result(text)
   !< Return raw character data without comments and processing instructions (and CDATA sections, if asked); markup inside
   !< a CDATA section is data, an unterminated markup is kept as it is.
   character(*),      intent(in) :: raw              !< Raw character data.
   logical, optional, intent(in) :: is_cdata_removed !< Remove CDATA sections too.
   character(len=:), allocatable :: text             !< Character data without markup.
   character(len=:), allocatable :: buffer           !< Kept characters (allocatable: no stack object as large as raw).
   logical                       :: is_cdata_removed_ !< Remove CDATA sections too, local variable.
   integer(I8P)                  :: n                !< Number of kept characters.
   integer(I8P)                  :: p                !< Current position.
   integer(I8P)                  :: k                !< End of the current markup.
   integer(I8P)                  :: e                !< Relative position of the markup end.

   if (index(raw, '<', kind=I8P)==0) then
      text = raw
      return
   endif
   is_cdata_removed_ = .false. ; if (present(is_cdata_removed)) is_cdata_removed_ = is_cdata_removed
   allocate(character(len=len(raw, kind=I8P)) :: buffer)
   n = 0
   p = 1
   do while (p<=len(raw, kind=I8P))
      k = 0
      if (raw(p:p)=='<') then
         if (raw(p:min(len(raw, kind=I8P), p+8))==CDATA_START) then
            e = index(raw(p+9:), CDATA_END, kind=I8P)
            if (e>0) k = p + e + 10
            if (k>0.and..not.is_cdata_removed_) then ! kept as it is
               buffer(n+1:n+k-p+1) = raw(p:k)
               n = n + k - p + 1
            endif
         elseif (raw(p:min(len(raw, kind=I8P), p+3))=='<!--') then
            e = index(raw(p+4:), '-->', kind=I8P)
            if (e>0) k = p + e + 5
         elseif (raw(p:min(len(raw, kind=I8P), p+1))=='<?') then
            e = index(raw(p+2:), '?>', kind=I8P)
            if (e>0) k = p + e + 2
         endif
      endif
      if (k>0) then
         p = k + 1
      else
         n = n + 1
         buffer(n:n) = raw(p:p)
         p = p + 1
      endif
   enddo
   text = buffer(1:n)
   endfunction without_markup

   pure function strip_blanks(string) result(stripped)
   !< Return string without leading and trailing blanks: spaces, tabs, new lines and carriage returns.
   character(*), intent(in)      :: string   !< String to strip.
   character(len=:), allocatable :: stripped !< Stripped string.
   integer(I8P)                  :: first    !< First not blank character position.
   integer(I8P)                  :: last     !< Last not blank character position.

   first = verify(string, BLANKS, kind=I8P)
   if (first == 0) then
      stripped = ''
   else
      last = verify(string, BLANKS, back=.true., kind=I8P)
      stripped = string(first:last)
   endif
   endfunction strip_blanks

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
   !<
   !< @note The bytes are set into a fixed length buffer: nvfortran gives a deferred-length string assigned from
   !< `char(i)` (i not constant) the length i.
   integer(I4P), intent(in)      :: code_point !< Unicode code point.
   character(len=:), allocatable :: bytes      !< UTF-8 bytes.
   character(len=4)              :: buffer     !< UTF-8 bytes buffer.
   integer(I4P)                  :: n          !< Number of bytes.

   if (code_point<128) then
      n = 1
      buffer(1:1) = char(code_point)
   elseif (code_point<2048) then
      n = 2
      buffer(1:1) = char(192 + code_point / 64)
      buffer(2:2) = char(128 + mod(code_point, 64))
   elseif (code_point<65536) then
      n = 3
      buffer(1:1) = char(224 + code_point / 4096)
      buffer(2:2) = char(128 + mod(code_point / 64, 64))
      buffer(3:3) = char(128 + mod(code_point, 64))
   else
      n = 4
      buffer(1:1) = char(240 + code_point / 262144)
      buffer(2:2) = char(128 + mod(code_point / 4096, 64))
      buffer(3:3) = char(128 + mod(code_point / 64, 64))
      buffer(4:4) = char(128 + mod(code_point, 64))
   endif
   bytes = buffer(1:n)
   endfunction utf8
endmodule foxy_xml_entities
