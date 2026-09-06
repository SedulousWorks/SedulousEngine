namespace Sedulous.Xml;

/// What the parser keeps and what it checks.
struct XmlParseSettings
{
	/// Keep text nodes that are entirely whitespace. Off by default, because indentation
	/// between elements is formatting rather than content, and keeping it puts a text node
	/// between every pair of siblings.
	public bool PreserveWhitespace = false;
	/// Parse comments and processing instructions but do not attach them. The syntax is
	/// still checked either way, so a malformed one is still an error.
	public bool IgnoreComments = false;
	public bool IgnoreProcessingInstructions = false;
	public bool ValidateNamespaces = true;

	public static XmlParseSettings Default => .();
}
