using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.Serialization; // the components' values, as they serialize
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Script.Resource;
using Sedulous.Engine.Script;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

// A script component's behaviours as a property source, under its header in the inspector:
// reflection does not show them (a behaviour's
// properties are its script's, from the cooked class), so this source does. A list of behaviours,
// each its script (an asset slot taking script classes), Enabled, its update interval and its
// script's properties by their kinds (a vector its three parts, an entity a slot over the scene, an
// asset a slot of its type); a property differs from its script's default while the behaviour
// overrides it, and a revert drops the override. Every edit is each entity's component mutated
// (ComponentTarget), grouped: one undo step for the selection. A behaviour whose script has no
// cooked class says so in its name; one with no script shows only its own rows.

class ScriptBehaviorsSource : IPropertySource
{
	private const String cList = "behaviors";

	// What a path names: the list, a behaviour, one of its rows, a property's part.
	private struct Where
	{
		public bool List = false;
		public int Behavior = -1;
		/// "script", "enabled", "interval", "p<hash>"; empty: none.
		public StringView Row = default;
		/// A vector property's x, y or z.
		public int32 Part = -1;

		public this() {}
	}

	private SceneEditContext mEdit;
	// Null in a host with no editor context: a behaviour's class is then only what it has bound.
	private EditorContext mContext;
	private List<Guid> mEntities = new .() ~ delete _;
	private uint64 mSignature = 0;
	/// The components' values at the last look.
	private ShownState mShown = new .() ~ delete _;
	private uint64 mGroups = 0;

	/// The behaviours of `entities`' script components; `edit` and `context` are borrowed and
	/// outlive it.
	public this(SceneEditContext edit, EditorContext context, Span<Guid> entities)
	{
		mEdit = edit;
		mContext = context;
		for (let id in entities)
			mEntities.Add(id);
		mSignature = Signature();
	}

	/// Tells the grid when the behaviours changed outside it (an undo, a pick elsewhere): their
	/// rows when the behaviours or their classes did, their values when only a value did.
	public void Refresh()
	{
		// Called every frame while the entities are selected: the grid hears of it only when the
		// components' values moved.
		let moved = mShown.Take(scope (ar) =>
			{
				for (int o < mEntities.Count)
				{
					let component = Component(o);
					if (component != null)
						component.Serialize(ar);
				}
			});
		let signature = Signature();
		if (signature != mSignature)
		{
			mSignature = signature;
			NotifyPropertiesChanged();
		}
		else if (moved)
			NotifyValuesChanged();
	}

	// === IPropertySource ===

	public override int ObjectCount => mEntities.Count;

	public override void GetProperties(StringView parent, List<PropertyInfo> outInfos)
	{
		if (parent.IsEmpty)
		{
			let list = new PropertyInfo();
			list.Name.Set(cList);
			list.DisplayName.Set("Behaviors");
			list.Kind = .List;
			list.ListOps = PropertyListAdd | PropertyListRemove | PropertyListMove;
			outInfos.Add(list);
			return;
		}
		let place = Parse(parent);
		let first = Component(0);
		if (place.List)
		{
			let count = BehaviorCount();
			for (int i < count)
			{
				let info = new PropertyInfo();
				i.ToString(info.Name);
				info.Kind = .Group;
				let behavior = first.Behaviors[i];
				let type = ClassOf(behavior);
				if (behavior.Script.Id.IsNil)
					info.DisplayName.AppendF("Behavior {}", i + 1);
				else if (type != null)
					info.DisplayName.AppendF("Behavior {}: {}", i + 1, type.ClassName);
				else
					info.DisplayName.AppendF("Behavior {}: (not cooked)", i + 1);
				outInfos.Add(info);
			}
			return;
		}
		if ((place.Behavior < 0) || (first == null) || (place.Behavior >= first.Behaviors.Count))
			return;
		if (!place.Row.IsEmpty)
		{
			// A vector property's parts.
			let property = PropertyOf(place.Behavior, place.Row);
			if ((property != null) && (place.Part < 0))
				ScriptPropertyRows.Parts(property, outInfos);
			return;
		}
		let script = new PropertyInfo();
		script.Name.Set("script");
		script.DisplayName.Set("Script");
		script.Kind = .Reference;
		script.ReferenceType = typeof(ScriptClass);
		outInfos.Add(script);
		let enabled = new PropertyInfo();
		enabled.Name.Set("enabled");
		enabled.DisplayName.Set("Enabled");
		enabled.Kind = .Bool;
		outInfos.Add(enabled);
		let interval = new PropertyInfo();
		interval.Name.Set("interval");
		interval.DisplayName.Set("Update Interval");
		interval.Description.Set("Seconds between onUpdate calls (0: every frame)");
		interval.Kind = .Float;
		interval.HasRange = true;
		interval.Min = 0.0;
		interval.Max = 3600.0;
		interval.Step = 0.05;
		outInfos.Add(interval);
		if (let type = ClassOf(first.Behaviors[place.Behavior]))
			ScriptPropertyRows.Describe(type, outInfos);
	}

