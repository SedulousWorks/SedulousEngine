namespace Sedulous.UI.Resources;

using System;
using Sedulous.Resources;
using Sedulous.UI;

/// Resource wrapper for a UI layout loaded from an XML file.
/// Holds the raw XML source; instantiate views via LoadView().
public class UILayoutResource : Resource
{
	public String XmlSource ~ delete _;

	public override ResourceType ResourceType => .("ui.layout");

	/// Instantiate a new View tree from the stored XML source.
	/// Caller owns the returned View.
	public View LoadView()
	{
		if (XmlSource == null || XmlSource.IsEmpty)
			return null;
		return UIXmlLoader.LoadFromString(XmlSource);
	}
}
