{$I ETblVer.inc}

unit ETblFileManage;


interface

uses classes, sysutils, windows, ESingleFileSystem,ESFSEngine, ETblConst;

type
 TaaFileStoreMode = (fsmDefault, fsmDisk, fsmESFS, fsmInMemory, fsmTemporary);


// forward specs
 TAbstractPlainFileSystem=class;

//------------------------------------------------------------------------------
// Parent class for all types of files
//------------------------------------------------------------------------------
 TAbstractFile=class
 protected
  FFileName:  AnsiString;
  FExclusive: boolean;
  FReadOnly:  boolean;
  FTemporary: boolean;

  // set exclusive mode
  procedure SetExclusive(value: boolean); virtual;
  // set file position
  procedure SetPosition(Pos: Longint); virtual;
  // get file position
  function GetPosition: Longint; virtual;
  // set read-only mode
  procedure SetReadOnly(value: boolean); virtual;
  // set file size
  procedure SetSize(value: Longint); virtual; abstract;
  // get file size
  function GetSize: Longint; virtual;
  // set temporary mode
  procedure SetTemporary(value: boolean); virtual;

 public
  FPFSHandle: TAbstractPlainFileSystem;

  // constructor
  constructor Create(PFSHandle: TAbstractPlainFileSystem;
                     FileName: AnsiString; bReadOnly, bExclusive: boolean);
  // destructor
  destructor Destroy; override;
  // copy form source file
  function CopyFrom(Source: TAbstractFile; Count: Longint): Longint;
  // close file
  procedure Close; virtual; abstract;
  // flush file buffers
  procedure FlushBuffers; virtual; abstract;
  // lock file
//  procedure Lock; virtual; abstract;
  // open file (with params specified in constructor)
  procedure Open(bCreate: boolean); virtual; abstract;
  // read from file
  function Read(var Buffer; Count: Longint): Longint; virtual; abstract;
  // read known bytes from file
  procedure ReadBuffer(var Buffer; Count: Longint);
  // seek in file
  function Seek(Offset: Longint; Origin: Word): Longint; virtual; abstract;
  // unlock file
//  procedure Unlock; virtual; abstract;
  // write into the file
  function Write(const Buffer; Count: Longint): Longint; virtual; abstract;
  // write known bytes into the file
  procedure WriteBuffer(const Buffer; Count: Longint);

 published
  // if true - file is in exclusive mode
  property Exclusive: Boolean read FExclusive write SetExclusive default False;
  // file name
  property FileName: AnsiString read FFileName write FFileName;
  // current position in file
  property Position: Longint read GetPosition write SetPosition default 0;
  // if true - file is in read only mode
  property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
  // size of file
  property Size: Longint read GetSize write SetSize default 0;
  // is temporary file?
  property Temporary: boolean read FTemporary write SetTemporary default False;
 end;


//------------------------------------------------------------------------------
// Disk file
//------------------------------------------------------------------------------
 TDiskFile=class(TAbstractFile)
 private
  FHandle: Integer; // file handle
  FDirectory: AnsiString; // work directory

  // reopen file (in a new mode)
  procedure Reopen;

 protected
  // internal open
  procedure InternalOpen(const FileName: AnsiString; bCreate: boolean);
  // set exclusive mode
  procedure SetExclusive(value: boolean); override;
  // set read-only mode
  procedure SetReadOnly(value: boolean); override;
  // set file size
  procedure SetSize(value: Longint); override;

 public
  // constructor
  constructor Create(PFSHandle: TAbstractPlainFileSystem;
                     FileName: AnsiString; bReadOnly, bExclusive: boolean);
  // close file
  procedure Close; override;
  // destructor
  destructor Destroy; override;
  // flush file buffers
  procedure FlushBuffers; override;
  // open file (with params specified in constructor)
  procedure Open(bCreate: boolean); override;
  // read from file
  function Read(var Buffer; Count: Longint): Longint; override;
  // seek in file
  function Seek(Offset: Longint; Origin: Word): Longint; override;
  // write into the file
  function Write(const Buffer; Count: Longint): Longint; override;

 published
  // if true - file is in exclusive mode
  property Exclusive: Boolean read FExclusive write SetExclusive default False;
  // file name
  property FileName: AnsiString read FFileName write FFileName;
  // if true - file is in read only mode
  property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
  // current position in file
  property Position: Longint read GetPosition write SetPosition default 0;
  // size of file
  property Size: Longint read GetSize write SetSize default 0;
 end;// TDiskFile


//------------------------------------------------------------------------------
// Memory file
//------------------------------------------------------------------------------
 TMemoryFile=class(TAbstractFile)
 private
  FStream: TMemoryStream; // to store file data

 protected
  // set file size
  procedure SetSize(value: Longint); override;

 public
  // constructor
  constructor Create(PFSHandle: TAbstractPlainFileSystem;
                     FileName: AnsiString; bReadOnly, bExclusive: boolean);
  // close file
  procedure Close; override;
  // destructor
  destructor Destroy; override;
  // flush file buffers
  procedure FlushBuffers; override;
  // open file (with params specified in constructor)
  procedure Open(bCreate: boolean); override;
  // read from file
  function Read(var Buffer; Count: Longint): Longint; override;
  // seek in file
  function Seek(Offset: Longint; Origin: Word): Longint; override;
  // write into the file
  function Write(const Buffer; Count: Longint): Longint; override;

 published
  // if true - file is in exclusive mode
  property Exclusive: Boolean read FExclusive write SetExclusive default False;
  // file name
  property FileName: AnsiString read FFileName write FFileName;
  // if true - file is in read only mode
  property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
  // current position in file
  property Position: Longint read GetPosition write SetPosition default 0;
  // size of file
  property Size: Longint read GetSize write SetSize default 0;
 end;// TMemoryFile


//------------------------------------------------------------------------------
// ESFS file
//------------------------------------------------------------------------------
 TESFSFile=class(TAbstractFile)
 private
  ESFSHandle: TESingleFileSystem;
  FHandle: Integer; // file handle
  FDirectory: AnsiString; // work directory
//esfsStream: TESFSFileStream;

  // reopen file (in a new mode)
  procedure Reopen;

 protected
  // internal open
  procedure InternalOpen(const FileName: AnsiString; bCreate: boolean);
  // set exclusive mode
  procedure SetExclusive(value: boolean); override;
  // set read-only mode
  procedure SetReadOnly(value: boolean); override;
  // set file size
  procedure SetSize(value: Longint); override;

 public
  // constructor
  constructor Create(ESFSHandle1: TESingleFileSystem; PFSHandle: TAbstractPlainFileSystem;
                     FileName: AnsiString; bReadOnly, bExclusive: boolean); overload;
  // close file
  procedure Close; override;
  // destructor
  destructor Destroy; override;
  // flush file buffers
  procedure FlushBuffers; override;
  // open file (with params specified in constructor)
  procedure Open(bCreate: boolean); override;
  // read from file
  function Read(var Buffer; Count: Longint): Longint; override;
  // seek in file
  function Seek(Offset: Longint; Origin: Word): Longint; override;
  // write into the file
  function Write(const Buffer; Count: Longint): Longint; override;

 published
  // if true - file is in exclusive mode
  property Exclusive: Boolean read FExclusive write SetExclusive default False;
  // file name
  property FileName: AnsiString read FFileName write FFileName;
  // if true - file is in read only mode
  property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
  // current position in file
  property Position: Longint read GetPosition write SetPosition default 0;
  // size of file
  property Size: Longint read GetSize write SetSize default 0;
 end;// TESFSFile



