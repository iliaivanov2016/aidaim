unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, JPEG, CPSMain;

type

  TFileInfo = record
   FileName: String;
   FileSize: Integer;
  end;
  PFileInfo = ^TFileInfo;

  TfmMain = class(TForm)
    CPSManager1: TCPSManager;
    Panel1: TPanel;
    gbImages: TGroupBox;
    Splitter1: TSplitter;
    gbImageView: TGroupBox;
    bnCreateArchive: TButton;
    bnViewArchive: TButton;
    bnExit: TButton;
    Label1: TLabel;
    lbImages: TListBox;
    Image1: TImage;
    procedure bnExitClick(Sender: TObject);
    procedure bnCreateArchiveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bnViewArchiveClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lbImagesClick(Sender: TObject);
  private
    { Private declarations }
    FilePath:           String;
    FileList:           TList;
    FirstImagePosition: Int64;
  public
    { Public declarations }
    procedure CreateArchive(files: TList);
    procedure ViewImage(ImageNo: Integer);
    procedure LoadImage(Stream: TStream; ImageNo: Integer);
  end;

const ArchiveName = 'archive.cps';

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

procedure ClearFileList(FileList: TList);
var i: Integer;
begin
  for i := 0 to FileList.Count-1 do
   Dispose(FileList.Items[i]);
  FileList.Clear; 
end;

procedure TfmMain.bnExitClick(Sender: TObject);
begin
 Close;
end;

procedure TfmMain.bnCreateArchiveClick(Sender: TObject);
var sr:        TSearchRec;
    FileName:  String;
    files:     TList;
    info:      PFileInfo;
begin
 bnCreateArchive.Enabled := False;
 bnViewArchive.Enabled := False;
 files := TList.Create;
 try
   FileName := FilePath+
               'Images\*.*';
   if (FindFirst(FileName,faAnyFile-faDirectory,sr) = 0) then
    try
      repeat
       New(info);
       info^.FileName := sr.Name;
       info^.FileSize := sr.Size;
       files.Add(info);
      until (FindNext(sr) <> 0);
    finally
      FindClose(sr);
    end;
   if (files.Count > 0) then
    begin
     CreateArchive(files);
     ShowMessage('Archive '+FilePath+ArchiveName+' was created successfully.');
    end
   else
    ShowMessage('There is no files in Images folder - cannot create archive.');
 finally
   bnCreateArchive.Enabled := True;
   bnViewArchive.Enabled := True;
   ClearFileList(files);
   files.Free;
 end;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
  FilePath := IncludeTrailingBackslash(ExtractFilePath(Application.ExeName));
  FileList := TList.Create;
end;

procedure TfmMain.bnViewArchiveClick(Sender: TObject);
var i,n:    Integer;
    w:      Word;
    cpsfs:  TCPSCryptoPressFileStream;
    info:   pFileInfo;
