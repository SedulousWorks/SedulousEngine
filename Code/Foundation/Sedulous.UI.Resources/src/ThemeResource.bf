namespace Sedulous.UI.Resources;

using System;
using Sedulous.Resources;
using Sedulous.UI;

/// Resource wrapper for a Theme loaded from a theme XML file.
public class ThemeResource : Resource
{
	public Theme Theme ~ delete _;

	public override ResourceType ResourceType => .("ui.theme");
}
