// Controls: the buttons count into the GUI's data (a label shows it through {{clicks}}); the bar and
// the number follow the slider, and the echo the text field, through bindings, with no handlers.
//
// The handlers are the surface's EventHandler shape: each returns false, so a click goes on as
// Raptor's void handlers left it.

Slider@ slider;
Slider@ vertical;
Slider@ stepped;
Slider@ freq;
TextField@ field;

bool add1(GuiEvent@ e) { Gui.SetNumber("clicks", Gui.GetNumber("clicks") + 1); return false; }
bool add5(GuiEvent@ e) { Gui.SetNumber("clicks", Gui.GetNumber("clicks") + 5); return false; }
bool reset(GuiEvent@ e) { Gui.SetNumber("clicks", 0); return false; }

double sliderValue() { return slider.Value; }
string sliderText() { return "" + int(slider.Value * 100 + 0.5) + "%"; }
string rangesText()
{
    return "vertical " + int(vertical.Value) + ", stepped " + int(stepped.Value) + " of 10, exponential " + int(freq.Value) + " Hz";
}
int logLines = 0;
bool addLogLine(GuiEvent@ e)
{
    ++logLines;
    Label@ line = Label::Of(Gui.Root().Find("controls-log").Add("Label"));
    line.Text = "Line " + logLines + " arrived";
    line.AddClass("scroll-line");
    return false;
}

int addedTabs = 0;
bool addTab(GuiEvent@ e)
{
    ++addedTabs;
    TabPage@ page = TabPage::Of(Gui.Root().Find("controls-tabs").Add("TabPage"));
    page.Title = "Added " + addedTabs;
    Label@ body = Label::Of(page.Add("Label"));
    body.Text = "A page added by the script.";
    body.AddClass("caption");
    return false;
}

string echoText() { return field.Text == "" ? "(the echo follows the field)" : "echo: " + field.Text; }

void main()
{
    Node@ root = Gui.Root();
    root.Find("controls-add").On("click", EventHandler(add1));
    root.Find("controls-add5").On("click", EventHandler(add5));
    root.Find("controls-reset").On("click", EventHandler(reset));
    root.Find("controls-repeat").On("click", EventHandler(add1));
    root.Find("controls-press").On("click", EventHandler(add1));
    root.Find("controls-log-add").On("click", EventHandler(addLogLine));
    root.Find("controls-tab-add").On("click", EventHandler(addTab));
    @slider = Slider::Of(root.Find("controls-slider"));
    @field = TextField::Of(root.Find("controls-field"));
    @vertical = Slider::Of(root.Find("controls-vertical"));
    @stepped = Slider::Of(root.Find("controls-stepped"));
    @freq = Slider::Of(root.Find("controls-freq"));
    root.Find("controls-ranges").Bind("Text", TextExpression(rangesText));
    root.Find("controls-progress").BindNumber("Value", NumberExpression(sliderValue));
    root.Find("controls-slider-value").Bind("Text", TextExpression(sliderText));
    root.Find("controls-echo").Bind("Text", TextExpression(echoText));
}
