unit ESFSFileCtrl;

{$I ESFSVer.inc}

interface

uses classes, sysutils, windows
{$IFDEF DEBUG_LOG}
,ESFSDebug
{$ENDIF}
;

// Function return Max File Size for drive ( extracted from FileNeme)
function  GetMaxFileSize(FileName: AnsiString) : Int64;

var
   HFSignature: array [0..7] of AnsiChar = 'AAMVHFSS'; // AidAim multi-volume huge file system signature
const
   HFSignatureSize = 8;
   FBlockSize = 512*1024; // 0,5Mb
type
  // Partition Header - points to the name of the next partition file
  TESFSHugeFilePartitionHeader = record
    Signature: array [0..HFSignatureSize-1] of AnsiChar; // signature
    PartitionSize: Int64; // max size of each partition (get used value only from first part in chain)
    NextFileName: array [0..260] of AnsiChar; // name of the next file in chain
  end;

const
   HFPHeaderSize = sizeof(TESFSHugeFilePartitionHeader);


//------------------------------------------------------------------------------
// Parent class for all types of usual files
//------------------------------------------------------------------------------
type
 TESFSAbstractFile=class
 protected
  FFileName:  AnsiString;
  FExclusive: boolean;
  FReadOnly:  boolean;

  // set exclusive mode
  procedure SetExclusive(value: boolean); virtual;
  // set file position
  procedure SetPosition(Pos: Int64); virtual;
  // get file position
  function GetPosition: Int64; virtual;
  // set read-only mode
  procedure SetReadOnly(value: boolean); virtual;
  // set file size
  procedure SetSize(value: Int64); virtual; abstract;
  // get file size
  function GetSize: Int64; virtual;

 public
  // constructor
  constructor Create(FileName: AnsiString; bReadOnly, bExclusive: boolean); virtual;
  // copy form source file
  function CopyFrom(Source: TESFSAbstractFile; Count: Int64): Int64;
  // close file
  procedure Close; virtual; abstract;
  // flush file buffers
  procedure FlushBuffers; virtual; abstract;
  // lock file
//  procedure Lock; virtual; abstract;
  // open file (with params specified in constructor)
  function Open(bCreate: boolean): boolean; virtual; abstract;
  // read from file
  function Read(var Buffer; Count: Longint): Longint; virtual; abstract;
  // read known bytes from file
  procedure ReadBuffer(var Buffer; Count: Longint);
  // seek in file
  function Seek(Offset: Int64; Origin: Word): Int64; virtual; abstract;
  // unlock file
//  procedure Unlock; virtual; abstract;
  // write into the file
  function Write(const Buffer; Count: Longint): Longint; virtual; abstract;
  // write known bytes into the file
  procedure WriteBuffer(const Buffer; Count: Longint);

 public
  // if true - file is in exclusive mode
  property Exclusive: Boolean read FExclusive write SetExclusive default False;
  // file name
  property FileName: AnsiString read FFileName write FFileName;
  // current position in file
  property Position: Int64 read GetPosition write SetPosition default 0;
  // if true - file is in read only mode
  property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
  // size of file
  property Size: Int64 read GetSize write SetSize default 0;
  // is temporary file?
//  property Temporary: boolean read FTemporary write SetTemporary default False;
 end;


//------------------------------------------------------------------------------
// Disk file
//------------------------------------------------------------------------------
 TESFSDiskFile=class(TESFSAbstractFile)
 private
  FHandle: Integer; // file handle
  FDirectory: AnsiString; // work directory

  // reopen file (in a new mode)
  procedure Reopen;

 protected
  // internal open
  function InternalOpen(const FileName: AnsiString; bCreate: boolean): boolean;
  // set exclusive mode
  procedure SetExclusive(value: boolean); override;
  // set read-only mode
  procedure SetReadOnly(value: boolean); override;
  // set file size
  procedure SetSize(value: Int64); override;

 public
  // constructor
  constructor Create(FileName: AnsiString; bReadOnly, bExclusive: boolean); override;
  // close file
  procedure Close; override;
  // destructor
  destructor Destroy; override;
  // flush file buffers
  procedure FlushBuffers; override;
  // open file (with params specified in constructor)
  function Open(bCreate: boolean): boolean; override;
  // read from file
  function Read(var Buffer; Count: Longint): Longint; override;
  // seek in file
  function Seek(Offset: Int64; Origin: Word): Int64; override;
  // write into the file
  function Write(const Buffer; Count: Longint): Longint; override;

 public
  // if true - file is in exclusive mode
  property Exclusive: Boolean read FExclusive write SetExclusive default False;
  // file name
  property FileName: AnsiString read FFileName write FFileName;
  // if true - file is in read only mode
  property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
  // current position in file
  property Position: Int64 read GetPosition write SetPosition default 0;
  // size of file
  property Size: Int64 read GetSize write SetSize default 0;
 end;// TESFSDiskFile


//------------------------------------------------------------------------------
// Memory file
//------------------------------------------------------------------------------
 TESFSMemoryFile=class(TESFSAbstractFile)
 private
  FStream: TMemoryStream; // to store file data

 protected
  // set file size
  procedure SetSize(value: Int64); override;

 public
  // constructor
  constructor Create(FileName: AnsiString; bReadOnly, bExclusive: boolean); override;
  // close file
  procedure Close; override;
  // destructor
  destructor Destroy; override;
  // flush file buffers
  procedure FlushBuffers; override;
  // open file (with params specified in constructor)
  function Open(bCreate: boolean): boolean; override;
  // read from file
  function Read(var Buffer; Count: Longint): Longint; override;
  // seek in file
  function Seek(Offset: Int64; Origin: Word): Int64; override;
  // write into the file
  function Write(const Buffer; Count: Longint): Longint; override;

 public
  // if true - file is in exclusive mode
  property Exclusive: Boolean read FExclusive write SetExclusive default False;
  // file name
  property FileName: AnsiString read FFileName write FFileName;
  // if true - file is in read only mode
  property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
  // current position in file
  property Position: Int64 read GetPosition write SetPosition default 0;
  // size of file
  property Size: Int64 read GetSize write SetSize default 0;
 end;// TESFSMemoryFile


