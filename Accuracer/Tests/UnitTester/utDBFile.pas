unit utDBFile;

interface

{$I UTConfig.Inc}

uses SysUtils, Classes,
     uTestList,
     ACRTypes,
{$IFDEF ACR5H}
     ACRComMain, ACRDatabaseFile,
{$ENDIF}
     ACRDiskEngine;

type
  TUnitTestDBFile = class(TUnitTest)
   public
    procedure TestShort; override;
   public
    procedure tCreateFile;
  end;


var
  UnitTestDBFile: TUnitTestDBFile;



implementation


{ TUnitTestDBFile }


procedure TUnitTestDBFile.TestShort;
begin
  CheckAction(tCreateFile, 'CreateFile');
end;


procedure TUnitTestDBFile.tCreateFile;
var
  f: TACRDatabaseFile;
  s: String;
  fs: TFileStream;
  i: Integer;
  FileName: String;
  res: Boolean;
  am: TACRAccessMode;
  sm: TACRShareMode;
begin
  FileName := TempDir + 'db.acr';
  f := TACRDatabaseFile.Create;
  try
    f.CreateAndOpenFile(FileName);
    s := 'qwerty';
    f.WriteBuffer(PChar(s)^, Length(s), 20, 001);
    s := 'AAA';
    f.WriteBuffer(PChar(s)^, Length(s), 2, 002);
    SetLength(s, 6);
    f.ReadBuffer(s[1], 6, 20, 003);
    if s <> 'qwerty' then
      WriteToErrorLog('Read/Write Error');

    f.Size := 1024;
    if f.Size <> 1024 then
      WriteToErrorLog('SetSize/GetSize Error');

    f.Position := 2048;
    if f.Position <> 2048 then
      WriteToErrorLog('SetPosition/GetPosition Error');

    //f.Position := 10000000000;
    f.Size := 5000;
    f.CloseFile;

    am := amReadWrite;
    sm := smExclusive;
    {$IFDEF ACR5H}
    f.OpenFile(FileName, '', am, sm,False);
    {$ELSE}
    f.OpenFile(FileName, '', am, sm);
    {$ENDIF}
    s := 'BBB';
    f.WriteBuffer(PChar(s)^, Length(s), 5000-3, 0013);
    f.CloseFile;


    // Locks
{$IFDEF FILE_SERVER_VERSION}
    f.OpenFile(FileName, amReadWrite, smExclusive);
    if not f.LockByte(13, 1) then
      WriteToErrorLog('#1: Lock Byte Error');
    // Double Lock
    if f.LockByte(13, 1) then
      WriteToErrorLog('#2: Double Lock Byte Error');
    // Check Locked
    if not f.IsByteLocked(13) then
      WriteToErrorLog('#3: Check Lock Byte Error');
    // Check Region Locked
    if not f.IsRegionLocked(12,3) then
      WriteToErrorLog('#4: Check Region Lock Error');
    // Unlock
    if not f.UnlockByte(13, 1) then
      WriteToErrorLog('#5: Unock Byte Error');
    // Double Unlock
    if f.UnlockByte(13, 1) then
      WriteToErrorLog('#6: Double Unock Byte Error');
    // Check Locked
    if f.IsByteLocked(13) then
      WriteToErrorLog('#7: Check Lock Byte Error');
    // Check Region Locked
    if f.IsRegionLocked(12,3) then
      WriteToErrorLog('#8: Check Region Lock Error');
    f.CloseFile;
{$ENDIF}
    {$IFDEF ACR5H}
    f.DeleteFile;
    {$ELSE}
    f.DeleteFile(f.FileName);
    {$ENDIF}

  finally
    f.Free;
  end;
end;

initialization
  UnitTestDBFile := TUnitTestDBFile.Create(UnitTestList);

finalization
  UnitTestDBFile.Free;

end.
