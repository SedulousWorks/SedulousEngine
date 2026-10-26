// The GUI lab's showcase (G6 of Raptor's Documentation/Specs/vg-and-gui-lab.md): the menu's
// behaviour, in AngelScript, through the GUI's script surface alone, on the gamekit (K7 of
// gui-lab-evolution-3.md). The markup holds the widgets (menu.xml the frame, screens/ a document
// per screen) and the sheet (menu.css) their looks, entrances and exits. This script pushes and
// pops the screens on the gamekit's stack, wires each screen's buttons as it is pushed (fresh each
// time), runs the loading bar and, once loading is done, a stand-in game under the HUD (E10 of
// gui-lab-evolution-2.md): the score counting up, health draining and healing, the run's clock,
// and a pause screen on Escape, a pad's East or Start. Back (Escape, East) is the stack's: it pops
// the top screen, and the title keeps it. The host calls main() once, then update(dt) while it
// returns true.
//
// The handlers are the surface's EventHandler shape: each returns false, so a click goes on as
// Raptor's void handlers left it.

const string kScreens = "Assets/ui/showcase/screens/";

ScreenStack@ stack; // the game's screens
Node@ stage;        // the title over the menu's pages
Screen@ hud;        // the game's HUD while a game runs (null otherwise)
bool loadingNow = false;
double loadTime = 0;
double untilGame = -1; // seconds from "Ready" to the HUD (-1: not waiting)
double gameTime = 0;
double nextPoint = 0;
int score = 0;
bool popTurn = false;

Screen@ push(const string &in name) { return stack.Push(kScreens + name + ".xml"); }
bool popScreen(GuiEvent@ e) { stack.Pop(); return false; }

// === The menu ===

void showTitle()
{
    stage.Displayed = true;
    Screen@ title = push("title");
    title.Find("play").On("click", EventHandler(onPlay));
    title.Find("settings-btn").On("click", EventHandler(onSettings));
    title.Find("controls-btn").On("click", EventHandler(onControls));
    title.Find("quit").On("click", EventHandler(onQuit));
}

string volumeText() { return "" + int(Gui.GetNumber("volume") * 100 + 0.5) + "%"; }
string musicText() { return Gui.Tr(Gui.GetBool("music") ? "settings.on" : "settings.off"); }

bool onSettings(GuiEvent@ e)
{
    Screen@ page = push("settings");
    page.Find("settings-back").On("click", EventHandler(popScreen));
    // Labels that follow the data through functions of it: no handler updates them.
    page.Find("volume-text").Bind("Text", TextExpression(volumeText));
    page.Find("music-text").Bind("Text", TextExpression(musicText));
    return false;
}

// === Controls (E12 of gui-lab-evolution-2.md) ===
// Each action's key, bound to its command in the game's key context. Choosing one listens for the
// next key or pad button (Gui.CaptureKey, before the keymap and navigation see it); a key another
// action had swaps over to it; Escape cancels.
array<string> actions = {"jump", "dash", "interact", "map"};
array<string> keys = {"space", "leftshift", "e", "m"};
int listening = -1; // the action waiting for its key (-1: none)
Screen@ controls;

bool onControls(GuiEvent@ e)
{
    @controls = push("controls");
    controls.Find("bind-jump").On("click", EventHandler(onBindJump));
    controls.Find("bind-dash").On("click", EventHandler(onBindDash));
    controls.Find("bind-interact").On("click", EventHandler(onBindInteract));
    controls.Find("bind-map").On("click", EventHandler(onBindMap));
    controls.Find("controls-back").On("click", EventHandler(popScreen));
    Gui.SetText("controls-hint", Gui.Tr("controls.choose"));
    showKeys();
    return false;
}
void showKeys()
{
    for (uint i = 0; i < actions.length(); i++)
    {
        Gui.SetText("key-" + actions[i], Gui.KeyText(keys[i]));
        Gui.BindKey(keys[i], "game." + actions[i], "game");
    }
}
void listen(int action)
{
    if (listening >= 0)
        return;
    listening = action;
    UIWidget::Of(controls.Find("bind-" + actions[action])).AddClass("listening");
    Gui.SetText("key-" + actions[action], Gui.Tr("controls.press"));
    Gui.SetText("controls-hint", Gui.Tr("controls.keep") + Gui.KeyText(keys[action]));
    Gui.CaptureKey(KeyHandler(onCapturedKey));
}
void onCapturedKey(const string &in pressed)
{
    const int action = listening;
    listening = -1;
    UIWidget::Of(controls.Find("bind-" + actions[action])).RemoveClass("listening");
    Gui.SetText("controls-hint", Gui.Tr("controls.choose"));
    if (pressed != "")
    {
        for (uint i = 0; i < actions.length(); i++)
            if (int(i) != action && keys[i] == pressed)
            {
                keys[i] = keys[action]; // taken: the two swap
                Gui.SetText("controls-hint", Gui.Tr("controls.swapped") + Gui.Tr("controls." + actions[i]));
            }
        Gui.BindKey(keys[action], "", "game"); // the old key unbound there
        keys[action] = pressed;
    }
    showKeys();
}
bool onBindJump(GuiEvent@ e) { listen(0); return false; }
bool onBindDash(GuiEvent@ e) { listen(1); return false; }
bool onBindInteract(GuiEvent@ e) { listen(2); return false; }
bool onBindMap(GuiEvent@ e) { listen(3); return false; }

