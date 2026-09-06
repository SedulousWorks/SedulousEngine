using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;

namespace Sedulous.Content.Tests;

/// A scratch directory, a mount over it, and a database on top.
///
/// Every case builds one of these, so the whole stack is exercised end to end rather than
/// against a stand-in for the filesystem.
class ContentFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Factory ~ delete _;
	private String mRoot = new .() ~ delete _;

	public this(StringView root, bool useXml)
	{
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		Mount = new NativeFileSystem(mRoot);
		Factory = useXml
			? XmlSerializerFactory()
			: new (stream, mode) => new BinarySerializerContext(stream, mode);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// A fresh database over the same directory, which is how a rescan is tested: whatever
	/// the previous session wrote has to be found again from the files alone.
	public ContentDatabase Open() => new ContentDatabase(Mount, Factory, "asset");
}
