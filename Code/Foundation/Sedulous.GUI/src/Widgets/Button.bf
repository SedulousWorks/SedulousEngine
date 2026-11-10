using System;
using Sedulous.Core;

namespace Sedulous.GUI;

// Button: the button core (ButtonBase) with its content centred: a text, an icon and the text, or
// whatever markup puts inside it. What were separate kinds elsewhere are its attributes: an icon
// button has an icon, a toggle button `toggle`, a repeat button `repeat`.

[GuiReflect(true)]
class Button : ButtonBase
{
	public this()
	{
		Tag = "button"; // CSS `button { ... }` targets it by default
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) => { s.JustifyContent = .Center; });
		}
	}
}
