using System;
namespace joltc_Beef;

static
{
	public const float JPH_DEFAULT_COLLISION_TOLERANCE = (1.0e-4f); // float cDefaultCollisionTolerance = 1.0e-4f
	public const float JPH_DEFAULT_PENETRATION_TOLERANCE = (1.0e-4f); // float cDefaultPenetrationTolerance = 1.0e-4f
	public const float JPH_DEFAULT_CONVEX_RADIUS = (0.05f); // float cDefaultConvexRadius = 0.05f
	public const float JPH_CAPSULE_PROJECTION_SLOP = (0.02f); // float cCapsuleProjectionSlop = 0.02f
	public const int32 JPH_MAX_PHYSICS_JOBS = (2048); // int32 cMaxPhysicsJobs = 2048
	public const int32 JPH_MAX_PHYSICS_BARRIERS = (8); // int32 cMaxPhysicsBarriers = 8
	public const uint32 JPH_INVALID_COLLISION_GROUP_ID = (~0U);
	public const uint32 JPH_INVALID_COLLISION_SUBGROUP_ID = (~0U);
	public const float JPH_M_PI = (3.14159265358979323846f); // To avoid collision with JPH_PI
}

typealias JPH_Bool = uint32;
typealias JPH_BodyID = uint32;
typealias JPH_SubShapeID = uint32;
typealias JPH_ObjectLayer = uint32;
typealias JPH_BroadPhaseLayer = uint8  ;
typealias JPH_CollisionGroupID = uint32;
typealias JPH_CollisionSubGroupID = uint32;
typealias JPH_CharacterID = uint32;

/* Forward declarations */
[CRepr] struct JPH_BroadPhaseLayerInterface				;
[CRepr] struct JPH_ObjectVsBroadPhaseLayerFilter		;
[CRepr] struct JPH_ObjectLayerPairFilter				;

[CRepr] struct JPH_BroadPhaseLayerFilter				;
[CRepr] struct JPH_ObjectLayerFilter					;
[CRepr] struct JPH_BodyFilter							;
[CRepr] struct JPH_ShapeFilter							;

[CRepr] struct JPH_SimShapeFilter						;

[CRepr] struct JPH_PhysicsStepListener					;
[CRepr] struct JPH_PhysicsSystem						;
[CRepr] struct JPH_PhysicsMaterial						;

[CRepr] struct JPH_LinearCurve							;

/* ShapeSettings */
[CRepr] struct JPH_ShapeSettings						;
[CRepr] struct JPH_ConvexShapeSettings					;
[CRepr] struct JPH_SphereShapeSettings					;
[CRepr] struct JPH_BoxShapeSettings						;
[CRepr] struct JPH_PlaneShapeSettings					;
[CRepr] struct JPH_TriangleShapeSettings				;
[CRepr] struct JPH_CapsuleShapeSettings					;
[CRepr] struct JPH_TaperedCapsuleShapeSettings			;
[CRepr] struct JPH_CylinderShapeSettings				;
[CRepr] struct JPH_TaperedCylinderShapeSettings			;
[CRepr] struct JPH_ConvexHullShapeSettings				;
[CRepr] struct JPH_CompoundShapeSettings				;
[CRepr] struct JPH_StaticCompoundShapeSettings			;
[CRepr] struct JPH_MutableCompoundShapeSettings			;
[CRepr] struct JPH_MeshShapeSettings					;
[CRepr] struct JPH_HeightFieldShapeSettings				;
[CRepr] struct JPH_RotatedTranslatedShapeSettings		;
[CRepr] struct JPH_ScaledShapeSettings					;
[CRepr] struct JPH_OffsetCenterOfMassShapeSettings		;
[CRepr] struct JPH_EmptyShapeSettings					;

/* Shape */
[CRepr] struct JPH_Shape								;
[CRepr] struct JPH_ConvexShape							;
[CRepr] struct JPH_SphereShape							;
[CRepr] struct JPH_BoxShape								;
[CRepr] struct JPH_PlaneShape							;
[CRepr] struct JPH_CapsuleShape							;
[CRepr] struct JPH_CylinderShape						;
[CRepr] struct JPH_TaperedCylinderShape					;
[CRepr] struct JPH_TriangleShape						;
[CRepr] struct JPH_TaperedCapsuleShape					;
[CRepr] struct JPH_ConvexHullShape						;
[CRepr] struct JPH_CompoundShape						;
[CRepr] struct JPH_StaticCompoundShape					;
[CRepr] struct JPH_MutableCompoundShape					;
[CRepr] struct JPH_MeshShape							;
[CRepr] struct JPH_HeightFieldShape						;
[CRepr] struct JPH_DecoratedShape						;
[CRepr] struct JPH_RotatedTranslatedShape				;
[CRepr] struct JPH_ScaledShape							;
[CRepr] struct JPH_OffsetCenterOfMassShape				;
[CRepr] struct JPH_EmptyShape							;

[CRepr] struct JPH_BodyCreationSettings					;
[CRepr] struct JPH_SoftBodyCreationSettings				;
[CRepr] struct JPH_BodyInterface						;
[CRepr] struct JPH_BodyLockInterface					;
[CRepr] struct JPH_BroadPhaseQuery						;
[CRepr] struct JPH_NarrowPhaseQuery						;
[CRepr] struct JPH_MotionProperties						;
//[CRepr] struct JPH_MassProperties						;
[CRepr] struct JPH_Body									;

//[CRepr] struct JPH_CollideShapeResult					;
[CRepr] struct JPH_ContactListener						;
[CRepr] struct JPH_ContactManifold						;

[CRepr] struct JPH_GroupFilter							;
[CRepr] struct JPH_GroupFilterTable						; /* Inherits JPH_GroupFilter */

/* Enums */
enum JPH_PhysicsUpdateError : int32
{
	JPH_PhysicsUpdateError_None = 0,
	JPH_PhysicsUpdateError_ManifoldCacheFull = 1 << 0,
	JPH_PhysicsUpdateError_BodyPairCacheFull = 1 << 1,
	JPH_PhysicsUpdateError_ContactConstraintsFull = 1 << 2,

	_JPH_PhysicsUpdateError_Count,
	_JPH_PhysicsUpdateError_Force32 = 0x7fffffff
}

enum JPH_BodyType : int32
{
	JPH_BodyType_Rigid = 0,
	JPH_BodyType_Soft = 1,

	_JPH_BodyType_Count,
	_JPH_BodyType_Force32 = 0x7fffffff
}

enum JPH_MotionType : int32
{
	JPH_MotionType_Static = 0,
	JPH_MotionType_Kinematic = 1,
	JPH_MotionType_Dynamic = 2,

	_JPH_MotionType_Count,
	_JPH_MotionType_Force32 = 0x7fffffff
}

enum JPH_Activation : int32
{
	JPH_Activation_Activate = 0,
	JPH_Activation_DontActivate = 1,

	_JPH_Activation_Count,
	_JPH_Activation_Force32 = 0x7fffffff
}

enum JPH_ValidateResult : int32
{
	JPH_ValidateResult_AcceptAllContactsForThisBodyPair = 0,
	JPH_ValidateResult_AcceptContact = 1,
	JPH_ValidateResult_RejectContact = 2,
	JPH_ValidateResult_RejectAllContactsForThisBodyPair = 3,

	_JPH_ValidateResult_Count,
	_JPH_ValidateResult_Force32 = 0x7fffffff
}

enum JPH_ShapeType : int32
{
	JPH_ShapeType_Convex = 0,
	JPH_ShapeType_Compound = 1,
	JPH_ShapeType_Decorated = 2,
	JPH_ShapeType_Mesh = 3,
	JPH_ShapeType_HeightField = 4,
	JPH_ShapeType_SoftBody = 5,

	JPH_ShapeType_User1 = 6,
	JPH_ShapeType_User2 = 7,
	JPH_ShapeType_User3 = 8,
	JPH_ShapeType_User4 = 9,

	_JPH_ShapeType_Count,
	_JPH_ShapeType_Force32 = 0x7fffffff
}

enum JPH_ShapeSubType : int32
{
	JPH_ShapeSubType_Sphere = 0,
	JPH_ShapeSubType_Box = 1,
	JPH_ShapeSubType_Triangle = 2,
	JPH_ShapeSubType_Capsule = 3,
	JPH_ShapeSubType_TaperedCapsule = 4,
	JPH_ShapeSubType_Cylinder = 5,
	JPH_ShapeSubType_ConvexHull = 6,
	JPH_ShapeSubType_StaticCompound = 7,
	JPH_ShapeSubType_MutableCompound = 8,
	JPH_ShapeSubType_RotatedTranslated = 9,
	JPH_ShapeSubType_Scaled = 10,
	JPH_ShapeSubType_OffsetCenterOfMass = 11,
	JPH_ShapeSubType_Mesh = 12,
	JPH_ShapeSubType_HeightField = 13,
	JPH_ShapeSubType_SoftBody = 14,

	_JPH_ShapeSubType_Count,
	_JPH_ShapeSubType_Force32 = 0x7fffffff
}

enum JPH_ConstraintType : int32
{
	JPH_ConstraintType_Constraint = 0,
	JPH_ConstraintType_TwoBodyConstraint = 1,

	_JPH_ConstraintType_Count,
	_JPH_ConstraintType_Force32 = 0x7fffffff
}

enum JPH_ConstraintSubType : int32
{
	JPH_ConstraintSubType_Fixed = 0,
	JPH_ConstraintSubType_Point = 1,
	JPH_ConstraintSubType_Hinge = 2,
	JPH_ConstraintSubType_Slider = 3,
	JPH_ConstraintSubType_Distance = 4,
	JPH_ConstraintSubType_Cone = 5,
	JPH_ConstraintSubType_SwingTwist = 6,
	JPH_ConstraintSubType_SixDOF = 7,
	JPH_ConstraintSubType_Path = 8,
	JPH_ConstraintSubType_Vehicle = 9,
	JPH_ConstraintSubType_RackAndPinion = 10,
	JPH_ConstraintSubType_Gear = 11,
	JPH_ConstraintSubType_Pulley = 12,

	JPH_ConstraintSubType_User1 = 13,
	JPH_ConstraintSubType_User2 = 14,
	JPH_ConstraintSubType_User3 = 15,
	JPH_ConstraintSubType_User4 = 16,

	_JPH_ConstraintSubType_Count,
	_JPH_ConstraintSubType_Force32 = 0x7fffffff
}

enum JPH_ConstraintSpace : int32
{
	JPH_ConstraintSpace_LocalToBodyCOM = 0,
	JPH_ConstraintSpace_WorldSpace = 1,

	_JPH_ConstraintSpace_Count,
	_JPH_ConstraintSpace_Force32 = 0x7fffffff
}

enum JPH_MotionQuality : int32
{
	JPH_MotionQuality_Discrete = 0,
	JPH_MotionQuality_LinearCast = 1,

	_JPH_MotionQuality_Count,
	_JPH_MotionQuality_Force32 = 0x7fffffff
}

enum JPH_OverrideMassProperties : int32
{
	JPH_OverrideMassProperties_CalculateMassAndInertia,
	JPH_OverrideMassProperties_CalculateInertia,
	JPH_OverrideMassProperties_MassAndInertiaProvided,

	_JPH_JPH_OverrideMassProperties_Count,
	_JPH_JPH_OverrideMassProperties_Force32 = 0x7FFFFFFF
}

enum JPH_AllowedDOFs : int32
{
	JPH_AllowedDOFs_All = 0b111111,
	JPH_AllowedDOFs_TranslationX = 0b000001,
	JPH_AllowedDOFs_TranslationY = 0b000010,
	JPH_AllowedDOFs_TranslationZ = 0b000100,
	JPH_AllowedDOFs_RotationX = 0b001000,
	JPH_AllowedDOFs_RotationY = 0b010000,
	JPH_AllowedDOFs_RotationZ = 0b100000,
	JPH_AllowedDOFs_Plane2D = JPH_AllowedDOFs_TranslationX | JPH_AllowedDOFs_TranslationY | JPH_AllowedDOFs_RotationZ,

	_JPH_AllowedDOFs_Count,
	_JPH_AllowedDOFs_Force32 = 0x7FFFFFFF
}

enum JPH_GroundState : int32
{
	JPH_GroundState_OnGround = 0,
	JPH_GroundState_OnSteepGround = 1,
	JPH_GroundState_NotSupported = 2,
	JPH_GroundState_InAir = 3,

	_JPH_GroundState_Count,
	_JPH_GroundState_Force32 = 0x7FFFFFFF
}

enum JPH_BackFaceMode : int32
{
	JPH_BackFaceMode_IgnoreBackFaces,
	JPH_BackFaceMode_CollideWithBackFaces,

	_JPH_BackFaceMode_Count,
	_JPH_BackFaceMode_Force32 = 0x7FFFFFFF
}

enum JPH_ActiveEdgeMode : int32
{
	JPH_ActiveEdgeMode_CollideOnlyWithActive,
	JPH_ActiveEdgeMode_CollideWithAll,

	_JPH_ActiveEdgeMode_Count,
	_JPH_ActiveEdgeMode_Force32 = 0x7FFFFFFF
}

enum JPH_CollectFacesMode : int32
{
	JPH_CollectFacesMode_CollectFaces,
	JPH_CollectFacesMode_NoFaces,

	_JPH_CollectFacesMode_Count,
	_JPH_CollectFacesMode_Force32 = 0x7FFFFFFF
}

enum JPH_MotorState : int32
{
	JPH_MotorState_Off = 0,
	JPH_MotorState_Velocity = 1,
	JPH_MotorState_Position = 2,

	_JPH_MotorState_Count,
	_JPH_MotorState_Force32 = 0x7FFFFFFF
}

enum JPH_CollisionCollectorType : int32
{
	JPH_CollisionCollectorType_AllHit = 0,
	JPH_CollisionCollectorType_AllHitSorted = 1,
	JPH_CollisionCollectorType_ClosestHit = 2,
	JPH_CollisionCollectorType_AnyHit = 3,

	_JPH_CollisionCollectorType_Count,
	_JPH_CollisionCollectorType_Force32 = 0x7FFFFFFF
}

enum JPH_SwingType : int32
{
	JPH_SwingType_Cone,
	JPH_SwingType_Pyramid,

	_JPH_SwingType_Count,
	_JPH_SwingType_Force32 = 0x7FFFFFFF
}

[AllowDuplicates]
enum JPH_SixDOFConstraintAxis : int32
{
	JPH_SixDOFConstraintAxis_TranslationX,
	JPH_SixDOFConstraintAxis_TranslationY,
	JPH_SixDOFConstraintAxis_TranslationZ,

	JPH_SixDOFConstraintAxis_RotationX,
	JPH_SixDOFConstraintAxis_RotationY,
	JPH_SixDOFConstraintAxis_RotationZ,

	_JPH_SixDOFConstraintAxis_Num,
	_JPH_SixDOFConstraintAxis_NumTranslation = JPH_SixDOFConstraintAxis_TranslationZ + 1,
	_JPH_SixDOFConstraintAxis_Force32 = 0x7FFFFFFF
}

enum JPH_SpringMode : int32
{
	JPH_SpringMode_FrequencyAndDamping = 0,
	JPH_SpringMode_StiffnessAndDamping = 1,

	_JPH_SpringMode_Count,
	_JPH_SpringMode_Force32 = 0x7FFFFFFF
}

/// Defines how to color soft body constraints
enum JPH_SoftBodyConstraintColor : int32
{
	JPH_SoftBodyConstraintColor_ConstraintType, /// Draw different types of constraints in different colors
	JPH_SoftBodyConstraintColor_ConstraintGroup, /// Draw constraints in the same group in the same color, non-parallel group will be red
	JPH_SoftBodyConstraintColor_ConstraintOrder, /// Draw constraints in the same group in the same color, non-parallel group will be red, and order within each group will be indicated with gradient

	_JPH_SoftBodyConstraintColor_Count,
	_JPH_SoftBodyConstraintColor_Force32 = 0x7FFFFFFF
}

enum JPH_BodyManager_ShapeColor : int32
{
	JPH_BodyManager_ShapeColor_InstanceColor, ///< Random color per instance
	JPH_BodyManager_ShapeColor_ShapeTypeColor, ///< Convex = green, scaled = yellow, compound = orange, mesh = red
	JPH_BodyManager_ShapeColor_MotionTypeColor, ///< Static = grey, keyframed = green, dynamic = random color per instance
	JPH_BodyManager_ShapeColor_SleepColor, ///< Static = grey, keyframed = green, dynamic = yellow, sleeping = red
	JPH_BodyManager_ShapeColor_IslandColor, ///< Static = grey, active = random color per island, sleeping = light grey
	JPH_BodyManager_ShapeColor_MaterialColor, ///< Color as defined by the PhysicsMaterial of the shape

	_JPH_BodyManager_ShapeColor_Count,
	_JPH_BodyManager_ShapeColor_Force32 = 0x7FFFFFFF
}

enum JPH_DebugRenderer_CastShadow : int32
{
	JPH_DebugRenderer_CastShadow_On = 0, ///< This shape should cast a shadow
	JPH_DebugRenderer_CastShadow_Off = 1, ///< This shape should not cast a shadow

	_JPH_DebugRenderer_CastShadow_Count,
	_JPH_DebugRenderer_CastShadow_Force32 = 0x7FFFFFFF
}

enum JPH_DebugRenderer_DrawMode : int32
{
	JPH_DebugRenderer_DrawMode_Solid = 0, ///< Draw as a solid shape
	JPH_DebugRenderer_DrawMode_Wireframe = 1, ///< Draw as wireframe

	_JPH_DebugRenderer_DrawMode_Count,
	_JPH_DebugRenderer_DrawMode_Force32 = 0x7FFFFFFF
}

enum JPH_Mesh_Shape_BuildQuality : int32
{
	JPH_Mesh_Shape_BuildQuality_FavorRuntimePerformance = 0,
	JPH_Mesh_Shape_BuildQuality_FavorBuildSpeed = 1,

	_JPH_Mesh_Shape_BuildQuality_Count,
	_JPH_Mesh_Shape_BuildQuality_Force32 = 0x7FFFFFFF
}

enum JPH_TransmissionMode : int32
{
	JPH_TransmissionMode_Auto = 0,
	JPH_TransmissionMode_Manual = 1,

	_JPH_TransmissionMode_Count,
	_JPH_TransmissionMode_Force32 = 0x7FFFFFFF
}

[CRepr] struct JPH_Vec3
{
	public float x;
	public float y;
	public float z;
}

[CRepr] struct JPH_Vec4
{
	public float x;
	public float y;
	public float z;
	public float w;
}

[CRepr] struct JPH_Quat
{
	public float x;
	public float y;
	public float z;
	public float w;
}

[CRepr] struct JPH_Plane
{
	public JPH_Vec3 normal;
	public float distance;
}

[CRepr] struct JPH_Mat4
{
	public JPH_Vec4[4] column;
}

[CRepr] struct JPH_Point
{
	public float x;
	public float y;
}

//#if defined(JPH_DOUBLE_PRECISION)
//[CRepr] struct JPH_RVec3 {
//	double x;
//	double y;
//	double z;
//} JPH_RVec3;

//[CRepr] struct JPH_RMat4 {
//	JPH_Vec4 column[3];
//	JPH_RVec3 column3;
//} JPH_RMat4;
//#else
typealias JPH_RVec3 = JPH_Vec3;
typealias JPH_RMat4 = JPH_Mat4;
//#endif

typealias JPH_Color = uint32;

[CRepr] struct JPH_AABox
{
	public JPH_Vec3 min;
	public JPH_Vec3 max;
}

[CRepr] struct JPH_Triangle
{
	public JPH_Vec3 v1;
	public JPH_Vec3 v2;
	public JPH_Vec3 v3;
	public uint32 materialIndex;
}

[CRepr] struct JPH_IndexedTriangleNoMaterial
{
	public uint32 i1;
	public uint32 i2;
	public uint32 i3;
}

[CRepr] struct JPH_IndexedTriangle
{
	public uint32 i1;
	public uint32 i2;
	public uint32 i3;
	public uint32 materialIndex;
	public uint32 userData;
}

[CRepr] struct JPH_MassProperties
{
	public float mass;
	public JPH_Mat4 inertia;
}

[CRepr] struct JPH_ContactSettings
{
	public float					combinedFriction;
	public float					combinedRestitution;
	public float					invMassScale1;
	public float					invInertiaScale1;
	public float					invMassScale2;
	public float					invInertiaScale2;
	public JPH_Bool				isSensor;
	public JPH_Vec3				relativeLinearSurfaceVelocity;
	public JPH_Vec3				relativeAngularSurfaceVelocity;
}

[CRepr] struct JPH_CollideSettingsBase
{
	/// How active edges (edges that a moving object should bump into) are handled
	public JPH_ActiveEdgeMode			activeEdgeMode /* = JPH_ActiveEdgeMode_CollideOnlyWithActive*/;

	/// If colliding faces should be collected or only the collision point
	public JPH_CollectFacesMode		collectFacesMode /* = JPH_CollectFacesMode_NoFaces*/;

	/// If objects are closer than this distance, they are considered to be colliding (used for GJK) (unit: meter)
	public float						collisionTolerance /* = JPH_DEFAULT_COLLISION_TOLERANCE*/;

	/// A factor that determines the accuracy of the penetration depth calculation. If the change of the squared distance is less than tolerance * current_penetration_depth^2 the algorithm will terminate. (unit: dimensionless)
	public float						penetrationTolerance /* = JPH_DEFAULT_PENETRATION_TOLERANCE*/;

	/// When mActiveEdgeMode is CollideOnlyWithActive a movement direction can be provided. When hitting an inactive edge, the system will select the triangle normal as penetration depth only if it impedes the movement less than with the calculated penetration depth.
	public JPH_Vec3					activeEdgeMovementDirection /* = Vec3::sZero()*/;
}

/* CollideShapeSettings */
[CRepr] struct JPH_CollideShapeSettings
{
	public JPH_CollideSettingsBase     @base; /* Inherits JPH_CollideSettingsBase */
	/// When > 0 contacts in the vicinity of the query shape can be found. All nearest contacts that are not further away than this distance will be found (unit: meter)
	public float						maxSeparationDistance /* = 0.0f*/;

	/// How backfacing triangles should be treated
	public JPH_BackFaceMode			backFaceMode /* = JPH_BackFaceMode_IgnoreBackFaces*/;
}

/* ShapeCastSettings */
[CRepr] struct JPH_ShapeCastSettings
{
	public JPH_CollideSettingsBase     @base; /* Inherits JPH_CollideSettingsBase */

	/// How backfacing triangles should be treated (should we report moving from back to front for triangle based shapes, e.g. for MeshShape/HeightFieldShape?)
	public JPH_BackFaceMode			backFaceModeTriangles /* = JPH_BackFaceMode_IgnoreBackFaces*/;

	/// How backfacing convex objects should be treated (should we report starting inside an object and moving out?)
	public JPH_BackFaceMode			backFaceModeConvex /* = JPH_BackFaceMode_IgnoreBackFaces*/;

	/// Indicates if we want to shrink the shape by the convex radius and then expand it again. This speeds up collision detection and gives a more accurate normal at the cost of a more 'rounded' shape.
	public bool						useShrunkenShapeAndConvexRadius /* = false*/;

	/// When true, and the shape is intersecting at the beginning of the cast (fraction = 0) then this will calculate the deepest penetration point (costing additional CPU time)
	public bool						returnDeepestPoint /* = false*/;
}

[CRepr] struct JPH_RayCastSettings
{
	/// How backfacing triangles should be treated (should we report back facing hits for triangle based shapes, e.g. MeshShape/HeightFieldShape?)
	public JPH_BackFaceMode backFaceModeTriangles /* = JPH_BackFaceMode_IgnoreBackFaces*/;

	/// How backfacing convex objects should be treated (should we report back facing hits for convex shapes?)
	public JPH_BackFaceMode backFaceModeConvex /* = JPH_BackFaceMode_IgnoreBackFaces*/;

	/// If convex shapes should be treated as solid. When true, a ray starting inside a convex shape will generate a hit at fraction 0.
	public bool treatConvexAsSolid /* = true*/;
}

[CRepr] struct JPH_SpringSettings
{
	public JPH_SpringMode mode;
	public float frequencyOrStiffness;
	public float damping;
}

[CRepr] struct JPH_MotorSettings
{
	public JPH_SpringSettings springSettings;
	public float minForceLimit;
	public float maxForceLimit;
	public float minTorqueLimit;
	public float maxTorqueLimit;
}

[CRepr] struct JPH_SubShapeIDPair
{
	public JPH_BodyID     Body1ID;
	public JPH_SubShapeID subShapeID1;
	public JPH_BodyID     Body2ID;
	public JPH_SubShapeID subShapeID2;
}

[CRepr] struct JPH_BroadPhaseCastResult
{
	public JPH_BodyID     bodyID;
	public float          fraction;
}

[CRepr] struct JPH_RayCastResult
{
	public JPH_BodyID     bodyID;
	public float          fraction;
	public JPH_SubShapeID subShapeID2;
}

[CRepr] struct JPH_CollidePointResult
{
	JPH_BodyID bodyID;
	JPH_SubShapeID subShapeID2;
}

[CRepr] struct JPH_CollideShapeResult
{
	JPH_Vec3		contactPointOn1;
	JPH_Vec3		contactPointOn2;
	JPH_Vec3		penetrationAxis;
	float			penetrationDepth;
	JPH_SubShapeID	subShapeID1;
	JPH_SubShapeID	subShapeID2;
	JPH_BodyID		bodyID2;
	uint32		shape1FaceCount;
	JPH_Vec3*		shape1Faces;
	uint32		shape2FaceCount;
	JPH_Vec3*		shape2Faces;
}

[CRepr] struct JPH_ShapeCastResult
{
	public JPH_Vec3           contactPointOn1;
	public JPH_Vec3           contactPointOn2;
	public JPH_Vec3           penetrationAxis;
	public float              penetrationDepth;
	public JPH_SubShapeID     subShapeID1;
	public JPH_SubShapeID     subShapeID2;
	public JPH_BodyID         bodyID2;
	public float              fraction;
	public bool			   isBackFaceHit;
}

[CRepr] struct JPH_DrawSettings
{
	bool						drawGetSupportFunction; ///< Draw the GetSupport() function, used for convex collision detection
	bool						drawSupportDirection; ///< When drawing the support function, also draw which direction mapped to a specific support point
	bool						drawGetSupportingFace; ///< Draw the faces that were found colliding during collision detection
	bool						drawShape; ///< Draw the shapes of all bodies
	bool						drawShapeWireframe; ///< When mDrawShape is true and this is true, the shapes will be drawn in wireframe instead of solid.
	JPH_BodyManager_ShapeColor	drawShapeColor; ///< Coloring scheme to use for shapes
	bool						drawBoundingBox; ///< Draw a bounding box per body
	bool						drawCenterOfMassTransform; ///< Draw the center of mass for each body
	bool						drawWorldTransform; ///< Draw the world transform (which may differ from its center of mass) of each body
	bool						drawVelocity; ///< Draw the velocity vector for each body
	bool						drawMassAndInertia; ///< Draw the mass and inertia (as the box equivalent) for each body
	bool						drawSleepStats; ///< Draw stats regarding the sleeping algorithm of each body
	bool						drawSoftBodyVertices; ///< Draw the vertices of soft bodies
	bool						drawSoftBodyVertexVelocities; ///< Draw the velocities of the vertices of soft bodies
	bool						drawSoftBodyEdgeConstraints; ///< Draw the edge constraints of soft bodies
	bool						drawSoftBodyBendConstraints; ///< Draw the bend constraints of soft bodies
	bool						drawSoftBodyVolumeConstraints; ///< Draw the volume constraints of soft bodies
	bool						drawSoftBodySkinConstraints; ///< Draw the skin constraints of soft bodies
	bool						drawSoftBodyLRAConstraints; ///< Draw the LRA constraints of soft bodies
	bool						drawSoftBodyPredictedBounds; ///< Draw the predicted bounds of soft bodies
	JPH_SoftBodyConstraintColor	drawSoftBodyConstraintColor; ///< Coloring scheme to use for soft body constraints
}

[CRepr] struct JPH_SupportingFace
{
	uint32 count;
	JPH_Vec3[32] vertices;
}

[CRepr] struct JPH_CollisionGroup
{
	JPH_GroupFilter*	groupFilter;
	JPH_CollisionGroupID	groupID;
	JPH_CollisionSubGroupID	subGroupID;
}

typealias JPH_CastRayResultCallback = function void(void* context, JPH_RayCastResult* result);
typealias JPH_RayCastBodyResultCallback = function void(void* context, JPH_BroadPhaseCastResult* result);
typealias JPH_CollideShapeBodyResultCallback = function void(void* context, JPH_BodyID result);
typealias JPH_CollidePointResultCallback = function void(void* context, JPH_CollidePointResult* result);
typealias JPH_CollideShapeResultCallback = function void(void* context, JPH_CollideShapeResult* result);
typealias JPH_CastShapeResultCallback = function void(void* context,  JPH_ShapeCastResult* result);