	public override Sedulous.GUI.Variant GetValue(StringView path, int object)
	{
		let place = Parse(path);
		if (place.List)
			return Sedulous.GUI.Variant((int64)BehaviorCount());
		let component = Component(object);
		if ((component == null) || (place.Behavior < 0) || (place.Behavior >= component.Behaviors.Count) || place.Row.IsEmpty)
			return .();
		let behavior = component.Behaviors[place.Behavior];
		switch (place.Row)
		{
		case "script": return ScriptPropertyRows.GuidText(behavior.Script.Id);
		case "enabled": return Sedulous.GUI.Variant(behavior.Enabled);
		case "interval": return Sedulous.GUI.Variant((double)behavior.UpdateInterval);
		default:
		}
		let property = PropertyOf(place.Behavior, place.Row);
		if (property == null)
			return .();
		let over = behavior.FindOverride(property.Hash);
		return ScriptPropertyRows.ToGrid((over != null) ? over.Value : property.Default, property.Type, place.Part);
	}

	public override void BeginEdit(StringView path) {}
	public override void PreviewEdit(StringView path, PropertyWrite write) {}
	public override void CancelEdit(StringView path) {}

	public override void CommitEdit(StringView path, PropertyWrite write)
	{
		let place = Parse(path);
		if ((place.Behavior < 0) || place.Row.IsEmpty)
			return;
		let index = place.Behavior;
		switch (place.Row)
		{
		case "script":
			var text = write.Value.AsString;
			text.Trim();
			var id = Guid.Empty;
			if (Guid.Parse(text) case .Ok(let parsed))
				id = parsed;
			Mutate(scope (c) =>
				{
					if (index >= c.Behaviors.Count)
						return;
					c.Behaviors[index].Script = Ref<ScriptClass>(id);
					ClearAndDeleteItems(c.Behaviors[index].Overrides); // another script's properties
				});
			return;
		case "enabled":
			let enabled = write.Value.AsBool;
			Mutate(scope (c) =>
				{
					if (index < c.Behaviors.Count)
						c.Behaviors[index].Enabled = enabled;
				});
			return;
		case "interval":
			let interval = (float)Math.Max(0.0, write.Value.AsFloat);
			Mutate(scope (c) =>
				{
					if (index < c.Behaviors.Count)
						c.Behaviors[index].UpdateInterval = interval;
				});
			return;
		default:
		}
		let property = PropertyOf(index, place.Row);
		if (property == null)
			return;
		let hash = property.Hash;
		let kind = property.Type;
		let fallback = property.Default;
		let part = place.Part;
		let value = write.Value;
		Mutate(scope (c) =>
			{
				if (index >= c.Behaviors.Count)
					return;
				let behavior = c.Behaviors[index];
				let over = behavior.FindOverride(hash);
				behavior.SetOverride(hash, ScriptPropertyRows.FromGrid((over != null) ? over.Value : fallback, kind, part, value));
			});
	}

