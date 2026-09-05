unit MainUnit;

interface

{DEFINE MEMCHECK}
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  SingleFileSystem,SFSEngine, StdCtrls, Db, Gauges, FileCtrl, SFSPassword,aaDebug
{$IFDEF MEMCHECK}
  ,  MemCheck
{$ENDIF}
  ;

const TestCount = 30000; // TestCount mod 2 shold be always 0
//const TestCount = 10000; // TestCount mod 2 shold be always 0
//const TestCount = 25000; // TestCount mod 2 shold be always 0
//const TestCount = 10; // TestCount mod 2 shold be always 0
//const TestCount = 10; // TestCount mod 2 shold be always 0

type
  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    cmbDirArray: TButton;
    Info: TMemo;
    cmbClose: TButton;
    CurrentProgress: TGauge;
    Label1: TLabel;
    OverallProgress: TGauge;
    Label2: TLabel;
    Button1: TButton;
    cmbDIRManager: TButton;
    btPageManager: TButton;
    btUFPMTest: TButton;
    cbnFFSTest: TButton;
    Button2: TButton;
    procedure cmbCloseClick(Sender: TObject);
    procedure cmbDirArrayClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure cmbDIRManagerClick(Sender: TObject);
    procedure btPageManagerClick(Sender: TObject);
    procedure btUFPMTestClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cbnFFSTestClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure TestDIRArray;
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.TestDIRArray;
label m1;
var dir:    TDirArray;
    el,el1: TDirectoryElement;
    str:    string;
    sList:  TStringList;
    pID:    array of Integer;
    i,l,n:  integer;
    bOk:    Boolean;
    sr:     TSearchRec;
begin
 bOk := true;
 sList := TStringList.Create;
 SetLength(pID,testCount);
 dir := TDirArray.Create;
 Info.Text := Info.Text + 'Testing DIRArray. FileCount = '+inttostr(TestCount)+
              '... '+#13#10+#13#10;
 OverallProgress.Progress := 0;
 OverallProgress.MaxValue := 9; // number of test
 CurrentProgress.MaxValue := TestCount;
//goto  m1;
 // testing appends
 CurrentProgress.Progress := 0;
 aaInitTime;
 Info.Text := Info.Text + 'Testing appends... '+#13#10;
 Application.ProcessMessages;
 for i := 1 to TestCount do
  begin
//   str := 'file'+inttostr(Random(MAXINT) mod TestCount);
   str := 'file'+inttostr(i);
   sList.Add(str);
   l := StrLen(pChar(str));
   if (l >= 260) then
    l := 259;
   Move(pChar(str)^,el.FileName,l);
   el.FileName[l] := #0;

   el.FileSize := 0;

   if (i mod 2 = 0) then
    el.ParentID := -1
   else
    // this is invalid value, for debug only
    el.ParentID := i;
   pID[i-1] := el.ParentID;
   el.IsFolder := 0;
   el.IsDeleted := 0;
   el.FirstMapPageNo := i;
   aaStartTime;
   dir.AppendItem(el);
   aaStopTime;

   CurrentProgress.Progress := i;
   Application.ProcessMessages;
  end;
 Info.Text := Info.Text +'Append time = '+Inttostr(aaGetTime)+#13#10+#13#10;
 // number of test
 OverallProgress.Progress := OverallProgress.Progress +1;
 // testing find by name
 CurrentProgress.Progress := 0;
 aaInitTime;
 Info.Text := Info.Text + 'Testing find file by name... '+#13#10;
 Application.ProcessMessages;
 for i := 1 to TestCount do
  begin
   str := sList.Strings[i-1];
   l := StrLen(pChar(str));
   if (l >= 260) then
    l := 259;
   Move(pChar(str)^,el.FileName,l+1);
   aaStartTime;
   n := dir.FindPositionForInsert(el,true,false,false);
   aaStopTime;
   if (n < 0) then
    begin
     bOk := false;
     Info.Text := Info.Text + 'Error in Name Index - element not found!'+#13#10;
     break;
    end;
   el1 := dir.ReadItem(dir.NameIndex.items[n]);
   l := AnsiStrComp(
       AnsiStrLower(pChar(@el.fileName)),
       AnsiStrLower(pChar(@el1.fileName)));
   if (l <> 0) then
    begin
     bOk := false;
     Info.Text := Info.Text + 'Error in Name Index - invalid element found!'+#13#10;
     break;
    end;
   CurrentProgress.Progress := CurrentProgress.Progress + i;
   Application.ProcessMessages;
  end;
 Info.Text := Info.Text +'Find by name time = '+Inttostr(aaGetTime)+#13#10;
 // number of test
 OverallProgress.Progress := OverallProgress.Progress +  1;
 // testing find by parent ID
 CurrentProgress.Progress := 0;
 aaInitTime;
 Info.Text := Info.Text + #13#10+'Testing find file by parent ID... '+#13#10;
 Application.ProcessMessages;
 for i := 1 to TestCount do
  begin
   el.ParentID := pID[i-1];
   aaStartTime;
   n := dir.FindPositionForInsert(el,false,false,false);
   aaStopTime;
   if (n < 0) then
    begin
     bOk := false;
     Info.Text := Info.Text + 'Error in Parent Index - element not found!'+#13#10;
     break;
    end;
   el1 := dir.ReadItem(dir.ParentIndex.items[n]);
   if (el.parentID <> el1.parentID) then
    begin
     bOk := false;
     Info.Text := Info.Text + 'Error in Parent Index - invalid element found!'+#13#10;
     break;
    end;
   CurrentProgress.Progress := CurrentProgress.Progress + i;
   Application.ProcessMessages;
  end;
 Info.Text := Info.Text +'Find by parent ID time = '+Inttostr(aaGetTime)+#13#10;
 // number of test
 OverallProgress.Progress := OverallProgress.Progress +  1;
 Application.ProcessMessages;
 //----------------------------- update test -------------------------------
 dir.SetSize(0);
 sList.Clear;
 // testing appends
 CurrentProgress.Progress := 0;
 aaInitTime;
 Info.Text := Info.Text + 'Testing appends for update test... '+#13#10;
 Application.ProcessMessages;
 for i := 1 to TestCount do
  begin
   str := 'file'+inttostr(i);
//   str := 'file'+inttostr(Random(MAXINT) mod TestCount);
   sList.Add(str);
   l := StrLen(pChar(str));
   if (l >= 260) then
    l := 259;
   Move(pChar(str)^,el.FileName,l);
   el.FileName[l] := #0;
   el.FileSize := 0;
