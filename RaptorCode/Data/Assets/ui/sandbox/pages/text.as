// Text: the rich text's links and the field's events, shown through the GUI's data.
funcdef bool EventHandler(GuiEvent e);

int inputs = 0;
int changes = 0;
int submits = 0;

void showEvents(const string &in last)
{
    gui::set("fieldEvents", "input " + inputs + ", change " + changes + ", submit " + submits + (last == "" ? "" : ": " + last));
}

bool onLink(GuiEvent e) { gui::set("linkText", "link: " + e.text); return true; }
bool onInput(GuiEvent e) { ++inputs; showEvents(""); return false; }
bool onChange(GuiEvent e) { ++changes; showEvents("committed"); return false; }
bool onSubmit(GuiEvent e) { ++submits; showEvents("submitted"); return false; }

void main()
{
    gui::set("linkText", "Click a link: it is reported as a link event with its id.");
    showEvents("");
    Node@ root = gui::root();
    root.find("text-rich").on("link", EventHandler(onLink));
    root.find("text-field").on("input", EventHandler(onInput));
    root.find("text-field").on("change", EventHandler(onChange));
    root.find("text-field").on("submit", EventHandler(onSubmit));
}
