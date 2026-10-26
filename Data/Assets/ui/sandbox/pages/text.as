// Text: the rich text's links and the field's events, shown through the GUI's data.
int inputs = 0;
int changes = 0;
int submits = 0;

void showEvents(const string &in last)
{
    Gui.SetText("fieldEvents", "input " + inputs + ", change " + changes + ", submit " + submits + (last == "" ? "" : ": " + last));
}

bool onLink(GuiEvent@ e) { Gui.SetText("linkText", "link: " + e.Text); return true; }
bool onInput(GuiEvent@ e) { ++inputs; showEvents(""); return false; }
bool onChange(GuiEvent@ e) { ++changes; showEvents("committed"); return false; }
bool onSubmit(GuiEvent@ e) { ++submits; showEvents("submitted"); return false; }

void main()
{
    Gui.SetText("linkText", "Click a link: it is reported as a link event with its id.");
    showEvents("");
    Node@ root = Gui.Root();
    root.Find("text-rich").On("link", EventHandler(onLink));
    root.Find("text-field").On("input", EventHandler(onInput));
    root.Find("text-field").On("change", EventHandler(onChange));
    root.Find("text-field").On("submit", EventHandler(onSubmit));
}
