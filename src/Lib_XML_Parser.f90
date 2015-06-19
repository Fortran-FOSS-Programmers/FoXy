!> @ingroup Library
!> @{
!> @defgroup Lib_XML_ParserLibrary Lib_XML_Parser
!> @}

!> @ingroup Interface
!> @{
!> @defgroup Lib_XML_ParserInterface Lib_XML_Parser
!> @}

!> @ingroup GlobalVarPar
!> @{
!> @defgroup Lib_XML_ParserGlobalVarPar Lib_XML_Parser
!> @}

!> @ingroup PublicProcedure
!> @{
!> @defgroup Lib_XML_ParserPublicProcedure Lib_XML_Parser
!> @}

!> This module contains a parser for XML file.
!> This is a library module.
!> @ingroup Lib_XML_ParserLibrary
module Lib_XML_Parser
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision                                                                  ! Integers and reals precision definition.
USE Data_Type_XML_Tag,            only: Type_XML_Tag                              ! Definition of Type_XML_Tag.
USE Lib_IO_Misc                                                                   ! Procedures for IO and strings operations.
USE, intrinsic:: ISO_FORTRAN_ENV, only: stdout=>OUTPUT_UNIT, stderr=>ERROR_UNIT,& ! Standard output/error logical units.
                                        IOSTAT_END, IOSTAT_EOR                    ! Standard end-of-file/end-of record parameters.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
save
private
public:: xml_parser
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  !> @ingroup Lib_XML_ParserPublicProcedure
  !> @{
  !> @brief Procedure for parsing a file or an input string searching for XML tags passed as arguments.
  subroutine xml_parser(pref,filename,string,iostat,iomsg,tags)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional,          intent(IN)::    pref                      !< Prefixing string.
  character(*), optional,          intent(IN)::    filename                  !< XML file name.
  character(*), optional,          intent(IN)::    string                    !< String containing the input.
  integer(I4P), optional,          intent(OUT)::   iostat                    !< IO error.
  character(*), optional,          intent(OUT)::   iomsg                     !< IO error message.
  type(Type_XML_Tag), allocatable, intent(INOUT):: tags(:)                   !< XML tags composing the file.
  logical::                                        is_file                   !< Flag for inquiring the presence of the file.
  integer(I4P)::                                   unit                      !< Unit file.
  integer(I4P)::                                   iostatd                   !< IO error.
  character(500)::                                 iomsgd                    !< IO error message.
  character(len=:), allocatable::                  prefd                     !< Prefixing string.
  character(len=1)::                               c1                        !< Dummy string for parsing file.
  character(len=:), allocatable::                  c2                        !< Dummy string for parsing file.
  integer(I4P)::                                   Nt,t,topen                !< Counters.
  character(2)::                                   tclose(1:2) = ['</','/>'] !< Tags closing marks.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  if (present(filename)) then
    inquire(file=adjustl(trim(filename)),exist=is_file,iostat=iostatd)
    if (.not.is_file) then
      iostat = File_Not_Found(filename=adjustl(trim(filename)),cpn=prefd//'xml_parser')
      return
    endif
    open(unit=Get_Unit(unit),file=adjustl(trim(filename)),access='STREAM',form='UNFORMATTED',iostat=iostatd,iomsg=iomsgd)
    if (iostatd/=0) then
      write(stderr,'(A)')prefd//' Opening file '//adjustl(trim(filename))//' some errors occurs!'
      write(stderr,'(A)')prefd//iomsgd
      return
    endif
    Nt = 0
    read(unit=unit,iostat=iostatd,iomsg=iomsgd,end=10)c1
    Tags_Count: do
      c2 = c1
      read(unit=unit,iostat=iostatd,iomsg=iomsgd,end=10)c1
      c2 = c2//c1
      if (c2==tclose(1).or.c2==tclose(2)) Nt = Nt + 1
    enddo Tags_Count
    10 continue
    if (Nt>0) then
      if (allocated(tags)) then
        call tags%free
        deallocate(tags)
      endif
      allocate(tags(1:Nt))
      rewind(unit)
      t = 0
      topen = 0
      Tag_Search: do
        read(unit=unit,iostat=iostatd,iomsg=iomsgd,end=20)c1
        if (c1=='<'.and.topen==0) then
          t = t + 1
          topen = topen + 1
          c2 = c1
          Tag_Name: do
            read(unit=unit,iostat=iostatd,iomsg=iomsgd,end=20)c1
            c2 = c2//c1
            if (c1=='>') then
              topen = topen - 1
              exit Tag_Name
            endif
          enddo Tag_Name
          tags(t)%string%vs = c2
          if (.not.(index(string=c2,substring='/>')>0)) then ! not a self closing tag: tag value must be read
            c2 = ''
            Tag_Value: do
              read(unit=unit,iostat=iostatd,iomsg=iomsgd,end=20)c1
              c2 = c2//c1
              if (c1=='>') then
                if (topen==0) exit Tag_Value
                topen = topen - 1
              elseif (c1=='<') then
                topen = topen + 1
              endif
            enddo Tag_Value
            tags(t)%string%vs = tags(t)%string%vs//c2
          endif
          c2 = tags(t)%string%vs
          call tags(t)%parse(string=c2)
        endif
      enddo Tag_Search
      20 close(unit)
    endif
  elseif (present(string)) then
  else
    write(stderr,'(A)')prefd//' Error: one of "filename" or "input_string" must be passed as argument to xml_parser'
    iostat = -1
  endif
  if (present(iostat)) iostat = iostatd
  if (present(iomsg))  iomsg  = iomsgd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine
  !> @}
endmodule Lib_XML_Parser
