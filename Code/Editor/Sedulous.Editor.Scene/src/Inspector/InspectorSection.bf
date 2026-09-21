using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The rows a GENERATED inspector body adds for one target, under one category. Each verb
/// makes an editor, wires its setter to the target's undoable verbs, and registers a
/// refresher that re-reads the live value every frame the row is not being edited.
///
/// The read delegates the generated code hands over are OWNED here for the life of the
/// grid's contents; the generated code never frees anything.
class InspectorSection
{
	private SceneInspectorView mOwner;
	private InspectorTarget mTarget;
	private String mCategory = new .() ~ delete _;
	private String mPendingLabel = new .() ~ delete _;
	private String mPendingTooltip = new .() ~ delete _;

	public this(SceneInspectorView owner, InspectorTarget target, StringView category)
	{
		mOwner = owner;
		mTarget = target;
		mCategory.Set(category);
	}

	public InspectorTarget Target => mTarget;
	public StringView Category => mCategory;
	public int RowCount => mOwner.Grid.PropertyCount;

	/// The label and tooltip for the NEXT row added.
	public void Label(StringView displayName, StringView tooltip)
	{
		mPendingLabel.Set(displayName);
		mPendingTooltip.Set(tooltip);
	}

	// ---- scalar rows ----

	public void FloatRow(StringView field, delegate float(void* p) read, bool ranged, float min,
		float max, float step)
	{
		let key = Own(field);
		Keep(read);
		let target = mTarget;
		let value = Read(read, 0.0f);
		if (ranged)
		{
			let editor = new RangeEditor(field, value, min, max, step,
				new [=target, =key](v) => { target.SetProperty(key, Variant.Create<float>(v)); }, mCategory);
			Add(editor, new [=editor, =read, =target]() => { if (let p = target.Address) editor.SetValue(read(p)); });
			return;
		}
		let editor = new FloatEditor(field, value, -1e9, 1e9, 0.1, 2,
			new [=target, =key](v) => { target.SetProperty(key, Variant.Create<float>((float)v)); }, mCategory);
		Add(editor, new [=editor, =read, =target]() => { if (let p = target.Address) editor.SetValue(read(p)); });
	}

	public void BoolRow(StringView field, delegate bool(void* p) read)
	{
		let key = Own(field);
		Keep(read);
		let target = mTarget;
		let editor = new BoolEditor(field, Read(read, false),
			new [=target, =key](v) => { target.SetProperty(key, Variant.Create<bool>(v)); }, mCategory);
		Add(editor, new [=editor, =read, =target]() => { if (let p = target.Address) editor.SetValue(read(p)); });
	}

	/// A COMPUTED bool, written back through Mutate: the whole component is the undo step,
	/// since there is no field for a property write to land on.
	public void BoolRow(StringView field, delegate bool(void* p) read, delegate void(void* p, bool v) write)
	{
		Own(field);
		Keep(read);
		Keep(write);
		let target = mTarget;
		let editor = new BoolEditor(field, Read(read, false),
			new [=target, =write](v) => { target.Mutate(scope [=write, =v](p) => { write(p, v); }); }, mCategory);
		Add(editor, new [=editor, =read, =target]() => { if (let p = target.Address) editor.SetValue(read(p)); });
	}

	/// A COMPUTED value, shown as text and never edited; `read` formats it.
	public void ReadOnlyRow(StringView field, delegate void(void* p, String text) read)
	{
		Own(field);
		Keep(read);
		let target = mTarget;
		let initial = scope String();
		if (let p = target.Address)
			read(p, initial);
		let editor = new ReadOnlyEditor(field, initial, mCategory);
		Add(editor, new [=editor, =read, =target]() =>
		{
			if (let p = target.Address)
			{
				let text = scope String();
				read(p, text);
				editor.SetValue(text);
			}
		});
	}

