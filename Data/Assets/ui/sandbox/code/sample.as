// The Code page's script: a counter for a page.
// It is only checked, never run.

int clicks = 0;

// The label says how many times the button was pressed.
void show(Label@ label)
{
    label.Text = "Pressed " + clicks + (clicks == 1 ? " time" : " times");
}

bool pressed(GuiEvent@ e)
{
    ++clicks;
    Node@ root = Gui.Root();
    show(Label::Of(root.Find("counter-label")));
    // A misspelling the compiler marks: Tweem is no method of Node.
    root.Find("counter-button").Tweem("opacity", "0.6", 0.1, "ease-out");
    return true;
}

void reset()
{
    clicks = 0;
    show(Label::Of(Gui.Root().Find("counter-label")));
}