//   if (i mod 2 = 0) then
//    el.ParentID := -1
//   else
    // this is invalid value, for debug only
    el.ParentID := i;
   pID[i-1] := el.ParentID;
   el.IsFolder := 0;
   if (i mod 2 = 0) then
    el.IsDeleted := 0
   else
    el.IsDeleted := 1;
   el.FirstMapPageNo := i;
   aaStartTime;
   dir.AppendItem(el);
   aaStopTime;
   CurrentProgress.Progress := i;
   Application.ProcessMessages;
  end;
 Info.Text := Info.Text +'Append time = '+Inttostr(aaGetTime)+#13#10+#13#10;
 // number of test
 OverallProgress.Progress := OverallProgress.Progress +1;
 // testing appends
 CurrentProgress.Progress := 0;
 aaInitTime;
 Info.Text := Info.Text + 'Testing updates... '+#13#10;
 Application.ProcessMessages;
 for i := 1 to TestCount do
  begin
   if (i <= TestCount div 2) then
    begin
     el := dir.Items[i-1];
     el.IsDeleted := 1;
     aaStartTime;
     dir.UpdateItem(el,i-1);
     aaStopTime;
    end
   else
    begin
     el := dir.Items[i-1];
     el.IsDeleted := 0;
     aaStartTime;
     dir.UpdateItem(el,i-1);
     aaStopTime;
    end;
   CurrentProgress.Progress := i;
   Application.ProcessMessages;
  end;
 Info.Text := Info.Text +'Update time = '+Inttostr(aaGetTime)+#13#10+#13#10;
 // number of test
 OverallProgress.Progress := OverallProgress.Progress +1;
 Application.ProcessMessages;
 // testing find by name
 CurrentProgress.Progress := 0;
 aaInitTime;
 Info.Text := Info.Text + 'Testing find file by name... '+#13#10;
 Application.ProcessMessages;
 for i := 1 to TestCount do
  begin
   str := sList.Strings[i-1];
   l := StrLen(pChar(str));
   if (l >= 260) then
    l := 259;
   Move(pChar(str)^,el.FileName,l+1);
   aaStartTime;
   n := dir.FindPositionForInsert(el,true,false,false);
   aaStopTime;
   if ((n < 0) and (i > TestCount div 2))
      or
      ((n >= 0) and (i <= TestCount div 2))then
    begin
     bOk := false;
     Info.Text := Info.Text + 'Error in Name Index - element not found!'+#13#10;
     break;
    end;
   if (n >= 0) and (i > TestCount div 2) then
    begin
     el1 := dir.ReadItem(dir.NameIndex.items[n]);
     l := AnsiStrComp(
       AnsiStrLower(pChar(@el.fileName)),
       AnsiStrLower(pChar(@el1.fileName)));
     if (l <> 0) then
      begin
       bOk := false;
       Info.Text := Info.Text + 'Error in Name Index - invalid element found!'+#13#10;
       break;
      end;
    end;
   CurrentProgress.Progress := CurrentProgress.Progress + i;
   Application.ProcessMessages;
  end;
 Info.Text := Info.Text +'Find by name time = '+Inttostr(aaGetTime)+#13#10;
 // number of test
 OverallProgress.Progress := OverallProgress.Progress +  1;
 // testing find by parent ID
 CurrentProgress.Progress := 0;
 aaInitTime;
 Info.Text := Info.Text + #13#10+'Testing find file by parent ID... '+#13#10;
 Application.ProcessMessages;
 for i := 1 to TestCount do
  begin
   el.ParentID := pID[i-1];
   aaStartTime;
   n := dir.FindPositionForInsert(el,false,false,false);
   aaStopTime;
   if ((n < 0) and (i > TestCount div 2))
      or
      ((n >= 0) and (i <= TestCount div 2))then
    begin
     bOk := false;
     Info.Text := Info.Text + 'Error in Parent Index - element not found!'+#13#10;
     break;
    end;
   if (n >= 0) and (i > TestCount div 2) then
    begin
     el1 := dir.ReadItem(dir.ParentIndex.items[n]);
     if (el.parentID <> el1.parentID) then
      begin
       bOk := false;
       Info.Text := Info.Text + 'Error in Parent Index - invalid element found!'+#13#10;
       break;
      end;
    end;
   CurrentProgress.Progress := CurrentProgress.Progress + i;
   Application.ProcessMessages;
  end;
 Info.Text := Info.Text +'Find by parent ID time = '+Inttostr(aaGetTime)+#13#10;
 // number of test
 OverallProgress.Progress := OverallProgress.Progress +  1;
 Application.ProcessMessages;

