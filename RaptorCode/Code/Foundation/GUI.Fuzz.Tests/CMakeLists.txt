# Foundation::GUI fuzz targets (E10 of Specs/gui-lab-evolution-2.md): in ctest, every seed and a
# seeded run of mutations through each target; with OPTION_GUI_LIBFUZZER under clang, a libFuzzer
# executable per target for long runs.
add_executable(GUI.Fuzz.Tests
    TestsMain.cpp
    FuzzTests.cpp)

target_link_libraries(GUI.Fuzz.Tests PRIVATE
    Foundation::GUI Foundation::GUI.Testing Foundation::VFS Foundation::Xml.Serialization
    Foundation::I18N doctest::doctest)

target_compile_definitions(GUI.Fuzz.Tests PRIVATE
    DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)

target_compile_options(GUI.Fuzz.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings;-Wno-error=c2y-extensions>"
    "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")

add_test(NAME GUI.Fuzz.Tests COMMAND GUI.Fuzz.Tests)

# Long runs: one executable per target (GUI.Fuzz.Css, .Markup, .Keymap, .StringTable, .Input), in a
# tree whose code is built for coverage (CMAKE_CXX_FLAGS=-fsanitize=fuzzer-no-link,address).
if(OPTION_GUI_LIBFUZZER AND CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    set(_gui_fuzz_targets Css Markup Keymap StringTable Input)
    set(_gui_fuzz_index 1)
    foreach(_name IN LISTS _gui_fuzz_targets)
        add_executable(GUI.Fuzz.${_name} LibFuzzer.cpp)
        target_link_libraries(GUI.Fuzz.${_name} PRIVATE
            Foundation::GUI Foundation::GUI.Testing Foundation::VFS Foundation::Xml.Serialization Foundation::I18N)
        target_compile_definitions(GUI.Fuzz.${_name} PRIVATE GUI_FUZZ_TARGET=${_gui_fuzz_index})
        target_compile_options(GUI.Fuzz.${_name} PRIVATE -fsanitize=fuzzer,address)
        target_link_options(GUI.Fuzz.${_name} PRIVATE -fsanitize=fuzzer,address)
        math(EXPR _gui_fuzz_index "${_gui_fuzz_index} + 1")
    endforeach()
endif()