typealias  JPH_CastRayCollectorCallback = function float(void* context, JPH_RayCastResult* result);
typealias  JPH_RayCastBodyCollectorCallback = function  float(void* context, JPH_BroadPhaseCastResult* result);
typealias  JPH_CollideShapeBodyCollectorCallback = function  float(void* context, JPH_BodyID result);
typealias  JPH_CollidePointCollectorCallback = function  float(void* context, JPH_CollidePointResult* result);
typealias  JPH_CollideShapeCollectorCallback = function  float(void* context, JPH_CollideShapeResult* result);
typealias  JPH_CastShapeCollectorCallback = function  float(void* context, JPH_ShapeCastResult* result);

[CRepr] struct JPH_CollisionEstimationResultImpulse
{
	float	contactImpulse;
	float	frictionImpulse1;
	float	frictionImpulse2;
}

[CRepr] struct JPH_CollisionEstimationResult
{
	JPH_Vec3								linearVelocity1;
	JPH_Vec3								angularVelocity1;
	JPH_Vec3								linearVelocity2;
	JPH_Vec3								angularVelocity2;

	JPH_Vec3								tangent1;
	JPH_Vec3								tangent2;

	uint32								impulseCount;
	JPH_CollisionEstimationResultImpulse*	impulses;
}

[CRepr] struct JPH_BodyActivationListener           ;
[CRepr] struct JPH_BodyDrawFilter                   ;

[CRepr] struct JPH_SharedMutex                      ;

[CRepr] struct JPH_DebugRenderer                    ;

/* Constraint */
[CRepr] struct JPH_Constraint                       ;
[CRepr] struct JPH_TwoBodyConstraint                ;
[CRepr] struct JPH_FixedConstraint                  ;
[CRepr] struct JPH_DistanceConstraint               ;
[CRepr] struct JPH_PointConstraint                  ;
[CRepr] struct JPH_HingeConstraint                  ;
[CRepr] struct JPH_SliderConstraint                 ;
[CRepr] struct JPH_ConeConstraint                   ;
[CRepr] struct JPH_SwingTwistConstraint             ;
[CRepr] struct JPH_SixDOFConstraint				    ;
[CRepr] struct JPH_GearConstraint				    ;

/* Character, CharacterVirtual */
[CRepr] struct JPH_CharacterBase					;
[CRepr] struct JPH_Character						; /* Inherits JPH_CharacterBase */
[CRepr] struct JPH_CharacterVirtual                 ; /* Inherits JPH_CharacterBase */
[CRepr] struct JPH_CharacterContactListener			;
[CRepr] struct JPH_CharacterVsCharacterCollision	;

/* Skeleton/Ragdoll */
[CRepr] struct JPH_Skeleton							;
[CRepr] struct JPH_SkeletonPose						;
[CRepr] struct JPH_SkeletalAnimation				;
[CRepr] struct JPH_SkeletonMapper					;
[CRepr] struct JPH_RagdollSettings					;
[CRepr] struct JPH_Ragdoll							;

[CRepr] struct JPH_ConstraintSettings
{
	public bool					enabled;
	public uint32				constraintPriority;
	public uint32				numVelocityStepsOverride;
	public uint32				numPositionStepsOverride;
	public float				drawConstraintSize;
	public uint64				userData;
}

[CRepr] struct JPH_FixedConstraintSettings
{
	public JPH_ConstraintSettings	@base; /* Inherits JPH_ConstraintSettings */

	public JPH_ConstraintSpace		space;
	public bool						autoDetectPoint;
	public JPH_RVec3				point1;
	public JPH_Vec3					axisX1;
	public JPH_Vec3					axisY1;
	public JPH_RVec3				point2;
	public JPH_Vec3					axisX2;
	public JPH_Vec3					axisY2;
}

[CRepr] struct JPH_DistanceConstraintSettings
{
	public JPH_ConstraintSettings	@base; /* Inherits JPH_ConstraintSettings */

	public JPH_ConstraintSpace		space;
	public JPH_RVec3				point1;
	public JPH_RVec3				point2;
	public float					minDistance;
	public float					maxDistance;
	public JPH_SpringSettings		limitsSpringSettings;
}

[CRepr] struct JPH_PointConstraintSettings
{
	public JPH_ConstraintSettings	@base; /* Inherits JPH_ConstraintSettings */

	public JPH_ConstraintSpace		space;
	public JPH_RVec3				point1;
	public JPH_RVec3				point2;
}

[CRepr] struct JPH_HingeConstraintSettings
{
	public JPH_ConstraintSettings	@base; /* Inherits JPH_ConstraintSettings */

	public JPH_ConstraintSpace		space;
	public JPH_RVec3				point1;
	public JPH_Vec3					hingeAxis1;
	public JPH_Vec3					normalAxis1;
	public JPH_RVec3				point2;
	public JPH_Vec3					hingeAxis2;
	public JPH_Vec3					normalAxis2;
	public float					limitsMin;
	public float					limitsMax;
	public JPH_SpringSettings		limitsSpringSettings;
	public float					maxFrictionTorque;
	public JPH_MotorSettings		motorSettings;
}

[CRepr] struct JPH_SliderConstraintSettings
{
	public JPH_ConstraintSettings	@base; /* Inherits JPH_ConstraintSettings */

	public JPH_ConstraintSpace		space;
	public bool						autoDetectPoint;
	public JPH_RVec3				point1;
	public JPH_Vec3					sliderAxis1;
	public JPH_Vec3					normalAxis1;
	public JPH_RVec3				point2;
	public JPH_Vec3					sliderAxis2;
	public JPH_Vec3					normalAxis2;
	public float					limitsMin;
	public float					limitsMax;
	public JPH_SpringSettings		limitsSpringSettings;
	public float					maxFrictionForce;
	public JPH_MotorSettings		motorSettings;
}

[CRepr] struct JPH_ConeConstraintSettings
{
	public JPH_ConstraintSettings	@base; /* Inherits JPH_ConstraintSettings */

	public JPH_ConstraintSpace		space;
	public JPH_RVec3				point1;
	public JPH_Vec3					twistAxis1;
	public JPH_RVec3				point2;
	public JPH_Vec3					twistAxis2;
	public float					halfConeAngle;
}

[CRepr] struct JPH_SwingTwistConstraintSettings
{
	public JPH_ConstraintSettings	@base; /* Inherits JPH_ConstraintSettings */

	public JPH_ConstraintSpace		space;
	public JPH_RVec3				position1;
	public JPH_Vec3					twistAxis1;
	public JPH_Vec3					planeAxis1;
	public JPH_RVec3				position2;
	public JPH_Vec3					twistAxis2;
	public JPH_Vec3					planeAxis2;
	public JPH_SwingType			swingType;
	public float					normalHalfConeAngle;
	public float					planeHalfConeAngle;
	public float					twistMinAngle;
	public float					twistMaxAngle;
	public float					maxFrictionTorque;
	public JPH_MotorSettings		swingMotorSettings;
	public JPH_MotorSettings		twistMotorSettings;
}

[CRepr] struct JPH_SixDOFConstraintSettings
{
	public JPH_ConstraintSettings	@base; /* Inherits JPH_ConstraintSettings */

	public JPH_ConstraintSpace		space;
	public JPH_RVec3				position1;
	public JPH_Vec3					axisX1;
	public JPH_Vec3					axisY1;
	public JPH_RVec3				position2;
	public JPH_Vec3					axisX2;
	public JPH_Vec3					axisY2;
	public float[(int)JPH_SixDOFConstraintAxis._JPH_SixDOFConstraintAxis_Num]					maxFriction;
	public JPH_SwingType			swingType;
	public float[(int)JPH_SixDOFConstraintAxis._JPH_SixDOFConstraintAxis_Num]					limitMin;
	public float[(int)JPH_SixDOFConstraintAxis._JPH_SixDOFConstraintAxis_Num]					limitMax;

	public JPH_SpringSettings[(int)JPH_SixDOFConstraintAxis._JPH_SixDOFConstraintAxis_NumTranslation]	limitsSpringSettings;
	public JPH_MotorSettings[(int)JPH_SixDOFConstraintAxis._JPH_SixDOFConstraintAxis_Num]		motorSettings;
}

[CRepr] struct JPH_GearConstraintSettings
{
	public JPH_ConstraintSettings	@base; /* Inherits JPH_ConstraintSettings */

	public JPH_ConstraintSpace		space;
	public JPH_Vec3					hingeAxis1;
	public JPH_Vec3					hingeAxis2;
	public float					ratio;
}

[CRepr] struct JPH_BodyLockRead
{
	public JPH_BodyLockInterface* lockInterface;
	public JPH_SharedMutex* mutex;
	public JPH_Body* body;
}

[CRepr] struct JPH_BodyLockWrite
{
	public JPH_BodyLockInterface* lockInterface;
	public JPH_SharedMutex* mutex;
	public JPH_Body* body;
}

[CRepr] struct JPH_BodyLockMultiRead;
[CRepr] struct JPH_BodyLockMultiWrite;

[CRepr] struct JPH_ExtendedUpdateSettings
{
	public JPH_Vec3		stickToFloorStepDown;
	public JPH_Vec3		walkStairsStepUp;
	public float		walkStairsMinStepForward;
	public float		walkStairsStepForwardTest;
	public float		walkStairsCosAngleForwardContact;
	public JPH_Vec3		walkStairsStepDownExtra;
}

[CRepr] struct JPH_CharacterBaseSettings
{
	public JPH_Vec3 up;
	public JPH_Plane supportingVolume;
	public float maxSlopeAngle;
	public bool enhancedInternalEdgeRemoval;
	public JPH_Shape* shape;
}

/* Character */
[CRepr] struct JPH_CharacterSettings
{
	public JPH_CharacterBaseSettings		@base; /* Inherits JPH_CharacterBaseSettings */
	public JPH_ObjectLayer					layer;
	public float							mass;
	public float							friction;
	public float							gravityFactor;
	public JPH_AllowedDOFs					allowedDOFs;
}

/* CharacterVirtual */
[CRepr] struct JPH_CharacterVirtualSettings
{
	public JPH_CharacterBaseSettings		@base; /* Inherits JPH_CharacterBaseSettings */
	public JPH_CharacterID					ID;
	public float							mass;
	public float							maxStrength;
	public JPH_Vec3							shapeOffset;
	public JPH_BackFaceMode					backFaceMode;
	public float							predictiveContactDistance;
	public uint32							maxCollisionIterations;
	public uint32							maxConstraintIterations;
	public float							minTimeRemaining;
	public float							collisionTolerance;
	public float							characterPadding;
	public uint32							maxNumHits;
	public float							hitReductionCosMaxAngle;
	public float							penetrationRecoverySpeed;
	public JPH_Shape*						innerBodyShape;
	public JPH_BodyID						innerBodyIDOverride;
	public JPH_ObjectLayer					innerBodyLayer;
}

[CRepr] struct JPH_CharacterContactSettings
{
	public bool canPushCharacter;
	public bool canReceiveImpulses;
}

[CRepr] struct JPH_CharacterVirtualContact
{
	public uint64					hash;
	public JPH_BodyID				bodyB;
	public JPH_CharacterID			characterIDB;
	public JPH_SubShapeID			subShapeIDB;
	public JPH_RVec3				position;
	public JPH_Vec3					linearVelocity;
	public JPH_Vec3					contactNormal;
	public JPH_Vec3					surfaceNormal;
	public float					distance;
	public float					fraction;
	public JPH_MotionType			motionTypeB;
	public bool						isSensorB;
	public JPH_CharacterVirtual*	characterB;
	public uint64					userData;
	public JPH_PhysicsMaterial*		material;
	public bool						hadCollision;
	public bool						wasDiscarded;
	public bool						canPushCharacter;
}

[CRepr /*, CallingConvention(.Cdecl)*/] typealias JPH_TraceFunc = function void(char8* message);
[CRepr /*, CallingConvention(.Cdecl)*/] typealias JPH_AssertFailureFunc = function bool(char8* expression, char8* message, char8* file, uint32 line);

typealias JPH_JobFunction = function void(void* arg);
typealias JPH_QueueJobCallback = function void(void* context, JPH_JobFunction* job, void* arg);
typealias JPH_QueueJobsCallback = function void(void* context, JPH_JobFunction* job, void** args, uint32 count);

[CRepr] struct JobSystemThreadPoolConfig
{
	public uint32 maxJobs;
	public uint32 maxBarriers;
	public int32 numThreads;
}

[CRepr] struct JPH_JobSystemConfig
{
	public void* context;
	public JPH_QueueJobCallback* queueJob;
	public JPH_QueueJobsCallback* queueJobs;
	public uint32 maxConcurrency;
	public uint32 maxBarriers;
}

[CRepr] struct JPH_JobSystem;

/* Calculate max tire impulses by combining friction, slip, and suspension impulse. Note that the actual applied impulse may be lower (e.g. when the vehicle is stationary on a horizontal surface the actual impulse applied will be 0) */
[CRepr /*, CallingConvention(.Cdecl)*/] typealias JPH_TireMaxImpulseCallback = function void(
	void* userData,
	uint32 wheelIndex,
	float* outLongitudinalImpulse,
	float* outLateralImpulse,
	float suspensionImpulse,
	float longitudinalFriction,
	float lateralFriction,
	float longitudinalSlip,
	float lateralSlip,
	float deltaTime);

static
{
	[CLink] public static extern JPH_JobSystem* JPH_JobSystemThreadPool_Create(JobSystemThreadPoolConfig* config);
	[CLink] public static extern JPH_JobSystem* JPH_JobSystemCallback_Create(JPH_JobSystemConfig* config);
	[CLink] public static extern void JPH_JobSystem_Destroy(JPH_JobSystem* jobSystem);

	[CLink] public static extern bool JPH_Init();
	[CLink] public static extern void JPH_Shutdown();
	[CLink] public static extern void JPH_SetTraceHandler(JPH_TraceFunc handler);
	[CLink] public static extern void JPH_SetAssertFailureHandler(JPH_AssertFailureFunc handler);

	/* Structs free members */
	[CLink] public static extern void JPH_CollideShapeResult_FreeMembers(JPH_CollideShapeResult* result);
	[CLink] public static extern void JPH_CollisionEstimationResult_FreeMembers(JPH_CollisionEstimationResult* result);

	/* JPH_BroadPhaseLayerInterface */
	[CLink] public static extern JPH_BroadPhaseLayerInterface* JPH_BroadPhaseLayerInterfaceMask_Create(uint32 numBroadPhaseLayers);
	[CLink] public static extern void JPH_BroadPhaseLayerInterfaceMask_ConfigureLayer(JPH_BroadPhaseLayerInterface* bpInterface, JPH_BroadPhaseLayer broadPhaseLayer, uint32 groupsToInclude, uint32 groupsToExclude);

	[CLink] public static extern JPH_BroadPhaseLayerInterface* JPH_BroadPhaseLayerInterfaceTable_Create(uint32 numObjectLayers, uint32 numBroadPhaseLayers);
	[CLink] public static extern void JPH_BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(JPH_BroadPhaseLayerInterface* bpInterface, JPH_ObjectLayer objectLayer, JPH_BroadPhaseLayer broadPhaseLayer);

	/* JPH_ObjectLayerPairFilter */
	[CLink] public static extern JPH_ObjectLayerPairFilter* JPH_ObjectLayerPairFilterMask_Create();
	[CLink] public static extern JPH_ObjectLayer JPH_ObjectLayerPairFilterMask_GetObjectLayer(uint32 group, uint32 mask);
	[CLink] public static extern uint32 JPH_ObjectLayerPairFilterMask_GetGroup(JPH_ObjectLayer layer);
	[CLink] public static extern uint32 JPH_ObjectLayerPairFilterMask_GetMask(JPH_ObjectLayer layer);

	[CLink] public static extern JPH_ObjectLayerPairFilter* JPH_ObjectLayerPairFilterTable_Create(uint32 numObjectLayers);
	[CLink] public static extern void JPH_ObjectLayerPairFilterTable_DisableCollision(JPH_ObjectLayerPairFilter* objectFilter, JPH_ObjectLayer layer1, JPH_ObjectLayer layer2);
	[CLink] public static extern void JPH_ObjectLayerPairFilterTable_EnableCollision(JPH_ObjectLayerPairFilter* objectFilter, JPH_ObjectLayer layer1, JPH_ObjectLayer layer2);
	[CLink] public static extern bool JPH_ObjectLayerPairFilterTable_ShouldCollide(JPH_ObjectLayerPairFilter* objectFilter, JPH_ObjectLayer layer1, JPH_ObjectLayer layer2);

	/* JPH_ObjectVsBroadPhaseLayerFilter */
	[CLink] public static extern JPH_ObjectVsBroadPhaseLayerFilter* JPH_ObjectVsBroadPhaseLayerFilterMask_Create(JPH_BroadPhaseLayerInterface* broadPhaseLayerInterface);

	[CLink] public static extern JPH_ObjectVsBroadPhaseLayerFilter* JPH_ObjectVsBroadPhaseLayerFilterTable_Create(
		JPH_BroadPhaseLayerInterface* broadPhaseLayerInterface, uint32 numBroadPhaseLayers,
		JPH_ObjectLayerPairFilter* objectLayerPairFilter, uint32 numObjectLayers);

	[CLink] public static extern void JPH_DrawSettings_InitDefault(JPH_DrawSettings* settings);
}

	/* JPH_PhysicsSystem */
[CRepr] struct JPH_PhysicsSystemSettings
{
	public uint32 maxBodies; /* 10240 */
	public uint32 numBodyMutexes; /* 0 */
	public uint32 maxBodyPairs; /* 65536 */
	public uint32 maxContactConstraints; /* 10240 */
	public uint32 _padding;
	public JPH_BroadPhaseLayerInterface* broadPhaseLayerInterface;
	public JPH_ObjectLayerPairFilter* objectLayerPairFilter;
	public JPH_ObjectVsBroadPhaseLayerFilter* objectVsBroadPhaseLayerFilter;
}

[CRepr] struct JPH_PhysicsSettings
{
	int32 maxInFlightBodyPairs;
	int32 stepListenersBatchSize;
	int32 stepListenerBatchesPerJob;
	float baumgarte;
	float speculativeContactDistance;
	float penetrationSlop;
	float linearCastThreshold;
	float linearCastMaxPenetration;
	float manifoldTolerance;
	float maxPenetrationDistance;
	float bodyPairCacheMaxDeltaPositionSq;
	float bodyPairCacheCosMaxDeltaRotationDiv2;
	float contactNormalCosMaxDeltaRotation;
	float contactPointPreserveLambdaMaxDistSq;
	uint32 numVelocitySteps;
	uint32 numPositionSteps;
	float minVelocityForRestitution;
	float timeBeforeSleep;
	float pointVelocitySleepThreshold;
	bool deterministicSimulation;
	bool constraintWarmStart;
	bool useBodyPairContactCache;
	bool useManifoldReduction;
	bool useLargeIslandSplitter;
	bool allowSleeping;
	bool checkActiveEdges;
}
static
{
	[CLink] public static extern JPH_PhysicsSystem* JPH_PhysicsSystem_Create(JPH_PhysicsSystemSettings* settings);
	[CLink] public static extern void JPH_PhysicsSystem_Destroy(JPH_PhysicsSystem* system);

	[CLink] public static extern void JPH_PhysicsSystem_SetPhysicsSettings(JPH_PhysicsSystem* system, JPH_PhysicsSettings* settings);
	[CLink] public static extern void JPH_PhysicsSystem_GetPhysicsSettings(JPH_PhysicsSystem* system, JPH_PhysicsSettings* result);

	[CLink] public static extern void JPH_PhysicsSystem_OptimizeBroadPhase(JPH_PhysicsSystem* system);
	[CLink] public static extern JPH_PhysicsUpdateError JPH_PhysicsSystem_Update(JPH_PhysicsSystem* system, float deltaTime, int32 collisionSteps, JPH_JobSystem* jobSystem);

	[CLink] public static extern JPH_BodyInterface* JPH_PhysicsSystem_GetBodyInterface(JPH_PhysicsSystem* system);
	[CLink] public static extern JPH_BodyInterface* JPH_PhysicsSystem_GetBodyInterfaceNoLock(JPH_PhysicsSystem* system);

	[CLink] public static extern JPH_BodyLockInterface* JPH_PhysicsSystem_GetBodyLockInterface(JPH_PhysicsSystem* system);
	[CLink] public static extern JPH_BodyLockInterface* JPH_PhysicsSystem_GetBodyLockInterfaceNoLock(JPH_PhysicsSystem* system);

	[CLink] public static extern JPH_BroadPhaseQuery* JPH_PhysicsSystem_GetBroadPhaseQuery(JPH_PhysicsSystem* system);

	[CLink] public static extern JPH_NarrowPhaseQuery* JPH_PhysicsSystem_GetNarrowPhaseQuery(JPH_PhysicsSystem* system);
	[CLink] public static extern JPH_NarrowPhaseQuery* JPH_PhysicsSystem_GetNarrowPhaseQueryNoLock(JPH_PhysicsSystem* system);

	[CLink] public static extern void JPH_PhysicsSystem_SetContactListener(JPH_PhysicsSystem* system, JPH_ContactListener* listener);
	[CLink] public static extern void JPH_PhysicsSystem_SetBodyActivationListener(JPH_PhysicsSystem* system, JPH_BodyActivationListener* listener);
	[CLink] public static extern void JPH_PhysicsSystem_SetSimShapeFilter(JPH_PhysicsSystem* system, JPH_SimShapeFilter* filter);

	[CLink] public static extern bool JPH_PhysicsSystem_WereBodiesInContact(JPH_PhysicsSystem* system, JPH_BodyID body1, JPH_BodyID body2);

	[CLink] public static extern uint32 JPH_PhysicsSystem_GetNumBodies(JPH_PhysicsSystem* system);
	[CLink] public static extern uint32 JPH_PhysicsSystem_GetNumActiveBodies(JPH_PhysicsSystem* system, JPH_BodyType type);
	[CLink] public static extern uint32 JPH_PhysicsSystem_GetMaxBodies(JPH_PhysicsSystem* system);
	[CLink] public static extern uint32 JPH_PhysicsSystem_GetNumConstraints(JPH_PhysicsSystem* system);

	[CLink] public static extern void JPH_PhysicsSystem_SetGravity(JPH_PhysicsSystem* system, JPH_Vec3* value);
	[CLink] public static extern void JPH_PhysicsSystem_GetGravity(JPH_PhysicsSystem* system, JPH_Vec3* result);

	[CLink] public static extern void JPH_PhysicsSystem_AddConstraint(JPH_PhysicsSystem* system, JPH_Constraint* constraint);
	[CLink] public static extern void JPH_PhysicsSystem_RemoveConstraint(JPH_PhysicsSystem* system, JPH_Constraint* constraint);

	[CLink] public static extern void JPH_PhysicsSystem_AddConstraints(JPH_PhysicsSystem* system, JPH_Constraint** constraints, uint32 count);
	[CLink] public static extern void JPH_PhysicsSystem_RemoveConstraints(JPH_PhysicsSystem* system, JPH_Constraint** constraints, uint32 count);

	[CLink] public static extern void JPH_PhysicsSystem_AddStepListener(JPH_PhysicsSystem* system, JPH_PhysicsStepListener* listener);
	[CLink] public static extern void JPH_PhysicsSystem_RemoveStepListener(JPH_PhysicsSystem* system, JPH_PhysicsStepListener* listener);

	[CLink] public static extern void JPH_PhysicsSystem_GetBodies(JPH_PhysicsSystem* system, JPH_BodyID* ids, uint32 count);
	[CLink] public static extern void JPH_PhysicsSystem_GetConstraints(JPH_PhysicsSystem* system, JPH_Constraint** constraints, uint32 count);

	[CLink] public static extern void JPH_PhysicsSystem_ActivateBodiesInAABox(JPH_PhysicsSystem* system, JPH_AABox* @box, JPH_ObjectLayer layer);

	[CLink] public static extern void JPH_PhysicsSystem_DrawBodies(JPH_PhysicsSystem* system, JPH_DrawSettings* settings, JPH_DebugRenderer* renderer, JPH_BodyDrawFilter* bodyFilter /* = nullptr */);
	[CLink] public static extern void JPH_PhysicsSystem_DrawConstraints(JPH_PhysicsSystem* system, JPH_DebugRenderer* renderer);
	[CLink] public static extern void JPH_PhysicsSystem_DrawConstraintLimits(JPH_PhysicsSystem* system, JPH_DebugRenderer* renderer);
	[CLink] public static extern void JPH_PhysicsSystem_DrawConstraintReferenceFrame(JPH_PhysicsSystem* system, JPH_DebugRenderer* renderer);
}
	/* PhysicsStepListener */
[CRepr] struct JPH_PhysicsStepListenerContext
{
	float					deltaTime;
	JPH_Bool				isFirstStep;
	JPH_Bool				isLastStep;
	JPH_PhysicsSystem*		physicsSystem;
}


