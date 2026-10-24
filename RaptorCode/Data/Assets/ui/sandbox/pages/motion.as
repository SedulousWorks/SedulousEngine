// Motion: a level's end, played with tweens (E14). The card fades in and springs from small to
// its size; a sequence waits, pops each gem (a fade beside an ease-out-back scale, together),
// fills the score bar while a label bound to it counts, then slides a toast in, waits and slides
// it out. Every tween gives its start, so playing again starts over from the same place.

funcdef bool EventHandler(GuiEvent e);
funcdef string TextExpression();

TweenGroup@ pop(Node@ gem)
{
    return TweenParallel()
        .add(gem.createTween("opacity", "1", 0.2, "linear").from("0"))
        .add(gem.createTween("transform", "rotate(45deg) scale(1)", 0.35, "ease-out-back").from("rotate(45deg) scale(0.2)"));
}

void play()
{
    Node@ root = gui::root();
    Node@ card = root.find("motion-card");
    Node@ bar = root.find("motion-score-bar");
    Node@ toast = root.find("motion-toast");
    card.tween("opacity", "1", 0.25, "ease-out").from("0");
    card.springTo("transform", "scale(1)", 260, 14, 1).from("scale(0.6)");
    for (int i = 1; i <= 3; ++i)
        root.find("motion-gem-" + i).tween("opacity", "0", 0, "linear"); // hidden until popped
    bar.tween("value", "0", 0, "linear");
    toast.tween("opacity", "0", 0, "linear");
    card.play(TweenSequence()
        .wait(0.35)
        .addGroup(pop(root.find("motion-gem-1")))
        .addGroup(pop(root.find("motion-gem-2")))
        .addGroup(pop(root.find("motion-gem-3")))
        .add(bar.createTween("value", "100", 1.2, "ease-out-cubic").from("0"))
        .addGroup(TweenParallel()
            .add(toast.createTween("opacity", "1", 0.25, "linear").from("0"))
            .add(toast.createTween("transform", "translate(0, 0)", 0.4, "ease-out-back").from("translate(120px, 0)")))
        .wait(1.6)
        .addGroup(TweenParallel()
            .add(toast.createTween("opacity", "0", 0.3, "linear"))
            .add(toast.createTween("transform", "translate(120px, 0)", 0.3, "ease-in-cubic"))));
}

bool replay(GuiEvent e)
{
    play();
    return true;
}

string score() { return "Score " + int(ProgressBar::of(gui::root().find("motion-score-bar")).value * 125 + 0.5); }

void main()
{
    gui::root().find("motion-replay").on("click", EventHandler(replay));
    gui::root().find("motion-score").bind("text", TextExpression(score));
}
