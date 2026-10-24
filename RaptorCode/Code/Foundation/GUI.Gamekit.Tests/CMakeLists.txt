# Foundation::GUI.Gamekit's tests: a game's screens (K4 of Specs/gui-lab-evolution-3.md), from
# code and markup. Backend-neutral: its script surface is tested in Integration.ScriptFacades.
add_executable(GUI.Gamekit.Tests
    ScreenStackTests.cpp
    PromptTests.cpp
    TestsMain.cpp)

target_link_libraries(GUI.Gamekit.Tests PRIVATE
    Foundation::GUI.Gamekit Foundation::GUI Foundation::Core doctest::doctest)

target_compile_definitions(GUI.Gamekit.Tests PRIVATE
    DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)

target_compile_options(GUI.Gamekit.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings;-Wno-error=c2y-extensions>"
    "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")

add_test(NAME GUI.Gamekit.Tests COMMAND GUI.Gamekit.Tests)