	public override bool EditList(StringView path, ListEdit edit)
	{
		if (!Parse(path).List)
			return false;
		let kind = edit.Kind;
		let at = edit.Index;
		let to = edit.To;
		Mutate(scope (c) =>
			{
				switch (kind)
				{
				case .Insert:
					c.Behaviors.Insert(Math.Clamp(at, 0, c.Behaviors.Count), new ScriptBehavior());
				case .Remove:
					if ((at >= 0) && (at < c.Behaviors.Count))
					{
						delete c.Behaviors[at];
						c.Behaviors.RemoveAt(at);
					}
				case .Move:
					if ((at >= 0) && (at < c.Behaviors.Count) && (to >= 0) && (to < c.Behaviors.Count) && (at != to))
					{
						let moved = c.Behaviors[at];
						c.Behaviors.RemoveAt(at);
						c.Behaviors.Insert(to, moved);
					}
				}
			});
		return true;
	}

	public override Sedulous.GUI.Variant GetDefault(StringView path, int object)
	{
		let place = Parse(path);
		if ((place.Behavior < 0) || place.Row.IsEmpty)
			return .();
		switch (place.Row)
		{
		case "enabled": return Sedulous.GUI.Variant(true);
		case "interval": return Sedulous.GUI.Variant(0.0);
		case "script": return .();
		default:
		}
		let property = PropertyOf(place.Behavior, place.Row);
		return (property != null) ? ScriptPropertyRows.ToGrid(property.Default, property.Type, place.Part) : .();
	}

	public override bool Revert(StringView path)
	{
		let place = Parse(path);
		if ((place.Behavior < 0) || place.Row.IsEmpty)
			return false;
		let index = place.Behavior;
		let property = PropertyOf(index, place.Row);
		if (property == null)
		{
			// Its own rows: their defaults.
			if ((place.Row != "enabled") && (place.Row != "interval"))
				return false;
			let enabled = place.Row == "enabled";
			Mutate(scope (c) =>
				{
					if (index >= c.Behaviors.Count)
						return;
					if (enabled)
						c.Behaviors[index].Enabled = true;
					else
						c.Behaviors[index].UpdateInterval = 0.0f;
				});
			return true;
		}
		let hash = property.Hash;
		Mutate(scope (c) =>
			{
				if (index < c.Behaviors.Count)
					c.Behaviors[index].RemoveOverride(hash);
			});
		return true;
	}

	public override void GetRevertText(StringView path, String outText) => outText.Append("Revert to the script's default");

	public override void CopyValue(StringView path, String outText) {}

	public override bool PasteValue(StringView path, StringView text, String reason)
	{
		reason.Set("A behaviour's value does not paste");
		return false;
	}

	// === Its behaviours ===

	private ScriptComponent* Component(int object)
	{
		if ((object < 0) || (object >= mEntities.Count))
			return null;
		let manager = mEdit.Scene.GetSystem<ScriptComponentManager>();
		let e = mEdit.Resolve(mEntities[object]);
		let component = ((manager != null) && e.IsAssigned) ? manager.Get(e) : null;
		return ((component != null) && (component.Behaviors != null)) ? component : null;
	}

	// The fewest any entity has: a list shows what every object holds.
	private int BehaviorCount()
	{
		var count = int.MaxValue;
		for (int o < mEntities.Count)
		{
			let component = Component(o);
			count = Math.Min(count, (component != null) ? component.Behaviors.Count : 0);
		}
		return (count == int.MaxValue) ? 0 : count;
	}

	private ScriptClass ClassOf(ScriptBehavior behavior)
	{
		if (behavior.Script.Get != null)
			return behavior.Script.Get;
		if (behavior.Script.Id.IsNil || (mContext == null) || (mContext.Resources == null))
			return null;
		return mContext.Resources.Bind<ScriptClass>(behavior.Script.Id).Get;
	}

	private ScriptPropertyDesc PropertyOf(int behavior, StringView row)
	{
		let component = Component(0);
		if ((component == null) || (behavior >= component.Behaviors.Count))
			return null;
		let type = ClassOf(component.Behaviors[behavior]);
		if (type == null)
			return null;
		return ScriptPropertyRows.Find(type, row);
	}

