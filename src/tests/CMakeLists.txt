include(GNUInstallDirs)

SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/tests/${CMAKE_INSTALL_BINDIR}")

function(add_foxy_test test_src libraries)
    get_filename_component(test_name ${test_src} NAME_WE)

    add_executable(${test_name} ${test_src})
    foreach(lib IN LISTS libraries)
        target_link_libraries(${test_name} ${lib})
    endforeach()
    add_test(NAME ${test_name} COMMAND ${test_name})

endfunction()

file(GLOB_RECURSE tests *.f90)

foreach(foxy_test IN LISTS tests)
    add_foxy_test(${foxy_test} FoXy::FoXy)
endforeach()
