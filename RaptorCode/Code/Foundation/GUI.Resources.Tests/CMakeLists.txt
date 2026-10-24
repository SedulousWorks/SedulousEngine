add_executable(GUI.Resources.Tests TestsMain.cpp GuiResourceTests.cpp)
target_link_libraries(GUI.Resources.Tests PRIVATE
    Foundation::GUI.Resources Foundation::Content Foundation::Resource Foundation::VFS doctest::doctest)
target_compile_definitions(GUI.Resources.Tests PRIVATE DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)
target_compile_options(GUI.Resources.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings>" "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")
add_test(NAME GUI.Resources.Tests COMMAND GUI.Resources.Tests)
