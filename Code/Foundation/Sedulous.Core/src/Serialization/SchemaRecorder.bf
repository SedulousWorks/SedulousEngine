using System;
using System.Collections;

namespace Sedulous.Core.Serialization;

enum SchemaNodeKind : uint8
{
	/// BeginObject .. EndObject (the root is one).
	case Object;
	/// BeginArray .. EndArray; the children are the elements written, in order.
	case Array;
	/// One typed scalar; Scalar says which, Value its text.
	case Scalar;
	/// A string; Value is it.
	case Text;
	/// A guid; Value is its canonical thirty six character text.
	case Guid;
	/// Opaque bytes; BlobSize is how many.
	case Blob;
}

/// One thing a Serialize body wrote, in the order it wrote it.
class SchemaNode
{
	/// The Key that preceded it; empty for an array element or the root.
	public String Key = new .() ~ delete _;
	public SchemaNodeKind Kind = .Object;
	/// For Scalar.
	public ScalarKind Scalar = .Bool;
	/// The value written, as text: a default constructed instance's default.
	public String Value = new .() ~ delete _;
	/// For Array: the element count written.
	public uint32 Count = 0;
	/// For Blob.
	public int BlobSize = 0;
	/// For Object and Array. OWNED.
	public List<SchemaNode> Children = new .() ~ DeleteContainerAndItems!(_);

	/// The first child with `name` (an object's field by key); null when none.
	public SchemaNode Find(StringView name)
	{
		for (let child in Children)
		{
			if (child.Key == name)
				return child;
		}
		return null;
	}

	public SchemaNode At(int index) => ((index >= 0) && (index < Children.Count)) ? Children[index] : null;
}

/// A serializer backend in WRITE mode that stores nothing and records what a Serialize body
/// DID: each Key with the scalar kind and the value that followed it, the nesting of objects
/// and arrays, text, guid and blob fields, and the data version chain a versioned payload
/// pushed. Driven through the real write path over a default constructed instance, the
/// recording IS the wire format: the order, keys, kinds and defaults the reader will expect,
/// taken from the code that writes real files rather than from reflection, which differs from
/// the wire in field set, order, encoding and defaults. The scene format reference is built
/// from it.
class SchemaRecorder : Serializer
{
	private SchemaNode mRoot = new .() ~ delete _;
	/// The open object or array; the nodes are owned by the tree.
	private List<SchemaNode> mStack = new .() ~ delete _;
	private String mPendingKey = new .() ~ delete _;
	private List<SerializedDataVersion> mChain = new .() ~ delete _;
	private bool mChainTaken = false;

	public this() : base(.Write)
	{
		mRoot.Kind = .Object;
		mStack.Add(mRoot);
	}

	/// The recording: an implicit root object holding what the body wrote at its top level.
	public SchemaNode Root => mRoot;

	/// The data version chain of the OUTERMOST versioned payload recorded (the concrete type
	/// first, then every versioned base), as BeginVersionedPayload pushed it; empty when the
	/// body was not versioned.
	public Span<SerializedDataVersion> VersionChain => mChain;

	public override bool IsSelfDescribing => true;

	// ---- every operation records and moves nothing ----------------------------------------

	public override void Key(StringView name) => mPendingKey.Set(name);

	public override void BeginObject() => mStack.Add(Add(.Object));

	public override void EndObject() => Pop();

	public override void BeginArray(ref uint32 count)
	{
		let node = Add(.Array);
		node.Count = count;
		mStack.Add(node);
	}

	public override void EndArray() => Pop();

	public override void Scalar(void* value, ScalarKind kind)
	{
		let node = Add(.Scalar);
		node.Scalar = kind;
		ScalarText(value, kind, node.Value);
	}

	public override void Text(String value) => Add(.Text).Value.Set(value);

	public override void GuidValue(ref Guid value) => value.ToString(Add(.Guid).Value, 'D');

	public override void Blob(void* data, int size) => Add(.Blob).BlobSize = size;

	public override void PushVersionScope(Span<SerializedDataVersion> chain)
	{
		if (!mChainTaken)
		{
			for (let entry in chain)
				mChain.Add(entry);
			mChainTaken = true;
		}
		base.PushVersionScope(chain);
	}

	/// A scalar's text the way the schema shows a default: booleans as true and false,
	/// integers as decimal, floats as their shortest round trip decimal.
	public static void ScalarText(void* value, ScalarKind kind, String outText)
	{
		switch (kind)
		{
		case .Bool: outText.Append(*(bool*)value ? "true" : "false");
		case .Int8: (*(int8*)value).ToString(outText);
		case .UInt8: (*(uint8*)value).ToString(outText);
		case .Int16: (*(int16*)value).ToString(outText);
		case .UInt16: (*(uint16*)value).ToString(outText);
		case .Int32: (*(int32*)value).ToString(outText);
		case .UInt32: (*(uint32*)value).ToString(outText);
		case .Int64: (*(int64*)value).ToString(outText);
		case .UInt64: (*(uint64*)value).ToString(outText);
		case .Float32: (*(float*)value).ToString(outText);
		case .Float64: (*(double*)value).ToString(outText);
		}
	}

	private SchemaNode Add(SchemaNodeKind kind)
	{
		let node = new SchemaNode();
		node.Kind = kind;
		node.Key.Set(mPendingKey);
		mPendingKey.Clear();
		mStack.Back.Children.Add(node);
		return node;
	}

	/// The root never pops: an unbalanced End is the body's bug, not a crash.
	private void Pop()
	{
		if (mStack.Count > 1)
			mStack.PopBack();
	}
}
