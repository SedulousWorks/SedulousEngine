# Foundation::GUI.Shell tests (doctest).
add_executable(GUI.Shell.Tests
    TestsMain.cpp
    BridgeTests.cpp)

target_link_libraries(GUI.Shell.Tests PRIVATE
    Foundation::GUI.Shell Foundation::Shell.Null doctest::doctest)

target_compile_definitions(GUI.Shell.Tests PRIVATE
    DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)

target_compile_options(GUI.Shell.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings;-Wno-error=c2y-extensions>"
    "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")

add_test(NAME GUI.Shell.Tests COMMAND GUI.Shell.Tests)
