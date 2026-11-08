using System;
using System.Collections;

namespace Sedulous.Script;

/// One type on a script surface: what it is, where it came from, which domain owns it, and
/// the members a script may touch.
class ScriptTypeInfo
{
	/// The Beef name with its namespace, `Sedulous.Core.Float3`. For a Global, the namespace.
	public String FullName = new .() ~ delete _;
	/// The bare name, which is what the script sees. Empty for a Global.
	public String Name = new .() ~ delete _;
	public String Namespace = new .() ~ delete _;
	/// The [TypeDomain], Runtime when unmarked.
	public String Domain = new .() ~ delete _;
	public ScriptTypeKind Kind = .Class;
	public ScriptTypeRole Role = .Plain;
	/// For a Component: the ComponentManager<T> that pools it, when the closure has one.
	public String ManagerTypeName = new .() ~ delete _;
	/// For a Component: the [SerializableComponent] type id, when it has one.
	public String ComponentTypeId = new .() ~ delete _;
	/// The plugin whose Engine part published it (ScriptSurface.AddPluginTypes); empty for the
	/// engine's.
	public String Plugin = new .() ~ delete _;
	public String DisplayName = new .() ~ delete _;
	public String Description = new .() ~ delete _;
	public String Category = new .() ~ delete _;
	/// True when the type was marked AllPublic: every public data member is on the surface.
	public bool AllPublic = false;
	/// The Beef type itself, for a backend that has to size, check or reflect it. Null for
	/// a Global.
	public Type BeefType = null;
	/// The instance size and alignment, for a struct a backend allocates inline.
	public int32 Size = 0;
	public int32 Align = 1;

	/// For a SceneSystem or ComponentManager: the callable that answers the scene's
	/// instance, Self being the scene. How a script reaches `scene.Physics`.
	public ScriptThunk FromScene = null;
	/// A component's: whether the entity in Self carries one, a Bool result. What a backend's
	/// `X.of(entity)` asks before it hands out a handle, so a missing component is null.
	public ScriptThunk IsOn = null;
	/// A component's: gives the entity in Self a default-made one when it has none, then
	/// answers, a Bool result, whether it has one. What a backend's `X.addTo(entity)` asks
	/// before it hands out a handle as `of` does; a gone entity or no manager is simply no.
	public ScriptThunk AddTo = null;
	/// A component's: takes the entity in Self's off, a Bool result saying whether it had one.
	/// What a backend's `X.removeFrom(entity)` answers.
	public ScriptThunk RemoveFrom = null;
	/// For a Weak type: the topmost weakly held base on the surface (the type itself when it
	/// has none), which a backend's `X::Of(node)` takes.
	public String WeakRootTypeName = new .() ~ delete _;
	/// A Weak type's: whether the handle in Self names one of this type, Self again as the
	/// result when it does and Nil when not, a gone handle included. Never a failure.
	public ScriptThunk Cast = null;

	public List<ScriptFieldInfo> Fields = new .() ~ DeleteContainerAndItems!(_);
	public List<ScriptMethodInfo> Methods = new .() ~ DeleteContainerAndItems!(_);
	public List<ScriptEnumValueInfo> EnumValues = new .() ~ DeleteContainerAndItems!(_);

	public ScriptFieldInfo AddField(StringView name, StringView typeName, bool isStatic = false,
		bool isProperty = false)
	{
		let f = new ScriptFieldInfo();
		f.Name.Set(name);
		f.ScriptName.Set(name);
		f.TypeName.Set(typeName);
		f.IsStatic = isStatic;
		f.IsProperty = isProperty;
		Fields.Add(f);
		return f;
	}

	public ScriptMethodInfo AddMethod(StringView name, StringView returnTypeName,
		bool isStatic = false)
	{
		let m = new ScriptMethodInfo();
		m.Name.Set(name);
		m.ScriptName.Set(name);
		m.ReturnTypeName.Set(returnTypeName);
		m.IsStatic = isStatic;
		Methods.Add(m);
		return m;
	}

	public ScriptMethodInfo AddConstructor()
	{
		let m = AddMethod("this", FullName, false);
		m.IsConstructor = true;
		return m;
	}

	public ScriptEnumValueInfo AddEnumValue(StringView name, int64 value)
	{
		let v = new ScriptEnumValueInfo();
		v.Name.Set(name);
		v.Value = value;
		EnumValues.Add(v);
		return v;
	}

	public ScriptTypeInfo Describe(StringView description)
	{
		Description.Set(description);
		return this;
	}

	/// The name a script uses, where the Beef one will not do: [ScriptName] on the type.
	public ScriptTypeInfo Named(StringView scriptName)
	{
		Name.Set(scriptName);
		return this;
	}

	public ScriptTypeInfo Display(StringView displayName)
	{
		DisplayName.Set(displayName);
		return this;
	}

	public ScriptTypeInfo Categorised(StringView category)
	{
		Category.Set(category);
		return this;
	}

	public ScriptTypeInfo As(ScriptTypeRole role, StringView managerTypeName = "",
		StringView componentTypeId = "")
	{
		Role = role;
		ManagerTypeName.Set(managerTypeName);
		ComponentTypeId.Set(componentTypeId);
		return this;
	}

	public ScriptTypeInfo Typed(Type type, int32 size, int32 align)
	{
		BeefType = type;
		Size = size;
		Align = align;
		return this;
	}

	public ScriptTypeInfo ResolvedBy(ScriptThunk fromScene)
	{
		FromScene = fromScene;
		return this;
	}

	public ScriptTypeInfo PresentBy(ScriptThunk isOn)
	{
		IsOn = isOn;
		return this;
	}

	public ScriptTypeInfo AddedBy(ScriptThunk addTo)
	{
		AddTo = addTo;
		return this;
	}

	public ScriptTypeInfo RemovedBy(ScriptThunk removeFrom)
	{
		RemoveFrom = removeFrom;
		return this;
	}

	public ScriptTypeInfo WeakRoot(StringView rootTypeName)
	{
		WeakRootTypeName.Set(rootTypeName);
		return this;
	}

	public ScriptTypeInfo CastBy(ScriptThunk cast)
	{
		Cast = cast;
		return this;
	}

	public ScriptTypeInfo Everything()
	{
		AllPublic = true;
		return this;
	}
}