m1: ;
 //----------------------------- pathfinding test --------------------------------
 dir.SetSize(0);
 sList.Clear;
 CurrentProgress.Progress := 0;
 Info.Text := Info.Text + 'Testing FindFileByName... '+#13#10;
 Application.ProcessMessages;
 //--------------------
 // test directory:
 // root contains folders 1,2 and files 1,2
 // \folder1 contains folder1,2 and file1
 // \folder2 contains folder1,2 and file2
 // \folder1\folder1 contains file1
 // \folder1\folder2 contains file2
 // \folder2\folder1 contains file1
 // \folder2\folder2 contains file2
 //--------------------
 el.IsDeleted := 0;
 el.ParentID := -1;
 // making root structure
 el.FileName := 'Folder1'+#0;
 el.IsFolder := 1;
 el.Attributes := 0;
 dir.AppendItem(el);
 el.FileName := 'Folder2'+#0;
 el.IsFolder := 1;
 el.Attributes := 1;
 dir.AppendItem(el);
 el.FileName := 'file1.txt'+#0;
 el.IsFolder := 0;
 el.Attributes := 2;
 dir.AppendItem(el);
 el.FileName := 'file2.txt'+#0;
 el.IsFolder := 0;
 el.Attributes := 3;
 dir.AppendItem(el);
 // \folder1
 el.ParentID := 0;
 el.FileName := 'Folder1'+#0;
 el.IsFolder := 1;
 el.Attributes := 4;
 dir.AppendItem(el);
 el.FileName := 'Folder2'+#0;
 el.IsFolder := 1;
 el.Attributes := 5;
 dir.AppendItem(el);
 el.FileName := 'file1.txt'+#0;
 el.IsFolder := 0;
 el.Attributes := 6;
 dir.AppendItem(el);
 // folder2
 el.ParentID := 1;
 el.FileName := 'Folder1'+#0;
 el.IsFolder := 1;
 el.Attributes := 7;
 dir.AppendItem(el);
 el.FileName := 'Folder2'+#0;
 el.IsFolder := 1;
 el.Attributes := 8;
 dir.AppendItem(el);
 el.FileName := 'file2.txt'+#0;
 el.IsFolder := 0;
 el.Attributes := 9;
 dir.AppendItem(el);
 // files in 3 level
 el.IsFolder := 0;
 // \folder1\folder1\file1.txt
 el.ParentID := 4;
 el.FileName := 'file1.txt'+#0;
 el.Attributes := 10;
 dir.AppendItem(el);
 // \folder1\folder2\file2.txt
 el.ParentID := 5;
 el.FileName := 'file2.txt'+#0;
 el.Attributes := 11;
 dir.AppendItem(el);
 // \folder2\folder1\file1.txt
 el.ParentID := 7;
 el.FileName := 'file1.txt'+#0;
 el.Attributes := 12;
 dir.AppendItem(el);
 // \folder2\folder2\file2.txt
 el.ParentID := 8;
 el.FileName := 'file2.txt'+#0;
 el.Attributes := 13;
 dir.AppendItem(el);
 // \folder1\folder1\aaa...aa
 el.ParentID := 4;
 for i := 0 to 258 do
  el.FileName[i] := 'a';
 el.FileName[259] := #0;
 el.Attributes := 14;
 dir.AppendItem(el);
 // \folder1\folder2\aaa...aa
 el.ParentID := 5;
 el.Attributes := 15;
 dir.AppendItem(el);
 // \folder1\folder1\file3.aaa.txt
 el.ParentID := 4;
 el.FileName := 'file.aaa.txt'+#0;
 el.Attributes := 16;
 dir.AppendItem(el);
 // \folder1\folder1\file3.txt.aaa
 el.ParentID := 4;
 el.FileName := 'file.txt.aaa'+#0;
 el.Attributes := 17;
 dir.AppendItem(el);
 // checking finding files

 // test#1: startDir = rootID, finding 'folder1'
 i := dir.FindFileByName('fOlder1',rootID);
 if (i <> 0) then
  begin
   if (i < -1) then
    Info.Text := Info.Text + 'Error in FindFileByName,1 - path error!'+#13#10
   else
    Info.Text := Info.Text + 'Error in FindFileByName,1 - invalid element found!'+#13#10;
   bOk := false;
  end;
 // test#2: startDir = rootID, finding '\folder1'
 i := dir.FindFileByName('\fOlder1',rootID);
 if (i <> 0) then
  begin
   if (i < -1) then
    Info.Text := Info.Text + 'Error in FindFileByName,2 - path error!'+#13#10
   else
    Info.Text := Info.Text + 'Error in FindFileByName,2 - invalid element found!'+#13#10;
   bOk := false;
  end;
 // test#3: startDir = '\folder1\folder2', finding '\folder1'
 i := dir.FindFileByName('\fOlder1',5);
 if (i <> 0) then
  begin
   if (i < -1) then
    Info.Text := Info.Text + 'Error in FindFileByName,3 - path error!'+#13#10
   else
    Info.Text := Info.Text + 'Error in FindFileByName,3 - invalid element found!'+#13#10;
   bOk := false;
  end;
 // test#4: startDir = '\', finding 'folder1\folder1'
 i := dir.FindFileByName('fOlder1\foLder1',-1);
 if (i <> 4) then
  begin
   if (i < -1) then
    Info.Text := Info.Text + 'Error in FindFileByName,4 - path error!'+#13#10
   else
    Info.Text := Info.Text + 'Error in FindFileByName,4 - invalid element found!'+#13#10;
   bOk := false;
  end;
 // test#5: startDir = '\folder2', finding '\folder1\folder1'
 i := dir.FindFileByName('\fOlder1\foLder1',2);
 if (i <> 4) then
  begin
   if (i < -1) then
    Info.Text := Info.Text + 'Error in FindFileByName,5 - path error!'+#13#10
   else
    Info.Text := Info.Text + 'Error in FindFileByName,5 - invalid element found!'+#13#10;
   bOk := false;
  end;
 // test#6: startDir = '\folder1', finding '\folder1\folder1'
 i := dir.FindFileByName('foLder1',0);
 if (i <> 4) then
  begin
   if (i < -1) then
    Info.Text := Info.Text + 'Error in FindFileByName,6 - path error!'+#13#10
   else
    Info.Text := Info.Text + 'Error in FindFileByName,6 - invalid element found!'+#13#10;
   bOk := false;
  end;
 // test#7: startDir = '\folder1', finding '..\folder2'
 i := dir.FindFileByName('..\foLder2',0);
 if (i <> 1) then
  begin
   if (i < -1) then
    Info.Text := Info.Text + 'Error in FindFileByName,7 - path error!'+#13#10
   else
    Info.Text := Info.Text + 'Error in FindFileByName,7 - invalid element found!'+#13#10;
   bOk := false;
  end;
 // test#8: startDir = '\folder2\folder2', finding '\folder1\folder1\file1.txt'
 i := dir.FindFileByName('\folder1\folder1\file1.txt',8);
 if (i <> 10) then
  begin
   if (i < -1) then
    Info.Text := Info.Text + 'Error in FindFileByName,8 - path error!'+#13#10
   else
    Info.Text := Info.Text + 'Error in FindFileByName,8 - invalid element found!'+#13#10;
   bOk := false;
  end;
 // test#9: startDir = '\folder2\folder2', finding '\folder1\folder1\file1.txt'
 i := dir.FindFileByName('..\..\folder1\folder1\file1.txt',8);
 if (i <> 10) then
  begin
   if (i < -1) then
    Info.Text := Info.Text + 'Error in FindFileByName,9 - path error!'+#13#10
   else
    Info.Text := Info.Text + 'Error in FindFileByName,9 - invalid element found!'+#13#10;
   bOk := false;
  end;
 // test#10: startDir = '\folder2\folder2', finding '\folder1\folder2\aa..aa'
 str := '..\..\folder1\folder2\';
// str := str + 'file2.tXt';
 for i := 0 to 258 do
  str := str + 'A';
 i := dir.FindFileByName(pChar(str),8);
 if (i <> 15) then
  begin
   if (i < -1) then
    Info.Text := Info.Text + 'Error in FindFileByName,10 - path error!'+#13#10
   else
    Info.Text := Info.Text + 'Error in FindFileByName,10 - invalid element found!'+#13#10;
   bOk := false;
  end;

 OverallProgress.Progress := OverallProgress.Progress +  1;
 Application.ProcessMessages;
 //----------------------------- FindFirst, FindNext ... --------------------------------
 Info.Text := Info.Text + #13#10+'Testing FindFirst, FindNext... '+#13#10;
 Application.ProcessMessages;
 // test#1: startDir = '\folder1\folder1\', finding '..\..\file?.txt'
 if (dir.FindFirst('..\..\file?.txt',SysUtils.faAnyFile,sr,4) <> 0) then
  begin
   Info.Text := Info.Text + 'Error in FindFirst #1 - file not found!'+#13#10;
   bOk := false;
  end
 else
 if (sr.Attr <> 3) and (sr.Attr <> 2) then
  begin
   Info.Text := Info.Text + 'Error in FindFirst #1 - invalid file found!'+#13#10;
   bOk := false;
  end;
 if (dir.FindNext(sr) <> 0) then
  begin
   Info.Text := Info.Text + 'Error in FindNext #1 - file not found!'+#13#10;
   bOk := false;
  end
 else
 if (sr.Attr <> 3) and (sr.Attr <> 2)then
  begin
   Info.Text := Info.Text + 'Error in FindNext #1 - invalid file found!'+#13#10;
   bOk := false;
  end;
 if (dir.FindNext(sr) = 0) then
  begin
   Info.Text := Info.Text + 'Error in FindNext #1 - too many files found!'+#13#10;
   bOk := false;
  end;
 dir.FindClose(sr);
 // test#2: startDir = '\folder1\folder1\', finding '..\..\fil*.*'
 if (dir.FindFirst('\fil*.txt',3+faAnyFile,sr,4) <> 0) then
  begin
   Info.Text := Info.Text + 'Error in FindFirst #2 - file not found!'+#13#10;
   bOk := false;
  end
 else
 if (sr.Attr <> 2) and (sr.Attr <> 3)then
  begin
   Info.Text := Info.Text + 'Error in FindFirst #2 - invalid file found!'+#13#10;
   bOk := false;
  end;
 if (dir.FindNext(sr) <> 0) then
  begin
   Info.Text := Info.Text + 'Error in FindNext #2 - file not found!'+#13#10;
   bOk := false;
  end;
 if (sr.Attr <> 2) and (sr.Attr <> 3)then
  begin
   Info.Text := Info.Text + 'Error in FindNext #2 - invalid file found!'+#13#10;
   bOk := false;
  end;
 if (dir.FindNext(sr) = 0) then
  begin
   Info.Text := Info.Text + 'Error in FindNext #2 - too many files found!'+#13#10;
   bOk := false;
  end;
 dir.FindClose(sr);
 // test#3: startDir = '\folder1\folder1\', finding '*.txt'
 if (dir.FindFirst('folder1\folder1\file.*.txt',32+faAnyFile,sr,-1) <> 0) then
  begin
   Info.Text := Info.Text + 'Error in FindFirst #3 - file not found!'+#13#10;
   bOk := false;
  end
 else
 if (sr.Attr <> 16) then
  begin
   Info.Text := Info.Text + 'Error in FindFirst #3 - invalid file found!'+#13#10;
   bOk := false;
  end;
 if (dir.FindNext(sr) = 0) then
  begin
   Info.Text := Info.Text + 'Error in FindNext #3 - too many files found!'+#13#10;
   bOk := false;
  end;
 dir.FindClose(sr);

