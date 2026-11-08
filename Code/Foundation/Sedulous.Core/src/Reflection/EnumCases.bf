using System;
using System.Collections;
using System.Reflection;

namespace Sedulous.Core;

/// The cases of an enum, by name and value, for the tools that name them (the inspector's
/// dropdown, entity_inspect, component_set, the scene schema), whether or not the enum is
/// reflected.
///
/// An enum without [Reflect] has no case names at run time: Enum.GetEnumerator finds nothing,
/// and a value reads as its number. A game's enum carries none unless someone writes it, so the
/// attributes that describe a type to the tools ([Behaviour], [Level], [Game] and
/// [SerializableComponent]) register, from compile time, the cases of every enum their type's
/// fields hold, alone or as a list's elements (AppendRegistration). The tools ask here, and an
/// enum nothing registered falls back to its reflection.
///
/// A registration runs in the registering type's static initialization, at startup, so the
/// cases are in before anything can ask: a scene schema or a game probe can ask about a type
/// no scene has a manager for yet. Static constructors run in an order nothing here controls,
/// so the table is made by the first registration rather than by a field initializer, which
/// would run in this class's own static constructor and might come after a registrant's and
/// reset it. Nothing registers after startup, so reading needs no lock.
static class EnumCases
{
	/// An enum's cases in declaration order. The names point INTO the string literals the
	/// registrations pass, which live as long as the process.
	private static Dictionary<Type, List<(StringView name, int64 value)>> sCases ~ DeleteDictionaryAndValues!(_);

	/// Records `enumType`'s cases from `cases`, "Name=value" entries separated by ';', unless
	/// they are recorded already (several types hold the same enum). `cases` must live as long
	/// as the process: the emitted registration passes a literal. Answers true, so the emitted
	/// static field can be initialized by it.
	public static bool Register(Type enumType, StringView cases)
	{
		if (enumType == null)
			return true;
		if (sCases == null)
			sCases = new .();
		if (sCases.ContainsKey(enumType))
			return true;
		let list = new List<(StringView name, int64 value)>();
		for (let entry in cases.Split(';', .RemoveEmptyEntries))
		{
			let equals = entry.IndexOf('=');
			if (equals <= 0)
				continue;
			if (int64.Parse(entry.Substring(equals + 1)) case .Ok(let caseValue))
				list.Add((entry.Substring(0, equals), caseValue));
		}
		sCases[enumType] = list;
		return true;
	}

	/// Whether `enumType`'s cases were registered, rather than coming from its reflection.
	public static bool IsRegistered(Type enumType) => (sCases != null) && (enumType != null) && sCases.ContainsKey(enumType);

	/// `enumType`'s cases: the registered ones, else what its reflection has (nothing for an
	/// enum that has none).
	public static CaseEnumerator Of(Type enumType) => .(enumType);

	/// The name of `enumType`'s case `caseValue`, appended; its number when no case has it.
	public static void NameOf(Type enumType, int64 caseValue, String outName)
	{
		for (let (name, data) in Of(enumType))
		{
			if (data == caseValue)
			{
				outName.Append(name);
				return;
			}
		}
		caseValue.ToString(outName);
	}

	public struct CaseEnumerator : IEnumerator<(StringView name, int64 value)>
	{
		private List<(StringView name, int64 value)> mRegistered;
		private int mIndex;
		private Enum.EnumEnumerator mReflected;

		public this(Type enumType)
		{
			mRegistered = null;
			mIndex = -1;
			mReflected = Enum.GetEnumerator(enumType);
			if ((sCases != null) && (enumType != null) && sCases.TryGetValue(enumType, let registered))
				mRegistered = registered;
		}

		public Result<(StringView name, int64 value)> GetNext() mut
		{
			if (mRegistered == null)
				return mReflected.GetNext();
			mIndex++;
			if (mIndex >= mRegistered.Count)
				return .Err;
			return mRegistered[mIndex];
		}
	}

	/// Appends to `body`, the type body an attribute emits for `type`, a static field whose
	/// initializer registers every enum the type's instance fields hold, alone or as a List's
	/// elements, base first; nothing when there is none. Each enum is registered by its full
	/// name, so a field inherited from a base registers only when it is public: a private one's
	/// type may be one this type cannot name. An enum with payload cases has no plain value per
	/// case and is left to its reflection.
	///
	/// The field is private and static, so a subclass that also registers declares its own.
	[Comptime]
	public static void AppendRegistration(Type type, String body)
	{
		let chain = scope List<Type>();
		for (var walk = type; (walk != null) && (walk != typeof(Object)); walk = walk.BaseType)
			chain.Add(walk);

		let enums = scope List<Type>();
		for (int i = chain.Count - 1; i >= 0; i--)
		{
			let declaring = chain[i];
			for (let field in declaring.GetFields())
			{
				if (!field.IsInstanceField || (field.DeclaringType != declaring))
					continue;
				if ((declaring != type) && !field.IsPublic)
					continue;
				var held = field.FieldType;
				if (let element = ListElement(held))
					held = element;
				if (IsPlainEnum(held) && !enums.Contains(held))
					enums.Add(held);
			}
		}
		if (enums.IsEmpty)
			return;

		body.Append("private static bool sEnumCasesRegistered = ");
		for (int i < enums.Count)
		{
			if (i > 0)
				body.Append("\n\t&& ");
			body.Append("Sedulous.Core.EnumCases.Register(typeof(");
			enums[i].GetFullName(body);
			body.Append("), \"");
			bool first = true;
			for (let c in enums[i].GetFields())
			{
				if (!c.IsEnumCase)
					continue;
				if (!first)
					body.Append(';');
				first = false;
				// A case's constant lives in the field's data slot, as Enum.GetValues reads it.
				body.AppendF("{}={}", c.Name, (int64)c.[Friend]mFieldData.mData);
			}
			body.Append("\")");
		}
		body.Append(";\n");
	}

	/// Whether `type` is an enum whose cases are plain values, none carrying a payload.
	[Comptime]
	private static bool IsPlainEnum(Type type)
	{
		if ((type == null) || !type.IsEnum)
			return false;
		for (let c in type.GetFields())
		{
			if (!c.IsEnumCase)
				continue;
			if (let caseType = c.FieldType as TypeInstance)
			{
				if (caseType.IsTuple && (caseType.FieldCount > 0))
					return false;
			}
		}
		return true;
	}

	/// A List<T>'s T; null for any other type.
	[Comptime]
	private static Type ListElement(Type type)
	{
		if (let generic = type as SpecializedGenericType)
		{
			if (generic.UnspecializedType == typeof(System.Collections.List<>))
				return generic.GetGenericArg(0);
		}
		return null;
	}
}
