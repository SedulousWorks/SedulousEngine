using System;

namespace Sedulous.Mcp;

/// A read only text resource, addressed by uri.
class Resource
{
	/// Fills outText on success, or outError on failure.
	public typealias Reader = delegate bool(String outText, String outError);

	public String Uri = new .() ~ delete _;
	public String Name = new .() ~ delete _;
	public String MimeType = new .() ~ delete _;
	public String Description = new .() ~ delete _;
	/// Null for an entry listed by a provider, whose reads go through the provider instead.
	public Reader Read ~ delete _;

	public this(StringView uri, StringView name, StringView mimeType, StringView description,
		Reader read = null)
	{
		Uri.Set(uri);
		Name.Set(name);
		MimeType.Set(mimeType);
		Description.Set(description);
		Read = read;
	}
}
