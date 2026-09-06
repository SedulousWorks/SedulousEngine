using System;

namespace Sedulous.Xml;

/// Serialising one element, without a document around it.
static
{
	/// Writes an element and its subtree. No declaration, since a fragment is not a
	/// document and should not claim to be one.
	public static void ToXml(XmlElement element, String output, bool compact = false)
	{
		var settings = XmlWriteSettings.Default;
		settings.CompactMode = compact;

		let writer = scope XmlWriter(output, settings);
		writer.WriteElement(element);
	}
}
