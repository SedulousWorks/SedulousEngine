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

	/// The bool setting named `name` (its field's name), for a caller that reads or flips it (the
	/// import window's kind rows); null when the options have no bool setting of that name.
	public bool* FindBoolSetting(StringView name)
	{
		for (let setting in GetSettings(.. scope .()))
		{
			if ((setting.Name == name) && (setting.FieldType == typeof(bool)))
				return (bool*)((uint8*)Internal.UnsafeCastToPtr(this) + setting.MemberOffset);
		}
		return null;
	}

	/// The settings as text, a line each, "Name=value", appended: a flag true or false, a number, a
	/// choice by its case's name. An import records them beside what it made
	/// (ImportPaths.RecordImportSettings), so a reimport starts from them.
	public void SettingsText(String outText)
	{
		let self = (uint8*)Internal.UnsafeCastToPtr(this);
		let value = scope String();
		for (let setting in GetSettings(.. scope .()))
		{
			let address = self + setting.MemberOffset;
			let type = setting.FieldType;
			value.Clear();
			if (type == typeof(bool))
				value.Append(*(bool*)address ? "true" : "false");
			else if (type == typeof(float))
				(*(float*)address).ToString(value);
			else if (type.IsEnum)
			{
				let raw = ReadInteger(address, type.Size);
				for (var (caseName, data) in Enum.GetEnumerator(type))
				{
					if (data == raw)
					{
						value.Append(caseName);
						break;
					}
				}
				if (value.IsEmpty)
					continue; // a value no case names
			}
			else
				continue; // not a kind a setting is yet
			outText.AppendF("{}={}\n", setting.Name, value);
		}
	}

	/// Takes settings from SettingsText's text. A line naming no setting, or a value that does not
	/// read, is skipped: what an older import recorded still applies as far as it goes.
	public void ReadSettingsText(StringView text)
	{
		let self = (uint8*)Internal.UnsafeCastToPtr(this);
		let settings = GetSettings(.. scope .());
		for (let line in text.Split('\n'))
		{
			let eq = line.IndexOf('=');
			if (eq <= 0)
				continue;
			let name = line.Substring(0, eq);
			let value = line.Substring(eq + 1);
			FieldInfo setting = default;
			bool found = false;
			for (let candidate in settings)
			{
				if (candidate.Name == name)
				{
					setting = candidate;
					found = true;
					break;
				}
			}
			if (!found)
				continue;
			let address = self + setting.MemberOffset;
			let type = setting.FieldType;
			if (type == typeof(bool))
			{
				if ((value == "true") || (value == "false"))
					*(bool*)address = value == "true";
			}
			else if (type == typeof(float))
			{
				if (float.Parse(value) case .Ok(let number))
					*(float*)address = number;
			}
			else if (type.IsEnum)
			{
				for (var (caseName, data) in Enum.GetEnumerator(type))
				{
					if (caseName == value)
					{
						WriteInteger(address, type.Size, data);
						break;
					}
				}
			}
		}
	}

	/// The integer stored at `address`, sized by its type (an enum's).
	private static int64 ReadInteger(void* address, int size)
	{
		switch (size)
		{
		case 1: return *(uint8*)address;
		case 2: return *(uint16*)address;
		case 8: return *(int64*)address;
		default: return *(int32*)address;
		}
	}

	private static void WriteInteger(void* address, int size, int64 value)
	{
		switch (size)
		{
		case 1: *(uint8*)address = (uint8)value;
		case 2: *(uint16*)address = (uint16)value;
		case 8: *(int64*)address = value;
		default: *(int32*)address = (int32)value;
		}
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
