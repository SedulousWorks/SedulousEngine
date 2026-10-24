add_executable(Engine.GUI.Tests TestsMain.cpp GuiSubsystemTests.cpp)
target_link_libraries(Engine.GUI.Tests PRIVATE
    Engine::GUI Engine::Scene Engine::Render Foundation::Scene Foundation::Runtime Foundation::Render
    Foundation::Resource Foundation::Content Foundation::VFS Foundation::Image Foundation::Texture.Resource
    Foundation::VG.Resource Foundation::VG.SVG Foundation::RHI Foundation::RHI.Null
    Foundation::GUI Foundation::GUI.Gamekit Foundation::GUI.Resources Foundation::Script.Facades
    doctest::doctest)
target_compile_definitions(Engine.GUI.Tests PRIVATE DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)
target_compile_options(Engine.GUI.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings>" "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")
add_test(NAME Engine.GUI.Tests COMMAND Engine.GUI.Tests)
