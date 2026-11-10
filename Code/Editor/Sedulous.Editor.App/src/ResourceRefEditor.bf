using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// The inspector's asset reference: the property grid's
// editor for GUI.Toolkit's Reference kind, an asset slot. What may fill it is asked of the builders,
// never listed here: the source asset types whose builder makes the type the reference
// points at (EditorContext.SourceAssetTypesOf). Pick, drop and clear are one write, the grid's, so
// one undo step; a pick opens the asset picker (AssetPickerWindow). Open and reveal show the asset. What
// it asks of the editor is a table of its own (ResourceRefServices), so a test gives its own and the
// application fills it from its context.
//
// An entity reference is not this editor's: an EntityRef is no reference to an asset, and only a
// scene names its entities, so it comes with the scene page's inspector.

/// What a referenced asset shows: its name, its type's glyph and the class that tints it, and its
/// thumbnail in the glyph's place once there is one.
class ResourceRefShown
{
	/// The asset's thumbnail; null until one is generated (a bind asks again). Borrowed.
	public Sedulous.GUI.Drawable Picture = null;
	public String Name = new .() ~ delete _;
	/// The glyph's image; empty: none.
	public String Glyph = new .() ~ delete _;
	/// Its category's class (a tint); empty: the plain colour.
	public String GlyphClass = new .() ~ delete _;
}

/// What a reference row asks of the editor. Each is optional: one unset leaves its verb out. Each
/// is owned, assigned once.
class ResourceRefServices
{
	/// The asset types, by name, that may fill a reference to `target`, appended to `outTypes` (the
	/// caller deletes them).
	public delegate void(Type target, List<String> outTypes) AcceptedTypes ~ delete _;
	/// What `id` names, into `outShown`; false when the project has no such asset (a dangling
	/// reference).
	public delegate bool(Guid id, ResourceRefShown outShown) Describe ~ delete _;
	/// Opens a picker over `types` (empty: any), `current` checked; `chosen`
	/// assigns what it picks (nil: None). OWNERSHIP of `chosen` transfers: the picker deletes it
	/// once it has answered, or given up.
	public delegate void(Span<String> types, Guid current, delegate void(Guid id) chosen) Pick ~ delete _;
	public delegate void(Guid id) Open ~ delete _;
	public delegate void(Guid id) Reveal ~ delete _;

	/// A table filled from the editor's context: the builders' types (SourceAssetTypesOf; none,
	/// the type itself, a reference naming a source asset type), the project's names, the type
	/// icons, the asset picker over the project's sources (`open` shows the asset picker for a
	/// request, taking the request; null: no pick), the context's open and reveal. `context` and `icons` outlive it; OWNERSHIP
	/// of `open` transfers. The caller deletes it.
	public static ResourceRefServices From(EditorContext context, EditorIcons icons,
		delegate void(AssetPickRequest request) open)
	{
		let services = new ResourceRefServices();
		if (open != null)
		{
			services.Pick = new [=context, =open] (types, current, chosen) =>
				{
					let project = context.Project;
					if (project == null)
					{
						delete chosen; // given up: no project, nothing to pick
						return;
					}
					let request = new AssetPickRequest();
					for (let type in types)
						request.Types.Add(new String(type));
					request.Current = current;
					request.Chosen = chosen; // the request's: it goes with it, once the picker has answered or closed
					open(request);
				} ~ { delete open; };
		}
		// What the builders make it from; none: the type itself, a reference naming a source asset
		// type (as Project Settings' does).
		services.AcceptedTypes = new [=context] (target, outTypes) =>
			{
				let start = outTypes.Count;
				if (context.SourceAssetTypesOf != null)
				{
					let assets = scope List<Type>();
					context.SourceAssetTypesOf(target, assets);
					for (let asset in assets)
						outTypes.Add(asset.GetName(.. new String()));
				}
				if ((outTypes.Count == start) && (target != null))
					outTypes.Add(target.GetName(.. new String()));
			};
		services.Describe = new [=context, =icons] (id, outShown) =>
			{
				let project = context.Project;
				let instance = (project != null) ? project.SourceDb.GetInstance(id) : null;
				if (instance == null)
					return false;
				outShown.Name.Set(instance.Name);
				// The instance names its type in full; the page registry knows the Beef type by it.
				if (let type = context.Pages.ResolveType(instance.TypeName))
				{
					let icon = icons.For(type, "Asset");
					outShown.Glyph.Set(icon.Source);
					outShown.GlyphClass.Set(icon.Class);
				}
				if (context.Thumbnails != null)
					outShown.Picture = context.Thumbnails.Get(id); // null until generated; a bind asks again
				return true;
			};
		services.Open = new [=context] (id) =>
			{
				if (context.OpenAsset != null)
					context.OpenAsset(id);
			};
		services.Reveal = new [=context] (id) =>
			{
				if (context.RevealAsset != null)
					context.RevealAsset(id);
			};
		return services;
	}
}

