# Editor::GUI - `editor.gui`: the editor's pages for the engine GUI's assets (E10 of
# Specs/gui-lab-evolution-3.md): a .gml document and a .css sheet, each its text with a live
# preview drawn by the engine GUI. Built only with the GUI.
util_add_engine_library(Editor.GUI ALIAS Editor::GUI)
target_link_libraries(Editor.GUI PUBLIC
    Foundation::Core Foundation::Content Foundation::Runtime.Client Foundation::UI Foundation::UI.Toolkit
    Foundation::UI.Runtime Foundation::UI.Viewport Foundation::Graphics Foundation::RHI Foundation::VG.Renderer
    Foundation::GUI Pipeline::GUI Pipeline::Core Engine::GUI
    Editor::Core Editor::App Foundation::Policy)
target_sources(Editor.GUI
    PRIVATE GuiPagesImpl.cpp
    PUBLIC FILE_SET editor_gui_modules TYPE CXX_MODULES FILES GuiPages.cppm)
