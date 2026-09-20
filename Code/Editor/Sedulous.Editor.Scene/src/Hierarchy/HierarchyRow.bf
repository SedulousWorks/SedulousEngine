using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.Editor.Scene;

/// A hierarchy row: an editable name, tinted for a prefab member and dimmed when the entity
/// is not effectively active.
class HierarchyRow : EditableLabel
{
	private Guid mEntity = .();

	public Guid Entity => mEntity;

	public void Bind(Guid entity, StringView name, float textInset, bool prefabMember,
		bool effectivelyActive)
	{
		mEntity = entity;
		SetText(name);
		TextOffsetX.Value = textInset;
		Color? color = null;
		if (prefabMember)
			color = Color(0.45f, 0.72f, 1.0f, 1.0f);
		if (!effectivelyActive)
		{
			var faded = color.HasValue ? color.Value : Color(1.0f, 1.0f, 1.0f, 1.0f);
			faded.A = 0.45f;
			color = faded;
		}
		TextColor.Value = color;
	}
}
