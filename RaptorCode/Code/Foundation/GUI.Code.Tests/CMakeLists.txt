add_executable(GUI.Code.Tests
    CodeDocumentTests.cpp
    CodeEditorTests.cpp
    CodeLanguageTests.cpp
    CodeEditingTests.cpp
    CodeCompletionTests.cpp
    CodeFoldingTests.cpp
    TestsMain.cpp)

target_link_libraries(GUI.Code.Tests PRIVATE Foundation::GUI.Code Foundation::GUI Foundation::Xml.Serialization doctest::doctest)

target_compile_definitions(GUI.Code.Tests PRIVATE
    DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS
    GUI_CODE_SANDBOX_LANGUAGES="${CMAKE_SOURCE_DIR}/Data/Assets/ui/sandbox/code")

target_compile_options(GUI.Code.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings;-Wno-error=c2y-extensions>"
    "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")

add_test(NAME GUI.Code.Tests COMMAND GUI.Code.Tests)
