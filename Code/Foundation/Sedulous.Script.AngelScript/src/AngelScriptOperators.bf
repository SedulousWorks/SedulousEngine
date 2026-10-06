using System;
using System.Collections;
using AngelScript;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;

namespace Sedulous.Script.AngelScript;

/// The value type an operator binding works on.
enum AngelScriptOperatorType
{
	Float2,
	Float3,
	Float4,
	Quaternion,
	Color,
	Guid,
	/// A script entity: its handle and its scene.
	Entity
}

/// Which operator a binding is: the arithmetic, the equality, and the compound assignments.
enum AngelScriptOperator
{
	Neg,
	Add,
	Sub,
	/// Value by value: component-wise for a vector, composition for a quaternion.
	Mul,
	/// Value times a float.
	MulScalar,
	/// A float times the value, `2.0f * v`.
	MulScalarReversed,
	DivScalar,
	/// Component-wise.
	Div,
	Equals,
	AddAssign,
	SubAssign,
	MulScalarAssign,
	DivScalarAssign,
	/// The default constructor of a value with no surface constructor: `Guid()` is nil and
	/// `Entity()` no entity. Without one a temporary `Guid()` has no object behind it, and a
	/// method called on it (`Guid() == id`) reads a null pointer.
	Construct
}

/// The operators on the inline values: `a + b`, `v * 2.0f`, `-v`, `q * r`, `a == b`,
/// `p += v`, and equality on a Guid and an entity (`hit.Entity == self`). Exactly the operators the Beef types define, each computed by the Beef operator
/// itself, so a script's arithmetic is the engine's (a quaternion product composes in the same
/// order). Declared with the value types, so every surface has them.
extension AngelScriptRuntime
{
	/// What script_api lists for the operators, replayed after Bind clears the listing.
	private class OperatorApi
	{
		public String TypeName = new .() ~ delete _;
		public String FullName = new .() ~ delete _;
		public String Name = new .() ~ delete _;
		public String Signature = new .() ~ delete _;
	}

	private List<OperatorApi> mOperatorApi = new .() ~ DeleteContainerAndItems!(_);

	private void DeclareOperators()
	{
		// The vectors: what Float2 and Float3 define, Float4 a subset.
		for (let type in AngelScriptOperatorType[3](.Float2, .Float3, .Float4))
		{
			let n = TypeNameOf(type);
			Operator(type, .Neg, scope $"{n} opNeg() const", "-a");
			Operator(type, .Add, scope $"{n} opAdd(const {n} &in) const", "a + b");
			Operator(type, .Sub, scope $"{n} opSub(const {n} &in) const", "a - b");
			Operator(type, .MulScalar, scope $"{n} opMul(float) const", "a * s");
			Operator(type, .MulScalarReversed, scope $"{n} opMul_r(float) const", "s * a");
			Operator(type, .Equals, scope $"bool opEquals(const {n} &in) const", "a == b, a != b");
			Operator(type, .AddAssign, scope $"{n} &opAddAssign(const {n} &in)", "a += b");
			Operator(type, .SubAssign, scope $"{n} &opSubAssign(const {n} &in)", "a -= b");
			Operator(type, .MulScalarAssign, scope $"{n} &opMulAssign(float)", "a *= s");
			if (type != .Float4)
			{
				Operator(type, .Mul, scope $"{n} opMul(const {n} &in) const", "a * b, component-wise");
				Operator(type, .DivScalar, scope $"{n} opDiv(float) const", "a / s");
				Operator(type, .DivScalarAssign, scope $"{n} &opDivAssign(float)", "a /= s");
			}
		}
		Operator(.Float3, .Div, "Float3 opDiv(const Float3 &in) const", "a / b, component-wise");
		Operator(.Quaternion, .Mul, "Quaternion opMul(const Quaternion &in) const", "a * b, the rotations composed");
		Operator(.Color, .Add, "Color opAdd(const Color &in) const", "a + b");
		Operator(.Color, .MulScalar, "Color opMul(float) const", "c * s");
		Operator(.Color, .Equals, "bool opEquals(const Color &in) const", "a == b, a != b");
		Constructor(.Guid);
		Operator(.Guid, .Equals, "bool opEquals(const Guid &in) const", "a == b, a != b");
		// The same entity of the same scene: its handle's index and generation, and its scene.
		Constructor(.Entity);
		Operator(.Entity, .Equals, "bool opEquals(const Entity &in) const", "a == b, a != b");
	}

