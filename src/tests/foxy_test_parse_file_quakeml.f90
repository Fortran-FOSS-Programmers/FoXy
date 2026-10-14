!< FoXy test.
program foxy_test_parse_file_quakeml
!< FoXy test.
!<
!< Read a real QuakeML document (issue #7 use case): the preferred origin and magnitude of an event, among the many
!< origins, magnitudes and focal mechanisms sharing the same tags names.
!<
!< The data file is the unmodified USGS FDSN event service response for the 2019 Ridgecrest M7.1 earthquake (public
!< domain, US Government work), retrieved on 2026-10-14 from
!< https://earthquake.usgs.gov/fdsnws/event/1/query?eventid=ci38457511&format=quakeml
!< The expected values have been cross-checked with Python xml.etree.
use foxy, only: xml_file
use penf, only: I4P

implicit none
character(len=*), parameter   :: FILENAME = 'src/tests/data/quakeml_ci38457511.xml' !< QuakeML file, relative to project root.
character(len=*), parameter   :: EXPECTED_LATITUDES = '35.7695 35.7695 35.5 35.488 35.693' !< Latitudes of all origins.
type(xml_file)                :: xfile                                              !< XML file handler.
character(len=:), allocatable :: preferred_id                                       !< Preferred origin/magnitude ID.
character(len=:), allocatable :: latitudes                                          !< Latitudes of all origins.
integer(I4P), allocatable     :: ids(:)                                             !< Tags IDs.
integer(I4P)                  :: origin                                             !< Preferred origin tag ID.
integer(I4P)                  :: magnitude                                          !< Preferred magnitude tag ID.
integer(I4P)                  :: plane                                              !< Nodal plane tag ID.
integer(I4P)                  :: i                                                  !< Counter.
logical                       :: test_passed(6)                                     !< List of passed tests.

test_passed = .false.

print "(A)", 'Parsing '//FILENAME
call xfile%parse(filename=FILENAME)

test_passed(1) = size(xfile%find_all(path='event/origin'))==5.and.        &
                 size(xfile%find_all(path='event/magnitude'))==5.and.     &
                 size(xfile%find_all(path='event/focalMechanism'))==4
print "(A,L1)", 'Are origins, magnitudes and focal mechanisms counted correctly? ', test_passed(1)

! preferred origin: the origin whose publicID is the event preferredOriginID
preferred_id = xfile%content(id=xfile%find(path='event/preferredOriginID'))
origin = 0
ids = xfile%find_all(path='event/origin')
do i=1, size(ids)
   if (xfile%attribute(id=ids(i), name='publicID')==preferred_id) origin = ids(i)
enddo
print "(A)", 'Preferred origin: lat '//xfile%content(id=xfile%find(path='latitude/value', parent=origin))//&
             ', lon '//xfile%content(id=xfile%find(path='longitude/value', parent=origin))//            &
             ', depth '//xfile%content(id=xfile%find(path='depth/value', parent=origin))
test_passed(2) = origin>0.and.                                                                  &
                 xfile%content(id=xfile%find(path='latitude/value', parent=origin))=='35.7695'.and.  &
                 xfile%content(id=xfile%find(path='longitude/value', parent=origin))=='-117.5993333'.and. &
                 xfile%content(id=xfile%find(path='depth/value', parent=origin))=='8000'
print "(A,L1)", 'Is preferred origin correct? ', test_passed(2)

! preferred magnitude
preferred_id = xfile%content(id=xfile%find(path='event/preferredMagnitudeID'))
magnitude = 0
ids = xfile%find_all(path='event/magnitude')
do i=1, size(ids)
   if (xfile%attribute(id=ids(i), name='publicID')==preferred_id) magnitude = ids(i)
enddo
print "(A)", 'Preferred magnitude: '//xfile%content(id=xfile%find(path='mag/value', parent=magnitude))//' '// &
             xfile%content(id=xfile%find(name='type', parent=magnitude))
test_passed(3) = magnitude>0.and.                                                       &
                 xfile%content(id=xfile%find(path='mag/value', parent=magnitude))=='7.1'.and. &
                 xfile%content(id=xfile%find(name='type', parent=magnitude))=='mw'
print "(A,L1)", 'Is preferred magnitude correct? ', test_passed(3)

! latitudes of all origins, in document order
ids = xfile%find_all(path='origin/latitude/value')
latitudes = ''
do i=1, size(ids)
   latitudes = latitudes//' '//xfile%content(id=ids(i))
enddo
test_passed(4) = latitudes(2:)==EXPECTED_LATITUDES
print "(A,L1)", 'Are all origins latitudes ('//latitudes(2:)//') correct? ', test_passed(4)

! first nodal plane: only some focal mechanisms have one
ids = xfile%find_all(path='focalMechanism/nodalPlanes/nodalPlane1')
test_passed(5) = size(ids)>0
if (test_passed(5)) then
   plane = ids(1)
   test_passed(5) = xfile%content(id=xfile%find(path='strike/value', parent=plane))=='229.85'.and. &
                    xfile%content(id=xfile%find(path='dip/value', parent=plane))=='81.33'.and.     &
                    xfile%content(id=xfile%find(path='rake/value', parent=plane))=='-6.17'
endif
print "(A,L1)", 'Is first nodal plane correct? ', test_passed(5)

! namespaced attributes are plain attributes
test_passed(6) = xfile%attribute(id=xfile%find(path='event/origin'), name='catalog:datasource')=='ci'
print "(A,L1)", 'Is namespaced attribute correct? ', test_passed(6)

print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
endprogram foxy_test_parse_file_quakeml
