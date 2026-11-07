using System;

namespace Sedulous.Engine.Gameplay;

/// Marks a Level subclass, states its settings block's id on disk, and generates the block's
/// identity and SerializeSettings.
///
/// The id is stated rather than derived from the class name, as a behaviour's is: a rename must
/// not orphan the block every scene saved under the old one. DataVersion and
/// MinReadDataVersion are the block's SettingsDataVersion and SettingsMinReadDataVersion: a
/// block stamped with another version is REFUSED, unless a legacy reader accepts it.
///
/// The generated SerializeSettings walks the PUBLIC instance fields, base first, in declaration
/// order, with the walk [Serializable] uses (its keys, [NotSerialized], [Appended]): Level's
/// Active leads, and a private field is runtime state, neither saved nor shown. FIELD ORDER IS
/// THE BINARY FORMAT.
///
/// It also asks for what the tools need: the type and its instance fields reflected (the
/// inspector and the MCP tools read them), its default constructor reflected (the inspector's
/// defaults), and the type always included, so a class nothing else names still links.
///
/// DisplayName, Category and Description go beside it: the DisplayName titles its section in
/// the scene's settings.
[AttributeUsage(.Class, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple,
	ReflectUser = .Type | .NonStaticFields | .DefaultConstructor, AlwaysIncludeUser = .Type | .AssumeInstantiated)]
struct LevelAttribute : Attribute, IComptimeTypeApply
{
	public String LevelId;
	/// Bumped when the stored shape changes; see SceneSystem.SettingsDataVersion.
	public uint32 DataVersion;
	/// The oldest stored version a legacy reader still accepts, nought meaning the current
	/// one alone.
	public uint32 MinReadDataVersion;

	public this(String levelId, uint32 dataVersion = 1, uint32 minReadDataVersion = 0)
	{
		LevelId = levelId;
		DataVersion = dataVersion;
		MinReadDataVersion = minReadDataVersion;
	}

	[Comptime]
	public void ApplyToType(Type type)
	{
		Runtime.Assert(DerivesFromLevel(type), "[Level] marks a class derived from Level");

		// Only the fields: the scene's settings record brackets them with the block's id and
		// version envelope, and the "settings" object, as it does every system's.
		let body = scope String();
		body.Append("public override System.StringView SettingsId => \"");
		body.Append(LevelId);
		body.Append("\";\n");
		body.Append("public override uint32 SettingsDataVersion => ");
		DataVersion.ToString(body);
		body.Append(";\n");
		body.Append("public override uint32 SettingsMinReadDataVersion => ");
		MinReadDataVersion.ToString(body);
		body.Append(";\n");
		body.Append("public override void SerializeSettings(Sedulous.Core.Serialization.ISerializer ar)\n{\n");
		Sedulous.Core.Serialization.SerializableAttribute.AppendFieldMoves(type, body, true);
		body.Append("}\n");
		Compiler.EmitTypeBody(type, body);
	}

	[Comptime]
	private static bool DerivesFromLevel(Type type)
	{
		for (var walk = type.BaseType; walk != null; walk = walk.BaseType)
		{
			if (walk == typeof(Level))
				return true;
		}
		return false;
	}
}
