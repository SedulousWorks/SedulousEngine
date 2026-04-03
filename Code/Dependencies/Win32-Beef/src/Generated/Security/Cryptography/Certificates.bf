using Win32.System.Com;
using Win32.Foundation;
using Win32.Security.Cryptography;
using Win32.Security.Authentication.Identity;
using System;

namespace Win32.Security.Cryptography.Certificates;

#region Constants
public static
{
	public const String wszREGKEYNOSYSTEMCERTSVCPATH = "CurrentControlSet\\Services\\CertSvc";
	public const String wszREGKEYCERTSVCPATH = "SYSTEM\\CurrentControlSet\\Services\\CertSvc";
	public const uint32 CA_DISP_INCOMPLETE = 0;
	public const uint32 CA_DISP_ERROR = 1;
	public const uint32 CA_DISP_REVOKED = 2;
	public const uint32 CA_DISP_VALID = 3;
	public const uint32 CA_DISP_INVALID = 4;
	public const uint32 CA_DISP_UNDER_SUBMISSION = 5;
	public const uint32 KRA_DISP_EXPIRED = 0;
	public const uint32 KRA_DISP_NOTFOUND = 1;
	public const uint32 KRA_DISP_REVOKED = 2;
	public const uint32 KRA_DISP_VALID = 3;
	public const uint32 KRA_DISP_INVALID = 4;
	public const uint32 KRA_DISP_UNTRUSTED = 5;
	public const uint32 KRA_DISP_NOTLOADED = 6;
	public const uint32 CA_ACCESS_MASKROLES = 255;
	public const uint32 CA_CRL_BASE = 1;
	public const uint32 CA_CRL_DELTA = 2;
	public const uint32 CA_CRL_REPUBLISH = 16;
	public const uint32 ICF_ALLOWFOREIGN = 65536;
	public const uint32 ICF_EXISTINGROW = 131072;
	public const uint32 IKF_OVERWRITE = 65536;
	public const String wszOCSPCAPROP_CACERTIFICATE = "CACertificate";
	public const String wszOCSPCAPROP_HASHALGORITHMID = "HashAlgorithmId";
	public const String wszOCSPCAPROP_SIGNINGFLAGS = "SigningFlags";
	public const String wszOCSPCAPROP_REMINDERDURATION = "ReminderDuration";
	public const String wszOCSPCAPROP_SIGNINGCERTIFICATE = "SigningCertificate";
	public const String wszOCSPCAPROP_CSPNAME = "CSPName";
	public const String wszOCSPCAPROP_KEYSPEC = "KeySpec";
	public const String wszOCSPCAPROP_ERRORCODE = "ErrorCode";
	public const String wszOCSPCAPROP_PROVIDERCLSID = "ProviderCLSID";
	public const String wszOCSPCAPROP_PROVIDERPROPERTIES = "Provider";
	public const String wszOCSPCAPROP_LOCALREVOCATIONINFORMATION = "LocalRevocationInformation";
	public const String wszOCSPCAPROP_SIGNINGCERTIFICATETEMPLATE = "SigningCertificateTemplate";
	public const String wszOCSPCAPROP_CACONFIG = "CAConfig";
	public const String wszOCSPPROP_LOGLEVEL = "LogLevel";
	public const String wszOCSPPROP_DEBUG = "Debug";
	public const String wszOCSPPROP_AUDITFILTER = "AuditFilter";
	public const String wszOCSPPROP_ARRAYCONTROLLER = "ArrayController";
	public const String wszOCSPPROP_ARRAYMEMBERS = "ArrayMembers";
	public const String wszOCSPPROP_ENROLLPOLLINTERVAL = "EnrollPollInterval";
	public const String wszOCSPISAPIPROP_VIRTUALROOTNAME = "VirtualRootName";
	public const String wszOCSPISAPIPROP_NUMOFTHREADS = "NumOfThreads";
	public const String wszOCSPISAPIPROP_NUMOFBACKENDCONNECTIONS = "NumOfBackendConnections";
	public const String wszOCSPISAPIPROP_REFRESHRATE = "RefreshRate";
	public const String wszOCSPISAPIPROP_MAXNUMOFCACHEENTRIES = "MaxNumOfCacheEntries";
	public const String wszOCSPISAPIPROP_MAXAGE = "MaxAge";
	public const String wszOCSPISAPIPROP_DEBUG = "ISAPIDebug";
	public const String wszOCSPCOMMONPROP_REQFLAGS = "RequestFlags";
	public const String wszOCSPCOMMONPROP_MAXINCOMINGMESSAGESIZE = "MaxIncomingMessageSize";
	public const String wszOCSPCOMMONPROP_MAXNUMOFREQUESTENTRIES = "MaxNumOfRequestEntries";
	public const String wszOCSPREVPROP_CRLURLTIMEOUT = "CrlUrlTimeOut";
	public const String wszOCSPREVPROP_BASECRLURLS = "BaseCrlUrls";
	public const String wszOCSPREVPROP_SERIALNUMBERSDIRS = "IssuedSerialNumbersDirectories";
	public const String wszOCSPREVPROP_BASECRL = "BaseCrl";
	public const String wszOCSPREVPROP_DELTACRLURLS = "DeltaCrlUrls";
	public const String wszOCSPREVPROP_DELTACRL = "DeltaCrl";
	public const String wszOCSPREVPROP_REFRESHTIMEOUT = "RefreshTimeOut";
	public const String wszOCSPREVPROP_ERRORCODE = "RevocationErrorCode";
	public const String szBACKUPANNOTATION = "Cert Server Backup Interface";
	public const String szRESTOREANNOTATION = "Cert Server Restore Interface";
	public const uint32 CSBACKUP_TYPE_MASK = 3;
	public const uint32 CSRESTORE_TYPE_FULL = 1;
	public const uint32 CSRESTORE_TYPE_ONLINE = 2;
	public const uint32 CSRESTORE_TYPE_CATCHUP = 4;
	public const uint32 CSRESTORE_TYPE_MASK = 5;
	public const uint32 CSBACKUP_DISABLE_INCREMENTAL = 4294967295;
	public const uint32 CSBFT_DIRECTORY = 128;
	public const uint32 CSBFT_DATABASE_DIRECTORY = 64;
	public const uint32 CSBFT_LOG_DIRECTORY = 32;
	public const uint64 CSCONTROL_SHUTDOWN = 1;
	public const uint64 CSCONTROL_SUSPEND = 2;
	public const uint64 CSCONTROL_RESTART = 3;
	public const String wszCONFIG_COMMONNAME = "CommonName";
	public const String wszCONFIG_ORGUNIT = "OrgUnit";
	public const String wszCONFIG_ORGANIZATION = "Organization";
	public const String wszCONFIG_LOCALITY = "Locality";
	public const String wszCONFIG_STATE = "State";
	public const String wszCONFIG_COUNTRY = "Country";
	public const String wszCONFIG_CONFIG = "Config";
	public const String wszCONFIG_EXCHANGECERTIFICATE = "ExchangeCertificate";
	public const String wszCONFIG_SIGNATURECERTIFICATE = "SignatureCertificate";
	public const String wszCONFIG_DESCRIPTION = "Description";
	public const String wszCONFIG_COMMENT = "Comment";
	public const String wszCONFIG_SERVER = "Server";
	public const String wszCONFIG_AUTHORITY = "Authority";
	public const String wszCONFIG_SANITIZEDNAME = "SanitizedName";
	public const String wszCONFIG_SHORTNAME = "ShortName";
	public const String wszCONFIG_SANITIZEDSHORTNAME = "SanitizedShortName";
	public const String wszCONFIG_FLAGS = "Flags";
	public const String wszCONFIG_WEBENROLLMENTSERVERS = "WebEnrollmentServers";
	public const uint32 CAIF_DSENTRY = 1;
	public const uint32 CAIF_SHAREDFOLDERENTRY = 2;
	public const uint32 CAIF_REGISTRY = 4;
	public const uint32 CAIF_LOCAL = 8;
	public const uint32 CAIF_REGISTRYPARENT = 16;
	public const uint32 CR_IN_ENCODEANY = 255;
	public const uint32 CR_IN_ENCODEMASK = 255;
	public const uint32 CR_IN_FORMATANY = 0;
	public const uint32 CR_IN_PKCS10 = 256;
	public const uint32 CR_IN_KEYGEN = 512;
	public const uint32 CR_IN_PKCS7 = 768;
	public const uint32 CR_IN_CMC = 1024;
	public const uint32 CR_IN_CHALLENGERESPONSE = 1280;
	public const uint32 CR_IN_SIGNEDCERTIFICATETIMESTAMPLIST = 1536;
	public const uint32 CR_IN_FORMATMASK = 65280;
	public const uint32 CR_IN_SCEP = 65536;
	public const uint32 CR_IN_RPC = 131072;
	public const uint32 CR_IN_HTTP = 196608;
	public const uint32 CR_IN_FULLRESPONSE = 262144;
	public const uint32 CR_IN_CRLS = 524288;
	public const uint32 CR_IN_MACHINE = 1048576;
	public const uint32 CR_IN_ROBO = 2097152;
	public const uint32 CR_IN_CLIENTIDNONE = 4194304;
	public const uint32 CR_IN_CONNECTONLY = 8388608;
	public const uint32 CR_IN_RETURNCHALLENGE = 16777216;
	public const uint32 CR_IN_SCEPPOST = 33554432;
	public const uint32 CR_IN_CERTIFICATETRANSPARENCY = 67108864;
	public const uint32 CR_DISP_REVOKED = 6;
	public const uint32 CR_OUT_BASE64REQUESTHEADER = 3;
	public const uint32 CR_OUT_HEX = 4;
	public const uint32 CR_OUT_HEXASCII = 5;
	public const uint32 CR_OUT_BASE64X509CRLHEADER = 9;
	public const uint32 CR_OUT_HEXADDR = 10;
	public const uint32 CR_OUT_HEXASCIIADDR = 11;
	public const uint32 CR_OUT_HEXRAW = 12;
	public const uint32 CR_OUT_ENCODEMASK = 255;
	public const uint32 CR_OUT_CHAIN = 256;
	public const uint32 CR_OUT_CRLS = 512;
	public const uint32 CR_OUT_NOCRLF = 1073741824;
	public const uint32 CR_OUT_NOCR = 2147483648;
	public const uint32 CR_GEMT_DEFAULT = 0;
	public const uint32 CR_GEMT_HRESULT_STRING = 1;
	public const uint32 CR_GEMT_HTTP_ERROR = 2;
	public const uint32 CR_PROP_NONE = 0;
	public const uint32 CR_PROP_FILEVERSION = 1;
	public const uint32 CR_PROP_PRODUCTVERSION = 2;
	public const uint32 CR_PROP_EXITCOUNT = 3;
	public const uint32 CR_PROP_EXITDESCRIPTION = 4;
	public const uint32 CR_PROP_POLICYDESCRIPTION = 5;
	public const uint32 CR_PROP_CANAME = 6;
	public const uint32 CR_PROP_SANITIZEDCANAME = 7;
	public const uint32 CR_PROP_SHAREDFOLDER = 8;
	public const uint32 CR_PROP_PARENTCA = 9;
	public const uint32 CR_PROP_CATYPE = 10;
	public const uint32 CR_PROP_CASIGCERTCOUNT = 11;
	public const uint32 CR_PROP_CASIGCERT = 12;
	public const uint32 CR_PROP_CASIGCERTCHAIN = 13;
	public const uint32 CR_PROP_CAXCHGCERTCOUNT = 14;
	public const uint32 CR_PROP_CAXCHGCERT = 15;
	public const uint32 CR_PROP_CAXCHGCERTCHAIN = 16;
	public const uint32 CR_PROP_BASECRL = 17;
	public const uint32 CR_PROP_DELTACRL = 18;
	public const uint32 CR_PROP_CACERTSTATE = 19;
	public const uint32 CR_PROP_CRLSTATE = 20;
	public const uint32 CR_PROP_CAPROPIDMAX = 21;
	public const uint32 CR_PROP_DNSNAME = 22;
	public const uint32 CR_PROP_ROLESEPARATIONENABLED = 23;
	public const uint32 CR_PROP_KRACERTUSEDCOUNT = 24;
	public const uint32 CR_PROP_KRACERTCOUNT = 25;
	public const uint32 CR_PROP_KRACERT = 26;
	public const uint32 CR_PROP_KRACERTSTATE = 27;
	public const uint32 CR_PROP_ADVANCEDSERVER = 28;
	public const uint32 CR_PROP_TEMPLATES = 29;
	public const uint32 CR_PROP_BASECRLPUBLISHSTATUS = 30;
	public const uint32 CR_PROP_DELTACRLPUBLISHSTATUS = 31;
	public const uint32 CR_PROP_CASIGCERTCRLCHAIN = 32;
	public const uint32 CR_PROP_CAXCHGCERTCRLCHAIN = 33;
	public const uint32 CR_PROP_CACERTSTATUSCODE = 34;
	public const uint32 CR_PROP_CAFORWARDCROSSCERT = 35;
	public const uint32 CR_PROP_CABACKWARDCROSSCERT = 36;
	public const uint32 CR_PROP_CAFORWARDCROSSCERTSTATE = 37;
	public const uint32 CR_PROP_CABACKWARDCROSSCERTSTATE = 38;
	public const uint32 CR_PROP_CACERTVERSION = 39;
	public const uint32 CR_PROP_SANITIZEDCASHORTNAME = 40;
	public const uint32 CR_PROP_CERTCDPURLS = 41;
	public const uint32 CR_PROP_CERTAIAURLS = 42;
	public const uint32 CR_PROP_CERTAIAOCSPURLS = 43;
	public const uint32 CR_PROP_LOCALENAME = 44;
	public const uint32 CR_PROP_SUBJECTTEMPLATE_OIDS = 45;
	public const uint32 CR_PROP_SCEPSERVERCERTS = 1000;
	public const uint32 CR_PROP_SCEPSERVERCAPABILITIES = 1001;
	public const uint32 CR_PROP_SCEPSERVERCERTSCHAIN = 1002;
	public const uint32 CR_PROP_SCEPMIN = 1000;
	public const uint32 CR_PROP_SCEPMAX = 1002;
	public const uint32 FR_PROP_CLAIMCHALLENGE = 22;
	public const uint32 EAN_NAMEOBJECTID = 2147483648;
	public const uint32 EANR_SUPPRESS_IA5CONVERSION = 2147483648;
	public const uint32 CERTENROLL_INDEX_BASE = 0;
	public const uint32 EXITEVENT_INVALID = 0;
	public const uint32 EXITEVENT_STARTUP = 128;
	public const uint32 EXITEVENT_CERTIMPORTED = 512;
	public const uint32 ENUMEXT_OBJECTID = 1;
	public const uint32 CMM_REFRESHONLY = 1;
	public const uint32 CMM_READONLY = 2;
	public const uint32 DBG_CERTSRV = 1;
	public const String wszSERVICE_NAME = "CertSvc";
	public const String wszREGKEYBASE = "SYSTEM\\CurrentControlSet\\Services\\CertSvc";
	public const String wszREGKEYCONFIG = "Configuration";
	public const String wszREGACTIVE = "Active";
	public const String wszREGDIRECTORY = "ConfigurationDirectory";
	public const String wszREGDBDIRECTORY = "DBDirectory";
	public const String wszREGDBLOGDIRECTORY = "DBLogDirectory";
	public const String wszREGDBSYSDIRECTORY = "DBSystemDirectory";
	public const String wszREGDBTEMPDIRECTORY = "DBTempDirectory";
	public const String wszREGDBSESSIONCOUNT = "DBSessionCount";
	public const String wszREGDBMAXREADSESSIONCOUNT = "DBMaxReadSessionCount";
	public const String wszREGDBFLAGS = "DBFlags";
	public const String wszREGDBLASTFULLBACKUP = "DBLastFullBackup";
	public const String wszREGDBLASTINCREMENTALBACKUP = "DBLastIncrementalBackup";
	public const String wszREGDBLASTRECOVERY = "DBLastRecovery";
	public const String wszREGWEBCLIENTCAMACHINE = "WebClientCAMachine";
	public const String wszREGVERSION = "Version";
	public const String wszREGWEBCLIENTCANAME = "WebClientCAName";
	public const String wszREGWEBCLIENTCATYPE = "WebClientCAType";
	public const String wszREGLDAPFLAGS = "LDAPFlags";
	public const String wszREGCERTSRVDEBUG = "Debug";
	public const uint32 DBSESSIONCOUNTDEFAULT = 100;
	public const uint32 DBFLAGS_READONLY = 1;
	public const uint32 DBFLAGS_CREATEIFNEEDED = 2;
	public const uint32 DBFLAGS_CIRCULARLOGGING = 4;
	public const uint32 DBFLAGS_LAZYFLUSH = 8;
	public const uint32 DBFLAGS_MAXCACHESIZEX100 = 16;
	public const uint32 DBFLAGS_CHECKPOINTDEPTH60MB = 32;
	public const uint32 DBFLAGS_LOGBUFFERSLARGE = 64;
	public const uint32 DBFLAGS_LOGBUFFERSHUGE = 128;
	public const uint32 DBFLAGS_LOGFILESIZE16MB = 256;
	public const uint32 DBFLAGS_MULTITHREADTRANSACTIONS = 512;
	public const uint32 DBFLAGS_DISABLESNAPSHOTBACKUP = 1024;
	public const uint32 DBFLAGS_ENABLEVOLATILEREQUESTS = 2048;
	public const uint32 LDAPF_SSLENABLE = 1;
	public const uint32 LDAPF_SIGNDISABLE = 2;
	public const uint32 CSVER_MAJOR_WIN2K = 1;
	public const uint32 CSVER_MINOR_WIN2K = 1;
	public const uint32 CSVER_MAJOR_WHISTLER = 2;
	public const uint32 CSVER_MINOR_WHISTLER_BETA2 = 1;
	public const uint32 CSVER_MINOR_WHISTLER_BETA3 = 2;
	public const uint32 CSVER_MAJOR_LONGHORN = 3;
	public const uint32 CSVER_MINOR_LONGHORN_BETA1 = 1;
	public const uint32 CSVER_MAJOR_WIN7 = 4;
	public const uint32 CSVER_MINOR_WIN7 = 1;
	public const uint32 CSVER_MAJOR_WIN8 = 5;
	public const uint32 CSVER_MINOR_WIN8 = 1;
	public const uint32 CSVER_MAJOR_WINBLUE = 6;
	public const uint32 CSVER_MINOR_WINBLUE = 1;
	public const uint32 CSVER_MAJOR_THRESHOLD = 7;
	public const uint32 CSVER_MINOR_THRESHOLD = 1;
	public const uint32 CSVER_MAJOR = 7;
	public const uint32 CSVER_MINOR = 1;
	public const String wszREGKEYRESTOREINPROGRESS = "RestoreInProgress";
	public const String wszREGKEYDBPARAMETERS = "DBParameters";
	public const String wszREGCADESCRIPTION = "CADescription";
	public const String wszREGCACERTHASH = "CACertHash";
	public const String wszREGCASERIALNUMBER = "CACertSerialNumber";
	public const String wszREGCAXCHGCERTHASH = "CAXchgCertHash";
	public const String wszREGKRACERTHASH = "KRACertHash";
	public const String wszREGKRACERTCOUNT = "KRACertCount";
	public const String wszREGKRAFLAGS = "KRAFlags";
	public const String wszREGCATYPE = "CAType";
	public const String wszREGCERTENROLLCOMPATIBLE = "CertEnrollCompatible";
	public const String wszREGENFORCEX500NAMELENGTHS = "EnforceX500NameLengths";
	public const String wszREGCOMMONNAME = "CommonName";
	public const String wszREGCLOCKSKEWMINUTES = "ClockSkewMinutes";
	public const String wszREGCRLNEXTPUBLISH = "CRLNextPublish";
	public const String wszREGCRLPERIODSTRING = "CRLPeriod";
	public const String wszREGCRLPERIODCOUNT = "CRLPeriodUnits";
	public const String wszREGCRLOVERLAPPERIODSTRING = "CRLOverlapPeriod";
	public const String wszREGCRLOVERLAPPERIODCOUNT = "CRLOverlapUnits";
	public const String wszREGCRLDELTANEXTPUBLISH = "CRLDeltaNextPublish";
	public const String wszREGCRLDELTAPERIODSTRING = "CRLDeltaPeriod";
	public const String wszREGCRLDELTAPERIODCOUNT = "CRLDeltaPeriodUnits";
	public const String wszREGCRLDELTAOVERLAPPERIODSTRING = "CRLDeltaOverlapPeriod";
	public const String wszREGCRLDELTAOVERLAPPERIODCOUNT = "CRLDeltaOverlapUnits";
	public const String wszREGCRLPUBLICATIONURLS = "CRLPublicationURLs";
	public const String wszREGCACERTPUBLICATIONURLS = "CACertPublicationURLs";
	public const String wszREGCAXCHGVALIDITYPERIODSTRING = "CAXchgValidityPeriod";
	public const String wszREGCAXCHGVALIDITYPERIODCOUNT = "CAXchgValidityPeriodUnits";
	public const String wszREGCAXCHGOVERLAPPERIODSTRING = "CAXchgOverlapPeriod";
	public const String wszREGCAXCHGOVERLAPPERIODCOUNT = "CAXchgOverlapPeriodUnits";
	public const String wszREGCRLPATH_OLD = "CRLPath";
	public const String wszREGCRLEDITFLAGS = "CRLEditFlags";
	public const String wszREGCRLFLAGS = "CRLFlags";
	public const String wszREGCRLATTEMPTREPUBLISH = "CRLAttemptRepublish";
	public const String wszREGENABLED = "Enabled";
	public const String wszREGFORCETELETEX = "ForceTeletex";
	public const String wszREGLOGLEVEL = "LogLevel";
	public const String wszREGHIGHSERIAL = "HighSerial";
	public const String wszREGPOLICYFLAGS = "PolicyFlags";
	public const String wszREGNAMESEPARATOR = "SubjectNameSeparator";
	public const String wszREGSUBJECTTEMPLATE = "SubjectTemplate";
	public const String wszREGCAUSEDS = "UseDS";
	public const String wszREGVALIDITYPERIODSTRING = "ValidityPeriod";
	public const String wszREGVALIDITYPERIODCOUNT = "ValidityPeriodUnits";
	public const String wszREGPARENTCAMACHINE = "ParentCAMachine";
	public const String wszREGPARENTCANAME = "ParentCAName";
	public const String wszREGREQUESTFILENAME = "RequestFileName";
	public const String wszREGREQUESTID = "RequestId";
	public const String wszREGREQUESTKEYCONTAINER = "RequestKeyContainer";
	public const String wszREGREQUESTKEYINDEX = "RequestKeyIndex";
	public const String wszREGCASERVERNAME = "CAServerName";
	public const String wszREGCACERTFILENAME = "CACertFileName";
	public const String wszREGCASECURITY = "Security";
	public const String wszREGAUDITFILTER = "AuditFilter";
	public const String wszREGOFFICERRIGHTS = "OfficerRights";
	public const String wszENROLLMENTAGENTRIGHTS = "EnrollmentAgentRights";
	public const String wszREGMAXINCOMINGMESSAGESIZE = "MaxIncomingMessageSize";
	public const String wszREGMAXINCOMINGALLOCSIZE = "MaxIncomingAllocSize";
	public const String wszREGROLESEPARATIONENABLED = "RoleSeparationEnabled";
	public const String wszREGALTERNATEPUBLISHDOMAINS = "AlternatePublishDomains";
	public const String wszREGSETUPSTATUS = "SetupStatus";
	public const String wszREGINTERFACEFLAGS = "InterfaceFlags";
	public const String wszREGDSCONFIGDN = "DSConfigDN";
	public const String wszREGDSDOMAINDN = "DSDomainDN";
	public const String wszREGVIEWAGEMINUTES = "ViewAgeMinutes";
	public const String wszREGVIEWIDLEMINUTES = "ViewIdleMinutes";
	public const String wszREGEKPUBLISTDIRECTORIES = "EndorsementKeyListDirectories";
	public const String wszCERTIFICATETRANSPARENCYFLAGS = "CertificateTransparencyFlags";
	public const String wszREGMAXSCTLISTSIZE = "MaxSCTListSize";
	public const String wszREGCERTIFICATETRANSPARENCYINFOOID = "CTInformationExtensionOid";
	public const String wszREGPROCESSINGFLAGS = "ProcessingFlags";
	public const String wszREGUSEDEFINEDCACERTINREQ = "UseDefinedCACertInRequest";
	public const String wszREGENABLEDEKUFORDEFINEDCACERT = "EnabledEKUForDefinedCACert";
	public const String wszREGEKUOIDSFORPUBLISHEXPIREDCERTINCRL = "EKUOIDsForPublishExpiredCertInCRL";
	public const String wszCRTFILENAMEEXT = ".crt";
	public const String wszPFXFILENAMEEXT = ".p12";
	public const String wszDATFILENAMEEXT = ".dat";
	public const String wszLOGFILENAMEEXT = ".log";
	public const String wszDBFILENAMEEXT = ".edb";
	public const String szDBBASENAMEPARM = "edb";
	public const String wszLOGPATH = "CertLog";
	public const String wszDBBACKUPSUBDIR = "DataBase";
	public const String wszDBBACKUPCERTBACKDAT = "certbkxp.dat";
	public const uint32 CCLOCKSKEWMINUTESDEFAULT = 10;
	public const uint32 CVIEWAGEMINUTESDEFAULT = 16;
	public const uint32 dwVALIDITYPERIODCOUNTDEFAULT_ROOT = 5;
	public const uint32 dwVALIDITYPERIODCOUNTDEFAULT_ENTERPRISE = 2;
	public const uint32 dwVALIDITYPERIODCOUNTDEFAULT_STANDALONE = 1;
	public const uint32 dwCAXCHGVALIDITYPERIODCOUNTDEFAULT = 1;
	public const uint32 dwCAXCHGOVERLAPPERIODCOUNTDEFAULT = 1;
	public const uint32 dwCRLPERIODCOUNTDEFAULT = 1;
	public const uint32 dwCRLOVERLAPPERIODCOUNTDEFAULT = 0;
	public const uint32 dwCRLDELTAPERIODCOUNTDEFAULT = 1;
	public const uint32 dwCRLDELTAOVERLAPPERIODCOUNTDEFAULT = 0;
	public const uint32 SETUP_SERVER_FLAG = 1;
	public const uint32 SETUP_CLIENT_FLAG = 2;
	public const uint32 SETUP_SUSPEND_FLAG = 4;
	public const uint32 SETUP_REQUEST_FLAG = 8;
	public const uint32 SETUP_ONLINE_FLAG = 16;
	public const uint32 SETUP_DENIED_FLAG = 32;
	public const uint32 SETUP_CREATEDB_FLAG = 64;
	public const uint32 SETUP_ATTEMPT_VROOT_CREATE = 128;
	public const uint32 SETUP_FORCECRL_FLAG = 256;
	public const uint32 SETUP_UPDATE_CAOBJECT_SVRTYPE = 512;
	public const uint32 SETUP_SERVER_UPGRADED_FLAG = 1024;
	public const uint32 SETUP_W2K_SECURITY_NOT_UPGRADED_FLAG = 2048;
	public const uint32 SETUP_SECURITY_CHANGED = 4096;
	public const uint32 SETUP_DCOM_SECURITY_UPDATED_FLAG = 8192;
	public const uint32 SETUP_SERVER_IS_UP_TO_DATE_FLAG = 16384;
	public const uint32 CRLF_DELTA_USE_OLDEST_UNEXPIRED_BASE = 1;
	public const uint32 CRLF_DELETE_EXPIRED_CRLS = 2;
	public const uint32 CRLF_CRLNUMBER_CRITICAL = 4;
	public const uint32 CRLF_REVCHECK_IGNORE_OFFLINE = 8;
	public const uint32 CRLF_IGNORE_INVALID_POLICIES = 16;
	public const uint32 CRLF_REBUILD_MODIFIED_SUBJECT_ONLY = 32;
	public const uint32 CRLF_SAVE_FAILED_CERTS = 64;
	public const uint32 CRLF_IGNORE_UNKNOWN_CMC_ATTRIBUTES = 128;
	public const uint32 CRLF_IGNORE_CROSS_CERT_TRUST_ERROR = 256;
	public const uint32 CRLF_PUBLISH_EXPIRED_CERT_CRLS = 512;
	public const uint32 CRLF_ENFORCE_ENROLLMENT_AGENT = 1024;
	public const uint32 CRLF_DISABLE_RDN_REORDER = 2048;
	public const uint32 CRLF_DISABLE_ROOT_CROSS_CERTS = 4096;
	public const uint32 CRLF_LOG_FULL_RESPONSE = 8192;
	public const uint32 CRLF_USE_XCHG_CERT_TEMPLATE = 16384;
	public const uint32 CRLF_USE_CROSS_CERT_TEMPLATE = 32768;
	public const uint32 CRLF_ALLOW_REQUEST_ATTRIBUTE_SUBJECT = 65536;
	public const uint32 CRLF_REVCHECK_IGNORE_NOREVCHECK = 131072;
	public const uint32 CRLF_PRESERVE_EXPIRED_CA_CERTS = 262144;
	public const uint32 CRLF_PRESERVE_REVOKED_CA_CERTS = 524288;
	public const uint32 CRLF_DISABLE_CHAIN_VERIFICATION = 1048576;
	public const uint32 CRLF_BUILD_ROOTCA_CRLENTRIES_BASEDONKEY = 2097152;
	public const uint32 KRAF_ENABLEFOREIGN = 1;
	public const uint32 KRAF_SAVEBADREQUESTKEY = 2;
	public const uint32 KRAF_ENABLEARCHIVEALL = 4;
	public const uint32 KRAF_DISABLEUSEDEFAULTPROVIDER = 8;
	public const uint32 IF_LOCKICERTREQUEST = 1;
	public const uint32 IF_NOREMOTEICERTREQUEST = 2;
	public const uint32 IF_NOLOCALICERTREQUEST = 4;
	public const uint32 IF_NORPCICERTREQUEST = 8;
	public const uint32 IF_NOREMOTEICERTADMIN = 16;
	public const uint32 IF_NOLOCALICERTADMIN = 32;
	public const uint32 IF_NOREMOTEICERTADMINBACKUP = 64;
	public const uint32 IF_NOLOCALICERTADMINBACKUP = 128;
	public const uint32 IF_NOSNAPSHOTBACKUP = 256;
	public const uint32 IF_ENFORCEENCRYPTICERTREQUEST = 512;
	public const uint32 IF_ENFORCEENCRYPTICERTADMIN = 1024;
	public const uint32 IF_ENABLEEXITKEYRETRIEVAL = 2048;
	public const uint32 IF_ENABLEADMINASAUDITOR = 4096;
	public const uint32 PROCFLG_NONE = 0;
	public const uint32 PROCFLG_ENFORCEGOODKEYS = 1;
	public const uint32 CSURL_SERVERPUBLISH = 1;
	public const uint32 CSURL_ADDTOCERTCDP = 2;
	public const uint32 CSURL_ADDTOFRESHESTCRL = 4;
	public const uint32 CSURL_ADDTOCRLCDP = 8;
	public const uint32 CSURL_PUBLISHRETRY = 16;
	public const uint32 CSURL_ADDTOCERTOCSP = 32;
	public const uint32 CSURL_SERVERPUBLISHDELTA = 64;
	public const uint32 CSURL_ADDTOIDP = 128;
	public const String wszREGKEYCSP = "CSP";
	public const String wszREGKEYENCRYPTIONCSP = "EncryptionCSP";
	public const String wszREGKEYEXITMODULES = "ExitModules";
	public const String wszREGKEYPOLICYMODULES = "PolicyModules";
	public const String wszSECUREDATTRIBUTES = "SignedAttributes";
	public const String wszzDEFAULTSIGNEDATTRIBUTES = "RequesterName\u{0000}";
	public const String wszREGBACKUPLOGDIRECTORY = "BackupLogDirectory";
	public const String wszREGCHECKPOINTFILE = "CheckPointFile";
	public const String wszREGHIGHLOGNUMBER = "HighLogNumber";
	public const String wszREGLOWLOGNUMBER = "LowLogNumber";
	public const String wszREGLOGPATH = "LogPath";
	public const String wszREGRESTOREMAPCOUNT = "RestoreMapCount";
	public const String wszREGRESTOREMAP = "RestoreMap";
	public const String wszREGDATABASERECOVERED = "DatabaseRecovered";
	public const String wszREGRESTORESTATUS = "RestoreStatus";
	public const String wszREGB2ICERTMANAGEMODULE = "ICertManageModule";
	public const String wszREGSP4DEFAULTCONFIGURATION = "DefaultConfiguration";
	public const String wszREGSP4KEYSETNAME = "KeySetName";
	public const String wszREGSP4SUBJECTNAMESEPARATOR = "SubjectNameSeparator";
	public const String wszREGSP4NAMES = "Names";
	public const String wszREGSP4QUERIES = "Queries";
	public const String wszREGNETSCAPECERTTYPE = "NetscapeCertType";
	public const String wszNETSCAPEREVOCATIONTYPE = "Netscape";
	public const String wszREGPROVIDERTYPE = "ProviderType";
	public const String wszREGPROVIDER = "Provider";
	public const String wszHASHALGORITHM = "HashAlgorithm";
	public const String wszENCRYPTIONALGORITHM = "EncryptionAlgorithm";
	public const String wszMACHINEKEYSET = "MachineKeyset";
	public const String wszREGKEYSIZE = "KeySize";
	public const String wszREGSYMMETRICKEYSIZE = "SymmetricKeySize";
	public const String wszCNGPUBLICKEYALGORITHM = "CNGPublicKeyAlgorithm";
	public const String wszCNGHASHALGORITHM = "CNGHashAlgorithm";
	public const String wszCNGENCRYPTIONALGORITHM = "CNGEncryptionAlgorithm";
	public const String wszREGALTERNATESIGNATUREALGORITHM = "AlternateSignatureAlgorithm";
	public const String szNAMESEPARATORDEFAULT = "\n";
	public const String wszPERIODYEARS = "Years";
	public const String wszPERIODMONTHS = "Months";
	public const String wszPERIODWEEKS = "Weeks";
	public const String wszPERIODDAYS = "Days";
	public const String wszPERIODHOURS = "Hours";
	public const String wszPERIODMINUTES = "Minutes";
	public const String wszPERIODSECONDS = "Seconds";
	public const String wszREGISSUERCERTURLFLAGS = "IssuerCertURLFlags";
	public const String wszREGEDITFLAGS = "EditFlags";
	public const String wszREGUPNMAP = "UPNMap";
	public const String wszREGSUBJECTALTNAME = "SubjectAltName";
	public const String wszREGSUBJECTALTNAME2 = "SubjectAltName2";
	public const String wszREGREQUESTDISPOSITION = "RequestDisposition";
	public const String wszREGCAPATHLENGTH = "CAPathLength";
	public const String wszREGREVOCATIONTYPE = "RevocationType";
	public const String wszREGLDAPREVOCATIONCRLURL_OLD = "LDAPRevocationCRLURL";
	public const String wszREGREVOCATIONCRLURL_OLD = "RevocationCRLURL";
	public const String wszREGFTPREVOCATIONCRLURL_OLD = "FTPRevocationCRLURL";
	public const String wszREGFILEREVOCATIONCRLURL_OLD = "FileRevocationCRLURL";
	public const String wszREGREVOCATIONURL = "RevocationURL";
	public const String wszREGLDAPISSUERCERTURL_OLD = "LDAPIssuerCertURL";
	public const String wszREGISSUERCERTURL_OLD = "IssuerCertURL";
	public const String wszREGFTPISSUERCERTURL_OLD = "FTPIssuerCertURL";
	public const String wszREGFILEISSUERCERTURL_OLD = "FileIssuerCertURL";
	public const String wszREGENABLEREQUESTEXTENSIONLIST = "EnableRequestExtensionList";
	public const String wszREGENABLEENROLLEEREQUESTEXTENSIONLIST = "EnableEnrolleeRequestExtensionList";
	public const String wszREGDISABLEEXTENSIONLIST = "DisableExtensionList";
	public const String wszREGEKUOIDSFORVOLATILEREQUESTS = "EKUOIDsforVolatileRequests";
	public const String wszREGLDAPSESSIONOPTIONS = "LDAPSessionOptions";
	public const String wszLDAPSESSIONOPTIONVALUE = "LDAPSessionOptionValue";
	public const String wszREGDEFAULTSMIME = "DefaultSMIME";
	public const uint32 CAPATHLENGTH_INFINITE = 4294967295;
	public const uint32 REQDISP_PENDING = 0;
	public const uint32 REQDISP_ISSUE = 1;
	public const uint32 REQDISP_DENY = 2;
	public const uint32 REQDISP_USEREQUESTATTRIBUTE = 3;
	public const uint32 REQDISP_MASK = 255;
	public const uint32 REQDISP_PENDINGFIRST = 256;
	public const uint32 REQDISP_DEFAULT_ENTERPRISE = 1;
	public const uint32 REVEXT_CDPLDAPURL_OLD = 1;
	public const uint32 REVEXT_CDPHTTPURL_OLD = 2;
	public const uint32 REVEXT_CDPFTPURL_OLD = 4;
	public const uint32 REVEXT_CDPFILEURL_OLD = 8;
	public const uint32 REVEXT_CDPURLMASK_OLD = 255;
	public const uint32 REVEXT_CDPENABLE = 256;
	public const uint32 REVEXT_ASPENABLE = 512;
	public const uint32 REVEXT_DEFAULT_NODS = 256;
	public const uint32 REVEXT_DEFAULT_DS = 256;
	public const uint32 ISSCERT_LDAPURL_OLD = 1;
	public const uint32 ISSCERT_HTTPURL_OLD = 2;
	public const uint32 ISSCERT_FTPURL_OLD = 4;
	public const uint32 ISSCERT_FILEURL_OLD = 8;
	public const uint32 ISSCERT_URLMASK_OLD = 255;
	public const uint32 ISSCERT_ENABLE = 256;
	public const uint32 ISSCERT_DEFAULT_NODS = 256;
	public const uint32 ISSCERT_DEFAULT_DS = 256;
	public const uint32 EDITF_ENABLEREQUESTEXTENSIONS = 1;
	public const uint32 EDITF_REQUESTEXTENSIONLIST = 2;
	public const uint32 EDITF_DISABLEEXTENSIONLIST = 4;
	public const uint32 EDITF_ADDOLDKEYUSAGE = 8;
	public const uint32 EDITF_ADDOLDCERTTYPE = 16;
	public const uint32 EDITF_ATTRIBUTEENDDATE = 32;
	public const uint32 EDITF_BASICCONSTRAINTSCRITICAL = 64;
	public const uint32 EDITF_BASICCONSTRAINTSCA = 128;
	public const uint32 EDITF_ENABLEAKIKEYID = 256;
	public const uint32 EDITF_ATTRIBUTECA = 512;
	public const uint32 EDITF_IGNOREREQUESTERGROUP = 1024;
	public const uint32 EDITF_ENABLEAKIISSUERNAME = 2048;
	public const uint32 EDITF_ENABLEAKIISSUERSERIAL = 4096;
	public const uint32 EDITF_ENABLEAKICRITICAL = 8192;
	public const uint32 EDITF_SERVERUPGRADED = 16384;
	public const uint32 EDITF_ATTRIBUTEEKU = 32768;
	public const uint32 EDITF_ENABLEDEFAULTSMIME = 65536;
	public const uint32 EDITF_EMAILOPTIONAL = 131072;
	public const uint32 EDITF_ATTRIBUTESUBJECTALTNAME2 = 262144;
	public const uint32 EDITF_ENABLELDAPREFERRALS = 524288;
	public const uint32 EDITF_ENABLECHASECLIENTDC = 1048576;
	public const uint32 EDITF_AUDITCERTTEMPLATELOAD = 2097152;
	public const uint32 EDITF_DISABLEOLDOSCNUPN = 4194304;
	public const uint32 EDITF_DISABLELDAPPACKAGELIST = 8388608;
	public const uint32 EDITF_ENABLEUPNMAP = 16777216;
	public const uint32 EDITF_ENABLEOCSPREVNOCHECK = 33554432;
	public const uint32 EDITF_ENABLERENEWONBEHALFOF = 67108864;
	public const uint32 EDITF_ENABLEKEYENCIPHERMENTCACERT = 134217728;
	public const String wszREGLDAPREVOCATIONDN_OLD = "LDAPRevocationDN";
	public const String wszREGLDAPREVOCATIONDNTEMPLATE_OLD = "LDAPRevocationDNTemplate";
	public const String wszCRLPUBLISHRETRYCOUNT = "CRLPublishRetryCount";
	public const String wszREGCERTPUBLISHFLAGS = "PublishCertFlags";
	public const uint32 EXITPUB_FILE = 1;
	public const uint32 EXITPUB_ACTIVEDIRECTORY = 2;
	public const uint32 EXITPUB_REMOVEOLDCERTS = 16;
	public const uint32 EXITPUB_DEFAULT_ENTERPRISE = 2;
	public const uint32 EXITPUB_DEFAULT_STANDALONE = 1;
	public const String wszCLASS_CERTADMIN = "CertificateAuthority.Admin";
	public const String wszCLASS_CERTCONFIG = "CertificateAuthority.Config";
	public const String wszCLASS_CERTGETCONFIG = "CertificateAuthority.GetConfig";
	public const String wszCLASS_CERTENCODE = "CertificateAuthority.Encode";
	public const String wszCLASS_CERTDBMEM = "CertificateAuthority.DBMem";
	public const String wszCLASS_CERTREQUEST = "CertificateAuthority.Request";
	public const String wszCLASS_CERTSERVEREXIT = "CertificateAuthority.ServerExit";
	public const String wszCLASS_CERTSERVERPOLICY = "CertificateAuthority.ServerPolicy";
	public const String wszCLASS_CERTVIEW = "CertificateAuthority.View";
	public const String wszMICROSOFTCERTMODULE_PREFIX = "CertificateAuthority_MicrosoftDefault";
	public const String wszCERTMANAGE_SUFFIX = "Manage";
	public const String wszCERTEXITMODULE_POSTFIX = ".Exit";
	public const String wszCERTPOLICYMODULE_POSTFIX = ".Policy";
	public const String wszCAPOLICYFILE = "CAPolicy.inf";
	public const String wszINFSECTION_CDP = "CRLDistributionPoint";
	public const String wszINFSECTION_AIA = "AuthorityInformationAccess";
	public const String wszINFSECTION_EKU = "EnhancedKeyUsageExtension";
	public const String wszINFSECTION_CCDP = "CrossCertificateDistributionPointsExtension";
	public const String wszINFSECTION_CERTSERVER = "certsrv_server";
	public const String wszINFKEY_RENEWALKEYLENGTH = "RenewalKeyLength";
	public const String wszINFKEY_RENEWALVALIDITYPERIODSTRING = "RenewalValidityPeriod";
	public const String wszINFKEY_RENEWALVALIDITYPERIODCOUNT = "RenewalValidityPeriodUnits";
	public const String wszINFKEY_UTF8 = "UTF8";
	public const String wszINFKEY_CRLPERIODSTRING = "CRLPeriod";
	public const String wszINFKEY_CRLPERIODCOUNT = "CRLPeriodUnits";
	public const String wszINFKEY_CRLDELTAPERIODSTRING = "CRLDeltaPeriod";
	public const String wszINFKEY_CRLDELTAPERIODCOUNT = "CRLDeltaPeriodUnits";
	public const String wszINFKEY_LOADDEFAULTTEMPLATES = "LoadDefaultTemplates";
	public const String wszINFKEY_ENABLEKEYCOUNTING = "EnableKeyCounting";
	public const String wszINFKEY_FORCEUTF8 = "ForceUTF8";
	public const String wszINFKEY_ALTERNATESIGNATUREALGORITHM = "AlternateSignatureAlgorithm";
	public const String wszINFKEY_SHOWALLCSPS = "ShowAllCSPs";
	public const String wszINFKEY_CRITICAL = "Critical";
	public const String wszINFKEY_EMPTY = "Empty";
	public const String wszINFKEY_CCDPSYNCDELTATIME = "SyncDeltaTime";
	public const String wszINFSECTION_CAPOLICY = "CAPolicy";
	public const String wszINFSECTION_POLICYSTATEMENT = "PolicyStatementExtension";
	public const String wszINFSECTION_APPLICATIONPOLICYSTATEMENT = "ApplicationPolicyStatementExtension";
	public const String wszINFKEY_POLICIES = "Policies";
	public const String wszINFKEY_OID = "OID";
	public const String wszINFKEY_NOTICE = "Notice";
	public const String wszINFKEY_FLAGS = "Flags";
	public const String wszINFSECTION_REQUESTATTRIBUTES = "RequestAttributes";
	public const String wszINFSECTION_NAMECONSTRAINTS = "NameConstraintsExtension";
	public const String wszINFKEY_INCLUDE = "Include";
	public const String wszINFKEY_EXCLUDE = "Exclude";
	public const String wszINFKEY_SUBTREE = "SubTree";
	public const String wszINFKEY_UPN = "UPN";
	public const String wszINFKEY_EMAIL = "EMail";
	public const String wszINFKEY_DNS = "DNS";
	public const String wszINFKEY_DIRECTORYNAME = "DirectoryName";
	public const String wszINFKEY_URL = "URL";
	public const String wszINFKEY_IPADDRESS = "IPAddress";
	public const String wszINFKEY_REGISTEREDID = "RegisteredId";
	public const String wszINFKEY_OTHERNAME = "OtherName";
	public const String wszINFSECTION_POLICYMAPPINGS = "PolicyMappingsExtension";
	public const String wszINFSECTION_APPLICATIONPOLICYMAPPINGS = "ApplicationPolicyMappingsExtension";
	public const String wszINFSECTION_POLICYCONSTRAINTS = "PolicyConstraintsExtension";
	public const String wszINFSECTION_APPLICATIONPOLICYCONSTRAINTS = "ApplicationPolicyConstraintsExtension";
	public const String wszINFKEY_REQUIREEXPLICITPOLICY = "RequireExplicitPolicy";
	public const String wszINFKEY_INHIBITPOLICYMAPPING = "InhibitPolicyMapping";
	public const String wszINFSECTION_BASICCONSTRAINTS = "BasicConstraintsExtension";
	public const String wszINFKEY_PATHLENGTH = "PathLength";
	public const String wszINFSECTION_EXTENSIONS = "Extensions";
	public const String wszINFSECTION_PROPERTIES = "Properties";
	public const String wszINFKEY_CONTINUE = "_continue_";
	public const String wszINFSECTION_NEWREQUEST = "NewRequest";
	public const String wszINFKEY_SUBJECT = "Subject";
	public const String wszINFKEY_SUBJECTNAMEFLAGS = "SubjectNameFlags";
	public const String wszINFKEY_X500NAMEFLAGS = "X500NameFlags";
	public const String wszINFKEY_EXPORTABLE = "Exportable";
	public const String wszINFKEY_EXPORTABLEENCRYPTED = "ExportableEncrypted";
	public const String wszINFKEY_HASHALGORITHM = "HashAlgorithm";
	public const String wszINFKEY_KEYALGORITHM = "KeyAlgorithm";
	public const String wszINFKEY_KEYALGORITHMPARMETERS = "KeyAlgorithmParameters";
	public const String wszINFKEY_KEYCONTAINER = "KeyContainer";
	public const String wszINFKEY_READERNAME = "ReaderName";
	public const String wszINFKEY_KEYLENGTH = "KeyLength";
	public const String wszINFKEY_LEGACYKEYSPEC = "KeySpec";
	public const String wszINFKEY_KEYUSAGEEXTENSION = "KeyUsage";
	public const String wszINFKEY_KEYUSAGEPROPERTY = "KeyUsageProperty";
	public const String wszINFKEY_MACHINEKEYSET = "MachineKeySet";
	public const String wszINFKEY_PRIVATEKEYARCHIVE = "PrivateKeyArchive";
	public const String wszINFKEY_ENCRYPTIONALGORITHM = "EncryptionAlgorithm";
	public const String wszINFKEY_ENCRYPTIONLENGTH = "EncryptionLength";
	public const String wszINFKEY_PROVIDERNAME = "ProviderName";
	public const String wszINFKEY_PROVIDERTYPE = "ProviderType";
	public const String wszINFKEY_RENEWALCERT = "RenewalCert";
	public const String wszINFKEY_REQUESTTYPE = "RequestType";
	public const String wszINFKEY_SECURITYDESCRIPTOR = "SecurityDescriptor";
	public const String wszINFKEY_SILENT = "Silent";
	public const String wszINFKEY_SMIME = "SMIME";
	public const String wszINFKEY_SUPPRESSDEFAULTS = "SuppressDefaults";
	public const String wszINFKEY_USEEXISTINGKEY = "UseExistingKeySet";
	public const String wszINFKEY_USERPROTECTED = "UserProtected";
	public const String wszINFKEY_KEYPROTECTION = "KeyProtection";
	public const String wszINFKEY_UICONTEXTMESSAGE = "UIContextMessage";
	public const String wszINFKEY_FRIENDLYNAME = "FriendlyName";
	public const String wszINFKEY_NOTBEFORE = "NotBefore";
	public const String wszINFKEY_NOTAFTER = "NotAfter";
	public const String wszINFKEY_ATTESTPRIVATEKEY = "AttestPrivateKey";
	public const String wszINFKEY_PUBLICKEY = "PublicKey";
	public const String wszINFKEY_PUBLICKEYPARAMETERS = "PublicKeyParameters";
	public const String wszINFKEY_ECCKEYPARAMETERS = "EccKeyParameters";
	public const String wszINFKEY_ECCKEYPARAMETERS_P = "EccKeyParameters_P";
	public const String wszINFKEY_ECCKEYPARAMETERS_A = "EccKeyParameters_A";
	public const String wszINFKEY_ECCKEYPARAMETERS_B = "EccKeyParameters_B";
	public const String wszINFKEY_ECCKEYPARAMETERS_SEED = "EccKeyParameters_Seed";
	public const String wszINFKEY_ECCKEYPARAMETERS_BASE = "EccKeyParameters_Base";
	public const String wszINFKEY_ECCKEYPARAMETERS_ORDER = "EccKeyParameters_Order";
	public const String wszINFKEY_ECCKEYPARAMETERS_COFACTOR = "EccKeyParameters_Cofactor";
	public const String wszINFKEY_ECCKEYPARAMETERSTYPE = "EccKeyParametersType";
	public const String wszINFKEY_SERIALNUMBER = "SerialNumber";
	public const String wszINFKEY_CATHUMBPRINT = "CAThumbprint";
	public const String wszINFKEY_CACERTS = "CACerts";
	public const String wszINFKEY_CACAPABILITIES = "CACapabilities";
	public const String wszINFKEY_CHALLENGEPASSWORD = "ChallengePassword";
	public const String wszINFVALUE_REQUESTTYPE_PKCS10 = "PKCS10";
	public const String wszINFVALUE_REQUESTTYPE_PKCS7 = "PKCS7";
	public const String wszINFVALUE_REQUESTTYPE_CMC = "CMC";
	public const String wszINFVALUE_REQUESTTYPE_CERT = "Cert";
	public const String wszINFVALUE_REQUESTTYPE_SCEP = "SCEP";
	public const String wszINFVALUE_ENDORSEMENTKEY = "EndorsementKey";
	public const String wszREGEXITSMTPKEY = "SMTP";
	public const String wszREGEXITSMTPTEMPLATES = "Templates";
	public const String wszREGEXITSMTPEVENTFILTER = "EventFilter";
	public const String wszREGEXITSMTPSERVER = "SMTPServer";
	public const String wszREGEXITSMTPAUTHENTICATE = "SMTPAuthenticate";
	public const String wszREGEXITDENIEDKEY = "Denied";
	public const String wszREGEXITISSUEDKEY = "Issued";
	public const String wszREGEXITPENDINGKEY = "Pending";
	public const String wszREGEXITREVOKEDKEY = "Revoked";
	public const String wszREGEXITCRLISSUEDKEY = "CRLIssued";
	public const String wszREGEXITSHUTDOWNKEY = "Shutdown";
	public const String wszREGEXITSTARTUPKEY = "Startup";
	public const String wszREGEXITIMPORTEDKEY = "Imported";
	public const String wszREGEXITSMTPFROM = "From";
	public const String wszREGEXITSMTPTO = "To";
	public const String wszREGEXITSMTPCC = "Cc";
	public const String wszREGEXITTITLEFORMAT = "TitleFormat";
	public const String wszREGEXITTITLEARG = "TitleArg";
	public const String wszREGEXITBODYFORMAT = "BodyFormat";
	public const String wszREGEXITBODYARG = "BodyArg";
	public const String wszREGEXITPROPNOTFOUND = "???";
	public const String wszREGKEYENROLLMENT = "Software\\Microsoft\\Cryptography\\AutoEnrollment";
	public const String wszREGKEYGROUPPOLICYENROLLMENT = "Software\\Policies\\Microsoft\\Cryptography\\AutoEnrollment";
	public const String wszREGMAXPENDINGREQUESTDAYS = "MaxPendingRequestDays";
	public const String wszREGAELOGLEVEL_OLD = "AEEventLogLevel";
	public const String wszREGENROLLFLAGS = "EnrollFlags";
	public const String wszREGVERIFYFLAGS = "VerifyFlags";
	public const String wszREGUNICODE = "Unicode";
	public const String wszREGAIKCLOUDCAURL = "AIKCloudCAURL";
	public const String wszREGAIKKEYALGORITHM = "AIKKeyAlgorithm";
	public const String wszREGAIKKEYLENGTH = "AIKKeyLength";
	public const String wszREGPRESERVESCEPDUMMYCERTS = "PreserveSCEPDummyCerts";
	public const String wszREGALLPROVIDERS = "All";
	public const uint32 TP_MACHINEPOLICY = 1;
	public const String wszREGKEYREPAIR = "KeyRepair";
	public const uint32 KR_ENABLE_MACHINE = 1;
	public const uint32 KR_ENABLE_USER = 2;
	public const String wszPROPDISTINGUISHEDNAME = "DistinguishedName";
	public const String wszPROPRAWNAME = "RawName";
	public const String wszPROPCOUNTRY = "Country";
	public const String wszPROPORGANIZATION = "Organization";
	public const String wszPROPORGUNIT = "OrgUnit";
	public const String wszPROPCOMMONNAME = "CommonName";
	public const String wszPROPLOCALITY = "Locality";
	public const String wszPROPSTATE = "State";
	public const String wszPROPTITLE = "Title";
	public const String wszPROPGIVENNAME = "GivenName";
	public const String wszPROPINITIALS = "Initials";
	public const String wszPROPSURNAME = "SurName";
	public const String wszPROPDOMAINCOMPONENT = "DomainComponent";
	public const String wszPROPEMAIL = "EMail";
	public const String wszPROPSTREETADDRESS = "StreetAddress";
	public const String wszPROPUNSTRUCTUREDNAME = "UnstructuredName";
	public const String wszPROPUNSTRUCTUREDADDRESS = "UnstructuredAddress";
	public const String wszPROPDEVICESERIALNUMBER = "DeviceSerialNumber";
	public const String wszPROPSUBJECTDOT = "Subject.";
	public const String wszPROPREQUESTDOT = "Request.";
	public const String wszPROPREQUESTREQUESTID = "RequestID";
	public const String wszPROPREQUESTRAWREQUEST = "RawRequest";
	public const String wszPROPREQUESTRAWARCHIVEDKEY = "RawArchivedKey";
	public const String wszPROPREQUESTARCHIVEDKEY = "ArchivedKey";
	public const String wszPROPREQUESTKEYRECOVERYHASHES = "KeyRecoveryHashes";
	public const String wszPROPREQUESTRAWOLDCERTIFICATE = "RawOldCertificate";
	public const String wszPROPREQUESTATTRIBUTES = "RequestAttributes";
	public const String wszPROPREQUESTTYPE = "RequestType";
	public const String wszPROPREQUESTFLAGS = "RequestFlags";
	public const String wszPROPREQUESTSTATUSCODE = "StatusCode";
	public const String wszPROPREQUESTDISPOSITION = "Disposition";
	public const String wszPROPREQUESTDISPOSITIONMESSAGE = "DispositionMessage";
	public const String wszPROPREQUESTSUBMITTEDWHEN = "SubmittedWhen";
	public const String wszPROPREQUESTRESOLVEDWHEN = "ResolvedWhen";
	public const String wszPROPREQUESTREVOKEDWHEN = "RevokedWhen";
	public const String wszPROPREQUESTREVOKEDEFFECTIVEWHEN = "RevokedEffectiveWhen";
	public const String wszPROPREQUESTREVOKEDREASON = "RevokedReason";
	public const String wszPROPREQUESTERNAME = "RequesterName";
	public const String wszPROPCALLERNAME = "CallerName";
	public const String wszPROPSIGNERPOLICIES = "SignerPolicies";
	public const String wszPROPSIGNERAPPLICATIONPOLICIES = "SignerApplicationPolicies";
	public const String wszPROPOFFICER = "Officer";
	public const String wszPROPPUBLISHEXPIREDCERTINCRL = "PublishExpiredCertInCRL";
	public const String wszPROPREQUESTERNAMEFROMOLDCERTIFICATE = "RequesterNameFromOldCertificate";
	public const String wszPROPATTESTATIONCHALLENGE = "AttestationChallenge";
	public const String wszPROPENDORSEMENTKEYHASH = "EndorsementKeyHash";
	public const String wszPROPENDORSEMENTCERTIFICATEHASH = "EndorsementCertificateHash";
	public const String wszPROPRAWPRECERTIFICATE = "RawPrecertificate";
	public const String wszPROPCHALLENGE = "Challenge";
	public const String wszPROPEXPECTEDCHALLENGE = "ExpectedChallenge";
	public const String wszPROPDISPOSITION = "Disposition";
	public const String wszPROPDISPOSITIONDENY = "Deny";
	public const String wszPROPDISPOSITIONPENDING = "Pending";
	public const String wszPROPVALIDITYPERIODSTRING = "ValidityPeriod";
	public const String wszPROPVALIDITYPERIODCOUNT = "ValidityPeriodUnits";
	public const String wszPROPEXPIRATIONDATE = "ExpirationDate";
	public const String wszPROPCERTTYPE = "CertType";
	public const String wszPROPCERTTEMPLATE = "CertificateTemplate";
	public const String wszPROPCERTUSAGE = "CertificateUsage";
	public const String wszPROPREQUESTOSVERSION = "RequestOSVersion";
	public const String wszPROPREQUESTCSPPROVIDER = "RequestCSPProvider";
	public const String wszPROPEXITCERTFILE = "CertFile";
	public const String wszPROPCLIENTBROWSERMACHINE = "cbm";
	public const String wszPROPCERTCLIENTMACHINE = "ccm";
	public const String wszPROPCLIENTDCDNS = "cdc";
	public const String wszPROPREQUESTMACHINEDNS = "rmd";
	public const String wszPROPSUBJECTALTNAME2 = "san";
	public const String wszPROPDNS = "dns";
	public const String wszPROPDN = "dn";
	public const String wszPROPURL = "url";
	public const String wszPROPIPADDRESS = "ipaddress";
	public const String wszPROPGUID = "guid";
	public const String wszPROPOID = "oid";
	public const String wszPROPUPN = "upn";
	public const String szPROPASNTAG = "{asn}";
	public const String wszPROPCRITICALTAG = "{critical}";
	public const String wszPROPUTF8TAG = "{utf8}";
	public const String wszPROPOCTETTAG = "{octet}";
	public const String wszPROPHEXTAG = "{hex}";
	public const String wszPROPTEXTTAG = "{text}";
	public const String wszPROPDECIMALTAG = "{decimal}";
	public const String wszPROPFILETAG = "{file}";
	public const String wszAT_EKCERTINF = "@EKCert";
	public const String wszAT_TESTROOT = "@TestRoot";
	public const String wszPROPCATYPE = "CAType";
	public const String wszPROPSANITIZEDCANAME = "SanitizedCAName";
	public const String wszPROPSANITIZEDSHORTNAME = "SanitizedShortName";
	public const String wszPROPMACHINEDNSNAME = "MachineDNSName";
	public const String wszPROPMODULEREGLOC = "ModuleRegistryLocation";
	public const String wszPROPUSEDS = "fUseDS";
	public const String wszPROPDELTACRLSDISABLED = "fDeltaCRLsDisabled";
	public const String wszPROPSERVERUPGRADED = "fServerUpgraded";
	public const String wszPROPCONFIGDN = "ConfigDN";
	public const String wszPROPDOMAINDN = "DomainDN";
	public const String wszPROPLOGLEVEL = "LogLevel";
	public const String wszPROPSESSIONCOUNT = "SessionCount";
	public const String wszPROPTEMPLATECHANGESEQUENCENUMBER = "TemplateChangeSequenceNumber";
	public const String wszPROPVOLATILEMODE = "VolatileMode";
	public const String wszLOCALIZEDTIMEPERIODUNITS = "LocalizedTimePeriodUnits";
	public const String wszPROPREQUESTERCAACCESS = "RequesterCAAccess";
	public const String wszPROPUSERDN = "UserDN";
	public const String wszPROPKEYARCHIVED = "KeyArchived";
	public const String wszPROPCERTCOUNT = "CertCount";
	public const String wszPROPRAWCACERTIFICATE = "RawCACertificate";
	public const String wszPROPCERTSTATE = "CertState";
	public const String wszPROPCERTSUFFIX = "CertSuffix";
	public const String wszPROPRAWCRL = "RawCRL";
	public const String wszPROPRAWDELTACRL = "RawDeltaCRL";
	public const String wszPROPCRLINDEX = "CRLIndex";
	public const String wszPROPCRLSTATE = "CRLState";
	public const String wszPROPCRLSUFFIX = "CRLSuffix";
	public const String wszPROPEVENTLOGTERSE = "EventLogTerse";
	public const String wszPROPEVENTLOGERROR = "EventLogError";
	public const String wszPROPEVENTLOGWARNING = "EventLogWarning";
	public const String wszPROPEVENTLOGVERBOSE = "EventLogVerbose";
	public const String wszPROPEVENTLOGEXHAUSTIVE = "EventLogExhaustive";
	public const String wszPROPDCNAME = "DCName";
	public const String wszPROPCROSSFOREST = "CrossForest";
	public const String wszPROPREQUESTERSAMNAME = "RequesterSAMName";
	public const String wszPROPREQUESTERUPN = "RequesterUPN";
	public const String wszPROPREQUESTERDN = "RequesterDN";
	public const String wszPROPSEAUDITID = "SEAuditId";
	public const String wszPROPSEAUDITFILTER = "SEAuditFilter";
	public const String wszPROPCERTIFICATEREQUESTID = "RequestID";
	public const String wszPROPRAWCERTIFICATE = "RawCertificate";
	public const String wszPROPCERTIFICATEHASH = "CertificateHash";
	public const String wszPROPCERTIFICATETEMPLATE = "CertificateTemplate";
	public const String wszPROPCERTIFICATEENROLLMENTFLAGS = "EnrollmentFlags";
	public const String wszPROPCERTIFICATEGENERALFLAGS = "GeneralFlags";
	public const String wszPROPCERTIFICATEPRIVATEKEYFLAGS = "PrivatekeyFlags";
	public const String wszPROPCERTIFICATESERIALNUMBER = "SerialNumber";
	public const String wszPROPCERTIFICATENOTBEFOREDATE = "NotBefore";
	public const String wszPROPCERTIFICATENOTAFTERDATE = "NotAfter";
	public const String wszPROPCERTIFICATESUBJECTKEYIDENTIFIER = "SubjectKeyIdentifier";
	public const String wszPROPCERTIFICATERAWPUBLICKEY = "RawPublicKey";
	public const String wszPROPCERTIFICATEPUBLICKEYLENGTH = "PublicKeyLength";
	public const String wszPROPCERTIFICATEPUBLICKEYALGORITHM = "PublicKeyAlgorithm";
	public const String wszPROPCERTIFICATERAWPUBLICKEYALGORITHMPARAMETERS = "RawPublicKeyAlgorithmParameters";
	public const String wszPROPCERTIFICATEUPN = "UPN";
	public const String wszPROPCERTIFICATETYPE = "CertificateType";
	public const String wszPROPCERTIFICATERAWSMIMECAPABILITIES = "RawSMIMECapabilities";
	public const String wszPROPNAMETYPE = "NameType";
	public const uint32 EXTENSION_CRITICAL_FLAG = 1;
	public const uint32 EXTENSION_DISABLE_FLAG = 2;
	public const uint32 EXTENSION_DELETE_FLAG = 4;
	public const uint32 EXTENSION_POLICY_MASK = 65535;
	public const uint32 EXTENSION_ORIGIN_REQUEST = 65536;
	public const uint32 EXTENSION_ORIGIN_POLICY = 131072;
	public const uint32 EXTENSION_ORIGIN_ADMIN = 196608;
	public const uint32 EXTENSION_ORIGIN_SERVER = 262144;
	public const uint32 EXTENSION_ORIGIN_RENEWALCERT = 327680;
	public const uint32 EXTENSION_ORIGIN_IMPORTEDCERT = 393216;
	public const uint32 EXTENSION_ORIGIN_PKCS7 = 458752;
	public const uint32 EXTENSION_ORIGIN_CMC = 524288;
	public const uint32 EXTENSION_ORIGIN_CACERT = 589824;
	public const uint32 EXTENSION_ORIGIN_MASK = 983040;
	public const String wszPROPEXTREQUESTID = "ExtensionRequestId";
	public const String wszPROPEXTNAME = "ExtensionName";
	public const String wszPROPEXTFLAGS = "ExtensionFlags";
	public const String wszPROPEXTRAWVALUE = "ExtensionRawValue";
	public const String wszPROPATTRIBREQUESTID = "AttributeRequestId";
	public const String wszPROPATTRIBNAME = "AttributeName";
	public const String wszPROPATTRIBVALUE = "AttributeValue";
	public const String wszPROPCRLROWID = "CRLRowId";
	public const String wszPROPCRLNUMBER = "CRLNumber";
	public const String wszPROPCRLMINBASE = "CRLMinBase";
	public const String wszPROPCRLNAMEID = "CRLNameId";
	public const String wszPROPCRLCOUNT = "CRLCount";
	public const String wszPROPCRLTHISUPDATE = "CRLThisUpdate";
	public const String wszPROPCRLNEXTUPDATE = "CRLNextUpdate";
	public const String wszPROPCRLTHISPUBLISH = "CRLThisPublish";
	public const String wszPROPCRLNEXTPUBLISH = "CRLNextPublish";
	public const String wszPROPCRLEFFECTIVE = "CRLEffective";
	public const String wszPROPCRLPROPAGATIONCOMPLETE = "CRLPropagationComplete";
	public const String wszPROPCRLLASTPUBLISHED = "CRLLastPublished";
	public const String wszPROPCRLPUBLISHATTEMPTS = "CRLPublishAttempts";
	public const String wszPROPCRLPUBLISHFLAGS = "CRLPublishFlags";
	public const String wszPROPCRLPUBLISHSTATUSCODE = "CRLPublishStatusCode";
	public const String wszPROPCRLPUBLISHERROR = "CRLPublishError";
	public const String wszPROPCRLRAWCRL = "CRLRawCRL";
	public const uint32 CPF_BASE = 1;
	public const uint32 CPF_DELTA = 2;
	public const uint32 CPF_COMPLETE = 4;
	public const uint32 CPF_SHADOW = 8;
	public const uint32 CPF_CASTORE_ERROR = 16;
	public const uint32 CPF_BADURL_ERROR = 32;
	public const uint32 CPF_MANUAL = 64;
	public const uint32 CPF_SIGNATURE_ERROR = 128;
	public const uint32 CPF_LDAP_ERROR = 256;
	public const uint32 CPF_FILE_ERROR = 512;
	public const uint32 CPF_FTP_ERROR = 1024;
	public const uint32 CPF_HTTP_ERROR = 2048;
	public const uint32 CPF_POSTPONED_BASE_LDAP_ERROR = 4096;
	public const uint32 CPF_POSTPONED_BASE_FILE_ERROR = 8192;
	public const uint32 PROPTYPE_MASK = 255;
	public const uint32 PROPCALLER_SERVER = 256;
	public const uint32 PROPCALLER_POLICY = 512;
	public const uint32 PROPCALLER_EXIT = 768;
	public const uint32 PROPCALLER_ADMIN = 1024;
	public const uint32 PROPCALLER_REQUEST = 1280;
	public const uint32 PROPCALLER_MASK = 3840;
	public const uint32 PROPFLAGS_INDEXED = 65536;
	public const uint32 CR_FLG_FORCETELETEX = 1;
	public const uint32 CR_FLG_RENEWAL = 2;
	public const uint32 CR_FLG_FORCEUTF8 = 4;
	public const uint32 CR_FLG_CAXCHGCERT = 8;
	public const uint32 CR_FLG_ENROLLONBEHALFOF = 16;
	public const uint32 CR_FLG_SUBJECTUNMODIFIED = 32;
	public const uint32 CR_FLG_VALIDENCRYPTEDKEYHASH = 64;
	public const uint32 CR_FLG_CACROSSCERT = 128;
	public const uint32 CR_FLG_ENFORCEUTF8 = 256;
	public const uint32 CR_FLG_DEFINEDCACERT = 512;
	public const uint32 CR_FLG_CHALLENGEPENDING = 1024;
	public const uint32 CR_FLG_CHALLENGESATISFIED = 2048;
	public const uint32 CR_FLG_TRUSTONUSE = 4096;
	public const uint32 CR_FLG_TRUSTEKCERT = 8192;
	public const uint32 CR_FLG_TRUSTEKKEY = 16384;
	public const uint32 CR_FLG_PUBLISHERROR = 2147483648;
	public const uint32 DB_DISP_ACTIVE = 8;
	public const uint32 DB_DISP_PENDING = 9;
	public const uint32 DB_DISP_QUEUE_MAX = 9;
	public const uint32 DB_DISP_FOREIGN = 12;
	public const uint32 DB_DISP_CA_CERT = 15;
	public const uint32 DB_DISP_CA_CERT_CHAIN = 16;
	public const uint32 DB_DISP_KRA_CERT = 17;
	public const uint32 DB_DISP_LOG_MIN = 20;
	public const uint32 DB_DISP_ISSUED = 20;
	public const uint32 DB_DISP_REVOKED = 21;
	public const uint32 DB_DISP_LOG_FAILED_MIN = 30;
	public const uint32 DB_DISP_ERROR = 30;
	public const uint32 DB_DISP_DENIED = 31;
	public const uint32 VR_PENDING = 0;
	public const uint32 VR_INSTANT_OK = 1;
	public const uint32 VR_INSTANT_BAD = 2;
	public const String wszCERT_TYPE = "RequestType";
	public const String wszCERT_TYPE_CLIENT = "Client";
	public const String wszCERT_TYPE_SERVER = "Server";
	public const String wszCERT_TYPE_CODESIGN = "CodeSign";
	public const String wszCERT_TYPE_CUSTOMER = "SetCustomer";
	public const String wszCERT_TYPE_MERCHANT = "SetMerchant";
	public const String wszCERT_TYPE_PAYMENT = "SetPayment";
	public const String wszCERT_VERSION = "Version";
	public const String wszCERT_VERSION_1 = "1";
	public const String wszCERT_VERSION_2 = "2";
	public const String wszCERT_VERSION_3 = "3";
	public const uint32 CV_OUT_HEXRAW = 12;
	public const uint32 CV_OUT_ENCODEMASK = 255;
	public const uint32 CV_OUT_NOCRLF = 1073741824;
	public const uint32 CV_OUT_NOCR = 2147483648;
	public const uint32 CVR_SEEK_NONE = 0;
	public const uint32 CVR_SEEK_MASK = 255;
	public const uint32 CVR_SEEK_NODELTA = 4096;
	public const uint32 CVR_SORT_NONE = 0;
	public const uint32 CVR_SORT_ASCEND = 1;
	public const uint32 CVR_SORT_DESCEND = 2;
	public const int32 CV_COLUMN_EXTENSION_DEFAULT = -4;
	public const int32 CV_COLUMN_ATTRIBUTE_DEFAULT = -5;
	public const int32 CV_COLUMN_CRL_DEFAULT = -6;
	public const int32 CV_COLUMN_LOG_REVOKED_DEFAULT = -7;
	public const uint32 CVRC_TABLE_MASK = 61440;
	public const uint32 CVRC_TABLE_SHIFT = 12;
	public const uint32 CRYPT_ENUM_ALL_PROVIDERS = 1;
	public const int32 XEPR_ENUM_FIRST = -1;
	public const uint32 XEPR_DATE = 5;
	public const uint32 XEPR_TEMPLATENAME = 6;
	public const uint32 XEPR_VERSION = 7;
	public const uint32 XEPR_V1TEMPLATENAME = 9;
	public const uint32 XEPR_V2TEMPLATEOID = 16;
	public const uint32 XEKL_KEYSIZE_DEFAULT = 4;
	public const uint32 XECP_STRING_PROPERTY = 1;
	public const uint32 XECI_DISABLE = 0;
	public const uint32 XECI_XENROLL = 1;
	public const uint32 XECI_AUTOENROLL = 2;
	public const uint32 XECI_REQWIZARD = 3;
	public const uint32 XECI_CERTREQ = 4;
	public const String wszCMM_PROP_NAME = "Name";
	public const String wszCMM_PROP_DESCRIPTION = "Description";
	public const String wszCMM_PROP_COPYRIGHT = "Copyright";
	public const String wszCMM_PROP_FILEVER = "File Version";
	public const String wszCMM_PROP_PRODUCTVER = "Product Version";
	public const String wszCMM_PROP_DISPLAY_HWND = "HWND";
	public const String wszCMM_PROP_ISMULTITHREADED = "IsMultiThreaded";
}
#endregion

#region Enums

[AllowDuplicates]
public enum CERT_VIEW_COLUMN_INDEX : int32
{
	CV_COLUMN_LOG_DEFAULT = -2,
	CV_COLUMN_LOG_FAILED_DEFAULT = -3,
	CV_COLUMN_QUEUE_DEFAULT = -1,
}


[AllowDuplicates]
public enum CERT_DELETE_ROW_FLAGS : uint32
{
	CDR_EXPIRED = 1,
	CDR_REQUEST_LAST_CHANGED = 2,
}


[AllowDuplicates]
public enum FULL_RESPONSE_PROPERTY_ID : uint32
{
	FR_PROP_NONE = 0,
	FR_PROP_FULLRESPONSE = 1,
	FR_PROP_STATUSINFOCOUNT = 2,
	FR_PROP_BODYPARTSTRING = 3,
	FR_PROP_STATUS = 4,
	FR_PROP_STATUSSTRING = 5,
	FR_PROP_OTHERINFOCHOICE = 6,
	FR_PROP_FAILINFO = 7,
	FR_PROP_PENDINFOTOKEN = 8,
	FR_PROP_PENDINFOTIME = 9,
	FR_PROP_ISSUEDCERTIFICATEHASH = 10,
	FR_PROP_ISSUEDCERTIFICATE = 11,
	FR_PROP_ISSUEDCERTIFICATECHAIN = 12,
	FR_PROP_ISSUEDCERTIFICATECRLCHAIN = 13,
	FR_PROP_ENCRYPTEDKEYHASH = 14,
	FR_PROP_FULLRESPONSENOPKCS7 = 15,
	FR_PROP_CAEXCHANGECERTIFICATEHASH = 16,
	FR_PROP_CAEXCHANGECERTIFICATE = 17,
	FR_PROP_CAEXCHANGECERTIFICATECHAIN = 18,
	FR_PROP_CAEXCHANGECERTIFICATECRLCHAIN = 19,
	FR_PROP_ATTESTATIONCHALLENGE = 20,
	FR_PROP_ATTESTATIONPROVIDERNAME = 21,
}


[AllowDuplicates]
public enum CVRC_COLUMN : uint32
{
	CVRC_COLUMN_SCHEMA = 0,
	CVRC_COLUMN_RESULT = 1,
	CVRC_COLUMN_VALUE = 2,
	CVRC_COLUMN_MASK = 4095,
}


[AllowDuplicates]
public enum CERT_IMPORT_FLAGS : uint32
{
	CR_IN_BASE64HEADER = 0,
	CR_IN_BASE64 = 1,
	CR_IN_BINARY = 2,
}


[AllowDuplicates]
public enum CERT_GET_CONFIG_FLAGS : uint32
{
	CC_DEFAULTCONFIG = 0,
	CC_FIRSTCONFIG = 2,
	CC_LOCALACTIVECONFIG = 4,
	CC_LOCALCONFIG = 3,
	CC_UIPICKCONFIG = 1,
	CC_UIPICKCONFIGSKIPLOCALCA = 5,
}


[AllowDuplicates]
public enum ENUM_CERT_COLUMN_VALUE_FLAGS : uint32
{
	CV_OUT_BASE64 = 1,
	CV_OUT_BASE64HEADER = 0,
	CV_OUT_BASE64REQUESTHEADER = 3,
	CV_OUT_BASE64X509CRLHEADER = 9,
	CV_OUT_BINARY = 2,
	CV_OUT_HEX = 4,
	CV_OUT_HEXADDR = 10,
	CV_OUT_HEXASCII = 5,
	CV_OUT_HEXASCIIADDR = 11,
}


[AllowDuplicates]
public enum PENDING_REQUEST_DESIRED_PROPERTY : uint32
{
	XEPR_CADNS = 1,
	XEPR_CAFRIENDLYNAME = 3,
	XEPR_CANAME = 2,
	XEPR_HASH = 8,
	XEPR_REQUESTID = 4,
}


[AllowDuplicates]
public enum CERTADMIN_GET_ROLES_FLAGS : uint32
{
	CA_ACCESS_ADMIN = 1,
	CA_ACCESS_AUDITOR = 4,
	CA_ACCESS_ENROLL = 512,
	CA_ACCESS_OFFICER = 2,
	CA_ACCESS_OPERATOR = 8,
	CA_ACCESS_READ = 256,
}


[AllowDuplicates]
public enum CR_DISP : uint32
{
	CR_DISP_DENIED = 2,
	CR_DISP_ERROR = 1,
	CR_DISP_INCOMPLETE = 0,
	CR_DISP_ISSUED = 3,
	CR_DISP_ISSUED_OUT_OF_BAND = 4,
	CR_DISP_UNDER_SUBMISSION = 5,
}


[AllowDuplicates]
public enum XEKL_KEYSIZE : uint32
{
	XEKL_KEYSIZE_MIN = 1,
	XEKL_KEYSIZE_MAX = 2,
	XEKL_KEYSIZE_INC = 3,
}


[AllowDuplicates]
public enum CERT_CREATE_REQUEST_FLAGS : uint32
{
	XECR_CMC = 3,
	XECR_PKCS10_V1_5 = 4,
	XECR_PKCS10_V2_0 = 1,
	XECR_PKCS7 = 2,
}


[AllowDuplicates]
public enum CERT_EXIT_EVENT_MASK : uint32
{
	EXITEVENT_CERTDENIED = 4,
	EXITEVENT_CERTISSUED = 1,
	EXITEVENT_CERTPENDING = 2,
	EXITEVENT_CERTRETRIEVEPENDING = 16,
	EXITEVENT_CERTREVOKED = 8,
	EXITEVENT_CRLISSUED = 32,
	EXITEVENT_SHUTDOWN = 64,
}


[AllowDuplicates]
public enum ADDED_CERT_TYPE : uint32
{
	XECT_EXTENSION_V1 = 1,
	XECT_EXTENSION_V2 = 2,
}


[AllowDuplicates]
public enum CVRC_TABLE : uint32
{
	CVRC_TABLE_ATTRIBUTES = 16384,
	CVRC_TABLE_CRL = 20480,
	CVRC_TABLE_EXTENSIONS = 12288,
	CVRC_TABLE_REQCERT = 0,
}


[AllowDuplicates]
public enum CERT_PROPERTY_TYPE : uint32
{
	PROPTYPE_BINARY = 3,
	PROPTYPE_DATE = 2,
	PROPTYPE_LONG = 1,
	PROPTYPE_STRING = 4,
}


[AllowDuplicates]
public enum CERT_ALT_NAME : uint32
{
	CERT_ALT_NAME_RFC822_NAME = 2,
	CERT_ALT_NAME_DNS_NAME = 3,
	CERT_ALT_NAME_URL = 7,
	CERT_ALT_NAME_REGISTERED_ID = 9,
	CERT_ALT_NAME_DIRECTORY_NAME = 5,
	CERT_ALT_NAME_IP_ADDRESS = 8,
	CERT_ALT_NAME_OTHER_NAME = 1,
}


[AllowDuplicates]
public enum CSBACKUP_TYPE : uint32
{
	CSBACKUP_TYPE_FULL = 1,
	CSBACKUP_TYPE_LOGS_ONLY = 2,
}


[AllowDuplicates]
public enum XEKL_KEYSPEC : uint32
{
	XEKL_KEYSPEC_KEYX = 1,
	XEKL_KEYSPEC_SIG = 2,
}


[AllowDuplicates]
public enum CERT_REQUEST_OUT_TYPE : uint32
{
	CR_OUT_BASE64HEADER = 0,
	CR_OUT_BASE64 = 1,
	CR_OUT_BINARY = 2,
}


[AllowDuplicates]
public enum CERT_VIEW_SEEK_OPERATOR_FLAGS : uint32
{
	CVR_SEEK_EQ = 1,
	CVR_SEEK_LE = 4,
	CVR_SEEK_LT = 2,
	CVR_SEEK_GE = 8,
	CVR_SEEK_GT = 16,
}


[AllowDuplicates]
public enum OCSPSigningFlag : int32
{
	OCSP_SF_SILENT = 1,
	OCSP_SF_USE_CACERT = 2,
	OCSP_SF_ALLOW_SIGNINGCERT_AUTORENEWAL = 4,
	OCSP_SF_FORCE_SIGNINGCERT_ISSUER_ISCA = 8,
	OCSP_SF_AUTODISCOVER_SIGNINGCERT = 16,
	OCSP_SF_MANUAL_ASSIGN_SIGNINGCERT = 32,
	OCSP_SF_RESPONDER_ID_KEYHASH = 64,
	OCSP_SF_RESPONDER_ID_NAME = 128,
	OCSP_SF_ALLOW_NONCE_EXTENSION = 256,
	OCSP_SF_ALLOW_SIGNINGCERT_AUTOENROLLMENT = 512,
}


[AllowDuplicates]
public enum OCSPRequestFlag : int32
{
	OCSP_RF_REJECT_SIGNED_REQUESTS = 1,
}


[AllowDuplicates]
public enum X509EnrollmentAuthFlags : int32
{
	X509AuthNone = 0,
	X509AuthAnonymous = 1,
	X509AuthKerberos = 2,
	X509AuthUsername = 4,
	X509AuthCertificate = 8,
}


[AllowDuplicates]
public enum X509SCEPMessageType : int32
{
	SCEPMessageUnknown = -1,
	SCEPMessageCertResponse = 3,
	SCEPMessagePKCSRequest = 19,
	SCEPMessageGetCertInitial = 20,
	SCEPMessageGetCert = 21,
	SCEPMessageGetCRL = 22,
	SCEPMessageClaimChallengeAnswer = 41,
}


[AllowDuplicates]
public enum X509SCEPDisposition : int32
{
	SCEPDispositionUnknown = -1,
	SCEPDispositionSuccess = 0,
	SCEPDispositionFailure = 2,
	SCEPDispositionPending = 3,
	SCEPDispositionPendingChallenge = 11,
}


[AllowDuplicates]
public enum X509SCEPFailInfo : int32
{
	SCEPFailUnknown = -1,
	SCEPFailBadAlgorithm = 0,
	SCEPFailBadMessageCheck = 1,
	SCEPFailBadRequest = 2,
	SCEPFailBadTime = 3,
	SCEPFailBadCertId = 4,
}


[AllowDuplicates]
public enum CERTENROLL_OBJECTID : int32
{
	XCN_OID_NONE = 0,
	XCN_OID_RSA = 1,
	XCN_OID_PKCS = 2,
	XCN_OID_RSA_HASH = 3,
	XCN_OID_RSA_ENCRYPT = 4,
	XCN_OID_PKCS_1 = 5,
	XCN_OID_PKCS_2 = 6,
	XCN_OID_PKCS_3 = 7,
	XCN_OID_PKCS_4 = 8,
	XCN_OID_PKCS_5 = 9,
	XCN_OID_PKCS_6 = 10,
	XCN_OID_PKCS_7 = 11,
	XCN_OID_PKCS_8 = 12,
	XCN_OID_PKCS_9 = 13,
	XCN_OID_PKCS_10 = 14,
	XCN_OID_PKCS_12 = 15,
	XCN_OID_RSA_RSA = 16,
	XCN_OID_RSA_MD2RSA = 17,
	XCN_OID_RSA_MD4RSA = 18,
	XCN_OID_RSA_MD5RSA = 19,
	XCN_OID_RSA_SHA1RSA = 20,
	XCN_OID_RSA_SETOAEP_RSA = 21,
	XCN_OID_RSA_DH = 22,
	XCN_OID_RSA_data = 23,
	XCN_OID_RSA_signedData = 24,
	XCN_OID_RSA_envelopedData = 25,
	XCN_OID_RSA_signEnvData = 26,
	XCN_OID_RSA_digestedData = 27,
	XCN_OID_RSA_hashedData = 28,
	XCN_OID_RSA_encryptedData = 29,
	XCN_OID_RSA_emailAddr = 30,
	XCN_OID_RSA_unstructName = 31,
	XCN_OID_RSA_contentType = 32,
	XCN_OID_RSA_messageDigest = 33,
	XCN_OID_RSA_signingTime = 34,
	XCN_OID_RSA_counterSign = 35,
	XCN_OID_RSA_challengePwd = 36,
	XCN_OID_RSA_unstructAddr = 37,
	XCN_OID_RSA_extCertAttrs = 38,
	XCN_OID_RSA_certExtensions = 39,
	XCN_OID_RSA_SMIMECapabilities = 40,
	XCN_OID_RSA_preferSignedData = 41,
	XCN_OID_RSA_SMIMEalg = 42,
	XCN_OID_RSA_SMIMEalgESDH = 43,
	XCN_OID_RSA_SMIMEalgCMS3DESwrap = 44,
	XCN_OID_RSA_SMIMEalgCMSRC2wrap = 45,
	XCN_OID_RSA_MD2 = 46,
	XCN_OID_RSA_MD4 = 47,
	XCN_OID_RSA_MD5 = 48,
	XCN_OID_RSA_RC2CBC = 49,
	XCN_OID_RSA_RC4 = 50,
	XCN_OID_RSA_DES_EDE3_CBC = 51,
	XCN_OID_RSA_RC5_CBCPad = 52,
	XCN_OID_ANSI_X942 = 53,
	XCN_OID_ANSI_X942_DH = 54,
	XCN_OID_X957 = 55,
	XCN_OID_X957_DSA = 56,
	XCN_OID_X957_SHA1DSA = 57,
	XCN_OID_DS = 58,
	XCN_OID_DSALG = 59,
	XCN_OID_DSALG_CRPT = 60,
	XCN_OID_DSALG_HASH = 61,
	XCN_OID_DSALG_SIGN = 62,
	XCN_OID_DSALG_RSA = 63,
	XCN_OID_OIW = 64,
	XCN_OID_OIWSEC = 65,
	XCN_OID_OIWSEC_md4RSA = 66,
	XCN_OID_OIWSEC_md5RSA = 67,
	XCN_OID_OIWSEC_md4RSA2 = 68,
	XCN_OID_OIWSEC_desECB = 69,
	XCN_OID_OIWSEC_desCBC = 70,
	XCN_OID_OIWSEC_desOFB = 71,
	XCN_OID_OIWSEC_desCFB = 72,
	XCN_OID_OIWSEC_desMAC = 73,
	XCN_OID_OIWSEC_rsaSign = 74,
	XCN_OID_OIWSEC_dsa = 75,
	XCN_OID_OIWSEC_shaDSA = 76,
	XCN_OID_OIWSEC_mdc2RSA = 77,
	XCN_OID_OIWSEC_shaRSA = 78,
	XCN_OID_OIWSEC_dhCommMod = 79,
	XCN_OID_OIWSEC_desEDE = 80,
	XCN_OID_OIWSEC_sha = 81,
	XCN_OID_OIWSEC_mdc2 = 82,
	XCN_OID_OIWSEC_dsaComm = 83,
	XCN_OID_OIWSEC_dsaCommSHA = 84,
	XCN_OID_OIWSEC_rsaXchg = 85,
	XCN_OID_OIWSEC_keyHashSeal = 86,
	XCN_OID_OIWSEC_md2RSASign = 87,
	XCN_OID_OIWSEC_md5RSASign = 88,
	XCN_OID_OIWSEC_sha1 = 89,
	XCN_OID_OIWSEC_dsaSHA1 = 90,
	XCN_OID_OIWSEC_dsaCommSHA1 = 91,
	XCN_OID_OIWSEC_sha1RSASign = 92,
	XCN_OID_OIWDIR = 93,
	XCN_OID_OIWDIR_CRPT = 94,
	XCN_OID_OIWDIR_HASH = 95,
	XCN_OID_OIWDIR_SIGN = 96,
	XCN_OID_OIWDIR_md2 = 97,
	XCN_OID_OIWDIR_md2RSA = 98,
	XCN_OID_INFOSEC = 99,
	XCN_OID_INFOSEC_sdnsSignature = 100,
	XCN_OID_INFOSEC_mosaicSignature = 101,
	XCN_OID_INFOSEC_sdnsConfidentiality = 102,
	XCN_OID_INFOSEC_mosaicConfidentiality = 103,
	XCN_OID_INFOSEC_sdnsIntegrity = 104,
	XCN_OID_INFOSEC_mosaicIntegrity = 105,
	XCN_OID_INFOSEC_sdnsTokenProtection = 106,
	XCN_OID_INFOSEC_mosaicTokenProtection = 107,
	XCN_OID_INFOSEC_sdnsKeyManagement = 108,
	XCN_OID_INFOSEC_mosaicKeyManagement = 109,
	XCN_OID_INFOSEC_sdnsKMandSig = 110,
	XCN_OID_INFOSEC_mosaicKMandSig = 111,
	XCN_OID_INFOSEC_SuiteASignature = 112,
	XCN_OID_INFOSEC_SuiteAConfidentiality = 113,
	XCN_OID_INFOSEC_SuiteAIntegrity = 114,
	XCN_OID_INFOSEC_SuiteATokenProtection = 115,
	XCN_OID_INFOSEC_SuiteAKeyManagement = 116,
	XCN_OID_INFOSEC_SuiteAKMandSig = 117,
	XCN_OID_INFOSEC_mosaicUpdatedSig = 118,
	XCN_OID_INFOSEC_mosaicKMandUpdSig = 119,
	XCN_OID_INFOSEC_mosaicUpdatedInteg = 120,
	XCN_OID_COMMON_NAME = 121,
	XCN_OID_SUR_NAME = 122,
	XCN_OID_DEVICE_SERIAL_NUMBER = 123,
	XCN_OID_COUNTRY_NAME = 124,
	XCN_OID_LOCALITY_NAME = 125,
	XCN_OID_STATE_OR_PROVINCE_NAME = 126,
	XCN_OID_STREET_ADDRESS = 127,
	XCN_OID_ORGANIZATION_NAME = 128,
	XCN_OID_ORGANIZATIONAL_UNIT_NAME = 129,
	XCN_OID_TITLE = 130,
	XCN_OID_DESCRIPTION = 131,
	XCN_OID_SEARCH_GUIDE = 132,
	XCN_OID_BUSINESS_CATEGORY = 133,
	XCN_OID_POSTAL_ADDRESS = 134,
	XCN_OID_POSTAL_CODE = 135,
	XCN_OID_POST_OFFICE_BOX = 136,
	XCN_OID_PHYSICAL_DELIVERY_OFFICE_NAME = 137,
	XCN_OID_TELEPHONE_NUMBER = 138,
	XCN_OID_TELEX_NUMBER = 139,
	XCN_OID_TELETEXT_TERMINAL_IDENTIFIER = 140,
	XCN_OID_FACSIMILE_TELEPHONE_NUMBER = 141,
	XCN_OID_X21_ADDRESS = 142,
	XCN_OID_INTERNATIONAL_ISDN_NUMBER = 143,
	XCN_OID_REGISTERED_ADDRESS = 144,
	XCN_OID_DESTINATION_INDICATOR = 145,
	XCN_OID_PREFERRED_DELIVERY_METHOD = 146,
	XCN_OID_PRESENTATION_ADDRESS = 147,
	XCN_OID_SUPPORTED_APPLICATION_CONTEXT = 148,
	XCN_OID_MEMBER = 149,
	XCN_OID_OWNER = 150,
	XCN_OID_ROLE_OCCUPANT = 151,
	XCN_OID_SEE_ALSO = 152,
	XCN_OID_USER_PASSWORD = 153,
	XCN_OID_USER_CERTIFICATE = 154,
	XCN_OID_CA_CERTIFICATE = 155,
	XCN_OID_AUTHORITY_REVOCATION_LIST = 156,
	XCN_OID_CERTIFICATE_REVOCATION_LIST = 157,
	XCN_OID_CROSS_CERTIFICATE_PAIR = 158,
	XCN_OID_GIVEN_NAME = 159,
	XCN_OID_INITIALS = 160,
	XCN_OID_DN_QUALIFIER = 161,
	XCN_OID_DOMAIN_COMPONENT = 162,
	XCN_OID_PKCS_12_FRIENDLY_NAME_ATTR = 163,
	XCN_OID_PKCS_12_LOCAL_KEY_ID = 164,
	XCN_OID_PKCS_12_KEY_PROVIDER_NAME_ATTR = 165,
	XCN_OID_LOCAL_MACHINE_KEYSET = 166,
	XCN_OID_PKCS_12_EXTENDED_ATTRIBUTES = 167,
	XCN_OID_KEYID_RDN = 168,
	XCN_OID_AUTHORITY_KEY_IDENTIFIER = 169,
	XCN_OID_KEY_ATTRIBUTES = 170,
	XCN_OID_CERT_POLICIES_95 = 171,
	XCN_OID_KEY_USAGE_RESTRICTION = 172,
	XCN_OID_SUBJECT_ALT_NAME = 173,
	XCN_OID_ISSUER_ALT_NAME = 174,
	XCN_OID_BASIC_CONSTRAINTS = 175,
	XCN_OID_KEY_USAGE = 176,
	XCN_OID_PRIVATEKEY_USAGE_PERIOD = 177,
	XCN_OID_BASIC_CONSTRAINTS2 = 178,
	XCN_OID_CERT_POLICIES = 179,
	XCN_OID_ANY_CERT_POLICY = 180,
	XCN_OID_AUTHORITY_KEY_IDENTIFIER2 = 181,
	XCN_OID_SUBJECT_KEY_IDENTIFIER = 182,
	XCN_OID_SUBJECT_ALT_NAME2 = 183,
	XCN_OID_ISSUER_ALT_NAME2 = 184,
	XCN_OID_CRL_REASON_CODE = 185,
	XCN_OID_REASON_CODE_HOLD = 186,
	XCN_OID_CRL_DIST_POINTS = 187,
	XCN_OID_ENHANCED_KEY_USAGE = 188,
	XCN_OID_CRL_NUMBER = 189,
	XCN_OID_DELTA_CRL_INDICATOR = 190,
	XCN_OID_ISSUING_DIST_POINT = 191,
	XCN_OID_FRESHEST_CRL = 192,
	XCN_OID_NAME_CONSTRAINTS = 193,
	XCN_OID_POLICY_MAPPINGS = 194,
	XCN_OID_LEGACY_POLICY_MAPPINGS = 195,
	XCN_OID_POLICY_CONSTRAINTS = 196,
	XCN_OID_RENEWAL_CERTIFICATE = 197,
	XCN_OID_ENROLLMENT_NAME_VALUE_PAIR = 198,
	XCN_OID_ENROLLMENT_CSP_PROVIDER = 199,
	XCN_OID_OS_VERSION = 200,
	XCN_OID_ENROLLMENT_AGENT = 201,
	XCN_OID_PKIX = 202,
	XCN_OID_PKIX_PE = 203,
	XCN_OID_AUTHORITY_INFO_ACCESS = 204,
	XCN_OID_BIOMETRIC_EXT = 205,
	XCN_OID_LOGOTYPE_EXT = 206,
	XCN_OID_CERT_EXTENSIONS = 207,
	XCN_OID_NEXT_UPDATE_LOCATION = 208,
	XCN_OID_REMOVE_CERTIFICATE = 209,
	XCN_OID_CROSS_CERT_DIST_POINTS = 210,
	XCN_OID_CTL = 211,
	XCN_OID_SORTED_CTL = 212,
	XCN_OID_SERIALIZED = 213,
	XCN_OID_NT_PRINCIPAL_NAME = 214,
	XCN_OID_PRODUCT_UPDATE = 215,
	XCN_OID_ANY_APPLICATION_POLICY = 216,
	XCN_OID_AUTO_ENROLL_CTL_USAGE = 217,
	XCN_OID_ENROLL_CERTTYPE_EXTENSION = 218,
	XCN_OID_CERT_MANIFOLD = 219,
	XCN_OID_CERTSRV_CA_VERSION = 220,
	XCN_OID_CERTSRV_PREVIOUS_CERT_HASH = 221,
	XCN_OID_CRL_VIRTUAL_BASE = 222,
	XCN_OID_CRL_NEXT_PUBLISH = 223,
	XCN_OID_KP_CA_EXCHANGE = 224,
	XCN_OID_KP_KEY_RECOVERY_AGENT = 225,
	XCN_OID_CERTIFICATE_TEMPLATE = 226,
	XCN_OID_ENTERPRISE_OID_ROOT = 227,
	XCN_OID_RDN_DUMMY_SIGNER = 228,
	XCN_OID_APPLICATION_CERT_POLICIES = 229,
	XCN_OID_APPLICATION_POLICY_MAPPINGS = 230,
	XCN_OID_APPLICATION_POLICY_CONSTRAINTS = 231,
	XCN_OID_ARCHIVED_KEY_ATTR = 232,
	XCN_OID_CRL_SELF_CDP = 233,
	XCN_OID_REQUIRE_CERT_CHAIN_POLICY = 234,
	XCN_OID_ARCHIVED_KEY_CERT_HASH = 235,
	XCN_OID_ISSUED_CERT_HASH = 236,
	XCN_OID_DS_EMAIL_REPLICATION = 237,
	XCN_OID_REQUEST_CLIENT_INFO = 238,
	XCN_OID_ENCRYPTED_KEY_HASH = 239,
	XCN_OID_CERTSRV_CROSSCA_VERSION = 240,
	XCN_OID_NTDS_REPLICATION = 241,
	XCN_OID_SUBJECT_DIR_ATTRS = 242,
	XCN_OID_PKIX_KP = 243,
	XCN_OID_PKIX_KP_SERVER_AUTH = 244,
	XCN_OID_PKIX_KP_CLIENT_AUTH = 245,
	XCN_OID_PKIX_KP_CODE_SIGNING = 246,
	XCN_OID_PKIX_KP_EMAIL_PROTECTION = 247,
	XCN_OID_PKIX_KP_IPSEC_END_SYSTEM = 248,
	XCN_OID_PKIX_KP_IPSEC_TUNNEL = 249,
	XCN_OID_PKIX_KP_IPSEC_USER = 250,
	XCN_OID_PKIX_KP_TIMESTAMP_SIGNING = 251,
	XCN_OID_PKIX_KP_OCSP_SIGNING = 252,
	XCN_OID_PKIX_OCSP_NOCHECK = 253,
	XCN_OID_IPSEC_KP_IKE_INTERMEDIATE = 254,
	XCN_OID_KP_CTL_USAGE_SIGNING = 255,
	XCN_OID_KP_TIME_STAMP_SIGNING = 256,
	XCN_OID_SERVER_GATED_CRYPTO = 257,
	XCN_OID_SGC_NETSCAPE = 258,
	XCN_OID_KP_EFS = 259,
	XCN_OID_EFS_RECOVERY = 260,
	XCN_OID_WHQL_CRYPTO = 261,
	XCN_OID_NT5_CRYPTO = 262,
	XCN_OID_OEM_WHQL_CRYPTO = 263,
	XCN_OID_EMBEDDED_NT_CRYPTO = 264,
	XCN_OID_ROOT_LIST_SIGNER = 265,
	XCN_OID_KP_QUALIFIED_SUBORDINATION = 266,
	XCN_OID_KP_KEY_RECOVERY = 267,
	XCN_OID_KP_DOCUMENT_SIGNING = 268,
	XCN_OID_KP_LIFETIME_SIGNING = 269,
	XCN_OID_KP_MOBILE_DEVICE_SOFTWARE = 270,
	XCN_OID_KP_SMART_DISPLAY = 271,
	XCN_OID_KP_CSP_SIGNATURE = 272,
	XCN_OID_DRM = 273,
	XCN_OID_DRM_INDIVIDUALIZATION = 274,
	XCN_OID_LICENSES = 275,
	XCN_OID_LICENSE_SERVER = 276,
	XCN_OID_KP_SMARTCARD_LOGON = 277,
	XCN_OID_YESNO_TRUST_ATTR = 278,
	XCN_OID_PKIX_POLICY_QUALIFIER_CPS = 279,
	XCN_OID_PKIX_POLICY_QUALIFIER_USERNOTICE = 280,
	XCN_OID_CERT_POLICIES_95_QUALIFIER1 = 281,
	XCN_OID_PKIX_ACC_DESCR = 282,
	XCN_OID_PKIX_OCSP = 283,
	XCN_OID_PKIX_CA_ISSUERS = 284,
	XCN_OID_VERISIGN_PRIVATE_6_9 = 285,
	XCN_OID_VERISIGN_ONSITE_JURISDICTION_HASH = 286,
	XCN_OID_VERISIGN_BITSTRING_6_13 = 287,
	XCN_OID_VERISIGN_ISS_STRONG_CRYPTO = 288,
	XCN_OID_NETSCAPE = 289,
	XCN_OID_NETSCAPE_CERT_EXTENSION = 290,
	XCN_OID_NETSCAPE_CERT_TYPE = 291,
	XCN_OID_NETSCAPE_BASE_URL = 292,
	XCN_OID_NETSCAPE_REVOCATION_URL = 293,
	XCN_OID_NETSCAPE_CA_REVOCATION_URL = 294,
	XCN_OID_NETSCAPE_CERT_RENEWAL_URL = 295,
	XCN_OID_NETSCAPE_CA_POLICY_URL = 296,
	XCN_OID_NETSCAPE_SSL_SERVER_NAME = 297,
	XCN_OID_NETSCAPE_COMMENT = 298,
	XCN_OID_NETSCAPE_DATA_TYPE = 299,
	XCN_OID_NETSCAPE_CERT_SEQUENCE = 300,
	XCN_OID_CT_PKI_DATA = 301,
	XCN_OID_CT_PKI_RESPONSE = 302,
	XCN_OID_PKIX_NO_SIGNATURE = 303,
	XCN_OID_CMC = 304,
	XCN_OID_CMC_STATUS_INFO = 305,
	XCN_OID_CMC_IDENTIFICATION = 306,
	XCN_OID_CMC_IDENTITY_PROOF = 307,
	XCN_OID_CMC_DATA_RETURN = 308,
	XCN_OID_CMC_TRANSACTION_ID = 309,
	XCN_OID_CMC_SENDER_NONCE = 310,
	XCN_OID_CMC_RECIPIENT_NONCE = 311,
	XCN_OID_CMC_ADD_EXTENSIONS = 312,
	XCN_OID_CMC_ENCRYPTED_POP = 313,
	XCN_OID_CMC_DECRYPTED_POP = 314,
	XCN_OID_CMC_LRA_POP_WITNESS = 315,
	XCN_OID_CMC_GET_CERT = 316,
	XCN_OID_CMC_GET_CRL = 317,
	XCN_OID_CMC_REVOKE_REQUEST = 318,
	XCN_OID_CMC_REG_INFO = 319,
	XCN_OID_CMC_RESPONSE_INFO = 320,
	XCN_OID_CMC_QUERY_PENDING = 321,
	XCN_OID_CMC_ID_POP_LINK_RANDOM = 322,
	XCN_OID_CMC_ID_POP_LINK_WITNESS = 323,
	XCN_OID_CMC_ID_CONFIRM_CERT_ACCEPTANCE = 324,
	XCN_OID_CMC_ADD_ATTRIBUTES = 325,
	XCN_OID_LOYALTY_OTHER_LOGOTYPE = 326,
	XCN_OID_BACKGROUND_OTHER_LOGOTYPE = 327,
	XCN_OID_PKIX_OCSP_BASIC_SIGNED_RESPONSE = 328,
	XCN_OID_PKCS_7_DATA = 329,
	XCN_OID_PKCS_7_SIGNED = 330,
	XCN_OID_PKCS_7_ENVELOPED = 331,
	XCN_OID_PKCS_7_SIGNEDANDENVELOPED = 332,
	XCN_OID_PKCS_7_DIGESTED = 333,
	XCN_OID_PKCS_7_ENCRYPTED = 334,
	XCN_OID_PKCS_9_CONTENT_TYPE = 335,
	XCN_OID_PKCS_9_MESSAGE_DIGEST = 336,
	XCN_OID_CERT_PROP_ID_PREFIX = 337,
	XCN_OID_CERT_KEY_IDENTIFIER_PROP_ID = 338,
	XCN_OID_CERT_ISSUER_SERIAL_NUMBER_MD5_HASH_PROP_ID = 339,
	XCN_OID_CERT_SUBJECT_NAME_MD5_HASH_PROP_ID = 340,
	XCN_OID_CERT_MD5_HASH_PROP_ID = 341,
	XCN_OID_RSA_SHA256RSA = 342,
	XCN_OID_RSA_SHA384RSA = 343,
	XCN_OID_RSA_SHA512RSA = 344,
	XCN_OID_NIST_sha256 = 345,
	XCN_OID_NIST_sha384 = 346,
	XCN_OID_NIST_sha512 = 347,
	XCN_OID_RSA_MGF1 = 348,
	XCN_OID_ECC_PUBLIC_KEY = 349,
	XCN_OID_ECDSA_SHA1 = 350,
	XCN_OID_ECDSA_SPECIFIED = 351,
	XCN_OID_ANY_ENHANCED_KEY_USAGE = 352,
	XCN_OID_RSA_SSA_PSS = 353,
	XCN_OID_ATTR_SUPPORTED_ALGORITHMS = 355,
	XCN_OID_ATTR_TPM_SECURITY_ASSERTIONS = 356,
	XCN_OID_ATTR_TPM_SPECIFICATION = 357,
	XCN_OID_CERT_DISALLOWED_FILETIME_PROP_ID = 358,
	XCN_OID_CERT_SIGNATURE_HASH_PROP_ID = 359,
	XCN_OID_CERT_STRONG_KEY_OS_1 = 360,
	XCN_OID_CERT_STRONG_KEY_OS_CURRENT = 361,
	XCN_OID_CERT_STRONG_KEY_OS_PREFIX = 362,
	XCN_OID_CERT_STRONG_SIGN_OS_1 = 363,
	XCN_OID_CERT_STRONG_SIGN_OS_CURRENT = 364,
	XCN_OID_CERT_STRONG_SIGN_OS_PREFIX = 365,
	XCN_OID_DH_SINGLE_PASS_STDDH_SHA1_KDF = 366,
	XCN_OID_DH_SINGLE_PASS_STDDH_SHA256_KDF = 367,
	XCN_OID_DH_SINGLE_PASS_STDDH_SHA384_KDF = 368,
	XCN_OID_DISALLOWED_HASH = 369,
	XCN_OID_DISALLOWED_LIST = 370,
	XCN_OID_ECC_CURVE_P256 = 371,
	XCN_OID_ECC_CURVE_P384 = 372,
	XCN_OID_ECC_CURVE_P521 = 373,
	XCN_OID_ECDSA_SHA256 = 374,
	XCN_OID_ECDSA_SHA384 = 375,
	XCN_OID_ECDSA_SHA512 = 376,
	XCN_OID_ENROLL_CAXCHGCERT_HASH = 377,
	XCN_OID_ENROLL_EK_INFO = 378,
	XCN_OID_ENROLL_EKPUB_CHALLENGE = 379,
	XCN_OID_ENROLL_EKVERIFYCERT = 380,
	XCN_OID_ENROLL_EKVERIFYCREDS = 381,
	XCN_OID_ENROLL_EKVERIFYKEY = 382,
	XCN_OID_EV_RDN_COUNTRY = 383,
	XCN_OID_EV_RDN_LOCALE = 384,
	XCN_OID_EV_RDN_STATE_OR_PROVINCE = 385,
	XCN_OID_INHIBIT_ANY_POLICY = 386,
	XCN_OID_INTERNATIONALIZED_EMAIL_ADDRESS = 387,
	XCN_OID_KP_KERNEL_MODE_CODE_SIGNING = 388,
	XCN_OID_KP_KERNEL_MODE_HAL_EXTENSION_SIGNING = 389,
	XCN_OID_KP_KERNEL_MODE_TRUSTED_BOOT_SIGNING = 390,
	XCN_OID_KP_TPM_AIK_CERTIFICATE = 391,
	XCN_OID_KP_TPM_EK_CERTIFICATE = 392,
	XCN_OID_KP_TPM_PLATFORM_CERTIFICATE = 393,
	XCN_OID_NIST_AES128_CBC = 394,
	XCN_OID_NIST_AES128_WRAP = 395,
	XCN_OID_NIST_AES192_CBC = 396,
	XCN_OID_NIST_AES192_WRAP = 397,
	XCN_OID_NIST_AES256_CBC = 398,
	XCN_OID_NIST_AES256_WRAP = 399,
	XCN_OID_PKCS_12_PbeIds = 400,
	XCN_OID_PKCS_12_pbeWithSHA1And128BitRC2 = 401,
	XCN_OID_PKCS_12_pbeWithSHA1And128BitRC4 = 402,
	XCN_OID_PKCS_12_pbeWithSHA1And2KeyTripleDES = 403,
	XCN_OID_PKCS_12_pbeWithSHA1And3KeyTripleDES = 404,
	XCN_OID_PKCS_12_pbeWithSHA1And40BitRC2 = 405,
	XCN_OID_PKCS_12_pbeWithSHA1And40BitRC4 = 406,
	XCN_OID_PKCS_12_PROTECTED_PASSWORD_SECRET_BAG_TYPE_ID = 407,
	XCN_OID_PKINIT_KP_KDC = 408,
	XCN_OID_PKIX_CA_REPOSITORY = 409,
	XCN_OID_PKIX_OCSP_NONCE = 410,
	XCN_OID_PKIX_TIME_STAMPING = 411,
	XCN_OID_QC_EU_COMPLIANCE = 412,
	XCN_OID_QC_SSCD = 413,
	XCN_OID_QC_STATEMENTS_EXT = 414,
	XCN_OID_RDN_TPM_MANUFACTURER = 415,
	XCN_OID_RDN_TPM_MODEL = 416,
	XCN_OID_RDN_TPM_VERSION = 417,
	XCN_OID_REVOKED_LIST_SIGNER = 418,
	XCN_OID_RFC3161_counterSign = 419,
	XCN_OID_ROOT_PROGRAM_AUTO_UPDATE_CA_REVOCATION = 420,
	XCN_OID_ROOT_PROGRAM_AUTO_UPDATE_END_REVOCATION = 421,
	XCN_OID_ROOT_PROGRAM_FLAGS = 422,
	XCN_OID_ROOT_PROGRAM_NO_OCSP_FAILOVER_TO_CRL = 423,
	XCN_OID_RSA_PSPECIFIED = 424,
	XCN_OID_RSAES_OAEP = 425,
	XCN_OID_SUBJECT_INFO_ACCESS = 426,
	XCN_OID_TIMESTAMP_TOKEN = 427,
	XCN_OID_ENROLL_SCEP_ERROR = 428,
	XCN_OIDVerisign_MessageType = 429,
	XCN_OIDVerisign_PkiStatus = 430,
	XCN_OIDVerisign_FailInfo = 431,
	XCN_OIDVerisign_SenderNonce = 432,
	XCN_OIDVerisign_RecipientNonce = 433,
	XCN_OIDVerisign_TransactionID = 434,
	XCN_OID_ENROLL_ATTESTATION_CHALLENGE = 435,
	XCN_OID_ENROLL_ATTESTATION_STATEMENT = 436,
	XCN_OID_ENROLL_ENCRYPTION_ALGORITHM = 437,
	XCN_OID_ENROLL_KSP_NAME = 438,
}


[AllowDuplicates]
public enum WebSecurityLevel : int32
{
	LevelUnsafe = 0,
	LevelSafe = 1,
}


[AllowDuplicates]
public enum EncodingType : int32
{
	XCN_CRYPT_STRING_BASE64HEADER = 0,
	XCN_CRYPT_STRING_BASE64 = 1,
	XCN_CRYPT_STRING_BINARY = 2,
	XCN_CRYPT_STRING_BASE64REQUESTHEADER = 3,
	XCN_CRYPT_STRING_HEX = 4,
	XCN_CRYPT_STRING_HEXASCII = 5,
	XCN_CRYPT_STRING_BASE64_ANY = 6,
	XCN_CRYPT_STRING_ANY = 7,
	XCN_CRYPT_STRING_HEX_ANY = 8,
	XCN_CRYPT_STRING_BASE64X509CRLHEADER = 9,
	XCN_CRYPT_STRING_HEXADDR = 10,
	XCN_CRYPT_STRING_HEXASCIIADDR = 11,
	XCN_CRYPT_STRING_HEXRAW = 12,
	XCN_CRYPT_STRING_BASE64URI = 13,
	XCN_CRYPT_STRING_ENCODEMASK = 255,
	XCN_CRYPT_STRING_CHAIN = 256,
	XCN_CRYPT_STRING_TEXT = 512,
	XCN_CRYPT_STRING_PERCENTESCAPE = 134217728,
	XCN_CRYPT_STRING_HASHDATA = 268435456,
	XCN_CRYPT_STRING_STRICT = 536870912,
	XCN_CRYPT_STRING_NOCRLF = 1073741824,
	XCN_CRYPT_STRING_NOCR = -2147483648,
}


[AllowDuplicates]
public enum PFXExportOptions : int32
{
	PFXExportEEOnly = 0,
	PFXExportChainNoRoot = 1,
	PFXExportChainWithRoot = 2,
}


[AllowDuplicates]
public enum ObjectIdGroupId : int32
{
	XCN_CRYPT_ANY_GROUP_ID = 0,
	XCN_CRYPT_HASH_ALG_OID_GROUP_ID = 1,
	XCN_CRYPT_ENCRYPT_ALG_OID_GROUP_ID = 2,
	XCN_CRYPT_PUBKEY_ALG_OID_GROUP_ID = 3,
	XCN_CRYPT_SIGN_ALG_OID_GROUP_ID = 4,
	XCN_CRYPT_RDN_ATTR_OID_GROUP_ID = 5,
	XCN_CRYPT_EXT_OR_ATTR_OID_GROUP_ID = 6,
	XCN_CRYPT_ENHKEY_USAGE_OID_GROUP_ID = 7,
	XCN_CRYPT_POLICY_OID_GROUP_ID = 8,
	XCN_CRYPT_TEMPLATE_OID_GROUP_ID = 9,
	XCN_CRYPT_KDF_OID_GROUP_ID = 10,
	XCN_CRYPT_LAST_OID_GROUP_ID = 10,
	XCN_CRYPT_FIRST_ALG_OID_GROUP_ID = 1,
	XCN_CRYPT_LAST_ALG_OID_GROUP_ID = 4,
	XCN_CRYPT_GROUP_ID_MASK = 65535,
	XCN_CRYPT_OID_PREFER_CNG_ALGID_FLAG = 1073741824,
	XCN_CRYPT_OID_DISABLE_SEARCH_DS_FLAG = -2147483648,
	XCN_CRYPT_OID_INFO_OID_GROUP_BIT_LEN_MASK = 268369920,
	XCN_CRYPT_OID_INFO_OID_GROUP_BIT_LEN_SHIFT = 16,
	XCN_CRYPT_KEY_LENGTH_MASK = 268369920,
}


[AllowDuplicates]
public enum ObjectIdPublicKeyFlags : int32
{
	XCN_CRYPT_OID_INFO_PUBKEY_ANY = 0,
	XCN_CRYPT_OID_INFO_PUBKEY_SIGN_KEY_FLAG = -2147483648,
	XCN_CRYPT_OID_INFO_PUBKEY_ENCRYPT_KEY_FLAG = 1073741824,
}


[AllowDuplicates]
public enum AlgorithmFlags : int32
{
	AlgorithmFlagsNone = 0,
	AlgorithmFlagsWrap = 1,
}


[AllowDuplicates]
public enum X500NameFlags : int32
{
	XCN_CERT_NAME_STR_NONE = 0,
	XCN_CERT_SIMPLE_NAME_STR = 1,
	XCN_CERT_OID_NAME_STR = 2,
	XCN_CERT_X500_NAME_STR = 3,
	XCN_CERT_XML_NAME_STR = 4,
	XCN_CERT_NAME_STR_SEMICOLON_FLAG = 1073741824,
	XCN_CERT_NAME_STR_NO_PLUS_FLAG = 536870912,
	XCN_CERT_NAME_STR_NO_QUOTING_FLAG = 268435456,
	XCN_CERT_NAME_STR_CRLF_FLAG = 134217728,
	XCN_CERT_NAME_STR_COMMA_FLAG = 67108864,
	XCN_CERT_NAME_STR_REVERSE_FLAG = 33554432,
	XCN_CERT_NAME_STR_FORWARD_FLAG = 16777216,
	XCN_CERT_NAME_STR_AMBIGUOUS_SEPARATOR_FLAGS = 1275068416,
	XCN_CERT_NAME_STR_DISABLE_IE4_UTF8_FLAG = 65536,
	XCN_CERT_NAME_STR_ENABLE_T61_UNICODE_FLAG = 131072,
	XCN_CERT_NAME_STR_ENABLE_UTF8_UNICODE_FLAG = 262144,
	XCN_CERT_NAME_STR_FORCE_UTF8_DIR_STR_FLAG = 524288,
	XCN_CERT_NAME_STR_DISABLE_UTF8_DIR_STR_FLAG = 1048576,
	XCN_CERT_NAME_STR_ENABLE_PUNYCODE_FLAG = 2097152,
	XCN_CERT_NAME_STR_DS_ESCAPED = 8388608,
}


[AllowDuplicates]
public enum X509CertificateEnrollmentContext : int32
{
	ContextNone = 0,
	ContextUser = 1,
	ContextMachine = 2,
	ContextAdministratorForceMachine = 3,
}


[AllowDuplicates]
public enum EnrollmentEnrollStatus : int32
{
	Enrolled = 1,
	EnrollPended = 2,
	EnrollUIDeferredEnrollmentRequired = 4,
	EnrollError = 16,
	EnrollUnknown = 32,
	EnrollSkipped = 64,
	EnrollDenied = 256,
}


[AllowDuplicates]
public enum EnrollmentSelectionStatus : int32
{
	SelectedNo = 0,
	SelectedYes = 1,
}


[AllowDuplicates]
public enum EnrollmentDisplayStatus : int32
{
	DisplayNo = 0,
	DisplayYes = 1,
}


[AllowDuplicates]
public enum X509ProviderType : int32
{
	XCN_PROV_NONE = 0,
	XCN_PROV_RSA_FULL = 1,
	XCN_PROV_RSA_SIG = 2,
	XCN_PROV_DSS = 3,
	XCN_PROV_FORTEZZA = 4,
	XCN_PROV_MS_EXCHANGE = 5,
	XCN_PROV_SSL = 6,
	XCN_PROV_RSA_SCHANNEL = 12,
	XCN_PROV_DSS_DH = 13,
	XCN_PROV_EC_ECDSA_SIG = 14,
	XCN_PROV_EC_ECNRA_SIG = 15,
	XCN_PROV_EC_ECDSA_FULL = 16,
	XCN_PROV_EC_ECNRA_FULL = 17,
	XCN_PROV_DH_SCHANNEL = 18,
	XCN_PROV_SPYRUS_LYNKS = 20,
	XCN_PROV_RNG = 21,
	XCN_PROV_INTEL_SEC = 22,
	XCN_PROV_REPLACE_OWF = 23,
	XCN_PROV_RSA_AES = 24,
}


[AllowDuplicates]
public enum AlgorithmType : int32
{
	XCN_BCRYPT_UNKNOWN_INTERFACE = 0,
	XCN_BCRYPT_CIPHER_INTERFACE = 1,
	XCN_BCRYPT_HASH_INTERFACE = 2,
	XCN_BCRYPT_ASYMMETRIC_ENCRYPTION_INTERFACE = 3,
	XCN_BCRYPT_SIGNATURE_INTERFACE = 5,
	XCN_BCRYPT_SECRET_AGREEMENT_INTERFACE = 4,
	XCN_BCRYPT_RNG_INTERFACE = 6,
	XCN_BCRYPT_KEY_DERIVATION_INTERFACE = 7,
}


[AllowDuplicates]
public enum AlgorithmOperationFlags : int32
{
	XCN_NCRYPT_NO_OPERATION = 0,
	XCN_NCRYPT_CIPHER_OPERATION = 1,
	XCN_NCRYPT_HASH_OPERATION = 2,
	XCN_NCRYPT_ASYMMETRIC_ENCRYPTION_OPERATION = 4,
	XCN_NCRYPT_SECRET_AGREEMENT_OPERATION = 8,
	XCN_NCRYPT_SIGNATURE_OPERATION = 16,
	XCN_NCRYPT_RNG_OPERATION = 32,
	XCN_NCRYPT_KEY_DERIVATION_OPERATION = 64,
	XCN_NCRYPT_ANY_ASYMMETRIC_OPERATION = 28,
	XCN_NCRYPT_PREFER_SIGNATURE_ONLY_OPERATION = 2097152,
	XCN_NCRYPT_PREFER_NON_SIGNATURE_OPERATION = 4194304,
	XCN_NCRYPT_EXACT_MATCH_OPERATION = 8388608,
	XCN_NCRYPT_PREFERENCE_MASK_OPERATION = 14680064,
}


[AllowDuplicates]
public enum X509KeySpec : int32
{
	XCN_AT_NONE = 0,
	XCN_AT_KEYEXCHANGE = 1,
	XCN_AT_SIGNATURE = 2,
}


[AllowDuplicates]
public enum KeyIdentifierHashAlgorithm : int32
{
	SKIHashDefault = 0,
	SKIHashSha1 = 1,
	SKIHashCapiSha1 = 2,
	SKIHashSha256 = 3,
	SKIHashHPKP = 5,
}


[AllowDuplicates]
public enum X509PrivateKeyExportFlags : int32
{
	XCN_NCRYPT_ALLOW_EXPORT_NONE = 0,
	XCN_NCRYPT_ALLOW_EXPORT_FLAG = 1,
	XCN_NCRYPT_ALLOW_PLAINTEXT_EXPORT_FLAG = 2,
	XCN_NCRYPT_ALLOW_ARCHIVING_FLAG = 4,
	XCN_NCRYPT_ALLOW_PLAINTEXT_ARCHIVING_FLAG = 8,
}


[AllowDuplicates]
public enum X509PrivateKeyUsageFlags : int32
{
	XCN_NCRYPT_ALLOW_USAGES_NONE = 0,
	XCN_NCRYPT_ALLOW_DECRYPT_FLAG = 1,
	XCN_NCRYPT_ALLOW_SIGNING_FLAG = 2,
	XCN_NCRYPT_ALLOW_KEY_AGREEMENT_FLAG = 4,
	XCN_NCRYPT_ALLOW_KEY_IMPORT_FLAG = 8,
	XCN_NCRYPT_ALLOW_ALL_USAGES = 16777215,
}


[AllowDuplicates]
public enum X509PrivateKeyProtection : int32
{
	XCN_NCRYPT_UI_NO_PROTECTION_FLAG = 0,
	XCN_NCRYPT_UI_PROTECT_KEY_FLAG = 1,
	XCN_NCRYPT_UI_FORCE_HIGH_PROTECTION_FLAG = 2,
	XCN_NCRYPT_UI_FINGERPRINT_PROTECTION_FLAG = 4,
	XCN_NCRYPT_UI_APPCONTAINER_ACCESS_MEDIUM_FLAG = 8,
}


[AllowDuplicates]
public enum X509PrivateKeyVerify : int32
{
	VerifyNone = 0,
	VerifySilent = 1,
	VerifySmartCardNone = 2,
	VerifySmartCardSilent = 3,
	VerifyAllowUI = 4,
}


[AllowDuplicates]
public enum X509HardwareKeyUsageFlags : int32
{
	XCN_NCRYPT_PCP_NONE = 0,
	XCN_NCRYPT_TPM12_PROVIDER = 65536,
	XCN_NCRYPT_PCP_SIGNATURE_KEY = 1,
	XCN_NCRYPT_PCP_ENCRYPTION_KEY = 2,
	XCN_NCRYPT_PCP_GENERIC_KEY = 3,
	XCN_NCRYPT_PCP_STORAGE_KEY = 4,
	XCN_NCRYPT_PCP_IDENTITY_KEY = 8,
}


[AllowDuplicates]
public enum X509KeyParametersExportType : int32
{
	XCN_CRYPT_OID_USE_CURVE_NONE = 0,
	XCN_CRYPT_OID_USE_CURVE_NAME_FOR_ENCODE_FLAG = 536870912,
	XCN_CRYPT_OID_USE_CURVE_PARAMETERS_FOR_ENCODE_FLAG = 268435456,
}


[AllowDuplicates]
public enum X509KeyUsageFlags : int32
{
	XCN_CERT_NO_KEY_USAGE = 0,
	XCN_CERT_DIGITAL_SIGNATURE_KEY_USAGE = 128,
	XCN_CERT_NON_REPUDIATION_KEY_USAGE = 64,
	XCN_CERT_KEY_ENCIPHERMENT_KEY_USAGE = 32,
	XCN_CERT_DATA_ENCIPHERMENT_KEY_USAGE = 16,
	XCN_CERT_KEY_AGREEMENT_KEY_USAGE = 8,
	XCN_CERT_KEY_CERT_SIGN_KEY_USAGE = 4,
	XCN_CERT_OFFLINE_CRL_SIGN_KEY_USAGE = 2,
	XCN_CERT_CRL_SIGN_KEY_USAGE = 2,
	XCN_CERT_ENCIPHER_ONLY_KEY_USAGE = 1,
	XCN_CERT_DECIPHER_ONLY_KEY_USAGE = 32768,
}


[AllowDuplicates]
public enum AlternativeNameType : int32
{
	XCN_CERT_ALT_NAME_UNKNOWN = 0,
	XCN_CERT_ALT_NAME_OTHER_NAME = 1,
	XCN_CERT_ALT_NAME_RFC822_NAME = 2,
	XCN_CERT_ALT_NAME_DNS_NAME = 3,
	XCN_CERT_ALT_NAME_X400_ADDRESS = 4,
	XCN_CERT_ALT_NAME_DIRECTORY_NAME = 5,
	XCN_CERT_ALT_NAME_EDI_PARTY_NAME = 6,
	XCN_CERT_ALT_NAME_URL = 7,
	XCN_CERT_ALT_NAME_IP_ADDRESS = 8,
	XCN_CERT_ALT_NAME_REGISTERED_ID = 9,
	XCN_CERT_ALT_NAME_GUID = 10,
	XCN_CERT_ALT_NAME_USER_PRINCIPLE_NAME = 11,
}


[AllowDuplicates]
public enum PolicyQualifierType : int32
{
	PolicyQualifierTypeUnknown = 0,
	PolicyQualifierTypeUrl = 1,
	PolicyQualifierTypeUserNotice = 2,
	PolicyQualifierTypeFlags = 3,
}


[AllowDuplicates]
public enum RequestClientInfoClientId : int32
{
	ClientIdNone = 0,
	ClientIdXEnroll2003 = 1,
	ClientIdAutoEnroll2003 = 2,
	ClientIdWizard2003 = 3,
	ClientIdCertReq2003 = 4,
	ClientIdDefaultRequest = 5,
	ClientIdAutoEnroll = 6,
	ClientIdRequestWizard = 7,
	ClientIdEOBO = 8,
	ClientIdCertReq = 9,
	ClientIdTest = 10,
	ClientIdWinRT = 11,
	ClientIdUserStart = 1000,
}


[AllowDuplicates]
public enum CERTENROLL_PROPERTYID : int32
{
	XCN_PROPERTYID_NONE = 0,
	XCN_CERT_KEY_PROV_HANDLE_PROP_ID = 1,
	XCN_CERT_KEY_PROV_INFO_PROP_ID = 2,
	XCN_CERT_SHA1_HASH_PROP_ID = 3,
	XCN_CERT_MD5_HASH_PROP_ID = 4,
	XCN_CERT_HASH_PROP_ID = 3,
	XCN_CERT_KEY_CONTEXT_PROP_ID = 5,
	XCN_CERT_KEY_SPEC_PROP_ID = 6,
	XCN_CERT_IE30_RESERVED_PROP_ID = 7,
	XCN_CERT_PUBKEY_HASH_RESERVED_PROP_ID = 8,
	XCN_CERT_ENHKEY_USAGE_PROP_ID = 9,
	XCN_CERT_CTL_USAGE_PROP_ID = 9,
	XCN_CERT_NEXT_UPDATE_LOCATION_PROP_ID = 10,
	XCN_CERT_FRIENDLY_NAME_PROP_ID = 11,
	XCN_CERT_PVK_FILE_PROP_ID = 12,
	XCN_CERT_DESCRIPTION_PROP_ID = 13,
	XCN_CERT_ACCESS_STATE_PROP_ID = 14,
	XCN_CERT_SIGNATURE_HASH_PROP_ID = 15,
	XCN_CERT_SMART_CARD_DATA_PROP_ID = 16,
	XCN_CERT_EFS_PROP_ID = 17,
	XCN_CERT_FORTEZZA_DATA_PROP_ID = 18,
	XCN_CERT_ARCHIVED_PROP_ID = 19,
	XCN_CERT_KEY_IDENTIFIER_PROP_ID = 20,
	XCN_CERT_AUTO_ENROLL_PROP_ID = 21,
	XCN_CERT_PUBKEY_ALG_PARA_PROP_ID = 22,
	XCN_CERT_CROSS_CERT_DIST_POINTS_PROP_ID = 23,
	XCN_CERT_ISSUER_PUBLIC_KEY_MD5_HASH_PROP_ID = 24,
	XCN_CERT_SUBJECT_PUBLIC_KEY_MD5_HASH_PROP_ID = 25,
	XCN_CERT_ENROLLMENT_PROP_ID = 26,
	XCN_CERT_DATE_STAMP_PROP_ID = 27,
	XCN_CERT_ISSUER_SERIAL_NUMBER_MD5_HASH_PROP_ID = 28,
	XCN_CERT_SUBJECT_NAME_MD5_HASH_PROP_ID = 29,
	XCN_CERT_EXTENDED_ERROR_INFO_PROP_ID = 30,
	XCN_CERT_RENEWAL_PROP_ID = 64,
	XCN_CERT_ARCHIVED_KEY_HASH_PROP_ID = 65,
	XCN_CERT_AUTO_ENROLL_RETRY_PROP_ID = 66,
	XCN_CERT_AIA_URL_RETRIEVED_PROP_ID = 67,
	XCN_CERT_AUTHORITY_INFO_ACCESS_PROP_ID = 68,
	XCN_CERT_BACKED_UP_PROP_ID = 69,
	XCN_CERT_OCSP_RESPONSE_PROP_ID = 70,
	XCN_CERT_REQUEST_ORIGINATOR_PROP_ID = 71,
	XCN_CERT_SOURCE_LOCATION_PROP_ID = 72,
	XCN_CERT_SOURCE_URL_PROP_ID = 73,
	XCN_CERT_NEW_KEY_PROP_ID = 74,
	XCN_CERT_OCSP_CACHE_PREFIX_PROP_ID = 75,
	XCN_CERT_SMART_CARD_ROOT_INFO_PROP_ID = 76,
	XCN_CERT_NO_AUTO_EXPIRE_CHECK_PROP_ID = 77,
	XCN_CERT_NCRYPT_KEY_HANDLE_PROP_ID = 78,
	XCN_CERT_HCRYPTPROV_OR_NCRYPT_KEY_HANDLE_PROP_ID = 79,
	XCN_CERT_SUBJECT_INFO_ACCESS_PROP_ID = 80,
	XCN_CERT_CA_OCSP_AUTHORITY_INFO_ACCESS_PROP_ID = 81,
	XCN_CERT_CA_DISABLE_CRL_PROP_ID = 82,
	XCN_CERT_ROOT_PROGRAM_CERT_POLICIES_PROP_ID = 83,
	XCN_CERT_ROOT_PROGRAM_NAME_CONSTRAINTS_PROP_ID = 84,
	XCN_CERT_SUBJECT_OCSP_AUTHORITY_INFO_ACCESS_PROP_ID = 85,
	XCN_CERT_SUBJECT_DISABLE_CRL_PROP_ID = 86,
	XCN_CERT_CEP_PROP_ID = 87,
	XCN_CERT_SIGN_HASH_CNG_ALG_PROP_ID = 89,
	XCN_CERT_SCARD_PIN_ID_PROP_ID = 90,
	XCN_CERT_SCARD_PIN_INFO_PROP_ID = 91,
	XCN_CERT_SUBJECT_PUB_KEY_BIT_LENGTH_PROP_ID = 92,
	XCN_CERT_PUB_KEY_CNG_ALG_BIT_LENGTH_PROP_ID = 93,
	XCN_CERT_ISSUER_PUB_KEY_BIT_LENGTH_PROP_ID = 94,
	XCN_CERT_ISSUER_CHAIN_SIGN_HASH_CNG_ALG_PROP_ID = 95,
	XCN_CERT_ISSUER_CHAIN_PUB_KEY_CNG_ALG_BIT_LENGTH_PROP_ID = 96,
	XCN_CERT_NO_EXPIRE_NOTIFICATION_PROP_ID = 97,
	XCN_CERT_AUTH_ROOT_SHA256_HASH_PROP_ID = 98,
	XCN_CERT_NCRYPT_KEY_HANDLE_TRANSFER_PROP_ID = 99,
	XCN_CERT_HCRYPTPROV_TRANSFER_PROP_ID = 100,
	XCN_CERT_SMART_CARD_READER_PROP_ID = 101,
	XCN_CERT_SEND_AS_TRUSTED_ISSUER_PROP_ID = 102,
	XCN_CERT_KEY_REPAIR_ATTEMPTED_PROP_ID = 103,
	XCN_CERT_DISALLOWED_FILETIME_PROP_ID = 104,
	XCN_CERT_ROOT_PROGRAM_CHAIN_POLICIES_PROP_ID = 105,
	XCN_CERT_SMART_CARD_READER_NON_REMOVABLE_PROP_ID = 106,
	XCN_CERT_SHA256_HASH_PROP_ID = 107,
	XCN_CERT_SCEP_SERVER_CERTS_PROP_ID = 108,
	XCN_CERT_SCEP_RA_SIGNATURE_CERT_PROP_ID = 109,
	XCN_CERT_SCEP_RA_ENCRYPTION_CERT_PROP_ID = 110,
	XCN_CERT_SCEP_CA_CERT_PROP_ID = 111,
	XCN_CERT_SCEP_SIGNER_CERT_PROP_ID = 112,
	XCN_CERT_SCEP_NONCE_PROP_ID = 113,
	XCN_CERT_SCEP_ENCRYPT_HASH_CNG_ALG_PROP_ID = 114,
	XCN_CERT_SCEP_FLAGS_PROP_ID = 115,
	XCN_CERT_SCEP_GUID_PROP_ID = 116,
	XCN_CERT_SERIALIZABLE_KEY_CONTEXT_PROP_ID = 117,
	XCN_CERT_ISOLATED_KEY_PROP_ID = 118,
	XCN_CERT_SERIAL_CHAIN_PROP_ID = 119,
	XCN_CERT_KEY_CLASSIFICATION_PROP_ID = 120,
	XCN_CERT_DISALLOWED_ENHKEY_USAGE_PROP_ID = 122,
	XCN_CERT_NONCOMPLIANT_ROOT_URL_PROP_ID = 123,
	XCN_CERT_PIN_SHA256_HASH_PROP_ID = 124,
	XCN_CERT_CLR_DELETE_KEY_PROP_ID = 125,
	XCN_CERT_NOT_BEFORE_FILETIME_PROP_ID = 126,
	XCN_CERT_CERT_NOT_BEFORE_ENHKEY_USAGE_PROP_ID = 127,
	XCN_CERT_FIRST_RESERVED_PROP_ID = 128,
	XCN_CERT_LAST_RESERVED_PROP_ID = 32767,
	XCN_CERT_FIRST_USER_PROP_ID = 32768,
	XCN_CERT_LAST_USER_PROP_ID = 65535,
	XCN_CERT_STORE_LOCALIZED_NAME_PROP_ID = 4096,
}


[AllowDuplicates]
public enum EnrollmentPolicyServerPropertyFlags : int32
{
	DefaultNone = 0,
	DefaultPolicyServer = 1,
}


[AllowDuplicates]
public enum PolicyServerUrlFlags : int32
{
	PsfNone = 0,
	PsfLocationGroupPolicy = 1,
	PsfLocationRegistry = 2,
	PsfUseClientId = 4,
	PsfAutoEnrollmentEnabled = 16,
	PsfAllowUnTrustedCA = 32,
}


[AllowDuplicates]
public enum EnrollmentTemplateProperty : int32
{
	TemplatePropCommonName = 1,
	TemplatePropFriendlyName = 2,
	TemplatePropEKUs = 3,
	TemplatePropCryptoProviders = 4,
	TemplatePropMajorRevision = 5,
	TemplatePropDescription = 6,
	TemplatePropKeySpec = 7,
	TemplatePropSchemaVersion = 8,
	TemplatePropMinorRevision = 9,
	TemplatePropRASignatureCount = 10,
	TemplatePropMinimumKeySize = 11,
	TemplatePropOID = 12,
	TemplatePropSupersede = 13,
	TemplatePropRACertificatePolicies = 14,
	TemplatePropRAEKUs = 15,
	TemplatePropCertificatePolicies = 16,
	TemplatePropV1ApplicationPolicy = 17,
	TemplatePropAsymmetricAlgorithm = 18,
	TemplatePropKeySecurityDescriptor = 19,
	TemplatePropSymmetricAlgorithm = 20,
	TemplatePropSymmetricKeyLength = 21,
	TemplatePropHashAlgorithm = 22,
	TemplatePropKeyUsage = 23,
	TemplatePropEnrollmentFlags = 24,
	TemplatePropSubjectNameFlags = 25,
	TemplatePropPrivateKeyFlags = 26,
	TemplatePropGeneralFlags = 27,
	TemplatePropSecurityDescriptor = 28,
	TemplatePropExtensions = 29,
	TemplatePropValidityPeriod = 30,
	TemplatePropRenewalPeriod = 31,
}


[AllowDuplicates]
public enum CommitTemplateFlags : int32
{
	CommitFlagSaveTemplateGenerateOID = 1,
	CommitFlagSaveTemplateUseCurrentOID = 2,
	CommitFlagSaveTemplateOverwrite = 3,
	CommitFlagDeleteTemplate = 4,
}


[AllowDuplicates]
public enum EnrollmentCAProperty : int32
{
	CAPropCommonName = 1,
	CAPropDistinguishedName = 2,
	CAPropSanitizedName = 3,
	CAPropSanitizedShortName = 4,
	CAPropDNSName = 5,
	CAPropCertificateTypes = 6,
	CAPropCertificate = 7,
	CAPropDescription = 8,
	CAPropWebServers = 9,
	CAPropSiteName = 10,
	CAPropSecurity = 11,
	CAPropRenewalOnly = 12,
}


[AllowDuplicates]
public enum X509EnrollmentPolicyLoadOption : int32
{
	LoadOptionDefault = 0,
	LoadOptionCacheOnly = 1,
	LoadOptionReload = 2,
	LoadOptionRegisterForADChanges = 4,
}


[AllowDuplicates]
public enum EnrollmentPolicyFlags : int32
{
	DisableGroupPolicyList = 2,
	DisableUserServerList = 4,
}


[AllowDuplicates]
public enum PolicyServerUrlPropertyID : int32
{
	PsPolicyID = 0,
	PsFriendlyName = 1,
}


[AllowDuplicates]
public enum X509EnrollmentPolicyExportFlags : int32
{
	ExportTemplates = 1,
	ExportOIDs = 2,
	ExportCAs = 4,
}


[AllowDuplicates]
public enum X509RequestType : int32
{
	TypeAny = 0,
	TypePkcs10 = 1,
	TypePkcs7 = 2,
	TypeCmc = 3,
	TypeCertificate = 4,
}


[AllowDuplicates]
public enum X509RequestInheritOptions : int32
{
	InheritDefault = 0,
	InheritNewDefaultKey = 1,
	InheritNewSimilarKey = 2,
	InheritPrivateKey = 3,
	InheritPublicKey = 4,
	InheritKeyMask = 15,
	InheritNone = 16,
	InheritRenewalCertificateFlag = 32,
	InheritTemplateFlag = 64,
	InheritSubjectFlag = 128,
	InheritExtensionsFlag = 256,
	InheritSubjectAltNameFlag = 512,
	InheritValidityPeriodFlag = 1024,
	InheritReserved80000000 = -2147483648,
}


[AllowDuplicates]
public enum InnerRequestLevel : int32
{
	LevelInnermost = 0,
	LevelNext = 1,
}


[AllowDuplicates]
public enum Pkcs10AllowedSignatureTypes : int32
{
	AllowedKeySignature = 1,
	AllowedNullSignature = 2,
}


[AllowDuplicates]
public enum KeyAttestationClaimType : int32
{
	XCN_NCRYPT_CLAIM_NONE = 0,
	XCN_NCRYPT_CLAIM_AUTHORITY_AND_SUBJECT = 3,
	XCN_NCRYPT_CLAIM_AUTHORITY_ONLY = 1,
	XCN_NCRYPT_CLAIM_SUBJECT_ONLY = 2,
	XCN_NCRYPT_CLAIM_UNKNOWN = 4096,
}


[AllowDuplicates]
public enum InstallResponseRestrictionFlags : int32
{
	AllowNone = 0,
	AllowNoOutstandingRequest = 1,
	AllowUntrustedCertificate = 2,
	AllowUntrustedRoot = 4,
}


[AllowDuplicates]
public enum WebEnrollmentFlags : int32
{
	EnrollPrompt = 1,
}


[AllowDuplicates]
public enum CRLRevocationReason : int32
{
	XCN_CRL_REASON_UNSPECIFIED = 0,
	XCN_CRL_REASON_KEY_COMPROMISE = 1,
	XCN_CRL_REASON_CA_COMPROMISE = 2,
	XCN_CRL_REASON_AFFILIATION_CHANGED = 3,
	XCN_CRL_REASON_SUPERSEDED = 4,
	XCN_CRL_REASON_CESSATION_OF_OPERATION = 5,
	XCN_CRL_REASON_CERTIFICATE_HOLD = 6,
	XCN_CRL_REASON_REMOVE_FROM_CRL = 8,
	XCN_CRL_REASON_PRIVILEGE_WITHDRAWN = 9,
	XCN_CRL_REASON_AA_COMPROMISE = 10,
}


[AllowDuplicates]
public enum X509SCEPProcessMessageFlags : int32
{
	SCEPProcessDefault = 0,
	SCEPProcessSkipCertInstall = 1,
}


[AllowDuplicates]
public enum DelayRetryAction : int32
{
	DelayRetryUnknown = 0,
	DelayRetryNone = 1,
	DelayRetryShort = 2,
	DelayRetryLong = 3,
	DelayRetrySuccess = 4,
	DelayRetryPastSuccess = 5,
}


[AllowDuplicates]
public enum X509CertificateTemplateGeneralFlag : int32
{
	GeneralMachineType = 64,
	GeneralCA = 128,
	GeneralCrossCA = 2048,
	GeneralDefault = 65536,
	GeneralModified = 131072,
	GeneralDonotPersist = 4096,
}


[AllowDuplicates]
public enum X509CertificateTemplateEnrollmentFlag : int32
{
	EnrollmentIncludeSymmetricAlgorithms = 1,
	EnrollmentPendAllRequests = 2,
	EnrollmentPublishToKRAContainer = 4,
	EnrollmentPublishToDS = 8,
	EnrollmentAutoEnrollmentCheckUserDSCertificate = 16,
	EnrollmentAutoEnrollment = 32,
	EnrollmentDomainAuthenticationNotRequired = 128,
	EnrollmentPreviousApprovalValidateReenrollment = 64,
	EnrollmentUserInteractionRequired = 256,
	EnrollmentAddTemplateName = 512,
	EnrollmentRemoveInvalidCertificateFromPersonalStore = 1024,
	EnrollmentAllowEnrollOnBehalfOf = 2048,
	EnrollmentAddOCSPNoCheck = 4096,
	EnrollmentReuseKeyOnFullSmartCard = 8192,
	EnrollmentNoRevocationInfoInCerts = 16384,
	EnrollmentIncludeBasicConstraintsForEECerts = 32768,
	EnrollmentPreviousApprovalKeyBasedValidateReenrollment = 65536,
	EnrollmentCertificateIssuancePoliciesFromRequest = 131072,
	EnrollmentSkipAutoRenewal = 262144,
}


[AllowDuplicates]
public enum X509CertificateTemplateSubjectNameFlag : int32
{
	SubjectNameEnrolleeSupplies = 1,
	SubjectNameRequireDirectoryPath = -2147483648,
	SubjectNameRequireCommonName = 1073741824,
	SubjectNameRequireEmail = 536870912,
	SubjectNameRequireDNS = 268435456,
	SubjectNameAndAlternativeNameOldCertSupplies = 8,
	SubjectAlternativeNameEnrolleeSupplies = 65536,
	SubjectAlternativeNameRequireDirectoryGUID = 16777216,
	SubjectAlternativeNameRequireUPN = 33554432,
	SubjectAlternativeNameRequireEmail = 67108864,
	SubjectAlternativeNameRequireSPN = 8388608,
	SubjectAlternativeNameRequireDNS = 134217728,
	SubjectAlternativeNameRequireDomainDNS = 4194304,
}


[AllowDuplicates]
public enum X509CertificateTemplatePrivateKeyFlag : int32
{
	PrivateKeyRequireArchival = 1,
	PrivateKeyExportable = 16,
	PrivateKeyRequireStrongKeyProtection = 32,
	PrivateKeyRequireAlternateSignatureAlgorithm = 64,
	PrivateKeyRequireSameKeyRenewal = 128,
	PrivateKeyUseLegacyProvider = 256,
	PrivateKeyEKTrustOnUse = 512,
	PrivateKeyEKValidateCert = 1024,
	PrivateKeyEKValidateKey = 2048,
	PrivateKeyAttestNone = 0,
	PrivateKeyAttestPreferred = 4096,
	PrivateKeyAttestRequired = 8192,
	PrivateKeyAttestMask = 12288,
	PrivateKeyAttestWithoutPolicy = 16384,
	PrivateKeyServerVersionMask = 983040,
	PrivateKeyServerVersionShift = 16,
	PrivateKeyHelloKspKey = 1048576,
	PrivateKeyHelloLogonKey = 2097152,
	PrivateKeyClientVersionMask = 251658240,
	PrivateKeyClientVersionShift = 24,
}


[AllowDuplicates]
public enum ImportPFXFlags : int32
{
	ImportNone = 0,
	ImportMachineContext = 1,
	ImportForceOverwrite = 2,
	ImportSilent = 4,
	ImportSaveProperties = 8,
	ImportExportable = 16,
	ImportExportableEncrypted = 32,
	ImportNoUserProtected = 64,
	ImportUserProtected = 128,
	ImportUserProtectedHigh = 256,
	ImportInstallCertificate = 512,
	ImportInstallChain = 1024,
	ImportInstallChainAndRoot = 2048,
}


[AllowDuplicates]
public enum ENUM_CATYPES : int32
{
	ENUM_ENTERPRISE_ROOTCA = 0,
	ENUM_ENTERPRISE_SUBCA = 1,
	ENUM_STANDALONE_ROOTCA = 3,
	ENUM_STANDALONE_SUBCA = 4,
	ENUM_UNKNOWN_CA = 5,
}

#endregion

#region Function Pointers
public function HRESULT FNCERTSRVISSERVERONLINEW(PWSTR pwszServerName, BOOL* pfServerOnline);

public function HRESULT FNCERTSRVBACKUPGETDYNAMICFILELISTW(void* hbc, uint16** ppwszzFileList, uint32* pcbSize);

public function HRESULT FNCERTSRVBACKUPPREPAREW(PWSTR pwszServerName, uint32 grbitJet, uint32 dwBackupFlags, void** phbc);

public function HRESULT FNCERTSRVBACKUPGETDATABASENAMESW(void* hbc, uint16** ppwszzAttachmentInformation, uint32* pcbSize);

public function HRESULT FNCERTSRVBACKUPOPENFILEW(void* hbc, PWSTR pwszAttachmentName, uint32 cbReadHintSize, LARGE_INTEGER* pliFileSize);

public function HRESULT FNCERTSRVBACKUPREAD(void* hbc, void* pvBuffer, uint32 cbBuffer, uint32* pcbRead);

public function HRESULT FNCERTSRVBACKUPCLOSE(void* hbc);

public function HRESULT FNCERTSRVBACKUPGETBACKUPLOGSW(void* hbc, uint16** ppwszzBackupLogFiles, uint32* pcbSize);

public function HRESULT FNCERTSRVBACKUPTRUNCATELOGS(void* hbc);

public function HRESULT FNCERTSRVBACKUPEND(void* hbc);

public function void FNCERTSRVBACKUPFREE(void* pv);

public function HRESULT FNCERTSRVRESTOREGETDATABASELOCATIONSW(void* hbc, uint16** ppwszzDatabaseLocationList, uint32* pcbSize);

public function HRESULT FNCERTSRVRESTOREPREPAREW(PWSTR pwszServerName, uint32 dwRestoreFlags, void** phbc);

public function HRESULT FNCERTSRVRESTOREREGISTERW(void* hbc, PWSTR pwszCheckPointFilePath, PWSTR pwszLogPath, CSEDB_RSTMAPW* rgrstmap, int32 crstmap, PWSTR pwszBackupLogPath, uint32 genLow, uint32 genHigh);

public function HRESULT FNCERTSRVRESTOREREGISTERCOMPLETE(void* hbc, HRESULT hrRestoreState);

public function HRESULT FNCERTSRVRESTOREEND(void* hbc);

public function HRESULT FNCERTSRVSERVERCONTROLW(PWSTR pwszServerName, uint32 dwControlFlags, uint32* pcbOut, uint8** ppbOut);

public function HRESULT FNIMPORTPFXTOPROVIDER(HWND hWndParent, uint8* pbPFX, uint32 cbPFX, ImportPFXFlags ImportFlags, PWSTR pwszPassword, PWSTR pwszProviderName, PWSTR pwszReaderName, PWSTR pwszContainerNamePrefix, PWSTR pwszPin, PWSTR pwszFriendlyName, uint32* pcCertOut, CERT_CONTEXT*** prgpCertOut);

public function void FNIMPORTPFXTOPROVIDERFREEDATA(uint32 cCert, CERT_CONTEXT** rgpCert);

#endregion

#region Structs
[CRepr]
public struct CSEDB_RSTMAPW
{
	public PWSTR pwszDatabaseName;
	public PWSTR pwszNewDatabaseName;
}

[CRepr]
public struct CERTTRANSBLOB
{
	public uint32 cb;
	public uint8* pb;
}

[CRepr]
public struct CERTVIEWRESTRICTION
{
	public uint32 ColumnIndex;
	public int32 SeekOperator;
	public int32 SortOrder;
	public uint8* pbValue;
	public uint32 cbValue;
}

[CRepr]
public struct CAINFO
{
	public uint32 cbSize;
	public ENUM_CATYPES CAType;
	public uint32 cCASignatureCerts;
	public uint32 cCAExchangeCerts;
	public uint32 cExitModules;
	public int32 lPropIdMax;
	public int32 lRoleSeparationEnabled;
	public uint32 cKRACertUsedCount;
	public uint32 cKRACertCount;
	public uint32 fAdvancedServer;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_CCertAdmin = .(0x37eabaf0, 0x7fb6, 0x11d0, 0x88, 0x17, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);


	public const Guid CLSID_CCertView = .(0xa12d0f7a, 0x1e84, 0x11d1, 0x9b, 0xd6, 0x00, 0xc0, 0x4f, 0xb6, 0x83, 0xfa);


	public const Guid CLSID_OCSPPropertyCollection = .(0xf935a528, 0xba8a, 0x4dd9, 0xba, 0x79, 0xf2, 0x83, 0x27, 0x5c, 0xb2, 0xde);


	public const Guid CLSID_OCSPAdmin = .(0xd3f73511, 0x92c9, 0x47cb, 0x8f, 0xf2, 0x8d, 0x89, 0x1a, 0x7c, 0x4d, 0xe4);


	public const Guid CLSID_CCertGetConfig = .(0xc6cc49b0, 0xce17, 0x11d0, 0x88, 0x33, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);


	public const Guid CLSID_CCertConfig = .(0x372fce38, 0x4324, 0x11d0, 0x88, 0x10, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);


	public const Guid CLSID_CCertRequest = .(0x98aff3f0, 0x5524, 0x11d0, 0x88, 0x12, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);


	public const Guid CLSID_CCertServerPolicy = .(0xaa000926, 0xffbe, 0x11cf, 0x88, 0x00, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);


	public const Guid CLSID_CCertServerExit = .(0x4c4a5e40, 0x732c, 0x11d0, 0x88, 0x16, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);


	public const Guid CLSID_CCertEncodeStringArray = .(0x19a76fe0, 0x7494, 0x11d0, 0x88, 0x16, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);


	public const Guid CLSID_CCertEncodeLongArray = .(0x4e0680a0, 0xa0a2, 0x11d0, 0x88, 0x21, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);


	public const Guid CLSID_CCertEncodeDateArray = .(0x301f77b0, 0xa470, 0x11d0, 0x88, 0x21, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);


	public const Guid CLSID_CCertEncodeCRLDistInfo = .(0x01fa60a0, 0xbbff, 0x11d0, 0x88, 0x25, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);


	public const Guid CLSID_CCertEncodeAltName = .(0x1cfc4cda, 0x1271, 0x11d1, 0x9b, 0xd4, 0x00, 0xc0, 0x4f, 0xb6, 0x83, 0xfa);


	public const Guid CLSID_CCertEncodeBitString = .(0x6d6b3cd8, 0x1278, 0x11d1, 0x9b, 0xd4, 0x00, 0xc0, 0x4f, 0xb6, 0x83, 0xfa);


	public const Guid CLSID_CObjectId = .(0x884e2000, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CObjectIds = .(0x884e2001, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CBinaryConverter = .(0x884e2002, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX500DistinguishedName = .(0x884e2003, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCspInformation = .(0x884e2007, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCspInformations = .(0x884e2008, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCspStatus = .(0x884e2009, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509PublicKey = .(0x884e200b, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509PrivateKey = .(0x884e200c, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509EndorsementKey = .(0x11a25a1d, 0xb9a3, 0x4edd, 0xaf, 0x83, 0x3b, 0x59, 0xad, 0xbe, 0xd3, 0x61);


	public const Guid CLSID_CX509Extension = .(0x884e200d, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509Extensions = .(0x884e200e, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509ExtensionKeyUsage = .(0x884e200f, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509ExtensionEnhancedKeyUsage = .(0x884e2010, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509ExtensionTemplateName = .(0x884e2011, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509ExtensionTemplate = .(0x884e2012, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CAlternativeName = .(0x884e2013, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CAlternativeNames = .(0x884e2014, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509ExtensionAlternativeNames = .(0x884e2015, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509ExtensionBasicConstraints = .(0x884e2016, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509ExtensionSubjectKeyIdentifier = .(0x884e2017, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509ExtensionAuthorityKeyIdentifier = .(0x884e2018, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CSmimeCapability = .(0x884e2019, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CSmimeCapabilities = .(0x884e201a, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509ExtensionSmimeCapabilities = .(0x884e201b, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CPolicyQualifier = .(0x884e201c, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CPolicyQualifiers = .(0x884e201d, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertificatePolicy = .(0x884e201e, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertificatePolicies = .(0x884e201f, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509ExtensionCertificatePolicies = .(0x884e2020, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509ExtensionMSApplicationPolicies = .(0x884e2021, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509Attribute = .(0x884e2022, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509Attributes = .(0x884e2023, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509AttributeExtensions = .(0x884e2024, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509AttributeClientId = .(0x884e2025, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509AttributeRenewalCertificate = .(0x884e2026, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509AttributeArchiveKey = .(0x884e2027, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509AttributeArchiveKeyHash = .(0x884e2028, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509AttributeOSVersion = .(0x884e202a, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509AttributeCspProvider = .(0x884e202b, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCryptAttribute = .(0x884e202c, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCryptAttributes = .(0x884e202d, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertProperty = .(0x884e202e, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertProperties = .(0x884e202f, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertPropertyFriendlyName = .(0x884e2030, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertPropertyDescription = .(0x884e2031, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertPropertyAutoEnroll = .(0x884e2032, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertPropertyRequestOriginator = .(0x884e2033, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertPropertySHA1Hash = .(0x884e2034, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertPropertyKeyProvInfo = .(0x884e2036, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertPropertyArchived = .(0x884e2037, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertPropertyBackedUp = .(0x884e2038, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertPropertyEnrollment = .(0x884e2039, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertPropertyRenewal = .(0x884e203a, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertPropertyArchivedKeyHash = .(0x884e203b, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertPropertyEnrollmentPolicyServer = .(0x884e204c, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CSignerCertificate = .(0x884e203d, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509NameValuePair = .(0x884e203f, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CCertificateAttestationChallenge = .(0x1362ada1, 0xeb60, 0x456a, 0xb6, 0xe1, 0x11, 0x80, 0x50, 0xdb, 0x74, 0x1b);


	public const Guid CLSID_CX509CertificateRequestPkcs10 = .(0x884e2042, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509CertificateRequestCertificate = .(0x884e2043, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509CertificateRequestPkcs7 = .(0x884e2044, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509CertificateRequestCmc = .(0x884e2045, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509Enrollment = .(0x884e2046, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509EnrollmentWebClassFactory = .(0x884e2049, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509EnrollmentHelper = .(0x884e2050, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509MachineEnrollmentFactory = .(0x884e2051, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509EnrollmentPolicyActiveDirectory = .(0x91f39027, 0x217f, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509EnrollmentPolicyWebService = .(0x91f39028, 0x217f, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509PolicyServerListManager = .(0x91f39029, 0x217f, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509PolicyServerUrl = .(0x91f3902a, 0x217f, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509CertificateTemplateADWritable = .(0x8336e323, 0x2e6a, 0x4a04, 0x93, 0x7c, 0x54, 0x8f, 0x68, 0x18, 0x39, 0xb3);


	public const Guid CLSID_CX509CertificateRevocationListEntry = .(0x884e205e, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509CertificateRevocationListEntries = .(0x884e205f, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509CertificateRevocationList = .(0x884e2060, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509SCEPEnrollment = .(0x884e2061, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CX509SCEPEnrollmentHelper = .(0x884e2062, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);


	public const Guid CLSID_CEnroll2 = .(0x127698e4, 0xe730, 0x4e5c, 0xa2, 0xb1, 0x21, 0x49, 0x0a, 0x70, 0xc8, 0xa1);


	public const Guid CLSID_CEnroll = .(0x43f8f289, 0x7a20, 0x11d0, 0x8f, 0x06, 0x00, 0xc0, 0x4f, 0xc2, 0x95, 0xe1);


}
#endregion

#region COM Types
[CRepr]struct IEnumCERTVIEWCOLUMN : IDispatch
{
	public new const Guid IID = .(0x9c735be2, 0x57a5, 0x11d1, 0x9b, 0xdb, 0x00, 0xc0, 0x4f, 0xb6, 0x83, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pIndex) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrOut) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrOut) GetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pType) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pIndexed) IsIndexed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pMaxLength) GetMaxLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ENUM_CERT_COLUMN_VALUE_FLAGS Flags, VARIANT* pvarValue) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumCERTVIEWCOLUMN** ppenum) Clone;
	}


	public HRESULT Next(int32* pIndex) mut => VT.[Friend]Next(&this, pIndex);

	public HRESULT GetName(BSTR* pstrOut) mut => VT.[Friend]GetName(&this, pstrOut);

	public HRESULT GetDisplayName(BSTR* pstrOut) mut => VT.[Friend]GetDisplayName(&this, pstrOut);

	public HRESULT GetType(int32* pType) mut => VT.[Friend]COM_GetType(&this, pType);

	public HRESULT IsIndexed(int32* pIndexed) mut => VT.[Friend]IsIndexed(&this, pIndexed);

	public HRESULT GetMaxLength(int32* pMaxLength) mut => VT.[Friend]GetMaxLength(&this, pMaxLength);

	public HRESULT GetValue(ENUM_CERT_COLUMN_VALUE_FLAGS Flags, VARIANT* pvarValue) mut => VT.[Friend]GetValue(&this, Flags, pvarValue);

	public HRESULT Skip(int32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumCERTVIEWCOLUMN** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IEnumCERTVIEWATTRIBUTE : IDispatch
{
	public new const Guid IID = .(0xe77db656, 0x7653, 0x11d1, 0x9b, 0xde, 0x00, 0xc0, 0x4f, 0xb6, 0x83, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pIndex) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrOut) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrOut) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumCERTVIEWATTRIBUTE** ppenum) Clone;
	}


	public HRESULT Next(int32* pIndex) mut => VT.[Friend]Next(&this, pIndex);

	public HRESULT GetName(BSTR* pstrOut) mut => VT.[Friend]GetName(&this, pstrOut);

	public HRESULT GetValue(BSTR* pstrOut) mut => VT.[Friend]GetValue(&this, pstrOut);

	public HRESULT Skip(int32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumCERTVIEWATTRIBUTE** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IEnumCERTVIEWEXTENSION : IDispatch
{
	public new const Guid IID = .(0xe7dd1466, 0x7653, 0x11d1, 0x9b, 0xde, 0x00, 0xc0, 0x4f, 0xb6, 0x83, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pIndex) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrOut) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pFlags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_PROPERTY_TYPE Type, ENUM_CERT_COLUMN_VALUE_FLAGS Flags, VARIANT* pvarValue) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumCERTVIEWEXTENSION** ppenum) Clone;
	}


	public HRESULT Next(int32* pIndex) mut => VT.[Friend]Next(&this, pIndex);

	public HRESULT GetName(BSTR* pstrOut) mut => VT.[Friend]GetName(&this, pstrOut);

	public HRESULT GetFlags(int32* pFlags) mut => VT.[Friend]COM_GetFlags(&this, pFlags);

	public HRESULT GetValue(CERT_PROPERTY_TYPE Type, ENUM_CERT_COLUMN_VALUE_FLAGS Flags, VARIANT* pvarValue) mut => VT.[Friend]GetValue(&this, Type, Flags, pvarValue);

	public HRESULT Skip(int32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumCERTVIEWEXTENSION** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IEnumCERTVIEWROW : IDispatch
{
	public new const Guid IID = .(0xd1157f4c, 0x5af2, 0x11d1, 0x9b, 0xdc, 0x00, 0xc0, 0x4f, 0xb6, 0x83, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pIndex) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumCERTVIEWCOLUMN** ppenum) EnumCertViewColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, IEnumCERTVIEWATTRIBUTE** ppenum) EnumCertViewAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, IEnumCERTVIEWEXTENSION** ppenum) EnumCertViewExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumCERTVIEWROW** ppenum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pIndex) GetMaxIndex;
	}


	public HRESULT Next(int32* pIndex) mut => VT.[Friend]Next(&this, pIndex);

	public HRESULT EnumCertViewColumn(IEnumCERTVIEWCOLUMN** ppenum) mut => VT.[Friend]EnumCertViewColumn(&this, ppenum);

	public HRESULT EnumCertViewAttribute(int32 Flags, IEnumCERTVIEWATTRIBUTE** ppenum) mut => VT.[Friend]EnumCertViewAttribute(&this, Flags, ppenum);

	public HRESULT EnumCertViewExtension(int32 Flags, IEnumCERTVIEWEXTENSION** ppenum) mut => VT.[Friend]EnumCertViewExtension(&this, Flags, ppenum);

	public HRESULT Skip(int32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumCERTVIEWROW** ppenum) mut => VT.[Friend]Clone(&this, ppenum);

	public HRESULT GetMaxIndex(int32* pIndex) mut => VT.[Friend]GetMaxIndex(&this, pIndex);
}

[CRepr]struct ICertView : IDispatch
{
	public new const Guid IID = .(0xc3fac344, 0x1e84, 0x11d1, 0x9b, 0xd6, 0x00, 0xc0, 0x4f, 0xb6, 0x83, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig) OpenConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CVRC_COLUMN fResultColumn, IEnumCERTVIEWCOLUMN** ppenum) EnumCertViewColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CVRC_COLUMN fResultColumn, int32* pcColumn) GetColumnCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CVRC_COLUMN fResultColumn, BSTR strColumnName, int32* pColumnIndex) GetColumnIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cResultColumn) SetResultColumnCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 ColumnIndex) SetResultColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_VIEW_COLUMN_INDEX ColumnIndex, CERT_VIEW_SEEK_OPERATOR_FLAGS SeekOperator, int32 SortOrder, VARIANT* pvarValue) SetRestriction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumCERTVIEWROW** ppenum) OpenView;
	}


	public HRESULT OpenConnection(BSTR strConfig) mut => VT.[Friend]OpenConnection(&this, strConfig);

	public HRESULT EnumCertViewColumn(CVRC_COLUMN fResultColumn, IEnumCERTVIEWCOLUMN** ppenum) mut => VT.[Friend]EnumCertViewColumn(&this, fResultColumn, ppenum);

	public HRESULT GetColumnCount(CVRC_COLUMN fResultColumn, int32* pcColumn) mut => VT.[Friend]GetColumnCount(&this, fResultColumn, pcColumn);

	public HRESULT GetColumnIndex(CVRC_COLUMN fResultColumn, BSTR strColumnName, int32* pColumnIndex) mut => VT.[Friend]GetColumnIndex(&this, fResultColumn, strColumnName, pColumnIndex);

	public HRESULT SetResultColumnCount(int32 cResultColumn) mut => VT.[Friend]SetResultColumnCount(&this, cResultColumn);

	public HRESULT SetResultColumn(int32 ColumnIndex) mut => VT.[Friend]SetResultColumn(&this, ColumnIndex);

	public HRESULT SetRestriction(CERT_VIEW_COLUMN_INDEX ColumnIndex, CERT_VIEW_SEEK_OPERATOR_FLAGS SeekOperator, int32 SortOrder, VARIANT* pvarValue) mut => VT.[Friend]SetRestriction(&this, ColumnIndex, SeekOperator, SortOrder, pvarValue);

	public HRESULT OpenView(IEnumCERTVIEWROW** ppenum) mut => VT.[Friend]OpenView(&this, ppenum);
}

[CRepr]struct ICertView2 : ICertView
{
	public new const Guid IID = .(0xd594b282, 0x8851, 0x4b61, 0x9c, 0x66, 0x3e, 0xda, 0xdf, 0x84, 0x88, 0x63);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertView.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CVRC_TABLE Table) SetTable;
	}


	public HRESULT SetTable(CVRC_TABLE Table) mut => VT.[Friend]SetTable(&this, Table);
}

[CRepr]struct ICertAdmin : IDispatch
{
	public new const Guid IID = .(0x34df6950, 0x7fb6, 0x11d0, 0x88, 0x17, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, BSTR strSerialNumber, int32* pDisposition) IsValidCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pReason) GetRevocationReason;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, BSTR strSerialNumber, int32 Reason, double Date) RevokeCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 RequestId, BSTR strAttributes) SetRequestAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 RequestId, BSTR strExtensionName, CERT_PROPERTY_TYPE Type, int32 Flags, VARIANT* pvarValue) SetCertificateExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 RequestId) DenyRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 RequestId, int32* pDisposition) ResubmitRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, double Date) PublishCRL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 Flags, BSTR* pstrCRL) GetCRL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, BSTR strCertificate, CERT_IMPORT_FLAGS Flags, int32* pRequestId) ImportCertificate;
	}


	public HRESULT IsValidCertificate(BSTR strConfig, BSTR strSerialNumber, int32* pDisposition) mut => VT.[Friend]IsValidCertificate(&this, strConfig, strSerialNumber, pDisposition);

	public HRESULT GetRevocationReason(int32* pReason) mut => VT.[Friend]GetRevocationReason(&this, pReason);

	public HRESULT RevokeCertificate(BSTR strConfig, BSTR strSerialNumber, int32 Reason, double Date) mut => VT.[Friend]RevokeCertificate(&this, strConfig, strSerialNumber, Reason, Date);

	public HRESULT SetRequestAttributes(BSTR strConfig, int32 RequestId, BSTR strAttributes) mut => VT.[Friend]SetRequestAttributes(&this, strConfig, RequestId, strAttributes);

	public HRESULT SetCertificateExtension(BSTR strConfig, int32 RequestId, BSTR strExtensionName, CERT_PROPERTY_TYPE Type, int32 Flags, VARIANT* pvarValue) mut => VT.[Friend]SetCertificateExtension(&this, strConfig, RequestId, strExtensionName, Type, Flags, pvarValue);

	public HRESULT DenyRequest(BSTR strConfig, int32 RequestId) mut => VT.[Friend]DenyRequest(&this, strConfig, RequestId);

	public HRESULT ResubmitRequest(BSTR strConfig, int32 RequestId, int32* pDisposition) mut => VT.[Friend]ResubmitRequest(&this, strConfig, RequestId, pDisposition);

	public HRESULT PublishCRL(BSTR strConfig, double Date) mut => VT.[Friend]PublishCRL(&this, strConfig, Date);

	public HRESULT GetCRL(BSTR strConfig, int32 Flags, BSTR* pstrCRL) mut => VT.[Friend]GetCRL(&this, strConfig, Flags, pstrCRL);

	public HRESULT ImportCertificate(BSTR strConfig, BSTR strCertificate, CERT_IMPORT_FLAGS Flags, int32* pRequestId) mut => VT.[Friend]ImportCertificate(&this, strConfig, strCertificate, Flags, pRequestId);
}

[CRepr]struct ICertAdmin2 : ICertAdmin
{
	public new const Guid IID = .(0xf7c3ac41, 0xb8ce, 0x4fb4, 0xaa, 0x58, 0x3d, 0x1d, 0xc0, 0xe3, 0x6b, 0x39);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertAdmin.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, double Date, int32 CRLFlags) PublishCRLs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 PropId, int32 PropIndex, int32 PropType, int32 Flags, VARIANT* pvarPropertyValue) GetCAProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 PropId, int32 PropIndex, CERT_PROPERTY_TYPE PropType, VARIANT* pvarPropertyValue) SetCAProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 PropId, int32* pPropFlags) GetCAPropertyFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 PropId, BSTR* pstrDisplayName) GetCAPropertyDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 RequestId, int32 Flags, BSTR* pstrArchivedKey) GetArchivedKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, BSTR strNodePath, BSTR strEntryName, VARIANT* pvarEntry) GetConfigEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, BSTR strNodePath, BSTR strEntryName, VARIANT* pvarEntry) SetConfigEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 RequestId, BSTR strCertHash, CERT_IMPORT_FLAGS Flags, BSTR strKey) ImportKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, CERTADMIN_GET_ROLES_FLAGS* pRoles) GetMyRoles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, CERT_DELETE_ROW_FLAGS Flags, double Date, CVRC_TABLE Table, int32 RowId, int32* pcDeleted) DeleteRow;
	}


	public HRESULT PublishCRLs(BSTR strConfig, double Date, int32 CRLFlags) mut => VT.[Friend]PublishCRLs(&this, strConfig, Date, CRLFlags);

	public HRESULT GetCAProperty(BSTR strConfig, int32 PropId, int32 PropIndex, int32 PropType, int32 Flags, VARIANT* pvarPropertyValue) mut => VT.[Friend]GetCAProperty(&this, strConfig, PropId, PropIndex, PropType, Flags, pvarPropertyValue);

	public HRESULT SetCAProperty(BSTR strConfig, int32 PropId, int32 PropIndex, CERT_PROPERTY_TYPE PropType, VARIANT* pvarPropertyValue) mut => VT.[Friend]SetCAProperty(&this, strConfig, PropId, PropIndex, PropType, pvarPropertyValue);

	public HRESULT GetCAPropertyFlags(BSTR strConfig, int32 PropId, int32* pPropFlags) mut => VT.[Friend]GetCAPropertyFlags(&this, strConfig, PropId, pPropFlags);

	public HRESULT GetCAPropertyDisplayName(BSTR strConfig, int32 PropId, BSTR* pstrDisplayName) mut => VT.[Friend]GetCAPropertyDisplayName(&this, strConfig, PropId, pstrDisplayName);

	public HRESULT GetArchivedKey(BSTR strConfig, int32 RequestId, int32 Flags, BSTR* pstrArchivedKey) mut => VT.[Friend]GetArchivedKey(&this, strConfig, RequestId, Flags, pstrArchivedKey);

	public HRESULT GetConfigEntry(BSTR strConfig, BSTR strNodePath, BSTR strEntryName, VARIANT* pvarEntry) mut => VT.[Friend]GetConfigEntry(&this, strConfig, strNodePath, strEntryName, pvarEntry);

	public HRESULT SetConfigEntry(BSTR strConfig, BSTR strNodePath, BSTR strEntryName, VARIANT* pvarEntry) mut => VT.[Friend]SetConfigEntry(&this, strConfig, strNodePath, strEntryName, pvarEntry);

	public HRESULT ImportKey(BSTR strConfig, int32 RequestId, BSTR strCertHash, CERT_IMPORT_FLAGS Flags, BSTR strKey) mut => VT.[Friend]ImportKey(&this, strConfig, RequestId, strCertHash, Flags, strKey);

	public HRESULT GetMyRoles(BSTR strConfig, CERTADMIN_GET_ROLES_FLAGS* pRoles) mut => VT.[Friend]GetMyRoles(&this, strConfig, pRoles);

	public HRESULT DeleteRow(BSTR strConfig, CERT_DELETE_ROW_FLAGS Flags, double Date, CVRC_TABLE Table, int32 RowId, int32* pcDeleted) mut => VT.[Friend]DeleteRow(&this, strConfig, Flags, Date, Table, RowId, pcDeleted);
}

[CRepr]struct IOCSPProperty : IDispatch
{
	public new const Guid IID = .(0x66fb7839, 0x5f04, 0x4c25, 0xad, 0x18, 0x9f, 0xf1, 0xa8, 0x37, 0x6e, 0xe0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVal) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT newVal) put_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_Modified;
	}


	public HRESULT get_Name(BSTR* pVal) mut => VT.[Friend]get_Name(&this, pVal);

	public HRESULT get_Value(VARIANT* pVal) mut => VT.[Friend]get_Value(&this, pVal);

	public HRESULT put_Value(VARIANT newVal) mut => VT.[Friend]put_Value(&this, newVal);

	public HRESULT get_Modified(int16* pVal) mut => VT.[Friend]get_Modified(&this, pVal);
}

[CRepr]struct IOCSPPropertyCollection : IDispatch
{
	public new const Guid IID = .(0x2597c18d, 0x54e6, 0x4b74, 0x9f, 0xa9, 0xa6, 0xbf, 0xda, 0x99, 0xcb, 0xbe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropName, VARIANT* pVal) get_ItemByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropName, VARIANT* pVarPropValue, IOCSPProperty** ppVal) CreateProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropName) DeleteProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVarProperties) InitializeFromProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVarProperties) GetAllProperties;
	}


	public HRESULT get__NewEnum(IUnknown** ppVal) mut => VT.[Friend]get__NewEnum(&this, ppVal);

	public HRESULT get_Item(int32 Index, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_ItemByName(BSTR bstrPropName, VARIANT* pVal) mut => VT.[Friend]get_ItemByName(&this, bstrPropName, pVal);

	public HRESULT CreateProperty(BSTR bstrPropName, VARIANT* pVarPropValue, IOCSPProperty** ppVal) mut => VT.[Friend]CreateProperty(&this, bstrPropName, pVarPropValue, ppVal);

	public HRESULT DeleteProperty(BSTR bstrPropName) mut => VT.[Friend]DeleteProperty(&this, bstrPropName);

	public HRESULT InitializeFromProperties(VARIANT* pVarProperties) mut => VT.[Friend]InitializeFromProperties(&this, pVarProperties);

	public HRESULT GetAllProperties(VARIANT* pVarProperties) mut => VT.[Friend]GetAllProperties(&this, pVarProperties);
}

[CRepr]struct IOCSPCAConfiguration : IDispatch
{
	public new const Guid IID = .(0xaec92b40, 0x3d46, 0x433f, 0x87, 0xd1, 0xb8, 0x4d, 0x5c, 0x1e, 0x79, 0x0d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_Identifier;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVal) get_CACertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pVal) get_SigningFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 newVal) put_SigningFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVal) get_SigningCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT newVal) put_SigningCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pVal) get_ReminderDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 newVal) put_ReminderDuration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pVal) get_ErrorCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_CSPName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pVal) get_KeySpec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_ProviderCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_ProviderCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVal) get_ProviderProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT newVal) put_ProviderProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pVal) get_Modified;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pVal) get_LocalRevocationInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT newVal) put_LocalRevocationInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_SigningCertificateTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_SigningCertificateTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pVal) get_CAConfig;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newVal) put_CAConfig;
	}


	public HRESULT get_Identifier(BSTR* pVal) mut => VT.[Friend]get_Identifier(&this, pVal);

	public HRESULT get_CACertificate(VARIANT* pVal) mut => VT.[Friend]get_CACertificate(&this, pVal);

	public HRESULT get_HashAlgorithm(BSTR* pVal) mut => VT.[Friend]get_HashAlgorithm(&this, pVal);

	public HRESULT put_HashAlgorithm(BSTR newVal) mut => VT.[Friend]put_HashAlgorithm(&this, newVal);

	public HRESULT get_SigningFlags(uint32* pVal) mut => VT.[Friend]get_SigningFlags(&this, pVal);

	public HRESULT put_SigningFlags(uint32 newVal) mut => VT.[Friend]put_SigningFlags(&this, newVal);

	public HRESULT get_SigningCertificate(VARIANT* pVal) mut => VT.[Friend]get_SigningCertificate(&this, pVal);

	public HRESULT put_SigningCertificate(VARIANT newVal) mut => VT.[Friend]put_SigningCertificate(&this, newVal);

	public HRESULT get_ReminderDuration(uint32* pVal) mut => VT.[Friend]get_ReminderDuration(&this, pVal);

	public HRESULT put_ReminderDuration(uint32 newVal) mut => VT.[Friend]put_ReminderDuration(&this, newVal);

	public HRESULT get_ErrorCode(uint32* pVal) mut => VT.[Friend]get_ErrorCode(&this, pVal);

	public HRESULT get_CSPName(BSTR* pVal) mut => VT.[Friend]get_CSPName(&this, pVal);

	public HRESULT get_KeySpec(uint32* pVal) mut => VT.[Friend]get_KeySpec(&this, pVal);

	public HRESULT get_ProviderCLSID(BSTR* pVal) mut => VT.[Friend]get_ProviderCLSID(&this, pVal);

	public HRESULT put_ProviderCLSID(BSTR newVal) mut => VT.[Friend]put_ProviderCLSID(&this, newVal);

	public HRESULT get_ProviderProperties(VARIANT* pVal) mut => VT.[Friend]get_ProviderProperties(&this, pVal);

	public HRESULT put_ProviderProperties(VARIANT newVal) mut => VT.[Friend]put_ProviderProperties(&this, newVal);

	public HRESULT get_Modified(int16* pVal) mut => VT.[Friend]get_Modified(&this, pVal);

	public HRESULT get_LocalRevocationInformation(VARIANT* pVal) mut => VT.[Friend]get_LocalRevocationInformation(&this, pVal);

	public HRESULT put_LocalRevocationInformation(VARIANT newVal) mut => VT.[Friend]put_LocalRevocationInformation(&this, newVal);

	public HRESULT get_SigningCertificateTemplate(BSTR* pVal) mut => VT.[Friend]get_SigningCertificateTemplate(&this, pVal);

	public HRESULT put_SigningCertificateTemplate(BSTR newVal) mut => VT.[Friend]put_SigningCertificateTemplate(&this, newVal);

	public HRESULT get_CAConfig(BSTR* pVal) mut => VT.[Friend]get_CAConfig(&this, pVal);

	public HRESULT put_CAConfig(BSTR newVal) mut => VT.[Friend]put_CAConfig(&this, newVal);
}

[CRepr]struct IOCSPCAConfigurationCollection : IDispatch
{
	public new const Guid IID = .(0x2bebea0b, 0x5ece, 0x4f28, 0xa9, 0x1c, 0x86, 0xb4, 0xbb, 0x20, 0xf0, 0xd3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, VARIANT* pVal) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrIdentifier, VARIANT* pVal) get_ItemByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrIdentifier, VARIANT varCACert, IOCSPCAConfiguration** ppVal) CreateCAConfiguration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrIdentifier) DeleteCAConfiguration;
	}


	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT get_Item(int32 Index, VARIANT* pVal) mut => VT.[Friend]get_Item(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get_ItemByName(BSTR bstrIdentifier, VARIANT* pVal) mut => VT.[Friend]get_ItemByName(&this, bstrIdentifier, pVal);

	public HRESULT CreateCAConfiguration(BSTR bstrIdentifier, VARIANT varCACert, IOCSPCAConfiguration** ppVal) mut => VT.[Friend]CreateCAConfiguration(&this, bstrIdentifier, varCACert, ppVal);

	public HRESULT DeleteCAConfiguration(BSTR bstrIdentifier) mut => VT.[Friend]DeleteCAConfiguration(&this, bstrIdentifier);
}

[CRepr]struct IOCSPAdmin : IDispatch
{
	public new const Guid IID = .(0x322e830d, 0x67db, 0x4fe9, 0x95, 0x77, 0x45, 0x96, 0xd9, 0xf0, 0x92, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOCSPPropertyCollection** ppVal) get_OCSPServiceProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOCSPCAConfigurationCollection** pVal) get_OCSPCAConfigurationCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServerName, int16 bForce) GetConfiguration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServerName, int16 bForce) SetConfiguration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServerName, int32* pRoles) GetMyRoles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServerName) Ping;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServerName, BSTR bstrVal) SetSecurity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServerName, BSTR* pVal) GetSecurity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServerName, VARIANT* pCACertVar, VARIANT* pVal) GetSigningCertificates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrServerName, BSTR bstrCAId, VARIANT* pVal) GetHashAlgorithms;
	}


	public HRESULT get_OCSPServiceProperties(IOCSPPropertyCollection** ppVal) mut => VT.[Friend]get_OCSPServiceProperties(&this, ppVal);

	public HRESULT get_OCSPCAConfigurationCollection(IOCSPCAConfigurationCollection** pVal) mut => VT.[Friend]get_OCSPCAConfigurationCollection(&this, pVal);

	public HRESULT GetConfiguration(BSTR bstrServerName, int16 bForce) mut => VT.[Friend]GetConfiguration(&this, bstrServerName, bForce);

	public HRESULT SetConfiguration(BSTR bstrServerName, int16 bForce) mut => VT.[Friend]SetConfiguration(&this, bstrServerName, bForce);

	public HRESULT GetMyRoles(BSTR bstrServerName, int32* pRoles) mut => VT.[Friend]GetMyRoles(&this, bstrServerName, pRoles);

	public HRESULT Ping(BSTR bstrServerName) mut => VT.[Friend]Ping(&this, bstrServerName);

	public HRESULT SetSecurity(BSTR bstrServerName, BSTR bstrVal) mut => VT.[Friend]SetSecurity(&this, bstrServerName, bstrVal);

	public HRESULT GetSecurity(BSTR bstrServerName, BSTR* pVal) mut => VT.[Friend]GetSecurity(&this, bstrServerName, pVal);

	public HRESULT GetSigningCertificates(BSTR bstrServerName, VARIANT* pCACertVar, VARIANT* pVal) mut => VT.[Friend]GetSigningCertificates(&this, bstrServerName, pCACertVar, pVal);

	public HRESULT GetHashAlgorithms(BSTR bstrServerName, BSTR bstrCAId, VARIANT* pVal) mut => VT.[Friend]GetHashAlgorithms(&this, bstrServerName, bstrCAId, pVal);
}

[CRepr]struct ICertServerPolicy : IDispatch
{
	public new const Guid IID = .(0xaa000922, 0xffbe, 0x11cf, 0x88, 0x00, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Context) SetContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strPropertyName, int32 PropertyType, VARIANT* pvarPropertyValue) GetRequestProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strAttributeName, BSTR* pstrAttributeValue) GetRequestAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strPropertyName, CERT_PROPERTY_TYPE PropertyType, VARIANT* pvarPropertyValue) GetCertificateProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strPropertyName, int32 PropertyType, VARIANT* pvarPropertyValue) SetCertificateProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strExtensionName, CERT_PROPERTY_TYPE Type, VARIANT* pvarValue) GetCertificateExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pExtFlags) GetCertificateExtensionFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strExtensionName, int32 Type, int32 ExtFlags, VARIANT* pvarValue) SetCertificateExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags) EnumerateExtensionsSetup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrExtensionName) EnumerateExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnumerateExtensionsClose;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags) EnumerateAttributesSetup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrAttributeName) EnumerateAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnumerateAttributesClose;
	}


	public HRESULT SetContext(int32 Context) mut => VT.[Friend]SetContext(&this, Context);

	public HRESULT GetRequestProperty(BSTR strPropertyName, int32 PropertyType, VARIANT* pvarPropertyValue) mut => VT.[Friend]GetRequestProperty(&this, strPropertyName, PropertyType, pvarPropertyValue);

	public HRESULT GetRequestAttribute(BSTR strAttributeName, BSTR* pstrAttributeValue) mut => VT.[Friend]GetRequestAttribute(&this, strAttributeName, pstrAttributeValue);

	public HRESULT GetCertificateProperty(BSTR strPropertyName, CERT_PROPERTY_TYPE PropertyType, VARIANT* pvarPropertyValue) mut => VT.[Friend]GetCertificateProperty(&this, strPropertyName, PropertyType, pvarPropertyValue);

	public HRESULT SetCertificateProperty(BSTR strPropertyName, int32 PropertyType, VARIANT* pvarPropertyValue) mut => VT.[Friend]SetCertificateProperty(&this, strPropertyName, PropertyType, pvarPropertyValue);

	public HRESULT GetCertificateExtension(BSTR strExtensionName, CERT_PROPERTY_TYPE Type, VARIANT* pvarValue) mut => VT.[Friend]GetCertificateExtension(&this, strExtensionName, Type, pvarValue);

	public HRESULT GetCertificateExtensionFlags(int32* pExtFlags) mut => VT.[Friend]GetCertificateExtensionFlags(&this, pExtFlags);

	public HRESULT SetCertificateExtension(BSTR strExtensionName, int32 Type, int32 ExtFlags, VARIANT* pvarValue) mut => VT.[Friend]SetCertificateExtension(&this, strExtensionName, Type, ExtFlags, pvarValue);

	public HRESULT EnumerateExtensionsSetup(int32 Flags) mut => VT.[Friend]EnumerateExtensionsSetup(&this, Flags);

	public HRESULT EnumerateExtensions(BSTR* pstrExtensionName) mut => VT.[Friend]EnumerateExtensions(&this, pstrExtensionName);

	public HRESULT EnumerateExtensionsClose() mut => VT.[Friend]EnumerateExtensionsClose(&this);

	public HRESULT EnumerateAttributesSetup(int32 Flags) mut => VT.[Friend]EnumerateAttributesSetup(&this, Flags);

	public HRESULT EnumerateAttributes(BSTR* pstrAttributeName) mut => VT.[Friend]EnumerateAttributes(&this, pstrAttributeName);

	public HRESULT EnumerateAttributesClose() mut => VT.[Friend]EnumerateAttributesClose(&this);
}

[CRepr]struct ICertServerExit : IDispatch
{
	public new const Guid IID = .(0x4ba9eb90, 0x732c, 0x11d0, 0x88, 0x16, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Context) SetContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strPropertyName, int32 PropertyType, VARIANT* pvarPropertyValue) GetRequestProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strAttributeName, BSTR* pstrAttributeValue) GetRequestAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strPropertyName, int32 PropertyType, VARIANT* pvarPropertyValue) GetCertificateProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strExtensionName, int32 Type, VARIANT* pvarValue) GetCertificateExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pExtFlags) GetCertificateExtensionFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags) EnumerateExtensionsSetup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrExtensionName) EnumerateExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnumerateExtensionsClose;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags) EnumerateAttributesSetup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrAttributeName) EnumerateAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnumerateAttributesClose;
	}


	public HRESULT SetContext(int32 Context) mut => VT.[Friend]SetContext(&this, Context);

	public HRESULT GetRequestProperty(BSTR strPropertyName, int32 PropertyType, VARIANT* pvarPropertyValue) mut => VT.[Friend]GetRequestProperty(&this, strPropertyName, PropertyType, pvarPropertyValue);

	public HRESULT GetRequestAttribute(BSTR strAttributeName, BSTR* pstrAttributeValue) mut => VT.[Friend]GetRequestAttribute(&this, strAttributeName, pstrAttributeValue);

	public HRESULT GetCertificateProperty(BSTR strPropertyName, int32 PropertyType, VARIANT* pvarPropertyValue) mut => VT.[Friend]GetCertificateProperty(&this, strPropertyName, PropertyType, pvarPropertyValue);

	public HRESULT GetCertificateExtension(BSTR strExtensionName, int32 Type, VARIANT* pvarValue) mut => VT.[Friend]GetCertificateExtension(&this, strExtensionName, Type, pvarValue);

	public HRESULT GetCertificateExtensionFlags(int32* pExtFlags) mut => VT.[Friend]GetCertificateExtensionFlags(&this, pExtFlags);

	public HRESULT EnumerateExtensionsSetup(int32 Flags) mut => VT.[Friend]EnumerateExtensionsSetup(&this, Flags);

	public HRESULT EnumerateExtensions(BSTR* pstrExtensionName) mut => VT.[Friend]EnumerateExtensions(&this, pstrExtensionName);

	public HRESULT EnumerateExtensionsClose() mut => VT.[Friend]EnumerateExtensionsClose(&this);

	public HRESULT EnumerateAttributesSetup(int32 Flags) mut => VT.[Friend]EnumerateAttributesSetup(&this, Flags);

	public HRESULT EnumerateAttributes(BSTR* pstrAttributeName) mut => VT.[Friend]EnumerateAttributes(&this, pstrAttributeName);

	public HRESULT EnumerateAttributesClose() mut => VT.[Friend]EnumerateAttributesClose(&this);
}

[CRepr]struct ICertGetConfig : IDispatch
{
	public new const Guid IID = .(0xc7ea09c0, 0xce17, 0x11d0, 0x88, 0x33, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_GET_CONFIG_FLAGS Flags, BSTR* pstrOut) GetConfig;
	}


	public HRESULT GetConfig(CERT_GET_CONFIG_FLAGS Flags, BSTR* pstrOut) mut => VT.[Friend]GetConfig(&this, Flags, pstrOut);
}

[CRepr]struct ICertConfig : IDispatch
{
	public new const Guid IID = .(0x372fce34, 0x4324, 0x11d0, 0x88, 0x10, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, int32* pCount) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pIndex) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strFieldName, BSTR* pstrOut) GetField;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, BSTR* pstrOut) GetConfig;
	}


	public HRESULT Reset(int32 Index, int32* pCount) mut => VT.[Friend]Reset(&this, Index, pCount);

	public HRESULT Next(int32* pIndex) mut => VT.[Friend]Next(&this, pIndex);

	public HRESULT GetField(BSTR strFieldName, BSTR* pstrOut) mut => VT.[Friend]GetField(&this, strFieldName, pstrOut);

	public HRESULT GetConfig(int32 Flags, BSTR* pstrOut) mut => VT.[Friend]GetConfig(&this, Flags, pstrOut);
}

[CRepr]struct ICertConfig2 : ICertConfig
{
	public new const Guid IID = .(0x7a18edde, 0x7e78, 0x4163, 0x8d, 0xed, 0x78, 0xe2, 0xc9, 0xce, 0xe9, 0x24);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertConfig.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strSharedFolder) SetSharedFolder;
	}


	public HRESULT SetSharedFolder(BSTR strSharedFolder) mut => VT.[Friend]SetSharedFolder(&this, strSharedFolder);
}

[CRepr]struct ICertRequest : IDispatch
{
	public new const Guid IID = .(0x014e4840, 0x5523, 0x11d0, 0x88, 0x12, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, BSTR strRequest, BSTR strAttributes, BSTR strConfig, int32* pDisposition) Submit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 RequestId, BSTR strConfig, int32* pDisposition) RetrievePending;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pStatus) GetLastStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pRequestId) GetRequestId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrDispositionMessage) GetDispositionMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 fExchangeCertificate, BSTR strConfig, int32 Flags, BSTR* pstrCertificate) GetCACertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, BSTR* pstrCertificate) GetCertificate;
	}


	public HRESULT Submit(int32 Flags, BSTR strRequest, BSTR strAttributes, BSTR strConfig, int32* pDisposition) mut => VT.[Friend]Submit(&this, Flags, strRequest, strAttributes, strConfig, pDisposition);

	public HRESULT RetrievePending(int32 RequestId, BSTR strConfig, int32* pDisposition) mut => VT.[Friend]RetrievePending(&this, RequestId, strConfig, pDisposition);

	public HRESULT GetLastStatus(int32* pStatus) mut => VT.[Friend]GetLastStatus(&this, pStatus);

	public HRESULT GetRequestId(int32* pRequestId) mut => VT.[Friend]GetRequestId(&this, pRequestId);

	public HRESULT GetDispositionMessage(BSTR* pstrDispositionMessage) mut => VT.[Friend]GetDispositionMessage(&this, pstrDispositionMessage);

	public HRESULT GetCACertificate(int32 fExchangeCertificate, BSTR strConfig, int32 Flags, BSTR* pstrCertificate) mut => VT.[Friend]GetCACertificate(&this, fExchangeCertificate, strConfig, Flags, pstrCertificate);

	public HRESULT GetCertificate(int32 Flags, BSTR* pstrCertificate) mut => VT.[Friend]GetCertificate(&this, Flags, pstrCertificate);
}

[CRepr]struct ICertRequest2 : ICertRequest
{
	public new const Guid IID = .(0xa4772988, 0x4a85, 0x4fa9, 0x82, 0x4e, 0xb5, 0xcf, 0x5c, 0x16, 0x40, 0x5a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertRequest.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 RequestId, BSTR strSerialNumber, CR_DISP* pDisposition) GetIssuedCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 hrMessage, int32 Flags, BSTR* pstrErrorMessageText) GetErrorMessageText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 PropId, int32 PropIndex, int32 PropType, int32 Flags, VARIANT* pvarPropertyValue) GetCAProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 PropId, int32* pPropFlags) GetCAPropertyFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 PropId, BSTR* pstrDisplayName) GetCAPropertyDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FULL_RESPONSE_PROPERTY_ID PropId, int32 PropIndex, CERT_PROPERTY_TYPE PropType, CERT_REQUEST_OUT_TYPE Flags, VARIANT* pvarPropertyValue) GetFullResponseProperty;
	}


	public HRESULT GetIssuedCertificate(BSTR strConfig, int32 RequestId, BSTR strSerialNumber, CR_DISP* pDisposition) mut => VT.[Friend]GetIssuedCertificate(&this, strConfig, RequestId, strSerialNumber, pDisposition);

	public HRESULT GetErrorMessageText(int32 hrMessage, int32 Flags, BSTR* pstrErrorMessageText) mut => VT.[Friend]GetErrorMessageText(&this, hrMessage, Flags, pstrErrorMessageText);

	public HRESULT GetCAProperty(BSTR strConfig, int32 PropId, int32 PropIndex, int32 PropType, int32 Flags, VARIANT* pvarPropertyValue) mut => VT.[Friend]GetCAProperty(&this, strConfig, PropId, PropIndex, PropType, Flags, pvarPropertyValue);

	public HRESULT GetCAPropertyFlags(BSTR strConfig, int32 PropId, int32* pPropFlags) mut => VT.[Friend]GetCAPropertyFlags(&this, strConfig, PropId, pPropFlags);

	public HRESULT GetCAPropertyDisplayName(BSTR strConfig, int32 PropId, BSTR* pstrDisplayName) mut => VT.[Friend]GetCAPropertyDisplayName(&this, strConfig, PropId, pstrDisplayName);

	public HRESULT GetFullResponseProperty(FULL_RESPONSE_PROPERTY_ID PropId, int32 PropIndex, CERT_PROPERTY_TYPE PropType, CERT_REQUEST_OUT_TYPE Flags, VARIANT* pvarPropertyValue) mut => VT.[Friend]GetFullResponseProperty(&this, PropId, PropIndex, PropType, Flags, pvarPropertyValue);
}

[CRepr]struct ICertRequest3 : ICertRequest2
{
	public new const Guid IID = .(0xafc8f92b, 0x33a2, 0x4861, 0xbf, 0x36, 0x29, 0x33, 0xb7, 0xcd, 0x67, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertRequest2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 hWnd, X509EnrollmentAuthFlags AuthType, BSTR strCredential, BSTR strPassword) SetCredential;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrRequestId) GetRequestIdString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, BSTR strRequestId, BSTR strSerialNumber, CR_DISP* pDisposition) GetIssuedCertificate2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) GetRefreshPolicy;
	}


	public HRESULT SetCredential(int32 hWnd, X509EnrollmentAuthFlags AuthType, BSTR strCredential, BSTR strPassword) mut => VT.[Friend]SetCredential(&this, hWnd, AuthType, strCredential, strPassword);

	public HRESULT GetRequestIdString(BSTR* pstrRequestId) mut => VT.[Friend]GetRequestIdString(&this, pstrRequestId);

	public HRESULT GetIssuedCertificate2(BSTR strConfig, BSTR strRequestId, BSTR strSerialNumber, CR_DISP* pDisposition) mut => VT.[Friend]GetIssuedCertificate2(&this, strConfig, strRequestId, strSerialNumber, pDisposition);

	public HRESULT GetRefreshPolicy(int16* pValue) mut => VT.[Friend]GetRefreshPolicy(&this, pValue);
}

[CRepr]struct ICertManageModule : IDispatch
{
	public new const Guid IID = .(0xe7d7ad42, 0xbd3d, 0x11d1, 0x9a, 0x4d, 0x00, 0xc0, 0x4f, 0xc2, 0x97, 0xeb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, BSTR strStorageLocation, BSTR strPropertyName, int32 Flags, VARIANT* pvarProperty) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, BSTR strStorageLocation, BSTR strPropertyName, int32 Flags, VARIANT* pvarProperty) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, BSTR strStorageLocation, int32 Flags) Configure;
	}


	public HRESULT GetProperty(BSTR strConfig, BSTR strStorageLocation, BSTR strPropertyName, int32 Flags, VARIANT* pvarProperty) mut => VT.[Friend]GetProperty(&this, strConfig, strStorageLocation, strPropertyName, Flags, pvarProperty);

	public HRESULT SetProperty(BSTR strConfig, BSTR strStorageLocation, BSTR strPropertyName, int32 Flags, VARIANT* pvarProperty) mut => VT.[Friend]SetProperty(&this, strConfig, strStorageLocation, strPropertyName, Flags, pvarProperty);

	public HRESULT Configure(BSTR strConfig, BSTR strStorageLocation, int32 Flags) mut => VT.[Friend]Configure(&this, strConfig, strStorageLocation, Flags);
}

[CRepr]struct ICertPolicy : IDispatch
{
	public new const Guid IID = .(0x38bb5a00, 0x7636, 0x11d0, 0xb4, 0x13, 0x00, 0xa0, 0xc9, 0x1b, 0xbf, 0x8c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, int32 Context, int32 bNewRequest, int32 Flags, int32* pDisposition) VerifyRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrDescription) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShutDown;
	}


	public HRESULT Initialize(BSTR strConfig) mut => VT.[Friend]Initialize(&this, strConfig);

	public HRESULT VerifyRequest(BSTR strConfig, int32 Context, int32 bNewRequest, int32 Flags, int32* pDisposition) mut => VT.[Friend]VerifyRequest(&this, strConfig, Context, bNewRequest, Flags, pDisposition);

	public HRESULT GetDescription(BSTR* pstrDescription) mut => VT.[Friend]GetDescription(&this, pstrDescription);

	public HRESULT ShutDown() mut => VT.[Friend]ShutDown(&this);
}

[CRepr]struct ICertPolicy2 : ICertPolicy
{
	public new const Guid IID = .(0x3db4910e, 0x8001, 0x4bf1, 0xaa, 0x1b, 0xf4, 0x3a, 0x80, 0x83, 0x17, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertPolicy.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICertManageModule** ppManageModule) GetManageModule;
	}


	public HRESULT GetManageModule(ICertManageModule** ppManageModule) mut => VT.[Friend]GetManageModule(&this, ppManageModule);
}

[CRepr]struct INDESPolicy : IUnknown
{
	public new const Guid IID = .(0x13ca515d, 0x431d, 0x46cc, 0x8c, 0x2e, 0x1d, 0xa2, 0x69, 0xbb, 0xd6, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Uninitialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszTemplate, PWSTR pwszParams, PWSTR* ppwszResponse) GenerateChallenge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERTTRANSBLOB* pctbRequest, CERTTRANSBLOB* pctbSigningCertEncoded, PWSTR pwszTemplate, PWSTR pwszTransactionId, BOOL* pfVerified) VerifyRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszChallenge, PWSTR pwszTransactionId, X509SCEPDisposition disposition, int32 lastHResult, CERTTRANSBLOB* pctbIssuedCertEncoded) Notify;
	}


	public HRESULT Initialize() mut => VT.[Friend]Initialize(&this);

	public HRESULT Uninitialize() mut => VT.[Friend]Uninitialize(&this);

	public HRESULT GenerateChallenge(PWSTR pwszTemplate, PWSTR pwszParams, PWSTR* ppwszResponse) mut => VT.[Friend]GenerateChallenge(&this, pwszTemplate, pwszParams, ppwszResponse);

	public HRESULT VerifyRequest(CERTTRANSBLOB* pctbRequest, CERTTRANSBLOB* pctbSigningCertEncoded, PWSTR pwszTemplate, PWSTR pwszTransactionId, BOOL* pfVerified) mut => VT.[Friend]VerifyRequest(&this, pctbRequest, pctbSigningCertEncoded, pwszTemplate, pwszTransactionId, pfVerified);

	public HRESULT Notify(PWSTR pwszChallenge, PWSTR pwszTransactionId, X509SCEPDisposition disposition, int32 lastHResult, CERTTRANSBLOB* pctbIssuedCertEncoded) mut => VT.[Friend]Notify(&this, pwszChallenge, pwszTransactionId, disposition, lastHResult, pctbIssuedCertEncoded);
}

[CRepr]struct IObjectId : IDispatch
{
	public new const Guid IID = .(0x728ab300, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERTENROLL_OBJECTID Name) InitializeFromName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strValue) InitializeFromValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ObjectIdGroupId GroupId, ObjectIdPublicKeyFlags KeyFlags, AlgorithmFlags AlgFlags, BSTR strAlgorithmName) InitializeFromAlgorithmName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERTENROLL_OBJECTID* pValue) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_FriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_FriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ObjectIdGroupId GroupId, ObjectIdPublicKeyFlags KeyFlags, BSTR* pstrAlgorithmName) GetAlgorithmName;
	}


	public HRESULT InitializeFromName(CERTENROLL_OBJECTID Name) mut => VT.[Friend]InitializeFromName(&this, Name);

	public HRESULT InitializeFromValue(BSTR strValue) mut => VT.[Friend]InitializeFromValue(&this, strValue);

	public HRESULT InitializeFromAlgorithmName(ObjectIdGroupId GroupId, ObjectIdPublicKeyFlags KeyFlags, AlgorithmFlags AlgFlags, BSTR strAlgorithmName) mut => VT.[Friend]InitializeFromAlgorithmName(&this, GroupId, KeyFlags, AlgFlags, strAlgorithmName);

	public HRESULT get_Name(CERTENROLL_OBJECTID* pValue) mut => VT.[Friend]get_Name(&this, pValue);

	public HRESULT get_FriendlyName(BSTR* pValue) mut => VT.[Friend]get_FriendlyName(&this, pValue);

	public HRESULT put_FriendlyName(BSTR Value) mut => VT.[Friend]put_FriendlyName(&this, Value);

	public HRESULT get_Value(BSTR* pValue) mut => VT.[Friend]get_Value(&this, pValue);

	public HRESULT GetAlgorithmName(ObjectIdGroupId GroupId, ObjectIdPublicKeyFlags KeyFlags, BSTR* pstrAlgorithmName) mut => VT.[Friend]GetAlgorithmName(&this, GroupId, KeyFlags, pstrAlgorithmName);
}

[CRepr]struct IObjectIds : IDispatch
{
	public new const Guid IID = .(0x728ab301, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IObjectId** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectIds* pValue) AddRange;
	}


	public HRESULT get_ItemByIndex(int32 Index, IObjectId** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(IObjectId* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT AddRange(IObjectIds* pValue) mut => VT.[Friend]AddRange(&this, pValue);
}

[CRepr]struct IBinaryConverter : IDispatch
{
	public new const Guid IID = .(0x728ab302, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEncodedIn, EncodingType EncodingIn, EncodingType Encoding, BSTR* pstrEncoded) StringToString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarByteArray, EncodingType Encoding, BSTR* pstrEncoded) VariantByteArrayToString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEncoded, EncodingType Encoding, VARIANT* pvarByteArray) StringToVariantByteArray;
	}


	public HRESULT StringToString(BSTR strEncodedIn, EncodingType EncodingIn, EncodingType Encoding, BSTR* pstrEncoded) mut => VT.[Friend]StringToString(&this, strEncodedIn, EncodingIn, Encoding, pstrEncoded);

	public HRESULT VariantByteArrayToString(VARIANT* pvarByteArray, EncodingType Encoding, BSTR* pstrEncoded) mut => VT.[Friend]VariantByteArrayToString(&this, pvarByteArray, Encoding, pstrEncoded);

	public HRESULT StringToVariantByteArray(BSTR strEncoded, EncodingType Encoding, VARIANT* pvarByteArray) mut => VT.[Friend]StringToVariantByteArray(&this, strEncoded, Encoding, pvarByteArray);
}

[CRepr]struct IBinaryConverter2 : IBinaryConverter
{
	public new const Guid IID = .(0x8d7928b4, 0x4e17, 0x428d, 0x9a, 0x17, 0x72, 0x8d, 0xf0, 0x0d, 0x1b, 0x2b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBinaryConverter.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarStringArray, VARIANT* pvarVariantArray) StringArrayToVariantArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarVariantArray, VARIANT* pvarStringArray) VariantArrayToStringArray;
	}


	public HRESULT StringArrayToVariantArray(VARIANT* pvarStringArray, VARIANT* pvarVariantArray) mut => VT.[Friend]StringArrayToVariantArray(&this, pvarStringArray, pvarVariantArray);

	public HRESULT VariantArrayToStringArray(VARIANT* pvarVariantArray, VARIANT* pvarStringArray) mut => VT.[Friend]VariantArrayToStringArray(&this, pvarVariantArray, pvarStringArray);
}

[CRepr]struct IX500DistinguishedName : IDispatch
{
	public new const Guid IID = .(0x728ab303, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEncodedName, EncodingType Encoding, X500NameFlags NameFlags) Decode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strName, X500NameFlags NameFlags) Encode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_EncodedName;
	}


	public HRESULT Decode(BSTR strEncodedName, EncodingType Encoding, X500NameFlags NameFlags) mut => VT.[Friend]Decode(&this, strEncodedName, Encoding, NameFlags);

	public HRESULT Encode(BSTR strName, X500NameFlags NameFlags) mut => VT.[Friend]Encode(&this, strName, NameFlags);

	public HRESULT get_Name(BSTR* pValue) mut => VT.[Friend]get_Name(&this, pValue);

	public HRESULT get_EncodedName(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_EncodedName(&this, Encoding, pValue);
}

[CRepr]struct IX509EnrollmentStatus : IDispatch
{
	public new const Guid IID = .(0x728ab304, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strText) AppendText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_Text;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_Text;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EnrollmentSelectionStatus* pValue) get_Selected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EnrollmentSelectionStatus Value) put_Selected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EnrollmentDisplayStatus* pValue) get_Display;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EnrollmentDisplayStatus Value) put_Display;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EnrollmentEnrollStatus* pValue) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EnrollmentEnrollStatus Value) put_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* pValue) get_Error;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT Value) put_Error;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_ErrorText;
	}


	public HRESULT AppendText(BSTR strText) mut => VT.[Friend]AppendText(&this, strText);

	public HRESULT get_Text(BSTR* pValue) mut => VT.[Friend]get_Text(&this, pValue);

	public HRESULT put_Text(BSTR Value) mut => VT.[Friend]put_Text(&this, Value);

	public HRESULT get_Selected(EnrollmentSelectionStatus* pValue) mut => VT.[Friend]get_Selected(&this, pValue);

	public HRESULT put_Selected(EnrollmentSelectionStatus Value) mut => VT.[Friend]put_Selected(&this, Value);

	public HRESULT get_Display(EnrollmentDisplayStatus* pValue) mut => VT.[Friend]get_Display(&this, pValue);

	public HRESULT put_Display(EnrollmentDisplayStatus Value) mut => VT.[Friend]put_Display(&this, Value);

	public HRESULT get_Status(EnrollmentEnrollStatus* pValue) mut => VT.[Friend]get_Status(&this, pValue);

	public HRESULT put_Status(EnrollmentEnrollStatus Value) mut => VT.[Friend]put_Status(&this, Value);

	public HRESULT get_Error(HRESULT* pValue) mut => VT.[Friend]get_Error(&this, pValue);

	public HRESULT put_Error(HRESULT Value) mut => VT.[Friend]put_Error(&this, Value);

	public HRESULT get_ErrorText(BSTR* pValue) mut => VT.[Friend]get_ErrorText(&this, pValue);
}

[CRepr]struct ICspAlgorithm : IDispatch
{
	public new const Guid IID = .(0x728ab305, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Length, AlgorithmFlags AlgFlags, IObjectId** ppValue) GetAlgorithmOid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_DefaultLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_IncrementLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_LongName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_Valid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_MaxLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_MinLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AlgorithmType* pValue) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AlgorithmOperationFlags* pValue) get_Operations;
	}


	public HRESULT GetAlgorithmOid(int32 Length, AlgorithmFlags AlgFlags, IObjectId** ppValue) mut => VT.[Friend]GetAlgorithmOid(&this, Length, AlgFlags, ppValue);

	public HRESULT get_DefaultLength(int32* pValue) mut => VT.[Friend]get_DefaultLength(&this, pValue);

	public HRESULT get_IncrementLength(int32* pValue) mut => VT.[Friend]get_IncrementLength(&this, pValue);

	public HRESULT get_LongName(BSTR* pValue) mut => VT.[Friend]get_LongName(&this, pValue);

	public HRESULT get_Valid(int16* pValue) mut => VT.[Friend]get_Valid(&this, pValue);

	public HRESULT get_MaxLength(int32* pValue) mut => VT.[Friend]get_MaxLength(&this, pValue);

	public HRESULT get_MinLength(int32* pValue) mut => VT.[Friend]get_MinLength(&this, pValue);

	public HRESULT get_Name(BSTR* pValue) mut => VT.[Friend]get_Name(&this, pValue);

	public HRESULT get_Type(AlgorithmType* pValue) mut => VT.[Friend]get_Type(&this, pValue);

	public HRESULT get_Operations(AlgorithmOperationFlags* pValue) mut => VT.[Friend]get_Operations(&this, pValue);
}

[CRepr]struct ICspAlgorithms : IDispatch
{
	public new const Guid IID = .(0x728ab306, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ICspAlgorithm** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspAlgorithm* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strName, ICspAlgorithm** ppValue) get_ItemByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pObjectId, int32* pIndex) get_IndexByObjectId;
	}


	public HRESULT get_ItemByIndex(int32 Index, ICspAlgorithm** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(ICspAlgorithm* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT get_ItemByName(BSTR strName, ICspAlgorithm** ppValue) mut => VT.[Friend]get_ItemByName(&this, strName, ppValue);

	public HRESULT get_IndexByObjectId(IObjectId* pObjectId, int32* pIndex) mut => VT.[Friend]get_IndexByObjectId(&this, pObjectId, pIndex);
}

[CRepr]struct ICspInformation : IDispatch
{
	public new const Guid IID = .(0x728ab307, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strName) InitializeFromName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509ProviderType Type, IObjectId* pAlgorithm, int16 MachineContext) InitializeFromType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspAlgorithms** ppValue) get_CspAlgorithms;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_HasHardwareRandomNumberGenerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_IsHardwareDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_IsRemovable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_IsSoftwareDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_Valid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_MaxKeyContainerNameLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509ProviderType* pValue) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_Version;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509KeySpec* pValue) get_KeySpec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_IsSmartCard;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 MachineContext, BSTR* pValue) GetDefaultSecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_LegacyCsp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pAlgorithm, AlgorithmOperationFlags Operations, ICspStatus** ppValue) GetCspStatusFromOperations;
	}


	public HRESULT InitializeFromName(BSTR strName) mut => VT.[Friend]InitializeFromName(&this, strName);

	public HRESULT InitializeFromType(X509ProviderType Type, IObjectId* pAlgorithm, int16 MachineContext) mut => VT.[Friend]InitializeFromType(&this, Type, pAlgorithm, MachineContext);

	public HRESULT get_CspAlgorithms(ICspAlgorithms** ppValue) mut => VT.[Friend]get_CspAlgorithms(&this, ppValue);

	public HRESULT get_HasHardwareRandomNumberGenerator(int16* pValue) mut => VT.[Friend]get_HasHardwareRandomNumberGenerator(&this, pValue);

	public HRESULT get_IsHardwareDevice(int16* pValue) mut => VT.[Friend]get_IsHardwareDevice(&this, pValue);

	public HRESULT get_IsRemovable(int16* pValue) mut => VT.[Friend]get_IsRemovable(&this, pValue);

	public HRESULT get_IsSoftwareDevice(int16* pValue) mut => VT.[Friend]get_IsSoftwareDevice(&this, pValue);

	public HRESULT get_Valid(int16* pValue) mut => VT.[Friend]get_Valid(&this, pValue);

	public HRESULT get_MaxKeyContainerNameLength(int32* pValue) mut => VT.[Friend]get_MaxKeyContainerNameLength(&this, pValue);

	public HRESULT get_Name(BSTR* pValue) mut => VT.[Friend]get_Name(&this, pValue);

	public HRESULT get_Type(X509ProviderType* pValue) mut => VT.[Friend]get_Type(&this, pValue);

	public HRESULT get_Version(int32* pValue) mut => VT.[Friend]get_Version(&this, pValue);

	public HRESULT get_KeySpec(X509KeySpec* pValue) mut => VT.[Friend]get_KeySpec(&this, pValue);

	public HRESULT get_IsSmartCard(int16* pValue) mut => VT.[Friend]get_IsSmartCard(&this, pValue);

	public HRESULT GetDefaultSecurityDescriptor(int16 MachineContext, BSTR* pValue) mut => VT.[Friend]GetDefaultSecurityDescriptor(&this, MachineContext, pValue);

	public HRESULT get_LegacyCsp(int16* pValue) mut => VT.[Friend]get_LegacyCsp(&this, pValue);

	public HRESULT GetCspStatusFromOperations(IObjectId* pAlgorithm, AlgorithmOperationFlags Operations, ICspStatus** ppValue) mut => VT.[Friend]GetCspStatusFromOperations(&this, pAlgorithm, Operations, ppValue);
}

[CRepr]struct ICspInformations : IDispatch
{
	public new const Guid IID = .(0x728ab308, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ICspInformation** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspInformation* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AddAvailableCsps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strName, ICspInformation** ppCspInformation) get_ItemByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strProviderName, X509KeySpec LegacyKeySpec, ICspStatus** ppValue) GetCspStatusFromProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AlgorithmOperationFlags Operations, ICspInformation* pCspInformation, ICspStatuses** ppValue) GetCspStatusesFromOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspInformation* pCspInformation, ICspAlgorithms** ppValue) GetEncryptionCspAlgorithms;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspInformation* pCspInformation, IObjectIds** ppValue) GetHashAlgorithms;
	}


	public HRESULT get_ItemByIndex(int32 Index, ICspInformation** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(ICspInformation* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT AddAvailableCsps() mut => VT.[Friend]AddAvailableCsps(&this);

	public HRESULT get_ItemByName(BSTR strName, ICspInformation** ppCspInformation) mut => VT.[Friend]get_ItemByName(&this, strName, ppCspInformation);

	public HRESULT GetCspStatusFromProviderName(BSTR strProviderName, X509KeySpec LegacyKeySpec, ICspStatus** ppValue) mut => VT.[Friend]GetCspStatusFromProviderName(&this, strProviderName, LegacyKeySpec, ppValue);

	public HRESULT GetCspStatusesFromOperations(AlgorithmOperationFlags Operations, ICspInformation* pCspInformation, ICspStatuses** ppValue) mut => VT.[Friend]GetCspStatusesFromOperations(&this, Operations, pCspInformation, ppValue);

	public HRESULT GetEncryptionCspAlgorithms(ICspInformation* pCspInformation, ICspAlgorithms** ppValue) mut => VT.[Friend]GetEncryptionCspAlgorithms(&this, pCspInformation, ppValue);

	public HRESULT GetHashAlgorithms(ICspInformation* pCspInformation, IObjectIds** ppValue) mut => VT.[Friend]GetHashAlgorithms(&this, pCspInformation, ppValue);
}

[CRepr]struct ICspStatus : IDispatch
{
	public new const Guid IID = .(0x728ab309, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspInformation* pCsp, ICspAlgorithm* pAlgorithm) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_Ordinal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) put_Ordinal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspAlgorithm** ppValue) get_CspAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspInformation** ppValue) get_CspInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509EnrollmentStatus** ppValue) get_EnrollmentStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_DisplayName;
	}


	public HRESULT Initialize(ICspInformation* pCsp, ICspAlgorithm* pAlgorithm) mut => VT.[Friend]Initialize(&this, pCsp, pAlgorithm);

	public HRESULT get_Ordinal(int32* pValue) mut => VT.[Friend]get_Ordinal(&this, pValue);

	public HRESULT put_Ordinal(int32 Value) mut => VT.[Friend]put_Ordinal(&this, Value);

	public HRESULT get_CspAlgorithm(ICspAlgorithm** ppValue) mut => VT.[Friend]get_CspAlgorithm(&this, ppValue);

	public HRESULT get_CspInformation(ICspInformation** ppValue) mut => VT.[Friend]get_CspInformation(&this, ppValue);

	public HRESULT get_EnrollmentStatus(IX509EnrollmentStatus** ppValue) mut => VT.[Friend]get_EnrollmentStatus(&this, ppValue);

	public HRESULT get_DisplayName(BSTR* pValue) mut => VT.[Friend]get_DisplayName(&this, pValue);
}

[CRepr]struct ICspStatuses : IDispatch
{
	public new const Guid IID = .(0x728ab30a, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ICspStatus** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspStatus* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strCspName, BSTR strAlgorithmName, ICspStatus** ppValue) get_ItemByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Ordinal, ICspStatus** ppValue) get_ItemByOrdinal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strCspName, BSTR strAlgorithmName, AlgorithmOperationFlags Operations, ICspStatus** ppValue) get_ItemByOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspStatus* pCspStatus, ICspStatus** ppValue) get_ItemByProvider;
	}


	public HRESULT get_ItemByIndex(int32 Index, ICspStatus** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(ICspStatus* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT get_ItemByName(BSTR strCspName, BSTR strAlgorithmName, ICspStatus** ppValue) mut => VT.[Friend]get_ItemByName(&this, strCspName, strAlgorithmName, ppValue);

	public HRESULT get_ItemByOrdinal(int32 Ordinal, ICspStatus** ppValue) mut => VT.[Friend]get_ItemByOrdinal(&this, Ordinal, ppValue);

	public HRESULT get_ItemByOperations(BSTR strCspName, BSTR strAlgorithmName, AlgorithmOperationFlags Operations, ICspStatus** ppValue) mut => VT.[Friend]get_ItemByOperations(&this, strCspName, strAlgorithmName, Operations, ppValue);

	public HRESULT get_ItemByProvider(ICspStatus* pCspStatus, ICspStatus** ppValue) mut => VT.[Friend]get_ItemByProvider(&this, pCspStatus, ppValue);
}

[CRepr]struct IX509PublicKey : IDispatch
{
	public new const Guid IID = .(0x728ab30b, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pObjectId, BSTR strEncodedKey, BSTR strEncodedParameters, EncodingType Encoding) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEncodedPublicKeyInfo, EncodingType Encoding) InitializeFromEncodedPublicKeyInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_Algorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_EncodedKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_EncodedParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, KeyIdentifierHashAlgorithm Algorithm, EncodingType Encoding, BSTR* pValue) ComputeKeyIdentifier;
	}


	public HRESULT Initialize(IObjectId* pObjectId, BSTR strEncodedKey, BSTR strEncodedParameters, EncodingType Encoding) mut => VT.[Friend]Initialize(&this, pObjectId, strEncodedKey, strEncodedParameters, Encoding);

	public HRESULT InitializeFromEncodedPublicKeyInfo(BSTR strEncodedPublicKeyInfo, EncodingType Encoding) mut => VT.[Friend]InitializeFromEncodedPublicKeyInfo(&this, strEncodedPublicKeyInfo, Encoding);

	public HRESULT get_Algorithm(IObjectId** ppValue) mut => VT.[Friend]get_Algorithm(&this, ppValue);

	public HRESULT get_Length(int32* pValue) mut => VT.[Friend]get_Length(&this, pValue);

	public HRESULT get_EncodedKey(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_EncodedKey(&this, Encoding, pValue);

	public HRESULT get_EncodedParameters(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_EncodedParameters(&this, Encoding, pValue);

	public HRESULT ComputeKeyIdentifier(KeyIdentifierHashAlgorithm Algorithm, EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]ComputeKeyIdentifier(&this, Algorithm, Encoding, pValue);
}

[CRepr]struct IX509PrivateKey : IDispatch
{
	public new const Guid IID = .(0x728ab30c, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509PrivateKeyVerify VerifyType) Verify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strExportType, BSTR strEncodedKey, EncodingType Encoding) Import;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strExportType, EncodingType Encoding, BSTR* pstrEncodedKey) Export;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509PublicKey** ppPublicKey) ExportPublicKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_ContainerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_ContainerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_ContainerNamePrefix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_ContainerNamePrefix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_ReaderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_ReaderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspInformations** ppValue) get_CspInformations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspInformations* pValue) put_CspInformations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspStatus** ppValue) get_CspStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspStatus* pValue) put_CspStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_ProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_ProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509ProviderType* pValue) get_ProviderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509ProviderType Value) put_ProviderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_LegacyCsp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_LegacyCsp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_Algorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pValue) put_Algorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509KeySpec* pValue) get_KeySpec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509KeySpec Value) put_KeySpec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) put_Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509PrivateKeyExportFlags* pValue) get_ExportPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509PrivateKeyExportFlags Value) put_ExportPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509PrivateKeyUsageFlags* pValue) get_KeyUsage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509PrivateKeyUsageFlags Value) put_KeyUsage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509PrivateKeyProtection* pValue) get_KeyProtection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509PrivateKeyProtection Value) put_KeyProtection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_MachineContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_MachineContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_SecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_SecurityDescriptor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_Certificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR Value) put_Certificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_UniqueContainerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_Opened;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_DefaultContainer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_Existing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_Existing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_Silent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_Silent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_ParentWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) put_ParentWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_UIContextMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_UIContextMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_Pin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_FriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_FriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_Description;
	}


	public HRESULT Open() mut => VT.[Friend]Open(&this);

	public HRESULT Create() mut => VT.[Friend]Create(&this);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Verify(X509PrivateKeyVerify VerifyType) mut => VT.[Friend]Verify(&this, VerifyType);

	public HRESULT Import(BSTR strExportType, BSTR strEncodedKey, EncodingType Encoding) mut => VT.[Friend]Import(&this, strExportType, strEncodedKey, Encoding);

	public HRESULT Export(BSTR strExportType, EncodingType Encoding, BSTR* pstrEncodedKey) mut => VT.[Friend]Export(&this, strExportType, Encoding, pstrEncodedKey);

	public HRESULT ExportPublicKey(IX509PublicKey** ppPublicKey) mut => VT.[Friend]ExportPublicKey(&this, ppPublicKey);

	public HRESULT get_ContainerName(BSTR* pValue) mut => VT.[Friend]get_ContainerName(&this, pValue);

	public HRESULT put_ContainerName(BSTR Value) mut => VT.[Friend]put_ContainerName(&this, Value);

	public HRESULT get_ContainerNamePrefix(BSTR* pValue) mut => VT.[Friend]get_ContainerNamePrefix(&this, pValue);

	public HRESULT put_ContainerNamePrefix(BSTR Value) mut => VT.[Friend]put_ContainerNamePrefix(&this, Value);

	public HRESULT get_ReaderName(BSTR* pValue) mut => VT.[Friend]get_ReaderName(&this, pValue);

	public HRESULT put_ReaderName(BSTR Value) mut => VT.[Friend]put_ReaderName(&this, Value);

	public HRESULT get_CspInformations(ICspInformations** ppValue) mut => VT.[Friend]get_CspInformations(&this, ppValue);

	public HRESULT put_CspInformations(ICspInformations* pValue) mut => VT.[Friend]put_CspInformations(&this, pValue);

	public HRESULT get_CspStatus(ICspStatus** ppValue) mut => VT.[Friend]get_CspStatus(&this, ppValue);

	public HRESULT put_CspStatus(ICspStatus* pValue) mut => VT.[Friend]put_CspStatus(&this, pValue);

	public HRESULT get_ProviderName(BSTR* pValue) mut => VT.[Friend]get_ProviderName(&this, pValue);

	public HRESULT put_ProviderName(BSTR Value) mut => VT.[Friend]put_ProviderName(&this, Value);

	public HRESULT get_ProviderType(X509ProviderType* pValue) mut => VT.[Friend]get_ProviderType(&this, pValue);

	public HRESULT put_ProviderType(X509ProviderType Value) mut => VT.[Friend]put_ProviderType(&this, Value);

	public HRESULT get_LegacyCsp(int16* pValue) mut => VT.[Friend]get_LegacyCsp(&this, pValue);

	public HRESULT put_LegacyCsp(int16 Value) mut => VT.[Friend]put_LegacyCsp(&this, Value);

	public HRESULT get_Algorithm(IObjectId** ppValue) mut => VT.[Friend]get_Algorithm(&this, ppValue);

	public HRESULT put_Algorithm(IObjectId* pValue) mut => VT.[Friend]put_Algorithm(&this, pValue);

	public HRESULT get_KeySpec(X509KeySpec* pValue) mut => VT.[Friend]get_KeySpec(&this, pValue);

	public HRESULT put_KeySpec(X509KeySpec Value) mut => VT.[Friend]put_KeySpec(&this, Value);

	public HRESULT get_Length(int32* pValue) mut => VT.[Friend]get_Length(&this, pValue);

	public HRESULT put_Length(int32 Value) mut => VT.[Friend]put_Length(&this, Value);

	public HRESULT get_ExportPolicy(X509PrivateKeyExportFlags* pValue) mut => VT.[Friend]get_ExportPolicy(&this, pValue);

	public HRESULT put_ExportPolicy(X509PrivateKeyExportFlags Value) mut => VT.[Friend]put_ExportPolicy(&this, Value);

	public HRESULT get_KeyUsage(X509PrivateKeyUsageFlags* pValue) mut => VT.[Friend]get_KeyUsage(&this, pValue);

	public HRESULT put_KeyUsage(X509PrivateKeyUsageFlags Value) mut => VT.[Friend]put_KeyUsage(&this, Value);

	public HRESULT get_KeyProtection(X509PrivateKeyProtection* pValue) mut => VT.[Friend]get_KeyProtection(&this, pValue);

	public HRESULT put_KeyProtection(X509PrivateKeyProtection Value) mut => VT.[Friend]put_KeyProtection(&this, Value);

	public HRESULT get_MachineContext(int16* pValue) mut => VT.[Friend]get_MachineContext(&this, pValue);

	public HRESULT put_MachineContext(int16 Value) mut => VT.[Friend]put_MachineContext(&this, Value);

	public HRESULT get_SecurityDescriptor(BSTR* pValue) mut => VT.[Friend]get_SecurityDescriptor(&this, pValue);

	public HRESULT put_SecurityDescriptor(BSTR Value) mut => VT.[Friend]put_SecurityDescriptor(&this, Value);

	public HRESULT get_Certificate(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_Certificate(&this, Encoding, pValue);

	public HRESULT put_Certificate(EncodingType Encoding, BSTR Value) mut => VT.[Friend]put_Certificate(&this, Encoding, Value);

	public HRESULT get_UniqueContainerName(BSTR* pValue) mut => VT.[Friend]get_UniqueContainerName(&this, pValue);

	public HRESULT get_Opened(int16* pValue) mut => VT.[Friend]get_Opened(&this, pValue);

	public HRESULT get_DefaultContainer(int16* pValue) mut => VT.[Friend]get_DefaultContainer(&this, pValue);

	public HRESULT get_Existing(int16* pValue) mut => VT.[Friend]get_Existing(&this, pValue);

	public HRESULT put_Existing(int16 Value) mut => VT.[Friend]put_Existing(&this, Value);

	public HRESULT get_Silent(int16* pValue) mut => VT.[Friend]get_Silent(&this, pValue);

	public HRESULT put_Silent(int16 Value) mut => VT.[Friend]put_Silent(&this, Value);

	public HRESULT get_ParentWindow(int32* pValue) mut => VT.[Friend]get_ParentWindow(&this, pValue);

	public HRESULT put_ParentWindow(int32 Value) mut => VT.[Friend]put_ParentWindow(&this, Value);

	public HRESULT get_UIContextMessage(BSTR* pValue) mut => VT.[Friend]get_UIContextMessage(&this, pValue);

	public HRESULT put_UIContextMessage(BSTR Value) mut => VT.[Friend]put_UIContextMessage(&this, Value);

	public HRESULT put_Pin(BSTR Value) mut => VT.[Friend]put_Pin(&this, Value);

	public HRESULT get_FriendlyName(BSTR* pValue) mut => VT.[Friend]get_FriendlyName(&this, pValue);

	public HRESULT put_FriendlyName(BSTR Value) mut => VT.[Friend]put_FriendlyName(&this, Value);

	public HRESULT get_Description(BSTR* pValue) mut => VT.[Friend]get_Description(&this, pValue);

	public HRESULT put_Description(BSTR Value) mut => VT.[Friend]put_Description(&this, Value);
}

[CRepr]struct IX509PrivateKey2 : IX509PrivateKey
{
	public new const Guid IID = .(0x728ab362, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509PrivateKey.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509HardwareKeyUsageFlags* pValue) get_HardwareKeyUsage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509HardwareKeyUsageFlags Value) put_HardwareKeyUsage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_AlternateStorageLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_AlternateStorageLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_AlgorithmName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_AlgorithmName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_AlgorithmParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR Value) put_AlgorithmParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509KeyParametersExportType* pValue) get_ParametersExportType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509KeyParametersExportType Value) put_ParametersExportType;
	}


	public HRESULT get_HardwareKeyUsage(X509HardwareKeyUsageFlags* pValue) mut => VT.[Friend]get_HardwareKeyUsage(&this, pValue);

	public HRESULT put_HardwareKeyUsage(X509HardwareKeyUsageFlags Value) mut => VT.[Friend]put_HardwareKeyUsage(&this, Value);

	public HRESULT get_AlternateStorageLocation(BSTR* pValue) mut => VT.[Friend]get_AlternateStorageLocation(&this, pValue);

	public HRESULT put_AlternateStorageLocation(BSTR Value) mut => VT.[Friend]put_AlternateStorageLocation(&this, Value);

	public HRESULT get_AlgorithmName(BSTR* pValue) mut => VT.[Friend]get_AlgorithmName(&this, pValue);

	public HRESULT put_AlgorithmName(BSTR Value) mut => VT.[Friend]put_AlgorithmName(&this, Value);

	public HRESULT get_AlgorithmParameters(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_AlgorithmParameters(&this, Encoding, pValue);

	public HRESULT put_AlgorithmParameters(EncodingType Encoding, BSTR Value) mut => VT.[Friend]put_AlgorithmParameters(&this, Encoding, Value);

	public HRESULT get_ParametersExportType(X509KeyParametersExportType* pValue) mut => VT.[Friend]get_ParametersExportType(&this, pValue);

	public HRESULT put_ParametersExportType(X509KeyParametersExportType Value) mut => VT.[Friend]put_ParametersExportType(&this, Value);
}

[CRepr]struct IX509EndorsementKey : IDispatch
{
	public new const Guid IID = .(0xb11cd855, 0xf4c4, 0x4fc6, 0xb7, 0x10, 0x44, 0x22, 0x23, 0x7f, 0x09, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_ProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_ProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_Opened;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strCertificate) AddCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strCertificate) RemoveCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 ManufacturerOnly, int32 dwIndex, EncodingType Encoding, BSTR* pValue) GetCertificateByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 ManufacturerOnly, int32* pCount) GetCertificateCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509PublicKey** ppPublicKey) ExportPublicKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT get_ProviderName(BSTR* pValue) mut => VT.[Friend]get_ProviderName(&this, pValue);

	public HRESULT put_ProviderName(BSTR Value) mut => VT.[Friend]put_ProviderName(&this, Value);

	public HRESULT get_Length(int32* pValue) mut => VT.[Friend]get_Length(&this, pValue);

	public HRESULT get_Opened(int16* pValue) mut => VT.[Friend]get_Opened(&this, pValue);

	public HRESULT AddCertificate(EncodingType Encoding, BSTR strCertificate) mut => VT.[Friend]AddCertificate(&this, Encoding, strCertificate);

	public HRESULT RemoveCertificate(EncodingType Encoding, BSTR strCertificate) mut => VT.[Friend]RemoveCertificate(&this, Encoding, strCertificate);

	public HRESULT GetCertificateByIndex(int16 ManufacturerOnly, int32 dwIndex, EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]GetCertificateByIndex(&this, ManufacturerOnly, dwIndex, Encoding, pValue);

	public HRESULT GetCertificateCount(int16 ManufacturerOnly, int32* pCount) mut => VT.[Friend]GetCertificateCount(&this, ManufacturerOnly, pCount);

	public HRESULT ExportPublicKey(IX509PublicKey** ppPublicKey) mut => VT.[Friend]ExportPublicKey(&this, ppPublicKey);

	public HRESULT Open() mut => VT.[Friend]Open(&this);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IX509Extension : IDispatch
{
	public new const Guid IID = .(0x728ab30d, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pObjectId, EncodingType Encoding, BSTR strEncodedData) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_ObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_RawData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_Critical;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_Critical;
	}


	public HRESULT Initialize(IObjectId* pObjectId, EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]Initialize(&this, pObjectId, Encoding, strEncodedData);

	public HRESULT get_ObjectId(IObjectId** ppValue) mut => VT.[Friend]get_ObjectId(&this, ppValue);

	public HRESULT get_RawData(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_RawData(&this, Encoding, pValue);

	public HRESULT get_Critical(int16* pValue) mut => VT.[Friend]get_Critical(&this, pValue);

	public HRESULT put_Critical(int16 Value) mut => VT.[Friend]put_Critical(&this, Value);
}

[CRepr]struct IX509Extensions : IDispatch
{
	public new const Guid IID = .(0x728ab30e, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IX509Extension** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509Extension* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pObjectId, int32* pIndex) get_IndexByObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509Extensions* pValue) AddRange;
	}


	public HRESULT get_ItemByIndex(int32 Index, IX509Extension** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(IX509Extension* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT get_IndexByObjectId(IObjectId* pObjectId, int32* pIndex) mut => VT.[Friend]get_IndexByObjectId(&this, pObjectId, pIndex);

	public HRESULT AddRange(IX509Extensions* pValue) mut => VT.[Friend]AddRange(&this, pValue);
}

[CRepr]struct IX509ExtensionKeyUsage : IX509Extension
{
	public new const Guid IID = .(0x728ab30f, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Extension.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509KeyUsageFlags UsageFlags) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509KeyUsageFlags* pValue) get_KeyUsage;
	}


	public HRESULT InitializeEncode(X509KeyUsageFlags UsageFlags) mut => VT.[Friend]InitializeEncode(&this, UsageFlags);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_KeyUsage(X509KeyUsageFlags* pValue) mut => VT.[Friend]get_KeyUsage(&this, pValue);
}

[CRepr]struct IX509ExtensionEnhancedKeyUsage : IX509Extension
{
	public new const Guid IID = .(0x728ab310, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Extension.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectIds* pValue) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectIds** ppValue) get_EnhancedKeyUsage;
	}


	public HRESULT InitializeEncode(IObjectIds* pValue) mut => VT.[Friend]InitializeEncode(&this, pValue);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_EnhancedKeyUsage(IObjectIds** ppValue) mut => VT.[Friend]get_EnhancedKeyUsage(&this, ppValue);
}

[CRepr]struct IX509ExtensionTemplateName : IX509Extension
{
	public new const Guid IID = .(0x728ab311, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Extension.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strTemplateName) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_TemplateName;
	}


	public HRESULT InitializeEncode(BSTR strTemplateName) mut => VT.[Friend]InitializeEncode(&this, strTemplateName);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_TemplateName(BSTR* pValue) mut => VT.[Friend]get_TemplateName(&this, pValue);
}

[CRepr]struct IX509ExtensionTemplate : IX509Extension
{
	public new const Guid IID = .(0x728ab312, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Extension.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pTemplateOid, int32 MajorVersion, int32 MinorVersion) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_TemplateOid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_MajorVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_MinorVersion;
	}


	public HRESULT InitializeEncode(IObjectId* pTemplateOid, int32 MajorVersion, int32 MinorVersion) mut => VT.[Friend]InitializeEncode(&this, pTemplateOid, MajorVersion, MinorVersion);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_TemplateOid(IObjectId** ppValue) mut => VT.[Friend]get_TemplateOid(&this, ppValue);

	public HRESULT get_MajorVersion(int32* pValue) mut => VT.[Friend]get_MajorVersion(&this, pValue);

	public HRESULT get_MinorVersion(int32* pValue) mut => VT.[Friend]get_MinorVersion(&this, pValue);
}

[CRepr]struct IAlternativeName : IDispatch
{
	public new const Guid IID = .(0x728ab313, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AlternativeNameType Type, BSTR strValue) InitializeFromString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AlternativeNameType Type, EncodingType Encoding, BSTR strRawData) InitializeFromRawData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pObjectId, EncodingType Encoding, BSTR strRawData, int16 ToBeWrapped) InitializeFromOtherName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AlternativeNameType* pValue) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_StrValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_ObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_RawData;
	}


	public HRESULT InitializeFromString(AlternativeNameType Type, BSTR strValue) mut => VT.[Friend]InitializeFromString(&this, Type, strValue);

	public HRESULT InitializeFromRawData(AlternativeNameType Type, EncodingType Encoding, BSTR strRawData) mut => VT.[Friend]InitializeFromRawData(&this, Type, Encoding, strRawData);

	public HRESULT InitializeFromOtherName(IObjectId* pObjectId, EncodingType Encoding, BSTR strRawData, int16 ToBeWrapped) mut => VT.[Friend]InitializeFromOtherName(&this, pObjectId, Encoding, strRawData, ToBeWrapped);

	public HRESULT get_Type(AlternativeNameType* pValue) mut => VT.[Friend]get_Type(&this, pValue);

	public HRESULT get_StrValue(BSTR* pValue) mut => VT.[Friend]get_StrValue(&this, pValue);

	public HRESULT get_ObjectId(IObjectId** ppValue) mut => VT.[Friend]get_ObjectId(&this, ppValue);

	public HRESULT get_RawData(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_RawData(&this, Encoding, pValue);
}

[CRepr]struct IAlternativeNames : IDispatch
{
	public new const Guid IID = .(0x728ab314, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IAlternativeName** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAlternativeName* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT get_ItemByIndex(int32 Index, IAlternativeName** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(IAlternativeName* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IX509ExtensionAlternativeNames : IX509Extension
{
	public new const Guid IID = .(0x728ab315, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Extension.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAlternativeNames* pValue) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAlternativeNames** ppValue) get_AlternativeNames;
	}


	public HRESULT InitializeEncode(IAlternativeNames* pValue) mut => VT.[Friend]InitializeEncode(&this, pValue);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_AlternativeNames(IAlternativeNames** ppValue) mut => VT.[Friend]get_AlternativeNames(&this, ppValue);
}

[CRepr]struct IX509ExtensionBasicConstraints : IX509Extension
{
	public new const Guid IID = .(0x728ab316, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Extension.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 IsCA, int32 PathLenConstraint) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_IsCA;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_PathLenConstraint;
	}


	public HRESULT InitializeEncode(int16 IsCA, int32 PathLenConstraint) mut => VT.[Friend]InitializeEncode(&this, IsCA, PathLenConstraint);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_IsCA(int16* pValue) mut => VT.[Friend]get_IsCA(&this, pValue);

	public HRESULT get_PathLenConstraint(int32* pValue) mut => VT.[Friend]get_PathLenConstraint(&this, pValue);
}

[CRepr]struct IX509ExtensionSubjectKeyIdentifier : IX509Extension
{
	public new const Guid IID = .(0x728ab317, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Extension.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strKeyIdentifier) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_SubjectKeyIdentifier;
	}


	public HRESULT InitializeEncode(EncodingType Encoding, BSTR strKeyIdentifier) mut => VT.[Friend]InitializeEncode(&this, Encoding, strKeyIdentifier);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_SubjectKeyIdentifier(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_SubjectKeyIdentifier(&this, Encoding, pValue);
}

[CRepr]struct IX509ExtensionAuthorityKeyIdentifier : IX509Extension
{
	public new const Guid IID = .(0x728ab318, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Extension.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strKeyIdentifier) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_AuthorityKeyIdentifier;
	}


	public HRESULT InitializeEncode(EncodingType Encoding, BSTR strKeyIdentifier) mut => VT.[Friend]InitializeEncode(&this, Encoding, strKeyIdentifier);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_AuthorityKeyIdentifier(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_AuthorityKeyIdentifier(&this, Encoding, pValue);
}

[CRepr]struct ISmimeCapability : IDispatch
{
	public new const Guid IID = .(0x728ab319, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pObjectId, int32 BitCount) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_ObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_BitCount;
	}


	public HRESULT Initialize(IObjectId* pObjectId, int32 BitCount) mut => VT.[Friend]Initialize(&this, pObjectId, BitCount);

	public HRESULT get_ObjectId(IObjectId** ppValue) mut => VT.[Friend]get_ObjectId(&this, ppValue);

	public HRESULT get_BitCount(int32* pValue) mut => VT.[Friend]get_BitCount(&this, pValue);
}

[CRepr]struct ISmimeCapabilities : IDispatch
{
	public new const Guid IID = .(0x728ab31a, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ISmimeCapability** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISmimeCapability* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspInformation* pValue) AddFromCsp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 MachineContext) AddAvailableSmimeCapabilities;
	}


	public HRESULT get_ItemByIndex(int32 Index, ISmimeCapability** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(ISmimeCapability* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT AddFromCsp(ICspInformation* pValue) mut => VT.[Friend]AddFromCsp(&this, pValue);

	public HRESULT AddAvailableSmimeCapabilities(int16 MachineContext) mut => VT.[Friend]AddAvailableSmimeCapabilities(&this, MachineContext);
}

[CRepr]struct IX509ExtensionSmimeCapabilities : IX509Extension
{
	public new const Guid IID = .(0x728ab31b, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Extension.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISmimeCapabilities* pValue) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISmimeCapabilities** ppValue) get_SmimeCapabilities;
	}


	public HRESULT InitializeEncode(ISmimeCapabilities* pValue) mut => VT.[Friend]InitializeEncode(&this, pValue);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_SmimeCapabilities(ISmimeCapabilities** ppValue) mut => VT.[Friend]get_SmimeCapabilities(&this, ppValue);
}

[CRepr]struct IPolicyQualifier : IDispatch
{
	public new const Guid IID = .(0x728ab31c, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strQualifier, PolicyQualifierType Type) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_ObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_Qualifier;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PolicyQualifierType* pValue) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_RawData;
	}


	public HRESULT InitializeEncode(BSTR strQualifier, PolicyQualifierType Type) mut => VT.[Friend]InitializeEncode(&this, strQualifier, Type);

	public HRESULT get_ObjectId(IObjectId** ppValue) mut => VT.[Friend]get_ObjectId(&this, ppValue);

	public HRESULT get_Qualifier(BSTR* pValue) mut => VT.[Friend]get_Qualifier(&this, pValue);

	public HRESULT get_Type(PolicyQualifierType* pValue) mut => VT.[Friend]get_Type(&this, pValue);

	public HRESULT get_RawData(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_RawData(&this, Encoding, pValue);
}

[CRepr]struct IPolicyQualifiers : IDispatch
{
	public new const Guid IID = .(0x728ab31d, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IPolicyQualifier** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPolicyQualifier* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT get_ItemByIndex(int32 Index, IPolicyQualifier** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(IPolicyQualifier* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct ICertificatePolicy : IDispatch
{
	public new const Guid IID = .(0x728ab31e, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pValue) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_ObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPolicyQualifiers** ppValue) get_PolicyQualifiers;
	}


	public HRESULT Initialize(IObjectId* pValue) mut => VT.[Friend]Initialize(&this, pValue);

	public HRESULT get_ObjectId(IObjectId** ppValue) mut => VT.[Friend]get_ObjectId(&this, ppValue);

	public HRESULT get_PolicyQualifiers(IPolicyQualifiers** ppValue) mut => VT.[Friend]get_PolicyQualifiers(&this, ppValue);
}

[CRepr]struct ICertificatePolicies : IDispatch
{
	public new const Guid IID = .(0x728ab31f, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ICertificatePolicy** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICertificatePolicy* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT get_ItemByIndex(int32 Index, ICertificatePolicy** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(ICertificatePolicy* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IX509ExtensionCertificatePolicies : IX509Extension
{
	public new const Guid IID = .(0x728ab320, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Extension.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICertificatePolicies* pValue) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICertificatePolicies** ppValue) get_Policies;
	}


	public HRESULT InitializeEncode(ICertificatePolicies* pValue) mut => VT.[Friend]InitializeEncode(&this, pValue);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_Policies(ICertificatePolicies** ppValue) mut => VT.[Friend]get_Policies(&this, ppValue);
}

[CRepr]struct IX509ExtensionMSApplicationPolicies : IX509Extension
{
	public new const Guid IID = .(0x728ab321, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Extension.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICertificatePolicies* pValue) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICertificatePolicies** ppValue) get_Policies;
	}


	public HRESULT InitializeEncode(ICertificatePolicies* pValue) mut => VT.[Friend]InitializeEncode(&this, pValue);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_Policies(ICertificatePolicies** ppValue) mut => VT.[Friend]get_Policies(&this, ppValue);
}

[CRepr]struct IX509Attribute : IDispatch
{
	public new const Guid IID = .(0x728ab322, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pObjectId, EncodingType Encoding, BSTR strEncodedData) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_ObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_RawData;
	}


	public HRESULT Initialize(IObjectId* pObjectId, EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]Initialize(&this, pObjectId, Encoding, strEncodedData);

	public HRESULT get_ObjectId(IObjectId** ppValue) mut => VT.[Friend]get_ObjectId(&this, ppValue);

	public HRESULT get_RawData(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_RawData(&this, Encoding, pValue);
}

[CRepr]struct IX509Attributes : IDispatch
{
	public new const Guid IID = .(0x728ab323, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IX509Attribute** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509Attribute* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT get_ItemByIndex(int32 Index, IX509Attribute** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(IX509Attribute* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IX509AttributeExtensions : IX509Attribute
{
	public new const Guid IID = .(0x728ab324, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Attribute.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509Extensions* pExtensions) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509Extensions** ppValue) get_X509Extensions;
	}


	public HRESULT InitializeEncode(IX509Extensions* pExtensions) mut => VT.[Friend]InitializeEncode(&this, pExtensions);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_X509Extensions(IX509Extensions** ppValue) mut => VT.[Friend]get_X509Extensions(&this, ppValue);
}

[CRepr]struct IX509AttributeClientId : IX509Attribute
{
	public new const Guid IID = .(0x728ab325, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Attribute.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RequestClientInfoClientId ClientId, BSTR strMachineDnsName, BSTR strUserSamName, BSTR strProcessName) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RequestClientInfoClientId* pValue) get_ClientId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_MachineDnsName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_UserSamName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_ProcessName;
	}


	public HRESULT InitializeEncode(RequestClientInfoClientId ClientId, BSTR strMachineDnsName, BSTR strUserSamName, BSTR strProcessName) mut => VT.[Friend]InitializeEncode(&this, ClientId, strMachineDnsName, strUserSamName, strProcessName);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_ClientId(RequestClientInfoClientId* pValue) mut => VT.[Friend]get_ClientId(&this, pValue);

	public HRESULT get_MachineDnsName(BSTR* pValue) mut => VT.[Friend]get_MachineDnsName(&this, pValue);

	public HRESULT get_UserSamName(BSTR* pValue) mut => VT.[Friend]get_UserSamName(&this, pValue);

	public HRESULT get_ProcessName(BSTR* pValue) mut => VT.[Friend]get_ProcessName(&this, pValue);
}

[CRepr]struct IX509AttributeRenewalCertificate : IX509Attribute
{
	public new const Guid IID = .(0x728ab326, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Attribute.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strCert) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_RenewalCertificate;
	}


	public HRESULT InitializeEncode(EncodingType Encoding, BSTR strCert) mut => VT.[Friend]InitializeEncode(&this, Encoding, strCert);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_RenewalCertificate(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_RenewalCertificate(&this, Encoding, pValue);
}

[CRepr]struct IX509AttributeArchiveKey : IX509Attribute
{
	public new const Guid IID = .(0x728ab327, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Attribute.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509PrivateKey* pKey, EncodingType Encoding, BSTR strCAXCert, IObjectId* pAlgorithm, int32 EncryptionStrength) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_EncryptedKeyBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_EncryptionAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_EncryptionStrength;
	}


	public HRESULT InitializeEncode(IX509PrivateKey* pKey, EncodingType Encoding, BSTR strCAXCert, IObjectId* pAlgorithm, int32 EncryptionStrength) mut => VT.[Friend]InitializeEncode(&this, pKey, Encoding, strCAXCert, pAlgorithm, EncryptionStrength);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_EncryptedKeyBlob(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_EncryptedKeyBlob(&this, Encoding, pValue);

	public HRESULT get_EncryptionAlgorithm(IObjectId** ppValue) mut => VT.[Friend]get_EncryptionAlgorithm(&this, ppValue);

	public HRESULT get_EncryptionStrength(int32* pValue) mut => VT.[Friend]get_EncryptionStrength(&this, pValue);
}

[CRepr]struct IX509AttributeArchiveKeyHash : IX509Attribute
{
	public new const Guid IID = .(0x728ab328, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Attribute.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncryptedKeyBlob) InitializeEncodeFromEncryptedKeyBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_EncryptedKeyHashBlob;
	}


	public HRESULT InitializeEncodeFromEncryptedKeyBlob(EncodingType Encoding, BSTR strEncryptedKeyBlob) mut => VT.[Friend]InitializeEncodeFromEncryptedKeyBlob(&this, Encoding, strEncryptedKeyBlob);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_EncryptedKeyHashBlob(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_EncryptedKeyHashBlob(&this, Encoding, pValue);
}

[CRepr]struct IX509AttributeOSVersion : IX509Attribute
{
	public new const Guid IID = .(0x728ab32a, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Attribute.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strOSVersion) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_OSVersion;
	}


	public HRESULT InitializeEncode(BSTR strOSVersion) mut => VT.[Friend]InitializeEncode(&this, strOSVersion);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_OSVersion(BSTR* pValue) mut => VT.[Friend]get_OSVersion(&this, pValue);
}

[CRepr]struct IX509AttributeCspProvider : IX509Attribute
{
	public new const Guid IID = .(0x728ab32b, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Attribute.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509KeySpec KeySpec, BSTR strProviderName, EncodingType Encoding, BSTR strSignature) InitializeEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509KeySpec* pValue) get_KeySpec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_ProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_Signature;
	}


	public HRESULT InitializeEncode(X509KeySpec KeySpec, BSTR strProviderName, EncodingType Encoding, BSTR strSignature) mut => VT.[Friend]InitializeEncode(&this, KeySpec, strProviderName, Encoding, strSignature);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_KeySpec(X509KeySpec* pValue) mut => VT.[Friend]get_KeySpec(&this, pValue);

	public HRESULT get_ProviderName(BSTR* pValue) mut => VT.[Friend]get_ProviderName(&this, pValue);

	public HRESULT get_Signature(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_Signature(&this, Encoding, pValue);
}

[CRepr]struct ICryptAttribute : IDispatch
{
	public new const Guid IID = .(0x728ab32c, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pObjectId) InitializeFromObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509Attributes* pAttributes) InitializeFromValues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_ObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509Attributes** ppValue) get_Values;
	}


	public HRESULT InitializeFromObjectId(IObjectId* pObjectId) mut => VT.[Friend]InitializeFromObjectId(&this, pObjectId);

	public HRESULT InitializeFromValues(IX509Attributes* pAttributes) mut => VT.[Friend]InitializeFromValues(&this, pAttributes);

	public HRESULT get_ObjectId(IObjectId** ppValue) mut => VT.[Friend]get_ObjectId(&this, ppValue);

	public HRESULT get_Values(IX509Attributes** ppValue) mut => VT.[Friend]get_Values(&this, ppValue);
}

[CRepr]struct ICryptAttributes : IDispatch
{
	public new const Guid IID = .(0x728ab32d, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ICryptAttribute** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICryptAttribute* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pObjectId, int32* pIndex) get_IndexByObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICryptAttributes* pValue) AddRange;
	}


	public HRESULT get_ItemByIndex(int32 Index, ICryptAttribute** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(ICryptAttribute* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT get_IndexByObjectId(IObjectId* pObjectId, int32* pIndex) mut => VT.[Friend]get_IndexByObjectId(&this, pObjectId, pIndex);

	public HRESULT AddRange(ICryptAttributes* pValue) mut => VT.[Friend]AddRange(&this, pValue);
}

[CRepr]struct ICertProperty : IDispatch
{
	public new const Guid IID = .(0x728ab32e, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 MachineContext, EncodingType Encoding, BSTR strCertificate) InitializeFromCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strEncodedData) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERTENROLL_PROPERTYID* pValue) get_PropertyId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERTENROLL_PROPERTYID Value) put_PropertyId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_RawData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 MachineContext, EncodingType Encoding, BSTR strCertificate) RemoveFromCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 MachineContext, EncodingType Encoding, BSTR strCertificate) SetValueOnCertificate;
	}


	public HRESULT InitializeFromCertificate(int16 MachineContext, EncodingType Encoding, BSTR strCertificate) mut => VT.[Friend]InitializeFromCertificate(&this, MachineContext, Encoding, strCertificate);

	public HRESULT InitializeDecode(EncodingType Encoding, BSTR strEncodedData) mut => VT.[Friend]InitializeDecode(&this, Encoding, strEncodedData);

	public HRESULT get_PropertyId(CERTENROLL_PROPERTYID* pValue) mut => VT.[Friend]get_PropertyId(&this, pValue);

	public HRESULT put_PropertyId(CERTENROLL_PROPERTYID Value) mut => VT.[Friend]put_PropertyId(&this, Value);

	public HRESULT get_RawData(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_RawData(&this, Encoding, pValue);

	public HRESULT RemoveFromCertificate(int16 MachineContext, EncodingType Encoding, BSTR strCertificate) mut => VT.[Friend]RemoveFromCertificate(&this, MachineContext, Encoding, strCertificate);

	public HRESULT SetValueOnCertificate(int16 MachineContext, EncodingType Encoding, BSTR strCertificate) mut => VT.[Friend]SetValueOnCertificate(&this, MachineContext, Encoding, strCertificate);
}

[CRepr]struct ICertProperties : IDispatch
{
	public new const Guid IID = .(0x728ab32f, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ICertProperty** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICertProperty* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 MachineContext, EncodingType Encoding, BSTR strCertificate) InitializeFromCertificate;
	}


	public HRESULT get_ItemByIndex(int32 Index, ICertProperty** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(ICertProperty* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT InitializeFromCertificate(int16 MachineContext, EncodingType Encoding, BSTR strCertificate) mut => VT.[Friend]InitializeFromCertificate(&this, MachineContext, Encoding, strCertificate);
}

[CRepr]struct ICertPropertyFriendlyName : ICertProperty
{
	public new const Guid IID = .(0x728ab330, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertProperty.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strFriendlyName) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_FriendlyName;
	}


	public HRESULT Initialize(BSTR strFriendlyName) mut => VT.[Friend]Initialize(&this, strFriendlyName);

	public HRESULT get_FriendlyName(BSTR* pValue) mut => VT.[Friend]get_FriendlyName(&this, pValue);
}

[CRepr]struct ICertPropertyDescription : ICertProperty
{
	public new const Guid IID = .(0x728ab331, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertProperty.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strDescription) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_Description;
	}


	public HRESULT Initialize(BSTR strDescription) mut => VT.[Friend]Initialize(&this, strDescription);

	public HRESULT get_Description(BSTR* pValue) mut => VT.[Friend]get_Description(&this, pValue);
}

[CRepr]struct ICertPropertyAutoEnroll : ICertProperty
{
	public new const Guid IID = .(0x728ab332, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertProperty.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strTemplateName) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_TemplateName;
	}


	public HRESULT Initialize(BSTR strTemplateName) mut => VT.[Friend]Initialize(&this, strTemplateName);

	public HRESULT get_TemplateName(BSTR* pValue) mut => VT.[Friend]get_TemplateName(&this, pValue);
}

[CRepr]struct ICertPropertyRequestOriginator : ICertProperty
{
	public new const Guid IID = .(0x728ab333, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertProperty.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strRequestOriginator) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InitializeFromLocalRequestOriginator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_RequestOriginator;
	}


	public HRESULT Initialize(BSTR strRequestOriginator) mut => VT.[Friend]Initialize(&this, strRequestOriginator);

	public HRESULT InitializeFromLocalRequestOriginator() mut => VT.[Friend]InitializeFromLocalRequestOriginator(&this);

	public HRESULT get_RequestOriginator(BSTR* pValue) mut => VT.[Friend]get_RequestOriginator(&this, pValue);
}

[CRepr]struct ICertPropertySHA1Hash : ICertProperty
{
	public new const Guid IID = .(0x728ab334, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertProperty.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strRenewalValue) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_SHA1Hash;
	}


	public HRESULT Initialize(EncodingType Encoding, BSTR strRenewalValue) mut => VT.[Friend]Initialize(&this, Encoding, strRenewalValue);

	public HRESULT get_SHA1Hash(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_SHA1Hash(&this, Encoding, pValue);
}

[CRepr]struct ICertPropertyKeyProvInfo : ICertProperty
{
	public new const Guid IID = .(0x728ab336, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertProperty.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509PrivateKey* pValue) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509PrivateKey** ppValue) get_PrivateKey;
	}


	public HRESULT Initialize(IX509PrivateKey* pValue) mut => VT.[Friend]Initialize(&this, pValue);

	public HRESULT get_PrivateKey(IX509PrivateKey** ppValue) mut => VT.[Friend]get_PrivateKey(&this, ppValue);
}

[CRepr]struct ICertPropertyArchived : ICertProperty
{
	public new const Guid IID = .(0x728ab337, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertProperty.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 ArchivedValue) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_Archived;
	}


	public HRESULT Initialize(int16 ArchivedValue) mut => VT.[Friend]Initialize(&this, ArchivedValue);

	public HRESULT get_Archived(int16* pValue) mut => VT.[Friend]get_Archived(&this, pValue);
}

[CRepr]struct ICertPropertyBackedUp : ICertProperty
{
	public new const Guid IID = .(0x728ab338, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertProperty.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 BackedUpValue) InitializeFromCurrentTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 BackedUpValue, double Date) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_BackedUpValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pDate) get_BackedUpTime;
	}


	public HRESULT InitializeFromCurrentTime(int16 BackedUpValue) mut => VT.[Friend]InitializeFromCurrentTime(&this, BackedUpValue);

	public HRESULT Initialize(int16 BackedUpValue, double Date) mut => VT.[Friend]Initialize(&this, BackedUpValue, Date);

	public HRESULT get_BackedUpValue(int16* pValue) mut => VT.[Friend]get_BackedUpValue(&this, pValue);

	public HRESULT get_BackedUpTime(double* pDate) mut => VT.[Friend]get_BackedUpTime(&this, pDate);
}

[CRepr]struct ICertPropertyEnrollment : ICertProperty
{
	public new const Guid IID = .(0x728ab339, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertProperty.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 RequestId, BSTR strCADnsName, BSTR strCAName, BSTR strFriendlyName) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_RequestId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_CADnsName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_CAName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_FriendlyName;
	}


	public HRESULT Initialize(int32 RequestId, BSTR strCADnsName, BSTR strCAName, BSTR strFriendlyName) mut => VT.[Friend]Initialize(&this, RequestId, strCADnsName, strCAName, strFriendlyName);

	public HRESULT get_RequestId(int32* pValue) mut => VT.[Friend]get_RequestId(&this, pValue);

	public HRESULT get_CADnsName(BSTR* pValue) mut => VT.[Friend]get_CADnsName(&this, pValue);

	public HRESULT get_CAName(BSTR* pValue) mut => VT.[Friend]get_CAName(&this, pValue);

	public HRESULT get_FriendlyName(BSTR* pValue) mut => VT.[Friend]get_FriendlyName(&this, pValue);
}

[CRepr]struct ICertPropertyRenewal : ICertProperty
{
	public new const Guid IID = .(0x728ab33a, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertProperty.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strRenewalValue) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 MachineContext, EncodingType Encoding, BSTR strCertificate) InitializeFromCertificateHash;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_Renewal;
	}


	public HRESULT Initialize(EncodingType Encoding, BSTR strRenewalValue) mut => VT.[Friend]Initialize(&this, Encoding, strRenewalValue);

	public HRESULT InitializeFromCertificateHash(int16 MachineContext, EncodingType Encoding, BSTR strCertificate) mut => VT.[Friend]InitializeFromCertificateHash(&this, MachineContext, Encoding, strCertificate);

	public HRESULT get_Renewal(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_Renewal(&this, Encoding, pValue);
}

[CRepr]struct ICertPropertyArchivedKeyHash : ICertProperty
{
	public new const Guid IID = .(0x728ab33b, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertProperty.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strArchivedKeyHashValue) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_ArchivedKeyHash;
	}


	public HRESULT Initialize(EncodingType Encoding, BSTR strArchivedKeyHashValue) mut => VT.[Friend]Initialize(&this, Encoding, strArchivedKeyHashValue);

	public HRESULT get_ArchivedKeyHash(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_ArchivedKeyHash(&this, Encoding, pValue);
}

[CRepr]struct ICertPropertyEnrollmentPolicyServer : ICertProperty
{
	public new const Guid IID = .(0x728ab34a, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertProperty.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EnrollmentPolicyServerPropertyFlags PropertyFlags, X509EnrollmentAuthFlags AuthFlags, X509EnrollmentAuthFlags EnrollmentServerAuthFlags, PolicyServerUrlFlags UrlFlags, BSTR strRequestId, BSTR strUrl, BSTR strId, BSTR strEnrollmentServerUrl) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) GetPolicyServerUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) GetPolicyServerId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) GetEnrollmentServerUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) GetRequestIdString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EnrollmentPolicyServerPropertyFlags* pValue) GetPropertyFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PolicyServerUrlFlags* pValue) GetUrlFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509EnrollmentAuthFlags* pValue) GetAuthentication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509EnrollmentAuthFlags* pValue) GetEnrollmentServerAuthentication;
	}


	public HRESULT Initialize(EnrollmentPolicyServerPropertyFlags PropertyFlags, X509EnrollmentAuthFlags AuthFlags, X509EnrollmentAuthFlags EnrollmentServerAuthFlags, PolicyServerUrlFlags UrlFlags, BSTR strRequestId, BSTR strUrl, BSTR strId, BSTR strEnrollmentServerUrl) mut => VT.[Friend]Initialize(&this, PropertyFlags, AuthFlags, EnrollmentServerAuthFlags, UrlFlags, strRequestId, strUrl, strId, strEnrollmentServerUrl);

	public HRESULT GetPolicyServerUrl(BSTR* pValue) mut => VT.[Friend]GetPolicyServerUrl(&this, pValue);

	public HRESULT GetPolicyServerId(BSTR* pValue) mut => VT.[Friend]GetPolicyServerId(&this, pValue);

	public HRESULT GetEnrollmentServerUrl(BSTR* pValue) mut => VT.[Friend]GetEnrollmentServerUrl(&this, pValue);

	public HRESULT GetRequestIdString(BSTR* pValue) mut => VT.[Friend]GetRequestIdString(&this, pValue);

	public HRESULT GetPropertyFlags(EnrollmentPolicyServerPropertyFlags* pValue) mut => VT.[Friend]GetPropertyFlags(&this, pValue);

	public HRESULT GetUrlFlags(PolicyServerUrlFlags* pValue) mut => VT.[Friend]GetUrlFlags(&this, pValue);

	public HRESULT GetAuthentication(X509EnrollmentAuthFlags* pValue) mut => VT.[Friend]GetAuthentication(&this, pValue);

	public HRESULT GetEnrollmentServerAuthentication(X509EnrollmentAuthFlags* pValue) mut => VT.[Friend]GetEnrollmentServerAuthentication(&this, pValue);
}

[CRepr]struct IX509SignatureInformation : IDispatch
{
	public new const Guid IID = .(0x728ab33c, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pValue) put_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_PublicKeyAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pValue) put_PublicKeyAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_Parameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR Value) put_Parameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_AlternateSignatureAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_AlternateSignatureAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_AlternateSignatureAlgorithmSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_NullSigned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_NullSigned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Pkcs7Signature, int16 SignatureKey, IObjectId** ppValue) GetSignatureAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetDefaultValues;
	}


	public HRESULT get_HashAlgorithm(IObjectId** ppValue) mut => VT.[Friend]get_HashAlgorithm(&this, ppValue);

	public HRESULT put_HashAlgorithm(IObjectId* pValue) mut => VT.[Friend]put_HashAlgorithm(&this, pValue);

	public HRESULT get_PublicKeyAlgorithm(IObjectId** ppValue) mut => VT.[Friend]get_PublicKeyAlgorithm(&this, ppValue);

	public HRESULT put_PublicKeyAlgorithm(IObjectId* pValue) mut => VT.[Friend]put_PublicKeyAlgorithm(&this, pValue);

	public HRESULT get_Parameters(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_Parameters(&this, Encoding, pValue);

	public HRESULT put_Parameters(EncodingType Encoding, BSTR Value) mut => VT.[Friend]put_Parameters(&this, Encoding, Value);

	public HRESULT get_AlternateSignatureAlgorithm(int16* pValue) mut => VT.[Friend]get_AlternateSignatureAlgorithm(&this, pValue);

	public HRESULT put_AlternateSignatureAlgorithm(int16 Value) mut => VT.[Friend]put_AlternateSignatureAlgorithm(&this, Value);

	public HRESULT get_AlternateSignatureAlgorithmSet(int16* pValue) mut => VT.[Friend]get_AlternateSignatureAlgorithmSet(&this, pValue);

	public HRESULT get_NullSigned(int16* pValue) mut => VT.[Friend]get_NullSigned(&this, pValue);

	public HRESULT put_NullSigned(int16 Value) mut => VT.[Friend]put_NullSigned(&this, Value);

	public HRESULT GetSignatureAlgorithm(int16 Pkcs7Signature, int16 SignatureKey, IObjectId** ppValue) mut => VT.[Friend]GetSignatureAlgorithm(&this, Pkcs7Signature, SignatureKey, ppValue);

	public HRESULT SetDefaultValues() mut => VT.[Friend]SetDefaultValues(&this);
}

[CRepr]struct ISignerCertificate : IDispatch
{
	public new const Guid IID = .(0x728ab33d, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 MachineContext, X509PrivateKeyVerify VerifyType, EncodingType Encoding, BSTR strCertificate) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_Certificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509PrivateKey** ppValue) get_PrivateKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_Silent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_Silent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_ParentWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) put_ParentWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_UIContextMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_UIContextMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_Pin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509SignatureInformation** ppValue) get_SignatureInformation;
	}


	public HRESULT Initialize(int16 MachineContext, X509PrivateKeyVerify VerifyType, EncodingType Encoding, BSTR strCertificate) mut => VT.[Friend]Initialize(&this, MachineContext, VerifyType, Encoding, strCertificate);

	public HRESULT get_Certificate(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_Certificate(&this, Encoding, pValue);

	public HRESULT get_PrivateKey(IX509PrivateKey** ppValue) mut => VT.[Friend]get_PrivateKey(&this, ppValue);

	public HRESULT get_Silent(int16* pValue) mut => VT.[Friend]get_Silent(&this, pValue);

	public HRESULT put_Silent(int16 Value) mut => VT.[Friend]put_Silent(&this, Value);

	public HRESULT get_ParentWindow(int32* pValue) mut => VT.[Friend]get_ParentWindow(&this, pValue);

	public HRESULT put_ParentWindow(int32 Value) mut => VT.[Friend]put_ParentWindow(&this, Value);

	public HRESULT get_UIContextMessage(BSTR* pValue) mut => VT.[Friend]get_UIContextMessage(&this, pValue);

	public HRESULT put_UIContextMessage(BSTR Value) mut => VT.[Friend]put_UIContextMessage(&this, Value);

	public HRESULT put_Pin(BSTR Value) mut => VT.[Friend]put_Pin(&this, Value);

	public HRESULT get_SignatureInformation(IX509SignatureInformation** ppValue) mut => VT.[Friend]get_SignatureInformation(&this, ppValue);
}

[CRepr]struct ISignerCertificates : IDispatch
{
	public new const Guid IID = .(0x728ab33e, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ISignerCertificate** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificate* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificate* pSignerCert, int32* piSignerCert) Find;
	}


	public HRESULT get_ItemByIndex(int32 Index, ISignerCertificate** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(ISignerCertificate* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT Find(ISignerCertificate* pSignerCert, int32* piSignerCert) mut => VT.[Friend]Find(&this, pSignerCert, piSignerCert);
}

[CRepr]struct IX509NameValuePair : IDispatch
{
	public new const Guid IID = .(0x728ab33f, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strName, BSTR strValue) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_Name;
	}


	public HRESULT Initialize(BSTR strName, BSTR strValue) mut => VT.[Friend]Initialize(&this, strName, strValue);

	public HRESULT get_Value(BSTR* pValue) mut => VT.[Friend]get_Value(&this, pValue);

	public HRESULT get_Name(BSTR* pValue) mut => VT.[Friend]get_Name(&this, pValue);
}

[CRepr]struct IX509NameValuePairs : IDispatch
{
	public new const Guid IID = .(0x728ab340, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IX509NameValuePair** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509NameValuePair* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT get_ItemByIndex(int32 Index, IX509NameValuePair** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(IX509NameValuePair* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IX509CertificateTemplate : IDispatch
{
	public new const Guid IID = .(0x54244a13, 0x555a, 0x4e22, 0x89, 0x6d, 0x1b, 0x0e, 0x52, 0xf7, 0x64, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EnrollmentTemplateProperty property, VARIANT* pValue) get_Property;
	}


	public HRESULT get_Property(EnrollmentTemplateProperty property, VARIANT* pValue) mut => VT.[Friend]get_Property(&this, property, pValue);
}

[CRepr]struct IX509CertificateTemplates : IDispatch
{
	public new const Guid IID = .(0x13b79003, 0x2181, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IX509CertificateTemplate** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateTemplate* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, IX509CertificateTemplate** ppValue) get_ItemByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pOid, IX509CertificateTemplate** ppValue) get_ItemByOid;
	}


	public HRESULT get_ItemByIndex(int32 Index, IX509CertificateTemplate** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(IX509CertificateTemplate* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT get_ItemByName(BSTR bstrName, IX509CertificateTemplate** ppValue) mut => VT.[Friend]get_ItemByName(&this, bstrName, ppValue);

	public HRESULT get_ItemByOid(IObjectId* pOid, IX509CertificateTemplate** ppValue) mut => VT.[Friend]get_ItemByOid(&this, pOid, ppValue);
}

[CRepr]struct IX509CertificateTemplateWritable : IDispatch
{
	public new const Guid IID = .(0xf49466a7, 0x395a, 0x4e9e, 0xb6, 0xe7, 0x32, 0xb3, 0x31, 0x60, 0x0d, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateTemplate* pValue) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CommitTemplateFlags commitFlags, BSTR strServerContext) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EnrollmentTemplateProperty property, VARIANT* pValue) get_Property;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EnrollmentTemplateProperty property, VARIANT value) put_Property;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateTemplate** ppValue) get_Template;
	}


	public HRESULT Initialize(IX509CertificateTemplate* pValue) mut => VT.[Friend]Initialize(&this, pValue);

	public HRESULT Commit(CommitTemplateFlags commitFlags, BSTR strServerContext) mut => VT.[Friend]Commit(&this, commitFlags, strServerContext);

	public HRESULT get_Property(EnrollmentTemplateProperty property, VARIANT* pValue) mut => VT.[Friend]get_Property(&this, property, pValue);

	public HRESULT put_Property(EnrollmentTemplateProperty property, VARIANT value) mut => VT.[Friend]put_Property(&this, property, value);

	public HRESULT get_Template(IX509CertificateTemplate** ppValue) mut => VT.[Friend]get_Template(&this, ppValue);
}

[CRepr]struct ICertificationAuthority : IDispatch
{
	public new const Guid IID = .(0x835d1f61, 0x1e95, 0x4bc8, 0xb4, 0xd3, 0x97, 0x6c, 0x42, 0xb9, 0x68, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EnrollmentCAProperty property, VARIANT* pValue) get_Property;
	}


	public HRESULT get_Property(EnrollmentCAProperty property, VARIANT* pValue) mut => VT.[Friend]get_Property(&this, property, pValue);
}

[CRepr]struct ICertificationAuthorities : IDispatch
{
	public new const Guid IID = .(0x13b79005, 0x2181, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, ICertificationAuthority** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICertificationAuthority* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ComputeSiteCosts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strName, ICertificationAuthority** ppValue) get_ItemByName;
	}


	public HRESULT get_ItemByIndex(int32 Index, ICertificationAuthority** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(ICertificationAuthority* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT ComputeSiteCosts() mut => VT.[Friend]ComputeSiteCosts(&this);

	public HRESULT get_ItemByName(BSTR strName, ICertificationAuthority** ppValue) mut => VT.[Friend]get_ItemByName(&this, strName, ppValue);
}

[CRepr]struct IX509EnrollmentPolicyServer : IDispatch
{
	public new const Guid IID = .(0x13b79026, 0x2181, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPolicyServerUrl, BSTR bstrPolicyServerId, X509EnrollmentAuthFlags authFlags, int16 fIsUnTrusted, X509CertificateEnrollmentContext context) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509EnrollmentPolicyLoadOption option) LoadPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateTemplates** pTemplates) GetTemplates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateTemplate* pTemplate, ICertificationAuthorities** ppCAs) GetCAsForTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICertificationAuthorities** ppCAs) GetCAs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Validate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectIds** ppObjectIds) GetCustomOids;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pDate) GetNextUpdateTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pDate) GetLastUpdateTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) GetPolicyServerUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) GetPolicyServerId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) GetFriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) GetIsDefaultCEP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) GetUseClientId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) GetAllowUnTrustedCA;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) GetCachePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) GetCacheDir;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509EnrollmentAuthFlags* pValue) GetAuthFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 hWndParent, X509EnrollmentAuthFlags flag, BSTR strCredential, BSTR strPassword) SetCredential;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) QueryChanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT val) InitializeImport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509EnrollmentPolicyExportFlags exportFlags, VARIANT* pVal) Export;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pValue) get_Cost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 value) put_Cost;
	}


	public HRESULT Initialize(BSTR bstrPolicyServerUrl, BSTR bstrPolicyServerId, X509EnrollmentAuthFlags authFlags, int16 fIsUnTrusted, X509CertificateEnrollmentContext context) mut => VT.[Friend]Initialize(&this, bstrPolicyServerUrl, bstrPolicyServerId, authFlags, fIsUnTrusted, context);

	public HRESULT LoadPolicy(X509EnrollmentPolicyLoadOption option) mut => VT.[Friend]LoadPolicy(&this, option);

	public HRESULT GetTemplates(IX509CertificateTemplates** pTemplates) mut => VT.[Friend]GetTemplates(&this, pTemplates);

	public HRESULT GetCAsForTemplate(IX509CertificateTemplate* pTemplate, ICertificationAuthorities** ppCAs) mut => VT.[Friend]GetCAsForTemplate(&this, pTemplate, ppCAs);

	public HRESULT GetCAs(ICertificationAuthorities** ppCAs) mut => VT.[Friend]GetCAs(&this, ppCAs);

	public HRESULT Validate() mut => VT.[Friend]Validate(&this);

	public HRESULT GetCustomOids(IObjectIds** ppObjectIds) mut => VT.[Friend]GetCustomOids(&this, ppObjectIds);

	public HRESULT GetNextUpdateTime(double* pDate) mut => VT.[Friend]GetNextUpdateTime(&this, pDate);

	public HRESULT GetLastUpdateTime(double* pDate) mut => VT.[Friend]GetLastUpdateTime(&this, pDate);

	public HRESULT GetPolicyServerUrl(BSTR* pValue) mut => VT.[Friend]GetPolicyServerUrl(&this, pValue);

	public HRESULT GetPolicyServerId(BSTR* pValue) mut => VT.[Friend]GetPolicyServerId(&this, pValue);

	public HRESULT GetFriendlyName(BSTR* pValue) mut => VT.[Friend]GetFriendlyName(&this, pValue);

	public HRESULT GetIsDefaultCEP(int16* pValue) mut => VT.[Friend]GetIsDefaultCEP(&this, pValue);

	public HRESULT GetUseClientId(int16* pValue) mut => VT.[Friend]GetUseClientId(&this, pValue);

	public HRESULT GetAllowUnTrustedCA(int16* pValue) mut => VT.[Friend]GetAllowUnTrustedCA(&this, pValue);

	public HRESULT GetCachePath(BSTR* pValue) mut => VT.[Friend]GetCachePath(&this, pValue);

	public HRESULT GetCacheDir(BSTR* pValue) mut => VT.[Friend]GetCacheDir(&this, pValue);

	public HRESULT GetAuthFlags(X509EnrollmentAuthFlags* pValue) mut => VT.[Friend]GetAuthFlags(&this, pValue);

	public HRESULT SetCredential(int32 hWndParent, X509EnrollmentAuthFlags flag, BSTR strCredential, BSTR strPassword) mut => VT.[Friend]SetCredential(&this, hWndParent, flag, strCredential, strPassword);

	public HRESULT QueryChanges(int16* pValue) mut => VT.[Friend]QueryChanges(&this, pValue);

	public HRESULT InitializeImport(VARIANT val) mut => VT.[Friend]InitializeImport(&this, val);

	public HRESULT Export(X509EnrollmentPolicyExportFlags exportFlags, VARIANT* pVal) mut => VT.[Friend]Export(&this, exportFlags, pVal);

	public HRESULT get_Cost(uint32* pValue) mut => VT.[Friend]get_Cost(&this, pValue);

	public HRESULT put_Cost(uint32 value) mut => VT.[Friend]put_Cost(&this, value);
}

[CRepr]struct IX509PolicyServerUrl : IDispatch
{
	public new const Guid IID = .(0x884e204a, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext context) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* ppValue) get_Url;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pValue) put_Url;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_Default;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 value) put_Default;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PolicyServerUrlFlags* pValue) get_Flags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PolicyServerUrlFlags Flags) put_Flags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509EnrollmentAuthFlags* pValue) get_AuthFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509EnrollmentAuthFlags Flags) put_AuthFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pValue) get_Cost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 value) put_Cost;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PolicyServerUrlPropertyID propertyId, BSTR* ppValue) GetStringProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PolicyServerUrlPropertyID propertyId, BSTR pValue) SetStringProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext context) UpdateRegistry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext context) RemoveFromRegistry;
	}


	public HRESULT Initialize(X509CertificateEnrollmentContext context) mut => VT.[Friend]Initialize(&this, context);

	public HRESULT get_Url(BSTR* ppValue) mut => VT.[Friend]get_Url(&this, ppValue);

	public HRESULT put_Url(BSTR pValue) mut => VT.[Friend]put_Url(&this, pValue);

	public HRESULT get_Default(int16* pValue) mut => VT.[Friend]get_Default(&this, pValue);

	public HRESULT put_Default(int16 value) mut => VT.[Friend]put_Default(&this, value);

	public HRESULT get_Flags(PolicyServerUrlFlags* pValue) mut => VT.[Friend]get_Flags(&this, pValue);

	public HRESULT put_Flags(PolicyServerUrlFlags Flags) mut => VT.[Friend]put_Flags(&this, Flags);

	public HRESULT get_AuthFlags(X509EnrollmentAuthFlags* pValue) mut => VT.[Friend]get_AuthFlags(&this, pValue);

	public HRESULT put_AuthFlags(X509EnrollmentAuthFlags Flags) mut => VT.[Friend]put_AuthFlags(&this, Flags);

	public HRESULT get_Cost(uint32* pValue) mut => VT.[Friend]get_Cost(&this, pValue);

	public HRESULT put_Cost(uint32 value) mut => VT.[Friend]put_Cost(&this, value);

	public HRESULT GetStringProperty(PolicyServerUrlPropertyID propertyId, BSTR* ppValue) mut => VT.[Friend]GetStringProperty(&this, propertyId, ppValue);

	public HRESULT SetStringProperty(PolicyServerUrlPropertyID propertyId, BSTR pValue) mut => VT.[Friend]SetStringProperty(&this, propertyId, pValue);

	public HRESULT UpdateRegistry(X509CertificateEnrollmentContext context) mut => VT.[Friend]UpdateRegistry(&this, context);

	public HRESULT RemoveFromRegistry(X509CertificateEnrollmentContext context) mut => VT.[Friend]RemoveFromRegistry(&this, context);
}

[CRepr]struct IX509PolicyServerListManager : IDispatch
{
	public new const Guid IID = .(0x884e204b, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IX509PolicyServerUrl** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509PolicyServerUrl* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext context, PolicyServerUrlFlags Flags) Initialize;
	}


	public HRESULT get_ItemByIndex(int32 Index, IX509PolicyServerUrl** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(IX509PolicyServerUrl* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT Initialize(X509CertificateEnrollmentContext context, PolicyServerUrlFlags Flags) mut => VT.[Friend]Initialize(&this, context, Flags);
}

[CRepr]struct IX509CertificateRequest : IDispatch
{
	public new const Guid IID = .(0x728ab341, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Encode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetForEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InnerRequestLevel Level, IX509CertificateRequest** ppValue) GetInnerRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509RequestType* pValue) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext* pValue) get_EnrollmentContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_Silent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_Silent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_ParentWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) put_ParentWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_UIContextMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_UIContextMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_SuppressDefaults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_SuppressDefaults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_RenewalCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR Value) put_RenewalCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RequestClientInfoClientId* pValue) get_ClientId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RequestClientInfoClientId Value) put_ClientId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspInformations** ppValue) get_CspInformations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspInformations* pValue) put_CspInformations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pValue) put_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_AlternateSignatureAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_AlternateSignatureAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_RawData;
	}


	public HRESULT Initialize(X509CertificateEnrollmentContext Context) mut => VT.[Friend]Initialize(&this, Context);

	public HRESULT Encode() mut => VT.[Friend]Encode(&this);

	public HRESULT ResetForEncode() mut => VT.[Friend]ResetForEncode(&this);

	public HRESULT GetInnerRequest(InnerRequestLevel Level, IX509CertificateRequest** ppValue) mut => VT.[Friend]GetInnerRequest(&this, Level, ppValue);

	public HRESULT get_Type(X509RequestType* pValue) mut => VT.[Friend]get_Type(&this, pValue);

	public HRESULT get_EnrollmentContext(X509CertificateEnrollmentContext* pValue) mut => VT.[Friend]get_EnrollmentContext(&this, pValue);

	public HRESULT get_Silent(int16* pValue) mut => VT.[Friend]get_Silent(&this, pValue);

	public HRESULT put_Silent(int16 Value) mut => VT.[Friend]put_Silent(&this, Value);

	public HRESULT get_ParentWindow(int32* pValue) mut => VT.[Friend]get_ParentWindow(&this, pValue);

	public HRESULT put_ParentWindow(int32 Value) mut => VT.[Friend]put_ParentWindow(&this, Value);

	public HRESULT get_UIContextMessage(BSTR* pValue) mut => VT.[Friend]get_UIContextMessage(&this, pValue);

	public HRESULT put_UIContextMessage(BSTR Value) mut => VT.[Friend]put_UIContextMessage(&this, Value);

	public HRESULT get_SuppressDefaults(int16* pValue) mut => VT.[Friend]get_SuppressDefaults(&this, pValue);

	public HRESULT put_SuppressDefaults(int16 Value) mut => VT.[Friend]put_SuppressDefaults(&this, Value);

	public HRESULT get_RenewalCertificate(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_RenewalCertificate(&this, Encoding, pValue);

	public HRESULT put_RenewalCertificate(EncodingType Encoding, BSTR Value) mut => VT.[Friend]put_RenewalCertificate(&this, Encoding, Value);

	public HRESULT get_ClientId(RequestClientInfoClientId* pValue) mut => VT.[Friend]get_ClientId(&this, pValue);

	public HRESULT put_ClientId(RequestClientInfoClientId Value) mut => VT.[Friend]put_ClientId(&this, Value);

	public HRESULT get_CspInformations(ICspInformations** ppValue) mut => VT.[Friend]get_CspInformations(&this, ppValue);

	public HRESULT put_CspInformations(ICspInformations* pValue) mut => VT.[Friend]put_CspInformations(&this, pValue);

	public HRESULT get_HashAlgorithm(IObjectId** ppValue) mut => VT.[Friend]get_HashAlgorithm(&this, ppValue);

	public HRESULT put_HashAlgorithm(IObjectId* pValue) mut => VT.[Friend]put_HashAlgorithm(&this, pValue);

	public HRESULT get_AlternateSignatureAlgorithm(int16* pValue) mut => VT.[Friend]get_AlternateSignatureAlgorithm(&this, pValue);

	public HRESULT put_AlternateSignatureAlgorithm(int16 Value) mut => VT.[Friend]put_AlternateSignatureAlgorithm(&this, Value);

	public HRESULT get_RawData(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_RawData(&this, Encoding, pValue);
}

[CRepr]struct IX509CertificateRequestPkcs10 : IX509CertificateRequest
{
	public new const Guid IID = .(0x728ab342, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509CertificateRequest.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context, BSTR strTemplateName) InitializeFromTemplateName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context, IX509PrivateKey* pPrivateKey, BSTR strTemplateName) InitializeFromPrivateKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context, IX509PublicKey* pPublicKey, BSTR strTemplateName) InitializeFromPublicKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context, BSTR strCertificate, EncodingType Encoding, X509RequestInheritOptions InheritOptions) InitializeFromCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEncodedData, EncodingType Encoding) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Pkcs10AllowedSignatureTypes AllowedSignatureTypes) CheckSignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) IsSmartCard;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_TemplateObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509PublicKey** ppValue) get_PublicKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509PrivateKey** ppValue) get_PrivateKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_NullSigned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_ReuseKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_OldCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX500DistinguishedName** ppValue) get_Subject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX500DistinguishedName* pValue) put_Subject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICspStatuses** ppValue) get_CspStatuses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_SmimeCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_SmimeCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509SignatureInformation** ppValue) get_SignatureInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_KeyContainerNamePrefix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_KeyContainerNamePrefix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICryptAttributes** ppValue) get_CryptAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509Extensions** ppValue) get_X509Extensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectIds** ppValue) get_CriticalExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectIds** ppValue) get_SuppressOids;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_RawDataToBeSigned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_Signature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509KeySpec KeySpec, ICspStatuses** ppCspStatuses) GetCspStatuses;
	}


	public HRESULT InitializeFromTemplateName(X509CertificateEnrollmentContext Context, BSTR strTemplateName) mut => VT.[Friend]InitializeFromTemplateName(&this, Context, strTemplateName);

	public HRESULT InitializeFromPrivateKey(X509CertificateEnrollmentContext Context, IX509PrivateKey* pPrivateKey, BSTR strTemplateName) mut => VT.[Friend]InitializeFromPrivateKey(&this, Context, pPrivateKey, strTemplateName);

	public HRESULT InitializeFromPublicKey(X509CertificateEnrollmentContext Context, IX509PublicKey* pPublicKey, BSTR strTemplateName) mut => VT.[Friend]InitializeFromPublicKey(&this, Context, pPublicKey, strTemplateName);

	public HRESULT InitializeFromCertificate(X509CertificateEnrollmentContext Context, BSTR strCertificate, EncodingType Encoding, X509RequestInheritOptions InheritOptions) mut => VT.[Friend]InitializeFromCertificate(&this, Context, strCertificate, Encoding, InheritOptions);

	public HRESULT InitializeDecode(BSTR strEncodedData, EncodingType Encoding) mut => VT.[Friend]InitializeDecode(&this, strEncodedData, Encoding);

	public HRESULT CheckSignature(Pkcs10AllowedSignatureTypes AllowedSignatureTypes) mut => VT.[Friend]CheckSignature(&this, AllowedSignatureTypes);

	public HRESULT IsSmartCard(int16* pValue) mut => VT.[Friend]IsSmartCard(&this, pValue);

	public HRESULT get_TemplateObjectId(IObjectId** ppValue) mut => VT.[Friend]get_TemplateObjectId(&this, ppValue);

	public HRESULT get_PublicKey(IX509PublicKey** ppValue) mut => VT.[Friend]get_PublicKey(&this, ppValue);

	public HRESULT get_PrivateKey(IX509PrivateKey** ppValue) mut => VT.[Friend]get_PrivateKey(&this, ppValue);

	public HRESULT get_NullSigned(int16* pValue) mut => VT.[Friend]get_NullSigned(&this, pValue);

	public HRESULT get_ReuseKey(int16* pValue) mut => VT.[Friend]get_ReuseKey(&this, pValue);

	public HRESULT get_OldCertificate(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_OldCertificate(&this, Encoding, pValue);

	public HRESULT get_Subject(IX500DistinguishedName** ppValue) mut => VT.[Friend]get_Subject(&this, ppValue);

	public HRESULT put_Subject(IX500DistinguishedName* pValue) mut => VT.[Friend]put_Subject(&this, pValue);

	public HRESULT get_CspStatuses(ICspStatuses** ppValue) mut => VT.[Friend]get_CspStatuses(&this, ppValue);

	public HRESULT get_SmimeCapabilities(int16* pValue) mut => VT.[Friend]get_SmimeCapabilities(&this, pValue);

	public HRESULT put_SmimeCapabilities(int16 Value) mut => VT.[Friend]put_SmimeCapabilities(&this, Value);

	public HRESULT get_SignatureInformation(IX509SignatureInformation** ppValue) mut => VT.[Friend]get_SignatureInformation(&this, ppValue);

	public HRESULT get_KeyContainerNamePrefix(BSTR* pValue) mut => VT.[Friend]get_KeyContainerNamePrefix(&this, pValue);

	public HRESULT put_KeyContainerNamePrefix(BSTR Value) mut => VT.[Friend]put_KeyContainerNamePrefix(&this, Value);

	public HRESULT get_CryptAttributes(ICryptAttributes** ppValue) mut => VT.[Friend]get_CryptAttributes(&this, ppValue);

	public HRESULT get_X509Extensions(IX509Extensions** ppValue) mut => VT.[Friend]get_X509Extensions(&this, ppValue);

	public HRESULT get_CriticalExtensions(IObjectIds** ppValue) mut => VT.[Friend]get_CriticalExtensions(&this, ppValue);

	public HRESULT get_SuppressOids(IObjectIds** ppValue) mut => VT.[Friend]get_SuppressOids(&this, ppValue);

	public HRESULT get_RawDataToBeSigned(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_RawDataToBeSigned(&this, Encoding, pValue);

	public HRESULT get_Signature(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_Signature(&this, Encoding, pValue);

	public HRESULT GetCspStatuses(X509KeySpec KeySpec, ICspStatuses** ppCspStatuses) mut => VT.[Friend]GetCspStatuses(&this, KeySpec, ppCspStatuses);
}

[CRepr]struct IX509CertificateRequestPkcs10V2 : IX509CertificateRequestPkcs10
{
	public new const Guid IID = .(0x728ab35b, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509CertificateRequestPkcs10.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext context, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) InitializeFromTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context, IX509PrivateKey* pPrivateKey, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) InitializeFromPrivateKeyTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context, IX509PublicKey* pPublicKey, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) InitializeFromPublicKeyTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509EnrollmentPolicyServer** ppPolicyServer) get_PolicyServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateTemplate** ppTemplate) get_Template;
	}


	public HRESULT InitializeFromTemplate(X509CertificateEnrollmentContext context, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) mut => VT.[Friend]InitializeFromTemplate(&this, context, pPolicyServer, pTemplate);

	public HRESULT InitializeFromPrivateKeyTemplate(X509CertificateEnrollmentContext Context, IX509PrivateKey* pPrivateKey, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) mut => VT.[Friend]InitializeFromPrivateKeyTemplate(&this, Context, pPrivateKey, pPolicyServer, pTemplate);

	public HRESULT InitializeFromPublicKeyTemplate(X509CertificateEnrollmentContext Context, IX509PublicKey* pPublicKey, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) mut => VT.[Friend]InitializeFromPublicKeyTemplate(&this, Context, pPublicKey, pPolicyServer, pTemplate);

	public HRESULT get_PolicyServer(IX509EnrollmentPolicyServer** ppPolicyServer) mut => VT.[Friend]get_PolicyServer(&this, ppPolicyServer);

	public HRESULT get_Template(IX509CertificateTemplate** ppTemplate) mut => VT.[Friend]get_Template(&this, ppTemplate);
}

[CRepr]struct IX509CertificateRequestPkcs10V3 : IX509CertificateRequestPkcs10V2
{
	public new const Guid IID = .(0x54ea9942, 0x3d66, 0x4530, 0xb7, 0x6e, 0x7c, 0x91, 0x70, 0xd3, 0xec, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509CertificateRequestPkcs10V2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_AttestPrivateKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_AttestPrivateKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_AttestationEncryptionCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR Value) put_AttestationEncryptionCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_EncryptionAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pValue) put_EncryptionAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_EncryptionStrength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) put_EncryptionStrength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_ChallengePassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_ChallengePassword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509NameValuePairs** ppValue) get_NameValuePairs;
	}


	public HRESULT get_AttestPrivateKey(int16* pValue) mut => VT.[Friend]get_AttestPrivateKey(&this, pValue);

	public HRESULT put_AttestPrivateKey(int16 Value) mut => VT.[Friend]put_AttestPrivateKey(&this, Value);

	public HRESULT get_AttestationEncryptionCertificate(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_AttestationEncryptionCertificate(&this, Encoding, pValue);

	public HRESULT put_AttestationEncryptionCertificate(EncodingType Encoding, BSTR Value) mut => VT.[Friend]put_AttestationEncryptionCertificate(&this, Encoding, Value);

	public HRESULT get_EncryptionAlgorithm(IObjectId** ppValue) mut => VT.[Friend]get_EncryptionAlgorithm(&this, ppValue);

	public HRESULT put_EncryptionAlgorithm(IObjectId* pValue) mut => VT.[Friend]put_EncryptionAlgorithm(&this, pValue);

	public HRESULT get_EncryptionStrength(int32* pValue) mut => VT.[Friend]get_EncryptionStrength(&this, pValue);

	public HRESULT put_EncryptionStrength(int32 Value) mut => VT.[Friend]put_EncryptionStrength(&this, Value);

	public HRESULT get_ChallengePassword(BSTR* pValue) mut => VT.[Friend]get_ChallengePassword(&this, pValue);

	public HRESULT put_ChallengePassword(BSTR Value) mut => VT.[Friend]put_ChallengePassword(&this, Value);

	public HRESULT get_NameValuePairs(IX509NameValuePairs** ppValue) mut => VT.[Friend]get_NameValuePairs(&this, ppValue);
}

[CRepr]struct IX509CertificateRequestPkcs10V4 : IX509CertificateRequestPkcs10V3
{
	public new const Guid IID = .(0x728ab363, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509CertificateRequestPkcs10V3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, KeyAttestationClaimType* pValue) get_ClaimType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, KeyAttestationClaimType Value) put_ClaimType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_AttestPrivateKeyPreferred;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_AttestPrivateKeyPreferred;
	}


	public HRESULT get_ClaimType(KeyAttestationClaimType* pValue) mut => VT.[Friend]get_ClaimType(&this, pValue);

	public HRESULT put_ClaimType(KeyAttestationClaimType Value) mut => VT.[Friend]put_ClaimType(&this, Value);

	public HRESULT get_AttestPrivateKeyPreferred(int16* pValue) mut => VT.[Friend]get_AttestPrivateKeyPreferred(&this, pValue);

	public HRESULT put_AttestPrivateKeyPreferred(int16 Value) mut => VT.[Friend]put_AttestPrivateKeyPreferred(&this, Value);
}

[CRepr]struct IX509CertificateRequestCertificate : IX509CertificateRequestPkcs10
{
	public new const Guid IID = .(0x728ab343, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509CertificateRequestPkcs10.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509PublicKey* pPublicKey) CheckPublicKeySignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX500DistinguishedName** ppValue) get_Issuer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX500DistinguishedName* pValue) put_Issuer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pValue) get_NotBefore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double Value) put_NotBefore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pValue) get_NotAfter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double Value) put_NotAfter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_SerialNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR Value) put_SerialNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificate** ppValue) get_SignerCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificate* pValue) put_SignerCertificate;
	}


	public HRESULT CheckPublicKeySignature(IX509PublicKey* pPublicKey) mut => VT.[Friend]CheckPublicKeySignature(&this, pPublicKey);

	public HRESULT get_Issuer(IX500DistinguishedName** ppValue) mut => VT.[Friend]get_Issuer(&this, ppValue);

	public HRESULT put_Issuer(IX500DistinguishedName* pValue) mut => VT.[Friend]put_Issuer(&this, pValue);

	public HRESULT get_NotBefore(double* pValue) mut => VT.[Friend]get_NotBefore(&this, pValue);

	public HRESULT put_NotBefore(double Value) mut => VT.[Friend]put_NotBefore(&this, Value);

	public HRESULT get_NotAfter(double* pValue) mut => VT.[Friend]get_NotAfter(&this, pValue);

	public HRESULT put_NotAfter(double Value) mut => VT.[Friend]put_NotAfter(&this, Value);

	public HRESULT get_SerialNumber(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_SerialNumber(&this, Encoding, pValue);

	public HRESULT put_SerialNumber(EncodingType Encoding, BSTR Value) mut => VT.[Friend]put_SerialNumber(&this, Encoding, Value);

	public HRESULT get_SignerCertificate(ISignerCertificate** ppValue) mut => VT.[Friend]get_SignerCertificate(&this, ppValue);

	public HRESULT put_SignerCertificate(ISignerCertificate* pValue) mut => VT.[Friend]put_SignerCertificate(&this, pValue);
}

[CRepr]struct IX509CertificateRequestCertificate2 : IX509CertificateRequestCertificate
{
	public new const Guid IID = .(0x728ab35a, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509CertificateRequestCertificate.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext context, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) InitializeFromTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context, IX509PrivateKey* pPrivateKey, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) InitializeFromPrivateKeyTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509EnrollmentPolicyServer** ppPolicyServer) get_PolicyServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateTemplate** ppTemplate) get_Template;
	}


	public HRESULT InitializeFromTemplate(X509CertificateEnrollmentContext context, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) mut => VT.[Friend]InitializeFromTemplate(&this, context, pPolicyServer, pTemplate);

	public HRESULT InitializeFromPrivateKeyTemplate(X509CertificateEnrollmentContext Context, IX509PrivateKey* pPrivateKey, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) mut => VT.[Friend]InitializeFromPrivateKeyTemplate(&this, Context, pPrivateKey, pPolicyServer, pTemplate);

	public HRESULT get_PolicyServer(IX509EnrollmentPolicyServer** ppPolicyServer) mut => VT.[Friend]get_PolicyServer(&this, ppPolicyServer);

	public HRESULT get_Template(IX509CertificateTemplate** ppTemplate) mut => VT.[Friend]get_Template(&this, ppTemplate);
}

[CRepr]struct IX509CertificateRequestPkcs7 : IX509CertificateRequest
{
	public new const Guid IID = .(0x728ab344, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509CertificateRequest.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context, BSTR strTemplateName) InitializeFromTemplateName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context, int16 RenewalRequest, BSTR strCertificate, EncodingType Encoding, X509RequestInheritOptions InheritOptions) InitializeFromCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateRequest* pInnerRequest) InitializeFromInnerRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEncodedData, EncodingType Encoding) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_RequesterName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_RequesterName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificate** ppValue) get_SignerCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificate* pValue) put_SignerCertificate;
	}


	public HRESULT InitializeFromTemplateName(X509CertificateEnrollmentContext Context, BSTR strTemplateName) mut => VT.[Friend]InitializeFromTemplateName(&this, Context, strTemplateName);

	public HRESULT InitializeFromCertificate(X509CertificateEnrollmentContext Context, int16 RenewalRequest, BSTR strCertificate, EncodingType Encoding, X509RequestInheritOptions InheritOptions) mut => VT.[Friend]InitializeFromCertificate(&this, Context, RenewalRequest, strCertificate, Encoding, InheritOptions);

	public HRESULT InitializeFromInnerRequest(IX509CertificateRequest* pInnerRequest) mut => VT.[Friend]InitializeFromInnerRequest(&this, pInnerRequest);

	public HRESULT InitializeDecode(BSTR strEncodedData, EncodingType Encoding) mut => VT.[Friend]InitializeDecode(&this, strEncodedData, Encoding);

	public HRESULT get_RequesterName(BSTR* pValue) mut => VT.[Friend]get_RequesterName(&this, pValue);

	public HRESULT put_RequesterName(BSTR Value) mut => VT.[Friend]put_RequesterName(&this, Value);

	public HRESULT get_SignerCertificate(ISignerCertificate** ppValue) mut => VT.[Friend]get_SignerCertificate(&this, ppValue);

	public HRESULT put_SignerCertificate(ISignerCertificate* pValue) mut => VT.[Friend]put_SignerCertificate(&this, pValue);
}

[CRepr]struct IX509CertificateRequestPkcs7V2 : IX509CertificateRequestPkcs7
{
	public new const Guid IID = .(0x728ab35c, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509CertificateRequestPkcs7.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext context, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) InitializeFromTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509EnrollmentPolicyServer** ppPolicyServer) get_PolicyServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateTemplate** ppTemplate) get_Template;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 ValidateCertificateChain) CheckCertificateSignature;
	}


	public HRESULT InitializeFromTemplate(X509CertificateEnrollmentContext context, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) mut => VT.[Friend]InitializeFromTemplate(&this, context, pPolicyServer, pTemplate);

	public HRESULT get_PolicyServer(IX509EnrollmentPolicyServer** ppPolicyServer) mut => VT.[Friend]get_PolicyServer(&this, ppPolicyServer);

	public HRESULT get_Template(IX509CertificateTemplate** ppTemplate) mut => VT.[Friend]get_Template(&this, ppTemplate);

	public HRESULT CheckCertificateSignature(int16 ValidateCertificateChain) mut => VT.[Friend]CheckCertificateSignature(&this, ValidateCertificateChain);
}

[CRepr]struct IX509CertificateRequestCmc : IX509CertificateRequestPkcs7
{
	public new const Guid IID = .(0x728ab345, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509CertificateRequestPkcs7.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateRequest* pInnerRequest, BSTR strTemplateName) InitializeFromInnerRequestTemplateName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_TemplateObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_NullSigned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICryptAttributes** ppValue) get_CryptAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509NameValuePairs** ppValue) get_NameValuePairs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509Extensions** ppValue) get_X509Extensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectIds** ppValue) get_CriticalExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectIds** ppValue) get_SuppressOids;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_TransactionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) put_TransactionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_SenderNonce;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR Value) put_SenderNonce;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509SignatureInformation** ppValue) get_SignatureInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_ArchivePrivateKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_ArchivePrivateKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_KeyArchivalCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR Value) put_KeyArchivalCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_EncryptionAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pValue) put_EncryptionAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_EncryptionStrength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) put_EncryptionStrength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_EncryptedKeyHash;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificates** ppValue) get_SignerCertificates;
	}


	public HRESULT InitializeFromInnerRequestTemplateName(IX509CertificateRequest* pInnerRequest, BSTR strTemplateName) mut => VT.[Friend]InitializeFromInnerRequestTemplateName(&this, pInnerRequest, strTemplateName);

	public HRESULT get_TemplateObjectId(IObjectId** ppValue) mut => VT.[Friend]get_TemplateObjectId(&this, ppValue);

	public HRESULT get_NullSigned(int16* pValue) mut => VT.[Friend]get_NullSigned(&this, pValue);

	public HRESULT get_CryptAttributes(ICryptAttributes** ppValue) mut => VT.[Friend]get_CryptAttributes(&this, ppValue);

	public HRESULT get_NameValuePairs(IX509NameValuePairs** ppValue) mut => VT.[Friend]get_NameValuePairs(&this, ppValue);

	public HRESULT get_X509Extensions(IX509Extensions** ppValue) mut => VT.[Friend]get_X509Extensions(&this, ppValue);

	public HRESULT get_CriticalExtensions(IObjectIds** ppValue) mut => VT.[Friend]get_CriticalExtensions(&this, ppValue);

	public HRESULT get_SuppressOids(IObjectIds** ppValue) mut => VT.[Friend]get_SuppressOids(&this, ppValue);

	public HRESULT get_TransactionId(int32* pValue) mut => VT.[Friend]get_TransactionId(&this, pValue);

	public HRESULT put_TransactionId(int32 Value) mut => VT.[Friend]put_TransactionId(&this, Value);

	public HRESULT get_SenderNonce(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_SenderNonce(&this, Encoding, pValue);

	public HRESULT put_SenderNonce(EncodingType Encoding, BSTR Value) mut => VT.[Friend]put_SenderNonce(&this, Encoding, Value);

	public HRESULT get_SignatureInformation(IX509SignatureInformation** ppValue) mut => VT.[Friend]get_SignatureInformation(&this, ppValue);

	public HRESULT get_ArchivePrivateKey(int16* pValue) mut => VT.[Friend]get_ArchivePrivateKey(&this, pValue);

	public HRESULT put_ArchivePrivateKey(int16 Value) mut => VT.[Friend]put_ArchivePrivateKey(&this, Value);

	public HRESULT get_KeyArchivalCertificate(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_KeyArchivalCertificate(&this, Encoding, pValue);

	public HRESULT put_KeyArchivalCertificate(EncodingType Encoding, BSTR Value) mut => VT.[Friend]put_KeyArchivalCertificate(&this, Encoding, Value);

	public HRESULT get_EncryptionAlgorithm(IObjectId** ppValue) mut => VT.[Friend]get_EncryptionAlgorithm(&this, ppValue);

	public HRESULT put_EncryptionAlgorithm(IObjectId* pValue) mut => VT.[Friend]put_EncryptionAlgorithm(&this, pValue);

	public HRESULT get_EncryptionStrength(int32* pValue) mut => VT.[Friend]get_EncryptionStrength(&this, pValue);

	public HRESULT put_EncryptionStrength(int32 Value) mut => VT.[Friend]put_EncryptionStrength(&this, Value);

	public HRESULT get_EncryptedKeyHash(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_EncryptedKeyHash(&this, Encoding, pValue);

	public HRESULT get_SignerCertificates(ISignerCertificates** ppValue) mut => VT.[Friend]get_SignerCertificates(&this, ppValue);
}

[CRepr]struct IX509CertificateRequestCmc2 : IX509CertificateRequestCmc
{
	public new const Guid IID = .(0x728ab35d, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509CertificateRequestCmc.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext context, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) InitializeFromTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateRequest* pInnerRequest, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) InitializeFromInnerRequestTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509EnrollmentPolicyServer** ppPolicyServer) get_PolicyServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateTemplate** ppTemplate) get_Template;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Pkcs10AllowedSignatureTypes AllowedSignatureTypes) CheckSignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificate* pSignerCertificate, int16 ValidateCertificateChain) CheckCertificateSignature;
	}


	public HRESULT InitializeFromTemplate(X509CertificateEnrollmentContext context, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) mut => VT.[Friend]InitializeFromTemplate(&this, context, pPolicyServer, pTemplate);

	public HRESULT InitializeFromInnerRequestTemplate(IX509CertificateRequest* pInnerRequest, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) mut => VT.[Friend]InitializeFromInnerRequestTemplate(&this, pInnerRequest, pPolicyServer, pTemplate);

	public HRESULT get_PolicyServer(IX509EnrollmentPolicyServer** ppPolicyServer) mut => VT.[Friend]get_PolicyServer(&this, ppPolicyServer);

	public HRESULT get_Template(IX509CertificateTemplate** ppTemplate) mut => VT.[Friend]get_Template(&this, ppTemplate);

	public HRESULT CheckSignature(Pkcs10AllowedSignatureTypes AllowedSignatureTypes) mut => VT.[Friend]CheckSignature(&this, AllowedSignatureTypes);

	public HRESULT CheckCertificateSignature(ISignerCertificate* pSignerCertificate, int16 ValidateCertificateChain) mut => VT.[Friend]CheckCertificateSignature(&this, pSignerCertificate, ValidateCertificateChain);
}

[CRepr]struct IX509Enrollment : IDispatch
{
	public new const Guid IID = .(0x728ab346, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context, BSTR strTemplateName) InitializeFromTemplateName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateRequest* pRequest) InitializeFromRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) CreateRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Enroll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InstallResponseRestrictionFlags Restrictions, BSTR strResponse, EncodingType Encoding, BSTR strPassword) InstallResponse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strPassword, PFXExportOptions ExportOptions, EncodingType Encoding, BSTR* pValue) CreatePFX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateRequest** pValue) get_Request;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_Silent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_Silent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_ParentWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) put_ParentWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509NameValuePairs** ppValue) get_NameValuePairs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext* pValue) get_EnrollmentContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509EnrollmentStatus** ppValue) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_Certificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_Response;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_CertificateFriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strValue) put_CertificateFriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_CertificateDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strValue) put_CertificateDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_RequestId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_CAConfigString;
	}


	public HRESULT Initialize(X509CertificateEnrollmentContext Context) mut => VT.[Friend]Initialize(&this, Context);

	public HRESULT InitializeFromTemplateName(X509CertificateEnrollmentContext Context, BSTR strTemplateName) mut => VT.[Friend]InitializeFromTemplateName(&this, Context, strTemplateName);

	public HRESULT InitializeFromRequest(IX509CertificateRequest* pRequest) mut => VT.[Friend]InitializeFromRequest(&this, pRequest);

	public HRESULT CreateRequest(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]CreateRequest(&this, Encoding, pValue);

	public HRESULT Enroll() mut => VT.[Friend]Enroll(&this);

	public HRESULT InstallResponse(InstallResponseRestrictionFlags Restrictions, BSTR strResponse, EncodingType Encoding, BSTR strPassword) mut => VT.[Friend]InstallResponse(&this, Restrictions, strResponse, Encoding, strPassword);

	public HRESULT CreatePFX(BSTR strPassword, PFXExportOptions ExportOptions, EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]CreatePFX(&this, strPassword, ExportOptions, Encoding, pValue);

	public HRESULT get_Request(IX509CertificateRequest** pValue) mut => VT.[Friend]get_Request(&this, pValue);

	public HRESULT get_Silent(int16* pValue) mut => VT.[Friend]get_Silent(&this, pValue);

	public HRESULT put_Silent(int16 Value) mut => VT.[Friend]put_Silent(&this, Value);

	public HRESULT get_ParentWindow(int32* pValue) mut => VT.[Friend]get_ParentWindow(&this, pValue);

	public HRESULT put_ParentWindow(int32 Value) mut => VT.[Friend]put_ParentWindow(&this, Value);

	public HRESULT get_NameValuePairs(IX509NameValuePairs** ppValue) mut => VT.[Friend]get_NameValuePairs(&this, ppValue);

	public HRESULT get_EnrollmentContext(X509CertificateEnrollmentContext* pValue) mut => VT.[Friend]get_EnrollmentContext(&this, pValue);

	public HRESULT get_Status(IX509EnrollmentStatus** ppValue) mut => VT.[Friend]get_Status(&this, ppValue);

	public HRESULT get_Certificate(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_Certificate(&this, Encoding, pValue);

	public HRESULT get_Response(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_Response(&this, Encoding, pValue);

	public HRESULT get_CertificateFriendlyName(BSTR* pValue) mut => VT.[Friend]get_CertificateFriendlyName(&this, pValue);

	public HRESULT put_CertificateFriendlyName(BSTR strValue) mut => VT.[Friend]put_CertificateFriendlyName(&this, strValue);

	public HRESULT get_CertificateDescription(BSTR* pValue) mut => VT.[Friend]get_CertificateDescription(&this, pValue);

	public HRESULT put_CertificateDescription(BSTR strValue) mut => VT.[Friend]put_CertificateDescription(&this, strValue);

	public HRESULT get_RequestId(int32* pValue) mut => VT.[Friend]get_RequestId(&this, pValue);

	public HRESULT get_CAConfigString(BSTR* pValue) mut => VT.[Friend]get_CAConfigString(&this, pValue);
}

[CRepr]struct IX509Enrollment2 : IX509Enrollment
{
	public new const Guid IID = .(0x728ab350, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509Enrollment.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext context, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) InitializeFromTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InstallResponseRestrictionFlags Restrictions, BSTR strResponse, EncodingType Encoding, BSTR strPassword, BSTR strEnrollmentPolicyServerUrl, BSTR strEnrollmentPolicyServerID, PolicyServerUrlFlags EnrollmentPolicyServerFlags, X509EnrollmentAuthFlags authFlags) InstallResponse2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509EnrollmentPolicyServer** ppPolicyServer) get_PolicyServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateTemplate** ppTemplate) get_Template;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_RequestIdString;
	}


	public HRESULT InitializeFromTemplate(X509CertificateEnrollmentContext context, IX509EnrollmentPolicyServer* pPolicyServer, IX509CertificateTemplate* pTemplate) mut => VT.[Friend]InitializeFromTemplate(&this, context, pPolicyServer, pTemplate);

	public HRESULT InstallResponse2(InstallResponseRestrictionFlags Restrictions, BSTR strResponse, EncodingType Encoding, BSTR strPassword, BSTR strEnrollmentPolicyServerUrl, BSTR strEnrollmentPolicyServerID, PolicyServerUrlFlags EnrollmentPolicyServerFlags, X509EnrollmentAuthFlags authFlags) mut => VT.[Friend]InstallResponse2(&this, Restrictions, strResponse, Encoding, strPassword, strEnrollmentPolicyServerUrl, strEnrollmentPolicyServerID, EnrollmentPolicyServerFlags, authFlags);

	public HRESULT get_PolicyServer(IX509EnrollmentPolicyServer** ppPolicyServer) mut => VT.[Friend]get_PolicyServer(&this, ppPolicyServer);

	public HRESULT get_Template(IX509CertificateTemplate** ppTemplate) mut => VT.[Friend]get_Template(&this, ppTemplate);

	public HRESULT get_RequestIdString(BSTR* pValue) mut => VT.[Friend]get_RequestIdString(&this, pValue);
}

[CRepr]struct IX509EnrollmentHelper : IDispatch
{
	public new const Guid IID = .(0x728ab351, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEnrollmentPolicyServerURI, BSTR strEnrollmentPolicyID, PolicyServerUrlFlags EnrollmentPolicyServerFlags, X509EnrollmentAuthFlags authFlags, BSTR strCredential, BSTR strPassword) AddPolicyServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEnrollmentServerURI, X509EnrollmentAuthFlags authFlags, BSTR strCredential, BSTR strPassword) AddEnrollmentServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEnrollmentPolicyServerURI, BSTR strTemplateName, EncodingType Encoding, WebEnrollmentFlags enrollFlags, BSTR* pstrCertificate) Enroll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context) Initialize;
	}


	public HRESULT AddPolicyServer(BSTR strEnrollmentPolicyServerURI, BSTR strEnrollmentPolicyID, PolicyServerUrlFlags EnrollmentPolicyServerFlags, X509EnrollmentAuthFlags authFlags, BSTR strCredential, BSTR strPassword) mut => VT.[Friend]AddPolicyServer(&this, strEnrollmentPolicyServerURI, strEnrollmentPolicyID, EnrollmentPolicyServerFlags, authFlags, strCredential, strPassword);

	public HRESULT AddEnrollmentServer(BSTR strEnrollmentServerURI, X509EnrollmentAuthFlags authFlags, BSTR strCredential, BSTR strPassword) mut => VT.[Friend]AddEnrollmentServer(&this, strEnrollmentServerURI, authFlags, strCredential, strPassword);

	public HRESULT Enroll(BSTR strEnrollmentPolicyServerURI, BSTR strTemplateName, EncodingType Encoding, WebEnrollmentFlags enrollFlags, BSTR* pstrCertificate) mut => VT.[Friend]Enroll(&this, strEnrollmentPolicyServerURI, strTemplateName, Encoding, enrollFlags, pstrCertificate);

	public HRESULT Initialize(X509CertificateEnrollmentContext Context) mut => VT.[Friend]Initialize(&this, Context);
}

[CRepr]struct IX509EnrollmentWebClassFactory : IDispatch
{
	public new const Guid IID = .(0x728ab349, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strProgID, IUnknown** ppIUnknown) CreateObject;
	}


	public HRESULT CreateObject(BSTR strProgID, IUnknown** ppIUnknown) mut => VT.[Friend]CreateObject(&this, strProgID, ppIUnknown);
}

[CRepr]struct IX509MachineEnrollmentFactory : IDispatch
{
	public new const Guid IID = .(0x728ab352, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strProgID, IX509EnrollmentHelper** ppIHelper) CreateObject;
	}


	public HRESULT CreateObject(BSTR strProgID, IX509EnrollmentHelper** ppIHelper) mut => VT.[Friend]CreateObject(&this, strProgID, ppIHelper);
}

[CRepr]struct IX509CertificateRevocationListEntry : IDispatch
{
	public new const Guid IID = .(0x728ab35e, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR SerialNumber, double RevocationDate) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_SerialNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pValue) get_RevocationDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CRLRevocationReason* pValue) get_RevocationReason;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CRLRevocationReason Value) put_RevocationReason;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509Extensions** ppValue) get_X509Extensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectIds** ppValue) get_CriticalExtensions;
	}


	public HRESULT Initialize(EncodingType Encoding, BSTR SerialNumber, double RevocationDate) mut => VT.[Friend]Initialize(&this, Encoding, SerialNumber, RevocationDate);

	public HRESULT get_SerialNumber(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_SerialNumber(&this, Encoding, pValue);

	public HRESULT get_RevocationDate(double* pValue) mut => VT.[Friend]get_RevocationDate(&this, pValue);

	public HRESULT get_RevocationReason(CRLRevocationReason* pValue) mut => VT.[Friend]get_RevocationReason(&this, pValue);

	public HRESULT put_RevocationReason(CRLRevocationReason Value) mut => VT.[Friend]put_RevocationReason(&this, Value);

	public HRESULT get_X509Extensions(IX509Extensions** ppValue) mut => VT.[Friend]get_X509Extensions(&this, ppValue);

	public HRESULT get_CriticalExtensions(IObjectIds** ppValue) mut => VT.[Friend]get_CriticalExtensions(&this, ppValue);
}

[CRepr]struct IX509CertificateRevocationListEntries : IDispatch
{
	public new const Guid IID = .(0x728ab35f, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, IX509CertificateRevocationListEntry** pVal) get_ItemByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVal) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pVal) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateRevocationListEntry* pVal) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR SerialNumber, int32* pIndex) get_IndexBySerialNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateRevocationListEntries* pValue) AddRange;
	}


	public HRESULT get_ItemByIndex(int32 Index, IX509CertificateRevocationListEntry** pVal) mut => VT.[Friend]get_ItemByIndex(&this, Index, pVal);

	public HRESULT get_Count(int32* pVal) mut => VT.[Friend]get_Count(&this, pVal);

	public HRESULT get__NewEnum(IUnknown** pVal) mut => VT.[Friend]get__NewEnum(&this, pVal);

	public HRESULT Add(IX509CertificateRevocationListEntry* pVal) mut => VT.[Friend]Add(&this, pVal);

	public HRESULT Remove(int32 Index) mut => VT.[Friend]Remove(&this, Index);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT get_IndexBySerialNumber(EncodingType Encoding, BSTR SerialNumber, int32* pIndex) mut => VT.[Friend]get_IndexBySerialNumber(&this, Encoding, SerialNumber, pIndex);

	public HRESULT AddRange(IX509CertificateRevocationListEntries* pValue) mut => VT.[Friend]AddRange(&this, pValue);
}

[CRepr]struct IX509CertificateRevocationList : IDispatch
{
	public new const Guid IID = .(0x728ab360, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEncodedData, EncodingType Encoding) InitializeDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Encode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetForEncode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509PublicKey* pPublicKey) CheckPublicKeySignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CheckSignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX500DistinguishedName** ppValue) get_Issuer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX500DistinguishedName* pValue) put_Issuer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pValue) get_ThisUpdate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double Value) put_ThisUpdate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pValue) get_NextUpdate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double Value) put_NextUpdate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateRevocationListEntries** ppValue) get_X509CRLEntries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509Extensions** ppValue) get_X509Extensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectIds** ppValue) get_CriticalExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificate** ppValue) get_SignerCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificate* pValue) put_SignerCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_CRLNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR Value) put_CRLNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pValue) get_CAVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 pValue) put_CAVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_BaseCRL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_NullSigned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId** ppValue) get_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectId* pValue) put_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_AlternateSignatureAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_AlternateSignatureAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509SignatureInformation** ppValue) get_SignatureInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_RawData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_RawDataToBeSigned;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_Signature;
	}


	public HRESULT Initialize() mut => VT.[Friend]Initialize(&this);

	public HRESULT InitializeDecode(BSTR strEncodedData, EncodingType Encoding) mut => VT.[Friend]InitializeDecode(&this, strEncodedData, Encoding);

	public HRESULT Encode() mut => VT.[Friend]Encode(&this);

	public HRESULT ResetForEncode() mut => VT.[Friend]ResetForEncode(&this);

	public HRESULT CheckPublicKeySignature(IX509PublicKey* pPublicKey) mut => VT.[Friend]CheckPublicKeySignature(&this, pPublicKey);

	public HRESULT CheckSignature() mut => VT.[Friend]CheckSignature(&this);

	public HRESULT get_Issuer(IX500DistinguishedName** ppValue) mut => VT.[Friend]get_Issuer(&this, ppValue);

	public HRESULT put_Issuer(IX500DistinguishedName* pValue) mut => VT.[Friend]put_Issuer(&this, pValue);

	public HRESULT get_ThisUpdate(double* pValue) mut => VT.[Friend]get_ThisUpdate(&this, pValue);

	public HRESULT put_ThisUpdate(double Value) mut => VT.[Friend]put_ThisUpdate(&this, Value);

	public HRESULT get_NextUpdate(double* pValue) mut => VT.[Friend]get_NextUpdate(&this, pValue);

	public HRESULT put_NextUpdate(double Value) mut => VT.[Friend]put_NextUpdate(&this, Value);

	public HRESULT get_X509CRLEntries(IX509CertificateRevocationListEntries** ppValue) mut => VT.[Friend]get_X509CRLEntries(&this, ppValue);

	public HRESULT get_X509Extensions(IX509Extensions** ppValue) mut => VT.[Friend]get_X509Extensions(&this, ppValue);

	public HRESULT get_CriticalExtensions(IObjectIds** ppValue) mut => VT.[Friend]get_CriticalExtensions(&this, ppValue);

	public HRESULT get_SignerCertificate(ISignerCertificate** ppValue) mut => VT.[Friend]get_SignerCertificate(&this, ppValue);

	public HRESULT put_SignerCertificate(ISignerCertificate* pValue) mut => VT.[Friend]put_SignerCertificate(&this, pValue);

	public HRESULT get_CRLNumber(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_CRLNumber(&this, Encoding, pValue);

	public HRESULT put_CRLNumber(EncodingType Encoding, BSTR Value) mut => VT.[Friend]put_CRLNumber(&this, Encoding, Value);

	public HRESULT get_CAVersion(int32* pValue) mut => VT.[Friend]get_CAVersion(&this, pValue);

	public HRESULT put_CAVersion(int32 pValue) mut => VT.[Friend]put_CAVersion(&this, pValue);

	public HRESULT get_BaseCRL(int16* pValue) mut => VT.[Friend]get_BaseCRL(&this, pValue);

	public HRESULT get_NullSigned(int16* pValue) mut => VT.[Friend]get_NullSigned(&this, pValue);

	public HRESULT get_HashAlgorithm(IObjectId** ppValue) mut => VT.[Friend]get_HashAlgorithm(&this, ppValue);

	public HRESULT put_HashAlgorithm(IObjectId* pValue) mut => VT.[Friend]put_HashAlgorithm(&this, pValue);

	public HRESULT get_AlternateSignatureAlgorithm(int16* pValue) mut => VT.[Friend]get_AlternateSignatureAlgorithm(&this, pValue);

	public HRESULT put_AlternateSignatureAlgorithm(int16 Value) mut => VT.[Friend]put_AlternateSignatureAlgorithm(&this, Value);

	public HRESULT get_SignatureInformation(IX509SignatureInformation** ppValue) mut => VT.[Friend]get_SignatureInformation(&this, ppValue);

	public HRESULT get_RawData(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_RawData(&this, Encoding, pValue);

	public HRESULT get_RawDataToBeSigned(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_RawDataToBeSigned(&this, Encoding, pValue);

	public HRESULT get_Signature(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_Signature(&this, Encoding, pValue);
}

[CRepr]struct ICertificateAttestationChallenge : IDispatch
{
	public new const Guid IID = .(0x6f175a7c, 0x4a3a, 0x40ae, 0x9d, 0xba, 0x59, 0x2f, 0xd6, 0xbb, 0xf9, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR strPendingFullCmcResponseWithChallenge) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pstrEnvelopedPkcs7ReencryptedToCA) DecryptChallenge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrRequestID) get_RequestID;
	}


	public HRESULT Initialize(EncodingType Encoding, BSTR strPendingFullCmcResponseWithChallenge) mut => VT.[Friend]Initialize(&this, Encoding, strPendingFullCmcResponseWithChallenge);

	public HRESULT DecryptChallenge(EncodingType Encoding, BSTR* pstrEnvelopedPkcs7ReencryptedToCA) mut => VT.[Friend]DecryptChallenge(&this, Encoding, pstrEnvelopedPkcs7ReencryptedToCA);

	public HRESULT get_RequestID(BSTR* pstrRequestID) mut => VT.[Friend]get_RequestID(&this, pstrRequestID);
}

[CRepr]struct ICertificateAttestationChallenge2 : ICertificateAttestationChallenge
{
	public new const Guid IID = .(0x4631334d, 0xe266, 0x47d6, 0xbd, 0x79, 0xbe, 0x53, 0xcb, 0x2e, 0x27, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertificateAttestationChallenge.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_KeyContainerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR Value) put_KeyBlob;
	}


	public HRESULT put_KeyContainerName(BSTR Value) mut => VT.[Friend]put_KeyContainerName(&this, Value);

	public HRESULT put_KeyBlob(EncodingType Encoding, BSTR Value) mut => VT.[Friend]put_KeyBlob(&this, Encoding, Value);
}

[CRepr]struct IX509SCEPEnrollment : IDispatch
{
	public new const Guid IID = .(0x728ab361, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateRequestPkcs10* pRequest, BSTR strThumbprint, EncodingType ThumprintEncoding, BSTR strServerCertificates, EncodingType Encoding) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context) InitializeForPending;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) CreateRequestMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) CreateRetrievePendingMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509CertificateEnrollmentContext Context, BSTR strIssuer, EncodingType IssuerEncoding, BSTR strSerialNumber, EncodingType SerialNumberEncoding, EncodingType Encoding, BSTR* pValue) CreateRetrieveCertificateMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strResponse, EncodingType Encoding, X509SCEPDisposition* pDisposition) ProcessResponseMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_ServerCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509SCEPFailInfo* pValue) get_FailInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificate** ppValue) get_SignerCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificate* pValue) put_SignerCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificate** ppValue) get_OldCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISignerCertificate* pValue) put_OldCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_TransactionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR Value) put_TransactionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509CertificateRequestPkcs10** ppValue) get_Request;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_CertificateFriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_CertificateFriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509EnrollmentStatus** ppValue) get_Status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) get_Certificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pValue) get_Silent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_Silent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DeleteRequest;
	}


	public HRESULT Initialize(IX509CertificateRequestPkcs10* pRequest, BSTR strThumbprint, EncodingType ThumprintEncoding, BSTR strServerCertificates, EncodingType Encoding) mut => VT.[Friend]Initialize(&this, pRequest, strThumbprint, ThumprintEncoding, strServerCertificates, Encoding);

	public HRESULT InitializeForPending(X509CertificateEnrollmentContext Context) mut => VT.[Friend]InitializeForPending(&this, Context);

	public HRESULT CreateRequestMessage(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]CreateRequestMessage(&this, Encoding, pValue);

	public HRESULT CreateRetrievePendingMessage(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]CreateRetrievePendingMessage(&this, Encoding, pValue);

	public HRESULT CreateRetrieveCertificateMessage(X509CertificateEnrollmentContext Context, BSTR strIssuer, EncodingType IssuerEncoding, BSTR strSerialNumber, EncodingType SerialNumberEncoding, EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]CreateRetrieveCertificateMessage(&this, Context, strIssuer, IssuerEncoding, strSerialNumber, SerialNumberEncoding, Encoding, pValue);

	public HRESULT ProcessResponseMessage(BSTR strResponse, EncodingType Encoding, X509SCEPDisposition* pDisposition) mut => VT.[Friend]ProcessResponseMessage(&this, strResponse, Encoding, pDisposition);

	public HRESULT put_ServerCapabilities(BSTR Value) mut => VT.[Friend]put_ServerCapabilities(&this, Value);

	public HRESULT get_FailInfo(X509SCEPFailInfo* pValue) mut => VT.[Friend]get_FailInfo(&this, pValue);

	public HRESULT get_SignerCertificate(ISignerCertificate** ppValue) mut => VT.[Friend]get_SignerCertificate(&this, ppValue);

	public HRESULT put_SignerCertificate(ISignerCertificate* pValue) mut => VT.[Friend]put_SignerCertificate(&this, pValue);

	public HRESULT get_OldCertificate(ISignerCertificate** ppValue) mut => VT.[Friend]get_OldCertificate(&this, ppValue);

	public HRESULT put_OldCertificate(ISignerCertificate* pValue) mut => VT.[Friend]put_OldCertificate(&this, pValue);

	public HRESULT get_TransactionId(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_TransactionId(&this, Encoding, pValue);

	public HRESULT put_TransactionId(EncodingType Encoding, BSTR Value) mut => VT.[Friend]put_TransactionId(&this, Encoding, Value);

	public HRESULT get_Request(IX509CertificateRequestPkcs10** ppValue) mut => VT.[Friend]get_Request(&this, ppValue);

	public HRESULT get_CertificateFriendlyName(BSTR* pValue) mut => VT.[Friend]get_CertificateFriendlyName(&this, pValue);

	public HRESULT put_CertificateFriendlyName(BSTR Value) mut => VT.[Friend]put_CertificateFriendlyName(&this, Value);

	public HRESULT get_Status(IX509EnrollmentStatus** ppValue) mut => VT.[Friend]get_Status(&this, ppValue);

	public HRESULT get_Certificate(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]get_Certificate(&this, Encoding, pValue);

	public HRESULT get_Silent(int16* pValue) mut => VT.[Friend]get_Silent(&this, pValue);

	public HRESULT put_Silent(int16 Value) mut => VT.[Friend]put_Silent(&this, Value);

	public HRESULT DeleteRequest() mut => VT.[Friend]DeleteRequest(&this);
}

[CRepr]struct IX509SCEPEnrollment2 : IX509SCEPEnrollment
{
	public new const Guid IID = .(0x728ab364, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IX509SCEPEnrollment.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pValue) CreateChallengeAnswerMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509SCEPProcessMessageFlags Flags, BSTR strResponse, EncodingType Encoding, X509SCEPDisposition* pDisposition) ProcessResponseMessage2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_ResultMessageText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DelayRetryAction* pValue) get_DelayRetry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_ActivityId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Value) put_ActivityId;
	}


	public HRESULT CreateChallengeAnswerMessage(EncodingType Encoding, BSTR* pValue) mut => VT.[Friend]CreateChallengeAnswerMessage(&this, Encoding, pValue);

	public HRESULT ProcessResponseMessage2(X509SCEPProcessMessageFlags Flags, BSTR strResponse, EncodingType Encoding, X509SCEPDisposition* pDisposition) mut => VT.[Friend]ProcessResponseMessage2(&this, Flags, strResponse, Encoding, pDisposition);

	public HRESULT get_ResultMessageText(BSTR* pValue) mut => VT.[Friend]get_ResultMessageText(&this, pValue);

	public HRESULT get_DelayRetry(DelayRetryAction* pValue) mut => VT.[Friend]get_DelayRetry(&this, pValue);

	public HRESULT get_ActivityId(BSTR* pValue) mut => VT.[Friend]get_ActivityId(&this, pValue);

	public HRESULT put_ActivityId(BSTR Value) mut => VT.[Friend]put_ActivityId(&this, Value);
}

[CRepr]struct IX509SCEPEnrollmentHelper : IDispatch
{
	public new const Guid IID = .(0x728ab365, 0x217d, 0x11da, 0xb2, 0xa4, 0x00, 0x0e, 0x7b, 0xbb, 0x2b, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strServerUrl, BSTR strRequestHeaders, IX509CertificateRequestPkcs10* pRequest, BSTR strCACertificateThumbprint) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strServerUrl, BSTR strRequestHeaders, X509CertificateEnrollmentContext Context, BSTR strTransactionId) InitializeForPending;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509SCEPProcessMessageFlags ProcessFlags, X509SCEPDisposition* pDisposition) Enroll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, X509SCEPProcessMessageFlags ProcessFlags, X509SCEPDisposition* pDisposition) FetchPending;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IX509SCEPEnrollment** ppValue) get_X509SCEPEnrollment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pValue) get_ResultMessageText;
	}


	public HRESULT Initialize(BSTR strServerUrl, BSTR strRequestHeaders, IX509CertificateRequestPkcs10* pRequest, BSTR strCACertificateThumbprint) mut => VT.[Friend]Initialize(&this, strServerUrl, strRequestHeaders, pRequest, strCACertificateThumbprint);

	public HRESULT InitializeForPending(BSTR strServerUrl, BSTR strRequestHeaders, X509CertificateEnrollmentContext Context, BSTR strTransactionId) mut => VT.[Friend]InitializeForPending(&this, strServerUrl, strRequestHeaders, Context, strTransactionId);

	public HRESULT Enroll(X509SCEPProcessMessageFlags ProcessFlags, X509SCEPDisposition* pDisposition) mut => VT.[Friend]Enroll(&this, ProcessFlags, pDisposition);

	public HRESULT FetchPending(X509SCEPProcessMessageFlags ProcessFlags, X509SCEPDisposition* pDisposition) mut => VT.[Friend]FetchPending(&this, ProcessFlags, pDisposition);

	public HRESULT get_X509SCEPEnrollment(IX509SCEPEnrollment** ppValue) mut => VT.[Friend]get_X509SCEPEnrollment(&this, ppValue);

	public HRESULT get_ResultMessageText(BSTR* pValue) mut => VT.[Friend]get_ResultMessageText(&this, pValue);
}

[CRepr]struct ICertEncodeStringArray : IDispatch
{
	public new const Guid IID = .(0x12a88820, 0x7494, 0x11d0, 0x88, 0x16, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strBinary) Decode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pStringType) GetStringType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, BSTR* pstr) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Count, CERT_RDN_ATTR_VALUE_TYPE StringType) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, BSTR str) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrBinary) Encode;
	}


	public HRESULT Decode(BSTR strBinary) mut => VT.[Friend]Decode(&this, strBinary);

	public HRESULT GetStringType(int32* pStringType) mut => VT.[Friend]GetStringType(&this, pStringType);

	public HRESULT GetCount(int32* pCount) mut => VT.[Friend]GetCount(&this, pCount);

	public HRESULT GetValue(int32 Index, BSTR* pstr) mut => VT.[Friend]GetValue(&this, Index, pstr);

	public HRESULT Reset(int32 Count, CERT_RDN_ATTR_VALUE_TYPE StringType) mut => VT.[Friend]Reset(&this, Count, StringType);

	public HRESULT SetValue(int32 Index, BSTR str) mut => VT.[Friend]SetValue(&this, Index, str);

	public HRESULT Encode(BSTR* pstrBinary) mut => VT.[Friend]Encode(&this, pstrBinary);
}

[CRepr]struct ICertEncodeStringArray2 : ICertEncodeStringArray
{
	public new const Guid IID = .(0x9c680d93, 0x9b7d, 0x4e95, 0x90, 0x18, 0x4f, 0xfe, 0x10, 0xba, 0x5a, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertEncodeStringArray.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEncodedData, EncodingType Encoding) DecodeBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pstrEncodedData) EncodeBlob;
	}


	public HRESULT DecodeBlob(BSTR strEncodedData, EncodingType Encoding) mut => VT.[Friend]DecodeBlob(&this, strEncodedData, Encoding);

	public HRESULT EncodeBlob(EncodingType Encoding, BSTR* pstrEncodedData) mut => VT.[Friend]EncodeBlob(&this, Encoding, pstrEncodedData);
}

[CRepr]struct ICertEncodeLongArray : IDispatch
{
	public new const Guid IID = .(0x15e2f230, 0xa0a2, 0x11d0, 0x88, 0x21, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strBinary) Decode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, int32* pValue) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Count) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, int32 Value) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrBinary) Encode;
	}


	public HRESULT Decode(BSTR strBinary) mut => VT.[Friend]Decode(&this, strBinary);

	public HRESULT GetCount(int32* pCount) mut => VT.[Friend]GetCount(&this, pCount);

	public HRESULT GetValue(int32 Index, int32* pValue) mut => VT.[Friend]GetValue(&this, Index, pValue);

	public HRESULT Reset(int32 Count) mut => VT.[Friend]Reset(&this, Count);

	public HRESULT SetValue(int32 Index, int32 Value) mut => VT.[Friend]SetValue(&this, Index, Value);

	public HRESULT Encode(BSTR* pstrBinary) mut => VT.[Friend]Encode(&this, pstrBinary);
}

[CRepr]struct ICertEncodeLongArray2 : ICertEncodeLongArray
{
	public new const Guid IID = .(0x4efde84a, 0xbd9b, 0x4fc2, 0xa1, 0x08, 0xc3, 0x47, 0xd4, 0x78, 0x84, 0x0f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertEncodeLongArray.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEncodedData, EncodingType Encoding) DecodeBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pstrEncodedData) EncodeBlob;
	}


	public HRESULT DecodeBlob(BSTR strEncodedData, EncodingType Encoding) mut => VT.[Friend]DecodeBlob(&this, strEncodedData, Encoding);

	public HRESULT EncodeBlob(EncodingType Encoding, BSTR* pstrEncodedData) mut => VT.[Friend]EncodeBlob(&this, Encoding, pstrEncodedData);
}

[CRepr]struct ICertEncodeDateArray : IDispatch
{
	public new const Guid IID = .(0x2f9469a0, 0xa470, 0x11d0, 0x88, 0x21, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strBinary) Decode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, double* pValue) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Count) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, double Value) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrBinary) Encode;
	}


	public HRESULT Decode(BSTR strBinary) mut => VT.[Friend]Decode(&this, strBinary);

	public HRESULT GetCount(int32* pCount) mut => VT.[Friend]GetCount(&this, pCount);

	public HRESULT GetValue(int32 Index, double* pValue) mut => VT.[Friend]GetValue(&this, Index, pValue);

	public HRESULT Reset(int32 Count) mut => VT.[Friend]Reset(&this, Count);

	public HRESULT SetValue(int32 Index, double Value) mut => VT.[Friend]SetValue(&this, Index, Value);

	public HRESULT Encode(BSTR* pstrBinary) mut => VT.[Friend]Encode(&this, pstrBinary);
}

[CRepr]struct ICertEncodeDateArray2 : ICertEncodeDateArray
{
	public new const Guid IID = .(0x99a4edb5, 0x2b8e, 0x448d, 0xbf, 0x95, 0xbb, 0xa8, 0xd7, 0x78, 0x9d, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertEncodeDateArray.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEncodedData, EncodingType Encoding) DecodeBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pstrEncodedData) EncodeBlob;
	}


	public HRESULT DecodeBlob(BSTR strEncodedData, EncodingType Encoding) mut => VT.[Friend]DecodeBlob(&this, strEncodedData, Encoding);

	public HRESULT EncodeBlob(EncodingType Encoding, BSTR* pstrEncodedData) mut => VT.[Friend]EncodeBlob(&this, Encoding, pstrEncodedData);
}

[CRepr]struct ICertEncodeCRLDistInfo : IDispatch
{
	public new const Guid IID = .(0x01958640, 0xbbff, 0x11d0, 0x88, 0x25, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strBinary) Decode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pDistPointCount) GetDistPointCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 DistPointIndex, int32* pNameCount) GetNameCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 DistPointIndex, int32 NameIndex, int32* pNameChoice) GetNameChoice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 DistPointIndex, int32 NameIndex, BSTR* pstrName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 DistPointCount) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 DistPointIndex, int32 NameCount) SetNameCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 DistPointIndex, int32 NameIndex, CERT_ALT_NAME NameChoice, BSTR strName) SetNameEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrBinary) Encode;
	}


	public HRESULT Decode(BSTR strBinary) mut => VT.[Friend]Decode(&this, strBinary);

	public HRESULT GetDistPointCount(int32* pDistPointCount) mut => VT.[Friend]GetDistPointCount(&this, pDistPointCount);

	public HRESULT GetNameCount(int32 DistPointIndex, int32* pNameCount) mut => VT.[Friend]GetNameCount(&this, DistPointIndex, pNameCount);

	public HRESULT GetNameChoice(int32 DistPointIndex, int32 NameIndex, int32* pNameChoice) mut => VT.[Friend]GetNameChoice(&this, DistPointIndex, NameIndex, pNameChoice);

	public HRESULT GetName(int32 DistPointIndex, int32 NameIndex, BSTR* pstrName) mut => VT.[Friend]GetName(&this, DistPointIndex, NameIndex, pstrName);

	public HRESULT Reset(int32 DistPointCount) mut => VT.[Friend]Reset(&this, DistPointCount);

	public HRESULT SetNameCount(int32 DistPointIndex, int32 NameCount) mut => VT.[Friend]SetNameCount(&this, DistPointIndex, NameCount);

	public HRESULT SetNameEntry(int32 DistPointIndex, int32 NameIndex, CERT_ALT_NAME NameChoice, BSTR strName) mut => VT.[Friend]SetNameEntry(&this, DistPointIndex, NameIndex, NameChoice, strName);

	public HRESULT Encode(BSTR* pstrBinary) mut => VT.[Friend]Encode(&this, pstrBinary);
}

[CRepr]struct ICertEncodeCRLDistInfo2 : ICertEncodeCRLDistInfo
{
	public new const Guid IID = .(0xb4275d4b, 0x3e30, 0x446f, 0xad, 0x36, 0x09, 0xd0, 0x31, 0x20, 0xb0, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertEncodeCRLDistInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEncodedData, EncodingType Encoding) DecodeBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pstrEncodedData) EncodeBlob;
	}


	public HRESULT DecodeBlob(BSTR strEncodedData, EncodingType Encoding) mut => VT.[Friend]DecodeBlob(&this, strEncodedData, Encoding);

	public HRESULT EncodeBlob(EncodingType Encoding, BSTR* pstrEncodedData) mut => VT.[Friend]EncodeBlob(&this, Encoding, pstrEncodedData);
}

[CRepr]struct ICertEncodeAltName : IDispatch
{
	public new const Guid IID = .(0x1c9a8c70, 0x1271, 0x11d1, 0x9b, 0xd4, 0x00, 0xc0, 0x4f, 0xb6, 0x83, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strBinary) Decode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pNameCount) GetNameCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NameIndex, int32* pNameChoice) GetNameChoice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NameIndex, BSTR* pstrName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NameCount) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NameIndex, CERT_ALT_NAME NameChoice, BSTR strName) SetNameEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrBinary) Encode;
	}


	public HRESULT Decode(BSTR strBinary) mut => VT.[Friend]Decode(&this, strBinary);

	public HRESULT GetNameCount(int32* pNameCount) mut => VT.[Friend]GetNameCount(&this, pNameCount);

	public HRESULT GetNameChoice(int32 NameIndex, int32* pNameChoice) mut => VT.[Friend]GetNameChoice(&this, NameIndex, pNameChoice);

	public HRESULT GetName(int32 NameIndex, BSTR* pstrName) mut => VT.[Friend]GetName(&this, NameIndex, pstrName);

	public HRESULT Reset(int32 NameCount) mut => VT.[Friend]Reset(&this, NameCount);

	public HRESULT SetNameEntry(int32 NameIndex, CERT_ALT_NAME NameChoice, BSTR strName) mut => VT.[Friend]SetNameEntry(&this, NameIndex, NameChoice, strName);

	public HRESULT Encode(BSTR* pstrBinary) mut => VT.[Friend]Encode(&this, pstrBinary);
}

[CRepr]struct ICertEncodeAltName2 : ICertEncodeAltName
{
	public new const Guid IID = .(0xf67fe177, 0x5ef1, 0x4535, 0xb4, 0xce, 0x29, 0xdf, 0x15, 0xe2, 0xe0, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertEncodeAltName.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEncodedData, EncodingType Encoding) DecodeBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pstrEncodedData) EncodeBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NameIndex, EncodingType Encoding, BSTR* pstrName) GetNameBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 NameIndex, int32 NameChoice, BSTR strName, EncodingType Encoding) SetNameEntryBlob;
	}


	public HRESULT DecodeBlob(BSTR strEncodedData, EncodingType Encoding) mut => VT.[Friend]DecodeBlob(&this, strEncodedData, Encoding);

	public HRESULT EncodeBlob(EncodingType Encoding, BSTR* pstrEncodedData) mut => VT.[Friend]EncodeBlob(&this, Encoding, pstrEncodedData);

	public HRESULT GetNameBlob(int32 NameIndex, EncodingType Encoding, BSTR* pstrName) mut => VT.[Friend]GetNameBlob(&this, NameIndex, Encoding, pstrName);

	public HRESULT SetNameEntryBlob(int32 NameIndex, int32 NameChoice, BSTR strName, EncodingType Encoding) mut => VT.[Friend]SetNameEntryBlob(&this, NameIndex, NameChoice, strName, Encoding);
}

[CRepr]struct ICertEncodeBitString : IDispatch
{
	public new const Guid IID = .(0x6db525be, 0x1278, 0x11d1, 0x9b, 0xd4, 0x00, 0xc0, 0x4f, 0xb6, 0x83, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strBinary) Decode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pBitCount) GetBitCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrBitString) GetBitString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 BitCount, BSTR strBitString, BSTR* pstrBinary) Encode;
	}


	public HRESULT Decode(BSTR strBinary) mut => VT.[Friend]Decode(&this, strBinary);

	public HRESULT GetBitCount(int32* pBitCount) mut => VT.[Friend]GetBitCount(&this, pBitCount);

	public HRESULT GetBitString(BSTR* pstrBitString) mut => VT.[Friend]GetBitString(&this, pstrBitString);

	public HRESULT Encode(int32 BitCount, BSTR strBitString, BSTR* pstrBinary) mut => VT.[Friend]Encode(&this, BitCount, strBitString, pstrBinary);
}

[CRepr]struct ICertEncodeBitString2 : ICertEncodeBitString
{
	public new const Guid IID = .(0xe070d6e7, 0x23ef, 0x4dd2, 0x82, 0x42, 0xeb, 0xd9, 0xc9, 0x28, 0xcb, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertEncodeBitString.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strEncodedData, EncodingType Encoding) DecodeBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 BitCount, BSTR strBitString, EncodingType EncodingIn, EncodingType Encoding, BSTR* pstrEncodedData) EncodeBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EncodingType Encoding, BSTR* pstrBitString) GetBitStringBlob;
	}


	public HRESULT DecodeBlob(BSTR strEncodedData, EncodingType Encoding) mut => VT.[Friend]DecodeBlob(&this, strEncodedData, Encoding);

	public HRESULT EncodeBlob(int32 BitCount, BSTR strBitString, EncodingType EncodingIn, EncodingType Encoding, BSTR* pstrEncodedData) mut => VT.[Friend]EncodeBlob(&this, BitCount, strBitString, EncodingIn, Encoding, pstrEncodedData);

	public HRESULT GetBitStringBlob(EncodingType Encoding, BSTR* pstrBitString) mut => VT.[Friend]GetBitStringBlob(&this, Encoding, pstrBitString);
}

[CRepr]struct ICertExit : IDispatch
{
	public new const Guid IID = .(0xe19ae1a0, 0x7364, 0x11d0, 0x88, 0x16, 0x00, 0xa0, 0xc9, 0x03, 0xb8, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strConfig, CERT_EXIT_EVENT_MASK* pEventMask) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 ExitEvent, int32 Context) Notify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstrDescription) GetDescription;
	}


	public HRESULT Initialize(BSTR strConfig, CERT_EXIT_EVENT_MASK* pEventMask) mut => VT.[Friend]Initialize(&this, strConfig, pEventMask);

	public HRESULT Notify(int32 ExitEvent, int32 Context) mut => VT.[Friend]Notify(&this, ExitEvent, Context);

	public HRESULT GetDescription(BSTR* pstrDescription) mut => VT.[Friend]GetDescription(&this, pstrDescription);
}

[CRepr]struct ICertExit2 : ICertExit
{
	public new const Guid IID = .(0x0abf484b, 0xd049, 0x464d, 0xa7, 0xed, 0x55, 0x2e, 0x75, 0x29, 0xb0, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertExit.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICertManageModule** ppManageModule) GetManageModule;
	}


	public HRESULT GetManageModule(ICertManageModule** ppManageModule) mut => VT.[Friend]GetManageModule(&this, ppManageModule);
}

[CRepr]struct ICEnroll : IDispatch
{
	public new const Guid IID = .(0x43f8f288, 0x7a20, 0x11d0, 0x8f, 0x06, 0x00, 0xc0, 0x4f, 0xc2, 0x95, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR DNName, BSTR Usage, BSTR wszPKCS10FileName) createFilePKCS10;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR wszPKCS7FileName) acceptFilePKCS7;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR DNName, BSTR Usage, BSTR* pPKCS10) createPKCS10;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PKCS7) acceptPKCS7;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR wszPKCS7, BSTR* pbstrCert) getCertFromPKCS7;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwIndex, int32 dwFlags, BSTR* pbstrProvName) enumProviders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwIndex, BSTR* pbstr) enumContainers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PKCS7OrPKCS10) freeRequestInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_MyStoreName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_MyStoreName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrType) get_MyStoreType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrType) put_MyStoreType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwFlags) get_MyStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwFlags) put_MyStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_CAStoreName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_CAStoreName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrType) get_CAStoreType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrType) put_CAStoreType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwFlags) get_CAStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwFlags) put_CAStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_RootStoreName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_RootStoreName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrType) get_RootStoreType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrType) put_RootStoreType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwFlags) get_RootStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwFlags) put_RootStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_RequestStoreName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_RequestStoreName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrType) get_RequestStoreType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrType) put_RequestStoreType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwFlags) get_RequestStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwFlags) put_RequestStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrContainer) get_ContainerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrContainer) put_ContainerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrProvider) get_ProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProvider) put_ProviderName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwType) get_ProviderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwType) put_ProviderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdw) get_KeySpec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dw) put_KeySpec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwFlags) get_ProviderFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwFlags) put_ProviderFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fUseExistingKeys) get_UseExistingKeySet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fUseExistingKeys) put_UseExistingKeySet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwFlags) get_GenKeyFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwFlags) put_GenKeyFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fDelete) get_DeleteRequestCert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fDelete) put_DeleteRequestCert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fBool) get_WriteCertToCSP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fBool) put_WriteCertToCSP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_SPCFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr) put_SPCFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_PVKFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr) put_PVKFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) get_HashAlgorithm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstr) put_HashAlgorithm;
	}


	public HRESULT createFilePKCS10(BSTR DNName, BSTR Usage, BSTR wszPKCS10FileName) mut => VT.[Friend]createFilePKCS10(&this, DNName, Usage, wszPKCS10FileName);

	public HRESULT acceptFilePKCS7(BSTR wszPKCS7FileName) mut => VT.[Friend]acceptFilePKCS7(&this, wszPKCS7FileName);

	public HRESULT createPKCS10(BSTR DNName, BSTR Usage, BSTR* pPKCS10) mut => VT.[Friend]createPKCS10(&this, DNName, Usage, pPKCS10);

	public HRESULT acceptPKCS7(BSTR PKCS7) mut => VT.[Friend]acceptPKCS7(&this, PKCS7);

	public HRESULT getCertFromPKCS7(BSTR wszPKCS7, BSTR* pbstrCert) mut => VT.[Friend]getCertFromPKCS7(&this, wszPKCS7, pbstrCert);

	public HRESULT enumProviders(int32 dwIndex, int32 dwFlags, BSTR* pbstrProvName) mut => VT.[Friend]enumProviders(&this, dwIndex, dwFlags, pbstrProvName);

	public HRESULT enumContainers(int32 dwIndex, BSTR* pbstr) mut => VT.[Friend]enumContainers(&this, dwIndex, pbstr);

	public HRESULT freeRequestInfo(BSTR PKCS7OrPKCS10) mut => VT.[Friend]freeRequestInfo(&this, PKCS7OrPKCS10);

	public HRESULT get_MyStoreName(BSTR* pbstrName) mut => VT.[Friend]get_MyStoreName(&this, pbstrName);

	public HRESULT put_MyStoreName(BSTR bstrName) mut => VT.[Friend]put_MyStoreName(&this, bstrName);

	public HRESULT get_MyStoreType(BSTR* pbstrType) mut => VT.[Friend]get_MyStoreType(&this, pbstrType);

	public HRESULT put_MyStoreType(BSTR bstrType) mut => VT.[Friend]put_MyStoreType(&this, bstrType);

	public HRESULT get_MyStoreFlags(int32* pdwFlags) mut => VT.[Friend]get_MyStoreFlags(&this, pdwFlags);

	public HRESULT put_MyStoreFlags(int32 dwFlags) mut => VT.[Friend]put_MyStoreFlags(&this, dwFlags);

	public HRESULT get_CAStoreName(BSTR* pbstrName) mut => VT.[Friend]get_CAStoreName(&this, pbstrName);

	public HRESULT put_CAStoreName(BSTR bstrName) mut => VT.[Friend]put_CAStoreName(&this, bstrName);

	public HRESULT get_CAStoreType(BSTR* pbstrType) mut => VT.[Friend]get_CAStoreType(&this, pbstrType);

	public HRESULT put_CAStoreType(BSTR bstrType) mut => VT.[Friend]put_CAStoreType(&this, bstrType);

	public HRESULT get_CAStoreFlags(int32* pdwFlags) mut => VT.[Friend]get_CAStoreFlags(&this, pdwFlags);

	public HRESULT put_CAStoreFlags(int32 dwFlags) mut => VT.[Friend]put_CAStoreFlags(&this, dwFlags);

	public HRESULT get_RootStoreName(BSTR* pbstrName) mut => VT.[Friend]get_RootStoreName(&this, pbstrName);

	public HRESULT put_RootStoreName(BSTR bstrName) mut => VT.[Friend]put_RootStoreName(&this, bstrName);

	public HRESULT get_RootStoreType(BSTR* pbstrType) mut => VT.[Friend]get_RootStoreType(&this, pbstrType);

	public HRESULT put_RootStoreType(BSTR bstrType) mut => VT.[Friend]put_RootStoreType(&this, bstrType);

	public HRESULT get_RootStoreFlags(int32* pdwFlags) mut => VT.[Friend]get_RootStoreFlags(&this, pdwFlags);

	public HRESULT put_RootStoreFlags(int32 dwFlags) mut => VT.[Friend]put_RootStoreFlags(&this, dwFlags);

	public HRESULT get_RequestStoreName(BSTR* pbstrName) mut => VT.[Friend]get_RequestStoreName(&this, pbstrName);

	public HRESULT put_RequestStoreName(BSTR bstrName) mut => VT.[Friend]put_RequestStoreName(&this, bstrName);

	public HRESULT get_RequestStoreType(BSTR* pbstrType) mut => VT.[Friend]get_RequestStoreType(&this, pbstrType);

	public HRESULT put_RequestStoreType(BSTR bstrType) mut => VT.[Friend]put_RequestStoreType(&this, bstrType);

	public HRESULT get_RequestStoreFlags(int32* pdwFlags) mut => VT.[Friend]get_RequestStoreFlags(&this, pdwFlags);

	public HRESULT put_RequestStoreFlags(int32 dwFlags) mut => VT.[Friend]put_RequestStoreFlags(&this, dwFlags);

	public HRESULT get_ContainerName(BSTR* pbstrContainer) mut => VT.[Friend]get_ContainerName(&this, pbstrContainer);

	public HRESULT put_ContainerName(BSTR bstrContainer) mut => VT.[Friend]put_ContainerName(&this, bstrContainer);

	public HRESULT get_ProviderName(BSTR* pbstrProvider) mut => VT.[Friend]get_ProviderName(&this, pbstrProvider);

	public HRESULT put_ProviderName(BSTR bstrProvider) mut => VT.[Friend]put_ProviderName(&this, bstrProvider);

	public HRESULT get_ProviderType(int32* pdwType) mut => VT.[Friend]get_ProviderType(&this, pdwType);

	public HRESULT put_ProviderType(int32 dwType) mut => VT.[Friend]put_ProviderType(&this, dwType);

	public HRESULT get_KeySpec(int32* pdw) mut => VT.[Friend]get_KeySpec(&this, pdw);

	public HRESULT put_KeySpec(int32 dw) mut => VT.[Friend]put_KeySpec(&this, dw);

	public HRESULT get_ProviderFlags(int32* pdwFlags) mut => VT.[Friend]get_ProviderFlags(&this, pdwFlags);

	public HRESULT put_ProviderFlags(int32 dwFlags) mut => VT.[Friend]put_ProviderFlags(&this, dwFlags);

	public HRESULT get_UseExistingKeySet(BOOL* fUseExistingKeys) mut => VT.[Friend]get_UseExistingKeySet(&this, fUseExistingKeys);

	public HRESULT put_UseExistingKeySet(BOOL fUseExistingKeys) mut => VT.[Friend]put_UseExistingKeySet(&this, fUseExistingKeys);

	public HRESULT get_GenKeyFlags(int32* pdwFlags) mut => VT.[Friend]get_GenKeyFlags(&this, pdwFlags);

	public HRESULT put_GenKeyFlags(int32 dwFlags) mut => VT.[Friend]put_GenKeyFlags(&this, dwFlags);

	public HRESULT get_DeleteRequestCert(BOOL* fDelete) mut => VT.[Friend]get_DeleteRequestCert(&this, fDelete);

	public HRESULT put_DeleteRequestCert(BOOL fDelete) mut => VT.[Friend]put_DeleteRequestCert(&this, fDelete);

	public HRESULT get_WriteCertToCSP(BOOL* fBool) mut => VT.[Friend]get_WriteCertToCSP(&this, fBool);

	public HRESULT put_WriteCertToCSP(BOOL fBool) mut => VT.[Friend]put_WriteCertToCSP(&this, fBool);

	public HRESULT get_SPCFileName(BSTR* pbstr) mut => VT.[Friend]get_SPCFileName(&this, pbstr);

	public HRESULT put_SPCFileName(BSTR bstr) mut => VT.[Friend]put_SPCFileName(&this, bstr);

	public HRESULT get_PVKFileName(BSTR* pbstr) mut => VT.[Friend]get_PVKFileName(&this, pbstr);

	public HRESULT put_PVKFileName(BSTR bstr) mut => VT.[Friend]put_PVKFileName(&this, bstr);

	public HRESULT get_HashAlgorithm(BSTR* pbstr) mut => VT.[Friend]get_HashAlgorithm(&this, pbstr);

	public HRESULT put_HashAlgorithm(BSTR bstr) mut => VT.[Friend]put_HashAlgorithm(&this, bstr);
}

[CRepr]struct ICEnroll2 : ICEnroll
{
	public new const Guid IID = .(0x704ca730, 0xc90b, 0x11d1, 0x9b, 0xec, 0x00, 0xc0, 0x4f, 0xc2, 0x95, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICEnroll.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR CertType) addCertTypeToRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name, BSTR Value) addNameValuePairToSignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fBool) get_WriteCertToUserDS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fBool) put_WriteCertToUserDS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fBool) get_EnableT61DNEncoding;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fBool) put_EnableT61DNEncoding;
	}


	public HRESULT addCertTypeToRequest(BSTR CertType) mut => VT.[Friend]addCertTypeToRequest(&this, CertType);

	public HRESULT addNameValuePairToSignature(BSTR Name, BSTR Value) mut => VT.[Friend]addNameValuePairToSignature(&this, Name, Value);

	public HRESULT get_WriteCertToUserDS(BOOL* fBool) mut => VT.[Friend]get_WriteCertToUserDS(&this, fBool);

	public HRESULT put_WriteCertToUserDS(BOOL fBool) mut => VT.[Friend]put_WriteCertToUserDS(&this, fBool);

	public HRESULT get_EnableT61DNEncoding(BOOL* fBool) mut => VT.[Friend]get_EnableT61DNEncoding(&this, fBool);

	public HRESULT put_EnableT61DNEncoding(BOOL fBool) mut => VT.[Friend]put_EnableT61DNEncoding(&this, fBool);
}

[CRepr]struct ICEnroll3 : ICEnroll2
{
	public new const Guid IID = .(0xc28c2d95, 0xb7de, 0x11d2, 0xa4, 0x21, 0x00, 0xc0, 0x4f, 0x79, 0xfe, 0x8e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICEnroll2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PKCS7) InstallPKCS7;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwKeySpec) GetSupportedKeySpec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fMin, BOOL fExchange, int32* pdwKeySize) GetKeyLen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwIndex, int32 algClass, int32* pdwAlgID) EnumAlgs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 algID, BSTR* pbstr) GetAlgName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fReuseHardwareKeyIfUnableToGenNew) put_ReuseHardwareKeyIfUnableToGenNew;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fReuseHardwareKeyIfUnableToGenNew) get_ReuseHardwareKeyIfUnableToGenNew;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 hashAlgID) put_HashAlgID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* hashAlgID) get_HashAlgID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fLimitExchangeKeyToEncipherment) put_LimitExchangeKeyToEncipherment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fLimitExchangeKeyToEncipherment) get_LimitExchangeKeyToEncipherment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnableSMIMECapabilities) put_EnableSMIMECapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fEnableSMIMECapabilities) get_EnableSMIMECapabilities;
	}


	public HRESULT InstallPKCS7(BSTR PKCS7) mut => VT.[Friend]InstallPKCS7(&this, PKCS7);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT GetSupportedKeySpec(int32* pdwKeySpec) mut => VT.[Friend]GetSupportedKeySpec(&this, pdwKeySpec);

	public HRESULT GetKeyLen(BOOL fMin, BOOL fExchange, int32* pdwKeySize) mut => VT.[Friend]GetKeyLen(&this, fMin, fExchange, pdwKeySize);

	public HRESULT EnumAlgs(int32 dwIndex, int32 algClass, int32* pdwAlgID) mut => VT.[Friend]EnumAlgs(&this, dwIndex, algClass, pdwAlgID);

	public HRESULT GetAlgName(int32 algID, BSTR* pbstr) mut => VT.[Friend]GetAlgName(&this, algID, pbstr);

	public HRESULT put_ReuseHardwareKeyIfUnableToGenNew(BOOL fReuseHardwareKeyIfUnableToGenNew) mut => VT.[Friend]put_ReuseHardwareKeyIfUnableToGenNew(&this, fReuseHardwareKeyIfUnableToGenNew);

	public HRESULT get_ReuseHardwareKeyIfUnableToGenNew(BOOL* fReuseHardwareKeyIfUnableToGenNew) mut => VT.[Friend]get_ReuseHardwareKeyIfUnableToGenNew(&this, fReuseHardwareKeyIfUnableToGenNew);

	public HRESULT put_HashAlgID(int32 hashAlgID) mut => VT.[Friend]put_HashAlgID(&this, hashAlgID);

	public HRESULT get_HashAlgID(int32* hashAlgID) mut => VT.[Friend]get_HashAlgID(&this, hashAlgID);

	public HRESULT put_LimitExchangeKeyToEncipherment(BOOL fLimitExchangeKeyToEncipherment) mut => VT.[Friend]put_LimitExchangeKeyToEncipherment(&this, fLimitExchangeKeyToEncipherment);

	public HRESULT get_LimitExchangeKeyToEncipherment(BOOL* fLimitExchangeKeyToEncipherment) mut => VT.[Friend]get_LimitExchangeKeyToEncipherment(&this, fLimitExchangeKeyToEncipherment);

	public HRESULT put_EnableSMIMECapabilities(BOOL fEnableSMIMECapabilities) mut => VT.[Friend]put_EnableSMIMECapabilities(&this, fEnableSMIMECapabilities);

	public HRESULT get_EnableSMIMECapabilities(BOOL* fEnableSMIMECapabilities) mut => VT.[Friend]get_EnableSMIMECapabilities(&this, fEnableSMIMECapabilities);
}

[CRepr]struct ICEnroll4 : ICEnroll3
{
	public new const Guid IID = .(0xc1f1188a, 0x2eb5, 0x4a80, 0x84, 0x1b, 0x7e, 0x72, 0x9a, 0x35, 0x6d, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICEnroll3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCert) put_PrivateKeyArchiveCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCert) get_PrivateKeyArchiveCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrThumbPrint) put_ThumbPrint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrThumbPrint) get_ThumbPrint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, BSTR strBinary, BSTR* pstrEncoded) binaryToString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, BSTR strEncoded, BSTR* pstrBinary) stringToBinary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, BSTR strName, BSTR strValue) addExtensionToRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, BSTR strName, BSTR strValue) addAttributeToRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, BSTR strName, BSTR strValue) addNameValuePairToRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) resetExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) resetAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CREATE_REQUEST_FLAGS Flags, BSTR strDNName, BSTR Usage, BSTR* pstrRequest) createRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CREATE_REQUEST_FLAGS Flags, BSTR strDNName, BSTR strUsage, BSTR strRequestFileName) createFileRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strResponse) acceptResponse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strResponseFileName) acceptFileResponse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strResponse, BSTR* pstrCert) getCertFromResponse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strResponseFileName, BSTR* pstrCert) getCertFromFileResponse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strPassword, BSTR* pstrPFX) createPFX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strPassword, BSTR strPFXFileName) createFilePFX;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lRequestID, BSTR strCADNS, BSTR strCAName, BSTR strFriendlyName) setPendingRequestInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, PENDING_REQUEST_DESIRED_PROPERTY lDesiredProperty, VARIANT* pvarProperty) enumPendingRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strThumbprint) removePendingRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XEKL_KEYSIZE lSizeSpec, XEKL_KEYSPEC lKeySpec, int32* pdwKeySize) GetKeyLenEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PKCS7, int32* plCertInstalled) InstallPKCS7Ex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADDED_CERT_TYPE lType, BSTR bstrOIDOrName, int32 lMajorVersion, BOOL fMinorVersion, int32 lMinorVersion) addCertTypeToRequestEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strProvName, int32* plProvType) getProviderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCert) put_SignerCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lClientId) put_ClientId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plClientId) get_ClientId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropertyId, int32 lReserved, BSTR bstrProperty) addBlobPropertyToCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) resetBlobProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fInclude) put_IncludeSubjectKeyID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfInclude) get_IncludeSubjectKeyID;
	}


	public HRESULT put_PrivateKeyArchiveCertificate(BSTR bstrCert) mut => VT.[Friend]put_PrivateKeyArchiveCertificate(&this, bstrCert);

	public HRESULT get_PrivateKeyArchiveCertificate(BSTR* pbstrCert) mut => VT.[Friend]get_PrivateKeyArchiveCertificate(&this, pbstrCert);

	public HRESULT put_ThumbPrint(BSTR bstrThumbPrint) mut => VT.[Friend]put_ThumbPrint(&this, bstrThumbPrint);

	public HRESULT get_ThumbPrint(BSTR* pbstrThumbPrint) mut => VT.[Friend]get_ThumbPrint(&this, pbstrThumbPrint);

	public HRESULT binaryToString(int32 Flags, BSTR strBinary, BSTR* pstrEncoded) mut => VT.[Friend]binaryToString(&this, Flags, strBinary, pstrEncoded);

	public HRESULT stringToBinary(int32 Flags, BSTR strEncoded, BSTR* pstrBinary) mut => VT.[Friend]stringToBinary(&this, Flags, strEncoded, pstrBinary);

	public HRESULT addExtensionToRequest(int32 Flags, BSTR strName, BSTR strValue) mut => VT.[Friend]addExtensionToRequest(&this, Flags, strName, strValue);

	public HRESULT addAttributeToRequest(int32 Flags, BSTR strName, BSTR strValue) mut => VT.[Friend]addAttributeToRequest(&this, Flags, strName, strValue);

	public HRESULT addNameValuePairToRequest(int32 Flags, BSTR strName, BSTR strValue) mut => VT.[Friend]addNameValuePairToRequest(&this, Flags, strName, strValue);

	public HRESULT resetExtensions() mut => VT.[Friend]resetExtensions(&this);

	public HRESULT resetAttributes() mut => VT.[Friend]resetAttributes(&this);

	public HRESULT createRequest(CERT_CREATE_REQUEST_FLAGS Flags, BSTR strDNName, BSTR Usage, BSTR* pstrRequest) mut => VT.[Friend]createRequest(&this, Flags, strDNName, Usage, pstrRequest);

	public HRESULT createFileRequest(CERT_CREATE_REQUEST_FLAGS Flags, BSTR strDNName, BSTR strUsage, BSTR strRequestFileName) mut => VT.[Friend]createFileRequest(&this, Flags, strDNName, strUsage, strRequestFileName);

	public HRESULT acceptResponse(BSTR strResponse) mut => VT.[Friend]acceptResponse(&this, strResponse);

	public HRESULT acceptFileResponse(BSTR strResponseFileName) mut => VT.[Friend]acceptFileResponse(&this, strResponseFileName);

	public HRESULT getCertFromResponse(BSTR strResponse, BSTR* pstrCert) mut => VT.[Friend]getCertFromResponse(&this, strResponse, pstrCert);

	public HRESULT getCertFromFileResponse(BSTR strResponseFileName, BSTR* pstrCert) mut => VT.[Friend]getCertFromFileResponse(&this, strResponseFileName, pstrCert);

	public HRESULT createPFX(BSTR strPassword, BSTR* pstrPFX) mut => VT.[Friend]createPFX(&this, strPassword, pstrPFX);

	public HRESULT createFilePFX(BSTR strPassword, BSTR strPFXFileName) mut => VT.[Friend]createFilePFX(&this, strPassword, strPFXFileName);

	public HRESULT setPendingRequestInfo(int32 lRequestID, BSTR strCADNS, BSTR strCAName, BSTR strFriendlyName) mut => VT.[Friend]setPendingRequestInfo(&this, lRequestID, strCADNS, strCAName, strFriendlyName);

	public HRESULT enumPendingRequest(int32 lIndex, PENDING_REQUEST_DESIRED_PROPERTY lDesiredProperty, VARIANT* pvarProperty) mut => VT.[Friend]enumPendingRequest(&this, lIndex, lDesiredProperty, pvarProperty);

	public HRESULT removePendingRequest(BSTR strThumbprint) mut => VT.[Friend]removePendingRequest(&this, strThumbprint);

	public HRESULT GetKeyLenEx(XEKL_KEYSIZE lSizeSpec, XEKL_KEYSPEC lKeySpec, int32* pdwKeySize) mut => VT.[Friend]GetKeyLenEx(&this, lSizeSpec, lKeySpec, pdwKeySize);

	public HRESULT InstallPKCS7Ex(BSTR PKCS7, int32* plCertInstalled) mut => VT.[Friend]InstallPKCS7Ex(&this, PKCS7, plCertInstalled);

	public HRESULT addCertTypeToRequestEx(ADDED_CERT_TYPE lType, BSTR bstrOIDOrName, int32 lMajorVersion, BOOL fMinorVersion, int32 lMinorVersion) mut => VT.[Friend]addCertTypeToRequestEx(&this, lType, bstrOIDOrName, lMajorVersion, fMinorVersion, lMinorVersion);

	public HRESULT getProviderType(BSTR strProvName, int32* plProvType) mut => VT.[Friend]getProviderType(&this, strProvName, plProvType);

	public HRESULT put_SignerCertificate(BSTR bstrCert) mut => VT.[Friend]put_SignerCertificate(&this, bstrCert);

	public HRESULT put_ClientId(int32 lClientId) mut => VT.[Friend]put_ClientId(&this, lClientId);

	public HRESULT get_ClientId(int32* plClientId) mut => VT.[Friend]get_ClientId(&this, plClientId);

	public HRESULT addBlobPropertyToCertificate(int32 lPropertyId, int32 lReserved, BSTR bstrProperty) mut => VT.[Friend]addBlobPropertyToCertificate(&this, lPropertyId, lReserved, bstrProperty);

	public HRESULT resetBlobProperties() mut => VT.[Friend]resetBlobProperties(&this);

	public HRESULT put_IncludeSubjectKeyID(BOOL fInclude) mut => VT.[Friend]put_IncludeSubjectKeyID(&this, fInclude);

	public HRESULT get_IncludeSubjectKeyID(BOOL* pfInclude) mut => VT.[Friend]get_IncludeSubjectKeyID(&this, pfInclude);
}

[CRepr]struct IEnroll : IUnknown
{
	public new const Guid IID = .(0xacaa7838, 0x4585, 0x11d1, 0xab, 0x57, 0x00, 0xc0, 0x4f, 0xc2, 0x95, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR DNName, PWSTR Usage, PWSTR wszPKCS10FileName) createFilePKCS10WStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszPKCS7FileName) acceptFilePKCS7WStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR DNName, PWSTR Usage, CRYPTOAPI_BLOB* pPkcs10Blob) createPKCS10WStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CRYPTOAPI_BLOB* pBlobPKCS7) acceptPKCS7Blob;
		protected new function [CallingConvention(.Stdcall)] CERT_CONTEXT*(SelfOuter* self, CRYPTOAPI_BLOB* pBlobPKCS7) getCertContextFromPKCS7;
		protected new function [CallingConvention(.Stdcall)] HCERTSTORE(SelfOuter* self) getMyStore;
		protected new function [CallingConvention(.Stdcall)] HCERTSTORE(SelfOuter* self) getCAStore;
		protected new function [CallingConvention(.Stdcall)] HCERTSTORE(SelfOuter* self) getROOTHStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwIndex, int32 dwFlags, PWSTR* pbstrProvName) enumProvidersWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwIndex, PWSTR* pbstr) enumContainersWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CRYPTOAPI_BLOB pkcs7OrPkcs10) freeRequestInfoBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* szwName) get_MyStoreNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szwName) put_MyStoreNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* szwType) get_MyStoreTypeWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szwType) put_MyStoreTypeWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwFlags) get_MyStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwFlags) put_MyStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* szwName) get_CAStoreNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szwName) put_CAStoreNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* szwType) get_CAStoreTypeWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szwType) put_CAStoreTypeWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwFlags) get_CAStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwFlags) put_CAStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* szwName) get_RootStoreNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szwName) put_RootStoreNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* szwType) get_RootStoreTypeWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szwType) put_RootStoreTypeWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwFlags) get_RootStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwFlags) put_RootStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* szwName) get_RequestStoreNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szwName) put_RequestStoreNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* szwType) get_RequestStoreTypeWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szwType) put_RequestStoreTypeWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwFlags) get_RequestStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwFlags) put_RequestStoreFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* szwContainer) get_ContainerNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szwContainer) put_ContainerNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* szwProvider) get_ProviderNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szwProvider) put_ProviderNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwType) get_ProviderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwType) put_ProviderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdw) get_KeySpec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dw) put_KeySpec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwFlags) get_ProviderFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwFlags) put_ProviderFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fUseExistingKeys) get_UseExistingKeySet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fUseExistingKeys) put_UseExistingKeySet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwFlags) get_GenKeyFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwFlags) put_GenKeyFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fDelete) get_DeleteRequestCert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fDelete) put_DeleteRequestCert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fBool) get_WriteCertToUserDS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fBool) put_WriteCertToUserDS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fBool) get_EnableT61DNEncoding;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fBool) put_EnableT61DNEncoding;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fBool) get_WriteCertToCSP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fBool) put_WriteCertToCSP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* szw) get_SPCFileNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szw) put_SPCFileNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* szw) get_PVKFileNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szw) put_PVKFileNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* szw) get_HashAlgorithmWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szw) put_HashAlgorithmWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CONTEXT** ppCertContext) get_RenewalCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CONTEXT* pCertContext) put_RenewalCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR szw) AddCertTypeToRequestWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Name, PWSTR Value) AddNameValuePairToSignatureWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_EXTENSIONS* pCertExtensions) AddExtensionsToRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CRYPT_ATTRIBUTES* pAttributes) AddAuthenticatedAttributesToPKCS7Request;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CRYPTOAPI_BLOB* pRequest, CERT_CONTEXT* pSigningCertContext, CRYPTOAPI_BLOB* pPkcs7Blob) CreatePKCS7RequestFromRequest;
	}


	public HRESULT createFilePKCS10WStr(PWSTR DNName, PWSTR Usage, PWSTR wszPKCS10FileName) mut => VT.[Friend]createFilePKCS10WStr(&this, DNName, Usage, wszPKCS10FileName);

	public HRESULT acceptFilePKCS7WStr(PWSTR wszPKCS7FileName) mut => VT.[Friend]acceptFilePKCS7WStr(&this, wszPKCS7FileName);

	public HRESULT createPKCS10WStr(PWSTR DNName, PWSTR Usage, CRYPTOAPI_BLOB* pPkcs10Blob) mut => VT.[Friend]createPKCS10WStr(&this, DNName, Usage, pPkcs10Blob);

	public HRESULT acceptPKCS7Blob(CRYPTOAPI_BLOB* pBlobPKCS7) mut => VT.[Friend]acceptPKCS7Blob(&this, pBlobPKCS7);

	public CERT_CONTEXT* getCertContextFromPKCS7(CRYPTOAPI_BLOB* pBlobPKCS7) mut => VT.[Friend]getCertContextFromPKCS7(&this, pBlobPKCS7);

	public HCERTSTORE getMyStore() mut => VT.[Friend]getMyStore(&this);

	public HCERTSTORE getCAStore() mut => VT.[Friend]getCAStore(&this);

	public HCERTSTORE getROOTHStore() mut => VT.[Friend]getROOTHStore(&this);

	public HRESULT enumProvidersWStr(int32 dwIndex, int32 dwFlags, PWSTR* pbstrProvName) mut => VT.[Friend]enumProvidersWStr(&this, dwIndex, dwFlags, pbstrProvName);

	public HRESULT enumContainersWStr(int32 dwIndex, PWSTR* pbstr) mut => VT.[Friend]enumContainersWStr(&this, dwIndex, pbstr);

	public HRESULT freeRequestInfoBlob(CRYPTOAPI_BLOB pkcs7OrPkcs10) mut => VT.[Friend]freeRequestInfoBlob(&this, pkcs7OrPkcs10);

	public HRESULT get_MyStoreNameWStr(PWSTR* szwName) mut => VT.[Friend]get_MyStoreNameWStr(&this, szwName);

	public HRESULT put_MyStoreNameWStr(PWSTR szwName) mut => VT.[Friend]put_MyStoreNameWStr(&this, szwName);

	public HRESULT get_MyStoreTypeWStr(PWSTR* szwType) mut => VT.[Friend]get_MyStoreTypeWStr(&this, szwType);

	public HRESULT put_MyStoreTypeWStr(PWSTR szwType) mut => VT.[Friend]put_MyStoreTypeWStr(&this, szwType);

	public HRESULT get_MyStoreFlags(int32* pdwFlags) mut => VT.[Friend]get_MyStoreFlags(&this, pdwFlags);

	public HRESULT put_MyStoreFlags(int32 dwFlags) mut => VT.[Friend]put_MyStoreFlags(&this, dwFlags);

	public HRESULT get_CAStoreNameWStr(PWSTR* szwName) mut => VT.[Friend]get_CAStoreNameWStr(&this, szwName);

	public HRESULT put_CAStoreNameWStr(PWSTR szwName) mut => VT.[Friend]put_CAStoreNameWStr(&this, szwName);

	public HRESULT get_CAStoreTypeWStr(PWSTR* szwType) mut => VT.[Friend]get_CAStoreTypeWStr(&this, szwType);

	public HRESULT put_CAStoreTypeWStr(PWSTR szwType) mut => VT.[Friend]put_CAStoreTypeWStr(&this, szwType);

	public HRESULT get_CAStoreFlags(int32* pdwFlags) mut => VT.[Friend]get_CAStoreFlags(&this, pdwFlags);

	public HRESULT put_CAStoreFlags(int32 dwFlags) mut => VT.[Friend]put_CAStoreFlags(&this, dwFlags);

	public HRESULT get_RootStoreNameWStr(PWSTR* szwName) mut => VT.[Friend]get_RootStoreNameWStr(&this, szwName);

	public HRESULT put_RootStoreNameWStr(PWSTR szwName) mut => VT.[Friend]put_RootStoreNameWStr(&this, szwName);

	public HRESULT get_RootStoreTypeWStr(PWSTR* szwType) mut => VT.[Friend]get_RootStoreTypeWStr(&this, szwType);

	public HRESULT put_RootStoreTypeWStr(PWSTR szwType) mut => VT.[Friend]put_RootStoreTypeWStr(&this, szwType);

	public HRESULT get_RootStoreFlags(int32* pdwFlags) mut => VT.[Friend]get_RootStoreFlags(&this, pdwFlags);

	public HRESULT put_RootStoreFlags(int32 dwFlags) mut => VT.[Friend]put_RootStoreFlags(&this, dwFlags);

	public HRESULT get_RequestStoreNameWStr(PWSTR* szwName) mut => VT.[Friend]get_RequestStoreNameWStr(&this, szwName);

	public HRESULT put_RequestStoreNameWStr(PWSTR szwName) mut => VT.[Friend]put_RequestStoreNameWStr(&this, szwName);

	public HRESULT get_RequestStoreTypeWStr(PWSTR* szwType) mut => VT.[Friend]get_RequestStoreTypeWStr(&this, szwType);

	public HRESULT put_RequestStoreTypeWStr(PWSTR szwType) mut => VT.[Friend]put_RequestStoreTypeWStr(&this, szwType);

	public HRESULT get_RequestStoreFlags(int32* pdwFlags) mut => VT.[Friend]get_RequestStoreFlags(&this, pdwFlags);

	public HRESULT put_RequestStoreFlags(int32 dwFlags) mut => VT.[Friend]put_RequestStoreFlags(&this, dwFlags);

	public HRESULT get_ContainerNameWStr(PWSTR* szwContainer) mut => VT.[Friend]get_ContainerNameWStr(&this, szwContainer);

	public HRESULT put_ContainerNameWStr(PWSTR szwContainer) mut => VT.[Friend]put_ContainerNameWStr(&this, szwContainer);

	public HRESULT get_ProviderNameWStr(PWSTR* szwProvider) mut => VT.[Friend]get_ProviderNameWStr(&this, szwProvider);

	public HRESULT put_ProviderNameWStr(PWSTR szwProvider) mut => VT.[Friend]put_ProviderNameWStr(&this, szwProvider);

	public HRESULT get_ProviderType(int32* pdwType) mut => VT.[Friend]get_ProviderType(&this, pdwType);

	public HRESULT put_ProviderType(int32 dwType) mut => VT.[Friend]put_ProviderType(&this, dwType);

	public HRESULT get_KeySpec(int32* pdw) mut => VT.[Friend]get_KeySpec(&this, pdw);

	public HRESULT put_KeySpec(int32 dw) mut => VT.[Friend]put_KeySpec(&this, dw);

	public HRESULT get_ProviderFlags(int32* pdwFlags) mut => VT.[Friend]get_ProviderFlags(&this, pdwFlags);

	public HRESULT put_ProviderFlags(int32 dwFlags) mut => VT.[Friend]put_ProviderFlags(&this, dwFlags);

	public HRESULT get_UseExistingKeySet(BOOL* fUseExistingKeys) mut => VT.[Friend]get_UseExistingKeySet(&this, fUseExistingKeys);

	public HRESULT put_UseExistingKeySet(BOOL fUseExistingKeys) mut => VT.[Friend]put_UseExistingKeySet(&this, fUseExistingKeys);

	public HRESULT get_GenKeyFlags(int32* pdwFlags) mut => VT.[Friend]get_GenKeyFlags(&this, pdwFlags);

	public HRESULT put_GenKeyFlags(int32 dwFlags) mut => VT.[Friend]put_GenKeyFlags(&this, dwFlags);

	public HRESULT get_DeleteRequestCert(BOOL* fDelete) mut => VT.[Friend]get_DeleteRequestCert(&this, fDelete);

	public HRESULT put_DeleteRequestCert(BOOL fDelete) mut => VT.[Friend]put_DeleteRequestCert(&this, fDelete);

	public HRESULT get_WriteCertToUserDS(BOOL* fBool) mut => VT.[Friend]get_WriteCertToUserDS(&this, fBool);

	public HRESULT put_WriteCertToUserDS(BOOL fBool) mut => VT.[Friend]put_WriteCertToUserDS(&this, fBool);

	public HRESULT get_EnableT61DNEncoding(BOOL* fBool) mut => VT.[Friend]get_EnableT61DNEncoding(&this, fBool);

	public HRESULT put_EnableT61DNEncoding(BOOL fBool) mut => VT.[Friend]put_EnableT61DNEncoding(&this, fBool);

	public HRESULT get_WriteCertToCSP(BOOL* fBool) mut => VT.[Friend]get_WriteCertToCSP(&this, fBool);

	public HRESULT put_WriteCertToCSP(BOOL fBool) mut => VT.[Friend]put_WriteCertToCSP(&this, fBool);

	public HRESULT get_SPCFileNameWStr(PWSTR* szw) mut => VT.[Friend]get_SPCFileNameWStr(&this, szw);

	public HRESULT put_SPCFileNameWStr(PWSTR szw) mut => VT.[Friend]put_SPCFileNameWStr(&this, szw);

	public HRESULT get_PVKFileNameWStr(PWSTR* szw) mut => VT.[Friend]get_PVKFileNameWStr(&this, szw);

	public HRESULT put_PVKFileNameWStr(PWSTR szw) mut => VT.[Friend]put_PVKFileNameWStr(&this, szw);

	public HRESULT get_HashAlgorithmWStr(PWSTR* szw) mut => VT.[Friend]get_HashAlgorithmWStr(&this, szw);

	public HRESULT put_HashAlgorithmWStr(PWSTR szw) mut => VT.[Friend]put_HashAlgorithmWStr(&this, szw);

	public HRESULT get_RenewalCertificate(CERT_CONTEXT** ppCertContext) mut => VT.[Friend]get_RenewalCertificate(&this, ppCertContext);

	public HRESULT put_RenewalCertificate(CERT_CONTEXT* pCertContext) mut => VT.[Friend]put_RenewalCertificate(&this, pCertContext);

	public HRESULT AddCertTypeToRequestWStr(PWSTR szw) mut => VT.[Friend]AddCertTypeToRequestWStr(&this, szw);

	public HRESULT AddNameValuePairToSignatureWStr(PWSTR Name, PWSTR Value) mut => VT.[Friend]AddNameValuePairToSignatureWStr(&this, Name, Value);

	public HRESULT AddExtensionsToRequest(CERT_EXTENSIONS* pCertExtensions) mut => VT.[Friend]AddExtensionsToRequest(&this, pCertExtensions);

	public HRESULT AddAuthenticatedAttributesToPKCS7Request(CRYPT_ATTRIBUTES* pAttributes) mut => VT.[Friend]AddAuthenticatedAttributesToPKCS7Request(&this, pAttributes);

	public HRESULT CreatePKCS7RequestFromRequest(CRYPTOAPI_BLOB* pRequest, CERT_CONTEXT* pSigningCertContext, CRYPTOAPI_BLOB* pPkcs7Blob) mut => VT.[Friend]CreatePKCS7RequestFromRequest(&this, pRequest, pSigningCertContext, pPkcs7Blob);
}

[CRepr]struct IEnroll2 : IEnroll
{
	public new const Guid IID = .(0xc080e199, 0xb7df, 0x11d2, 0xa4, 0x21, 0x00, 0xc0, 0x4f, 0x79, 0xfe, 0x8e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IEnroll.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CRYPTOAPI_BLOB* pBlobPKCS7) InstallPKCS7Blob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pdwKeySpec) GetSupportedKeySpec;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fMin, BOOL fExchange, int32* pdwKeySize) GetKeyLen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwIndex, int32 algClass, int32* pdwAlgID) EnumAlgs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 algID, PWSTR* ppwsz) GetAlgNameWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fReuseHardwareKeyIfUnableToGenNew) put_ReuseHardwareKeyIfUnableToGenNew;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fReuseHardwareKeyIfUnableToGenNew) get_ReuseHardwareKeyIfUnableToGenNew;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 hashAlgID) put_HashAlgID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* hashAlgID) get_HashAlgID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HCERTSTORE hStore) SetHStoreMy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HCERTSTORE hStore) SetHStoreCA;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HCERTSTORE hStore) SetHStoreROOT;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HCERTSTORE hStore) SetHStoreRequest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fLimitExchangeKeyToEncipherment) put_LimitExchangeKeyToEncipherment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fLimitExchangeKeyToEncipherment) get_LimitExchangeKeyToEncipherment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnableSMIMECapabilities) put_EnableSMIMECapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* fEnableSMIMECapabilities) get_EnableSMIMECapabilities;
	}


	public HRESULT InstallPKCS7Blob(CRYPTOAPI_BLOB* pBlobPKCS7) mut => VT.[Friend]InstallPKCS7Blob(&this, pBlobPKCS7);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT GetSupportedKeySpec(int32* pdwKeySpec) mut => VT.[Friend]GetSupportedKeySpec(&this, pdwKeySpec);

	public HRESULT GetKeyLen(BOOL fMin, BOOL fExchange, int32* pdwKeySize) mut => VT.[Friend]GetKeyLen(&this, fMin, fExchange, pdwKeySize);

	public HRESULT EnumAlgs(int32 dwIndex, int32 algClass, int32* pdwAlgID) mut => VT.[Friend]EnumAlgs(&this, dwIndex, algClass, pdwAlgID);

	public HRESULT GetAlgNameWStr(int32 algID, PWSTR* ppwsz) mut => VT.[Friend]GetAlgNameWStr(&this, algID, ppwsz);

	public HRESULT put_ReuseHardwareKeyIfUnableToGenNew(BOOL fReuseHardwareKeyIfUnableToGenNew) mut => VT.[Friend]put_ReuseHardwareKeyIfUnableToGenNew(&this, fReuseHardwareKeyIfUnableToGenNew);

	public HRESULT get_ReuseHardwareKeyIfUnableToGenNew(BOOL* fReuseHardwareKeyIfUnableToGenNew) mut => VT.[Friend]get_ReuseHardwareKeyIfUnableToGenNew(&this, fReuseHardwareKeyIfUnableToGenNew);

	public HRESULT put_HashAlgID(int32 hashAlgID) mut => VT.[Friend]put_HashAlgID(&this, hashAlgID);

	public HRESULT get_HashAlgID(int32* hashAlgID) mut => VT.[Friend]get_HashAlgID(&this, hashAlgID);

	public HRESULT SetHStoreMy(HCERTSTORE hStore) mut => VT.[Friend]SetHStoreMy(&this, hStore);

	public HRESULT SetHStoreCA(HCERTSTORE hStore) mut => VT.[Friend]SetHStoreCA(&this, hStore);

	public HRESULT SetHStoreROOT(HCERTSTORE hStore) mut => VT.[Friend]SetHStoreROOT(&this, hStore);

	public HRESULT SetHStoreRequest(HCERTSTORE hStore) mut => VT.[Friend]SetHStoreRequest(&this, hStore);

	public HRESULT put_LimitExchangeKeyToEncipherment(BOOL fLimitExchangeKeyToEncipherment) mut => VT.[Friend]put_LimitExchangeKeyToEncipherment(&this, fLimitExchangeKeyToEncipherment);

	public HRESULT get_LimitExchangeKeyToEncipherment(BOOL* fLimitExchangeKeyToEncipherment) mut => VT.[Friend]get_LimitExchangeKeyToEncipherment(&this, fLimitExchangeKeyToEncipherment);

	public HRESULT put_EnableSMIMECapabilities(BOOL fEnableSMIMECapabilities) mut => VT.[Friend]put_EnableSMIMECapabilities(&this, fEnableSMIMECapabilities);

	public HRESULT get_EnableSMIMECapabilities(BOOL* fEnableSMIMECapabilities) mut => VT.[Friend]get_EnableSMIMECapabilities(&this, fEnableSMIMECapabilities);
}

[CRepr]struct IEnroll4 : IEnroll2
{
	public new const Guid IID = .(0xf8053fe5, 0x78f4, 0x448f, 0xa0, 0xdb, 0x41, 0xd6, 0x1b, 0x73, 0x44, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IEnroll2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CRYPTOAPI_BLOB thumbPrintBlob) put_ThumbPrintWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CRYPTOAPI_BLOB* thumbPrintBlob) get_ThumbPrintWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CONTEXT* pPrivateKeyArchiveCert) SetPrivateKeyArchiveCertificate;
		protected new function [CallingConvention(.Stdcall)] CERT_CONTEXT*(SelfOuter* self) GetPrivateKeyArchiveCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, CRYPTOAPI_BLOB* pblobBinary, PWSTR* ppwszString) binaryBlobToString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, PWSTR pwszString, CRYPTOAPI_BLOB* pblobBinary, int32* pdwSkip, int32* pdwFlags) stringToBinaryBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, PWSTR pwszName, CRYPTOAPI_BLOB* pblobValue) addExtensionToRequestWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, PWSTR pwszName, CRYPTOAPI_BLOB* pblobValue) addAttributeToRequestWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Flags, PWSTR pwszName, PWSTR pwszValue) addNameValuePairToRequestWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) resetExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) resetAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CREATE_REQUEST_FLAGS Flags, PWSTR pwszDNName, PWSTR pwszUsage, CRYPTOAPI_BLOB* pblobRequest) createRequestWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CREATE_REQUEST_FLAGS Flags, PWSTR pwszDNName, PWSTR pwszUsage, PWSTR pwszRequestFileName) createFileRequestWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CRYPTOAPI_BLOB* pblobResponse) acceptResponseBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszResponseFileName) acceptFileResponseWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CRYPTOAPI_BLOB* pblobResponse, CERT_CONTEXT** ppCertContext) getCertContextFromResponseBlob;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszResponseFileName, CERT_CONTEXT** ppCertContext) getCertContextFromFileResponseWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszPassword, CRYPTOAPI_BLOB* pblobPFX) createPFXWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszPassword, PWSTR pwszPFXFileName) createFilePFXWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lRequestID, PWSTR pwszCADNS, PWSTR pwszCAName, PWSTR pwszFriendlyName) setPendingRequestInfoWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, PENDING_REQUEST_DESIRED_PROPERTY lDesiredProperty, void* ppProperty) enumPendingRequestWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CRYPTOAPI_BLOB thumbPrintBlob) removePendingRequestWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XEKL_KEYSIZE lSizeSpec, XEKL_KEYSPEC lKeySpec, int32* pdwKeySize) GetKeyLenEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CRYPTOAPI_BLOB* pBlobPKCS7, int32* plCertInstalled) InstallPKCS7BlobEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADDED_CERT_TYPE lType, PWSTR pwszOIDOrName, int32 lMajorVersion, BOOL fMinorVersion, int32 lMinorVersion) AddCertTypeToRequestWStrEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszProvName, int32* plProvType) getProviderTypeWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lPropertyId, int32 lReserved, CRYPTOAPI_BLOB* pBlobProperty) addBlobPropertyToCertificateWStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CONTEXT* pSignerCert) SetSignerCertificate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lClientId) put_ClientId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plClientId) get_ClientId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fInclude) put_IncludeSubjectKeyID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfInclude) get_IncludeSubjectKeyID;
	}


	public HRESULT put_ThumbPrintWStr(CRYPTOAPI_BLOB thumbPrintBlob) mut => VT.[Friend]put_ThumbPrintWStr(&this, thumbPrintBlob);

	public HRESULT get_ThumbPrintWStr(CRYPTOAPI_BLOB* thumbPrintBlob) mut => VT.[Friend]get_ThumbPrintWStr(&this, thumbPrintBlob);

	public HRESULT SetPrivateKeyArchiveCertificate(CERT_CONTEXT* pPrivateKeyArchiveCert) mut => VT.[Friend]SetPrivateKeyArchiveCertificate(&this, pPrivateKeyArchiveCert);

	public CERT_CONTEXT* GetPrivateKeyArchiveCertificate() mut => VT.[Friend]GetPrivateKeyArchiveCertificate(&this);

	public HRESULT binaryBlobToString(int32 Flags, CRYPTOAPI_BLOB* pblobBinary, PWSTR* ppwszString) mut => VT.[Friend]binaryBlobToString(&this, Flags, pblobBinary, ppwszString);

	public HRESULT stringToBinaryBlob(int32 Flags, PWSTR pwszString, CRYPTOAPI_BLOB* pblobBinary, int32* pdwSkip, int32* pdwFlags) mut => VT.[Friend]stringToBinaryBlob(&this, Flags, pwszString, pblobBinary, pdwSkip, pdwFlags);

	public HRESULT addExtensionToRequestWStr(int32 Flags, PWSTR pwszName, CRYPTOAPI_BLOB* pblobValue) mut => VT.[Friend]addExtensionToRequestWStr(&this, Flags, pwszName, pblobValue);

	public HRESULT addAttributeToRequestWStr(int32 Flags, PWSTR pwszName, CRYPTOAPI_BLOB* pblobValue) mut => VT.[Friend]addAttributeToRequestWStr(&this, Flags, pwszName, pblobValue);

	public HRESULT addNameValuePairToRequestWStr(int32 Flags, PWSTR pwszName, PWSTR pwszValue) mut => VT.[Friend]addNameValuePairToRequestWStr(&this, Flags, pwszName, pwszValue);

	public HRESULT resetExtensions() mut => VT.[Friend]resetExtensions(&this);

	public HRESULT resetAttributes() mut => VT.[Friend]resetAttributes(&this);

	public HRESULT createRequestWStr(CERT_CREATE_REQUEST_FLAGS Flags, PWSTR pwszDNName, PWSTR pwszUsage, CRYPTOAPI_BLOB* pblobRequest) mut => VT.[Friend]createRequestWStr(&this, Flags, pwszDNName, pwszUsage, pblobRequest);

	public HRESULT createFileRequestWStr(CERT_CREATE_REQUEST_FLAGS Flags, PWSTR pwszDNName, PWSTR pwszUsage, PWSTR pwszRequestFileName) mut => VT.[Friend]createFileRequestWStr(&this, Flags, pwszDNName, pwszUsage, pwszRequestFileName);

	public HRESULT acceptResponseBlob(CRYPTOAPI_BLOB* pblobResponse) mut => VT.[Friend]acceptResponseBlob(&this, pblobResponse);

	public HRESULT acceptFileResponseWStr(PWSTR pwszResponseFileName) mut => VT.[Friend]acceptFileResponseWStr(&this, pwszResponseFileName);

	public HRESULT getCertContextFromResponseBlob(CRYPTOAPI_BLOB* pblobResponse, CERT_CONTEXT** ppCertContext) mut => VT.[Friend]getCertContextFromResponseBlob(&this, pblobResponse, ppCertContext);

	public HRESULT getCertContextFromFileResponseWStr(PWSTR pwszResponseFileName, CERT_CONTEXT** ppCertContext) mut => VT.[Friend]getCertContextFromFileResponseWStr(&this, pwszResponseFileName, ppCertContext);

	public HRESULT createPFXWStr(PWSTR pwszPassword, CRYPTOAPI_BLOB* pblobPFX) mut => VT.[Friend]createPFXWStr(&this, pwszPassword, pblobPFX);

	public HRESULT createFilePFXWStr(PWSTR pwszPassword, PWSTR pwszPFXFileName) mut => VT.[Friend]createFilePFXWStr(&this, pwszPassword, pwszPFXFileName);

	public HRESULT setPendingRequestInfoWStr(int32 lRequestID, PWSTR pwszCADNS, PWSTR pwszCAName, PWSTR pwszFriendlyName) mut => VT.[Friend]setPendingRequestInfoWStr(&this, lRequestID, pwszCADNS, pwszCAName, pwszFriendlyName);

	public HRESULT enumPendingRequestWStr(int32 lIndex, PENDING_REQUEST_DESIRED_PROPERTY lDesiredProperty, void* ppProperty) mut => VT.[Friend]enumPendingRequestWStr(&this, lIndex, lDesiredProperty, ppProperty);

	public HRESULT removePendingRequestWStr(CRYPTOAPI_BLOB thumbPrintBlob) mut => VT.[Friend]removePendingRequestWStr(&this, thumbPrintBlob);

	public HRESULT GetKeyLenEx(XEKL_KEYSIZE lSizeSpec, XEKL_KEYSPEC lKeySpec, int32* pdwKeySize) mut => VT.[Friend]GetKeyLenEx(&this, lSizeSpec, lKeySpec, pdwKeySize);

	public HRESULT InstallPKCS7BlobEx(CRYPTOAPI_BLOB* pBlobPKCS7, int32* plCertInstalled) mut => VT.[Friend]InstallPKCS7BlobEx(&this, pBlobPKCS7, plCertInstalled);

	public HRESULT AddCertTypeToRequestWStrEx(ADDED_CERT_TYPE lType, PWSTR pwszOIDOrName, int32 lMajorVersion, BOOL fMinorVersion, int32 lMinorVersion) mut => VT.[Friend]AddCertTypeToRequestWStrEx(&this, lType, pwszOIDOrName, lMajorVersion, fMinorVersion, lMinorVersion);

	public HRESULT getProviderTypeWStr(PWSTR pwszProvName, int32* plProvType) mut => VT.[Friend]getProviderTypeWStr(&this, pwszProvName, plProvType);

	public HRESULT addBlobPropertyToCertificateWStr(int32 lPropertyId, int32 lReserved, CRYPTOAPI_BLOB* pBlobProperty) mut => VT.[Friend]addBlobPropertyToCertificateWStr(&this, lPropertyId, lReserved, pBlobProperty);

	public HRESULT SetSignerCertificate(CERT_CONTEXT* pSignerCert) mut => VT.[Friend]SetSignerCertificate(&this, pSignerCert);

	public HRESULT put_ClientId(int32 lClientId) mut => VT.[Friend]put_ClientId(&this, lClientId);

	public HRESULT get_ClientId(int32* plClientId) mut => VT.[Friend]get_ClientId(&this, plClientId);

	public HRESULT put_IncludeSubjectKeyID(BOOL fInclude) mut => VT.[Friend]put_IncludeSubjectKeyID(&this, fInclude);

	public HRESULT get_IncludeSubjectKeyID(BOOL* pfInclude) mut => VT.[Friend]get_IncludeSubjectKeyID(&this, pfInclude);
}

[CRepr]struct ICertRequestD : IUnknown
{
	public new const Guid IID = .(0xd99e6e70, 0xfc88, 0x11d0, 0xb4, 0x98, 0x00, 0xa0, 0xc9, 0x03, 0x12, 0xf3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, PWSTR pwszAuthority, uint32* pdwRequestId, uint32* pdwDisposition, PWSTR pwszAttributes, CERTTRANSBLOB* pctbRequest, CERTTRANSBLOB* pctbCertChain, CERTTRANSBLOB* pctbEncodedCert, CERTTRANSBLOB* pctbDispositionMessage) Request;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fchain, PWSTR pwszAuthority, CERTTRANSBLOB* pctbOut) GetCACert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszAuthority) Ping;
	}


	public HRESULT Request(uint32 dwFlags, PWSTR pwszAuthority, uint32* pdwRequestId, uint32* pdwDisposition, PWSTR pwszAttributes, CERTTRANSBLOB* pctbRequest, CERTTRANSBLOB* pctbCertChain, CERTTRANSBLOB* pctbEncodedCert, CERTTRANSBLOB* pctbDispositionMessage) mut => VT.[Friend]Request(&this, dwFlags, pwszAuthority, pdwRequestId, pdwDisposition, pwszAttributes, pctbRequest, pctbCertChain, pctbEncodedCert, pctbDispositionMessage);

	public HRESULT GetCACert(uint32 fchain, PWSTR pwszAuthority, CERTTRANSBLOB* pctbOut) mut => VT.[Friend]GetCACert(&this, fchain, pwszAuthority, pctbOut);

	public HRESULT Ping(PWSTR pwszAuthority) mut => VT.[Friend]Ping(&this, pwszAuthority);
}

[CRepr]struct ICertRequestD2 : ICertRequestD
{
	public new const Guid IID = .(0x5422fd3a, 0xd4b8, 0x4cef, 0xa1, 0x2e, 0xe8, 0x7d, 0x4c, 0xa2, 0x2e, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICertRequestD.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszAuthority, uint32 dwFlags, PWSTR pwszSerialNumber, uint32* pdwRequestId, uint32* pdwDisposition, PWSTR pwszAttributes, CERTTRANSBLOB* pctbRequest, CERTTRANSBLOB* pctbFullResponse, CERTTRANSBLOB* pctbEncodedCert, CERTTRANSBLOB* pctbDispositionMessage) Request2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszAuthority, int32 PropId, int32 PropIndex, int32 PropType, CERTTRANSBLOB* pctbPropertyValue) GetCAProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszAuthority, int32* pcProperty, CERTTRANSBLOB* pctbPropInfo) GetCAPropertyInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszAuthority) Ping2;
	}


	public HRESULT Request2(PWSTR pwszAuthority, uint32 dwFlags, PWSTR pwszSerialNumber, uint32* pdwRequestId, uint32* pdwDisposition, PWSTR pwszAttributes, CERTTRANSBLOB* pctbRequest, CERTTRANSBLOB* pctbFullResponse, CERTTRANSBLOB* pctbEncodedCert, CERTTRANSBLOB* pctbDispositionMessage) mut => VT.[Friend]Request2(&this, pwszAuthority, dwFlags, pwszSerialNumber, pdwRequestId, pdwDisposition, pwszAttributes, pctbRequest, pctbFullResponse, pctbEncodedCert, pctbDispositionMessage);

	public HRESULT GetCAProperty(PWSTR pwszAuthority, int32 PropId, int32 PropIndex, int32 PropType, CERTTRANSBLOB* pctbPropertyValue) mut => VT.[Friend]GetCAProperty(&this, pwszAuthority, PropId, PropIndex, PropType, pctbPropertyValue);

	public HRESULT GetCAPropertyInfo(PWSTR pwszAuthority, int32* pcProperty, CERTTRANSBLOB* pctbPropInfo) mut => VT.[Friend]GetCAPropertyInfo(&this, pwszAuthority, pcProperty, pctbPropInfo);

	public HRESULT Ping2(PWSTR pwszAuthority) mut => VT.[Friend]Ping2(&this, pwszAuthority);
}

#endregion

#region Functions
public static
{
	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvIsServerOnlineW(PWSTR pwszServerName, BOOL* pfServerOnline);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvBackupGetDynamicFileListW(void* hbc, PWSTR* ppwszzFileList, uint32* pcbSize);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvBackupPrepareW(PWSTR pwszServerName, uint32 grbitJet, CSBACKUP_TYPE dwBackupFlags, void** phbc);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvBackupGetDatabaseNamesW(void* hbc, PWSTR* ppwszzAttachmentInformation, uint32* pcbSize);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvBackupOpenFileW(void* hbc, PWSTR pwszAttachmentName, uint32 cbReadHintSize, LARGE_INTEGER* pliFileSize);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvBackupRead(void* hbc, void* pvBuffer, uint32 cbBuffer, uint32* pcbRead);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvBackupClose(void* hbc);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvBackupGetBackupLogsW(void* hbc, PWSTR* ppwszzBackupLogFiles, uint32* pcbSize);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvBackupTruncateLogs(void* hbc);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvBackupEnd(void* hbc);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void CertSrvBackupFree(void* pv);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvRestoreGetDatabaseLocationsW(void* hbc, PWSTR* ppwszzDatabaseLocationList, uint32* pcbSize);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvRestorePrepareW(PWSTR pwszServerName, uint32 dwRestoreFlags, void** phbc);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvRestoreRegisterW(void* hbc, PWSTR pwszCheckPointFilePath, PWSTR pwszLogPath, CSEDB_RSTMAPW* rgrstmap, int32 crstmap, PWSTR pwszBackupLogPath, uint32 genLow, uint32 genHigh);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvRestoreRegisterThroughFile(void* hbc, PWSTR pwszCheckPointFilePath, PWSTR pwszLogPath, CSEDB_RSTMAPW* rgrstmap, int32 crstmap, PWSTR pwszBackupLogPath, uint32 genLow, uint32 genHigh);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvRestoreRegisterComplete(void* hbc, HRESULT hrRestoreState);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvRestoreEnd(void* hbc);

	[Import("certadm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CertSrvServerControlW(PWSTR pwszServerName, uint32 dwControlFlags, uint32* pcbOut, uint8** ppbOut);

	[Import("certpoleng.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS PstGetTrustAnchors(UNICODE_STRING* pTargetName, uint32 cCriteria, CERT_SELECT_CRITERIA* rgpCriteria, SecPkgContext_IssuerListInfoEx** ppTrustedIssuers);

	[Import("certpoleng.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS PstGetTrustAnchorsEx(UNICODE_STRING* pTargetName, uint32 cCriteria, CERT_SELECT_CRITERIA* rgpCriteria, CERT_CONTEXT* pCertContext, SecPkgContext_IssuerListInfoEx** ppTrustedIssuers);

	[Import("certpoleng.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS PstGetCertificateChain(CERT_CONTEXT* pCert, SecPkgContext_IssuerListInfoEx* pTrustedIssuers, CERT_CHAIN_CONTEXT** ppCertChainContext);

	[Import("certpoleng.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS PstGetCertificates(UNICODE_STRING* pTargetName, uint32 cCriteria, CERT_SELECT_CRITERIA* rgpCriteria, BOOL bIsClient, uint32* pdwCertChainContextCount, CERT_CHAIN_CONTEXT*** ppCertChainContexts);

	[Import("certpoleng.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS PstAcquirePrivateKey(CERT_CONTEXT* pCert);

	[Import("certpoleng.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS PstValidate(UNICODE_STRING* pTargetName, BOOL bIsClient, CERT_USAGE_MATCH* pRequestedIssuancePolicy, HCERTSTORE* phAdditionalCertStore, CERT_CONTEXT* pCert, Guid* pProvGUID);

	[Import("certpoleng.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS PstMapCertificate(CERT_CONTEXT* pCert, LSA_TOKEN_INFORMATION_TYPE* pTokenInformationType, void** ppTokenInformation);

	[Import("certpoleng.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS PstGetUserNameForCertificate(CERT_CONTEXT* pCertContext, UNICODE_STRING* UserName);

}
#endregion
