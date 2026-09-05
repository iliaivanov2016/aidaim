unit utStrUtils;

interface

{$I UTConfig.Inc}

uses SysUtils, Classes,
     uTestList,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRStrUtils;

type
  TUnitTestStrUtils = class(TUnitTest)
   public
    procedure TestShort; override;
    procedure TestExceptions; override;
   public
    procedure InternalTestInitOrderedChars;
    procedure InternalTestUpperCase;
  end;


var
  UnitTestStrUtils: TUnitTestStrUtils;



implementation


{ TUnitTestStrUtils }


procedure TUnitTestStrUtils.TestShort;
begin
  CheckAction(InternalTestInitOrderedChars, 'init OrderedChars');
end;


procedure TUnitTestStrUtils.TestExceptions;
begin
end;



procedure TUnitTestStrUtils.InternalTestUpperCase;
begin
;
end;

procedure TUnitTestStrUtils.InternalTestInitOrderedChars;
var fs: TFileStream;
    i,j: Byte;
    n: Byte;
    c: Char;
    s: String;
    pc: PChar;
begin
 //InitOrderedChars;

 // Check for Unic SortOrder
 for i:=0 to 255 do
   begin
     n := 0;
     for j:=0 to 255 do
       if OrderedChars[i] = OrderedChars[j] then
         inc(n);
     if (n <> 1) then
       raise Exception.Create('SortOrder Table has not unic elements');
   end;

 fs := TFileStream.Create(TempDir + 'OrderedChars.bin', fmCreate);
 try
   fs.Write(OrderedChars,256);
 finally
   fs.Free;
 end;

 fs := TFileStream.Create(TempDir + 'OrderedChars.txt', fmCreate);
 try
   for i:=0 to 255 do
     for j:=0 to 255 do
       if OrderedChars[j] = i then
         begin
           c := chr(j);
           fs.Write(c, 1);
           break;
         end;
 finally
   fs.Free;
 end;


// i := OrderedChars[253{ord('')}];
// j := OrderedChars[255{ord('')}];
  //pc := nil;


  s:='AaBbCcܻ';
  i := Length(s);
  pc := AllocMem(i+1);
  move(PChar(s)^, pc^, i);

  //ToUpperCase(pc);

  ChangeCaseCustom(pc, nil);
  ChangeCaseCustom(pc, @ToUpperChars);
  ToLowerCase(pc);
  ToUpperCase(pc);

  FreeMem(pc);
  DeleteFile(TempDir + 'OrderedChars.bin');
  DeleteFile(TempDir + 'OrderedChars.txt');

end;

initialization
  UnitTestStrUtils := TUnitTestStrUtils.Create(UnitTestList);

finalization
  UnitTestStrUtils.Free;

end.
