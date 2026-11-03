!< FoXy sources encodings: detection (byte order mark, XML 1.0 Appendix F, encoding declaration) and conversion to UTF-8.
module foxy_xml_source
!< FoXy sources encodings: detection (byte order mark, XML 1.0 Appendix F, encoding declaration) and conversion to UTF-8.
!<
!< FoXy parses UTF-8. A source in UTF-16, UTF-32, ISO-8859-1, windows-1252 or US-ASCII is converted to UTF-8 piece by
!< piece (StringiFor `to_utf8`) before the tokenizer: positions refer to the converted text. The encoding is detected
!< from the first bytes (XML 1.0 4.3.3 and Appendix F): a byte order mark, the patterns of `<?` in UTF-16/UTF-32, then
!< the `encoding` of the XML declaration. An invalid sequence becomes the byte FF (never in UTF-8), so the tokenizer
!< reports it at its place, in source order, as any other problem.
use penf
use stringifor, only : bom_encoding, bom_length, canonical_encoding, to_utf8

implicit none
private
public :: DETECT_LEN
public :: INVALID_BYTE
public :: MAX_PIECE
public :: converted_line
public :: decode_piece
public :: decoded
public :: detect_encoding
public :: detect_file_encoding
public :: source_encoding
public :: with_utf8_declaration

integer(I8P), parameter :: DETECT_LEN   = 1024_I8P          !< Bytes read to detect the encoding.
integer(I8P), parameter :: MAX_PIECE    = 1073741824_I8P    !< Largest piece converted at once (StringiFor positions).
character(*), parameter :: INVALID_BYTE = achar(255)        !< Replacement of an invalid sequence (never in UTF-8).
character(*), parameter :: BLANKS       = ' '//achar(9)//achar(10)//achar(13) !< XML blanks.

type :: source_encoding
   !< Encoding of a source, as detected, and the conversion state.
   character(len=:), allocatable :: name               !< Canonical name, endianness included (`UTF-8` if not converted).
   character(len=:), allocatable :: problem            !< Problem of the encoding (reported at position 1), empty if none.
   character(len=:), allocatable :: carry              !< Incomplete character between pieces.
   integer(I8P)                  :: skip=0_I8P         !< Bytes of a UTF-16/UTF-32 byte order mark, not converted.
   logical                       :: is_converted=.false. !< The source is converted to UTF-8.
endtype source_encoding

