using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;

namespace Sedulous.Scene.Resource;

/// The passes that run AFTER a scene is read.
///
/// Loading deliberately leaves two things undone. Resources are not bound, because binding
/// needs a manager over the database the scene came from and the loader has no business
/// knowing about one. Records whose code was absent are parked rather than dropped,
/// because the code may arrive later and until it does the bytes are all that stands
/// between a plugin's data and losing it.
static class SceneResolve
{
	/// Binds every resource reference the scene holds.
	///
	/// EVERY system, not only the component managers: a plain system's settings block holds
	/// references too, an environment's sky texture being the obvious one. Idempotent, so
	/// re binding something already bound is a cache hit rather than a fault.
	public static void ResolveSceneResources(Scene scene, ResourceManager resources)
	{
		for (let system in scene.Systems)
			system.ResolveResources(resources);
	}

	/// Turns the parked records of `manager`'s type into real components.
	///
	/// Called when a manager JOINS a live scene, which is what a plugin loading does, or
	/// for every manager at once after a load.
	public static void ResolveUnresolvedComponents(Scene scene, ComponentManagerBase manager)
	{
		let pending = scope List<UnresolvedComponent>();
		defer { ClearAndDeleteItems!(pending); }
		scene.TakeUnresolvedComponents(manager.SerializationTypeId, pending);

		for (let record in pending)
		{
			let owner = scene.FindEntity(record.Owner);
			if (!owner.IsAssigned)
				continue; // its entity is gone, so there is nothing to attach to

			if (!record.Text)
			{
				SceneStreamFormat.ComponentFromBlob(manager, owner, record.Payload);
				continue;
			}

			let document = scope XmlDocument();
			if (!ReparseFragment(document, record.Payload))
			{
				GlobalLog(.Warning,
					"SceneResolve: an unresolved component of type '{}' would not re-parse",
					record.TypeId);
				continue;
			}

			let ar = scope XmlSerializer(document);
			ar.Key("data");
			ar.BeginObject();
			manager.ReadComponent(ar, owner);
			ar.EndObject();
		}
	}

	/// The same for a system's settings block. At most one record per system, so this
	/// takes it or finds nothing.
	public static void ResolveUnresolvedSettings(Scene scene, SceneSystem system)
	{
		if (system.SettingsType == null)
			return;

		let record = scene.TakeUnresolvedSettings(system.SettingsId);
		if (record == null)
			return;
		defer delete record;

		let typeId = TypeIdOf(system.SettingsId);

		if (!record.Text)
		{
			let buffer = scope MemoryStream();
			buffer.Write(record.Payload);
			buffer.Seek(0, .Begin);
			let ar = scope BinarySerializer(buffer, .Read);
			ReadSettingsPayload(ar, system, typeId);
			return;
		}

		let document = scope XmlDocument();
		if (!ReparseFragment(document, record.Payload))
		{
			GlobalLog(.Warning,
				"SceneResolve: the unresolved settings of system '{}' would not re-parse",
				record.SystemId);
			return;
		}

		let ar = scope XmlSerializer(document);
		ReadSettingsPayload(ar, system, typeId);
	}

	/// Every parked record, against everything the scene now has.
	public static void ResolveAllUnresolvedRecords(Scene scene)
	{
		if (!scene.UnresolvedComponents.IsEmpty)
		{
			scene.ForEachManager(scope [&](manager) =>
			{
				if (manager.IsSerializable)
					ResolveUnresolvedComponents(scene, manager);
			});
		}

		if (!scene.UnresolvedSettingsRecords.IsEmpty)
		{
			for (let system in scene.Systems)
				ResolveUnresolvedSettings(scene, system);
		}
	}

	private static void ReadSettingsPayload(ISerializer ar, SceneSystem system, uint64 typeId)
	{
		BeginVersionedPayload(ar, typeId, system.SettingsDataVersion);
		ar.Key("settings");
		ar.BeginObject();
		system.SerializeSettings(ar);
		ar.EndObject();
		EndVersionedPayload(ar);
	}

	/// A captured text payload is an element FRAGMENT rather than a document, so it is
	/// wrapped before parsing: a parser needs one root and the capture kept only what sat
	/// inside the record.
	private static bool ReparseFragment(XmlDocument document, List<uint8> payload)
	{
		let wrapped = scope String();
		wrapped.Append("<root>");
		wrapped.Append(StringView((char8*)payload.Ptr, payload.Count));
		wrapped.Append("</root>");
		return document.Parse(wrapped) == .Ok;
	}
}
