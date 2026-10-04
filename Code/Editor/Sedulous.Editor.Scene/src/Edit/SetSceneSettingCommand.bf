using System;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Sets one reflected field of a system's settings block, by Variant or by raw integer
/// bytes. Merges like a scrub: consecutive sets of one field are one undo step.
class SetSceneSettingCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Type mSettingsType;
	private String mProperty = new .() ~ delete _;
	private Variant mNew = .() ~ _.Dispose();
	private Variant mOld = .() ~ _.Dispose();
	private int64 mNewRaw = 0;
	private int64 mOldRaw = 0;
	private bool mRaw = false;
	private bool mHasOld = false;
	/// Where the edit lands (SettingsEditProfile), fixed when it first applies so an undo
	/// returns it to the same place.
	private Guid mProfile = .();
	private bool mRouted = false;

	/// CONSUMES `value`.
	public this(SceneEditContext ctx, Type settingsType, StringView property, Variant value)
	{
		mCtx = ctx;
		mSettingsType = settingsType;
		mProperty.Set(property);
		mNew = value;
	}

	public this(SceneEditContext ctx, Type settingsType, StringView property, int64 rawValue)
	{
		mCtx = ctx;
		mSettingsType = settingsType;
		mProperty.Set(property);
		mNewRaw = rawValue;
		mRaw = true;
	}

	public override bool Execute()
	{
		void* settings = ?;
		FieldInfo field = ?;
		if (!ResolveField(out settings, out field))
			return false;

		if (mRaw)
		{
			let address = RawFieldAccess.AddressOf(field, settings);
			if (!mHasOld)
			{
				mOldRaw = RawFieldAccess.ReadRawInt(address, field.FieldType.Size);
				mHasOld = true;
			}
			RawFieldAccess.WriteRawInt(address, field.FieldType.Size, mNewRaw);
			mCtx.NoteSettingsProfileEdited(mSettingsType, mProfile);
			return true;
		}

		if (!mHasOld)
		{
			if (!(RawFieldAccess.Read(field, settings, mSettingsType) case .Ok(let old)))
				return false;
			mOld = old;
			mHasOld = true;
		}
		let written = RawFieldAccess.Write(field, settings, mSettingsType, mNew) case .Ok;
		mCtx.NoteSettingsProfileEdited(mSettingsType, mProfile);
		return written;
	}

	public override void Undo()
	{
		void* settings = ?;
		FieldInfo field = ?;
		if (!ResolveField(out settings, out field))
			return;
		if (mRaw)
			RawFieldAccess.WriteRawInt(RawFieldAccess.AddressOf(field, settings),
				field.FieldType.Size, mOldRaw);
		else
			RawFieldAccess.Write(field, settings, mSettingsType, mOld).IgnoreError();
		mCtx.NoteSettingsProfileEdited(mSettingsType, mProfile);
	}

	public override StringView TypeId => "set_scene_setting";

	public override bool MergeInto(EditorCommand previous)
	{
		let prev = (SetSceneSettingCommand)previous;
		if ((prev.mSettingsType != mSettingsType) || (prev.mRaw != mRaw)
			|| (prev.mProfile != mProfile) || (prev.mProperty != mProperty))
			return false;
		prev.mNew.Dispose();
		prev.mNew = mNew;
		mNew = .();
		prev.mNewRaw = mNewRaw;
		return true;
	}

	private bool ResolveField(out void* settings, out FieldInfo field)
	{
		settings = null;
		field = ?;
		if (!mRouted)
		{
			mProfile = mCtx.SettingsEditProfile(mSettingsType, mProperty);
			mRouted = true;
		}
		settings = mCtx.SettingsEditTarget(mSettingsType, mProfile);
		if (settings == null)
			return false;
		if (!(RawFieldAccess.FindField(mSettingsType, mProperty) case .Ok(let found)))
			return false;
		field = found;
		return true;
	}
}
