add_executable(GUI.Viewport.Tests
    ViewportTests.cpp
    TestsMain.cpp)

target_link_libraries(GUI.Viewport.Tests PRIVATE
    Foundation::GUI.Viewport Foundation::GUI.Hosting Foundation::RHI Foundation::RHI.Null Foundation::Graphics
    Foundation::Graphics.Null Foundation::Shell Foundation::Shell.Null Foundation::VG.Renderer doctest::doctest)

target_compile_definitions(GUI.Viewport.Tests PRIVATE
    DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)

target_compile_options(GUI.Viewport.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings;-Wno-error=c2y-extensions>"
    "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")

add_test(NAME GUI.Viewport.Tests COMMAND GUI.Viewport.Tests)
