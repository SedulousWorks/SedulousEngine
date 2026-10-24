add_executable(GUI.Pipeline.Tests TestsMain.cpp GuiPipelineTests.cpp)
target_link_libraries(GUI.Pipeline.Tests PRIVATE
    Pipeline::GUI Foundation::GUI.Resources Foundation::GUI Pipeline::Core Pipeline::Importer
    Foundation::Content Foundation::Resource Foundation::VFS doctest::doctest)
target_compile_definitions(GUI.Pipeline.Tests PRIVATE DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)
target_compile_options(GUI.Pipeline.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings;-Wno-error=c2y-extensions>" "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")
add_test(NAME GUI.Pipeline.Tests COMMAND GUI.Pipeline.Tests)