//------------------------------------------------------------------------------
// Abstract plain file system (directories not supported)
//------------------------------------------------------------------------------
 TAbstractPlainFileSystem=class(TObject)
 protected
  OpenFileList: TList; // list of opened files

 public
  DatabaseName: AnsiString;
  FileStoreMode: TaaFileStoreMode;

  // constructor
  constructor Create(NewDatabaseName: AnsiString; NewFileStoreMode: TaaFileStoreMode);
  // destructor
  destructor Destroy; override;
  // open or create file
  function OpenFile(FileName: AnsiString; bCreate, bExclusive, bReadOnly: boolean): TAbstractFile; virtual; abstract;
  // close file
  procedure CloseFile(FileHandle: TAbstractFile); virtual; abstract;
  // delete file
  function DeleteFile(const FileName: AnsiString): Boolean; virtual; abstract;
  // rename file
  function RenameFile(const OldName, NewName: AnsiString): Boolean; virtual; abstract;
  // is file exists
  function FileExists(const FileName: AnsiString): Boolean; virtual; abstract;
  // get files list with specified extension
  procedure GetFilesListByExt(Ext:AnsiString; List: TStrings); virtual; abstract;
  // returns open file or nil if not found
  function GetOpenFile(FileName: AnsiString): TAbstractFile;
 end;// TAbstractPlainFileSystem


//------------------------------------------------------------------------------
// Disk plain file system (directories not supported)
//------------------------------------------------------------------------------
 TDiskPlainFileSystem=class(TAbstractPlainFileSystem)
 protected
  FDirectory: AnsiString; // root directory

  // get name with path
  function GetFullFileName(FileName: AnsiString): AnsiString;

 public
  // constructor
  constructor Create(NewDatabaseName: AnsiString; NewFileStoreMode: TaaFileStoreMode);
  // open or create file
  function OpenFile(FileName: AnsiString; bCreate, bExclusive, bReadOnly: boolean): TAbstractFile; override;
  // close file
  procedure CloseFile(FileHandle: TAbstractFile); override;
  // delete file
  function DeleteFile(const FileName: AnsiString): Boolean; override;
  // rename file
  function RenameFile(const OldName, NewName: AnsiString): Boolean; override;
  // is file exists
  function FileExists(const FileName: AnsiString): Boolean; override;
  // get files list with specified extension
  procedure GetFilesListByExt(Ext: AnsiString; List: TStrings); override;

 published
  property Directory: AnsiString read FDirectory write FDirectory;
 end;// TDiskPlainFileSystem


//------------------------------------------------------------------------------
// Temporary plain file system (directories not supported)
//------------------------------------------------------------------------------
 TTemporaryPlainFileSystem=class(TDiskPlainFileSystem)
 public
  // open or create file
  function OpenFile(FileName: AnsiString; bCreate, bExclusive, bReadOnly: boolean): TAbstractFile; override;
  // close file
  procedure CloseFile(FileHandle: TAbstractFile); override;
  // delete file
  function DeleteFile(const FileName: AnsiString): Boolean; override;
  // rename file
  function RenameFile(const OldName, NewName: AnsiString): Boolean; override;

 published
  property Directory;
 end;


//------------------------------------------------------------------------------
// Memory plain file system (directories not supported)
//------------------------------------------------------------------------------
 TMemoryPlainFileSystem=class(TAbstractPlainFileSystem)
 public
  // open or create file
  function OpenFile(FileName: AnsiString; bCreate, bExclusive, bReadOnly: boolean): TAbstractFile; override;
  // close file
  procedure CloseFile(FileHandle: TAbstractFile); override;
  // delete file
  function DeleteFile(const FileName: AnsiString): Boolean; override;
  // rename file
  function RenameFile(const OldName, NewName: AnsiString): Boolean; override;
  // is file exists
  function FileExists(const FileName: AnsiString): Boolean; override;
  // get files list with specified extension
  procedure GetFilesListByExt(Ext: AnsiString; List: TStrings); override;
 end;// TMemoryPlainFileSystem


//------------------------------------------------------------------------------
// ESingleFileSystem plain file system (directories not supported)
//------------------------------------------------------------------------------
 TESFSPlainFileSystem=class(TAbstractPlainFileSystem)
 protected
  FReadOnly: boolean;
  FInMemory: boolean;

  // in memory mode
  procedure SetInMemory(Value: Boolean);

 public
  ESFSHandle: TESingleFileSystem;
  // constructor
  constructor Create(NewDatabaseName, Password: AnsiString; NewFileStoreMode: TaaFileStoreMode;
                     DatabaseFileMode: TDatabaseFileMode;
                     ReadOnly: boolean; InMemory: boolean;
                     bCreate: boolean);
  // destructor
  destructor Destroy; override;
  // open or create file
  function OpenFile(FileName: AnsiString; bCreate, bExclusive, bReadOnly: boolean): TAbstractFile; override;
  // close file
  procedure CloseFile(FileHandle: TAbstractFile); override;
  // delete file
  function DeleteFile(const FileName: AnsiString): Boolean; override;
  // rename file
  function RenameFile(const OldName, NewName: AnsiString): Boolean; override;
  // is file exists
  function FileExists(const FileName: AnsiString): Boolean; override;
  // get files list with specified extension
  procedure GetFilesListByExt(Ext: AnsiString; List: TStrings); override;

  // repairs file, returns true if repair is successful
  // if some errors were found, source file will have same name + '.bak'
  // if result = false then source file is unchanged, repair failed
  // if bSkipBadFiles = true it means that all files with errors will be deleted,
  // otherwise they will be rewritten with correct CRC, but with damaged data
//	function RepairESFS(var log: AnsiString; DeleteCorruptedFiles: Boolean = false): Boolean;
 published
  property ReadOnly: Boolean read FReadOnly write FReadOnly;
  property InMemory: Boolean read FInMemory write SetInMemory;
 end;// TESFSPlainFileSystem


 // Plain File Systems manager
 TPFSManager = class(TObject)
 private
  PFSList:         TList; // list of PFS objects
  FLockSection:    Pointer;
  FLockCount:      Integer;

 public
  // create manager
  constructor Create;
  // destroy manager
  destructor Destroy; override;
  // locks (thread-safe)
  procedure LockSection;
  // unlocks section (thread-safe)
  procedure UnlockSection;
  // find PFS
  function FindPFS(DatabaseName: AnsiString; FileStoreMode: TaaFileStoreMode;
                   ESFSInMemory: boolean): TAbstractPlainFileSystem;
  // get PFS handle (find or create object)
  function GetPFSHandle(DatabaseName, Password: AnsiString; FileStoreMode: TaaFileStoreMode;
                        var ESFSReadOnly: boolean; ESFSInMemory: boolean;
                        DatabaseFileMode: TDatabaseFileMode = dfmNormal
                        ): TAbstractPlainFileSystem;
  // close PFS with ESFS on disk or in memory
  procedure ClosePhysESFS(DatabaseName: AnsiString; InMemory: boolean);
  // create PFS with ESFS on disk or in memory
  function CreatePhysESFS(DatabaseName, Password: AnsiString; 
                                   InMemory: boolean;
                                   DatabaseFileMode: TDatabaseFileMode
            ): boolean;
  // delete PFS on disk or in memory
  function DeletePhysESFS(DatabaseName: AnsiString; InMemory: boolean): boolean;
  // repair PFS on disk or in memory
