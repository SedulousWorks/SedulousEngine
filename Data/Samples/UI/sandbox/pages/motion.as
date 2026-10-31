// Motion: a level's end, played with tweens (E14). The card fades in and springs from small to
// its size; a sequence waits, pops each gem (a fade beside an ease-out-back scale, together),
// fills the score bar while a label bound to it counts, then slides a toast in, waits and slides
// it out. Every tween gives its start, so playing again starts over from the same place.

TweenGroup@ pop(Node@ gem)
{
    return TweenParallel()
        .Add(gem.CreateTween("opacity", "1", 0.2, "linear").From("0"))
        .Add(gem.CreateTween("transform", "rotate(45deg) scale(1)", 0.35, "ease-out-back").From("rotate(45deg) scale(0.2)"));
}

void play()
{
    Node@ root = Gui.Root();
    Node@ card = root.Find("motion-card");
    Node@ bar = root.Find("motion-score-bar");
    Node@ toast = root.Find("motion-toast");
    card.Tween("opacity", "1", 0.25, "ease-out").From("0");
    card.SpringTo("transform", "scale(1)", 260, 14, 1).From("scale(0.6)");
    for (int i = 1; i <= 3; ++i)
        root.Find("motion-gem-" + i).Tween("opacity", "0", 0, "linear"); // hidden until popped
    bar.Tween("value", "0", 0, "linear");
    toast.Tween("opacity", "0", 0, "linear");
    card.Play(TweenSequence()
        .Wait(0.35)
        .AddGroup(pop(root.Find("motion-gem-1")))
        .AddGroup(pop(root.Find("motion-gem-2")))
        .AddGroup(pop(root.Find("motion-gem-3")))
        .Add(bar.CreateTween("value", "100", 1.2, "ease-out-cubic").From("0"))
        .AddGroup(TweenParallel()
            .Add(toast.CreateTween("opacity", "1", 0.25, "linear").From("0"))
            .Add(toast.CreateTween("transform", "translate(0, 0)", 0.4, "ease-out-back").From("translate(120px, 0)")))
        .Wait(1.6)
        .AddGroup(TweenParallel()
            .Add(toast.CreateTween("opacity", "0", 0.3, "linear"))
            .Add(toast.CreateTween("transform", "translate(120px, 0)", 0.3, "ease-in-cubic"))));
}

bool replay(GuiEvent@ e)
{
    play();
    return true;
}

string score() { return "Score " + int(ProgressBar::Of(Gui.Root().Find("motion-score-bar")).Value * 125 + 0.5); }

void main()
{
    Gui.Root().Find("motion-replay").On("click", EventHandler(replay));
    Gui.Root().Find("motion-score").Bind("Text", TextExpression(score));
}
