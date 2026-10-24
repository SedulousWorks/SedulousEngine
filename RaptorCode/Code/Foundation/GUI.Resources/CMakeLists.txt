# Foundation::GUI.Resources - `foundation.gui.resources`: cooked GUI documents and style sheets
# (validated text), free of the GUI framework. foundation.ui's counterpart: UI.Resource.
# Specs/gui-lab-evolution-3.md, E2.
util_add_engine_library(GUI.Resources ALIAS Foundation::GUI.Resources)
target_link_libraries(GUI.Resources
    PUBLIC Foundation::Core Foundation::Resource Foundation::Content Foundation::Policy)

target_sources(GUI.Resources
    PUBLIC
        FILE_SET guiresources_modules TYPE CXX_MODULES FILES
            ResourcesModule.cppm)