/// A Reference property's row: an AssetPickerSlot over the asset its Guid names.
class ResourceRefEditor : SingleControlEditor
{
	/// What a reference to an asset the project lacks shows: still cleared, still replaced.
	public const String cMissingText = "(missing)";

	/// Borrowed: the registrar's, outliving the editor.
	private ResourceRefServices mServices;
	private AssetPickerSlot mSlot ~ _.ReleaseRef();
	private List<String> mTypes = new .() ~ DeleteContainerAndItems!(_);
	private Guid mCurrent = .Empty;
	private bool mMixed = false;

	/// `services` outlives the editor (the registrar's).
	public this(ResourceRefServices services)
	{
		mServices = services;
		AddClass("reference");
		mSlot = new AssetPickerSlot();
		Hold(mSlot);
	}

	/// The editor for every Reference property `registry` shows; `services` outlives it.
	public static void Register(PropertyEditorRegistry registry, ResourceRefServices services)
	{
		registry.RegisterKind(.Reference, new [=services] () => new ResourceRefEditor(services));
	}

	public AssetPickerSlot Slot => mSlot;
	/// What it references: nil for none, or when the objects differ.
	public Guid Current => mCurrent;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mCurrent = .Empty;
		mMixed = value.Mixed;
		if (!mMixed)
		{
			var text = value.Value.AsString;
			text.Trim();
			if (!text.IsEmpty && (Guid.Parse(text) case .Ok(let id)))
				mCurrent = id;
		}
		ClearAndDeleteItems(mTypes);
		if ((info.ReferenceType != null) && (mServices.AcceptedTypes != null))
			mServices.AcceptedTypes(info.ReferenceType, mTypes);
		let types = scope List<StringView>();
		for (let type in mTypes)
			types.Add(type);
		mSlot.SetAcceptedTypes(types);
		Wire();
		Show();
	}

	/// Its verbs, as far as the services and the property allow: a read-only one only opens (and
	/// reveals, which changes nothing either); over objects that differ, there is no one asset to
	/// open or reveal.
	private void Wire()
	{
		let writes = !IsReadOnly;
		if (writes && (mServices.Pick != null))
			mSlot.SetOnPick(new [=this] () => { Pick(); });
		else
			mSlot.SetOnPick(null);
		if (writes)
		{
			mSlot.SetOnClear(new [=this] () => { Assign(.Empty); });
			mSlot.SetOnDropped(new [=this] (id) => { Assign(id); });
		}
		else
		{
			mSlot.SetOnClear(null);
			mSlot.SetOnDropped(null);
		}
		if ((mServices.Open != null) && !mMixed)
			mSlot.SetOnOpen(new [=this] () => { mServices.Open(mCurrent); });
		else
			mSlot.SetOnOpen(null);
		if ((mServices.Reveal != null) && !mMixed)
			mSlot.SetOnReveal(new [=this] () => { mServices.Reveal(mCurrent); });
		else
			mSlot.SetOnReveal(null);
	}

	private void Show()
	{
		mSlot.SetPicture(null);
		if (mMixed)
		{
			mSlot.SetGlyph("");
			mSlot.SetValue(MixedValueText());
			return;
		}
		if (mCurrent.IsNil)
		{
			mSlot.SetGlyph("");
			mSlot.SetValue("");
			return;
		}
		let shown = scope ResourceRefShown();
		if ((mServices.Describe != null) && mServices.Describe(mCurrent, shown))
		{
			mSlot.SetGlyph(shown.Glyph, shown.GlyphClass);
			mSlot.SetPicture(shown.Picture);
			mSlot.SetValue(shown.Name);
		}
		else
		{
			mSlot.SetGlyph("");
			mSlot.SetValue(cMissingText); // still cleared, still replaced
		}
	}

	/// The picker opens below the slot, the current value checked. It answers later, when the row
	/// may show another property (rows are pooled): its choice lands only on the property it was
	/// opened for. The row is held until the picker lets its answer go.
	private void Pick()
	{
		let self = this;
		let path = new String(Path);
		AddRef();
		mServices.Pick(mTypes, mCurrent, new [=self, =path] (id) =>
			{
				if (self.Path == path)
					self.Assign(id);
			} ~ { self.ReleaseRef(); delete path; });
	}

	/// One write through the grid: a pick, a drop and a clear alike.
	private void Assign(Guid id)
	{
		AddRef(); // the write may rebind the row
		defer ReleaseRef();
		let text = scope String();
		if (!id.IsNil)
			id.ToString(text);
		ApplyEdit(PropertyWrite(Sedulous.GUI.Variant(text)));
	}
}