	private uint64 Signature()
	{
		var hash = 14695981039346656037UL;
		for (int o < mEntities.Count)
		{
			let component = Component(o);
			if (component == null)
				continue;
			hash = (hash ^ (uint64)component.Behaviors.Count) &* 1099511628211UL;
			for (let behavior in component.Behaviors)
			{
				hash = (hash ^ (uint64)behavior.Script.Id.GetHashCode()) &* 1099511628211UL;
				hash = (hash ^ ((ClassOf(behavior) != null) ? 1UL : 0UL)) &* 1099511628211UL;
			}
		}
		return hash;
	}

	// Every selected entity's component mutated as one undo step.
	private void Mutate(delegate void(ScriptComponent* component) mutate)
	{
		mEdit.Commands.BeginGroup(scope $"inspector.behaviors.{++mGroups}"); // never coalesced with the last
		for (let entity in mEntities)
		{
			let target = scope ComponentTarget(mEdit, entity, typeof(ScriptComponent));
			target.Mutate(scope [&] (instance) =>
				{
					let component = (ScriptComponent*)instance;
					if (component.Behaviors != null)
						mutate(component);
				});
		}
		mEdit.Commands.EndGroup();
		Refresh();
	}

	// === Paths and values ===

	// `path` read: "behaviors", "behaviors.<i>", "behaviors.<i>.<row>", "behaviors.<i>.<row>.<part>".
	private static Where Parse(StringView path)
	{
		var place = Where();
		if (!path.StartsWith(cList))
			return place;
		var rest = path.Substring(cList.Length);
		if (rest.IsEmpty)
		{
			place.List = true;
			return place;
		}
		if (rest[0] != '.')
			return place;
		rest = rest.Substring(1);
		var at = 0;
		var index = 0;
		while ((at < rest.Length) && rest[at].IsDigit)
			index = index * 10 + (rest[at++] - '0');
		if (at == 0)
			return place;
		place.Behavior = index;
		if (at == rest.Length)
			return place;
		ScriptPropertyRows.ParseRow(rest.Substring(at + 1), out place.Row, out place.Part);
		return place;
	}
}

/// A script class's properties as a grid's rows (a behaviour's, a level's): each row named
/// `p<hash>`, its kind from the property's, a vector its three parts; values to and from the
/// grid's.
static class ScriptPropertyRows
{
	private static StringView[3] sParts = .("x", "y", "z");
	// The product types script properties name, by name (null: none of that name).
	private static Dictionary<String, Type> sAssetTypes = new .() ~ DeleteDictionaryAndKeys!(_);

	/// The rows of `type`'s properties.
	public static void Describe(ScriptClass type, List<PropertyInfo> outInfos)
	{
		for (let property in type.Properties)
		{
			let info = new PropertyInfo();
			switch (property.Type)
			{
			case .Float: info.Kind = .Float;
			case .Int: info.Kind = .Integer;
			case .Bool: info.Kind = .Bool;
			case .String: info.Kind = .String;
			case .Color: info.Kind = .Color;
			case .Vec3:
				info.Kind = .Group;
				info.Hint.Set("Float3");
			case .Entity:
				info.Kind = .Reference;
				info.Hint.Set(FieldPropertySource.cEntityRefHint);
				info.ReferenceType = typeof(EntityRef);
			case .Asset:
				info.Kind = .Reference;
				info.ReferenceType = AssetType(property.AssetType);
			default:
				delete info;
				continue;
			}
			RowOf(property, info.Name);
			info.DisplayName.Set(property.Name);
			info.Description.Set(property.Description);
			outInfos.Add(info);
		}
	}

	/// A vector property's parts (`x`, `y`, `z`), under its row; none for any other.
	public static void Parts(ScriptPropertyDesc property, List<PropertyInfo> outInfos)
	{
		if (property.Type != .Vec3)
			return;
		for (let part in sParts)
		{
			let info = new PropertyInfo();
			info.Name.Set(part);
			info.Kind = .Float;
			outInfos.Add(info);
		}
	}

	/// The property a row names (`p<hash>`); null when none.
	public static ScriptPropertyDesc Find(ScriptClass type, StringView row)
	{
		for (let property in type.Properties)
		{
			if (RowOf(property, .. scope String()) == row)
				return property;
		}
		return null;
	}

