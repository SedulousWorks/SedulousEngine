add_executable(GUI.VFS.Tests
    VfsResourceProviderTests.cpp
    TestsMain.cpp)

target_link_libraries(GUI.VFS.Tests PRIVATE
    Foundation::GUI.VFS Foundation::VFS Foundation::Image Foundation::Image.IO doctest::doctest)

target_compile_definitions(GUI.VFS.Tests PRIVATE
    DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)

target_compile_options(GUI.VFS.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings;-Wno-error=c2y-extensions>"
    "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")

add_test(NAME GUI.VFS.Tests COMMAND GUI.VFS.Tests)
