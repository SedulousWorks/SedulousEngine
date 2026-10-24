# Foundation::GUI.Toolkit - `foundation.gui.toolkit`: editor widgets: tool and status bars, the property grid, colour, curves, gradients, the timeline, node graphs, the breadcrumb bar. Docking is not here (GUI.Docking), nor the code editor (GUI.Code).
# foundation.ui's counterpart: UI.Toolkit less docking and the code editor. Specs/gui-lab-evolution-3.md.
util_add_engine_library(GUI.Toolkit ALIAS Foundation::GUI.Toolkit)
target_link_libraries(GUI.Toolkit
    PUBLIC Foundation::Core Foundation::VG Foundation::GUI Foundation::Policy)

target_sources(GUI.Toolkit
    PUBLIC
        FILE_SET guitoolkit_modules TYPE CXX_MODULES FILES
            ToolkitModule.cppm
            ToolkitSheet.cppm
            ToolBar.cppm
            StatusBar.cppm
            PropertySource.cppm
            PropertyEditor.cppm
            PropertyEditors.cppm
            PropertyGrid.cppm
            ReflectedSource.cppm
            TimeAxis.cppm
            TimelineSource.cppm
            CurveSource.cppm
            CurveView.cppm
            GradientView.cppm
            Dopesheet.cppm
            CurveEditors.cppm
            GraphSource.cppm
            GraphNodePicker.cppm
            GraphView.cppm
            BreadcrumbBar.cppm
    PRIVATE
        ToolkitReflection.cpp)
