# Foundation::GUI.Gamekit - `foundation.gui.gamekit`: a game's screens: a screen stack, input modes, transitions, prompts.
# foundation.ui's counterpart: UI.Gamekit. Specs/gui-lab-evolution-3.md, section K.
util_add_engine_library(GUI.Gamekit ALIAS Foundation::GUI.Gamekit)
target_link_libraries(GUI.Gamekit
    PUBLIC Foundation::Core Foundation::GUI Foundation::Input Foundation::Policy)

target_sources(GUI.Gamekit
    PUBLIC
        FILE_SET guigamekit_modules TYPE CXX_MODULES FILES
            GamekitModule.cppm
            ScreenStack.cppm
            Prompt.cppm
    PRIVATE
        GamekitReflection.cpp)
