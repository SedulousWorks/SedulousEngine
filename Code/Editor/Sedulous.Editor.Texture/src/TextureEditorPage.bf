using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Texture;
using Sedulous.Texture.Compression;
using Sedulous.Texture.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Texture;

/// The texture page: the source, or the embedded pixels, previewed over an info line with
/// the derived cooked format and mip count; a row of profile buttons; and a grid of the
/// import settings, each edit a whole asset snapshot command, every row re-pulled after an
/// undo. A usage pick derives the colour space, and a mismatch shows a lint row.
class TextureEditorPage : UIEditorPage
{
	private static readonly StringView[2] cColorSpaceItems = .("sRGB", "Linear");
	private static readonly StringView[5] cShapeItems = .("2D", "2D Array", "3D", "Cubemap", "Cubemap Array");
	private static readonly StringView[4] cFilterItems = .("Nearest", "Linear", "Mipmap Nearest", "Mipmap Linear");
	private static readonly StringView[4] cWrapItems = .("Repeat", "Clamp To Edge", "Clamp To Border", "Mirrored Repeat");
	private static readonly StringView[4] cUsageItems = .("Color", "Normal map", "Data mask (rough/AO/height/coverage)", "HDR");
	private static readonly StringView[3] cCompressionItems = .("Default", "None", "Quality");

	/// Borrowed.
	private EditorContext mContext;
	private String mTitle = new .() ~ delete _;
	/// Owned; null when the read failed and the page opened empty.
	private TextureAsset mAsset = null ~ delete _;
	/// Owned: the ImageView borrows it.
	private OwnedImageData mPreview = null ~ delete _;
	/// The source's format before the preview conversion.
	private PixelFormat mSourceFormat = .RGBA8;

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private PageToolbar mToolbar = null;
	private ImageView mImage = null;
	private Label mInfo = null;
	private PropertyGrid mGrid = null;
	private List<delegate void()> mRefreshers = new .() ~ DeleteContainerAndItems!(_);

