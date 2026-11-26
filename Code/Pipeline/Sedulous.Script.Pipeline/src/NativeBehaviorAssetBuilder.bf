using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;
using Sedulous.Script.Resource;

namespace Sedulous.Script.Pipeline;

/// Cooks a Native Behavior asset: the class's declaration, read from its reflection as a script's
/// cook reads source. Its kind comes from its base chain, its handlers from its methods named
/// `On<Name>`, and its properties from the fields it marks BehaviorProperty, their defaults read
/// from an object of it. A marked field of a type no property holds fails the cook, naming it.
class NativeBehaviorAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(NativeBehaviorAsset);
	public Type ProductType => typeof(BehaviorClassSource);
	public int32 Version => 1;
	/// A class rebuilt with a property more recooks its asset.
	public uint64 EnvironmentHash => NativeBehaviorHarvest.DeclarationsHash();

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);
		let native = (NativeBehaviorAsset)asset;
		let type = NativeBehaviorTypes.FindClass(native.ClassName);
		if (type == null)
		{
			GlobalLog(.Error, "Cook: native class '{}' is not built in (is its plugin enabled and built?)", native.ClassName);
			return .Err(.NotFound);
		}
		let record = scope BehaviorClassSource();
		let why = scope String();
		if (!NativeBehaviorHarvest.Harvest(type, record, why))
		{
			GlobalLog(.Error, "Cook: native class '{}': {}", native.ClassName, why);
			return .Err(.InvalidArgument);
		}
		return context.Output.WriteObject(record);
	}
}

/// What a native class declares, read from its reflection.
static class NativeBehaviorHarvest
{
	/// The type names an entity property is held in.
	const String cEntityHandle = "Sedulous.Scene.EntityHandle";

	/// Fills `outRecord` with what `type` declares: its language, full name, kind, handlers and
	/// properties with their defaults. False, with `outWhy`, when it is no native class, cannot be
	/// made, or marks a field of a type no property holds.
	public static bool Harvest(Type type, BehaviorClassSource outRecord, String outWhy)
	{
		let name = type.GetName(.. scope .());
		outRecord.Kind = NativeBehaviorTypes.KindOf(type);
		if (outRecord.Kind == .None)
		{
			outWhy.AppendF("'{}' derives from none of RunBehavior, SceneBehavior and EntityBehavior", name);
			return false;
		}
		Object made;
		switch (type.CreateObject())
		{
		case .Ok(let object): made = object;
		case .Err:
			outWhy.AppendF("'{}' cannot be made (does it have a constructor taking nothing?)", name);
			return false;
		}
		defer delete made;

		outRecord.Language.Set(NativeBehaviorTypes.cLanguage);
		type.GetFullName(outRecord.ClassName..Clear());
		outRecord.SourceName.Set(name);
		// The class's own declarations after its bases', as a script's derive.
		let chain = scope List<Type>();
		for (var t = type; t != null; t = t.BaseType)
			chain.Insert(0, t);
		for (let t in chain)
		{
			for (let field in t.GetFields(.Instance | .Public | .NonPublic | .DeclaredOnly))
			{
				if (!(field.GetCustomAttribute<BehaviorPropertyAttribute>() case .Ok(let marked)))
					continue;
				let kind = PropertyTypeOf(field.FieldType, marked);
				if (kind == .None)
				{
					outWhy.AppendF("'{}' marks '{}' a property, but its type is none a property holds (a number, a bool, a String, a Color, a Float3, an EntityHandle, or an asset's Guid with AssetType)", name, field.Name);
					return false;
				}
				let property = new BehaviorProperty();
				NativeBehaviorTypes.ScriptName(field.Name, property.Name);
				property.Hash = ScriptPropertyNames.HashOf(property.Name);
				property.Type = kind;
				property.AssetType.Set(marked.AssetType);
				if (field.GetCustomAttribute<DescriptionAttribute>() case .Ok(let described))
					property.Description.Set(described.Text);
				property.Replicated = marked.Replicated;
				property.Default = DefaultOf(field, kind, made);
				outRecord.Properties.Add(property);
			}
			for (let method in t.GetMethods(.Instance | .Public | .NonPublic | .DeclaredOnly))
			{
				if (NativeBehaviorTypes.IsHandlerName(method.Name))
					outRecord.Handlers.Add(NativeBehaviorTypes.ScriptName(method.Name, .. new .()));
			}
		}
		return true;
	}

