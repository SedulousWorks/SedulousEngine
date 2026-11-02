using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Pipeline.Importer;

/// Importer specific options, shown by the import window before the import runs.
///
/// A subclass declares its settings as reflected fields ([Reflect(.NonStaticFields)]), each
/// labelled by its [DisplayName] and explained by its [Description], as an asset's properties
/// are: the import window draws them with the inspector's property editors ([VisibleWhen] showing
/// one only while another holds), and an agent sets them by label (asset_import's `options`). The
/// base declares none: no settings and no plan means no window, and the import runs on the drop.
[Reflect(.NonStaticFields)]
class ImportOptions : ISerializable
{
	/// The review dialog's per resource decisions, being an edited copy of what DescribeImport
	/// returned.
	///
	/// Empty means import everything under its default name. An importer that supports review
	/// consults this at each creation site through the two accessors below; one that does not
	/// ignores it entirely.
	[Hidden]
	public ImportPlan Selection = new .() ~ delete _;

	/// The settings these options declare, appended: the shown fields (public, instance, not
	/// [Hidden]) of their type and its bases, a base's before its subclass's, each in declaration
	/// order.
	public void GetSettings(List<FieldInfo> outSettings)
	{
		let chain = scope List<Type>();
		for (Type t = GetType(); (t != null) && (t != typeof(Object)); t = t.BaseType)
			chain.Insert(0, t);
		for (let t in chain)
		{
			for (let field in t.GetFields())
			{
				if (field.IsPublic && !field.IsStatic && !field.HasCustomAttribute<HiddenAttribute>())
					outSettings.Add(field);
			}
		}
	}

	/// Whether these options declare any setting (a window shows them).
	public bool HasSettings => !GetSettings(.. scope .()).IsEmpty;

	/// What a setting is called, appended: its [DisplayName], else its name.
	public static void SettingLabel(FieldInfo setting, String outLabel)
	{
		if (setting.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let named))
			outLabel.Append(named.Name);
		else
			outLabel.Append(setting.Name);
	}

	/// The setting labelled `label`, case and spaces ignored ("generate collision" finds "Generate
	/// collision"); false when there is none.
	public bool FindSetting(StringView label, out FieldInfo outSetting)
	{
		outSetting = default;
		let wanted = Squeeze(label, .. scope .());
		let settings = GetSettings(.. scope .());
		let name = scope String();
		for (let setting in settings)
		{
			name.Clear();
			SettingLabel(setting, name);
			if (Squeeze(name, .. scope .()) == wanted)
			{
				outSetting = setting;
				return true;
			}
		}
		return false;
	}

	/// Takes `other`'s settings when it is the same type of options (the import window's "Use these
	/// for every ..."); false, changing nothing, when it is not. The plan's choices stay. A setting is
	/// a value (a bool, a number, a choice) copied as it is; one held by reference is left alone.
	public bool CopySettingsFrom(ImportOptions other)
	{
		if (other === this)
			return true;
		if ((other == null) || (other.GetType() != GetType()))
			return false;
		let from = (uint8*)Internal.UnsafeCastToPtr(other);
		let to = (uint8*)Internal.UnsafeCastToPtr(this);
		for (let setting in GetSettings(.. scope .()))
		{
			let type = setting.FieldType;
			if (!type.IsObject)
				Internal.MemCpy(to + setting.MemberOffset, from + setting.MemberOffset, type.Size);
		}
		return true;
	}

	/// `text` lower cased without its spaces, appended.
	private static void Squeeze(StringView text, String outText)
	{
		for (let c in text.RawChars)
		{
			if (c != ' ')
				outText.Append(c.ToLower);
		}
	}

	public virtual void Serialize(ISerializer ar)
	{
	}

	/// Whether the resource is checked. An UNMENTIONED resource is enabled: a selection that
	/// does not name something has no opinion about it, which is not the same as excluding it.
	public bool SelectionEnabled(ImportResourceKind kind, StringView sourceName)
	{
		let entry = Selection.Find(kind, sourceName);
		return (entry == null) || entry.Enabled;
	}

	/// The user's target name for the resource, falling back to the importer's base name.
	public StringView SelectionName(ImportResourceKind kind, StringView sourceName)
	{
		let entry = Selection.Find(kind, sourceName);
		return ((entry != null) && !entry.TargetName.IsEmpty) ? entry.TargetName : sourceName;
	}
}
