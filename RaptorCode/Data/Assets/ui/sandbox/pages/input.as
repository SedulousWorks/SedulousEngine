// Input: the clickable card counts the clicks that reach it (the button's stop at the button);
// the pad shows where it was pressed and how many presses of a run that was; the glass over a
// button lets clicks through (pointer-events: none); the canvas says what was dropped on it; the
// viewer turns two fingers' gestures into its picture's transform.
funcdef bool EventHandler(GuiEvent e);
bool onCard(GuiEvent e) { gui::set("cardClicks", gui::getNumber("cardClicks") + 1); return false; }
bool onCardButton(GuiEvent e) { gui::set("buttonClicks", gui::getNumber("buttonClicks") + 1); return false; }
bool onPad(GuiEvent e)
{
    gui::set("padX", int(e.localX));
    gui::set("padY", int(e.localY));
    gui::set("padClicks", e.clickCount);
    return true;
}
bool onGlass(GuiEvent e) { gui::set("glassClicks", gui::getNumber("glassClicks") + 1); return false; }
bool onPaint(GuiEvent e) { gui::set("paint", e.text + " (" + e.effect + ")"); return true; }

// The viewer (E17c): where the last gesture left the picture, and each gesture on top of it.
double viewX = 0; double viewY = 0; double viewScale = 1; double viewTurn = 0; // degrees
void showView(double x, double y, double scale, double turn)
{
    gui::root().find("input-photo").tween("transform", "translate(" + x + "px, " + y + "px) rotate(" + turn + "deg) scale(" + scale + ")", 0, "linear");
    gui::set("viewer", "Scale " + int(scale * 100 + 0.5) + "%, turned " + int(turn) + " degrees, moved " + int(x) + ", " + int(y));
}
bool onGesture(GuiEvent e)
{
    showView(viewX + e.translationX, viewY + e.translationY, viewScale * e.scale, viewTurn + e.rotation * 57.29578);
    return true;
}
bool onGestureEnd(GuiEvent e)
{
    viewX += e.translationX;
    viewY += e.translationY;
    viewScale *= e.scale;
    viewTurn += e.rotation * 57.29578;
    showView(viewX, viewY, viewScale, viewTurn);
    return true;
}
bool onGestureCancel(GuiEvent e) { showView(viewX, viewY, viewScale, viewTurn); return true; } // back where it was
bool onViewReset(GuiEvent e)
{
    viewX = 0; viewY = 0; viewScale = 1; viewTurn = 0;
    showView(viewX, viewY, viewScale, viewTurn);
    return true;
}
void main()
{
    gui::set("cardClicks", 0);
    gui::set("buttonClicks", 0);
    gui::set("padX", 0);
    gui::set("padY", 0);
    gui::set("padClicks", 0);
    gui::set("glassClicks", 0);
    gui::set("paint", "nothing yet");
    Node@ root = gui::root();
    root.find("input-click-card").on("click", EventHandler(onCard));
    root.find("input-card-button").on("click", EventHandler(onCardButton));
    root.find("input-pad").on("mousedown", EventHandler(onPad));
    root.find("input-under-glass").on("click", EventHandler(onGlass));
    root.find("input-canvas").on("drop", EventHandler(onPaint));
    Node@ viewer = root.find("input-viewer");
    viewer.on("gesturechange", EventHandler(onGesture));
    viewer.on("gestureend", EventHandler(onGestureEnd));
    viewer.on("gesturecancel", EventHandler(onGestureCancel));
    root.find("input-viewer-reset").on("click", EventHandler(onViewReset));
    gui::set("viewer", "Scale 100%, turned 0 degrees, moved 0, 0");
}