//------------------------------------------------------------------------------
// Huge File (consists of several usual files)
//------------------------------------------------------------------------------
 TESFSHugeFile=class
 private
  FFileName:      AnsiString;  // full file name with path
  FExclusive:     boolean; // id file open in exclusive mode
  FReadOnly:      boolean; // is file read-only
  FInMemory:      boolean; // is file stored in memory
  FPosition:      Int64;   // current position
  FSize:          Int64;   // file size
  FPartitionSize: Int64;   // max size of each separate part (usual file)
  FPartitionDataSize: Int64; // user data size in each partition
  PartFiles:      array of TESFSAbstractFile; // list of partition files
  IsFileOpen:     boolean; // is file open or closed?
  FStubSize:      Int64;

  // get partition No and offset there by global file position
  procedure GetFileNoAndOffset(Pos: Int64; var FileNo: integer; var Offset: Int64);
  // init part header
  procedure InitPartHeader(var HFPartHeader: TESFSHugeFilePartitionHeader);
  // append part file
  function AppendPartFile: boolean;
  // delete last part file
  procedure DeleteLastPartFile;
  // open files chain
  function OpenFilesChain(const FileName: AnsiString): boolean;
  // internal open
  function InternalOpen(const FileName: AnsiString; bCreate: boolean;
                        bIgnoreErrors: boolean=false): boolean;
  // set exclusive mode
  procedure SetExclusive(value: boolean);
  // set in-memory mode
  procedure SetInMemory(value: boolean);
  // set file position
  procedure SetPosition(Pos: Int64);
  // get file position
  function GetPosition: Int64;
  // set read-only mode
  procedure SetReadOnly(value: boolean);
  // set file size
  procedure SetSize(value: Int64);
  // get file size
  function GetSize: Int64;
  // detects stub and+ gets its size
  procedure CalculateStubSize(FFile: TESFSAbstractFile);

 public
  // constructor
  constructor Create(FileName: AnsiString; bReadOnly, bExclusive, bInMemory: boolean;
                     PartitionSize: Int64 = -1);
  // destructor
  destructor Destroy; override;
  // copy form source file
  function CopyFrom(Source: TESFSHugeFile; Count: Int64): Int64;
  // save to stream
  procedure SaveToStream(Stream: TStream);
  // load from stream
  procedure LoadFromStream(Stream: TStream);
  // close file
  procedure Close;
  // flush file buffers
  procedure FlushBuffers;
  // open file (with params specified in constructor)
  function Open(bCreate: boolean; bIgnoreErrors: boolean=false): boolean;
  // read from file
  function Read(var Buffer; Count: Longint): Longint;
  // read known bytes from file
  procedure ReadBuffer(var Buffer; Count: Longint);
  // seek in file
  function Seek(Offset: Int64; Origin: Word): Int64;
  // write into the file
  function Write(const Buffer; Count: Longint): Longint;
  // write known bytes into the file
  procedure WriteBuffer(const Buffer; Count: Longint);
  // copy file
  function CopyFile(const NewName: AnsiString): Boolean;
  // rename file
  function RenameFile(const NewName: AnsiString): Boolean;
  // delete file
  function DeleteFile: Boolean;

 public
  // if true - file is in exclusive mode
  property Exclusive: Boolean read FExclusive write SetExclusive default False;
  // file name
  property FileName: AnsiString read FFileName write FFileName;
  // current position in file
  property Position: Int64 read GetPosition write SetPosition default 0;
  // if true - file is in read only mode
  property ReadOnly: Boolean read FReadOnly write SetReadOnly default False;
  // size of file
  property Size: Int64 read GetSize write SetSize default 0;
  // is memory file?
  property InMemory: boolean read FInMemory write SetInMemory;
  // is temporary file?
//  property Temporary: boolean read FTemporary write SetTemporary default False;
 end;

implementation

uses ESFSEngine;

////////////////////////////////////////////////////////////////////////////////
//
//   TESFSAbstractFile
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// set exclusive mode
//------------------------------------------------------------------------------
procedure TESFSAbstractFile.SetExclusive(value: boolean);
begin
 FExclusive := value;
end;// TESFSAbstractFile.SetExclusive


//------------------------------------------------------------------------------
// get file position
//------------------------------------------------------------------------------
function TESFSAbstractFile.GetPosition: Int64;
begin
  Result := Seek(0, 1);
end;// GetPosition


//------------------------------------------------------------------------------
// set file position
//------------------------------------------------------------------------------
procedure TESFSAbstractFile.SetPosition(Pos: Int64);
begin
  Seek(Pos, 0);
end;// SetPosition


//------------------------------------------------------------------------------
// set read-only mode
//------------------------------------------------------------------------------
procedure TESFSAbstractFile.SetReadOnly(value: boolean);
begin
 FReadOnly := value;
end;// TESFSAbstractFile.SetReadOnly


//------------------------------------------------------------------------------
// get file size
//------------------------------------------------------------------------------
function TESFSAbstractFile.GetSize: Int64;
var
  Pos: Longint;
begin
  Pos := Seek(0, 1);
  Result := Seek(0, 2);
  Seek(Pos, 0);
end;// TESFSAbstractFile.GetSize


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TESFSAbstractFile.Create(FileName: AnsiString; bReadOnly, bExclusive: boolean);
begin
 FFileName := FileName;
 FReadOnly := bReadOnly;
 FExclusive := bExclusive;
end;// TESFSAbstractFile.Create


//------------------------------------------------------------------------------
// copy form source file
//------------------------------------------------------------------------------
function TESFSAbstractFile.CopyFrom(Source: TESFSAbstractFile; Count: Int64): Int64;
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
      Count := Count - Int64(N);
    end;
  finally
    FreeMem(Buffer, BufSize);
  end;
end;// TESFSAbstractFile.CopyFrom


//------------------------------------------------------------------------------
// read known bytes from file
//------------------------------------------------------------------------------
procedure TESFSAbstractFile.ReadBuffer(var Buffer; Count: Longint);
begin
  if (Count <> 0) and (Read(Buffer, Count) <> Count) then
    raise Exception.Create('TESFSAbstractFile.ReadBuffer - Stream read error');
end;// TESFSAbstractFile.ReadBuffer


//------------------------------------------------------------------------------
// write known bytes into the file
//------------------------------------------------------------------------------
procedure TESFSAbstractFile.WriteBuffer(const Buffer; Count: Longint);
begin
  if (Count <> 0) and (Write(Buffer, Count) <> Count) then
    raise Exception.Create('TESFSAbstractFile.WriteBuffer - Stream write error');
end;// TESFSAbstractFile.WriteBuffer



////////////////////////////////////////////////////////////////////////////////
//
//   TESFSDiskFile
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// reopen file (in a new mode)
//------------------------------------------------------------------------------
procedure TESFSDiskFile.Reopen;
var pos: Longint;
begin
 pos := Position;
 Close;
 Open(false);
 Position := pos;
end;// TESFSDiskFile.Reopen


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TESFSDiskFile.Create(FileName: AnsiString; bReadOnly, bExclusive: boolean);

begin
 inherited Create(FileName, bReadOnly, bExclusive);
 FDirectory := ExtractFilePath(FileName);
 FHandle := -1;
end;// TESFSDiskFile.Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TESFSDiskFile.Destroy;
begin
 Close;
 inherited Destroy;
end;// TESFSDiskFile.Destroy


//------------------------------------------------------------------------------
// internal open
//------------------------------------------------------------------------------
function TESFSDiskFile.InternalOpen(const FileName: AnsiString; bCreate: boolean): boolean;
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
{	if FTemporary then
		Flags := (Flags or FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_DELETE_ON_CLOSE)
	else}
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
//  FullFileName := FDirectory+FileName;
  FullFileName := FileName;
  StrPCopy(@TempFileName, FullFileName);
  FHandle := Integer(Windows.CreateFileA(PAnsiChar(@TempFileName), AccessMode[Mode and 3],
    ShareMode[(Mode and $F0) shr 4], nil, CreateDistribution,
    Flags, 0));

  Result := true;
  if FHandle < 0 then
   Result := false;
end;// TESFSDiskFile.InternalOpen


//------------------------------------------------------------------------------
// flush file buffers
//------------------------------------------------------------------------------
procedure TESFSDiskFile.FlushBuffers;
begin
  FlushFileBuffers(FHandle);
end;// TESFSDiskFile.FlushBuffers;


