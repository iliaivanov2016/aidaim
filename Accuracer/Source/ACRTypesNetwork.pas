unit ACRTypesNetwork;

//------------------------------------------------------------------------------
// network types
//------------------------------------------------------------------------------

interface

{$I ACRVer.inc}

uses
// Accuracer units
{$IFDEF DEBUG_LOG}
  ACRDebug,
{$ENDIF}
  ACRConst,
  ACRTypes;

type

// Network protocols
 TACRClientProtocol = (acrTCP, acrUDP);
 TACRServerProtocol = (acrsTCP, acrsUDP, acrsTCPandUDP);

// default protocols
const
 ACRDefaultClientProtocol = acrTCP;
 ACRDefaultServerProtocol = acrsTCPandUDP;

type
// Default Network Settings types
 TACRDefaultNetworkSettings = (ACRLocal, ACRLAN, ACRWAN, ACRModem);

// Connection parameters
 TACRConnectParams = packed record
    ConnectionParamsTunning:          Boolean;
    PingClients:                      Boolean;
    RemoteHost:                       AnsiString;
    RemotePort:                       Integer;
    LocalHost:                        AnsiString;
    LocalPort:                        Integer;
    ServerID:                         Integer;
    PacketSize:                       Integer;
    MaxThreadCount:                   Integer;
    TestPacketCount:                  Integer;
    ConnectRetryCount:                Integer;
    ConnectDelay:                     Integer;
    StartReceiveTimeOut:              Integer;
    ReceiveTimeOut:                   Integer;
    ReceiveSleep:                     Integer;
    ServerReceiveTimeOut:             Integer;
    ServerReceiveSleep:               Integer;
    MinSendTimeOut:                   Integer;
    SendTimeOut:                      Integer;
    MinServerSendTimeOut:             Integer;
    ServerSendTimeOut:                Integer;
    WaitForSendSleep:                 Integer;
    ServerWaitForSendSleep:           Integer;
    ResendDelay:                      Integer;
    RequestDelay:                     Integer;
    ServerResendDelay:                Integer;
    ServerRequestDelay:               Integer;
    DisconnectRetryCount:             Integer;
    DisconnectDelay:                  Integer;
    WaitForTimeOut:                   Integer;
    WaitForMessagesSend:              Integer;
    WaitForServerSessionThreadTimeOut:Integer;
    ThreadsTerminateDelay:            Integer;
    ServerThreadsTerminateDelay:      Integer;
    ServerSessionTerminatorSleep:     Integer;
    PingCount:                        Integer;
    WaitForPingAnswer:                Integer;
    ServerPingSleep:                  Integer;
    CommandRetryCount:                Integer;
    KeepConnection:                   Boolean;
    UseServerSettings:                Boolean;
    CryptoInfo:                       TACRCryptoInfo;
    CompressionAlgorithm:             Byte;
    CompressionMode:                  Byte;
    Protocol:                         Byte;
 end;
 PACRConnectParams = ^TACRConnectParams;

// types of messages
 TACRMessageType = (aamtText,aamtBinary,aamtStream,aamtUnicodeText);

implementation

uses
  ACRMemory; // last

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('< ACRTypesNetwork initialized');
{$ENDIF}
ACRMaxInternalFileNotCompressedSize := ACRDefaultPacketSize
  - SizeOf(TACRDiskPageHeader) - SizeOf(TACRInternalFileHeader);
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('> ACRTypesNetwork initialized');
{$ENDIF}
  ACRMemoryIncUseCount;

finalization

  ACRMemoryDecUseCount;


end.
