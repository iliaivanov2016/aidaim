unit utMemoryManager;
interface

{$I UTConfig.Inc}

uses uTestList, SysUtils,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
    ACRMemory, ACRTypes
  ;
type
  TUnitTestMemoryManager = class(TUnitTest)
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
   public
    procedure TestGetMem;
    procedure TestReallocMemAndClearTail;
    procedure TestMemoryOverrunException;
  end;

var
  UnitTestMemoryManager: TUnitTestMemoryManager;

implementation

{ TUnitTestMemoryManager }

procedure TUnitTestMemoryManager.TestShort;
begin
  CheckAction(TestGetMem, 'GetMem Test');
  CheckAction(TestReallocMemAndClearTail, 'Test function ReallocMemAndClearTail');
end;

procedure TUnitTestMemoryManager.TestExceptions;
begin
  CheckAction(TestMemoryOverrunException, 'MemoryOverrunException Test');
end;

procedure TUnitTestMemoryManager.TestGetMem;
type tarr = array[1..1024] of byte;
     parr = ^tarr;
var
    ar: tarr;
    par: parr;
    i: Integer;
begin
   for i:=1 to 1024 do
     ar[i] := i mod 256;
   par := MemoryManager.GetMem(2048*100);
   try
     move(ar, par^, 1024);
     MemoryManager.ReallocMem(par, 1024 * 10000);
     MemoryManager.ReallocMem(par, 10000);
     //i := MemoryManager.GetMemoryBufferSize(Par);
     for i:=1 to 1024 do
       if (ar[i] <> par^[i]) then
        raise Exception.Create('Realloc and move error.');
   finally
     MemoryManager.FreeAndNilMem(par);
   end;
end;

procedure TUnitTestMemoryManager.TestMemoryOverrunException;
var
  p: Pointer;
begin
  // Correct Fill
  p := MemoryManager.AllocMem(1024);
  try
    FillChar(p^, 1024, ord('G'));
  finally
    MemoryManager.FreeAndNilMem(p);
  end;
  WriteToProcessLog('Correct Fill Processed.');

  // Overrun Fill
  p := MemoryManager.AllocMem(1024);
  try
    try
      FillChar(p^, 1025, ord('G'));
    finally
      MemoryManager.FreeAndNilMem(p);
    end;
    WriteToErrorLog('Error detecting Overrun');
  except
    on e: Exception do
      WriteToProcessLog('Overrun detected correctly. ErrorMessage: ' + e.Message);
  end;

end;




procedure TUnitTestMemoryManager.TestReallocMemAndClearTail;
var
    i: Integer;
    buf: PChar;
    buf_et: PChar;
begin


   buf_et := MemoryManager.GetMem(1024);
   buf := MemoryManager.GetMem(1024);
   for i := 0 to 1023 do
     pByte(buf_et + i)^ := i mod 256;
   try

     Move(buf_et^,buf^,1024);

     MemoryManager.ReallocMemAndClearTail(buf, 2048);
     for i := 0 to 1023 do
       if (pByte(buf + i)^ <> PByte(buf_et + i)^) then
        WriteToErrorLog('utMemoryManager - ReallocMemAndClearTail and move error.');

     for i:=1024 to 2047 do
       if (pByte(buf + i)^ <> 0) then
        WriteToErrorLog('utMemoryManager - ReallocMemAndClearTail Clear error.');

   finally
     MemoryManager.FreeAndNilMem(buf);
     MemoryManager.FreeAndNilMem(buf_et);
   end;

end;

initialization
  UnitTestMemoryManager := TUnitTestMemoryManager.Create(UnitTestList);

finalization
  UnitTestMemoryManager.Free;
end.