//------------------------------------------------------------------------------
// set read-only mode
//------------------------------------------------------------------------------
procedure TESFSDiskFile.SetReadOnly(value: boolean);
begin
 if (FReadOnly <> value) then
  begin
   FReadOnly := value;
   Reopen;
  end;
end;// TESFSDiskFile.SetReadOnly


//------------------------------------------------------------------------------
// set file size
//------------------------------------------------------------------------------
procedure TESFSDiskFile.SetSize(value: Int64);
begin
  Seek(value, 0);
  Win32Check(SetEndOfFile(FHandle));
end;// TESFSDiskFile.SetSize


//------------------------------------------------------------------------------
// set exclusive mode
//------------------------------------------------------------------------------
procedure TESFSDiskFile.SetExclusive(value: boolean);
begin
 if (FExclusive <> value) then
  begin
   FExclusive := value;
   Reopen;
  end;
end;// TESFSDiskFile.SetExclusive


//------------------------------------------------------------------------------
// open file
//------------------------------------------------------------------------------
function TESFSDiskFile.Open(bCreate: boolean): boolean;
begin
 Result := InternalOpen(FFileName, bCreate);
end;// TESFSDiskFile.Open


//------------------------------------------------------------------------------
// close file
//------------------------------------------------------------------------------
procedure TESFSDiskFile.Close;
begin
  if FHandle >= 0 then
   begin
    FlushBuffers;
    FileClose(FHandle);
   end;
  FHandle := -1;
end;// TESFSDiskFile.Close;


//------------------------------------------------------------------------------
// read from file
//------------------------------------------------------------------------------
function TESFSDiskFile.Read(var Buffer; Count: Longint): Longint;
begin
 Result:=FileRead(FHandle,Buffer,Count);
end;// TESFSDiskFile.Read


//------------------------------------------------------------------------------
// seek in file
//------------------------------------------------------------------------------
function TESFSDiskFile.Seek(Offset: Int64; Origin: Word): Int64;
begin
{
  Result := FileSeek(FHandle, Offset, Integer(Origin));
}
  {$R-}
  Result := Offset;
  Int64Rec(Result).Lo := SetFilePointer(THandle(FHandle), Int64Rec(Result).Lo,
    @Int64Rec(Result).Hi, Origin);
  {$R+}
end;// TESFSDiskFile.Seek


//------------------------------------------------------------------------------
// write into the file
//------------------------------------------------------------------------------
function TESFSDiskFile.Write(const Buffer; Count: Longint): Longint;
begin
 Result := 0;
 if (Count = 0) then
   SetEndOfFile(FHandle)
 else
   Result := FileWrite(FHandle, Buffer, Count);
end;// TESFSDiskFile.Write



////////////////////////////////////////////////////////////////////////////////
//
//   TESFSMemoryFile
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TESFSMemoryFile.Create(FileName: AnsiString; bReadOnly, bExclusive: boolean);
begin
 inherited Create(FileName, bReadOnly, bExclusive);
 FStream := nil;
end;// TESFSMemoryFile.Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TESFSMemoryFile.Destroy;
begin
 Close;
 inherited Destroy;
end;// TESFSMemoryFile.Destroy


//------------------------------------------------------------------------------
// flush file buffers
//------------------------------------------------------------------------------
procedure TESFSMemoryFile.FlushBuffers;
begin
; // do nothing
end;// TESFSMemoryFile.FlushBuffers;


//------------------------------------------------------------------------------
// set file size
//------------------------------------------------------------------------------
procedure TESFSMemoryFile.SetSize(value: Int64);
begin
  FStream.Size := value;
end;// TESFSMemoryFile.SetSize


//------------------------------------------------------------------------------
// open file
//------------------------------------------------------------------------------
function TESFSMemoryFile.Open(bCreate: boolean): boolean;
begin
 if (not bCreate) then
  raise Exception.Create('TESFSMemoryFile.Open - File cannot be open, only creation is available.');
 try
  FStream := TMemoryStream.Create;
  Result := true;
 except
  Result := false;
 end;
end;// TESFSMemoryFile.Open


//------------------------------------------------------------------------------
// close file
//------------------------------------------------------------------------------
procedure TESFSMemoryFile.Close;
begin
  if FStream <> nil then
   FStream.Free;
  FStream := nil;
end;// TESFSMemoryFile.Close;


//------------------------------------------------------------------------------
// read from file
//------------------------------------------------------------------------------
function TESFSMemoryFile.Read(var Buffer; Count: Longint): Longint;
begin
 Result := FStream.Read(Buffer, Count);
end;// TESFSMemoryFile.Read


//------------------------------------------------------------------------------
// seek in file
//------------------------------------------------------------------------------
function TESFSMemoryFile.Seek(Offset: Int64; Origin: Word): Int64;
begin
  Result := FStream.Seek(Offset, Origin);
end;// TESFSMemoryFile.Seek


//------------------------------------------------------------------------------
// write into the file
//------------------------------------------------------------------------------
function TESFSMemoryFile.Write(const Buffer; Count: Longint): Longint;
begin
 Result := FStream.Write(Buffer, Count);
end;// TESFSMemoryFile.Write



////////////////////////////////////////////////////////////////////////////////
//
//   TESFSHugeFile
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TESFSHugeFile.Create(FileName: AnsiString; bReadOnly, bExclusive, bInMemory: boolean;
                             PartitionSize: Int64=-1);
begin
 FFileName := FileName;
 FReadOnly := bReadOnly;
 FExclusive := bExclusive;
 FInMemory := bInMemory;
 IsFileOpen := false;
 FStubSize := 0;

 if (PartitionSize <> -1) then
  FPartitionSize := PartitionSize // specified size
 else
  begin
   FPartitionSize := GetMaxFileSize(FileName);
   // detect failed
   if (FPartitionSize <= 0) then
    FPartitionSize := 2*Int64(1024)*Int64(1024)*Int64(1024)-1; // 2Gb
  end;

 // used for user data size
 FPartitionDataSize := FPartitionSize - Int64(HFPHeaderSize);
 if (FPartitionDataSize < 100) then
  raise Exception.Create('File part size is too small. Minimal part size is '+
                         IntToStr(Int64(HFPHeaderSize)+100));
 // no files
 SetLength(PartFiles,0);
 FSize := 0;
 FPosition := 0;
end;// Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TESFSHugeFile.Destroy;
begin
  FInMemory := false;
  Close;
  inherited Destroy;
end;// Destroy


//------------------------------------------------------------------------------
// get partition No and offset there by global file position
//------------------------------------------------------------------------------
procedure TESFSHugeFile.GetFileNoAndOffset(Pos: Int64; var FileNo: integer; var Offset: Int64);
begin
  FileNo := Integer((Pos+FStubSize) div FPartitionDataSize);
  Offset := (Pos+FStubSize) - Int64(FileNo) * Int64(FPartitionDataSize);
  if (FileNo = 0) then
   Offset := Offset - FStubSize;
end;// GetFileNoAndOffset


//------------------------------------------------------------------------------
// init part header
//------------------------------------------------------------------------------
procedure TESFSHugeFile.InitPartHeader(var HFPartHeader: TESFSHugeFilePartitionHeader);
begin
  // clear record
  HFPartHeader.PartitionSize := 0;
  FillChar(HFPartHeader.Signature, HFSignatureSize, 0);
  FillChar(HFPartHeader.NextFileName, sizeof(HFPartHeader.NextFileName), 0);