// === Loading ===

bool onPlay(GuiEvent@ e)
{
    Screen@ loading = push("loading");
    loading.Find("loading-back").On("click", EventHandler(popScreen));
    loading.On("screenleave", EventHandler(onLoadingLeave)); // Back, or the game starting
    stage.Displayed = false; // the loading screen replaces the menu
    Gui.SetText("status", Gui.Tr("loading.loading"));
    Gui.SetNumber("progress", 0);
    loadTime = 0;
    loadingNow = true;
    return false;
}
bool onLoadingLeave(GuiEvent@ e)
{
    loadingNow = false;
    untilGame = -1;
    stage.Displayed = hud is null; // back on the menu, unless the game took over
    return false;
}

// === Quit ===
// The question opens over the menu, which stays where it is behind the dimmed glass; Stay and Back
// pop it, the focus back on Quit.
bool onQuit(GuiEvent@ e)
{
    Screen@ question = push("quit");
    question.Find("confirm-yes").On("click", EventHandler(onLeave));
    question.Find("confirm-no").On("click", EventHandler(popScreen));
    return false;
}
bool onLeave(GuiEvent@ e)
{
    // The whole menu fades out; once `quit` is set and the fade has run, the host takes the player
    // back to where they came from (the sandbox).
    UIWidget::Of(Gui.Root().Find("showcase")).AddClass("closing");
    Gui.SetBool("quit", true);
    return false;
}

// === The game ===

void startGame()
{
    untilGame = -1;
    score = 0;
    gameTime = 0;
    nextPoint = 1.2;
    Gui.SetNumber("score", 0);
    Gui.SetNumber("health", 1.0);
    Gui.SetText("clock", "0:00");
    @hud = null;
    stack.Clear(); // the menu and the loading screen leave as the HUD comes in
    @hud = push("hud");
    stage.Displayed = false;
    hud.OnCommand("back", CommandHandler(onPauseCommand)); // in the game, Back pauses
}
// Pause (Back in the game, and Start): opens the pause screen over the HUD, or closes it.
bool onPauseCommand()
{
    if (hud is null)
        return true; // not in a game: someone else's
    if (stack.IsPaused)
        stack.Pop();
    else
    {
        Screen@ pause = push("pause");
        pause.Find("resume").On("click", EventHandler(popScreen));
        pause.Find("to-menu").On("click", EventHandler(onToMenu));
    }
    return false;
}
bool onToMenu(GuiEvent@ e) { enter(); return false; }

// A second of the stand-in game: a point now and then (the number counts up and pops), health
// draining and, low, warning, then healed by a point.
void play(double dt)
{
    gameTime += dt;
    int seconds = int(gameTime);
    Gui.SetText("clock", "" + (seconds / 60) + ":" + ((seconds % 60) < 10 ? "0" : "") + (seconds % 60));
    double health = Gui.GetNumber("health") - dt * 0.06;
    nextPoint -= dt;
    if (nextPoint <= 0)
    {
        nextPoint = 1.4;
        score += 10;
        Gui.Tween("score", score, 0.35, "ease-out").Whole(true); // the data counts up in whole numbers: no widget drives it
        UIWidget@ number = UIWidget::Of(hud.Find("hud-score"));
        number.RemoveClass(popTurn ? "pop-a" : "pop-b");
        number.AddClass(popTurn ? "pop-b" : "pop-a");
        popTurn = !popTurn;
        if (health < 0.3)
            health = 1.0; // a light gathered heals
    }
    if (health < 0)
        health = 0;
    Gui.SetNumber("health", health);
    UIWidget@ bar = UIWidget::Of(hud.Find("hud-health"));
    if (health < 0.3)
        bar.AddClass("hp-low");
    else
        bar.RemoveClass("hp-low");
}

void main()
{
    Node@ root = Gui.Root();
    @stack = ScreenStack::Of(root.Find("screens"));
    @stage = root.Find("stage");
    // Start pauses in the game. The handler is the menu's own: it is a modal layer of the
    // sandbox's root, and a command from inside it stops at its edge.
    root.Find("showcase").OnCommand("pause", CommandHandler(onPauseCommand));
    Gui.BindKey("pad-start", "pause", "");
    enter();
}

// The menu as it opens (the host calls this each time it shows the menu): the title screen alone,
// nothing left over from the last visit.
void enter()
{
    loadingNow = false;
    untilGame = -1;
    @hud = null;
    UIWidget::Of(Gui.Root().Find("showcase")).RemoveClass("closing");
    stack.Clear();
    showTitle();
}

// The loading bar fills over two and a half seconds, then the game runs while it is not paused;
// true while there is more to do.
bool update(double dt)
{
    if (untilGame >= 0)
    {
        untilGame -= dt;
        if (untilGame < 0)
            startGame();
    }
    if (hud !is null && !stack.IsPaused)
        play(dt);
    if (loadingNow)
    {
        loadTime += dt;
        double progress = loadTime / 2.5;
        if (progress >= 1)
        {
            progress = 1;
            loadingNow = false;
            Gui.SetText("status", Gui.Tr("loading.ready"));
            untilGame = 0.6; // a moment on "Ready", then the game
        }
        Gui.SetNumber("progress", progress);
    }
    return loadingNow || untilGame >= 0 || hud !is null;
}
