add_executable(Editor.GUI.Tests TestsMain.cpp GuiPagesTests.cpp)
target_link_libraries(Editor.GUI.Tests PRIVATE
    Editor::GUI Editor::Core Foundation::UI Foundation::UI.Toolkit Foundation::GUI Pipeline::GUI doctest::doctest)
target_compile_definitions(Editor.GUI.Tests PRIVATE DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)
target_compile_options(Editor.GUI.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings>" "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")
add_test(NAME Editor.GUI.Tests COMMAND Editor.GUI.Tests)
