using System;
using Sedulous.Core;

namespace Sedulous.Editor.Scene;

/// A profile asset's values, for the rows a scene's settings section shows: every write is one
/// of the page's snapshot commands. There is no scene block, so a [SceneOnly] field (the
/// source, the profile reference) has no row here.
class ProfileValuesTarget : InspectorTarget
{
	/// Borrowed: the page owns this target's rows.
	private SettingsProfilePage mPage;

	public this(SettingsProfilePage page) : base(null)
	{
		mPage = page;
	}

	public override Type TargetType => mPage.ValuesType;
	public override void* Address => mPage.ValuesAddress;
	public override InspectorTarget SceneOnlyTarget => null;

	public override void SetProperty(StringView field, Variant value)
	{
		var value;
		defer value.Dispose();
		let type = TargetType;
		if (!(RawFieldAccess.FindField(type, field) case .Ok(let info)))
			return;
		mPage.ApplyEdit(field, scope [&](values) => { RawFieldAccess.Write(info, values, type, value).IgnoreError(); });
	}

	public override void SetPropertyRaw(StringView field, int64 raw)
	{
		if (!(RawFieldAccess.FindField(TargetType, field) case .Ok(let info)))
			return;
		mPage.ApplyEdit(field, scope [&](values) =>
			{
				RawFieldAccess.WriteRawInt(RawFieldAccess.AddressOf(info, values), info.FieldType.Size, raw);
			});
	}

	/// A profile holds no entity references.
	public override void SetEntityRef(StringView field, Guid target) {}

	/// A Ref<T> field: its identity, which the preview binds when it takes the values.
	public override void SetReference(StringView field, Guid id)
	{
		if (!(RawFieldAccess.FindField(TargetType, field) case .Ok(let info)))
			return;
		if (!(info.FieldType.GetField("Id") case .Ok(let idField)))
			return;
		mPage.ApplyEdit(field, scope [&](values) =>
			{
				*(Guid*)RawFieldAccess.AddressOf(idField, RawFieldAccess.AddressOf(info, values)) = id;
			});
	}

	public override void Mutate(delegate void(void* instance) mutate, StringView mergeKey)
		=> mPage.ApplyEdit(mergeKey, scope [&](values) => { mutate(values); });
}