	/// `pack` makes a Variant of the field's own integer type from the edited value.
	public void IntRow(StringView field, delegate int64(void* p) read, delegate Variant(int64 v) pack)
	{
		let key = Own(field);
		Keep(read);
		Keep(pack);
		let target = mTarget;
		let editor = new IntEditor(field, Read(read, (int64)0), int64.MinValue, int64.MaxValue,
			new [=target, =key, =pack](v) => { target.SetProperty(key, pack(v)); }, mCategory);
		Add(editor, new [=editor, =read, =target]() => { if (let p = target.Address) editor.SetValue(read(p)); });
	}

	/// The cases by name, parallel to their raw values; the raw value is what is written.
	public void EnumRow(StringView field, delegate int64(void* p) read, Span<StringView> names,
		Span<int64> values)
	{
		let key = Own(field);
		Keep(read);
		let target = mTarget;
		let raws = new List<int64>();
		raws.AddRange(values);
		Keep(raws);
		let editor = new EnumEditor(field, IndexOf(raws, Read(read, (int64)0)), names,
			new [=target, =key, =raws](index) =>
			{
				if ((index >= 0) && (index < raws.Count))
					target.SetPropertyRaw(key, raws[index]);
			}, mCategory);
		Add(editor, new [=editor, =read, =target, =raws]() =>
		{
			if (let p = target.Address)
				editor.SetValue(IndexOf(raws, read(p)));
		});
	}

	/// A String field, edited in place through Mutate: the string object stays the
	/// component's own.
	public void TextRow(StringView field, delegate StringView(void* p) read,
		delegate void(void* p, StringView v) write)
	{
		Own(field);
		Keep(read);
		Keep(write);
		let target = mTarget;
		let editor = new StringEditor(field, Read(read, StringView()),
			new [=target, =write](v) =>
			{
				let text = scope String(v);
				target.Mutate(scope [=write, =text](p) => { write(p, text); });
			}, mCategory);
		Add(editor, new [=editor, =read, =target]() => { if (let p = target.Address) editor.SetValue(read(p)); });
	}

	public void Float2Row(StringView field, delegate Float2(void* p) read)
	{
		let key = Own(field);
		Keep(read);
		let target = mTarget;
		let editor = new Float2Editor(field, Read(read, Float2()), -100000.0f, 100000.0f, 0.1f,
			new [=target, =key](v) => { target.SetProperty(key, Variant.Create<Float2>(v)); }, mCategory);
		Add(editor, new [=editor, =read, =target]() => { if (let p = target.Address) editor.SetValue(read(p)); });
	}

	public void Float3Row(StringView field, delegate Float3(void* p) read)
	{
		let key = Own(field);
		Keep(read);
		let target = mTarget;
		let editor = new Float3Editor(field, Read(read, Float3()), -100000.0f, 100000.0f, 0.1f,
			new [=target, =key](v) => { target.SetProperty(key, Variant.Create<Float3>(v)); }, mCategory);
		Add(editor, new [=editor, =read, =target]() => { if (let p = target.Address) editor.SetValue(read(p)); });
	}

	public void Float4Row(StringView field, delegate Float4(void* p) read)
	{
		let key = Own(field);
		Keep(read);
		let target = mTarget;
		let editor = new Float4Editor(field, Read(read, Float4()), -100000.0f, 100000.0f, 0.1f,
			new [=target, =key](v) => { target.SetProperty(key, Variant.Create<Float4>(v)); }, mCategory);
		Add(editor, new [=editor, =read, =target]() => { if (let p = target.Address) editor.SetValue(read(p)); });
	}

	public void ColorRow(StringView field, delegate Color(void* p) read)
	{
		let key = Own(field);
		Keep(read);
		let target = mTarget;
		let editor = new ColorEditor(field, Read(read, Color(1, 1, 1, 1)),
			new [=target, =key](v) => { target.SetProperty(key, Variant.Create<Color>(v)); }, mCategory);
		Add(editor, new [=editor, =read, =target]() => { if (let p = target.Address) editor.SetValue(read(p)); });
	}