//  function RepairPhysESFS(DatabaseName: AnsiString; InMemory: boolean; var log: AnsiString; DeleteCorruptedFiles: boolean): boolean;
  // rename PFS on disk or in memory
  function RenamePhysESFS(DatabaseName: AnsiString; InMemory: boolean; const NewDatabaseName: AnsiString): boolean;
  // copy PFS on disk or in memory
  function CopyPhysESFS(DatabaseName: AnsiString; InMemory: boolean; const NewDatabaseName: AnsiString): boolean;
 end;


implementation

uses ETblEngine;

////////////////////////////////////////////////////////////////////////////////
//
//   TAbstractFile
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// set exclusive mode
//------------------------------------------------------------------------------
procedure TAbstractFile.SetExclusive(value: boolean);
begin
 FExclusive := value;
end;// TAbstractFile.SetExclusive


//------------------------------------------------------------------------------
// get file position
//------------------------------------------------------------------------------
function TAbstractFile.GetPosition: Longint;
begin
  Result := Seek(0, 1);
end;// GetPosition


//------------------------------------------------------------------------------
// set file position
//------------------------------------------------------------------------------
procedure TAbstractFile.SetPosition(Pos: Longint);
begin
  Seek(Pos, 0);
end;// SetPosition


//------------------------------------------------------------------------------
// set read-only mode
//------------------------------------------------------------------------------
procedure TAbstractFile.SetReadOnly(value: boolean);
begin
 FReadOnly := value;
end;// TAbstractFile.SetReadOnly


//------------------------------------------------------------------------------
// get file size
//------------------------------------------------------------------------------
function TAbstractFile.GetSize: Longint;
var
  Pos: Longint;
begin
  Pos := Seek(0, 1);
  Result := Seek(0, 2);
  Seek(Pos, 0);
end;// TAbstractFile.GetSize


//------------------------------------------------------------------------------
// set temporary mode
//------------------------------------------------------------------------------
procedure TAbstractFile.SetTemporary(value: boolean);
begin
 FTemporary := value;
end;// TAbstractFile.SetTemporary


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TAbstractFile.Create(PFSHandle: TAbstractPlainFileSystem;
                     FileName: AnsiString; bReadOnly, bExclusive: boolean);
begin
 FPFSHandle := PFSHandle;
 FFileName := FileName;
 FReadOnly := bReadOnly;
 FExclusive := bExclusive;
end;// TAbstractFile.Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TAbstractFile.Destroy;
begin
 // exclude from file system open files list
 FPFSHandle.OpenFileList.Remove(self);
end;// Destroy;


//------------------------------------------------------------------------------
// copy form source file
//------------------------------------------------------------------------------
function TAbstractFile.CopyFrom(Source: TAbstractFile; Count: Longint): Longint;
const
  MaxBufSize = $F000;
var
  BufSize, N: Integer;
  Buffer: PAnsiChar;
begin
  if Count = 0 then
  begin
    Source.Position := 0;
    Count := Source.Size;
  end;
  Result := Count;
  if Count > MaxBufSize then BufSize := MaxBufSize else BufSize := Count;
  GetMem(Buffer, BufSize);
  try
    while Count <> 0 do
    begin
      if Count > BufSize then N := BufSize else N := Count;
      Source.ReadBuffer(Buffer^, N);
      WriteBuffer(Buffer^, N);
      Dec(Count, N);
    end;
  finally
    FreeMem(Buffer, BufSize);
  end;
end;// TAbstractFile.CopyFrom


//------------------------------------------------------------------------------
// read known bytes from file
//------------------------------------------------------------------------------
procedure TAbstractFile.ReadBuffer(var Buffer; Count: Longint);
begin
  if (Count <> 0) and (Read(Buffer, Count) <> Count) then
    raise Exception.Create('TAbstractFile.ReadBuffer - Stream read error');
end;// TAbstractFile.ReadBuffer


//------------------------------------------------------------------------------
// write known bytes into the file
//------------------------------------------------------------------------------
procedure TAbstractFile.WriteBuffer(const Buffer; Count: Longint);
begin
  if (Count <> 0) and (Write(Buffer, Count) <> Count) then
    raise Exception.Create('TAbstractFile.WriteBuffer - Stream write error');
end;// TAbstractFile.WriteBuffer



////////////////////////////////////////////////////////////////////////////////
//
//   TDiskFile
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// reopen file (in a new mode)
//------------------------------------------------------------------------------
procedure TDiskFile.Reopen;
var pos: Longint;
begin
 pos := Position;
 Close;
 Open(false);
 Position := pos;
end;// TDiskFile.Reopen


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TDiskFile.Create(PFSHandle: TAbstractPlainFileSystem;
                     FileName: AnsiString; bReadOnly, bExclusive: boolean);

begin
 inherited Create(PFSHandle, FileName, bReadOnly, bExclusive);
 FDirectory := TDiskPlainFileSystem(FPFSHandle).Directory;
 FHandle := -1;
end;// TDiskFile.Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TDiskFile.Destroy;
begin
 Close;
 inherited Destroy;
end;// TDiskFile.Destroy


//------------------------------------------------------------------------------
// internal open
//------------------------------------------------------------------------------
procedure TDiskFile.InternalOpen(const FileName: AnsiString; bCreate: boolean);
const
  AccessMode: array[0..2] of LongWord = (
    GENERIC_READ,
    GENERIC_WRITE,
    GENERIC_READ or GENERIC_WRITE);
  ShareMode: array[0..4] of LongWord = (
    0,
    0,
    FILE_SHARE_READ,
    FILE_SHARE_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE);
var
   CreateDistribution: DWORD;
	 Flags: DWORD;
   FullFileName: AnsiString;
   TempFileName: array [0..255] of AnsiChar;
   Mode: Word;
begin
  Flags := FILE_FLAG_RANDOM_ACCESS{ or FILE_FLAG_WRITE_THROUGH};
	if FTemporary then
		Flags := (Flags or FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_DELETE_ON_CLOSE)
	else
		Flags := (Flags or FILE_ATTRIBUTE_NORMAL);

  if bCreate then
   CreateDistribution := CREATE_ALWAYS
  else
   CreateDistribution := OPEN_EXISTING;

  Mode := 0;
  if FReadOnly then
     Mode := Mode or fmOpenRead
  else
     Mode := Mode or fmOpenReadWrite;
  if FExclusive then
     Mode := Mode or fmShareExclusive
  else
     Mode := Mode or fmShareDenyNone;
  FullFileName := FDirectory+FileName;
  StrPCopy(@TempFileName, FullFileName);
  FHandle := Integer(Windows.CreateFileA(PAnsiChar(@TempFileName), AccessMode[Mode and 3],
    ShareMode[(Mode and $F0) shr 4], nil, CreateDistribution,
    Flags, 0));

  if bCreate then
  begin
    if FHandle < 0 then
      raise Exception.Create('Cannot create file "'+FullFileName+'"');
  end else
  begin
    if FHandle < 0 then
     if (FReadOnly) then
      raise Exception.Create('Cannot open file "'+FullFileName+'"')
     else
      begin
       // try to open in read only mode
       FReadOnly := true;
       try
        InternalOpen(FileName, bCreate);
       except
        FReadOnly := false;
        raise Exception.Create('Cannot open file "'+FullFileName+'"')
       end;
      end;
  end;
