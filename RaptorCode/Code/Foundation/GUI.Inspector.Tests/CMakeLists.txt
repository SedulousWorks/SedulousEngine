# Foundation::GUI.Inspector tests (doctest).
add_executable(GUI.Inspector.Tests
    TestsMain.cpp
    QueriesTests.cpp
    InspectorTests.cpp)

target_link_libraries(GUI.Inspector.Tests PRIVATE
    Foundation::GUI.Inspector doctest::doctest)

target_compile_definitions(GUI.Inspector.Tests PRIVATE
    DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)

target_compile_options(GUI.Inspector.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings;-Wno-error=c2y-extensions>"
    "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")

add_test(NAME GUI.Inspector.Tests COMMAND GUI.Inspector.Tests)