	// ---- reference rows ----

	/// A Ref<T> field: the asset's name, its thumbnail, and the pick, clear, edit, reveal and
	/// drop verbs, all through the target's undoable ref command.
	public void ResourceRefRow<T>(StringView field, delegate Guid(void* p) read,
		Span<StringView> assetTypes) where T : class
	{
		let key = Own(field);
		Keep(read);
		let target = mTarget;
		let owner = mOwner;
		let types = new List<String>();
		Keep(types);
		for (let t in assetTypes)
			types.Add(Own(t));

		let editor = new ResourceRefEditor(field, owner.AssetNameFor(Read(read, Guid()), .. scope .()), mCategory);
		editor.OnPick = new [=owner, =target, =key, =types]() =>
		{
			if ((owner.Context == null) || (owner.Editor.Project == null))
				return;
			let names = scope List<StringView>();
			for (let t in types)
				names.Add(t);
			let dialog = new AssetPickerDialog(owner.Editor, names);
			dialog.OnPicked = new [=owner, =target, =key](picked) => { SetRef<T>(owner, target, key, picked); };
			dialog.Show(owner.Context);
		};
		if (!types.IsEmpty)
			editor.SetPreviewIcon(EditorIcons.ForAssetType(types[0]));
		editor.OnClear = new [=owner, =target, =key]() =>
		{
			if ((owner.Context == null) || (owner.Editor.Project == null))
				return;
			SetRef<T>(owner, target, key, .());
		};
		editor.OnEdit = new [=owner, =read, =target]() =>
		{
			let id = Read(read, target, Guid());
			if (!id.IsNil && (owner.Editor.OpenAsset != null))
				owner.Editor.OpenAsset(id);
		};
		editor.OnReveal = new [=owner, =read, =target]() =>
		{
			let id = Read(read, target, Guid());
			if (!id.IsNil && (owner.Editor.RevealAsset != null))
				owner.Editor.RevealAsset(id);
		};
		let accepted = scope List<StringView>();
		for (let t in types)
			accepted.Add(t);
		editor.SetAcceptedTypes(accepted);
		editor.OnAssignDropped = new [=owner, =target, =key](picked) =>
		{
			if ((owner.Context == null) || (owner.Editor.Project == null))
				return;
			SetRef<T>(owner, target, key, picked);
		};
		editor.OnRejectedDrop = new [=owner, =types](assetName, typeName) =>
		{
			let wanted = types.IsEmpty ? StringView("?") : StringView(types[0]);
			owner.Editor.Notify(.Warning, scope $"{assetName} is a {typeName} - this field takes {wanted}");
		};
		Add(editor, new [=owner, =editor, =read, =target]() =>
		{
			let id = Read(read, target, Guid());
			editor.SetValueText(owner.AssetNameFor(id, .. scope .()));
			editor.SetPreviewThumbnail((!id.IsNil && (owner.Editor.Thumbnails != null))
				? owner.Editor.Thumbnails.Get(id) : null);
		});
	}

	/// An EntityRef field: the target entity's name and a picker over the scene tree.
	public void EntityRefRow(StringView field, delegate Guid(void* p) read)
	{
		let key = Own(field);
		Keep(read);
		let target = mTarget;
		let owner = mOwner;
		let editor = new ResourceRefEditor(field, EntityNameFor(target, Read(read, Guid()), .. scope .()), mCategory);
		editor.OnPick = new [=owner, =target, =key, =read]() =>
		{
			if (owner.Context == null)
				return;
			let dialog = new EntityPickerDialog(target.Edit.Scene, Read(read, target, Guid()));
			dialog.OnPicked = new [=target, =key](picked) => { target.SetEntityRef(key, picked); };
			dialog.Show(owner.Context);
		};
		Add(editor, new [=editor, =read, =target]() =>
		{
			editor.SetValueText(EntityNameFor(target, Read(read, target, Guid()), .. scope .()));
		});
	}

