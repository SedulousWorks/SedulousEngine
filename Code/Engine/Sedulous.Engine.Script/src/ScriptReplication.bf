using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.Resource;

namespace Sedulous.Engine.Script;

/// A networked entity's behaviours keep their replicated properties (ScriptPropertyDesc.
/// Replicated) the same on every peer: the host writes their live values, a client writes
/// them back in, through the setter when the instance runs and as overrides for an instance
/// made later. A behaviour is matched by its slot and its class, so a value never reaches a
/// different class.
///
/// The bytes, the manager's own format: VarCount of entries, each { u32 slot, u64 class name
/// hash, u64 property hash, u8 kind, the value by its kind }.
extension ScriptComponentManager
{
	private ScriptRuntime LiveRuntime => ((ScriptSystem != null) && (ScriptSystem.Host != null)) ? ScriptSystem.Host.Runtime : null;

	public bool WriteReplicatedState(EntityHandle entity, List<uint8> outState)
	{
		outState.Clear();
		let component = Get(entity);
		if ((component == null) || (component.Behaviors == null))
			return false;
		let stream = scope MemoryStream();
		let writer = scope BinaryWriter(stream);
		uint32 count = 0;
		writer.Write(count); // patched below
		let runtime = LiveRuntime;
		for (int slot < component.Behaviors.Count)
		{
			let behavior = component.Behaviors[slot];
			let scriptClass = behavior.Script.Get;
			if (scriptClass == null)
				continue;
			let classHash = ScriptPropertyNames.HashOf(scriptClass.ClassName);
			for (let property in scriptClass.Properties)
			{
				if (!property.Replicated)
					continue;
				var value = ScriptPropertyValue();
				// The live value when the script runs (its text this writer's); else what it would
				// start with (borrowed).
				let live = (runtime != null) && (behavior.Instance != null) && LiveValue(runtime, behavior.Instance, property, ref value);
				if (!live)
				{
					if (let over = behavior.FindOverride(property.Hash))
						value = over.Value;
					else
						value = property.Default;
					value.Kind = property.Type;
				}
				writer.Write((uint32)slot);
				writer.Write(classHash);
				writer.Write(property.Hash);
				WriteValue(writer, value);
				if (live && (value.Text != null))
					delete value.Text;
				count++;
			}
		}
		if (count == 0)
			return false;
		let bytes = stream.Bytes;
		*(uint32*)bytes.Ptr = count;
		outState.AddRange(bytes);
		return writer.IsOk;
	}

	public void ReadReplicatedState(EntityHandle entity, Span<uint8> state)
	{
		let component = Get(entity);
		if ((component == null) || (component.Behaviors == null))
			return;
		let stream = scope MemoryStream();
		stream.Write(state);
		stream.Seek(0, .Begin);
		let reader = scope BinaryReader(stream);
		uint32 count = 0;
		if (!reader.Read(out count))
			return;
		let runtime = LiveRuntime;
		for (uint32 i < count)
		{
			uint32 slot = 0;
			uint64 classHash = 0;
			uint64 propertyHash = 0;
			reader.Read(out slot);
			reader.Read(out classHash);
			reader.Read(out propertyHash);
			var value = ScriptPropertyValue();
			if (!ReadValue(reader, ref value))
				return; // cut short: nothing half read is applied
			defer { if (value.Text != null) delete value.Text; }
			if (slot >= (uint32)component.Behaviors.Count)
				continue;
			let behavior = component.Behaviors[(int)slot];
			let scriptClass = behavior.Script.Get;
			if ((scriptClass == null) || (ScriptPropertyNames.HashOf(scriptClass.ClassName) != classHash))
				continue; // not the behaviour the host meant
			let property = scriptClass.FindProperty(propertyHash);
			if ((property == null) || !property.Replicated || (property.Type != value.Kind))
				continue;
			// For an instance made later; the override takes its own copy of the text.
			var kept = value;
			if (value.Text != null)
				kept.Text = new String(value.Text);
			behavior.SetOverride(propertyHash, kept);
			if ((runtime != null) && (behavior.Instance != null))
				ScriptProperties.Apply(runtime, behavior.Instance, property, value, Scene);
		}
	}

	/// The instance's current value of `property`, as the property's own kind.
	private static bool LiveValue(ScriptRuntime runtime, ScriptObject instance, ScriptPropertyDesc property, ref ScriptPropertyValue value)
	{
		var live = ScriptValue.Nil;
		if (!runtime.GetProperty(instance, property.Name, ref live))
			return false;
		value.Kind = property.Type;
		switch (property.Type)
		{
		case .Float, .Int:
			if ((live.Kind != .Float) && (live.Kind != .Int))
				return false;
			value.Number = live.AsNumber;
		case .Bool:
			if (live.Kind != .Bool)
				return false;
			value.Boolean = live.AsBool;
		case .String:
			if (live.Kind == .String)
				value.Text = new String(live.AsString);
			else if (let text = live.AsObject as String)
				value.Text = new String(text);
			else
				return false;
		case .Color:
			if (live.Kind != .Color)
				return false;
			value.Color = live.AsColor;
		case .Vec3:
			if (live.Kind != .Float3)
				return false;
			value.Vector = live.AsFloat3;
		default:
			return false; // entity and asset references are never replicated (refused at cook)
		}
		return true;
	}

	private static void WriteValue(BinaryWriter writer, ScriptPropertyValue value)
	{
		writer.Write((uint8)value.Kind);
		switch (value.Kind)
		{
		case .Float, .Int: writer.Write(value.Number);
		case .Bool: writer.Write((uint8)(value.Boolean ? 1 : 0));
		case .String: writer.WriteString(value.Text ?? "");
		case .Color: writer.Write(value.Color);
		case .Vec3: writer.Write(value.Vector);
		default:
		}
	}

	/// A value written by WriteValue; a text it reads is the caller's.
	private static bool ReadValue(BinaryReader reader, ref ScriptPropertyValue value)
	{
		uint8 kind = 0;
		if (!reader.Read(out kind))
			return false;
		value.Kind = (ScriptPropertyType)kind;
		switch (value.Kind)
		{
		case .Float, .Int: reader.Read(out value.Number);
		case .Bool:
			uint8 flag = 0;
			reader.Read(out flag);
			value.Boolean = flag != 0;
		case .String:
			let text = new String();
			if (!reader.ReadString(text))
			{
				delete text;
				return false;
			}
			value.Text = text;
		case .Color: reader.Read(out value.Color);
		case .Vec3: reader.Read(out value.Vector);
		default: return false;
		}
		return reader.IsOk;
	}
}
