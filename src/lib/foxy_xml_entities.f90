!< FoXy XML character references handling and character data values.
module foxy_xml_entities
!< FoXy XML character references handling and character data values.
!<
!< *text_value*, *without_markup* and *strip_blanks* (values of raw character data) and *is_name* are public for the other
!< FoXy modules, not re-exported by *foxy*.
!<
!< What StringiFor does, FoXy delegates to it (escaping, decoding, number conversion, replacements). Kept here, with
!< their reasons: *strip_blanks* and *line_ends_normalized* work on document-sized text (contents over 2 GiB) with 64-bit
!< positions and no copy, while StringiFor's `strip` and `replace` use default-integer positions on a copy; *is_name*
!< and *without_markup* are XML rules StringiFor does not have.
!<
!< Character references are the predefined entities `&lt;`, `&gt;`, `&amp;`, `&quot;`, `&apos;` and the numeric
!< references `&#N;` (decimal) and `&#xH;` (hexadecimal) of a Unicode code point, decoded as UTF-8 bytes; escaping and
!< decoding are StringiFor's (`string%escape_xml`, `string%unescape_xml`).
use penf, only : I4P, I8P
use stringifor, only : string_t => string

implicit none
private
public :: is_name
public :: strip_blanks
public :: text_value
public :: without_markup
public :: xml_escape
public :: xml_unescape

