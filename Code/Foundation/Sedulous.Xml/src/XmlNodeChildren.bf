using System;
using System.Collections;

namespace Sedulous.Xml;

/// Walks the direct children of a node.
///
/// A live view of the sibling chain rather than a snapshot, so it must not be held across
/// a change to that chain.
struct XmlNodeChildren : IEnumerator<XmlNode>
{
	private XmlNode mNext;

	public this(XmlNode first)
	{
		mNext = first;
	}

	public Result<XmlNode> GetNext() mut
	{
		if (mNext == null)
			return .Err;

		let current = mNext;
		mNext = current.NextSibling;
		return .Ok(current);
	}
}