	private void Constructor(AngelScriptOperatorType type)
	{
		let b = new AngelScriptBinding();
		b.Kind = .Operator;
		b.OperatorType = type;
		b.Operator = .Construct;
		mBindings.Add(b);
		let typeName = TypeNameOf(type);
		Check(AS.asc_engine_register_object_behaviour(mEngine, scope String(typeName).CStr(), AS.asBEHAVE_CONSTRUCT, "void f()", Internal.UnsafeCastToPtr(b)), scope $"{typeName} void f()");
	}

	private static StringView TypeNameOf(AngelScriptOperatorType type)
	{
		switch (type)
		{
		case .Float2: return "Float2";
		case .Float3: return "Float3";
		case .Float4: return "Float4";
		case .Quaternion: return "Quaternion";
		case .Color: return "Color";
		case .Guid: return "Guid";
		case .Entity: return "Entity";
		}
	}

	private static void FullNameOf(AngelScriptOperatorType type, String outName)
	{
		switch (type)
		{
		case .Float2: typeof(Float2).GetFullName(outName);
		case .Float3: typeof(Float3).GetFullName(outName);
		case .Float4: typeof(Float4).GetFullName(outName);
		case .Quaternion: typeof(Quaternion).GetFullName(outName);
		case .Color: typeof(Color).GetFullName(outName);
		case .Guid: typeof(Guid).GetFullName(outName);
		case .Entity: typeof(EntityHandle).GetFullName(outName);
		}
	}

	private void Operator(AngelScriptOperatorType type, AngelScriptOperator op, StringView declaration, StringView reads)
	{
		let b = new AngelScriptBinding();
		b.Kind = .Operator;
		b.OperatorType = type;
		b.Operator = op;
		mBindings.Add(b);
		let typeName = TypeNameOf(type);
		if (!Check(AS.asc_engine_register_object_method(mEngine, scope String(typeName).CStr(), scope String(declaration).CStr(), Internal.UnsafeCastToPtr(b)), scope $"{typeName} {declaration}"))
			return;
		let api = new OperatorApi();
		api.TypeName.Set(typeName);
		FullNameOf(type, api.FullName);
		let open = declaration.IndexOf(' ');
		let paren = declaration.IndexOf('(');
		api.Name.Set(declaration.Substring(open + 1, paren - open - 1));
		api.Name.TrimStart('&'); // a compound assignment returns a reference: `Float3 &opAddAssign`
		api.Signature.AppendF("{}  // {}", declaration, reads);
		mOperatorApi.Add(api);
	}

	/// The operator members in the listing, after Bind cleared it: on the types the surface
	/// declares, since the listing names the surface's types (a surface without Float2 lists
	/// no Float2, though the language still has it).
	private void RecordOperators(ScriptSurface surface)
	{
		for (let api in mOperatorApi)
		{
			if (surface.Find(api.FullName) != null)
				Record(ApiType(api.TypeName, api.FullName, false), api.Name, api.Signature, false, .Method);
		}
	}

	private static void ReturnValue<T>(AS.Generic* gen, T value)
	{
		var copy = value;
		AS.asc_generic_set_return_object(gen, &copy);
	}

	private static void ReturnBool(AS.Generic* gen, bool value) => AS.asc_generic_set_return_byte(gen, value ? 1 : 0);

	private static T* Arg<T>(AS.Generic* gen) => (T*)AS.asc_generic_get_arg_address(gen, 0);

	private static float Scalar(AS.Generic* gen) => AS.asc_generic_get_arg_float(gen, 0);