{
if (FindFirst('d:\temp\file.*.txt',faAnyFile+32,sr) <> 0) then
 raise Exception.Create('');
if (FindNext(sr) = 0) then
 raise Exception.Create('');
 }
 OverallProgress.Progress := OverallProgress.Progress +  1;
 Application.ProcessMessages;
 //----------------------------- finalising ... --------------------------------
 dir.Free;
 sList.Free;
 pID := nil;
 if (bOk) then
  Info.Text := Info.Text+#13#10+'DIRArray - Ok!'+#13#10
 else
  Info.Text := Info.Text+#13#10+'DIRArray - errors occured!!! '+#13#10;

end;


procedure TForm1.cmbCloseClick(Sender: TObject);
begin
 Form1.Close;
 Application.terminate;
end;

procedure TForm1.cmbDirArrayClick(Sender: TObject);
begin
 Info.Text := '';
 TestDIRArray;
end;

// free space manager test
procedure TForm1.Button1Click(Sender: TObject);
label m1;
var time: TFileTime;
    fh: THandle;
    sr: TSearchRec;
    el: TDirectoryElement;
    PMHandle: TPageFileManager;
    FSMHandle:TFreeSpaceManager;
    pages: TIntegerArray;
    PageSize: Integer;
    bOk : Boolean;
    FileName:String;
    fs: TFileStream;
begin
 bOk := true;
 FileName := 'c:\temp\test_fsm.edb';
// PageSize := 128;
 PageSize := 4096;
 Info.Text := Info.Text + 'Testing FreeSpaceManager, testCount = '+Inttostr(testCount)+'.'#13#10;
 // create file
 try
  PMHandle := TPageFileManager.Create(FileName, fmCreate);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on file creation.'#13#10;
 end;

 FillChar(PMHandle.FHeader,sizeof(PMHandle.FHeader),$00);
 PMHandle.FHeader.Signature := SingleFileSystemSignature;
 PMHandle.FHeader.Version := SFSCurrentVersion;
 PMHandle.FHeader.PageSize := PageSize;
// PMHandle.FHeader.ExtentPageCount := 4;
 PMHandle.FHeader.ExtentPageCount := 16;
 PMHandle.FHeader.HDRPageCount := 1;
 PMHandle.FHeader.TOTALPageCount := 1;
 // save header first copy
 try
  PMHandle.SaveSFHeader;
  PMHandle.LoadSFHeader;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on saving FF header.'#13#10;
 end;

Application.ProcessMessages;
 try
  FSMHandle := TFreeSpaceManager.Create(PMHandle);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on creating FreeSpaceManager.'#13#10;
 end;

// goto m1;
Application.ProcessMessages;
 try
  pages := TIntegerArray.Create(0,TestCount,TestCount);
  aaInitTime;
  aaStartTime;
  FSMHandle.GetPages(TestCount,0,false,pages);
  aaStopTime;
  if (pages.ItemCount <> TestCount) then
   raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on creating FreeSpaceManager.'#13#10;
 end;
 Info.Text := Info.Text + 'FSM.GetPages mixed mode time = '+Inttostr(aaGetTime)+#13#10;
Application.ProcessMessages;

 try
  aaInitTime;
  aaStartTime;
  FSMHandle.FreePages(pages);
  aaStopTime;
  pages.Free;
  if (pages.ItemCount <> TestCount) then
   raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on creating FreeSpaceManager.'#13#10;
 end;
 Info.Text := Info.Text + 'FSM.FreePages mixed mode time = '+Inttostr(aaGetTime)+#13#10;

 m1:
Application.ProcessMessages;
 pages := TIntegerArray.Create(0,TestCount,TestCount);
 FSMHandle.GetPages(TestCount,0,false,pages);
 pages.SetSize(TestCount div 2);
 FSMHandle.FreePages(pages);
 pages.Free;
 FSMHandle.Free;
 PMHandle.Free;

 try
  PMHandle := TPageFileManager.Create(FileName, fmOpenReadWrite);
  PMHandle.LoadSFHeader;
  FSMHandle := TFreeSpaceManager.Create(PMHandle);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on file opening.'#13#10;
 end;

Application.ProcessMessages;
 try
  pages := TIntegerArray.Create(0,TestCount,TestCount);
  aaInitTime;
  aaStartTime;
  FSMHandle.GetPages(TestCount,0,true,pages);
  aaStopTime;
//  if (pages.ItemCount <> TestCount) then
//   raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on creating FreeSpaceManager.'#13#10;
 end;
 Info.Text := Info.Text + 'FSM.GetPages uniform mode time = '+Inttostr(aaGetTime)+#13#10;
Application.ProcessMessages;

pages.Free;

 FSMHandle.Free;
 PMHandle.Free;

{
 aaInitTime;
 aaStartTime;
 fs := TFileStream.Create('c:\temp\fs.edb',fmCreate);
 fs.Size := PageSize * TestCount;
 fs.Free;
 aaStopTime;
 Info.Text := Info.Text + 'FileStream.SetSize('+Inttostr(PageSize * TestCount)+') time = '+Inttostr(aaGetTime)+#13#10;
 }
 if (bOK) then
  Info.Text := Info.Text + 'All OK.'#13#10;

Exit;
// SetCurrentTime(time);
 CreateDir('d:\temp\dir');
 FindFirst('d:\temp\d*.*',faDirectory,sr);
 FindClose(sr);
 fh := FileCreate('d:\temp\test1234.txt');
 FileClose(fh);
 FindFirst('d:\temp\test1234.txt',faAnyFile,sr);
 FindClose(sr);

 fh := FileCreate('d:\temp\test12345.txt');
 FileClose(fh);
 FindFirst('d:\temp\test12345.txt',faAnyFile,sr);
 FindClose(sr);

 fh := FileCreate('d:\temp\test1234.txt3');
 FileClose(fh);
 FindFirst('d:\temp\test1234.txt3',faAnyFile,sr);
 FindClose(sr);

 fh := FileCreate('d:\temp\test12345.txt5');
 FileClose(fh);
 FindFirst('d:\temp\test12345.txt5',faAnyFile,sr);
 FindClose(sr);

 fh := FileCreate('d:\temp\test12345.txt123');
 FileClose(fh);
 FindFirst('d:\temp\test12345.txt123',faAnyFile,sr);
 FindClose(sr);

 fh := FileCreate('d:\temp\file12345.abcdef');
 FileClose(fh);
 FindFirst('d:\temp\file12345.abcdef',faAnyFile,sr);
 FindClose(sr);
{
 SetFileName('test.txt',el);
 SetFileName('test0123.txt',el);
 SetFileName('test01234.txt',el);
 SetFileName('test.txt012345',el);
 SetFileName('test012345.txttxt',el);
 }
