using Win32.Foundation;
using Win32.System.Registry;
using Win32.System.SystemServices;
using Win32.Security;
using Win32.System.Com;
using Win32.Graphics.Gdi;
using Win32.UI.WindowsAndMessaging;
using System;

namespace Win32.Networking.Clustering;

#region Constants
public static
{
	public const uint32 CLUSTER_VERSION_FLAG_MIXED_MODE = 1;
	public const uint32 CLUSTER_VERSION_UNKNOWN = 4294967295;
	public const uint32 NT4_MAJOR_VERSION = 1;
	public const uint32 NT4SP4_MAJOR_VERSION = 2;
	public const uint32 NT5_MAJOR_VERSION = 3;
	public const uint32 NT51_MAJOR_VERSION = 4;
	public const uint32 NT6_MAJOR_VERSION = 5;
	public const uint32 NT7_MAJOR_VERSION = 6;
	public const uint32 NT8_MAJOR_VERSION = 7;
	public const uint32 NT9_MAJOR_VERSION = 8;
	public const uint32 NT10_MAJOR_VERSION = 9;
	public const uint32 NT11_MAJOR_VERSION = 10;
	public const uint32 NT12_MAJOR_VERSION = 11;
	public const uint32 NT13_MAJOR_VERSION = 12;
	public const uint32 WS2016_TP4_UPGRADE_VERSION = 6;
	public const uint32 WS2016_TP5_UPGRADE_VERSION = 7;
	public const uint32 WS2016_RTM_UPGRADE_VERSION = 8;
	public const uint32 RS3_UPGRADE_VERSION = 1;
	public const uint32 RS4_UPGRADE_VERSION = 2;
	public const uint32 RS5_UPGRADE_VERSION = 3;
	public const uint32 NINETEEN_H1_UPGRADE_VERSION = 1;
	public const uint32 NINETEEN_H2_UPGRADE_VERSION = 2;
	public const uint32 MN_UPGRADE_VERSION = 3;
	public const uint32 FE_UPGRADE_VERSION = 4;
	public const uint32 CA_UPGRADE_VERSION = 1;
	public const uint32 HCI_UPGRADE_BIT = 32768;
	public const String CLUSREG_NAME_MIXED_MODE = "MixedMode";
	public const uint32 CLUSAPI_VERSION_SERVER2008 = 1536;
	public const uint32 CLUSAPI_VERSION_SERVER2008R2 = 1792;
	public const uint32 CLUSAPI_VERSION_WINDOWS8 = 1793;
	public const uint32 CLUSAPI_VERSION_WINDOWSBLUE = 1794;
	public const uint32 CLUSAPI_VERSION_WINTHRESHOLD = 1795;
	public const uint32 CLUSAPI_VERSION_RS3 = 2560;
	public const uint32 CLUSAPI_VERSION = 2560;
	public const uint32 CREATE_CLUSTER_VERSION = 1536;
	public const uint32 CREATE_CLUSTER_MAJOR_VERSION_MASK = 4294967040;
	public const uint32 MAX_CLUSTERNAME_LENGTH = 63;
	public const uint32 CLUSTER_INSTALLED = 1;
	public const uint32 CLUSTER_CONFIGURED = 2;
	public const uint32 CLUSTER_RUNNING = 16;
	public const uint32 CLUS_HYBRID_QUORUM = 1024;
	public const uint32 CLUS_NODE_MAJORITY_QUORUM = 0;
	public const uint32 CLUSCTL_RESOURCE_STATE_CHANGE_REASON_VERSION_1 = 1;
	public const uint32 CLUSREG_DATABASE_SYNC_WRITE_TO_ALL_NODES = 1;
	public const uint32 CLUSREG_DATABASE_ISOLATE_READ = 2;
	public const uint32 CLUSTER_ENUM_ITEM_VERSION_1 = 1;
	public const uint32 CLUSTER_ENUM_ITEM_VERSION = 1;
	public const uint32 CLUSTER_CREATE_GROUP_INFO_VERSION_1 = 1;
	public const uint32 CLUSTER_CREATE_GROUP_INFO_VERSION = 1;
	public const uint32 GROUPSET_READY_SETTING_DELAY = 1;
	public const uint32 GROUPSET_READY_SETTING_ONLINE = 2;
	public const uint32 GROUPSET_READY_SETTING_OS_HEARTBEAT = 3;
	public const uint32 GROUPSET_READY_SETTING_APPLICATION_READY = 4;
	public const uint32 CLUS_GRP_MOVE_ALLOWED = 0;
	public const uint32 CLUS_GRP_MOVE_LOCKED = 1;
	public const int32 CLUSAPI_READ_ACCESS = 1;
	public const int32 CLUSAPI_CHANGE_ACCESS = 2;
	public const int32 CLUSAPI_NO_ACCESS = 4;
	public const uint32 CLUSTER_SET_ACCESS_TYPE_ALLOWED = 0;
	public const uint32 CLUSTER_SET_ACCESS_TYPE_DENIED = 1;
	public const uint32 CLUSTER_DELETE_ACCESS_CONTROL_ENTRY = 2;
	public const uint64 CLUSGROUPSET_STATUS_GROUPS_PENDING = 1;
	public const uint64 CLUSGROUPSET_STATUS_GROUPS_ONLINE = 2;
	public const uint64 CLUSGROUPSET_STATUS_OS_HEARTBEAT = 4;
	public const uint64 CLUSGROUPSET_STATUS_APPLICATION_READY = 8;
	public const uint32 CLUSTER_AVAILABILITY_SET_CONFIG_V1 = 1;
	public const uint32 CLUSTER_GROUP_ENUM_ITEM_VERSION_1 = 1;
	public const uint32 CLUSTER_GROUP_ENUM_ITEM_VERSION = 1;
	public const uint32 CLUSTER_RESOURCE_ENUM_ITEM_VERSION_1 = 1;
	public const uint32 CLUSTER_RESOURCE_ENUM_ITEM_VERSION = 1;
	public const uint32 CLUSAPI_NODE_PAUSE_REMAIN_ON_PAUSED_NODE_ON_MOVE_ERROR = 1;
	public const uint32 CLUSAPI_NODE_AVOID_PLACEMENT = 2;
	public const uint32 CLUSAPI_NODE_PAUSE_RETRY_DRAIN_ON_FAILURE = 4;
	public const uint64 CLUSGRP_STATUS_LOCKED_MODE = 1;
	public const uint64 CLUSGRP_STATUS_PREEMPTED = 2;
	public const uint64 CLUSGRP_STATUS_WAITING_IN_QUEUE_FOR_MOVE = 4;
	public const uint64 CLUSGRP_STATUS_PHYSICAL_RESOURCES_LACKING = 8;
	public const uint64 CLUSGRP_STATUS_WAITING_TO_START = 16;
	public const uint64 CLUSGRP_STATUS_EMBEDDED_FAILURE = 32;
	public const uint64 CLUSGRP_STATUS_OFFLINE_DUE_TO_ANTIAFFINITY_CONFLICT = 64;
	public const uint64 CLUSGRP_STATUS_NETWORK_FAILURE = 128;
	public const uint64 CLUSGRP_STATUS_UNMONITORED = 256;
	public const uint64 CLUSGRP_STATUS_OS_HEARTBEAT = 512;
	public const uint64 CLUSGRP_STATUS_APPLICATION_READY = 1024;
	public const uint64 CLUSGRP_STATUS_OFFLINE_NOT_LOCAL_DISK_OWNER = 2048;
	public const uint64 CLUSGRP_STATUS_WAITING_FOR_DEPENDENCIES = 4096;
	public const uint64 CLUSRES_STATUS_LOCKED_MODE = 1;
	public const uint64 CLUSRES_STATUS_EMBEDDED_FAILURE = 2;
	public const uint64 CLUSRES_STATUS_FAILED_DUE_TO_INSUFFICIENT_CPU = 4;
	public const uint64 CLUSRES_STATUS_FAILED_DUE_TO_INSUFFICIENT_MEMORY = 8;
	public const uint64 CLUSRES_STATUS_FAILED_DUE_TO_INSUFFICIENT_GENERIC_RESOURCES = 16;
	public const uint64 CLUSRES_STATUS_NETWORK_FAILURE = 32;
	public const uint64 CLUSRES_STATUS_UNMONITORED = 64;
	public const uint64 CLUSRES_STATUS_OS_HEARTBEAT = 128;
	public const uint64 CLUSRES_STATUS_APPLICATION_READY = 256;
	public const uint64 CLUSRES_STATUS_OFFLINE_NOT_LOCAL_DISK_OWNER = 512;
	public const uint32 CLUSAPI_GROUP_ONLINE_IGNORE_RESOURCE_STATUS = 1;
	public const uint32 CLUSAPI_GROUP_ONLINE_SYNCHRONOUS = 2;
	public const uint32 CLUSAPI_GROUP_ONLINE_BEST_POSSIBLE_NODE = 4;
	public const uint32 CLUSAPI_GROUP_ONLINE_IGNORE_AFFINITY_RULE = 8;
	public const uint32 CLUSAPI_GROUP_OFFLINE_IGNORE_RESOURCE_STATUS = 1;
	public const uint32 CLUSAPI_RESOURCE_ONLINE_IGNORE_RESOURCE_STATUS = 1;
	public const uint32 CLUSAPI_RESOURCE_ONLINE_DO_NOT_UPDATE_PERSISTENT_STATE = 2;
	public const uint32 CLUSAPI_RESOURCE_ONLINE_NECESSARY_FOR_QUORUM = 4;
	public const uint32 CLUSAPI_RESOURCE_ONLINE_BEST_POSSIBLE_NODE = 8;
	public const uint32 CLUSAPI_RESOURCE_ONLINE_IGNORE_AFFINITY_RULE = 32;
	public const uint32 CLUSAPI_RESOURCE_OFFLINE_IGNORE_RESOURCE_STATUS = 1;
	public const uint32 CLUSAPI_RESOURCE_OFFLINE_FORCE_WITH_TERMINATION = 2;
	public const uint32 CLUSAPI_RESOURCE_OFFLINE_DO_NOT_UPDATE_PERSISTENT_STATE = 4;
	public const uint32 CLUSAPI_RESOURCE_OFFLINE_REASON_NONE = 0;
	public const uint32 CLUSAPI_RESOURCE_OFFLINE_REASON_UNKNOWN = 1;
	public const uint32 CLUSAPI_RESOURCE_OFFLINE_REASON_MOVING = 2;
	public const uint32 CLUSAPI_RESOURCE_OFFLINE_REASON_USER_REQUESTED = 4;
	public const uint32 CLUSAPI_RESOURCE_OFFLINE_REASON_BEING_DELETED = 8;
	public const uint32 CLUSAPI_RESOURCE_OFFLINE_REASON_BEING_RESTARTED = 16;
	public const uint32 CLUSAPI_RESOURCE_OFFLINE_REASON_PREEMPTED = 32;
	public const uint32 CLUSAPI_RESOURCE_OFFLINE_REASON_SHUTTING_DOWN = 64;
	public const uint32 CLUSAPI_GROUP_MOVE_IGNORE_RESOURCE_STATUS = 1;
	public const uint32 CLUSAPI_GROUP_MOVE_RETURN_TO_SOURCE_NODE_ON_ERROR = 2;
	public const uint32 CLUSAPI_GROUP_MOVE_QUEUE_ENABLED = 4;
	public const uint32 CLUSAPI_GROUP_MOVE_HIGH_PRIORITY_START = 8;
	public const uint32 CLUSAPI_GROUP_MOVE_FAILBACK = 16;
	public const uint32 CLUSAPI_GROUP_MOVE_IGNORE_AFFINITY_RULE = 32;
	public const uint64 CLUSAPI_CHANGE_RESOURCE_GROUP_FORCE_MOVE_TO_CSV = 1;
	public const uint64 CLUSAPI_VALID_CHANGE_RESOURCE_GROUP_FLAGS = 1;
	public const uint32 GROUP_FAILURE_INFO_VERSION_1 = 1;
	public const uint32 RESOURCE_FAILURE_INFO_VERSION_1 = 1;
	public const uint32 CLUS_ACCESS_ANY = 0;
	public const uint32 CLUS_ACCESS_READ = 1;
	public const uint32 CLUS_ACCESS_WRITE = 2;
	public const uint32 CLUS_NO_MODIFY = 0;
	public const uint32 CLUS_MODIFY = 1;
	public const uint32 CLUS_NOT_GLOBAL = 0;
	public const uint32 CLUS_GLOBAL = 1;
	public const uint32 CLUSCTL_ACCESS_SHIFT = 0;
	public const uint32 CLUSCTL_FUNCTION_SHIFT = 2;
	public const uint32 CLCTL_INTERNAL_SHIFT = 20;
	public const uint32 CLCTL_USER_SHIFT = 21;
	public const uint32 CLCTL_MODIFY_SHIFT = 22;
	public const uint32 CLCTL_GLOBAL_SHIFT = 23;
	public const uint32 CLUSCTL_OBJECT_SHIFT = 24;
	public const uint32 CLUSCTL_CONTROL_CODE_MASK = 4194303;
	public const uint32 CLUSCTL_OBJECT_MASK = 255;
	public const uint32 CLUSCTL_ACCESS_MODE_MASK = 3;
	public const uint32 CLCTL_CLUSTER_BASE = 0;
	public const int32 BitLockerEnabled = 1;
	public const int32 BitLockerDecrypted = 4;
	public const int32 BitlockerEncrypted = 8;
	public const int32 BitLockerDecrypting = 16;
	public const int32 BitlockerEncrypting = 32;
	public const int32 BitLockerPaused = 64;
	public const int32 BitLockerStopped = 128;
	public const uint64 RedirectedIOReasonUserRequest = 1;
	public const uint64 RedirectedIOReasonUnsafeFileSystemFilter = 2;
	public const uint64 RedirectedIOReasonUnsafeVolumeFilter = 4;
	public const uint64 RedirectedIOReasonFileSystemTiering = 8;
	public const uint64 RedirectedIOReasonBitLockerInitializing = 16;
	public const uint64 RedirectedIOReasonReFs = 32;
	public const uint64 RedirectedIOReasonMax = 9223372036854775808;
	public const uint64 VolumeRedirectedIOReasonNoDiskConnectivity = 1;
	public const uint64 VolumeRedirectedIOReasonStorageSpaceNotAttached = 2;
	public const uint64 VolumeRedirectedIOReasonVolumeReplicationEnabled = 4;
	public const uint64 VolumeRedirectedIOReasonMax = 9223372036854775808;
	public const uint32 MAX_OBJECTID = 64;
	public const uint32 MAX_CO_PASSWORD_LENGTH = 16;
	public const uint32 GUID_PRESENT = 1;
	public const uint32 CREATEDC_PRESENT = 2;
	public const uint32 MAX_CO_PASSWORD_LENGTHEX = 127;
	public const uint32 MAX_CO_PASSWORD_STORAGEEX = 128;
	public const uint32 MAX_CREATINGDC_LENGTH = 256;
	public const uint32 DNS_LENGTH = 64;
	public const uint32 MAINTENANCE_MODE_V2_SIG = 2881155087;
	public const uint32 NNLEN = 80;
	public const String CLUS_RESTYPE_NAME_GENAPP = "Generic Application";
	public const String CLUS_RESTYPE_NAME_GENSVC = "Generic Service";
	public const String CLUS_RESTYPE_NAME_GENSCRIPT = "Generic Script";
	public const String CLUS_RESTYPE_NAME_IPADDR = "IP Address";
	public const String CLUS_RESTYPE_NAME_NETNAME = "Network Name";
	public const String CLUS_RESTYPE_NAME_DNN = "Distributed Network Name";
	public const String CLUS_RESTYPE_NAME_FILESHR = "File Share";
	public const String CLUS_RESTYPE_NAME_PRTSPLR = "Print Spooler";
	public const String CLUS_RESTYPE_NAME_IPV6_NATIVE = "IPv6 Address";
	public const String CLUS_RESTYPE_NAME_IPV6_TUNNEL = "IPv6 Tunnel Address";
	public const String CLUS_RESTYPE_NAME_VSSTASK = "Volume Shadow Copy Service Task";
	public const String CLUS_RESTYPE_NAME_WINS = "WINS Service";
	public const String CLUS_RESTYPE_NAME_DHCP = "DHCP Service";
	public const String CLUS_RESTYPE_NAME_MSMQ = "Microsoft Message Queue Server";
	public const String CLUS_RESTYPE_NAME_NEW_MSMQ = "MSMQ";
	public const String CLUS_RESTYPE_NAME_MSMQ_TRIGGER = "MSMQTriggers";
	public const String CLUS_RESTYPE_NAME_MSDTC = "Distributed Transaction Coordinator";
	public const String CLUS_RESTYPE_NAME_NFS = "NFS Share";
	public const String CLUS_RESTYPE_NAME_NETWORK_FILE_SYSTEM = "Network File System";
	public const String CLUS_RESTYPE_NAME_ISNS = "Microsoft iSNS";
	public const String CLUS_RESTYPE_NAME_HARDDISK = "Physical Disk";
	public const String CLUS_RESTYPE_NAME_PHYS_DISK = "Physical Disk";
	public const String CLUS_RESTYPE_NAME_FSWITNESS = "File Share Witness";
	public const String CLUS_RESTYPE_NAME_FILESERVER = "File Server";
	public const String CLUS_RESTYPE_NAME_SODAFILESERVER = "Scale Out File Server";
	public const String CLUS_RESTYPE_NAME_DFS = "Distributed File System";
	public const String CLUS_RESTYPE_NAME_DFSR = "DFS Replicated Folder";
	public const String CLUS_RESTYPE_NAME_VM = "Virtual Machine";
	public const String CLUS_RESTYPE_NAME_VM_CONFIG = "Virtual Machine Configuration";
	public const String CLUS_RESTYPE_NAME_ISCSITARGET = "iSCSI Target Server";
	public const String CLUS_RESTYPE_NAME_STORAGE_POOL = "Storage Pool";
	public const String CLUS_RESTYPE_NAME_TASKSCHEDULER = "Task Scheduler";
	public const String CLUS_RESTYPE_NAME_VMREPLICA_BROKER = "Virtual Machine Replication Broker";
	public const String CLUS_RESTYPE_NAME_VMREPLICA_COORDINATOR = "Virtual Machine Replication Coordinator";
	public const String CLUS_RESTYPE_NAME_NFS_V2 = "Network File System";
	public const String CLUS_RESTYPE_NAME_NFS_MSNS = "NFS Multi Server Namespace";
	public const String CLUS_RESTYPE_NAME_CAU = "ClusterAwareUpdatingResource";
	public const String CLUS_RESTYPE_NAME_NV_PROVIDER_ADDRESS = "Provider Address";
	public const String CLUS_RESTYPE_NAME_NAT = "Nat";
	public const String CLUS_RESTYPE_NAME_STORAGE_POLICIES = "Storage Policies";
	public const String CLUS_RESTYPE_NAME_STORQOS = "Storage QoS Policy Manager";
	public const String CLUS_RESTYPE_NAME_HEALTH_SERVICE = "Health Service";
	public const String CLUS_RESTYPE_NAME_VM_WMI = "Virtual Machine Cluster WMI";
	public const String CLUS_RESTYPE_NAME_SDDC_MANAGEMENT = "SDDC Management";
	public const String CLUS_RESTYPE_NAME_HCSVM = "HCS Virtual Machine";
	public const String CLUS_RESTYPE_NAME_VIRTUAL_IPV4 = "Disjoint IPv4 Address";
	public const String CLUS_RESTYPE_NAME_VIRTUAL_IPV6 = "Disjoint IPv6 Address";
	public const String CLUS_RESTYPE_NAME_CLOUD_WITNESS = "Cloud Witness";
	public const String CLUS_RESTYPE_NAME_STORAGE_REPLICA = "Storage Replica";
	public const String CLUS_RESTYPE_NAME_CROSS_CLUSTER = "Cross Cluster Dependency Orchestrator";
	public const String CLUS_RESTYPE_NAME_SCALEOUT_MASTER = "Scaleout Master";
	public const String CLUS_RESTYPE_NAME_SCALEOUT_WORKER = "Scaleout Worker";
	public const String CLUS_RESTYPE_NAME_CONTAINER = "Container";
	public const String CLUS_RES_NAME_SCALEOUT_MASTER = "Scaleout Master";
	public const String CLUS_RES_NAME_SCALEOUT_WORKER = "Scaleout Worker";
	public const String CLUSREG_NAME_CLUS_DESC = "Description";
	public const String CLUSREG_NAME_CLUS_SD = "Security Descriptor";
	public const String CLUSREG_NAME_CLUS_DEFAULT_NETWORK_ROLE = "DefaultNetworkRole";
	public const String CLUSREG_NAME_QUORUM_ARBITRATION_TIMEOUT = "QuorumArbitrationTimeMax";
	public const String CLUSTER_HANG_TIMEOUT_KEYNAME = "ClusSvcHangTimeout";
	public const String CLUSTER_HANG_RECOVERY_ACTION_KEYNAME = "HangRecoveryAction";
	public const String CLUSTER_CSA_VSS_STATE = "BackupInProgress";
	public const String CLUSTER_REQUEST_REPLY_TIMEOUT = "RequestReplyTimeout";
	public const String CLUSTER_WITNESS_FAILED_RESTART_INTERVAL = "WitnessRestartInterval";
	public const String CLUSTER_WITNESS_DATABASE_WRITE_TIMEOUT = "WitnessDatabaseWriteTimeout";
	public const String CLUSTER_ADD_EVICT_DELAY = "AddEvictDelay";
	public const String CLUSREG_NAME_FIXQUORUM = "FixQuorum";
	public const String CLUSREG_NAME_PREVENTQUORUM = "PreventQuorum";
	public const String CLUSREG_NAME_IGNORE_PERSISTENT_STATE = "IgnorePersistentStateOnStartup";
	public const String CLUSTER_SHARED_VOLUMES_ROOT = "SharedVolumesRoot";
	public const String ENABLE_CLUSTER_SHARED_VOLUMES = "EnableSharedVolumes";
	public const String CLUSTER_SHARED_VOLUME_VSS_WRITER_OPERATION_TIMEOUT = "SharedVolumeVssWriterOperationTimeout";
	public const String USE_CLIENT_ACCESS_NETWORKS_FOR_CSV = "UseClientAccessNetworksForSharedVolumes";
	public const String CLUSTER_CSV_COMPATIBLE_FILTERS = "SharedVolumeCompatibleFilters";
	public const String CLUSTER_CSV_INCOMPATIBLE_FILTERS = "SharedVolumeIncompatibleFilters";
	public const String CLUSTER_GROUP_WAIT_DELAY = "ClusterGroupWaitDelay";
	public const String MINIMUM_PREEMPTOR_PRIORITY = "MinimumPreemptorPriority";
	public const String MINIMUM_NEVER_PREEMPT_PRIORITY = "MinimumNeverPreemptPriority";
	public const String CLUSTER_ENFORCED_ANTIAFFINITY = "ClusterEnforcedAntiaffinity";
	public const String CLUSREG_NAME_SHUTDOWN_TIMEOUT_MINUTES = "ShutdownTimeoutInMinutes";
	public const String CLUSREG_NAME_CSV_MDS_SD = "SharedVolumeSecurityDescriptor";
	public const String CLUSREG_NAME_FAILOVER_MOVE_MIGRATION_TYPE = "FailoverMoveMigrationType";
	public const String CLUSREG_NAME_CSV_BLOCK_CACHE = "BlockCacheSize";
	public const String CLUSREG_NAME_ROUTE_HISTORY_LENGTH = "RouteHistoryLength";
	public const String CLUSREG_NAME_LAST_RECENT_EVENTS_RESET_TIME = "RecentEventsResetTime";
	public const String CLUSREG_NAME_DRAIN_ON_SHUTDOWN = "DrainOnShutdown";
	public const String CLUSREG_NAME_NETFT_IPSEC_ENABLED = "NetftIPSecEnabled";
	public const String CLUSREG_NAME_WITNESS_DYNAMIC_WEIGHT = "WitnessDynamicWeight";
	public const String CLUSREG_NAME_MESSAGE_BUFFER_LENGTH = "MessageBufferLength";
	public const String CLUSREG_NAME_DATABASE_READ_WRITE_MODE = "DatabaseReadWriteMode";
	public const String CLUSREG_NAME_FUNCTIONAL_LEVEL = "ClusterFunctionalLevel";
	public const String CLUSREG_NAME_UPGRADE_VERSION = "ClusterUpgradeVersion";
	public const String CLUSREG_NAME_RESILIENCY_LEVEL = "ResiliencyLevel";
	public const String CLUSREG_NAME_RESILIENCY_DEFAULT_SECONDS = "ResiliencyDefaultPeriod";
	public const String CLUSREG_NAME_QUARANTINE_THRESHOLD = "QuarantineThreshold";
	public const String CLUSREG_NAME_QUARANTINE_DURATION = "QuarantineDuration";
	public const String CLUSTER_S2D_ENABLED = "S2DEnabled";
	public const String CLUSTER_S2D_BUS_TYPES = "S2DBusTypes";
	public const String CLUSTER_S2D_CACHE_PAGE_SIZE_KBYTES = "S2DCachePageSizeKBytes";
	public const String CLUSTER_S2D_OPTIMIZATIONS = "S2DOptimizations";
	public const String CLUSTER_S2D_IO_LATENCY_THRESHOLD = "S2DIOLatencyThreshold";
	public const String CLUSTER_S2D_CACHE_DESIRED_STATE = "S2DCacheDesiredState";
	public const String CLUSTER_S2D_CACHE_METADATA_RESERVE = "S2DCacheMetadataReserveBytes";
	public const String CLUSTER_S2D_CACHE_FLASH_RESERVE_PERCENT = "S2DCacheFlashReservePercent";
	public const String CLUSTER_S2D_CACHE_BEHAVIOR_FLAGS = "S2DCacheBehavior";
	public const String CLUSTER_NAME_PREFERRED_SITE = "PreferredSite";
	public const String CLUSTER_NAME_AUTO_BALANCER_MODE = "AutoBalancerMode";
	public const String CLUSTER_NAME_AUTO_BALANCER_LEVEL = "AutoBalancerLevel";
	public const String CLUSREG_NAME_GROUP_DEPENDENCY_TIMEOUT = "GroupDependencyTimeout";
	public const String CLUSREG_NAME_PLACEMENT_OPTIONS = "PlacementOptions";
	public const String CLUSREG_NAME_ENABLED_EVENT_LOGS = "EnabledEventLogs";
	public const String CLUSREG_NAME_SAME_SUBNET_DELAY = "SameSubnetDelay";
	public const String CLUSREG_NAME_CROSS_SUBNET_DELAY = "CrossSubnetDelay";
	public const String CLUSREG_NAME_CROSS_SITE_DELAY = "CrossSiteDelay";
	public const String CLUSREG_NAME_SAME_SUBNET_THRESHOLD = "SameSubnetThreshold";
	public const String CLUSREG_NAME_CROSS_SUBNET_THRESHOLD = "CrossSubnetThreshold";
	public const String CLUSREG_NAME_CROSS_SITE_THRESHOLD = "CrossSiteThreshold";
	public const String CLUSREG_NAME_PLUMB_ALL_CROSS_SUBNET_ROUTES = "PlumbAllCrossSubnetRoutes";
	public const String CLUSREG_NAME_NODE_NAME = "NodeName";
	public const String CLUSREG_NAME_NODE_HIGHEST_VERSION = "NodeHighestVersion";
	public const String CLUSREG_NAME_NODE_LOWEST_VERSION = "NodeLowestVersion";
	public const String CLUSREG_NAME_NODE_DESC = "Description";
	public const String CLUSREG_NAME_NODE_MAJOR_VERSION = "MajorVersion";
	public const String CLUSREG_NAME_NODE_MINOR_VERSION = "MinorVersion";
	public const String CLUSREG_NAME_NODE_BUILD_NUMBER = "BuildNumber";
	public const String CLUSREG_NAME_NODE_CSDVERSION = "CSDVersion";
	public const String CLUSREG_NAME_NODE_WEIGHT = "NodeWeight";
	public const String CLUSREG_NAME_NODE_DYNAMIC_WEIGHT = "DynamicWeight";
	public const String CLUSREG_NAME_NODE_IS_PRIMARY = "IsPrimary";
	public const String CLUSREG_NAME_NODE_DRAIN_STATUS = "NodeDrainStatus";
	public const String CLUSREG_NAME_NODE_DRAIN_TARGET = "NodeDrainTarget";
	public const String CLUSREG_NAME_NODE_NEEDS_PQ = "NeedsPreventQuorum";
	public const String CLUSREG_NAME_NODE_FDID = "FaultDomainId";
	public const String CLUSREG_NAME_NODE_STATUS_INFO = "StatusInformation";
	public const String CLUSREG_NAME_NODE_FAULT_DOMAIN = "FaultDomain";
	public const String CLUSREG_NAME_NODE_MODEL = "Model";
	public const String CLUSREG_NAME_NODE_SERIALNUMBER = "SerialNumber";
	public const String CLUSREG_NAME_NODE_MANUFACTURER = "Manufacturer";
	public const String CLUSREG_NAME_GRP_NAME = "Name";
	public const String CLUSREG_NAME_GRP_TYPE = "GroupType";
	public const String CLUSREG_NAME_GRP_DESC = "Description";
	public const String CLUSREG_NAME_GRP_PERSISTENT_STATE = "PersistentState";
	public const String CLUSREG_NAME_GRP_FAILBACK_TYPE = "AutoFailbackType";
	public const String CLUSREG_NAME_GRP_FAILBACK_WIN_START = "FailbackWindowStart";
	public const String CLUSREG_NAME_GRP_FAILBACK_WIN_END = "FailbackWindowEnd";
	public const String CLUSREG_NAME_GRP_FAILOVER_THRESHOLD = "FailoverThreshold";
	public const String CLUSREG_NAME_GRP_FAILOVER_PERIOD = "FailoverPeriod";
	public const String CLUSREG_NAME_GRP_PRIORITY = "Priority";
	public const String CLUSREG_NAME_GRP_DEFAULT_OWNER = "DefaultOwner";
	public const String CLUSREG_NAME_GRP_STATUS_INFORMATION = "StatusInformation";
	public const String CLUSREG_NAME_GRP_ANTI_AFFINITY_CLASS_NAME = "AntiAffinityClassNames";
	public const String CLUSREG_NAME_GRP_START_DELAY = "GroupStartDelay";
	public const String CLUSREG_NAME_GRP_CCF_EPOCH = "CCFEpoch";
	public const String CLUSREG_NAME_GRP_CCF_EPOCH_HIGH = "CCFEpochHigh";
	public const String CLUSREG_NAME_GRP_RESILIENCY_PERIOD = "ResiliencyPeriod";
	public const String CLUSREG_NAME_GRP_PREFERRED_SITE = "PreferredSite";
	public const String CLUSREG_NAME_GRP_COLD_START_SETTING = "ColdStartSetting";
	public const String CLUSREG_NAME_GRP_FAULT_DOMAIN = "FaultDomain";
	public const String CLUSREG_NAME_GRP_UPDATE_DOMAIN = "UpdateDomain";
	public const String CLUSREG_NAME_GRP_PLACEMENT_OPTIONS = "PlacementOptions";
	public const String CLUSREG_NAME_GRP_LOCK_MOVE = "LockedFromMoving";
	public const String CLUSREG_NAME_RES_NAME = "Name";
	public const String CLUSREG_NAME_RES_TYPE = "Type";
	public const String CLUSREG_NAME_RES_DESC = "Description";
	public const String CLUSREG_NAME_RES_SEPARATE_MONITOR = "SeparateMonitor";
	public const String CLUSREG_NAME_RES_PERSISTENT_STATE = "PersistentState";
	public const String CLUSREG_NAME_RES_LOOKS_ALIVE = "LooksAlivePollInterval";
	public const String CLUSREG_NAME_RES_IS_ALIVE = "IsAlivePollInterval";
	public const String CLUSREG_NAME_RES_RESTART_ACTION = "RestartAction";
	public const String CLUSREG_NAME_RES_RESTART_THRESHOLD = "RestartThreshold";
	public const String CLUSREG_NAME_RES_RESTART_PERIOD = "RestartPeriod";
	public const String CLUSREG_NAME_RES_RESTART_DELAY = "RestartDelay";
	public const String CLUSREG_NAME_RES_RETRY_PERIOD_ON_FAILURE = "RetryPeriodOnFailure";
	public const String CLUSREG_NAME_RES_EMBEDDED_FAILURE_ACTION = "EmbeddedFailureAction";
	public const String CLUSREG_NAME_RES_PENDING_TIMEOUT = "PendingTimeout";
	public const String CLUSREG_NAME_RES_DEADLOCK_TIMEOUT = "DeadlockTimeout";
	public const String CLUSREG_NAME_RES_MONITOR_PID = "MonitorProcessId";
	public const String CLUSREG_NAME_RES_STATUS_INFORMATION = "StatusInformation";
	public const String CLUSREG_NAME_RES_LAST_OPERATION_STATUS_CODE = "LastOperationStatusCode";
	public const String CLUSREG_NAME_RES_DATA1 = "ResourceSpecificData1";
	public const String CLUSREG_NAME_RES_DATA2 = "ResourceSpecificData2";
	public const String CLUSREG_NAME_RES_STATUS = "ResourceSpecificStatus";
	public const String CLUSREG_NAME_RESTYPE_NAME = "Name";
	public const String CLUSREG_NAME_RESTYPE_DESC = "Description";
	public const String CLUSREG_NAME_RESTYPE_DLL_NAME = "DllName";
	public const String CLUSREG_NAME_RESTYPE_ADMIN_EXTENSIONS = "AdminExtensions";
	public const String CLUSREG_NAME_RESTYPE_LOOKS_ALIVE = "LooksAlivePollInterval";
	public const String CLUSREG_NAME_RESTYPE_IS_ALIVE = "IsAlivePollInterval";
	public const String CLUSREG_NAME_RESTYPE_PENDING_TIMEOUT = "PendingTimeout";
	public const String CLUSREG_NAME_RESTYPE_DEADLOCK_TIMEOUT = "DeadlockTimeout";
	public const String CLUSREG_NAME_RESTYPE_DUMP_POLICY = "DumpPolicy";
	public const String CLUSREG_NAME_RESTYPE_DUMP_LOG_QUERY = "DumpLogQuery";
	public const String CLUSREG_NAME_RESTYPE_DUMP_SERVICES = "DumpServices";
	public const String CLUSREG_NAME_RESTYPE_ENABLED_EVENT_LOGS = "EnabledEventLogs";
	public const String CLUSREG_NAME_RESTYPE_MAX_MONITORS = "MaximumMonitors";
	public const String CLUSREG_NAME_RESTYPE_WPR_START_AFTER = "WprStartAfter";
	public const String CLUSREG_NAME_RESTYPE_WPR_PROFILES = "WprProfiles";
	public const String CLUSREG_NAME_NET_NAME = "Name";
	public const String CLUSREG_NAME_NET_IPV6_ADDRESSES = "IPv6Addresses";
	public const String CLUSREG_NAME_NET_IPV6_PREFIXLENGTHS = "IPv6PrefixLengths";
	public const String CLUSREG_NAME_NET_IPV4_ADDRESSES = "IPv4Addresses";
	public const String CLUSREG_NAME_NET_IPV4_PREFIXLENGTHS = "IPv4PrefixLengths";
	public const String CLUSREG_NAME_NET_ADDRESS = "Address";
	public const String CLUSREG_NAME_NET_ADDRESS_MASK = "AddressMask";
	public const String CLUSREG_NAME_NET_DESC = "Description";
	public const String CLUSREG_NAME_NET_ROLE = "Role";
	public const String CLUSREG_NAME_NET_SPEED = "LinkSpeed";
	public const String CLUSREG_NAME_NET_RDMA_CAPABLE = "RdmaCapable";
	public const String CLUSREG_NAME_NET_RSS_CAPABLE = "RssCapable";
	public const String CLUSREG_NAME_NET_METRIC = "Metric";
	public const String CLUSREG_NAME_NET_AUTOMETRIC = "AutoMetric";
	public const String CLUSREG_NAME_NETIFACE_NAME = "Name";
	public const String CLUSREG_NAME_NETIFACE_NODE = "Node";
	public const String CLUSREG_NAME_NETIFACE_NETWORK = "Network";
	public const String CLUSREG_NAME_NETIFACE_ADAPTER_NAME = "Adapter";
	public const String CLUSREG_NAME_NETIFACE_ADAPTER_ID = "AdapterId";
	public const String CLUSREG_NAME_NETIFACE_DHCP_ENABLED = "DhcpEnabled";
	public const String CLUSREG_NAME_NETIFACE_IPV6_ADDRESSES = "IPv6Addresses";
	public const String CLUSREG_NAME_NETIFACE_IPV4_ADDRESSES = "IPv4Addresses";
	public const String CLUSREG_NAME_NETIFACE_ADDRESS = "Address";
	public const String CLUSREG_NAME_NETIFACE_DESC = "Description";
	public const String CLUSREG_NAME_GROUPSET_NAME = "Name";
	public const String CLUSREG_NAME_GROUPSET_STARTUP_SETTING = "StartupSetting";
	public const String CLUSREG_NAME_GROUPSET_STARTUP_COUNT = "StartupCount";
	public const String CLUSREG_NAME_GROUPSET_STARTUP_DELAY = "StartupDelay";
	public const String CLUSREG_NAME_GROUPSET_IS_GLOBAL = "IsGlobal";
	public const String CLUSREG_NAME_GROUPSET_STATUS_INFORMATION = "StatusInformation";
	public const String CLUSREG_NAME_GROUPSET_IS_AVAILABILITY_SET = "IsAvailabilitySet";
	public const String CLUSREG_NAME_GROUPSET_UPDATE_DOMAINS = "UpdateDomains";
	public const String CLUSREG_NAME_GROUPSET_FAULT_DOMAINS = "FaultDomains";
	public const String CLUSREG_NAME_GROUPSET_RESERVE_NODE = "ReserveSpareNode";
	public const String CLUSREG_NAME_GROUPSET_AVAILABILITY_SET_INDEX_TO_NODE_MAPPING = "NodeDomainInfo";
	public const String CLUSREG_NAME_AFFINITYRULE_NAME = "Name";
	public const String CLUSREG_NAME_AFFINITYRULE_TYPE = "RuleType";
	public const String CLUSREG_NAME_AFFINITYRULE_GROUPS = "Groups";
	public const String CLUSREG_NAME_AFFINITYRULE_ENABLED = "Enabled";
	public const String CLUSREG_NAME_START_MEMORY = "StartMemory";
	public const String CLUSREG_NAME_VIRTUAL_NUMA_COUNT = "VirtualNumaCount";
	public const String CLUSREG_NAME_DDA_DEVICE_ALLOCATIONS = "DdaDeviceAllocations";
	public const String CLUSREG_NAME_GPUP_DEVICE_ALLOCATIONS = "GpupDeviceAllocations";
	public const String CLUSREG_NAME_PHYSDISK_DISKIDTYPE = "DiskIdType";
	public const String CLUSREG_NAME_PHYSDISK_DISKSIGNATURE = "DiskSignature";
	public const String CLUSREG_NAME_PHYSDISK_DISKIDGUID = "DiskIdGuid";
	public const String CLUSREG_NAME_PHYSDISK_DISKRUNCHKDSK = "DiskRunChkDsk";
	public const String CLUSREG_NAME_PHYSDISK_DISKUNIQUEIDS = "DiskUniqueIds";
	public const String CLUSREG_NAME_PHYSDISK_DISKVOLUMEINFO = "DiskVolumeInfo";
	public const String CLUSREG_NAME_PHYSDISK_DISKARBTYPE = "DiskArbType";
	public const String CLUSREG_NAME_PHYSDISK_DISKARBINTERVAL = "DiskArbInterval";
	public const String CLUSREG_NAME_PHYSDISK_DISKPATH = "DiskPath";
	public const String CLUSREG_NAME_PHYSDISK_DISKRELOAD = "DiskReload";
	public const String CLUSREG_NAME_PHYSDISK_MAINTMODE = "MaintenanceMode";
	public const String CLUSREG_NAME_PHYSDISK_DISKIODELAY = "MaxIoLatency";
	public const String CLUSREG_NAME_PHYSDISK_MIGRATEFIXUP = "MigrateDriveLetters";
	public const String CLUSREG_NAME_PHYSDISK_CSVWRITETHROUGH = "CsvEnforceWriteThrough";
	public const String CLUSREG_NAME_PHYSDISK_CSVBLOCKCACHE = "EnableBlockCache";
	public const String CLUSREG_NAME_PHYSDISK_FASTONLINEARBITRATE = "FastOnlineArbitrate";
	public const String CLUSREG_NAME_PHYSDISK_SPACEIDGUID = "VirtualDiskId";
	public const String CLUSREG_NAME_STORAGESPACE_POOLIDGUID = "PoolId";
	public const String CLUSREG_NAME_PHYSDISK_CSVSNAPSHOTDIFFAREASIZE = "SnapshotDiffSize";
	public const String CLUSREG_NAME_PHYSDISK_CSVSNAPSHOTAGELIMIT = "SnapshotAgeLimit";
	public const String CLUSREG_NAME_PHYSDISK_DISKGUID = "DiskGuid";
	public const String CLUSREG_NAME_PHYSDISK_VOLSNAPACTIVATETIMEOUT = "VolsnapActivateTimeout";
	public const String CLUSREG_NAME_PHYSDISK_DISKRECOVERYACTION = "DiskRecoveryAction";
	public const String CLUSREG_NAME_STORAGESPACE_NAME = "VirtualDiskName";
	public const String CLUSREG_NAME_STORAGESPACE_DESCRIPTION = "VirtualDiskDescription";
	public const String CLUSREG_NAME_STORAGESPACE_HEALTH = "VirtualDiskHealth";
	public const String CLUSREG_NAME_STORAGESPACE_STATE = "VirtualDiskState";
	public const String CLUSREG_NAME_STORAGESPACE_PROVISIONING = "VirtualDiskProvisioning";
	public const String CLUSREG_NAME_STORAGESPACE_RESILIENCYTYPE = "VirtualDiskResiliencyType";
	public const String CLUSREG_NAME_STORAGESPACE_RESILIENCYCOLUMNS = "VirtualDiskResiliencyColumns";
	public const String CLUSREG_NAME_STORAGESPACE_RESILIENCYINTERLEAVE = "VirtualDiskResiliencyInterleave";
	public const String CLUSREG_NAME_GENAPP_COMMAND_LINE = "CommandLine";
	public const String CLUSREG_NAME_GENAPP_CURRENT_DIRECTORY = "CurrentDirectory";
	public const String CLUSREG_NAME_GENAPP_USE_NETWORK_NAME = "UseNetworkName";
	public const String CLUSREG_NAME_GENSCRIPT_SCRIPT_FILEPATH = "ScriptFilepath";
	public const String CLUSREG_NAME_GENSVC_SERVICE_NAME = "ServiceName";
	public const String CLUSREG_NAME_GENSVC_STARTUP_PARAMS = "StartupParameters";
	public const String CLUSREG_NAME_GENSVC_USE_NETWORK_NAME = "UseNetworkName";
	public const String CLUSREG_NAME_IPADDR_NETWORK = "Network";
	public const String CLUSREG_NAME_IPADDR_ADDRESS = "Address";
	public const String CLUSREG_NAME_IPADDR_SUBNET_MASK = "SubnetMask";
	public const String CLUSREG_NAME_IPADDR_ENABLE_NETBIOS = "EnableNetBIOS";
	public const String CLUSREG_NAME_IPADDR_OVERRIDE_ADDRMATCH = "OverrideAddressMatch";
	public const String CLUSREG_NAME_IPADDR_ENABLE_DHCP = "EnableDhcp";
	public const String CLUSREG_NAME_IPADDR_LEASE_OBTAINED_TIME = "LeaseObtainedTime";
	public const String CLUSREG_NAME_IPADDR_LEASE_TERMINATES_TIME = "LeaseExpiresTime";
	public const String CLUSREG_NAME_IPADDR_T1 = "T1";
	public const String CLUSREG_NAME_IPADDR_T2 = "T2";
	public const String CLUSREG_NAME_IPADDR_DHCP_SERVER = "DhcpServer";
	public const String CLUSREG_NAME_IPADDR_DHCP_ADDRESS = "DhcpAddress";
	public const String CLUSREG_NAME_IPADDR_DHCP_SUBNET_MASK = "DhcpSubnetMask";
	public const String CLUSREG_NAME_IPADDR_SHARED_NETNAME = "SharedNetname";
	public const String CLUSREG_NAME_IPADDR_PROBE_PORT = "ProbePort";
	public const String CLUSREG_NAME_IPADDR_PROBE_FAILURE_THRESHOLD = "ProbeFailureThreshold";
	public const String CLUSREG_NAME_IPV6_NATIVE_NETWORK = "Network";
	public const String CLUSREG_NAME_IPV6_NATIVE_ADDRESS = "Address";
	public const String CLUSREG_NAME_IPV6_NATIVE_PREFIX_LENGTH = "PrefixLength";
	public const String CLUSREG_NAME_IPV6_TUNNEL_ADDRESS = "Address";
	public const String CLUSREG_NAME_IPV6_TUNNEL_TUNNELTYPE = "TunnelType";
	public const String CLUSREG_NAME_NETNAME_NAME = "Name";
	public const String CLUSREG_NAME_NETNAME_CREATING_DC = "CreatingDC";
	public const String CLUSREG_NAME_NETNAME_OBJECT_ID = "ObjectGUID";
	public const String CLUSREG_NAME_NETNAME_DNS_NAME = "DnsName";
	public const String CLUSREG_NAME_NETNAME_REMAP_PIPE_NAMES = "RemapPipeNames";
	public const String CLUSREG_NAME_NETNAME_RESOURCE_DATA = "ResourceData";
	public const String CLUSREG_NAME_NETNAME_STATUS_NETBIOS = "StatusNetBIOS";
	public const String CLUSREG_NAME_NETNAME_STATUS_DNS = "StatusDNS";
	public const String CLUSREG_NAME_NETNAME_STATUS_KERBEROS = "StatusKerberos";
	public const String CLUSREG_NAME_NETNAME_VCO_CONTAINER = "VcoContainer";
	public const String CLUSREG_NAME_NETNAME_LAST_DNS_UPDATE = "LastDNSUpdateTime";
	public const String CLUSREG_NAME_NETNAME_CONTAINERGUID = "CryptoContainerGUID";
	public const String CLUSREG_NAME_NETNAME_HOST_TTL = "HostRecordTTL";
	public const String CLUSREG_NAME_NETNAME_PUBLISH_PTR = "PublishPTRRecords";
	public const String CLUSREG_NAME_NETNAME_REMOVEVCO_ONDELETE = "DeleteVcoOnResCleanup";
	public const String CLUSREG_NAME_NETNAME_REGISTER_ALL_IP = "RegisterAllProvidersIP";
	public const String CLUSREG_KEYNAME_OBJECTGUIDS = "ObjectGUIDs";
	public const String CLUSREG_NAME_NETNAME_EXCLUDE_NETWORKS = "ExcludeNetworks";
	public const String CLUSREG_NAME_NETNAME_ALIASES = "Aliases";
	public const String CLUSREG_NAME_NETNAME_IN_USE_NETWORKS = "InUseNetworks";
	public const String CLUSREG_NAME_NETNAME_DNS_SUFFIX = "DnsSuffix";
	public const String CLUSREG_NAME_NETNAME_AD_AWARE = "ADAware";
	public const String CLUSREG_NAME_NETNAME_DNN_DISABLE_CLONES = "DisableClones";
	public const String CLUSREG_NAME_PRTSPOOL_DEFAULT_SPOOL_DIR = "DefaultSpoolDirectory";
	public const String CLUSREG_NAME_PRTSPOOL_TIMEOUT = "JobCompletionTimeout";
	public const String CLUSREG_NAME_FILESHR_SERVER_NAME = "ServerName";
	public const String CLUSREG_NAME_FILESHR_SHARE_NAME = "ShareName";
	public const String CLUSREG_NAME_FILESHR_PATH = "Path";
	public const String CLUSREG_NAME_FILESHR_REMARK = "Remark";
	public const String CLUSREG_NAME_FILESHR_MAX_USERS = "MaxUsers";
	public const String CLUSREG_NAME_FILESHR_SD = "Security Descriptor";
	public const String CLUSREG_NAME_FILESHR_SHARE_SUBDIRS = "ShareSubDirs";
	public const String CLUSREG_NAME_FILESHR_HIDE_SUBDIR_SHARES = "HideSubDirShares";
	public const String CLUSREG_NAME_FILESHR_IS_DFS_ROOT = "IsDfsRoot";
	public const String CLUSREG_NAME_FILESHR_SHARE_FLAGS = "ShareFlags";
	public const String CLUSREG_NAME_FILESHR_CA_TIMEOUT = "CATimeout";
	public const String CLUSREG_NAME_DHCP_DATABASE_PATH = "DatabasePath";
	public const String CLUSREG_NAME_DHCP_BACKUP_PATH = "BackupPath";
	public const String CLUSREG_NAME_LOG_FILE_PATH = "LogFilePath";
	public const String CLUSREG_NAME_WINS_DATABASE_PATH = "DatabasePath";
	public const String CLUSREG_NAME_WINS_BACKUP_PATH = "BackupPath";
	public const String CLUSREG_NAME_VSSTASK_CURRENTDIRECTORY = "CurrentDirectory";
	public const String CLUSREG_NAME_VSSTASK_APPNAME = "ApplicationName";
	public const String CLUSREG_NAME_VSSTASK_APPPARAMS = "ApplicationParams";
	public const String CLUSREG_NAME_VSSTASK_TRIGGERARRAY = "TriggerArray";
	public const String CLUSREG_NAME_FSWITNESS_SHARE_PATH = "SharePath";
	public const String CLUSREG_NAME_FSWITNESS_ARB_DELAY = "ArbitrationDelay";
	public const String CLUSREG_NAME_FSWITNESS_IMPERSONATE_CNO = "ImpersonateCNO";
	public const String CLUSREG_NAME_STORAGESPACE_POOLNAME = "Name";
	public const String CLUSREG_NAME_STORAGESPACE_POOLDESC = "Description";
	public const String CLUSREG_NAME_STORAGESPACE_POOLDRIVEIDS = "DriveIds";
	public const String CLUSREG_NAME_STORAGESPACE_POOLHEALTH = "Health";
	public const String CLUSREG_NAME_STORAGESPACE_POOLSTATE = "State";
	public const String CLUSREG_NAME_STORAGESPACE_POOLTOTALCAPACITY = "TotalCapacity";
	public const String CLUSREG_NAME_STORAGESPACE_POOLCONSUMEDCAPACITY = "ConsumedCapacity";
	public const String CLUSREG_NAME_STORAGESPACE_POOLARBITRATE = "Arbitrate";
	public const String CLUSREG_NAME_STORAGESPACE_POOLREEVALTIMEOUT = "ReEvaluatePlacementTimeout";
	public const String CLUSREG_NAME_STORAGESPACE_POOLQUORUMSHARE = "PoolQuorumShare";
	public const String CLUSREG_NAME_STORAGESPACE_POOLQUORUMUSERACCOUNT = "PoolQuorumUserAccount";
	public const String CLUSREG_NAME_SOFS_SMBASYMMETRYMODE = "SmbAsymmetryMode";
	public const String CLUSREG_NAME_VIP_PREFIX_LENGTH = "PrefixLength";
	public const String CLUSREG_NAME_VIP_ADAPTER_NAME = "AdapterName";
	public const String CLUSREG_NAME_VIP_ADDRESS = "Address";
	public const String CLUSREG_NAME_VIP_VSID = "VSID";
	public const String CLUSREG_NAME_VIP_RDID = "RDID";
	public const String CLUSREG_NAME_CLOUDWITNESS_PRIMARY_TOKEN = "PrimaryToken";
	public const String CLUSREG_NAME_CLOUDWITNESS_PRIMARY_KEY = "PrimaryKey";
	public const String CLUSREG_NAME_CLOUDWITNESS_ACCOUNT_NAME = "AccountName";
	public const String CLUSREG_NAME_CLOUDWITNESS_ENDPOINT_INFO = "EndpointInfo";
	public const String CLUSREG_NAME_CLOUDWITNESS_CONTAINER_NAME = "ContainerName";
	public const String CLOUD_WITNESS_CONTAINER_NAME = "msft-cloud-witness";
	public const String CLUS_NAME_RES_TYPE_SOURCE_RESID = "SourceResourceId";
	public const String CLUS_NAME_RES_TYPE_TARGET_RESID = "TargetResourceId";
	public const String CLUS_NAME_RES_TYPE_SOURCE_VOLUMES = "SourceVolumes";
	public const String CLUS_NAME_RES_TYPE_TARGET_VOLUMES = "TargetVolumes";
	public const String CLUS_NAME_RES_TYPE_DATA_RESID = "DataResourceId";
	public const String CLUS_NAME_RES_TYPE_LOG_RESID = "LogResourceId";
	public const String CLUS_NAME_RES_TYPE_LOG_VOLUME = "LogVolume";
	public const String CLUS_NAME_RES_TYPE_REPLICATION_GROUPID = "ReplicationGroupId";
	public const String CLUS_NAME_RES_TYPE_CLUSTER_GROUPID = "ClusterGroupId";
	public const String CLUS_NAME_RES_TYPE_REPLICATION_GROUP_TYPE = "ReplicationClusterGroupType";
	public const String CLUS_NAME_RES_TYPE_MINIMUM_LOG_SIZE = "MinimumLogSizeInBytes";
	public const String CLUS_NAME_RES_TYPE_UNIT_LOG_SIZE_CHANGE = "UnitOfLogSizeChangeInBytes";
	public const String CLUS_NAME_RES_TYPE_LOG_MULTIPLE = "LogSizeMultiple";
	public const uint32 SR_REPLICATED_PARTITION_DISALLOW_MULTINODE_IO = 1;
	public const uint32 CLUSCTL_RESOURCE_TYPE_STORAGE_GET_AVAILABLE_DISKS_EX2_FLAG_ADD_VOLUME_INFO = 1;
	public const uint32 CLUSCTL_RESOURCE_TYPE_STORAGE_GET_AVAILABLE_DISKS_EX2_FLAG_FILTER_BY_POOL = 2;
	public const uint32 CLUSCTL_RESOURCE_TYPE_STORAGE_GET_AVAILABLE_DISKS_EX2_FLAG_INCLUDE_NON_SHARED_DISKS = 4;
	public const String STARTUP_ROUTINE = "Startup";
	public const uint32 CLRES_VERSION_V1_00 = 256;
	public const String STARTUP_EX_ROUTINE = "StartupEx";
	public const uint32 CLRES_VERSION_V2_00 = 512;
	public const uint32 CLRES_VERSION_V3_00 = 768;
	public const uint32 CLRES_VERSION_V4_00 = 1024;
	public const uint32 CLUSCTL_GET_OPERATION_CONTEXT_PARAMS_VERSION_1 = 1;
	public const String CLUSRES_NAME_GET_OPERATION_CONTEXT_FLAGS = "Flags";
	public const uint32 CLUSRESDLL_STATUS_OFFLINE_BUSY = 1;
	public const uint32 CLUSRESDLL_STATUS_OFFLINE_SOURCE_THROTTLED = 2;
	public const uint32 CLUSRESDLL_STATUS_OFFLINE_DESTINATION_THROTTLED = 4;
	public const uint32 CLUSRESDLL_STATUS_OFFLINE_DESTINATION_REJECTED = 8;
	public const uint32 CLUSRESDLL_STATUS_INSUFFICIENT_MEMORY = 16;
	public const uint32 CLUSRESDLL_STATUS_INSUFFICIENT_PROCESSOR = 32;
	public const uint32 CLUSRESDLL_STATUS_INSUFFICIENT_OTHER_RESOURCES = 64;
	public const uint32 CLUSRESDLL_STATUS_INVALID_PARAMETERS = 128;
	public const uint32 CLUSRESDLL_STATUS_NETWORK_NOT_AVAILABLE = 256;
	public const uint32 CLUSRESDLL_STATUS_DO_NOT_COLLECT_WER_REPORT = 1073741824;
	public const uint32 CLUSRESDLL_STATUS_DUMP_NOW = 2147483648;
	public const uint32 CLUS_RESDLL_OPEN_RECOVER_MONITOR_STATE = 1;
	public const uint32 CLUS_RESDLL_ONLINE_RECOVER_MONITOR_STATE = 1;
	public const uint32 CLUS_RESDLL_ONLINE_IGNORE_RESOURCE_STATUS = 2;
	public const uint32 CLUS_RESDLL_ONLINE_RETURN_TO_SOURCE_NODE_ON_ERROR = 4;
	public const uint32 CLUS_RESDLL_ONLINE_RESTORE_ONLINE_STATE = 8;
	public const uint32 CLUS_RESDLL_ONLINE_IGNORE_NETWORK_CONNECTIVITY = 16;
	public const uint32 CLUS_RESDLL_OFFLINE_IGNORE_RESOURCE_STATUS = 1;
	public const uint32 CLUS_RESDLL_OFFLINE_RETURN_TO_SOURCE_NODE_ON_ERROR = 2;
	public const uint32 CLUS_RESDLL_OFFLINE_QUEUE_ENABLED = 4;
	public const uint32 CLUS_RESDLL_OFFLINE_RETURNING_TO_SOURCE_NODE_BECAUSE_OF_ERROR = 8;
	public const uint32 CLUS_RESDLL_OFFLINE_DUE_TO_EMBEDDED_FAILURE = 16;
	public const uint32 CLUS_RESDLL_OFFLINE_IGNORE_NETWORK_CONNECTIVITY = 32;
	public const uint32 CLUS_RESDLL_OFFLINE_DO_NOT_UPDATE_PERSISTENT_STATE = 64;
	public const uint32 CLUS_RESDLL_OPEN_DONT_DELETE_TEMP_DISK = 2;
	public const uint32 RESTYPE_MONITOR_SHUTTING_DOWN_NODE_STOP = 1;
	public const uint32 RESTYPE_MONITOR_SHUTTING_DOWN_CLUSSVC_CRASH = 2;
	public const uint32 RESUTIL_PROPITEM_READ_ONLY = 1;
	public const uint32 RESUTIL_PROPITEM_REQUIRED = 2;
	public const uint32 RESUTIL_PROPITEM_SIGNED = 4;
	public const uint32 RESUTIL_PROPITEM_IN_MEMORY = 8;
	public const uint32 LOCKED_MODE_FLAGS_DONT_REMOVE_FROM_MOVE_QUEUE = 1;
	public const String CLUSTER_HEALTH_FAULT_PROPERTY_NAME = "ClusterHealth";
	public const uint32 CLUSTER_HEALTH_FAULT_ARGS = 7;
	public const uint32 CLUSTER_HEALTH_FAULT_ID = 0;
	public const uint32 CLUSTER_HEALTH_FAULT_ERRORTYPE = 1;
	public const uint32 CLUSTER_HEALTH_FAULT_ERRORCODE = 2;
	public const uint32 CLUSTER_HEALTH_FAULT_DESCRIPTION = 3;
	public const uint32 CLUSTER_HEALTH_FAULT_PROVIDER = 4;
	public const uint32 CLUSTER_HEALTH_FAULT_FLAGS = 5;
	public const uint32 CLUSTER_HEALTH_FAULT_RESERVED = 6;
	public const String CLUSTER_HEALTH_FAULT_ID_LABEL = "Id";
	public const String CLUSTER_HEALTH_FAULT_ERRORTYPE_LABEL = "ErrorType";
	public const String CLUSTER_HEALTH_FAULT_ERRORCODE_LABEL = "ErrorCode";
	public const String CLUSTER_HEALTH_FAULT_DESCRIPTION_LABEL = "Description";
	public const String CLUSTER_HEALTH_FAULT_PROVIDER_LABEL = "Provider";
	public const String CLUSTER_HEALTH_FAULT_FLAGS_LABEL = "Flags";
	public const String CLUSTER_HEALTH_FAULT_RESERVED_LABEL = "Reserved";
	public const uint32 CLUS_CREATE_CRYPT_CONTAINER_NOT_FOUND = 1;
	public const uint32 SET_APPINSTANCE_CSV_FLAGS_VALID_ONLY_IF_CSV_COORDINATOR = 1;
}
#endregion

#region Enums

[AllowDuplicates]
public enum CLUSTER_QUORUM_TYPE : int32
{
	OperationalQuorum = 0,
	ModifyQuorum = 1,
}


[AllowDuplicates]
public enum NODE_CLUSTER_STATE : int32
{
	ClusterStateNotInstalled = 0,
	ClusterStateNotConfigured = 1,
	ClusterStateNotRunning = 3,
	ClusterStateRunning = 19,
}


[AllowDuplicates]
public enum CLUSTER_RESOURCE_STATE_CHANGE_REASON : int32
{
	eResourceStateChangeReasonUnknown = 0,
	eResourceStateChangeReasonMove = 1,
	eResourceStateChangeReasonFailover = 2,
	eResourceStateChangeReasonFailedMove = 3,
	eResourceStateChangeReasonShutdown = 4,
	eResourceStateChangeReasonRundown = 5,
}


[AllowDuplicates]
public enum CLUSTER_REG_COMMAND : int32
{
	CLUSREG_COMMAND_NONE = 0,
	CLUSREG_SET_VALUE = 1,
	CLUSREG_CREATE_KEY = 2,
	CLUSREG_DELETE_KEY = 3,
	CLUSREG_DELETE_VALUE = 4,
	CLUSREG_SET_KEY_SECURITY = 5,
	CLUSREG_VALUE_DELETED = 6,
	CLUSREG_READ_KEY = 7,
	CLUSREG_READ_VALUE = 8,
	CLUSREG_READ_ERROR = 9,
	CLUSREG_CONTROL_COMMAND = 10,
	CLUSREG_CONDITION_EXISTS = 11,
	CLUSREG_CONDITION_NOT_EXISTS = 12,
	CLUSREG_CONDITION_IS_EQUAL = 13,
	CLUSREG_CONDITION_IS_NOT_EQUAL = 14,
	CLUSREG_CONDITION_IS_GREATER_THAN = 15,
	CLUSREG_CONDITION_IS_LESS_THAN = 16,
	CLUSREG_CONDITION_KEY_EXISTS = 17,
	CLUSREG_CONDITION_KEY_NOT_EXISTS = 18,
	CLUSREG_LAST_COMMAND = 19,
}


[AllowDuplicates]
public enum CLUSGROUP_TYPE : int32
{
	ClusGroupTypeCoreCluster = 1,
	ClusGroupTypeAvailableStorage = 2,
	ClusGroupTypeTemporary = 3,
	ClusGroupTypeSharedVolume = 4,
	ClusGroupTypeStoragePool = 5,
	ClusGroupTypeFileServer = 100,
	ClusGroupTypePrintServer = 101,
	ClusGroupTypeDhcpServer = 102,
	ClusGroupTypeDtc = 103,
	ClusGroupTypeMsmq = 104,
	ClusGroupTypeWins = 105,
	ClusGroupTypeStandAloneDfs = 106,
	ClusGroupTypeGenericApplication = 107,
	ClusGroupTypeGenericService = 108,
	ClusGroupTypeGenericScript = 109,
	ClusGroupTypeIScsiNameService = 110,
	ClusGroupTypeVirtualMachine = 111,
	ClusGroupTypeTsSessionBroker = 112,
	ClusGroupTypeIScsiTarget = 113,
	ClusGroupTypeScaleoutFileServer = 114,
	ClusGroupTypeVMReplicaBroker = 115,
	ClusGroupTypeTaskScheduler = 116,
	ClusGroupTypeClusterUpdateAgent = 117,
	ClusGroupTypeScaleoutCluster = 118,
	ClusGroupTypeStorageReplica = 119,
	ClusGroupTypeVMReplicaCoordinator = 120,
	ClusGroupTypeCrossClusterOrchestrator = 121,
	ClusGroupTypeInfrastructureFileServer = 122,
	ClusGroupTypeCoreSddc = 123,
	ClusGroupTypeUnknown = 9999,
}


[AllowDuplicates]
public enum CLUSTER_MGMT_POINT_TYPE : int32
{
	CLUSTER_MGMT_POINT_TYPE_NONE = 0,
	CLUSTER_MGMT_POINT_TYPE_CNO = 1,
	CLUSTER_MGMT_POINT_TYPE_DNS_ONLY = 2,
	CLUSTER_MGMT_POINT_TYPE_CNO_ONLY = 3,
}


[AllowDuplicates]
public enum CLUSTER_MGMT_POINT_RESTYPE : int32
{
	CLUSTER_MGMT_POINT_RESTYPE_AUTO = 0,
	CLUSTER_MGMT_POINT_RESTYPE_SNN = 1,
	CLUSTER_MGMT_POINT_RESTYPE_DNN = 2,
}


[AllowDuplicates]
public enum CLUSTER_CLOUD_TYPE : int32
{
	CLUSTER_CLOUD_TYPE_NONE = 0,
	CLUSTER_CLOUD_TYPE_AZURE = 1,
	CLUSTER_CLOUD_TYPE_MIXED = 128,
	CLUSTER_CLOUD_TYPE_UNKNOWN = -1,
}


[AllowDuplicates]
public enum CLUS_GROUP_START_SETTING : int32
{
	CLUS_GROUP_START_ALWAYS = 0,
	CLUS_GROUP_DO_NOT_START = 1,
	CLUS_GROUP_START_ALLOWED = 2,
}


[AllowDuplicates]
public enum CLUS_AFFINITY_RULE_TYPE : int32
{
	CLUS_AFFINITY_RULE_NONE = 0,
	CLUS_AFFINITY_RULE_SAME_FAULT_DOMAIN = 1,
	CLUS_AFFINITY_RULE_SAME_NODE = 2,
	CLUS_AFFINITY_RULE_DIFFERENT_FAULT_DOMAIN = 3,
	CLUS_AFFINITY_RULE_DIFFERENT_NODE = 4,
	CLUS_AFFINITY_RULE_MIN = 0,
	CLUS_AFFINITY_RULE_MAX = 4,
}


[AllowDuplicates]
public enum CLUSTER_QUORUM_VALUE : int32
{
	CLUSTER_QUORUM_MAINTAINED = 0,
	CLUSTER_QUORUM_LOST = 1,
}


[AllowDuplicates]
public enum CLUSTER_UPGRADE_PHASE : int32
{
	ClusterUpgradePhaseInitialize = 1,
	ClusterUpgradePhaseValidatingUpgrade = 2,
	ClusterUpgradePhaseUpgradingComponents = 3,
	ClusterUpgradePhaseInstallingNewComponents = 4,
	ClusterUpgradePhaseUpgradeComplete = 5,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE : int32
{
	CLUSTER_CHANGE_NODE_STATE = 1,
	CLUSTER_CHANGE_NODE_DELETED = 2,
	CLUSTER_CHANGE_NODE_ADDED = 4,
	CLUSTER_CHANGE_NODE_PROPERTY = 8,
	CLUSTER_CHANGE_REGISTRY_NAME = 16,
	CLUSTER_CHANGE_REGISTRY_ATTRIBUTES = 32,
	CLUSTER_CHANGE_REGISTRY_VALUE = 64,
	CLUSTER_CHANGE_REGISTRY_SUBTREE = 128,
	CLUSTER_CHANGE_RESOURCE_STATE = 256,
	CLUSTER_CHANGE_RESOURCE_DELETED = 512,
	CLUSTER_CHANGE_RESOURCE_ADDED = 1024,
	CLUSTER_CHANGE_RESOURCE_PROPERTY = 2048,
	CLUSTER_CHANGE_GROUP_STATE = 4096,
	CLUSTER_CHANGE_GROUP_DELETED = 8192,
	CLUSTER_CHANGE_GROUP_ADDED = 16384,
	CLUSTER_CHANGE_GROUP_PROPERTY = 32768,
	CLUSTER_CHANGE_RESOURCE_TYPE_DELETED = 65536,
	CLUSTER_CHANGE_RESOURCE_TYPE_ADDED = 131072,
	CLUSTER_CHANGE_RESOURCE_TYPE_PROPERTY = 262144,
	CLUSTER_CHANGE_CLUSTER_RECONNECT = 524288,
	CLUSTER_CHANGE_NETWORK_STATE = 1048576,
	CLUSTER_CHANGE_NETWORK_DELETED = 2097152,
	CLUSTER_CHANGE_NETWORK_ADDED = 4194304,
	CLUSTER_CHANGE_NETWORK_PROPERTY = 8388608,
	CLUSTER_CHANGE_NETINTERFACE_STATE = 16777216,
	CLUSTER_CHANGE_NETINTERFACE_DELETED = 33554432,
	CLUSTER_CHANGE_NETINTERFACE_ADDED = 67108864,
	CLUSTER_CHANGE_NETINTERFACE_PROPERTY = 134217728,
	CLUSTER_CHANGE_QUORUM_STATE = 268435456,
	CLUSTER_CHANGE_CLUSTER_STATE = 536870912,
	CLUSTER_CHANGE_CLUSTER_PROPERTY = 1073741824,
	CLUSTER_CHANGE_HANDLE_CLOSE = -2147483648,
	CLUSTER_CHANGE_ALL = -1,
}


[AllowDuplicates]
public enum CLUSTER_NOTIFICATIONS_VERSION : int32
{
	CLUSTER_NOTIFICATIONS_V1 = 1,
	CLUSTER_NOTIFICATIONS_V2 = 2,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE_CLUSTER_V2 : int32
{
	CLUSTER_CHANGE_CLUSTER_RECONNECT_V2 = 1,
	CLUSTER_CHANGE_CLUSTER_STATE_V2 = 2,
	CLUSTER_CHANGE_CLUSTER_GROUP_ADDED_V2 = 4,
	CLUSTER_CHANGE_CLUSTER_HANDLE_CLOSE_V2 = 8,
	CLUSTER_CHANGE_CLUSTER_NETWORK_ADDED_V2 = 16,
	CLUSTER_CHANGE_CLUSTER_NODE_ADDED_V2 = 32,
	CLUSTER_CHANGE_CLUSTER_RESOURCE_TYPE_ADDED_V2 = 64,
	CLUSTER_CHANGE_CLUSTER_COMMON_PROPERTY_V2 = 128,
	CLUSTER_CHANGE_CLUSTER_PRIVATE_PROPERTY_V2 = 256,
	CLUSTER_CHANGE_CLUSTER_LOST_NOTIFICATIONS_V2 = 512,
	CLUSTER_CHANGE_CLUSTER_RENAME_V2 = 1024,
	CLUSTER_CHANGE_CLUSTER_MEMBERSHIP_V2 = 2048,
	CLUSTER_CHANGE_CLUSTER_UPGRADED_V2 = 4096,
	CLUSTER_CHANGE_CLUSTER_ALL_V2 = 8191,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE_GROUP_V2 : int32
{
	CLUSTER_CHANGE_GROUP_DELETED_V2 = 1,
	CLUSTER_CHANGE_GROUP_COMMON_PROPERTY_V2 = 2,
	CLUSTER_CHANGE_GROUP_PRIVATE_PROPERTY_V2 = 4,
	CLUSTER_CHANGE_GROUP_STATE_V2 = 8,
	CLUSTER_CHANGE_GROUP_OWNER_NODE_V2 = 16,
	CLUSTER_CHANGE_GROUP_PREFERRED_OWNERS_V2 = 32,
	CLUSTER_CHANGE_GROUP_RESOURCE_ADDED_V2 = 64,
	CLUSTER_CHANGE_GROUP_RESOURCE_GAINED_V2 = 128,
	CLUSTER_CHANGE_GROUP_RESOURCE_LOST_V2 = 256,
	CLUSTER_CHANGE_GROUP_HANDLE_CLOSE_V2 = 512,
	CLUSTER_CHANGE_GROUP_ALL_V2 = 1023,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE_GROUPSET_V2 : int32
{
	CLUSTER_CHANGE_GROUPSET_DELETED_v2 = 1,
	CLUSTER_CHANGE_GROUPSET_COMMON_PROPERTY_V2 = 2,
	CLUSTER_CHANGE_GROUPSET_PRIVATE_PROPERTY_V2 = 4,
	CLUSTER_CHANGE_GROUPSET_STATE_V2 = 8,
	CLUSTER_CHANGE_GROUPSET_GROUP_ADDED = 16,
	CLUSTER_CHANGE_GROUPSET_GROUP_REMOVED = 32,
	CLUSTER_CHANGE_GROUPSET_DEPENDENCIES_V2 = 64,
	CLUSTER_CHANGE_GROUPSET_DEPENDENTS_V2 = 128,
	CLUSTER_CHANGE_GROUPSET_HANDLE_CLOSE_v2 = 256,
	CLUSTER_CHANGE_GROUPSET_ALL_V2 = 511,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE_RESOURCE_V2 : int32
{
	CLUSTER_CHANGE_RESOURCE_COMMON_PROPERTY_V2 = 1,
	CLUSTER_CHANGE_RESOURCE_PRIVATE_PROPERTY_V2 = 2,
	CLUSTER_CHANGE_RESOURCE_STATE_V2 = 4,
	CLUSTER_CHANGE_RESOURCE_OWNER_GROUP_V2 = 8,
	CLUSTER_CHANGE_RESOURCE_DEPENDENCIES_V2 = 16,
	CLUSTER_CHANGE_RESOURCE_DEPENDENTS_V2 = 32,
	CLUSTER_CHANGE_RESOURCE_POSSIBLE_OWNERS_V2 = 64,
	CLUSTER_CHANGE_RESOURCE_DELETED_V2 = 128,
	CLUSTER_CHANGE_RESOURCE_DLL_UPGRADED_V2 = 256,
	CLUSTER_CHANGE_RESOURCE_HANDLE_CLOSE_V2 = 512,
	CLUSTER_CHANGE_RESOURCE_TERMINAL_STATE_V2 = 1024,
	CLUSTER_CHANGE_RESOURCE_ALL_V2 = 2047,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE_RESOURCE_TYPE_V2 : int32
{
	CLUSTER_CHANGE_RESOURCE_TYPE_DELETED_V2 = 1,
	CLUSTER_CHANGE_RESOURCE_TYPE_COMMON_PROPERTY_V2 = 2,
	CLUSTER_CHANGE_RESOURCE_TYPE_PRIVATE_PROPERTY_V2 = 4,
	CLUSTER_CHANGE_RESOURCE_TYPE_POSSIBLE_OWNERS_V2 = 8,
	CLUSTER_CHANGE_RESOURCE_TYPE_DLL_UPGRADED_V2 = 16,
	CLUSTER_RESOURCE_TYPE_SPECIFIC_V2 = 32,
	CLUSTER_CHANGE_RESOURCE_TYPE_ALL_V2 = 63,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE_NETINTERFACE_V2 : int32
{
	CLUSTER_CHANGE_NETINTERFACE_DELETED_V2 = 1,
	CLUSTER_CHANGE_NETINTERFACE_COMMON_PROPERTY_V2 = 2,
	CLUSTER_CHANGE_NETINTERFACE_PRIVATE_PROPERTY_V2 = 4,
	CLUSTER_CHANGE_NETINTERFACE_STATE_V2 = 8,
	CLUSTER_CHANGE_NETINTERFACE_HANDLE_CLOSE_V2 = 16,
	CLUSTER_CHANGE_NETINTERFACE_ALL_V2 = 31,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE_NETWORK_V2 : int32
{
	CLUSTER_CHANGE_NETWORK_DELETED_V2 = 1,
	CLUSTER_CHANGE_NETWORK_COMMON_PROPERTY_V2 = 2,
	CLUSTER_CHANGE_NETWORK_PRIVATE_PROPERTY_V2 = 4,
	CLUSTER_CHANGE_NETWORK_STATE_V2 = 8,
	CLUSTER_CHANGE_NETWORK_HANDLE_CLOSE_V2 = 16,
	CLUSTER_CHANGE_NETWORK_ALL_V2 = 31,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE_NODE_V2 : int32
{
	CLUSTER_CHANGE_NODE_NETINTERFACE_ADDED_V2 = 1,
	CLUSTER_CHANGE_NODE_DELETED_V2 = 2,
	CLUSTER_CHANGE_NODE_COMMON_PROPERTY_V2 = 4,
	CLUSTER_CHANGE_NODE_PRIVATE_PROPERTY_V2 = 8,
	CLUSTER_CHANGE_NODE_STATE_V2 = 16,
	CLUSTER_CHANGE_NODE_GROUP_GAINED_V2 = 32,
	CLUSTER_CHANGE_NODE_GROUP_LOST_V2 = 64,
	CLUSTER_CHANGE_NODE_HANDLE_CLOSE_V2 = 128,
	CLUSTER_CHANGE_NODE_ALL_V2 = 255,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE_REGISTRY_V2 : int32
{
	CLUSTER_CHANGE_REGISTRY_ATTRIBUTES_V2 = 1,
	CLUSTER_CHANGE_REGISTRY_NAME_V2 = 2,
	CLUSTER_CHANGE_REGISTRY_SUBTREE_V2 = 4,
	CLUSTER_CHANGE_REGISTRY_VALUE_V2 = 8,
	CLUSTER_CHANGE_REGISTRY_HANDLE_CLOSE_V2 = 16,
	CLUSTER_CHANGE_REGISTRY_ALL_V2 = 31,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE_QUORUM_V2 : int32
{
	CLUSTER_CHANGE_QUORUM_STATE_V2 = 1,
	CLUSTER_CHANGE_QUORUM_ALL_V2 = 1,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE_SHARED_VOLUME_V2 : int32
{
	CLUSTER_CHANGE_SHARED_VOLUME_STATE_V2 = 1,
	CLUSTER_CHANGE_SHARED_VOLUME_ADDED_V2 = 2,
	CLUSTER_CHANGE_SHARED_VOLUME_REMOVED_V2 = 4,
	CLUSTER_CHANGE_SHARED_VOLUME_ALL_V2 = 7,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE_SPACEPORT_V2 : int32
{
	CLUSTER_CHANGE_SPACEPORT_CUSTOM_PNP_V2 = 1,
}


[AllowDuplicates]
public enum CLUSTER_CHANGE_NODE_UPGRADE_PHASE_V2 : int32
{
	CLUSTER_CHANGE_UPGRADE_NODE_PREPARE = 1,
	CLUSTER_CHANGE_UPGRADE_NODE_COMMIT = 2,
	CLUSTER_CHANGE_UPGRADE_NODE_POSTCOMMIT = 4,
	CLUSTER_CHANGE_UPGRADE_ALL = 7,
}


[AllowDuplicates]
public enum CLUSTER_OBJECT_TYPE : int32
{
	CLUSTER_OBJECT_TYPE_NONE = 0,
	CLUSTER_OBJECT_TYPE_CLUSTER = 1,
	CLUSTER_OBJECT_TYPE_GROUP = 2,
	CLUSTER_OBJECT_TYPE_RESOURCE = 3,
	CLUSTER_OBJECT_TYPE_RESOURCE_TYPE = 4,
	CLUSTER_OBJECT_TYPE_NETWORK_INTERFACE = 5,
	CLUSTER_OBJECT_TYPE_NETWORK = 6,
	CLUSTER_OBJECT_TYPE_NODE = 7,
	CLUSTER_OBJECT_TYPE_REGISTRY = 8,
	CLUSTER_OBJECT_TYPE_QUORUM = 9,
	CLUSTER_OBJECT_TYPE_SHARED_VOLUME = 10,
	CLUSTER_OBJECT_TYPE_GROUPSET = 13,
	CLUSTER_OBJECT_TYPE_AFFINITYRULE = 16,
}


[AllowDuplicates]
public enum CLUSTERSET_OBJECT_TYPE : int32
{
	CLUSTERSET_OBJECT_TYPE_NONE = 0,
	CLUSTERSET_OBJECT_TYPE_MEMBER = 1,
	CLUSTERSET_OBJECT_TYPE_WORKLOAD = 2,
	CLUSTERSET_OBJECT_TYPE_DATABASE = 3,
}


[AllowDuplicates]
public enum CLUSTER_ENUM : int32
{
	CLUSTER_ENUM_NODE = 1,
	CLUSTER_ENUM_RESTYPE = 2,
	CLUSTER_ENUM_RESOURCE = 4,
	CLUSTER_ENUM_GROUP = 8,
	CLUSTER_ENUM_NETWORK = 16,
	CLUSTER_ENUM_NETINTERFACE = 32,
	CLUSTER_ENUM_SHARED_VOLUME_GROUP = 536870912,
	CLUSTER_ENUM_SHARED_VOLUME_RESOURCE = 1073741824,
	CLUSTER_ENUM_INTERNAL_NETWORK = -2147483648,
	CLUSTER_ENUM_ALL = 63,
}


[AllowDuplicates]
public enum CLUSTER_NODE_ENUM : int32
{
	CLUSTER_NODE_ENUM_NETINTERFACES = 1,
	CLUSTER_NODE_ENUM_GROUPS = 2,
	CLUSTER_NODE_ENUM_PREFERRED_GROUPS = 4,
	CLUSTER_NODE_ENUM_ALL = 3,
}


[AllowDuplicates]
public enum CLUSTER_NODE_STATE : int32
{
	ClusterNodeStateUnknown = -1,
	ClusterNodeUp = 0,
	ClusterNodeDown = 1,
	ClusterNodePaused = 2,
	ClusterNodeJoining = 3,
}


[AllowDuplicates]
public enum CLUSTER_STORAGENODE_STATE : int32
{
	ClusterStorageNodeStateUnknown = 0,
	ClusterStorageNodeUp = 1,
	ClusterStorageNodeDown = 2,
	ClusterStorageNodePaused = 3,
	ClusterStorageNodeStarting = 4,
	ClusterStorageNodeStopping = 5,
}


[AllowDuplicates]
public enum CLUSTER_NODE_DRAIN_STATUS : int32
{
	NodeDrainStatusNotInitiated = 0,
	NodeDrainStatusInProgress = 1,
	NodeDrainStatusCompleted = 2,
	NodeDrainStatusFailed = 3,
	ClusterNodeDrainStatusCount = 4,
}


[AllowDuplicates]
public enum CLUSTER_NODE_STATUS : int32
{
	NodeStatusNormal = 0,
	NodeStatusIsolated = 1,
	NodeStatusQuarantined = 2,
	NodeStatusDrainInProgress = 4,
	NodeStatusDrainCompleted = 8,
	NodeStatusDrainFailed = 16,
	NodeStatusAvoidPlacement = 32,
	NodeStatusMax = 51,
}


[AllowDuplicates]
public enum CLUSTER_GROUP_ENUM : int32
{
	CLUSTER_GROUP_ENUM_CONTAINS = 1,
	CLUSTER_GROUP_ENUM_NODES = 2,
	CLUSTER_GROUP_ENUM_ALL = 3,
}


[AllowDuplicates]
public enum CLUSTER_GROUP_STATE : int32
{
	ClusterGroupStateUnknown = -1,
	ClusterGroupOnline = 0,
	ClusterGroupOffline = 1,
	ClusterGroupFailed = 2,
	ClusterGroupPartialOnline = 3,
	ClusterGroupPending = 4,
}


[AllowDuplicates]
public enum CLUSTER_GROUP_PRIORITY : int32
{
	PriorityDisabled = 0,
	PriorityLow = 1000,
	PriorityMedium = 2000,
	PriorityHigh = 3000,
}


[AllowDuplicates]
public enum CLUSTER_GROUP_AUTOFAILBACK_TYPE : int32
{
	ClusterGroupPreventFailback = 0,
	ClusterGroupAllowFailback = 1,
	ClusterGroupFailbackTypeCount = 2,
}


[AllowDuplicates]
public enum CLUSTER_NODE_RESUME_FAILBACK_TYPE : int32
{
	DoNotFailbackGroups = 0,
	FailbackGroupsImmediately = 1,
	FailbackGroupsPerPolicy = 2,
	ClusterNodeResumeFailbackTypeCount = 3,
}


[AllowDuplicates]
public enum CLUSTER_RESOURCE_STATE : int32
{
	ClusterResourceStateUnknown = -1,
	ClusterResourceInherited = 0,
	ClusterResourceInitializing = 1,
	ClusterResourceOnline = 2,
	ClusterResourceOffline = 3,
	ClusterResourceFailed = 4,
	ClusterResourcePending = 128,
	ClusterResourceOnlinePending = 129,
	ClusterResourceOfflinePending = 130,
}


[AllowDuplicates]
public enum CLUSTER_RESOURCE_RESTART_ACTION : int32
{
	ClusterResourceDontRestart = 0,
	ClusterResourceRestartNoNotify = 1,
	ClusterResourceRestartNotify = 2,
	ClusterResourceRestartActionCount = 3,
}


[AllowDuplicates]
public enum CLUSTER_RESOURCE_EMBEDDED_FAILURE_ACTION : int32
{
	ClusterResourceEmbeddedFailureActionNone = 0,
	ClusterResourceEmbeddedFailureActionLogOnly = 1,
	ClusterResourceEmbeddedFailureActionRecover = 2,
}


[AllowDuplicates]
public enum CLUSTER_RESOURCE_CREATE_FLAGS : int32
{
	CLUSTER_RESOURCE_DEFAULT_MONITOR = 0,
	CLUSTER_RESOURCE_SEPARATE_MONITOR = 1,
	CLUSTER_RESOURCE_VALID_FLAGS = 1,
}


[AllowDuplicates]
public enum CLUSTER_SHARED_VOLUME_SNAPSHOT_STATE : int32
{
	ClusterSharedVolumeSnapshotStateUnknown = 0,
	ClusterSharedVolumePrepareForHWSnapshot = 1,
	ClusterSharedVolumeHWSnapshotCompleted = 2,
	ClusterSharedVolumePrepareForFreeze = 3,
}


[AllowDuplicates]
public enum CLUSTER_PROPERTY_TYPE : int32
{
	CLUSPROP_TYPE_UNKNOWN = -1,
	CLUSPROP_TYPE_ENDMARK = 0,
	CLUSPROP_TYPE_LIST_VALUE = 1,
	CLUSPROP_TYPE_RESCLASS = 2,
	CLUSPROP_TYPE_RESERVED1 = 3,
	CLUSPROP_TYPE_NAME = 4,
	CLUSPROP_TYPE_SIGNATURE = 5,
	CLUSPROP_TYPE_SCSI_ADDRESS = 6,
	CLUSPROP_TYPE_DISK_NUMBER = 7,
	CLUSPROP_TYPE_PARTITION_INFO = 8,
	CLUSPROP_TYPE_FTSET_INFO = 9,
	CLUSPROP_TYPE_DISK_SERIALNUMBER = 10,
	CLUSPROP_TYPE_DISK_GUID = 11,
	CLUSPROP_TYPE_DISK_SIZE = 12,
	CLUSPROP_TYPE_PARTITION_INFO_EX = 13,
	CLUSPROP_TYPE_PARTITION_INFO_EX2 = 14,
	CLUSPROP_TYPE_STORAGE_DEVICE_ID_DESCRIPTOR = 15,
	CLUSPROP_TYPE_USER = 32768,
}


[AllowDuplicates]
public enum CLUSTER_PROPERTY_FORMAT : int32
{
	CLUSPROP_FORMAT_UNKNOWN = 0,
	CLUSPROP_FORMAT_BINARY = 1,
	CLUSPROP_FORMAT_DWORD = 2,
	CLUSPROP_FORMAT_SZ = 3,
	CLUSPROP_FORMAT_EXPAND_SZ = 4,
	CLUSPROP_FORMAT_MULTI_SZ = 5,
	CLUSPROP_FORMAT_ULARGE_INTEGER = 6,
	CLUSPROP_FORMAT_LONG = 7,
	CLUSPROP_FORMAT_EXPANDED_SZ = 8,
	CLUSPROP_FORMAT_SECURITY_DESCRIPTOR = 9,
	CLUSPROP_FORMAT_LARGE_INTEGER = 10,
	CLUSPROP_FORMAT_WORD = 11,
	CLUSPROP_FORMAT_FILETIME = 12,
	CLUSPROP_FORMAT_VALUE_LIST = 13,
	CLUSPROP_FORMAT_PROPERTY_LIST = 14,
	CLUSPROP_FORMAT_USER = 32768,
}


[AllowDuplicates]
public enum CLUSTER_PROPERTY_SYNTAX : uint32
{
	CLUSPROP_SYNTAX_ENDMARK = 0,
	CLUSPROP_SYNTAX_NAME = 262147,
	CLUSPROP_SYNTAX_RESCLASS = 131074,
	CLUSPROP_SYNTAX_LIST_VALUE_SZ = 65539,
	CLUSPROP_SYNTAX_LIST_VALUE_EXPAND_SZ = 65540,
	CLUSPROP_SYNTAX_LIST_VALUE_DWORD = 65538,
	CLUSPROP_SYNTAX_LIST_VALUE_BINARY = 65537,
	CLUSPROP_SYNTAX_LIST_VALUE_MULTI_SZ = 65541,
	CLUSPROP_SYNTAX_LIST_VALUE_LONG = 65543,
	CLUSPROP_SYNTAX_LIST_VALUE_EXPANDED_SZ = 65544,
	CLUSPROP_SYNTAX_LIST_VALUE_SECURITY_DESCRIPTOR = 65545,
	CLUSPROP_SYNTAX_LIST_VALUE_LARGE_INTEGER = 65546,
	CLUSPROP_SYNTAX_LIST_VALUE_ULARGE_INTEGER = 65542,
	CLUSPROP_SYNTAX_LIST_VALUE_WORD = 65547,
	CLUSPROP_SYNTAX_LIST_VALUE_PROPERTY_LIST = 65550,
	CLUSPROP_SYNTAX_LIST_VALUE_FILETIME = 65548,
	CLUSPROP_SYNTAX_DISK_SIGNATURE = 327682,
	CLUSPROP_SYNTAX_SCSI_ADDRESS = 393218,
	CLUSPROP_SYNTAX_DISK_NUMBER = 458754,
	CLUSPROP_SYNTAX_PARTITION_INFO = 524289,
	CLUSPROP_SYNTAX_FTSET_INFO = 589825,
	CLUSPROP_SYNTAX_DISK_SERIALNUMBER = 655363,
	CLUSPROP_SYNTAX_DISK_GUID = 720899,
	CLUSPROP_SYNTAX_DISK_SIZE = 786438,
	CLUSPROP_SYNTAX_PARTITION_INFO_EX = 851969,
	CLUSPROP_SYNTAX_PARTITION_INFO_EX2 = 917505,
	CLUSPROP_SYNTAX_STORAGE_DEVICE_ID_DESCRIPTOR = 983041,
}


[AllowDuplicates]
public enum CLUSTER_CONTROL_OBJECT : int32
{
	CLUS_OBJECT_INVALID = 0,
	CLUS_OBJECT_RESOURCE = 1,
	CLUS_OBJECT_RESOURCE_TYPE = 2,
	CLUS_OBJECT_GROUP = 3,
	CLUS_OBJECT_NODE = 4,
	CLUS_OBJECT_NETWORK = 5,
	CLUS_OBJECT_NETINTERFACE = 6,
	CLUS_OBJECT_CLUSTER = 7,
	CLUS_OBJECT_GROUPSET = 8,
	CLUS_OBJECT_AFFINITYRULE = 9,
	CLUS_OBJECT_USER = 128,
}


[AllowDuplicates]
public enum CLCTL_CODES : int32
{
	CLCTL_UNKNOWN = 0,
	CLCTL_GET_CHARACTERISTICS = 5,
	CLCTL_GET_FLAGS = 9,
	CLCTL_GET_CLASS_INFO = 13,
	CLCTL_GET_REQUIRED_DEPENDENCIES = 17,
	CLCTL_GET_ARB_TIMEOUT = 21,
	CLCTL_GET_FAILURE_INFO = 25,
	CLCTL_GET_NAME = 41,
	CLCTL_GET_RESOURCE_TYPE = 45,
	CLCTL_GET_NODE = 49,
	CLCTL_GET_NETWORK = 53,
	CLCTL_GET_ID = 57,
	CLCTL_GET_FQDN = 61,
	CLCTL_GET_CLUSTER_SERVICE_ACCOUNT_NAME = 65,
	CLCTL_CHECK_VOTER_EVICT = 69,
	CLCTL_CHECK_VOTER_DOWN = 73,
	CLCTL_SHUTDOWN = 77,
	CLCTL_ENUM_COMMON_PROPERTIES = 81,
	CLCTL_GET_RO_COMMON_PROPERTIES = 85,
	CLCTL_GET_COMMON_PROPERTIES = 89,
	CLCTL_SET_COMMON_PROPERTIES = 4194398,
	CLCTL_VALIDATE_COMMON_PROPERTIES = 97,
	CLCTL_GET_COMMON_PROPERTY_FMTS = 101,
	CLCTL_GET_COMMON_RESOURCE_PROPERTY_FMTS = 105,
	CLCTL_ENUM_PRIVATE_PROPERTIES = 121,
	CLCTL_GET_RO_PRIVATE_PROPERTIES = 125,
	CLCTL_GET_PRIVATE_PROPERTIES = 129,
	CLCTL_SET_PRIVATE_PROPERTIES = 4194438,
	CLCTL_VALIDATE_PRIVATE_PROPERTIES = 137,
	CLCTL_GET_PRIVATE_PROPERTY_FMTS = 141,
	CLCTL_GET_PRIVATE_RESOURCE_PROPERTY_FMTS = 145,
	CLCTL_ADD_REGISTRY_CHECKPOINT = 4194466,
	CLCTL_DELETE_REGISTRY_CHECKPOINT = 4194470,
	CLCTL_GET_REGISTRY_CHECKPOINTS = 169,
	CLCTL_ADD_CRYPTO_CHECKPOINT = 4194478,
	CLCTL_DELETE_CRYPTO_CHECKPOINT = 4194482,
	CLCTL_GET_CRYPTO_CHECKPOINTS = 181,
	CLCTL_RESOURCE_UPGRADE_DLL = 4194490,
	CLCTL_ADD_REGISTRY_CHECKPOINT_64BIT = 4194494,
	CLCTL_ADD_REGISTRY_CHECKPOINT_32BIT = 4194498,
	CLCTL_GET_LOADBAL_PROCESS_LIST = 201,
	CLCTL_SET_ACCOUNT_ACCESS = 4194546,
	CLCTL_GET_NETWORK_NAME = 361,
	CLCTL_NETNAME_GET_VIRTUAL_SERVER_TOKEN = 365,
	CLCTL_NETNAME_REGISTER_DNS_RECORDS = 370,
	CLCTL_GET_DNS_NAME = 373,
	CLCTL_NETNAME_SET_PWD_INFO = 378,
	CLCTL_NETNAME_DELETE_CO = 382,
	CLCTL_NETNAME_VALIDATE_VCO = 385,
	CLCTL_NETNAME_RESET_VCO = 389,
	CLCTL_NETNAME_REPAIR_VCO = 397,
	CLCTL_STORAGE_GET_DISK_INFO = 401,
	CLCTL_STORAGE_GET_AVAILABLE_DISKS = 405,
	CLCTL_STORAGE_IS_PATH_VALID = 409,
	CLCTL_STORAGE_SYNC_CLUSDISK_DB = 4194718,
	CLCTL_STORAGE_GET_DISK_NUMBER_INFO = 417,
	CLCTL_QUERY_DELETE = 441,
	CLCTL_IPADDRESS_RENEW_LEASE = 4194750,
	CLCTL_IPADDRESS_RELEASE_LEASE = 4194754,
	CLCTL_QUERY_MAINTENANCE_MODE = 481,
	CLCTL_SET_MAINTENANCE_MODE = 4194790,
	CLCTL_STORAGE_SET_DRIVELETTER = 4194794,
	CLCTL_STORAGE_GET_DRIVELETTERS = 493,
	CLCTL_STORAGE_GET_DISK_INFO_EX = 497,
	CLCTL_STORAGE_GET_AVAILABLE_DISKS_EX = 501,
	CLCTL_STORAGE_GET_DISK_INFO_EX2 = 505,
	CLCTL_STORAGE_GET_CLUSPORT_DISK_COUNT = 509,
	CLCTL_STORAGE_REMAP_DRIVELETTER = 513,
	CLCTL_STORAGE_GET_DISKID = 517,
	CLCTL_STORAGE_IS_CLUSTERABLE = 521,
	CLCTL_STORAGE_REMOVE_VM_OWNERSHIP = 4194830,
	CLCTL_STORAGE_GET_MOUNTPOINTS = 529,
	CLCTL_STORAGE_GET_DIRTY = 537,
	CLCTL_STORAGE_GET_SHARED_VOLUME_INFO = 549,
	CLCTL_STORAGE_IS_CSV_FILE = 553,
	CLCTL_STORAGE_GET_RESOURCEID = 557,
	CLCTL_VALIDATE_PATH = 561,
	CLCTL_VALIDATE_NETNAME = 565,
	CLCTL_VALIDATE_DIRECTORY = 569,
	CLCTL_BATCH_BLOCK_KEY = 574,
	CLCTL_BATCH_UNBLOCK_KEY = 577,
	CLCTL_FILESERVER_SHARE_ADD = 4194886,
	CLCTL_FILESERVER_SHARE_DEL = 4194890,
	CLCTL_FILESERVER_SHARE_MODIFY = 4194894,
	CLCTL_FILESERVER_SHARE_REPORT = 593,
	CLCTL_NETNAME_GET_OU_FOR_VCO = 4194926,
	CLCTL_ENABLE_SHARED_VOLUME_DIRECTIO = 4194954,
	CLCTL_DISABLE_SHARED_VOLUME_DIRECTIO = 4194958,
	CLCTL_GET_SHARED_VOLUME_ID = 657,
	CLCTL_SET_CSV_MAINTENANCE_MODE = 4194966,
	CLCTL_SET_SHARED_VOLUME_BACKUP_MODE = 4194970,
	CLCTL_STORAGE_GET_SHARED_VOLUME_PARTITION_NAMES = 669,
	CLCTL_STORAGE_GET_SHARED_VOLUME_STATES = 4194978,
	CLCTL_STORAGE_IS_SHARED_VOLUME = 677,
	CLCTL_GET_CLUSDB_TIMESTAMP = 681,
	CLCTL_RW_MODIFY_NOOP = 4194990,
	CLCTL_IS_QUORUM_BLOCKED = 689,
	CLCTL_POOL_GET_DRIVE_INFO = 693,
	CLCTL_GET_GUM_LOCK_OWNER = 697,
	CLCTL_GET_STUCK_NODES = 701,
	CLCTL_INJECT_GEM_FAULT = 705,
	CLCTL_INTRODUCE_GEM_REPAIR_DELAY = 709,
	CLCTL_SEND_DUMMY_GEM_MESSAGES = 713,
	CLCTL_BLOCK_GEM_SEND_RECV = 717,
	CLCTL_GET_GEMID_VECTOR = 721,
	CLCTL_ADD_CRYPTO_CHECKPOINT_EX = 4195030,
	CLCTL_GROUP_GET_LAST_MOVE_TIME = 729,
	CLCTL_SET_STORAGE_CONFIGURATION = 4195042,
	CLCTL_GET_STORAGE_CONFIGURATION = 741,
	CLCTL_GET_STORAGE_CONFIG_ATTRIBUTES = 745,
	CLCTL_REMOVE_NODE = 4195054,
	CLCTL_IS_FEATURE_INSTALLED = 753,
	CLCTL_IS_S2D_FEATURE_SUPPORTED = 757,
	CLCTL_STORAGE_GET_PHYSICAL_DISK_INFO = 761,
	CLCTL_STORAGE_GET_CLUSBFLT_PATHS = 765,
	CLCTL_STORAGE_GET_CLUSBFLT_PATHINFO = 769,
	CLCTL_CLEAR_NODE_CONNECTION_INFO = 4195078,
	CLCTL_SET_DNS_DOMAIN = 4195082,
	CTCTL_GET_ROUTESTATUS_BASIC = 781,
	CTCTL_GET_ROUTESTATUS_EXTENDED = 785,
	CTCTL_GET_FAULT_DOMAIN_STATE = 789,
	CLCTL_NETNAME_SET_PWD_INFOEX = 794,
	CLCTL_STORAGE_GET_AVAILABLE_DISKS_EX2_INT = 8161,
	CLCTL_CLOUD_WITNESS_RESOURCE_TYPE_VALIDATE_CREDENTIALS = 8417,
	CLCTL_CLOUD_WITNESS_RESOURCE_UPDATE_TOKEN = 4202726,
	CLCTL_RESOURCE_PREPARE_UPGRADE = 4202730,
	CLCTL_RESOURCE_UPGRADE_COMPLETED = 4202734,
	CLCTL_CLOUD_WITNESS_RESOURCE_TYPE_VALIDATE_CREDENTIALS_WITH_KEY = 8433,
	CLCTL_CLOUD_WITNESS_RESOURCE_UPDATE_KEY = 4202742,
	CLCTL_REPLICATION_ADD_REPLICATION_GROUP = 8514,
	CLCTL_REPLICATION_GET_LOG_INFO = 8517,
	CLCTL_REPLICATION_GET_ELIGIBLE_LOGDISKS = 8521,
	CLCTL_REPLICATION_GET_ELIGIBLE_TARGET_DATADISKS = 8525,
	CLCTL_REPLICATION_GET_ELIGIBLE_SOURCE_DATADISKS = 8529,
	CLCTL_REPLICATION_GET_REPLICATED_DISKS = 8533,
	CLCTL_REPLICATION_GET_REPLICA_VOLUMES = 8537,
	CLCTL_REPLICATION_GET_LOG_VOLUME = 8541,
	CLCTL_REPLICATION_GET_RESOURCE_GROUP = 8545,
	CLCTL_REPLICATION_GET_REPLICATED_PARTITION_INFO = 8549,
	CLCTL_GET_STATE_CHANGE_TIME = 11613,
	CLCTL_SET_CLUSTER_S2D_ENABLED = 4205922,
	CLCTL_SET_CLUSTER_S2D_CACHE_METADATA_RESERVE_BYTES = 4205934,
	CLCTL_GROUPSET_GET_GROUPS = 11633,
	CLCTL_GROUPSET_GET_PROVIDER_GROUPS = 11637,
	CLCTL_GROUPSET_GET_PROVIDER_GROUPSETS = 11641,
	CLCTL_GROUP_GET_PROVIDER_GROUPS = 11645,
	CLCTL_GROUP_GET_PROVIDER_GROUPSETS = 11649,
	CLCTL_GROUP_SET_CCF_FROM_MASTER = 4205958,
	CLCTL_GET_INFRASTRUCTURE_SOFS_BUFFER = 11657,
	CLCTL_SET_INFRASTRUCTURE_SOFS_BUFFER = 4205966,
	CLCTL_NOTIFY_INFRASTRUCTURE_SOFS_CHANGED = 4205970,
	CLCTL_SCALEOUT_COMMAND = 4205974,
	CLCTL_SCALEOUT_CONTROL = 4205978,
	CLCTL_SCALEOUT_GET_CLUSTERS = 4205981,
	CLCTL_RELOAD_AUTOLOGGER_CONFIG = 11730,
	CLCTL_STORAGE_RENAME_SHARED_VOLUME = 11734,
	CLCTL_STORAGE_RENAME_SHARED_VOLUME_GUID = 11738,
	CLCTL_ENUM_AFFINITY_RULE_NAMES = 11741,
	CLCTL_GET_NODES_IN_FD = 11745,
	CLCTL_FORCE_DB_FLUSH = 4206054,
	CLCTL_DELETE = 5242886,
	CLCTL_INSTALL_NODE = 5242890,
	CLCTL_EVICT_NODE = 5242894,
	CLCTL_ADD_DEPENDENCY = 5242898,
	CLCTL_REMOVE_DEPENDENCY = 5242902,
	CLCTL_ADD_OWNER = 5242906,
	CLCTL_REMOVE_OWNER = 5242910,
	CLCTL_SET_NAME = 5242918,
	CLCTL_CLUSTER_NAME_CHANGED = 5242922,
	CLCTL_CLUSTER_VERSION_CHANGED = 5242926,
	CLCTL_FIXUP_ON_UPGRADE = 5242930,
	CLCTL_STARTING_PHASE1 = 5242934,
	CLCTL_STARTING_PHASE2 = 5242938,
	CLCTL_HOLD_IO = 5242942,
	CLCTL_RESUME_IO = 5242946,
	CLCTL_FORCE_QUORUM = 5242950,
	CLCTL_INITIALIZE = 5242954,
	CLCTL_STATE_CHANGE_REASON = 5242958,
	CLCTL_PROVIDER_STATE_CHANGE = 5242962,
	CLCTL_LEAVING_GROUP = 5242966,
	CLCTL_JOINING_GROUP = 5242970,
	CLCTL_FSWITNESS_GET_EPOCH_INFO = 1048669,
	CLCTL_FSWITNESS_SET_EPOCH_INFO = 5242978,
	CLCTL_FSWITNESS_RELEASE_LOCK = 5242982,
	CLCTL_NETNAME_CREDS_NOTIFYCAM = 5242986,
	CLCTL_NOTIFY_QUORUM_STATUS = 5243006,
	CLCTL_NOTIFY_MONITOR_SHUTTING_DOWN = 1048705,
	CLCTL_UNDELETE = 5243014,
	CLCTL_GET_OPERATION_CONTEXT = 1057001,
	CLCTL_NOTIFY_OWNER_CHANGE = 5251362,
	CLCTL_VALIDATE_CHANGE_GROUP = 1057061,
	CLCTL_CHECK_DRAIN_VETO = 1057069,
	CLCTL_NOTIFY_DRAIN_COMPLETE = 1057073,
}


[AllowDuplicates]
public enum CLUSCTL_RESOURCE_CODES : int32
{
	CLUSCTL_RESOURCE_UNKNOWN = 16777216,
	CLUSCTL_RESOURCE_GET_CHARACTERISTICS = 16777221,
	CLUSCTL_RESOURCE_GET_FLAGS = 16777225,
	CLUSCTL_RESOURCE_GET_CLASS_INFO = 16777229,
	CLUSCTL_RESOURCE_GET_REQUIRED_DEPENDENCIES = 16777233,
	CLUSCTL_RESOURCE_GET_NAME = 16777257,
	CLUSCTL_RESOURCE_GET_ID = 16777273,
	CLUSCTL_RESOURCE_GET_RESOURCE_TYPE = 16777261,
	CLUSCTL_RESOURCE_ENUM_COMMON_PROPERTIES = 16777297,
	CLUSCTL_RESOURCE_GET_RO_COMMON_PROPERTIES = 16777301,
	CLUSCTL_RESOURCE_GET_COMMON_PROPERTIES = 16777305,
	CLUSCTL_RESOURCE_SET_COMMON_PROPERTIES = 20971614,
	CLUSCTL_RESOURCE_VALIDATE_COMMON_PROPERTIES = 16777313,
	CLUSCTL_RESOURCE_GET_COMMON_PROPERTY_FMTS = 16777317,
	CLUSCTL_RESOURCE_ENUM_PRIVATE_PROPERTIES = 16777337,
	CLUSCTL_RESOURCE_GET_RO_PRIVATE_PROPERTIES = 16777341,
	CLUSCTL_RESOURCE_GET_PRIVATE_PROPERTIES = 16777345,
	CLUSCTL_RESOURCE_SET_PRIVATE_PROPERTIES = 20971654,
	CLUSCTL_RESOURCE_VALIDATE_PRIVATE_PROPERTIES = 16777353,
	CLUSCTL_RESOURCE_GET_PRIVATE_PROPERTY_FMTS = 16777357,
	CLUSCTL_RESOURCE_ADD_REGISTRY_CHECKPOINT = 20971682,
	CLUSCTL_RESOURCE_DELETE_REGISTRY_CHECKPOINT = 20971686,
	CLUSCTL_RESOURCE_GET_REGISTRY_CHECKPOINTS = 16777385,
	CLUSCTL_RESOURCE_ADD_CRYPTO_CHECKPOINT = 20971694,
	CLUSCTL_RESOURCE_DELETE_CRYPTO_CHECKPOINT = 20971698,
	CLUSCTL_RESOURCE_ADD_CRYPTO_CHECKPOINT_EX = 20972246,
	CLUSCTL_RESOURCE_GET_CRYPTO_CHECKPOINTS = 16777397,
	CLUSCTL_RESOURCE_GET_LOADBAL_PROCESS_LIST = 16777417,
	CLUSCTL_RESOURCE_GET_NETWORK_NAME = 16777577,
	CLUSCTL_RESOURCE_NETNAME_GET_VIRTUAL_SERVER_TOKEN = 16777581,
	CLUSCTL_RESOURCE_NETNAME_SET_PWD_INFO = 16777594,
	CLUSCTL_RESOURCE_NETNAME_SET_PWD_INFOEX = 16778010,
	CLUSCTL_RESOURCE_NETNAME_DELETE_CO = 16777598,
	CLUSCTL_RESOURCE_NETNAME_VALIDATE_VCO = 16777601,
	CLUSCTL_RESOURCE_NETNAME_RESET_VCO = 16777605,
	CLUSCTL_RESOURCE_NETNAME_REPAIR_VCO = 16777613,
	CLUSCTL_RESOURCE_NETNAME_REGISTER_DNS_RECORDS = 16777586,
	CLUSCTL_RESOURCE_GET_DNS_NAME = 16777589,
	CLUSCTL_RESOURCE_STORAGE_GET_DISK_INFO = 16777617,
	CLUSCTL_RESOURCE_STORAGE_GET_DISK_NUMBER_INFO = 16777633,
	CLUSCTL_RESOURCE_STORAGE_IS_PATH_VALID = 16777625,
	CLUSCTL_RESOURCE_QUERY_DELETE = 16777657,
	CLUSCTL_RESOURCE_UPGRADE_DLL = 20971706,
	CLUSCTL_RESOURCE_IPADDRESS_RENEW_LEASE = 20971966,
	CLUSCTL_RESOURCE_IPADDRESS_RELEASE_LEASE = 20971970,
	CLUSCTL_RESOURCE_ADD_REGISTRY_CHECKPOINT_64BIT = 20971710,
	CLUSCTL_RESOURCE_ADD_REGISTRY_CHECKPOINT_32BIT = 20971714,
	CLUSCTL_RESOURCE_QUERY_MAINTENANCE_MODE = 16777697,
	CLUSCTL_RESOURCE_SET_MAINTENANCE_MODE = 20972006,
	CLUSCTL_RESOURCE_STORAGE_SET_DRIVELETTER = 20972010,
	CLUSCTL_RESOURCE_STORAGE_GET_DISK_INFO_EX = 16777713,
	CLUSCTL_RESOURCE_STORAGE_GET_DISK_INFO_EX2 = 16777721,
	CLUSCTL_RESOURCE_STORAGE_GET_MOUNTPOINTS = 16777745,
	CLUSCTL_RESOURCE_STORAGE_GET_DIRTY = 16777753,
	CLUSCTL_RESOURCE_STORAGE_GET_SHARED_VOLUME_INFO = 16777765,
	CLUSCTL_RESOURCE_SET_CSV_MAINTENANCE_MODE = 20972182,
	CLUSCTL_RESOURCE_ENABLE_SHARED_VOLUME_DIRECTIO = 20972170,
	CLUSCTL_RESOURCE_DISABLE_SHARED_VOLUME_DIRECTIO = 20972174,
	CLUSCTL_RESOURCE_SET_SHARED_VOLUME_BACKUP_MODE = 20972186,
	CLUSCTL_RESOURCE_STORAGE_GET_SHARED_VOLUME_PARTITION_NAMES = 16777885,
	CLUSCTL_RESOURCE_GET_FAILURE_INFO = 16777241,
	CLUSCTL_RESOURCE_STORAGE_GET_DISKID = 16777733,
	CLUSCTL_RESOURCE_STORAGE_GET_SHARED_VOLUME_STATES = 20972194,
	CLUSCTL_RESOURCE_STORAGE_IS_SHARED_VOLUME = 16777893,
	CLUSCTL_RESOURCE_IS_QUORUM_BLOCKED = 16777905,
	CLUSCTL_RESOURCE_POOL_GET_DRIVE_INFO = 16777909,
	CLUSCTL_RESOURCE_RLUA_GET_VIRTUAL_SERVER_TOKEN = 16777581,
	CLUSCTL_RESOURCE_RLUA_SET_PWD_INFO = 16777594,
	CLUSCTL_RESOURCE_RLUA_SET_PWD_INFOEX = 16778010,
	CLUSCTL_RESOURCE_DELETE = 22020102,
	CLUSCTL_RESOURCE_UNDELETE = 22020230,
	CLUSCTL_RESOURCE_INSTALL_NODE = 22020106,
	CLUSCTL_RESOURCE_EVICT_NODE = 22020110,
	CLUSCTL_RESOURCE_ADD_DEPENDENCY = 22020114,
	CLUSCTL_RESOURCE_REMOVE_DEPENDENCY = 22020118,
	CLUSCTL_RESOURCE_ADD_OWNER = 22020122,
	CLUSCTL_RESOURCE_REMOVE_OWNER = 22020126,
	CLUSCTL_RESOURCE_SET_NAME = 22020134,
	CLUSCTL_RESOURCE_CLUSTER_NAME_CHANGED = 22020138,
	CLUSCTL_RESOURCE_CLUSTER_VERSION_CHANGED = 22020142,
	CLUSCTL_RESOURCE_FORCE_QUORUM = 22020166,
	CLUSCTL_RESOURCE_INITIALIZE = 22020170,
	CLUSCTL_RESOURCE_STATE_CHANGE_REASON = 22020174,
	CLUSCTL_RESOURCE_PROVIDER_STATE_CHANGE = 22020178,
	CLUSCTL_RESOURCE_LEAVING_GROUP = 22020182,
	CLUSCTL_RESOURCE_JOINING_GROUP = 22020186,
	CLUSCTL_RESOURCE_FSWITNESS_GET_EPOCH_INFO = 17825885,
	CLUSCTL_RESOURCE_FSWITNESS_SET_EPOCH_INFO = 22020194,
	CLUSCTL_RESOURCE_FSWITNESS_RELEASE_LOCK = 22020198,
	CLUSCTL_RESOURCE_NETNAME_CREDS_NOTIFYCAM = 22020202,
	CLUSCTL_RESOURCE_GET_OPERATION_CONTEXT = 17834217,
	CLUSCTL_RESOURCE_RW_MODIFY_NOOP = 20972206,
	CLUSCTL_RESOURCE_NOTIFY_QUORUM_STATUS = 22020222,
	CLUSCTL_RESOURCE_NOTIFY_OWNER_CHANGE = 22028578,
	CLUSCTL_RESOURCE_VALIDATE_CHANGE_GROUP = 17834277,
	CLUSCTL_RESOURCE_STORAGE_RENAME_SHARED_VOLUME = 16788950,
	CLUSCTL_RESOURCE_STORAGE_RENAME_SHARED_VOLUME_GUID = 16788954,
	CLUSCTL_CLOUD_WITNESS_RESOURCE_UPDATE_TOKEN = 20979942,
	CLUSCTL_CLOUD_WITNESS_RESOURCE_UPDATE_KEY = 20979958,
	CLUSCTL_RESOURCE_PREPARE_UPGRADE = 20979946,
	CLUSCTL_RESOURCE_UPGRADE_COMPLETED = 20979950,
	CLUSCTL_RESOURCE_GET_STATE_CHANGE_TIME = 16788829,
	CLUSCTL_RESOURCE_GET_INFRASTRUCTURE_SOFS_BUFFER = 16788873,
	CLUSCTL_RESOURCE_SET_INFRASTRUCTURE_SOFS_BUFFER = 20983182,
	CLUSCTL_RESOURCE_SCALEOUT_COMMAND = 20983190,
	CLUSCTL_RESOURCE_SCALEOUT_CONTROL = 20983194,
	CLUSCTL_RESOURCE_SCALEOUT_GET_CLUSTERS = 20983197,
	CLUSCTL_RESOURCE_CHECK_DRAIN_VETO = 17834285,
	CLUSCTL_RESOURCE_NOTIFY_DRAIN_COMPLETE = 17834289,
	CLUSCTL_RESOURCE_GET_NODES_IN_FD = 16788961,
}


[AllowDuplicates]
public enum CLUSCTL_RESOURCE_TYPE_CODES : int32
{
	CLUSCTL_RESOURCE_TYPE_UNKNOWN = 33554432,
	CLUSCTL_RESOURCE_TYPE_GET_CHARACTERISTICS = 33554437,
	CLUSCTL_RESOURCE_TYPE_GET_FLAGS = 33554441,
	CLUSCTL_RESOURCE_TYPE_GET_CLASS_INFO = 33554445,
	CLUSCTL_RESOURCE_TYPE_GET_REQUIRED_DEPENDENCIES = 33554449,
	CLUSCTL_RESOURCE_TYPE_GET_ARB_TIMEOUT = 33554453,
	CLUSCTL_RESOURCE_TYPE_ENUM_COMMON_PROPERTIES = 33554513,
	CLUSCTL_RESOURCE_TYPE_GET_RO_COMMON_PROPERTIES = 33554517,
	CLUSCTL_RESOURCE_TYPE_GET_COMMON_PROPERTIES = 33554521,
	CLUSCTL_RESOURCE_TYPE_VALIDATE_COMMON_PROPERTIES = 33554529,
	CLUSCTL_RESOURCE_TYPE_SET_COMMON_PROPERTIES = 37748830,
	CLUSCTL_RESOURCE_TYPE_GET_COMMON_PROPERTY_FMTS = 33554533,
	CLUSCTL_RESOURCE_TYPE_GET_COMMON_RESOURCE_PROPERTY_FMTS = 33554537,
	CLUSCTL_RESOURCE_TYPE_ENUM_PRIVATE_PROPERTIES = 33554553,
	CLUSCTL_RESOURCE_TYPE_GET_RO_PRIVATE_PROPERTIES = 33554557,
	CLUSCTL_RESOURCE_TYPE_GET_PRIVATE_PROPERTIES = 33554561,
	CLUSCTL_RESOURCE_TYPE_SET_PRIVATE_PROPERTIES = 37748870,
	CLUSCTL_RESOURCE_TYPE_VALIDATE_PRIVATE_PROPERTIES = 33554569,
	CLUSCTL_RESOURCE_TYPE_GET_PRIVATE_PROPERTY_FMTS = 33554573,
	CLUSCTL_RESOURCE_TYPE_GET_PRIVATE_RESOURCE_PROPERTY_FMTS = 33554577,
	CLUSCTL_RESOURCE_TYPE_GET_REGISTRY_CHECKPOINTS = 33554601,
	CLUSCTL_RESOURCE_TYPE_GET_CRYPTO_CHECKPOINTS = 33554613,
	CLUSCTL_RESOURCE_TYPE_STORAGE_GET_AVAILABLE_DISKS = 33554837,
	CLUSCTL_RESOURCE_TYPE_STORAGE_SYNC_CLUSDISK_DB = 37749150,
	CLUSCTL_RESOURCE_TYPE_NETNAME_VALIDATE_NETNAME = 33554997,
	CLUSCTL_RESOURCE_TYPE_NETNAME_GET_OU_FOR_VCO = 37749358,
	CLUSCTL_RESOURCE_TYPE_GEN_APP_VALIDATE_PATH = 33554993,
	CLUSCTL_RESOURCE_TYPE_GEN_APP_VALIDATE_DIRECTORY = 33555001,
	CLUSCTL_RESOURCE_TYPE_GEN_SCRIPT_VALIDATE_PATH = 33554993,
	CLUSCTL_RESOURCE_TYPE_QUERY_DELETE = 33554873,
	CLUSCTL_RESOURCE_TYPE_STORAGE_GET_DRIVELETTERS = 33554925,
	CLUSCTL_RESOURCE_TYPE_STORAGE_GET_AVAILABLE_DISKS_EX = 33554933,
	CLUSCTL_RESOURCE_TYPE_STORAGE_REMAP_DRIVELETTER = 33554945,
	CLUSCTL_RESOURCE_TYPE_STORAGE_GET_DISKID = 33554949,
	CLUSCTL_RESOURCE_TYPE_STORAGE_GET_RESOURCEID = 33554989,
	CLUSCTL_RESOURCE_TYPE_STORAGE_IS_CLUSTERABLE = 33554953,
	CLUSCTL_RESOURCE_TYPE_STORAGE_REMOVE_VM_OWNERSHIP = 37749262,
	CLUSCTL_RESOURCE_TYPE_STORAGE_IS_CSV_FILE = 16777769,
	CLUSCTL_RESOURCE_TYPE_WITNESS_VALIDATE_PATH = 33554993,
	CLUSCTL_RESOURCE_TYPE_INSTALL_NODE = 38797322,
	CLUSCTL_RESOURCE_TYPE_EVICT_NODE = 38797326,
	CLUSCTL_RESOURCE_TYPE_CLUSTER_VERSION_CHANGED = 38797358,
	CLUSCTL_RESOURCE_TYPE_FIXUP_ON_UPGRADE = 38797362,
	CLUSCTL_RESOURCE_TYPE_STARTING_PHASE1 = 38797366,
	CLUSCTL_RESOURCE_TYPE_STARTING_PHASE2 = 38797370,
	CLUSCTL_RESOURCE_TYPE_HOLD_IO = 38797374,
	CLUSCTL_RESOURCE_TYPE_RESUME_IO = 38797378,
	CLUSCTL_RESOURCE_TYPE_STORAGE_GET_AVAILABLE_DISKS_EX2_INT = 33562593,
	CLUSCTL_RESOURCE_TYPE_REPLICATION_GET_ELIGIBLE_LOGDISKS = 33562953,
	CLUSCTL_RESOURCE_TYPE_REPLICATION_GET_ELIGIBLE_TARGET_DATADISKS = 33562957,
	CLUSCTL_RESOURCE_TYPE_REPLICATION_GET_ELIGIBLE_SOURCE_DATADISKS = 33562961,
	CLUSCTL_RESOURCE_TYPE_REPLICATION_GET_REPLICATED_DISKS = 33562965,
	CLUSCTL_RESOURCE_TYPE_REPLICATION_GET_REPLICA_VOLUMES = 33562969,
	CLUSCTL_RESOURCE_TYPE_REPLICATION_GET_LOG_VOLUME = 33562973,
	CLUSCTL_RESOURCE_TYPE_REPLICATION_GET_RESOURCE_GROUP = 33562977,
	CLUSCTL_RESOURCE_TYPE_REPLICATION_GET_REPLICATED_PARTITION_INFO = 33562981,
	CLUSCTL_RESOURCE_TYPE_REPLICATION_GET_LOG_INFO = 33562949,
	CLUSCTL_RESOURCE_TYPE_REPLICATION_ADD_REPLICATION_GROUP = 33562946,
	CLUSCTL_CLOUD_WITNESS_RESOURCE_TYPE_VALIDATE_CREDENTIALS = 33562849,
	CLUSCTL_CLOUD_WITNESS_RESOURCE_TYPE_VALIDATE_CREDENTIALS_WITH_KEY = 33562865,
	CLUSCTL_RESOURCE_TYPE_PREPARE_UPGRADE = 37757162,
	CLUSCTL_RESOURCE_TYPE_UPGRADE_COMPLETED = 37757166,
	CLUSCTL_RESOURCE_TYPE_NOTIFY_MONITOR_SHUTTING_DOWN = 34603137,
	CLUSCTL_RESOURCE_TYPE_CHECK_DRAIN_VETO = 34611501,
	CLUSCTL_RESOURCE_TYPE_NOTIFY_DRAIN_COMPLETE = 34611505,
}


[AllowDuplicates]
public enum CLUSCTL_GROUP_CODES : int32
{
	CLUSCTL_GROUP_UNKNOWN = 50331648,
	CLUSCTL_GROUP_GET_CHARACTERISTICS = 50331653,
	CLUSCTL_GROUP_GET_FLAGS = 50331657,
	CLUSCTL_GROUP_GET_NAME = 50331689,
	CLUSCTL_GROUP_GET_ID = 50331705,
	CLUSCTL_GROUP_ENUM_COMMON_PROPERTIES = 50331729,
	CLUSCTL_GROUP_GET_RO_COMMON_PROPERTIES = 50331733,
	CLUSCTL_GROUP_GET_COMMON_PROPERTIES = 50331737,
	CLUSCTL_GROUP_SET_COMMON_PROPERTIES = 54526046,
	CLUSCTL_GROUP_VALIDATE_COMMON_PROPERTIES = 50331745,
	CLUSCTL_GROUP_ENUM_PRIVATE_PROPERTIES = 50331769,
	CLUSCTL_GROUP_GET_RO_PRIVATE_PROPERTIES = 50331773,
	CLUSCTL_GROUP_GET_PRIVATE_PROPERTIES = 50331777,
	CLUSCTL_GROUP_SET_PRIVATE_PROPERTIES = 54526086,
	CLUSCTL_GROUP_VALIDATE_PRIVATE_PROPERTIES = 50331785,
	CLUSCTL_GROUP_QUERY_DELETE = 50332089,
	CLUSCTL_GROUP_GET_COMMON_PROPERTY_FMTS = 50331749,
	CLUSCTL_GROUP_GET_PRIVATE_PROPERTY_FMTS = 50331789,
	CLUSCTL_GROUP_GET_FAILURE_INFO = 50331673,
	CLUSCTL_GROUP_GET_LAST_MOVE_TIME = 50332377,
	CLUSCTL_GROUP_SET_CCF_FROM_MASTER = 54537606,
}


[AllowDuplicates]
public enum CLUSCTL_NODE_CODES : int32
{
	CLUSCTL_NODE_UNKNOWN = 67108864,
	CLUSCTL_NODE_GET_CHARACTERISTICS = 67108869,
	CLUSCTL_NODE_GET_FLAGS = 67108873,
	CLUSCTL_NODE_GET_NAME = 67108905,
	CLUSCTL_NODE_GET_ID = 67108921,
	CLUSCTL_NODE_ENUM_COMMON_PROPERTIES = 67108945,
	CLUSCTL_NODE_GET_RO_COMMON_PROPERTIES = 67108949,
	CLUSCTL_NODE_GET_COMMON_PROPERTIES = 67108953,
	CLUSCTL_NODE_SET_COMMON_PROPERTIES = 71303262,
	CLUSCTL_NODE_VALIDATE_COMMON_PROPERTIES = 67108961,
	CLUSCTL_NODE_ENUM_PRIVATE_PROPERTIES = 67108985,
	CLUSCTL_NODE_GET_RO_PRIVATE_PROPERTIES = 67108989,
	CLUSCTL_NODE_GET_PRIVATE_PROPERTIES = 67108993,
	CLUSCTL_NODE_SET_PRIVATE_PROPERTIES = 71303302,
	CLUSCTL_NODE_VALIDATE_PRIVATE_PROPERTIES = 67109001,
	CLUSCTL_NODE_GET_COMMON_PROPERTY_FMTS = 67108965,
	CLUSCTL_NODE_GET_PRIVATE_PROPERTY_FMTS = 67109005,
	CLUSCTL_NODE_GET_CLUSTER_SERVICE_ACCOUNT_NAME = 67108929,
	CLUSCTL_NODE_GET_STUCK_NODES = 67109565,
	CLUSCTL_NODE_INJECT_GEM_FAULT = 67109569,
	CLUSCTL_NODE_INTRODUCE_GEM_REPAIR_DELAY = 67109573,
	CLUSCTL_NODE_SEND_DUMMY_GEM_MESSAGES = 67109577,
	CLUSCTL_NODE_BLOCK_GEM_SEND_RECV = 67109581,
	CLUSCTL_NODE_GET_GEMID_VECTOR = 67109585,
}


[AllowDuplicates]
public enum CLUSCTL_NETWORK_CODES : int32
{
	CLUSCTL_NETWORK_UNKNOWN = 83886080,
	CLUSCTL_NETWORK_GET_CHARACTERISTICS = 83886085,
	CLUSCTL_NETWORK_GET_FLAGS = 83886089,
	CLUSCTL_NETWORK_GET_NAME = 83886121,
	CLUSCTL_NETWORK_GET_ID = 83886137,
	CLUSCTL_NETWORK_ENUM_COMMON_PROPERTIES = 83886161,
	CLUSCTL_NETWORK_GET_RO_COMMON_PROPERTIES = 83886165,
	CLUSCTL_NETWORK_GET_COMMON_PROPERTIES = 83886169,
	CLUSCTL_NETWORK_SET_COMMON_PROPERTIES = 88080478,
	CLUSCTL_NETWORK_VALIDATE_COMMON_PROPERTIES = 83886177,
	CLUSCTL_NETWORK_ENUM_PRIVATE_PROPERTIES = 83886201,
	CLUSCTL_NETWORK_GET_RO_PRIVATE_PROPERTIES = 83886205,
	CLUSCTL_NETWORK_GET_PRIVATE_PROPERTIES = 83886209,
	CLUSCTL_NETWORK_SET_PRIVATE_PROPERTIES = 88080518,
	CLUSCTL_NETWORK_VALIDATE_PRIVATE_PROPERTIES = 83886217,
	CLUSCTL_NETWORK_GET_COMMON_PROPERTY_FMTS = 83886181,
	CLUSCTL_NETWORK_GET_PRIVATE_PROPERTY_FMTS = 83886221,
}


[AllowDuplicates]
public enum CLUSCTL_NETINTERFACE_CODES : int32
{
	CLUSCTL_NETINTERFACE_UNKNOWN = 100663296,
	CLUSCTL_NETINTERFACE_GET_CHARACTERISTICS = 100663301,
	CLUSCTL_NETINTERFACE_GET_FLAGS = 100663305,
	CLUSCTL_NETINTERFACE_GET_NAME = 100663337,
	CLUSCTL_NETINTERFACE_GET_ID = 100663353,
	CLUSCTL_NETINTERFACE_GET_NODE = 100663345,
	CLUSCTL_NETINTERFACE_GET_NETWORK = 100663349,
	CLUSCTL_NETINTERFACE_ENUM_COMMON_PROPERTIES = 100663377,
	CLUSCTL_NETINTERFACE_GET_RO_COMMON_PROPERTIES = 100663381,
	CLUSCTL_NETINTERFACE_GET_COMMON_PROPERTIES = 100663385,
	CLUSCTL_NETINTERFACE_SET_COMMON_PROPERTIES = 104857694,
	CLUSCTL_NETINTERFACE_VALIDATE_COMMON_PROPERTIES = 100663393,
	CLUSCTL_NETINTERFACE_ENUM_PRIVATE_PROPERTIES = 100663417,
	CLUSCTL_NETINTERFACE_GET_RO_PRIVATE_PROPERTIES = 100663421,
	CLUSCTL_NETINTERFACE_GET_PRIVATE_PROPERTIES = 100663425,
	CLUSCTL_NETINTERFACE_SET_PRIVATE_PROPERTIES = 104857734,
	CLUSCTL_NETINTERFACE_VALIDATE_PRIVATE_PROPERTIES = 100663433,
	CLUSCTL_NETINTERFACE_GET_COMMON_PROPERTY_FMTS = 100663397,
	CLUSCTL_NETINTERFACE_GET_PRIVATE_PROPERTY_FMTS = 100663437,
}


[AllowDuplicates]
public enum CLUSCTL_CLUSTER_CODES : int32
{
	CLUSCTL_CLUSTER_UNKNOWN = 117440512,
	CLUSCTL_CLUSTER_GET_FQDN = 117440573,
	CLUSCTL_CLUSTER_SET_STORAGE_CONFIGURATION = 121635554,
	CLUSCTL_CLUSTER_GET_STORAGE_CONFIGURATION = 117441253,
	CLUSCTL_CLUSTER_GET_STORAGE_CONFIG_ATTRIBUTES = 117441257,
	CLUSCTL_CLUSTER_ENUM_COMMON_PROPERTIES = 117440593,
	CLUSCTL_CLUSTER_GET_RO_COMMON_PROPERTIES = 117440597,
	CLUSCTL_CLUSTER_GET_COMMON_PROPERTIES = 117440601,
	CLUSCTL_CLUSTER_SET_COMMON_PROPERTIES = 121634910,
	CLUSCTL_CLUSTER_VALIDATE_COMMON_PROPERTIES = 117440609,
	CLUSCTL_CLUSTER_ENUM_PRIVATE_PROPERTIES = 117440633,
	CLUSCTL_CLUSTER_GET_RO_PRIVATE_PROPERTIES = 117440637,
	CLUSCTL_CLUSTER_GET_PRIVATE_PROPERTIES = 117440641,
	CLUSCTL_CLUSTER_SET_PRIVATE_PROPERTIES = 121634950,
	CLUSCTL_CLUSTER_VALIDATE_PRIVATE_PROPERTIES = 117440649,
	CLUSCTL_CLUSTER_GET_COMMON_PROPERTY_FMTS = 117440613,
	CLUSCTL_CLUSTER_GET_PRIVATE_PROPERTY_FMTS = 117440653,
	CLUSCTL_CLUSTER_CHECK_VOTER_EVICT = 117440581,
	CLUSCTL_CLUSTER_CHECK_VOTER_DOWN = 117440585,
	CLUSCTL_CLUSTER_SHUTDOWN = 117440589,
	CLUSCTL_CLUSTER_BATCH_BLOCK_KEY = 117441086,
	CLUSCTL_CLUSTER_BATCH_UNBLOCK_KEY = 117441089,
	CLUSCTL_CLUSTER_GET_SHARED_VOLUME_ID = 117441169,
	CLUSCTL_CLUSTER_GET_CLUSDB_TIMESTAMP = 117441193,
	CLUSCTL_CLUSTER_GET_GUM_LOCK_OWNER = 117441209,
	CLUSCTL_CLUSTER_REMOVE_NODE = 121635566,
	CLUSCTL_CLUSTER_SET_ACCOUNT_ACCESS = 121635058,
	CLUSCTL_CLUSTER_CLEAR_NODE_CONNECTION_INFO = 121635590,
	CLUSCTL_CLUSTER_SET_DNS_DOMAIN = 121635594,
	CLUSCTL_CLUSTER_SET_CLUSTER_S2D_ENABLED = 121646434,
	CLUSCTL_CLUSTER_SET_CLUSTER_S2D_CACHE_METADATA_RESERVE_BYTES = 121646446,
	CLUSCTL_CLUSTER_STORAGE_RENAME_SHARED_VOLUME = 117452246,
	CLUSCTL_CLUSTER_STORAGE_RENAME_SHARED_VOLUME_GUID = 117452250,
	CLUSCTL_CLUSTER_RELOAD_AUTOLOGGER_CONFIG = 117452242,
	CLUSCTL_CLUSTER_ENUM_AFFINITY_RULE_NAMES = 117452253,
	CLUSCTL_CLUSTER_GET_NODES_IN_FD = 117452257,
	CLUSCTL_CLUSTER_FORCE_FLUSH_DB = 121646566,
	CLUSCTL_CLUSTER_GET_CLMUSR_TOKEN = 117440877,
}


[AllowDuplicates]
public enum CLUSCTL_GROUPSET_CODES : int32
{
	CLUSCTL_GROUPSET_GET_COMMON_PROPERTIES = 134217817,
	CLUSCTL_GROUPSET_GET_RO_COMMON_PROPERTIES = 134217813,
	CLUSCTL_GROUPSET_SET_COMMON_PROPERTIES = 138412126,
	CLUSCTL_GROUPSET_GET_GROUPS = 134229361,
	CLUSCTL_GROUPSET_GET_PROVIDER_GROUPS = 134229365,
	CLUSCTL_GROUPSET_GET_PROVIDER_GROUPSETS = 134229369,
	CLUSCTL_GROUP_GET_PROVIDER_GROUPS = 134229373,
	CLUSCTL_GROUP_GET_PROVIDER_GROUPSETS = 134229377,
	CLUSCTL_GROUPSET_GET_ID = 134217785,
}


[AllowDuplicates]
public enum CLUSCTL_AFFINITYRULE_CODES : int32
{
	CLUSCTL_AFFINITYRULE_GET_COMMON_PROPERTIES = 150995033,
	CLUSCTL_AFFINITYRULE_GET_RO_COMMON_PROPERTIES = 150995029,
	CLUSCTL_AFFINITYRULE_SET_COMMON_PROPERTIES = 155189342,
	CLUSCTL_AFFINITYRULE_GET_ID = 150995001,
	CLUSCTL_AFFINITYRULE_GET_GROUPNAMES = 151006577,
}


[AllowDuplicates]
public enum CLUSTER_RESOURCE_CLASS : int32
{
	CLUS_RESCLASS_UNKNOWN = 0,
	CLUS_RESCLASS_STORAGE = 1,
	CLUS_RESCLASS_NETWORK = 2,
	CLUS_RESCLASS_USER = 32768,
}


[AllowDuplicates]
public enum CLUS_RESSUBCLASS : int32
{
	CLUS_RESSUBCLASS_SHARED = -2147483648,
}


[AllowDuplicates]
public enum CLUS_RESSUBCLASS_STORAGE : int32
{
	CLUS_RESSUBCLASS_STORAGE_SHARED_BUS = -2147483648,
	CLUS_RESSUBCLASS_STORAGE_DISK = 1073741824,
	CLUS_RESSUBCLASS_STORAGE_REPLICATION = 268435456,
}


[AllowDuplicates]
public enum CLUS_RESSUBCLASS_NETWORK : int32
{
	CLUS_RESSUBCLASS_NETWORK_INTERNET_PROTOCOL = -2147483648,
}


[AllowDuplicates]
public enum CLUS_CHARACTERISTICS : int32
{
	CLUS_CHAR_UNKNOWN = 0,
	CLUS_CHAR_QUORUM = 1,
	CLUS_CHAR_DELETE_REQUIRES_ALL_NODES = 2,
	CLUS_CHAR_LOCAL_QUORUM = 4,
	CLUS_CHAR_LOCAL_QUORUM_DEBUG = 8,
	CLUS_CHAR_REQUIRES_STATE_CHANGE_REASON = 16,
	CLUS_CHAR_BROADCAST_DELETE = 32,
	CLUS_CHAR_SINGLE_CLUSTER_INSTANCE = 64,
	CLUS_CHAR_SINGLE_GROUP_INSTANCE = 128,
	CLUS_CHAR_COEXIST_IN_SHARED_VOLUME_GROUP = 256,
	CLUS_CHAR_PLACEMENT_DATA = 512,
	CLUS_CHAR_MONITOR_DETACH = 1024,
	CLUS_CHAR_MONITOR_REATTACH = 2048,
	CLUS_CHAR_OPERATION_CONTEXT = 4096,
	CLUS_CHAR_CLONES = 8192,
	CLUS_CHAR_NOT_PREEMPTABLE = 16384,
	CLUS_CHAR_NOTIFY_NEW_OWNER = 32768,
	CLUS_CHAR_SUPPORTS_UNMONITORED_STATE = 65536,
	CLUS_CHAR_INFRASTRUCTURE = 131072,
	CLUS_CHAR_VETO_DRAIN = 262144,
	CLUS_CHAR_DRAIN_LOCAL_OFFLINE = 524288,
}


[AllowDuplicates]
public enum CLUS_FLAGS : int32
{
	CLUS_FLAG_CORE = 1,
}


[AllowDuplicates]
public enum CLUSPROP_PIFLAGS : int32
{
	CLUSPROP_PIFLAG_STICKY = 1,
	CLUSPROP_PIFLAG_REMOVABLE = 2,
	CLUSPROP_PIFLAG_USABLE = 4,
	CLUSPROP_PIFLAG_DEFAULT_QUORUM = 8,
	CLUSPROP_PIFLAG_USABLE_FOR_CSV = 16,
	CLUSPROP_PIFLAG_ENCRYPTION_ENABLED = 32,
	CLUSPROP_PIFLAG_RAW = 64,
	CLUSPROP_PIFLAG_UNKNOWN = -2147483648,
}


[AllowDuplicates]
public enum CLUSTER_CSV_VOLUME_FAULT_STATE : int32
{
	VolumeStateNoFaults = 0,
	VolumeStateNoDirectIO = 1,
	VolumeStateNoAccess = 2,
	VolumeStateInMaintenance = 4,
	VolumeStateDismounted = 8,
}


[AllowDuplicates]
public enum CLUSTER_SHARED_VOLUME_BACKUP_STATE : int32
{
	VolumeBackupNone = 0,
	VolumeBackupInProgress = 1,
}


[AllowDuplicates]
public enum CLUSTER_SHARED_VOLUME_STATE : int32
{
	SharedVolumeStateUnavailable = 0,
	SharedVolumeStatePaused = 1,
	SharedVolumeStateActive = 2,
	SharedVolumeStateActiveRedirected = 3,
	SharedVolumeStateActiveVolumeRedirected = 4,
}


[AllowDuplicates]
public enum CLUSTER_SHARED_VOLUME_RENAME_INPUT_TYPE : int32
{
	ClusterSharedVolumeRenameInputTypeNone = 0,
	ClusterSharedVolumeRenameInputTypeVolumeOffset = 1,
	ClusterSharedVolumeRenameInputTypeVolumeId = 2,
	ClusterSharedVolumeRenameInputTypeVolumeName = 3,
	ClusterSharedVolumeRenameInputTypeVolumeGuid = 4,
}


[AllowDuplicates]
public enum MAINTENANCE_MODE_TYPE_ENUM : int32
{
	MaintenanceModeTypeDisableIsAliveCheck = 1,
	MaintenanceModeTypeOfflineResource = 2,
	MaintenanceModeTypeUnclusterResource = 3,
}


[AllowDuplicates]
public enum CLUSPROP_IPADDR_ENABLENETBIOS : int32
{
	CLUSPROP_IPADDR_ENABLENETBIOS_DISABLED = 0,
	CLUSPROP_IPADDR_ENABLENETBIOS_ENABLED = 1,
	CLUSPROP_IPADDR_ENABLENETBIOS_TRACK_NIC = 2,
}


[AllowDuplicates]
public enum FILESHARE_CHANGE_ENUM : int32
{
	FILESHARE_CHANGE_NONE = 0,
	FILESHARE_CHANGE_ADD = 1,
	FILESHARE_CHANGE_DEL = 2,
	FILESHARE_CHANGE_MODIFY = 3,
}


[AllowDuplicates]
public enum CLUSTER_RESOURCE_ENUM : int32
{
	CLUSTER_RESOURCE_ENUM_DEPENDS = 1,
	CLUSTER_RESOURCE_ENUM_PROVIDES = 2,
	CLUSTER_RESOURCE_ENUM_NODES = 4,
	CLUSTER_RESOURCE_ENUM_ALL = 7,
}


[AllowDuplicates]
public enum CLUSTER_RESOURCE_TYPE_ENUM : int32
{
	CLUSTER_RESOURCE_TYPE_ENUM_NODES = 1,
	CLUSTER_RESOURCE_TYPE_ENUM_RESOURCES = 2,
	CLUSTER_RESOURCE_TYPE_ENUM_ALL = 3,
}


[AllowDuplicates]
public enum CLUSTER_NETWORK_ENUM : int32
{
	CLUSTER_NETWORK_ENUM_NETINTERFACES = 1,
	CLUSTER_NETWORK_ENUM_ALL = 1,
}


[AllowDuplicates]
public enum CLUSTER_NETWORK_STATE : int32
{
	ClusterNetworkStateUnknown = -1,
	ClusterNetworkUnavailable = 0,
	ClusterNetworkDown = 1,
	ClusterNetworkPartitioned = 2,
	ClusterNetworkUp = 3,
}


[AllowDuplicates]
public enum CLUSTER_NETWORK_ROLE : int32
{
	ClusterNetworkRoleNone = 0,
	ClusterNetworkRoleInternalUse = 1,
	ClusterNetworkRoleClientAccess = 2,
	ClusterNetworkRoleInternalAndClient = 3,
}


[AllowDuplicates]
public enum CLUSTER_NETINTERFACE_STATE : int32
{
	ClusterNetInterfaceStateUnknown = -1,
	ClusterNetInterfaceUnavailable = 0,
	ClusterNetInterfaceFailed = 1,
	ClusterNetInterfaceUnreachable = 2,
	ClusterNetInterfaceUp = 3,
}


[AllowDuplicates]
public enum CLUSTER_SETUP_PHASE : int32
{
	ClusterSetupPhaseInitialize = 1,
	ClusterSetupPhaseValidateNodeState = 100,
	ClusterSetupPhaseValidateNetft = 102,
	ClusterSetupPhaseValidateClusDisk = 103,
	ClusterSetupPhaseConfigureClusSvc = 104,
	ClusterSetupPhaseStartingClusSvc = 105,
	ClusterSetupPhaseQueryClusterNameAccount = 106,
	ClusterSetupPhaseValidateClusterNameAccount = 107,
	ClusterSetupPhaseCreateClusterAccount = 108,
	ClusterSetupPhaseConfigureClusterAccount = 109,
	ClusterSetupPhaseFormingCluster = 200,
	ClusterSetupPhaseAddClusterProperties = 201,
	ClusterSetupPhaseCreateResourceTypes = 202,
	ClusterSetupPhaseCreateGroups = 203,
	ClusterSetupPhaseCreateIPAddressResources = 204,
	ClusterSetupPhaseCreateNetworkName = 205,
	ClusterSetupPhaseClusterGroupOnline = 206,
	ClusterSetupPhaseGettingCurrentMembership = 300,
	ClusterSetupPhaseAddNodeToCluster = 301,
	ClusterSetupPhaseNodeUp = 302,
	ClusterSetupPhaseMoveGroup = 400,
	ClusterSetupPhaseDeleteGroup = 401,
	ClusterSetupPhaseCleanupCOs = 402,
	ClusterSetupPhaseOfflineGroup = 403,
	ClusterSetupPhaseEvictNode = 404,
	ClusterSetupPhaseCleanupNode = 405,
	ClusterSetupPhaseCoreGroupCleanup = 406,
	ClusterSetupPhaseFailureCleanup = 999,
}


[AllowDuplicates]
public enum CLUSTER_SETUP_PHASE_TYPE : int32
{
	ClusterSetupPhaseStart = 1,
	ClusterSetupPhaseContinue = 2,
	ClusterSetupPhaseEnd = 3,
	ClusterSetupPhaseReport = 4,
}


[AllowDuplicates]
public enum CLUSTER_SETUP_PHASE_SEVERITY : int32
{
	ClusterSetupPhaseInformational = 1,
	ClusterSetupPhaseWarning = 2,
	ClusterSetupPhaseFatal = 3,
}


[AllowDuplicates]
public enum PLACEMENT_OPTIONS : int32
{
	PLACEMENT_OPTIONS_MIN_VALUE = 0,
	PLACEMENT_OPTIONS_DEFAULT_PLACEMENT_OPTIONS = 0,
	PLACEMENT_OPTIONS_DISABLE_CSV_VM_DEPENDENCY = 1,
	PLACEMENT_OPTIONS_CONSIDER_OFFLINE_VMS = 2,
	PLACEMENT_OPTIONS_DONT_USE_MEMORY = 4,
	PLACEMENT_OPTIONS_DONT_USE_CPU = 8,
	PLACEMENT_OPTIONS_DONT_USE_LOCAL_TEMP_DISK = 16,
	PLACEMENT_OPTIONS_DONT_RESUME_VMS_WITH_EXISTING_TEMP_DISK = 32,
	PLACEMENT_OPTIONS_SAVE_VMS_WITH_LOCAL_DISK_ON_DRAIN_OVERWRITE = 64,
	PLACEMENT_OPTIONS_DONT_RESUME_AVAILABILTY_SET_VMS_WITH_EXISTING_TEMP_DISK = 128,
	PLACEMENT_OPTIONS_SAVE_AVAILABILTY_SET_VMS_WITH_LOCAL_DISK_ON_DRAIN_OVERWRITE = 256,
	PLACEMENT_OPTIONS_AVAILABILITY_SET_DOMAIN_AFFINITY = 512,
	PLACEMENT_OPTIONS_ALL = 1023,
}


[AllowDuplicates]
public enum GRP_PLACEMENT_OPTIONS : int32
{
	GRP_PLACEMENT_OPTIONS_MIN_VALUE = 0,
	GRP_PLACEMENT_OPTIONS_DEFAULT = 0,
	GRP_PLACEMENT_OPTIONS_DISABLE_AUTOBALANCING = 1,
	GRP_PLACEMENT_OPTIONS_ALL = 1,
}


[AllowDuplicates]
public enum SR_REPLICATED_DISK_TYPE : int32
{
	SrReplicatedDiskTypeNone = 0,
	SrReplicatedDiskTypeSource = 1,
	SrReplicatedDiskTypeLogSource = 2,
	SrReplicatedDiskTypeDestination = 3,
	SrReplicatedDiskTypeLogDestination = 4,
	SrReplicatedDiskTypeNotInParthership = 5,
	SrReplicatedDiskTypeLogNotInParthership = 6,
	SrReplicatedDiskTypeOther = 7,
}


[AllowDuplicates]
public enum SR_DISK_REPLICATION_ELIGIBLE : int32
{
	SrDiskReplicationEligibleNone = 0,
	SrDiskReplicationEligibleYes = 1,
	SrDiskReplicationEligibleOffline = 2,
	SrDiskReplicationEligibleNotGpt = 3,
	SrDiskReplicationEligiblePartitionLayoutMismatch = 4,
	SrDiskReplicationEligibleInsufficientFreeSpace = 5,
	SrDiskReplicationEligibleNotInSameSite = 6,
	SrDiskReplicationEligibleInSameSite = 7,
	SrDiskReplicationEligibleFileSystemNotSupported = 8,
	SrDiskReplicationEligibleAlreadyInReplication = 9,
	SrDiskReplicationEligibleSameAsSpecifiedDisk = 10,
	SrDiskReplicationEligibleOther = 9999,
}


[AllowDuplicates]
public enum VM_RESDLL_CONTEXT : int32
{
	VmResdllContextTurnOff = 0,
	VmResdllContextSave = 1,
	VmResdllContextShutdown = 2,
	VmResdllContextShutdownForce = 3,
	VmResdllContextLiveMigration = 4,
}


[AllowDuplicates]
public enum RESDLL_CONTEXT_OPERATION_TYPE : int32
{
	ResdllContextOperationTypeFailback = 0,
	ResdllContextOperationTypeDrain = 1,
	ResdllContextOperationTypeDrainFailure = 2,
	ResdllContextOperationTypeEmbeddedFailure = 3,
	ResdllContextOperationTypePreemption = 4,
	ResdllContextOperationTypeNetworkDisconnect = 5,
	ResdllContextOperationTypeNetworkDisconnectMoveRetry = 6,
}


[AllowDuplicates]
public enum LOG_LEVEL : int32
{
	LOG_INFORMATION = 0,
	LOG_WARNING = 1,
	LOG_ERROR = 2,
	LOG_SEVERE = 3,
}


[AllowDuplicates]
public enum RESOURCE_EXIT_STATE : int32
{
	ResourceExitStateContinue = 0,
	ResourceExitStateTerminate = 1,
	ResourceExitStateMax = 2,
}


[AllowDuplicates]
public enum FAILURE_TYPE : int32
{
	FAILURE_TYPE_GENERAL = 0,
	FAILURE_TYPE_EMBEDDED = 1,
	FAILURE_TYPE_NETWORK_LOSS = 2,
}


[AllowDuplicates]
public enum CLUSTER_RESOURCE_APPLICATION_STATE : int32
{
	ClusterResourceApplicationStateUnknown = 1,
	ClusterResourceApplicationOSHeartBeat = 2,
	ClusterResourceApplicationReady = 3,
}


[AllowDuplicates]
public enum RESOURCE_MONITOR_STATE : int32
{
	RmonInitializing = 0,
	RmonIdle = 1,
	RmonStartingResource = 2,
	RmonInitializingResource = 3,
	RmonOnlineResource = 4,
	RmonOfflineResource = 5,
	RmonShutdownResource = 6,
	RmonDeletingResource = 7,
	RmonIsAlivePoll = 8,
	RmonLooksAlivePoll = 9,
	RmonArbitrateResource = 10,
	RmonReleaseResource = 11,
	RmonResourceControl = 12,
	RmonResourceTypeControl = 13,
	RmonTerminateResource = 14,
	RmonDeadlocked = 15,
}


[AllowDuplicates]
public enum CLUSTER_ROLE : int32
{
	ClusterRoleDHCP = 0,
	ClusterRoleDTC = 1,
	ClusterRoleFileServer = 2,
	ClusterRoleGenericApplication = 3,
	ClusterRoleGenericScript = 4,
	ClusterRoleGenericService = 5,
	ClusterRoleISCSINameServer = 6,
	ClusterRoleMSMQ = 7,
	ClusterRoleNFS = 8,
	ClusterRolePrintServer = 9,
	ClusterRoleStandAloneNamespaceServer = 10,
	ClusterRoleVolumeShadowCopyServiceTask = 11,
	ClusterRoleWINS = 12,
	ClusterRoleTaskScheduler = 13,
	ClusterRoleNetworkFileSystem = 14,
	ClusterRoleDFSReplicatedFolder = 15,
	ClusterRoleDistributedFileSystem = 16,
	ClusterRoleDistributedNetworkName = 17,
	ClusterRoleFileShare = 18,
	ClusterRoleFileShareWitness = 19,
	ClusterRoleHardDisk = 20,
	ClusterRoleIPAddress = 21,
	ClusterRoleIPV6Address = 22,
	ClusterRoleIPV6TunnelAddress = 23,
	ClusterRoleISCSITargetServer = 24,
	ClusterRoleNetworkName = 25,
	ClusterRolePhysicalDisk = 26,
	ClusterRoleSODAFileServer = 27,
	ClusterRoleStoragePool = 28,
	ClusterRoleVirtualMachine = 29,
	ClusterRoleVirtualMachineConfiguration = 30,
	ClusterRoleVirtualMachineReplicaBroker = 31,
}


[AllowDuplicates]
public enum CLUSTER_ROLE_STATE : int32
{
	ClusterRoleUnknown = -1,
	ClusterRoleClustered = 0,
	ClusterRoleUnclustered = 1,
}


[AllowDuplicates]
public enum CLUADMEX_OBJECT_TYPE : int32
{
	CLUADMEX_OT_NONE = 0,
	CLUADMEX_OT_CLUSTER = 1,
	CLUADMEX_OT_NODE = 2,
	CLUADMEX_OT_GROUP = 3,
	CLUADMEX_OT_RESOURCE = 4,
	CLUADMEX_OT_RESOURCETYPE = 5,
	CLUADMEX_OT_NETWORK = 6,
	CLUADMEX_OT_NETINTERFACE = 7,
}

#endregion

#region Function Pointers
public function uint32 PCLUSAPI_GET_NODE_CLUSTER_STATE(PWSTR lpszNodeName, uint32* pdwClusterState);

public function _HCLUSTER* PCLUSAPI_OPEN_CLUSTER(PWSTR lpszClusterName);

public function _HCLUSTER* PCLUSAPI_OPEN_CLUSTER_EX(PWSTR lpszClusterName, uint32 dwDesiredAccess, uint32* lpdwGrantedAccess);

public function BOOL PCLUSAPI_CLOSE_CLUSTER(_HCLUSTER* hCluster);

public function uint32 PCLUSAPI_SetClusterName(_HCLUSTER* hCluster, PWSTR lpszNewClusterName);

public function uint32 PCLUSAPI_GET_CLUSTER_INFORMATION(_HCLUSTER* hCluster, char16* lpszClusterName, uint32* lpcchClusterName, CLUSTERVERSIONINFO* lpClusterInfo);

public function uint32 PCLUSAPI_GET_CLUSTER_QUORUM_RESOURCE(_HCLUSTER* hCluster, char16* lpszResourceName, uint32* lpcchResourceName, char16* lpszDeviceName, uint32* lpcchDeviceName, uint32* lpdwMaxQuorumLogSize);

public function uint32 PCLUSAPI_SET_CLUSTER_QUORUM_RESOURCE(_HRESOURCE* hResource, PWSTR lpszDeviceName, uint32 dwMaxQuoLogSize);

public function uint32 PCLUSAPI_BACKUP_CLUSTER_DATABASE(_HCLUSTER* hCluster, PWSTR lpszPathName);

public function uint32 PCLUSAPI_RESTORE_CLUSTER_DATABASE(PWSTR lpszPathName, BOOL bForce, PWSTR lpszQuorumDriveLetter);

public function uint32 PCLUSAPI_SET_CLUSTER_NETWORK_PRIORITY_ORDER(_HCLUSTER* hCluster, uint32 NetworkCount, _HNETWORK** NetworkList);

public function uint32 PCLUSAPI_SET_CLUSTER_SERVICE_ACCOUNT_PASSWORD(PWSTR lpszClusterName, PWSTR lpszNewPassword, uint32 dwFlags, CLUSTER_SET_PASSWORD_STATUS* lpReturnStatusBuffer, uint32* lpcbReturnStatusBufferSize);

public function uint32 PCLUSAPI_CLUSTER_CONTROL(_HCLUSTER* hCluster, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned);

public function BOOL PCLUSTER_UPGRADE_PROGRESS_CALLBACK(void* pvCallbackArg, CLUSTER_UPGRADE_PHASE eUpgradePhase);

public function uint32 PCLUSAPI_CLUSTER_UPGRADE(_HCLUSTER* hCluster, BOOL perform, PCLUSTER_UPGRADE_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg);

public function _HCHANGE* PCLUSAPI_CREATE_CLUSTER_NOTIFY_PORT_V2(_HCHANGE* hChange, _HCLUSTER* hCluster, NOTIFY_FILTER_AND_TYPE* Filters, uint32 dwFilterCount, uint dwNotifyKey);

public function uint32 PCLUSAPI_REGISTER_CLUSTER_NOTIFY_V2(_HCHANGE* hChange, NOTIFY_FILTER_AND_TYPE Filter, HANDLE hObject, uint dwNotifyKey);

public function uint32 PCLUSAPI_GET_NOTIFY_EVENT_HANDLE_V2(_HCHANGE* hChange, HANDLE* lphTargetEvent);

public function uint32 PCLUSAPI_GET_CLUSTER_NOTIFY_V2(_HCHANGE* hChange, uint* lpdwNotifyKey, NOTIFY_FILTER_AND_TYPE* pFilterAndType, uint8* buffer, uint32* lpcchBufferSize, PWSTR lpszObjectId, uint32* lpcchObjectId, PWSTR lpszParentId, uint32* lpcchParentId, PWSTR lpszName, uint32* lpcchName, PWSTR lpszType, uint32* lpcchType, uint32 dwMilliseconds);

public function _HCHANGE* PCLUSAPI_CREATE_CLUSTER_NOTIFY_PORT(_HCHANGE* hChange, _HCLUSTER* hCluster, uint32 dwFilter, uint dwNotifyKey);

public function uint32 PCLUSAPI_REGISTER_CLUSTER_NOTIFY(_HCHANGE* hChange, uint32 dwFilterType, HANDLE hObject, uint dwNotifyKey);

public function uint32 PCLUSAPI_GET_CLUSTER_NOTIFY(_HCHANGE* hChange, uint* lpdwNotifyKey, uint32* lpdwFilterType, char16* lpszName, uint32* lpcchName, uint32 dwMilliseconds);

public function BOOL PCLUSAPI_CLOSE_CLUSTER_NOTIFY_PORT(_HCHANGE* hChange);

public function _HCLUSENUM* PCLUSAPI_CLUSTER_OPEN_ENUM(_HCLUSTER* hCluster, uint32 dwType);

public function uint32 PCLUSAPI_CLUSTER_GET_ENUM_COUNT(_HCLUSENUM* hEnum);

public function uint32 PCLUSAPI_CLUSTER_ENUM(_HCLUSENUM* hEnum, uint32 dwIndex, uint32* lpdwType, char16* lpszName, uint32* lpcchName);

public function uint32 PCLUSAPI_CLUSTER_CLOSE_ENUM(_HCLUSENUM* hEnum);

public function _HCLUSENUMEX* PCLUSAPI_CLUSTER_OPEN_ENUM_EX(_HCLUSTER* hCluster, uint32 dwType, void* pOptions);

public function uint32 PCLUSAPI_CLUSTER_GET_ENUM_COUNT_EX(_HCLUSENUMEX* hClusterEnum);

public function uint32 PCLUSAPI_CLUSTER_ENUM_EX(_HCLUSENUMEX* hClusterEnum, uint32 dwIndex, CLUSTER_ENUM_ITEM* pItem, uint32* cbItem);

public function uint32 PCLUSAPI_CLUSTER_CLOSE_ENUM_EX(_HCLUSENUMEX* hClusterEnum);

public function _HGROUPSET* PCLUSAPI_CREATE_CLUSTER_GROUP_GROUPSET(_HCLUSTER* hCluster, PWSTR lpszGroupSetName);

public function _HGROUPSET* PCLUSAPI_OPEN_CLUSTER_GROUP_GROUPSET(_HCLUSTER* hCluster, PWSTR lpszGroupSetName);

public function BOOL PCLUSAPI_CLOSE_CLUSTER_GROUP_GROUPSET(_HGROUPSET* hGroupSet);

public function uint32 PCLUSAPI_DELETE_CLUSTER_GROUP_GROUPSET(_HGROUPSET* hGroupSet);

public function uint32 PCLUSAPI_CLUSTER_ADD_GROUP_TO_GROUP_GROUPSET(_HGROUPSET* hGroupSet, _HGROUP* hGroup);

public function uint32 PCLUSAPI_CLUSTER_REMOVE_GROUP_FROM_GROUP_GROUPSET(_HGROUPSET* hGroupSet, _HGROUP* hGroupName);

public function uint32 PCLUSAPI_CLUSTER_GROUP_GROUPSET_CONTROL(_HGROUPSET* hGroupSet, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 cbInBufferSize, void* lpOutBuffer, uint32 cbOutBufferSize, uint32* lpBytesReturned);

public function uint32 PCLUSAPI_ADD_CLUSTER_GROUP_DEPENDENCY(_HGROUP* hDependentGroup, _HGROUP* hProviderGroup);

public function uint32 PCLUSAPI_SET_GROUP_DEPENDENCY_EXPRESSION(_HGROUP* hGroupSet, PWSTR lpszDependencyExpression);

public function uint32 PCLUSAPI_REMOVE_CLUSTER_GROUP_DEPENDENCY(_HGROUP* hGroup, _HGROUP* hDependsOn);

public function uint32 PCLUSAPI_ADD_CLUSTER_GROUP_GROUPSET_DEPENDENCY(_HGROUPSET* hDependentGroupSet, _HGROUPSET* hProviderGroupSet);

public function uint32 PCLUSAPI_SET_CLUSTER_GROUP_GROUPSET_DEPENDENCY_EXPRESSION(_HGROUPSET* hGroupSet, PWSTR lpszDependencyExpression);

public function uint32 PCLUSAPI_REMOVE_CLUSTER_GROUP_GROUPSET_DEPENDENCY(_HGROUPSET* hGroupSet, _HGROUPSET* hDependsOn);

public function uint32 PCLUSAPI_ADD_CLUSTER_GROUP_TO_GROUP_GROUPSET_DEPENDENCY(_HGROUP* hDependentGroup, _HGROUPSET* hProviderGroupSet);

public function uint32 PCLUSAPI_REMOVE_CLUSTER_GROUP_TO_GROUP_GROUPSET_DEPENDENCY(_HGROUP* hGroup, _HGROUPSET* hDependsOn);

public function _HCLUSTER* PCLUSAPI_GET_CLUSTER_FROM_GROUP_GROUPSET(_HGROUPSET* hGroupSet);

public function uint32 PCLUSAPI_ADD_CROSS_CLUSTER_GROUPSET_DEPENDENCY(_HGROUPSET* hDependentGroupSet, PWSTR lpRemoteClusterName, PWSTR lpRemoteGroupSetName);

public function uint32 PCLUSAPI_REMOVE_CROSS_CLUSTER_GROUPSET_DEPENDENCY(_HGROUPSET* hDependentGroupSet, PWSTR lpRemoteClusterName, PWSTR lpRemoteGroupSetName);

public function _HGROUPSET* PCLUSAPI_CREATE_CLUSTER_AVAILABILITY_SET(_HCLUSTER* hCluster, PWSTR lpAvailabilitySetName, CLUSTER_AVAILABILITY_SET_CONFIG* pAvailabilitySetConfig);

public function uint32 PCLUSAPI_CLUSTER_CREATE_AFFINITY_RULE(_HCLUSTER* hCluster, PWSTR ruleName, CLUS_AFFINITY_RULE_TYPE ruleType);

public function uint32 PCLUSAPI_CLUSTER_REMOVE_AFFINITY_RULE(_HCLUSTER* hCluster, PWSTR ruleName);

public function uint32 PCLUSAPI_CLUSTER_ADD_GROUP_TO_AFFINITY_RULE(_HCLUSTER* hCluster, PWSTR ruleName, _HGROUP* hGroup);

public function uint32 PCLUSAPI_CLUSTER_REMOVE_GROUP_FROM_AFFINITY_RULE(_HCLUSTER* hCluster, PWSTR ruleName, _HGROUP* hGroup);

public function uint32 PCLUSAPI_CLUSTER_AFFINITY_RULE_CONTROL(_HCLUSTER* hCluster, PWSTR affinityRuleName, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 cbInBufferSize, void* lpOutBuffer, uint32 cbOutBufferSize, uint32* lpBytesReturned);

public function _HNODE* PCLUSAPI_OPEN_CLUSTER_NODE(_HCLUSTER* hCluster, PWSTR lpszNodeName);

public function _HNODE* PCLUSAPI_OPEN_CLUSTER_NODE_EX(_HCLUSTER* hCluster, PWSTR lpszNodeName, uint32 dwDesiredAccess, uint32* lpdwGrantedAccess);

public function _HNODE* PCLUSAPI_OPEN_NODE_BY_ID(_HCLUSTER* hCluster, uint32 nodeId);

public function BOOL PCLUSAPI_CLOSE_CLUSTER_NODE(_HNODE* hNode);

public function CLUSTER_NODE_STATE PCLUSAPI_GET_CLUSTER_NODE_STATE(_HNODE* hNode);

public function uint32 PCLUSAPI_GET_CLUSTER_NODE_ID(_HNODE* hNode, char16* lpszNodeId, uint32* lpcchName);

public function _HCLUSTER* PCLUSAPI_GET_CLUSTER_FROM_NODE(_HNODE* hNode);

public function uint32 PCLUSAPI_PAUSE_CLUSTER_NODE(_HNODE* hNode);

public function uint32 PCLUSAPI_RESUME_CLUSTER_NODE(_HNODE* hNode);

public function uint32 PCLUSAPI_EVICT_CLUSTER_NODE(_HNODE* hNode);

public function _HNODEENUM* PCLUSAPI_CLUSTER_NODE_OPEN_ENUM(_HNODE* hNode, uint32 dwType);

public function _HNODEENUMEX* PCLUSAPI_CLUSTER_NODE_OPEN_ENUM_EX(_HNODE* hNode, uint32 dwType, void* pOptions);

public function uint32 PCLUSAPI_CLUSTER_NODE_GET_ENUM_COUNT_EX(_HNODEENUMEX* hNodeEnum);

public function uint32 PCLUSAPI_CLUSTER_NODE_ENUM_EX(_HNODEENUMEX* hNodeEnum, uint32 dwIndex, CLUSTER_ENUM_ITEM* pItem, uint32* cbItem);

public function uint32 PCLUSAPI_CLUSTER_NODE_CLOSE_ENUM_EX(_HNODEENUMEX* hNodeEnum);

public function uint32 PCLUSAPI_CLUSTER_NODE_GET_ENUM_COUNT(_HNODEENUM* hNodeEnum);

public function uint32 PCLUSAPI_CLUSTER_NODE_CLOSE_ENUM(_HNODEENUM* hNodeEnum);

public function uint32 PCLUSAPI_CLUSTER_NODE_ENUM(_HNODEENUM* hNodeEnum, uint32 dwIndex, uint32* lpdwType, char16* lpszName, uint32* lpcchName);

public function uint32 PCLUSAPI_EVICT_CLUSTER_NODE_EX(_HNODE* hNode, uint32 dwTimeOut, HRESULT* phrCleanupStatus);

public function HKEY PCLUSAPI_GET_CLUSTER_RESOURCE_TYPE_KEY(_HCLUSTER* hCluster, PWSTR lpszTypeName, uint32 samDesired);

public function _HGROUP* PCLUSAPI_CREATE_CLUSTER_GROUP(_HCLUSTER* hCluster, PWSTR lpszGroupName);

public function _HGROUP* PCLUSAPI_OPEN_CLUSTER_GROUP(_HCLUSTER* hCluster, PWSTR lpszGroupName);

public function _HGROUP* PCLUSAPI_OPEN_CLUSTER_GROUP_EX(_HCLUSTER* hCluster, PWSTR lpszGroupName, uint32 dwDesiredAccess, uint32* lpdwGrantedAccess);

public function uint32 PCLUSAPI_PAUSE_CLUSTER_NODE_EX(_HNODE* hNode, BOOL bDrainNode, uint32 dwPauseFlags, _HNODE* hNodeDrainTarget);

public function uint32 PCLUSAPI_RESUME_CLUSTER_NODE_EX(_HNODE* hNode, CLUSTER_NODE_RESUME_FAILBACK_TYPE eResumeFailbackType, uint32 dwResumeFlagsReserved);

public function _HGROUP* PCLUSAPI_CREATE_CLUSTER_GROUPEX(_HCLUSTER* hCluster, PWSTR lpszGroupName, CLUSTER_CREATE_GROUP_INFO* pGroupInfo);

public function _HGROUPENUMEX* PCLUSAPI_CLUSTER_GROUP_OPEN_ENUM_EX(_HCLUSTER* hCluster, PWSTR lpszProperties, uint32 cbProperties, PWSTR lpszRoProperties, uint32 cbRoProperties, uint32 dwFlags);

public function uint32 PCLUSAPI_CLUSTER_GROUP_GET_ENUM_COUNT_EX(_HGROUPENUMEX* hGroupEnumEx);

public function uint32 PCLUSAPI_CLUSTER_GROUP_ENUM_EX(_HGROUPENUMEX* hGroupEnumEx, uint32 dwIndex, CLUSTER_GROUP_ENUM_ITEM* pItem, uint32* cbItem);

public function uint32 PCLUSAPI_CLUSTER_GROUP_CLOSE_ENUM_EX(_HGROUPENUMEX* hGroupEnumEx);

public function _HRESENUMEX* PCLUSAPI_CLUSTER_RESOURCE_OPEN_ENUM_EX(_HCLUSTER* hCluster, PWSTR lpszProperties, uint32 cbProperties, PWSTR lpszRoProperties, uint32 cbRoProperties, uint32 dwFlags);

public function uint32 PCLUSAPI_CLUSTER_RESOURCE_GET_ENUM_COUNT_EX(_HRESENUMEX* hResourceEnumEx);

public function uint32 PCLUSAPI_CLUSTER_RESOURCE_ENUM_EX(_HRESENUMEX* hResourceEnumEx, uint32 dwIndex, CLUSTER_RESOURCE_ENUM_ITEM* pItem, uint32* cbItem);

public function uint32 PCLUSAPI_CLUSTER_RESOURCE_CLOSE_ENUM_EX(_HRESENUMEX* hResourceEnumEx);

public function uint32 PCLUSAPI_RESTART_CLUSTER_RESOURCE(_HRESOURCE* hResource, uint32 dwFlags);

public function BOOL PCLUSAPI_CLOSE_CLUSTER_GROUP(_HGROUP* hGroup);

public function _HCLUSTER* PCLUSAPI_GET_CLUSTER_FROM_GROUP(_HGROUP* hGroup);

public function CLUSTER_GROUP_STATE PCLUSAPI_GET_CLUSTER_GROUP_STATE(_HGROUP* hGroup, char16* lpszNodeName, uint32* lpcchNodeName);

public function uint32 PCLUSAPI_SET_CLUSTER_GROUP_NAME(_HGROUP* hGroup, PWSTR lpszGroupName);

public function uint32 PCLUSAPI_SET_CLUSTER_GROUP_NODE_LIST(_HGROUP* hGroup, uint32 NodeCount, _HNODE** NodeList);

public function uint32 PCLUSAPI_ONLINE_CLUSTER_GROUP(_HGROUP* hGroup, _HNODE* hDestinationNode);

public function uint32 PCLUSAPI_MOVE_CLUSTER_GROUP(_HGROUP* hGroup, _HNODE* hDestinationNode);

public function uint32 PCLUSAPI_OFFLINE_CLUSTER_GROUP(_HGROUP* hGroup);

public function uint32 PCLUSAPI_DELETE_CLUSTER_GROUP(_HGROUP* hGroup);

public function uint32 PCLUSAPI_DESTROY_CLUSTER_GROUP(_HGROUP* hGroup);

public function _HGROUPENUM* PCLUSAPI_CLUSTER_GROUP_OPEN_ENUM(_HGROUP* hGroup, uint32 dwType);

public function uint32 PCLUSAPI_CLUSTER_GROUP_GET_ENUM_COUNT(_HGROUPENUM* hGroupEnum);

public function uint32 PCLUSAPI_CLUSTER_GROUP_ENUM(_HGROUPENUM* hGroupEnum, uint32 dwIndex, uint32* lpdwType, char16* lpszResourceName, uint32* lpcchName);

public function uint32 PCLUSAPI_CLUSTER_GROUP_CLOSE_ENUM(_HGROUPENUM* hGroupEnum);

public function _HRESOURCE* PCLUSAPI_CREATE_CLUSTER_RESOURCE(_HGROUP* hGroup, PWSTR lpszResourceName, PWSTR lpszResourceType, uint32 dwFlags);

public function _HRESOURCE* PCLUSAPI_OPEN_CLUSTER_RESOURCE(_HCLUSTER* hCluster, PWSTR lpszResourceName);

public function _HRESOURCE* PCLUSAPI_OPEN_CLUSTER_RESOURCE_EX(_HCLUSTER* hCluster, PWSTR lpszResourceName, uint32 dwDesiredAccess, uint32* lpdwGrantedAccess);

public function BOOL PCLUSAPI_CLOSE_CLUSTER_RESOURCE(_HRESOURCE* hResource);

public function _HCLUSTER* PCLUSAPI_GET_CLUSTER_FROM_RESOURCE(_HRESOURCE* hResource);

public function uint32 PCLUSAPI_DELETE_CLUSTER_RESOURCE(_HRESOURCE* hResource);

public function CLUSTER_RESOURCE_STATE PCLUSAPI_GET_CLUSTER_RESOURCE_STATE(_HRESOURCE* hResource, char16* lpszNodeName, uint32* lpcchNodeName, char16* lpszGroupName, uint32* lpcchGroupName);

public function uint32 PCLUSAPI_SET_CLUSTER_RESOURCE_NAME(_HRESOURCE* hResource, PWSTR lpszResourceName);

public function uint32 PCLUSAPI_FAIL_CLUSTER_RESOURCE(_HRESOURCE* hResource);

public function uint32 PCLUSAPI_ONLINE_CLUSTER_RESOURCE(_HRESOURCE* hResource);

public function uint32 PCLUSAPI_OFFLINE_CLUSTER_RESOURCE(_HRESOURCE* hResource);

public function uint32 PCLUSAPI_CHANGE_CLUSTER_RESOURCE_GROUP(_HRESOURCE* hResource, _HGROUP* hGroup);

public function uint32 PCLUSAPI_CHANGE_CLUSTER_RESOURCE_GROUP_EX(_HRESOURCE* hResource, _HGROUP* hGroup, uint64 Flags);

public function uint32 PCLUSAPI_ADD_CLUSTER_RESOURCE_NODE(_HRESOURCE* hResource, _HNODE* hNode);

public function uint32 PCLUSAPI_REMOVE_CLUSTER_RESOURCE_NODE(_HRESOURCE* hResource, _HNODE* hNode);

public function uint32 PCLUSAPI_ADD_CLUSTER_RESOURCE_DEPENDENCY(_HRESOURCE* hResource, _HRESOURCE* hDependsOn);

public function uint32 PCLUSAPI_REMOVE_CLUSTER_RESOURCE_DEPENDENCY(_HRESOURCE* hResource, _HRESOURCE* hDependsOn);

public function uint32 PCLUSAPI_SET_CLUSTER_RESOURCE_DEPENDENCY_EXPRESSION(_HRESOURCE* hResource, PWSTR lpszDependencyExpression);

public function uint32 PCLUSAPI_GET_CLUSTER_RESOURCE_DEPENDENCY_EXPRESSION(_HRESOURCE* hResource, char16* lpszDependencyExpression, uint32* lpcchDependencyExpression);

public function uint32 PCLUSAPI_ADD_RESOURCE_TO_CLUSTER_SHARED_VOLUMES(_HRESOURCE* hResource);

public function uint32 PCLUSAPI_REMOVE_RESOURCE_FROM_CLUSTER_SHARED_VOLUMES(_HRESOURCE* hResource);

public function uint32 PCLUSAPI_IS_FILE_ON_CLUSTER_SHARED_VOLUME(PWSTR lpszPathName, BOOL* pbFileIsOnSharedVolume);

public function uint32 PCLUSAPI_SHARED_VOLUME_SET_SNAPSHOT_STATE(Guid guidSnapshotSet, PWSTR lpszVolumeName, CLUSTER_SHARED_VOLUME_SNAPSHOT_STATE state);

public function BOOL PCLUSAPI_CAN_RESOURCE_BE_DEPENDENT(_HRESOURCE* hResource, _HRESOURCE* hResourceDependent);

public function uint32 PCLUSAPI_CLUSTER_RESOURCE_CONTROL(_HRESOURCE* hResource, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 cbInBufferSize, void* lpOutBuffer, uint32 cbOutBufferSize, uint32* lpBytesReturned);

public function uint32 PCLUSAPI_CLUSTER_RESOURCE_TYPE_CONTROL(_HCLUSTER* hCluster, PWSTR lpszResourceTypeName, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned);

public function uint32 PCLUSAPI_CLUSTER_GROUP_CONTROL(_HGROUP* hGroup, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned);

public function uint32 PCLUSAPI_CLUSTER_NODE_CONTROL(_HNODE* hNode, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned);

public function BOOL PCLUSAPI_GET_CLUSTER_RESOURCE_NETWORK_NAME(_HRESOURCE* hResource, char16* lpBuffer, uint32* nSize);

public function _HRESENUM* PCLUSAPI_CLUSTER_RESOURCE_OPEN_ENUM(_HRESOURCE* hResource, uint32 dwType);

public function uint32 PCLUSAPI_CLUSTER_RESOURCE_GET_ENUM_COUNT(_HRESENUM* hResEnum);

public function uint32 PCLUSAPI_CLUSTER_RESOURCE_ENUM(_HRESENUM* hResEnum, uint32 dwIndex, uint32* lpdwType, char16* lpszName, uint32* lpcchName);

public function uint32 PCLUSAPI_CLUSTER_RESOURCE_CLOSE_ENUM(_HRESENUM* hResEnum);

public function uint32 PCLUSAPI_CREATE_CLUSTER_RESOURCE_TYPE(_HCLUSTER* hCluster, PWSTR lpszResourceTypeName, PWSTR lpszDisplayName, PWSTR lpszResourceTypeDll, uint32 dwLooksAlivePollInterval, uint32 dwIsAlivePollInterval);

public function uint32 PCLUSAPI_DELETE_CLUSTER_RESOURCE_TYPE(_HCLUSTER* hCluster, PWSTR lpszResourceTypeName);

public function _HRESTYPEENUM* PCLUSAPI_CLUSTER_RESOURCE_TYPE_OPEN_ENUM(_HCLUSTER* hCluster, PWSTR lpszResourceTypeName, uint32 dwType);

public function uint32 PCLUSAPI_CLUSTER_RESOURCE_TYPE_GET_ENUM_COUNT(_HRESTYPEENUM* hResTypeEnum);

public function uint32 PCLUSAPI_CLUSTER_RESOURCE_TYPE_ENUM(_HRESTYPEENUM* hResTypeEnum, uint32 dwIndex, uint32* lpdwType, char16* lpszName, uint32* lpcchName);

public function uint32 PCLUSAPI_CLUSTER_RESOURCE_TYPE_CLOSE_ENUM(_HRESTYPEENUM* hResTypeEnum);

public function _HNETWORK* PCLUSAPI_OPEN_CLUSTER_NETWORK(_HCLUSTER* hCluster, PWSTR lpszNetworkName);

public function _HNETWORK* PCLUSAPI_OPEN_CLUSTER_NETWORK_EX(_HCLUSTER* hCluster, PWSTR lpszNetworkName, uint32 dwDesiredAccess, uint32* lpdwGrantedAccess);

public function BOOL PCLUSAPI_CLOSE_CLUSTER_NETWORK(_HNETWORK* hNetwork);

public function _HCLUSTER* PCLUSAPI_GET_CLUSTER_FROM_NETWORK(_HNETWORK* hNetwork);

public function _HNETWORKENUM* PCLUSAPI_CLUSTER_NETWORK_OPEN_ENUM(_HNETWORK* hNetwork, uint32 dwType);

public function uint32 PCLUSAPI_CLUSTER_NETWORK_GET_ENUM_COUNT(_HNETWORKENUM* hNetworkEnum);

public function uint32 PCLUSAPI_CLUSTER_NETWORK_ENUM(_HNETWORKENUM* hNetworkEnum, uint32 dwIndex, uint32* lpdwType, char16* lpszName, uint32* lpcchName);

public function uint32 PCLUSAPI_CLUSTER_NETWORK_CLOSE_ENUM(_HNETWORKENUM* hNetworkEnum);

public function CLUSTER_NETWORK_STATE PCLUSAPI_GET_CLUSTER_NETWORK_STATE(_HNETWORK* hNetwork);

public function uint32 PCLUSAPI_SET_CLUSTER_NETWORK_NAME(_HNETWORK* hNetwork, PWSTR lpszName);

public function uint32 PCLUSAPI_GET_CLUSTER_NETWORK_ID(_HNETWORK* hNetwork, char16* lpszNetworkId, uint32* lpcchName);

public function uint32 PCLUSAPI_CLUSTER_NETWORK_CONTROL(_HNETWORK* hNetwork, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned);

public function _HNETINTERFACE* PCLUSAPI_OPEN_CLUSTER_NET_INTERFACE(_HCLUSTER* hCluster, PWSTR lpszInterfaceName);

public function _HNETINTERFACE* PCLUSAPI_OPEN_CLUSTER_NETINTERFACE_EX(_HCLUSTER* hCluster, PWSTR lpszNetInterfaceName, uint32 dwDesiredAccess, uint32* lpdwGrantedAccess);

public function uint32 PCLUSAPI_GET_CLUSTER_NET_INTERFACE(_HCLUSTER* hCluster, PWSTR lpszNodeName, PWSTR lpszNetworkName, char16* lpszInterfaceName, uint32* lpcchInterfaceName);

public function BOOL PCLUSAPI_CLOSE_CLUSTER_NET_INTERFACE(_HNETINTERFACE* hNetInterface);

public function _HCLUSTER* PCLUSAPI_GET_CLUSTER_FROM_NET_INTERFACE(_HNETINTERFACE* hNetInterface);

public function CLUSTER_NETINTERFACE_STATE PCLUSAPI_GET_CLUSTER_NET_INTERFACE_STATE(_HNETINTERFACE* hNetInterface);

public function uint32 PCLUSAPI_CLUSTER_NET_INTERFACE_CONTROL(_HNETINTERFACE* hNetInterface, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned);

public function HKEY PCLUSAPI_GET_CLUSTER_KEY(_HCLUSTER* hCluster, uint32 samDesired);

public function HKEY PCLUSAPI_GET_CLUSTER_GROUP_KEY(_HGROUP* hGroup, uint32 samDesired);

public function HKEY PCLUSAPI_GET_CLUSTER_RESOURCE_KEY(_HRESOURCE* hResource, uint32 samDesired);

public function HKEY PCLUSAPI_GET_CLUSTER_NODE_KEY(_HNODE* hNode, uint32 samDesired);

public function HKEY PCLUSAPI_GET_CLUSTER_NETWORK_KEY(_HNETWORK* hNetwork, uint32 samDesired);

public function HKEY PCLUSAPI_GET_CLUSTER_NET_INTERFACE_KEY(_HNETINTERFACE* hNetInterface, uint32 samDesired);

public function int32 PCLUSAPI_CLUSTER_REG_CREATE_KEY(HKEY hKey, PWSTR lpszSubKey, uint32 dwOptions, uint32 samDesired, SECURITY_ATTRIBUTES* lpSecurityAttributes, HKEY* phkResult, uint32* lpdwDisposition);

public function int32 PCLUSAPI_CLUSTER_REG_OPEN_KEY(HKEY hKey, PWSTR lpszSubKey, uint32 samDesired, HKEY* phkResult);

public function int32 PCLUSAPI_CLUSTER_REG_DELETE_KEY(HKEY hKey, PWSTR lpszSubKey);

public function int32 PCLUSAPI_CLUSTER_REG_CLOSE_KEY(HKEY hKey);

public function int32 PCLUSAPI_CLUSTER_REG_ENUM_KEY(HKEY hKey, uint32 dwIndex, char16* lpszName, uint32* lpcchName, FILETIME* lpftLastWriteTime);

public function uint32 PCLUSAPI_CLUSTER_REG_SET_VALUE(HKEY hKey, PWSTR lpszValueName, uint32 dwType, uint8* lpData, uint32 cbData);

public function uint32 PCLUSAPI_CLUSTER_REG_DELETE_VALUE(HKEY hKey, PWSTR lpszValueName);

public function int32 PCLUSAPI_CLUSTER_REG_QUERY_VALUE(HKEY hKey, PWSTR lpszValueName, uint32* lpdwValueType, uint8* lpData, uint32* lpcbData);

public function uint32 PCLUSAPI_CLUSTER_REG_ENUM_VALUE(HKEY hKey, uint32 dwIndex, char16* lpszValueName, uint32* lpcchValueName, uint32* lpdwType, uint8* lpData, uint32* lpcbData);

public function int32 PCLUSAPI_CLUSTER_REG_QUERY_INFO_KEY(HKEY hKey, uint32* lpcSubKeys, uint32* lpcbMaxSubKeyLen, uint32* lpcValues, uint32* lpcbMaxValueNameLen, uint32* lpcbMaxValueLen, uint32* lpcbSecurityDescriptor, FILETIME* lpftLastWriteTime);

public function int32 PCLUSAPI_CLUSTER_REG_GET_KEY_SECURITY(HKEY hKey, uint32 RequestedInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor, uint32* lpcbSecurityDescriptor);

public function int32 PCLUSAPI_CLUSTER_REG_SET_KEY_SECURITY(HKEY hKey, uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor);

public function int32 PCLUSAPI_CLUSTER_REG_SYNC_DATABASE(_HCLUSTER* hCluster, uint32 flags);

public function int32 PCLUSAPI_CLUSTER_REG_CREATE_BATCH(HKEY hKey, _HREGBATCH** pHREGBATCH);

public function int32 PCLUSTER_REG_BATCH_ADD_COMMAND(_HREGBATCH* hRegBatch, CLUSTER_REG_COMMAND dwCommand, PWSTR wzName, uint32 dwOptions, void* lpData, uint32 cbData);

public function int32 PCLUSTER_REG_CLOSE_BATCH(_HREGBATCH* hRegBatch, BOOL bCommit, int32* failedCommandNumber);

public function int32 PCLUSTER_REG_BATCH_READ_COMMAND(_HREGBATCHNOTIFICATION* hBatchNotification, CLUSTER_BATCH_COMMAND* pBatchCommand);

public function int32 PCLUSTER_REG_BATCH_CLOSE_NOTIFICATION(_HREGBATCHNOTIFICATION* hBatchNotification);

public function int32 PCLUSTER_REG_CREATE_BATCH_NOTIFY_PORT(HKEY hKey, _HREGBATCHPORT** phBatchNotifyPort);

public function int32 PCLUSTER_REG_CLOSE_BATCH_NOTIFY_PORT(_HREGBATCHPORT* hBatchNotifyPort);

public function int32 PCLUSTER_REG_GET_BATCH_NOTIFICATION(_HREGBATCHPORT* hBatchNotify, _HREGBATCHNOTIFICATION** phBatchNotification);

public function int32 PCLUSTER_REG_CREATE_READ_BATCH(HKEY hKey, _HREGREADBATCH** phRegReadBatch);

public function int32 PCLUSTER_REG_READ_BATCH_ADD_COMMAND(_HREGREADBATCH* hRegReadBatch, PWSTR wzSubkeyName, PWSTR wzValueName);

public function int32 PCLUSTER_REG_CLOSE_READ_BATCH(_HREGREADBATCH* hRegReadBatch, _HREGREADBATCHREPLY** phRegReadBatchReply);

public function int32 PCLUSTER_REG_CLOSE_READ_BATCH_EX(_HREGREADBATCH* hRegReadBatch, uint32 flags, _HREGREADBATCHREPLY** phRegReadBatchReply);

public function int32 PCLUSTER_REG_READ_BATCH_REPLY_NEXT_COMMAND(_HREGREADBATCHREPLY* hRegReadBatchReply, CLUSTER_READ_BATCH_COMMAND* pBatchCommand);

public function int32 PCLUSTER_REG_CLOSE_READ_BATCH_REPLY(_HREGREADBATCHREPLY* hRegReadBatchReply);

public function uint32 PCLUSTER_SET_ACCOUNT_ACCESS(_HCLUSTER* hCluster, PWSTR szAccountSID, uint32 dwAccess, uint32 dwControlType);

public function BOOL PCLUSTER_SETUP_PROGRESS_CALLBACK(void* pvCallbackArg, CLUSTER_SETUP_PHASE eSetupPhase, CLUSTER_SETUP_PHASE_TYPE ePhaseType, CLUSTER_SETUP_PHASE_SEVERITY ePhaseSeverity, uint32 dwPercentComplete, PWSTR lpszObjectName, uint32 dwStatus);

public function _HCLUSTER* PCLUSAPI_CREATE_CLUSTER(CREATE_CLUSTER_CONFIG* pConfig, PCLUSTER_SETUP_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg);

public function _HCLUSTER* PCLUSAPI_CREATE_CLUSTER_CNOLESS(CREATE_CLUSTER_CONFIG* pConfig, PCLUSTER_SETUP_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg);

public function uint32 PCLUSAPI_CREATE_CLUSTER_NAME_ACCOUNT(_HCLUSTER* hCluster, CREATE_CLUSTER_NAME_ACCOUNT* pConfig, PCLUSTER_SETUP_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg);

public function uint32 PCLUSAPI_REMOVE_CLUSTER_NAME_ACCOUNT(_HCLUSTER* hCluster);

public function _HNODE* PCLUSAPI_ADD_CLUSTER_NODE(_HCLUSTER* hCluster, PWSTR lpszNodeName, PCLUSTER_SETUP_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg);

public function _HNODE* PCLUSAPI_ADD_CLUSTER_NODE_EX(_HCLUSTER* hCluster, PWSTR lpszNodeName, uint32 dwFlags, PCLUSTER_SETUP_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg);

public function uint32 PCLUSAPI_DESTROY_CLUSTER(_HCLUSTER* hCluster, PCLUSTER_SETUP_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg, BOOL fdeleteVirtualComputerObjects);

public function uint32 PSET_RESOURCE_STATUS_ROUTINE_EX(int ResourceHandle, RESOURCE_STATUS_EX* ResourceStatus);

public function uint32 PSET_RESOURCE_STATUS_ROUTINE(int ResourceHandle, RESOURCE_STATUS* ResourceStatus);

public function void PQUORUM_RESOURCE_LOST(int Resource);

public function void PLOG_EVENT_ROUTINE(int ResourceHandle, LOG_LEVEL LogLevel, PWSTR FormatString);

public function void* POPEN_ROUTINE(PWSTR ResourceName, HKEY ResourceKey, int ResourceHandle);

public function void PCLOSE_ROUTINE(void* Resource);

public function uint32 PONLINE_ROUTINE(void* Resource, HANDLE* EventHandle);

public function uint32 POFFLINE_ROUTINE(void* Resource);

public function void PTERMINATE_ROUTINE(void* Resource);

public function BOOL PIS_ALIVE_ROUTINE(void* Resource);

public function BOOL PLOOKS_ALIVE_ROUTINE(void* Resource);

public function uint32 PARBITRATE_ROUTINE(void* Resource, PQUORUM_RESOURCE_LOST LostQuorumResource);

public function uint32 PRELEASE_ROUTINE(void* Resource);

public function uint32 PRESOURCE_CONTROL_ROUTINE(void* Resource, uint32 ControlCode, void* InBuffer, uint32 InBufferSize, void* OutBuffer, uint32 OutBufferSize, uint32* BytesReturned);

public function uint32 PRESOURCE_TYPE_CONTROL_ROUTINE(PWSTR ResourceTypeName, uint32 ControlCode, void* InBuffer, uint32 InBufferSize, void* OutBuffer, uint32 OutBufferSize, uint32* BytesReturned);

public function void* POPEN_V2_ROUTINE(PWSTR ResourceName, HKEY ResourceKey, int ResourceHandle, uint32 OpenFlags);

public function uint32 PONLINE_V2_ROUTINE(void* Resource, HANDLE* EventHandle, uint32 OnlineFlags, uint8* InBuffer, uint32 InBufferSize, uint32 Reserved);

public function uint32 POFFLINE_V2_ROUTINE(void* Resource, PWSTR DestinationNodeName, uint32 OfflineFlags, uint8* InBuffer, uint32 InBufferSize, uint32 Reserved);

public function uint32 PCANCEL_ROUTINE(void* Resource, uint32 CancelFlags_RESERVED);

public function uint32 PBEGIN_RESCALL_ROUTINE(void* Resource, uint32 ControlCode, void* InBuffer, uint32 InBufferSize, void* OutBuffer, uint32 OutBufferSize, uint32* BytesReturned, int64 context, BOOL* ReturnedAsynchronously);

public function uint32 PBEGIN_RESTYPECALL_ROUTINE(PWSTR ResourceTypeName, uint32 ControlCode, void* InBuffer, uint32 InBufferSize, void* OutBuffer, uint32 OutBufferSize, uint32* BytesReturned, int64 context, BOOL* ReturnedAsynchronously);

public function uint32 PBEGIN_RESCALL_AS_USER_ROUTINE(void* Resource, HANDLE TokenHandle, uint32 ControlCode, void* InBuffer, uint32 InBufferSize, void* OutBuffer, uint32 OutBufferSize, uint32* BytesReturned, int64 context, BOOL* ReturnedAsynchronously);

public function uint32 PBEGIN_RESTYPECALL_AS_USER_ROUTINE(PWSTR ResourceTypeName, HANDLE TokenHandle, uint32 ControlCode, void* InBuffer, uint32 InBufferSize, void* OutBuffer, uint32 OutBufferSize, uint32* BytesReturned, int64 context, BOOL* ReturnedAsynchronously);

public function uint32 PSTARTUP_ROUTINE(PWSTR ResourceType, uint32 MinVersionSupported, uint32 MaxVersionSupported, PSET_RESOURCE_STATUS_ROUTINE SetResourceStatus, PLOG_EVENT_ROUTINE LogEvent, CLRES_FUNCTION_TABLE** FunctionTable);

public function uint32 PSET_RESOURCE_LOCKED_MODE_ROUTINE(int ResourceHandle, BOOL LockedModeEnabled, uint32 LockedModeReason);

public function uint32 PSIGNAL_FAILURE_ROUTINE(int ResourceHandle, FAILURE_TYPE FailureType, uint32 ApplicationSpecificErrorCode);

public function uint32 PSET_RESOURCE_INMEMORY_NODELOCAL_PROPERTIES_ROUTINE(int ResourceHandle, uint8* propertyListBuffer, uint32 propertyListBufferSize);

public function uint32 PEND_CONTROL_CALL(int64 context, uint32 status);

public function uint32 PEND_TYPE_CONTROL_CALL(int64 context, uint32 status);

public function uint32 PEXTEND_RES_CONTROL_CALL(int64 context, uint32 newTimeoutInMs);

public function uint32 PEXTEND_RES_TYPE_CONTROL_CALL(int64 context, uint32 newTimeoutInMs);

public function uint32 PRAISE_RES_TYPE_NOTIFICATION(PWSTR ResourceType, uint8* pPayload, uint32 payloadSize);

public function uint32 PCHANGE_RESOURCE_PROCESS_FOR_DUMPS(int resource, PWSTR processName, uint32 processId, BOOL isAdd);

public function uint32 PCHANGE_RES_TYPE_PROCESS_FOR_DUMPS(PWSTR resourceTypeName, PWSTR processName, uint32 processId, BOOL isAdd);

public function uint32 PSET_INTERNAL_STATE(int param0, CLUSTER_RESOURCE_APPLICATION_STATE stateType, BOOL active);

public function uint32 PSET_RESOURCE_LOCKED_MODE_EX_ROUTINE(int ResourceHandle, BOOL LockedModeEnabled, uint32 LockedModeReason, uint32 LockedModeFlags);

public function uint32 PREQUEST_DUMP_ROUTINE(int ResourceHandle, BOOL DumpDueToCallInProgress, uint32 DumpDelayInMs);

public function uint32 PSTARTUP_EX_ROUTINE(PWSTR ResourceType, uint32 MinVersionSupported, uint32 MaxVersionSupported, CLRES_CALLBACK_FUNCTION_TABLE* MonitorCallbackFunctions, CLRES_FUNCTION_TABLE** ResourceDllInterfaceFunctions);

public function uint32 PRESUTIL_START_RESOURCE_SERVICE(PWSTR pszServiceName, int* phServiceHandle);

public function uint32 PRESUTIL_VERIFY_RESOURCE_SERVICE(PWSTR pszServiceName);

public function uint32 PRESUTIL_STOP_RESOURCE_SERVICE(PWSTR pszServiceName);

public function uint32 PRESUTIL_VERIFY_SERVICE(SC_HANDLE hServiceHandle);

public function uint32 PRESUTIL_STOP_SERVICE(SC_HANDLE hServiceHandle);

public function uint32 PRESUTIL_CREATE_DIRECTORY_TREE(PWSTR pszPath);

public function BOOL PRESUTIL_IS_PATH_VALID(PWSTR pszPath);

public function uint32 PRESUTIL_ENUM_PROPERTIES(RESUTIL_PROPERTY_ITEM* pPropertyTable, PWSTR pszOutProperties, uint32 cbOutPropertiesSize, uint32* pcbBytesReturned, uint32* pcbRequired);

public function uint32 PRESUTIL_ENUM_PRIVATE_PROPERTIES(HKEY hkeyClusterKey, PWSTR pszOutProperties, uint32 cbOutPropertiesSize, uint32* pcbBytesReturned, uint32* pcbRequired);

public function uint32 PRESUTIL_GET_PROPERTIES(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* pOutPropertyList, uint32 cbOutPropertyListSize, uint32* pcbBytesReturned, uint32* pcbRequired);

public function uint32 PRESUTIL_GET_ALL_PROPERTIES(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* pOutPropertyList, uint32 cbOutPropertyListSize, uint32* pcbBytesReturned, uint32* pcbRequired);

public function uint32 PRESUTIL_GET_PRIVATE_PROPERTIES(HKEY hkeyClusterKey, void* pOutPropertyList, uint32 cbOutPropertyListSize, uint32* pcbBytesReturned, uint32* pcbRequired);

public function uint32 PRESUTIL_GET_PROPERTY_SIZE(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTableItem, uint32* pcbOutPropertyListSize, uint32* pnPropertyCount);

public function uint32 PRESUTIL_GET_PROPERTY(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTableItem, void** pOutPropertyItem, uint32* pcbOutPropertyItemSize);

public function uint32 PRESUTIL_VERIFY_PROPERTY_TABLE(RESUTIL_PROPERTY_ITEM* pPropertyTable, void* Reserved, BOOL bAllowUnknownProperties, void* pInPropertyList, uint32 cbInPropertyListSize, uint8* pOutParams);

public function uint32 PRESUTIL_SET_PROPERTY_TABLE(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* Reserved, BOOL bAllowUnknownProperties, void* pInPropertyList, uint32 cbInPropertyListSize, uint8* pOutParams);

public function uint32 PRESUTIL_SET_PROPERTY_TABLE_EX(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* Reserved, BOOL bAllowUnknownProperties, void* pInPropertyList, uint32 cbInPropertyListSize, BOOL bForceWrite, uint8* pOutParams);

public function uint32 PRESUTIL_SET_PROPERTY_PARAMETER_BLOCK(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* Reserved, uint8* pInParams, void* pInPropertyList, uint32 cbInPropertyListSize, uint8* pOutParams);

public function uint32 PRESUTIL_SET_PROPERTY_PARAMETER_BLOCK_EX(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* Reserved, uint8* pInParams, void* pInPropertyList, uint32 cbInPropertyListSize, BOOL bForceWrite, uint8* pOutParams);

public function uint32 PRESUTIL_SET_UNKNOWN_PROPERTIES(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* pInPropertyList, uint32 cbInPropertyListSize);

public function uint32 PRESUTIL_GET_PROPERTIES_TO_PARAMETER_BLOCK(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, uint8* pOutParams, BOOL bCheckForRequiredProperties, PWSTR* pszNameOfPropInError);

public function uint32 PRESUTIL_PROPERTY_LIST_FROM_PARAMETER_BLOCK(RESUTIL_PROPERTY_ITEM* pPropertyTable, void* pOutPropertyList, uint32* pcbOutPropertyListSize, uint8* pInParams, uint32* pcbBytesReturned, uint32* pcbRequired);

public function uint32 PRESUTIL_DUP_PARAMETER_BLOCK(uint8* pOutParams, uint8* pInParams, RESUTIL_PROPERTY_ITEM* pPropertyTable);

public function void PRESUTIL_FREE_PARAMETER_BLOCK(uint8* pOutParams, uint8* pInParams, RESUTIL_PROPERTY_ITEM* pPropertyTable);

public function uint32 PRESUTIL_ADD_UNKNOWN_PROPERTIES(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* pOutPropertyList, uint32 pcbOutPropertyListSize, uint32* pcbBytesReturned, uint32* pcbRequired);

public function uint32 PRESUTIL_SET_PRIVATE_PROPERTY_LIST(HKEY hkeyClusterKey, void* pInPropertyList, uint32 cbInPropertyListSize);

public function uint32 PRESUTIL_VERIFY_PRIVATE_PROPERTY_LIST(void* pInPropertyList, uint32 cbInPropertyListSize);

public function PWSTR PRESUTIL_DUP_STRING(PWSTR pszInString);

public function uint32 PRESUTIL_GET_BINARY_VALUE(HKEY hkeyClusterKey, PWSTR pszValueName, uint8** ppbOutValue, uint32* pcbOutValueSize);

public function PWSTR PRESUTIL_GET_SZ_VALUE(HKEY hkeyClusterKey, PWSTR pszValueName);

public function PWSTR PRESUTIL_GET_EXPAND_SZ_VALUE(HKEY hkeyClusterKey, PWSTR pszValueName, BOOL bExpand);

public function uint32 PRESUTIL_GET_DWORD_VALUE(HKEY hkeyClusterKey, PWSTR pszValueName, uint32* pdwOutValue, uint32 dwDefaultValue);

public function uint32 PRESUTIL_GET_QWORD_VALUE(HKEY hkeyClusterKey, PWSTR pszValueName, uint64* pqwOutValue, uint64 qwDefaultValue);

public function uint32 PRESUTIL_SET_BINARY_VALUE(HKEY hkeyClusterKey, PWSTR pszValueName, uint8* pbNewValue, uint32 cbNewValueSize, uint8** ppbOutValue, uint32* pcbOutValueSize);

public function uint32 PRESUTIL_SET_SZ_VALUE(HKEY hkeyClusterKey, PWSTR pszValueName, PWSTR pszNewValue, PWSTR* ppszOutString);

public function uint32 PRESUTIL_SET_EXPAND_SZ_VALUE(HKEY hkeyClusterKey, PWSTR pszValueName, PWSTR pszNewValue, PWSTR* ppszOutString);

public function uint32 PRESUTIL_SET_MULTI_SZ_VALUE(HKEY hkeyClusterKey, PWSTR pszValueName, PWSTR pszNewValue, uint32 cbNewValueSize, PWSTR* ppszOutValue, uint32* pcbOutValueSize);

public function uint32 PRESUTIL_SET_DWORD_VALUE(HKEY hkeyClusterKey, PWSTR pszValueName, uint32 dwNewValue, uint32* pdwOutValue);

public function uint32 PRESUTIL_SET_QWORD_VALUE(HKEY hkeyClusterKey, PWSTR pszValueName, uint64 qwNewValue, uint64* pqwOutValue);

public function uint32 PRESUTIL_GET_BINARY_PROPERTY(uint8** ppbOutValue, uint32* pcbOutValueSize, CLUSPROP_BINARY* pValueStruct, uint8* pbOldValue, uint32 cbOldValueSize, uint8** ppPropertyList, uint32* pcbPropertyListSize);

public function uint32 PRESUTIL_GET_SZ_PROPERTY(PWSTR* ppszOutValue, CLUSPROP_SZ* pValueStruct, PWSTR pszOldValue, uint8** ppPropertyList, uint32* pcbPropertyListSize);

public function uint32 PRESUTIL_GET_MULTI_SZ_PROPERTY(PWSTR* ppszOutValue, uint32* pcbOutValueSize, CLUSPROP_SZ* pValueStruct, PWSTR pszOldValue, uint32 cbOldValueSize, uint8** ppPropertyList, uint32* pcbPropertyListSize);

public function uint32 PRESUTIL_GET_DWORD_PROPERTY(uint32* pdwOutValue, CLUSPROP_DWORD* pValueStruct, uint32 dwOldValue, uint32 dwMinimum, uint32 dwMaximum, uint8** ppPropertyList, uint32* pcbPropertyListSize);

public function uint32 PRESUTIL_GET_LONG_PROPERTY(int32* plOutValue, CLUSPROP_LONG* pValueStruct, int32 lOldValue, int32 lMinimum, int32 lMaximum, uint8** ppPropertyList, uint32* pcbPropertyListSize);

public function uint32 PRESUTIL_GET_FILETIME_PROPERTY(FILETIME* pftOutValue, CLUSPROP_FILETIME* pValueStruct, FILETIME ftOldValue, FILETIME ftMinimum, FILETIME ftMaximum, uint8** ppPropertyList, uint32* pcbPropertyListSize);

public function void* PRESUTIL_GET_ENVIRONMENT_WITH_NET_NAME(_HRESOURCE* hResource);

public function uint32 PRESUTIL_FREE_ENVIRONMENT(void* lpEnvironment);

public function PWSTR PRESUTIL_EXPAND_ENVIRONMENT_STRINGS(PWSTR pszSrc);

public function uint32 PRESUTIL_SET_RESOURCE_SERVICE_ENVIRONMENT(PWSTR pszServiceName, _HRESOURCE* hResource, PLOG_EVENT_ROUTINE pfnLogEvent, int hResourceHandle);

public function uint32 PRESUTIL_REMOVE_RESOURCE_SERVICE_ENVIRONMENT(PWSTR pszServiceName, PLOG_EVENT_ROUTINE pfnLogEvent, int hResourceHandle);

public function uint32 PRESUTIL_SET_RESOURCE_SERVICE_START_PARAMETERS(PWSTR pszServiceName, SC_HANDLE schSCMHandle, int* phService, PLOG_EVENT_ROUTINE pfnLogEvent, int hResourceHandle);

public function uint32 PRESUTIL_FIND_SZ_PROPERTY(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, PWSTR* pszPropertyValue);

public function uint32 PRESUTIL_FIND_EXPAND_SZ_PROPERTY(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, PWSTR* pszPropertyValue);

public function uint32 PRESUTIL_FIND_EXPANDED_SZ_PROPERTY(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, PWSTR* pszPropertyValue);

public function uint32 PRESUTIL_FIND_DWORD_PROPERTY(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, uint32* pdwPropertyValue);

public function uint32 PRESUTIL_FIND_BINARY_PROPERTY(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, uint8** pbPropertyValue, uint32* pcbPropertyValueSize);

public function uint32 PRESUTIL_FIND_MULTI_SZ_PROPERTY(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, PWSTR* pszPropertyValue, uint32* pcbPropertyValueSize);

public function uint32 PRESUTIL_FIND_LONG_PROPERTY(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, int32* plPropertyValue);

public function uint32 PRESUTIL_FIND_ULARGEINTEGER_PROPERTY(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, uint64* plPropertyValue);

public function uint32 PRESUTIL_FIND_FILETIME_PROPERTY(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, FILETIME* pftPropertyValue);

public function uint32 PWORKER_START_ROUTINE(CLUS_WORKER* pWorker, void* lpThreadParameter);

public function uint32 PCLUSAPI_CLUS_WORKER_CREATE(CLUS_WORKER* lpWorker, PWORKER_START_ROUTINE lpStartAddress, void* lpParameter);

public function BOOL PCLUSAPIClusWorkerCheckTerminate(CLUS_WORKER* lpWorker);

public function void PCLUSAPI_CLUS_WORKER_TERMINATE(CLUS_WORKER* lpWorker);

public function uint32 LPRESOURCE_CALLBACK(_HRESOURCE* param0, _HRESOURCE* param1, void* param2);

public function uint32 LPRESOURCE_CALLBACK_EX(_HCLUSTER* param0, _HRESOURCE* param1, _HRESOURCE* param2, void* param3);

public function uint32 LPGROUP_CALLBACK_EX(_HCLUSTER* param0, _HGROUP* param1, _HGROUP* param2, void* param3);

public function uint32 LPNODE_CALLBACK(_HCLUSTER* param0, _HNODE* param1, CLUSTER_NODE_STATE param2, void* param3);

public function BOOL PRESUTIL_RESOURCES_EQUAL(_HRESOURCE* hSelf, _HRESOURCE* hResource);

public function BOOL PRESUTIL_RESOURCE_TYPES_EQUAL(PWSTR lpszResourceTypeName, _HRESOURCE* hResource);

public function BOOL PRESUTIL_IS_RESOURCE_CLASS_EQUAL(CLUS_RESOURCE_CLASS_INFO* prci, _HRESOURCE* hResource);

public function uint32 PRESUTIL_ENUM_RESOURCES(_HRESOURCE* hSelf, PWSTR lpszResTypeName, LPRESOURCE_CALLBACK pResCallBack, void* pParameter);

public function uint32 PRESUTIL_ENUM_RESOURCES_EX(_HCLUSTER* hCluster, _HRESOURCE* hSelf, PWSTR lpszResTypeName, LPRESOURCE_CALLBACK_EX pResCallBack, void* pParameter);

public function _HRESOURCE* PRESUTIL_GET_RESOURCE_DEPENDENCY(HANDLE hSelf, PWSTR lpszResourceType);

public function _HRESOURCE* PRESUTIL_GET_RESOURCE_DEPENDENCY_BY_NAME(_HCLUSTER* hCluster, HANDLE hSelf, PWSTR lpszResourceType, BOOL bRecurse);

public function _HRESOURCE* PRESUTIL_GET_RESOURCE_DEPENDENCY_BY_CLASS(_HCLUSTER* hCluster, HANDLE hSelf, CLUS_RESOURCE_CLASS_INFO* prci, BOOL bRecurse);

public function _HRESOURCE* PRESUTIL_GET_RESOURCE_NAME_DEPENDENCY(PWSTR lpszResourceName, PWSTR lpszResourceType);

public function uint32 PRESUTIL_GET_RESOURCE_DEPENDENTIP_ADDRESS_PROPS(_HRESOURCE* hResource, char16* pszAddress, uint32* pcchAddress, char16* pszSubnetMask, uint32* pcchSubnetMask, char16* pszNetwork, uint32* pcchNetwork);

public function uint32 PRESUTIL_FIND_DEPENDENT_DISK_RESOURCE_DRIVE_LETTER(_HCLUSTER* hCluster, _HRESOURCE* hResource, char16* pszDriveLetter, uint32* pcchDriveLetter);

public function uint32 PRESUTIL_TERMINATE_SERVICE_PROCESS_FROM_RES_DLL(uint32 dwServicePid, BOOL bOffline, uint32* pdwResourceState, PLOG_EVENT_ROUTINE pfnLogEvent, int hResourceHandle);

public function uint32 PRESUTIL_GET_PROPERTY_FORMATS(RESUTIL_PROPERTY_ITEM* pPropertyTable, void* pOutPropertyFormatList, uint32 cbPropertyFormatListSize, uint32* pcbBytesReturned, uint32* pcbRequired);

public function uint32 PRESUTIL_GET_CORE_CLUSTER_RESOURCES(_HCLUSTER* hCluster, _HRESOURCE** phClusterNameResource, _HRESOURCE** phClusterIPAddressResource, _HRESOURCE** phClusterQuorumResource);

public function uint32 PRESUTIL_GET_RESOURCE_NAME(_HRESOURCE* hResource, char16* pszResourceName, uint32* pcchResourceNameInOut);

public function BOOL PCLUSTER_IS_PATH_ON_SHARED_VOLUME(PWSTR lpszPathName);

public function BOOL PCLUSTER_GET_VOLUME_PATH_NAME(PWSTR lpszFileName, PWSTR lpszVolumePathName, uint32 cchBufferLength);

public function BOOL PCLUSTER_GET_VOLUME_NAME_FOR_VOLUME_MOUNT_POINT(PWSTR lpszVolumeMountPoint, PWSTR lpszVolumeName, uint32 cchBufferLength);

public function uint32 PCLUSTER_PREPARE_SHARED_VOLUME_FOR_BACKUP(PWSTR lpszFileName, PWSTR lpszVolumePathName, uint32* lpcchVolumePathName, PWSTR lpszVolumeName, uint32* lpcchVolumeName);

public function uint32 PCLUSTER_CLEAR_BACKUP_STATE_FOR_SHARED_VOLUME(PWSTR lpszVolumePathName);

public function uint32 PRESUTIL_SET_RESOURCE_SERVICE_START_PARAMETERS_EX(PWSTR pszServiceName, SC_HANDLE schSCMHandle, int* phService, uint32 dwDesiredAccess, PLOG_EVENT_ROUTINE pfnLogEvent, int hResourceHandle);

public function uint32 PRESUTIL_ENUM_RESOURCES_EX2(_HCLUSTER* hCluster, _HRESOURCE* hSelf, PWSTR lpszResTypeName, LPRESOURCE_CALLBACK_EX pResCallBack, void* pParameter, uint32 dwDesiredAccess);

public function _HRESOURCE* PRESUTIL_GET_RESOURCE_DEPENDENCY_EX(HANDLE hSelf, PWSTR lpszResourceType, uint32 dwDesiredAccess);

public function _HRESOURCE* PRESUTIL_GET_RESOURCE_DEPENDENCY_BY_NAME_EX(_HCLUSTER* hCluster, HANDLE hSelf, PWSTR lpszResourceType, BOOL bRecurse, uint32 dwDesiredAccess);

public function _HRESOURCE* PRESUTIL_GET_RESOURCE_DEPENDENCY_BY_CLASS_EX(_HCLUSTER* hCluster, HANDLE hSelf, CLUS_RESOURCE_CLASS_INFO* prci, BOOL bRecurse, uint32 dwDesiredAccess);

public function _HRESOURCE* PRESUTIL_GET_RESOURCE_NAME_DEPENDENCY_EX(PWSTR lpszResourceName, PWSTR lpszResourceType, uint32 dwDesiredAccess);

public function uint32 PRESUTIL_GET_CORE_CLUSTER_RESOURCES_EX(_HCLUSTER* hClusterIn, _HRESOURCE** phClusterNameResourceOut, _HRESOURCE** phClusterIPAddressResourceOut, _HRESOURCE** phClusterQuorumResourceOut, uint32 dwDesiredAccess);

public function _HCLUSCRYPTPROVIDER* POPEN_CLUSTER_CRYPT_PROVIDER(PWSTR lpszResource, int8* lpszProvider, uint32 dwType, uint32 dwFlags);

public function _HCLUSCRYPTPROVIDER* POPEN_CLUSTER_CRYPT_PROVIDEREX(PWSTR lpszResource, PWSTR lpszKeyname, int8* lpszProvider, uint32 dwType, uint32 dwFlags);

public function uint32 PCLOSE_CLUSTER_CRYPT_PROVIDER(_HCLUSCRYPTPROVIDER* hClusCryptProvider);

public function uint32 PCLUSTER_ENCRYPT(_HCLUSCRYPTPROVIDER* hClusCryptProvider, uint8* pData, uint32 cbData, uint8** ppData, uint32* pcbData);

public function uint32 PCLUSTER_DECRYPT(_HCLUSCRYPTPROVIDER* hClusCryptProvider, uint8* pCryptInput, uint32 cbCryptInput, uint8** ppCryptOutput, uint32* pcbCryptOutput);

public function uint32 PFREE_CLUSTER_CRYPT(void* pCryptInfo);

public function uint32 PRES_UTIL_VERIFY_SHUTDOWN_SAFE(uint32 flags, uint32 reason, uint32* pResult);

public function uint32 PREGISTER_APPINSTANCE(HANDLE ProcessHandle, Guid* AppInstanceId, BOOL ChildrenInheritAppInstance);

public function uint32 PREGISTER_APPINSTANCE_VERSION(Guid* AppInstanceId, uint64 InstanceVersionHigh, uint64 InstanceVersionLow);

public function uint32 PQUERY_APPINSTANCE_VERSION(Guid* AppInstanceId, uint64* InstanceVersionHigh, uint64* InstanceVersionLow, NTSTATUS* VersionStatus);

public function uint32 PRESET_ALL_APPINSTANCE_VERSIONS();

public function uint32 SET_APP_INSTANCE_CSV_FLAGS(HANDLE ProcessHandle, uint32 Mask, uint32 Flags);

#endregion

#region Structs
[CRepr]
public struct CLUSPROP_RESOURCE_CLASS_INFO
{
	public CLUSPROP_VALUE Base;
	public CLUS_RESOURCE_CLASS_INFO Base2;
}

[CRepr]
public struct CLUSTER_SHARED_VOLUME_RENAME_INPUT
{
	public CLUSTER_SHARED_VOLUME_RENAME_INPUT_VOLUME Base;
	public CLUSTER_SHARED_VOLUME_RENAME_INPUT_NAME Base2;
}

[CRepr]
public struct CLUSTER_SHARED_VOLUME_RENAME_GUID_INPUT
{
	public CLUSTER_SHARED_VOLUME_RENAME_INPUT_VOLUME Base;
	public CLUSTER_SHARED_VOLUME_RENAME_INPUT_GUID_NAME Base2;
}

[CRepr]
public struct CLUSPROP_PARTITION_INFO
{
	public CLUSPROP_VALUE Base;
	public CLUS_PARTITION_INFO Base2;
}

[CRepr]
public struct CLUSPROP_PARTITION_INFO_EX
{
	public CLUSPROP_VALUE Base;
	public CLUS_PARTITION_INFO_EX Base2;
}

[CRepr]
public struct CLUSPROP_PARTITION_INFO_EX2
{
	public CLUSPROP_PARTITION_INFO_EX Base;
	public CLUS_PARTITION_INFO_EX2 Base2;
}

[CRepr]
public struct CLUSPROP_FTSET_INFO
{
	public CLUSPROP_VALUE Base;
	public CLUS_FTSET_INFO Base2;
}

[CRepr]
public struct CLUSPROP_SCSI_ADDRESS
{
	public CLUSPROP_VALUE Base;
	public CLUS_SCSI_ADDRESS Base2;
}

[CRepr]
public struct _HCLUSTER
{
}

[CRepr]
public struct _HNODE
{
}

[CRepr]
public struct _HRESOURCE
{
}

[CRepr]
public struct _HGROUP
{
}

[CRepr]
public struct _HNETWORK
{
}

[CRepr]
public struct _HNETINTERFACE
{
}

[CRepr]
public struct _HCHANGE
{
}

[CRepr]
public struct _HCLUSENUM
{
}

[CRepr]
public struct _HGROUPENUM
{
}

[CRepr]
public struct _HRESENUM
{
}

[CRepr]
public struct _HNETWORKENUM
{
}

[CRepr]
public struct _HNODEENUM
{
}

[CRepr]
public struct _HNETINTERFACEENUM
{
}

[CRepr]
public struct _HRESTYPEENUM
{
}

[CRepr]
public struct _HREGBATCH
{
}

[CRepr]
public struct _HREGBATCHPORT
{
}

[CRepr]
public struct _HREGBATCHNOTIFICATION
{
}

[CRepr]
public struct _HREGREADBATCH
{
}

[CRepr]
public struct _HREGREADBATCHREPLY
{
}

[CRepr]
public struct _HNODEENUMEX
{
}

[CRepr]
public struct _HCLUSENUMEX
{
}

[CRepr]
public struct _HGROUPENUMEX
{
}

[CRepr]
public struct _HRESENUMEX
{
}

[CRepr]
public struct _HGROUPSET
{
}

[CRepr]
public struct _HGROUPSETENUM
{
}

[CRepr]
public struct CLUSTERVERSIONINFO_NT4
{
	public uint32 dwVersionInfoSize;
	public uint16 MajorVersion;
	public uint16 MinorVersion;
	public uint16 BuildNumber;
	public char16[64] szVendorId;
	public char16[64] szCSDVersion;
}

[CRepr]
public struct CLUSTERVERSIONINFO
{
	public uint32 dwVersionInfoSize;
	public uint16 MajorVersion;
	public uint16 MinorVersion;
	public uint16 BuildNumber;
	public char16[64] szVendorId;
	public char16[64] szCSDVersion;
	public uint32 dwClusterHighestVersion;
	public uint32 dwClusterLowestVersion;
	public uint32 dwFlags;
	public uint32 dwReserved;
}

[CRepr]
public struct CLUS_STARTING_PARAMS
{
	public uint32 dwSize;
	public BOOL bForm;
	public BOOL bFirst;
}

[CRepr]
public struct CLUSCTL_RESOURCE_STATE_CHANGE_REASON_STRUCT
{
	public uint32 dwSize;
	public uint32 dwVersion;
	public CLUSTER_RESOURCE_STATE_CHANGE_REASON eReason;
}

[CRepr]
public struct CLUSTER_BATCH_COMMAND
{
	public CLUSTER_REG_COMMAND Command;
	public uint32 dwOptions;
	public PWSTR wzName;
	public uint8* lpData;
	public uint32 cbData;
}

[CRepr]
public struct CLUSTER_READ_BATCH_COMMAND
{
	public CLUSTER_REG_COMMAND Command;
	public uint32 dwOptions;
	public PWSTR wzSubkeyName;
	public PWSTR wzValueName;
	public uint8* lpData;
	public uint32 cbData;
}

[CRepr]
public struct CLUSTER_ENUM_ITEM
{
	public uint32 dwVersion;
	public uint32 dwType;
	public uint32 cbId;
	public PWSTR lpszId;
	public uint32 cbName;
	public PWSTR lpszName;
}

[CRepr]
public struct CLUSTER_CREATE_GROUP_INFO
{
	public uint32 dwVersion;
	public CLUSGROUP_TYPE groupType;
}

[CRepr]
public struct CLUSTER_VALIDATE_PATH
{
	public char16* szPath mut => &szPath_impl;
	private char16[ANYSIZE_ARRAY] szPath_impl;
}

[CRepr]
public struct CLUSTER_VALIDATE_DIRECTORY
{
	public char16* szPath mut => &szPath_impl;
	private char16[ANYSIZE_ARRAY] szPath_impl;
}

[CRepr]
public struct CLUSTER_VALIDATE_NETNAME
{
	public char16* szNetworkName mut => &szNetworkName_impl;
	private char16[ANYSIZE_ARRAY] szNetworkName_impl;
}

[CRepr]
public struct CLUSTER_VALIDATE_CSV_FILENAME
{
	public char16* szFileName mut => &szFileName_impl;
	private char16[ANYSIZE_ARRAY] szFileName_impl;
}

[CRepr]
public struct CLUSTER_SET_PASSWORD_STATUS
{
	public uint32 NodeId;
	public BOOLEAN SetAttempted;
	public uint32 ReturnStatus;
}

[CRepr]
public struct CLUSTER_IP_ENTRY
{
	public PWSTR lpszIpAddress;
	public uint32 dwPrefixLength;
}

[CRepr]
public struct CREATE_CLUSTER_CONFIG
{
	public uint32 dwVersion;
	public PWSTR lpszClusterName;
	public uint32 cNodes;
	public PWSTR* ppszNodeNames;
	public uint32 cIpEntries;
	public CLUSTER_IP_ENTRY* pIpEntries;
	public BOOLEAN fEmptyCluster;
	public CLUSTER_MGMT_POINT_TYPE managementPointType;
	public CLUSTER_MGMT_POINT_RESTYPE managementPointResType;
}

[CRepr]
public struct CREATE_CLUSTER_NAME_ACCOUNT
{
	public uint32 dwVersion;
	public PWSTR lpszClusterName;
	public uint32 dwFlags;
	public PWSTR pszUserName;
	public PWSTR pszPassword;
	public PWSTR pszDomain;
	public CLUSTER_MGMT_POINT_TYPE managementPointType;
	public CLUSTER_MGMT_POINT_RESTYPE managementPointResType;
	public BOOLEAN bUpgradeVCOs;
}

[CRepr]
public struct NOTIFY_FILTER_AND_TYPE
{
	public uint32 dwObjectType;
	public int64 FilterFlags;
}

[CRepr]
public struct CLUSTER_MEMBERSHIP_INFO
{
	public BOOL HasQuorum;
	public uint32 UpnodesSize;
	public uint8* Upnodes mut => &Upnodes_impl;
	private uint8[ANYSIZE_ARRAY] Upnodes_impl;
}

[CRepr]
public struct CLUSTER_AVAILABILITY_SET_CONFIG
{
	public uint32 dwVersion;
	public uint32 dwUpdateDomains;
	public uint32 dwFaultDomains;
	public BOOL bReserveSpareNode;
}

[CRepr]
public struct CLUSTER_GROUP_ENUM_ITEM
{
	public uint32 dwVersion;
	public uint32 cbId;
	public PWSTR lpszId;
	public uint32 cbName;
	public PWSTR lpszName;
	public CLUSTER_GROUP_STATE state;
	public uint32 cbOwnerNode;
	public PWSTR lpszOwnerNode;
	public uint32 dwFlags;
	public uint32 cbProperties;
	public void* pProperties;
	public uint32 cbRoProperties;
	public void* pRoProperties;
}

[CRepr]
public struct CLUSTER_RESOURCE_ENUM_ITEM
{
	public uint32 dwVersion;
	public uint32 cbId;
	public PWSTR lpszId;
	public uint32 cbName;
	public PWSTR lpszName;
	public uint32 cbOwnerGroupName;
	public PWSTR lpszOwnerGroupName;
	public uint32 cbOwnerGroupId;
	public PWSTR lpszOwnerGroupId;
	public uint32 cbProperties;
	public void* pProperties;
	public uint32 cbRoProperties;
	public void* pRoProperties;
}

[CRepr]
public struct GROUP_FAILURE_INFO
{
	public uint32 dwFailoverAttemptsRemaining;
	public uint32 dwFailoverPeriodRemaining;
}

[CRepr]
public struct GROUP_FAILURE_INFO_BUFFER
{
	public uint32 dwVersion;
	public GROUP_FAILURE_INFO Info;
}

[CRepr]
public struct RESOURCE_FAILURE_INFO
{
	public uint32 dwRestartAttemptsRemaining;
	public uint32 dwRestartPeriodRemaining;
}

[CRepr]
public struct RESOURCE_FAILURE_INFO_BUFFER
{
	public uint32 dwVersion;
	public RESOURCE_FAILURE_INFO Info;
}

[CRepr]
public struct RESOURCE_TERMINAL_FAILURE_INFO_BUFFER
{
	public BOOL isTerminalFailure;
	public uint32 restartPeriodRemaining;
}

[CRepr, Union]
public struct CLUSPROP_SYNTAX
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint16 wFormat;
		public uint16 wType;
	}
	public uint32 dw;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr]
public struct CLUSPROP_VALUE
{
	public CLUSPROP_SYNTAX Syntax;
	public uint32 cbLength;
}

[CRepr]
public struct CLUSPROP_BINARY
{
	public CLUSPROP_VALUE Base;
	public uint8* rgb mut => &rgb_impl;
	private uint8[ANYSIZE_ARRAY] rgb_impl;
}

[CRepr]
public struct CLUSPROP_WORD
{
	public CLUSPROP_VALUE Base;
	public uint16 w;
}

[CRepr]
public struct CLUSPROP_DWORD
{
	public CLUSPROP_VALUE Base;
	public uint32 dw;
}

[CRepr]
public struct CLUSPROP_LONG
{
	public CLUSPROP_VALUE Base;
	public int32 l;
}

[CRepr]
public struct CLUSPROP_SZ
{
	public CLUSPROP_VALUE Base;
	public char16* sz mut => &sz_impl;
	private char16[ANYSIZE_ARRAY] sz_impl;
}

[CRepr]
public struct CLUSPROP_ULARGE_INTEGER
{
	public CLUSPROP_VALUE Base;
	public ULARGE_INTEGER li;
}

[CRepr]
public struct CLUSPROP_LARGE_INTEGER
{
	public CLUSPROP_VALUE Base;
	public LARGE_INTEGER li;
}

[CRepr]
public struct CLUSPROP_SECURITY_DESCRIPTOR
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public SECURITY_DESCRIPTOR_RELATIVE sd;
		public uint8* rgbSecurityDescriptor mut => &rgbSecurityDescriptor_impl;
		private uint8[ANYSIZE_ARRAY] rgbSecurityDescriptor_impl;
	}
	public CLUSPROP_VALUE Base;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CLUSPROP_FILETIME
{
	public CLUSPROP_VALUE Base;
	public FILETIME ft;
}

[CRepr]
public struct CLUS_RESOURCE_CLASS_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			[CRepr, Union]
			public struct _Anonymous_e__Union
			{
				public uint32 dw;
				public CLUSTER_RESOURCE_CLASS rc;
			}
			public using _Anonymous_e__Union Anonymous;
			public uint32 SubClass;
		}
		public using _Anonymous_e__Struct Anonymous;
		public ULARGE_INTEGER li;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CLUSPROP_RESOURCE_CLASS
{
	public CLUSPROP_VALUE Base;
	public CLUSTER_RESOURCE_CLASS rc;
}

[CRepr, Union]
public struct CLUSPROP_REQUIRED_DEPENDENCY
{
	public CLUSPROP_VALUE Value;
	public CLUSPROP_RESOURCE_CLASS ResClass;
	public CLUSPROP_SZ ResTypeName;
}

[CRepr]
public struct CLUS_FORCE_QUORUM_INFO
{
	public uint32 dwSize;
	public uint32 dwNodeBitMask;
	public uint32 dwMaxNumberofNodes;
	public char16* multiszNodeList mut => &multiszNodeList_impl;
	private char16[ANYSIZE_ARRAY] multiszNodeList_impl;
}

[CRepr]
public struct CLUS_PARTITION_INFO
{
	public uint32 dwFlags;
	public char16[260] szDeviceName;
	public char16[260] szVolumeLabel;
	public uint32 dwSerialNumber;
	public uint32 rgdwMaximumComponentLength;
	public uint32 dwFileSystemFlags;
	public char16[32] szFileSystem;
}

[CRepr]
public struct CLUS_PARTITION_INFO_EX
{
	public uint32 dwFlags;
	public char16[260] szDeviceName;
	public char16[260] szVolumeLabel;
	public uint32 dwSerialNumber;
	public uint32 rgdwMaximumComponentLength;
	public uint32 dwFileSystemFlags;
	public char16[32] szFileSystem;
	public ULARGE_INTEGER TotalSizeInBytes;
	public ULARGE_INTEGER FreeSizeInBytes;
	public uint32 DeviceNumber;
	public uint32 PartitionNumber;
	public Guid VolumeGuid;
}

[CRepr]
public struct CLUS_PARTITION_INFO_EX2
{
	public Guid GptPartitionId;
	public char16[260] szPartitionName;
	public uint32 EncryptionFlags;
}

[CRepr]
public struct CLUS_CSV_VOLUME_INFO
{
	public ULARGE_INTEGER VolumeOffset;
	public uint32 PartitionNumber;
	public CLUSTER_CSV_VOLUME_FAULT_STATE FaultState;
	public CLUSTER_SHARED_VOLUME_BACKUP_STATE BackupState;
	public char16[260] szVolumeFriendlyName;
	public char16[50] szVolumeName;
}

[CRepr]
public struct CLUS_CSV_VOLUME_NAME
{
	public LARGE_INTEGER VolumeOffset;
	public char16[260] szVolumeName;
	public char16[263] szRootPath;
}

[CRepr]
public struct CLUSTER_SHARED_VOLUME_STATE_INFO
{
	public char16[260] szVolumeName;
	public char16[260] szNodeName;
	public CLUSTER_SHARED_VOLUME_STATE VolumeState;
}

[CRepr]
public struct CLUSTER_SHARED_VOLUME_STATE_INFO_EX
{
	public char16[260] szVolumeName;
	public char16[260] szNodeName;
	public CLUSTER_SHARED_VOLUME_STATE VolumeState;
	public char16[260] szVolumeFriendlyName;
	public uint64 RedirectedIOReason;
	public uint64 VolumeRedirectedIOReason;
}

[CRepr]
public struct CLUSTER_SHARED_VOLUME_RENAME_INPUT_VOLUME
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint64 VolumeOffset;
		public char16[260] VolumeId;
		public char16[260] VolumeName;
		public char16[50] VolumeGuid;
	}
	public CLUSTER_SHARED_VOLUME_RENAME_INPUT_TYPE InputType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CLUSTER_SHARED_VOLUME_RENAME_INPUT_NAME
{
	public char16[260] NewVolumeName;
}

[CRepr]
public struct CLUSTER_SHARED_VOLUME_RENAME_INPUT_GUID_NAME
{
	public char16[260] NewVolumeName;
	public char16[50] NewVolumeGuid;
}

[CRepr]
public struct CLUS_CHKDSK_INFO
{
	public uint32 PartitionNumber;
	public uint32 ChkdskState;
	public uint32 FileIdCount;
	public uint64* FileIdList mut => &FileIdList_impl;
	private uint64[ANYSIZE_ARRAY] FileIdList_impl;
}

[CRepr]
public struct CLUS_DISK_NUMBER_INFO
{
	public uint32 DiskNumber;
	public uint32 BytesPerSector;
}

[CRepr]
public struct CLUS_SHARED_VOLUME_BACKUP_MODE
{
	public CLUSTER_SHARED_VOLUME_BACKUP_STATE BackupState;
	public uint32 DelayTimerInSecs;
	public char16[260] VolumeName;
}

[CRepr]
public struct CLUS_FTSET_INFO
{
	public uint32 dwRootSignature;
	public uint32 dwFtType;
}

[CRepr]
public struct CLUS_SCSI_ADDRESS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint8 PortNumber;
			public uint8 PathId;
			public uint8 TargetId;
			public uint8 Lun;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint32 dw;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CLUS_NETNAME_VS_TOKEN_INFO
{
	public uint32 ProcessID;
	public uint32 DesiredAccess;
	public BOOL InheritHandle;
}

[CRepr]
public struct CLUS_NETNAME_PWD_INFO
{
	public uint32 Flags;
	public char16[16] Password;
	public char16[258] CreatingDC;
	public char16[64] ObjectGuid;
}

[CRepr]
public struct CLUS_NETNAME_PWD_INFOEX
{
	public uint32 Flags;
	public char16[128] Password;
	public char16[258] CreatingDC;
	public char16[64] ObjectGuid;
}

[CRepr]
public struct CLUS_DNN_LEADER_STATUS
{
	public BOOL IsOnline;
	public BOOL IsFileServerPresent;
}

[CRepr]
public struct CLUS_DNN_SODAFS_CLONE_STATUS
{
	public uint32 NodeId;
	public CLUSTER_RESOURCE_STATE Status;
}

[CRepr]
public struct CLUS_NETNAME_IP_INFO_ENTRY
{
	public uint32 NodeId;
	public uint32 AddressSize;
	public uint8* Address mut => &Address_impl;
	private uint8[ANYSIZE_ARRAY] Address_impl;
}

[CRepr]
public struct CLUS_NETNAME_IP_INFO_FOR_MULTICHANNEL
{
	public char16[64] szName;
	public uint32 NumEntries;
	public CLUS_NETNAME_IP_INFO_ENTRY* IpInfo mut => &IpInfo_impl;
	private CLUS_NETNAME_IP_INFO_ENTRY[ANYSIZE_ARRAY] IpInfo_impl;
}

[CRepr]
public struct CLUS_MAINTENANCE_MODE_INFO
{
	public BOOL InMaintenance;
}

[CRepr]
public struct CLUS_CSV_MAINTENANCE_MODE_INFO
{
	public BOOL InMaintenance;
	public char16[260] VolumeName;
}

[CRepr]
public struct CLUS_MAINTENANCE_MODE_INFOEX
{
	public BOOL InMaintenance;
	public MAINTENANCE_MODE_TYPE_ENUM MaintainenceModeType;
	public CLUSTER_RESOURCE_STATE InternalState;
	public uint32 Signature;
}

[CRepr]
public struct CLUS_SET_MAINTENANCE_MODE_INPUT
{
	public BOOL InMaintenance;
	public uint32 ExtraParameterSize;
	public uint8* ExtraParameter mut => &ExtraParameter_impl;
	private uint8[ANYSIZE_ARRAY] ExtraParameter_impl;
}

[CRepr]
public struct CLUS_STORAGE_SET_DRIVELETTER
{
	public uint32 PartitionNumber;
	public uint32 DriveLetterMask;
}

[CRepr]
public struct CLUS_STORAGE_GET_AVAILABLE_DRIVELETTERS
{
	public uint32 AvailDrivelettersMask;
}

[CRepr]
public struct CLUS_STORAGE_REMAP_DRIVELETTER
{
	public uint32 CurrentDriveLetterMask;
	public uint32 TargetDriveLetterMask;
}

[CRepr]
public struct CLUS_PROVIDER_STATE_CHANGE_INFO
{
	public uint32 dwSize;
	public CLUSTER_RESOURCE_STATE resourceState;
	public char16* szProviderId mut => &szProviderId_impl;
	private char16[ANYSIZE_ARRAY] szProviderId_impl;
}

[CRepr]
public struct CLUS_CREATE_INFRASTRUCTURE_FILESERVER_INPUT
{
	public char16[16] FileServerName;
}

[CRepr]
public struct CLUS_CREATE_INFRASTRUCTURE_FILESERVER_OUTPUT
{
	public char16[260] FileServerName;
}

[CRepr]
public struct CLUSPROP_LIST
{
	public uint32 nPropertyCount;
	public CLUSPROP_SZ PropertyName;
}

[CRepr]
public struct FILESHARE_CHANGE
{
	public FILESHARE_CHANGE_ENUM Change;
	public char16[84] ShareName;
}

[CRepr]
public struct FILESHARE_CHANGE_LIST
{
	public uint32 NumEntries;
	public FILESHARE_CHANGE* ChangeEntry mut => &ChangeEntry_impl;
	private FILESHARE_CHANGE[ANYSIZE_ARRAY] ChangeEntry_impl;
}

[CRepr]
public struct CLUSCTL_GROUP_GET_LAST_MOVE_TIME_OUTPUT
{
	public uint64 GetTickCount64;
	public SYSTEMTIME GetSystemTime;
	public uint32 NodeId;
}

[CRepr, Union]
public struct CLUSPROP_BUFFER_HELPER
{
	public uint8* pb;
	public uint16* pw;
	public uint32* pdw;
	public int32* pl;
	public PWSTR psz;
	public CLUSPROP_LIST* pList;
	public CLUSPROP_SYNTAX* pSyntax;
	public CLUSPROP_SZ* pName;
	public CLUSPROP_VALUE* pValue;
	public CLUSPROP_BINARY* pBinaryValue;
	public CLUSPROP_WORD* pWordValue;
	public CLUSPROP_DWORD* pDwordValue;
	public CLUSPROP_LONG* pLongValue;
	public CLUSPROP_ULARGE_INTEGER* pULargeIntegerValue;
	public CLUSPROP_LARGE_INTEGER* pLargeIntegerValue;
	public CLUSPROP_SZ* pStringValue;
	public CLUSPROP_SZ* pMultiSzValue;
	public CLUSPROP_SECURITY_DESCRIPTOR* pSecurityDescriptor;
	public CLUSPROP_RESOURCE_CLASS* pResourceClassValue;
	public CLUSPROP_RESOURCE_CLASS_INFO* pResourceClassInfoValue;
	public CLUSPROP_DWORD* pDiskSignatureValue;
	public CLUSPROP_SCSI_ADDRESS* pScsiAddressValue;
	public CLUSPROP_DWORD* pDiskNumberValue;
	public CLUSPROP_PARTITION_INFO* pPartitionInfoValue;
	public CLUSPROP_REQUIRED_DEPENDENCY* pRequiredDependencyValue;
	public CLUSPROP_PARTITION_INFO_EX* pPartitionInfoValueEx;
	public CLUSPROP_PARTITION_INFO_EX2* pPartitionInfoValueEx2;
	public CLUSPROP_FILETIME* pFileTimeValue;
}

[CRepr]
public struct SR_RESOURCE_TYPE_REPLICATED_PARTITION_INFO
{
	public uint64 PartitionOffset;
	public uint32 Capabilities;
}

[CRepr]
public struct SR_RESOURCE_TYPE_REPLICATED_PARTITION_ARRAY
{
	public uint32 Count;
	public SR_RESOURCE_TYPE_REPLICATED_PARTITION_INFO* PartitionArray mut => &PartitionArray_impl;
	private SR_RESOURCE_TYPE_REPLICATED_PARTITION_INFO[ANYSIZE_ARRAY] PartitionArray_impl;
}

[CRepr]
public struct SR_RESOURCE_TYPE_QUERY_ELIGIBLE_LOGDISKS
{
	public Guid DataDiskGuid;
	public BOOLEAN IncludeOfflineDisks;
}

[CRepr]
public struct SR_RESOURCE_TYPE_QUERY_ELIGIBLE_TARGET_DATADISKS
{
	public Guid SourceDataDiskGuid;
	public Guid TargetReplicationGroupGuid;
	public BOOLEAN SkipConnectivityCheck;
	public BOOLEAN IncludeOfflineDisks;
}

[CRepr]
public struct SR_RESOURCE_TYPE_QUERY_ELIGIBLE_SOURCE_DATADISKS
{
	public Guid DataDiskGuid;
	public BOOLEAN IncludeAvailableStoargeDisks;
}

[CRepr]
public struct SR_RESOURCE_TYPE_DISK_INFO
{
	public SR_DISK_REPLICATION_ELIGIBLE Reason;
	public Guid DiskGuid;
}

[CRepr]
public struct SR_RESOURCE_TYPE_ELIGIBLE_DISKS_RESULT
{
	public uint16 Count;
	public SR_RESOURCE_TYPE_DISK_INFO* DiskInfo mut => &DiskInfo_impl;
	private SR_RESOURCE_TYPE_DISK_INFO[ANYSIZE_ARRAY] DiskInfo_impl;
}

[CRepr]
public struct SR_RESOURCE_TYPE_REPLICATED_DISK
{
	public SR_REPLICATED_DISK_TYPE Type;
	public Guid ClusterDiskResourceGuid;
	public Guid ReplicationGroupId;
	public char16[260] ReplicationGroupName;
}

[CRepr]
public struct SR_RESOURCE_TYPE_REPLICATED_DISKS_RESULT
{
	public uint16 Count;
	public SR_RESOURCE_TYPE_REPLICATED_DISK* ReplicatedDisks mut => &ReplicatedDisks_impl;
	private SR_RESOURCE_TYPE_REPLICATED_DISK[ANYSIZE_ARRAY] ReplicatedDisks_impl;
}

[CRepr]
public struct SR_RESOURCE_TYPE_ADD_REPLICATION_GROUP
{
	public char16[260] ReplicationGroupName;
	public char16[260] Description;
	public char16[260] LogPath;
	public uint64 MaxLogSizeInBytes;
	public uint16 LogType;
	public uint32 ReplicationMode;
	public uint32 MinimumPartnersInSync;
	public BOOLEAN EnableWriteConsistency;
	public BOOLEAN EnableEncryption;
	public char16[260] CertificateThumbprint;
	public uint32 VolumeNameCount;
	public char16[260] VolumeNames;
}

[CRepr]
public struct SR_RESOURCE_TYPE_ADD_REPLICATION_GROUP_RESULT
{
	public uint32 Result;
	public char16[260] ErrorString;
}

[CRepr]
public struct CLUSCTL_RESOURCE_TYPE_STORAGE_GET_AVAILABLE_DISKS_EX2_INPUT
{
	public uint32 dwFlags;
	public Guid guidPoolFilter;
}

[CRepr]
public struct RESOURCE_STATUS
{
	public CLUSTER_RESOURCE_STATE ResourceState;
	public uint32 CheckPoint;
	public uint32 WaitHint;
	public HANDLE EventHandle;
}

[CRepr]
public struct NodeUtilizationInfoElement
{
	public uint64 Id;
	public uint64 AvailableMemory;
	public uint64 AvailableMemoryAfterReclamation;
}

[CRepr]
public struct ResourceUtilizationInfoElement
{
	public uint64 PhysicalNumaId;
	public uint64 CurrentMemory;
}

[CRepr]
public struct GET_OPERATION_CONTEXT_PARAMS
{
	public uint32 Size;
	public uint32 Version;
	public RESDLL_CONTEXT_OPERATION_TYPE Type;
	public uint32 Priority;
}

[CRepr]
public struct RESOURCE_STATUS_EX
{
	public CLUSTER_RESOURCE_STATE ResourceState;
	public uint32 CheckPoint;
	public HANDLE EventHandle;
	public uint32 ApplicationSpecificErrorCode;
	public uint32 Flags;
	public uint32 WaitHint;
}

[CRepr]
public struct CLRES_V1_FUNCTIONS
{
	public POPEN_ROUTINE Open;
	public PCLOSE_ROUTINE Close;
	public PONLINE_ROUTINE Online;
	public POFFLINE_ROUTINE Offline;
	public PTERMINATE_ROUTINE Terminate;
	public PLOOKS_ALIVE_ROUTINE LooksAlive;
	public PIS_ALIVE_ROUTINE IsAlive;
	public PARBITRATE_ROUTINE Arbitrate;
	public PRELEASE_ROUTINE Release;
	public PRESOURCE_CONTROL_ROUTINE ResourceControl;
	public PRESOURCE_TYPE_CONTROL_ROUTINE ResourceTypeControl;
}

[CRepr]
public struct CLRES_V2_FUNCTIONS
{
	public POPEN_V2_ROUTINE Open;
	public PCLOSE_ROUTINE Close;
	public PONLINE_V2_ROUTINE Online;
	public POFFLINE_V2_ROUTINE Offline;
	public PTERMINATE_ROUTINE Terminate;
	public PLOOKS_ALIVE_ROUTINE LooksAlive;
	public PIS_ALIVE_ROUTINE IsAlive;
	public PARBITRATE_ROUTINE Arbitrate;
	public PRELEASE_ROUTINE Release;
	public PRESOURCE_CONTROL_ROUTINE ResourceControl;
	public PRESOURCE_TYPE_CONTROL_ROUTINE ResourceTypeControl;
	public PCANCEL_ROUTINE Cancel;
}

[CRepr]
public struct CLRES_V3_FUNCTIONS
{
	public POPEN_V2_ROUTINE Open;
	public PCLOSE_ROUTINE Close;
	public PONLINE_V2_ROUTINE Online;
	public POFFLINE_V2_ROUTINE Offline;
	public PTERMINATE_ROUTINE Terminate;
	public PLOOKS_ALIVE_ROUTINE LooksAlive;
	public PIS_ALIVE_ROUTINE IsAlive;
	public PARBITRATE_ROUTINE Arbitrate;
	public PRELEASE_ROUTINE Release;
	public PBEGIN_RESCALL_ROUTINE BeginResourceControl;
	public PBEGIN_RESTYPECALL_ROUTINE BeginResourceTypeControl;
	public PCANCEL_ROUTINE Cancel;
}

[CRepr]
public struct CLRES_V4_FUNCTIONS
{
	public POPEN_V2_ROUTINE Open;
	public PCLOSE_ROUTINE Close;
	public PONLINE_V2_ROUTINE Online;
	public POFFLINE_V2_ROUTINE Offline;
	public PTERMINATE_ROUTINE Terminate;
	public PLOOKS_ALIVE_ROUTINE LooksAlive;
	public PIS_ALIVE_ROUTINE IsAlive;
	public PARBITRATE_ROUTINE Arbitrate;
	public PRELEASE_ROUTINE Release;
	public PBEGIN_RESCALL_ROUTINE BeginResourceControl;
	public PBEGIN_RESTYPECALL_ROUTINE BeginResourceTypeControl;
	public PCANCEL_ROUTINE Cancel;
	public PBEGIN_RESCALL_AS_USER_ROUTINE BeginResourceControlAsUser;
	public PBEGIN_RESTYPECALL_AS_USER_ROUTINE BeginResourceTypeControlAsUser;
}

[CRepr]
public struct CLRES_FUNCTION_TABLE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public CLRES_V1_FUNCTIONS V1Functions;
		public CLRES_V2_FUNCTIONS V2Functions;
		public CLRES_V3_FUNCTIONS V3Functions;
		public CLRES_V4_FUNCTIONS V4Functions;
	}
	public uint32 TableSize;
	public uint32 Version;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct RESUTIL_LARGEINT_DATA
{
	public LARGE_INTEGER Default;
	public LARGE_INTEGER Minimum;
	public LARGE_INTEGER Maximum;
}

[CRepr]
public struct RESUTIL_ULARGEINT_DATA
{
	public ULARGE_INTEGER Default;
	public ULARGE_INTEGER Minimum;
	public ULARGE_INTEGER Maximum;
}

[CRepr]
public struct RESUTIL_FILETIME_DATA
{
	public FILETIME Default;
	public FILETIME Minimum;
	public FILETIME Maximum;
}

[CRepr]
public struct RESUTIL_PROPERTY_ITEM
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint DefaultPtr;
		public uint32 Default;
		public void* lpDefault;
		public RESUTIL_LARGEINT_DATA* LargeIntData;
		public RESUTIL_ULARGEINT_DATA* ULargeIntData;
		public RESUTIL_FILETIME_DATA* FileTimeData;
	}
	public PWSTR Name;
	public PWSTR KeyName;
	public uint32 Format;
	public using _Anonymous_e__Union Anonymous;
	public uint32 Minimum;
	public uint32 Maximum;
	public uint32 Flags;
	public uint32 Offset;
}

[CRepr]
public struct CLRES_CALLBACK_FUNCTION_TABLE
{
	public PLOG_EVENT_ROUTINE LogEvent;
	public PSET_RESOURCE_STATUS_ROUTINE_EX SetResourceStatusEx;
	public PSET_RESOURCE_LOCKED_MODE_ROUTINE SetResourceLockedMode;
	public PSIGNAL_FAILURE_ROUTINE SignalFailure;
	public PSET_RESOURCE_INMEMORY_NODELOCAL_PROPERTIES_ROUTINE SetResourceInMemoryNodeLocalProperties;
	public PEND_CONTROL_CALL EndControlCall;
	public PEND_TYPE_CONTROL_CALL EndTypeControlCall;
	public PEXTEND_RES_CONTROL_CALL ExtendControlCall;
	public PEXTEND_RES_TYPE_CONTROL_CALL ExtendTypeControlCall;
	public PRAISE_RES_TYPE_NOTIFICATION RaiseResTypeNotification;
	public PCHANGE_RESOURCE_PROCESS_FOR_DUMPS ChangeResourceProcessForDumps;
	public PCHANGE_RES_TYPE_PROCESS_FOR_DUMPS ChangeResTypeProcessForDumps;
	public PSET_INTERNAL_STATE SetInternalState;
	public PSET_RESOURCE_LOCKED_MODE_EX_ROUTINE SetResourceLockedModeEx;
	public PREQUEST_DUMP_ROUTINE RequestDump;
}

[CRepr]
public struct MONITOR_STATE
{
	public LARGE_INTEGER LastUpdate;
	public RESOURCE_MONITOR_STATE State;
	public HANDLE ActiveResource;
	public BOOL ResmonStop;
}

[CRepr]
public struct POST_UPGRADE_VERSION_INFO
{
	public uint32 newMajorVersion;
	public uint32 newUpgradeVersion;
	public uint32 oldMajorVersion;
	public uint32 oldUpgradeVersion;
	public uint32 reserved;
}

[CRepr]
public struct CLUSTER_HEALTH_FAULT
{
	public PWSTR Id;
	public uint32 ErrorType;
	public uint32 ErrorCode;
	public PWSTR Description;
	public PWSTR Provider;
	public uint32 Flags;
	public uint32 Reserved;
}

[CRepr]
public struct CLUSTER_HEALTH_FAULT_ARRAY
{
	public uint32 numFaults;
	public CLUSTER_HEALTH_FAULT* faults;
}

[CRepr]
public struct CLUS_WORKER
{
	public HANDLE hThread;
	public BOOL Terminate;
}

[CRepr]
public struct _HCLUSCRYPTPROVIDER
{
}

[CRepr]
public struct PaxosTagCStruct
{
	public uint64 __padding__PaxosTagVtable;
	public uint64 __padding__NextEpochVtable;
	public uint64 __padding__NextEpoch_DateTimeVtable;
	public uint64 NextEpoch_DateTime_ticks;
	public int32 NextEpoch_Value;
	public uint32 __padding__BoundryNextEpoch;
	public uint64 __padding__EpochVtable;
	public uint64 __padding__Epoch_DateTimeVtable;
	public uint64 Epoch_DateTime_ticks;
	public int32 Epoch_Value;
	public uint32 __padding__BoundryEpoch;
	public int32 Sequence;
	public uint32 __padding__BoundrySequence;
}

[CRepr]
public struct WitnessTagUpdateHelper
{
	public int32 Version;
	public PaxosTagCStruct paxosToSet;
	public PaxosTagCStruct paxosToValidate;
}

[CRepr]
public struct WitnessTagHelper
{
	public int32 Version;
	public PaxosTagCStruct paxosToValidate;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_ClusApplication = .(0xf2e606e5, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_Cluster = .(0xf2e606e3, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusVersion = .(0xf2e60715, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusResType = .(0xf2e6070f, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusProperty = .(0xf2e606fd, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusProperties = .(0xf2e606ff, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_DomainNames = .(0xf2e606e1, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusNetwork = .(0xf2e606f1, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusNetInterface = .(0xf2e606ed, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusNetInterfaces = .(0xf2e606ef, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusResDependencies = .(0xf2e60703, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusResGroupResources = .(0xf2e606e9, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusResTypeResources = .(0xf2e60713, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusResGroupPreferredOwnerNodes = .(0xf2e606e7, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusResPossibleOwnerNodes = .(0xf2e6070d, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusNetworks = .(0xf2e606f3, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusNetworkNetInterfaces = .(0xf2e606f5, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusNodeNetInterfaces = .(0xf2e606fb, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusRefObject = .(0xf2e60701, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusterNames = .(0xf2e606eb, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusNode = .(0xf2e606f7, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusNodes = .(0xf2e606f9, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusResGroup = .(0xf2e60705, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusResGroups = .(0xf2e60707, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusResource = .(0xf2e60709, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusResources = .(0xf2e6070b, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusResTypes = .(0xf2e60711, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusResTypePossibleOwnerNodes = .(0xf2e60717, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusPropertyValue = .(0xf2e60719, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusPropertyValues = .(0xf2e6071b, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusPropertyValueData = .(0xf2e6071d, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusPartition = .(0xf2e6071f, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusPartitionEx = .(0x53d51d26, 0xb51b, 0x4a79, 0xb2, 0xc3, 0x50, 0x48, 0xd9, 0x3a, 0x98, 0xfc);


	public const Guid CLSID_ClusPartitions = .(0xf2e60721, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusDisk = .(0xf2e60723, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusDisks = .(0xf2e60725, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusScsiAddress = .(0xf2e60727, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusRegistryKeys = .(0xf2e60729, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusCryptoKeys = .(0xf2e6072b, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


	public const Guid CLSID_ClusResDependents = .(0xf2e6072d, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);


}
#endregion

#region COM Types
[CRepr]struct IGetClusterUIInfo : IUnknown
{
	public new const Guid IID = .(0x97dede50, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR lpszName, int32* pcchName) GetClusterName;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetLocale;
		protected new function [CallingConvention(.Stdcall)] HFONT(SelfOuter* self) GetFont;
		protected new function [CallingConvention(.Stdcall)] HICON(SelfOuter* self) GetIcon;
	}


	public HRESULT GetClusterName(BSTR lpszName, int32* pcchName) mut => VT.[Friend]GetClusterName(&this, lpszName, pcchName);

	public uint32 GetLocale() mut => VT.[Friend]GetLocale(&this);

	public HFONT GetFont() mut => VT.[Friend]GetFont(&this);

	public HICON GetIcon() mut => VT.[Friend]GetIcon(&this);
}

[CRepr]struct IGetClusterDataInfo : IUnknown
{
	public new const Guid IID = .(0x97dede51, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR lpszName, int32* pcchName) GetClusterName;
		protected new function [CallingConvention(.Stdcall)] _HCLUSTER*(SelfOuter* self) GetClusterHandle;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self) GetObjectCount;
	}


	public HRESULT GetClusterName(BSTR lpszName, int32* pcchName) mut => VT.[Friend]GetClusterName(&this, lpszName, pcchName);

	public _HCLUSTER* GetClusterHandle() mut => VT.[Friend]GetClusterHandle(&this);

	public int32 GetObjectCount() mut => VT.[Friend]GetObjectCount(&this);
}

[CRepr]struct IGetClusterObjectInfo : IUnknown
{
	public new const Guid IID = .(0x97dede52, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lObjIndex, BSTR lpszName, int32* pcchName) GetObjectName;
		protected new function [CallingConvention(.Stdcall)] CLUADMEX_OBJECT_TYPE(SelfOuter* self, int32 lObjIndex) GetObjectType;
	}


	public HRESULT GetObjectName(int32 lObjIndex, BSTR lpszName, int32* pcchName) mut => VT.[Friend]GetObjectName(&this, lObjIndex, lpszName, pcchName);

	public CLUADMEX_OBJECT_TYPE GetObjectType(int32 lObjIndex) mut => VT.[Friend]GetObjectType(&this, lObjIndex);
}

[CRepr]struct IGetClusterNodeInfo : IUnknown
{
	public new const Guid IID = .(0x97dede53, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] _HNODE*(SelfOuter* self, int32 lObjIndex) GetNodeHandle;
	}


	public _HNODE* GetNodeHandle(int32 lObjIndex) mut => VT.[Friend]GetNodeHandle(&this, lObjIndex);
}

[CRepr]struct IGetClusterGroupInfo : IUnknown
{
	public new const Guid IID = .(0x97dede54, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] _HGROUP*(SelfOuter* self, int32 lObjIndex) GetGroupHandle;
	}


	public _HGROUP* GetGroupHandle(int32 lObjIndex) mut => VT.[Friend]GetGroupHandle(&this, lObjIndex);
}

[CRepr]struct IGetClusterResourceInfo : IUnknown
{
	public new const Guid IID = .(0x97dede55, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] _HRESOURCE*(SelfOuter* self, int32 lObjIndex) GetResourceHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lObjIndex, BSTR lpszResTypeName, int32* pcchResTypeName) GetResourceTypeName;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self, int32 lObjIndex, BSTR lpszNetName, uint32* pcchNetName) GetResourceNetworkName;
	}


	public _HRESOURCE* GetResourceHandle(int32 lObjIndex) mut => VT.[Friend]GetResourceHandle(&this, lObjIndex);

	public HRESULT GetResourceTypeName(int32 lObjIndex, BSTR lpszResTypeName, int32* pcchResTypeName) mut => VT.[Friend]GetResourceTypeName(&this, lObjIndex, lpszResTypeName, pcchResTypeName);

	public BOOL GetResourceNetworkName(int32 lObjIndex, BSTR lpszNetName, uint32* pcchNetName) mut => VT.[Friend]GetResourceNetworkName(&this, lObjIndex, lpszNetName, pcchNetName);
}

[CRepr]struct IGetClusterNetworkInfo : IUnknown
{
	public new const Guid IID = .(0x97dede56, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] _HNETWORK*(SelfOuter* self, int32 lObjIndex) GetNetworkHandle;
	}


	public _HNETWORK* GetNetworkHandle(int32 lObjIndex) mut => VT.[Friend]GetNetworkHandle(&this, lObjIndex);
}

[CRepr]struct IGetClusterNetInterfaceInfo : IUnknown
{
	public new const Guid IID = .(0x97dede57, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] _HNETINTERFACE*(SelfOuter* self, int32 lObjIndex) GetNetInterfaceHandle;
	}


	public _HNETINTERFACE* GetNetInterfaceHandle(int32 lObjIndex) mut => VT.[Friend]GetNetInterfaceHandle(&this, lObjIndex);
}

[CRepr]struct IWCPropertySheetCallback : IUnknown
{
	public new const Guid IID = .(0x97dede60, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* hpage) AddPropertySheetPage;
	}


	public HRESULT AddPropertySheetPage(int32* hpage) mut => VT.[Friend]AddPropertySheetPage(&this, hpage);
}

[CRepr]struct IWEExtendPropertySheet : IUnknown
{
	public new const Guid IID = .(0x97dede61, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* piData, IWCPropertySheetCallback* piCallback) CreatePropertySheetPages;
	}


	public HRESULT CreatePropertySheetPages(IUnknown* piData, IWCPropertySheetCallback* piCallback) mut => VT.[Friend]CreatePropertySheetPages(&this, piData, piCallback);
}

[CRepr]struct IWCWizardCallback : IUnknown
{
	public new const Guid IID = .(0x97dede62, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* hpage) AddWizardPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* hpage, BOOL bEnable) EnableNext;
	}


	public HRESULT AddWizardPage(int32* hpage) mut => VT.[Friend]AddWizardPage(&this, hpage);

	public HRESULT EnableNext(int32* hpage, BOOL bEnable) mut => VT.[Friend]EnableNext(&this, hpage, bEnable);
}

[CRepr]struct IWEExtendWizard : IUnknown
{
	public new const Guid IID = .(0x97dede63, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* piData, IWCWizardCallback* piCallback) CreateWizardPages;
	}


	public HRESULT CreateWizardPages(IUnknown* piData, IWCWizardCallback* piCallback) mut => VT.[Friend]CreateWizardPages(&this, piData, piCallback);
}

[CRepr]struct IWCContextMenuCallback : IUnknown
{
	public new const Guid IID = .(0x97dede64, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR lpszName, BSTR lpszStatusBarText, uint32 nCommandID, uint32 nSubmenuCommandID, uint32 uFlags) AddExtensionMenuItem;
	}


	public HRESULT AddExtensionMenuItem(BSTR lpszName, BSTR lpszStatusBarText, uint32 nCommandID, uint32 nSubmenuCommandID, uint32 uFlags) mut => VT.[Friend]AddExtensionMenuItem(&this, lpszName, lpszStatusBarText, nCommandID, nSubmenuCommandID, uFlags);
}

[CRepr]struct IWEExtendContextMenu : IUnknown
{
	public new const Guid IID = .(0x97dede65, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* piData, IWCContextMenuCallback* piCallback) AddContextMenuItems;
	}


	public HRESULT AddContextMenuItems(IUnknown* piData, IWCContextMenuCallback* piCallback) mut => VT.[Friend]AddContextMenuItems(&this, piData, piCallback);
}

[CRepr]struct IWEInvokeCommand : IUnknown
{
	public new const Guid IID = .(0x97dede66, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nCommandID, IUnknown* piData) InvokeCommand;
	}


	public HRESULT InvokeCommand(uint32 nCommandID, IUnknown* piData) mut => VT.[Friend]InvokeCommand(&this, nCommandID, piData);
}

[CRepr]struct IWCWizard97Callback : IUnknown
{
	public new const Guid IID = .(0x97dede67, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* hpage) AddWizard97Page;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* hpage, BOOL bEnable) EnableNext;
	}


	public HRESULT AddWizard97Page(int32* hpage) mut => VT.[Friend]AddWizard97Page(&this, hpage);

	public HRESULT EnableNext(int32* hpage, BOOL bEnable) mut => VT.[Friend]EnableNext(&this, hpage, bEnable);
}

[CRepr]struct IWEExtendWizard97 : IUnknown
{
	public new const Guid IID = .(0x97dede68, 0xfc6b, 0x11cf, 0xb5, 0xf5, 0x00, 0xa0, 0xc9, 0x0a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* piData, IWCWizard97Callback* piCallback) CreateWizard97Pages;
	}


	public HRESULT CreateWizard97Pages(IUnknown* piData, IWCWizard97Callback* piCallback) mut => VT.[Friend]CreateWizard97Pages(&this, piData, piCallback);
}

[CRepr]struct ISClusApplication : IDispatch
{
	public new const Guid IID = .(0xf2e606e6, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISDomainNames** ppDomains) get_DomainNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDomainName, ISClusterNames** ppClusters) get_ClusterNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrClusterName, ISCluster** pCluster) OpenCluster;
	}


	public HRESULT get_DomainNames(ISDomainNames** ppDomains) mut => VT.[Friend]get_DomainNames(&this, ppDomains);

	public HRESULT get_ClusterNames(BSTR bstrDomainName, ISClusterNames** ppClusters) mut => VT.[Friend]get_ClusterNames(&this, bstrDomainName, ppClusters);

	public HRESULT OpenCluster(BSTR bstrClusterName, ISCluster** pCluster) mut => VT.[Friend]OpenCluster(&this, bstrClusterName, pCluster);
}

[CRepr]struct ISDomainNames : IDispatch
{
	public new const Guid IID = .(0xf2e606e2, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, BSTR* pbstrDomainName) get_Item;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, BSTR* pbstrDomainName) mut => VT.[Friend]get_Item(&this, varIndex, pbstrDomainName);
}

[CRepr]struct ISClusterNames : IDispatch
{
	public new const Guid IID = .(0xf2e606ec, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, BSTR* pbstrClusterName) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDomainName) get_DomainName;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, BSTR* pbstrClusterName) mut => VT.[Friend]get_Item(&this, varIndex, pbstrClusterName);

	public HRESULT get_DomainName(BSTR* pbstrDomainName) mut => VT.[Friend]get_DomainName(&this, pbstrDomainName);
}

[CRepr]struct ISClusRefObject : IDispatch
{
	public new const Guid IID = .(0xf2e60702, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* phandle) get_Handle;
	}


	public HRESULT get_Handle(uint* phandle) mut => VT.[Friend]get_Handle(&this, phandle);
}

[CRepr]struct ISClusVersion : IDispatch
{
	public new const Guid IID = .(0xf2e60716, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrClusterName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pnMajorVersion) get_MajorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pnMinorVersion) get_MinorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pnBuildNumber) get_BuildNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrVendorId) get_VendorId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCSDVersion) get_CSDVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pnClusterHighestVersion) get_ClusterHighestVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pnClusterLowestVersion) get_ClusterLowestVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pnFlags) get_Flags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarMixedVersion) get_MixedVersion;
	}


	public HRESULT get_Name(BSTR* pbstrClusterName) mut => VT.[Friend]get_Name(&this, pbstrClusterName);

	public HRESULT get_MajorVersion(int32* pnMajorVersion) mut => VT.[Friend]get_MajorVersion(&this, pnMajorVersion);

	public HRESULT get_MinorVersion(int32* pnMinorVersion) mut => VT.[Friend]get_MinorVersion(&this, pnMinorVersion);

	public HRESULT get_BuildNumber(int16* pnBuildNumber) mut => VT.[Friend]get_BuildNumber(&this, pnBuildNumber);

	public HRESULT get_VendorId(BSTR* pbstrVendorId) mut => VT.[Friend]get_VendorId(&this, pbstrVendorId);

	public HRESULT get_CSDVersion(BSTR* pbstrCSDVersion) mut => VT.[Friend]get_CSDVersion(&this, pbstrCSDVersion);

	public HRESULT get_ClusterHighestVersion(int32* pnClusterHighestVersion) mut => VT.[Friend]get_ClusterHighestVersion(&this, pnClusterHighestVersion);

	public HRESULT get_ClusterLowestVersion(int32* pnClusterLowestVersion) mut => VT.[Friend]get_ClusterLowestVersion(&this, pnClusterLowestVersion);

	public HRESULT get_Flags(int32* pnFlags) mut => VT.[Friend]get_Flags(&this, pnFlags);

	public HRESULT get_MixedVersion(VARIANT* pvarMixedVersion) mut => VT.[Friend]get_MixedVersion(&this, pvarMixedVersion);
}

[CRepr]struct ISCluster : IDispatch
{
	public new const Guid IID = .(0xf2e606e4, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* phandle) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrClusterName) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrClusterName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusVersion** ppClusVersion) get_Version;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResource* pClusterResource) put_QuorumResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResource** pClusterResource) get_QuorumResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pnLogSize) get_QuorumLogSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nLogSize) put_QuorumLogSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* ppPath) get_QuorumPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pPath) put_QuorumPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusNodes** ppNodes) get_Nodes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResGroups** ppClusterResourceGroups) get_ResourceGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResources** ppClusterResources) get_Resources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResTypes** ppResourceTypes) get_ResourceTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusNetworks** ppNetworks) get_Networks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusNetInterfaces** ppNetInterfaces) get_NetInterfaces;
	}


	public HRESULT get_CommonProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonProperties(&this, ppProperties);

	public HRESULT get_PrivateProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateProperties(&this, ppProperties);

	public HRESULT get_CommonROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonROProperties(&this, ppProperties);

	public HRESULT get_PrivateROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateROProperties(&this, ppProperties);

	public HRESULT get_Handle(uint* phandle) mut => VT.[Friend]get_Handle(&this, phandle);

	public HRESULT Open(BSTR bstrClusterName) mut => VT.[Friend]Open(&this, bstrClusterName);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT put_Name(BSTR bstrClusterName) mut => VT.[Friend]put_Name(&this, bstrClusterName);

	public HRESULT get_Version(ISClusVersion** ppClusVersion) mut => VT.[Friend]get_Version(&this, ppClusVersion);

	public HRESULT put_QuorumResource(ISClusResource* pClusterResource) mut => VT.[Friend]put_QuorumResource(&this, pClusterResource);

	public HRESULT get_QuorumResource(ISClusResource** pClusterResource) mut => VT.[Friend]get_QuorumResource(&this, pClusterResource);

	public HRESULT get_QuorumLogSize(int32* pnLogSize) mut => VT.[Friend]get_QuorumLogSize(&this, pnLogSize);

	public HRESULT put_QuorumLogSize(int32 nLogSize) mut => VT.[Friend]put_QuorumLogSize(&this, nLogSize);

	public HRESULT get_QuorumPath(BSTR* ppPath) mut => VT.[Friend]get_QuorumPath(&this, ppPath);

	public HRESULT put_QuorumPath(BSTR pPath) mut => VT.[Friend]put_QuorumPath(&this, pPath);

	public HRESULT get_Nodes(ISClusNodes** ppNodes) mut => VT.[Friend]get_Nodes(&this, ppNodes);

	public HRESULT get_ResourceGroups(ISClusResGroups** ppClusterResourceGroups) mut => VT.[Friend]get_ResourceGroups(&this, ppClusterResourceGroups);

	public HRESULT get_Resources(ISClusResources** ppClusterResources) mut => VT.[Friend]get_Resources(&this, ppClusterResources);

	public HRESULT get_ResourceTypes(ISClusResTypes** ppResourceTypes) mut => VT.[Friend]get_ResourceTypes(&this, ppResourceTypes);

	public HRESULT get_Networks(ISClusNetworks** ppNetworks) mut => VT.[Friend]get_Networks(&this, ppNetworks);

	public HRESULT get_NetInterfaces(ISClusNetInterfaces** ppNetInterfaces) mut => VT.[Friend]get_NetInterfaces(&this, ppNetInterfaces);
}

[CRepr]struct ISClusNode : IDispatch
{
	public new const Guid IID = .(0xf2e606f8, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* phandle) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrNodeID) get_NodeID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_NODE_STATE* dwState) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Evict;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResGroups** ppResourceGroups) get_ResourceGroups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISCluster** ppCluster) get_Cluster;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusNodeNetInterfaces** ppClusNetInterfaces) get_NetInterfaces;
	}


	public HRESULT get_CommonProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonProperties(&this, ppProperties);

	public HRESULT get_PrivateProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateProperties(&this, ppProperties);

	public HRESULT get_CommonROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonROProperties(&this, ppProperties);

	public HRESULT get_PrivateROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateROProperties(&this, ppProperties);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT get_Handle(uint* phandle) mut => VT.[Friend]get_Handle(&this, phandle);

	public HRESULT get_NodeID(BSTR* pbstrNodeID) mut => VT.[Friend]get_NodeID(&this, pbstrNodeID);

	public HRESULT get_State(CLUSTER_NODE_STATE* dwState) mut => VT.[Friend]get_State(&this, dwState);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public HRESULT Evict() mut => VT.[Friend]Evict(&this);

	public HRESULT get_ResourceGroups(ISClusResGroups** ppResourceGroups) mut => VT.[Friend]get_ResourceGroups(&this, ppResourceGroups);

	public HRESULT get_Cluster(ISCluster** ppCluster) mut => VT.[Friend]get_Cluster(&this, ppCluster);

	public HRESULT get_NetInterfaces(ISClusNodeNetInterfaces** ppClusNetInterfaces) mut => VT.[Friend]get_NetInterfaces(&this, ppClusNetInterfaces);
}

[CRepr]struct ISClusNodes : IDispatch
{
	public new const Guid IID = .(0xf2e606fa, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusNode** ppNode) get_Item;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusNode** ppNode) mut => VT.[Friend]get_Item(&this, varIndex, ppNode);
}

[CRepr]struct ISClusNetwork : IDispatch
{
	public new const Guid IID = .(0xf2e606f2, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* phandle) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrNetworkName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrNetworkID) get_NetworkID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_NETWORK_STATE* dwState) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusNetworkNetInterfaces** ppClusNetInterfaces) get_NetInterfaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISCluster** ppCluster) get_Cluster;
	}


	public HRESULT get_CommonProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonProperties(&this, ppProperties);

	public HRESULT get_PrivateProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateProperties(&this, ppProperties);

	public HRESULT get_CommonROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonROProperties(&this, ppProperties);

	public HRESULT get_PrivateROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateROProperties(&this, ppProperties);

	public HRESULT get_Handle(uint* phandle) mut => VT.[Friend]get_Handle(&this, phandle);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT put_Name(BSTR bstrNetworkName) mut => VT.[Friend]put_Name(&this, bstrNetworkName);

	public HRESULT get_NetworkID(BSTR* pbstrNetworkID) mut => VT.[Friend]get_NetworkID(&this, pbstrNetworkID);

	public HRESULT get_State(CLUSTER_NETWORK_STATE* dwState) mut => VT.[Friend]get_State(&this, dwState);

	public HRESULT get_NetInterfaces(ISClusNetworkNetInterfaces** ppClusNetInterfaces) mut => VT.[Friend]get_NetInterfaces(&this, ppClusNetInterfaces);

	public HRESULT get_Cluster(ISCluster** ppCluster) mut => VT.[Friend]get_Cluster(&this, ppCluster);
}

[CRepr]struct ISClusNetworks : IDispatch
{
	public new const Guid IID = .(0xf2e606f4, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusNetwork** ppClusNetwork) get_Item;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusNetwork** ppClusNetwork) mut => VT.[Friend]get_Item(&this, varIndex, ppClusNetwork);
}

[CRepr]struct ISClusNetInterface : IDispatch
{
	public new const Guid IID = .(0xf2e606ee, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* phandle) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_NETINTERFACE_STATE* dwState) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISCluster** ppCluster) get_Cluster;
	}


	public HRESULT get_CommonProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonProperties(&this, ppProperties);

	public HRESULT get_PrivateProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateProperties(&this, ppProperties);

	public HRESULT get_CommonROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonROProperties(&this, ppProperties);

	public HRESULT get_PrivateROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateROProperties(&this, ppProperties);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT get_Handle(uint* phandle) mut => VT.[Friend]get_Handle(&this, phandle);

	public HRESULT get_State(CLUSTER_NETINTERFACE_STATE* dwState) mut => VT.[Friend]get_State(&this, dwState);

	public HRESULT get_Cluster(ISCluster** ppCluster) mut => VT.[Friend]get_Cluster(&this, ppCluster);
}

[CRepr]struct ISClusNetInterfaces : IDispatch
{
	public new const Guid IID = .(0xf2e606f0, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusNetInterface** ppClusNetInterface) get_Item;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusNetInterface** ppClusNetInterface) mut => VT.[Friend]get_Item(&this, varIndex, ppClusNetInterface);
}

[CRepr]struct ISClusNodeNetInterfaces : IDispatch
{
	public new const Guid IID = .(0xf2e606fc, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusNetInterface** ppClusNetInterface) get_Item;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusNetInterface** ppClusNetInterface) mut => VT.[Friend]get_Item(&this, varIndex, ppClusNetInterface);
}

[CRepr]struct ISClusNetworkNetInterfaces : IDispatch
{
	public new const Guid IID = .(0xf2e606f6, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusNetInterface** ppClusNetInterface) get_Item;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusNetInterface** ppClusNetInterface) mut => VT.[Friend]get_Item(&this, varIndex, ppClusNetInterface);
}

[CRepr]struct ISClusResGroup : IDispatch
{
	public new const Guid IID = .(0xf2e60706, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* phandle) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGroupName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_GROUP_STATE* dwState) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusNode** ppOwnerNode) get_OwnerNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResGroupResources** ppClusterGroupResources) get_Resources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResGroupPreferredOwnerNodes** ppOwnerNodes) get_PreferredOwnerNodes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varTimeout, VARIANT varNode, VARIANT* pvarPending) Online;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varTimeout, VARIANT varNode, VARIANT* pvarPending) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varTimeout, VARIANT* pvarPending) Offline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISCluster** ppCluster) get_Cluster;
	}


	public HRESULT get_CommonProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonProperties(&this, ppProperties);

	public HRESULT get_PrivateProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateProperties(&this, ppProperties);

	public HRESULT get_CommonROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonROProperties(&this, ppProperties);

	public HRESULT get_PrivateROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateROProperties(&this, ppProperties);

	public HRESULT get_Handle(uint* phandle) mut => VT.[Friend]get_Handle(&this, phandle);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT put_Name(BSTR bstrGroupName) mut => VT.[Friend]put_Name(&this, bstrGroupName);

	public HRESULT get_State(CLUSTER_GROUP_STATE* dwState) mut => VT.[Friend]get_State(&this, dwState);

	public HRESULT get_OwnerNode(ISClusNode** ppOwnerNode) mut => VT.[Friend]get_OwnerNode(&this, ppOwnerNode);

	public HRESULT get_Resources(ISClusResGroupResources** ppClusterGroupResources) mut => VT.[Friend]get_Resources(&this, ppClusterGroupResources);

	public HRESULT get_PreferredOwnerNodes(ISClusResGroupPreferredOwnerNodes** ppOwnerNodes) mut => VT.[Friend]get_PreferredOwnerNodes(&this, ppOwnerNodes);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Online(VARIANT varTimeout, VARIANT varNode, VARIANT* pvarPending) mut => VT.[Friend]Online(&this, varTimeout, varNode, pvarPending);

	public HRESULT Move(VARIANT varTimeout, VARIANT varNode, VARIANT* pvarPending) mut => VT.[Friend]Move(&this, varTimeout, varNode, pvarPending);

	public HRESULT Offline(VARIANT varTimeout, VARIANT* pvarPending) mut => VT.[Friend]Offline(&this, varTimeout, pvarPending);

	public HRESULT get_Cluster(ISCluster** ppCluster) mut => VT.[Friend]get_Cluster(&this, ppCluster);
}

[CRepr]struct ISClusResGroups : IDispatch
{
	public new const Guid IID = .(0xf2e60708, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusResGroup** ppClusResGroup) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrResourceGroupName, ISClusResGroup** ppResourceGroup) CreateItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) DeleteItem;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusResGroup** ppClusResGroup) mut => VT.[Friend]get_Item(&this, varIndex, ppClusResGroup);

	public HRESULT CreateItem(BSTR bstrResourceGroupName, ISClusResGroup** ppResourceGroup) mut => VT.[Friend]CreateItem(&this, bstrResourceGroupName, ppResourceGroup);

	public HRESULT DeleteItem(VARIANT varIndex) mut => VT.[Friend]DeleteItem(&this, varIndex);
}

[CRepr]struct ISClusResource : IDispatch
{
	public new const Guid IID = .(0xf2e6070a, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint* phandle) get_Handle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrResourceName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_RESOURCE_STATE* dwState) get_State;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUS_FLAGS* dwCoreFlag) get_CoreFlag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDevicePath, int32 lMaxLogSize) BecomeQuorumResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Fail;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nTimeout, VARIANT* pvarPending) Online;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nTimeout, VARIANT* pvarPending) Offline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResGroup* pResourceGroup) ChangeResourceGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusNode* pNode) AddResourceNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusNode* pNode) RemoveResourceNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResource* pResource, VARIANT* pvarDependent) CanResourceBeDependent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResPossibleOwnerNodes** ppOwnerNodes) get_PossibleOwnerNodes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResDependencies** ppResDependencies) get_Dependencies;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResDependents** ppResDependents) get_Dependents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResGroup** ppResGroup) get_Group;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusNode** ppOwnerNode) get_OwnerNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISCluster** ppCluster) get_Cluster;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_RESOURCE_CLASS* prcClassInfo) get_ClassInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusDisk** ppDisk) get_Disk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusRegistryKeys** ppRegistryKeys) get_RegistryKeys;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusCryptoKeys** ppCryptoKeys) get_CryptoKeys;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTypeName) get_TypeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResType** ppResourceType) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbMaintenanceMode) get_MaintenanceMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bMaintenanceMode) put_MaintenanceMode;
	}


	public HRESULT get_CommonProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonProperties(&this, ppProperties);

	public HRESULT get_PrivateProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateProperties(&this, ppProperties);

	public HRESULT get_CommonROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonROProperties(&this, ppProperties);

	public HRESULT get_PrivateROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateROProperties(&this, ppProperties);

	public HRESULT get_Handle(uint* phandle) mut => VT.[Friend]get_Handle(&this, phandle);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT put_Name(BSTR bstrResourceName) mut => VT.[Friend]put_Name(&this, bstrResourceName);

	public HRESULT get_State(CLUSTER_RESOURCE_STATE* dwState) mut => VT.[Friend]get_State(&this, dwState);

	public HRESULT get_CoreFlag(CLUS_FLAGS* dwCoreFlag) mut => VT.[Friend]get_CoreFlag(&this, dwCoreFlag);

	public HRESULT BecomeQuorumResource(BSTR bstrDevicePath, int32 lMaxLogSize) mut => VT.[Friend]BecomeQuorumResource(&this, bstrDevicePath, lMaxLogSize);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Fail() mut => VT.[Friend]Fail(&this);

	public HRESULT Online(int32 nTimeout, VARIANT* pvarPending) mut => VT.[Friend]Online(&this, nTimeout, pvarPending);

	public HRESULT Offline(int32 nTimeout, VARIANT* pvarPending) mut => VT.[Friend]Offline(&this, nTimeout, pvarPending);

	public HRESULT ChangeResourceGroup(ISClusResGroup* pResourceGroup) mut => VT.[Friend]ChangeResourceGroup(&this, pResourceGroup);

	public HRESULT AddResourceNode(ISClusNode* pNode) mut => VT.[Friend]AddResourceNode(&this, pNode);

	public HRESULT RemoveResourceNode(ISClusNode* pNode) mut => VT.[Friend]RemoveResourceNode(&this, pNode);

	public HRESULT CanResourceBeDependent(ISClusResource* pResource, VARIANT* pvarDependent) mut => VT.[Friend]CanResourceBeDependent(&this, pResource, pvarDependent);

	public HRESULT get_PossibleOwnerNodes(ISClusResPossibleOwnerNodes** ppOwnerNodes) mut => VT.[Friend]get_PossibleOwnerNodes(&this, ppOwnerNodes);

	public HRESULT get_Dependencies(ISClusResDependencies** ppResDependencies) mut => VT.[Friend]get_Dependencies(&this, ppResDependencies);

	public HRESULT get_Dependents(ISClusResDependents** ppResDependents) mut => VT.[Friend]get_Dependents(&this, ppResDependents);

	public HRESULT get_Group(ISClusResGroup** ppResGroup) mut => VT.[Friend]get_Group(&this, ppResGroup);

	public HRESULT get_OwnerNode(ISClusNode** ppOwnerNode) mut => VT.[Friend]get_OwnerNode(&this, ppOwnerNode);

	public HRESULT get_Cluster(ISCluster** ppCluster) mut => VT.[Friend]get_Cluster(&this, ppCluster);

	public HRESULT get_ClassInfo(CLUSTER_RESOURCE_CLASS* prcClassInfo) mut => VT.[Friend]get_ClassInfo(&this, prcClassInfo);

	public HRESULT get_Disk(ISClusDisk** ppDisk) mut => VT.[Friend]get_Disk(&this, ppDisk);

	public HRESULT get_RegistryKeys(ISClusRegistryKeys** ppRegistryKeys) mut => VT.[Friend]get_RegistryKeys(&this, ppRegistryKeys);

	public HRESULT get_CryptoKeys(ISClusCryptoKeys** ppCryptoKeys) mut => VT.[Friend]get_CryptoKeys(&this, ppCryptoKeys);

	public HRESULT get_TypeName(BSTR* pbstrTypeName) mut => VT.[Friend]get_TypeName(&this, pbstrTypeName);

	public HRESULT get_Type(ISClusResType** ppResourceType) mut => VT.[Friend]get_Type(&this, ppResourceType);

	public HRESULT get_MaintenanceMode(BOOL* pbMaintenanceMode) mut => VT.[Friend]get_MaintenanceMode(&this, pbMaintenanceMode);

	public HRESULT put_MaintenanceMode(BOOL bMaintenanceMode) mut => VT.[Friend]put_MaintenanceMode(&this, bMaintenanceMode);
}

[CRepr]struct ISClusResDependencies : IDispatch
{
	public new const Guid IID = .(0xf2e60704, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusResource** ppClusResource) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrResourceName, BSTR bstrResourceType, CLUSTER_RESOURCE_CREATE_FLAGS dwFlags, ISClusResource** ppClusterResource) CreateItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) DeleteItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResource* pResource) AddItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) RemoveItem;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusResource** ppClusResource) mut => VT.[Friend]get_Item(&this, varIndex, ppClusResource);

	public HRESULT CreateItem(BSTR bstrResourceName, BSTR bstrResourceType, CLUSTER_RESOURCE_CREATE_FLAGS dwFlags, ISClusResource** ppClusterResource) mut => VT.[Friend]CreateItem(&this, bstrResourceName, bstrResourceType, dwFlags, ppClusterResource);

	public HRESULT DeleteItem(VARIANT varIndex) mut => VT.[Friend]DeleteItem(&this, varIndex);

	public HRESULT AddItem(ISClusResource* pResource) mut => VT.[Friend]AddItem(&this, pResource);

	public HRESULT RemoveItem(VARIANT varIndex) mut => VT.[Friend]RemoveItem(&this, varIndex);
}

[CRepr]struct ISClusResGroupResources : IDispatch
{
	public new const Guid IID = .(0xf2e606ea, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusResource** ppClusResource) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrResourceName, BSTR bstrResourceType, CLUSTER_RESOURCE_CREATE_FLAGS dwFlags, ISClusResource** ppClusterResource) CreateItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) DeleteItem;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusResource** ppClusResource) mut => VT.[Friend]get_Item(&this, varIndex, ppClusResource);

	public HRESULT CreateItem(BSTR bstrResourceName, BSTR bstrResourceType, CLUSTER_RESOURCE_CREATE_FLAGS dwFlags, ISClusResource** ppClusterResource) mut => VT.[Friend]CreateItem(&this, bstrResourceName, bstrResourceType, dwFlags, ppClusterResource);

	public HRESULT DeleteItem(VARIANT varIndex) mut => VT.[Friend]DeleteItem(&this, varIndex);
}

[CRepr]struct ISClusResTypeResources : IDispatch
{
	public new const Guid IID = .(0xf2e60714, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusResource** ppClusResource) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrResourceName, BSTR bstrGroupName, CLUSTER_RESOURCE_CREATE_FLAGS dwFlags, ISClusResource** ppClusterResource) CreateItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) DeleteItem;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusResource** ppClusResource) mut => VT.[Friend]get_Item(&this, varIndex, ppClusResource);

	public HRESULT CreateItem(BSTR bstrResourceName, BSTR bstrGroupName, CLUSTER_RESOURCE_CREATE_FLAGS dwFlags, ISClusResource** ppClusterResource) mut => VT.[Friend]CreateItem(&this, bstrResourceName, bstrGroupName, dwFlags, ppClusterResource);

	public HRESULT DeleteItem(VARIANT varIndex) mut => VT.[Friend]DeleteItem(&this, varIndex);
}

[CRepr]struct ISClusResources : IDispatch
{
	public new const Guid IID = .(0xf2e6070c, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusResource** ppClusResource) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrResourceName, BSTR bstrResourceType, BSTR bstrGroupName, CLUSTER_RESOURCE_CREATE_FLAGS dwFlags, ISClusResource** ppClusterResource) CreateItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) DeleteItem;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusResource** ppClusResource) mut => VT.[Friend]get_Item(&this, varIndex, ppClusResource);

	public HRESULT CreateItem(BSTR bstrResourceName, BSTR bstrResourceType, BSTR bstrGroupName, CLUSTER_RESOURCE_CREATE_FLAGS dwFlags, ISClusResource** ppClusterResource) mut => VT.[Friend]CreateItem(&this, bstrResourceName, bstrResourceType, bstrGroupName, dwFlags, ppClusterResource);

	public HRESULT DeleteItem(VARIANT varIndex) mut => VT.[Friend]DeleteItem(&this, varIndex);
}

[CRepr]struct ISClusResGroupPreferredOwnerNodes : IDispatch
{
	public new const Guid IID = .(0xf2e606e8, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusNode** ppNode) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusNode* pNode, int32 nPosition) InsertItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) RemoveItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarModified) get_Modified;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SaveChanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusNode* pNode) AddItem;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusNode** ppNode) mut => VT.[Friend]get_Item(&this, varIndex, ppNode);

	public HRESULT InsertItem(ISClusNode* pNode, int32 nPosition) mut => VT.[Friend]InsertItem(&this, pNode, nPosition);

	public HRESULT RemoveItem(VARIANT varIndex) mut => VT.[Friend]RemoveItem(&this, varIndex);

	public HRESULT get_Modified(VARIANT* pvarModified) mut => VT.[Friend]get_Modified(&this, pvarModified);

	public HRESULT SaveChanges() mut => VT.[Friend]SaveChanges(&this);

	public HRESULT AddItem(ISClusNode* pNode) mut => VT.[Friend]AddItem(&this, pNode);
}

[CRepr]struct ISClusResPossibleOwnerNodes : IDispatch
{
	public new const Guid IID = .(0xf2e6070e, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusNode** ppNode) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusNode* pNode) AddItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) RemoveItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarModified) get_Modified;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusNode** ppNode) mut => VT.[Friend]get_Item(&this, varIndex, ppNode);

	public HRESULT AddItem(ISClusNode* pNode) mut => VT.[Friend]AddItem(&this, pNode);

	public HRESULT RemoveItem(VARIANT varIndex) mut => VT.[Friend]RemoveItem(&this, varIndex);

	public HRESULT get_Modified(VARIANT* pvarModified) mut => VT.[Friend]get_Modified(&this, pvarModified);
}

[CRepr]struct ISClusResTypePossibleOwnerNodes : IDispatch
{
	public new const Guid IID = .(0xf2e60718, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusNode** ppNode) get_Item;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusNode** ppNode) mut => VT.[Friend]get_Item(&this, varIndex, ppNode);
}

[CRepr]struct ISClusResType : IDispatch
{
	public new const Guid IID = .(0xf2e60710, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_CommonROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusProperties** ppProperties) get_PrivateROProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISCluster** ppCluster) get_Cluster;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResTypeResources** ppClusterResTypeResources) get_Resources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResTypePossibleOwnerNodes** ppOwnerNodes) get_PossibleOwnerNodes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusDisks** ppAvailableDisks) get_AvailableDisks;
	}


	public HRESULT get_CommonProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonProperties(&this, ppProperties);

	public HRESULT get_PrivateProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateProperties(&this, ppProperties);

	public HRESULT get_CommonROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_CommonROProperties(&this, ppProperties);

	public HRESULT get_PrivateROProperties(ISClusProperties** ppProperties) mut => VT.[Friend]get_PrivateROProperties(&this, ppProperties);

	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT get_Cluster(ISCluster** ppCluster) mut => VT.[Friend]get_Cluster(&this, ppCluster);

	public HRESULT get_Resources(ISClusResTypeResources** ppClusterResTypeResources) mut => VT.[Friend]get_Resources(&this, ppClusterResTypeResources);

	public HRESULT get_PossibleOwnerNodes(ISClusResTypePossibleOwnerNodes** ppOwnerNodes) mut => VT.[Friend]get_PossibleOwnerNodes(&this, ppOwnerNodes);

	public HRESULT get_AvailableDisks(ISClusDisks** ppAvailableDisks) mut => VT.[Friend]get_AvailableDisks(&this, ppAvailableDisks);
}

[CRepr]struct ISClusResTypes : IDispatch
{
	public new const Guid IID = .(0xf2e60712, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusResType** ppClusResType) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrResourceTypeName, BSTR bstrDisplayName, BSTR bstrResourceTypeDll, int32 dwLooksAlivePollInterval, int32 dwIsAlivePollInterval, ISClusResType** ppResourceType) CreateItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) DeleteItem;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusResType** ppClusResType) mut => VT.[Friend]get_Item(&this, varIndex, ppClusResType);

	public HRESULT CreateItem(BSTR bstrResourceTypeName, BSTR bstrDisplayName, BSTR bstrResourceTypeDll, int32 dwLooksAlivePollInterval, int32 dwIsAlivePollInterval, ISClusResType** ppResourceType) mut => VT.[Friend]CreateItem(&this, bstrResourceTypeName, bstrDisplayName, bstrResourceTypeDll, dwLooksAlivePollInterval, dwIsAlivePollInterval, ppResourceType);

	public HRESULT DeleteItem(VARIANT varIndex) mut => VT.[Friend]DeleteItem(&this, varIndex);
}

[CRepr]struct ISClusProperty : IDispatch
{
	public new const Guid IID = .(0xf2e606fe, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pLength) get_Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) get_ValueCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusPropertyValues** ppClusterPropertyValues) get_Values;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarValue) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varValue) put_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_PROPERTY_TYPE* pType) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_PROPERTY_TYPE Type) put_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_PROPERTY_FORMAT* pFormat) get_Format;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_PROPERTY_FORMAT Format) put_Format;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarReadOnly) get_ReadOnly;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarPrivate) get_Private;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarCommon) get_Common;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarModified) get_Modified;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UseDefaultValue;
	}


	public HRESULT get_Name(BSTR* pbstrName) mut => VT.[Friend]get_Name(&this, pbstrName);

	public HRESULT get_Length(int32* pLength) mut => VT.[Friend]get_Length(&this, pLength);

	public HRESULT get_ValueCount(int32* pCount) mut => VT.[Friend]get_ValueCount(&this, pCount);

	public HRESULT get_Values(ISClusPropertyValues** ppClusterPropertyValues) mut => VT.[Friend]get_Values(&this, ppClusterPropertyValues);

	public HRESULT get_Value(VARIANT* pvarValue) mut => VT.[Friend]get_Value(&this, pvarValue);

	public HRESULT put_Value(VARIANT varValue) mut => VT.[Friend]put_Value(&this, varValue);

	public HRESULT get_Type(CLUSTER_PROPERTY_TYPE* pType) mut => VT.[Friend]get_Type(&this, pType);

	public HRESULT put_Type(CLUSTER_PROPERTY_TYPE Type) mut => VT.[Friend]put_Type(&this, Type);

	public HRESULT get_Format(CLUSTER_PROPERTY_FORMAT* pFormat) mut => VT.[Friend]get_Format(&this, pFormat);

	public HRESULT put_Format(CLUSTER_PROPERTY_FORMAT Format) mut => VT.[Friend]put_Format(&this, Format);

	public HRESULT get_ReadOnly(VARIANT* pvarReadOnly) mut => VT.[Friend]get_ReadOnly(&this, pvarReadOnly);

	public HRESULT get_Private(VARIANT* pvarPrivate) mut => VT.[Friend]get_Private(&this, pvarPrivate);

	public HRESULT get_Common(VARIANT* pvarCommon) mut => VT.[Friend]get_Common(&this, pvarCommon);

	public HRESULT get_Modified(VARIANT* pvarModified) mut => VT.[Friend]get_Modified(&this, pvarModified);

	public HRESULT UseDefaultValue() mut => VT.[Friend]UseDefaultValue(&this);
}

[CRepr]struct ISClusPropertyValue : IDispatch
{
	public new const Guid IID = .(0xf2e6071a, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarValue) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varValue) put_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_PROPERTY_TYPE* pType) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_PROPERTY_TYPE Type) put_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_PROPERTY_FORMAT* pFormat) get_Format;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CLUSTER_PROPERTY_FORMAT Format) put_Format;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pLength) get_Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) get_DataCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusPropertyValueData** ppClusterPropertyValueData) get_Data;
	}


	public HRESULT get_Value(VARIANT* pvarValue) mut => VT.[Friend]get_Value(&this, pvarValue);

	public HRESULT put_Value(VARIANT varValue) mut => VT.[Friend]put_Value(&this, varValue);

	public HRESULT get_Type(CLUSTER_PROPERTY_TYPE* pType) mut => VT.[Friend]get_Type(&this, pType);

	public HRESULT put_Type(CLUSTER_PROPERTY_TYPE Type) mut => VT.[Friend]put_Type(&this, Type);

	public HRESULT get_Format(CLUSTER_PROPERTY_FORMAT* pFormat) mut => VT.[Friend]get_Format(&this, pFormat);

	public HRESULT put_Format(CLUSTER_PROPERTY_FORMAT Format) mut => VT.[Friend]put_Format(&this, Format);

	public HRESULT get_Length(int32* pLength) mut => VT.[Friend]get_Length(&this, pLength);

	public HRESULT get_DataCount(int32* pCount) mut => VT.[Friend]get_DataCount(&this, pCount);

	public HRESULT get_Data(ISClusPropertyValueData** ppClusterPropertyValueData) mut => VT.[Friend]get_Data(&this, ppClusterPropertyValueData);
}

[CRepr]struct ISClusPropertyValues : IDispatch
{
	public new const Guid IID = .(0xf2e6071c, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusPropertyValue** ppPropertyValue) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, VARIANT varValue, ISClusPropertyValue** ppPropertyValue) CreateItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) RemoveItem;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT get_Item(VARIANT varIndex, ISClusPropertyValue** ppPropertyValue) mut => VT.[Friend]get_Item(&this, varIndex, ppPropertyValue);

	public HRESULT CreateItem(BSTR bstrName, VARIANT varValue, ISClusPropertyValue** ppPropertyValue) mut => VT.[Friend]CreateItem(&this, bstrName, varValue, ppPropertyValue);

	public HRESULT RemoveItem(VARIANT varIndex) mut => VT.[Friend]RemoveItem(&this, varIndex);
}

[CRepr]struct ISClusProperties : IDispatch
{
	public new const Guid IID = .(0xf2e60700, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusProperty** ppClusProperty) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, VARIANT varValue, ISClusProperty** pProperty) CreateItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) UseDefaultValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarStatusCode) SaveChanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarReadOnly) get_ReadOnly;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarPrivate) get_Private;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarCommon) get_Common;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarModified) get_Modified;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusProperty** ppClusProperty) mut => VT.[Friend]get_Item(&this, varIndex, ppClusProperty);

	public HRESULT CreateItem(BSTR bstrName, VARIANT varValue, ISClusProperty** pProperty) mut => VT.[Friend]CreateItem(&this, bstrName, varValue, pProperty);

	public HRESULT UseDefaultValue(VARIANT varIndex) mut => VT.[Friend]UseDefaultValue(&this, varIndex);

	public HRESULT SaveChanges(VARIANT* pvarStatusCode) mut => VT.[Friend]SaveChanges(&this, pvarStatusCode);

	public HRESULT get_ReadOnly(VARIANT* pvarReadOnly) mut => VT.[Friend]get_ReadOnly(&this, pvarReadOnly);

	public HRESULT get_Private(VARIANT* pvarPrivate) mut => VT.[Friend]get_Private(&this, pvarPrivate);

	public HRESULT get_Common(VARIANT* pvarCommon) mut => VT.[Friend]get_Common(&this, pvarCommon);

	public HRESULT get_Modified(VARIANT* pvarModified) mut => VT.[Friend]get_Modified(&this, pvarModified);
}

[CRepr]struct ISClusPropertyValueData : IDispatch
{
	public new const Guid IID = .(0xf2e6071e, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, VARIANT* pvarValue) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varValue, VARIANT* pvarData) CreateItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) RemoveItem;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT get_Item(VARIANT varIndex, VARIANT* pvarValue) mut => VT.[Friend]get_Item(&this, varIndex, pvarValue);

	public HRESULT CreateItem(VARIANT varValue, VARIANT* pvarData) mut => VT.[Friend]CreateItem(&this, varValue, pvarData);

	public HRESULT RemoveItem(VARIANT varIndex) mut => VT.[Friend]RemoveItem(&this, varIndex);
}

[CRepr]struct ISClusPartition : IDispatch
{
	public new const Guid IID = .(0xf2e60720, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plFlags) get_Flags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDeviceName) get_DeviceName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrVolumeLabel) get_VolumeLabel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSerialNumber) get_SerialNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMaximumComponentLength) get_MaximumComponentLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plFileSystemFlags) get_FileSystemFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFileSystem) get_FileSystem;
	}


	public HRESULT get_Flags(int32* plFlags) mut => VT.[Friend]get_Flags(&this, plFlags);

	public HRESULT get_DeviceName(BSTR* pbstrDeviceName) mut => VT.[Friend]get_DeviceName(&this, pbstrDeviceName);

	public HRESULT get_VolumeLabel(BSTR* pbstrVolumeLabel) mut => VT.[Friend]get_VolumeLabel(&this, pbstrVolumeLabel);

	public HRESULT get_SerialNumber(int32* plSerialNumber) mut => VT.[Friend]get_SerialNumber(&this, plSerialNumber);

	public HRESULT get_MaximumComponentLength(int32* plMaximumComponentLength) mut => VT.[Friend]get_MaximumComponentLength(&this, plMaximumComponentLength);

	public HRESULT get_FileSystemFlags(int32* plFileSystemFlags) mut => VT.[Friend]get_FileSystemFlags(&this, plFileSystemFlags);

	public HRESULT get_FileSystem(BSTR* pbstrFileSystem) mut => VT.[Friend]get_FileSystem(&this, pbstrFileSystem);
}

[CRepr]struct ISClusPartitionEx : ISClusPartition
{
	public new const Guid IID = .(0x8802d4fe, 0xb32e, 0x4ad1, 0x9d, 0xbd, 0x64, 0xf1, 0x8e, 0x11, 0x66, 0xce);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISClusPartition.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plTotalSize) get_TotalSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plFreeSpace) get_FreeSpace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plDeviceNumber) get_DeviceNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plPartitionNumber) get_PartitionNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrVolumeGuid) get_VolumeGuid;
	}


	public HRESULT get_TotalSize(int32* plTotalSize) mut => VT.[Friend]get_TotalSize(&this, plTotalSize);

	public HRESULT get_FreeSpace(int32* plFreeSpace) mut => VT.[Friend]get_FreeSpace(&this, plFreeSpace);

	public HRESULT get_DeviceNumber(int32* plDeviceNumber) mut => VT.[Friend]get_DeviceNumber(&this, plDeviceNumber);

	public HRESULT get_PartitionNumber(int32* plPartitionNumber) mut => VT.[Friend]get_PartitionNumber(&this, plPartitionNumber);

	public HRESULT get_VolumeGuid(BSTR* pbstrVolumeGuid) mut => VT.[Friend]get_VolumeGuid(&this, pbstrVolumeGuid);
}

[CRepr]struct ISClusPartitions : IDispatch
{
	public new const Guid IID = .(0xf2e60722, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusPartition** ppPartition) get_Item;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT get_Item(VARIANT varIndex, ISClusPartition** ppPartition) mut => VT.[Friend]get_Item(&this, varIndex, ppPartition);
}

[CRepr]struct ISClusDisk : IDispatch
{
	public new const Guid IID = .(0xf2e60724, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSignature) get_Signature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusScsiAddress** ppScsiAddress) get_ScsiAddress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plDiskNumber) get_DiskNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusPartitions** ppPartitions) get_Partitions;
	}


	public HRESULT get_Signature(int32* plSignature) mut => VT.[Friend]get_Signature(&this, plSignature);

	public HRESULT get_ScsiAddress(ISClusScsiAddress** ppScsiAddress) mut => VT.[Friend]get_ScsiAddress(&this, ppScsiAddress);

	public HRESULT get_DiskNumber(int32* plDiskNumber) mut => VT.[Friend]get_DiskNumber(&this, plDiskNumber);

	public HRESULT get_Partitions(ISClusPartitions** ppPartitions) mut => VT.[Friend]get_Partitions(&this, ppPartitions);
}

[CRepr]struct ISClusDisks : IDispatch
{
	public new const Guid IID = .(0xf2e60726, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusDisk** ppDisk) get_Item;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT get_Item(VARIANT varIndex, ISClusDisk** ppDisk) mut => VT.[Friend]get_Item(&this, varIndex, ppDisk);
}

[CRepr]struct ISClusScsiAddress : IDispatch
{
	public new const Guid IID = .(0xf2e60728, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarPortNumber) get_PortNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarPathId) get_PathId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarTargetId) get_TargetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarLun) get_Lun;
	}


	public HRESULT get_PortNumber(VARIANT* pvarPortNumber) mut => VT.[Friend]get_PortNumber(&this, pvarPortNumber);

	public HRESULT get_PathId(VARIANT* pvarPathId) mut => VT.[Friend]get_PathId(&this, pvarPathId);

	public HRESULT get_TargetId(VARIANT* pvarTargetId) mut => VT.[Friend]get_TargetId(&this, pvarTargetId);

	public HRESULT get_Lun(VARIANT* pvarLun) mut => VT.[Friend]get_Lun(&this, pvarLun);
}

[CRepr]struct ISClusRegistryKeys : IDispatch
{
	public new const Guid IID = .(0xf2e6072a, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, BSTR* pbstrRegistryKey) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRegistryKey) AddItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) RemoveItem;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, BSTR* pbstrRegistryKey) mut => VT.[Friend]get_Item(&this, varIndex, pbstrRegistryKey);

	public HRESULT AddItem(BSTR bstrRegistryKey) mut => VT.[Friend]AddItem(&this, bstrRegistryKey);

	public HRESULT RemoveItem(VARIANT varIndex) mut => VT.[Friend]RemoveItem(&this, varIndex);
}

[CRepr]struct ISClusCryptoKeys : IDispatch
{
	public new const Guid IID = .(0xf2e6072c, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, BSTR* pbstrCyrptoKey) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCryptoKey) AddItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) RemoveItem;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, BSTR* pbstrCyrptoKey) mut => VT.[Friend]get_Item(&this, varIndex, pbstrCyrptoKey);

	public HRESULT AddItem(BSTR bstrCryptoKey) mut => VT.[Friend]AddItem(&this, bstrCryptoKey);

	public HRESULT RemoveItem(VARIANT varIndex) mut => VT.[Friend]RemoveItem(&this, varIndex);
}

[CRepr]struct ISClusResDependents : IDispatch
{
	public new const Guid IID = .(0xf2e6072e, 0x2631, 0x11d1, 0x89, 0xf1, 0x00, 0xa0, 0xc9, 0x0d, 0x06, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex, ISClusResource** ppClusResource) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrResourceName, BSTR bstrResourceType, CLUSTER_RESOURCE_CREATE_FLAGS dwFlags, ISClusResource** ppClusterResource) CreateItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) DeleteItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISClusResource* pResource) AddItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varIndex) RemoveItem;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT get_Item(VARIANT varIndex, ISClusResource** ppClusResource) mut => VT.[Friend]get_Item(&this, varIndex, ppClusResource);

	public HRESULT CreateItem(BSTR bstrResourceName, BSTR bstrResourceType, CLUSTER_RESOURCE_CREATE_FLAGS dwFlags, ISClusResource** ppClusterResource) mut => VT.[Friend]CreateItem(&this, bstrResourceName, bstrResourceType, dwFlags, ppClusterResource);

	public HRESULT DeleteItem(VARIANT varIndex) mut => VT.[Friend]DeleteItem(&this, varIndex);

	public HRESULT AddItem(ISClusResource* pResource) mut => VT.[Friend]AddItem(&this, pResource);

	public HRESULT RemoveItem(VARIANT varIndex) mut => VT.[Friend]RemoveItem(&this, varIndex);
}

#endregion

#region Functions
public static
{
	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetNodeClusterState(PWSTR lpszNodeName, uint32* pdwClusterState);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCLUSTER* OpenCluster(PWSTR lpszClusterName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCLUSTER* OpenClusterEx(PWSTR lpszClusterName, uint32 DesiredAccess, uint32* GrantedAccess);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseCluster(_HCLUSTER* hCluster);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetClusterName(_HCLUSTER* hCluster, PWSTR lpszNewClusterName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetClusterInformation(_HCLUSTER* hCluster, char16* lpszClusterName, uint32* lpcchClusterName, CLUSTERVERSIONINFO* lpClusterInfo);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetClusterQuorumResource(_HCLUSTER* hCluster, char16* lpszResourceName, uint32* lpcchResourceName, char16* lpszDeviceName, uint32* lpcchDeviceName, uint32* lpdwMaxQuorumLogSize);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetClusterQuorumResource(_HRESOURCE* hResource, PWSTR lpszDeviceName, uint32 dwMaxQuoLogSize);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BackupClusterDatabase(_HCLUSTER* hCluster, PWSTR lpszPathName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RestoreClusterDatabase(PWSTR lpszPathName, BOOL bForce, PWSTR lpszQuorumDriveLetter);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetClusterNetworkPriorityOrder(_HCLUSTER* hCluster, uint32 NetworkCount, _HNETWORK** NetworkList);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetClusterServiceAccountPassword(PWSTR lpszClusterName, PWSTR lpszNewPassword, uint32 dwFlags, CLUSTER_SET_PASSWORD_STATUS* lpReturnStatusBuffer, uint32* lpcbReturnStatusBufferSize);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterControl(_HCLUSTER* hCluster, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterUpgradeFunctionalLevel(_HCLUSTER* hCluster, BOOL perform, PCLUSTER_UPGRADE_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCHANGE* CreateClusterNotifyPortV2(_HCHANGE* hChange, _HCLUSTER* hCluster, NOTIFY_FILTER_AND_TYPE* Filters, uint32 dwFilterCount, uint dwNotifyKey);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RegisterClusterNotifyV2(_HCHANGE* hChange, NOTIFY_FILTER_AND_TYPE Filter, HANDLE hObject, uint dwNotifyKey);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetNotifyEventHandle(_HCHANGE* hChange, HANDLE* lphTargetEvent);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetClusterNotifyV2(_HCHANGE* hChange, uint* lpdwNotifyKey, NOTIFY_FILTER_AND_TYPE* pFilterAndType, uint8* buffer, uint32* lpbBufferSize, char16* lpszObjectId, uint32* lpcchObjectId, char16* lpszParentId, uint32* lpcchParentId, char16* lpszName, uint32* lpcchName, char16* lpszType, uint32* lpcchType, uint32 dwMilliseconds);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCHANGE* CreateClusterNotifyPort(_HCHANGE* hChange, _HCLUSTER* hCluster, uint32 dwFilter, uint dwNotifyKey);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RegisterClusterNotify(_HCHANGE* hChange, uint32 dwFilterType, HANDLE hObject, uint dwNotifyKey);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetClusterNotify(_HCHANGE* hChange, uint* lpdwNotifyKey, uint32* lpdwFilterType, char16* lpszName, uint32* lpcchName, uint32 dwMilliseconds);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseClusterNotifyPort(_HCHANGE* hChange);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCLUSENUM* ClusterOpenEnum(_HCLUSTER* hCluster, uint32 dwType);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterGetEnumCount(_HCLUSENUM* hEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterEnum(_HCLUSENUM* hEnum, uint32 dwIndex, uint32* lpdwType, char16* lpszName, uint32* lpcchName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterCloseEnum(_HCLUSENUM* hEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCLUSENUMEX* ClusterOpenEnumEx(_HCLUSTER* hCluster, uint32 dwType, void* pOptions);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterGetEnumCountEx(_HCLUSENUMEX* hClusterEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterEnumEx(_HCLUSENUMEX* hClusterEnum, uint32 dwIndex, CLUSTER_ENUM_ITEM* pItem, uint32* cbItem);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterCloseEnumEx(_HCLUSENUMEX* hClusterEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HGROUPSET* CreateClusterGroupSet(_HCLUSTER* hCluster, PWSTR groupSetName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HGROUPSET* OpenClusterGroupSet(_HCLUSTER* hCluster, PWSTR lpszGroupSetName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseClusterGroupSet(_HGROUPSET* hGroupSet);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DeleteClusterGroupSet(_HGROUPSET* hGroupSet);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterAddGroupToGroupSet(_HGROUPSET* hGroupSet, _HGROUP* hGroup);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterAddGroupToGroupSetWithDomains(_HGROUPSET* hGroupSet, _HGROUP* hGroup, uint32 faultDomain, uint32 updateDomain);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterRemoveGroupFromGroupSet(_HGROUP* hGroup);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterGroupSetControl(_HGROUPSET* hGroupSet, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 cbInBufferSize, void* lpOutBuffer, uint32 cbOutBufferSize, uint32* lpBytesReturned);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddClusterGroupDependency(_HGROUP* hDependentGroup, _HGROUP* hProviderGroup);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetGroupDependencyExpression(_HGROUP* hGroup, PWSTR lpszDependencyExpression);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveClusterGroupDependency(_HGROUP* hGroup, _HGROUP* hDependsOn);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddClusterGroupSetDependency(_HGROUPSET* hDependentGroupSet, _HGROUPSET* hProviderGroupSet);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetClusterGroupSetDependencyExpression(_HGROUPSET* hGroupSet, PWSTR lpszDependencyExprssion);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveClusterGroupSetDependency(_HGROUPSET* hGroupSet, _HGROUPSET* hDependsOn);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddClusterGroupToGroupSetDependency(_HGROUP* hDependentGroup, _HGROUPSET* hProviderGroupSet);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveClusterGroupToGroupSetDependency(_HGROUP* hGroup, _HGROUPSET* hDependsOn);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HGROUPSETENUM* ClusterGroupSetOpenEnum(_HCLUSTER* hCluster);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterGroupSetGetEnumCount(_HGROUPSETENUM* hGroupSetEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterGroupSetEnum(_HGROUPSETENUM* hGroupSetEnum, uint32 dwIndex, char16* lpszName, uint32* lpcchName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterGroupSetCloseEnum(_HGROUPSETENUM* hGroupSetEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddCrossClusterGroupSetDependency(_HGROUPSET* hDependentGroupSet, PWSTR lpRemoteClusterName, PWSTR lpRemoteGroupSetName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveCrossClusterGroupSetDependency(_HGROUPSET* hDependentGroupSet, PWSTR lpRemoteClusterName, PWSTR lpRemoteGroupSetName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HGROUPSET* CreateClusterAvailabilitySet(_HCLUSTER* hCluster, PWSTR lpAvailabilitySetName, CLUSTER_AVAILABILITY_SET_CONFIG* pAvailabilitySetConfig);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNodeReplacement(_HCLUSTER* hCluster, PWSTR lpszNodeNameCurrent, PWSTR lpszNodeNameNew);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterCreateAffinityRule(_HCLUSTER* hCluster, PWSTR ruleName, CLUS_AFFINITY_RULE_TYPE ruleType);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterRemoveAffinityRule(_HCLUSTER* hCluster, PWSTR ruleName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterAddGroupToAffinityRule(_HCLUSTER* hCluster, PWSTR ruleName, _HGROUP* hGroup);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterRemoveGroupFromAffinityRule(_HCLUSTER* hCluster, PWSTR ruleName, _HGROUP* hGroup);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterAffinityRuleControl(_HCLUSTER* hCluster, PWSTR affinityRuleName, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 cbInBufferSize, void* lpOutBuffer, uint32 cbOutBufferSize, uint32* lpBytesReturned);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HNODE* OpenClusterNode(_HCLUSTER* hCluster, PWSTR lpszNodeName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HNODE* OpenClusterNodeEx(_HCLUSTER* hCluster, PWSTR lpszNodeName, uint32 dwDesiredAccess, uint32* lpdwGrantedAccess);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HNODE* OpenClusterNodeById(_HCLUSTER* hCluster, uint32 nodeId);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseClusterNode(_HNODE* hNode);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLUSTER_NODE_STATE GetClusterNodeState(_HNODE* hNode);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetClusterNodeId(_HNODE* hNode, char16* lpszNodeId, uint32* lpcchName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCLUSTER* GetClusterFromNode(_HNODE* hNode);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PauseClusterNode(_HNODE* hNode);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResumeClusterNode(_HNODE* hNode);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EvictClusterNode(_HNODE* hNode);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HNETINTERFACEENUM* ClusterNetInterfaceOpenEnum(_HCLUSTER* hCluster, PWSTR lpszNodeName, PWSTR lpszNetworkName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNetInterfaceEnum(_HNETINTERFACEENUM* hNetInterfaceEnum, uint32 dwIndex, char16* lpszName, uint32* lpcchName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNetInterfaceCloseEnum(_HNETINTERFACEENUM* hNetInterfaceEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HNODEENUM* ClusterNodeOpenEnum(_HNODE* hNode, uint32 dwType);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HNODEENUMEX* ClusterNodeOpenEnumEx(_HNODE* hNode, uint32 dwType, void* pOptions);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNodeGetEnumCountEx(_HNODEENUMEX* hNodeEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNodeEnumEx(_HNODEENUMEX* hNodeEnum, uint32 dwIndex, CLUSTER_ENUM_ITEM* pItem, uint32* cbItem);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNodeCloseEnumEx(_HNODEENUMEX* hNodeEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNodeGetEnumCount(_HNODEENUM* hNodeEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNodeCloseEnum(_HNODEENUM* hNodeEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNodeEnum(_HNODEENUM* hNodeEnum, uint32 dwIndex, uint32* lpdwType, char16* lpszName, uint32* lpcchName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 EvictClusterNodeEx(_HNODE* hNode, uint32 dwTimeOut, HRESULT* phrCleanupStatus);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY GetClusterResourceTypeKey(_HCLUSTER* hCluster, PWSTR lpszTypeName, uint32 samDesired);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HGROUP* CreateClusterGroup(_HCLUSTER* hCluster, PWSTR lpszGroupName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HGROUP* OpenClusterGroup(_HCLUSTER* hCluster, PWSTR lpszGroupName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HGROUP* OpenClusterGroupEx(_HCLUSTER* hCluster, PWSTR lpszGroupName, uint32 dwDesiredAccess, uint32* lpdwGrantedAccess);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PauseClusterNodeEx(_HNODE* hNode, BOOL bDrainNode, uint32 dwPauseFlags, _HNODE* hNodeDrainTarget);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResumeClusterNodeEx(_HNODE* hNode, CLUSTER_NODE_RESUME_FAILBACK_TYPE eResumeFailbackType, uint32 dwResumeFlagsReserved);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HGROUP* CreateClusterGroupEx(_HCLUSTER* hCluster, PWSTR lpszGroupName, CLUSTER_CREATE_GROUP_INFO* pGroupInfo);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HGROUPENUMEX* ClusterGroupOpenEnumEx(_HCLUSTER* hCluster, PWSTR lpszProperties, uint32 cbProperties, PWSTR lpszRoProperties, uint32 cbRoProperties, uint32 dwFlags);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterGroupGetEnumCountEx(_HGROUPENUMEX* hGroupEnumEx);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterGroupEnumEx(_HGROUPENUMEX* hGroupEnumEx, uint32 dwIndex, CLUSTER_GROUP_ENUM_ITEM* pItem, uint32* cbItem);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterGroupCloseEnumEx(_HGROUPENUMEX* hGroupEnumEx);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESENUMEX* ClusterResourceOpenEnumEx(_HCLUSTER* hCluster, PWSTR lpszProperties, uint32 cbProperties, PWSTR lpszRoProperties, uint32 cbRoProperties, uint32 dwFlags);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterResourceGetEnumCountEx(_HRESENUMEX* hResourceEnumEx);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterResourceEnumEx(_HRESENUMEX* hResourceEnumEx, uint32 dwIndex, CLUSTER_RESOURCE_ENUM_ITEM* pItem, uint32* cbItem);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterResourceCloseEnumEx(_HRESENUMEX* hResourceEnumEx);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OnlineClusterGroupEx(_HGROUP* hGroup, _HNODE* hDestinationNode, uint32 dwOnlineFlags, uint8* lpInBuffer, uint32 cbInBufferSize);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OfflineClusterGroupEx(_HGROUP* hGroup, uint32 dwOfflineFlags, uint8* lpInBuffer, uint32 cbInBufferSize);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OnlineClusterResourceEx(_HRESOURCE* hResource, uint32 dwOnlineFlags, uint8* lpInBuffer, uint32 cbInBufferSize);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OfflineClusterResourceEx(_HRESOURCE* hResource, uint32 dwOfflineFlags, uint8* lpInBuffer, uint32 cbInBufferSize);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MoveClusterGroupEx(_HGROUP* hGroup, _HNODE* hDestinationNode, uint32 dwMoveFlags, uint8* lpInBuffer, uint32 cbInBufferSize);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CancelClusterGroupOperation(_HGROUP* hGroup, uint32 dwCancelFlags_RESERVED);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RestartClusterResource(_HRESOURCE* hResource, uint32 dwFlags);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseClusterGroup(_HGROUP* hGroup);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCLUSTER* GetClusterFromGroup(_HGROUP* hGroup);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLUSTER_GROUP_STATE GetClusterGroupState(_HGROUP* hGroup, char16* lpszNodeName, uint32* lpcchNodeName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetClusterGroupName(_HGROUP* hGroup, PWSTR lpszGroupName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetClusterGroupNodeList(_HGROUP* hGroup, uint32 NodeCount, _HNODE** NodeList);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OnlineClusterGroup(_HGROUP* hGroup, _HNODE* hDestinationNode);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MoveClusterGroup(_HGROUP* hGroup, _HNODE* hDestinationNode);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OfflineClusterGroup(_HGROUP* hGroup);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DeleteClusterGroup(_HGROUP* hGroup);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DestroyClusterGroup(_HGROUP* hGroup);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HGROUPENUM* ClusterGroupOpenEnum(_HGROUP* hGroup, uint32 dwType);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterGroupGetEnumCount(_HGROUPENUM* hGroupEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterGroupEnum(_HGROUPENUM* hGroupEnum, uint32 dwIndex, uint32* lpdwType, char16* lpszResourceName, uint32* lpcchName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterGroupCloseEnum(_HGROUPENUM* hGroupEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESOURCE* CreateClusterResource(_HGROUP* hGroup, PWSTR lpszResourceName, PWSTR lpszResourceType, uint32 dwFlags);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESOURCE* OpenClusterResource(_HCLUSTER* hCluster, PWSTR lpszResourceName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESOURCE* OpenClusterResourceEx(_HCLUSTER* hCluster, PWSTR lpszResourceName, uint32 dwDesiredAccess, uint32* lpdwGrantedAccess);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseClusterResource(_HRESOURCE* hResource);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCLUSTER* GetClusterFromResource(_HRESOURCE* hResource);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DeleteClusterResource(_HRESOURCE* hResource);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLUSTER_RESOURCE_STATE GetClusterResourceState(_HRESOURCE* hResource, char16* lpszNodeName, uint32* lpcchNodeName, char16* lpszGroupName, uint32* lpcchGroupName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetClusterResourceName(_HRESOURCE* hResource, PWSTR lpszResourceName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FailClusterResource(_HRESOURCE* hResource);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OnlineClusterResource(_HRESOURCE* hResource);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 OfflineClusterResource(_HRESOURCE* hResource);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ChangeClusterResourceGroup(_HRESOURCE* hResource, _HGROUP* hGroup);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ChangeClusterResourceGroupEx(_HRESOURCE* hResource, _HGROUP* hGroup, uint64 Flags);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddClusterResourceNode(_HRESOURCE* hResource, _HNODE* hNode);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveClusterResourceNode(_HRESOURCE* hResource, _HNODE* hNode);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddClusterResourceDependency(_HRESOURCE* hResource, _HRESOURCE* hDependsOn);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveClusterResourceDependency(_HRESOURCE* hResource, _HRESOURCE* hDependsOn);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetClusterResourceDependencyExpression(_HRESOURCE* hResource, PWSTR lpszDependencyExpression);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetClusterResourceDependencyExpression(_HRESOURCE* hResource, char16* lpszDependencyExpression, uint32* lpcchDependencyExpression);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddResourceToClusterSharedVolumes(_HRESOURCE* hResource);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveResourceFromClusterSharedVolumes(_HRESOURCE* hResource);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 IsFileOnClusterSharedVolume(PWSTR lpszPathName, BOOL* pbFileIsOnSharedVolume);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterSharedVolumeSetSnapshotState(Guid guidSnapshotSet, PWSTR lpszVolumeName, CLUSTER_SHARED_VOLUME_SNAPSHOT_STATE state);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CanResourceBeDependent(_HRESOURCE* hResource, _HRESOURCE* hResourceDependent);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterResourceControl(_HRESOURCE* hResource, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 cbInBufferSize, void* lpOutBuffer, uint32 cbOutBufferSize, uint32* lpBytesReturned);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterResourceControlAsUser(_HRESOURCE* hResource, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 cbInBufferSize, void* lpOutBuffer, uint32 cbOutBufferSize, uint32* lpBytesReturned);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterResourceTypeControl(_HCLUSTER* hCluster, PWSTR lpszResourceTypeName, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterResourceTypeControlAsUser(_HCLUSTER* hCluster, PWSTR lpszResourceTypeName, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterGroupControl(_HGROUP* hGroup, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNodeControl(_HNODE* hNode, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetClusterResourceNetworkName(_HRESOURCE* hResource, char16* lpBuffer, uint32* nSize);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESENUM* ClusterResourceOpenEnum(_HRESOURCE* hResource, uint32 dwType);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterResourceGetEnumCount(_HRESENUM* hResEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterResourceEnum(_HRESENUM* hResEnum, uint32 dwIndex, uint32* lpdwType, char16* lpszName, uint32* lpcchName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterResourceCloseEnum(_HRESENUM* hResEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CreateClusterResourceType(_HCLUSTER* hCluster, PWSTR lpszResourceTypeName, PWSTR lpszDisplayName, PWSTR lpszResourceTypeDll, uint32 dwLooksAlivePollInterval, uint32 dwIsAlivePollInterval);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DeleteClusterResourceType(_HCLUSTER* hCluster, PWSTR lpszResourceTypeName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESTYPEENUM* ClusterResourceTypeOpenEnum(_HCLUSTER* hCluster, PWSTR lpszResourceTypeName, uint32 dwType);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterResourceTypeGetEnumCount(_HRESTYPEENUM* hResTypeEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterResourceTypeEnum(_HRESTYPEENUM* hResTypeEnum, uint32 dwIndex, uint32* lpdwType, char16* lpszName, uint32* lpcchName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterResourceTypeCloseEnum(_HRESTYPEENUM* hResTypeEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HNETWORK* OpenClusterNetwork(_HCLUSTER* hCluster, PWSTR lpszNetworkName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HNETWORK* OpenClusterNetworkEx(_HCLUSTER* hCluster, PWSTR lpszNetworkName, uint32 dwDesiredAccess, uint32* lpdwGrantedAccess);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseClusterNetwork(_HNETWORK* hNetwork);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCLUSTER* GetClusterFromNetwork(_HNETWORK* hNetwork);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HNETWORKENUM* ClusterNetworkOpenEnum(_HNETWORK* hNetwork, uint32 dwType);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNetworkGetEnumCount(_HNETWORKENUM* hNetworkEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNetworkEnum(_HNETWORKENUM* hNetworkEnum, uint32 dwIndex, uint32* lpdwType, char16* lpszName, uint32* lpcchName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNetworkCloseEnum(_HNETWORKENUM* hNetworkEnum);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLUSTER_NETWORK_STATE GetClusterNetworkState(_HNETWORK* hNetwork);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetClusterNetworkName(_HNETWORK* hNetwork, PWSTR lpszName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetClusterNetworkId(_HNETWORK* hNetwork, char16* lpszNetworkId, uint32* lpcchName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNetworkControl(_HNETWORK* hNetwork, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HNETINTERFACE* OpenClusterNetInterface(_HCLUSTER* hCluster, PWSTR lpszInterfaceName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HNETINTERFACE* OpenClusterNetInterfaceEx(_HCLUSTER* hCluster, PWSTR lpszInterfaceName, uint32 dwDesiredAccess, uint32* lpdwGrantedAccess);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetClusterNetInterface(_HCLUSTER* hCluster, PWSTR lpszNodeName, PWSTR lpszNetworkName, char16* lpszInterfaceName, uint32* lpcchInterfaceName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseClusterNetInterface(_HNETINTERFACE* hNetInterface);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCLUSTER* GetClusterFromNetInterface(_HNETINTERFACE* hNetInterface);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLUSTER_NETINTERFACE_STATE GetClusterNetInterfaceState(_HNETINTERFACE* hNetInterface);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterNetInterfaceControl(_HNETINTERFACE* hNetInterface, _HNODE* hHostNode, uint32 dwControlCode, void* lpInBuffer, uint32 nInBufferSize, void* lpOutBuffer, uint32 nOutBufferSize, uint32* lpBytesReturned);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY GetClusterKey(_HCLUSTER* hCluster, uint32 samDesired);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY GetClusterGroupKey(_HGROUP* hGroup, uint32 samDesired);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY GetClusterResourceKey(_HRESOURCE* hResource, uint32 samDesired);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY GetClusterNodeKey(_HNODE* hNode, uint32 samDesired);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY GetClusterNetworkKey(_HNETWORK* hNetwork, uint32 samDesired);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY GetClusterNetInterfaceKey(_HNETINTERFACE* hNetInterface, uint32 samDesired);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegCreateKey(HKEY hKey, PWSTR lpszSubKey, uint32 dwOptions, uint32 samDesired, SECURITY_ATTRIBUTES* lpSecurityAttributes, HKEY* phkResult, uint32* lpdwDisposition);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegOpenKey(HKEY hKey, PWSTR lpszSubKey, uint32 samDesired, HKEY* phkResult);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegDeleteKey(HKEY hKey, PWSTR lpszSubKey);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegCloseKey(HKEY hKey);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegEnumKey(HKEY hKey, uint32 dwIndex, char16* lpszName, uint32* lpcchName, FILETIME* lpftLastWriteTime);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterRegSetValue(HKEY hKey, PWSTR lpszValueName, uint32 dwType, uint8* lpData, uint32 cbData);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterRegDeleteValue(HKEY hKey, PWSTR lpszValueName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegQueryValue(HKEY hKey, PWSTR lpszValueName, uint32* lpdwValueType, uint8* lpData, uint32* lpcbData);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterRegEnumValue(HKEY hKey, uint32 dwIndex, char16* lpszValueName, uint32* lpcchValueName, uint32* lpdwType, uint8* lpData, uint32* lpcbData);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegQueryInfoKey(HKEY hKey, uint32* lpcSubKeys, uint32* lpcchMaxSubKeyLen, uint32* lpcValues, uint32* lpcchMaxValueNameLen, uint32* lpcbMaxValueLen, uint32* lpcbSecurityDescriptor, FILETIME* lpftLastWriteTime);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegGetKeySecurity(HKEY hKey, uint32 RequestedInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor, uint32* lpcbSecurityDescriptor);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegSetKeySecurity(HKEY hKey, uint32 SecurityInformation, PSECURITY_DESCRIPTOR pSecurityDescriptor);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegSyncDatabase(_HCLUSTER* hCluster, uint32 flags);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegCreateBatch(HKEY hKey, _HREGBATCH** pHREGBATCH);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegBatchAddCommand(_HREGBATCH* hRegBatch, CLUSTER_REG_COMMAND dwCommand, PWSTR wzName, uint32 dwOptions, void* lpData, uint32 cbData);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegCloseBatch(_HREGBATCH* hRegBatch, BOOL bCommit, int32* failedCommandNumber);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegCloseBatchEx(_HREGBATCH* hRegBatch, uint32 flags, int32* failedCommandNumber);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegBatchReadCommand(_HREGBATCHNOTIFICATION* hBatchNotification, CLUSTER_BATCH_COMMAND* pBatchCommand);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegBatchCloseNotification(_HREGBATCHNOTIFICATION* hBatchNotification);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegCreateBatchNotifyPort(HKEY hKey, _HREGBATCHPORT** phBatchNotifyPort);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegCloseBatchNotifyPort(_HREGBATCHPORT* hBatchNotifyPort);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegGetBatchNotification(_HREGBATCHPORT* hBatchNotify, _HREGBATCHNOTIFICATION** phBatchNotification);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegCreateReadBatch(HKEY hKey, _HREGREADBATCH** phRegReadBatch);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegReadBatchAddCommand(_HREGREADBATCH* hRegReadBatch, PWSTR wzSubkeyName, PWSTR wzValueName);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegCloseReadBatch(_HREGREADBATCH* hRegReadBatch, _HREGREADBATCHREPLY** phRegReadBatchReply);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegCloseReadBatchEx(_HREGREADBATCH* hRegReadBatch, uint32 flags, _HREGREADBATCHREPLY** phRegReadBatchReply);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegReadBatchReplyNextCommand(_HREGREADBATCHREPLY* hRegReadBatchReply, CLUSTER_READ_BATCH_COMMAND* pBatchCommand);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ClusterRegCloseReadBatchReply(_HREGREADBATCHREPLY* hRegReadBatchReply);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterSetAccountAccess(_HCLUSTER* hCluster, PWSTR szAccountSID, uint32 dwAccess, uint32 dwControlType);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCLUSTER* CreateCluster(CREATE_CLUSTER_CONFIG* pConfig, PCLUSTER_SETUP_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CreateClusterNameAccount(_HCLUSTER* hCluster, CREATE_CLUSTER_NAME_ACCOUNT* pConfig, PCLUSTER_SETUP_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveClusterNameAccount(_HCLUSTER* hCluster, BOOL bDeleteComputerObjects);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DetermineCNOResTypeFromNodelist(uint32 cNodes, PWSTR* ppszNodeNames, CLUSTER_MGMT_POINT_RESTYPE* pCNOResType);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DetermineCNOResTypeFromCluster(_HCLUSTER* hCluster, CLUSTER_MGMT_POINT_RESTYPE* pCNOResType);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DetermineClusterCloudTypeFromNodelist(uint32 cNodes, PWSTR* ppszNodeNames, CLUSTER_CLOUD_TYPE* pCloudType);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DetermineClusterCloudTypeFromCluster(_HCLUSTER* hCluster, CLUSTER_CLOUD_TYPE* pCloudType);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetNodeCloudTypeDW(PWSTR ppszNodeName, uint32* NodeCloudType);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RegisterClusterResourceTypeNotifyV2(_HCHANGE* hChange, _HCLUSTER* hCluster, int64 Flags, PWSTR resTypeName, uint dwNotifyKey);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HNODE* AddClusterNode(_HCLUSTER* hCluster, PWSTR lpszNodeName, PCLUSTER_SETUP_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 AddClusterStorageNode(_HCLUSTER* hCluster, PWSTR lpszNodeName, PCLUSTER_SETUP_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg, PWSTR lpszClusterStorageNodeDescription, PWSTR lpszClusterStorageNodeLocation);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HNODE* AddClusterNodeEx(_HCLUSTER* hCluster, PWSTR lpszNodeName, uint32 dwFlags, PCLUSTER_SETUP_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RemoveClusterStorageNode(_HCLUSTER* hCluster, PWSTR lpszClusterStorageEnclosureName, uint32 dwTimeout, uint32 dwFlags);

	[Import("CLUSAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DestroyCluster(_HCLUSTER* hCluster, PCLUSTER_SETUP_PROGRESS_CALLBACK pfnProgressCallback, void* pvCallbackArg, BOOL fdeleteVirtualComputerObjects);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 InitializeClusterHealthFault(CLUSTER_HEALTH_FAULT* clusterHealthFault);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 InitializeClusterHealthFaultArray(CLUSTER_HEALTH_FAULT_ARRAY* clusterHealthFaultArray);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FreeClusterHealthFault(CLUSTER_HEALTH_FAULT* clusterHealthFault);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FreeClusterHealthFaultArray(CLUSTER_HEALTH_FAULT_ARRAY* clusterHealthFaultArray);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusGetClusterHealthFaults(_HCLUSTER* hCluster, CLUSTER_HEALTH_FAULT_ARRAY* objects, uint32 flags);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusRemoveClusterHealthFault(_HCLUSTER* hCluster, PWSTR id, uint32 flags);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusAddClusterHealthFault(_HCLUSTER* hCluster, CLUSTER_HEALTH_FAULT* failure, uint32 param2);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilStartResourceService(PWSTR pszServiceName, int* phServiceHandle);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilVerifyResourceService(PWSTR pszServiceName);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilStopResourceService(PWSTR pszServiceName);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilVerifyService(SC_HANDLE hServiceHandle);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilStopService(SC_HANDLE hServiceHandle);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilCreateDirectoryTree(PWSTR pszPath);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ResUtilIsPathValid(PWSTR pszPath);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilEnumProperties(RESUTIL_PROPERTY_ITEM* pPropertyTable, PWSTR pszOutProperties, uint32 cbOutPropertiesSize, uint32* pcbBytesReturned, uint32* pcbRequired);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilEnumPrivateProperties(HKEY hkeyClusterKey, PWSTR pszOutProperties, uint32 cbOutPropertiesSize, uint32* pcbBytesReturned, uint32* pcbRequired);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetProperties(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* pOutPropertyList, uint32 cbOutPropertyListSize, uint32* pcbBytesReturned, uint32* pcbRequired);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetAllProperties(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* pOutPropertyList, uint32 cbOutPropertyListSize, uint32* pcbBytesReturned, uint32* pcbRequired);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetPrivateProperties(HKEY hkeyClusterKey, void* pOutPropertyList, uint32 cbOutPropertyListSize, uint32* pcbBytesReturned, uint32* pcbRequired);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetPropertySize(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTableItem, uint32* pcbOutPropertyListSize, uint32* pnPropertyCount);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetProperty(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTableItem, void** pOutPropertyItem, uint32* pcbOutPropertyItemSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilVerifyPropertyTable(RESUTIL_PROPERTY_ITEM* pPropertyTable, void* Reserved, BOOL bAllowUnknownProperties, void* pInPropertyList, uint32 cbInPropertyListSize, uint8* pOutParams);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetPropertyTable(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* Reserved, BOOL bAllowUnknownProperties, void* pInPropertyList, uint32 cbInPropertyListSize, uint8* pOutParams);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetPropertyTableEx(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* Reserved, BOOL bAllowUnknownProperties, void* pInPropertyList, uint32 cbInPropertyListSize, BOOL bForceWrite, uint8* pOutParams);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetPropertyParameterBlock(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* Reserved, uint8* pInParams, void* pInPropertyList, uint32 cbInPropertyListSize, uint8* pOutParams);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetPropertyParameterBlockEx(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* Reserved, uint8* pInParams, void* pInPropertyList, uint32 cbInPropertyListSize, BOOL bForceWrite, uint8* pOutParams);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetUnknownProperties(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* pInPropertyList, uint32 cbInPropertyListSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetPropertiesToParameterBlock(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, uint8* pOutParams, BOOL bCheckForRequiredProperties, PWSTR* pszNameOfPropInError);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilPropertyListFromParameterBlock(RESUTIL_PROPERTY_ITEM* pPropertyTable, void* pOutPropertyList, uint32* pcbOutPropertyListSize, uint8* pInParams, uint32* pcbBytesReturned, uint32* pcbRequired);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilDupParameterBlock(uint8* pOutParams, uint8* pInParams, RESUTIL_PROPERTY_ITEM* pPropertyTable);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ResUtilFreeParameterBlock(uint8* pOutParams, uint8* pInParams, RESUTIL_PROPERTY_ITEM* pPropertyTable);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilAddUnknownProperties(HKEY hkeyClusterKey, RESUTIL_PROPERTY_ITEM* pPropertyTable, void* pOutPropertyList, uint32 pcbOutPropertyListSize, uint32* pcbBytesReturned, uint32* pcbRequired);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetPrivatePropertyList(HKEY hkeyClusterKey, void* pInPropertyList, uint32 cbInPropertyListSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilVerifyPrivatePropertyList(void* pInPropertyList, uint32 cbInPropertyListSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR ResUtilDupString(PWSTR pszInString);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetBinaryValue(HKEY hkeyClusterKey, PWSTR pszValueName, uint8** ppbOutValue, uint32* pcbOutValueSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR ResUtilGetSzValue(HKEY hkeyClusterKey, PWSTR pszValueName);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetDwordValue(HKEY hkeyClusterKey, PWSTR pszValueName, uint32* pdwOutValue, uint32 dwDefaultValue);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetQwordValue(HKEY hkeyClusterKey, PWSTR pszValueName, uint64* pqwOutValue, uint64 qwDefaultValue);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetBinaryValue(HKEY hkeyClusterKey, PWSTR pszValueName, uint8* pbNewValue, uint32 cbNewValueSize, uint8** ppbOutValue, uint32* pcbOutValueSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetSzValue(HKEY hkeyClusterKey, PWSTR pszValueName, PWSTR pszNewValue, PWSTR* ppszOutString);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetExpandSzValue(HKEY hkeyClusterKey, PWSTR pszValueName, PWSTR pszNewValue, PWSTR* ppszOutString);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetMultiSzValue(HKEY hkeyClusterKey, PWSTR pszValueName, PWSTR pszNewValue, uint32 cbNewValueSize, PWSTR* ppszOutValue, uint32* pcbOutValueSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetDwordValue(HKEY hkeyClusterKey, PWSTR pszValueName, uint32 dwNewValue, uint32* pdwOutValue);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetQwordValue(HKEY hkeyClusterKey, PWSTR pszValueName, uint64 qwNewValue, uint64* pqwOutValue);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetValueEx(HKEY hkeyClusterKey, PWSTR valueName, uint32 valueType, uint8* valueData, uint32 valueSize, uint32 flags);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetBinaryProperty(uint8** ppbOutValue, uint32* pcbOutValueSize, CLUSPROP_BINARY* pValueStruct, uint8* pbOldValue, uint32 cbOldValueSize, uint8** ppPropertyList, uint32* pcbPropertyListSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetSzProperty(PWSTR* ppszOutValue, CLUSPROP_SZ* pValueStruct, PWSTR pszOldValue, uint8** ppPropertyList, uint32* pcbPropertyListSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetMultiSzProperty(PWSTR* ppszOutValue, uint32* pcbOutValueSize, CLUSPROP_SZ* pValueStruct, PWSTR pszOldValue, uint32 cbOldValueSize, uint8** ppPropertyList, uint32* pcbPropertyListSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetDwordProperty(uint32* pdwOutValue, CLUSPROP_DWORD* pValueStruct, uint32 dwOldValue, uint32 dwMinimum, uint32 dwMaximum, uint8** ppPropertyList, uint32* pcbPropertyListSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetLongProperty(int32* plOutValue, CLUSPROP_LONG* pValueStruct, int32 lOldValue, int32 lMinimum, int32 lMaximum, uint8** ppPropertyList, uint32* pcbPropertyListSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetFileTimeProperty(FILETIME* pftOutValue, CLUSPROP_FILETIME* pValueStruct, FILETIME ftOldValue, FILETIME ftMinimum, FILETIME ftMaximum, uint8** ppPropertyList, uint32* pcbPropertyListSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* ResUtilGetEnvironmentWithNetName(_HRESOURCE* hResource);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilFreeEnvironment(void* lpEnvironment);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR ResUtilExpandEnvironmentStrings(PWSTR pszSrc);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetResourceServiceEnvironment(PWSTR pszServiceName, _HRESOURCE* hResource, PLOG_EVENT_ROUTINE pfnLogEvent, int hResourceHandle);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilRemoveResourceServiceEnvironment(PWSTR pszServiceName, PLOG_EVENT_ROUTINE pfnLogEvent, int hResourceHandle);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetResourceServiceStartParameters(PWSTR pszServiceName, SC_HANDLE schSCMHandle, int* phService, PLOG_EVENT_ROUTINE pfnLogEvent, int hResourceHandle);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilFindSzProperty(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, PWSTR* pszPropertyValue);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilFindExpandSzProperty(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, PWSTR* pszPropertyValue);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilFindExpandedSzProperty(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, PWSTR* pszPropertyValue);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilFindDwordProperty(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, uint32* pdwPropertyValue);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilFindBinaryProperty(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, uint8** pbPropertyValue, uint32* pcbPropertyValueSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilFindMultiSzProperty(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, PWSTR* pszPropertyValue, uint32* pcbPropertyValueSize);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilFindLongProperty(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, int32* plPropertyValue);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilFindULargeIntegerProperty(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, uint64* plPropertyValue);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilFindFileTimeProperty(void* pPropertyList, uint32 cbPropertyListSize, PWSTR pszPropertyName, FILETIME* pftPropertyValue);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusWorkerCreate(CLUS_WORKER* lpWorker, PWORKER_START_ROUTINE lpStartAddress, void* lpParameter);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ClusWorkerCheckTerminate(CLUS_WORKER* lpWorker);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ClusWorkerTerminate(CLUS_WORKER* lpWorker);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusWorkerTerminateEx(CLUS_WORKER* ClusWorker, uint32 TimeoutInMilliseconds, BOOL WaitOnly);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusWorkersTerminate(CLUS_WORKER** ClusWorkers, uint ClusWorkersCount, uint32 TimeoutInMilliseconds, BOOL WaitOnly);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ResUtilResourcesEqual(_HRESOURCE* hSelf, _HRESOURCE* hResource);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ResUtilResourceTypesEqual(PWSTR lpszResourceTypeName, _HRESOURCE* hResource);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ResUtilIsResourceClassEqual(CLUS_RESOURCE_CLASS_INFO* prci, _HRESOURCE* hResource);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilEnumResources(_HRESOURCE* hSelf, PWSTR lpszResTypeName, LPRESOURCE_CALLBACK pResCallBack, void* pParameter);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilEnumResourcesEx(_HCLUSTER* hCluster, _HRESOURCE* hSelf, PWSTR lpszResTypeName, LPRESOURCE_CALLBACK_EX pResCallBack, void* pParameter);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESOURCE* ResUtilGetResourceDependency(HANDLE hSelf, PWSTR lpszResourceType);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESOURCE* ResUtilGetResourceDependencyByName(_HCLUSTER* hCluster, HANDLE hSelf, PWSTR lpszResourceType, BOOL bRecurse);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESOURCE* ResUtilGetResourceDependencyByClass(_HCLUSTER* hCluster, HANDLE hSelf, CLUS_RESOURCE_CLASS_INFO* prci, BOOL bRecurse);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESOURCE* ResUtilGetResourceNameDependency(PWSTR lpszResourceName, PWSTR lpszResourceType);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetResourceDependentIPAddressProps(_HRESOURCE* hResource, char16* pszAddress, uint32* pcchAddress, char16* pszSubnetMask, uint32* pcchSubnetMask, char16* pszNetwork, uint32* pcchNetwork);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilFindDependentDiskResourceDriveLetter(_HCLUSTER* hCluster, _HRESOURCE* hResource, char16* pszDriveLetter, uint32* pcchDriveLetter);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilTerminateServiceProcessFromResDll(uint32 dwServicePid, BOOL bOffline, uint32* pdwResourceState, PLOG_EVENT_ROUTINE pfnLogEvent, int hResourceHandle);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetPropertyFormats(RESUTIL_PROPERTY_ITEM* pPropertyTable, void* pOutPropertyFormatList, uint32 cbPropertyFormatListSize, uint32* pcbBytesReturned, uint32* pcbRequired);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetCoreClusterResources(_HCLUSTER* hCluster, _HRESOURCE** phClusterNameResource, _HRESOURCE** phClusterIPAddressResource, _HRESOURCE** phClusterQuorumResource);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetResourceName(_HRESOURCE* hResource, char16* pszResourceName, uint32* pcchResourceNameInOut);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CLUSTER_ROLE_STATE ResUtilGetClusterRoleState(_HCLUSTER* hCluster, CLUSTER_ROLE eClusterRole);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ClusterIsPathOnSharedVolume(PWSTR lpszPathName);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ClusterGetVolumePathName(PWSTR lpszFileName, PWSTR lpszVolumePathName, uint32 cchBufferLength);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ClusterGetVolumeNameForVolumeMountPoint(PWSTR lpszVolumeMountPoint, PWSTR lpszVolumeName, uint32 cchBufferLength);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterPrepareSharedVolumeForBackup(PWSTR lpszFileName, PWSTR lpszVolumePathName, uint32* lpcchVolumePathName, PWSTR lpszVolumeName, uint32* lpcchVolumeName);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterClearBackupStateForSharedVolume(PWSTR lpszVolumePathName);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilSetResourceServiceStartParametersEx(PWSTR pszServiceName, SC_HANDLE schSCMHandle, int* phService, uint32 dwDesiredAccess, PLOG_EVENT_ROUTINE pfnLogEvent, int hResourceHandle);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilEnumResourcesEx2(_HCLUSTER* hCluster, _HRESOURCE* hSelf, PWSTR lpszResTypeName, LPRESOURCE_CALLBACK_EX pResCallBack, void* pParameter, uint32 dwDesiredAccess);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESOURCE* ResUtilGetResourceDependencyEx(HANDLE hSelf, PWSTR lpszResourceType, uint32 dwDesiredAccess);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESOURCE* ResUtilGetResourceDependencyByNameEx(_HCLUSTER* hCluster, HANDLE hSelf, PWSTR lpszResourceType, BOOL bRecurse, uint32 dwDesiredAccess);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESOURCE* ResUtilGetResourceDependencyByClassEx(_HCLUSTER* hCluster, HANDLE hSelf, CLUS_RESOURCE_CLASS_INFO* prci, BOOL bRecurse, uint32 dwDesiredAccess);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HRESOURCE* ResUtilGetResourceNameDependencyEx(PWSTR lpszResourceName, PWSTR lpszResourceType, uint32 dwDesiredAccess);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetCoreClusterResourcesEx(_HCLUSTER* hClusterIn, _HRESOURCE** phClusterNameResourceOut, _HRESOURCE** phClusterQuorumResourceOut, uint32 dwDesiredAccess);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCLUSCRYPTPROVIDER* OpenClusterCryptProvider(PWSTR lpszResource, int8* lpszProvider, uint32 dwType, uint32 dwFlags);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HCLUSCRYPTPROVIDER* OpenClusterCryptProviderEx(PWSTR lpszResource, PWSTR lpszKeyname, int8* lpszProvider, uint32 dwType, uint32 dwFlags);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CloseClusterCryptProvider(_HCLUSCRYPTPROVIDER* hClusCryptProvider);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterEncrypt(_HCLUSCRYPTPROVIDER* hClusCryptProvider, uint8* pData, uint32 cbData, uint8** ppData, uint32* pcbData);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ClusterDecrypt(_HCLUSCRYPTPROVIDER* hClusCryptProvider, uint8* pCryptInput, uint32 cbCryptInput, uint8** ppCryptOutput, uint32* pcbCryptOutput);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 FreeClusterCrypt(void* pCryptInfo);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilVerifyShutdownSafe(uint32 flags, uint32 reason, uint32* pResult);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ResUtilPaxosComparer(PaxosTagCStruct* left, PaxosTagCStruct* right);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ResUtilLeftPaxosIsLessThanRight(PaxosTagCStruct* left, PaxosTagCStruct* right);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilsDeleteKeyTree(HKEY key, PWSTR keyName, BOOL treatNoKeyAsError);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGroupsEqual(_HGROUP* hSelf, _HGROUP* hGroup, BOOL* pEqual);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilEnumGroups(_HCLUSTER* hCluster, _HGROUP* hSelf, LPGROUP_CALLBACK_EX pResCallBack, void* pParameter);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilEnumGroupsEx(_HCLUSTER* hCluster, _HGROUP* hSelf, CLUSGROUP_TYPE groupType, LPGROUP_CALLBACK_EX pResCallBack, void* pParameter);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilDupGroup(_HGROUP* group, _HGROUP** copy);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetClusterGroupType(_HGROUP* hGroup, CLUSGROUP_TYPE* groupType);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern _HGROUP* ResUtilGetCoreGroup(_HCLUSTER* hCluster);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilResourceDepEnum(_HRESOURCE* hSelf, uint32 enumType, LPRESOURCE_CALLBACK_EX pResCallBack, void* pParameter);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilDupResource(_HRESOURCE* group, _HRESOURCE** copy);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilGetClusterId(_HCLUSTER* hCluster, Guid* guid);

	[Import("RESUTILS.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResUtilNodeEnum(_HCLUSTER* hCluster, LPNODE_CALLBACK pNodeCallBack, void* pParameter);

	[Import("NTLANMAN.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RegisterAppInstance(HANDLE ProcessHandle, Guid* AppInstanceId, BOOL ChildrenInheritAppInstance);

	[Import("NTLANMAN.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RegisterAppInstanceVersion(Guid* AppInstanceId, uint64 InstanceVersionHigh, uint64 InstanceVersionLow);

	[Import("NTLANMAN.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 QueryAppInstanceVersion(Guid* AppInstanceId, uint64* InstanceVersionHigh, uint64* InstanceVersionLow, NTSTATUS* VersionStatus);

	[Import("NTLANMAN.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ResetAllAppInstanceVersions();

	[Import("NTLANMAN.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetAppInstanceCsvFlags(HANDLE ProcessHandle, uint32 Mask, uint32 Flags);

}
#endregion