//  FillChar(HFPartHeader, HFPHeaderSize, 0);
  // move signature
  Move(HFSignature, HFPartHeader.Signature, HFSignatureSize);
  // set partition size
  HFPartHeader.PartitionSize := FPartitionSize;
end;// InitPartHeader


//------------------------------------------------------------------------------
// append part file
//------------------------------------------------------------------------------
function TESFSHugeFile.AppendPartFile: boolean;
var
  FName, s: AnsiString;
  i: integer;
  Pos: Int64;
  HFPHeader: TESFSHugeFilePartitionHeader;
begin
  //--- get name of new file ---
  if (Length(PartFiles) = 0) then
    FName := FFileName
  else
   begin
    i := Length(PartFiles);
    repeat
     FName := FFileName+IntToStr(i);
     if (not FileExists(FName)) then
      break;
     inc(i);
    until false;
   end;

  //--- create file ---
  i := Length(PartFiles);
  SetLength(PartFiles, i+1);
  if (FInMemory) then
   PartFiles[i] := TESFSMemoryFile.Create(FName,FReadOnly,FExclusive)
  else
   PartFiles[i] := TESFSDiskFile.Create(FName,FReadOnly,FExclusive);
  if (not PartFiles[i].Open(true)) then
   begin
     Result := false;
     exit;
   end
  else
   Result := true;

  // write partition header - no next file
  InitPartHeader(HFPHeader);
  if (i = 0) then
   PartFiles[i].Position := FStubSize;
  PartFiles[i].Write(HFPHeader, HFPHeaderSize);

  //--- modify header of previous file ---
  if (Length(PartFiles) <> 1) then
   begin
     // save position
     Pos := PartFiles[i-1].Position;
     //--- prepare header ---
     s := ExtractFileName(FName);
     Move(PAnsiChar(s)^, HFPHeader.NextFileName[0], Length(s));
     HFPHeader.NextFileName[Length(s)+1] := #0;
     // write header
     if ((i-1) = 0) then
      PartFiles[i-1].Position := FStubSize
     else
      PartFiles[i-1].Position := 0;
     PartFiles[i-1].Write(HFPHeader, HFPHeaderSize);
     // restore position
     PartFiles[i-1].Position := Pos;
   end;
end;// AppendPartFile


//------------------------------------------------------------------------------
// delete last part file
//------------------------------------------------------------------------------
procedure TESFSHugeFile.DeleteLastPartFile;
var
  FName: AnsiString;
  i: integer;
  Pos: Int64;
  HFPHeader: TESFSHugeFilePartitionHeader;
begin
  if (Length(PartFiles) <= 1) then
   raise Exception.Create('TESFSHugeFile.DeleteLastPartFile - No parts to delete.');
  i := Length(PartFiles)-1;
  FName := PartFiles[i].FileName;
  // close file and free object
  PartFiles[i].Free;
  // remove from memory list
  SetLength(PartFiles, i);
  // delete file
  if (not FInMemory) then
    SysUtils.DeleteFile(PAnsiChar(FName));

  //--- modify header of previous file ---
  // save position
  Pos := PartFiles[i-1].Position;
  // write partition header - no next file
  InitPartHeader(HFPHeader);
  if ((i-1) = 0) then
   PartFiles[i-1].Position := FStubSize
  else
   PartFiles[i-1].Position := 0;
  PartFiles[i-1].Write(HFPHeader, HFPHeaderSize);
  // restore position
  PartFiles[i-1].Position := Pos;
end;// DeleteLastPartFile


//------------------------------------------------------------------------------
// open files chain
//------------------------------------------------------------------------------
function TESFSHugeFile.OpenFilesChain(const FileName: AnsiString): boolean;
var
  CurFileName, CurFolder: AnsiString;
  i: integer;
  HFPHeader: TESFSHugeFilePartitionHeader;
  res: boolean;
  df: TESFSDiskFile;
begin
  CurFolder := ExtractFilePath(FileName);
  CurFileName := ExtractFileName(FileName);
  Result := true;
  repeat
    //--- open file ---
    i := Length(PartFiles);
    SetLength(PartFiles, i+1);
    if (FInMemory) then
     PartFiles[i] := TESFSMemoryFile.Create(CurFolder+CurFileName, FReadOnly, FExclusive)
    else
     PartFiles[i] := TESFSDiskFile.Create(CurFolder+CurFileName, FReadOnly, FExclusive);
    // open disk file and copy it to in-memory file?
    if (FInMemory) then
     begin
       df := TESFSDiskFile.Create(CurFolder+CurFileName, FReadOnly, FExclusive);
       res := df.Open(false);
       if (res) then
        begin
         // create in-memory file
         PartFiles[i].Open(true);
         PartFiles[i].CopyFrom(df,df.size);
         PartFiles[i].Position := 0;
        end;
       df.Free
     end
    else
      // just open disk file
      res := PartFiles[i].Open(false);
    if (not res) then
      begin
       // file is corrupted
       Result := false;
       // free its object
       PartFiles[i].Free;
       // and remove it from list
       SetLength(PartFiles, i);
       break;
      end;
    // calculate stub size
    if (i = 0) then
     begin
      CalculateStubSize(PartFiles[i]);
      PartFiles[i].Position := FStubSize;
     end;

    // read header
    PartFiles[i].Read(HFPHeader, HFPHeaderSize);
    // get next file name
    CurFileName := HFPHeader.NextFileName;
    // init partition size
    if (i = 0) then
     begin
       FPartitionSize := HFPHeader.PartitionSize;
       FPartitionDataSize := FPartitionSize - Int64(HFPHeaderSize);
     end;
    // check signature and size
    if ((StrLComp(HFPHeader.Signature, HFSignature, HFSignatureSize) <> 0) or
        (PartFiles[i].Size < HFPHeaderSize)) then
     begin
      // file is corrupted
      Result := false;
      // free its object
      PartFiles[i].Free;
      // and remove it from list
      SetLength(PartFiles, i);
      break;
     end;
    // truncated file in chain?
    if ((PartFiles[i].Size < FPartitionSize) and
         (CurFileName <> '')) then
     begin
      // file is truncated
      Result := false;
      break;
     end;
  until (CurFileName = '');
end;// OpenFilesChain


//------------------------------------------------------------------------------
// internal open
//------------------------------------------------------------------------------
function TESFSHugeFile.InternalOpen(const FileName: AnsiString; bCreate: boolean;
                                bIgnoreErrors: boolean=false): boolean;
var
  i: integer;
begin
  if (IsFileOpen) then
    raise Exception.Create('TESFSHugeFile.InternalOpen - File is already open.');

  // if memory files are still kept open - just set flags
  if ((FInMemory) and (Length(PartFiles) > 0) and (not bCreate)) then
   begin
    Result := true;
   end
  else
  if (Length(PartFiles) <> 0) then
    raise Exception.Create('TESFSHugeFile.InternalOpen - File was not closed.')
  else
  // create file?
  if (bCreate) then
   begin
     // if newly created file - delete current one
     DeleteFile;
     Result := AppendPartFile; // create file
     FSize := 0;
   end
  else
   begin
     // open files chain
     if (OpenFilesChain(FileName) or bIgnoreErrors) then
      begin
       if (Length(PartFiles) > 0) then
        begin
         FSize := 0;
         for i := 0 to Length(PartFiles)-1 do
          FSize := FSize + PartFiles[i].Size-HFPHeaderSize;
         FSize := FSize - FStubSize;
         Result := true;
        end
       else
        Result := false;
      end
     else
      begin
        // corrupted file
        Result := false;
      end;
   end;
  FPosition := 0;
  IsFileOpen := Result;