	/// The property type a field of `type` is; None for one a property cannot hold.
	public static BehaviorPropertyType PropertyTypeOf(Type type, BehaviorPropertyAttribute marked)
	{
		if ((type == typeof(float)) || (type == typeof(double)))
			return .Float;
		if ((type == typeof(int32)) || (type == typeof(int64)) || (type == typeof(int)) || (type == typeof(uint32)))
			return .Int;
		if (type == typeof(bool))
			return .Bool;
		if (type == typeof(String))
			return .String;
		if (type == typeof(Color))
			return .Color;
		if (type == typeof(Float3))
			return .Vec3;
		if (type.GetFullName(.. scope .()) == cEntityHandle)
			return .Entity;
		if ((type == typeof(Guid)) && !String.IsNullOrEmpty(marked.AssetType))
			return .Asset;
		return .None;
	}

	/// The value `field` holds on `instance`, as a property's default (its text owned by it). An
	/// entity's default is none: an entity is in no scene at the cook.
	static BehaviorPropertyValue DefaultOf(FieldInfo field, BehaviorPropertyType kind, Object instance)
	{
		var value = BehaviorPropertyValue();
		value.Kind = kind;
		if (kind == .String)
		{
			String text = null;
			if (field.GetValue<String>(instance) case .Ok(let held))
				text = held;
			value.Text = new String((text != null) ? text : "");
			return value;
		}
		if (kind == .Entity)
			return value;
		switch (field.GetValueReference(instance))
		{
		case .Ok(var reference):
			defer reference.Dispose();
			let data = reference.DataPtr;
			let type = field.FieldType;
			if (type == typeof(float))
				value.Number = *(float*)data;
			else if (type == typeof(double))
				value.Number = *(double*)data;
			else if (type == typeof(int32))
				value.Number = *(int32*)data;
			else if (type == typeof(int64))
				value.Number = *(int64*)data;
			else if (type == typeof(int))
				value.Number = *(int*)data;
			else if (type == typeof(uint32))
				value.Number = *(uint32*)data;
			else if (type == typeof(bool))
				value.Boolean = *(bool*)data;
			else if (type == typeof(Color))
				value.Color = *(Color*)data;
			else if (type == typeof(Float3))
				value.Vector = *(Float3*)data;
			else if (type == typeof(Guid))
				value.Id = *(Guid*)data;
		case .Err:
		}
		return value;
	}

	/// A hash of every built-in native class's declaration (its name, kind, fields, which are
	/// marked, and its methods): what the Native Behavior cook depends on.
	public static uint64 DeclarationsHash()
	{
		uint64 sum = 0;
		let text = scope String();
		for (let type in Type.Types)
		{
			if (!NativeBehaviorTypes.IsNativeBehavior(type))
				continue;
			text.Clear();
			type.GetFullName(text);
			text.AppendF("|{}", (int)NativeBehaviorTypes.KindOf(type));
			for (var t = type; t != null; t = t.BaseType)
			{
				for (let field in t.GetFields(.Instance | .Public | .NonPublic | .DeclaredOnly))
				{
					text.AppendF("|f:{}:", field.Name);
					field.FieldType.GetFullName(text);
					if (field.GetCustomAttribute<BehaviorPropertyAttribute>() case .Ok)
						text.Append(":p");
				}
				for (let method in t.GetMethods(.Instance | .Public | .NonPublic | .DeclaredOnly))
					text.AppendF("|m:{}:{}", method.Name, method.ParamCount);
			}
			sum += HashText(text); // order-free: the types' order is not the classes'
		}
		return sum;
	}
}