	private void DispatchOperator(AS.Generic* gen, AngelScriptBinding b)
	{
		let self = AS.asc_generic_get_object(gen);
		switch (b.OperatorType)
		{
		case .Float2:
			let v = (Float2*)self;
			switch (b.Operator)
			{
			case .Neg: ReturnValue(gen, -*v);
			case .Add: ReturnValue(gen, *v + *Arg<Float2>(gen));
			case .Sub: ReturnValue(gen, *v - *Arg<Float2>(gen));
			case .Mul: ReturnValue(gen, *v * *Arg<Float2>(gen));
			case .MulScalar: ReturnValue(gen, *v * Scalar(gen));
			case .MulScalarReversed: ReturnValue(gen, Scalar(gen) * *v);
			case .DivScalar: ReturnValue(gen, *v / Scalar(gen));
			case .Equals: ReturnBool(gen, *v == *Arg<Float2>(gen));
			case .AddAssign: *v += *Arg<Float2>(gen); AS.asc_generic_set_return_address(gen, v);
			case .SubAssign: *v -= *Arg<Float2>(gen); AS.asc_generic_set_return_address(gen, v);
			case .MulScalarAssign: *v *= Scalar(gen); AS.asc_generic_set_return_address(gen, v);
			case .DivScalarAssign: *v /= Scalar(gen); AS.asc_generic_set_return_address(gen, v);
			default:
			}
		case .Float3:
			let v = (Float3*)self;
			switch (b.Operator)
			{
			case .Neg: ReturnValue(gen, -*v);
			case .Add: ReturnValue(gen, *v + *Arg<Float3>(gen));
			case .Sub: ReturnValue(gen, *v - *Arg<Float3>(gen));
			case .Mul: ReturnValue(gen, *v * *Arg<Float3>(gen));
			case .Div: ReturnValue(gen, *v / *Arg<Float3>(gen));
			case .MulScalar: ReturnValue(gen, *v * Scalar(gen));
			case .MulScalarReversed: ReturnValue(gen, Scalar(gen) * *v);
			case .DivScalar: ReturnValue(gen, *v / Scalar(gen));
			case .Equals: ReturnBool(gen, *v == *Arg<Float3>(gen));
			case .AddAssign: *v += *Arg<Float3>(gen); AS.asc_generic_set_return_address(gen, v);
			case .SubAssign: *v -= *Arg<Float3>(gen); AS.asc_generic_set_return_address(gen, v);
			case .MulScalarAssign: *v *= Scalar(gen); AS.asc_generic_set_return_address(gen, v);
			case .DivScalarAssign: *v /= Scalar(gen); AS.asc_generic_set_return_address(gen, v);
			default:
			}
		case .Float4:
			let v = (Float4*)self;
			switch (b.Operator)
			{
			case .Neg: ReturnValue(gen, -*v);
			case .Add: ReturnValue(gen, *v + *Arg<Float4>(gen));
			case .Sub: ReturnValue(gen, *v - *Arg<Float4>(gen));
			case .MulScalar: ReturnValue(gen, *v * Scalar(gen));
			case .MulScalarReversed: ReturnValue(gen, Scalar(gen) * *v);
			case .Equals: ReturnBool(gen, *v == *Arg<Float4>(gen));
			case .AddAssign: *v += *Arg<Float4>(gen); AS.asc_generic_set_return_address(gen, v);
			case .SubAssign: *v -= *Arg<Float4>(gen); AS.asc_generic_set_return_address(gen, v);
			case .MulScalarAssign: *v *= Scalar(gen); AS.asc_generic_set_return_address(gen, v);
			default:
			}
		case .Quaternion:
			if (b.Operator == .Mul)
				ReturnValue(gen, *(Quaternion*)self * *Arg<Quaternion>(gen));
		case .Color:
			let c = (Color*)self;
			switch (b.Operator)
			{
			case .Add: ReturnValue(gen, *c + *Arg<Color>(gen));
			case .MulScalar: ReturnValue(gen, *c * Scalar(gen));
			case .Equals: ReturnBool(gen, *c == *Arg<Color>(gen));
			default:
			}
		case .Guid:
			if (b.Operator == .Construct)
				*(Guid*)self = .();
			else if (b.Operator == .Equals)
				ReturnBool(gen, *(Guid*)self == *Arg<Guid>(gen));
		case .Entity:
			if (b.Operator == .Construct)
				*(ScriptEntity*)self = .(.Invalid, null);
			else if (b.Operator == .Equals)
			{
				let a = (ScriptEntity*)self;
				let other = Arg<ScriptEntity>(gen);
				ReturnBool(gen, (a.Handle == other.Handle) && (a.Scene === other.Scene));
			}
		}
	}
}