end;// InternalOpen


//------------------------------------------------------------------------------
// set exclusive mode
//------------------------------------------------------------------------------
procedure TESFSHugeFile.SetExclusive(value: boolean);
begin
 FExclusive := value;
end;// SetExclusive


//------------------------------------------------------------------------------
// set in-memory mode
//------------------------------------------------------------------------------
procedure TESFSHugeFile.SetInMemory(value: boolean);
var
  PartFile: TESFSAbstractFile;
  s: AnsiString;
  i: integer;
begin
  if (value = FInMemory) then
   exit;
  // exchange data between disk and memory files
  if (Length(PartFiles) > 0) then
   begin
    // part files
    for i := 0 to Length(PartFiles)-1 do
     begin
      // part file name
      s := PartFiles[i].FileName;
      // create new file
      if (value) then
       PartFile := TESFSMemoryFile.Create(s, FReadOnly, FExclusive)
      else
       PartFile := TESFSDiskFile.Create(s, FReadOnly, FExclusive);
      PartFile.Open(true);
      // copy old file to new one
      PartFiles[i].Position := 0;
      PartFile.CopyFrom(PartFiles[i],PartFiles[i].Size);
      // set position
      PartFile.Position := PartFiles[i].Position;
      // free old file
      PartFiles[i].Free;
      // set element to the new file
      PartFiles[i] := PartFile;
     end;
   end;
  FInMemory := value;
end;// SetInMemory


//------------------------------------------------------------------------------
// get file position
//------------------------------------------------------------------------------
function TESFSHugeFile.GetPosition: Int64;
begin
  Result := Seek(0, 1);
end;// GetPosition


//------------------------------------------------------------------------------
// set file position
//------------------------------------------------------------------------------
procedure TESFSHugeFile.SetPosition(Pos: Int64);
begin
  Seek(Pos, soFromBeginning);
end;// SetPosition


//------------------------------------------------------------------------------
// set read-only mode
//------------------------------------------------------------------------------
procedure TESFSHugeFile.SetReadOnly(value: boolean);
begin
 FReadOnly := value;
end;// SetReadOnly


//------------------------------------------------------------------------------
// set file size
//------------------------------------------------------------------------------
procedure TESFSHugeFile.SetSize(Value: Int64);
var
  FileNo: integer;
  Offset: Int64;
begin
  // increase size?
  if (Value > FSize) then
   begin
     // get reqired No of part file
     GetFileNoAndOffset(Value, FileNo, Offset);
     // append required number of part files
     while (Length(PartFiles)-1 < FileNo) do
      begin
       // set size of part file
       PartFiles[Length(PartFiles)-1].Size := FPartitionSize;
       AppendPartFile;
      end;
     // set size of last part file
     if (FileNo = 0) then
      PartFiles[FileNo].Size := Int64(Offset+Int64(HFPHeaderSize)+FStubSize)
     else
      PartFiles[FileNo].Size := Int64(Offset+Int64(HFPHeaderSize));
   end
  else
  if (Value < FSize) then
   begin
     // get reqired No of part file
     GetFileNoAndOffset(Value, FileNo, Offset);
     // delete required number of part files
     while (Length(PartFiles)-1 > FileNo) do
       DeleteLastPartFile;
     // set size of last part file
     if (FileNo = 0) then
      PartFiles[FileNo].Size := Int64(Offset+Int64(HFPHeaderSize)+FStubSize)
     else
      PartFiles[FileNo].Size := Int64(Offset+Int64(HFPHeaderSize));
   end;
  FSize := Value;
  FPosition := Value;
end;// SetSize


//------------------------------------------------------------------------------
// get file size
//------------------------------------------------------------------------------
function TESFSHugeFile.GetSize: Int64;
begin
  Result := FSize;
end;// GetSize


//------------------------------------------------------------------------------
// detects stub and+ gets its size
//------------------------------------------------------------------------------
procedure TESFSHugeFile.CalculateStubSize(FFile: TESFSAbstractFile);
var
    size,offset,pos,
    i,j,k:	      Integer;
    buf:		      PAnsiChar;
    HFPHeader:    TESFSHugeFilePartitionHeader;
    name:         array [0..7] of AnsiChar;
    sgn:      		array [0..7] of AnsiChar;


 function CheckFile(headerPos: integer): Boolean;
 var oldPos: Integer;
 begin
  result := false;
  oldPos := FFile.Position;
  FFile.Position := headerPos;
  if (FFile.Size-FFile.Position >= HFPHeaderSize+SignatureSize) then
   begin
    FFile.ReadBuffer(HFPHeader,HFPHeaderSize);
    // check huge file signature
    if (HFPHeader.signature = HFSignature) then
     begin
       // check ESFS signature
       FFile.ReadBuffer(name,SignatureSize);
       if (name = ESingleFileSystemSignature) then
        result := true;
     end;
   end;
  FFile.Position := oldPos;
 end; //CheckFile

begin
 FStubSize := 0;
 buf := AllocMem($FFFF);
 offset := 0;
 FFile.Position := offset;
 sgn[0] := HFSignature[0];
 sgn[1] := HFSignature[1];
 sgn[2] := HFSignature[2];
 sgn[3] := HFSignature[3];
 // find local file header for first file in archive
 while FFile.Position < FFile.Size do
  begin
   pos := FFile.Position;
   size := FFile.Read(buf^,$FFFF);
   // find local file header signature
   i := 0;
   k := -1;
   while (i < size) do
    begin
     k := -1;
     if (pAnsiChar(Buf+i)^ = sgn[0]) then
      begin
       j := 1;
       while j <= 3 do
        begin
         if ((i + j) >= size) then break;
         if (pAnsiChar(Buf + i + j)^ <> sgn[j]) then break;
         inc(j);
         // signature found
         if (j > 3) then
           k := i;
        end; // chaeck signature
       if (k >= 0) then
        if (CheckFile(pos+k)) then
        // local file header for first file in archive found!
         break
        else
         k := -1;
      end; // signature found
     inc(i);
    end; // end of searching local header
   // stub size = difference between supposed offset for header
   // and real one
   if (k >= 0) then
    begin
     FStubSize := k+pos-offset;
     break;
    end;
  end;
 FFile.Position := offset;
 FreeMem(buf);
end;// CalculateStubSize


//------------------------------------------------------------------------------
// copy form source file
//------------------------------------------------------------------------------
function TESFSHugeFile.CopyFrom(Source: TESFSHugeFile; Count: Int64): Int64;
var oldPos,oldPos1,SourceSize:	Int64;
    outSize:					Integer;
    buf:            	PAnsiChar;
begin
 oldPos := Position;
 oldPos1 := Source.Position;
 if (Count <= 0) then
  begin
    Source.Position := 0;
   SourceSize := Source.Size;
  end
 else
  begin
   SourceSize := Source.Position + Count;
  end;
 result := 0;
 Size := 0;
 Position := 0;
 buf := AllocMem(FBlockSize);
 while Source.Position < SourceSize do
  begin
   if (SourceSize - Source.Position > FBlockSize) then
    outSize := FBlockSize
   else
    outSize := SourceSize - Source.Position;
   Source.ReadBuffer(buf^,outSize);
   WriteBuffer(buf^,outSize);
   result := result + Int64(outSize);
  end;
 FreeMem(buf);
 Position := oldPos;
 Source.Position := oldPos1;
