using System;
using System.Diagnostics;

namespace Sedulous.Xml;

/// One node in a document tree.
///
/// A node OWNS its children: deleting one deletes the subtree under it. Detaching with
/// RemoveChild hands that ownership back to the caller, which is why it does not delete.
///
/// Raptor threads an allocator through every node so a whole tree shares the document's
/// decision. Beef allocates through new, so the parameter, the field and the rule that
/// detached subtrees keep their creator's allocator all go away.
abstract class XmlNode
{
	private XmlNodeType mNodeType;
	private XmlNode mParent;
	private XmlNode mFirstChild;
	private XmlNode mLastChild;
	private XmlNode mPrevSibling;
	private XmlNode mNextSibling;

	protected this(XmlNodeType nodeType)
	{
		mNodeType = nodeType;
	}

	public ~this()
	{
		var child = mFirstChild;
		while (child != null)
		{
			let next = child.mNextSibling;
			delete child;
			child = next;
		}
	}

	public XmlNodeType NodeType => mNodeType;
	public XmlNode Parent => mParent;
	public XmlNode FirstChild => mFirstChild;
	public XmlNode LastChild => mLastChild;
	public XmlNode PrevSibling => mPrevSibling;
	public XmlNode NextSibling => mNextSibling;
	public bool HasChildren => mFirstChild != null;

	public int ChildCount
	{
		get
		{
			var count = 0;
			for (var child = mFirstChild; child != null; child = child.mNextSibling)
				count++;
			return count;
		}
	}

	/// The document this node belongs to, or null for a detached subtree.
	public XmlDocument OwnerDocument
	{
		get
		{
			var node = this;
			while (node.mParent != null)
				node = node.mParent;
			return node as XmlDocument;
		}
	}

	public XmlNodeChildren Children => .(mFirstChild);

	// ---- tree manipulation ----

	public virtual void AppendChild(XmlNode child)
	{
		Debug.Assert(child.mParent == null, "the node already has a parent");
		child.mParent = this;
		child.mPrevSibling = mLastChild;
		child.mNextSibling = null;

		if (mLastChild != null)
			mLastChild.mNextSibling = child;
		else
			mFirstChild = child;
		mLastChild = child;
	}

	public void PrependChild(XmlNode child)
	{
		Debug.Assert(child.mParent == null, "the node already has a parent");
		child.mParent = this;
		child.mPrevSibling = null;
		child.mNextSibling = mFirstChild;

		if (mFirstChild != null)
			mFirstChild.mPrevSibling = child;
		else
			mLastChild = child;
		mFirstChild = child;
	}

	/// A null reference node appends, since there is nothing to go before.
	public void InsertBefore(XmlNode newChild, XmlNode refChild)
	{
		if (refChild == null)
		{
			AppendChild(newChild);
			return;
		}

		Debug.Assert(refChild.mParent == this, "the reference node is not a child of this one");
		Debug.Assert(newChild.mParent == null, "the new node already has a parent");
		newChild.mParent = this;
		newChild.mPrevSibling = refChild.mPrevSibling;
		newChild.mNextSibling = refChild;

		if (refChild.mPrevSibling != null)
			refChild.mPrevSibling.mNextSibling = newChild;
		else
			mFirstChild = newChild;
		refChild.mPrevSibling = newChild;
	}

	/// A null reference node prepends, since there is nothing to go after.
	public void InsertAfter(XmlNode newChild, XmlNode refChild)
	{
		if (refChild == null)
		{
			PrependChild(newChild);
			return;
		}

		Debug.Assert(refChild.mParent == this, "the reference node is not a child of this one");
		Debug.Assert(newChild.mParent == null, "the new node already has a parent");
		newChild.mParent = this;
		newChild.mPrevSibling = refChild;
		newChild.mNextSibling = refChild.mNextSibling;

		if (refChild.mNextSibling != null)
			refChild.mNextSibling.mPrevSibling = newChild;
		else
			mLastChild = newChild;
		refChild.mNextSibling = newChild;
	}

	/// Detaches a child WITHOUT deleting it: the caller takes the subtree.
	public void RemoveChild(XmlNode child)
	{
		Debug.Assert(child.mParent == this, "the node is not a child of this one");

		if (child.mPrevSibling != null)
			child.mPrevSibling.mNextSibling = child.mNextSibling;
		else
			mFirstChild = child.mNextSibling;

		if (child.mNextSibling != null)
			child.mNextSibling.mPrevSibling = child.mPrevSibling;
		else
			mLastChild = child.mPrevSibling;

		child.mParent = null;
		child.mPrevSibling = null;
		child.mNextSibling = null;
	}

	public void RemoveFromParent()
	{
		if (mParent != null)
			mParent.RemoveChild(this);
	}

	/// Detaches AND deletes every child, unlike RemoveChild.
	public void ClearChildren()
	{
		var child = mFirstChild;
		while (child != null)
		{
			let next = child.mNextSibling;
			child.mParent = null;
			child.mPrevSibling = null;
			child.mNextSibling = null;
			delete child;
			child = next;
		}
		mFirstChild = null;
		mLastChild = null;
	}

	// ---- content ----

	/// The concatenated text of this node and everything under it, unescaped.
	public abstract void GetInnerText(String output);

	/// This node and everything under it, as XML.
	public abstract void GetOuterXml(String output);
}
