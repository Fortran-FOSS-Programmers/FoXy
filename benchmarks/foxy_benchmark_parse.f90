!< FoXy benchmark.
program foxy_benchmark_parse
!< FoXy benchmark: time parse, stringify and path lookups of generated documents of growing size.
!<
!< Usage (after `fobis build --mode benchmark-gnu`):
!<
!<```bash
!< exe/benchmarks/foxy_benchmark_parse KIND N [QUERIES]
!<```
!<
!< + KIND: `quakeml` (catalogue of QuakeML-like events, depth ~6), `flat` (N sibling tags under one root), `deep`
!<   (chains 100 levels deep under one root);
!< + N: approximate number of tags;
!< + QUERIES: number of `find(path=)` lookups timed (default 100).
!<
!< Output, one line: `KIND tags bytes t_parse t_stringify t_find` (seconds, wall clock). The documents are generated in
!< memory (not timed); `parse(string=)` is timed, so file reading is excluded.
use foxy, only: I4P, I8P, R8P, xml_file

implicit none
character(len=*), parameter   :: QUAKEML_EVENT =                                                            &
   '<event publicID="quakeml:us/event/1">'//                                                              &
   '<origin publicID="quakeml:us/origin/1"><time><value>2019-07-06T03:19:53.040Z</value></time>'//       &
   '<longitude><value>-117.5993333</value></longitude><latitude><value>35.7695</value></latitude>'//     &
   '<depth><value>8000</value><uncertainty>31610</uncertainty></depth>'//                                 &
   '<quality><usedPhaseCount>85</usedPhaseCount><standardError>0.22</standardError></quality>'//         &
   '<evaluationMode>manual</evaluationMode></origin>'//                                                   &
   '<magnitude publicID="quakeml:us/magnitude/1"><mag><value>7.1</value><uncertainty>0.028</uncertainty></mag>'// &
   '<type>mw</type><stationCount>126</stationCount></magnitude>'//                                        &
   '<preferredOriginID>quakeml:us/origin/1</preferredOriginID></event>'                                    !< QuakeML-like event.
integer(I4P),     parameter   :: QUAKEML_EVENT_TAGS = 22_I4P                                               !< Tags per event.
character(len=*), parameter   :: FLAT_TAG = '<v k="1">value</v>'                                           !< Flat tag.
integer(I4P),     parameter   :: DEEP_DEPTH = 100_I4P                                                      !< Deep chain depth.
character(len=32)             :: argument                                                                  !< Command line argument.
character(len=:), allocatable :: kind                                                                      !< Document kind.
character(len=:), allocatable :: source                                                                    !< Generated document.
character(len=:), allocatable :: path                                                                      !< Path looked up.
character(len=:), allocatable :: stringified                                                               !< Stringified document.
type(xml_file)                :: xfile                                                                     !< XML file handler.
integer(I4P)                  :: n                                                                         !< Requested number of tags.
integer(I4P)                  :: tags                                                                      !< Actual number of tags.
integer(I4P)                  :: queries                                                                   !< Number of lookups.
integer(I4P)                  :: found                                                                     !< Lookups result accumulator.
integer(I4P)                  :: q                                                                         !< Counter.
integer(I8P)                  :: t0, t1, t2, t3                                                            !< Clock counts.
integer(I8P)                  :: rate                                                                      !< Clock rate.

call get_command_argument(1, argument) ; kind = trim(argument)
call get_command_argument(2, argument) ; read(argument, *) n
queries = 100_I4P
if (command_argument_count()>2) then
   call get_command_argument(3, argument) ; read(argument, *) queries
endif

select case(kind)
case('quakeml')
   source = '<q:quakeml><eventParameters>'//repeat(QUAKEML_EVENT, max(1_I4P, n / QUAKEML_EVENT_TAGS))// &
            '</eventParameters></q:quakeml>'
   path = 'origin/latitude/value'
case('flat')
   source = '<root>'//repeat(FLAT_TAG, n)//'</root>'
   path = 'root/v'
case('deep')
   source = '<root>'//repeat(repeat('<d>', DEEP_DEPTH)//'x'//repeat('</d>', DEEP_DEPTH), max(1_I4P, n / DEEP_DEPTH))// &
            '</root>'
   path = repeat('d/', DEEP_DEPTH - 1)//'d'
case default
   error stop 'KIND must be quakeml, flat or deep'
endselect
tags = count_tags(source)

call system_clock(count_rate=rate)
call system_clock(t0)
call xfile%parse(string=source)
call system_clock(t1)
stringified = xfile%stringify()
call system_clock(t2)
found = 0
do q=1, queries
   found = found + xfile%find(path=path)
enddo
call system_clock(t3)
if (found==0) error stop 'lookup found nothing'

print '(A,1X,I0,1X,I0,3(1X,ES10.3))', kind, tags, len(source), real(t1 - t0, R8P) / rate, &
      real(t2 - t1, R8P) / rate, real(t3 - t2, R8P) / rate
contains
   pure function count_tags(string) result(tags)
   !< Count the start (and self closing) tags of a string.
   character(*), intent(in) :: string !< String.
   integer(I4P)             :: tags   !< Number of tags.
   integer(I4P)             :: c      !< Counter.

   tags = 0
   do c=1, len(string) - 1
      if (string(c:c)=='<'.and.string(c+1:c+1)/='/') tags = tags + 1
   enddo
   endfunction count_tags
endprogram foxy_benchmark_parse
