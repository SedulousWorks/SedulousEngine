using System;
using System.Collections;

namespace Sedulous.Mcp;

/// A DYNAMIC set of resources.
///
/// For entries that appear and disappear as the world changes, which cannot be registered
/// once: the open project's scenes, say. List appends whatever exists NOW; Read answers a uri
/// or declines it so the server can try the next provider.
class ResourceProvider
{
	/// Appends the current entries. The provider OWNS nothing afterwards: the list takes them.
	public typealias Lister = delegate void(List<Resource> outResources);
	public typealias UriReader = delegate ResourceReadOutcome(StringView uri, String outText,
		String outError);

	public Lister List ~ delete _;
	public UriReader Read ~ delete _;

	public this(Lister list, UriReader read)
	{
		List = list;
		Read = read;
	}
}
