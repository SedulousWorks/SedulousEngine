// Data binding: the percentage label follows a function of the GUI's volume.
funcdef string TextExpression();
string percent() { return "" + int(gui::getNumber("volume") * 100 + 0.5) + "%"; }
void main() { gui::root().find("binding-percent").bind("text", TextExpression(percent)); }
