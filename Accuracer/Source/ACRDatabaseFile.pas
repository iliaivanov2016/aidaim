unit ACRDatabaseFile;

interface

{$I ACRVer.Inc}

uses
{$IFDEF MSWINDOWS}
    Windows,
{$ENDIF}
    Classes,
    SysUtils,
{$IFDEF DEBUG_LOG}
		ACRDebug,
{$ENDIF}
    ACRExcept,
    ACRConst,
    ACRTypes,
    ACRCriticalSection,
    ACRCompression,
    ACRMemory
   ;

type
////////////////////////////////////////////////////////////////////////////////
//
// TACRDatabaseFile
//
////////////////////////////////////////////////////////////////////////////////

  TACRDatabaseFile = class(TObject)
  private
    FFileName:        AnsiString;
    FFileNameUnicode: WideString;

    FAccessMode:      TACRAccessMode;
    FShareMode:       TACRShareMode;
    FAttrFlags:       DWORD;
{$IFDEF MSWINDOWS}
    FHandle:          THandle;
{$ENDIF}
{$IFDEF LINUX}
    FHandle:          Integer;
    FSize:            Int64;
{$ENDIF}
    FIsOpened: Boolean;

    FThreadSync:      TACRReadWriteThreadSyncBySingleCriticalSection;
  private
    function ConvertAccessMode(am: TACRAccessMode): DWORD;
    function ConvertShareMode(sm: TACRShareMode): DWORD;

    // if file closed then raise
    procedure CheckOpened(OperationName: AnsiString);
    // if file opened then raise
    procedure CheckClosed(OperationName: AnsiString);
    // Seek
    procedure Seek(Offset: Int64; ErrorCode: Integer = 0);

    procedure SetPosition(Offset: Int64);
    function GetPosition: Int64;

    procedure SetSize(NewSize: Int64);
    function GetSize: Int64;
  public
    // Constructor
    constructor Create;
    // Destructor
    destructor Destroy; override;
    // lock
    procedure Lock;
    // unlock
    procedure Unlock;

    // Create and Open File
    procedure CreateAndOpenFile(FileName: AnsiString; FileNameUnicode: WideString = '');
    // Delete File
    procedure DeleteFile;
    // Rename Closed File
    procedure RenameFile(OldFileName, NewFileName: AnsiString);

    // Open File
    procedure OpenFile(FileName: AnsiString; FileNameUnicode: WideString;
      var AccessMode: TACRAccessMode; var ShareMode: TACRShareMode;
      SkipExistsCheck: Boolean);
    // Close File
    procedure CloseFile;

    // Read Buffer
    procedure ReadBuffer(var Buffer; const Count: Int64; const Pos: Int64;
      ErrorCode: Integer; DoLock: Boolean = True);
    // Write Buffer
    procedure WriteBuffer(const Buffer; const Count: Int64; const Pos: Int64;
      ErrorCode: Integer; DoLock: Boolean = True);
    // Flush Buffers
    procedure FlushFileBuffers;

    // Lock Byte (return TRUE if success)
    function LockByte(Offset: Int64; Count: Integer = 1;
      Exclusive: Boolean = True): Boolean;
    // Unlock Byte
    function UnlockByte(Offset: Int64; Count: Integer = 1;
      Exclusive: Boolean = True): Boolean;
    // return TRUE if byte Locked
    function IsByteLocked(Offset: Int64): Boolean;
    // return FALSE if any byte of region is locked
    function IsRegionLocked(Offset: Int64; Count: Integer): Boolean;
    function IsDBHeaderValid(Offset: Int64): Boolean;
    function GetOffsetToSignature(const sgn: TACRSignature;
      StartOffset: Int64 = 0): Int64;
  public
{$IFDEF DEBUG_LOG}
    property Handle: THandle read FHandle;
{$ENDIF}
    property FileName: AnsiString read FFileName;
    property FileNameUnicode: WideString read FFileNameUnicode;
    property IsOpened: Boolean read FIsOpened;
    property AccessMode: TACRAccessMode read FAccessMode;
    property Size: Int64 read GetSize write SetSize;
    property Position: Int64 read GetPosition write SetPosition;
  end; // TACRDatabaseFile


implementation


////////////////////////////////////////////////////////////////////////////////
//
// TACRDatabaseFile
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Convert ACRAccessMode to Windows or Linux file open access modes
//------------------------------------------------------------------------------
function TACRDatabaseFile.ConvertAccessMode(am: TACRAccessMode): DWORD;
begin
  case am of
    amReadOnly:
{$IFDEF MSWINDOWS}
      // Result := GENERIC_READ or GENERIC_WRITE;
      Result := GENERIC_READ;
{$ENDIF}
{$IFDEF LINUX}
      Result := fmOpenRead;
{$ENDIF}
    amReadWrite:
{$IFDEF MSWINDOWS}
      Result := GENERIC_READ or GENERIC_WRITE;
{$ENDIF}
{$IFDEF LINUX}
      Result := fmOpenReadWrite;
{$ENDIF}
    else
      raise EACRException.Create(30366, ErrorGUnknownAccessMode,
        [Integer(am)]);
  end;
end; // ConvertAccessMode


//------------------------------------------------------------------------------
// Convert ACRShareMode to Windows or Linux file open share modes
//------------------------------------------------------------------------------
function TACRDatabaseFile.ConvertShareMode(sm: TACRShareMode): DWORD;
begin
  case sm of
    smExclusive:
      {$IFDEF MSWINDOWS}
      Result := 0;
      {$ENDIF}
      {$IFDEF LINUX}
      Result := fmShareExclusive;
      {$ENDIF}
  smShared:
      {$IFDEF MSWINDOWS}
      Result := FILE_SHARE_READ or FILE_SHARE_WRITE;
      {$ENDIF}
      {$IFDEF LINUX}
      Result := fmShareDenyNone;
      {$ENDIF}
  else
   raise EACRException.Create(30367, ErrorGUnknownShareMode, [Integer(sm)]);
  end;
end; // ConvertShareMode


//------------------------------------------------------------------------------
// if file opened then raise
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.CheckOpened(OperationName: AnsiString);
begin
  if not FIsOpened then
    raise EACRException.Create(30376, ErrorGFileIsClosed, [OperationName]);
end; // CheckOpened


//------------------------------------------------------------------------------
// File Seek
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.CheckClosed(OperationName: AnsiString);
begin
  if FIsOpened then
    raise EACRException.Create(30377, ErrorGFileIsOpened, [OperationName]);
end; // CheckClosed


