# Foundation::GUI.Code - `foundation.gui.code`: the code editor (a document of lines, multi-cursor
# editing, incremental highlighting from language definitions its owners supply, diagnostics,
# completion through a language service). foundation.ui's counterpart: UI.Toolkit's CodeEditView.
# Specs/gui-lab-evolution-3.md, phases C0 to C8.
util_add_engine_library(GUI.Code ALIAS Foundation::GUI.Code)
target_link_libraries(GUI.Code
    PUBLIC Foundation::Core Foundation::GUI Foundation::Policy)

target_sources(GUI.Code
    PUBLIC
        FILE_SET guicode_modules TYPE CXX_MODULES FILES
            CodeModule.cppm
            CodeDocument.cppm
            CodeLanguage.cppm
            CodeSheet.cppm
            CodeFindBar.cppm
            CodeCompletion.cppm
            CodeEditor.cppm
    PRIVATE
        CodeReflection.cpp)
