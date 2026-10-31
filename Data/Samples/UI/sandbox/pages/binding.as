// Data binding: the percentage label follows a function of the GUI's volume.
string percent() { return "" + int(Gui.GetNumber("volume") * 100 + 0.5) + "%"; }
void main() { Gui.Root().Find("binding-percent").Bind("Text", TextExpression(percent)); }