end;

procedure TForm1.cmbDIRManagerClick(Sender: TObject);
label m1,m2;
var dir,dir1: TDirManager;
    el,el1: TDirectoryElement;
    str:    string;
    sList:  TStringList;
    pID:    array of Integer;
    i,l,n:  integer;
    bOk:    Boolean;
    sr:     TSearchRec;
    PMHandle: TPageFileManager;
    FSMHandle:TFreeSpaceManager;
    FileName: String;
begin

 bOk := true;
 FileName := 'c:\temp\test_dir.edb';
 // create file
 try
  PMHandle := TPageFileManager.Create(FileName, fmCreate);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on file creation.'#13#10;
 end;

 FillChar(PMHandle.FHeader,sizeof(PMHandle.FHeader),$00);
 PMHandle.FHeader.Signature := SingleFileSystemSignature;
 PMHandle.FHeader.Version := SFSCurrentVersion;
 PMHandle.FHeader.PageSize := 4096;
 PMHandle.FHeader.ExtentPageCount := 16;
 PMHandle.FHeader.HDRPageCount := 1;
 PMHandle.FHeader.TOTALPageCount := 1;
 // save header first copy
 try
  PMHandle.SaveSFHeader;
  PMHandle.LoadSFHeader;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on saving FF header.'#13#10;
 end;

Application.ProcessMessages;
 try
  FSMHandle := TFreeSpaceManager.Create(PMHandle);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on creating FreeSpaceManager.'#13#10;
 end;


 sList := TStringList.Create;
 SetLength(pID,testCount);

 Info.Text := Info.Text + 'Testing DIRManager. FileCount = '+inttostr(TestCount)+
              '... '+#13#10+#13#10;
 OverallProgress.Progress := 0;
 OverallProgress.MaxValue := 3; // number of test
 CurrentProgress.MaxValue := TestCount;
 // testing CreateDir
 dir := TDirManager.Create(PMHandle,FSMHandle);
 CurrentProgress.Progress := 0;
 aaInitTime;
 Info.Text := Info.Text + 'Testing CreateDIR... '+#13#10;
 Application.ProcessMessages;
//SetCurrentDir('d:\temp\1');
// goto m2;
 for i := 1 to TestCount do
  begin
//   str := 'folder'+inttostr(Random(MAXINT) mod TestCount);
   str := 'folder'+inttostr(i);
//   sList.Add(str);
   aaStartTime;
   if (not DIR.CreateDir(str)) then
//   if (not CreateDir(str)) then
    begin
     bOk := false;
     Info.Text := Info.Text + 'Error creating directories.'#13#10;
     break;
    end;
   aaStopTime;
   CurrentProgress.Progress := i;
   Application.ProcessMessages;
  end;
 Info.Text := Info.Text +'CreateDIR time = '+Inttostr(aaGetTime)+#13#10+#13#10;
 // number of test
 OverallProgress.Progress := OverallProgress.Progress +1;

 goto m1;
 aaInitTime;
 Info.Text := Info.Text + 'Testing RemoveDIR... '+#13#10;
 Application.ProcessMessages;
 for i := 1 to TestCount do
  begin
   str := sList.Strings[i-1];
   aaStartTime;
   if (not DIR.RemoveDir(str)) then
    begin
     bOk := false;
     Info.Text := Info.Text + 'Error removing directories.'#13#10;
     break;
    end;
   aaStopTime;
   CurrentProgress.Progress := i;
   Application.ProcessMessages;
  end;
 Info.Text := Info.Text +'RemoveDIR time = '+Inttostr(aaGetTime)+#13#10+#13#10;
 // number of test
 OverallProgress.Progress := OverallProgress.Progress +1;

m2:
 // testing ForceDirectories
 CurrentProgress.Progress := 0;
 aaInitTime;
 Info.Text := Info.Text + 'Testing ForcedDirectories... '+#13#10;
 Application.ProcessMessages;
 str := '';
// dir.SetCurrentDir('\');
 for i := 1 to TestCount do
  begin
   str := str + '\folder'+inttostr(i);
{
   if (i >= 5) then
    str := 'folderfuck0123456789';
   if (i >= 6) then
    str := 'folderfuck';
   if (i >= 7) then
    str := 'f';
   bOk := CreateDir(str);
if (not bOk) then
 begin
  ShowMessage('error creating dir, path length = '+inttostr(Length(GetCurrentDir)));
 end;

   bOk := SetCurrentDir(str);
//str := GetCurrentDir;
   //inttostr(Random(MAXINT) mod TestCount);
}
   CurrentProgress.Progress := i;
   Application.ProcessMessages;
  end;

//SetCurrentDir('d:\temp');
// str := string('d:\temp')+str;
//if (not FileCtrl.ForceDirectories(str)) then
 aaStartTime;
if (not dir.ForceDirectories(str)) then
  begin
   bOk := false;
   Info.Text := Info.Text + 'Error in ForceDirectories test - error!'+#13#10;
  end;
 aaStopTime;
//bOk := directoryExists(str);
//bOk := CreateDir(str);

 Info.Text := Info.Text +'ForceDirectories time = '+Inttostr(aaGetTime)+#13#10+#13#10;
//goto m1;

// dir.Free;
// FSMHandle.Free;
// PMHandle.Free;

// PMHandle := TPageFileManager.Create(FileName, fmOpenReadWrite);
// PMHandle.LoadSFHeader;
// FSMHandle := TFreeSpaceManager.Create(PMHandle);
aaInitTime;
aaStartTime;
 dir1 := TDIRManager.Create(PMHandle,FSMHandle);
aaStopTime;
if (dir1.FDIR.NameIndex.ItemCount <> dir.FDIR.NameIndex.ItemCount) then
 raise Exception.Create('');

for i := 0 to dir1.FDIR.ParentIndex.ItemCount-1 do
begin
 if (dir.FDIR.ParentIndex.Items[i] <>
     dir1.FDIR.ParentIndex.Items[i]) then
  raise Exception.Create('');
end;

for i := 1 to dir.FDIR.NameIndex.ItemCount-1 do
begin

 for n := 0 to i-1 do
  if (AnsiStrIComp(
  dir.FDIR.Items[dir.FDIR.NameIndex.Items[n]].FileName,
  dir.FDIR.Items[dir.FDIR.NameIndex.Items[i]].FileName) > 0) then
   raise Exception.Create('');
end;

for i := 1 to dir1.FDIR.NameIndex.ItemCount-1 do
begin

 for n := 0 to i-1 do
  if (AnsiStrIComp(
  dir1.FDIR.Items[dir1.FDIR.NameIndex.Items[n]].FileName,
  dir1.FDIR.Items[dir1.FDIR.NameIndex.Items[i]].FileName) > 0) then
   raise Exception.Create('');