begin
  if (not SysUtils.FileExists(FilePath+ArchiveName)) then
   begin
    ShowMessage('Error - file '+FilePath+ArchiveName+' not found.');
    Exit;
   end;
  ClearFileList(FileList);
  lbImages.Clear;
  gbImages.Caption := ' Images in archive ';
  cpsfs := CPSManager1.CreateCryptoPressFileStream(
            FilePath+ArchiveName,
            fmOpenRead or fmShareDenyWrite);
  try
   try
    cpsfs.ReadBuffer(n,SizeOf(n));
    for i := 0 to n-1 do
     begin
      New(info);
      FileList.Add(info);
      // load file size
      cpsfs.ReadBuffer(info^.FileSize,SizeOf(Integer));
      // load file name length
      cpsfs.ReadBuffer(w,SizeOf(w));
      SetLength(info^.FileName,w);
      if (w > 0) then
       cpsfs.ReadBuffer(info^.FileName[1],w);
     end;
    FirstImagePosition := cpsfs.Position;
    gbImages.Caption := ' Images in archive: '+IntToStr(n);
    for i := 0 to n-1 do
     lbImages.Items.Add(pFileInfo(FileList.Items[i])^.FileName);
   except
    on e: Exception do
     begin
      ClearFileList(FileList);
      ShowMessage('Error opening archive: '+#13#10+e.Message);
     end;
   end;
  finally
    cpsfs.Free;
  end;
end;

procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ClearFileList(FileList);
  FileList.Free;
end;

procedure TfmMain.lbImagesClick(Sender: TObject);
var i: Integer;
begin
  for i := 0 to lbImages.Count-1 do
   if (lbImages.Selected[i]) then
    ViewImage(i);
end;

procedure TfmMain.CreateArchive(files: TList);
var i,n:    Integer;
    w:      Word;
    cpsfs:  TCPSCryptoPressFileStream;
    fs:     TCPSFileStream;
begin
 cpsfs := CPSManager1.CreateCryptoPressFileStream(FilePath+ArchiveName,fmCreate);
 try
   n := files.Count;
   // write number of files to the archive
   cpsfs.WriteBuffer(n,SizeOf(n));
   // write archive header
   for i := 0 to n-1 do
    begin
     // write file size
     cpsfs.WriteBuffer(pFileInfo(files.Items[i])^.FileSize,SizeOf(Integer));
     // write file name length
     w := Word(Length(pFileInfo(files.Items[i])^.FileName));
     cpsfs.WriteBuffer(w,SizeOf(w));
     // write file name
     if (w > 0) then
      cpsfs.WriteBuffer(pFileInfo(files.Items[i])^.FileName[1],w);
    end;
   // write files
   for i := 0 to n-1 do
    begin
     fs := TCPSFileStream.Create(
            FilePath+'Images\'+pFileInfo(files.Items[i])^.FileName,
            fmOpenRead or fmShareDenyWrite,
            CPSManager1
                                );
     try
       fs.SaveToStream(cpsfs);
       cpsfs.Position := cpsfs.Position + fs.Size;
     finally
       fs.Free;
     end;
    end;
  cpsfs.FlushFileBuffers;
  cpsfs.Free;
 except
  on e: Exception do
   begin
    cpsfs.Free;
    SysUtils.DeleteFile(FilePath+ArchiveName);
    ShowMessage('Error - cannot create archive. Error message: '+#13#10+e.Message);
   end;
 end;
end;


procedure TfmMain.ViewImage(ImageNo: Integer);
var cpsfs: TCPSCryptoPressFileStream;
    i:     Integer;
begin
  if (not SysUtils.FileExists(FilePath+ArchiveName)) then
   begin
    ShowMessage('Error - file '+FilePath+ArchiveName+' not found.');
    Exit;
   end;
  cpsfs := CPSManager1.CreateCryptoPressFileStream(
            FilePath+ArchiveName,
            fmOpenRead or fmShareDenyWrite);
  try
    cpsfs.Position := FirstImagePosition;
    for i := 0 to ImageNo do
     if (i < ImageNo) then
      cpsfs.Position := cpsfs.Position + pFileInfo(FileList.Items[i])^.FileSize
     else
      LoadImage(cpsfs,ImageNo);
  finally
    cpsfs.Free;
  end;
end;


procedure TfmMain.LoadImage(Stream: TStream; ImageNo: Integer);
var
    jpg:   TJpegImage;
    ms:    TCPSMemoryStream;
    name:  String;
begin
  name := pFileInfo(FileList.Items[ImageNo])^.FileName;
  if (Pos('.jpg',LowerCase(name)) > 0) or
     (Pos('.jpeg',LowerCase(name)) > 0) then
   begin
    ms := TCPSMemoryStream.Create(nil);
    jpg := TJPEGImage.Create;
    try
     try
      ms.LoadFromStreamWithPosition(Stream,Stream.Position,
          pFileInfo(FileList.Items[ImageNo])^.FileSize);
      ms.Position := 0;
      jpg.LoadFromStream(ms);
      Image1.Picture.Assign(jpg);
      gbImageView.Caption := ' Image View: file "'+name+'", size '+IntToStr(ms.Size)+' bytes ';
     except
      on e: Exception do
       begin
        ShowMessage('Cannot load JPEG image from archive, FileName = '+
          name+'. Error: '+#13#10+e.Message);
        Exit;
       end;
     end;
    finally
      ms.Free;
      jpg.Free;
    end;
   end
  else
   ShowMessage('Unknown file type! Only .jpg or .JPEG images can be displayed by this demo.');
end;

end.
