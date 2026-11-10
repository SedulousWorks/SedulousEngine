using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

// The inspector's entity reference: a component's
// EntityRef as a slot, the grid's row for it (the field source takes EntityRef as a reference by its
// id, hinted "EntityRef", so this editor is chosen before the asset slot). It shows the entity
// referenced by its type icon and its name, "Not set", or "(missing)" when no entity of the scene has
// that id; its pick is the entity picker, the scene as its hierarchy shows it (the current one
// lit, None to clear); an entity dragged from the hierarchy drops on it. A pick, a drop and a clear are
// one write through the grid, so one undo step.

/// What the entity slots ask of their page. The registrar's; borrowed by the editors.
class EntityRefServices
{
	/// The scene whose entities it shows. Not owned.
	public SceneEditContext Edit = null;
	/// The entities' type icons; null: the plain entity's. Not owned.
	public EditorIcons Icons = null;
	/// Opens the entity picker for a request; OWNERSHIP of the request transfers. Null: no pick.
	public delegate void(EntityPickRequest request) Pick ~ delete _;
}

class EntityRefEditor : SingleControlEditor
{
	public const String cMissingText = "(missing)";

	/// Borrowed: the registrar's, outliving the editor.
	private EntityRefServices mServices;
	private AssetPickerSlot mSlot ~ _.ReleaseRef();
	private Guid mCurrent = .Empty;
	private bool mMixed = false;

	/// `services` outlives the editor (the registrar's).
	public this(EntityRefServices services)
	{
		mServices = services;
		AddClass("reference");
		mSlot = new AssetPickerSlot();
		Hold(mSlot);
	}

	/// The editor for every EntityRef `registry` shows; `services` outlives it.
	public static void Register(PropertyEditorRegistry registry, EntityRefServices services)
	{
		registry.RegisterHint(FieldPropertySource.cEntityRefHint, new [=services] () => new EntityRefEditor(services));
	}

	public AssetPickerSlot Slot => mSlot;
	/// What it references: nil for none, or when the objects differ.
	public Guid Current => mCurrent;

	/// The entity picker's request it opens: its value, and an answer that writes the pick. The
	/// caller takes it. Its pick lands only while the row still shows the property it was made for
	/// (rows are pooled); the row is held until the request lets its answer go.
	public EntityPickRequest Request()
	{
		let request = new EntityPickRequest();
		if (!mMixed)
			request.Current = mCurrent;
		let self = this;
		let path = new String(Path);
		AddRef();
		request.Chosen = new [=self, =path] (id) =>
			{
				if (self.Path != path)
					return; // the row shows another property now
				self.Assign(id); // None: nil
			} ~ { self.ReleaseRef(); delete path; };
		return request;
	}

	/// One write through the grid: a pick, a drop and a clear alike.
	public void Assign(Guid id)
	{
		AddRef(); // the write may rebind the row
		defer ReleaseRef();
		let text = scope String();
		if (!id.IsNil)
			id.ToString(text);
		ApplyEdit(PropertyWrite(Sedulous.GUI.Variant(text)));
	}

	/// Takes a dragged entity, as a drop on it does; false when the payload carries none of this
	/// scene's.
	public bool Take(DragPayload payload)
	{
		let entities = scope List<Guid>();
		if (IsReadOnly || (mServices.Edit == null) || !EntityDrag.Read(payload, entities) || !mServices.Edit.Scene.FindEntity(entities[0]).IsAssigned)
			return false;
		Assign(entities[0]);
		return true;
	}

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
		let writes = !IsReadOnly && (mServices.Edit != null);
		if (writes && (mServices.Pick != null))
			mSlot.SetOnPick(new [=this] () => { mServices.Pick(Request()); });
		else
			mSlot.SetOnPick(null);
		if (writes)
			mSlot.SetOnClear(new [=this] () => { Assign(.Empty); });
		else
			mSlot.SetOnClear(null);
		Show();
	}

	// An entity dragged from the hierarchy: the first it carries. The slot takes assets only, so an
	// entity's drag walks on to here.
	protected override void OnDragQuery(DropQuery query)
	{
		let entities = scope List<Guid>();
		if (IsReadOnly || (mServices.Edit == null) || !EntityDrag.Read(query.Payload, entities))
			return;
		let scene = mServices.Edit.Scene;
		let e = scene.FindEntity(entities[0]);
		if (!e.IsAssigned)
		{
			query.Refuse("That entity is in another scene");
			return;
		}
		query.Accept(.Link);
		query.Reason.Clear();
		query.Reason.AppendF("Use {}", scene.GetEntityName(e));
	}

	protected override void OnDrop(DragEvent e)
	{
		Take(e.Payload);
	}

	private void Show()
	{
		if (mMixed)
		{
			mSlot.SetGlyph("");
			mSlot.SetValue(MixedValueText());
			return;
		}
		if (mCurrent.IsNil || (mServices.Edit == null))
		{
			mSlot.SetGlyph("");
			mSlot.SetValue("");
			return;
		}
		let scene = mServices.Edit.Scene;
		let e = scene.FindEntity(mCurrent);
		if (!e.IsAssigned)
		{
			mSlot.SetValue(cMissingText); // an id no entity of the scene has
			mSlot.SetGlyph("Editor/Icons/warning.svg");
			return;
		}
		let name = scene.GetEntityName(e);
		mSlot.SetValue(name.IsEmpty ? "(unnamed)" : name);
		let source = scope String();
		let tint = scope String();
		IconOf(scene, e, source, tint);
		mSlot.SetGlyph(source, tint);
	}

	// An entity's first component's icon, else the plain entity's.
	private void IconOf(Sedulous.Scene.Scene scene, EntityHandle e, String outSource, String outClass)
	{
		if (mServices.Icons != null)
		{
			scene.ForEachManager(scope [&] (manager) =>
				{
					if (!outSource.IsEmpty || (manager.ComponentType == null) || !manager.HasComponent(e))
						return;
					let icon = mServices.Icons.For(manager.ComponentType, "");
					outSource.Set(icon.Source);
					outClass.Set(icon.Class);
				});
		}
		if (outSource.IsEmpty)
			outSource.Set("Editor/Icons/cube.svg");
	}
}