{
 if (dir.FDIR.NameIndex.Items[i] <>
     dir1.FDIR.NameIndex.Items[i]) then
  raise Exception.Create('');
}
end;
 dir.Free;
 dir := dir1;
 if (not dir.DirectoryExists(str)) then
  begin
   bOk := false;
   Info.Text := Info.Text + 'Error in ForceDirectories test - directory does not exist!'+#13#10;
  end;

 if (not dir.SetCurrentDir(str)) then
  begin
   bOk := false;
   Info.Text := Info.Text + 'Error in ForceDirectories test - directory does not set as current!'+#13#10;
  end;
 if (dir.CurrentDir <>  testCount-1) then
  begin
   bOk := false;
   Info.Text := Info.Text + 'Error in ForceDirectories test - directory does not set as current, invalid currentDIR!'+#13#10;
  end;
 if (dir.CurrentPath <> str) then
  begin
   bOk := false;
   Info.Text := Info.Text + 'Error in ForceDirectories test - directory does not set as current, invalid currentPath!'+#13#10;
  end;
 // number of test
 OverallProgress.Progress := OverallProgress.Progress +1;
 //----------------------------- finalising ... --------------------------------
m1:
 dir.Free;
// dir.Free;
 sList.Free;
 pID := nil;
 FSMHandle.Free;
 PMHandle.Free;

 if (bOk) then
  Info.Text := Info.Text+#13#10+'DIRManager - Ok!'+#13#10
 else
  Info.Text := Info.Text+#13#10+'DIRManager - errors occured!!! '+#13#10;
end;

procedure TForm1.btPageManagerClick(Sender: TObject);
var
  bOK: boolean;
  FileName: string;
  PMHandle: TPageFileManager;
  FS: TFileStream;
  ffh: TSingleFileHeader;
  FFPage: TFFPage;
  PageSize: integer;
begin
 bOk := true;
 FileName := 'c:\temp\test.edb';
 PageSize := 4096;
 Info.Text := Info.Text + 'Testing PageFileManager.'#13#10;

 // create file
 try
  PMHandle := TPageFileManager.Create(FileName, fmCreate);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on file creation.'#13#10;
 end;

 PMHandle.FHeader.Signature := SingleFileSystemSignature;
 PMHandle.FHeader.Version := 1;
 PMHandle.FHeader.PageSize := PageSize;
 // save header first copy
 try
  PMHandle.SaveSFHeader;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on saving FF header.'#13#10;
 end;

 // load header
 try
  PMHandle.LoadSFHeader;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on loading FF header.'#13#10;
 end;

 // write page
 PMHandle.AllocPageBuffer(FFPage);
 FFPage.PageHeader.EncType := 1;
  FFPage.PageHeader.PageType := 21;
  FFPage.PageHeader.NextPageNo := 2;
  FFPage.PageHeader.reserved1 := 111;
 try
  PMHandle.WritePage(FFPage,1,-1,'123');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on writing encrypted page.'#13#10;
 end;
 PMHandle.FreePageBuffer(FFPage);

 // write page
 PMHandle.AllocPageBuffer(FFPage);
 FFPage.PageHeader.EncType := 1;
  FFPage.PageHeader.PageType := 22;
  FFPage.PageHeader.NextPageNo := 3;
  FFPage.PageHeader.reserved1 := 222;
 try
  PMHandle.WritePage(FFPage,2,-1,'123');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on writing encrypted page.'#13#10;
 end;
 PMHandle.FreePageBuffer(FFPage);

 // read page
 PMHandle.AllocPageBuffer(FFPage);
 FFPage.PageHeader.EncType := 1;
  FFPage.PageHeader.PageType := 21;
 try
  if (not PMHandle.ReadPage(FFPage,1,-1,'123')) then
   begin
    bOK := false;
    Info.Text := Info.Text + 'Error on reading encrypted page.'#13#10;
   end;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on reading encrypted page.'#13#10;
 end;
 PMHandle.FreePageBuffer(FFPage);

 // add pages to the end
 try
  PMHandle.AppendPages(2);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on append pages.'#13#10;
 end;

 // delete page from the end
 try
  PMHandle.DeletePagesFromEOF(1);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on delete pages.'#13#10;
 end;

 // close ff
 try
  PMHandle.Free;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on close Single file.'#13#10;
 end;

 if (bOK) then
  Info.Text := Info.Text + 'All OK.'#13#10;
end;


procedure TForm1.btUFPMTestClick(Sender: TObject);
var
  bOK: boolean;
  PMHandle: TPageFileManager;
  UFPMHandle: TUserFilePageMapManager;
  FSMHandle: TFreeSpaceManager;
  FS: TFileStream;
  FileName: string;
  ffh: TSingleFileHeader;
  FFPage: TFFPage;
  PageSize: integer;
  de: TDirectoryElement;
  pages: TIntegerArray;
begin
 bOk := true;
 FileName := 'c:\temp\test.edb';
 PageSize := 4096;
 Info.Text := Info.Text + 'Testing UserFilePageMapManager.'#13#10;

 // create file
 try
  PMHandle := TPageFileManager.Create(FileName, fmCreate);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on file creation.'#13#10;
 end;

 FillChar(PMHandle.FHeader,sizeof(PMHandle.FHeader),$00);
 PMHandle.FHeader.Signature := SingleFileSystemSignature;
 PMHandle.FHeader.Version := SFSCurrentVersion;
 PMHandle.FHeader.PageSize := PageSize;
// PMHandle.FHeader.ExtentPageCount := 4;
 PMHandle.FHeader.ExtentPageCount := 16;
 PMHandle.FHeader.HDRPageCount := 1;
 PMHandle.FHeader.TOTALPageCount := 1;
 // save header
 try
  PMHandle.SaveSFHeader;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on saving FF header.'#13#10;
 end;

 // create file map
 try
  FSMHandle := TFreeSpaceManager.Create(PMHandle);
  UFPMHandle := TUserFilePageMapManager.Create(PMHandle,FSMHandle);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on managers creation.'#13#10;
 end;

 de.FirstMapPageNo := None;
 de.FileSize := 0;
 pages := TIntegerArray.Create(0);

 // get small piece from 0-100 bytes
 try
  UFPMHandle.GetPages(de,0,100,true,pages);
  de.FileSize := 100;
  if (pages.ItemCount <> 1) then
   Info.Text := Info.Text + 'Error #1 on get pages.'#13#10;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error #2 on get pages.'#13#10;
 end;

 // get piece from 50-4000 bytes
 try
  UFPMHandle.GetPages(de,50,4000,true,pages);
  de.FileSize := 4000;
  if (pages.ItemCount <> 1) then
   Info.Text := Info.Text + 'Error #3 on get pages.'#13#10;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error #4 on get pages.'#13#10;
 end;

 // set size to 0
 try
  UFPMHandle.SetSize(de,0);
  de.FileSize := 0;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error #5 on SetSize.'#13#10;
 end;

 // get piece from 5000-10000 bytes with allocation
 try
  UFPMHandle.GetPages(de,5000,5000,true,pages);
  de.FileSize := 10000;
  if (pages.ItemCount <> 2) then
   Info.Text := Info.Text + 'Error #6 on get pages.'#13#10;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error #7 on get pages.'#13#10;
 end;

 // get piece from 5000-4096*2000 bytes with allocation
 try
  UFPMHandle.GetPages(de,5000,4096*2000-5000,true,pages);
  de.FileSize := 4096*2000;
  if (pages.ItemCount <> 2015) then
   Info.Text := Info.Text + 'Error #8 on get pages.'#13#10;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error #9 on get pages.'#13#10;
 end;

 // recreate UFPM
 try
  UFPMHandle.Free;
  UFPMHandle := TUserFilePageMapManager.Create(PMHandle,FSMHandle);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error #10 on recreate UFPM.'#13#10;
 end;

 // get piece from 5000-4096*2000 bytes with allocation
 try
  UFPMHandle.GetPages(de,5000,4096*2000-5000,true,pages);
  de.FileSize := 4096*2000;
  if (pages.ItemCount <> 2015) then
   Info.Text := Info.Text + 'Error #11 on get pages.'#13#10;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error #12 on get pages.'#13#10;
 end;

 // close ff
 try
  PMHandle.Free;
  FSMHandle.Free;
  UFPMHandle.Free;
  pages.Free;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on close Single file.'#13#10;
 end;

 if (bOK) then
  Info.Text := Info.Text + 'All OK.'#13#10;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
{$IFDEF MEMCHECK}
 MemChk;
{$ENDIF}
end;

