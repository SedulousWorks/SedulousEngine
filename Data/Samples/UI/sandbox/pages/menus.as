// Menus and windows: the menus written in markup say what was picked. An item's `activate`
// bubbles, through its menu to what opened it, so one listener on the section hears them all;
// the event's id names the item. And what the script builds itself (E16): a menu of sixty items,
// longer than the window, which scrolls, and a window of its own; and a toast it fills in and posts.

bool picked(GuiEvent@ e)
{
    Label::Of(Gui.Root().Find("menus-markup-said")).Text = "Picked from markup: " + e.Id;
    return true;
}

Node@ longMenu;
Node@ scriptWindow;

bool pickedLong(GuiEvent@ e)
{
    Label::Of(Gui.Root().Find("menus-long-said")).Text = "Picked from the long menu: " + e.Id;
    return true;
}

bool openLong(GuiEvent@ e)
{
    Menu::Of(longMenu).OpenBelow(Gui.Root().Find("menus-long"));
    return true;
}

// A window of the script's own, built when asked (a window closed by its button is gone).
bool openWindow(GuiEvent@ e)
{
    if (scriptWindow is null || !scriptWindow.IsValid)
    {
        @scriptWindow = Gui.Root().Add("Window"); // over the whole GUI, centred in it
        scriptWindow.Width = 320;
        scriptWindow.Height = 160;
        Window::Of(scriptWindow).Title = "From menus.as";
        Node@ text = scriptWindow.Add("Label");
        Label::Of(text).Text = "The page's script built this window and its text.";
        UIWidget::Of(text).AddClass("text");
    }
    if (!Window::Of(scriptWindow).IsOpen)
        Window::Of(scriptWindow).Open();
    return true;
}

// A toast the script fills in and posts (T7 of round three), its action heard as an `activate`.
bool postToast(GuiEvent@ e)
{
    ToastRequest@ request = ToastRequest();
    request.Title = "From menus.as";
    request.Message = "The page's script filled in this request and posted it.";
    request.Severity = ToastSeverity::Success;
    request.Classes = "pop";
    request.AddAction("again", "Again", "");
    ToastHost::Nearest(Gui.Root()).Post(request);
    return true;
}

bool toastAction(GuiEvent@ e)
{
    if (e.Id == "again")
        Label::Of(Gui.Root().Find("toast-said")).Text = "The script heard its toast's action: " + e.Id + ".";
    return true;
}

void main()
{
    Node@ root = Gui.Root();
    root.Find("menus-markup").On("activate", EventHandler(picked));
    root.Find("toast-script").On("click", EventHandler(postToast));
    ToastHost::Nearest(root).On("activate", EventHandler(toastAction));

    // A menu longer than the window: it scrolls.
    @longMenu = root.Find("menus-long").Add("Menu");
    for (int i = 1; i <= 60; ++i)
    {
        Node@ item = longMenu.Add("MenuItem");
        MenuItem::Of(item).Text = "Item " + i;
        UIWidget::Of(item).Id = "item " + i;
    }
    longMenu.On("activate", EventHandler(pickedLong));
    root.Find("menus-long").On("click", EventHandler(openLong));

    root.Find("menus-script-window").On("click", EventHandler(openWindow));
}