integer(I8P), parameter :: SLICE_LEN         = 1073741824_I8P !< Longest string passed whole to StringiFor (1 GiB).
integer(I8P), parameter :: MAX_REFERENCE_LEN = 64_I8P      !< Longest reference kept whole when a string is sliced.
character(*), parameter :: BLANKS            = ' '//achar(9)//achar(10)//achar(13) !< XML blanks: space, tab, new line, CR.
character(*), parameter :: CR                = achar(13)   !< Carriage return.
character(*), parameter :: LF                = achar(10)   !< Line feed.
character(*), parameter :: CDATA_START       = '<![CDATA[' !< CDATA section start.
character(*), parameter :: CDATA_END         = ']]>'       !< CDATA section end, escaped as `]]&gt;` in content.
integer,      parameter :: FIRST_NON_ASCII   = 128         !< First non ASCII byte (UTF-8 multi-byte sequences).
contains
   pure function is_name(string) result(is_valid)
   !< Return true if *string* is an XML name (XML 1.0 production *Name*): its first character a letter, `_` or `:`, the
   !< others also digits, `-` or `.`; every non ASCII byte (UTF-8 encoded character) is accepted as a name character.
   character(*), intent(in) :: string   !< String.
   logical                  :: is_valid !< Check result.
   integer(I8P)             :: c        !< Counter.

   is_valid = .false.
   if (len(string)==0) return
   if (.not.is_name_start_char(iachar(string(1:1)))) return
   do c=2, len(string, kind=I8P)
      if (.not.is_name_char(iachar(string(c:c)))) return
   enddo
   is_valid = .true.
   endfunction is_name

   pure function xml_escape(string, attribute) result(escaped)
   !< Return *string* with `&`, `<`, `>`, `"` and `'` replaced by their predefined references, ready to be used as XML
   !< content or as an attribute value; with *attribute* true, tab, new line and carriage return also become `&#9;`,
   !< `&#10;` and `&#13;`, so that an attribute value reads back exactly (a parser turns them into spaces otherwise).
   !<
   !< @note StringiFor (`string%escape_xml`) escapes; FoXy passes strings longer than *SLICE_LEN* in slices (StringiFor
   !< positions are default integers): every escaped character is escaped wherever the string is cut.
   character(*),      intent(in)  :: string    !< String to escape.
   logical, optional, intent(in)  :: attribute !< Escape tab, new line and carriage return too, for an attribute value.
   character(len=:), allocatable  :: escaped   !< Escaped string.
   type(string_t)                 :: slice     !< Slice of the string.
   integer(I8P)                   :: first     !< First position of a slice.

   if (len(string, kind=I8P)<=SLICE_LEN) then
      slice = string
      escaped = ''//slice%escape_xml(attribute=attribute) ! // gives a character
      return
   endif
   escaped = ''
   first = 1
   do while (first<=len(string, kind=I8P))
      slice = string(first:min(len(string, kind=I8P), first+SLICE_LEN-1))
      escaped = escaped//slice%escape_xml(attribute=attribute)
      first = first + SLICE_LEN
   enddo
   endfunction xml_escape

   pure function xml_unescape(string) result(unescaped)
   !< Return *string* with its character references decoded: the predefined entities `&lt;`, `&gt;`, `&amp;`, `&quot;`,
   !< `&apos;` and the numeric references `&#N;`, `&#xH;` of a Unicode scalar value (other than 0), as UTF-8 bytes.
   !<
   !< @note StringiFor (`string%unescape_xml`) decodes: the string is scanned once, a decoded `&` never starts a new
   !< reference (`&amp;lt;` gives `&lt;`); a malformed reference (`&nbsp;`, defined only by a DTD, a bare `&`, `&#0;`, a
   !< surrogate) is left verbatim. Strings longer than *SLICE_LEN* are decoded in slices never cut inside a reference
   !< (one longer than *MAX_REFERENCE_LEN* characters, possible only with many leading zeros, may then be left verbatim).
   character(*), intent(in)      :: string    !< String to unescape.
   character(len=:), allocatable :: unescaped !< Unescaped string.
   type(string_t)                :: slice     !< Slice of the string.
   integer(I8P)                  :: first     !< First position of a slice.
   integer(I8P)                  :: last      !< Last position of a slice.
   integer(I8P)                  :: amp       !< Position of the last `&` near the end of a slice.

   if (index(string, '&', kind=I8P)==0) then
      unescaped = string
      return
   endif
   if (len(string, kind=I8P)<=SLICE_LEN) then
      slice = string
      unescaped = ''//slice%unescape_xml() ! // gives a character
      return
   endif
   unescaped = ''
   first = 1
   do while (first<=len(string, kind=I8P))
      last = min(len(string, kind=I8P), first+SLICE_LEN-1)
      if (last<len(string, kind=I8P)) then ! do not cut a reference: end the slice before an unterminated one
         amp = index(string(max(first, last-MAX_REFERENCE_LEN+1):last), '&', back=.true., kind=I8P)
         if (amp>0) then
            amp = max(first, last-MAX_REFERENCE_LEN+1) + amp - 1
            if (index(string(amp:last), ';', kind=I8P)==0.and.amp>first) last = amp - 1
         endif
      endif
      slice = string(first:last)
      unescaped = unescaped//slice%unescape_xml()
      first = last + 1
   enddo
   endfunction xml_unescape

   pure function text_value(raw) result(value)
   !< Return the value of raw character data: line ends normalized (CR LF and CR read as LF, XML 1.0 2.11, CDATA sections
   !< included), comments and PIs removed, layout blanks stripped, character references decoded, CDATA sections literal.
   character(*), intent(in)      :: raw      !< Raw character data.
   character(len=:), allocatable :: value    !< Value.
   character(len=:), allocatable :: stripped !< Raw data without leading and trailing blanks.
   integer(I8P)                  :: p        !< Current position.
   integer(I8P)                  :: c        !< Relative position of next CDATA start.
   integer(I8P)                  :: q        !< CDATA content start.
   integer(I8P)                  :: e        !< Relative position of CDATA end.

   stripped = strip_blanks(without_markup(line_ends_normalized(raw))) ! blanks first: encoded and CDATA blanks are data
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

   pure function line_ends_normalized(raw) result(text)
   !< Return raw character data with each CR LF pair and each lone CR replaced by LF (XML 1.0 2.11).
   character(*), intent(in)      :: raw    !< Raw character data.
   character(len=:), allocatable :: text   !< Normalized data.
   character(len=:), allocatable :: buffer !< Kept characters (allocatable: no stack object as large as raw).
   integer(I8P)                  :: n      !< Number of kept characters.
   integer(I8P)                  :: c      !< Counter.

   if (index(raw, CR, kind=I8P)==0) then
      text = raw
      return
   endif
   allocate(character(len=len(raw, kind=I8P)) :: buffer)
   n = 0
   do c=1, len(raw, kind=I8P)
      if (raw(c:c)==CR) then
         n = n + 1
         buffer(n:n) = LF
      elseif (raw(c:c)==LF.and.c>1) then
         if (raw(c-1:c-1)/=CR) then ! the LF of CR LF is already written
            n = n + 1
            buffer(n:n) = LF
         endif
      else
         n = n + 1
         buffer(n:n) = raw(c:c)
      endif
   enddo
   text = buffer(1:n)
   endfunction line_ends_normalized

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
   elemental function is_name_start_char(code) result(is_valid)
   !< Return true if the byte *code* can start an XML name: ASCII letter, `_`, `:` or a non ASCII byte.
   integer, intent(in) :: code     !< Byte code.
   logical             :: is_valid !< Check result.

   select case(code)
   case(iachar('A'):iachar('Z'), iachar('a'):iachar('z'), iachar('_'), iachar(':'), FIRST_NON_ASCII:)
      is_valid = .true.
   case default
      is_valid = .false.
   endselect
   endfunction is_name_start_char

   elemental function is_name_char(code) result(is_valid)
   !< Return true if the byte *code* can be in an XML name: a name start byte, a digit, `-` or `.`.
   integer, intent(in) :: code     !< Byte code.
   logical             :: is_valid !< Check result.

   select case(code)
   case(iachar('A'):iachar('Z'), iachar('a'):iachar('z'), iachar('_'), iachar(':'), iachar('0'):iachar('9'), iachar('-'), &
        iachar('.'), FIRST_NON_ASCII:)
      is_valid = .true.
   case default
      is_valid = .false.
   endselect
   endfunction is_name_char




endmodule foxy_xml_entities