//------------------------------------------------------------------------------
// File Seek
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.Seek(Offset: Int64; ErrorCode: Integer = 0);
var Pos:    Int64;
    ECode:  Integer;
begin
CheckOpened('Seek');
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
aaWriteToLog('> TACRDatabaseFile.Seek, Offset = ' + IntToStr(Offset) + ', ErrorCode = ' + IntToStr(ErrorCode));
{$ENDIF}
{$IFDEF MSWINDOWS}
{$R-}
  Pos := Offset;
  Int64Rec(Pos).Lo := SetFilePointer(THandle(FHandle),
    Int64Rec(Pos).Lo, @Int64Rec(Pos).Hi, 0);
{$R+}
{$ENDIF}
{$IFDEF LINUX}
  Pos := lseek64(FHandle, Offset, SEEK_SET);
{$ENDIF}
if (Pos <> Offset) then
  begin
    if ErrorCode = 0 then
      ECode := 30372
    else
      ECode := ErrorCode;
    raise EACRException.Create(ECode, ErrorGCannotSetFilePosition,
      [Offset, FFileName, GetPosition, GetSize]);
  end;
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
aaWriteToLog('< TACRDatabaseFile.Seek, Offset = ' + IntToStr(Offset)
    + ', ErrorCode = ' + IntToStr(ErrorCode)
    + #13#10 + 'pos = ' + IntToStr(Pos));
{$ENDIF}
end; // Seek


//------------------------------------------------------------------------------
// File Set Position
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.SetPosition(Offset: Int64);
begin
  CheckOpened('SetPosition');
{$IFDEF DEBUG_LOG_FILES}
aaWriteToLog('SetPosition to ' + IntToStr(Offset) + ':');
{$ENDIF}
  Seek(Offset);
{$IFDEF DEBUG_LOG_FILES}
aaWriteToLog('');
{$ENDIF}
end; // SetPosition


//------------------------------------------------------------------------------
// File Get Position
//------------------------------------------------------------------------------
function TACRDatabaseFile.GetPosition: Int64;
var SysErrorCode: DWORD;
{$IFDEF MSWINDOWS}
    HOffset:      Integer;
{$ENDIF}
begin
CheckOpened('GetPosition');
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
aaWriteToLog('> TACRDatabaseFile.GetPosition');
{$ENDIF}
{$IFDEF MSWINDOWS}
  HOffset := 0;
  Int64Rec(Result).Lo := SetFilePointer(FHandle, 0, @HOffset, FILE_CURRENT);
  Int64Rec(Result).Hi := HOffset;
{$ENDIF}
{$IFDEF LINUX}
  Result := lseek64(FHandle, 0, SEEK_CUR);
{$ENDIF}
  if (Result = INVALID_ID4) then
    begin
      SysErrorCode := GetLastError;
      raise EACRException.Create(30373, ErrorGCannotGetFilePosition,
        [FFileName, SysErrorCode, SysErrorMessage(SysErrorCode)]);
    end;
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
aaWriteToLog('< TACRDatabaseFile.GetPosition' + #13#10 +'Result = ' + IntToStr(Result));
{$ENDIF}
{$IFDEF DEBUG_LOG_FILES}
aaWriteToLog('GetPosition: ' + IntToStr(Result));
aaWriteToLog('');
{$ENDIF}
end; // GetPosition


//------------------------------------------------------------------------------
// Set File Size
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.SetSize(NewSize: Int64);
var SysErrorCode: DWORD;
begin
  CheckOpened('SetSize');
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
aaWriteToLog('> TACRDatabaseFile.SetSize, NewSize = ' + IntToStr(NewSize));
{$ENDIF}
  Lock;
  try
    // SetPosition
    Seek(NewSize);
    // Truncate File
{$IFDEF MSWINDOWS}
    if (not SetEndOfFile(FHandle)) then
      begin
{$ENDIF}
{$IFDEF LINUX}
    FSize := NewSize;
    if ftruncate(FHandle, Position) = -1 then
      begin
{$ENDIF}
        SysErrorCode := GetLastError;
        raise EACRException.Create(30370, ErrorGCannotTruncateFile,
          [FFileName, NewSize, SysErrorCode,
          SysErrorMessage(SysErrorCode)]);
      end;
  finally
    Unlock;
  end;
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog('< TACRDatabaseFile.SetSize, NewSize = ' + IntToStr(NewSize));
{$ENDIF}
end; // SetSize


//------------------------------------------------------------------------------
// Get File Size
//------------------------------------------------------------------------------
function TACRDatabaseFile.GetSize: Int64;
var
{$IFDEF MSWINDOWS}
  HSize: Integer;
{$ENDIF}
  SysErrorCode: DWORD;
begin
  CheckOpened('GetSize');
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
aaWriteToLog('> TACRDatabaseFile.GetSize');
{$ENDIF}
{$IFDEF MSWINDOWS}
  Int64Rec(Result).Lo := GetFileSize(FHandle, @HSize);
  if (Int64Rec(Result).Lo = INVALID_FILE_SIZE) then
    begin
      SysErrorCode := GetLastError;
      raise EACRException.Create(30371, ErrorGCannotGetFileSize,
        [FFileName, SysErrorCode, SysErrorMessage(SysErrorCode)]);
    end;
  Int64Rec(Result).Hi := HSize;
{$ENDIF}
{$IFDEF LINUX}
  Result := FSize;
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
aaWriteToLog('< TACRDatabaseFile.GetSize, Result = ' + IntToStr(Result));
{$ENDIF}
end; // GetSize


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
constructor TACRDatabaseFile.Create;
begin
  FThreadSync := TACRReadWriteThreadSyncBySingleCriticalSection.Create;
  FFileName := '';
  FAccessMode := amReadWrite;
  FShareMode := smShared;
{$IFDEF MSWINDOWS}
  // FAttrFlags  := FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN;
  FAttrFlags := FILE_ATTRIBUTE_NORMAL or FILE_FLAG_RANDOM_ACCESS;
{$ENDIF}
{$IFDEF LINUX}
  FAttrFlags := FileAccessRights;
  FSize := INVALID_FILE_SIZE;
{$ENDIF}
  FHandle := INVALID_HANDLE_VALUE;
  FIsOpened := False;
end; // Create

//------------------------------------------------------------------------------
// Destructor
//------------------------------------------------------------------------------
destructor TACRDatabaseFile.Destroy;
begin
  if FIsOpened then
   try
    CloseFile;
   except on E: Exception do
   end;
  FThreadSync.Free;
  inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.Lock;
begin
//  FThreadSync.Lock(True);
end; // Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.Unlock;
begin
//  FThreadSync.Unlock;
end; // Unlock


//------------------------------------------------------------------------------
// Create and Open File
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.CreateAndOpenFile(FileName: AnsiString; FileNameUnicode: WideString);
var
  SysErrorCode: DWORD;
begin
  CheckClosed('CreateFile');
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog('> TACRDatabaseFile.CreateAndOpenFile, FileName = ' +
      FileName + ', FileNameUnicode = ' + FileNameUnicode);
{$ENDIF}
  if ((FileName = '') and (FileNameUnicode = '')) then
    raise EACRException.Create(30374, ErrorGBlankFileName);

  FFileName := FileName;
  FFileNameUnicode := FileNameUnicode;
  FAccessMode := amReadWrite;
  FShareMode := smExclusive;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog('TACRDatabaseFile.CreateAndOpenFile starting... ' +
      ', FFileName = ' + FileName + ', AccessMode = ' + IntToStr
      (Integer(FAccessMode)) + ', ShareMode = ' + IntToStr
      (Integer(FShareMode)));
{$ENDIF}
{$IFDEF MSWINDOWS}
  if (FileNameUnicode = '') then
    FHandle := Windows.CreateFileA(PAnsiChar(@FFileName[1]),
      ConvertAccessMode(FAccessMode), ConvertShareMode(FShareMode),
      nil, CREATE_ALWAYS, FAttrFlags, 0)
  else
    FHandle := Windows.CreateFileW(PWideChar(@FFileNameUnicode[1]),
      ConvertAccessMode(FAccessMode), ConvertShareMode(FShareMode),
      nil, CREATE_ALWAYS, FAttrFlags, 0);
{$ENDIF}
{$IFDEF LINUX}
  FHandle := Integer(Libc.open(PAnsiChar(FFileName),
      ConvertAccessMode(FAccessMode)
        or ConvertShareMode(FShareMode)
        or O_ASYNC or O_TRUNC or O_CREAT, FileAccessRights));
{$ENDIF}
  if (FHandle = INVALID_HANDLE_VALUE) then
  begin
    SysErrorCode := GetLastError;
    raise EACRException.Create(30361, ErrorGCreateFileError,
      [FFileName, SysErrorCode, SysErrorMessage(SysErrorCode)]);
  end;
{$IFDEF LINUX}
  FSize := 0;
{$ENDIF}
  FIsOpened := True;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog('TACRDatabaseFile.CreateAndOpenFile starting... OK' +
      ', FFileName = ' + FileName + ', FHandle = ' + IntToStr
      (FHandle) + ', AccessMode = ' + IntToStr(Integer(FAccessMode))
      + ', ShareMode = ' + IntToStr(Integer(FShareMode)));
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog('< TACRDatabaseFile.CreateFile, FileName = ' +
      FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
      ', FHandle = ' + IntToStr(Integer(FHandle)));
{$ENDIF}
end; // CreateFile


//------------------------------------------------------------------------------
// Delete File
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.DeleteFile;
var
  SysErrorCode: DWORD;
begin
  CheckClosed('DeleteFile');
  if (FFileName <> '') then
    if not SysUtils.DeleteFile(PAnsiChar(FFileName)) then
    begin
      SysErrorCode := GetLastError;
      raise EACRException.Create(30362, ErrorGDeleteFileError,
        [FFileName, SysErrorCode, SysErrorMessage(SysErrorCode)]);
    end;
{$IFDEF MSWINDOWS}
  if (FFileNameUnicode <> '') then
    if not Windows.DeleteFileW(PWideChar(FFileNameUnicode)) then
    begin
      SysErrorCode := GetLastError;
      raise EACRException.Create(30362, ErrorGDeleteFileError,
        [FFileNameUnicode, SysErrorCode,
        SysErrorMessage(SysErrorCode)]);
    end;
{$ENDIF}
end; // DeleteFile


//------------------------------------------------------------------------------
// Rename Closed File
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.RenameFile(OldFileName,
  NewFileName: AnsiString);
var
  SysErrorCode: DWORD;
begin
  // CheckClosed('RenameFile');
  if not SysUtils.RenameFile(PAnsiChar(OldFileName),
    PAnsiChar(NewFileName)) then
  begin
    SysErrorCode := GetLastError;
    raise EACRException.Create(30378, ErrorGRenameFileError,
      [OldFileName, NewFileName, SysErrorCode,
      SysErrorMessage(SysErrorCode)]);
  end;
end; // RenameFile


//------------------------------------------------------------------------------
// Open File
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.OpenFile(FileName: AnsiString;
  FileNameUnicode: WideString; var AccessMode: TACRAccessMode;
  var ShareMode: TACRShareMode; SkipExistsCheck: Boolean);
var
  SysErrorCode: DWORD;
  attr: DWORD;
{$IFDEF MSWINDOWS}
  am: DWORD; // access mode
  sm: DWORD; // share mode

  procedure DoCreateFileWin;
  begin
    am := ConvertAccessMode(FAccessMode);
    sm := ConvertShareMode(FShareMode);
    if (FileNameUnicode = '') then
      FHandle := Windows.CreateFileA(PAnsiChar(@FFileName[1]), am,
        sm, nil, OPEN_EXISTING, FAttrFlags, 0)
    else
      FHandle := Windows.CreateFileW(PWideChar(@FFileNameUnicode[1]),
        am, sm, nil, OPEN_EXISTING, FAttrFlags, 0);
  end;
{$ENDIF}
{$IFDEF LINUX}
FileStat :
_stat;
{$ENDIF}
begin
  CheckClosed('OpenFile');
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog('> TACRDatabaseFile.OpenFile, FileName = ' +
      FileName + ', FileNameUnicode = ' + FileNameUnicode);
{$ENDIF}
  FFileName := FileName;
  FFileNameUnicode := FileNameUnicode;
  FAccessMode := AccessMode;
  FShareMode := ShareMode;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog
    ('TACRDatabaseFile.OpenFile checking if file exists... ' + ', FFileName = ' + FileName + ', AccessMode = ' + IntToStr(Integer(FAccessMode)) + ', ShareMode = ' + IntToStr(Integer(FShareMode)));
{$ENDIF}
  if (not SkipExistsCheck) then
    if (not ACRFileExists(FFileName, FFileNameUnicode)) then
    begin
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
      aaWriteToLog(
        'TACRDatabaseFile.OpenFile checking if file exists... FILE DOES NOT EXIST! '
          + ', FFileName = ' + FileName + ', AccessMode = ' +
          IntToStr(Integer(FAccessMode)) + ', ShareMode = ' + IntToStr
          (Integer(FShareMode)));
{$ENDIF}
      raise EACRException.Create(11351,
        ErrorLDatabaseFileDoesNotExists,
        [WideString(FFileName) + FFileNameUnicode]);
    end;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog('TACRDatabaseFile.OpenFile opening file... ' +
      ', FFileName = ' + FileName + ', AccessMode = ' + IntToStr
      (Integer(FAccessMode)) + ', ShareMode = ' + IntToStr
      (Integer(FShareMode)));
{$ENDIF}
{$IFDEF MSWINDOWS}
  DoCreateFileWin;
  // we always try to open in read-write access
  // to avoid Windows bug with read only access of files stored on network drive
  // that leads to poor performance
  if ((FHandle = INVALID_HANDLE_VALUE) and (FAccessMode = amReadWrite)
    ) then
  begin
    // try to open in read-only
    FAccessMode := amReadOnly;
    DoCreateFileWin;
  end;
{$ENDIF}
{$IFDEF LINUX}
  {
    if (Libc.stat64(PAnsiChar(FFileName), FileStat) = -1) then
    begin
    SysErrorCode := GetLastError;
    raise EACRException.Create(40018, ErrorRStatFileError,
    ['size', FFileName, SysErrorCode, SysErrorMessage(SysErrorCode)]);
    end;
    FSize := FileStat.st_size;
  }
  FHandle := Integer(Libc.open(PAnsiChar(FFileName),
      ConvertAccessMode(FAccessMode)
        or ConvertShareMode(FShareMode) or O_ASYNC,
      FileAccessRights));
{$ENDIF}
  if (FHandle = INVALID_HANDLE_VALUE) then
  begin
    SysErrorCode := GetLastError;
    raise EACRException.Create(30364, ErrorGOpenFileError,
      [WideString(FFileName) + FFileNameUnicode,
      SysErrorCode, SysErrorMessage(SysErrorCode)]);
  end;
{$IFDEF LINUX}
  if (Libc.fstat(FHandle, FileStat) = -1) then
  // if (Libc.stat64(PAnsiChar(FFileName), FileStat) = -1) then
  begin
    SysErrorCode := GetLastError;
    raise EACRException.Create(40018, ErrorRStatFileError,
      ['size', FFileName, SysErrorCode,
      SysErrorMessage(SysErrorCode)]);
  end;
  FSize := FileStat.st_size;
{$ENDIF}
  AccessMode := FAccessMode;
  ShareMode := FShareMode;
  FIsOpened := True;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog('TACRDatabaseFile.OpenFile finished ' +
      ', FFileName = ' + FileName + ', FHandle = ' + IntToStr
      (FHandle) + ', AccessMode = ' + IntToStr(Integer(FAccessMode))
      + ', ShareMode = ' + IntToStr(Integer(FShareMode)) + #13#10

    );
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog
    ('< TACRDatabaseFile.OpenFile, FileName = ' +
      FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
      ', FHandle = ' + IntToStr(Integer(FHandle)));
{$ENDIF}
end; // OpenFile


//------------------------------------------------------------------------------
// Close File
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.CloseFile;
var
  SysErrorCode: DWORD;
begin
  CheckOpened('CloseFile');
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog
    ('> TACRDatabaseFile.CloseFile, FileName = ' +
      FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
      ', FHandle = ' + IntToStr(Integer(FHandle)));
{$ENDIF}
  // FlushFileBuffers;
{$IFDEF MSWINDOWS}
  if (not Windows.CloseHandle(FHandle))
{$ENDIF}
{$IFDEF LINUX}
  if Libc.__close(FHandle) = -1 // No need to unlock since all locks are released on close.
{$ENDIF}
  then
  begin
    SysErrorCode := GetLastError;
    raise EACRException.Create(30365, ErrorGCloseFileError,
      [FFileName, SysErrorCode, SysErrorMessage(SysErrorCode)]);
  end;
{$IFDEF DEBUG_LOG_FILES}
  aaWriteToLog('File #' + IntToStr(Integer(FHandle)) + ' closed');
  aaWriteToLog('');
{$ENDIF}
  FHandle := INVALID_HANDLE_VALUE;
  FIsOpened := False;
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog
    ('< TACRDatabaseFile.CloseFile, FileName = ' +
      FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
      ', FHandle = ' + IntToStr(Integer(FHandle)));
{$ENDIF}
end; // CloseFile


//------------------------------------------------------------------------------
// Read Buffer
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.ReadBuffer(var Buffer; const Count, Pos: Int64; ErrorCode: Integer; DoLock: Boolean);
var
  // ALEX: Changed the following Windows code:
//  NumberOfBytesRead:  DWORD;
  SysErrorCode: DWORD;
  FileSize: Int64;
begin
{$IFDEF DEBUG_TRACE_FILE_FULL_LOG}
aaWriteToLog('RB'+#9+IntToStr(Pos)+#9+IntToStr(Count),'file_io_log.txt',True);
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
aaIncCounter(counter1);
aaIncCounter(counter2,Count);
if (Count = 4096) then
begin
  aaIncCounter(counter3);
  aaStartTime(time3);
end;
aaStartTime(time1);
try
{$ENDIF}
  CheckOpened('ReadBuffer');
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
aaWriteToLog('> TACRDatabaseFile.ReadBuffer, FileName = ' +
FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
', FHandle = ' + IntToStr(Integer(FHandle))
+ #13#10 + 'Count = ' + IntToStr(Count) + ', Pos = ' + IntToStr
(Pos)+#13#10+'Position = '+IntToStr(GetPosition));
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATABASE_FILE_READ_BUFFER}
aaWriteToLog('> TACRDatabaseFile.ReadBuffer, FileName = ' +
FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
', FHandle = ' + IntToStr(Integer(FHandle))
+ #13#10 + 'Count = ' + IntToStr(Count) + ', Pos = ' + IntToStr
(Pos)+#13#10+'Position = '+IntToStr(GetPosition));
{$ENDIF}
  if (DoLock) then
    Lock;
  try
    FileSize := GetSize;
    if (Pos + Count > FileSize) then
      raise EACRException.Create(11673, ErrorLCannotReadBeyondEOF,
        [Pos, Count, FileSize]);
    // Set Position
    Seek(Pos, ErrorCode);
    // Read Bytes
    // ALEX: Changed the following Windows code:
    // if not ReadFile(FHandle, Buffer, Count, NumberOfBytesRead, nil) then
    if SysUtils.FileRead(Integer(FHandle), Buffer, Count) = -1 then
      begin
        SysErrorCode := GetLastError;
        raise EACRException.Create(ErrorCode, ErrorGReadFileError,
          [FFileName, Pos, Count, Self.GetPosition, Self.GetSize,
          SysErrorCode, SysErrorMessage(SysErrorCode)]);
      end;
  finally
    if (DoLock) then
      Unlock;
  end;
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
aaWriteToLog('< TACRDatabaseFile.ReadBuffer, FileName = ' +
FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
', FHandle = ' + IntToStr(Integer(FHandle))
+ #13#10 + 'Count = ' + IntToStr(Count) + ', Pos = ' + IntToStr
(Pos)+#13#10+'Position = '+IntToStr(GetPosition));
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATABASE_FILE_READ_BUFFER}
aaWriteToLog('< TACRDatabaseFile.ReadBuffer, FileName = ' +
FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
', FHandle = ' + IntToStr(Integer(FHandle))
+ #13#10 + 'Count = ' + IntToStr(Count) + ', Pos = ' + IntToStr
(Pos)+#13#10+'Position = '+IntToStr(GetPosition));
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
finally
aaStopTime(time1);
if (Count = 4096) then
  aaStopTime(time3);
end;
{$ENDIF}
end; // ReadBuffer


//------------------------------------------------------------------------------
// Write Buffer
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.WriteBuffer(const Buffer;
  const Count, Pos: Int64; ErrorCode: Integer; DoLock: Boolean);
var
{$IFDEF DEBUG_LOG_FILES}
  str1: AnsiString;
{$ENDIF}
  // ALEX: Changed the following Windows code:
  // NumberOfBytesWritten: DWORD;
  SysErrorCode: DWORD;
begin
{$IFDEF DEBUG_TRACE_FILE_FULL_LOG}
aaWriteToLog('WB'+#9+IntToStr(Pos)+#9+IntToStr(Count),'file_io_log.txt',True);
{$ENDIF}
  CheckOpened('WriteBuffer');
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog('> TACRDatabaseFile.WriteBuffer, FileName = ' +
      FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
      ', FHandle = ' + IntToStr(Integer(FHandle))
      + #13#10 + 'Count = ' + IntToStr(Count) + ', Pos = ' + IntToStr
      (Pos)+#13#10+'Position = '+IntToStr(GetPosition));
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATABASE_FILE_WRITE_BUFFER}
  aaWriteToLog('> TACRDatabaseFile.WriteBuffer, FileName = ' +
      FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
      ', FHandle = ' + IntToStr(Integer(FHandle))
      + #13#10 + 'Count = ' + IntToStr(Count) + ', Pos = ' + IntToStr
      (Pos)+#13#10+'Position = '+IntToStr(GetPosition));
{$ENDIF}
  if (DoLock) then
    Lock;
  try
    // Set Position
    Seek(Pos, ErrorCode);
    // Write Count of bytes from Buffer
    // ALEX: Changed the following Windows code:
    // if not WriteFile(FHandle, Buffer, Count, NumberOfBytesWritten, nil) then
    if (SysUtils.FileWrite(Integer(FHandle), Buffer, Count) = -1) then
    begin
      SysErrorCode := GetLastError;
      raise EACRException.Create(ErrorCode, ErrorGWriteFileError,
        [FFileName, Pos, Count, Self.GetPosition, Self.GetSize,
        SysErrorCode, SysErrorMessage(SysErrorCode)]);
    end;

{$IFDEF LINUX}
    if ((Pos + Count) > FSize) then
      FSize := Pos + Count;
{$ENDIF}
  finally
    if (DoLock) then
      Unlock;
  end;
{$IFDEF DEBUG_TRACE_DATABASE_FILE_WRITE_BUFFER}
  aaWriteToLog('< TACRDatabaseFile.WriteBuffer, FileName = ' +
      FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
      ', FHandle = ' + IntToStr(Integer(FHandle))
      + #13#10 + 'Count = ' + IntToStr(Count)+ ', Pos = ' + IntToStr(Pos)+#13#10+'Position = '+IntToStr(GetPosition)
      );
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog('< TACRDatabaseFile.WriteBuffer, FileName = ' +
      FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
      ', FHandle = ' + IntToStr(Integer(FHandle))
      + #13#10 + 'Count = ' + IntToStr(Count)+ ', Pos = ' + IntToStr(Pos)+#13#10+'Position = '+IntToStr(GetPosition)
      );
{$ENDIF}
end; // WriteBuffer


//------------------------------------------------------------------------------
// Flush Buffers
//------------------------------------------------------------------------------
procedure TACRDatabaseFile.FlushFileBuffers;

var
  SysErrorCode: DWORD;
begin
{$IFDEF DEBUG_TRACE_FILE_FULL_LOG}
aaWriteToLog('FB','file_io_log.txt',True);
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog('> TACRDatabaseFile.FlushFileBuffers, FileName = ' +
      FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
      ', FHandle = ' + IntToStr(Integer(FHandle)));
{$ENDIF}
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog('TACRDatabaseFile.FlushFileBuffers starting ...' +
      ', FFileName = ' + FFileName);
{$ENDIF}
  CheckOpened('FlushFileBuffers');
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog('TACRDatabaseFile.FlushFileBuffers flushing...' +
      ', FFileName = ' + FFileName + 'FHandle = ' + IntToStr(FHandle)
    );
{$ENDIF}
{$IFDEF MSWINDOWS}
  if (not Windows.FlushFileBuffers(FHandle)) then
{$ENDIF}
{$IFDEF LINUX}
    // There is no need to flush buffers because the only low-level input and output
    // functions that operate on file descriptors are used.
    // If open with O_SYNC:
    if (Libc.fsync(FHandle) = -1) then
{$ENDIF}
    begin
      SysErrorCode := GetLastError;
      raise EACRException.Create(30379, ErrorGFlushFileBufferError,
        [FFileName, SysErrorCode, SysErrorMessage(SysErrorCode)]);
    end;
{$IFDEF DEBUG_LOG_CLOSE_DISK_DATABASE}
  aaWriteToLog('TACRDatabaseFile.FlushFileBuffers flushing... OK ' +
      ', FFileName = ' + FFileName + ', FHandle = ' + IntToStr
      (FHandle));
{$ENDIF}
{$IFDEF DEBUG_LOG_FILES}
  aaWriteToLog('FlushFileBuffers of file #' + IntToStr
      (Integer(FHandle)));
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog('< TACRDatabaseFile.FlushFileBuffers, FileName = ' +
      FFileName + ', FileNameUnicode = ' + FFileNameUnicode +
      ', FHandle = ' + IntToStr(Integer(FHandle)));
{$ENDIF}
end; // FlushFileBuffers


//------------------------------------------------------------------------------
// Lock Byte
//------------------------------------------------------------------------------
function TACRDatabaseFile.LockByte(Offset: Int64; Count: Integer;
  Exclusive: Boolean): Boolean;
{$IFDEF LINUX}
var
  LockP: TFLock;
{$ELSE}
var
  Overlapped: TOverlapped;
{$ENDIF}
{$IFDEF DEBUG_LOCK_BYTE_ZEROFILL}
var
  SgnOffset: Int64;
{$ENDIF}
begin
{$IFDEF DEBUG_TRACE_FILE_FULL_LOG}
aaWriteToLog('LB'+#9+IntToStr(Offset)+#9+IntToStr(Count)+#9+IntToStr(Integer(Exclusive)),'file_io_log.txt',True);
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
  aaStartTime(time4);
  aaIncCounter(counter4);
  try
{$ENDIF}
    CheckOpened('LockByte');
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
    aaWriteToLog('> TACRDatabaseFile.LockByte, FHandle = ' + IntToStr(Integer(FHandle))
        + #13#10 + 'Offset = ' + IntToStr(Offset)
        + ', Count = ' + IntToStr(Count)
        + ', Exclusive = ' + BoolToStr(Exclusive));
{$ENDIF}
{$IFDEF FILE_SERVER_VERSION}
    if (FShareMode = smExclusive) then
      Result := True
    else
    begin
{$IFDEF DEBUG_DO_NOT_LOCK_BYTES}
      Result := True;
      Exit;
{$ENDIF}
{$IFDEF MSWINDOWS}
{$IFDEF DEBUG_LOCKING_BYTES}
aaWriteToLog('> TACRDatabaseFile.LockByte, FHandle = ' + IntToStr(Integer(FHandle))
		+ #13#10 + 'Offset = ' + IntToStr(Offset)
    + ', Count = ' + IntToStr(Count)
    + ', Exclusive = ' + BoolToStr(Exclusive));
      try
{$ENDIF}
        // commented in v 5 - for better OS compatibility
//if (False) then
      if ( { (not Exclusive)and } ACR_OS_WINNT_COMPATIBLE) then
        begin
          FillChar(Overlapped, SizeOf(Overlapped), $00);
          Overlapped.Offset := Int64Rec(Offset).Lo;
          Overlapped.OffsetHigh := Int64Rec(Offset).Hi;
          // shared lock
{$IFDEF DEBUG_LOCKING_BYTES}
          aaWriteToLog('1 TACRDatabaseFile.LockByte - calling LockFileEx. Offset = '
              + IntToStr(Offset) + ', Count = ' + IntToStr(Count)
              + ', FHandle = ' + IntToStr(FHandle)
              + #13#10 + 'Exclusive = ' + BoolToStr(Exclusive,
              True) + #13#10 + 'ACR_OS_WINNT_COMPATIBLE = ' +
              BoolToStr(ACR_OS_WINNT_COMPATIBLE, True));
{$ENDIF}
          // Result := Windows.LockFileEx(FHandle, LOCKFILE_FAIL_IMMEDIATELY,0,
          // Count, 0, Overlapped);
{$IFDEF DEBUG_LOCK_BYTE_ZEROFILL}
          SgnOffset := GetOffsetToSignature(ACRDiskPageSignature,
            333);
          if (SgnOffset < 0) then
            aaWriteToLog
              ('Error before LockFileEx: Offset = ' + IntToStr
                (Offset) + ', Count = ' + IntToStr(Count)
                + ', SgnOffset = ' + IntToStr(SgnOffset)
                + ', FileSize = ' + IntToStr(GetSize))
          else
            aaWriteToLog('OK before LockFileEx: Offset = ' + IntToStr
                (Offset) + ', Count = ' + IntToStr(Count)
                + ', SgnOffset = ' + IntToStr(SgnOffset)
                + ', FileSize = ' + IntToStr(GetSize));
{$ENDIF}
          Result := Windows.LockFileEx(FHandle,
            LOCKFILE_FAIL_IMMEDIATELY or LOCKFILE_EXCLUSIVE_LOCK, 0,
            Count, 0, Overlapped);
{$IFDEF DEBUG_LOCK_BYTE_ZEROFILL}
          if (GetOffsetToSignature(ACRDiskPageSignature, 333) < 0)
            then
            aaWriteToLog
              ('Error after LockFileEx: Offset = ' + IntToStr
                (Offset) + ', Count = ' + IntToStr(Count)
                + ', SgnOffset = ' + IntToStr(SgnOffset)
                + ', FileSize = ' + IntToStr(GetSize)
                + ', Result = ' + BoolToStr(Result,
                True))
          else
            aaWriteToLog('OK after LockFileEx: Offset = ' + IntToStr
                (Offset) + ', Count = ' + IntToStr(Count)
                + ', SgnOffset = ' + IntToStr(SgnOffset)
                + ', FileSize = ' + IntToStr(GetSize)
                + ', Result = ' + BoolToStr(Result,
                True));
{$ENDIF}
        end
        else
        begin
{$IFDEF DEBUG_LOCKING_BYTES}
          aaWriteToLog('2 TACRDatabaseFile.LockByte - calling LockFile. Offset = '
              + IntToStr(Offset) + ', Count = ' + IntToStr(Count)
              + ', FHandle = ' + IntToStr(FHandle)
              + #13#10 + 'Exclusive = ' + BoolToStr(Exclusive,
              True) + #13#10 + 'ACR_OS_WINNT_COMPATIBLE = ' +
              BoolToStr(ACR_OS_WINNT_COMPATIBLE, True));
{$ENDIF}
          Result := Windows.LockFile(FHandle, Int64Rec(Offset).Lo,
            Int64Rec(Offset).Hi, Count, 0);

        end;
{$IFDEF DEBUG_LOCKING_BYTES}
        aaWriteToLog
          ('TACRDatabaseFile.LockByte Finished, Offset = ' + IntToStr
            (Offset) + ', Count = ' + IntToStr(Count)
            + ', FHandle = ' + IntToStr(FHandle)
            + ', Result = ' + BoolToStr(Result, True));
      except
        on E: Exception do
          aaWriteToLog
            ('TACRDatabaseFile.LockByte error, Offset = ' + IntToStr
              (Offset) + ', Count = ' + IntToStr(Count)
              + ', FHandle = ' + IntToStr(FHandle)
              + ', Eerror:' + #13#10 + E.Message)
        else
          aaWriteToLog
            ('TACRDatabaseFile.LockByte error, Offset = ' + IntToStr
              (Offset) + ', Count = ' + IntToStr(Count)
              + ', FHandle = ' + IntToStr(FHandle)
              + ', Unknown error!');
      end;
{$ENDIF}
{$ENDIF} // windows
{$IFDEF LINUX}

      begin
        LockP.l_type := F_WRLCK;
        LockP.l_whence := SEEK_SET;
        LockP.l_start := Offset;
        LockP.l_len := Int64(Count);
        if (Libc.fcntl(FHandle, F_SETLK, LockP) = -1) then
          Result := False
        else
          Result := True;
      end;
{$ENDIF}
    end;
{$ELSE}
    Result := True;
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
  finally
    aaStopTime(time4);
  end;
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog('< TACRDatabaseFile.LockByte, FHandle = ' + IntToStr
      (Integer(FHandle)) + #13#10 + 'Offset = ' + IntToStr(Offset)
      + ', Count = ' + IntToStr(Count) + ', Exclusive = ' + BoolToStr
      (Exclusive) + ', Result = ' + BoolToStr(Result));
{$ENDIF}
end; // LockByte


//------------------------------------------------------------------------------
// Unlock Byte
//------------------------------------------------------------------------------
function TACRDatabaseFile.UnlockByte(Offset: Int64; Count: Integer;
  Exclusive: Boolean): Boolean;
{$IFDEF LINUX}
var
  LockP: TFLock;
{$ELSE}
var
  Overlapped: TOverlapped;
{$ENDIF}
{$IFDEF DEBUG_UNLOCK_BYTE_ZEROFILL}
var
  SgnOffset: Int64;
{$ENDIF}
begin
{$IFDEF DEBUG_TRACE_FILE_FULL_LOG}
aaWriteToLog('UB'+#9+IntToStr(Offset)+#9+IntToStr(Count)+#9+IntToStr(Integer(Exclusive)),'file_io_log.txt',True);
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
 aaStartTime(time6);
aaIncCounter(counter6);
try
{$ENDIF}
  CheckOpened('UnlockByte');
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog('> TACRDatabaseFile.UnlockByte, FHandle = ' + IntToStr
      (Integer(FHandle)) + #13#10 + 'Offset = ' + IntToStr(Offset)
      + ', Count = ' + IntToStr(Count) + ', Exclusive = ' + BoolToStr
      (Exclusive));
{$ENDIF}
{$IFDEF FILE_SERVER_VERSION}
  if (FShareMode = smExclusive) then
    Result := True
  else
  begin
{$IFDEF DEBUG_DO_NOT_LOCK_BYTES}
    Result := True;
    Exit;
{$ENDIF}
{$IFDEF MSWINDOWS}
{$IFDEF DEBUG_LOCKING_BYTES}
    try
{$ENDIF}
//    if False Then
     if ( { (not Exclusive) and } ACR_OS_WINNT_COMPATIBLE) then
      begin
        FillChar(Overlapped, SizeOf(Overlapped), $00);
        Overlapped.Offset := Int64Rec(Offset).Lo;
        Overlapped.OffsetHigh := Int64Rec(Offset).Hi;
{$IFDEF DEBUG_LOCKING_BYTES}
        aaWriteToLog(#13#10 +
            'TACRDatabaseFile.UnlockByte - calling UnlockFileEx... Offset = '
            + IntToStr(Offset) + ', Count = ' + IntToStr(Count)
            + ', FHandle = ' + IntToStr(FHandle)
            + #13#10 + 'Exclusive = ' + BoolToStr(Exclusive,
            True) + #13#10 + 'ACR_OS_WINNT_COMPATIBLE = ' + BoolToStr
            (ACR_OS_WINNT_COMPATIBLE, True));
{$ENDIF}
{$IFDEF DEBUG_UNLOCK_BYTE_ZEROFILL}
        SgnOffset := GetOffsetToSignature(ACRDiskPageSignature, 333);
        if (SgnOffset < 0) then
          aaWriteToLog
            ('Error before UnockFileEx: Offset = ' + IntToStr
              (Offset) + ', Count = ' + IntToStr(Count)
              + ', SgnOffset = ' + IntToStr(SgnOffset)
              + ', FileSize = ' + IntToStr(GetSize))
        else
          aaWriteToLog('OK before UnlockFileEx: Offset = ' + IntToStr
              (Offset) + ', Count = ' + IntToStr(Count)
              + ', SgnOffset = ' + IntToStr(SgnOffset)
              + ', FileSize = ' + IntToStr(GetSize));
{$ENDIF}
        Result := Windows.UnlockFileEx(FHandle, 0, Count, 0,
          Overlapped);
{$IFDEF DEBUG_UNLOCK_BYTE_ZEROFILL}
        if (GetOffsetToSignature(ACRDiskPageSignature, 333) < 0) then
          aaWriteToLog
            ('Error after UnlockFileEx: Offset = ' + IntToStr
              (Offset) + ', Count = ' + IntToStr(Count)
              + ', SgnOffset = ' + IntToStr(SgnOffset)
              + ', FileSize = ' + IntToStr(GetSize)
              + ', Result = ' + BoolToStr(Result, True))
        else
          aaWriteToLog('OK after UnlockFileEx: Offset = ' + IntToStr
              (Offset) + ', Count = ' + IntToStr(Count)
              + ', SgnOffset = ' + IntToStr(SgnOffset)
              + ', FileSize = ' + IntToStr(GetSize)
              + ', Result = ' + BoolToStr(Result, True));
{$ENDIF}
      end
      else
      begin
{$IFDEF DEBUG_LOCKING_BYTES}
        aaWriteToLog(#13#10 +
            'TACRDatabaseFile.UnlockByte - calling UnlockFile... Offset = '
            + IntToStr(Offset) + ', Count = ' + IntToStr(Count)
            + ', FHandle = ' + IntToStr(FHandle)
            + #13#10 + 'Exclusive = ' + BoolToStr(Exclusive,
            True) + #13#10 + 'ACR_OS_WINNT_COMPATIBLE = ' + BoolToStr
            (ACR_OS_WINNT_COMPATIBLE, True));
{$ENDIF}
        Result := Windows.UnlockFile(FHandle, Int64Rec(Offset).Lo,
          Int64Rec(Offset).Hi, Count, 0);

      end;
{$IFDEF DEBUG_LOCKING_BYTES}
      aaWriteToLog
        ('TACRDatabaseFile.UnlockByte Finished. Offset = ' + IntToStr
          (Offset) + ', Count = ' + IntToStr(Count)
          + ', FHandle = ' + IntToStr(FHandle)
          + ', Result = ' + BoolToStr(Result, True));
    except
      on E: Exception do
        aaWriteToLog
          ('TACRDatabaseFile.UnlockByte error, Offset = ' + IntToStr
            (Offset) + ', Count = ' + IntToStr(Count)
            + ', FHandle = ' + IntToStr(FHandle)
            + ', Eerror:' + #13#10 + E.Message)
      else
        aaWriteToLog
          ('TACRDatabaseFile.UnlockByte error, Offset = ' + IntToStr
            (Offset) + ', Count = ' + IntToStr(Count)
            + ', FHandle = ' + IntToStr(FHandle)
            + ', Unknown error!');
    end;
{$ENDIF}
{$ENDIF} // windows
{$IFDEF LINUX}

    begin
      LockP.l_type := F_UNLCK;
      LockP.l_whence := SEEK_SET;
      LockP.l_start := Offset;
      LockP.l_len := Int64(Count);
      if (Libc.fcntl(FHandle, F_SETLK, LockP) = -1) then
        Result := False
      else
        Result := True;
    end;
{$ENDIF}
  end;
{$ELSE}
  Result := True;
{$ENDIF}
{$IFDEF DEBUG_TRACE_DATABASE_FILE}
  aaWriteToLog('< TACRDatabaseFile.UnlockByte, FHandle = ' + IntToStr
      (Integer(FHandle)) + #13#10 + 'Offset = ' + IntToStr(Offset)
      + ', Count = ' + IntToStr(Count) + ', Exclusive = ' + BoolToStr
      (Exclusive) + ', Result = ' + BoolToStr(Result));
{$ENDIF}
{$IFDEF DEBUG_LOCK_TIMES}
finally
aaStopTime(time6);
end;
{$ENDIF}
end; // UnlockByte


//------------------------------------------------------------------------------
// return TRUE if byte locked
//------------------------------------------------------------------------------
function TACRDatabaseFile.IsByteLocked(Offset: Int64): Boolean;
begin
{$IFDEF DEBUG_LOCK_TIMES}
  aaStartTime(time5);
  aaIncCounter(counter5);
  try
{$ENDIF}
    CheckOpened('IsByteLocked');
    Result := LockByte(Offset, 1, True);
    if Result then
      UnlockByte(Offset, 1, True);
    Result := not Result;
{$IFDEF DEBUG_LOCK_TIMES}
  finally
    aaStopTime(time5);
  end;
{$ENDIF}
end; // IsByteNotLocked


//------------------------------------------------------------------------------
// return FALSE if any byte of region is locked
//------------------------------------------------------------------------------
function TACRDatabaseFile.IsRegionLocked(Offset: Int64;
  Count: Integer): Boolean;
begin
{$IFDEF DEBUG_LOCK_TIMES}
  aaIncCounter(counter10);
  aaIncCounter(counter20, Count);
  aaStartTime(time10);
{$ENDIF}
  CheckOpened('IsRegionLocked');
  Result := LockByte(Offset, Count, True);
  if Result then
    UnlockByte(Offset, Count, True);
  Result := not Result;
{$IFDEF DEBUG_LOCK_TIMES}
  aaStopTime(time10);
{$ENDIF}
end; // IsByteRegionNotLocked


//------------------------------------------------------------------------------
// return true of db header is valid
//------------------------------------------------------------------------------
function TACRDatabaseFile.IsDBHeaderValid(Offset: Int64): Boolean;
var
  TempHeader: TACRDBHeader;
begin
  Result := False;
  if ((Offset + Int64(SizeOf(TempHeader))) < Self.Size) then
  begin
    Self.ReadBuffer(TempHeader, SizeOf(TempHeader), Offset, 11295);
    if (TempHeader.Signature = ACRDiskSignature) then
      if ((TempHeader.Version >= ACRMinVersion) and
          (TempHeader.Version <= ACRMaxVersion)) then
        Result := True;
  end;
end; // IsDBHeaderValid


//------------------------------------------------------------------------------
// return -1 if signature not found
//------------------------------------------------------------------------------
function TACRDatabaseFile.GetOffsetToSignature
  (const sgn: TACRSignature; StartOffset: Int64): Int64;
const
  BufSize = 4096;
var
  Size, Offset, Pos, i, j, k: Int64;
  buf: PAnsiChar;
begin
  Result := -1;
  Lock;
  try
    if (sgn = ACRDiskSignature) then
      if (IsDBHeaderValid(StartOffset)) then
      begin
        Result := 0;
        Exit;
      end;
    buf := MemoryManager.AllocMem(BufSize);
    try
      Offset := StartOffset;
      Self.Position := Offset;
      // find local file header for first file in archive
      while Self.Position < Self.Size do
      begin
        Pos := Self.Position;
        if (Self.Size - Self.Position > BufSize) then
          Size := BufSize
        else
          Size := Self.Size - Self.Position;
        Self.ReadBuffer(buf^, Size, Self.Position, 11293, False);
        // find local file header signature
        i := 0;
        k := -1;
        while (i < Size) do
        begin
          k := -1;
          if (PAnsiChar(buf + i)^ = sgn[0]) then
          begin
            j := 1;
            while j <= 3 do
            begin
              if ((i + j) >= Size) then
                break;
              if (PAnsiChar(buf + i + j)^ <> sgn[j]) then
                break;
              Inc(j);
              // signature found
              if (j > 3) then
                k := i;
            end; // check signature

            if (k >= 0) then
            begin
              if ((sgn = ACRDiskSignature) and
                  (IsDBHeaderValid(Pos + k))) then
                break
              else if (sgn = ACRDiskSignature) then
                k := -1
              else
                break;
            end;
          end; // signature found
          Inc(i);
        end; // end of searching local header
        // stub size = difference between supposed offset for header
        // and real one
        if (k >= 0) then
        begin
          Result := k + Pos - Offset;
          break;
        end;
      end;
    finally
      MemoryManager.FreeAndNilMem(buf);
    end;
  finally
    Unlock;
  end;
end; // GetOffsetToSignature


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRDatabaseFile> initialized');
{$ENDIF}
  ACRMemoryIncUseCount;

finalization

  ACRMemoryDecUseCount;


end.
