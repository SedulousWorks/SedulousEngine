using System;
using System.Collections;
using System.Reflection;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// Rewriting the entity references INSIDE a component when a prefab is spawned.
///
/// An owner remaps through the source to live map, but a component can also point at
/// entities through its own EntityRef fields: an animator's meshes, a spawner's target.
/// Those have to become the instance's copies, or every instance of a prefab would point
/// back at the template's entities.
///
/// A reference that resolves OUTSIDE the prefab is left alone. It points at the wider
/// scene rather than at the template, and rewriting it would silently redirect it to
/// whichever member happened to share a guid.
///
/// Driven by REFLECTION, so a component with a reference field is covered without a line
/// of per type code. [Component] and [SerializableComponent] force the field reflection
/// this needs, which is why declaring a component is the same act as asking for it.
static class PrefabEntityRefs
{
	/// Remaps every reference in `owner`'s component of this manager's type.
	///
	/// Run after the component is read and BEFORE its baseline is captured, so the
	/// baseline records the remapped value and a save does not then see a difference that
	/// spawning itself introduced.
	public static void Remap(ComponentManagerBase manager, EntityHandle owner,
		Dictionary<Guid, Guid> liveBySource)
	{
		let type = manager.ComponentType;
		if (type == null)
			return;

		let address = manager.GetComponentAddress(owner);
		if (address == null)
			return;

		for (let field in type.GetFields())
		{
			if (field.FieldType == typeof(EntityRef))
			{
				if (field.GetValueReference<EntityRef>(address, type) case .Ok(let reference))
					RemapOne(reference, liveBySource);
				continue;
			}

			// A LIST of references, which is how a component names several entities. The
			// elements are remapped in place through the list's own storage.
			if (field.FieldType == typeof(List<EntityRef>))
			{
				if (field.GetValueReference<List<EntityRef>>(address, type) case .Ok(let slot))
				{
					let list = *slot;
					if (list == null)
						continue;
					for (int i = 0; i < list.Count; i++)
					{
						var element = list[i];
						RemapOne(&element, liveBySource);
						list[i] = element;
					}
				}
			}
		}
	}

	private static void RemapOne(EntityRef* reference, Dictionary<Guid, Guid> liveBySource)
	{
		if ((reference == null) || reference.IsNil)
			return;
		if (liveBySource.TryGetValue(reference.Id, let live))
			reference.Id = live;
	}
}
