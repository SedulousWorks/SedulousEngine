using Win32.Foundation;
using System;

namespace Win32.NetworkManagement.NetBios;

#region Constants
public static
{
	public const uint32 NCBNAMSZ = 16;
	public const uint32 MAX_LANA = 254;
	public const uint32 NAME_FLAGS_MASK = 135;
	public const uint32 GROUP_NAME = 128;
	public const uint32 UNIQUE_NAME = 0;
	public const uint32 REGISTERING = 0;
	public const uint32 REGISTERED = 4;
	public const uint32 DEREGISTERED = 5;
	public const uint32 DUPLICATE = 6;
	public const uint32 DUPLICATE_DEREG = 7;
	public const uint32 LISTEN_OUTSTANDING = 1;
	public const uint32 CALL_PENDING = 2;
	public const uint32 SESSION_ESTABLISHED = 3;
	public const uint32 HANGUP_PENDING = 4;
	public const uint32 HANGUP_COMPLETE = 5;
	public const uint32 SESSION_ABORTED = 6;
	public const String ALL_TRANSPORTS = "M\u{0000}\u{0000}\u{0000}";
	public const String MS_NBF = "MNBF";
	public const uint32 NCBCALL = 16;
	public const uint32 NCBLISTEN = 17;
	public const uint32 NCBHANGUP = 18;
	public const uint32 NCBSEND = 20;
	public const uint32 NCBRECV = 21;
	public const uint32 NCBRECVANY = 22;
	public const uint32 NCBCHAINSEND = 23;
	public const uint32 NCBDGSEND = 32;
	public const uint32 NCBDGRECV = 33;
	public const uint32 NCBDGSENDBC = 34;
	public const uint32 NCBDGRECVBC = 35;
	public const uint32 NCBADDNAME = 48;
	public const uint32 NCBDELNAME = 49;
	public const uint32 NCBRESET = 50;
	public const uint32 NCBASTAT = 51;
	public const uint32 NCBSSTAT = 52;
	public const uint32 NCBCANCEL = 53;
	public const uint32 NCBADDGRNAME = 54;
	public const uint32 NCBENUM = 55;
	public const uint32 NCBUNLINK = 112;
	public const uint32 NCBSENDNA = 113;
	public const uint32 NCBCHAINSENDNA = 114;
	public const uint32 NCBLANSTALERT = 115;
	public const uint32 NCBACTION = 119;
	public const uint32 NCBFINDNAME = 120;
	public const uint32 NCBTRACE = 121;
	public const uint32 ASYNCH = 128;
	public const uint32 NRC_GOODRET = 0;
	public const uint32 NRC_BUFLEN = 1;
	public const uint32 NRC_ILLCMD = 3;
	public const uint32 NRC_CMDTMO = 5;
	public const uint32 NRC_INCOMP = 6;
	public const uint32 NRC_BADDR = 7;
	public const uint32 NRC_SNUMOUT = 8;
	public const uint32 NRC_NORES = 9;
	public const uint32 NRC_SCLOSED = 10;
	public const uint32 NRC_CMDCAN = 11;
	public const uint32 NRC_DUPNAME = 13;
	public const uint32 NRC_NAMTFUL = 14;
	public const uint32 NRC_ACTSES = 15;
	public const uint32 NRC_LOCTFUL = 17;
	public const uint32 NRC_REMTFUL = 18;
	public const uint32 NRC_ILLNN = 19;
	public const uint32 NRC_NOCALL = 20;
	public const uint32 NRC_NOWILD = 21;
	public const uint32 NRC_INUSE = 22;
	public const uint32 NRC_NAMERR = 23;
	public const uint32 NRC_SABORT = 24;
	public const uint32 NRC_NAMCONF = 25;
	public const uint32 NRC_IFBUSY = 33;
	public const uint32 NRC_TOOMANY = 34;
	public const uint32 NRC_BRIDGE = 35;
	public const uint32 NRC_CANOCCR = 36;
	public const uint32 NRC_CANCEL = 38;
	public const uint32 NRC_DUPENV = 48;
	public const uint32 NRC_ENVNOTDEF = 52;
	public const uint32 NRC_OSRESNOTAV = 53;
	public const uint32 NRC_MAXAPPS = 54;
	public const uint32 NRC_NOSAPS = 55;
	public const uint32 NRC_NORESOURCES = 56;
	public const uint32 NRC_INVADDRESS = 57;
	public const uint32 NRC_INVDDID = 59;
	public const uint32 NRC_LOCKFAIL = 60;
	public const uint32 NRC_OPENERR = 63;
	public const uint32 NRC_SYSTEM = 64;
	public const uint32 NRC_PENDING = 255;
}
#endregion

