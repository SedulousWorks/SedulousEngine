add_executable(GUI.Hosting.Tests
    PictureBakerTests.cpp
    GuiHostTests.cpp
    PassRendererTests.cpp
    TestsMain.cpp)

target_link_libraries(GUI.Hosting.Tests PRIVATE
    Foundation::GUI.Hosting Foundation::RHI Foundation::RHI.Null Foundation::Graphics Foundation::Graphics.Null
    Foundation::Shell Foundation::Shell.Null Foundation::VG.Renderer Foundation::VG.SVG Foundation::Image doctest::doctest)

target_compile_definitions(GUI.Hosting.Tests PRIVATE
    DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)

target_compile_options(GUI.Hosting.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings;-Wno-error=c2y-extensions>"
    "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")

add_test(NAME GUI.Hosting.Tests COMMAND GUI.Hosting.Tests)
