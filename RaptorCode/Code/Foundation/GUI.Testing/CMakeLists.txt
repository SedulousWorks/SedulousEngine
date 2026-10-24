# Foundation::GUI.Testing - `foundation.gui.testing`, helpers for tests of GUIs built with the
# lab (E8f of Specs/gui-lab-evolution.md): a tester stepping frames on a fixed clock, finders by
# selector and text, and the user's actions on what they find.
util_add_engine_library(GUI.Testing ALIAS Foundation::GUI.Testing)
target_link_libraries(GUI.Testing
    PUBLIC Foundation::GUI Foundation::GUI.Inspector Foundation::Core Foundation::Image)

target_sources(GUI.Testing
    PUBLIC
        FILE_SET guitesting_modules TYPE CXX_MODULES FILES
            Testing.cppm)
