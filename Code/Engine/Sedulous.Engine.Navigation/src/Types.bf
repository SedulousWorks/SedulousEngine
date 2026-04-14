namespace Sedulous.Engine.Navigation;

using System;
using recastnavigation_Beef;

/// Polygon reference wrapper.
struct PolyRef
{
	public dtPolyRef Value;

	public this(dtPolyRef value)
	{
		Value = value;
	}

	public bool IsValid => Value != 0;

	public static implicit operator dtPolyRef(PolyRef r) => r.Value;
	public static implicit operator PolyRef(dtPolyRef r) => PolyRef(r);
}

/// Tile reference wrapper.
struct TileRef
{
	public dtTileRef Value;

	public this(dtTileRef value)
	{
		Value = value;
	}

	public bool IsValid => Value != 0;

	public static implicit operator dtTileRef(TileRef r) => r.Value;
	public static implicit operator TileRef(dtTileRef r) => TileRef(r);
}

/// Obstacle reference wrapper.
struct ObstacleRef
{
	public dtObstacleRef Value;

	public this(dtObstacleRef value)
	{
		Value = value;
	}

	public bool IsValid => Value != 0;

	public static implicit operator dtObstacleRef(ObstacleRef r) => r.Value;
	public static implicit operator ObstacleRef(dtObstacleRef r) => ObstacleRef(r);
}

/// Navigation status result.
enum NavStatus
{
	Success,
	Failure,
	InProgress,
	PartialResult
}

/// Helper to convert dtStatus to NavStatus.
static class StatusHelper
{
	public static NavStatus FromDtStatus(dtStatus status)
	{
		if (dtStatusSucceed(status) != 0)
		{
			if (dtStatusDetail(status, DT_PARTIAL_RESULT) != 0)
				return .PartialResult;
			return .Success;
		}
		if (dtStatusInProgress(status) != 0)
			return .InProgress;
		return .Failure;
	}

	public static bool IsSuccess(dtStatus status)
	{
		return dtStatusSucceed(status) != 0;
	}
}

/// Straight path flags.
enum StraightPathFlags : uint8
{
	None = 0,
	Start = 0x01,
	End = 0x02,
	OffMeshConnection = 0x04
}

/// Crowd agent parameters.
[CRepr]
struct CrowdAgentParams
{
	public float Radius;
	public float Height;
	public float MaxAcceleration;
	public float MaxSpeed;
	public float CollisionQueryRange;
	public float PathOptimizationRange;
	public float SeparationWeight;
	public uint8 UpdateFlags;
	public uint8 ObstacleAvoidanceType;
	public uint8 QueryFilterType;
	public void* UserData;

	public static CrowdAgentParams Default => .() {
		Radius = 0.6f,
		Height = 2.0f,
		MaxAcceleration = 8.0f,
		MaxSpeed = 3.5f,
		CollisionQueryRange = 12.0f,
		PathOptimizationRange = 30.0f,
		SeparationWeight = 2.0f,
		UpdateFlags = (.)dtCrowdUpdateFlags.DT_CROWD_ANTICIPATE_TURNS |
					  (.)dtCrowdUpdateFlags.DT_CROWD_OBSTACLE_AVOIDANCE |
					  (.)dtCrowdUpdateFlags.DT_CROWD_SEPARATION,
		ObstacleAvoidanceType = 3,
		QueryFilterType = 0,
		UserData = null
	};
}

/// Navigation mesh build configuration.
struct NavMeshBuildConfig
{
	public float CellSize;
	public float CellHeight;
	public float AgentHeight;
	public float AgentRadius;
	public float AgentMaxClimb;
	public float AgentMaxSlope;
	public int32 RegionMinSize;
	public int32 RegionMergeSize;
	public float EdgeMaxLen;
	public float EdgeMaxError;
	public int32 VertsPerPoly;
	public float DetailSampleDist;
	public float DetailSampleMaxError;
	public int32 TileSize;

	public static NavMeshBuildConfig Default => .() {
		CellSize = 0.3f,
		CellHeight = 0.2f,
		AgentHeight = 2.0f,
		AgentRadius = 0.6f,
		AgentMaxClimb = 0.9f,
		AgentMaxSlope = 45.0f,
		RegionMinSize = 8,
		RegionMergeSize = 20,
		EdgeMaxLen = 12.0f,
		EdgeMaxError = 1.3f,
		VertsPerPoly = 6,
		DetailSampleDist = 6.0f,
		DetailSampleMaxError = 1.0f,
		TileSize = 0
	};
}

/// Debug draw vertex.
struct DebugDrawVertex
{
	public float X, Y, Z;
	public uint32 Color;

	public this(float x, float y, float z, uint32 color)
	{
		X = x;
		Y = y;
		Z = z;
		Color = color;
	}
}
