namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Shell;
using Sedulous.VFS;
using Sedulous.Editor.Core;

/// Property editor for a single ResourceRef.
/// Shows path (or ID if no path), a clear button (X), and a browse button (...).
class ResourceRefEditor : PropertyEditor
{
	private delegate ResourceRef() mGetter;
	private delegate void(ResourceRef) mSetter;
	private IDialogService mDialogs;
	private ISerializerProvider mSerializerProvider;
	private ResourceSystem mResourceSystem;
	private Sedulous.Editor.Core.EditorContext mEditorContext;
	private String mExtensionFilter ~ delete _;
	private Label mPathLabel;
	private bool mOwnsCallbacks;

	public this(StringView name, delegate ResourceRef() getter, delegate void(ResourceRef) setter,
		IDialogService dialogs = null, ISerializerProvider serializerProvider = null,
		ResourceSystem resourceSystem = null, Sedulous.Editor.Core.EditorContext editorContext = null,
		StringView extensionFilter = default,
		bool ownsCallbacks = true, StringView category = default)
		: base(name, category)
	{
		mGetter = getter;
		mSetter = setter;
		mDialogs = dialogs;
		mSerializerProvider = serializerProvider;
		mResourceSystem = resourceSystem;
		mEditorContext = editorContext;
		if (extensionFilter.Length > 0)
			mExtensionFilter = new String(extensionFilter);
		mOwnsCallbacks = ownsCallbacks;
	}

	public ~this()
	{
		if (mOwnsCallbacks)
		{
			delete mGetter;
			delete mSetter;
		}
	}

	protected override View CreateEditorView()
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 2;

		// Path/ID display
		mPathLabel = new Label();
		mPathLabel.FontSize.Value = 11;
		mPathLabel.TextColor.Value = .(180, 185, 200, 255);
		RefreshPathLabel();
		row.AddView(mPathLabel, new FlexLayout.LayoutParams() {
			Height = .Match, Grow = 1
		});

		// Browse button
		let browseBtn = new Button("...");
		browseBtn.OnClick.Add(new (btn) => { OnBrowse(); });
		row.AddView(browseBtn, new FlexLayout.LayoutParams() {
			Width = .Fixed(.Px(28)), Height = .Match
		});

		// Clear button
		let clearBtn = new Button("X");
		clearBtn.OnClick.Add(new (btn) => { OnClear(); });
		row.AddView(clearBtn, new FlexLayout.LayoutParams() {
			Width = .Fixed(.Px(24)), Height = .Match
		});

		return row;
	}

	private void RefreshPathLabel()
	{
		if (mPathLabel == null) return;

		let @ref = mGetter();
		if (@ref.HasPath)
		{
			let fileName = scope String();
			System.IO.Path.GetFileName(@ref.Path, fileName);
			mPathLabel.SetText(fileName);
		}
		else if (@ref.HasId)
		{
			let idStr = scope String();
			@ref.Id.ToString(idStr);
			mPathLabel.SetText(idStr);
		}
		else
		{
			mPathLabel.SetText("(none)");
		}
	}

	private void OnBrowse()
	{
		// Use asset picker dialog when EditorContext is available
		if (mEditorContext != null)
		{
			let ctx = mPathLabel?.Context;
			if (ctx == null) return;

			let picker = new AssetPickerDialog(mEditorContext, mExtensionFilter ?? "",
				new (protocolPath, guid) => {
					var newRef = ResourceRef(guid, protocolPath);
					BeginEdit();
					mSetter(newRef);
					NotifyValueChanged();
					EndEdit();
					newRef.Dispose();
					RefreshPathLabel();
				});
			picker.Show(ctx);
			return;
		}

		// Fallback: OS file dialog
		if (mDialogs == null) return;

		mDialogs.ShowOpenFileDialog(
			new (paths) => {
				if (paths.Length == 0) return;

				let absolutePath = paths[0];

				// Resolve the picked absolute path to one of the editor's mounts.
				// Files outside any mount can't be loaded later (LoadResource is
				// URI-only) so we refuse them here instead of creating a broken ref.
				IMount mount = null;
				let locator = scope String();
				if (mEditorContext == null ||
					!MountResolver.TryResolveAbsolute(mEditorContext.MountEntries, absolutePath, out mount, locator))
				{
					mEditorContext?.Logger?.LogWarning("ResourceRefEditor: picked file is not inside any mount: {}", absolutePath);
					return;
				}

				// Find the scheme the mount is registered under so we can build the URI.
				let scheme = scope String();
				for (let entry in mEditorContext.MountEntries)
				{
					if (entry.Mount === mount)
					{
						scheme.Set(entry.Scheme);
						break;
					}
				}

				var guid = Guid();
				if (mSerializerProvider != null)
					guid = ReadResourceGuid(mount, locator, mSerializerProvider);

				let refPath = scope String()..AppendF("{}://{}", scheme, locator);

				var newRef = ResourceRef(guid, refPath);
				BeginEdit();
				mSetter(newRef);
				NotifyValueChanged();
				EndEdit();
				newRef.Dispose();
				RefreshPathLabel();
			},
			default, default, false, null);
	}

	/// Reads just the GUID from a resource file header, opened through `mount`.
	private static Guid ReadResourceGuid(IMount mount, StringView locator, ISerializerProvider provider)
	{
		let openResult = mount.Open(locator);
		if (openResult case .Err) return .();
		let stream = openResult.Value;
		defer delete stream;

		let text = scope String();
		let len = (int)stream.Length;
		if (len > 0)
		{
			let buf = scope uint8[len];
			if (stream.TryRead(.(&buf[0], len)) case .Err) return .();
			text.Append((char8*)&buf[0], len);
		}

		let reader = provider.CreateReader(text);
		if (reader == null)
			return .();
		defer delete reader;

		// Read _type (skip)
		uint64 typeHash = 0;
		reader.UInt64("_type", ref typeHash);

		// Read version (skip)
		int32 version = 0;
		reader.Version(ref version);

		// Read _id
		let guidStr = scope String();
		reader.String("_id", guidStr);

		if (Guid.Parse(guidStr) case .Ok(let guid))
			return guid;
		return .();
	}

	private void OnClear()
	{
		let emptyRef = ResourceRef();
		BeginEdit();
		mSetter(emptyRef);
		NotifyValueChanged();
		EndEdit();
		RefreshPathLabel();
	}

	public override void RefreshView()
	{
		RefreshPathLabel();
	}
}
