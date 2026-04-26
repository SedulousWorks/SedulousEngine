namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Shell;

/// Property editor for a single ResourceRef.
/// Shows path (or ID if no path), a clear button (X), and a browse button (...).
class ResourceRefEditor : PropertyEditor
{
	private delegate ResourceRef() mGetter;
	private delegate void(ResourceRef) mSetter;
	private IDialogService mDialogs;
	private ISerializerProvider mSerializerProvider;
	private ResourceSystem mResourceSystem;
	private Label mPathLabel;
	private bool mOwnsCallbacks;

	public this(StringView name, delegate ResourceRef() getter, delegate void(ResourceRef) setter,
		IDialogService dialogs = null, ISerializerProvider serializerProvider = null,
		ResourceSystem resourceSystem = null,
		bool ownsCallbacks = true, StringView category = default)
		: base(name, category)
	{
		mGetter = getter;
		mSetter = setter;
		mDialogs = dialogs;
		mSerializerProvider = serializerProvider;
		mResourceSystem = resourceSystem;
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
		let row = new LinearLayout();
		row.Orientation = .Horizontal;
		row.Spacing = 2;

		// Path/ID display
		mPathLabel = new Label();
		mPathLabel.FontSize = 11;
		mPathLabel.TextColor = .(180, 185, 200, 255);
		RefreshPathLabel();
		row.AddView(mPathLabel, new LinearLayout.LayoutParams() {
			Width = 0, Height = LayoutParams.MatchParent, Weight = 1
		});

		// Browse button
		let browseBtn = new Button();
		browseBtn.SetText("...");
		browseBtn.OnClick.Add(new (btn) => { OnBrowse(); });
		row.AddView(browseBtn, new LinearLayout.LayoutParams() {
			Width = 28, Height = LayoutParams.MatchParent
		});

		// Clear button
		let clearBtn = new Button();
		clearBtn.SetText("X");
		clearBtn.OnClick.Add(new (btn) => { OnClear(); });
		row.AddView(clearBtn, new LinearLayout.LayoutParams() {
			Width = 24, Height = LayoutParams.MatchParent
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
		if (mDialogs == null) return;

		mDialogs.ShowOpenFileDialog(
			new (paths) => {
				if (paths.Length > 0)
				{
					let absolutePath = paths[0];
					var guid = Guid();

					// Try to read the resource header to get the GUID
					if (mSerializerProvider != null)
						guid = ReadResourceGuid(absolutePath, mSerializerProvider);

					// Convert to protocol path if possible (e.g. builtin://primitives/cube.mesh)
					let refPath = scope String();
					if (mResourceSystem != null)
						mResourceSystem.TryMakeProtocolPath(absolutePath, refPath);
					else
						refPath.Set(absolutePath);

					var newRef = ResourceRef(guid, refPath);
					BeginEdit();
					mSetter(newRef);
					NotifyValueChanged();
					EndEdit();
					newRef.Dispose();
					RefreshPathLabel();
				}
			},
			default, default, false, null);
	}

	/// Reads just the GUID from a resource file header.
	private static Guid ReadResourceGuid(StringView path, ISerializerProvider provider)
	{
		let text = scope String();
		if (System.IO.File.ReadAllText(path, text) case .Err)
			return .();

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
