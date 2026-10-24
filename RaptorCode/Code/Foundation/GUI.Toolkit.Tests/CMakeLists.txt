add_executable(GUI.Toolkit.Tests
    ToolBarTests.cpp
    StatusBarTests.cpp
    PropertySourceTests.cpp
    PropertyEditorTests.cpp
    PropertyGridTests.cpp
    ReflectedSourceTests.cpp
    TimeAxisTests.cpp
    CurveViewTests.cpp
    GradientViewTests.cpp
    CurveEditorTests.cpp
    DopesheetTests.cpp
    GraphSourceTests.cpp
    GraphViewTests.cpp
    BreadcrumbBarTests.cpp
    TestsMain.cpp)

target_link_libraries(GUI.Toolkit.Tests PRIVATE Foundation::GUI.Toolkit Foundation::GUI Foundation::Xml doctest::doctest)

target_compile_definitions(GUI.Toolkit.Tests PRIVATE
    DOCTEST_CONFIG_NO_EXCEPTIONS_BUT_WITH_ALL_ASSERTS)

target_compile_options(GUI.Toolkit.Tests PRIVATE
    "$<$<CXX_COMPILER_ID:Clang>:-Wno-error=#warnings;-Wno-error=c2y-extensions>"
    "$<$<CXX_COMPILER_ID:GNU>:-Wno-error=cpp>")

add_test(NAME GUI.Toolkit.Tests COMMAND GUI.Toolkit.Tests)
