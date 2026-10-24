// Navigation and commands: the editor panel handles "demo.cut", so the Cut button (bound to the
// command) is lit only while focus is inside it; Ctrl+X runs it there through a binding in the
// "editor" key context.
funcdef bool CommandHandler();
bool cut() { gui::set("cuts", gui::getNumber("cuts") + 1); return false; }
void main()
{
    gui::defineCommand("demo.cut", "Cut");
    gui::root().find("navigation-editor").onCommand("demo.cut", CommandHandler(cut));
    gui::bindKey("ctrl-x", "demo.cut", "editor");
}