	public this(EditorContext context, Instance instance)
	{
		mContext = context;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;

		let object = instance.ReadObject();
		mAsset = object as TextureAsset;
		if ((object != null) && (mAsset == null))
			delete object;
		if (mAsset == null)
			GlobalLog(.Error, "Editor: texture '{}' failed to read, page opens empty", mTitle);
		else
			LoadPreview(instance);

		mImage = new ImageView();
		mImage.ScaleType.Value = .FitCenter;
		mImage.SetImage(mPreview);
		mInfo = new Label("");
		mInfo.FontSize.Value = 12.0f;

		let previewColumn = new FlexLayout();
		previewColumn.Direction = .Vertical;
		previewColumn.Spacing = 6.0f;
		previewColumn.Padding = .(8, 6);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		previewColumn.AddView(mInfo, match);
		var growMatch = LayoutStyle();
		growMatch.Width = SizeSpec.Match();
		growMatch.FlexGrow = 1.0f;
		previewColumn.AddView(mImage, growMatch);

		mGrid = new PropertyGrid();
		BuildGrid();
		let gridColumn = new FlexLayout();
		gridColumn.Direction = .Vertical;
		gridColumn.Padding = .(8, 6);
		gridColumn.Spacing = 6.0f;
		let profileRow = new FlexLayout();
		profileRow.Direction = .Horizontal;
		profileRow.Spacing = 4.0f;
		BuildProfileRow(profileRow);
		gridColumn.AddView(profileRow, match);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		gridColumn.AddView(mGrid, grow);

		let split = new SplitView();
		split.SplitRatio = 0.55f;
		split.SetPanes(previewColumn, gridColumn);

		mToolbar = new PageToolbar(this);
		let pageColumn = new FlexLayout();
		pageColumn.Direction = .Vertical;
		pageColumn.AddView(mToolbar, match);
		pageColumn.AddView(split, growMatch);
		pageColumn.AddRef();
		mContent = pageColumn;
		RefreshInfo();
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public TextureAsset Asset => mAsset;
	public bool HasPreview => mPreview != null;

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mToolbar != null)
			mToolbar.Refresh();
	}

	public override Result<void, ErrorCode> Save()
	{
		if ((mAsset == null) || (mContext.Project == null))
			return .Err(.NotFound);
		let instance = mContext.Project.SourceDb.GetInstance(InstanceId);
		if (instance == null)
			return .Err(.NotFound);
		let saved = instance.WriteObject(mAsset);
		if (saved case .Ok)
		{
			ClearDirty();
			mContext.RequestCook(false);
			GlobalLog(.Information, "Editor: saved texture '{}'", mTitle);
		}
		return saved;
	}

	/// The embedded pixels when there is no source file, else the decoded source.
	private void LoadPreview(Instance instance)
	{
		if (mAsset == null)
			return;
		if (mAsset.FileName.IsEmpty && (mAsset.EmbeddedWidth > 0) && (mAsset.EmbeddedHeight > 0))
		{
			let stream = instance.ReadData("pixels");
			if (stream == null)
				return;
			defer delete stream;
			let expected = (int)mAsset.EmbeddedWidth * (int)mAsset.EmbeddedHeight * 4;
			let size = (int)stream.Size();
			if ((size <= 0) || (size < expected))
				return;
			let pixels = new List<uint8>(); // handed to the image
			pixels.Resize(expected);
			if (stream.Read(Span<uint8>(pixels.Ptr, expected)) != expected)
			{
				delete pixels;
				return;
			}
			mSourceFormat = .RGBA8;
			mPreview = new OwnedImageData(mAsset.EmbeddedWidth, mAsset.EmbeddedHeight, .RGBA8, pixels, mAsset.ColorSpace);
			return;
		}
		if (mAsset.FileName.IsEmpty || (mContext.Project == null))
			return;
		let path = PathJoin(mContext.Project.SourcesRoot(.. scope .()), mAsset.FileName.Value, .. scope .());
		let image = scope Sedulous.Image.Image();
		if (!(ImageIO.LoadImage(path, image) case .Ok))
		{
			GlobalLog(.Warning, "Editor: texture source missing or undecodable: {}", path);
			return;
		}
		mSourceFormat = image.Format;
		mPreview = TexturePreview.From(image);
	}

	private void RefreshInfo()
	{
		if (mAsset == null)
		{
			mInfo.SetText("Texture failed to load.");
			return;
		}
		if (mPreview == null)
		{
			mInfo.SetText("No preview (source file missing, embedded, or undecodable).");
			return;
		}
		let hdr = mSourceFormat == .RGBA32F;
		let derived = hdr ? "RGBA32F" : ((mAsset.ColorSpace == .Srgb) ? "RGBA8 sRGB" : "RGBA8 Linear");
		let mipLevels = mAsset.GenerateMipmaps ? TextureAssetEdit.MipLevels(mPreview.Width, mPreview.Height) : 1;
		mInfo.SetText(scope $"{mPreview.Width} x {mPreview.Height}  |  source {hdr ? "HDR" : "LDR"}  |  cooks to {derived}  |  {mipLevels} mip level(s)");
	}

	private void BuildGrid()
	{
		mGrid.Clear();
		ClearAndDeleteItems!(mRefreshers);
		if (mAsset == null)
			return;

		let usage = new EnumEditor("Usage", (int32)mAsset.Usage, cUsageItems, new [=this](v) =>
			{
				ApplyEdit("usage", new [=v](a) =>
					{
						a.Usage = (SourceUsage)v;
						a.ColorSpace = TextureAssetEdit.ColorSpaceFor(a.Usage);
					});
			}, "Content");
		AddEditor(usage, new [=this, =usage]() => { usage.SetValue((int32)mAsset.Usage); });

		let colorSpace = new EnumEditor("Color Space (advanced)", (int32)mAsset.ColorSpace, cColorSpaceItems, new [=this](v) =>
			{
				ApplyEdit("colorSpace", new [=v](a) => { a.ColorSpace = (ImageColorSpace)v; });
			}, "Content");
		AddEditor(colorSpace, new [=this, =colorSpace]() => { colorSpace.SetValue((int32)mAsset.ColorSpace); });

		let lint = new StringEditor("Warning", "", null, "Content");
		AddEditor(lint, new [=this, =lint]() =>
			{
				let text = TextureAssetEdit.Lint(mAsset.Usage, mAsset.ColorSpace);
				lint.SetRowVisible(!text.IsEmpty);
				if (!text.IsEmpty)
					lint.SetValue(text);
			});
		lint.SetRowVisible(false);

		let compression = new EnumEditor("Compression", (int32)mAsset.Compression, cCompressionItems, new [=this](v) =>
			{
				ApplyEdit("compression", new [=v](a) => { a.Compression = (CompressionChoice)v; });
			}, "Content");
		AddEditor(compression, new [=this, =compression]() => { compression.SetValue((int32)mAsset.Compression); });

		if (!mAsset.SourceHint.IsEmpty)
		{
			let source = new StringEditor("Source", mAsset.SourceHint, null, "Content");
			AddEditor(source, new [=this, =source]() => { source.SetValue(mAsset.SourceHint); });
		}

		let cooks = new StringEditor("Cooks to", "", null, "Content");
		AddEditor(cooks, new [=this, =cooks]() => { cooks.SetValue(TextureAssetEdit.ResolvedFormatText(mAsset, mPreview, mSourceFormat, .. scope .())); });
		cooks.SetValue(TextureAssetEdit.ResolvedFormatText(mAsset, mPreview, mSourceFormat, .. scope .()));

		let shape = new EnumEditor("Shape", (int32)mAsset.Shape, cShapeItems, new [=this](v) =>
			{
				ApplyEdit("shape", new [=v](a) => { a.Shape = (TextureShape)v; });
			}, "Sampling");
		AddEditor(shape, new [=this, =shape]() => { shape.SetValue((int32)mAsset.Shape); });

		AddFilterRow("Min Filter", "minFilter", new (a) => (int32)a.MinFilter, new (a, v) => a.MinFilter = (TextureFilter)v);
		AddFilterRow("Mag Filter", "magFilter", new (a) => (int32)a.MagFilter, new (a, v) => a.MagFilter = (TextureFilter)v);
		AddWrapRow("Wrap U", "wrapU", new (a) => (int32)a.WrapU, new (a, v) => a.WrapU = (TextureWrap)v);
		AddWrapRow("Wrap V", "wrapV", new (a) => (int32)a.WrapV, new (a, v) => a.WrapV = (TextureWrap)v);
		AddWrapRow("Wrap W", "wrapW", new (a) => (int32)a.WrapW, new (a, v) => a.WrapW = (TextureWrap)v);

		let mipmaps = new BoolEditor("Generate Mipmaps", mAsset.GenerateMipmaps, new [=this](v) =>
			{
				ApplyEdit("generateMipmaps", new [=v](a) => { a.GenerateMipmaps = v; });
			}, "Sampling");
		AddEditor(mipmaps, new [=this, =mipmaps]() => { mipmaps.SetValue(mAsset.GenerateMipmaps); });

		let anisotropy = new RangeEditor("Anisotropy", mAsset.Anisotropy, 1.0f, 16.0f, 1.0f, new [=this](v) =>
			{
				ApplyEdit("anisotropy", new [=v](a) => { a.Anisotropy = v; });
			}, "Sampling");
		AddEditor(anisotropy, new [=this, =anisotropy]() => { anisotropy.SetValue(mAsset.Anisotropy); });
	}

	/// An enum row over one of the sampler fields; `read` and `write` are consumed.
	private void AddEnumRow(StringView label, StringView key, Span<StringView> items, delegate int32(TextureAsset) read, delegate void(TextureAsset, int32) write)
	{
		let mergeKey = new String(key);
		let editor = new EnumEditor(label, read(mAsset), items, new [=this, =mergeKey, =write](v) =>
			{
				ApplyEdit(mergeKey, new [=write, =v](a) => { write(a, v); });
			} ~ { delete mergeKey; delete write; }, "Sampling");
		AddEditor(editor, new [=this, =editor, =read]() => { editor.SetValue(read(mAsset)); } ~ delete read);
	}

	private void AddFilterRow(StringView label, StringView key, delegate int32(TextureAsset) read, delegate void(TextureAsset, int32) write) => AddEnumRow(label, key, cFilterItems, read, write);
	private void AddWrapRow(StringView label, StringView key, delegate int32(TextureAsset) read, delegate void(TextureAsset, int32) write) => AddEnumRow(label, key, cWrapItems, read, write);

	/// The profile buttons: each applies one of the asset's own setups as a single command.
	private void BuildProfileRow(FlexLayout row)
	{
		let caption = new Label("Apply profile:");
		caption.FontSize.Value = 12.0f;
		var center = LayoutStyle();
		center.AlignSelf = .Center;
		row.AddView(caption, center);
		AddProfile(row, "UI", new (a) => a.SetupForUI());
		AddProfile(row, "Sprite", new (a) => a.SetupForSprite());
		AddProfile(row, "3D Surface", new (a) => a.SetupFor3D());
		AddProfile(row, "Normal Map", new (a) => a.SetupForNormalMap());
		AddProfile(row, "Data Mask", new (a) => a.SetupForDataMask());
		AddProfile(row, "Equirect Sky", new (a) => a.SetupForEquirectangularSkybox());
		AddProfile(row, "Cubemap Sky", new (a) => a.SetupForCubemapSkybox());
	}

	/// `setup` is consumed.
	private void AddProfile(FlexLayout row, StringView label, delegate void(TextureAsset) setup)
	{
		let button = new Button(label);
		button.OnClick.Add(new [=this, =setup](btn) =>
			{
				ApplyEdit("profile", new [=setup](a) => { setup(a); });
			} ~ delete setup);
		row.AddView(button);
	}

	/// Adds `editor` to the grid, which owns it, and keeps `refresher` to re-pull the shown
	/// value after an undo while the row is not being edited. `refresher` is consumed.
	private void AddEditor(PropertyEditor editor, delegate void() refresher)
	{
		mGrid.AddProperty(editor);
		mRefreshers.Add(new [=editor, =refresher]() =>
			{
				if (!editor.IsEditing)
					refresher();
			} ~ delete refresher);
	}

	private void Snapshot(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (mAsset != null)
			TextureAssetEdit.Snapshot(mAsset, outBlob);
	}

	/// Restores a snapshot, the undo and redo path; every row re-pulls and the info follows.
	public void ApplyBlob(List<uint8> blob)
	{
		if ((mAsset == null) || !TextureAssetEdit.Apply(mAsset, blob))
			return;
		for (let refresher in mRefreshers)
			refresher();
		RefreshInfo();
		MarkDirty();
	}

	/// Runs `mutate` on the asset and records the before and after as one merged-per-key
	/// command. `mutate` is consumed.
	public void ApplyEdit(StringView mergeKey, delegate void(TextureAsset asset) mutate)
	{
		defer delete mutate;
		if (mAsset == null)
			return;
		let before = scope List<uint8>();
		Snapshot(before);
		mutate(mAsset);
		let after = scope List<uint8>();
		Snapshot(after);
		Commands.Execute(new EditTextureCommand(this, mergeKey, before, after));
	}
}