contains
   pure subroutine detect_encoding(prefix, encoding)
   !< Detect the encoding of a source from its first bytes (*DETECT_LEN* at most, all of them if the source is shorter).
   !<
   !< @note A declared encoding that is not supported (or that contradicts the byte order mark or the first bytes) is a
   !< problem: the source is then read in the detected encoding (UTF-8 if none), as tolerant parsing does.
   character(*),          intent(in)  :: prefix   !< First bytes of the source.
   type(source_encoding), intent(out) :: encoding !< Detected encoding.
   character(len=:), allocatable      :: detected !< Encoding from the byte order mark or the first bytes.
   character(len=:), allocatable      :: text     !< First bytes converted, to read the declaration.
   character(len=:), allocatable      :: declared !< Declared encoding, as written.
   character(len=:), allocatable      :: declared_canonical !< Declared encoding, canonical name.
   logical                            :: is_marked !< The source starts with a byte order mark.
   integer                            :: first4(4) !< Values of the first 4 bytes.
   integer                            :: b         !< Counter.

   encoding%name = 'UTF-8'
   encoding%problem = ''
   encoding%carry = ''
   detected = bom_encoding(prefix)
   is_marked = len(detected)>0
   if (is_marked) then
      if (detected/='UTF-8') encoding%skip = int(bom_length(prefix), I8P)
   elseif (len(prefix)>=4) then
      ! byte values compared, not strings: nvfortran 26.9 takes case strings holding NUL bytes as duplicates
      first4 = [(iachar(prefix(b:b)), b=1, 4)]
      if (all(first4==[60, 0, 63, 0])) then
         detected = 'UTF-16LE'
      elseif (all(first4==[0, 60, 0, 63])) then
         detected = 'UTF-16BE'
      elseif (all(first4==[60, 0, 0, 0])) then
         detected = 'UTF-32LE'
      elseif (all(first4==[0, 0, 0, 60])) then
         detected = 'UTF-32BE'
      endif
   endif
   ! the declaration, read in the detected encoding (it is ASCII in every supported one)
   if (len(detected)>0.and.detected/='UTF-8') then
      call to_utf8(bytes=prefix(encoding%skip+1:), encoding=detected, utf8=text, carry=encoding%carry, is_last=.false.)
      encoding%carry = ''
   elseif (detected=='UTF-8') then
      text = prefix(4:)
   else
      text = prefix
   endif
   declared = declared_encoding(text)
   declared_canonical = canonical_encoding(declared)
   if (len(declared)>0.and.len(declared_canonical)==0) then
      encoding%problem = 'encoding "'//declared//'" not supported'
      if (len(detected)>0) encoding%name = detected
   elseif (len(detected)>0) then
      encoding%name = detected
      if (len(declared)>0.and..not.is_same_family(declared_canonical, detected)) then
         encoding%problem = 'encoding "'//declared//'" declared, but the source is '//detected
      elseif (.not.is_marked.and.detected(1:6)=='UTF-16') then
         encoding%problem = 'a UTF-16 source must start with a byte order mark'
      endif
   elseif (len(declared_canonical)>0) then
      if (declared_canonical(1:min(4, len(declared_canonical)))=='UTF-'.and.declared_canonical/='UTF-8') then
         encoding%problem = 'encoding "'//declared//'" declared, but the source is not '//declared_canonical
      else
         encoding%name = declared_canonical
      endif
   endif
   encoding%is_converted = encoding%name/='UTF-8'
   endsubroutine detect_encoding

   subroutine detect_file_encoding(unit, file_size, encoding, iostat, iomsg)
   !< Detect the encoding of an open stream file from its first bytes (read at position 1).
   integer(I4P),          intent(in)    :: unit      !< File unit.
   integer(I8P),          intent(in)    :: file_size !< File size.
   type(source_encoding), intent(out)   :: encoding  !< Detected encoding.
   integer(I4P),          intent(out)   :: iostat    !< IO status.
   character(*),          intent(inout) :: iomsg     !< IO message.
   character(len=:), allocatable        :: prefix    !< First bytes.

   allocate(character(len=min(file_size, DETECT_LEN)) :: prefix)
   iostat = 0
   if (len(prefix)>0) read(unit=unit, pos=1, iostat=iostat, iomsg=iomsg) prefix
   call detect_encoding(prefix=prefix, encoding=encoding)
   endsubroutine detect_file_encoding

   pure subroutine decode_piece(encoding, raw, is_last, utf8)
   !< Convert a piece of a source to UTF-8, carrying an incomplete character to the next piece.
   type(source_encoding),         intent(inout) :: encoding !< Encoding (and conversion state).
   character(*),                  intent(in)    :: raw      !< Piece of the source (at most *MAX_PIECE* bytes).
   logical,                       intent(in)    :: is_last  !< The source ends with this piece.
   character(len=:), allocatable, intent(out)   :: utf8     !< Piece converted.

   call to_utf8(bytes=raw, encoding=encoding%name, utf8=utf8, carry=encoding%carry, is_last=is_last, &
                replacement=INVALID_BYTE)
   endsubroutine decode_piece

   pure function decoded(source, encoding) result(utf8)
   !< Return a whole source (a string) converted to UTF-8, its byte order mark (*encoding%skip*) removed.
   character(*),          intent(in) :: source   !< Source.
   type(source_encoding), intent(in) :: encoding !< Detected encoding.
   character(len=:), allocatable     :: utf8     !< Source converted.
   type(source_encoding)             :: state    !< Conversion state.
   character(len=:), allocatable     :: piece    !< Piece converted.
   integer(I8P)                      :: first    !< First byte of a piece.
   integer(I8P)                      :: last     !< Last byte of a piece.

   state = encoding
   state%carry = ''
   utf8 = ''
   first = encoding%skip + 1
   do
      last = min(len(source, kind=I8P), first + MAX_PIECE - 1)
      call decode_piece(encoding=state, raw=source(first:last), is_last=last>=len(source, kind=I8P), utf8=piece)
      utf8 = utf8//piece
      first = last + 1
      if (first>len(source, kind=I8P)) exit
   enddo
   endfunction decoded

   function converted_line(unit, pos, chunk, encoding) result(line)
   !< Return the line of a position of the converted text of an open stream file (read again and converted, in chunks).
   integer(I4P),          intent(in) :: unit     !< File unit.
   integer(I8P),          intent(in) :: pos      !< Position in the converted text.
   integer(I8P),          intent(in) :: chunk    !< Size of the chunks read.
   type(source_encoding), intent(in) :: encoding !< Detected encoding.
   integer(I8P)                      :: line     !< Line.
   type(source_encoding)             :: state    !< Conversion state.
   character(len=:), allocatable     :: raw      !< Chunk read.
   character(len=:), allocatable     :: utf8     !< Chunk converted.
   integer(I8P)                      :: file_size !< File size.
   integer(I8P)                      :: first    !< First byte of a chunk.
   integer(I8P)                      :: size_    !< Size of a chunk.
   integer(I8P)                      :: done     !< Converted characters counted.
   integer(I8P)                      :: c        !< Counter.
   integer                           :: ios      !< I/O status.

   line = 1
   state = encoding
   state%carry = ''
   inquire(unit=unit, size=file_size)
   first = encoding%skip + 1
   done = 0
   do while (first<=file_size.and.done<pos-1)
      size_ = min(min(chunk, MAX_PIECE), file_size - first + 1)
      if (allocated(raw)) deallocate(raw)
      allocate(character(len=size_) :: raw)
      read(unit, pos=first, iostat=ios) raw
      if (ios/=0) exit
      call decode_piece(encoding=state, raw=raw, is_last=first+size_>file_size, utf8=utf8)
      do c=1, min(len(utf8, kind=I8P), pos - 1 - done)
         if (utf8(c:c)==new_line('a')) line = line + 1
      enddo
      done = done + len(utf8, kind=I8P)
      first = first + size_
   enddo
   endfunction converted_line

   pure function with_utf8_declaration(prolog) result(rewritten)
   !< Return a prolog whose XML declaration (if it has one, with an `encoding`) declares `UTF-8`: the text of a converted
   !< source is UTF-8.
   character(*), intent(in)      :: prolog    !< Prolog.
   character(len=:), allocatable :: rewritten !< Prolog declaring UTF-8.
   integer(I8P)                  :: first     !< First character of the encoding value.
   integer(I8P)                  :: last      !< Last character of the encoding value.

   rewritten = prolog
   call declared_encoding_range(prolog, first, last)
   if (first>0) rewritten = prolog(1:first-1)//'UTF-8'//prolog(last+1:)
   endfunction with_utf8_declaration

   ! private procedures
   pure function declared_encoding(text) result(declared)
   !< Return the encoding of the XML declaration that starts *text*, empty if there is none.
   character(*), intent(in)      :: text     !< Text (UTF-8).
   character(len=:), allocatable :: declared !< Declared encoding, as written.
   integer(I8P)                  :: first    !< First character of the value.
   integer(I8P)                  :: last     !< Last character of the value.

   call declared_encoding_range(text, first, last)
   if (first>0) then
      declared = text(first:last)
   else
      declared = ''
   endif
   endfunction declared_encoding

   pure subroutine declared_encoding_range(text, first, last)
   !< Return the range of the encoding value of the XML declaration that starts *text* (after leading characters that
   !< are not markup, as a UTF-8 byte order mark), first 0 if there is none.
   character(*), intent(in)  :: text  !< Text (UTF-8).
   integer(I8P), intent(out) :: first !< First character of the value.
   integer(I8P), intent(out) :: last  !< Last character of the value.
   integer(I8P)              :: start !< Start of the declaration.
   integer(I8P)              :: close_ !< End of the declaration.
   integer(I8P)              :: c     !< Current character.
   character                 :: quote !< Quote of the value.

   first = 0
   last = 0
   start = index(text, '<?xml', kind=I8P)
   if (start==0.or.start>4) return ! the declaration is the first thing (a UTF-8 mark may precede it)
   if (start+5>len(text, kind=I8P)) return
   if (index(BLANKS, text(start+5:start+5))==0) return
   close_ = index(text(start:), '?>', kind=I8P)
   if (close_==0) return
   close_ = start + close_ - 1
   c = index(text(start:close_), 'encoding', kind=I8P)
   if (c==0) return
   c = start + c - 1 + 8
   do while (c<close_)
      if (index(BLANKS, text(c:c))==0) exit
      c = c + 1
   enddo
   if (text(c:c)/='=') return
   c = c + 1
   do while (c<close_)
      if (index(BLANKS, text(c:c))==0) exit
      c = c + 1
   enddo
   quote = text(c:c)
   if (quote/='"'.and.quote/="'") return
   last = index(text(c+1:close_), quote, kind=I8P)
   if (last==0) return
   first = c + 1
   last = c + last - 1
   endsubroutine declared_encoding_range

   pure function is_same_family(declared, detected) result(is_same)
   !< Return true if a declared encoding agrees with the one detected from the byte order mark or the first bytes.
   character(*), intent(in) :: declared !< Declared encoding, canonical name.
   character(*), intent(in) :: detected !< Detected encoding.
   logical                  :: is_same  !< Check result.

   select case(detected)
   case('UTF-8')
      is_same = declared=='UTF-8'
   case('UTF-16LE', 'UTF-16BE')
      is_same = declared=='UTF-16'.or.declared==detected
   case('UTF-32LE', 'UTF-32BE')
      is_same = declared=='UTF-32'.or.declared==detected
   case default
      is_same = .false.
   endselect
   endfunction is_same_family
endmodule foxy_xml_source
