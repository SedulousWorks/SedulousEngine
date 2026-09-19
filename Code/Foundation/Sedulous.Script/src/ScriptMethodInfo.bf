using System;
using System.Collections;

namespace Sedulous.Script;

/// One callable on a surface type: a method, or a constructor when IsConstructor.
class ScriptMethodInfo
{
	/// The Beef name.
	public String Name = new .() ~ delete _;
	/// The name a script uses. The Beef name unless [ScriptName] renamed it, which is how an
	/// overload set is told apart in a language without overloading.
	public String ScriptName = new .() ~ delete _;
	public String DisplayName = new .() ~ delete _;
	public String Description = new .() ~ delete _;
	public String ReturnTypeName = new .() ~ delete _;
	/// How the result crosses; Nil for void.
	public ScriptValueKind ReturnKind = .Nil;
	public bool IsStatic = false;
	public bool IsConstructor = false;
	public List<ScriptParamInfo> Params = new .() ~ DeleteContainerAndItems!(_);
	/// The emitted callable, null when the member could not be bound.
	public ScriptThunk Invoke = null;
	/// The entity-first rule: an instance method of the scene, a scene system or a manager
	/// whose first parameter is an entity is ALSO a method on the entity itself, the entity
	/// as Self and the rest as the arguments, so a script writes `other.GetName()` as well
	/// as `scene.GetEntityName(other)`. The name here is the entity side's, the Beef name
	/// with the word Entity dropped; empty when the rule does not apply.
	public String EntityName = new .() ~ delete _;
	/// The thunk for the entity side: Self is the entity, whose scene resolves the owner.
	public ScriptThunk EntityInvoke = null;
	/// Why it could not be bound: the type the frame cannot carry. Empty when it could.
	public String Unsupported = new .() ~ delete _;

	public bool IsCallable => Invoke != null;
	public bool OnEntity => (EntityInvoke != null) && !EntityName.IsEmpty;

	/// The arguments the entity side takes: the parameters after the entity.
	public Span<ScriptParamInfo> EntityParams => Params.IsEmpty ? default : Span<ScriptParamInfo>(Params.Ptr + 1, Params.Count - 1);
	public int RequiredEntityParams => Math.Max(RequiredParams - 1, 0);

	/// Adds a parameter. Chains, for the generated populate code.
	public ScriptMethodInfo Param(StringView name, StringView typeName, ScriptValueKind kind,
		bool byRef = false, bool hasDefault = false)
	{
		let p = new ScriptParamInfo();
		p.Name.Set(name);
		p.TypeName.Set(typeName);
		p.Kind = kind;
		p.IsByRef = byRef;
		p.HasDefault = hasDefault;
		Params.Add(p);
		return this;
	}

	public ScriptMethodInfo Returns(ScriptValueKind kind)
	{
		ReturnKind = kind;
		return this;
	}

	/// The arguments a call must supply: the parameters without a default.
	public int RequiredParams
	{
		get
		{
			int n = 0;
			for (let p in Params)
			{
				if (!p.HasDefault)
					n++;
			}
			return n;
		}
	}

	public ScriptMethodInfo Describe(StringView description)
	{
		Description.Set(description);
		return this;
	}

	public ScriptMethodInfo Display(StringView displayName)
	{
		DisplayName.Set(displayName);
		return this;
	}

	public ScriptMethodInfo Bind(ScriptThunk thunk)
	{
		Invoke = thunk;
		return this;
	}

	/// Marks the entity side: the name a script uses on the entity, and its thunk.
	public ScriptMethodInfo BindEntity(StringView entityName, ScriptThunk thunk)
	{
		EntityName.Set(entityName);
		EntityInvoke = thunk;
		return this;
	}

	public ScriptMethodInfo Blocked(StringView reason)
	{
		Unsupported.Set(reason);
		return this;
	}

	/// Renames for the script.
	public ScriptMethodInfo Named(StringView scriptName)
	{
		ScriptName.Set(scriptName);
		return this;
	}
}
