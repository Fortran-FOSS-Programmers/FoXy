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
public :: attribute_value
public :: character_data
public :: first_bad_reference
public :: first_utf8_error
public :: is_name
public :: strip_blanks
public :: line_ends_normalized
public :: text_value
public :: utf8_tail_len
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
integer,      parameter :: FIRST_LEAD        = 192         !< First byte above the UTF-8 continuation bytes, 10xxxxxx.
contains
   pure function is_name(string) result(is_valid)
   !< Return true if *string* is an XML name (XML 1.0 5th edition, production *Name*): its first character a
   !< *NameStartChar*, the others *NameChar*s (the XML ranges of letters, digits, combining characters, ...).
   !<
   !< @note An ASCII name is checked byte by byte; a name with other bytes is decoded by StringiFor (`string%codepoints`),
   !< an ill-formed UTF-8 byte is not a name character.
   character(*), intent(in)  :: string   !< String.
   logical                   :: is_valid !< Check result.
   type(string_t)            :: name     !< Name, to decode.
   integer(I4P), allocatable :: codes(:) !< Code points of the name.
   integer(I8P)              :: c        !< Counter.

   is_valid = .false.
   if (len(string)==0) return
   if (iachar(string(1:1))<FIRST_NON_ASCII) then ! ASCII bytes are checked one by one: the common case
      if (.not.is_name_start_char(iachar(string(1:1), I4P))) return
      do c=2, len(string, kind=I8P)
         if (iachar(string(c:c))>=FIRST_NON_ASCII) exit
         if (.not.is_name_char(iachar(string(c:c), I4P))) return
      enddo
      if (c>len(string, kind=I8P)) then
         is_valid = .true.
         return
      endif
   endif
   name = string
   codes = name%codepoints()
   if (.not.is_name_start_char(codes(1))) return
   do c=2, size(codes, kind=I8P)
      if (.not.is_name_char(codes(c))) return
   enddo
   is_valid = .true.
   endfunction is_name

   pure function attribute_value(raw) result(value)
   !< Return the value of a raw attribute value (as in the source): each literal tab, new line and carriage return (a CR LF
   !< pair as one) read as a space (XML 1.0 3.3.3), then its references decoded.
   character(*), intent(in)      :: raw   !< Raw attribute value.
   character(len=:), allocatable :: value !< Value.

   value = xml_unescape(blanks_as_spaces(raw))
   endfunction attribute_value

   pure function character_data(raw) result(value)
   !< Return the value of raw character data, without removing anything: line ends normalized (CR LF and CR read as LF),
   !< references decoded (the streaming parser gives it in pieces; *text_value* also strips and drops markup).
   character(*), intent(in)      :: raw   !< Raw character data.
   character(len=:), allocatable :: value !< Value.

   value = xml_unescape(line_ends_normalized(raw))
   endfunction character_data

   pure function first_bad_reference(text) result(position)
   !< Return the position of the `&` of the first malformed reference of *text*, 0 if there is none: an `&` that does not
   !< start a predefined entity (`&amp; &lt; &gt; &quot; &apos;`) or a character reference (`&#N;`, `&#xH;`) of a Unicode
   !< scalar value other than 0 (a bare `&`, a missing `;`, `&nbsp;` of a DTD, `&#X41;`, a surrogate, `&#0;`).
   !<
   !< @note StringiFor (`string%xml_error`) checks; texts longer than *SLICE_LEN* are checked in slices never cut inside a
   !< reference.
   character(*), intent(in) :: text     !< Text.
   integer(I8P)             :: position !< Position of the first malformed reference, 0 if none.
   type(string_t)           :: slice    !< Slice of the text.
   integer(I8P)             :: first    !< First position of a slice.
   integer(I8P)             :: last     !< Last position of a slice.
   integer(I8P)             :: amp      !< Position of the last `&` near the end of a slice.
   integer(I8P)             :: e        !< Error position in a slice.

   position = 0
   if (index(text, '&', kind=I8P)==0) return
   first = 1
   do while (first<=len(text, kind=I8P))
      last = min(len(text, kind=I8P), first+SLICE_LEN-1)
      if (last<len(text, kind=I8P)) then ! do not cut a reference: end the slice before an unterminated one
         amp = index(text(max(first, last-MAX_REFERENCE_LEN+1):last), '&', back=.true., kind=I8P)
         if (amp>0) then
            amp = max(first, last-MAX_REFERENCE_LEN+1) + amp - 1
            if (index(text(amp:last), ';', kind=I8P)==0.and.amp>first) last = amp - 1
         endif
      endif
      slice = text(first:last)
      e = slice%xml_error()
      if (e>0) then
         position = first + e - 1
         return
      endif
      first = last + 1
   enddo
   endfunction first_bad_reference

   pure function first_utf8_error(text) result(position)
   !< Return the position of the first byte of *text* that is not part of a well-formed UTF-8 sequence (Unicode Table 3-7:
   !< no overlong form, no surrogate, nothing above U+10FFFF, no truncated sequence, no stray continuation byte), 0 if
   !< there is none.
   !<
   !< @note StringiFor (`string%utf8_error`) checks; texts longer than *SLICE_LEN* are checked in slices cut before a lead
   !< byte, so that no sequence is split.
   character(*), intent(in) :: text     !< Text.
   integer(I8P)             :: position !< Position of the first ill-formed byte, 0 if none.
   type(string_t)           :: slice    !< Slice of the text.
   integer(I8P)             :: first    !< First position of a slice.
   integer(I8P)             :: last     !< Last position of a slice.
   integer(I8P)             :: e        !< Error position in a slice.

   position = 0
   first = 1
   do while (first<=len(text, kind=I8P))
      last = min(len(text, kind=I8P), first+SLICE_LEN-1)
      if (last<len(text, kind=I8P)) then ! end the slice before the sequence the next byte belongs to
         do while (last>first.and.is_continuation(text(last+1:last+1)))
            last = last - 1
         enddo
      endif
      slice = text(first:last)
      e = slice%utf8_error()
      if (e>0) then
         position = first + e - 1
         return
      endif
      first = last + 1
   enddo
   endfunction first_utf8_error

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

   pure function utf8_tail_len(bytes) result(n)
   !< Return the number of bytes at the end of *bytes* that start a UTF-8 sequence not complete in them (0 to 3).
   character(*), intent(in) :: bytes !< Bytes.
   integer(I8P)             :: n     !< Bytes of the incomplete sequence.
   integer(I8P)             :: l     !< Position of the last lead byte.
   integer                  :: code  !< Lead byte code.
   integer                  :: need  !< Length of the sequence the lead byte starts.

   n = 0
   do l=len(bytes, kind=I8P), max(1_I8P, len(bytes, kind=I8P)-3), -1
      code = iachar(bytes(l:l))
      if (code<128) return            ! ASCII: nothing split
      if (code>=192) exit             ! a lead byte
   enddo
   if (l<1) return
   code = iachar(bytes(l:l))
   if (code<192) return               ! only continuation bytes: not a split sequence (an error, checked now)
   need = 2
   if (code>=224) need = 3
   if (code>=240) need = 4
   if (len(bytes, kind=I8P)-l+1<need) n = len(bytes, kind=I8P) - l + 1
   endfunction utf8_tail_len

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
   pure function blanks_as_spaces(text) result(normalized)
   !< Return a text with each blank (tab, new line, carriage return) replaced by a space, a CR LF pair by one space: the
   !< normalization of attribute values (XML 1.0 3.3.3), done by StringiFor `string%replace`.
   character(*), intent(in)      :: text       !< Text.
   character(len=:), allocatable :: normalized !< Normalized string.
   type(string_t)                :: work       !< String being normalized.

   if (scan(text, achar(9)//achar(10)//achar(13))==0) then
      normalized = text
      return
   endif
   work = text
   work = work%replace(old=achar(13)//achar(10), new=' ')
   work = work%replace(old=achar(13), new=' ')
   work = work%replace(old=achar(10), new=' ')
   work = work%replace(old=achar(9), new=' ')
   normalized = work%chars()
   endfunction blanks_as_spaces

   elemental function is_continuation(byte) result(is_cont)
   !< Return true if *byte* is a UTF-8 continuation byte, 10xxxxxx.
   character(len=1), intent(in) :: byte    !< Byte.
   logical                      :: is_cont !< Check result.

   is_cont = iachar(byte)>=FIRST_NON_ASCII.and.iachar(byte)<FIRST_LEAD
   endfunction is_continuation

   elemental function is_name_start_char(code) result(is_valid)
   !< Return true if the code point *code* is an XML 1.0 *NameStartChar* (a negative code, an ill-formed byte, is not).
   integer(I4P), intent(in) :: code     !< Code point.
   logical                  :: is_valid !< Check result.

   select case(code)
   case(iachar(':'), iachar('A'):iachar('Z'), iachar('_'), iachar('a'):iachar('z'), &
        int(z'C0'):int(z'D6'), int(z'D8'):int(z'F6'), int(z'F8'):int(z'2FF'), int(z'370'):int(z'37D'), &
        int(z'37F'):int(z'1FFF'), int(z'200C'):int(z'200D'), int(z'2070'):int(z'218F'), int(z'2C00'):int(z'2FEF'), &
        int(z'3001'):int(z'D7FF'), int(z'F900'):int(z'FDCF'), int(z'FDF0'):int(z'FFFD'), int(z'10000'):int(z'EFFFF'))
      is_valid = .true.
   case default
      is_valid = .false.
   endselect
   endfunction is_name_start_char

   elemental function is_name_char(code) result(is_valid)
   !< Return true if the code point *code* is an XML 1.0 *NameChar*: a *NameStartChar*, `-`, `.`, a digit, U+00B7,
   !< U+0300 to U+036F (combining marks), U+203F or U+2040.
   integer(I4P), intent(in) :: code     !< Code point.
   logical                  :: is_valid !< Check result.

   select case(code)
   case(iachar('-'), iachar('.'), iachar('0'):iachar('9'), int(z'B7'), int(z'300'):int(z'36F'), int(z'203F'):int(z'2040'))
      is_valid = .true.
   case default
      is_valid = is_name_start_char(code)
   endselect
   endfunction is_name_char




endmodule foxy_xml_entities
