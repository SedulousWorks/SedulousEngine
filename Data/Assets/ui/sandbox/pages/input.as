// Input: the clickable card counts the clicks that reach it (the button's stop at the button);
// the pad shows where it was pressed and how many presses of a run that was; the glass over a
// button lets clicks through (pointer-events: none); the canvas says what was dropped on it; the
// viewer turns two fingers' gestures into its picture's transform.
bool onCard(GuiEvent@ e) { Gui.SetNumber("cardClicks", Gui.GetNumber("cardClicks") + 1); return false; }
bool onCardButton(GuiEvent@ e) { Gui.SetNumber("buttonClicks", Gui.GetNumber("buttonClicks") + 1); return false; }
bool onPad(GuiEvent@ e)
{
    Gui.SetNumber("padX", int(e.LocalX));
    Gui.SetNumber("padY", int(e.LocalY));
    Gui.SetNumber("padClicks", e.ClickCount);
    return true;
}
bool onGlass(GuiEvent@ e) { Gui.SetNumber("glassClicks", Gui.GetNumber("glassClicks") + 1); return false; }
bool onPaint(GuiEvent@ e) { Gui.SetText("paint", e.Text + " (" + e.Effect + ")"); return true; }

// The viewer (E17c): where the last gesture left the picture, and each gesture on top of it.
double viewX = 0; double viewY = 0; double viewScale = 1; double viewTurn = 0; // degrees
void showView(double x, double y, double scale, double turn)
{
    Gui.Root().Find("input-photo").Tween("transform", "translate(" + x + "px, " + y + "px) rotate(" + turn + "deg) scale(" + scale + ")", 0, "linear");
    Gui.SetText("viewer", "Scale " + int(scale * 100 + 0.5) + "%, turned " + int(turn) + " degrees, moved " + int(x) + ", " + int(y));
}
bool onGesture(GuiEvent@ e)
{
    showView(viewX + e.TranslationX, viewY + e.TranslationY, viewScale * e.Scale, viewTurn + e.Rotation * 57.29578);
    return true;
}
bool onGestureEnd(GuiEvent@ e)
{
    viewX += e.TranslationX;
    viewY += e.TranslationY;
    viewScale *= e.Scale;
    viewTurn += e.Rotation * 57.29578;
    showView(viewX, viewY, viewScale, viewTurn);
    return true;
}
bool onGestureCancel(GuiEvent@ e) { showView(viewX, viewY, viewScale, viewTurn); return true; } // back where it was
bool onViewReset(GuiEvent@ e)
{
    viewX = 0; viewY = 0; viewScale = 1; viewTurn = 0;
    showView(viewX, viewY, viewScale, viewTurn);
    return true;
}
void main()
{
    Gui.SetNumber("cardClicks", 0);
    Gui.SetNumber("buttonClicks", 0);
    Gui.SetNumber("padX", 0);
    Gui.SetNumber("padY", 0);
    Gui.SetNumber("padClicks", 0);
    Gui.SetNumber("glassClicks", 0);
    Gui.SetText("paint", "nothing yet");
    Node@ root = Gui.Root();
    root.Find("input-click-card").On("click", EventHandler(onCard));
    root.Find("input-card-button").On("click", EventHandler(onCardButton));
    root.Find("input-pad").On("mousedown", EventHandler(onPad));
    root.Find("input-under-glass").On("click", EventHandler(onGlass));
    root.Find("input-canvas").On("drop", EventHandler(onPaint));
    Node@ viewer = root.Find("input-viewer");
    viewer.On("gesturechange", EventHandler(onGesture));
    viewer.On("gestureend", EventHandler(onGestureEnd));
    viewer.On("gesturecancel", EventHandler(onGestureCancel));
    root.Find("input-viewer-reset").On("click", EventHandler(onViewReset));
    Gui.SetText("viewer", "Scale 100%, turned 0 degrees, moved 0, 0");
}
