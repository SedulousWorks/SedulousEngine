// Navigation and commands: the editor panel handles "demo.cut", so the Cut button (bound to the
// command) is lit only while focus is inside it; Ctrl+X runs it there through a binding in the
// "editor" key context.
bool cut() { Gui.SetNumber("cuts", Gui.GetNumber("cuts") + 1); return false; }
void main()
{
    Gui.DefineCommand("demo.cut", "Cut");
    Gui.Root().Find("navigation-editor").OnCommand("demo.cut", CommandHandler(cut));
    Gui.BindKey("ctrl-x", "demo.cut", "editor");
}
