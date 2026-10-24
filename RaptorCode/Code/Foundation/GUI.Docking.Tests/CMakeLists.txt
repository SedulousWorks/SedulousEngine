add_executable(GUI.Docking.Tests
    DockLayoutTests.cpp
    DockDocumentTests.cpp
    DockSpaceTests.cpp
    DockDropTests.cpp
    DockKeyboardTests.cpp
    DockAreaTests.cpp
    DockHostWindowsTests.cpp
    TestsMain.cpp)

target_link_libraries(GUI.Docking.Tests PRIVATE Foundation::GUI.Docking Foundation::GUI Foundation::GUI.Hosting Foundation::Xml Foundation::Xml.Serialization
    Foundation::RHI Foundation::RHI.Null Foundation::Graphics Foundation::Graphics.Null Foundation::Shell Foundation::Shell.Null doctest::doctest)

target_compile_definitions(GUI.Docking.Tests PRIVATE
    DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)

target_compile_options(GUI.Docking.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings;-Wno-error=c2y-extensions>"
    "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")

add_test(NAME GUI.Docking.Tests COMMAND GUI.Docking.Tests)