end;// CopyFrom


//------------------------------------------------------------------------------
// save to stream
//------------------------------------------------------------------------------
procedure TESFSHugeFile.SaveToStream(Stream: TStream);
var outBytes,oldPos,oldPos1,inSize:	Int64;
    outSize:					Integer;
    buf:            	PAnsiChar;
    HFPartHeader: TESFSHugeFilePartitionHeader;
begin

 oldPos := Position;
 oldPos1 := Stream.Position;
 InitPartHeader(HFPartHeader);
 Stream.Write(HFPartHeader,HFPHeaderSize);
 Position := 0;
 outBytes := 0;
 inSize := Size;
 buf := AllocMem(FBlockSize);
 while outBytes < inSize do
    begin
   if (inSize - outBytes > FBlockSize) then
    outSize := FBlockSize
   else
    outSize := Size - outBytes;
   ReadBuffer(buf^,outSize);
   Stream.WriteBuffer(buf^,outSize);
   outBytes := outBytes + outSize;
  end;
 FreeMem(buf);
 Position := oldPos;
 Stream.Position := oldPos1;
end;


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TESFSHugeFile.LoadFromStream(Stream: TStream);
var oldPos,oldPos1:	Int64;
    outSize:					Integer;
    buf:            	PAnsiChar;
    HFPartHeader: TESFSHugeFilePartitionHeader;
begin
 oldPos := Position;
 oldPos1 := Stream.Position;
 Stream.Position := 0;
 Stream.Read(HFPartHeader,HFPHeaderSize);
 if (StrLComp(HFPartHeader.Signature, HFSignature, HFSignatureSize) <> 0) then
  raise Exception.Create('TESFSHugeFile.LoadFromStream - header corrupted or this is not ESFS file.');
 Size := 0;
 Position := 0;
// Stream.Position := HFPHeaderSize;
 buf := AllocMem(FBlockSize);
 while Stream.Position < Stream.Size do
  begin
   if (Stream.Size - Stream.Position > FBlockSize) then
    outSize := FBlockSize
   else
    outSize := Stream.Size - Stream.Position;
   Stream.ReadBuffer(buf^,outSize);
   WriteBuffer(buf^,outSize);
  end;
 FreeMem(buf);
 Position := oldPos;
 Stream.Position := oldPos1;
end;


//------------------------------------------------------------------------------
// close file
//------------------------------------------------------------------------------
procedure TESFSHugeFile.Close;
var
  i: integer;
begin
  // keep in-memory files open
  if (not FInMemory) then
   begin
    for i := 0 to Length(PartFiles)-1 do
     PartFiles[i].Free;
    SetLength(PartFiles, 0);
    FSize := 0;
   end;
  FPosition := 0;
  IsFileOpen := false;
end;// Close


//------------------------------------------------------------------------------
// flush file buffers
//------------------------------------------------------------------------------
procedure TESFSHugeFile.FlushBuffers;
var
  i: integer;
begin
  for i := 0 to Length(PartFiles)-1 do
   PartFiles[i].FlushBuffers;
end;// FlushBuffers


//------------------------------------------------------------------------------
// open file (with params specified in constructor)
//------------------------------------------------------------------------------
function TESFSHugeFile.Open(bCreate: boolean; bIgnoreErrors: boolean=false): boolean;
begin
 Result := InternalOpen(FFileName, bCreate, bIgnoreErrors);
end;// Open


//------------------------------------------------------------------------------
// read from file
//------------------------------------------------------------------------------
function TESFSHugeFile.Read(var Buffer; Count: Longint): Longint;
var
  ReadSize: LongInt;
  FileNo: integer;
  Offset: Int64;
  RestSize: Int64;
  PortionSize, sz: integer;
