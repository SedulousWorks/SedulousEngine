using System;

namespace Sedulous.Engine.Gameplay;

/// Marks a Behaviour subclass, states its identity on disk, and generates its Serialize.
///
/// The id is stated rather than derived from the class name, as a component's is: a rename
/// must not orphan every record saved under the old name. DataVersion and MinReadDataVersion
/// mean what they mean on [SerializableComponent]: a payload stamped with another version is
/// REFUSED, unless a legacy reader accepts it (MinReadDataVersion, with the fields added since
/// marked [Appended(version)]).
///
/// The generated Serialize walks the PUBLIC instance fields, base first, in declaration order,
/// with the same walk [Serializable] uses (its keys, [NotSerialized], [Appended]): a private
/// field is runtime state, neither saved nor shown. FIELD ORDER IS THE BINARY FORMAT.
///
/// It also asks for what the tools need: the type and its instance fields reflected (the
/// inspector, the MCP tools and the prefab EntityRef remap read them), its default constructor
/// reflected (defaults, Add Component), and the type always included, so a class nothing else
/// names still links. The enums its fields hold are registered with EnumCases, so the tools name
/// their cases without the enum being reflected.
///
/// It refuses, as a compile error naming the field, a [Replicated] field of a kind the wire
/// does not carry (BehaviourReplication.KindOf): an entity or asset reference, a list, a class.
///
/// DisplayName, Category and Description go beside it, as on a component.
[AttributeUsage(.Class, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple,
	ReflectUser = .Type | .NonStaticFields | .DefaultConstructor, AlwaysIncludeUser = .Type | .AssumeInstantiated)]
struct BehaviourAttribute : Attribute, IComptimeTypeApply
{
	public String TypeId;
	/// Bumped when the stored shape changes; see [SerializableComponent].
	public uint32 DataVersion;
	/// The oldest stored version a legacy reader still accepts, nought meaning the current
	/// one alone.
	public uint32 MinReadDataVersion;

	public this(String typeId, uint32 dataVersion = 1, uint32 minReadDataVersion = 0)
	{
		TypeId = typeId;
		DataVersion = dataVersion;
		MinReadDataVersion = minReadDataVersion;
	}

	[Comptime]
	public void ApplyToType(Type type)
	{
		Runtime.Assert(DerivesFromBehaviour(type), "[Behaviour] marks a class derived from Behaviour");
		// Here rather than when it is registered: a class nothing registers still fails to build.
		BehaviourReplication.RefuseUnsupported(type);

		// Only the fields. The record's version envelope is the manager's, as a component's
		// is SerializableComponentManager's, and a component record's fields sit directly in
		// it: no object of their own.
		let body = scope String();
		body.Append("public override void Serialize(Sedulous.Core.Serialization.ISerializer ar)\n{\n");
		Sedulous.Core.Serialization.SerializableAttribute.AppendFieldMoves(type, body, true);
		body.Append("}\n");
		Sedulous.Core.EnumCases.AppendRegistration(type, body);
		Compiler.EmitTypeBody(type, body);
	}

	[Comptime]
	private static bool DerivesFromBehaviour(Type type)
	{
		for (var walk = type.BaseType; walk != null; walk = walk.BaseType)
		{
			if (walk == typeof(Behaviour))
				return true;
		}
		return false;
	}
}