	// ---- list rows ----

	/// A List<Ref<T>> field: a slot per element, picked from the asset browser.
	public void ResourceRefListRow<T>(StringView field, delegate List<Ref<T>>(void* p) read,
		Span<StringView> assetTypes) where T : class
	{
		Own(field);
		Keep(read);
		let target = mTarget;
		let owner = mOwner;
		let types = new List<String>();
		Keep(types);
		for (let t in assetTypes)
			types.Add(Own(t));

		let names = scope List<String>();
		defer { ClearAndDeleteItems(names); }
		let list = new ContainerListEditor(field, mCategory);
		delegate void(List<String> outNames) computeNames = new [=owner, =read, =target](outNames) =>
		{
			ClearAndDeleteItems(outNames);
			let p = target.Address;
			if (p == null)
				return;
			for (let reference in read(p))
			{
				let id = reference.Id;
				outNames.Add(id.IsNil ? new String("None") : owner.AssetNameFor(id, .. new String()));
			}
		};
		Keep(computeNames);
		computeNames(list.SlotNames);

		list.OnAdd = new [=owner, =target, =read]() =>
		{
			target.Mutate(scope [=read](p) => { read(p).Add(Ref<T>(Guid())); });
			owner.RequestRebuild();
		};
		list.OnRemoveSlot = new [=owner, =target, =read](i) =>
		{
			target.Mutate(scope [=read, =i](p) =>
			{
				let l = read(p);
				if (i < l.Count)
					l.RemoveAt(i);
			});
			owner.RequestRebuild();
		};
		list.OnMoveSlot = new [=owner, =target, =read](i, up) =>
		{
			target.Mutate(scope [=read, =i, =up](p) =>
			{
				let l = read(p);
				let other = up ? i - 1 : i + 1;
				if ((i < l.Count) && (other >= 0) && (other < l.Count))
					Swap!(l[i], l[other]);
			});
			owner.RequestRebuild();
		};
		list.OnPickSlot = new [=owner, =target, =read, =types](i) =>
		{
			if ((owner.Context == null) || (owner.Editor.Project == null))
				return;
			let typeNames = scope List<StringView>();
			for (let t in types)
				typeNames.Add(t);
			let dialog = new AssetPickerDialog(owner.Editor, typeNames);
			dialog.OnPicked = new [=owner, =target, =read, =i](picked) =>
			{
				target.Mutate(scope [=read, =i, =picked](p) =>
				{
					let l = read(p);
					if (i < l.Count)
						l[i] = Ref<T>(picked);
				});
				owner.RequestRebuild();
			};
			dialog.Show(owner.Context);
		};
		Add(list, new [=owner, =list, =computeNames]() =>
		{
			let now = scope List<String>();
			defer { ClearAndDeleteItems(now); }
			computeNames(now);
			if (!SameNames(now, list.SlotNames))
				owner.RequestRebuild();
		});
	}