begin
  ReadSize := 0;
{$IFDEF DEBUG_TRACE_TESFSHugeFile_READ}
aaWriteToLog('0 TESFSHugeFile.FileRead. FPosition = '+IntToStr(FPosition)+#9+'Count = '+IntToStr(count));
{$ENDIF}
  // increase file size if required
  if (FPosition > FSize) then
   raise Exception.Create('TESFSHugeFile.Read - Stream read error.');
  // read
  while (ReadSize < Count) do
   begin
     // get part file No and offset there
     GetFileNoAndOffset(FPosition,FileNo,Offset);
{$IFDEF DEBUG_TRACE_TESFSHugeFile_READ}
aaWriteToLog('1 TESFSHugeFile.FileRead. FPosition = '+IntToStr(FPosition)+#9+'Offset = '+IntToStr(Offset)+#9+'FileNo = '+IntToStr(FileNo));
{$ENDIF}
     // data rest in last part file
     RestSize := FPartitionDataSize-Offset;
     if (FileNo = 0) then
       RestSize := RestSize - FStubSize;
     // get size of data portion to read
     if (RestSize < Count-ReadSize) then
      PortionSize := RestSize
     else
      PortionSize := Count-ReadSize;

     // if not first iteration - then make seek to part BOF
     if (ReadSize > 0) then
       PartFiles[FileNo].Position := HFPHeaderSize;
     // read portion
     sz := PartFiles[FileNo].Read((PAnsiChar(@Buffer)+ReadSize)^, PortionSize);
     inc(ReadSize, sz);
     FPosition := FPosition + Int64(sz);
     if (sz <> PortionSize) then
      break;
   end;
  Result := ReadSize;
{$IFDEF DEBUG_TRACE_TESFSHugeFile_READ}
aaWriteToLog('2 TESFSHugeFile.FileRead. Result = '+IntToStr(Result)+#9+'sz = '+IntToStr(sz)+#9+'FPosition = '+IntToStr(FPosition)+#9+'PortionSize = '+IntToStr(PortionSize));
{$ENDIF}
end;// Read


//------------------------------------------------------------------------------
// read known bytes from file
//------------------------------------------------------------------------------
procedure TESFSHugeFile.ReadBuffer(var Buffer; Count: Longint);
begin
  if (Count <> 0) and (Read(Buffer, Count) <> Count) then
    raise Exception.Create('TESFSHugeFile.ReadBuffer - Stream read error');
end;// ReadBuffer


//------------------------------------------------------------------------------
// seek in file
//------------------------------------------------------------------------------
function TESFSHugeFile.Seek(Offset: Int64; Origin: Word): Int64;
var
  FileNo: integer;
  FileOffset: Int64;
begin
  // calc global position
  case Origin of
    soFromBeginning:
        if (Offset < 0) then
         raise Exception.Create('TESFSHugeFile.Seek - Offset < 0 from file beginning.')
        else
         FPosition := Offset;
    soFromCurrent:
        FPosition := FPosition+Offset;
    soFromEnd:
        FPosition := FSize+Offset;
  end;
  // get corresponding FileNo and FileOffset
  GetFileNoAndOffset(FPosition, FileNo, FileOffset);
  // if possible - do physical seek
  if (FPosition <= FSize) then
   if (FileNo = 0) then
     PartFiles[FileNo].Position := FStubSize+FileOffset+Int64(HFPHeaderSize)
 //    PartFiles[FileNo].Seek(FStubSize+FileOffset+Int64(HFPHeaderSize),soFromBeginning)
   else
//     PartFiles[FileNo].Seek(FileOffset+Int64(HFPHeaderSize),soFromBeginning);
     PartFiles[FileNo].Position := FileOffset+Int64(HFPHeaderSize);
  // return new position
  Result := FPosition;
end;// Seek


//------------------------------------------------------------------------------
// write into the file
//------------------------------------------------------------------------------
function TESFSHugeFile.Write(const Buffer; Count: Longint): Longint;
var
  WrittenSize: LongInt;
  FileNo: integer;
  Offset: Int64;
  RestSize: Int64;
  PortionSize, sz: integer;
begin
  WrittenSize := 0;
  // increase file size if required
//  if ((FPosition > FSize) or (Count = 0)) then
//   if (FPosition > 0) then
//    SetSize(FPosition-1);
 Result := 0;
 if (Count <= 0) then
  Exit;
{$IFDEF DEBUG_TRACE_TESFSHugeFile_WRITE}
aaWriteToLog('0 TESFSHugeFile.FileWrite. FPosition = '+IntToStr(FPosition)+#9+'Count = '+IntToStr(count));
{$ENDIF}
 // write beyond end of the file
 if (FPosition > FSize) then
  begin
   offset := FPosition;
   Position := 0;
   SetSize(Offset);
   Position := Offset;
   if (Position <> Offset) then
     Exit;
  end;
  // write
  while (WrittenSize < Count) do
   begin
     // get part file No and offset there
     GetFileNoAndOffset(FPosition,FileNo,Offset);
{$IFDEF DEBUG_TRACE_TESFSHugeFile_WRITE}
 aaWriteToLog('1 TESFSHugeFile.FileWrite. FPosition = '+IntToStr(FPosition)+#9+'Offset = '+IntToStr(Offset)+#9+'FileNo = '+IntToStr(FileNo));
{$ENDIF}
     // if necessary append another part file
     if (FileNo >= Length(PartFiles)) then
      AppendPartFile
     else
     // if not first iteration - then make seek to part BOF
     if (WrittenSize > 0) then
//       PartFiles[FileNo].Seek(HFPHeaderSize, soFromBeginning);
       PartFiles[FileNo].Position := HFPHeaderSize;
     // free rest in last part file
     RestSize := FPartitionDataSize-Offset;
     // get size of data portion to write
     if (RestSize < Count-WrittenSize) then
      PortionSize := RestSize
     else
      PortionSize := Count-WrittenSize;
     // write portion
     sz := PartFiles[FileNo].Write((PAnsiChar(@Buffer)+WrittenSize)^, PortionSize);
     inc(WrittenSize, sz);
     FPosition := FPosition + Int64(sz);
     // update file size variable
     if (FPosition > FSize) then
      FSize := FPosition;
     if (sz <> PortionSize) then
      break;
   end;
  Result := WrittenSize;
end;// Write


//------------------------------------------------------------------------------
// write known bytes into the file
//------------------------------------------------------------------------------
procedure TESFSHugeFile.WriteBuffer(const Buffer; Count: Longint);
begin
  if (Count <> 0) and (Write(Buffer, Count) <> Count) then
    raise Exception.Create('TESFSHugeFile.WriteBuffer - Stream write error');
end;// WriteBuffer


//------------------------------------------------------------------------------
// copy file
//------------------------------------------------------------------------------
function TESFSHugeFile.CopyFile(const NewName: AnsiString): Boolean;
var
  PureFileName, NewPath, ExistingPath: AnsiString;
  HFPHeader: TESFSHugeFilePartitionHeader;
  CurFileName, NewFileName, s, s1: AnsiString;
  PartFile: TESFSAbstractFile;
  HF: TESFSHugeFile;
  i: Int64;
begin
  Result := true;
  // extract file name w/o path
  PureFileName := ExtractFileName(FFileName);
  NewFileName := ExtractFileName(NewName);
  ExistingPath := ExtractFilePath(FFileName);
  NewPath := ExtractFilePath(NewName);
  // copy first part file
  // in-memory file?
  if (FInMemory) then
   begin
     if (Length(PartFiles) <> 1) then
       raise Exception.Create('TESFSHugeFile.CopyFile - Cannot copy memory ESFS file.');
     HF := TESFSHugeFile.Create(NewName, false, true, false);
     HF.Open(true);
     i := Position;
     Position := 0;
     HF.CopyFrom(self, FSize);
     HF.Close;
     HF.Free;
     Position := i;
     result := True;
     exit;
   end
  else
  if (not Windows.CopyFileA(PAnsiChar(FFileName), PAnsiChar(NewName), False)) then
   begin
    Result := false;
    exit;
   end;
  // process parts
  CurFileName := NewName;
  i := 0;
  repeat
    PartFile := TESFSDiskFile.Create(CurFileName, FReadOnly, FExclusive);
    if (not PartFile.Open(false)) then
     begin
      PartFile.Free;
      Result := false;
      break;
     end;
    // read header
    if (i = 0) then
     PartFile.Position := FStubSize
    else
     PartFile.Position := 0;
    PartFile.Read(HFPHeader, HFPHeaderSize);
    // rename file
    s1 := HFPHeader.NextFileName;
    // last file in chain?
    if (s1 = '') then
     begin
      PartFile.Free;
      break;
     end;
    s := StringReplace(s1, PureFileName, NewFileName, [rfReplaceAll, rfIgnoreCase]);
    if (not Windows.CopyFileA(PAnsiChar(ExistingPath+s1), PAnsiChar(NewPath+s), false)) then
     begin
      Result := false;
      PartFile.Free;
      break;
     end;
    // update header
    Move(PAnsiChar(s)^, HFPHeader.NextFileName, Length(s)+1);
    // write header
    if (i = 0) then
     PartFile.Position := FStubSize
    else
     PartFile.Position := 0;
    if (PartFile.Write(HFPHeader, HFPHeaderSize) <> HFPHeaderSize) then
     begin
      Result := false;
      PartFile.Free;
      break;
     end;
    // close file
    PartFile.Free;
    CurFileName := NewPath+HFPHeader.NextFileName;
    inc(i);
   until false;
end;// CopyFile


//------------------------------------------------------------------------------
// rename file
//------------------------------------------------------------------------------
function TESFSHugeFile.RenameFile(const NewName: AnsiString): Boolean;
var
  PureFileName, Path: AnsiString;
  HFPHeader: TESFSHugeFilePartitionHeader;
  i: integer;
  CurFileName, NewFileName, s, s1: AnsiString;
  PartFile: TESFSAbstractFile;
begin
  Result := true;
  // extract file name w/o path
  PureFileName := ExtractFileName(FFileName);
  NewFileName := ExtractFileName(NewName);
  Path := ExtractFilePath(FFileName);
  // rename first part file
  // in-memory file?
  if (FInMemory) then
   begin
     if (Length(PartFiles) = 0) then
       raise Exception.Create('TESFSHugeFile.RenameFile - No memory files exist.');
     PartFiles[0].FileName := Path+NewFileName;
   end
  else
  if (not SysUtils.RenameFile(FFileName, Path+NewFileName)) then
   begin
    Result := false;
    exit;
   end;
  FFileName := Path+NewFileName;
  CurFileName := FFileName;
  // process parts
  i := 0;
  repeat
    if (FInMemory) then
     PartFile := PartFiles[i]
    else
     begin
      PartFile := TESFSDiskFile.Create(CurFileName, FReadOnly, FExclusive);
      if (not PartFile.Open(false)) then
       begin
        PartFile.Free;
        Result := false;
        break;
       end;
     end;
    // read header
    if (i = 0) then
     PartFile.Position := FStubSize
    else
     PartFile.Position := 0;
    PartFile.Read(HFPHeader, HFPHeaderSize);
    // rename file
    s1 := HFPHeader.NextFileName;
    // last file in chain?
    if (s1 = '') then
     begin
      if (not FInMemory) then
       PartFile.Free;
      break;
     end;
    s := StringReplace(s1, PureFileName, NewFileName, [rfReplaceAll, rfIgnoreCase]);
    if (FInMemory) then
     begin
      PartFiles[i+1].FileName := Path+s;
     end
    else
    if (not SysUtils.RenameFile(Path+s1, Path+s)) then
     begin
      Result := false;
      PartFile.Free;
      break;
     end;
    // update header
    Move(PAnsiChar(s)^, HFPHeader.NextFileName, Length(s)+1);
    // write header
    if (i = 0) then
     PartFile.Position := FStubSize
    else
     PartFile.Position := 0;
    if (PartFile.Write(HFPHeader, HFPHeaderSize) <> HFPHeaderSize) then
     begin
      SysUtils.RenameFile(Path+s, s1);
      Result := false;
      if (not FInMemory) then
       PartFile.Free;
      break;
     end;
    // close file
    if (not FInMemory) then
     PartFile.Free;
    CurFileName := Path+HFPHeader.NextFileName;
    inc(i);
   until false;
end;// RenameFile


//------------------------------------------------------------------------------
// delete file
//------------------------------------------------------------------------------
function TESFSHugeFile.DeleteFile: Boolean;
var
  i: integer;
  Path, CurFileName, s1: AnsiString;
  PartFile: TESFSAbstractFile;
  HFPHeader: TESFSHugeFilePartitionHeader;
begin
  if (FInMemory) then
   begin
    for i := 0 to Length(PartFiles)-1 do
     PartFiles[i].Free;
    SetLength(PartFiles, 0);
    FSize := 0;
    Result := true;
   end
  else
   begin
    Result := true;
    Path := ExtractFilePath(FFileName);
    CurFileName := FFileName;
    // process parts
    i := 0;
    repeat
      PartFile := TESFSDiskFile.Create(CurFileName, FReadOnly, FExclusive);
      if (not PartFile.Open(false)) then
       begin
        PartFile.Free;
        Result := false;
        break;
       end;
      // read header
      if (i = 0) then
       PartFile.Position := FStubSize
      else
       PartFile.Position := 0;
      PartFile.Read(HFPHeader, HFPHeaderSize);
      s1 := HFPHeader.NextFileName;
      // close file
      PartFile.Free;
      if (not SysUtils.DeleteFile(CurFileName)) then
       begin
        Result := false;
        break;
       end;
      // last file in chain?
      if (s1 = '') then
       begin
        break;
       end;
      CurFileName := Path+HFPHeader.NextFileName;
      inc(i);
     until false;
   end;
end;// DeleteFile


function  GetMaxFileSize(FileName: AnsiString) : Int64;
//type
//  TOSType = (osUnknown, osWin95, osWin98, osWinME, osWinNT351, osWinNT4, osWin2K, osWinXP, osWinNET );
const
  TwoGigabytes   = $7FFFFFFF;
  FourGigabytes  = $FFFFFFFF;
  MaxHDFloppy    = $00163E00;
  MaxInt64Value  = $7FFFFFFFFFFFFFFE ; // 2^64
var
//  OsType: TOSType;
//  OSVersion        : TOSVersionInfo;
  MaxFileNameLen   : DWord;
  FileSysFlags     : Dword;
  FileSysName      : array[0..MAX_PATH - 1] of AnsiChar;
  VolumeName       : array[0..MAX_PATH - 1] of AnsiChar;
  FileDrive        : AnsiString;
  MaxFileSize      : Int64;
  Size1,Size2,Size3: Int64;
  vers             : DWORD;
  bWinNTAndHigher  : Boolean;
begin
// changed in 2.70 - for Wn9x compatibility
  vers := GetVersion;
  bWinNTAndHigher := (vers < $80000000);
{
  // Get OS Version
  FillChar(OSVersion, SizeOf(TOSVersionInfo), 0);
  OSVersion.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  GetVersionEx(OSVersion);

  // Set version to Unknown for default
  OsType := osUnknown;

  case OSVersion.dwMajorVersion of
   3: OsType := osWinNT351;
   4: case OSVersion.dwMinorVersion of
        0:   if OSVersion.dwPlatformId = 1 then OsType := osWin95
                                           else OsType := osWinNT4;
        10:  OsType := osWin98;
        90:  OsType := osWinME;
      end;
   5: case OSVersion.dwMinorVersion of
        0:   OsType := osWin2K;
        1:   OsType := osWinXP;
        2:   OsType := osWinNET;
      end;
  end;
  if OsType = osUnknown then
   if (OSVersion.dwMajorVersion >= 5) then
    OsType := osWinXP;

  if OsType = osUnknown then
   raise Exception.Create('Can''t Identify OS version');
}
  FileDrive := ExtractFileDrive(FileName);
  FileDrive := FileDrive + '\';
  MaxFileSize := 0;
  if GetVolumeInformationA(PAnsiChar(FileDrive), VolumeName, Length(VolumeName),
      nil, Maxfilenamelen, FileSysFlags, FileSysName, SizeOf(FileSysName)) then
   begin
    if FileSysName = 'FAT32' then
// changed in 2.70 - for Wn9x compatibility
//     if OsType in [osWin2K, osWinXP, osWinNET] then
     if bWinNTAndHigher then
      MaxFileSize := FourGigabytes // Win2K max FAT32 file size = 4GB
     else
      MaxFileSize := TwoGigabytes  // Win95/98 max FAT32 file size = 2GB
    else if FileSysName = 'NTFS' then
      MaxFileSize := MaxInt64Value // NTFS max file size = 2^64
    else if FileSysName = 'FAT16' then // NT max FAT16 partition = 4GB; Max File Size = 2GB
      MaxFileSize := TwoGigabytes
    else if FileSysName = 'CDFS' then // Can't write to a CD-ROM drive
      MaxFileSize := 0
    else if FileSysName = 'FS_UDF' then // Rewriteble
     begin
      GetDiskFreeSpaceExA(PAnsiChar(FileDrive), Size1,Size2,@Size3);
      MaxFileSize := Size1;  // Set Max File Size to Free Size on device
     end
    else if FileSysName = 'FAT' then
      if (FileDrive = 'A:\') or (FileDrive = 'B:\') then
        MaxFileSize := MaxHDFloppy
      else
        MaxFileSize := TwoGigabytes
   end;
  Result := MaxFileSize;
  //ShowMessage('OS:' + IntToStr(integer(OsType)) + ' FS: ' + FileSysName + ' MaxFileSize: ' + IntToStr(MaxFileSize));
end;


end.
