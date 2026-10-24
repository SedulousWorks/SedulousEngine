// Controls: the buttons count into the GUI's data (a label shows it through {{clicks}}); the bar and
// the number follow the slider, and the echo the text field, through bindings, with no handlers.

funcdef string TextExpression();
funcdef double NumberExpression();

Slider@ slider;
Slider@ vertical;
Slider@ stepped;
Slider@ freq;
TextField@ field;

void add1() { gui::set("clicks", gui::getNumber("clicks") + 1); }
void add5() { gui::set("clicks", gui::getNumber("clicks") + 5); }
void reset() { gui::set("clicks", 0); }

double sliderValue() { return slider.value; }
string sliderText() { return "" + int(slider.value * 100 + 0.5) + "%"; }
string rangesText()
{
    return "vertical " + int(vertical.value) + ", stepped " + int(stepped.value) + " of 10, exponential " + int(freq.value) + " Hz";
}
int logLines = 0;
void addLogLine()
{
    ++logLines;
    Label@ line = Label::of(gui::root().find("controls-log").add("Label"));
    line.text = "Line " + logLines + " arrived";
    line.addClass("scroll-line");
}

int addedTabs = 0;
void addTab()
{
    ++addedTabs;
    TabPage@ page = TabPage::of(gui::root().find("controls-tabs").add("TabPage"));
    page.title = "Added " + addedTabs;
    Label@ body = Label::of(page.add("Label"));
    body.text = "A page added by the script.";
    body.addClass("caption");
}

string echoText() { return field.text == "" ? "(the echo follows the field)" : "echo: " + field.text; }

void main()
{
    Node@ root = gui::root();
    root.find("controls-add").on("click", Action(add1));
    root.find("controls-add5").on("click", Action(add5));
    root.find("controls-reset").on("click", Action(reset));
    root.find("controls-repeat").on("click", Action(add1));
    root.find("controls-press").on("click", Action(add1));
    root.find("controls-log-add").on("click", Action(addLogLine));
    root.find("controls-tab-add").on("click", Action(addTab));
    @slider = Slider::of(root.find("controls-slider"));
    @field = TextField::of(root.find("controls-field"));
    @vertical = Slider::of(root.find("controls-vertical"));
    @stepped = Slider::of(root.find("controls-stepped"));
    @freq = Slider::of(root.find("controls-freq"));
    root.find("controls-ranges").bind("text", TextExpression(rangesText));
    root.find("controls-progress").bind("value", NumberExpression(sliderValue));
    root.find("controls-slider-value").bind("text", TextExpression(sliderText));
    root.find("controls-echo").bind("text", TextExpression(echoText));
}