	/// A List<EntityRef> field: a slot per element, picked from the scene tree.
	public void EntityRefListRow(StringView field, delegate List<EntityRef>(void* p) read)
	{
		Own(field);
		Keep(read);
		let target = mTarget;
		let owner = mOwner;
		let list = new ContainerListEditor(field, mCategory);
		delegate void(List<String> outNames) computeNames = new [=read, =target](outNames) =>
		{
			ClearAndDeleteItems(outNames);
			let p = target.Address;
			if (p == null)
				return;
			for (let reference in read(p))
				outNames.Add(reference.IsNil ? new String("None") : EntityNameFor(target, reference.Id, .. new String()));
		};
		Keep(computeNames);
		computeNames(list.SlotNames);

		list.OnAdd = new [=owner, =target, =read]() =>
		{
			target.Mutate(scope [=read](p) => { read(p).Add(EntityRef()); });
			owner.RequestRebuild();
		};
		list.OnRemoveSlot = new [=owner, =target, =read](i) =>
		{
			target.Mutate(scope [=read, =i](p) =>
			{
				let l = read(p);
				if (i < l.Count)
					l.RemoveAt(i);
			});
			owner.RequestRebuild();
		};
		list.OnMoveSlot = new [=owner, =target, =read](i, up) =>
		{
			target.Mutate(scope [=read, =i, =up](p) =>
			{
				let l = read(p);
				let other = up ? i - 1 : i + 1;
				if ((i < l.Count) && (other >= 0) && (other < l.Count))
					Swap!(l[i], l[other]);
			});
			owner.RequestRebuild();
		};
		list.OnPickSlot = new [=owner, =target, =read](i) =>
		{
			if (owner.Context == null)
				return;
			var current = Guid();
			if (let p = target.Address)
			{
				let l = read(p);
				if (i < l.Count)
					current = l[i].Id;
			}
			let dialog = new EntityPickerDialog(target.Edit.Scene, current);
			dialog.OnPicked = new [=owner, =target, =read, =i](picked) =>
			{
				target.Mutate(scope [=read, =i, =picked](p) =>
				{
					let l = read(p);
					if (i < l.Count)
						l[i] = EntityRef(picked);
				});
				owner.RequestRebuild();
			};
			dialog.Show(owner.Context);
		};
		Add(list, new [=owner, =list, =computeNames]() =>
		{
			let now = scope List<String>();
			defer { ClearAndDeleteItems(now); }
			computeNames(now);
			if (!SameNames(now, list.SlotNames))
				owner.RequestRebuild();
		});
	}

	/// A list of plain values: add, remove and reorder, each slot labelled by its type.
	public void ValueListRow<TElem>(StringView field, delegate List<TElem>(void* p) read,
		StringView elementLabel) where TElem : struct
	{
		GenericList<TElem>(field, read, elementLabel, scope (l) => { l.Add(default); });
	}

	/// A list of objects the list owns: adding constructs one.
	public void ObjectListRow<TElem>(StringView field, delegate List<TElem>(void* p) read,
		StringView elementLabel) where TElem : class, new, delete
	{
		GenericList<TElem>(field, read, elementLabel, scope (l) => { l.Add(new TElem()); });
	}

	private void GenericList<TElem>(StringView field, delegate List<TElem>(void* p) read,
		StringView elementLabel, delegate void(List<TElem>) appendElement)
	{
		Own(field);
		Keep(read);
		let target = mTarget;
		let owner = mOwner;
		let element = Own(elementLabel);
		let list = new ContainerListEditor(field, mCategory);
		delegate int() count = new [=read, =target]() => { let p = target.Address; return (p != null) ? read(p).Count : 0; };
		Keep(count);
		for (int i < count())
			list.SlotNames.Add(new String(element));

		delegate void(List<TElem> l) appendOwned = new [=appendElement](l) => { appendElement(l); };
		Keep(appendOwned);
		list.OnAdd = new [=owner, =target, =read, =appendOwned]() =>
		{
			target.Mutate(scope [=read, =appendOwned](p) => { appendOwned(read(p)); });
			owner.RequestRebuild();
		};
		list.OnRemoveSlot = new [=owner, =target, =read](i) =>
		{
			target.Mutate(scope [=read, =i](p) =>
			{
				let l = read(p);
				if (i < l.Count)
				{
					RemoveOwned(l, i);
				}
			});
			owner.RequestRebuild();
		};
		list.OnMoveSlot = new [=owner, =target, =read](i, up) =>
		{
			target.Mutate(scope [=read, =i, =up](p) =>
			{
				let l = read(p);
				let other = up ? i - 1 : i + 1;
				if ((i < l.Count) && (other >= 0) && (other < l.Count))
					Swap!(l[i], l[other]);
			});
			owner.RequestRebuild();
		};
		Add(list, new [=owner, =list, =count]() =>
		{
			if (count() != list.SlotNames.Count)
				owner.RequestRebuild();
		});
	}