[CRepr] struct JPH_PhysicsStepListener_Procs
{
	public function void(void* userData, JPH_PhysicsStepListenerContext* context) OnStep;
}
static
{
	[CLink] public static extern void JPH_PhysicsStepListener_SetProcs(JPH_PhysicsStepListener_Procs* procs);
	[CLink] public static extern JPH_PhysicsStepListener* JPH_PhysicsStepListener_Create(void* userData);
	[CLink] public static extern void JPH_PhysicsStepListener_Destroy(JPH_PhysicsStepListener* listener);

	/* Math */
	[CLink] public static extern float JPH_Math_Sin(float value);
	[CLink] public static extern float JPH_Math_Cos(float value);

	[CLink] public static extern void JPH_Quat_FromTo(JPH_Vec3* from, JPH_Vec3* to, JPH_Quat* quat);
	[CLink] public static extern void JPH_Quat_GetAxisAngle(JPH_Quat* quat, JPH_Vec3* outAxis, float* outAngle);
	[CLink] public static extern void JPH_Quat_GetEulerAngles(JPH_Quat* quat, JPH_Vec3* result);
	[CLink] public static extern void JPH_Quat_RotateAxisX(JPH_Quat* quat, JPH_Vec3* result);
	[CLink] public static extern void JPH_Quat_RotateAxisY(JPH_Quat* quat, JPH_Vec3* result);
	[CLink] public static extern void JPH_Quat_RotateAxisZ(JPH_Quat* quat, JPH_Vec3* result);
	[CLink] public static extern void JPH_Quat_Inversed(JPH_Quat* quat, JPH_Quat* result);
	[CLink] public static extern void JPH_Quat_GetPerpendicular(JPH_Quat* quat, JPH_Quat* result);
	[CLink] public static extern float JPH_Quat_GetRotationAngle(JPH_Quat* quat, JPH_Vec3* axis);
	[CLink] public static extern void JPH_Quat_FromEulerAngles(JPH_Vec3* angles, JPH_Quat* result);

	[CLink] public static extern void JPH_Quat_Add(JPH_Quat* q1, JPH_Quat* q2, JPH_Quat* result);
	[CLink] public static extern void JPH_Quat_Subtract(JPH_Quat* q1, JPH_Quat* q2, JPH_Quat* result);
	[CLink] public static extern void JPH_Quat_Multiply(JPH_Quat* q1, JPH_Quat* q2, JPH_Quat* result);
	[CLink] public static extern void JPH_Quat_MultiplyScalar(JPH_Quat* q, float scalar, JPH_Quat* result);
	[CLink] public static extern void JPH_Quat_DivideScalar(JPH_Quat* q, float scalar, JPH_Quat* result);
	[CLink] public static extern void JPH_Quat_Dot(JPH_Quat* q1, JPH_Quat* q2, float* result);

	[CLink] public static extern void JPH_Quat_Conjugated(JPH_Quat* quat, JPH_Quat* result);
	[CLink] public static extern void JPH_Quat_GetTwist(JPH_Quat* quat, JPH_Vec3* axis, JPH_Quat* result);
	[CLink] public static extern void JPH_Quat_GetSwingTwist(JPH_Quat* quat, JPH_Quat* outSwing, JPH_Quat* outTwist);
	[CLink] public static extern void JPH_Quat_Lerp(JPH_Quat* from, JPH_Quat* to, float fraction, JPH_Quat* result);
	[CLink] public static extern void JPH_Quat_Slerp(JPH_Quat* from, JPH_Quat* to, float fraction, JPH_Quat* result);
	[CLink] public static extern void JPH_Quat_Rotate(JPH_Quat* quat, JPH_Vec3* vec, JPH_Vec3* result);
	[CLink] public static extern void JPH_Quat_InverseRotate(JPH_Quat* quat, JPH_Vec3* vec, JPH_Vec3* result);

	[CLink] public static extern void JPH_Vec3_AxisX(JPH_Vec3* result);
	[CLink] public static extern void JPH_Vec3_AxisY(JPH_Vec3* result);
	[CLink] public static extern void JPH_Vec3_AxisZ(JPH_Vec3* result);
	[CLink] public static extern bool JPH_Vec3_IsClose(JPH_Vec3* v1, JPH_Vec3* v2, float maxDistSq);
	[CLink] public static extern bool JPH_Vec3_IsNearZero(JPH_Vec3* v, float maxDistSq);
	[CLink] public static extern bool JPH_Vec3_IsNormalized(JPH_Vec3* v, float tolerance);
	[CLink] public static extern bool JPH_Vec3_IsNaN(JPH_Vec3* v);

	[CLink] public static extern void JPH_Vec3_Negate(JPH_Vec3* v, JPH_Vec3* result);
	[CLink] public static extern void JPH_Vec3_Normalized(JPH_Vec3* v, JPH_Vec3* result);
	[CLink] public static extern void JPH_Vec3_Cross(JPH_Vec3* v1, JPH_Vec3* v2, JPH_Vec3* result);
	[CLink] public static extern void JPH_Vec3_Abs(JPH_Vec3* v, JPH_Vec3* result);

	[CLink] public static extern float JPH_Vec3_Length(JPH_Vec3* v);
	[CLink] public static extern float JPH_Vec3_LengthSquared(JPH_Vec3* v);

	[CLink] public static extern void JPH_Vec3_DotProduct(JPH_Vec3* v1, JPH_Vec3* v2, float* result);
	[CLink] public static extern void JPH_Vec3_Normalize(JPH_Vec3* v, JPH_Vec3* result);

	[CLink] public static extern void JPH_Vec3_Add(JPH_Vec3* v1, JPH_Vec3* v2, JPH_Vec3* result);
	[CLink] public static extern void JPH_Vec3_Subtract(JPH_Vec3* v1, JPH_Vec3* v2, JPH_Vec3* result);
	[CLink] public static extern void JPH_Vec3_Multiply(JPH_Vec3* v1, JPH_Vec3* v2, JPH_Vec3* result);
	[CLink] public static extern void JPH_Vec3_MultiplyScalar(JPH_Vec3* v, float scalar, JPH_Vec3* result);
	[CLink] public static extern void JPH_Vec3_MultiplyMatrix(JPH_Mat4* left, JPH_Vec3* right, JPH_Vec3* result);

	[CLink] public static extern void JPH_Vec3_Divide(JPH_Vec3* v1, JPH_Vec3* v2, JPH_Vec3* result);
	[CLink] public static extern void JPH_Vec3_DivideScalar(JPH_Vec3* v, float scalar, JPH_Vec3* result);

	[CLink] public static extern void JPH_Mat4_Add(JPH_Mat4* m1, JPH_Mat4* m2, JPH_Mat4* result);
	[CLink] public static extern void JPH_Mat4_Subtract(JPH_Mat4* m1, JPH_Mat4* m2, JPH_Mat4* result);
	[CLink] public static extern void JPH_Mat4_Multiply(JPH_Mat4* m1, JPH_Mat4* m2, JPH_Mat4* result);
	[CLink] public static extern void JPH_Mat4_MultiplyScalar(JPH_Mat4* m, float scalar, JPH_Mat4* result);

	[CLink] public static extern void JPH_Mat4_Zero(JPH_Mat4* result);
	[CLink] public static extern void JPH_Mat4_Identity(JPH_Mat4* result);
	[CLink] public static extern void JPH_Mat4_Rotation(JPH_Mat4* result, JPH_Quat* rotation);
	[CLink] public static extern void JPH_Mat4_Rotation2(JPH_Mat4* result, JPH_Vec3* axis, float angle);
	[CLink] public static extern void JPH_Mat4_Translation(JPH_Mat4* result, JPH_Vec3* translation);
	[CLink] public static extern void JPH_Mat4_RotationTranslation(JPH_Mat4* result, JPH_Quat* rotation, JPH_Vec3* translation);
	[CLink] public static extern void JPH_Mat4_InverseRotationTranslation(JPH_Mat4* result, JPH_Quat* rotation, JPH_Vec3* translation);
	[CLink] public static extern void JPH_Mat4_Scale(JPH_Mat4* result, JPH_Vec3* scale);
	[CLink] public static extern void JPH_Mat4_Transposed(JPH_Mat4* m, JPH_Mat4* result);
	[CLink] public static extern void JPH_Mat4_Inversed(JPH_Mat4* matrix, JPH_Mat4* result);

	[CLink] public static extern void JPH_Mat4_GetAxisX(JPH_Mat4* matrix, JPH_Vec3* result);
	[CLink] public static extern void JPH_Mat4_GetAxisY(JPH_Mat4* matrix, JPH_Vec3* result);
	[CLink] public static extern void JPH_Mat4_GetAxisZ(JPH_Mat4* matrix, JPH_Vec3* result);
	[CLink] public static extern void JPH_Mat4_GetTranslation(JPH_Mat4* matrix, JPH_Vec3* result);
	[CLink] public static extern void JPH_Mat4_GetQuaternion(JPH_Mat4* matrix, JPH_Quat* result);

	//#if defined(JPH_DOUBLE_PRECISION)
	//[CLink] public static extern void JPH_RMat4_Zero(JPH_RMat4* result);
	//[CLink] public static extern void JPH_RMat4_Identity(JPH_RMat4* result);
	//[CLink] public static extern void JPH_RMat4_Rotation(JPH_RMat4* result, JPH_Quat* rotation);
	//[CLink] public static extern void JPH_RMat4_Translation(JPH_RMat4* result, JPH_RVec3* translation);
	//[CLink] public static extern void JPH_RMat4_RotationTranslation(JPH_RMat4* result, JPH_Quat* rotation, JPH_RVec3* translation);
	//[CLink] public static extern void JPH_RMat4_InverseRotationTranslation(JPH_RMat4* result, JPH_Quat* rotation, JPH_RVec3* translation);
	//[CLink] public static extern void JPH_RMat4_Scale(JPH_RMat4* result, JPH_Vec3* scale);
	//[CLink] public static extern void JPH_RMat4_Inversed(JPH_RMat4* m, JPH_RMat4* result);
	//#endif /* defined(JPH_DOUBLE_PRECISION) */

	/* Material */
	[CLink] public static extern JPH_PhysicsMaterial* JPH_PhysicsMaterial_Create(char8* name, uint32 color);
	[CLink] public static extern void JPH_PhysicsMaterial_Destroy(JPH_PhysicsMaterial* material);
	[CLink] public static extern char8* JPH_PhysicsMaterial_GetDebugName(JPH_PhysicsMaterial* material);
	[CLink] public static extern uint32 JPH_PhysicsMaterial_GetDebugColor(JPH_PhysicsMaterial* material);

	/* GroupFilter/GroupFilterTable */
	[CLink] public static extern void JPH_GroupFilter_Destroy(JPH_GroupFilter* groupFilter);
	[CLink] public static extern bool JPH_GroupFilter_CanCollide(JPH_GroupFilter* groupFilter, JPH_CollisionGroup* group1, JPH_CollisionGroup* group2);

	[CLink] public static extern JPH_GroupFilterTable* JPH_GroupFilterTable_Create(uint32 numSubGroups /* = 0*/);
	[CLink] public static extern void JPH_GroupFilterTable_DisableCollision(JPH_GroupFilterTable* table, JPH_CollisionSubGroupID subGroup1, JPH_CollisionSubGroupID subGroup2);
	[CLink] public static extern void JPH_GroupFilterTable_EnableCollision(JPH_GroupFilterTable* table, JPH_CollisionSubGroupID subGroup1, JPH_CollisionSubGroupID subGroup2);
	[CLink] public static extern bool JPH_GroupFilterTable_IsCollisionEnabled(JPH_GroupFilterTable* table, JPH_CollisionSubGroupID subGroup1, JPH_CollisionSubGroupID subGroup2);

	/* ShapeSettings */
	[CLink] public static extern void JPH_ShapeSettings_Destroy(JPH_ShapeSettings* settings);
	[CLink] public static extern uint64 JPH_ShapeSettings_GetUserData(JPH_ShapeSettings* settings);
	[CLink] public static extern void JPH_ShapeSettings_SetUserData(JPH_ShapeSettings* settings, uint64 userData);

	/* Shape */
	[CLink] public static extern void JPH_Shape_Draw(JPH_Shape* shape, JPH_DebugRenderer* renderer, JPH_RMat4* centerOfMassTransform, JPH_Vec3* scale, JPH_Color color, bool useMaterialColors, bool drawWireframe);
	[CLink] public static extern void JPH_Shape_Destroy(JPH_Shape* shape);
	[CLink] public static extern JPH_ShapeType JPH_Shape_GetType(JPH_Shape* shape);
	[CLink] public static extern JPH_ShapeSubType JPH_Shape_GetSubType(JPH_Shape* shape);
	[CLink] public static extern uint64 JPH_Shape_GetUserData(JPH_Shape* shape);
	[CLink] public static extern void JPH_Shape_SetUserData(JPH_Shape* shape, uint64 userData);
	[CLink] public static extern bool JPH_Shape_MustBeStatic(JPH_Shape* shape);
	[CLink] public static extern void JPH_Shape_GetCenterOfMass(JPH_Shape* shape, JPH_Vec3* result);
	[CLink] public static extern void JPH_Shape_GetLocalBounds(JPH_Shape* shape, JPH_AABox* result);
	[CLink] public static extern uint32 JPH_Shape_GetSubShapeIDBitsRecursive(JPH_Shape* shape);
	[CLink] public static extern void JPH_Shape_GetWorldSpaceBounds(JPH_Shape* shape, JPH_RMat4* centerOfMassTransform, JPH_Vec3* scale, JPH_AABox* result);
	[CLink] public static extern float JPH_Shape_GetInnerRadius(JPH_Shape* shape);
	[CLink] public static extern void JPH_Shape_GetMassProperties(JPH_Shape* shape, JPH_MassProperties* result);
	[CLink] public static extern JPH_Shape* JPH_Shape_GetLeafShape(JPH_Shape* shape, JPH_SubShapeID subShapeID, JPH_SubShapeID* remainder);
	[CLink] public static extern JPH_PhysicsMaterial* JPH_Shape_GetMaterial(JPH_Shape* shape, JPH_SubShapeID subShapeID);
	[CLink] public static extern void JPH_Shape_GetSurfaceNormal(JPH_Shape* shape, JPH_SubShapeID subShapeID, JPH_Vec3* localPosition, JPH_Vec3* normal);
	[CLink] public static extern void JPH_Shape_GetSupportingFace(JPH_Shape* shape, JPH_SubShapeID subShapeID, JPH_Vec3* direction, JPH_Vec3* scale, JPH_Mat4* centerOfMassTransform, JPH_SupportingFace* outVertices);
	[CLink] public static extern float JPH_Shape_GetVolume(JPH_Shape* shape);
	[CLink] public static extern bool JPH_Shape_IsValidScale(JPH_Shape* shape, JPH_Vec3* scale);
	[CLink] public static extern void JPH_Shape_MakeScaleValid(JPH_Shape* shape, JPH_Vec3* scale, JPH_Vec3* result);
	[CLink] public static extern JPH_Shape* JPH_Shape_ScaleShape(JPH_Shape* shape, JPH_Vec3* scale);
	[CLink] public static extern bool JPH_Shape_CastRay(JPH_Shape* shape, JPH_Vec3* origin, JPH_Vec3* direction, JPH_RayCastResult* hit);
	[CLink] public static extern bool JPH_Shape_CastRay2(JPH_Shape* shape, JPH_Vec3* origin, JPH_Vec3* direction, JPH_RayCastSettings* rayCastSettings, JPH_CollisionCollectorType collectorType, JPH_CastRayResultCallback* callback, void* userData, JPH_ShapeFilter* shapeFilter);
	[CLink] public static extern bool JPH_Shape_CollidePoint(JPH_Shape* shape, JPH_Vec3* point, JPH_ShapeFilter* shapeFilter);
	[CLink] public static extern bool JPH_Shape_CollidePoint2(JPH_Shape* shape, JPH_Vec3* point, JPH_CollisionCollectorType collectorType, JPH_CollidePointResultCallback* callback, void* userData, JPH_ShapeFilter* shapeFilter);

	/* JPH_ConvexShape */
	[CLink] public static extern float JPH_ConvexShapeSettings_GetDensity(JPH_ConvexShapeSettings* shape);
	[CLink] public static extern void JPH_ConvexShapeSettings_SetDensity(JPH_ConvexShapeSettings* shape, float value);
	[CLink] public static extern float JPH_ConvexShape_GetDensity(JPH_ConvexShape* shape);
	[CLink] public static extern void JPH_ConvexShape_SetDensity(JPH_ConvexShape* shape, float inDensity);

	/* BoxShape */
	[CLink] public static extern JPH_BoxShapeSettings* JPH_BoxShapeSettings_Create(JPH_Vec3* halfExtent, float convexRadius);
	[CLink] public static extern JPH_BoxShape* JPH_BoxShapeSettings_CreateShape(JPH_BoxShapeSettings* settings);

	[CLink] public static extern JPH_BoxShape* JPH_BoxShape_Create(JPH_Vec3* halfExtent, float convexRadius);
	[CLink] public static extern void JPH_BoxShape_GetHalfExtent(JPH_BoxShape* shape, JPH_Vec3* halfExtent);
	[CLink] public static extern float JPH_BoxShape_GetConvexRadius(JPH_BoxShape* shape);

	/* SphereShape */
	[CLink] public static extern JPH_SphereShapeSettings* JPH_SphereShapeSettings_Create(float radius);
	[CLink] public static extern JPH_SphereShape* JPH_SphereShapeSettings_CreateShape(JPH_SphereShapeSettings* settings);

	[CLink] public static extern float JPH_SphereShapeSettings_GetRadius(JPH_SphereShapeSettings* settings);
	[CLink] public static extern void JPH_SphereShapeSettings_SetRadius(JPH_SphereShapeSettings* settings, float radius);
	[CLink] public static extern JPH_SphereShape* JPH_SphereShape_Create(float radius);
	[CLink] public static extern float JPH_SphereShape_GetRadius(JPH_SphereShape* shape);

	/* PlaneShape */
	[CLink] public static extern JPH_PlaneShapeSettings* JPH_PlaneShapeSettings_Create(JPH_Plane* plane, JPH_PhysicsMaterial* material, float halfExtent);
	[CLink] public static extern JPH_PlaneShape* JPH_PlaneShapeSettings_CreateShape(JPH_PlaneShapeSettings* settings);
	[CLink] public static extern JPH_PlaneShape* JPH_PlaneShape_Create(JPH_Plane* plane, JPH_PhysicsMaterial* material, float halfExtent);
	[CLink] public static extern void JPH_PlaneShape_GetPlane(JPH_PlaneShape* shape, JPH_Plane* result);
	[CLink] public static extern float JPH_PlaneShape_GetHalfExtent(JPH_PlaneShape* shape);

	/* TriangleShape */
	[CLink] public static extern JPH_TriangleShapeSettings* JPH_TriangleShapeSettings_Create(JPH_Vec3* v1, JPH_Vec3* v2, JPH_Vec3* v3, float convexRadius);
	[CLink] public static extern JPH_TriangleShape* JPH_TriangleShapeSettings_CreateShape(JPH_TriangleShapeSettings* settings);

	[CLink] public static extern JPH_TriangleShape* JPH_TriangleShape_Create(JPH_Vec3* v1, JPH_Vec3* v2, JPH_Vec3* v3, float convexRadius);
	[CLink] public static extern float JPH_TriangleShape_GetConvexRadius(JPH_TriangleShape* shape);
	[CLink] public static extern void JPH_TriangleShape_GetVertex1(JPH_TriangleShape* shape, JPH_Vec3* result);
	[CLink] public static extern void JPH_TriangleShape_GetVertex2(JPH_TriangleShape* shape, JPH_Vec3* result);
	[CLink] public static extern void JPH_TriangleShape_GetVertex3(JPH_TriangleShape* shape, JPH_Vec3* result);

	/* CapsuleShape */
	[CLink] public static extern JPH_CapsuleShapeSettings* JPH_CapsuleShapeSettings_Create(float halfHeightOfCylinder, float radius);
	[CLink] public static extern JPH_CapsuleShape* JPH_CapsuleShapeSettings_CreateShape(JPH_CapsuleShapeSettings* settings);
	[CLink] public static extern JPH_CapsuleShape* JPH_CapsuleShape_Create(float halfHeightOfCylinder, float radius);
	[CLink] public static extern float JPH_CapsuleShape_GetRadius(JPH_CapsuleShape* shape);
	[CLink] public static extern float JPH_CapsuleShape_GetHalfHeightOfCylinder(JPH_CapsuleShape* shape);

	/* CylinderShape */
	[CLink] public static extern JPH_CylinderShapeSettings* JPH_CylinderShapeSettings_Create(float halfHeight, float radius, float convexRadius);
	[CLink] public static extern JPH_CylinderShape* JPH_CylinderShapeSettings_CreateShape(JPH_CylinderShapeSettings* settings);

	[CLink] public static extern JPH_CylinderShape* JPH_CylinderShape_Create(float halfHeight, float radius);
	[CLink] public static extern float JPH_CylinderShape_GetRadius(JPH_CylinderShape* shape);
	[CLink] public static extern float JPH_CylinderShape_GetHalfHeight(JPH_CylinderShape* shape);

	/* TaperedCylinderShape */
	[CLink] public static extern JPH_TaperedCylinderShapeSettings* JPH_TaperedCylinderShapeSettings_Create(float halfHeightOfTaperedCylinder, float topRadius, float bottomRadius, float convexRadius /* = cDefaultConvexRadius*/, JPH_PhysicsMaterial* material /* = NULL*/);
	[CLink] public static extern JPH_TaperedCylinderShape* JPH_TaperedCylinderShapeSettings_CreateShape(JPH_TaperedCylinderShapeSettings* settings);
	[CLink] public static extern float JPH_TaperedCylinderShape_GetTopRadius(JPH_TaperedCylinderShape* shape);
	[CLink] public static extern float JPH_TaperedCylinderShape_GetBottomRadius(JPH_TaperedCylinderShape* shape);
	[CLink] public static extern float JPH_TaperedCylinderShape_GetConvexRadius(JPH_TaperedCylinderShape* shape);
	[CLink] public static extern float JPH_TaperedCylinderShape_GetHalfHeight(JPH_TaperedCylinderShape* shape);

	/* ConvexHullShape */
	[CLink] public static extern JPH_ConvexHullShapeSettings* JPH_ConvexHullShapeSettings_Create(JPH_Vec3* points, uint32 pointsCount, float maxConvexRadius);
	[CLink] public static extern JPH_ConvexHullShape* JPH_ConvexHullShapeSettings_CreateShape(JPH_ConvexHullShapeSettings* settings);
	[CLink] public static extern uint32 JPH_ConvexHullShape_GetNumPoints(JPH_ConvexHullShape* shape);
	[CLink] public static extern void JPH_ConvexHullShape_GetPoint(JPH_ConvexHullShape* shape, uint32 index, JPH_Vec3* result);
	[CLink] public static extern uint32 JPH_ConvexHullShape_GetNumFaces(JPH_ConvexHullShape* shape);
	[CLink] public static extern uint32 JPH_ConvexHullShape_GetNumVerticesInFace(JPH_ConvexHullShape* shape, uint32 faceIndex);
	[CLink] public static extern uint32 JPH_ConvexHullShape_GetFaceVertices(JPH_ConvexHullShape* shape, uint32 faceIndex, uint32 maxVertices, uint32* vertices);

	/* MeshShape */
	[CLink] public static extern JPH_MeshShapeSettings* JPH_MeshShapeSettings_Create(JPH_Triangle* triangles, uint32 triangleCount);
	[CLink] public static extern JPH_MeshShapeSettings* JPH_MeshShapeSettings_Create2(JPH_Vec3* vertices, uint32 verticesCount, JPH_IndexedTriangle* triangles, uint32 triangleCount);
	[CLink] public static extern uint32 JPH_MeshShapeSettings_GetMaxTrianglesPerLeaf(JPH_MeshShapeSettings* settings);
	[CLink] public static extern void JPH_MeshShapeSettings_SetMaxTrianglesPerLeaf(JPH_MeshShapeSettings* settings, uint32 value);
	[CLink] public static extern float JPH_MeshShapeSettings_GetActiveEdgeCosThresholdAngle(JPH_MeshShapeSettings* settings);
	[CLink] public static extern void JPH_MeshShapeSettings_SetActiveEdgeCosThresholdAngle(JPH_MeshShapeSettings* settings, float value);
	[CLink] public static extern bool JPH_MeshShapeSettings_GetPerTriangleUserData(JPH_MeshShapeSettings* settings);
	[CLink] public static extern void JPH_MeshShapeSettings_SetPerTriangleUserData(JPH_MeshShapeSettings* settings, bool value);
	[CLink] public static extern JPH_Mesh_Shape_BuildQuality JPH_MeshShapeSettings_GetBuildQuality(JPH_MeshShapeSettings* settings);
	[CLink] public static extern void JPH_MeshShapeSettings_SetBuildQuality(JPH_MeshShapeSettings* settings, JPH_Mesh_Shape_BuildQuality value);

	[CLink] public static extern void JPH_MeshShapeSettings_Sanitize(JPH_MeshShapeSettings* settings);
	[CLink] public static extern JPH_MeshShape* JPH_MeshShapeSettings_CreateShape(JPH_MeshShapeSettings* settings);
	[CLink] public static extern uint32 JPH_MeshShape_GetTriangleUserData(JPH_MeshShape* shape, JPH_SubShapeID id);

	/* HeightFieldShape */
	[CLink] public static extern JPH_HeightFieldShapeSettings* JPH_HeightFieldShapeSettings_Create(float* samples, JPH_Vec3* offset, JPH_Vec3* scale, uint32 sampleCount, uint8* materialIndices);
	[CLink] public static extern void JPH_HeightFieldShapeSettings_DetermineMinAndMaxSample(JPH_HeightFieldShapeSettings* settings, float* pOutMinValue, float* pOutMaxValue, float* pOutQuantizationScale);
	[CLink] public static extern uint32 JPH_HeightFieldShapeSettings_CalculateBitsPerSampleForError(JPH_HeightFieldShapeSettings* settings, float maxError);
	[CLink] public static extern void JPH_HeightFieldShapeSettings_GetOffset(JPH_HeightFieldShapeSettings* shape, JPH_Vec3* result);
	[CLink] public static extern void JPH_HeightFieldShapeSettings_SetOffset(JPH_HeightFieldShapeSettings* settings, JPH_Vec3* value);
	[CLink] public static extern void JPH_HeightFieldShapeSettings_GetScale(JPH_HeightFieldShapeSettings* shape, JPH_Vec3* result);
	[CLink] public static extern void JPH_HeightFieldShapeSettings_SetScale(JPH_HeightFieldShapeSettings* settings, JPH_Vec3* value);
	[CLink] public static extern uint32 JPH_HeightFieldShapeSettings_GetSampleCount(JPH_HeightFieldShapeSettings* settings);
	[CLink] public static extern void JPH_HeightFieldShapeSettings_SetSampleCount(JPH_HeightFieldShapeSettings* settings, uint32 value);
	[CLink] public static extern float JPH_HeightFieldShapeSettings_GetMinHeightValue(JPH_HeightFieldShapeSettings* settings);
	[CLink] public static extern void JPH_HeightFieldShapeSettings_SetMinHeightValue(JPH_HeightFieldShapeSettings* settings, float value);
	[CLink] public static extern float JPH_HeightFieldShapeSettings_GetMaxHeightValue(JPH_HeightFieldShapeSettings* settings);
	[CLink] public static extern void JPH_HeightFieldShapeSettings_SetMaxHeightValue(JPH_HeightFieldShapeSettings* settings, float value);
	[CLink] public static extern uint32 JPH_HeightFieldShapeSettings_GetBlockSize(JPH_HeightFieldShapeSettings* settings);
	[CLink] public static extern void JPH_HeightFieldShapeSettings_SetBlockSize(JPH_HeightFieldShapeSettings* settings, uint32 value);
	[CLink] public static extern uint32 JPH_HeightFieldShapeSettings_GetBitsPerSample(JPH_HeightFieldShapeSettings* settings);
	[CLink] public static extern void JPH_HeightFieldShapeSettings_SetBitsPerSample(JPH_HeightFieldShapeSettings* settings, uint32 value);
	[CLink] public static extern float JPH_HeightFieldShapeSettings_GetActiveEdgeCosThresholdAngle(JPH_HeightFieldShapeSettings* settings);
	[CLink] public static extern void JPH_HeightFieldShapeSettings_SetActiveEdgeCosThresholdAngle(JPH_HeightFieldShapeSettings* settings, float value);
	[CLink] public static extern JPH_HeightFieldShape* JPH_HeightFieldShapeSettings_CreateShape(JPH_HeightFieldShapeSettings* settings);

	[CLink] public static extern uint32 JPH_HeightFieldShape_GetSampleCount(JPH_HeightFieldShape* shape);
	[CLink] public static extern uint32 JPH_HeightFieldShape_GetBlockSize(JPH_HeightFieldShape* shape);
	[CLink] public static extern JPH_PhysicsMaterial* JPH_HeightFieldShape_GetMaterial(JPH_HeightFieldShape* shape, uint32 x, uint32 y);
	[CLink] public static extern void JPH_HeightFieldShape_GetPosition(JPH_HeightFieldShape* shape, uint32 x, uint32 y, JPH_Vec3* result);
	[CLink] public static extern bool JPH_HeightFieldShape_IsNoCollision(JPH_HeightFieldShape* shape, uint32 x, uint32 y);
	[CLink] public static extern bool JPH_HeightFieldShape_ProjectOntoSurface(JPH_HeightFieldShape* shape, JPH_Vec3* localPosition, JPH_Vec3* outSurfacePosition, JPH_SubShapeID* outSubShapeID);
	[CLink] public static extern float JPH_HeightFieldShape_GetMinHeightValue(JPH_HeightFieldShape* shape);
	[CLink] public static extern float JPH_HeightFieldShape_GetMaxHeightValue(JPH_HeightFieldShape* shape);

	/* TaperedCapsuleShape */
	[CLink] public static extern JPH_TaperedCapsuleShapeSettings* JPH_TaperedCapsuleShapeSettings_Create(float halfHeightOfTaperedCylinder, float topRadius, float bottomRadius);
	[CLink] public static extern JPH_TaperedCapsuleShape* JPH_TaperedCapsuleShapeSettings_CreateShape(JPH_TaperedCapsuleShapeSettings* settings);

	[CLink] public static extern float JPH_TaperedCapsuleShape_GetTopRadius(JPH_TaperedCapsuleShape* shape);
	[CLink] public static extern float JPH_TaperedCapsuleShape_GetBottomRadius(JPH_TaperedCapsuleShape* shape);
	[CLink] public static extern float JPH_TaperedCapsuleShape_GetHalfHeight(JPH_TaperedCapsuleShape* shape);

	/* CompoundShape */
	[CLink] public static extern void JPH_CompoundShapeSettings_AddShape(JPH_CompoundShapeSettings* settings, JPH_Vec3* position, JPH_Quat* rotation, JPH_ShapeSettings* shapeSettings, uint32 userData);
	[CLink] public static extern void JPH_CompoundShapeSettings_AddShape2(JPH_CompoundShapeSettings* settings, JPH_Vec3* position, JPH_Quat* rotation, JPH_Shape* shape, uint32 userData);
	[CLink] public static extern uint32 JPH_CompoundShape_GetNumSubShapes(JPH_CompoundShape* shape);
	[CLink] public static extern void JPH_CompoundShape_GetSubShape(JPH_CompoundShape* shape, uint32 index, JPH_Shape** subShape, JPH_Vec3* positionCOM, JPH_Quat* rotation, uint32* userData);
	[CLink] public static extern uint32 JPH_CompoundShape_GetSubShapeIndexFromID(JPH_CompoundShape* shape, JPH_SubShapeID id, JPH_SubShapeID* remainder);

	/* StaticCompoundShape */
	[CLink] public static extern JPH_StaticCompoundShapeSettings* JPH_StaticCompoundShapeSettings_Create();
	[CLink] public static extern JPH_StaticCompoundShape* JPH_StaticCompoundShape_Create(JPH_StaticCompoundShapeSettings* settings);

	/* MutableCompoundShape */
	[CLink] public static extern JPH_MutableCompoundShapeSettings* JPH_MutableCompoundShapeSettings_Create();
	[CLink] public static extern JPH_MutableCompoundShape* JPH_MutableCompoundShape_Create(JPH_MutableCompoundShapeSettings* settings);

	[CLink] public static extern uint32 JPH_MutableCompoundShape_AddShape(JPH_MutableCompoundShape* shape, JPH_Vec3* position, JPH_Quat* rotation, JPH_Shape* child, uint32 userData /* = 0 */, uint32 index /* = UINT32_MAX */);
	[CLink] public static extern void JPH_MutableCompoundShape_RemoveShape(JPH_MutableCompoundShape* shape, uint32 index);
	[CLink] public static extern void JPH_MutableCompoundShape_ModifyShape(JPH_MutableCompoundShape* shape, uint32 index, JPH_Vec3* position, JPH_Quat* rotation);
	[CLink] public static extern void JPH_MutableCompoundShape_ModifyShape2(JPH_MutableCompoundShape* shape, uint32 index, JPH_Vec3* position, JPH_Quat* rotation, JPH_Shape* newShape);
	[CLink] public static extern void JPH_MutableCompoundShape_AdjustCenterOfMass(JPH_MutableCompoundShape* shape);

	/* DecoratedShape */
	[CLink] public static extern JPH_Shape* JPH_DecoratedShape_GetInnerShape(JPH_DecoratedShape* shape);

	/* RotatedTranslatedShape */
	[CLink] public static extern JPH_RotatedTranslatedShapeSettings* JPH_RotatedTranslatedShapeSettings_Create(JPH_Vec3* position, JPH_Quat* rotation, JPH_ShapeSettings* shapeSettings);
	[CLink] public static extern JPH_RotatedTranslatedShapeSettings* JPH_RotatedTranslatedShapeSettings_Create2(JPH_Vec3* position, JPH_Quat* rotation, JPH_Shape* shape);
	[CLink] public static extern JPH_RotatedTranslatedShape* JPH_RotatedTranslatedShapeSettings_CreateShape(JPH_RotatedTranslatedShapeSettings* settings);
	[CLink] public static extern JPH_RotatedTranslatedShape* JPH_RotatedTranslatedShape_Create(JPH_Vec3* position, JPH_Quat* rotation, JPH_Shape* shape);
	[CLink] public static extern void JPH_RotatedTranslatedShape_GetPosition(JPH_RotatedTranslatedShape* shape, JPH_Vec3* position);
	[CLink] public static extern void JPH_RotatedTranslatedShape_GetRotation(JPH_RotatedTranslatedShape* shape, JPH_Quat* rotation);

	/* ScaledShape */
	[CLink] public static extern JPH_ScaledShapeSettings* JPH_ScaledShapeSettings_Create(JPH_ShapeSettings* shapeSettings, JPH_Vec3* scale);
	[CLink] public static extern JPH_ScaledShapeSettings* JPH_ScaledShapeSettings_Create2(JPH_Shape* shape, JPH_Vec3* scale);
	[CLink] public static extern JPH_ScaledShape* JPH_ScaledShapeSettings_CreateShape(JPH_ScaledShapeSettings* settings);
	[CLink] public static extern JPH_ScaledShape* JPH_ScaledShape_Create(JPH_Shape* shape, JPH_Vec3* scale);
	[CLink] public static extern void JPH_ScaledShape_GetScale(JPH_ScaledShape* shape, JPH_Vec3* result);

	/* OffsetCenterOfMassShape */
	[CLink] public static extern JPH_OffsetCenterOfMassShapeSettings* JPH_OffsetCenterOfMassShapeSettings_Create(JPH_Vec3* offset, JPH_ShapeSettings* shapeSettings);
	[CLink] public static extern JPH_OffsetCenterOfMassShapeSettings* JPH_OffsetCenterOfMassShapeSettings_Create2(JPH_Vec3* offset, JPH_Shape* shape);
	[CLink] public static extern JPH_OffsetCenterOfMassShape* JPH_OffsetCenterOfMassShapeSettings_CreateShape(JPH_OffsetCenterOfMassShapeSettings* settings);

	[CLink] public static extern JPH_OffsetCenterOfMassShape* JPH_OffsetCenterOfMassShape_Create(JPH_Vec3* offset, JPH_Shape* shape);
	[CLink] public static extern void JPH_OffsetCenterOfMassShape_GetOffset(JPH_OffsetCenterOfMassShape* shape, JPH_Vec3* result);

	/* EmptyShape */
	[CLink] public static extern JPH_EmptyShapeSettings* JPH_EmptyShapeSettings_Create(JPH_Vec3* centerOfMass);
	[CLink] public static extern JPH_EmptyShape* JPH_EmptyShapeSettings_CreateShape(JPH_EmptyShapeSettings* settings);

	/* JPH_BodyCreationSettings */
	[CLink] public static extern JPH_BodyCreationSettings* JPH_BodyCreationSettings_Create();
	[CLink] public static extern JPH_BodyCreationSettings* JPH_BodyCreationSettings_Create2(JPH_ShapeSettings* settings,
		JPH_RVec3* position,
		JPH_Quat* rotation,
		JPH_MotionType motionType,
		JPH_ObjectLayer objectLayer);
	[CLink] public static extern JPH_BodyCreationSettings* JPH_BodyCreationSettings_Create3(JPH_Shape* shape,
		JPH_RVec3* position,
		JPH_Quat* rotation,
		JPH_MotionType motionType,
		JPH_ObjectLayer objectLayer);
	[CLink] public static extern void JPH_BodyCreationSettings_Destroy(JPH_BodyCreationSettings* settings);

	[CLink] public static extern void JPH_BodyCreationSettings_GetPosition(JPH_BodyCreationSettings* settings, JPH_RVec3* result);
	[CLink] public static extern void JPH_BodyCreationSettings_SetPosition(JPH_BodyCreationSettings* settings, JPH_RVec3* value);

	[CLink] public static extern void JPH_BodyCreationSettings_GetRotation(JPH_BodyCreationSettings* settings, JPH_Quat* result);
	[CLink] public static extern void JPH_BodyCreationSettings_SetRotation(JPH_BodyCreationSettings* settings, JPH_Quat* value);

	[CLink] public static extern void JPH_BodyCreationSettings_GetLinearVelocity(JPH_BodyCreationSettings* settings, JPH_Vec3* velocity);
	[CLink] public static extern void JPH_BodyCreationSettings_SetLinearVelocity(JPH_BodyCreationSettings* settings, JPH_Vec3* velocity);

	[CLink] public static extern void JPH_BodyCreationSettings_GetAngularVelocity(JPH_BodyCreationSettings* settings, JPH_Vec3* velocity);
	[CLink] public static extern void JPH_BodyCreationSettings_SetAngularVelocity(JPH_BodyCreationSettings* settings, JPH_Vec3* velocity);

	[CLink] public static extern uint64 JPH_BodyCreationSettings_GetUserData(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetUserData(JPH_BodyCreationSettings* settings, uint64 value);

	[CLink] public static extern JPH_ObjectLayer JPH_BodyCreationSettings_GetObjectLayer(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetObjectLayer(JPH_BodyCreationSettings* settings, JPH_ObjectLayer value);

	[CLink] public static extern void JPH_BodyCreationSettings_GetCollisionGroup(JPH_BodyCreationSettings* settings, JPH_CollisionGroup* result);
	[CLink] public static extern void JPH_BodyCreationSettings_SetCollisionGroup(JPH_BodyCreationSettings* settings, JPH_CollisionGroup* value);

	[CLink] public static extern JPH_MotionType JPH_BodyCreationSettings_GetMotionType(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetMotionType(JPH_BodyCreationSettings* settings, JPH_MotionType value);

	[CLink] public static extern JPH_AllowedDOFs JPH_BodyCreationSettings_GetAllowedDOFs(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetAllowedDOFs(JPH_BodyCreationSettings* settings, JPH_AllowedDOFs value);

	[CLink] public static extern bool JPH_BodyCreationSettings_GetAllowDynamicOrKinematic(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetAllowDynamicOrKinematic(JPH_BodyCreationSettings* settings, bool value);

	[CLink] public static extern bool JPH_BodyCreationSettings_GetIsSensor(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetIsSensor(JPH_BodyCreationSettings* settings, bool value);

	[CLink] public static extern bool JPH_BodyCreationSettings_GetCollideKinematicVsNonDynamic(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetCollideKinematicVsNonDynamic(JPH_BodyCreationSettings* settings, bool value);

	[CLink] public static extern bool JPH_BodyCreationSettings_GetUseManifoldReduction(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetUseManifoldReduction(JPH_BodyCreationSettings* settings, bool value);

	[CLink] public static extern bool JPH_BodyCreationSettings_GetApplyGyroscopicForce(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetApplyGyroscopicForce(JPH_BodyCreationSettings* settings, bool value);

	[CLink] public static extern JPH_MotionQuality JPH_BodyCreationSettings_GetMotionQuality(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetMotionQuality(JPH_BodyCreationSettings* settings, JPH_MotionQuality value);

	[CLink] public static extern bool JPH_BodyCreationSettings_GetEnhancedInternalEdgeRemoval(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetEnhancedInternalEdgeRemoval(JPH_BodyCreationSettings* settings, bool value);

	[CLink] public static extern bool JPH_BodyCreationSettings_GetAllowSleeping(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetAllowSleeping(JPH_BodyCreationSettings* settings, bool value);

	[CLink] public static extern float JPH_BodyCreationSettings_GetFriction(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetFriction(JPH_BodyCreationSettings* settings, float value);

	[CLink] public static extern float JPH_BodyCreationSettings_GetRestitution(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetRestitution(JPH_BodyCreationSettings* settings, float value);

	[CLink] public static extern float JPH_BodyCreationSettings_GetLinearDamping(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetLinearDamping(JPH_BodyCreationSettings* settings, float value);

	[CLink] public static extern float JPH_BodyCreationSettings_GetAngularDamping(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetAngularDamping(JPH_BodyCreationSettings* settings, float value);

	[CLink] public static extern float JPH_BodyCreationSettings_GetMaxLinearVelocity(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetMaxLinearVelocity(JPH_BodyCreationSettings* settings, float value);

	[CLink] public static extern float JPH_BodyCreationSettings_GetMaxAngularVelocity(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetMaxAngularVelocity(JPH_BodyCreationSettings* settings, float value);

	[CLink] public static extern float JPH_BodyCreationSettings_GetGravityFactor(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetGravityFactor(JPH_BodyCreationSettings* settings, float value);

	[CLink] public static extern uint32 JPH_BodyCreationSettings_GetNumVelocityStepsOverride(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetNumVelocityStepsOverride(JPH_BodyCreationSettings* settings, uint32 value);

	[CLink] public static extern uint32 JPH_BodyCreationSettings_GetNumPositionStepsOverride(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetNumPositionStepsOverride(JPH_BodyCreationSettings* settings, uint32 value);

	[CLink] public static extern JPH_OverrideMassProperties JPH_BodyCreationSettings_GetOverrideMassProperties(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetOverrideMassProperties(JPH_BodyCreationSettings* settings, JPH_OverrideMassProperties value);

	[CLink] public static extern float JPH_BodyCreationSettings_GetInertiaMultiplier(JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyCreationSettings_SetInertiaMultiplier(JPH_BodyCreationSettings* settings, float value);

	[CLink] public static extern void JPH_BodyCreationSettings_GetMassPropertiesOverride(JPH_BodyCreationSettings* settings, JPH_MassProperties* result);
	[CLink] public static extern void JPH_BodyCreationSettings_SetMassPropertiesOverride(JPH_BodyCreationSettings* settings, JPH_MassProperties* massProperties);

	/* JPH_SoftBodyCreationSettings */
	[CLink] public static extern JPH_SoftBodyCreationSettings* JPH_SoftBodyCreationSettings_Create();
	[CLink] public static extern void JPH_SoftBodyCreationSettings_Destroy(JPH_SoftBodyCreationSettings* settings);

	/* JPH_Constraint */
	[CLink] public static extern void JPH_Constraint_Destroy(JPH_Constraint* constraint);
	[CLink] public static extern JPH_ConstraintType JPH_Constraint_GetType(JPH_Constraint* constraint);
	[CLink] public static extern JPH_ConstraintSubType JPH_Constraint_GetSubType(JPH_Constraint* constraint);
	[CLink] public static extern uint32 JPH_Constraint_GetConstraintPriority(JPH_Constraint* constraint);
	[CLink] public static extern void JPH_Constraint_SetConstraintPriority(JPH_Constraint* constraint, uint32 priority);
	[CLink] public static extern uint32 JPH_Constraint_GetNumVelocityStepsOverride(JPH_Constraint* constraint);
	[CLink] public static extern void JPH_Constraint_SetNumVelocityStepsOverride(JPH_Constraint* constraint, uint32 value);
	[CLink] public static extern uint32 JPH_Constraint_GetNumPositionStepsOverride(JPH_Constraint* constraint);
	[CLink] public static extern void JPH_Constraint_SetNumPositionStepsOverride(JPH_Constraint* constraint, uint32 value);
	[CLink] public static extern bool JPH_Constraint_GetEnabled(JPH_Constraint* constraint);
	[CLink] public static extern void JPH_Constraint_SetEnabled(JPH_Constraint* constraint, bool enabled);
	[CLink] public static extern uint64 JPH_Constraint_GetUserData(JPH_Constraint* constraint);
	[CLink] public static extern void JPH_Constraint_SetUserData(JPH_Constraint* constraint, uint64 userData);
	[CLink] public static extern void JPH_Constraint_NotifyShapeChanged(JPH_Constraint* constraint, JPH_BodyID bodyID, JPH_Vec3* deltaCOM);
	[CLink] public static extern void JPH_Constraint_ResetWarmStart(JPH_Constraint* constraint);
	[CLink] public static extern bool JPH_Constraint_IsActive(JPH_Constraint* constraint);
	[CLink] public static extern void JPH_Constraint_SetupVelocityConstraint(JPH_Constraint* constraint, float deltaTime);
	[CLink] public static extern void JPH_Constraint_WarmStartVelocityConstraint(JPH_Constraint* constraint, float warmStartImpulseRatio);
	[CLink] public static extern bool JPH_Constraint_SolveVelocityConstraint(JPH_Constraint* constraint, float deltaTime);
	[CLink] public static extern bool JPH_Constraint_SolvePositionConstraint(JPH_Constraint* constraint, float deltaTime, float baumgarte);

	/* JPH_TwoBodyConstraint */
	[CLink] public static extern JPH_Body* JPH_TwoBodyConstraint_GetBody1(JPH_TwoBodyConstraint* constraint);
	[CLink] public static extern JPH_Body* JPH_TwoBodyConstraint_GetBody2(JPH_TwoBodyConstraint* constraint);
	[CLink] public static extern void JPH_TwoBodyConstraint_GetConstraintToBody1Matrix(JPH_TwoBodyConstraint* constraint, JPH_Mat4* result);
	[CLink] public static extern void JPH_TwoBodyConstraint_GetConstraintToBody2Matrix(JPH_TwoBodyConstraint* constraint, JPH_Mat4* result);

	/* JPH_FixedConstraint */
	[CLink] public static extern void JPH_FixedConstraintSettings_Init(JPH_FixedConstraintSettings* settings);
	[CLink] public static extern JPH_FixedConstraint* JPH_FixedConstraint_Create(JPH_FixedConstraintSettings* settings, JPH_Body* body1, JPH_Body* body2);
	[CLink] public static extern void JPH_FixedConstraint_GetSettings(JPH_FixedConstraint* constraint, JPH_FixedConstraintSettings* settings);
	[CLink] public static extern void JPH_FixedConstraint_GetTotalLambdaPosition(JPH_FixedConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_FixedConstraint_GetTotalLambdaRotation(JPH_FixedConstraint* constraint, JPH_Vec3* result);

	/* JPH_DistanceConstraint */
	[CLink] public static extern void JPH_DistanceConstraintSettings_Init(JPH_DistanceConstraintSettings* settings);
	[CLink] public static extern JPH_DistanceConstraint* JPH_DistanceConstraint_Create(JPH_DistanceConstraintSettings* settings, JPH_Body* body1, JPH_Body* body2);
	[CLink] public static extern void JPH_DistanceConstraint_GetSettings(JPH_DistanceConstraint* constraint, JPH_DistanceConstraintSettings* settings);
	[CLink] public static extern void JPH_DistanceConstraint_SetDistance(JPH_DistanceConstraint* constraint, float minDistance, float maxDistance);
	[CLink] public static extern float JPH_DistanceConstraint_GetMinDistance(JPH_DistanceConstraint* constraint);
	[CLink] public static extern float JPH_DistanceConstraint_GetMaxDistance(JPH_DistanceConstraint* constraint);
	[CLink] public static extern void JPH_DistanceConstraint_GetLimitsSpringSettings(JPH_DistanceConstraint* constraint, JPH_SpringSettings* result);
	[CLink] public static extern void JPH_DistanceConstraint_SetLimitsSpringSettings(JPH_DistanceConstraint* constraint, JPH_SpringSettings* settings);
	[CLink] public static extern float JPH_DistanceConstraint_GetTotalLambdaPosition(JPH_DistanceConstraint* constraint);

	/* JPH_PointConstraint */
	[CLink] public static extern void JPH_PointConstraintSettings_Init(JPH_PointConstraintSettings* settings);
	[CLink] public static extern JPH_PointConstraint* JPH_PointConstraint_Create(JPH_PointConstraintSettings* settings, JPH_Body* body1, JPH_Body* body2);
	[CLink] public static extern void JPH_PointConstraint_GetSettings(JPH_PointConstraint* constraint, JPH_PointConstraintSettings* settings);
	[CLink] public static extern void JPH_PointConstraint_SetPoint1(JPH_PointConstraint* constraint, JPH_ConstraintSpace space, JPH_RVec3* value);
	[CLink] public static extern void JPH_PointConstraint_SetPoint2(JPH_PointConstraint* constraint, JPH_ConstraintSpace space, JPH_RVec3* value);
	[CLink] public static extern void JPH_PointConstraint_GetLocalSpacePoint1(JPH_PointConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_PointConstraint_GetLocalSpacePoint2(JPH_PointConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_PointConstraint_GetTotalLambdaPosition(JPH_PointConstraint* constraint, JPH_Vec3* result);

	/* JPH_HingeConstraint */
	[CLink] public static extern void JPH_HingeConstraintSettings_Init(JPH_HingeConstraintSettings* settings);
	[CLink] public static extern JPH_HingeConstraint* JPH_HingeConstraint_Create(JPH_HingeConstraintSettings* settings, JPH_Body* body1, JPH_Body* body2);
	[CLink] public static extern void JPH_HingeConstraint_GetSettings(JPH_HingeConstraint* constraint, JPH_HingeConstraintSettings* settings);
	[CLink] public static extern void JPH_HingeConstraint_GetLocalSpacePoint1(JPH_HingeConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_HingeConstraint_GetLocalSpacePoint2(JPH_HingeConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_HingeConstraint_GetLocalSpaceHingeAxis1(JPH_HingeConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_HingeConstraint_GetLocalSpaceHingeAxis2(JPH_HingeConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_HingeConstraint_GetLocalSpaceNormalAxis1(JPH_HingeConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_HingeConstraint_GetLocalSpaceNormalAxis2(JPH_HingeConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern float JPH_HingeConstraint_GetCurrentAngle(JPH_HingeConstraint* constraint);
	[CLink] public static extern void JPH_HingeConstraint_SetMaxFrictionTorque(JPH_HingeConstraint* constraint, float frictionTorque);
	[CLink] public static extern float JPH_HingeConstraint_GetMaxFrictionTorque(JPH_HingeConstraint* constraint);
	[CLink] public static extern void JPH_HingeConstraint_SetMotorSettings(JPH_HingeConstraint* constraint, JPH_MotorSettings* settings);
	[CLink] public static extern void JPH_HingeConstraint_GetMotorSettings(JPH_HingeConstraint* constraint, JPH_MotorSettings* result);
	[CLink] public static extern void JPH_HingeConstraint_SetMotorState(JPH_HingeConstraint* constraint, JPH_MotorState state);
	[CLink] public static extern JPH_MotorState JPH_HingeConstraint_GetMotorState(JPH_HingeConstraint* constraint);
	[CLink] public static extern void JPH_HingeConstraint_SetTargetAngularVelocity(JPH_HingeConstraint* constraint, float angularVelocity);
	[CLink] public static extern float JPH_HingeConstraint_GetTargetAngularVelocity(JPH_HingeConstraint* constraint);
	[CLink] public static extern void JPH_HingeConstraint_SetTargetAngle(JPH_HingeConstraint* constraint, float angle);
	[CLink] public static extern float JPH_HingeConstraint_GetTargetAngle(JPH_HingeConstraint* constraint);
	[CLink] public static extern void JPH_HingeConstraint_SetLimits(JPH_HingeConstraint* constraint, float inLimitsMin, float inLimitsMax);
	[CLink] public static extern float JPH_HingeConstraint_GetLimitsMin(JPH_HingeConstraint* constraint);
	[CLink] public static extern float JPH_HingeConstraint_GetLimitsMax(JPH_HingeConstraint* constraint);
	[CLink] public static extern bool JPH_HingeConstraint_HasLimits(JPH_HingeConstraint* constraint);
	[CLink] public static extern void JPH_HingeConstraint_GetLimitsSpringSettings(JPH_HingeConstraint* constraint, JPH_SpringSettings* result);
	[CLink] public static extern void JPH_HingeConstraint_SetLimitsSpringSettings(JPH_HingeConstraint* constraint, JPH_SpringSettings* settings);
	[CLink] public static extern void JPH_HingeConstraint_GetTotalLambdaPosition(JPH_HingeConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_HingeConstraint_GetTotalLambdaRotation(JPH_HingeConstraint* constraint, float[2] rotation);
	[CLink] public static extern float JPH_HingeConstraint_GetTotalLambdaRotationLimits(JPH_HingeConstraint* constraint);
	[CLink] public static extern float JPH_HingeConstraint_GetTotalLambdaMotor(JPH_HingeConstraint* constraint);

	/* JPH_SliderConstraint */
	[CLink] public static extern void JPH_SliderConstraintSettings_Init(JPH_SliderConstraintSettings* settings);
	[CLink] public static extern void JPH_SliderConstraintSettings_SetSliderAxis(JPH_SliderConstraintSettings* settings, JPH_Vec3* axis);

	[CLink] public static extern JPH_SliderConstraint* JPH_SliderConstraint_Create(JPH_SliderConstraintSettings* settings, JPH_Body* body1, JPH_Body* body2);
	[CLink] public static extern void JPH_SliderConstraint_GetSettings(JPH_SliderConstraint* constraint, JPH_SliderConstraintSettings* settings);
	[CLink] public static extern float JPH_SliderConstraint_GetCurrentPosition(JPH_SliderConstraint* constraint);
	[CLink] public static extern void JPH_SliderConstraint_SetMaxFrictionForce(JPH_SliderConstraint* constraint, float frictionForce);
	[CLink] public static extern float JPH_SliderConstraint_GetMaxFrictionForce(JPH_SliderConstraint* constraint);
	[CLink] public static extern void JPH_SliderConstraint_SetMotorSettings(JPH_SliderConstraint* constraint, JPH_MotorSettings* settings);
	[CLink] public static extern void JPH_SliderConstraint_GetMotorSettings(JPH_SliderConstraint* constraint, JPH_MotorSettings* result);
	[CLink] public static extern void JPH_SliderConstraint_SetMotorState(JPH_SliderConstraint* constraint, JPH_MotorState state);
	[CLink] public static extern JPH_MotorState JPH_SliderConstraint_GetMotorState(JPH_SliderConstraint* constraint);
	[CLink] public static extern void JPH_SliderConstraint_SetTargetVelocity(JPH_SliderConstraint* constraint, float velocity);
	[CLink] public static extern float JPH_SliderConstraint_GetTargetVelocity(JPH_SliderConstraint* constraint);
	[CLink] public static extern void JPH_SliderConstraint_SetTargetPosition(JPH_SliderConstraint* constraint, float position);
	[CLink] public static extern float JPH_SliderConstraint_GetTargetPosition(JPH_SliderConstraint* constraint);
	[CLink] public static extern void JPH_SliderConstraint_SetLimits(JPH_SliderConstraint* constraint, float inLimitsMin, float inLimitsMax);
	[CLink] public static extern float JPH_SliderConstraint_GetLimitsMin(JPH_SliderConstraint* constraint);
	[CLink] public static extern float JPH_SliderConstraint_GetLimitsMax(JPH_SliderConstraint* constraint);
	[CLink] public static extern bool JPH_SliderConstraint_HasLimits(JPH_SliderConstraint* constraint);
	[CLink] public static extern void JPH_SliderConstraint_GetLimitsSpringSettings(JPH_SliderConstraint* constraint, JPH_SpringSettings* result);
	[CLink] public static extern void JPH_SliderConstraint_SetLimitsSpringSettings(JPH_SliderConstraint* constraint, JPH_SpringSettings* settings);
	[CLink] public static extern void JPH_SliderConstraint_GetTotalLambdaPosition(JPH_SliderConstraint* constraint, float[2] position);
	[CLink] public static extern float JPH_SliderConstraint_GetTotalLambdaPositionLimits(JPH_SliderConstraint* constraint);
	[CLink] public static extern void JPH_SliderConstraint_GetTotalLambdaRotation(JPH_SliderConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern float JPH_SliderConstraint_GetTotalLambdaMotor(JPH_SliderConstraint* constraint);

	/* JPH_ConeConstraint */
	[CLink] public static extern void JPH_ConeConstraintSettings_Init(JPH_ConeConstraintSettings* settings);
	[CLink] public static extern JPH_ConeConstraint* JPH_ConeConstraint_Create(JPH_ConeConstraintSettings* settings, JPH_Body* body1, JPH_Body* body2);
	[CLink] public static extern void JPH_ConeConstraint_GetSettings(JPH_ConeConstraint* constraint, JPH_ConeConstraintSettings* settings);
	[CLink] public static extern void JPH_ConeConstraint_SetHalfConeAngle(JPH_ConeConstraint* constraint, float halfConeAngle);
	[CLink] public static extern float JPH_ConeConstraint_GetCosHalfConeAngle(JPH_ConeConstraint* constraint);
	[CLink] public static extern void JPH_ConeConstraint_GetTotalLambdaPosition(JPH_ConeConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern float JPH_ConeConstraint_GetTotalLambdaRotation(JPH_ConeConstraint* constraint);

	/* JPH_SwingTwistConstraint */
	[CLink] public static extern void JPH_SwingTwistConstraintSettings_Init(JPH_SwingTwistConstraintSettings* settings);
	[CLink] public static extern JPH_SwingTwistConstraint* JPH_SwingTwistConstraint_Create(JPH_SwingTwistConstraintSettings* settings, JPH_Body* body1, JPH_Body* body2);
	[CLink] public static extern void JPH_SwingTwistConstraint_GetSettings(JPH_SwingTwistConstraint* constraint, JPH_SwingTwistConstraintSettings* settings);
	[CLink] public static extern float JPH_SwingTwistConstraint_GetNormalHalfConeAngle(JPH_SwingTwistConstraint* constraint);
	[CLink] public static extern void JPH_SwingTwistConstraint_GetTotalLambdaPosition(JPH_SwingTwistConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern float JPH_SwingTwistConstraint_GetTotalLambdaTwist(JPH_SwingTwistConstraint* constraint);
	[CLink] public static extern float JPH_SwingTwistConstraint_GetTotalLambdaSwingY(JPH_SwingTwistConstraint* constraint);
	[CLink] public static extern float JPH_SwingTwistConstraint_GetTotalLambdaSwingZ(JPH_SwingTwistConstraint* constraint);
	[CLink] public static extern void JPH_SwingTwistConstraint_GetTotalLambdaMotor(JPH_SwingTwistConstraint* constraint, JPH_Vec3* result);

	/* JPH_SixDOFConstraint */
	[CLink] public static extern void JPH_SixDOFConstraintSettings_Init(JPH_SixDOFConstraintSettings* settings);
	[CLink] public static extern void JPH_SixDOFConstraintSettings_MakeFreeAxis(JPH_SixDOFConstraintSettings* settings, JPH_SixDOFConstraintAxis axis);
	[CLink] public static extern bool JPH_SixDOFConstraintSettings_IsFreeAxis(JPH_SixDOFConstraintSettings* settings, JPH_SixDOFConstraintAxis axis);
	[CLink] public static extern void JPH_SixDOFConstraintSettings_MakeFixedAxis(JPH_SixDOFConstraintSettings* settings, JPH_SixDOFConstraintAxis axis);
	[CLink] public static extern bool JPH_SixDOFConstraintSettings_IsFixedAxis(JPH_SixDOFConstraintSettings* settings, JPH_SixDOFConstraintAxis axis);
	[CLink] public static extern void JPH_SixDOFConstraintSettings_SetLimitedAxis(JPH_SixDOFConstraintSettings* settings, JPH_SixDOFConstraintAxis axis, float min, float max);

	[CLink] public static extern JPH_SixDOFConstraint* JPH_SixDOFConstraint_Create(JPH_SixDOFConstraintSettings* settings, JPH_Body* body1, JPH_Body* body2);
	[CLink] public static extern void JPH_SixDOFConstraint_GetSettings(JPH_SixDOFConstraint* constraint, JPH_SixDOFConstraintSettings* settings);
	[CLink] public static extern float JPH_SixDOFConstraint_GetLimitsMin(JPH_SixDOFConstraint* constraint, JPH_SixDOFConstraintAxis axis);
	[CLink] public static extern float JPH_SixDOFConstraint_GetLimitsMax(JPH_SixDOFConstraint* constraint, JPH_SixDOFConstraintAxis axis);
	[CLink] public static extern void JPH_SixDOFConstraint_GetTotalLambdaPosition(JPH_SixDOFConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_SixDOFConstraint_GetTotalLambdaRotation(JPH_SixDOFConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_SixDOFConstraint_GetTotalLambdaMotorTranslation(JPH_SixDOFConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_SixDOFConstraint_GetTotalLambdaMotorRotation(JPH_SixDOFConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_SixDOFConstraint_GetTranslationLimitsMin(JPH_SixDOFConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_SixDOFConstraint_GetTranslationLimitsMax(JPH_SixDOFConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_SixDOFConstraint_GetRotationLimitsMin(JPH_SixDOFConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_SixDOFConstraint_GetRotationLimitsMax(JPH_SixDOFConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern bool JPH_SixDOFConstraint_IsFixedAxis(JPH_SixDOFConstraint* constraint, JPH_SixDOFConstraintAxis axis);
	[CLink] public static extern bool JPH_SixDOFConstraint_IsFreeAxis(JPH_SixDOFConstraint* constraint, JPH_SixDOFConstraintAxis axis);
	[CLink] public static extern void JPH_SixDOFConstraint_GetLimitsSpringSettings(JPH_SixDOFConstraint* constraint, JPH_SpringSettings* result, JPH_SixDOFConstraintAxis axis);
	[CLink] public static extern void JPH_SixDOFConstraint_SetLimitsSpringSettings(JPH_SixDOFConstraint* constraint, JPH_SpringSettings* settings, JPH_SixDOFConstraintAxis axis);
	[CLink] public static extern void JPH_SixDOFConstraint_SetMaxFriction(JPH_SixDOFConstraint* constraint, JPH_SixDOFConstraintAxis axis, float inFriction);
	[CLink] public static extern float JPH_SixDOFConstraint_GetMaxFriction(JPH_SixDOFConstraint* constraint, JPH_SixDOFConstraintAxis axis);
	[CLink] public static extern void JPH_SixDOFConstraint_GetRotationInConstraintSpace(JPH_SixDOFConstraint* constraint, JPH_Quat* result);
	[CLink] public static extern void JPH_SixDOFConstraint_GetMotorSettings(JPH_SixDOFConstraint* constraint, JPH_SixDOFConstraintAxis axis, JPH_MotorSettings* settings);
	[CLink] public static extern void JPH_SixDOFConstraint_SetMotorState(JPH_SixDOFConstraint* constraint, JPH_SixDOFConstraintAxis axis, JPH_MotorState state);
	[CLink] public static extern JPH_MotorState JPH_SixDOFConstraint_GetMotorState(JPH_SixDOFConstraint* constraint, JPH_SixDOFConstraintAxis axis);
	[CLink] public static extern void JPH_SixDOFConstraint_SetTargetVelocityCS(JPH_SixDOFConstraint* constraint, JPH_Vec3* inVelocity);
	[CLink] public static extern void JPH_SixDOFConstraint_GetTargetVelocityCS(JPH_SixDOFConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_SixDOFConstraint_SetTargetAngularVelocityCS(JPH_SixDOFConstraint* constraint, JPH_Vec3* inAngularVelocity);
	[CLink] public static extern void JPH_SixDOFConstraint_GetTargetAngularVelocityCS(JPH_SixDOFConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_SixDOFConstraint_SetTargetPositionCS(JPH_SixDOFConstraint* constraint, JPH_Vec3* inPosition);
	[CLink] public static extern void JPH_SixDOFConstraint_GetTargetPositionCS(JPH_SixDOFConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_SixDOFConstraint_SetTargetOrientationCS(JPH_SixDOFConstraint* constraint, JPH_Quat* inOrientation);
	[CLink] public static extern void JPH_SixDOFConstraint_GetTargetOrientationCS(JPH_SixDOFConstraint* constraint, JPH_Quat* result);
	[CLink] public static extern void JPH_SixDOFConstraint_SetTargetOrientationBS(JPH_SixDOFConstraint* constraint, JPH_Quat* inOrientation);

	/* JPH_GearConstraint */
	[CLink] public static extern void JPH_GearConstraintSettings_Init(JPH_GearConstraintSettings* settings);
	[CLink] public static extern JPH_GearConstraint* JPH_GearConstraint_Create(JPH_GearConstraintSettings* settings, JPH_Body* body1, JPH_Body* body2);
	[CLink] public static extern void JPH_GearConstraint_GetSettings(JPH_GearConstraint* constraint, JPH_GearConstraintSettings* settings);
	[CLink] public static extern void JPH_GearConstraint_SetConstraints(JPH_GearConstraint* constraint, JPH_Constraint* gear1, JPH_Constraint* gear2);
	[CLink] public static extern float JPH_GearConstraint_GetTotalLambda(JPH_GearConstraint* constraint);

	/* BodyInterface */
	[CLink] public static extern void JPH_BodyInterface_DestroyBody(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID);
	[CLink] public static extern JPH_BodyID JPH_BodyInterface_CreateAndAddBody(JPH_BodyInterface* bodyInterface, JPH_BodyCreationSettings* settings, JPH_Activation activationMode);
	[CLink] public static extern JPH_Body* JPH_BodyInterface_CreateBody(JPH_BodyInterface* bodyInterface, JPH_BodyCreationSettings* settings);
	[CLink] public static extern JPH_Body* JPH_BodyInterface_CreateBodyWithID(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID, JPH_BodyCreationSettings* settings);
	[CLink] public static extern JPH_Body* JPH_BodyInterface_CreateBodyWithoutID(JPH_BodyInterface* bodyInterface, JPH_BodyCreationSettings* settings);
	[CLink] public static extern void JPH_BodyInterface_DestroyBodyWithoutID(JPH_BodyInterface* bodyInterface, JPH_Body* body);
	[CLink] public static extern bool JPH_BodyInterface_AssignBodyID(JPH_BodyInterface* bodyInterface, JPH_Body* body);
	[CLink] public static extern bool JPH_BodyInterface_AssignBodyID2(JPH_BodyInterface* bodyInterface, JPH_Body* body, JPH_BodyID bodyID);
	[CLink] public static extern JPH_Body* JPH_BodyInterface_UnassignBodyID(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID);

	[CLink] public static extern JPH_Body* JPH_BodyInterface_CreateSoftBody(JPH_BodyInterface* bodyInterface, JPH_SoftBodyCreationSettings* settings);
	[CLink] public static extern JPH_Body* JPH_BodyInterface_CreateSoftBodyWithID(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID, JPH_SoftBodyCreationSettings* settings);
	[CLink] public static extern JPH_Body* JPH_BodyInterface_CreateSoftBodyWithoutID(JPH_BodyInterface* bodyInterface, JPH_SoftBodyCreationSettings* settings);
	[CLink] public static extern JPH_BodyID JPH_BodyInterface_CreateAndAddSoftBody(JPH_BodyInterface* bodyInterface, JPH_SoftBodyCreationSettings* settings, JPH_Activation activationMode);

	[CLink] public static extern void JPH_BodyInterface_AddBody(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID, JPH_Activation activationMode);
	[CLink] public static extern void JPH_BodyInterface_RemoveBody(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID);
	[CLink] public static extern void JPH_BodyInterface_RemoveAndDestroyBody(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID);
	[CLink] public static extern bool JPH_BodyInterface_IsAdded(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID);
	[CLink] public static extern JPH_BodyType JPH_BodyInterface_GetBodyType(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID);

	[CLink] public static extern void JPH_BodyInterface_SetLinearVelocity(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID, JPH_Vec3* velocity);
	[CLink] public static extern void JPH_BodyInterface_GetLinearVelocity(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID, JPH_Vec3* velocity);
	[CLink] public static extern void JPH_BodyInterface_GetCenterOfMassPosition(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID, JPH_RVec3* position);

	[CLink] public static extern JPH_MotionType JPH_BodyInterface_GetMotionType(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID);
	[CLink] public static extern void JPH_BodyInterface_SetMotionType(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID, JPH_MotionType motionType, JPH_Activation activationMode);

	[CLink] public static extern float JPH_BodyInterface_GetRestitution(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID);
	[CLink] public static extern void JPH_BodyInterface_SetRestitution(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID, float restitution);

	[CLink] public static extern float JPH_BodyInterface_GetFriction(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID);
	[CLink] public static extern void JPH_BodyInterface_SetFriction(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID, float friction);

	[CLink] public static extern void JPH_BodyInterface_SetPosition(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_RVec3* position, JPH_Activation activationMode);
	[CLink] public static extern void JPH_BodyInterface_GetPosition(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_RVec3* result);

	[CLink] public static extern void JPH_BodyInterface_SetRotation(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Quat* rotation, JPH_Activation activationMode);
	[CLink] public static extern void JPH_BodyInterface_GetRotation(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Quat* result);

	[CLink] public static extern void JPH_BodyInterface_SetPositionAndRotation(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_RVec3* position, JPH_Quat* rotation, JPH_Activation activationMode);
	[CLink] public static extern void JPH_BodyInterface_SetPositionAndRotationWhenChanged(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_RVec3* position, JPH_Quat* rotation, JPH_Activation activationMode);
	[CLink] public static extern void JPH_BodyInterface_GetPositionAndRotation(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_RVec3* position, JPH_Quat* rotation);
	[CLink] public static extern void JPH_BodyInterface_SetPositionRotationAndVelocity(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_RVec3* position, JPH_Quat* rotation, JPH_Vec3* linearVelocity, JPH_Vec3* angularVelocity);

	[CLink] public static extern void JPH_BodyInterface_GetCollisionGroup(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_CollisionGroup* result);
	[CLink] public static extern void JPH_BodyInterface_SetCollisionGroup(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_CollisionGroup* group);

	[CLink] public static extern JPH_Shape* JPH_BodyInterface_GetShape(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId);
	[CLink] public static extern void JPH_BodyInterface_SetShape(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Shape* shape, bool updateMassProperties, JPH_Activation activationMode);
	[CLink] public static extern void JPH_BodyInterface_NotifyShapeChanged(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* previousCenterOfMass, bool updateMassProperties, JPH_Activation activationMode);

	[CLink] public static extern void JPH_BodyInterface_ActivateBody(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId);
	[CLink] public static extern void JPH_BodyInterface_ActivateBodies(JPH_BodyInterface* bodyInterface, JPH_BodyID* bodyIDs, uint32 count);
	[CLink] public static extern void JPH_BodyInterface_ActivateBodiesInAABox(JPH_BodyInterface* bodyInterface, JPH_AABox* @box, JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter, JPH_ObjectLayerFilter* objectLayerFilter);
	[CLink] public static extern void JPH_BodyInterface_DeactivateBody(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId);
	[CLink] public static extern void JPH_BodyInterface_DeactivateBodies(JPH_BodyInterface* bodyInterface, JPH_BodyID* bodyIDs, uint32 count);
	[CLink] public static extern bool JPH_BodyInterface_IsActive(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID);
	[CLink] public static extern void JPH_BodyInterface_ResetSleepTimer(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyID);

	[CLink] public static extern JPH_ObjectLayer JPH_BodyInterface_GetObjectLayer(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId);
	[CLink] public static extern void JPH_BodyInterface_SetObjectLayer(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_ObjectLayer layer);

	[CLink] public static extern void JPH_BodyInterface_GetWorldTransform(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_RMat4* result);
	[CLink] public static extern void JPH_BodyInterface_GetCenterOfMassTransform(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_RMat4* result);

	[CLink] public static extern void JPH_BodyInterface_MoveKinematic(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_RVec3* targetPosition, JPH_Quat* targetRotation, float deltaTime);
	[CLink] public static extern bool JPH_BodyInterface_ApplyBuoyancyImpulse(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_RVec3* surfacePosition, JPH_Vec3* surfaceNormal, float buoyancy, float linearDrag, float angularDrag, JPH_Vec3* fluidVelocity, JPH_Vec3* gravity, float deltaTime);

	[CLink] public static extern void JPH_BodyInterface_SetLinearAndAngularVelocity(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* linearVelocity, JPH_Vec3* angularVelocity);
	[CLink] public static extern void JPH_BodyInterface_GetLinearAndAngularVelocity(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* linearVelocity, JPH_Vec3* angularVelocity);

	[CLink] public static extern void JPH_BodyInterface_AddLinearVelocity(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* linearVelocity);
	[CLink] public static extern void JPH_BodyInterface_AddLinearAndAngularVelocity(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* linearVelocity, JPH_Vec3* angularVelocity);

	[CLink] public static extern void JPH_BodyInterface_SetAngularVelocity(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* angularVelocity);
	[CLink] public static extern void JPH_BodyInterface_GetAngularVelocity(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* angularVelocity);

	[CLink] public static extern void JPH_BodyInterface_GetPointVelocity(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_RVec3* point, JPH_Vec3* velocity);

	[CLink] public static extern void JPH_BodyInterface_AddForce(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* force);
	[CLink] public static extern void JPH_BodyInterface_AddForce2(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* force, JPH_RVec3* point);
	[CLink] public static extern void JPH_BodyInterface_AddTorque(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* torque);
	[CLink] public static extern void JPH_BodyInterface_AddForceAndTorque(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* force, JPH_Vec3* torque);

	[CLink] public static extern void JPH_BodyInterface_AddImpulse(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* impulse);
	[CLink] public static extern void JPH_BodyInterface_AddImpulse2(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* impulse, JPH_RVec3* point);
	[CLink] public static extern void JPH_BodyInterface_AddAngularImpulse(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Vec3* angularImpulse);

	[CLink] public static extern void JPH_BodyInterface_SetMotionQuality(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_MotionQuality quality);
	[CLink] public static extern JPH_MotionQuality JPH_BodyInterface_GetMotionQuality(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId);

	[CLink] public static extern void JPH_BodyInterface_GetInverseInertia(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_Mat4* result);

	[CLink] public static extern void JPH_BodyInterface_SetGravityFactor(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, float value);
	[CLink] public static extern float JPH_BodyInterface_GetGravityFactor(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId);

	[CLink] public static extern void JPH_BodyInterface_SetUseManifoldReduction(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, bool value);
	[CLink] public static extern bool JPH_BodyInterface_GetUseManifoldReduction(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId);

	[CLink] public static extern void JPH_BodyInterface_SetUserData(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, uint64 inUserData);
	[CLink] public static extern uint64 JPH_BodyInterface_GetUserData(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId);

	[CLink] public static extern void JPH_BodyInterface_SetIsSensor(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, bool value);
	[CLink] public static extern bool JPH_BodyInterface_IsSensor(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId);

	[CLink] public static extern JPH_PhysicsMaterial* JPH_BodyInterface_GetMaterial(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId, JPH_SubShapeID subShapeID);

	[CLink] public static extern void JPH_BodyInterface_InvalidateContactCache(JPH_BodyInterface* bodyInterface, JPH_BodyID bodyId);

	//--------------------------------------------------------------------------------------------------
	// JPH_BodyLockInterface
	//--------------------------------------------------------------------------------------------------
	[CLink] public static extern void JPH_BodyLockInterface_LockRead(JPH_BodyLockInterface* lockInterface, JPH_BodyID bodyID, JPH_BodyLockRead* outLock);
	[CLink] public static extern void JPH_BodyLockInterface_UnlockRead(JPH_BodyLockInterface* lockInterface, JPH_BodyLockRead* ioLock);

	[CLink] public static extern void JPH_BodyLockInterface_LockWrite(JPH_BodyLockInterface* lockInterface, JPH_BodyID bodyID, JPH_BodyLockWrite* outLock);
	[CLink] public static extern void JPH_BodyLockInterface_UnlockWrite(JPH_BodyLockInterface* lockInterface, JPH_BodyLockWrite* ioLock);

	[CLink] public static extern JPH_BodyLockMultiRead* JPH_BodyLockInterface_LockMultiRead(JPH_BodyLockInterface* lockInterface, JPH_BodyID* bodyIDs, uint32 count);
	[CLink] public static extern void JPH_BodyLockMultiRead_Destroy(JPH_BodyLockMultiRead* ioLock);
	[CLink] public static extern JPH_Body* JPH_BodyLockMultiRead_GetBody(JPH_BodyLockMultiRead* ioLock, uint32 bodyIndex);

	[CLink] public static extern JPH_BodyLockMultiWrite* JPH_BodyLockInterface_LockMultiWrite(JPH_BodyLockInterface* lockInterface, JPH_BodyID* bodyIDs, uint32 count);
	[CLink] public static extern void JPH_BodyLockMultiWrite_Destroy(JPH_BodyLockMultiWrite* ioLock);
	[CLink] public static extern JPH_Body* JPH_BodyLockMultiWrite_GetBody(JPH_BodyLockMultiWrite* ioLock, uint32 bodyIndex);

	//--------------------------------------------------------------------------------------------------
	// JPH_MotionProperties
	//--------------------------------------------------------------------------------------------------
	[CLink] public static extern JPH_AllowedDOFs JPH_MotionProperties_GetAllowedDOFs(JPH_MotionProperties* properties);
	[CLink] public static extern void JPH_MotionProperties_SetLinearDamping(JPH_MotionProperties* properties, float damping);
	[CLink] public static extern float JPH_MotionProperties_GetLinearDamping(JPH_MotionProperties* properties);
	[CLink] public static extern void JPH_MotionProperties_SetAngularDamping(JPH_MotionProperties* properties, float damping);
	[CLink] public static extern float JPH_MotionProperties_GetAngularDamping(JPH_MotionProperties* properties);
	[CLink] public static extern void JPH_MotionProperties_SetMassProperties(JPH_MotionProperties* properties, JPH_AllowedDOFs allowedDOFs, JPH_MassProperties* massProperties);
	[CLink] public static extern float JPH_MotionProperties_GetInverseMassUnchecked(JPH_MotionProperties* properties);
	[CLink] public static extern void JPH_MotionProperties_SetInverseMass(JPH_MotionProperties* properties, float inverseMass);
	[CLink] public static extern void JPH_MotionProperties_GetInverseInertiaDiagonal(JPH_MotionProperties* properties, JPH_Vec3* result);
	[CLink] public static extern void JPH_MotionProperties_GetInertiaRotation(JPH_MotionProperties* properties, JPH_Quat* result);
	[CLink] public static extern void JPH_MotionProperties_SetInverseInertia(JPH_MotionProperties* properties, JPH_Vec3* diagonal, JPH_Quat* rot);
	[CLink] public static extern void JPH_MotionProperties_ScaleToMass(JPH_MotionProperties* properties, float mass);

	//--------------------------------------------------------------------------------------------------
	// JPH_RayCast
	//--------------------------------------------------------------------------------------------------
	[CLink] public static extern void JPH_RayCast_GetPointOnRay(JPH_Vec3* origin, JPH_Vec3* direction, float fraction, JPH_Vec3* result);
	[CLink] public static extern void JPH_RRayCast_GetPointOnRay(JPH_RVec3* origin, JPH_Vec3* direction, float fraction, JPH_RVec3* result);

	//--------------------------------------------------------------------------------------------------
	// JPH_MassProperties
	//--------------------------------------------------------------------------------------------------
	[CLink] public static extern void JPH_MassProperties_DecomposePrincipalMomentsOfInertia(JPH_MassProperties* properties, JPH_Mat4* rotation, JPH_Vec3* diagonal);
	[CLink] public static extern void JPH_MassProperties_ScaleToMass(JPH_MassProperties* properties, float mass);
	[CLink] public static extern void JPH_MassProperties_GetEquivalentSolidBoxSize(float mass, JPH_Vec3* inertiaDiagonal, JPH_Vec3* result);

	//--------------------------------------------------------------------------------------------------
	// JPH_CollideShapeSettings
	//--------------------------------------------------------------------------------------------------
	[CLink] public static extern void JPH_CollideShapeSettings_Init(JPH_CollideShapeSettings* settings);

	//--------------------------------------------------------------------------------------------------
	// JPH_ShapeCastSettings
	//--------------------------------------------------------------------------------------------------
	[CLink] public static extern void JPH_ShapeCastSettings_Init(JPH_ShapeCastSettings* settings);

	//--------------------------------------------------------------------------------------------------
	// JPH_BroadPhaseQuery
	//--------------------------------------------------------------------------------------------------
	[CLink] public static extern bool JPH_BroadPhaseQuery_CastRay(JPH_BroadPhaseQuery* query,
		JPH_Vec3* origin, JPH_Vec3* direction,
		JPH_RayCastBodyCollectorCallback* callback, void* userData,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter);

	[CLink] public static extern bool JPH_BroadPhaseQuery_CastRay2(JPH_BroadPhaseQuery* query,
		JPH_Vec3* origin, JPH_Vec3* direction,
		JPH_CollisionCollectorType collectorType,
		JPH_RayCastBodyResultCallback* callback, void* userData,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter);

	[CLink] public static extern bool JPH_BroadPhaseQuery_CollideAABox(JPH_BroadPhaseQuery* query,
		JPH_AABox* @box, JPH_CollideShapeBodyCollectorCallback* callback, void* userData,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter);

	[CLink] public static extern bool JPH_BroadPhaseQuery_CollideSphere(JPH_BroadPhaseQuery* query,
		JPH_Vec3* center, float radius, JPH_CollideShapeBodyCollectorCallback* callback, void* userData,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter);

	[CLink] public static extern bool JPH_BroadPhaseQuery_CollidePoint(JPH_BroadPhaseQuery* query,
		JPH_Vec3* point, JPH_CollideShapeBodyCollectorCallback* callback, void* userData,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter);

	//--------------------------------------------------------------------------------------------------
	// JPH_NarrowPhaseQuery
	//--------------------------------------------------------------------------------------------------
	[CLink] public static extern bool JPH_NarrowPhaseQuery_CastRay(JPH_NarrowPhaseQuery* query,
		JPH_RVec3* origin, JPH_Vec3* direction,
		JPH_RayCastResult* hit,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter,
		JPH_BodyFilter* bodyFilter);

	[CLink] public static extern bool JPH_NarrowPhaseQuery_CastRay2(JPH_NarrowPhaseQuery* query,
		JPH_RVec3* origin, JPH_Vec3* direction,
		JPH_RayCastSettings* rayCastSettings,
		JPH_CastRayCollectorCallback* callback, void* userData,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter,
		JPH_BodyFilter* bodyFilter,
		JPH_ShapeFilter* shapeFilter);

	[CLink] public static extern bool JPH_NarrowPhaseQuery_CastRay3(JPH_NarrowPhaseQuery* query,
		JPH_RVec3* origin, JPH_Vec3* direction,
		JPH_RayCastSettings* rayCastSettings,
		JPH_CollisionCollectorType collectorType,
		JPH_CastRayResultCallback callback, void* userData,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter,
		JPH_BodyFilter* bodyFilter,
		JPH_ShapeFilter* shapeFilter);

	[CLink] public static extern bool JPH_NarrowPhaseQuery_CollidePoint(JPH_NarrowPhaseQuery* query,
		JPH_RVec3* point,
		JPH_CollidePointCollectorCallback* callback, void* userData,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter,
		JPH_BodyFilter* bodyFilter,
		JPH_ShapeFilter* shapeFilter);

	[CLink] public static extern bool JPH_NarrowPhaseQuery_CollidePoint2(JPH_NarrowPhaseQuery* query,
		JPH_RVec3* point,
		JPH_CollisionCollectorType collectorType,
		JPH_CollidePointResultCallback* callback, void* userData,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter,
		JPH_BodyFilter* bodyFilter,
		JPH_ShapeFilter* shapeFilter);

	[CLink] public static extern bool JPH_NarrowPhaseQuery_CollideShape(JPH_NarrowPhaseQuery* query,
		JPH_Shape* shape, JPH_Vec3* scale, JPH_RMat4* centerOfMassTransform,
		JPH_CollideShapeSettings* settings,
		JPH_RVec3* baseOffset,
		JPH_CollideShapeCollectorCallback* callback, void* userData,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter,
		JPH_BodyFilter* bodyFilter,
		JPH_ShapeFilter* shapeFilter);

	[CLink] public static extern bool JPH_NarrowPhaseQuery_CollideShape2(JPH_NarrowPhaseQuery* query,
		JPH_Shape* shape, JPH_Vec3* scale, JPH_RMat4* centerOfMassTransform,
		JPH_CollideShapeSettings* settings,
		JPH_RVec3* baseOffset,
		JPH_CollisionCollectorType collectorType,
		JPH_CollideShapeResultCallback* callback, void* userData,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter,
		JPH_BodyFilter* bodyFilter,
		JPH_ShapeFilter* shapeFilter);

	[CLink] public static extern bool JPH_NarrowPhaseQuery_CastShape(JPH_NarrowPhaseQuery* query,
		JPH_Shape* shape,
		JPH_RMat4* worldTransform, JPH_Vec3* direction,
		JPH_ShapeCastSettings* settings,
		JPH_RVec3* baseOffset,
		JPH_CastShapeCollectorCallback* callback, void* userData,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter,
		JPH_BodyFilter* bodyFilter,
		JPH_ShapeFilter* shapeFilter);

	[CLink] public static extern bool JPH_NarrowPhaseQuery_CastShape2(JPH_NarrowPhaseQuery* query,
		JPH_Shape* shape,
		JPH_RMat4* worldTransform, JPH_Vec3* direction,
		JPH_ShapeCastSettings* settings,
		JPH_RVec3* baseOffset,
		JPH_CollisionCollectorType collectorType,
		JPH_CastShapeResultCallback callback, void* userData,
		JPH_BroadPhaseLayerFilter* broadPhaseLayerFilter,
		JPH_ObjectLayerFilter* objectLayerFilter,
		JPH_BodyFilter* bodyFilter,
		JPH_ShapeFilter* shapeFilter);

	//--------------------------------------------------------------------------------------------------
	// JPH_Body
	//--------------------------------------------------------------------------------------------------
	[CLink] public static extern JPH_BodyID JPH_Body_GetID(JPH_Body* body);
	[CLink] public static extern JPH_BodyType JPH_Body_GetBodyType(JPH_Body* body);
	[CLink] public static extern bool JPH_Body_IsRigidBody(JPH_Body* body);
	[CLink] public static extern bool JPH_Body_IsSoftBody(JPH_Body* body);
	[CLink] public static extern bool JPH_Body_IsActive(JPH_Body* body);
	[CLink] public static extern bool JPH_Body_IsStatic(JPH_Body* body);
	[CLink] public static extern bool JPH_Body_IsKinematic(JPH_Body* body);
	[CLink] public static extern bool JPH_Body_IsDynamic(JPH_Body* body);
	[CLink] public static extern bool JPH_Body_CanBeKinematicOrDynamic(JPH_Body* body);

	[CLink] public static extern void JPH_Body_SetIsSensor(JPH_Body* body, bool value);
	[CLink] public static extern bool JPH_Body_IsSensor(JPH_Body* body);

	[CLink] public static extern void JPH_Body_SetCollideKinematicVsNonDynamic(JPH_Body* body, bool value);
	[CLink] public static extern bool JPH_Body_GetCollideKinematicVsNonDynamic(JPH_Body* body);

	[CLink] public static extern void JPH_Body_SetUseManifoldReduction(JPH_Body* body, bool value);
	[CLink] public static extern bool JPH_Body_GetUseManifoldReduction(JPH_Body* body);
	[CLink] public static extern bool JPH_Body_GetUseManifoldReductionWithBody(JPH_Body* body, JPH_Body* other);

	[CLink] public static extern void JPH_Body_SetApplyGyroscopicForce(JPH_Body* body, bool value);
	[CLink] public static extern bool JPH_Body_GetApplyGyroscopicForce(JPH_Body* body);

	[CLink] public static extern void JPH_Body_SetEnhancedInternalEdgeRemoval(JPH_Body* body, bool value);
	[CLink] public static extern bool JPH_Body_GetEnhancedInternalEdgeRemoval(JPH_Body* body);
	[CLink] public static extern bool JPH_Body_GetEnhancedInternalEdgeRemovalWithBody(JPH_Body* body, JPH_Body* other);

	[CLink] public static extern JPH_MotionType JPH_Body_GetMotionType(JPH_Body* body);
	[CLink] public static extern void JPH_Body_SetMotionType(JPH_Body* body, JPH_MotionType motionType);

	[CLink] public static extern JPH_BroadPhaseLayer JPH_Body_GetBroadPhaseLayer(JPH_Body* body);
	[CLink] public static extern JPH_ObjectLayer JPH_Body_GetObjectLayer(JPH_Body* body);

	[CLink] public static extern void JPH_Body_GetCollisionGroup(JPH_Body* body, JPH_CollisionGroup* result);
	[CLink] public static extern void JPH_Body_SetCollisionGroup(JPH_Body* body, JPH_CollisionGroup* value);

	[CLink] public static extern bool JPH_Body_GetAllowSleeping(JPH_Body* body);
	[CLink] public static extern void JPH_Body_SetAllowSleeping(JPH_Body* body, bool allowSleeping);
	[CLink] public static extern void JPH_Body_ResetSleepTimer(JPH_Body* body);

	[CLink] public static extern float JPH_Body_GetFriction(JPH_Body* body);
	[CLink] public static extern void JPH_Body_SetFriction(JPH_Body* body, float friction);
	[CLink] public static extern float JPH_Body_GetRestitution(JPH_Body* body);
	[CLink] public static extern void JPH_Body_SetRestitution(JPH_Body* body, float restitution);
	[CLink] public static extern void JPH_Body_GetLinearVelocity(JPH_Body* body, JPH_Vec3* velocity);
	[CLink] public static extern void JPH_Body_SetLinearVelocity(JPH_Body* body, JPH_Vec3* velocity);
	[CLink] public static extern void JPH_Body_SetLinearVelocityClamped(JPH_Body* body, JPH_Vec3* velocity);
	[CLink] public static extern void JPH_Body_GetAngularVelocity(JPH_Body* body, JPH_Vec3* velocity);
	[CLink] public static extern void JPH_Body_SetAngularVelocity(JPH_Body* body, JPH_Vec3* velocity);
	[CLink] public static extern void JPH_Body_SetAngularVelocityClamped(JPH_Body* body, JPH_Vec3* velocity);

	[CLink] public static extern void JPH_Body_GetPointVelocityCOM(JPH_Body* body, JPH_Vec3* pointRelativeToCOM, JPH_Vec3* velocity);
	[CLink] public static extern void JPH_Body_GetPointVelocity(JPH_Body* body, JPH_RVec3* point, JPH_Vec3* velocity);

	[CLink] public static extern void JPH_Body_AddForce(JPH_Body* body, JPH_Vec3* force);
	[CLink] public static extern void JPH_Body_AddForceAtPosition(JPH_Body* body, JPH_Vec3* force, JPH_RVec3* position);
	[CLink] public static extern void JPH_Body_AddTorque(JPH_Body* body, JPH_Vec3* force);
	[CLink] public static extern void JPH_Body_GetAccumulatedForce(JPH_Body* body, JPH_Vec3* force);
	[CLink] public static extern void JPH_Body_GetAccumulatedTorque(JPH_Body* body, JPH_Vec3* force);
	[CLink] public static extern void JPH_Body_ResetForce(JPH_Body* body);
	[CLink] public static extern void JPH_Body_ResetTorque(JPH_Body* body);
	[CLink] public static extern void JPH_Body_ResetMotion(JPH_Body* body);

	[CLink] public static extern void JPH_Body_GetInverseInertia(JPH_Body* body, JPH_Mat4* result);

	[CLink] public static extern void JPH_Body_AddImpulse(JPH_Body* body, JPH_Vec3* impulse);
	[CLink] public static extern void JPH_Body_AddImpulseAtPosition(JPH_Body* body, JPH_Vec3* impulse, JPH_RVec3* position);
	[CLink] public static extern void JPH_Body_AddAngularImpulse(JPH_Body* body, JPH_Vec3* angularImpulse);
	[CLink] public static extern void JPH_Body_MoveKinematic(JPH_Body* body, JPH_RVec3* targetPosition, JPH_Quat* targetRotation, float deltaTime);
	[CLink] public static extern bool JPH_Body_ApplyBuoyancyImpulse(JPH_Body* body, JPH_RVec3* surfacePosition, JPH_Vec3* surfaceNormal, float buoyancy, float linearDrag, float angularDrag, JPH_Vec3* fluidVelocity, JPH_Vec3* gravity, float deltaTime);

	[CLink] public static extern bool JPH_Body_IsInBroadPhase(JPH_Body* body);
	[CLink] public static extern bool JPH_Body_IsCollisionCacheInvalid(JPH_Body* body);

	[CLink] public static extern JPH_Shape* JPH_Body_GetShape(JPH_Body* body);

	[CLink] public static extern void JPH_Body_GetPosition(JPH_Body* body, JPH_RVec3* result);
	[CLink] public static extern void JPH_Body_GetRotation(JPH_Body* body, JPH_Quat* result);
	[CLink] public static extern void JPH_Body_GetWorldTransform(JPH_Body* body, JPH_RMat4* result);
	[CLink] public static extern void JPH_Body_GetCenterOfMassPosition(JPH_Body* body, JPH_RVec3* result);
	[CLink] public static extern void JPH_Body_GetCenterOfMassTransform(JPH_Body* body, JPH_RMat4* result);
	[CLink] public static extern void JPH_Body_GetInverseCenterOfMassTransform(JPH_Body* body, JPH_RMat4* result);

	[CLink] public static extern void JPH_Body_GetWorldSpaceBounds(JPH_Body* body, JPH_AABox* result);
	[CLink] public static extern void JPH_Body_GetWorldSpaceSurfaceNormal(JPH_Body* body, JPH_SubShapeID subShapeID, JPH_RVec3* position, JPH_Vec3* normal);

	[CLink] public static extern JPH_MotionProperties* JPH_Body_GetMotionProperties(JPH_Body* body);
	[CLink] public static extern JPH_MotionProperties* JPH_Body_GetMotionPropertiesUnchecked(JPH_Body* body);

	[CLink] public static extern void JPH_Body_SetUserData(JPH_Body* body, uint64 userData);
	[CLink] public static extern uint64 JPH_Body_GetUserData(JPH_Body* body);

	[CLink] public static extern JPH_Body* JPH_Body_GetFixedToWorldBody();
}
	/* JPH_BroadPhaseLayerFilter_Procs */
[CRepr] struct JPH_BroadPhaseLayerFilter_Procs
{
	public function bool(void* userData, JPH_BroadPhaseLayer layer) ShouldCollide;
}
static
{
	[CLink] public static extern void JPH_BroadPhaseLayerFilter_SetProcs(JPH_BroadPhaseLayerFilter_Procs* procs);
	[CLink] public static extern JPH_BroadPhaseLayerFilter* JPH_BroadPhaseLayerFilter_Create(void* userData);
	[CLink] public static extern void JPH_BroadPhaseLayerFilter_Destroy(JPH_BroadPhaseLayerFilter* filter);
}
	/* JPH_ObjectLayerFilter */
[CRepr] struct JPH_ObjectLayerFilter_Procs
{
	public function bool(void* userData, JPH_ObjectLayer layer) ShouldCollide;
}
static
{
	[CLink] public static extern void JPH_ObjectLayerFilter_SetProcs(JPH_ObjectLayerFilter_Procs* procs);
	[CLink] public static extern JPH_ObjectLayerFilter* JPH_ObjectLayerFilter_Create(void* userData);
	[CLink] public static extern void JPH_ObjectLayerFilter_Destroy(JPH_ObjectLayerFilter* filter);
}
	/* JPH_BodyFilter */
[CRepr] struct JPH_BodyFilter_Procs
{
	public function bool(void* userData,
		JPH_BodyID bodyID) ShouldCollide;

	public function bool(void* userData,
		JPH_Body* bodyID) ShouldCollideLocked;
}
static
{
	[CLink] public static extern void JPH_BodyFilter_SetProcs(JPH_BodyFilter_Procs* procs);
	[CLink] public static extern JPH_BodyFilter* JPH_BodyFilter_Create(void* userData);
	[CLink] public static extern void JPH_BodyFilter_Destroy(JPH_BodyFilter* filter);
}
	/* JPH_ShapeFilter */
[CRepr] struct JPH_ShapeFilter_Procs
{
	public function bool(void* userData,
		JPH_Shape* shape2,
		JPH_SubShapeID* subShapeIDOfShape2) ShouldCollide;

	public function bool(void* userData,
		JPH_Shape* shape1,
		JPH_SubShapeID* subShapeIDOfShape1,
		JPH_Shape* shape2,
		JPH_SubShapeID* subShapeIDOfShape2) ShouldCollide2;
}
static
{
	[CLink] public static extern void JPH_ShapeFilter_SetProcs(JPH_ShapeFilter_Procs* procs);
	[CLink] public static extern JPH_ShapeFilter* JPH_ShapeFilter_Create(void* userData);
	[CLink] public static extern void JPH_ShapeFilter_Destroy(JPH_ShapeFilter* filter);
	[CLink] public static extern JPH_BodyID JPH_ShapeFilter_GetBodyID2(JPH_ShapeFilter* filter);
	[CLink] public static extern void JPH_ShapeFilter_SetBodyID2(JPH_ShapeFilter* filter, JPH_BodyID id);
}
	/* JPH_SimShapeFilter */
[CRepr] struct JPH_SimShapeFilter_Procs
{
	public function bool(void* userData,
		JPH_Body* body1,
		JPH_Shape* shape1,
		JPH_SubShapeID* subShapeIDOfShape1,
		JPH_Body* body2,
		JPH_Shape* shape2,
		JPH_SubShapeID* subShapeIDOfShape2
		) ShouldCollide;
}
static
{
	[CLink] public static extern void JPH_SimShapeFilter_SetProcs(JPH_SimShapeFilter_Procs* procs);
	[CLink] public static extern JPH_SimShapeFilter* JPH_SimShapeFilter_Create(void* userData);
	[CLink] public static extern void JPH_SimShapeFilter_Destroy(JPH_SimShapeFilter* filter);
}
	/* Contact listener */
[CRepr] struct JPH_ContactListener_Procs
{
	public function JPH_ValidateResult(void* userData,
		JPH_Body* body1,
		JPH_Body* body2,
		JPH_RVec3* baseOffset,
		JPH_CollideShapeResult* collisionResult) OnContactValidate;

	public function void(void* userData,
		JPH_Body* body1,
		JPH_Body* body2,
		JPH_ContactManifold* manifold,
		JPH_ContactSettings* settings) OnContactAdded;

	public function void(void* userData,
		JPH_Body* body1,
		JPH_Body* body2,
		JPH_ContactManifold* manifold,
		JPH_ContactSettings* settings) OnContactPersisted;

	public function void(void* userData,
		JPH_SubShapeIDPair* subShapePair
		) OnContactRemoved;
}

static
{
	[CLink] public static extern void JPH_ContactListener_SetProcs(JPH_ContactListener_Procs* procs);
	[CLink] public static extern JPH_ContactListener* JPH_ContactListener_Create(void* userData);
	[CLink] public static extern void JPH_ContactListener_Destroy(JPH_ContactListener* listener);

	/* BodyActivationListener */
	[CRepr] struct JPH_BodyActivationListener_Procs
	{
		public function void(void* userData, JPH_BodyID bodyID, uint64 bodyUserData) OnBodyActivated;
		public function void(void* userData, JPH_BodyID bodyID, uint64 bodyUserData) OnBodyDeactivated;
	}

	[CLink] public static extern void JPH_BodyActivationListener_SetProcs(JPH_BodyActivationListener_Procs* procs);
	[CLink] public static extern JPH_BodyActivationListener* JPH_BodyActivationListener_Create(void* userData);
	[CLink] public static extern void JPH_BodyActivationListener_Destroy(JPH_BodyActivationListener* listener);

	/* JPH_BodyDrawFilter */
	[CRepr] struct JPH_BodyDrawFilter_Procs
	{
		public function  bool(void* userData, JPH_Body* body) ShouldDraw;
	}

	[CLink] public static extern void JPH_BodyDrawFilter_SetProcs(JPH_BodyDrawFilter_Procs* procs);
	[CLink] public static extern JPH_BodyDrawFilter* JPH_BodyDrawFilter_Create(void* userData);
	[CLink] public static extern void JPH_BodyDrawFilter_Destroy(JPH_BodyDrawFilter* filter);

	/* ContactManifold */
	[CLink] public static extern void JPH_ContactManifold_GetWorldSpaceNormal(JPH_ContactManifold* manifold, JPH_Vec3* result);
	[CLink] public static extern float JPH_ContactManifold_GetPenetrationDepth(JPH_ContactManifold* manifold);
	[CLink] public static extern JPH_SubShapeID JPH_ContactManifold_GetSubShapeID1(JPH_ContactManifold* manifold);
	[CLink] public static extern JPH_SubShapeID JPH_ContactManifold_GetSubShapeID2(JPH_ContactManifold* manifold);
	[CLink] public static extern uint32 JPH_ContactManifold_GetPointCount(JPH_ContactManifold* manifold);
	[CLink] public static extern void JPH_ContactManifold_GetWorldSpaceContactPointOn1(JPH_ContactManifold* manifold, uint32 index, JPH_RVec3* result);
	[CLink] public static extern void JPH_ContactManifold_GetWorldSpaceContactPointOn2(JPH_ContactManifold* manifold, uint32 index, JPH_RVec3* result);

	/* CharacterBase */
	[CLink] public static extern void JPH_CharacterBase_Destroy(JPH_CharacterBase* character);
	[CLink] public static extern float JPH_CharacterBase_GetCosMaxSlopeAngle(JPH_CharacterBase* character);
	[CLink] public static extern void JPH_CharacterBase_SetMaxSlopeAngle(JPH_CharacterBase* character, float maxSlopeAngle);
	[CLink] public static extern void JPH_CharacterBase_GetUp(JPH_CharacterBase* character, JPH_Vec3* result);
	[CLink] public static extern void JPH_CharacterBase_SetUp(JPH_CharacterBase* character, JPH_Vec3* value);
	[CLink] public static extern bool JPH_CharacterBase_IsSlopeTooSteep(JPH_CharacterBase* character, JPH_Vec3* value);
	[CLink] public static extern JPH_Shape* JPH_CharacterBase_GetShape(JPH_CharacterBase* character);

	[CLink] public static extern JPH_GroundState JPH_CharacterBase_GetGroundState(JPH_CharacterBase* character);
	[CLink] public static extern bool JPH_CharacterBase_IsSupported(JPH_CharacterBase* character);
	[CLink] public static extern void JPH_CharacterBase_GetGroundPosition(JPH_CharacterBase* character, JPH_RVec3* position);
	[CLink] public static extern void JPH_CharacterBase_GetGroundNormal(JPH_CharacterBase* character, JPH_Vec3* normal);
	[CLink] public static extern void JPH_CharacterBase_GetGroundVelocity(JPH_CharacterBase* character, JPH_Vec3* velocity);
	[CLink] public static extern JPH_PhysicsMaterial* JPH_CharacterBase_GetGroundMaterial(JPH_CharacterBase* character);
	[CLink] public static extern JPH_BodyID JPH_CharacterBase_GetGroundBodyId(JPH_CharacterBase* character);
	[CLink] public static extern JPH_SubShapeID JPH_CharacterBase_GetGroundSubShapeId(JPH_CharacterBase* character);
	[CLink] public static extern uint64 JPH_CharacterBase_GetGroundUserData(JPH_CharacterBase* character);

	/* CharacterSettings */
	[CLink] public static extern void JPH_CharacterSettings_Init(JPH_CharacterSettings* settings);

	/* Character */
	[CLink] public static extern JPH_Character* JPH_Character_Create(JPH_CharacterSettings* settings,
		JPH_RVec3* position,
		JPH_Quat* rotation,
		uint64 userData,
		JPH_PhysicsSystem* system);

	[CLink] public static extern void JPH_Character_AddToPhysicsSystem(JPH_Character* character, JPH_Activation activationMode /*= JPH_ActivationActivate */, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_RemoveFromPhysicsSystem(JPH_Character* character, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_Activate(JPH_Character* character, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_PostSimulation(JPH_Character* character, float maxSeparationDistance, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_SetLinearAndAngularVelocity(JPH_Character* character, JPH_Vec3* linearVelocity, JPH_Vec3* angularVelocity, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_GetLinearVelocity(JPH_Character* character, JPH_Vec3* result);
	[CLink] public static extern void JPH_Character_SetLinearVelocity(JPH_Character* character, JPH_Vec3* value, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_AddLinearVelocity(JPH_Character* character, JPH_Vec3* value, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_AddImpulse(JPH_Character* character, JPH_Vec3* value, bool lockBodies /* = true */);
	[CLink] public static extern JPH_BodyID JPH_Character_GetBodyID(JPH_Character* character);

	[CLink] public static extern void JPH_Character_GetPositionAndRotation(JPH_Character* character, JPH_RVec3* position, JPH_Quat* rotation, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_SetPositionAndRotation(JPH_Character* character, JPH_RVec3* position, JPH_Quat* rotation, JPH_Activation activationMode, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_GetPosition(JPH_Character* character, JPH_RVec3* position, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_SetPosition(JPH_Character* character, JPH_RVec3* position, JPH_Activation activationMode, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_GetRotation(JPH_Character* character, JPH_Quat* rotation, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_SetRotation(JPH_Character* character, JPH_Quat* rotation, JPH_Activation activationMode, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_GetCenterOfMassPosition(JPH_Character* character, JPH_RVec3* result, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Character_GetWorldTransform(JPH_Character* character, JPH_RMat4* result, bool lockBodies /* = true */);
	[CLink] public static extern JPH_ObjectLayer JPH_Character_GetLayer(JPH_Character* character);
	[CLink] public static extern void JPH_Character_SetLayer(JPH_Character* character, JPH_ObjectLayer value, bool lockBodies /*= true*/);
	[CLink] public static extern void JPH_Character_SetShape(JPH_Character* character, JPH_Shape* shape, float maxPenetrationDepth, bool lockBodies /*= true*/);

	/* CharacterVirtualSettings */
	[CLink] public static extern void JPH_CharacterVirtualSettings_Init(JPH_CharacterVirtualSettings* settings);

	/* CharacterVirtual */
	[CLink] public static extern JPH_CharacterVirtual* JPH_CharacterVirtual_Create(JPH_CharacterVirtualSettings* settings,
		JPH_RVec3* position,
		JPH_Quat* rotation,
		uint64 userData,
		JPH_PhysicsSystem* system);

	[CLink] public static extern JPH_CharacterID JPH_CharacterVirtual_GetID(JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVirtual_SetListener(JPH_CharacterVirtual* character, JPH_CharacterContactListener* listener);
	[CLink] public static extern void JPH_CharacterVirtual_SetCharacterVsCharacterCollision(JPH_CharacterVirtual* character, JPH_CharacterVsCharacterCollision* characterVsCharacterCollision);

	[CLink] public static extern void JPH_CharacterVirtual_GetLinearVelocity(JPH_CharacterVirtual* character, JPH_Vec3* velocity);
	[CLink] public static extern void JPH_CharacterVirtual_SetLinearVelocity(JPH_CharacterVirtual* character, JPH_Vec3* velocity);
	[CLink] public static extern void JPH_CharacterVirtual_GetPosition(JPH_CharacterVirtual* character, JPH_RVec3* position);
	[CLink] public static extern void JPH_CharacterVirtual_SetPosition(JPH_CharacterVirtual* character, JPH_RVec3* position);
	[CLink] public static extern void JPH_CharacterVirtual_GetRotation(JPH_CharacterVirtual* character, JPH_Quat* rotation);
	[CLink] public static extern void JPH_CharacterVirtual_SetRotation(JPH_CharacterVirtual* character, JPH_Quat* rotation);
	[CLink] public static extern void JPH_CharacterVirtual_GetWorldTransform(JPH_CharacterVirtual* character, JPH_RMat4* result);
	[CLink] public static extern void JPH_CharacterVirtual_GetCenterOfMassTransform(JPH_CharacterVirtual* character, JPH_RMat4* result);
	[CLink] public static extern float JPH_CharacterVirtual_GetMass(JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVirtual_SetMass(JPH_CharacterVirtual* character, float value);
	[CLink] public static extern float JPH_CharacterVirtual_GetMaxStrength(JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVirtual_SetMaxStrength(JPH_CharacterVirtual* character, float value);

	[CLink] public static extern float JPH_CharacterVirtual_GetPenetrationRecoverySpeed(JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVirtual_SetPenetrationRecoverySpeed(JPH_CharacterVirtual* character, float value);
	[CLink] public static extern bool	JPH_CharacterVirtual_GetEnhancedInternalEdgeRemoval(JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVirtual_SetEnhancedInternalEdgeRemoval(JPH_CharacterVirtual* character, bool value);
	[CLink] public static extern float JPH_CharacterVirtual_GetCharacterPadding(JPH_CharacterVirtual* character);
	[CLink] public static extern uint32 JPH_CharacterVirtual_GetMaxNumHits(JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVirtual_SetMaxNumHits(JPH_CharacterVirtual* character, uint32 value);
	[CLink] public static extern float JPH_CharacterVirtual_GetHitReductionCosMaxAngle(JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVirtual_SetHitReductionCosMaxAngle(JPH_CharacterVirtual* character, float value);
	[CLink] public static extern bool JPH_CharacterVirtual_GetMaxHitsExceeded(JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVirtual_GetShapeOffset(JPH_CharacterVirtual* character, JPH_Vec3* result);
	[CLink] public static extern void JPH_CharacterVirtual_SetShapeOffset(JPH_CharacterVirtual* character, JPH_Vec3* value);
	[CLink] public static extern uint64 JPH_CharacterVirtual_GetUserData(JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVirtual_SetUserData(JPH_CharacterVirtual* character, uint64 value);
	[CLink] public static extern JPH_BodyID JPH_CharacterVirtual_GetInnerBodyID(JPH_CharacterVirtual* character);

	[CLink] public static extern void JPH_CharacterVirtual_CancelVelocityTowardsSteepSlopes(JPH_CharacterVirtual* character, JPH_Vec3* desiredVelocity, JPH_Vec3* velocity);
	[CLink] public static extern void JPH_CharacterVirtual_StartTrackingContactChanges(JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVirtual_FinishTrackingContactChanges(JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVirtual_Update(JPH_CharacterVirtual* character, float deltaTime, JPH_ObjectLayer layer, JPH_PhysicsSystem* system, JPH_BodyFilter* bodyFilter, JPH_ShapeFilter* shapeFilter);

	[CLink] public static extern void JPH_CharacterVirtual_ExtendedUpdate(JPH_CharacterVirtual* character, float deltaTime,
		JPH_ExtendedUpdateSettings* settings, JPH_ObjectLayer layer, JPH_PhysicsSystem* system, JPH_BodyFilter* bodyFilter, JPH_ShapeFilter* shapeFilter);
	[CLink] public static extern void JPH_CharacterVirtual_RefreshContacts(JPH_CharacterVirtual* character, JPH_ObjectLayer layer, JPH_PhysicsSystem* system, JPH_BodyFilter* bodyFilter, JPH_ShapeFilter* shapeFilter);

	[CLink] public static extern bool JPH_CharacterVirtual_CanWalkStairs(JPH_CharacterVirtual* character, JPH_Vec3* linearVelocity);
	[CLink] public static extern bool JPH_CharacterVirtual_WalkStairs(JPH_CharacterVirtual* character, float deltaTime,
		JPH_Vec3* stepUp, JPH_Vec3* stepForward, JPH_Vec3* stepForwardTest, JPH_Vec3* stepDownExtra,
		JPH_ObjectLayer layer, JPH_PhysicsSystem* system,
		JPH_BodyFilter* bodyFilter, JPH_ShapeFilter* shapeFilter);

	[CLink] public static extern bool JPH_CharacterVirtual_StickToFloor(JPH_CharacterVirtual* character, JPH_Vec3* stepDown,
		JPH_ObjectLayer layer, JPH_PhysicsSystem* system,
		JPH_BodyFilter* bodyFilter, JPH_ShapeFilter* shapeFilter);

	[CLink] public static extern void JPH_CharacterVirtual_UpdateGroundVelocity(JPH_CharacterVirtual* character);
	[CLink] public static extern bool JPH_CharacterVirtual_SetShape(JPH_CharacterVirtual* character, JPH_Shape* shape, float maxPenetrationDepth, JPH_ObjectLayer layer, JPH_PhysicsSystem* system, JPH_BodyFilter* bodyFilter, JPH_ShapeFilter* shapeFilter);
	[CLink] public static extern void JPH_CharacterVirtual_SetInnerBodyShape(JPH_CharacterVirtual* character, JPH_Shape* shape);

	[CLink] public static extern uint32 JPH_CharacterVirtual_GetNumActiveContacts(JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVirtual_GetActiveContact(JPH_CharacterVirtual* character, uint32 index, JPH_CharacterVirtualContact* result);

	[CLink] public static extern bool JPH_CharacterVirtual_HasCollidedWithBody(JPH_CharacterVirtual* character, JPH_BodyID body);
	[CLink] public static extern bool JPH_CharacterVirtual_HasCollidedWith(JPH_CharacterVirtual* character, JPH_CharacterID other);
	[CLink] public static extern bool JPH_CharacterVirtual_HasCollidedWithCharacter(JPH_CharacterVirtual* character, JPH_CharacterVirtual* other);
}
	/* CharacterContactListener */
[CRepr] struct JPH_CharacterContactListener_Procs
{
	public function void(void* userData,
		JPH_CharacterVirtual* character,
		JPH_Body* body2,
		JPH_Vec3* ioLinearVelocity,
		JPH_Vec3* ioAngularVelocity) OnAdjustBodyVelocity;

	public function bool(void* userData,
		JPH_CharacterVirtual* character,
		JPH_BodyID bodyID2,
		JPH_SubShapeID subShapeID2) OnContactValidate;

	public function bool(void* userData,
		JPH_CharacterVirtual* character,
		JPH_CharacterVirtual* otherCharacter,
		JPH_SubShapeID subShapeID2) OnCharacterContactValidate;

	public function void(void* userData,
		JPH_CharacterVirtual* character,
		JPH_BodyID bodyID2,
		JPH_SubShapeID subShapeID2,
		JPH_RVec3* contactPosition,
		JPH_Vec3* contactNormal,
		JPH_CharacterContactSettings* ioSettings) OnContactAdded;

	public function void(void* userData,
		JPH_CharacterVirtual* character,
		JPH_BodyID bodyID2,
		JPH_SubShapeID subShapeID2,
		JPH_RVec3* contactPosition,
		JPH_Vec3* contactNormal,
		JPH_CharacterContactSettings* ioSettings) OnContactPersisted;

	public function void(void* userData,
		JPH_CharacterVirtual* character,
		JPH_BodyID bodyID2,
		JPH_SubShapeID subShapeID2) OnContactRemoved;

	public function void(void* userData,
		JPH_CharacterVirtual* character,
		JPH_CharacterVirtual* otherCharacter,
		JPH_SubShapeID subShapeID2,
		JPH_RVec3* contactPosition,
		JPH_Vec3* contactNormal,
		JPH_CharacterContactSettings* ioSettings) OnCharacterContactAdded;

	public function void(void* userData,
		JPH_CharacterVirtual* character,
		JPH_CharacterVirtual* otherCharacter,
		JPH_SubShapeID subShapeID2,
		JPH_RVec3* contactPosition,
		JPH_Vec3* contactNormal,
		JPH_CharacterContactSettings* ioSettings) OnCharacterContactPersisted;

	public function void(void* userData,
		JPH_CharacterVirtual* character,
		JPH_CharacterID otherCharacterID,
		JPH_SubShapeID subShapeID2) OnCharacterContactRemoved;

	public function void(void* userData,
		JPH_CharacterVirtual* character,
		JPH_BodyID bodyID2,
		JPH_SubShapeID subShapeID2,
		JPH_RVec3* contactPosition,
		JPH_Vec3* contactNormal,
		JPH_Vec3* contactVelocity,
		JPH_PhysicsMaterial* contactMaterial,
		JPH_Vec3* characterVelocity,
		JPH_Vec3* newCharacterVelocity) OnContactSolve;

	public function void(void* userData,
		JPH_CharacterVirtual* character,
		JPH_CharacterVirtual* otherCharacter,
		JPH_SubShapeID subShapeID2,
		JPH_RVec3* contactPosition,
		JPH_Vec3* contactNormal,
		JPH_Vec3* contactVelocity,
		JPH_PhysicsMaterial* contactMaterial,
		JPH_Vec3* characterVelocity,
		JPH_Vec3* newCharacterVelocity) OnCharacterContactSolve;
}
static
{
	[CLink] public static extern void JPH_CharacterContactListener_SetProcs(JPH_CharacterContactListener_Procs* procs);
	[CLink] public static extern JPH_CharacterContactListener* JPH_CharacterContactListener_Create(void* userData);
	[CLink] public static extern void JPH_CharacterContactListener_Destroy(JPH_CharacterContactListener* listener);
}
	/* JPH_CharacterVsCharacterCollision */
[CRepr] struct JPH_CharacterVsCharacterCollision_Procs
{
	public function void(void* userData,
		JPH_CharacterVirtual* character,
		JPH_RMat4* centerOfMassTransform,
		JPH_CollideShapeSettings* collideShapeSettings,
		JPH_RVec3* baseOffset) CollideCharacter;

	public function void(void* userData,
		JPH_CharacterVirtual* character,
		JPH_RMat4* centerOfMassTransform,
		JPH_Vec3* direction,
		JPH_ShapeCastSettings* shapeCastSettings,
		JPH_RVec3* baseOffset) CastCharacter;
}
static
{
	[CLink] public static extern void JPH_CharacterVsCharacterCollision_SetProcs(JPH_CharacterVsCharacterCollision_Procs* procs);
	[CLink] public static extern JPH_CharacterVsCharacterCollision* JPH_CharacterVsCharacterCollision_Create(void* userData);
	[CLink] public static extern JPH_CharacterVsCharacterCollision* JPH_CharacterVsCharacterCollision_CreateSimple();
	[CLink] public static extern void JPH_CharacterVsCharacterCollisionSimple_AddCharacter(JPH_CharacterVsCharacterCollision* characterVsCharacter, JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVsCharacterCollisionSimple_RemoveCharacter(JPH_CharacterVsCharacterCollision* characterVsCharacter, JPH_CharacterVirtual* character);
	[CLink] public static extern void JPH_CharacterVsCharacterCollision_Destroy(JPH_CharacterVsCharacterCollision* listener);

	/* CollisionDispatch */
	[CLink] public static extern bool JPH_CollisionDispatch_CollideShapeVsShape(
		JPH_Shape* shape1, JPH_Shape* shape2,
		JPH_Vec3* scale1, JPH_Vec3* scale2,
		JPH_Mat4* centerOfMassTransform1, JPH_Mat4* centerOfMassTransform2,
		JPH_CollideShapeSettings* collideShapeSettings,
		JPH_CollideShapeCollectorCallback* callback, void* userData, JPH_ShapeFilter* shapeFilter);

	[CLink] public static extern bool JPH_CollisionDispatch_CastShapeVsShapeLocalSpace(
		JPH_Vec3* direction, JPH_Shape* shape1, JPH_Shape* shape2,
		JPH_Vec3* scale1InShape2LocalSpace, JPH_Vec3* scale2,
		JPH_Mat4* centerOfMassTransform1InShape2LocalSpace, JPH_Mat4* centerOfMassWorldTransform2,
		JPH_ShapeCastSettings* shapeCastSettings,
		JPH_CastShapeCollectorCallback* callback, void* userData,
		JPH_ShapeFilter* shapeFilter);

	[CLink] public static extern bool JPH_CollisionDispatch_CastShapeVsShapeWorldSpace(
		JPH_Vec3* direction, JPH_Shape* shape1, JPH_Shape* shape2,
		JPH_Vec3* scale1, JPH_Vec3* inScale2,
		JPH_Mat4* centerOfMassWorldTransform1, JPH_Mat4* centerOfMassWorldTransform2,
		JPH_ShapeCastSettings* shapeCastSettings,
		JPH_CastShapeCollectorCallback* callback, void* userData,
		JPH_ShapeFilter* shapeFilter);
}
	/* DebugRenderer */
[CRepr] struct JPH_DebugRenderer_Procs
{
	public function void(void* userData, JPH_RVec3* from, JPH_RVec3* to, JPH_Color color) DrawLine;
	public function void(void* userData, JPH_RVec3* v1, JPH_RVec3* v2, JPH_RVec3* v3, JPH_Color color, JPH_DebugRenderer_CastShadow castShadow) DrawTriangle;
	public function void(void* userData, JPH_RVec3* position, char8* str, JPH_Color color, float height) DrawText3D;
}
static
{
	[CLink] public static extern void JPH_DebugRenderer_SetProcs(JPH_DebugRenderer_Procs* procs);
	[CLink] public static extern JPH_DebugRenderer* JPH_DebugRenderer_Create(void* userData);
	[CLink] public static extern void JPH_DebugRenderer_Destroy(JPH_DebugRenderer* renderer);
	[CLink] public static extern void JPH_DebugRenderer_NextFrame(JPH_DebugRenderer* renderer);
	[CLink] public static extern void JPH_DebugRenderer_SetCameraPos(JPH_DebugRenderer* renderer, JPH_RVec3* position);

	[CLink] public static extern void JPH_DebugRenderer_DrawLine(JPH_DebugRenderer* renderer, JPH_RVec3* from, JPH_RVec3* to, JPH_Color color);
	[CLink] public static extern void JPH_DebugRenderer_DrawWireBox(JPH_DebugRenderer* renderer, JPH_AABox* @box, JPH_Color color);
	[CLink] public static extern void JPH_DebugRenderer_DrawWireBox2(JPH_DebugRenderer* renderer, JPH_RMat4* matrix, JPH_AABox* @box, JPH_Color color);
	[CLink] public static extern void JPH_DebugRenderer_DrawMarker(JPH_DebugRenderer* renderer, JPH_RVec3* position, JPH_Color color, float size);
	[CLink] public static extern void JPH_DebugRenderer_DrawArrow(JPH_DebugRenderer* renderer, JPH_RVec3* from, JPH_RVec3* to, JPH_Color color, float size);
	[CLink] public static extern void JPH_DebugRenderer_DrawCoordinateSystem(JPH_DebugRenderer* renderer, JPH_RMat4* matrix, float size);
	[CLink] public static extern void JPH_DebugRenderer_DrawPlane(JPH_DebugRenderer* renderer, JPH_RVec3* point, JPH_Vec3* normal, JPH_Color color, float size);
	[CLink] public static extern void JPH_DebugRenderer_DrawWireTriangle(JPH_DebugRenderer* renderer, JPH_RVec3* v1, JPH_RVec3* v2, JPH_RVec3* v3, JPH_Color color);
	[CLink] public static extern void JPH_DebugRenderer_DrawWireSphere(JPH_DebugRenderer* renderer, JPH_RVec3* center, float radius, JPH_Color color, int32 level);
	[CLink] public static extern void JPH_DebugRenderer_DrawWireUnitSphere(JPH_DebugRenderer* renderer, JPH_RMat4* matrix, JPH_Color color, int32 level);
	[CLink] public static extern void JPH_DebugRenderer_DrawTriangle(JPH_DebugRenderer* renderer, JPH_RVec3* v1, JPH_RVec3* v2, JPH_RVec3* v3, JPH_Color color, JPH_DebugRenderer_CastShadow castShadow);
	[CLink] public static extern void JPH_DebugRenderer_DrawBox(JPH_DebugRenderer* renderer, JPH_AABox* @box, JPH_Color color, JPH_DebugRenderer_CastShadow castShadow, JPH_DebugRenderer_DrawMode drawMode);
	[CLink] public static extern void JPH_DebugRenderer_DrawBox2(JPH_DebugRenderer* renderer, JPH_RMat4* matrix, JPH_AABox* @box, JPH_Color color, JPH_DebugRenderer_CastShadow castShadow, JPH_DebugRenderer_DrawMode drawMode);
	[CLink] public static extern void JPH_DebugRenderer_DrawSphere(JPH_DebugRenderer* renderer, JPH_RVec3* center, float radius, JPH_Color color, JPH_DebugRenderer_CastShadow castShadow, JPH_DebugRenderer_DrawMode drawMode);
	[CLink] public static extern void JPH_DebugRenderer_DrawUnitSphere(JPH_DebugRenderer* renderer, JPH_RMat4 matrix, JPH_Color color, JPH_DebugRenderer_CastShadow castShadow, JPH_DebugRenderer_DrawMode drawMode);
	[CLink] public static extern void JPH_DebugRenderer_DrawCapsule(JPH_DebugRenderer* renderer, JPH_RMat4* matrix, float halfHeightOfCylinder, float radius, JPH_Color color, JPH_DebugRenderer_CastShadow castShadow, JPH_DebugRenderer_DrawMode drawMode);
	[CLink] public static extern void JPH_DebugRenderer_DrawCylinder(JPH_DebugRenderer* renderer, JPH_RMat4* matrix, float halfHeight, float radius, JPH_Color color, JPH_DebugRenderer_CastShadow castShadow, JPH_DebugRenderer_DrawMode drawMode);
	[CLink] public static extern void JPH_DebugRenderer_DrawOpenCone(JPH_DebugRenderer* renderer, JPH_RVec3* top, JPH_Vec3* axis, JPH_Vec3* perpendicular, float halfAngle, float length, JPH_Color color, JPH_DebugRenderer_CastShadow castShadow, JPH_DebugRenderer_DrawMode drawMode);
	[CLink] public static extern void JPH_DebugRenderer_DrawSwingConeLimits(JPH_DebugRenderer* renderer, JPH_RMat4* matrix, float swingYHalfAngle, float swingZHalfAngle, float edgeLength, JPH_Color color, JPH_DebugRenderer_CastShadow castShadow, JPH_DebugRenderer_DrawMode drawMode);
	[CLink] public static extern void JPH_DebugRenderer_DrawSwingPyramidLimits(JPH_DebugRenderer* renderer, JPH_RMat4* matrix, float minSwingYAngle, float maxSwingYAngle, float minSwingZAngle, float maxSwingZAngle, float edgeLength, JPH_Color color, JPH_DebugRenderer_CastShadow castShadow, JPH_DebugRenderer_DrawMode drawMode);
	[CLink] public static extern void JPH_DebugRenderer_DrawPie(JPH_DebugRenderer* renderer, JPH_RVec3* center, float radius, JPH_Vec3* normal, JPH_Vec3* axis, float minAngle, float maxAngle, JPH_Color color, JPH_DebugRenderer_CastShadow castShadow, JPH_DebugRenderer_DrawMode drawMode);
	[CLink] public static extern void JPH_DebugRenderer_DrawTaperedCylinder(JPH_DebugRenderer* renderer, JPH_RMat4* inMatrix, float top, float bottom, float topRadius, float bottomRadius, JPH_Color color, JPH_DebugRenderer_CastShadow castShadow, JPH_DebugRenderer_DrawMode drawMode);
}

	/* Skeleton */
[CRepr] struct JPH_SkeletonJoint
{
	char8*		name;
	char8*		parentName;
	int32				parentJointIndex;
}
static
{
	[CLink] public static extern JPH_Skeleton* JPH_Skeleton_Create();
	[CLink] public static extern void JPH_Skeleton_Destroy(JPH_Skeleton* skeleton);

	[CLink] public static extern uint32 JPH_Skeleton_AddJoint(JPH_Skeleton* skeleton, char8* name);
	[CLink] public static extern uint32 JPH_Skeleton_AddJoint2(JPH_Skeleton* skeleton, char8* name, int32 parentIndex);
	[CLink] public static extern uint32 JPH_Skeleton_AddJoint3(JPH_Skeleton* skeleton, char8* name, char8* parentName);
	[CLink] public static extern int32 JPH_Skeleton_GetJointCount(JPH_Skeleton* skeleton);
	[CLink] public static extern void JPH_Skeleton_GetJoint(JPH_Skeleton* skeleton, int32 index, JPH_SkeletonJoint* joint);
	[CLink] public static extern int32 JPH_Skeleton_GetJointIndex(JPH_Skeleton* skeleton, char8* name);
	[CLink] public static extern void JPH_Skeleton_CalculateParentJointIndices(JPH_Skeleton* skeleton);
	[CLink] public static extern bool JPH_Skeleton_AreJointsCorrectlyOrdered(JPH_Skeleton* skeleton);

	/* SkeletonPose */
	[CLink] public static extern JPH_SkeletonPose* JPH_SkeletonPose_Create();
	[CLink] public static extern void JPH_SkeletonPose_Destroy(JPH_SkeletonPose* pose);
	[CLink] public static extern void JPH_SkeletonPose_SetSkeleton(JPH_SkeletonPose* pose, JPH_Skeleton* skeleton);
	[CLink] public static extern JPH_Skeleton* JPH_SkeletonPose_GetSkeleton(JPH_SkeletonPose* pose);
	[CLink] public static extern void JPH_SkeletonPose_SetRootOffset(JPH_SkeletonPose* pose, JPH_RVec3* offset);
	[CLink] public static extern void JPH_SkeletonPose_GetRootOffset(JPH_SkeletonPose* pose, JPH_RVec3* result);
	[CLink] public static extern int32 JPH_SkeletonPose_GetJointCount(JPH_SkeletonPose* pose);
	[CLink] public static extern void JPH_SkeletonPose_GetJointState(JPH_SkeletonPose* pose, int32 index, JPH_Vec3* outTranslation, JPH_Quat* outRotation);
	[CLink] public static extern void JPH_SkeletonPose_SetJointState(JPH_SkeletonPose* pose, int32 index, JPH_Vec3* translation, JPH_Quat* rotation);
	[CLink] public static extern void JPH_SkeletonPose_GetJointMatrix(JPH_SkeletonPose* pose, int32 index, JPH_Mat4* result);
	[CLink] public static extern void JPH_SkeletonPose_SetJointMatrix(JPH_SkeletonPose* pose, int32 index, JPH_Mat4* matrix);
	[CLink] public static extern void JPH_SkeletonPose_GetJointMatrices(JPH_SkeletonPose* pose, JPH_Mat4* outMatrices, int32 count);
	[CLink] public static extern void JPH_SkeletonPose_SetJointMatrices(JPH_SkeletonPose* pose, JPH_Mat4* matrices, int32 count);
	[CLink] public static extern void JPH_SkeletonPose_CalculateJointMatrices(JPH_SkeletonPose* pose);
	[CLink] public static extern void JPH_SkeletonPose_CalculateJointStates(JPH_SkeletonPose* pose);
	[CLink] public static extern void JPH_SkeletonPose_CalculateLocalSpaceJointMatrices(JPH_SkeletonPose* pose, JPH_Mat4* outMatrices);

	/* SkeletalAnimation */
	[CLink] public static extern JPH_SkeletalAnimation* JPH_SkeletalAnimation_Create();
	[CLink] public static extern void JPH_SkeletalAnimation_Destroy(JPH_SkeletalAnimation* animation);
	[CLink] public static extern float JPH_SkeletalAnimation_GetDuration(JPH_SkeletalAnimation* animation);
	[CLink] public static extern bool JPH_SkeletalAnimation_IsLooping(JPH_SkeletalAnimation* animation);
	[CLink] public static extern void JPH_SkeletalAnimation_SetIsLooping(JPH_SkeletalAnimation* animation, bool looping);
	[CLink] public static extern void JPH_SkeletalAnimation_ScaleJoints(JPH_SkeletalAnimation* animation, float scale);
	[CLink] public static extern void JPH_SkeletalAnimation_Sample(JPH_SkeletalAnimation* animation, float time, JPH_SkeletonPose* pose);
	[CLink] public static extern int32 JPH_SkeletalAnimation_GetAnimatedJointCount(JPH_SkeletalAnimation* animation);
	[CLink] public static extern void JPH_SkeletalAnimation_AddAnimatedJoint(JPH_SkeletalAnimation* animation, char8* jointName);
	[CLink] public static extern void JPH_SkeletalAnimation_AddKeyframe(JPH_SkeletalAnimation* animation, int32 jointIndex, float time, JPH_Vec3* translation, JPH_Quat* rotation);

	/* SkeletonMapper */
	[CLink] public static extern JPH_SkeletonMapper* JPH_SkeletonMapper_Create();
	[CLink] public static extern void JPH_SkeletonMapper_Destroy(JPH_SkeletonMapper* mapper);
	[CLink] public static extern void JPH_SkeletonMapper_Initialize(JPH_SkeletonMapper* mapper, JPH_Skeleton* skeleton1, JPH_Mat4* neutralPose1, JPH_Skeleton* skeleton2, JPH_Mat4* neutralPose2);
	[CLink] public static extern void JPH_SkeletonMapper_LockAllTranslations(JPH_SkeletonMapper* mapper, JPH_Skeleton* skeleton2, JPH_Mat4* neutralPose2);
	[CLink] public static extern void JPH_SkeletonMapper_LockTranslations(JPH_SkeletonMapper* mapper, JPH_Skeleton* skeleton2, bool* lockedTranslations, JPH_Mat4* neutralPose2);
	[CLink] public static extern void JPH_SkeletonMapper_Map(JPH_SkeletonMapper* mapper, JPH_Mat4* pose1ModelSpace, JPH_Mat4* pose2LocalSpace, JPH_Mat4* outPose2ModelSpace);
	[CLink] public static extern void JPH_SkeletonMapper_MapReverse(JPH_SkeletonMapper* mapper, JPH_Mat4* pose2ModelSpace, JPH_Mat4* outPose1ModelSpace);
	[CLink] public static extern int32 JPH_SkeletonMapper_GetMappedJointIndex(JPH_SkeletonMapper* mapper, int32 joint1Index);
	[CLink] public static extern bool JPH_SkeletonMapper_IsJointTranslationLocked(JPH_SkeletonMapper* mapper, int32 joint2Index);

	/* RagdollSettings */
	[CLink] public static extern JPH_RagdollSettings* JPH_RagdollSettings_Create();
	[CLink] public static extern void JPH_RagdollSettings_Destroy(JPH_RagdollSettings* settings);

	[CLink] public static extern JPH_Skeleton* JPH_RagdollSettings_GetSkeleton(JPH_RagdollSettings* character);
	[CLink] public static extern void JPH_RagdollSettings_SetSkeleton(JPH_RagdollSettings* character, JPH_Skeleton* skeleton);
	[CLink] public static extern bool JPH_RagdollSettings_Stabilize(JPH_RagdollSettings* settings);
	[CLink] public static extern void JPH_RagdollSettings_DisableParentChildCollisions(JPH_RagdollSettings* settings, JPH_Mat4* jointMatrices /*=nullptr*/, float minSeparationDistance /* = 0.0f*/);
	[CLink] public static extern void JPH_RagdollSettings_CalculateBodyIndexToConstraintIndex(JPH_RagdollSettings* settings);
	[CLink] public static extern int32 JPH_RagdollSettings_GetConstraintIndexForBodyIndex(JPH_RagdollSettings* settings, int32 bodyIndex);
	[CLink] public static extern void JPH_RagdollSettings_CalculateConstraintIndexToBodyIdxPair(JPH_RagdollSettings* settings);

	[CLink] public static extern void JPH_RagdollSettings_ResizeParts(JPH_RagdollSettings* settings, int32 count);
	[CLink] public static extern int32 JPH_RagdollSettings_GetPartCount(JPH_RagdollSettings* settings);
	[CLink] public static extern void JPH_RagdollSettings_SetPartShape(JPH_RagdollSettings* settings, int32 partIndex, JPH_Shape* shape);
	[CLink] public static extern void JPH_RagdollSettings_SetPartPosition(JPH_RagdollSettings* settings, int32 partIndex, JPH_RVec3* position);
	[CLink] public static extern void JPH_RagdollSettings_SetPartRotation(JPH_RagdollSettings* settings, int32 partIndex, JPH_Quat* rotation);
	[CLink] public static extern void JPH_RagdollSettings_SetPartMotionType(JPH_RagdollSettings* settings, int32 partIndex, JPH_MotionType motionType);
	[CLink] public static extern void JPH_RagdollSettings_SetPartObjectLayer(JPH_RagdollSettings* settings, int32 partIndex, JPH_ObjectLayer layer);
	[CLink] public static extern void JPH_RagdollSettings_SetPartMassProperties(JPH_RagdollSettings* settings, int32 partIndex, float mass);
	[CLink] public static extern void JPH_RagdollSettings_SetPartToParent(JPH_RagdollSettings* settings, int32 partIndex, JPH_SwingTwistConstraintSettings* constraintSettings);

	[CLink] public static extern JPH_Ragdoll* JPH_RagdollSettings_CreateRagdoll(JPH_RagdollSettings* settings, JPH_PhysicsSystem* system, JPH_CollisionGroupID collisionGroup /*=0*/, uint64 userData /* = 0*/);

	/* Ragdoll */
	[CLink] public static extern void JPH_Ragdoll_Destroy(JPH_Ragdoll* ragdoll);
	[CLink] public static extern void JPH_Ragdoll_AddToPhysicsSystem(JPH_Ragdoll* ragdoll, JPH_Activation activationMode /*= JPH_ActivationActivate */, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Ragdoll_RemoveFromPhysicsSystem(JPH_Ragdoll* ragdoll, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Ragdoll_Activate(JPH_Ragdoll* ragdoll, bool lockBodies /* = true */);
	[CLink] public static extern bool JPH_Ragdoll_IsActive(JPH_Ragdoll* ragdoll, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Ragdoll_ResetWarmStart(JPH_Ragdoll* ragdoll);
	[CLink] public static extern void JPH_Ragdoll_SetPose(JPH_Ragdoll* ragdoll, JPH_SkeletonPose* pose, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Ragdoll_SetPose2(JPH_Ragdoll* ragdoll, JPH_RVec3* rootOffset, JPH_Mat4* jointMatrices, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Ragdoll_GetPose(JPH_Ragdoll* ragdoll, JPH_SkeletonPose* outPose, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Ragdoll_GetPose2(JPH_Ragdoll* ragdoll, JPH_RVec3* outRootOffset, JPH_Mat4* outJointMatrices, bool lockBodies /* = true */);
	[CLink] public static extern void JPH_Ragdoll_DriveToPoseUsingMotors(JPH_Ragdoll* ragdoll, JPH_SkeletonPose* pose);
	[CLink] public static extern void JPH_Ragdoll_DriveToPoseUsingKinematics(JPH_Ragdoll* ragdoll, JPH_SkeletonPose* pose, float deltaTime, bool lockBodies /* = true */);
	[CLink] public static extern int32 JPH_Ragdoll_GetBodyCount(JPH_Ragdoll* ragdoll);
	[CLink] public static extern JPH_BodyID JPH_Ragdoll_GetBodyID(JPH_Ragdoll* ragdoll, int32 bodyIndex);
	[CLink] public static extern int32 JPH_Ragdoll_GetConstraintCount(JPH_Ragdoll* ragdoll);
	[CLink] public static extern JPH_TwoBodyConstraint* JPH_Ragdoll_GetConstraint(JPH_Ragdoll* ragdoll, int32 constraintIndex);
	[CLink] public static extern void JPH_Ragdoll_GetRootTransform(JPH_Ragdoll* ragdoll, JPH_RVec3* outPosition, JPH_Quat* outRotation, bool lockBodies /* = true */);
	[CLink] public static extern JPH_RagdollSettings* JPH_Ragdoll_GetRagdollSettings(JPH_Ragdoll* ragdoll);

	/* JPH_EstimateCollisionResponse */
	[CLink] public static extern void JPH_EstimateCollisionResponse(JPH_Body* body1, JPH_Body* body2, JPH_ContactManifold* manifold, float combinedFriction, float combinedRestitution, float minVelocityForRestitution, uint32 numIterations, JPH_CollisionEstimationResult* result);

	/* Vehicle */
	[CRepr] struct JPH_WheelSettings						;
	[CRepr] struct JPH_WheelSettingsWV						; /* Inherits JPH_WheelSettings */
	[CRepr] struct JPH_WheelSettingsTV						; /* Inherits JPH_WheelSettings */

	[CRepr] struct JPH_Wheel								;
	[CRepr] struct JPH_WheelWV								; /* Inherits JPH_Wheel */
	[CRepr] struct JPH_WheelTV								; /* Inherits JPH_Wheel */

	[CRepr] struct JPH_VehicleEngine						;
	[CRepr] struct JPH_VehicleTransmission					;
	[CRepr] struct JPH_VehicleTransmissionSettings			;
	[CRepr] struct JPH_VehicleCollisionTester				;
	[CRepr] struct JPH_VehicleCollisionTesterRay			; /* Inherits JPH_VehicleCollisionTester */
	[CRepr] struct JPH_VehicleCollisionTesterCastSphere		; /* Inherits JPH_VehicleCollisionTester */
	[CRepr] struct JPH_VehicleCollisionTesterCastCylinder	; /* Inherits JPH_VehicleCollisionTester */
	[CRepr] struct JPH_VehicleConstraint					; /* Inherits JPH_Constraint */

	[CRepr] struct JPH_VehicleControllerSettings			;
	[CRepr] struct JPH_WheeledVehicleControllerSettings		; /* Inherits JPH_VehicleControllerSettings */
	[CRepr] struct JPH_MotorcycleControllerSettings			; /* Inherits JPH_WheeledVehicleControllerSettings */
	[CRepr] struct JPH_TrackedVehicleControllerSettings		; /* Inherits JPH_VehicleControllerSettings */

	[CRepr] struct JPH_WheeledVehicleController				; /* Inherits JPH_VehicleController */
	[CRepr] struct JPH_MotorcycleController					; /* Inherits JPH_WheeledVehicleController */
	[CRepr] struct JPH_TrackedVehicleController				; /* Inherits JPH_VehicleController */
}

[CRepr] struct JPH_VehicleController					;

[CRepr] struct JPH_VehicleAntiRollBar
{
	int32						leftWheel;
	int32						rightWheel;
	float					stiffness;
}

[CRepr] struct JPH_VehicleConstraintSettings
{
	JPH_ConstraintSettings			@base; /* Inherits JPH_ConstraintSettings */

	JPH_Vec3						up;
	JPH_Vec3						forward;
	float							maxPitchRollAngle;
	uint32						wheelsCount;
	JPH_WheelSettings**				wheels;
	uint32						antiRollBarsCount;
	JPH_VehicleAntiRollBar*	antiRollBars;
	JPH_VehicleControllerSettings*	controller;
}

[CRepr] struct JPH_VehicleEngineSettings
{
	float					maxTorque;
	float					minRPM;
	float					maxRPM;
	JPH_LinearCurve*	normalizedTorque;
	float					inertia;
	float					angularDamping;
}

[CRepr] struct JPH_VehicleDifferentialSettings
{
	int32		leftWheel;
	int32		rightWheel;
	float	differentialRatio;
	float	leftRightSplit;
	float	limitedSlipRatio;
	float	engineTorqueRatio;
}
static
{
	[CLink] public static extern void JPH_VehicleConstraintSettings_Init(JPH_VehicleConstraintSettings* settings);

	[CLink] public static extern JPH_VehicleConstraint* JPH_VehicleConstraint_Create(JPH_Body* body, JPH_VehicleConstraintSettings* settings);
	[CLink] public static extern JPH_PhysicsStepListener* JPH_VehicleConstraint_AsPhysicsStepListener(JPH_VehicleConstraint* constraint);

	[CLink] public static extern void JPH_VehicleConstraint_SetMaxPitchRollAngle(JPH_VehicleConstraint* constraint, float maxPitchRollAngle);
	[CLink] public static extern void JPH_VehicleConstraint_SetVehicleCollisionTester(JPH_VehicleConstraint* constraint, JPH_VehicleCollisionTester* tester);

	[CLink] public static extern void JPH_VehicleConstraint_OverrideGravity(JPH_VehicleConstraint* constraint, JPH_Vec3* value);
	[CLink] public static extern bool JPH_VehicleConstraint_IsGravityOverridden(JPH_VehicleConstraint* constraint);
	[CLink] public static extern void JPH_VehicleConstraint_GetGravityOverride(JPH_VehicleConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_VehicleConstraint_ResetGravityOverride(JPH_VehicleConstraint* constraint);

	[CLink] public static extern void JPH_VehicleConstraint_GetLocalForward(JPH_VehicleConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_VehicleConstraint_GetLocalUp(JPH_VehicleConstraint* constraint, JPH_Vec3* result);
	[CLink] public static extern void JPH_VehicleConstraint_GetWorldUp(JPH_VehicleConstraint* constraint, JPH_Vec3* result);

	[CLink] public static extern JPH_Body* JPH_VehicleConstraint_GetVehicleBody(JPH_VehicleConstraint* constraint);
	[CLink] public static extern JPH_VehicleController* JPH_VehicleConstraint_GetController(JPH_VehicleConstraint* constraint);
	[CLink] public static extern uint32 JPH_VehicleConstraint_GetWheelsCount(JPH_VehicleConstraint* constraint);
	[CLink] public static extern JPH_Wheel* JPH_VehicleConstraint_GetWheel(JPH_VehicleConstraint* constraint, uint32 index);
	[CLink] public static extern void JPH_VehicleConstraint_GetWheelLocalBasis(JPH_VehicleConstraint* constraint, JPH_Wheel* wheel, JPH_Vec3* outForward, JPH_Vec3* outUp, JPH_Vec3* outRight);
	[CLink] public static extern void JPH_VehicleConstraint_GetWheelLocalTransform(JPH_VehicleConstraint* constraint, uint32 wheelIndex, JPH_Vec3* wheelRight, JPH_Vec3* wheelUp, JPH_Mat4* result);
	[CLink] public static extern void JPH_VehicleConstraint_GetWheelWorldTransform(JPH_VehicleConstraint* constraint, uint32 wheelIndex, JPH_Vec3* wheelRight, JPH_Vec3* wheelUp, JPH_RMat4* result);

	/* Wheel */
	[CLink] public static extern JPH_WheelSettings* JPH_WheelSettings_Create();
	[CLink] public static extern void JPH_WheelSettings_Destroy(JPH_WheelSettings* settings);
	[CLink] public static extern void JPH_WheelSettings_GetPosition(JPH_WheelSettings* settings, JPH_Vec3* result);
	[CLink] public static extern void JPH_WheelSettings_SetPosition(JPH_WheelSettings* settings, JPH_Vec3* value);
	[CLink] public static extern void JPH_WheelSettings_GetSuspensionForcePoint(JPH_WheelSettings* settings, JPH_Vec3* result);
	[CLink] public static extern void JPH_WheelSettings_SetSuspensionForcePoint(JPH_WheelSettings* settings, JPH_Vec3* value);
	[CLink] public static extern void JPH_WheelSettings_GetSuspensionDirection(JPH_WheelSettings* settings, JPH_Vec3* result);
	[CLink] public static extern void JPH_WheelSettings_SetSuspensionDirection(JPH_WheelSettings* settings, JPH_Vec3* value);
	[CLink] public static extern void JPH_WheelSettings_GetSteeringAxis(JPH_WheelSettings* settings, JPH_Vec3* result);
	[CLink] public static extern void JPH_WheelSettings_SetSteeringAxis(JPH_WheelSettings* settings, JPH_Vec3* value);
	[CLink] public static extern void JPH_WheelSettings_GetWheelUp(JPH_WheelSettings* settings, JPH_Vec3* result);
	[CLink] public static extern void JPH_WheelSettings_SetWheelUp(JPH_WheelSettings* settings, JPH_Vec3* value);
	[CLink] public static extern void JPH_WheelSettings_GetWheelForward(JPH_WheelSettings* settings, JPH_Vec3* result);
	[CLink] public static extern void JPH_WheelSettings_SetWheelForward(JPH_WheelSettings* settings, JPH_Vec3* value);
	[CLink] public static extern float JPH_WheelSettings_GetSuspensionMinLength(JPH_WheelSettings* settings);
	[CLink] public static extern void JPH_WheelSettings_SetSuspensionMinLength(JPH_WheelSettings* settings, float value);
	[CLink] public static extern float JPH_WheelSettings_GetSuspensionMaxLength(JPH_WheelSettings* settings);
	[CLink] public static extern void JPH_WheelSettings_SetSuspensionMaxLength(JPH_WheelSettings* settings, float value);
	[CLink] public static extern float JPH_WheelSettings_GetSuspensionPreloadLength(JPH_WheelSettings* settings);
	[CLink] public static extern void JPH_WheelSettings_SetSuspensionPreloadLength(JPH_WheelSettings* settings, float value);
	[CLink] public static extern void JPH_WheelSettings_GetSuspensionSpring(JPH_WheelSettings* settings, JPH_SpringSettings* result);
	[CLink] public static extern void JPH_WheelSettings_SetSuspensionSpring(JPH_WheelSettings* settings, JPH_SpringSettings* springSettings);
	[CLink] public static extern float JPH_WheelSettings_GetRadius(JPH_WheelSettings* settings);
	[CLink] public static extern void JPH_WheelSettings_SetRadius(JPH_WheelSettings* settings, float value);
	[CLink] public static extern float JPH_WheelSettings_GetWidth(JPH_WheelSettings* settings);
	[CLink] public static extern void JPH_WheelSettings_SetWidth(JPH_WheelSettings* settings, float value);
	[CLink] public static extern bool JPH_WheelSettings_GetEnableSuspensionForcePoint(JPH_WheelSettings* settings);
	[CLink] public static extern void JPH_WheelSettings_SetEnableSuspensionForcePoint(JPH_WheelSettings* settings, bool value);

	[CLink] public static extern JPH_Wheel* JPH_Wheel_Create(JPH_WheelSettings* settings);
	[CLink] public static extern void JPH_Wheel_Destroy(JPH_Wheel* wheel);
	[CLink] public static extern JPH_WheelSettings* JPH_Wheel_GetSettings(JPH_Wheel* wheel);
	[CLink] public static extern float JPH_Wheel_GetAngularVelocity(JPH_Wheel* wheel);
	[CLink] public static extern void JPH_Wheel_SetAngularVelocity(JPH_Wheel* wheel, float value);
	[CLink] public static extern float JPH_Wheel_GetRotationAngle(JPH_Wheel* wheel);
	[CLink] public static extern void JPH_Wheel_SetRotationAngle(JPH_Wheel* wheel, float value);
	[CLink] public static extern float JPH_Wheel_GetSteerAngle(JPH_Wheel* wheel);
	[CLink] public static extern void JPH_Wheel_SetSteerAngle(JPH_Wheel* wheel, float value);
	[CLink] public static extern bool JPH_Wheel_HasContact(JPH_Wheel* wheel);
	[CLink] public static extern JPH_BodyID JPH_Wheel_GetContactBodyID(JPH_Wheel* wheel);
	[CLink] public static extern JPH_SubShapeID JPH_Wheel_GetContactSubShapeID(JPH_Wheel* wheel);
	[CLink] public static extern void JPH_Wheel_GetContactPosition(JPH_Wheel* wheel, JPH_RVec3* result);
	[CLink] public static extern void JPH_Wheel_GetContactPointVelocity(JPH_Wheel* wheel, JPH_Vec3* result);
	[CLink] public static extern void JPH_Wheel_GetContactNormal(JPH_Wheel* wheel, JPH_Vec3* result);
	[CLink] public static extern void JPH_Wheel_GetContactLongitudinal(JPH_Wheel* wheel, JPH_Vec3* result);
	[CLink] public static extern void JPH_Wheel_GetContactLateral(JPH_Wheel* wheel, JPH_Vec3* result);
	[CLink] public static extern float JPH_Wheel_GetSuspensionLength(JPH_Wheel* wheel);
	[CLink] public static extern float JPH_Wheel_GetSuspensionLambda(JPH_Wheel* wheel);
	[CLink] public static extern float JPH_Wheel_GetLongitudinalLambda(JPH_Wheel* wheel);
	[CLink] public static extern float JPH_Wheel_GetLateralLambda(JPH_Wheel* wheel);
	[CLink] public static extern bool JPH_Wheel_HasHitHardPoint(JPH_Wheel* wheel);

	/* VehicleAntiRollBar */
	[CLink] public static extern void JPH_VehicleAntiRollBar_Init(JPH_VehicleAntiRollBar* antiRollBar);

	/* VehicleEngineSettings */
	[CLink] public static extern void JPH_VehicleEngineSettings_Init(JPH_VehicleEngineSettings* settings);

	/* VehicleEngine */
	[CLink] public static extern void JPH_VehicleEngine_ClampRPM(JPH_VehicleEngine* engine);
	[CLink] public static extern float JPH_VehicleEngine_GetCurrentRPM(JPH_VehicleEngine* engine);
	[CLink] public static extern void JPH_VehicleEngine_SetCurrentRPM(JPH_VehicleEngine* engine, float rpm);
	[CLink] public static extern float JPH_VehicleEngine_GetAngularVelocity(JPH_VehicleEngine* engine);
	[CLink] public static extern float JPH_VehicleEngine_GetTorque(JPH_VehicleEngine* engine, float acceleration);
	[CLink] public static extern void JPH_VehicleEngine_ApplyTorque(JPH_VehicleEngine* engine, float torque, float deltaTime);
	[CLink] public static extern void JPH_VehicleEngine_ApplyDamping(JPH_VehicleEngine* engine, float deltaTime);
	[CLink] public static extern bool JPH_VehicleEngine_AllowSleep(JPH_VehicleEngine* engine);

	/* VehicleDifferentialSettings */
	[CLink] public static extern void JPH_VehicleDifferentialSettings_Init(JPH_VehicleDifferentialSettings* settings);

	/* VehicleTransmissionSettings */
	[CLink] public static extern JPH_VehicleTransmissionSettings* JPH_VehicleTransmissionSettings_Create();
	[CLink] public static extern void JPH_VehicleTransmissionSettings_Destroy(JPH_VehicleTransmissionSettings* settings);

	[CLink] public static extern JPH_TransmissionMode JPH_VehicleTransmissionSettings_GetMode(JPH_VehicleTransmissionSettings* settings);
	[CLink] public static extern void JPH_VehicleTransmissionSettings_SetMode(JPH_VehicleTransmissionSettings* settings, JPH_TransmissionMode value);

	[CLink] public static extern uint32 JPH_VehicleTransmissionSettings_GetGearRatioCount(JPH_VehicleTransmissionSettings* settings);
	[CLink] public static extern float JPH_VehicleTransmissionSettings_GetGearRatio(JPH_VehicleTransmissionSettings* settings, uint32 index);
	[CLink] public static extern void JPH_VehicleTransmissionSettings_SetGearRatio(JPH_VehicleTransmissionSettings* settings, uint32 index, float value);
	[CLink] public static extern float* JPH_VehicleTransmissionSettings_GetGearRatios(JPH_VehicleTransmissionSettings* settings);
	[CLink] public static extern void JPH_VehicleTransmissionSettings_SetGearRatios(JPH_VehicleTransmissionSettings* settings, float* values, uint32 count);

	[CLink] public static extern uint32 JPH_VehicleTransmissionSettings_GetReverseGearRatioCount(JPH_VehicleTransmissionSettings* settings);
	[CLink] public static extern float JPH_VehicleTransmissionSettings_GetReverseGearRatio(JPH_VehicleTransmissionSettings* settings, uint32 index);
	[CLink] public static extern void JPH_VehicleTransmissionSettings_SetReverseGearRatio(JPH_VehicleTransmissionSettings* settings, uint32 index, float value);
	[CLink] public static extern float* JPH_VehicleTransmissionSettings_GetReverseGearRatios(JPH_VehicleTransmissionSettings* settings);
	[CLink] public static extern void JPH_VehicleTransmissionSettings_SetReverseGearRatios(JPH_VehicleTransmissionSettings* settings, float* values, uint32 count);

	[CLink] public static extern float JPH_VehicleTransmissionSettings_GetSwitchTime(JPH_VehicleTransmissionSettings* settings);
	[CLink] public static extern void JPH_VehicleTransmissionSettings_SetSwitchTime(JPH_VehicleTransmissionSettings* settings, float value);
	[CLink] public static extern float JPH_VehicleTransmissionSettings_GetClutchReleaseTime(JPH_VehicleTransmissionSettings* settings);
	[CLink] public static extern void JPH_VehicleTransmissionSettings_SetClutchReleaseTime(JPH_VehicleTransmissionSettings* settings, float value);
	[CLink] public static extern float JPH_VehicleTransmissionSettings_GetSwitchLatency(JPH_VehicleTransmissionSettings* settings);
	[CLink] public static extern void JPH_VehicleTransmissionSettings_SetSwitchLatency(JPH_VehicleTransmissionSettings* settings, float value);
	[CLink] public static extern float JPH_VehicleTransmissionSettings_GetShiftUpRPM(JPH_VehicleTransmissionSettings* settings);
	[CLink] public static extern void JPH_VehicleTransmissionSettings_SetShiftUpRPM(JPH_VehicleTransmissionSettings* settings, float value);
	[CLink] public static extern float JPH_VehicleTransmissionSettings_GetShiftDownRPM(JPH_VehicleTransmissionSettings* settings);
	[CLink] public static extern void JPH_VehicleTransmissionSettings_SetShiftDownRPM(JPH_VehicleTransmissionSettings* settings, float value);
	[CLink] public static extern float JPH_VehicleTransmissionSettings_GetClutchStrength(JPH_VehicleTransmissionSettings* settings);
	[CLink] public static extern void JPH_VehicleTransmissionSettings_SetClutchStrength(JPH_VehicleTransmissionSettings* settings, float value);

	/* VehicleTransmission */
	[CLink] public static extern void JPH_VehicleTransmission_Set(JPH_VehicleTransmission* transmission, int32 currentGear, float clutchFriction);
	[CLink] public static extern void JPH_VehicleTransmission_Update(JPH_VehicleTransmission* transmission, float deltaTime, float currentRPM, float forwardInput, bool canShiftUp);
	[CLink] public static extern int32 JPH_VehicleTransmission_GetCurrentGear(JPH_VehicleTransmission* transmission);
	[CLink] public static extern float JPH_VehicleTransmission_GetClutchFriction(JPH_VehicleTransmission* transmission);
	[CLink] public static extern bool JPH_VehicleTransmission_IsSwitchingGear(JPH_VehicleTransmission* transmission);
	[CLink] public static extern float JPH_VehicleTransmission_GetCurrentRatio(JPH_VehicleTransmission* transmission);
	[CLink] public static extern bool JPH_VehicleTransmission_AllowSleep(JPH_VehicleTransmission* transmission);

	/* VehicleCollisionTester */
	[CLink] public static extern void JPH_VehicleCollisionTester_Destroy(JPH_VehicleCollisionTester* tester);
	[CLink] public static extern JPH_ObjectLayer JPH_VehicleCollisionTester_GetObjectLayer(JPH_VehicleCollisionTester* tester);
	[CLink] public static extern void JPH_VehicleCollisionTester_SetObjectLayer(JPH_VehicleCollisionTester* tester, JPH_ObjectLayer value);

	[CLink] public static extern JPH_VehicleCollisionTesterRay* JPH_VehicleCollisionTesterRay_Create(JPH_ObjectLayer layer, JPH_Vec3* up, float maxSlopeAngle);
	[CLink] public static extern JPH_VehicleCollisionTesterCastSphere* JPH_VehicleCollisionTesterCastSphere_Create(JPH_ObjectLayer layer, float radius, JPH_Vec3* up, float maxSlopeAngle);
	[CLink] public static extern JPH_VehicleCollisionTesterCastCylinder* JPH_VehicleCollisionTesterCastCylinder_Create(JPH_ObjectLayer layer, float convexRadiusFraction);

	/* VehicleControllerSettings/VehicleController */
	[CLink] public static extern void JPH_VehicleControllerSettings_Destroy(JPH_VehicleControllerSettings* settings);
	[CLink] public static extern JPH_VehicleConstraint* JPH_VehicleController_GetConstraint(JPH_VehicleController* controller);

	/* ---- WheelSettingsWV - WheelWV - WheeledVehicleController ---- */

	[CLink] public static extern JPH_WheelSettingsWV* JPH_WheelSettingsWV_Create();
	[CLink] public static extern float JPH_WheelSettingsWV_GetInertia(JPH_WheelSettingsWV* settings);
	[CLink] public static extern void JPH_WheelSettingsWV_SetInertia(JPH_WheelSettingsWV* settings, float value);
	[CLink] public static extern float JPH_WheelSettingsWV_GetAngularDamping(JPH_WheelSettingsWV* settings);
	[CLink] public static extern void JPH_WheelSettingsWV_SetAngularDamping(JPH_WheelSettingsWV* settings, float value);
	[CLink] public static extern float JPH_WheelSettingsWV_GetMaxSteerAngle(JPH_WheelSettingsWV* settings);
	[CLink] public static extern void JPH_WheelSettingsWV_SetMaxSteerAngle(JPH_WheelSettingsWV* settings, float value);
	[CLink] public static extern JPH_LinearCurve* JPH_WheelSettingsWV_GetLongitudinalFriction(JPH_WheelSettingsWV* settings);
	[CLink] public static extern void JPH_WheelSettingsWV_SetLongitudinalFriction(JPH_WheelSettingsWV* settings, JPH_LinearCurve* value);
	[CLink] public static extern JPH_LinearCurve* JPH_WheelSettingsWV_GetLateralFriction(JPH_WheelSettingsWV* settings);
	[CLink] public static extern void JPH_WheelSettingsWV_SetLateralFriction(JPH_WheelSettingsWV* settings, JPH_LinearCurve* value);
	[CLink] public static extern float JPH_WheelSettingsWV_GetMaxBrakeTorque(JPH_WheelSettingsWV* settings);
	[CLink] public static extern void JPH_WheelSettingsWV_SetMaxBrakeTorque(JPH_WheelSettingsWV* settings, float value);
	[CLink] public static extern float JPH_WheelSettingsWV_GetMaxHandBrakeTorque(JPH_WheelSettingsWV* settings);
	[CLink] public static extern void JPH_WheelSettingsWV_SetMaxHandBrakeTorque(JPH_WheelSettingsWV* settings, float value);

	[CLink] public static extern JPH_WheelWV* JPH_WheelWV_Create(JPH_WheelSettingsWV* settings);
	[CLink] public static extern JPH_WheelSettingsWV* JPH_WheelWV_GetSettings(JPH_WheelWV* wheel);
	[CLink] public static extern void JPH_WheelWV_ApplyTorque(JPH_WheelWV* wheel, float torque, float deltaTime);

	[CLink] public static extern JPH_WheeledVehicleControllerSettings* JPH_WheeledVehicleControllerSettings_Create();

	[CLink] public static extern void JPH_WheeledVehicleControllerSettings_GetEngine(JPH_WheeledVehicleControllerSettings* settings, JPH_VehicleEngineSettings* result);
	[CLink] public static extern void JPH_WheeledVehicleControllerSettings_SetEngine(JPH_WheeledVehicleControllerSettings* settings, JPH_VehicleEngineSettings* value);
	[CLink] public static extern JPH_VehicleTransmissionSettings* JPH_WheeledVehicleControllerSettings_GetTransmission(JPH_WheeledVehicleControllerSettings* settings);
	[CLink] public static extern void JPH_WheeledVehicleControllerSettings_SetTransmission(JPH_WheeledVehicleControllerSettings* settings, JPH_VehicleTransmissionSettings* value);

	[CLink] public static extern uint32 JPH_WheeledVehicleControllerSettings_GetDifferentialsCount(JPH_WheeledVehicleControllerSettings* settings);
	[CLink] public static extern void JPH_WheeledVehicleControllerSettings_SetDifferentialsCount(JPH_WheeledVehicleControllerSettings* settings, uint32 count);
	[CLink] public static extern void JPH_WheeledVehicleControllerSettings_GetDifferential(JPH_WheeledVehicleControllerSettings* settings, uint32 index, JPH_VehicleDifferentialSettings* result);
	[CLink] public static extern void JPH_WheeledVehicleControllerSettings_SetDifferential(JPH_WheeledVehicleControllerSettings* settings, uint32 index, JPH_VehicleDifferentialSettings* value);
	[CLink] public static extern void JPH_WheeledVehicleControllerSettings_SetDifferentials(JPH_WheeledVehicleControllerSettings* settings, JPH_VehicleDifferentialSettings* values, uint32 count);

	[CLink] public static extern float JPH_WheeledVehicleControllerSettings_GetDifferentialLimitedSlipRatio(JPH_WheeledVehicleControllerSettings* settings);
	[CLink] public static extern void JPH_WheeledVehicleControllerSettings_SetDifferentialLimitedSlipRatio(JPH_WheeledVehicleControllerSettings* settings, float value);

	[CLink] public static extern void JPH_WheeledVehicleController_SetDriverInput(JPH_WheeledVehicleController* controller, float forward, float right, float brake, float handBrake);
	[CLink] public static extern void JPH_WheeledVehicleController_SetForwardInput(JPH_WheeledVehicleController* controller, float forward);
	[CLink] public static extern float JPH_WheeledVehicleController_GetForwardInput(JPH_WheeledVehicleController* controller);
	[CLink] public static extern void JPH_WheeledVehicleController_SetRightInput(JPH_WheeledVehicleController* controller, float rightRatio);
	[CLink] public static extern float JPH_WheeledVehicleController_GetRightInput(JPH_WheeledVehicleController* controller);
	[CLink] public static extern void JPH_WheeledVehicleController_SetBrakeInput(JPH_WheeledVehicleController* controller, float brakeInput);
	[CLink] public static extern float JPH_WheeledVehicleController_GetBrakeInput(JPH_WheeledVehicleController* controller);
	[CLink] public static extern void JPH_WheeledVehicleController_SetHandBrakeInput(JPH_WheeledVehicleController* controller, float handBrakeInput);
	[CLink] public static extern float JPH_WheeledVehicleController_GetHandBrakeInput(JPH_WheeledVehicleController* controller);
	[CLink] public static extern float JPH_WheeledVehicleController_GetWheelSpeedAtClutch(JPH_WheeledVehicleController* controller);
	[CLink] public static extern void JPH_WheeledVehicleController_SetTireMaxImpulseCallback(JPH_WheeledVehicleController* controller, JPH_TireMaxImpulseCallback tireMaxImpulseCallback, void* userData);
	[CLink] public static extern JPH_VehicleEngine* JPH_WheeledVehicleController_GetEngine(JPH_WheeledVehicleController* controller);
	[CLink] public static extern JPH_VehicleTransmission* JPH_WheeledVehicleController_GetTransmission(JPH_WheeledVehicleController* controller);
}

	/* WheelSettingsTV - WheelTV - TrackedVehicleController */
	/* WheelSettingsTV - WheelTV - TrackedVehicleController */

	/* VehicleTrack */
	//[CRepr] struct JPH_VehicleTrackSettings;
[CRepr] struct JPH_VehicleTrack;

enum JPH_TrackSide : int32
{
	JPH_TrackSide_Left = 0,
	JPH_TrackSide_Right = 1,
}

[CRepr] struct JPH_VehicleTrackSettings
{
	uint32					drivenWheel;
	uint32*				wheels;
	uint32					wheelsCount;
	float						inertia;
	float						angularDamping;
	float						maxBrakeTorque;
	float						differentialRatio;
}

static
{
	[CLink] public static extern void JPH_VehicleTrackSettings_Init(JPH_VehicleTrackSettings* settings);

	[CLink] public static extern float JPH_VehicleTrack_GetAngularVelocity(JPH_VehicleTrack* track);
	[CLink] public static extern void JPH_VehicleTrack_SetAngularVelocity(JPH_VehicleTrack* track, float velocity);
	[CLink] public static extern uint32 JPH_VehicleTrack_GetDrivenWheel(JPH_VehicleTrack* track);
	[CLink] public static extern float JPH_VehicleTrack_GetInertia(JPH_VehicleTrack* track);
	[CLink] public static extern float JPH_VehicleTrack_GetAngularDamping(JPH_VehicleTrack* track);
	[CLink] public static extern float JPH_VehicleTrack_GetMaxBrakeTorque(JPH_VehicleTrack* track);
	[CLink] public static extern float JPH_VehicleTrack_GetDifferentialRatio(JPH_VehicleTrack* track);

	[CLink] public static extern JPH_VehicleTrack* JPH_TrackedVehicleController_GetTrack(JPH_TrackedVehicleController* controller, JPH_TrackSide side);

	/* WheelSettingsTV */
	[CLink] public static extern JPH_WheelSettingsTV* JPH_WheelSettingsTV_Create();
	[CLink] public static extern float JPH_WheelSettingsTV_GetLongitudinalFriction(JPH_WheelSettingsTV* settings);
	[CLink] public static extern void JPH_WheelSettingsTV_SetLongitudinalFriction(JPH_WheelSettingsTV* settings, float value);
	[CLink] public static extern float JPH_WheelSettingsTV_GetLateralFriction(JPH_WheelSettingsTV* settings);
	[CLink] public static extern void JPH_WheelSettingsTV_SetLateralFriction(JPH_WheelSettingsTV* settings, float value);

	[CLink] public static extern JPH_WheelTV* JPH_WheelTV_Create(JPH_WheelSettingsTV* settings);
	[CLink] public static extern JPH_WheelSettingsTV* JPH_WheelTV_GetSettings(JPH_WheelTV* wheel);

	[CLink] public static extern JPH_TrackedVehicleControllerSettings* JPH_TrackedVehicleControllerSettings_Create();

	[CLink] public static extern void JPH_TrackedVehicleControllerSettings_GetEngine(JPH_TrackedVehicleControllerSettings* settings, JPH_VehicleEngineSettings* result);
	[CLink] public static extern void JPH_TrackedVehicleControllerSettings_SetEngine(JPH_TrackedVehicleControllerSettings* settings, JPH_VehicleEngineSettings* value);
	[CLink] public static extern JPH_VehicleTransmissionSettings* JPH_TrackedVehicleControllerSettings_GetTransmission(JPH_TrackedVehicleControllerSettings* settings);
	[CLink] public static extern void JPH_TrackedVehicleControllerSettings_SetTransmission(JPH_TrackedVehicleControllerSettings* settings, JPH_VehicleTransmissionSettings* value);

	[CLink] public static extern void JPH_TrackedVehicleController_SetDriverInput(JPH_TrackedVehicleController* controller, float forward, float leftRatio, float rightRatio, float brake);
	[CLink] public static extern float JPH_TrackedVehicleController_GetForwardInput(JPH_TrackedVehicleController* controller);
	[CLink] public static extern void JPH_TrackedVehicleController_SetForwardInput(JPH_TrackedVehicleController* controller, float value);
	[CLink] public static extern float JPH_TrackedVehicleController_GetLeftRatio(JPH_TrackedVehicleController* controller);
	[CLink] public static extern void JPH_TrackedVehicleController_SetLeftRatio(JPH_TrackedVehicleController* controller, float value);
	[CLink] public static extern float JPH_TrackedVehicleController_GetRightRatio(JPH_TrackedVehicleController* controller);
	[CLink] public static extern void JPH_TrackedVehicleController_SetRightRatio(JPH_TrackedVehicleController* controller, float value);
	[CLink] public static extern float JPH_TrackedVehicleController_GetBrakeInput(JPH_TrackedVehicleController* controller);
	[CLink] public static extern void JPH_TrackedVehicleController_SetBrakeInput(JPH_TrackedVehicleController* controller, float value);
	[CLink] public static extern JPH_VehicleEngine* JPH_TrackedVehicleController_GetEngine(JPH_TrackedVehicleController* controller);
	[CLink] public static extern JPH_VehicleTransmission* JPH_TrackedVehicleController_GetTransmission(JPH_TrackedVehicleController* controller);

	/* MotorcycleController */
	[CLink] public static extern JPH_MotorcycleControllerSettings* JPH_MotorcycleControllerSettings_Create();
	[CLink] public static extern float JPH_MotorcycleControllerSettings_GetMaxLeanAngle(JPH_MotorcycleControllerSettings* settings);
	[CLink] public static extern void JPH_MotorcycleControllerSettings_SetMaxLeanAngle(JPH_MotorcycleControllerSettings* settings, float value);
	[CLink] public static extern float JPH_MotorcycleControllerSettings_GetLeanSpringConstant(JPH_MotorcycleControllerSettings* settings);
	[CLink] public static extern void JPH_MotorcycleControllerSettings_SetLeanSpringConstant(JPH_MotorcycleControllerSettings* settings, float value);
	[CLink] public static extern float JPH_MotorcycleControllerSettings_GetLeanSpringDamping(JPH_MotorcycleControllerSettings* settings);
	[CLink] public static extern void JPH_MotorcycleControllerSettings_SetLeanSpringDamping(JPH_MotorcycleControllerSettings* settings, float value);
	[CLink] public static extern float JPH_MotorcycleControllerSettings_GetLeanSpringIntegrationCoefficient(JPH_MotorcycleControllerSettings* settings);
	[CLink] public static extern void JPH_MotorcycleControllerSettings_SetLeanSpringIntegrationCoefficient(JPH_MotorcycleControllerSettings* settings, float value);
	[CLink] public static extern float JPH_MotorcycleControllerSettings_GetLeanSpringIntegrationCoefficientDecay(JPH_MotorcycleControllerSettings* settings);
	[CLink] public static extern void JPH_MotorcycleControllerSettings_SetLeanSpringIntegrationCoefficientDecay(JPH_MotorcycleControllerSettings* settings, float value);
	[CLink] public static extern float JPH_MotorcycleControllerSettings_GetLeanSmoothingFactor(JPH_MotorcycleControllerSettings* settings);
	[CLink] public static extern void JPH_MotorcycleControllerSettings_SetLeanSmoothingFactor(JPH_MotorcycleControllerSettings* settings, float value);

	[CLink] public static extern float JPH_MotorcycleController_GetWheelBase(JPH_MotorcycleController* controller);
	[CLink] public static extern bool JPH_MotorcycleController_IsLeanControllerEnabled(JPH_MotorcycleController* controller);
	[CLink] public static extern void JPH_MotorcycleController_EnableLeanController(JPH_MotorcycleController* controller, bool value);
	[CLink] public static extern bool JPH_MotorcycleController_IsLeanSteeringLimitEnabled(JPH_MotorcycleController* controller);
	[CLink] public static extern void JPH_MotorcycleController_EnableLeanSteeringLimit(JPH_MotorcycleController* controller, bool value);
	[CLink] public static extern float JPH_MotorcycleController_GetLeanSpringConstant(JPH_MotorcycleController* controller);
	[CLink] public static extern void JPH_MotorcycleController_SetLeanSpringConstant(JPH_MotorcycleController* controller, float value);
	[CLink] public static extern float JPH_MotorcycleController_GetLeanSpringDamping(JPH_MotorcycleController* controller);
	[CLink] public static extern void JPH_MotorcycleController_SetLeanSpringDamping(JPH_MotorcycleController* controller, float value);
	[CLink] public static extern float JPH_MotorcycleController_GetLeanSpringIntegrationCoefficient(JPH_MotorcycleController* controller);
	[CLink] public static extern void JPH_MotorcycleController_SetLeanSpringIntegrationCoefficient(JPH_MotorcycleController* controller, float value);
	[CLink] public static extern float JPH_MotorcycleController_GetLeanSpringIntegrationCoefficientDecay(JPH_MotorcycleController* controller);
	[CLink] public static extern void JPH_MotorcycleController_SetLeanSpringIntegrationCoefficientDecay(JPH_MotorcycleController* controller, float value);
	[CLink] public static extern float JPH_MotorcycleController_GetLeanSmoothingFactor(JPH_MotorcycleController* controller);
	[CLink] public static extern void JPH_MotorcycleController_SetLeanSmoothingFactor(JPH_MotorcycleController* controller, float value);

	/* LinearCurve */
	[CLink] public static extern JPH_LinearCurve* JPH_LinearCurve_Create();
	[CLink] public static extern void JPH_LinearCurve_Destroy(JPH_LinearCurve* curve);
	[CLink] public static extern void JPH_LinearCurve_Clear(JPH_LinearCurve* curve);
	[CLink] public static extern void JPH_LinearCurve_Reserve(JPH_LinearCurve* curve, uint32 numPoints);
	[CLink] public static extern void JPH_LinearCurve_AddPoint(JPH_LinearCurve* curve, float x, float y);
	[CLink] public static extern void JPH_LinearCurve_Sort(JPH_LinearCurve* curve);
	[CLink] public static extern float JPH_LinearCurve_GetMinX(JPH_LinearCurve* curve);
	[CLink] public static extern float JPH_LinearCurve_GetMaxX(JPH_LinearCurve* curve);
	[CLink] public static extern float JPH_LinearCurve_GetValue(JPH_LinearCurve* curve, float x);
	[CLink] public static extern uint32 JPH_LinearCurve_GetPointCount(JPH_LinearCurve* curve);
	[CLink] public static extern void JPH_LinearCurve_GetPoint(JPH_LinearCurve* curve, uint32 index, JPH_Point* result);
	[CLink] public static extern void JPH_LinearCurve_GetPoints(JPH_LinearCurve* curve, JPH_Point* points, uint32* count);
}