procedure TForm1.cbnFFSTestClick(Sender: TObject);
var
  bOK: boolean;
  FileName: 	string;
  FileName1: 	string;
  FileName2: 	string;
  FileName3: 	string;
  FFSHandle:  TSingleFileSystem;
  FHandle,FHandle1:		Integer;
  s,Password,Question,Answer: String;
  Password1,Question1,Answer1: String;
  sr:					TSearchRec;
  srcFileName:String;
  size,crc:		Integer;
  fs:					TFileStream;
  buf:				pChar;
begin
 bOk := true;
 Password := 'pass';
//Password := '';
 Question := 'Are you crazy ?';
 Answer := 'Yes, of course';

 Password1 := 'user pass';
//Password1 := '';
 Question1 := 'Are you stupid idiot ?';
 Answer1 := 'Yes, of course';

//Password := '';
 srcFileName := 'd:\temp\test.txt';
 FileName := 'd:\temp\test.edb';
 FileName1 := 'file1.dat';
 FileName2 := 'file2.dat';
 FileName3 := 'folder1\file2.dat';
 Info.Text := Info.Text + 'Testing SingleFileSystem.'#13#10;

 fs := TFileStream.Create(srcFileName,fmOpenRead);
 size := fs.Size;
 buf := AllocMem(size);
 fs.ReadBuffer(buf^,size);
 fs.Free;
 crc := SFSPassword.CountCRC(buf,size,crcFull);
 // create Single file
 try
  FFSHandle := TSingleFileSystem.Create(FileName, fmCreate,Password,Question,Answer);
  if (FFSHandle = nil) then raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on Single file creation.'#13#10;
 end;

 // create user file 1
 try
  FHandle := FFSHandle.FileOpen(FileName1, fmCreate,Password1,Question1,Answer1);
  if (FFSHandle.FindFirst(FileName1,faAnyFile,sr) <> 0) then
  	raise Exception.Create('');
  FFSHandle.FindClose(sr);
  if (FHandle < 0) then raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on user file #1 creation.'#13#10;
 end;

 // create user file 2
 try
  FFSHandle.FileCreate(FileName2);
  FHandle1 := FFSHandle.FileOpen(FileName2,fmOpenReadWrite);
  if (FFSHandle.FindFirst(FileName2,faAnyFile,sr) <> 0) then
  	raise Exception.Create('');
  FFSHandle.FindClose(sr);
  if (FHandle1 < 0) then raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on user file #2 creation.'#13#10;
 end;

 try
  FFSHandle.FileWrite(FHandle1,buf^,size);
  if (SFSPassword.CountCRC(buf,size,crcFull) <> crc) then
  	raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on user file #2 writing.'#13#10;
 end;

 try
  FFSHandle.FileWrite(FHandle,buf^,size);
  if (SFSPassword.CountCRC(buf,size,crcFull) <> crc) then
  	raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on user file #1 writing.'#13#10;
 end;

 // close Single file
 try
  FFSHandle.Free;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on Single file closing.'#13#10;
 end;

// Answer := 'No, of course, not.';
 Info.Text := Info.Text + #13#10 + 'Control question: '+GetControlQuestion(FileName);
 if (RestorePasswordByControlAnswer(FileName,Answer,s)) then
  Info.Text := Info.Text + #13#10 + 'Password = '+s
 else
  Info.Text := Info.Text + #13#10 + 'Invalid answer = '+Answer;
 Info.Text := Info.Text + #13#10;
 Application.ProcessMessages;
 // open Single file
 try
  FFSHandle := TSingleFileSystem.Create(FileName, fmOpenReadWrite,Password,Question,Answer);
  if (FFSHandle.FindFirst(FileName1,faAnyFile,sr) <> 0) then
  	raise Exception.Create('');
  FFSHandle.FindClose(sr);
  if (FFSHandle = nil) then raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on Single file opening.'#13#10;
 end;

// Answer := 'No, of course, not.';
 Info.Text := Info.Text + #13#10 + 'Control question1: '+FFSHandle.GetControlQuestion(FileName1);
 if (FFSHandle.RestorePasswordByControlAnswer(FileName1,Answer1,s)) then
  Info.Text := Info.Text + #13#10 + 'Password1 = '+s
 else
  Info.Text := Info.Text + #13#10 + 'Invalid answer = '+Answer1;
 Info.Text := Info.Text + #13#10;
 Application.ProcessMessages;
 // open user files

 try
  FHandle := FFSHandle.FileOpen(FileName1, fmOpenRead,Password1);
  if (FHandle < 0) then raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on user file #1 opening.'#13#10;
 end;

 try
  FHandle1 := FFSHandle.FileOpen(FileName2, fmOpenRead,Password1);
  if (FHandle < 0) then raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on user file #2 opening.'#13#10;
 end;

 try
  if (FFSHandle.FileRead(FHandle,buf^,size) <> size) then
  	 raise Exception.Create('');
  if (SFSPassword.CountCRC(buf,size,crcFull) <> crc) then
  	raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on reading user file #1 .'#13#10;
 end;

 try
  if (FFSHandle.FileRead(FHandle1,buf^,size) <> size) then
  	 raise Exception.Create('');
  if (SFSPassword.CountCRC(buf,size,crcFull) <> crc) then
  	raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on reading user file #2 .'#13#10;
 end;

 FFSHandle.FileClose(FHandle);
 // rewrite file 2
  if (SFSPassword.CountCRC(buf,size,crcFull) <> crc) then
  	raise Exception.Create('');
    
 try
  FHandle := FFSHandle.FileOpen(FileName2, fmOpenReadWrite);
  if (FHandle < 0) then
   raise Exception.Create('');
  if (FFSHandle.FileSeek(FHandle,0,soFromEnd) <> size) then
   raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on user file #2 seeking.'#13#10;
 end;
 FFSHandle.FileClose(FHandle);
 FFSHandle.FileClose(FHandle1);

  if (SFSPassword.CountCRC(buf,size,crcFull) <> crc) then
  	raise Exception.Create('');

 // rewrite file 2
 try
  FHandle := FFSHandle.FileOpen(FileName2, fmOpenWrite);
