// The Code page's script: a counter for a page.
// It is only checked, never run.

funcdef bool EventHandler(GuiEvent e);

int clicks = 0;

// The label says how many times the button was pressed.
void show(Label@ label)
{
    label.text = "Pressed " + clicks + (clicks == 1 ? " time" : " times");
}

bool pressed(GuiEvent e)
{
    ++clicks;
    Node@ root = gui::root();
    show(Label::of(root.find("counter-label")));
    // A misspelling the compiler marks: tweem is no method of Node.
    root.find("counter-button").tweem("opacity", "0.6", 0.1, "ease-out");
    return true;
}

void reset()
{
    clicks = 0;
    show(Label::of(gui::root().find("counter-label")));
}
