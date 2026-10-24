# Engine::GUI - `engine.gui`: the engine's GUI on foundation.gui (E5 of Specs/gui-lab-evolution-3.md):
# one GUI for the application, a screen tier and a scene tier, drawn into the engine's overlay
# passes; the resource provider answering asset guids; the domain. Engine.UI's counterpart, beside
# it while both live.
util_add_engine_library(Engine.GUI ALIAS Engine::GUI)
target_link_libraries(Engine.GUI
    PUBLIC Foundation::Core Foundation::Runtime Foundation::Scene Engine::Scene Engine::Domain
           Foundation::Resource Foundation::Content Foundation::RHI Foundation::VFS Foundation::Image
           Foundation::Fonts Foundation::Fonts.TrueType Foundation::Fonts.Resource Foundation::Fonts.HarfBuzz Foundation::Fonts.Bidi
           Foundation::VG Foundation::VG.SVG Foundation::VG.Renderer Foundation::VG.Resource Foundation::Texture.Resource
           Foundation::Render Engine::Render Foundation::Shell Foundation::Input Engine::Input
           Foundation::GUI Foundation::GUI.Shell Foundation::GUI.Gamekit Foundation::GUI.Resources Foundation::GUI.Hosting
           Foundation::Script Foundation::Script.Facades Foundation::Profiler Foundation::Policy)
target_sources(Engine.GUI
    PRIVATE
        GuiSubsystemImpl.cpp   # implementation unit: the renderer, the shaders, the textures
    PUBLIC
        FILE_SET engine_gui_modules TYPE CXX_MODULES FILES
            GuiSubsystem.cppm)
