# Foundation::GUI.Testing tests (doctest).
add_executable(GUI.Testing.Tests
    TestsMain.cpp
    TesterTests.cpp)

target_link_libraries(GUI.Testing.Tests PRIVATE
    Foundation::GUI.Testing doctest::doctest)

target_compile_definitions(GUI.Testing.Tests PRIVATE
    DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)

target_compile_options(GUI.Testing.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings;-Wno-error=c2y-extensions>"
    "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")

add_test(NAME GUI.Testing.Tests COMMAND GUI.Testing.Tests)
