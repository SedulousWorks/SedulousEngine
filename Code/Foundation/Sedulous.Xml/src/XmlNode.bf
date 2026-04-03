using System;
using System.Collections;

namespace Sedulous.Xml;

/// <summary>
/// Node type enumeration.
/// </summary>
enum XmlNodeType : uint8
{
	Document,
	Element,
	Attribute,
	Text,
	CData,
	Comment,
	Declaration,
	ProcessingInstruction
}

/// <summary>
/// Base class for all XML nodes.
/// Nodes are organized in a tree hierarchy with parent/child/sibling relationships.
/// </summary>
abstract class XmlNode
{
	private XmlNodeType mNodeType;
	private XmlNode mParent;
	private XmlNode mFirstChild;
	private XmlNode mLastChild;
	private XmlNode mPrevSibling;
	private XmlNode mNextSibling;
	private String mTextLocation ~ delete _; // For error reporting

	protected this(XmlNodeType nodeType)
	{
		mNodeType = nodeType;
	}

	public ~this()
	{
		// Delete all children
		var child = mFirstChild;
		while (child != null)
		{
			let next = child.mNextSibling;
			delete child;
			child = next;
		}
	}

	// ---- Properties ----

	/// <summary>
	/// Gets the node type.
	/// </summary>
	public XmlNodeType NodeType => mNodeType;

	/// <summary>
	/// Gets the parent node.
	/// </summary>
	public XmlNode Parent => mParent;

	/// <summary>
	/// Gets the first child node.
	/// </summary>
	public XmlNode FirstChild => mFirstChild;

	/// <summary>
	/// Gets the last child node.
	/// </summary>
	public XmlNode LastChild => mLastChild;

	/// <summary>
	/// Gets the previous sibling node.
	/// </summary>
	public XmlNode PrevSibling => mPrevSibling;

	/// <summary>
	/// Gets the next sibling node.
	/// </summary>
	public XmlNode NextSibling => mNextSibling;

	/// <summary>
	/// Returns true if this node has any children.
	/// </summary>
	public bool HasChildren => mFirstChild != null;

	/// <summary>
	/// Returns the number of direct children.
	/// </summary>
	public int ChildCount
	{
		get
		{
			var count = 0;
			var child = mFirstChild;
			while (child != null)
			{
				count++;
				child = child.mNextSibling;
			}
			return count;
		}
	}

	/// <summary>
	/// Gets the owner document.
	/// </summary>
	public XmlDocument OwnerDocument
	{
		get
		{
			var node = this;
			while (node != null)
			{
				if (let doc = node as XmlDocument)
					return doc;
				node = node.mParent;
			}
			return null;
		}
	}

	// ---- Child Enumeration ----

	/// <summary>
	/// Enumerates all direct children.
	/// </summary>
	public ChildEnumerator Children => .(mFirstChild);

	public struct ChildEnumerator : IEnumerator<XmlNode>
	{
		private XmlNode mCurrent;
		private XmlNode mNext;

		public this(XmlNode first)
		{
			mCurrent = null;
			mNext = first;
		}

		public Result<XmlNode> GetNext() mut
		{
			if (mNext == null)
				return .Err;

			mCurrent = mNext;
			mNext = mCurrent.mNextSibling;
			return .Ok(mCurrent);
		}
	}

	// ---- Tree Manipulation ----

	/// <summary>
	/// Appends a child node to the end of this node's children.
	/// </summary>
	public void AppendChild(XmlNode child)
	{
		Runtime.Assert(child.mParent == null, "Node already has a parent");

		child.mParent = this;
		child.mPrevSibling = mLastChild;
		child.mNextSibling = null;

		if (mLastChild != null)
			mLastChild.mNextSibling = child;
		else
			mFirstChild = child;

		mLastChild = child;
	}

	/// <summary>
	/// Prepends a child node to the beginning of this node's children.
	/// </summary>
	public void PrependChild(XmlNode child)
	{
		Runtime.Assert(child.mParent == null, "Node already has a parent");

		child.mParent = this;
		child.mPrevSibling = null;
		child.mNextSibling = mFirstChild;

		if (mFirstChild != null)
			mFirstChild.mPrevSibling = child;
		else
			mLastChild = child;

		mFirstChild = child;
	}

	/// <summary>
	/// Inserts a child node before an existing child.
	/// </summary>
	public void InsertBefore(XmlNode newChild, XmlNode refChild)
	{
		if (refChild == null)
		{
			AppendChild(newChild);
			return;
		}

		Runtime.Assert(refChild.mParent == this, "Reference child is not a child of this node");
		Runtime.Assert(newChild.mParent == null, "New node already has a parent");

		newChild.mParent = this;
		newChild.mPrevSibling = refChild.mPrevSibling;
		newChild.mNextSibling = refChild;

		if (refChild.mPrevSibling != null)
			refChild.mPrevSibling.mNextSibling = newChild;
		else
			mFirstChild = newChild;

		refChild.mPrevSibling = newChild;
	}

	/// <summary>
	/// Inserts a child node after an existing child.
	/// </summary>
	public void InsertAfter(XmlNode newChild, XmlNode refChild)
	{
		if (refChild == null)
		{
			PrependChild(newChild);
			return;
		}

		Runtime.Assert(refChild.mParent == this, "Reference child is not a child of this node");
		Runtime.Assert(newChild.mParent == null, "New node already has a parent");

		newChild.mParent = this;
		newChild.mPrevSibling = refChild;
		newChild.mNextSibling = refChild.mNextSibling;

		if (refChild.mNextSibling != null)
			refChild.mNextSibling.mPrevSibling = newChild;
		else
			mLastChild = newChild;

		refChild.mNextSibling = newChild;
	}

	/// <summary>
	/// Removes a child node from this node's children.
	/// The child is not deleted.
	/// </summary>
	public void RemoveChild(XmlNode child)
	{
		Runtime.Assert(child.mParent == this, "Node is not a child of this node");

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

	/// <summary>
	/// Removes this node from its parent's children.
	/// </summary>
	public void RemoveFromParent()
	{
		if (mParent != null)
			mParent.RemoveChild(this);
	}

	/// <summary>
	/// Removes and deletes all children from this node.
	/// </summary>
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

	// ---- Abstract Methods ----

	/// <summary>
	/// Gets the inner text content of this node.
	/// </summary>
	public abstract void GetInnerText(String output);

	/// <summary>
	/// Gets the outer XML representation of this node.
	/// </summary>
	public abstract void GetOuterXml(String output);

	// ---- Location Tracking ----

	/// <summary>
	/// Sets the text location for error reporting.
	/// </summary>
	internal void SetTextLocation(StringView location)
	{
		delete mTextLocation;
		mTextLocation = new String(location);
	}

	/// <summary>
	/// Gets the text location for error reporting.
	/// </summary>
	public StringView TextLocation => mTextLocation ?? "";
}
