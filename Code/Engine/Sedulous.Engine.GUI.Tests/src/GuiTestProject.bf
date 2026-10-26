using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.GUI.Resources;
using Sedulous.Resource;
using Sedulous.RHI.Null;
using Sedulous.Texture.Resource;
using Sedulous.VFS;
using Sedulous.VG.Resource;

namespace Sedulous.Engine.GUI.Tests;

/// A content database of cooked GUI assets in a scratch folder, and a resource manager over it
/// with their factories: documents, sheets, vector images and textures (on the Null device).
class GuiTestProject
{
	private String mFolder = new .() ~ delete _;
	private NullDevice mDevice;
	private SerializableRegistry mSerializables;
	private SerializerFactory mSerializers;
	private NativeFileSystem mMount;
	private ContentDatabase mDatabase;
	private GuiDocumentFactory mDocuments;
	private GuiStyleSheetFactory mSheets;
	private VectorImageFactory mVectors;
	private TextureFactory mTextures;
	private ResourceManager mResources;

	public ResourceManager Resources => mResources;

	public this(StringView folder)
	{
		mFolder.Set(folder);
		RemoveDirectoryRecursive(mFolder);
		CreateDirectory(mFolder);
		mDevice = new NullDevice();
		mSerializables = new SerializableRegistry();
		GuiResources.RegisterAll(mSerializables);
		VGResources.RegisterAll(mSerializables);
		TextureResources.RegisterAll(mSerializables);
		mMount = new NativeFileSystem(mFolder);
		mSerializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		mDatabase = new ContentDatabase(mMount, mSerializers, "asset", mSerializables);
		mDocuments = new GuiDocumentFactory();
		mSheets = new GuiStyleSheetFactory();
		mVectors = new VectorImageFactory();
		mTextures = new TextureFactory(mDevice);
		mResources = new ResourceManager(mDatabase);
		mResources.AddFactory(mDocuments);
		mResources.AddFactory(mSheets);
		mResources.AddFactory(mVectors);
		mResources.AddFactory(mTextures);
	}

	public ~this()
	{
		// The manager first (it releases its products through the factories and the device),
		// then what it read through, the device last.
		delete mResources;
		delete mTextures;
		delete mVectors;
		delete mSheets;
		delete mDocuments;
		delete mDatabase;
		delete mSerializers;
		delete mMount;
		delete mSerializables;
		delete mDevice;
		RemoveDirectoryRecursive(mFolder);
	}

	public Guid Document(StringView name, StringView markup)
	{
		let instance = mDatabase.RootGroup.CreateInstance(name, "Sedulous.GUI.Resources.GuiDocumentSource");
		let source = scope GuiDocumentSource();
		source.Markup.Set(markup);
		Test.Assert(instance.WriteObject(source) case .Ok);
		return instance.Id;
	}

	public Guid Sheet(StringView name, StringView css)
	{
		let instance = mDatabase.RootGroup.CreateInstance(name, "Sedulous.GUI.Resources.GuiStyleSheetSource");
		RewriteSheet(instance.Id, css);
		return instance.Id;
	}

	/// The sheet cooked again with `css`, and reloaded as the editor's re-cook does.
	public void RewriteSheet(Guid id, StringView css)
	{
		let source = scope GuiStyleSheetSource();
		source.Css.Set(css);
		Test.Assert(mDatabase.GetInstance(id).WriteObject(source) case .Ok);
		mResources.Reload(id);
	}

	public Guid Vector(StringView name, StringView svg)
	{
		let instance = mDatabase.RootGroup.CreateInstance(name, "Sedulous.VG.Resource.VectorImageResource");
		let source = scope VectorImageResource();
		source.Svg.Set(svg);
		Test.Assert(instance.WriteObject(source) case .Ok);
		return instance.Id;
	}

	public Guid Texture(StringView name, uint32 width, uint32 height)
	{
		let instance = mDatabase.RootGroup.CreateInstance(name, "Sedulous.Texture.Resource.RenderTextureResource");
		let record = scope RenderTextureResource();
		record.Width = width;
		record.Height = height;
		Test.Assert(instance.WriteObject(record) case .Ok);
		return instance.Id;
	}

	/// `id` as "{guid}".
	public static void Braced(Guid id, String outText)
	{
		outText.Append('{');
		id.ToString(outText);
		outText.Append('}');
	}
}