#region Structs
#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct NCB
{
	public uint8 ncb_command;
	public uint8 ncb_retcode;
	public uint8 ncb_lsn;
	public uint8 ncb_num;
	public uint8* ncb_buffer;
	public uint16 ncb_length;
	public uint8[16] ncb_callname;
	public uint8[16] ncb_name;
	public uint8 ncb_rto;
	public uint8 ncb_sto;
	public int ncb_post;
	public uint8 ncb_lana_num;
	public uint8 ncb_cmd_cplt;
	public uint8[18] ncb_reserve;
	public HANDLE ncb_event;
}
#endif

#if BF_32_BIT
[CRepr]
public struct NCB
{
	public uint8 ncb_command;
	public uint8 ncb_retcode;
	public uint8 ncb_lsn;
	public uint8 ncb_num;
	public uint8* ncb_buffer;
	public uint16 ncb_length;
	public uint8[16] ncb_callname;
	public uint8[16] ncb_name;
	public uint8 ncb_rto;
	public uint8 ncb_sto;
	public int ncb_post;
	public uint8 ncb_lana_num;
	public uint8 ncb_cmd_cplt;
	public uint8[10] ncb_reserve;
	public HANDLE ncb_event;
}
#endif

[CRepr]
public struct ADAPTER_STATUS
{
	public uint8[6] adapter_address;
	public uint8 rev_major;
	public uint8 reserved0;
	public uint8 adapter_type;
	public uint8 rev_minor;
	public uint16 duration;
	public uint16 frmr_recv;
	public uint16 frmr_xmit;
	public uint16 iframe_recv_err;
	public uint16 xmit_aborts;
	public uint32 xmit_success;
	public uint32 recv_success;
	public uint16 iframe_xmit_err;
	public uint16 recv_buff_unavail;
	public uint16 t1_timeouts;
	public uint16 ti_timeouts;
	public uint32 reserved1;
	public uint16 free_ncbs;
	public uint16 max_cfg_ncbs;
	public uint16 max_ncbs;
	public uint16 xmit_buf_unavail;
	public uint16 max_dgram_size;
	public uint16 pending_sess;
	public uint16 max_cfg_sess;
	public uint16 max_sess;
	public uint16 max_sess_pkt_size;
	public uint16 name_count;
}

[CRepr]
public struct NAME_BUFFER
{
	public uint8[16] name;
	public uint8 name_num;
	public uint8 name_flags;
}

[CRepr]
public struct SESSION_HEADER
{
	public uint8 sess_name;
	public uint8 num_sess;
	public uint8 rcv_dg_outstanding;
	public uint8 rcv_any_outstanding;
}

[CRepr]
public struct SESSION_BUFFER
{
	public uint8 lsn;
	public uint8 state;
	public uint8[16] local_name;
	public uint8[16] remote_name;
	public uint8 rcvs_outstanding;
	public uint8 sends_outstanding;
}

[CRepr]
public struct LANA_ENUM
{
	public uint8 length;
	public uint8[255] lana;
}

[CRepr]
public struct FIND_NAME_HEADER
{
	public uint16 node_count;
	public uint8 reserved;
	public uint8 unique_group;
}

[CRepr]
public struct FIND_NAME_BUFFER
{
	public uint8 length;
	public uint8 access_control;
	public uint8 frame_control;
	public uint8[6] destination_addr;
	public uint8[6] source_addr;
	public uint8[18] routing_info;
}

[CRepr]
public struct ACTION_HEADER
{
	public uint32 transport_id;
	public uint16 action_code;
	public uint16 reserved;
}

#endregion

#region Functions
public static
{
	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8 Netbios(NCB* pncb);

}
#endregion