end;// TDiskFile.InternalOpen


//------------------------------------------------------------------------------
// flush file buffers
//------------------------------------------------------------------------------
procedure TDiskFile.FlushBuffers;
begin
  FlushFileBuffers(FHandle);
end;// TDiskFile.FlushBuffers;


//------------------------------------------------------------------------------
// set read-only mode
//------------------------------------------------------------------------------
procedure TDiskFile.SetReadOnly(value: boolean);
begin
 if (FReadOnly <> value) then
  begin
   FReadOnly := value;
   Reopen;
  end;
end;// TDiskFile.SetReadOnly


//------------------------------------------------------------------------------
// set file size
//------------------------------------------------------------------------------
procedure TDiskFile.SetSize(value: Longint);
begin
  Seek(value, soFromBeginning);
  Win32Check(SetEndOfFile(FHandle));
end;// TDiskFile.SetSize


//------------------------------------------------------------------------------
// set exclusive mode
//------------------------------------------------------------------------------
procedure TDiskFile.SetExclusive(value: boolean);
begin
 if (FExclusive <> value) then
  begin
   FExclusive := value;
   Reopen;
  end;
end;// TDiskFile.SetExclusive


//------------------------------------------------------------------------------
// open file
//------------------------------------------------------------------------------
procedure TDiskFile.Open(bCreate: boolean);
begin
 InternalOpen(FFileName, bCreate);
end;// TDiskFile.Open


//------------------------------------------------------------------------------
// close file
//------------------------------------------------------------------------------
procedure TDiskFile.Close;
begin
  if FHandle >= 0 then
   begin
    FlushBuffers;
    FileClose(FHandle);
   end;
  FHandle := -1;
end;// TDiskFile.Close;


//------------------------------------------------------------------------------
// read from file
//------------------------------------------------------------------------------
function TDiskFile.Read(var Buffer; Count: Longint): Longint;
begin
 Result:=FileRead(FHandle,Buffer,Count);
end;// TDiskFile.Read


//------------------------------------------------------------------------------
// seek in file
//------------------------------------------------------------------------------
function TDiskFile.Seek(Offset: Longint; Origin: Word): Longint;
begin
  Result := FileSeek(FHandle, Offset, Origin);
end;// TDiskFile.Seek


//------------------------------------------------------------------------------
// write into the file
//------------------------------------------------------------------------------
function TDiskFile.Write(const Buffer; Count: Longint): Longint;
begin
 Result := 0;
 if (Count = 0) then
   SetEndOfFile(FHandle)
 else
   Result := FileWrite(FHandle, Buffer, Count);
end;// TDiskFile.Write



////////////////////////////////////////////////////////////////////////////////
//
//   TMemoryFile
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TMemoryFile.Create(PFSHandle: TAbstractPlainFileSystem;
                   FileName: AnsiString; bReadOnly, bExclusive: boolean);
begin
 inherited Create(PFSHandle, FileName, bReadOnly, bExclusive);
 FStream := nil;
end;// TMemoryFile.Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TMemoryFile.Destroy;
begin
 Close;
 inherited Destroy;
end;// TMemoryFile.Destroy


//------------------------------------------------------------------------------
// flush file buffers
//------------------------------------------------------------------------------
procedure TMemoryFile.FlushBuffers;
begin
; // do nothing
end;// TMemoryFile.FlushBuffers;


//------------------------------------------------------------------------------
// set file size
//------------------------------------------------------------------------------
procedure TMemoryFile.SetSize(value: Longint);
begin
try
  FStream.SetSize(value);
except
 raise;
end;
end;// TMemoryFile.SetSize


//------------------------------------------------------------------------------
// open file
//------------------------------------------------------------------------------
procedure TMemoryFile.Open(bCreate: boolean);
begin
 if (not bCreate) then
  raise Exception.Create('TMemoryFile.Open - File cannot be open, only creation is available.');
 FStream := TMemoryStream.Create;
end;// TMemoryFile.Open


//------------------------------------------------------------------------------
// close file
//------------------------------------------------------------------------------
procedure TMemoryFile.Close;
begin
  if FStream <> nil then
   FStream.Free;
  FStream := nil;
end;// TMemoryFile.Close;


//------------------------------------------------------------------------------
// read from file
//------------------------------------------------------------------------------
function TMemoryFile.Read(var Buffer; Count: Longint): Longint;
begin
 Result := FStream.Read(Buffer, Count);
end;// TMemoryFile.Read


//------------------------------------------------------------------------------
// seek in file
//------------------------------------------------------------------------------
function TMemoryFile.Seek(Offset: Longint; Origin: Word): Longint;
begin
try
  Result := FStream.Seek(Offset, Origin);
except
 raise;
end;
end;// TMemoryFile.Seek


//------------------------------------------------------------------------------
// write into the file
//------------------------------------------------------------------------------
function TMemoryFile.Write(const Buffer; Count: Longint): Longint;
begin
try
 Result := FStream.Write(Buffer, Count);
except
 raise;
end;
end;// TMemoryFile.Write



////////////////////////////////////////////////////////////////////////////////
//
//   TESFSFile
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// reopen file (in a new mode)
//------------------------------------------------------------------------------
procedure TESFSFile.Reopen;
var pos: Longint;
begin
 pos := Position;
 Close;
 Open(false);
 Position := pos;
end;// TESFSFile.Reopen 
 
	
//------------------------------------------------------------------------------ 
// constructor
//------------------------------------------------------------------------------
constructor TESFSFile.Create(ESFSHandle1: TESingleFileSystem; PFSHandle: TAbstractPlainFileSystem; 
                     FileName: AnsiString; bReadOnly, bExclusive: boolean);
 
begin
 inherited Create(PFSHandle, FileName, bReadOnly, bExclusive); 
 ESFSHandle := ESFSHandle1;
 FDirectory := ''; 
 FHandle := -1; 
//esfsStream := nil; 
end;// TESFSFile.Create
	
	
//------------------------------------------------------------------------------ 
// destructor 
//------------------------------------------------------------------------------ 
destructor TESFSFile.Destroy;
begin 
 Close;
 inherited Destroy;
end;// TESFSFile.Destroy 
	
 
//------------------------------------------------------------------------------
// internal open 
//------------------------------------------------------------------------------ 
procedure TESFSFile.InternalOpen(const FileName: AnsiString; bCreate: boolean);
var 
   FullFileName: AnsiString;
   Mode: Word; 
begin
  Mode := 0;
  if FReadOnly then 
     Mode := Mode or fmOpenRead
  else
     Mode := Mode or fmOpenReadWrite;
  if FExclusive then
     Mode := Mode or fmShareExclusive
  else 
     Mode := Mode or fmShareDenyNone;
  FullFileName := FDirectory+FileName;
  if (bCreate) then
    Mode := fmCreate;
{ 
try
esfsStream := TESFSFileStream.Create(ESFSHandle,FullFileName,Mode); 
except
 esfsStream := nil;
end;
}
  FHandle := ESFSHandle.FileOpen(FullFileName, Mode); 
  if bCreate then
  begin 
    if FHandle < 0 then 
