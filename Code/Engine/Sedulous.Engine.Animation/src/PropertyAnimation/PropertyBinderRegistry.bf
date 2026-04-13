namespace Sedulous.Engine.Animation;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Scenes;

// ---- Delegate types for property setters ----

public delegate void FloatPropertySetter(Scene scene, EntityHandle entity, float value);
public delegate void Vector2PropertySetter(Scene scene, EntityHandle entity, Vector2 value);
public delegate void Vector3PropertySetter(Scene scene, EntityHandle entity, Vector3 value);
public delegate void Vector4PropertySetter(Scene scene, EntityHandle entity, Vector4 value);
public delegate void QuaternionPropertySetter(Scene scene, EntityHandle entity, Quaternion value);

/// Registry mapping string property paths to typed setter delegates.
/// Built-in bindings for Transform properties are registered automatically.
/// Game code can register custom bindings for any component property.
public class PropertyBinderRegistry
{
	private Dictionary<String, FloatPropertySetter> mFloatSetters = new .() ~ {
		for (let entry in _) { delete entry.key; delete entry.value; }
		delete _;
	};

	private Dictionary<String, Vector2PropertySetter> mVector2Setters = new .() ~ {
		for (let entry in _) { delete entry.key; delete entry.value; }
		delete _;
	};

	private Dictionary<String, Vector3PropertySetter> mVector3Setters = new .() ~ {
		for (let entry in _) { delete entry.key; delete entry.value; }
		delete _;
	};

	private Dictionary<String, Vector4PropertySetter> mVector4Setters = new .() ~ {
		for (let entry in _) { delete entry.key; delete entry.value; }
		delete _;
	};

	private Dictionary<String, QuaternionPropertySetter> mQuaternionSetters = new .() ~ {
		for (let entry in _) { delete entry.key; delete entry.value; }
		delete _;
	};

	public this()
	{
		RegisterBuiltinBindings();
	}

	// ---- Registration ----

	public void RegisterFloat(StringView path, FloatPropertySetter setter)
	{
		let key = new String(path);
		if (mFloatSetters.TryGetValue(key, let existing))
		{
			delete existing;
			mFloatSetters[key] = setter;
			delete key;
		}
		else
			mFloatSetters[key] = setter;
	}

	public void RegisterVector2(StringView path, Vector2PropertySetter setter)
	{
		let key = new String(path);
		if (mVector2Setters.TryGetValue(key, let existing))
		{
			delete existing;
			mVector2Setters[key] = setter;
			delete key;
		}
		else
			mVector2Setters[key] = setter;
	}

	public void RegisterVector3(StringView path, Vector3PropertySetter setter)
	{
		let key = new String(path);
		if (mVector3Setters.TryGetValue(key, let existing))
		{
			delete existing;
			mVector3Setters[key] = setter;
			delete key;
		}
		else
			mVector3Setters[key] = setter;
	}

	public void RegisterVector4(StringView path, Vector4PropertySetter setter)
	{
		let key = new String(path);
		if (mVector4Setters.TryGetValue(key, let existing))
		{
			delete existing;
			mVector4Setters[key] = setter;
			delete key;
		}
		else
			mVector4Setters[key] = setter;
	}

	public void RegisterQuaternion(StringView path, QuaternionPropertySetter setter)
	{
		let key = new String(path);
		if (mQuaternionSetters.TryGetValue(key, let existing))
		{
			delete existing;
			mQuaternionSetters[key] = setter;
			delete key;
		}
		else
			mQuaternionSetters[key] = setter;
	}

	// ---- Lookup ----

	public FloatPropertySetter GetFloatSetter(StringView path)
	{
		if (mFloatSetters.TryGetValueAlt(path, let setter))
			return setter;
		return null;
	}

	public Vector2PropertySetter GetVector2Setter(StringView path)
	{
		if (mVector2Setters.TryGetValueAlt(path, let setter))
			return setter;
		return null;
	}

	public Vector3PropertySetter GetVector3Setter(StringView path)
	{
		if (mVector3Setters.TryGetValueAlt(path, let setter))
			return setter;
		return null;
	}

	public Vector4PropertySetter GetVector4Setter(StringView path)
	{
		if (mVector4Setters.TryGetValueAlt(path, let setter))
			return setter;
		return null;
	}

	public QuaternionPropertySetter GetQuaternionSetter(StringView path)
	{
		if (mQuaternionSetters.TryGetValueAlt(path, let setter))
			return setter;
		return null;
	}

	// ---- Built-in Bindings ----

	private void RegisterBuiltinBindings()
	{
		// Transform.Position (Vector3)
		RegisterVector3("Transform.Position", new (scene, entity, value) =>
		{
			var t = scene.GetLocalTransform(entity);
			t.Position = value;
			scene.SetLocalTransform(entity, t);
		});

		// Transform.Rotation (Quaternion)
		RegisterQuaternion("Transform.Rotation", new (scene, entity, value) =>
		{
			var t = scene.GetLocalTransform(entity);
			t.Rotation = value;
			scene.SetLocalTransform(entity, t);
		});

		// Transform.Scale (Vector3)
		RegisterVector3("Transform.Scale", new (scene, entity, value) =>
		{
			var t = scene.GetLocalTransform(entity);
			t.Scale = value;
			scene.SetLocalTransform(entity, t);
		});

		// Transform.Position.X/Y/Z (Float)
		RegisterFloat("Transform.Position.X", new (scene, entity, value) =>
		{
			var t = scene.GetLocalTransform(entity);
			t.Position.X = value;
			scene.SetLocalTransform(entity, t);
		});

		RegisterFloat("Transform.Position.Y", new (scene, entity, value) =>
		{
			var t = scene.GetLocalTransform(entity);
			t.Position.Y = value;
			scene.SetLocalTransform(entity, t);
		});

		RegisterFloat("Transform.Position.Z", new (scene, entity, value) =>
		{
			var t = scene.GetLocalTransform(entity);
			t.Position.Z = value;
			scene.SetLocalTransform(entity, t);
		});

		// Transform.Scale.X/Y/Z (Float)
		RegisterFloat("Transform.Scale.X", new (scene, entity, value) =>
		{
			var t = scene.GetLocalTransform(entity);
			t.Scale.X = value;
			scene.SetLocalTransform(entity, t);
		});

		RegisterFloat("Transform.Scale.Y", new (scene, entity, value) =>
		{
			var t = scene.GetLocalTransform(entity);
			t.Scale.Y = value;
			scene.SetLocalTransform(entity, t);
		});

		RegisterFloat("Transform.Scale.Z", new (scene, entity, value) =>
		{
			var t = scene.GetLocalTransform(entity);
			t.Scale.Z = value;
			scene.SetLocalTransform(entity, t);
		});
	}
}