//  FHandle := FFSHandle.FileOpen(FileName2, fmOpenReadWrite);
  if (FHandle < 0) then
   raise Exception.Create('');
  if (FFSHandle.FileSeek(FHandle,0,soFromEnd) <> 0) then
//  ;
   raise Exception.Create('');
  if (SFSPassword.CountCRC(buf,size,crcFull) <> crc) then
  	raise Exception.Create('');
  FFSHandle.FileWrite(FHandle,buf^,size);
  FFSHandle.FileClose(FHandle);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on user file #2 opening.'#13#10;
 end;

 // rename file 1
 try
  if (not FFSHandle.RenameFile(FileName1,FileName3)) then
  	 raise Exception.Create('');
  if (FFSHandle.FindFirst(FileName3,faAnyFile,sr) <> 0) then
  	raise Exception.Create('');
  FFSHandle.FindClose(sr);
  if (FFSHandle.FindFirst(FileName1,faAnyFile,sr) = 0) then
  	raise Exception.Create('');
  FFSHandle.FindClose(sr);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on renaming user file #1 .'#13#10;
 end;

 // delete file 2
 try
  if (not FFSHandle.DeleteFile(FileName2)) then
  	 raise Exception.Create('');
  if (FFSHandle.FindFirst(FileName2,faAnyFile,sr) = 0) then
  	raise Exception.Create('');
  FFSHandle.FindClose(sr);
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on deleting user file #2 .'#13#10;
 end;

 // close Single file
 if (not FFSHandle.Repair(s)) then
  begin
   bOK := false;
   Info.Text := Info.Text + 'Error on Single file repairing.'#13#10;
  end;
 Info.Text := Info.Text + 'Repair results: '+s + #13#10;

 // close Single file
 try
  FFSHandle.Free;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on Single file closing 2.'#13#10;
 end;

 FreeMem(buf);
 if (bOK) then
  Info.Text := Info.Text + 'All OK.'#13#10;
end;

procedure TForm1.Button2Click(Sender: TObject);
label m1;
var
  bOK: boolean;
  FileName: 	string;
  FileName1: 	string;
  FFSHandle:  TSingleFileSystem;
  FHandle,FHandle1:		Integer;
  size,crc:		Integer;
  fs:					TFileStream;
  buf:				pChar;
  i:					Integer;
  srcFileName:String;
  mode: 			Byte;
  sr:					TSearchRec;
begin
 mode := crcFull;
 bOk := true;
// srcFileName := 'd:\temp\test.zip';
// FileName := 'd:\temp\test.edb';
 srcFileName := 'f:\test.zip';
 FileName := 'f:\test.sfs';
 Info.Text := Info.Text + 'Loading file'+
              '... '+#13#10+#13#10;
 Application.ProcessMessages;
 fs := TFileStream.Create(srcFileName,fmOpenReadWrite);
 size := fs.Size;
 buf := AllocMem(size);
 aaInitTime;
 aaStartTime;
 fs.ReadBuffer(buf^,size);
 aaStopTime;
 Info.Text := Info.Text + 'Load time = '+IntToStr(aaGetTime * TestCount)+#13#10;
fs.Size := 0;
 aaInitTime;
 aaStartTime;
 fs.WriteBuffer(buf^,size);
 aaStopTime;
 fs.Free;
 Info.Text := Info.Text + 'Write time = '+IntToStr(aaGetTime * TestCount)+#13#10;

 aaInitTime;
 aaStartTime;
 crc := SFSPassword.CountCRC(buf,size,mode);
 aaStopTime;
 Info.Text := Info.Text + 'CRC check time = '+IntToStr(aaGetTime)+#13#10;

 // create Single file
 try
  FFSHandle := TSingleFileSystem.Create(FileName, fmCreate);
  if (FFSHandle = nil) then raise Exception.Create('');
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on Single file creation.'#13#10;
 end;

 Info.Text := Info.Text + 'Writing files, FileCount = '+inttostr(TestCount)+
              ', file size = '+inttostr(size)+
              '... '+#13#10;
 OverallProgress.Progress := 0;
 OverallProgress.MaxValue := 2; // number of test
 CurrentProgress.MaxValue := TestCount;
 CurrentProgress.Progress := 0;
 aaInitTime;
 Application.ProcessMessages;
 // write user files
 try
  for i := 0 to TestCount - 1 do
   begin
//	  FileName1 := 'file'+IntToStr(i)+'.dat';
	  FileName1 := 'file'+IntToStr(i)+'.zip';
	  FHandle := FFSHandle.FileOpen(FileName1, fmCreate);
	  if (FHandle < 0) then raise Exception.Create('');
	  if (FFSHandle.FindFirst(FileName1,faAnyFile,sr) <> 0) then
  		raise Exception.Create('');
    FFSHandle.FindClose(sr);
aaStartTime;
    if (FFSHandle.FileWrite(FHandle,buf^,size) <> size) then
  		raise Exception.Create('');
aaStopTime;
    CurrentProgress.Progress := i+1;
    label1.Caption := IntToStr(i+1);
    Application.ProcessMessages;

    FFSHandle.FileClose(FHandle);
   end;
  CurrentProgress.Progress := TestCount;
  Application.ProcessMessages;
 except
  bOK := false;
  Info.Text := Info.Text + 'Error on user file writing.'#13#10;
 end;
 Info.Text := Info.Text + 'Write time = '+IntToStr(aaGetTime)+#13#10;
 OverallProgress.Progress := 1;
 CurrentProgress.Progress := 0;
goto m1;
 aaInitTime;
 Info.Text := Info.Text  +#13#10 +'Reading files, FileCount = '+inttostr(TestCount)+
              ', file size = '+inttostr(size)+
              '... '+#13#10;
 Application.ProcessMessages;
 // read user files
 try
  for i := 0 to TestCount - 1 do
   begin

	  FileName1 := 'file'+IntToStr(i)+'.zip';
//	  FileName1 := 'file'+IntToStr(i)+'.dat';
	  FHandle := FFSHandle.FileOpen(FileName1, fmOpenRead);
	  if (FHandle < 0) then raise Exception.Create('');
	  if (FFSHandle.FindFirst(FileName1,faAnyFile,sr) <> 0) then
  		raise Exception.Create('');
    FFSHandle.FindClose(sr);
aaStartTime;
    if (FFSHandle.FileRead(FHandle,buf^,size) <> size) then
  		raise Exception.Create('');
aaStopTime;
	  if (SFSPassword.CountCRC(buf,size,mode) <> crc) then
  		raise Exception.Create('');
    FFSHandle.FileClose(FHandle);
    CurrentProgress.Progress := i+1;
    Application.ProcessMessages;
   end;
  CurrentProgress.Progress := TestCount;
  Application.ProcessMessages;
  except
  bOK := false;
  Info.Text := Info.Text + 'Error on user file reading.'#13#10;
 end;
m1:
 Info.Text := Info.Text + 'Read time = '+IntToStr(aaGetTime)+#13#10;
 OverallProgress.Progress := 2;

 FFSHandle.Free;
 FreeMem(buf);
 if (bOK) then
  Info.Text := Info.Text + 'All OK.'#13#10;
end;

end.