//     if (esfsStream = nil) then
      raise Exception.Create('Cannot create file "'+FullFileName+'"'); 
  end else 
  begin
//     if (esfsStream = nil) then
    if FHandle < 0 then
     if (FReadOnly) then 
      raise Exception.Create('Cannot open file "'+FullFileName+'"')
     else 
      begin 
       // try to open in read only mode
       FReadOnly := true; 
       try
        InternalOpen(FileName, bCreate); 
       except 
        FReadOnly := false; 
        raise Exception.Create('Cannot open file "'+FullFileName+'"') 
       end;
      end;
  end; 
end;// TESFSFile.InternalOpen
 
	
//------------------------------------------------------------------------------ 
// flush file buffers 
//------------------------------------------------------------------------------
procedure TESFSFile.FlushBuffers;
begin
  ESFSHandle.FlushFileBuffers(FHandle); 
end;// TESFSFile.FlushBuffers;
	
 
//------------------------------------------------------------------------------ 
// set read-only mode 
//------------------------------------------------------------------------------
procedure TESFSFile.SetReadOnly(value: boolean);
begin
 if (FReadOnly <> value) then
  begin 
   FReadOnly := value;
   Reopen; 
  end; 
end;// TESFSFile.SetReadOnly 
	
 
//------------------------------------------------------------------------------ 
// set file size
//------------------------------------------------------------------------------ 
procedure TESFSFile.SetSize(value: Longint);
begin
//  Seek(Value,0);
  ESFSHandle.FileSetSize(FHandle, value);
end;// TESFSFile.SetSize
	
 
//------------------------------------------------------------------------------ 
// set exclusive mode 
//------------------------------------------------------------------------------ 
procedure TESFSFile.SetExclusive(value: boolean);
begin
 if (FExclusive <> value) then
  begin 
   FExclusive := value; 
   Reopen; 
  end; 
end;// TESFSFile.SetExclusive
 
	
//------------------------------------------------------------------------------ 
// open file
//------------------------------------------------------------------------------
procedure TESFSFile.Open(bCreate: boolean);
begin
 InternalOpen(FFileName, bCreate);
end;// TESFSFile.Open


//------------------------------------------------------------------------------
// close file
//------------------------------------------------------------------------------
procedure TESFSFile.Close;
begin
{
if esfsStream <> nil then
 begin
  esfsStream.Free;
  esfsStream := nil;
 end;
}

  if FHandle >= 0 then
   begin
    FlushBuffers;
    ESFSHandle.FileClose(FHandle);
   end;
  FHandle := -1;

end;// TESFSFile.Close;


//------------------------------------------------------------------------------
// read from file
//------------------------------------------------------------------------------
function TESFSFile.Read(var Buffer; Count: Longint): Longint;
begin
 Result:=ESFSHandle.FileRead(FHandle,Buffer,Count);
// Result := esfsStream.Read(Buffer,Count);
end;// TESFSFile.Read


//------------------------------------------------------------------------------
// seek in file
//------------------------------------------------------------------------------
function TESFSFile.Seek(Offset: Longint; Origin: Word): Longint;
begin
  Result := ESFSHandle.FileSeek(FHandle, Offset, Origin);
// Result := esfsStream.Seek(Offset,Origin);
end;// TESFSFile.Seek


//------------------------------------------------------------------------------
// write into the file
//------------------------------------------------------------------------------
function TESFSFile.Write(const Buffer; Count: Longint): Longint;
begin
 Result := ESFSHandle.FileWrite(FHandle, Buffer, Count);
// Result := esfsStream.Write(Buffer,Count);
end;// TESFSFile.Write



////////////////////////////////////////////////////////////////////////////////
//
//   TAbstractPlainFileSystem
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TAbstractPlainFileSystem.Create(NewDatabaseName: AnsiString; NewFileStoreMode: TaaFileStoreMode);
begin
 DatabaseName := NewDatabaseName;
 FileStoreMode := NewFileStoreMode;
 OpenFileList := TList.Create;
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TAbstractPlainFileSystem.Destroy;
begin
 // destroy/close all opened files
 // (destructor automatically extracts from list)
 while OpenFileList.Count > 0 do
  TAbstractFile(OpenFileList.Items[0]).Free;
 OpenFileList.Free;
 inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// returns open file or nil if not found
//------------------------------------------------------------------------------
function TAbstractPlainFileSystem.GetOpenFile(FileName: AnsiString): TAbstractFile;
var
    i: integer;
begin
 result := nil;
 // check all open files
 for i:=0 to OpenFileList.Count-1 do
  if (AnsiLowerCase(TAbstractFile(OpenFileList.Items[i]).FileName) =
      AnsiLowerCase(FileName)) then
    begin
     result := TAbstractFile(OpenFileList.Items[i]);
     break;
    end;
end;// GetOpenFile



////////////////////////////////////////////////////////////////////////////////
//
//   TDiskPlainFileSystem
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// get name with path
//------------------------------------------------------------------------------
function TDiskPlainFileSystem.GetFullFileName(FileName: AnsiString): AnsiString;
var
    FullFileName: AnsiString;