	/// A row's name (`p<hash>`) and a part's index (`x`: 0; else -1) parsed from what follows a
	/// source's own path; `outRow` is a view of `rest`.
	public static void ParseRow(StringView rest, out StringView outRow, out int32 outPart)
	{
		var dot = rest.IndexOf('.');
		if (dot < 0)
			dot = rest.Length;
		outRow = rest.Substring(0, dot);
		outPart = -1;
		if (dot < rest.Length)
		{
			let part = rest.Substring(dot + 1);
			for (int32 i < 3)
			{
				if (part == sParts[i])
					outPart = i;
			}
		}
	}

	/// A property's row name (`p<hash>`), appended.
	public static void RowOf(ScriptPropertyDesc property, String outRow) => outRow.AppendF("p{}", property.Hash);

	// The product type a script's asset property names ("AudioClip"), found by its name.
	private static Type AssetType(StringView name)
	{
		if (name.IsEmpty)
			return null;
		if (sAssetTypes.TryGetAlt(name, let known, let found))
			return found;
		Type type = null;
		let text = scope String();
		for (let candidate in Type.Types)
		{
			// What is no named type instance (a tuple's GetName fatals) cannot be one.
			if (!(candidate is TypeInstance) || candidate.IsBoxed || candidate.IsPointer || candidate.IsArray
				|| candidate.IsSizedArray || candidate.IsGenericParam || candidate.IsTuple)
				continue;
			text.Clear();
			candidate.GetFullName(text);
			if (AssetTypeNames.Matches(text, name))
			{
				type = candidate;
				break;
			}
		}
		sAssetTypes[new String(name)] = type;
		return type;
	}

	/// An id as a reference row shows it: empty for nil.
	public static Sedulous.GUI.Variant GuidText(Guid id)
	{
		if (id.IsNil)
			return Sedulous.GUI.Variant("").Copy();
		return Sedulous.GUI.Variant(id.ToString(.. scope String())).Copy();
	}

	/// A row's value: `value` as the property's kind (`part` a vector's, else -1).
	public static Sedulous.GUI.Variant ToGrid(ScriptPropertyValue value, ScriptPropertyType type, int32 part)
	{
		switch (type)
		{
		case .Float: return Sedulous.GUI.Variant(value.Number);
		case .Int: return Sedulous.GUI.Variant((int64)value.Number);
		case .Bool: return Sedulous.GUI.Variant(value.Boolean);
		case .String: return Sedulous.GUI.Variant((StringView)(value.Text ?? "")).Copy();
		case .Color: return Sedulous.GUI.Variant(value.Color);
		case .Vec3:
			switch (part)
			{
			case 0: return Sedulous.GUI.Variant((double)value.Vector.X);
			case 1: return Sedulous.GUI.Variant((double)value.Vector.Y);
			case 2: return Sedulous.GUI.Variant((double)value.Vector.Z);
			default: return .();
			}
		case .Entity, .Asset: return GuidText(value.Id);
		default: return .();
		}
	}

	/// `write` over `old` as the property's kind; a text is a new string the override takes.
	public static ScriptPropertyValue FromGrid(ScriptPropertyValue old, ScriptPropertyType type, int32 part, Sedulous.GUI.Variant write)
	{
		var value = old;
		value.Kind = type;
		// The override owns its text: never the one `old` holds.
		value.Text = (old.Text != null) ? new String(old.Text) : null;
		switch (type)
		{
		case .Float: value.Number = write.AsFloat;
		case .Int: value.Number = (double)write.AsInt;
		case .Bool: value.Boolean = write.AsBool;
		case .String:
			if (value.Text == null)
				value.Text = new String();
			value.Text.Set(write.AsString);
		case .Color: value.Color = write.AsColor;
		case .Vec3:
			switch (part)
			{
			case 0: value.Vector.X = (float)write.AsFloat;
			case 1: value.Vector.Y = (float)write.AsFloat;
			case 2: value.Vector.Z = (float)write.AsFloat;
			default:
			}
		case .Entity, .Asset:
			var text = write.AsString;
			text.Trim();
			var id = Guid.Empty;
			if (Guid.Parse(text) case .Ok(let parsed))
				id = parsed;
			value.Id = id;
		default:
		}
		return value;
	}
}