	// ---- presentation ----

	/// Hides the rows from `firstRow` while the dependent value fails the condition, re-read
	/// every refresh.
	public void VisibleWhen(int firstRow, StringView spec, delegate int64(void* p) dependentRead)
	{
		Keep(dependentRead);
		let condition = new PropertyCondition();
		Keep(condition);
		if (!PropertyCondition.Parse(spec, condition))
			return;
		let target = mTarget;
		let grid = mOwner.Grid;
		for (int i = firstRow; i < grid.PropertyCount; i++)
		{
			let editor = grid.PropertyAt(i);
			delegate void() refresh = new [=editor, =condition, =dependentRead, =target]() =>
			{
				let p = target.Address;
				editor.SetRowVisible((p != null) && condition.Matches(dependentRead(p)));
			};
			refresh();
			mOwner.AddRefresher(refresh);
		}
	}

	// ---- plumbing ----

	/// Adds the editor with the pending label and tooltip applied, and its refresher.
	private void Add(PropertyEditor editor, delegate void() refresher)
	{
		if (!mPendingLabel.IsEmpty)
			editor.SetDisplayName(mPendingLabel);
		else
			editor.SetDisplayName(PropertyNames.Prettify(editor.Name, .. scope .()));
		if (!mPendingTooltip.IsEmpty)
			editor.SetTooltip(mPendingTooltip);
		mPendingLabel.Clear();
		mPendingTooltip.Clear();
		mOwner.AddEditor(editor, refresher);
	}

	private void Keep(Object owned) => mOwner.Keep(owned);

	/// An owned copy of a name the closures can hold.
	private String Own(StringView text)
	{
		let s = new String(text);
		Keep(s);
		return s;
	}

	private T Read<T>(delegate T(void* p) read, T fallback)
	{
		let p = mTarget.Address;
		return (p != null) ? read(p) : fallback;
	}

	private static T Read<T>(delegate T(void* p) read, InspectorTarget target, T fallback)
	{
		let p = target.Address;
		return (p != null) ? read(p) : fallback;
	}

	private static int32 IndexOf(List<int64> values, int64 value)
	{
		for (int32 i < (int32)values.Count)
		{
			if (values[i] == value)
				return i;
		}
		return 0;
	}

	private static void SetRef<T>(SceneInspectorView owner, InspectorTarget target, String key,
		Guid id) where T : class
	{
		let resources = owner.Editor.Resources;
		if (let component = target as ComponentTarget)
			target.Edit.SetComponentResourceRef<T>(component.Id, component.Type, key, id, resources);
		else if (let settings = target as SettingsTarget)
			target.Edit.SetSceneSettingResourceRef<T>(settings.Type, key, id, resources);
	}

	/// STATIC, taking the target: the section is scoped to the build and gone by the time a
	/// refresher runs, so a closure must never capture it.
	private static void EntityNameFor(InspectorTarget target, Guid id, String outName)
	{
		if (id.IsNil)
		{
			outName.Set("(none)");
			return;
		}
		let scene = target.Edit.Scene;
		let h = scene.FindEntity(id);
		outName.Set(h.IsAssigned ? scene.GetEntityName(h) : "(missing)");
	}

	private static bool SameNames(List<String> a, List<String> b)
	{
		if (a.Count != b.Count)
			return false;
		for (int i < a.Count)
		{
			if (a[i] != b[i])
				return false;
		}
		return true;
	}

	private static void RemoveOwned<TElem>(List<TElem> l, int i)
	{
		// An object element the list owns is freed with its slot.
		if (typeof(TElem).IsObject)
			delete (Object)l[i];
		l.RemoveAt(i);
	}
}