begin
 // get name with path
 if ((FDirectory <> '') and (not IsDelimiter('\', FDirectory, Length(FDirectory)))) then
  FullFileName := FDirectory+'\'+FileName
 else
  FullFileName := FDirectory+FileName;
 result := FullFileName;
end;// GetFullFileName


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TDiskPlainFileSystem.Create(NewDatabaseName: AnsiString; NewFileStoreMode: TaaFileStoreMode);
begin
 inherited Create(NewDatabaseName, NewFileStoreMode);
 FDirectory := NewDatabaseName;
 // empty db name <=> current folder
 if (FDirectory <> '') then
//  FDirectory := GetCurrentDir;
 if (not IsDelimiter('\', FDirectory, Length(FDirectory))) then
  FDirectory := FDirectory+'\';
end;// Create


//------------------------------------------------------------------------------
// open or create file
//------------------------------------------------------------------------------
function TDiskPlainFileSystem.OpenFile(FileName: AnsiString; bCreate, bExclusive, bReadOnly: boolean): TAbstractFile;
var
    FHandle: TAbstractFile;
    df: TDiskFile;
begin
 // check if not already open
 FHandle := GetOpenFile(FileName);
 if (FHandle <> nil) then
   raise Exception.Create('TDiskPlainFileSystem.OpenFile - File "'+
                          GetFullFileName(FileName)+'" is already open.');
 // create disk file object
 df := TDiskFile.Create(Self, FileName, bReadOnly, bExclusive);
 // open / create file
 df.Open(bCreate);
 // store to list of open files
 OpenFileList.Add(df);
 result := df;
end;// OpenFile


//------------------------------------------------------------------------------
// close file
//------------------------------------------------------------------------------
procedure TDiskPlainFileSystem.CloseFile(FileHandle: TAbstractFile);
begin
 FileHandle.Free;
end;// Close


//------------------------------------------------------------------------------
// delete file
//------------------------------------------------------------------------------
function TDiskPlainFileSystem.DeleteFile(const FileName: AnsiString): Boolean;
begin
 result := SysUtils.DeleteFile(GetFullFileName(FileName));
end;// DeleteFile


//------------------------------------------------------------------------------
// rename file
//------------------------------------------------------------------------------
function TDiskPlainFileSystem.RenameFile(const OldName, NewName: AnsiString): Boolean;
begin
 result := SysUtils.RenameFile(GetFullFileName(OldName),GetFullFileName(NewName));
end;// RenameFile


//------------------------------------------------------------------------------
// is file exists
//------------------------------------------------------------------------------
function TDiskPlainFileSystem.FileExists(const FileName: AnsiString): Boolean;
begin
 result := SysUtils.FileExists(GetFullFileName(FileName));
end;// FileExists


//------------------------------------------------------------------------------
// get files list with specified extension
//------------------------------------------------------------------------------
procedure TDiskPlainFileSystem.GetFilesListByExt(Ext: AnsiString; List: TStrings);
var sr : TSearchRec;
    filter, s: AnsiString;
begin
 List.Clear;
 if ((FDirectory <> '') and (not IsDelimiter('\', FDirectory, Length(FDirectory)))) then
  filter := FDirectory+'\*'+Ext
 else
  filter := FDirectory+'*'+Ext;
 if (FindFirst(filter,faAnyFile,sr) <> 0) then
   SysUtils.FindClose(sr)
 else
  begin
   repeat
    if ((sr.Attr and faDirectory) = 0) then
     begin
      // remove extension
      s := ExtractFileName(sr.Name);
      s := Copy(s,1,Length(s)-Length(ExtractFileExt(s)));
      List.Add(s);
     end;
   until (FindNext(sr) <> 0);
   SysUtils.FindClose(sr);
  end;
end;// GetFilesListByExt



////////////////////////////////////////////////////////////////////////////////
//
//   TTemporaryPlainFileSystem
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// open or create file
//------------------------------------------------------------------------------
function TTemporaryPlainFileSystem.OpenFile(FileName: AnsiString; bCreate, bExclusive, bReadOnly: boolean): TAbstractFile;
var
    FHandle: TAbstractFile;
    df: TDiskFile;
begin
 df := nil;
 FHandle := GetOpenFile(FileName);
 if (FHandle <> nil) then
   begin
     df := TDiskFile(FHandle);
     // if create - clear previous content
     if (bCreate) then
      df.Size := 0;
     // positions to start
     df.Position := 0;
   end;
 // if not found then create
 if (df <> nil) then
  begin
   // create disk file object
   df := TDiskFile.Create(Self, FileName, bReadOnly, bExclusive);
   // set temporary property
   df.Temporary := true;
   // open / create file
   df.Open(bCreate);
  end;
 // store to list of open files
 OpenFileList.Add(df);
 result := df;
end;// OpenFile


//------------------------------------------------------------------------------
// close file
//------------------------------------------------------------------------------
procedure TTemporaryPlainFileSystem.CloseFile(FileHandle: TAbstractFile);
begin
; // do nothing
end;// CloseFile


//------------------------------------------------------------------------------
// delete file
//------------------------------------------------------------------------------
function TTemporaryPlainFileSystem.DeleteFile(const FileName: AnsiString): Boolean;
var
   FHandle: TAbstractFile;
begin
 FHandle := GetOpenFile(FileName);
 if (FHandle <> nil) then
  inherited CloseFile(FHandle);
 result := inherited DeleteFile(FileName);
end;// DeleteFile


//------------------------------------------------------------------------------
// rename file
//------------------------------------------------------------------------------
function TTemporaryPlainFileSystem.RenameFile(const OldName, NewName: AnsiString): Boolean;
var
   FHandle: TAbstractFile;
begin
 FHandle := GetOpenFile(OldName);
 if (FHandle <> nil) then
  inherited CloseFile(FHandle);
 result := inherited RenameFile(OldName, NewName);
end;// RenameFile


////////////////////////////////////////////////////////////////////////////////
//
//   TMemoryPlainFileSystem
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// open or create file
//------------------------------------------------------------------------------
function TMemoryPlainFileSystem.OpenFile(FileName: AnsiString; bCreate, bExclusive, bReadOnly: boolean): TAbstractFile;
var
    mf: TMemoryFile;
    FHandle: TAbstractFile;
begin
 mf := nil;
 FHandle := GetOpenFile(FileName);
 if (FHandle <> nil) then
    begin
     mf := TMemoryFile(FHandle);
     // if create - clear previous content
     if (bCreate) then
      mf.Size := 0;
     // positions to start
     mf.Position := 0;
     mf.ReadOnly := bReadOnly;
    end;
 // if not found then create it
 if (mf = nil) then
  begin
   // create Memory file object
   mf := TMemoryFile.Create(Self, FileName, bReadOnly, bExclusive);
   // open / create file
   mf.Open(bCreate);
   // store to list of open files
   OpenFileList.Add(mf);
  end;
 result := mf;
end;// OpenFile


//------------------------------------------------------------------------------
// close file
//------------------------------------------------------------------------------
procedure TMemoryPlainFileSystem.CloseFile(FileHandle: TAbstractFile);
begin
; // do nothing
end;// Close


//------------------------------------------------------------------------------
// delete file
//------------------------------------------------------------------------------
function TMemoryPlainFileSystem.DeleteFile(const FileName: AnsiString): Boolean;
var
    i: integer;
    mf: TMemoryFile;
begin
 result := false;
 // check if was already open - then delete it
 for i:=0 to OpenFileList.Count-1 do
  if (AnsiLowerCase(TAbstractFile(OpenFileList.Items[i]).FileName) =
      AnsiLowerCase(FileName)) then
    begin
     mf := TMemoryFile(OpenFileList.Items[i]);
     OpenFileList.Remove(mf);
     mf.Free;
     result := true;
     break;
    end;
end;// DeleteFile


//------------------------------------------------------------------------------
// rename file
//------------------------------------------------------------------------------
function TMemoryPlainFileSystem.RenameFile(const OldName, NewName: AnsiString): Boolean;
var
    i: integer;
    mf: TMemoryFile;
begin
 result := false;
 // check if was already open - then rename it
 for i:=0 to OpenFileList.Count-1 do
  if (AnsiLowerCase(TAbstractFile(OpenFileList.Items[i]).FileName) =
      AnsiLowerCase(OldName)) then
    begin
     mf := TMemoryFile(OpenFileList.Items[i]);
     mf.FileName := NewName;
     result := true;
     break;
    end;
end;// RenameFile


//------------------------------------------------------------------------------
// is file exists
//------------------------------------------------------------------------------
function TMemoryPlainFileSystem.FileExists(const FileName: AnsiString): Boolean;
var
    i: integer;
begin
 result := false;
 // check if was already open - then exists
 for i:=0 to OpenFileList.Count-1 do
  if (AnsiLowerCase(TAbstractFile(OpenFileList.Items[i]).FileName) =
      AnsiLowerCase(FileName)) then
    begin
     result := true;
     break;
    end;
end;// FileExists


//------------------------------------------------------------------------------
// get files list with specified extension
//------------------------------------------------------------------------------
procedure TMemoryPlainFileSystem.GetFilesListByExt(Ext: AnsiString; List: TStrings);
var
    i: integer;
    mf: TMemoryFile;
begin
 List.Clear;
 // check all open files
 for i:=0 to OpenFileList.Count-1 do
  if (ExtractFileExt(AnsiLowerCase(TAbstractFile(OpenFileList.Items[i]).FileName)) =
      AnsiLowerCase(Ext)) then
    begin
     mf := TMemoryFile(OpenFileList.Items[i]);
     List.Add(ExtractFileName(mf.FileName));
    end;
end;// GetFilesListByExt


////////////////////////////////////////////////////////////////////////////////
//
//   TESFSPlainFileSystem
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TESFSPlainFileSystem.Create(NewDatabaseName, Password: AnsiString; NewFileStoreMode: TaaFileStoreMode;
                                       DatabaseFileMode: TDatabaseFileMode;
                                       ReadOnly: boolean; InMemory: boolean;
                                       bCreate: boolean);
var
  Mode: Word;
  PageSize: integer;
  ExtentPageCount: Integer;
begin
 inherited Create(NewDatabaseName, NewFileStoreMode);
 FReadOnly := ReadOnly;
 FInMemory := InMemory;
 if (bCreate) then
  Mode := fmCreate
 else
 if (FReadOnly) then
  Mode := fmOpenRead or fmShareDenyNone
 else
  Mode := fmOpenReadWrite or fmShareDenyWrite;
 // open esfs
 case DatabaseFileMode of
  dfmCompact:
   begin
    PageSize := MIN_PAGE_SIZE;
    ExtentPageCount := 2;
   end;
  dfmNormal:
   begin
    PageSize := DEFAULT_PAGE_SIZE;
    ExtentPageCount := DEFAULT_EXTENT_PAGE_COUNT;
   end;
  dfmLarge:
   begin
    PageSize := 2 * DEFAULT_PAGE_SIZE;
    ExtentPageCount := 2 * DEFAULT_EXTENT_PAGE_COUNT;
   end;
 end; // case database mode

 UNIFORM_MIN_PAGE_COUNT := ExtentPageCount;
 ESFSHandle := TESingleFileSystem.Create(NewDatabaseName, Mode, FInMemory,
              Password,'','',esfsNone,
              PageSize,
              ExtentPageCount
              );
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TESFSPlainFileSystem.Destroy;
begin
  inherited Destroy;
  ESFSHandle.Free;
end;// TESFSPlainFileSystem.Destroy


//------------------------------------------------------------------------------
// in memory mode
//------------------------------------------------------------------------------
procedure TESFSPlainFileSystem.SetInMemory(Value: Boolean);
begin
 ESFSHandle.InMemory := Value;
end;// SetInMemory


//------------------------------------------------------------------------------
// open or create file
//------------------------------------------------------------------------------
function TESFSPlainFileSystem.OpenFile(FileName: AnsiString; bCreate, bExclusive, bReadOnly: boolean): TAbstractFile;
var
    FHandle: TAbstractFile;
    df: TESFSFile;
begin
 // check if not already open
 FHandle := GetOpenFile(FileName);
 if (FHandle <> nil) then
   raise Exception.Create('TESFSPlainFileSystem.OpenFile - File "'+
                          FileName+'" is already open.');
 // create disk file object
 df := TESFSFile.Create(ESFSHandle, Self, FileName, bReadOnly, bExclusive);
 // open / create file
 df.Open(bCreate);
 // store to list of open files
 OpenFileList.Add(df);
 result := df;
end;// OpenFile


//------------------------------------------------------------------------------
// close file
//------------------------------------------------------------------------------
procedure TESFSPlainFileSystem.CloseFile(FileHandle: TAbstractFile);
begin
 FileHandle.Free;
end;// Close


//------------------------------------------------------------------------------
// delete file
//------------------------------------------------------------------------------
function TESFSPlainFileSystem.DeleteFile(const FileName: AnsiString): Boolean;
begin
 result := ESFSHandle.DeleteFile(FileName);
end;// DeleteFile


//------------------------------------------------------------------------------
// rename file
//------------------------------------------------------------------------------
function TESFSPlainFileSystem.RenameFile(const OldName, NewName: AnsiString): Boolean;
begin
  result := ESFSHandle.RenameFile(OldName,NewName);
end;// RenameFile


//------------------------------------------------------------------------------
// is file exists
//------------------------------------------------------------------------------
function TESFSPlainFileSystem.FileExists(const FileName: AnsiString): Boolean;
begin
  result := ESFSHandle.FileExists(FileName);
end;// FileExists


//------------------------------------------------------------------------------
// get files list with specified extension
//------------------------------------------------------------------------------
procedure TESFSPlainFileSystem.GetFilesListByExt(Ext: AnsiString; List: TStrings);
var sr : TSearchRec;
    filter, s: AnsiString;
begin
 List.Clear;
 filter := '\*'+Ext;
 if (ESFSHandle.FindFirst(filter,faAnyFile,sr) <> 0) then
   ESFSHandle.FindClose(sr)
 else
  begin
   repeat
    if ((sr.Attr and faDirectory) = 0) then
     begin
      // remove extension
      s := ExtractFileName(sr.Name);
      s := Copy(s,1,Length(s)-Length(ExtractFileExt(s)));
      if (list.IndexOf(s) < 0) then
       List.Add(s);
     end;
   until (ESFSHandle.FindNext(sr) <> 0);
   ESFSHandle.FindClose(sr);
  end;
end;// GetFilesListByExt


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  TPFSManager
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// creates manager
//------------------------------------------------------------------------------
constructor TPFSManager.Create;
begin
 PFSList := TList.Create;
 FLockSection := ETblAllocCriticalSection;
 ETblInitializeCriticalSection(FLockSection);
 FLockCount := 0;
end;// Create


//------------------------------------------------------------------------------
// destroys manager
//------------------------------------------------------------------------------
destructor TPFSManager.Destroy;
var
  i: integer;
begin
  for i := 0 to PFSList.Count-1 do
   TAbstractPlainFileSystem(PFSList.Items[i]).Free;
 PFSList.Free;
 ETblDeleteCriticalSection(FLockSection);
 ETblFreeCriticalSection(FLockSection);
end;// Destroy


//------------------------------------------------------------------------------
// locks (thread-safe)
//------------------------------------------------------------------------------
procedure TPFSManager.LockSection;
begin
  ETblEnterCriticalSection(FLockSection);
  Inc(FLockCount);
end;// LockSection


//------------------------------------------------------------------------------
// unlocks section (thread-safe)
//------------------------------------------------------------------------------
procedure TPFSManager.UnlockSection;
begin
  Dec(FLockCount);
//  if (FLockCount = 0) then
  ETblLeaveCriticalSection(FLockSection);
end;// UnlockSection


//------------------------------------------------------------------------------
// find PFS in list
//------------------------------------------------------------------------------
function TPFSManager.FindPFS(DatabaseName: AnsiString; FileStoreMode: TaaFileStoreMode;
                   ESFSInMemory: boolean): TAbstractPlainFileSystem;
var
  I: Integer;
  PFSHandle: TAbstractPlainFileSystem;
begin
  LockSection;
  try
   PFSHandle := nil;
   // find PFS
   for I := PFSList.Count - 1 downto 0 do
    begin
       if (LowerCase(TAbstractPlainFileSystem(PFSList.Items[i]).DatabaseName) =
           LowerCase(DatabaseName)) then
        if (TAbstractPlainFileSystem(PFSList.Items[i]).FileStoreMode =
            FileStoreMode) then
         begin
           PFSHandle := TAbstractPlainFileSystem(PFSList.Items[i]);
           break;
         end;
    end;
   Result := PFSHandle;
  finally
    UnlockSection;
  end;
end;// FindPFS


//------------------------------------------------------------------------------
// Get Plain File System
//------------------------------------------------------------------------------
function TPFSManager.GetPFSHandle(DatabaseName, Password: AnsiString; FileStoreMode: TaaFileStoreMode;
                        var ESFSReadOnly: boolean; ESFSInMemory: boolean;
                        DatabaseFileMode: TDatabaseFileMode = dfmNormal
                        ): TAbstractPlainFileSystem;
var
  PFSHandle: TAbstractPlainFileSystem;
  handle, attr: Integer;
begin
 LockSection;
 try
   Result := nil;
   PFSHandle := FindPFS(DatabaseName,FileStoreMode,ESFSInMemory);
   // if not found then create
   if (PFSHandle <> nil) then
    begin
     Result := PFSHandle;
     if (FileStoreMode = fsmESFS) then
      ESFSReadOnly := TESFSPlainFileSystem(PFSHandle).ReadOnly;
    end
   else
    begin
     try
      case FileStoreMode of
       fsmDisk:
         result := TDiskPlainFileSystem.Create(DatabaseName, FileStoreMode);
       fsmInMemory:
         result := TMemoryPlainFileSystem.Create(DatabaseName, FileStoreMode);
       fsmTemporary:
           result := TTemporaryPlainFileSystem.Create(DatabaseName, FileStoreMode);
       fsmESFS:
         if (SysUtils.FileExists(DatabaseName)) then
          begin
           if (not ESFSReadOnly) then
            begin
              // try to open with read-write access
              Handle := SysUtils.FileOpen(DatabaseName, fmOpenReadWrite or fmShareDenyWrite);
              ESFSReadOnly := (Handle < 0);
              if (Handle >= 0) then
                FileClose(Handle);
              // check write access
              if (not ESFSReadOnly) then
               begin
                 attr := FileGetAttr(DatabaseName);
                 if ((attr and faReadOnly) <> 0) then
                  ESFSReadOnly := True
                 else
                  begin
                   if (FileSetAttr(DatabaseName, attr) <> 0) then
                     ESFSReadOnly := True
                  end;
               end;
            end;
           result := TESFSPlainFileSystem.Create(DatabaseName, Password,
              FileStoreMode, DatabaseFileMode, ESFSReadOnly, ESFSInMemory, false);
          end
         else
          begin
           result := nil;
          end;
       else
        raise Exception.Create('TPFSManager.GetPFSHandle - Unsuuported file store mode.');
      end;
      if (result <> nil) then
       PFSList.Add(result);
     except
      result := nil;
     end;
    end;
 finally
   UnlockSection;
 end;
end;// GetPFS


//------------------------------------------------------------------------------
// close PFS with ESFS on disk or in memory
//------------------------------------------------------------------------------
procedure TPFSManager.ClosePhysESFS(DatabaseName: AnsiString; InMemory: boolean);
var
  PFSHandle: TAbstractPlainFileSystem;
begin
  LockSection;
  try
   PFSHandle := FindPFS(DatabaseName, fsmESFS, InMemory);
   // if open then close it
   if (PFSHandle <> nil) then
    begin
      PFSList.Remove(PFSHandle);
      PFSHandle.Free;
    end;
  finally
   UnlockSection;
  end;
end;// ClosePhysESFS


//------------------------------------------------------------------------------
// create PFS with ESFS on disk or in memory
//------------------------------------------------------------------------------
function TPFSManager.CreatePhysESFS(DatabaseName, Password: AnsiString;
                                   InMemory: boolean;
                                   DatabaseFileMode: TDatabaseFileMode
                                   ): boolean;
var
  PFSHandle: TAbstractPlainFileSystem;
begin
 LockSection;
 try
   // if ESFS is open - close it
   ClosePhysESFS(DatabaseName, InMemory);
   // try to create
   result := true;
   try
    PFSHandle := TESFSPlainFileSystem.Create(DatabaseName, Password, fsmESFS,
                           DatabaseFileMode, false, InMemory, true);
    PFSList.Add(PFSHandle);
    // close ESFS
    if (not InMemory) then
     ClosePhysESFS(DatabaseName, InMemory);
   except
    result := false;
   end;
 finally
  UnlockSection;
 end;
end;// CreatePhysESFS


//------------------------------------------------------------------------------
// delete PFS on disk or in memory
//------------------------------------------------------------------------------
function TPFSManager.DeletePhysESFS(DatabaseName: AnsiString; InMemory: boolean): boolean;
begin
 LockSection;
 try
   // if ESFS is open - close it
   ClosePhysESFS(DatabaseName, InMemory);
   // if not in-memory files then delete them
   if (not InMemory) then
    result := ESingleFileSystem.DeleteESFS(DatabaseName)
   else
    result := true;
 finally
  UnlockSection;
 end;
end;// DeletePhysESFS

{
//------------------------------------------------------------------------------
// repair PFS on disk or in memory
//------------------------------------------------------------------------------
function TPFSManager.RepairPhysESFS(DatabaseName: AnsiString; InMemory: boolean; var log: AnsiString; DeleteCorruptedFiles: boolean): boolean;
var
  PFSHandle: TESFSPlainFileSystem;
  ronly: boolean;
begin
 // if ESFS is closed - open it
 ronly := false;
 PFSHandle := TESFSPlainFileSystem(GetPFSHandle(DatabaseName, fsmESFS, ronly, InMemory));
 // if not in-memory files then repair them
 if (not InMemory) then
	result := PFSHandle.RepairESFS(log, DeleteCorruptedFiles)
 else
  result := true;
end;// RepairPhysESFS
}

//------------------------------------------------------------------------------
// rename PFS on disk or in memory
//------------------------------------------------------------------------------
function TPFSManager.RenamePhysESFS(DatabaseName: AnsiString; InMemory: boolean; const NewDatabaseName: AnsiString): boolean;
begin
 LockSection;
 try
  if (InMemory) then
   raise Exception.Create('TPFSManager.RenamePhysESFS - Cannot rename in-memory database.');
  // if ESFS is open - close it
  ClosePhysESFS(DatabaseName, InMemory);
  result := ESingleFileSystem.RenameESFS(DatabaseName, NewDatabaseName)
 finally
  UnlockSection;
 end;
end;

//------------------------------------------------------------------------------
// copy PFS on disk or in memory
//------------------------------------------------------------------------------
function TPFSManager.CopyPhysESFS(DatabaseName: AnsiString; InMemory: boolean; const NewDatabaseName: AnsiString): boolean;
var
  PFSHandle: TESFSPlainFileSystem;
begin
 LockSection;
 try
//   if (InMemory) then
    begin
     PFSHandle := TESFSPlainFileSystem(FindPFS(DatabaseName, fsmESFS, InMemory));
     PFSHandle.ESFSHandle.SaveToFile(NewDatabaseName);
     result := true;
    end
{   else
    begin
     // if ESFS is open - close it
     ClosePhysESFS(DatabaseName, InMemory);
    result := ESingleFileSystem.CopyESFS(DatabaseName, NewDatabaseName);
    end;}
 finally
  UnlockSection;
 end;
end;

end.
