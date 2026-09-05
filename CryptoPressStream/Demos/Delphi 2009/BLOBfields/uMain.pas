unit uMain;

interface

{$I ..\..\ver.inc}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,
  CPSMain, CPSConst,
  StdCtrls, ComCtrls, ExtCtrls, DBCtrls, Grids, DBGrids,
  DB, DBTables, Registry;

type
  TForm1 = class(TForm)
    CPSManager1: TCPSManager;
    tSource: TTable;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    Panel1: TPanel;
    bnCompressTable: TButton;
    bnBrowseCompressed: TButton;
    bnExit: TButton;
    DBNavigator1: TDBNavigator;
    Panel2: TPanel;
    Splitter1: TSplitter;
    RichEdit2: TRichEdit;
    Image2: TImage;
    DataSource2: TDataSource;
    tDest: TTable;
    procedure bnCompressTableClick(Sender: TObject);
    procedure bnExitClick(Sender: TObject);
    procedure bnBrowseCompressedClick(Sender: TObject);
    procedure tDestAfterScroll(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation


{$R *.dfm}

procedure TForm1.bnCompressTableClick(Sender: TObject);
var cs:               TCPSStream;
    bsSource, bsDest: TStream;
    i:                Integer;
    srcsize,size:     Int64;
    ratio:            Double;
    path :            AnsiString;
    reg:              TRegistry;
    t:                Cardinal;
    dbi:              TDBImage;
begin
 tDest.ReadOnly := False;
 reg := TRegistry.Create;
 try
   reg.RootKey := HKEY_LOCAL_MACHINE;
   if (not reg.OpenKeyReadOnly('Software\Borland\Borland Shared\Data')) then
    if (not reg.OpenKeyReadOnly('Software\Codegear\Borland Shared\Data')) then
     reg.OpenKeyReadOnly('Software\Embarcadero\Borland Shared\Data');
   path := reg.ReadString('RootDir')+'\';
 finally
   reg.Free;
 end;
  cs := TCPSFileStream.Create(path+'biolife.db',fmOpenRead);
  srcsize := cs.Size;
  cs.Free;
  cs := TCPSFileStream.Create(path+'biolife.mb',fmOpenRead);
  srcsize := srcsize + cs.Size;
  cs.Free;
  cs := TCPSFileStream.Create(path+'biolife.px',fmOpenRead);
  srcsize := srcsize + cs.Size;
  cs.Free;
 t := GetTickCount;
 try
   tSource.Open;
   tDest.Close;
   if (tDest.Exists) then
    tDest.DeleteTable;
   tDest.FieldDefs.Assign(tSource.FieldDefs);
   tDest.IndexDefs.Assign(tSource.IndexDefs);
   for i := 0 to tDest.FieldDefs.Count-1 do
    if (tDest.FieldDefs.Items[i].DataType = ftMemo) or
       (tDest.FieldDefs.Items[i].DataType = ftGraphic) then
     tDest.FieldDefs.Items[i].DataType := ftBLOB;
   tDest.CreateTable;
   tDest.Open;
   tSource.First;
   while not tSource.Eof do
     begin
      tDest.Insert;
      for i := 0 to tSource.FieldCount-1 do
       if (not tSource.Fields[i].IsNull) then
        begin
         if (tSource.Fields[i] is TLargeintField) then
          TLargeintField(tDest.Fields[i]).AsLargeInt := TLargeintField(tSource.Fields[i]).AsLargeInt
         else
         if (tSource.Fields[i].IsBlob) then
          begin
           if (tSource.Fields[i].DataType = ftGraphic) then
            begin
             bsDest := tDest.CreateBlobStream(tDest.Fields[i],bmReadWrite);
             cs := CPSManager1.CreateCryptoPressStream(bsDest,True,False);
             dbi := TDBImage.Create(nil);
             try
               dbi.DataSource := DataSource2;
               dbi.DataField := tSource.Fields[i].FieldName;
               dbi.Picture.Bitmap.SaveToStream(cs);
               dbi.DataSource := nil;
             finally
               dbi.Free;
               cs.Free;
               bsDest.Free;
             end;
            end
           else
            begin
               bsSource := tSource.CreateBlobStream(tSource.Fields[i],bmRead);
               try
                 bsDest := tDest.CreateBlobStream(tDest.Fields[i],bmReadWrite);
                 cs := CPSManager1.CreateCryptoPressStream(bsDest,True,False);
                 try
                  cs.LoadFromStream(bsSource);
                 finally
                   cs.Free;
                   bsDest.Free;
                 end;
               finally
                 bsSource.Free;
               end;
            end;
          end
         else
          tDest.Fields[i].Assign(tSource.Fields[i]);
        end;
      tDest.Post;
      tSource.Next;
     end;
  tDest.Close;
  tSource.Close;
  t := GetTickCount - t;
  cs := TCPSFileStream.Create('biolife.db',fmOpenRead);
  size := cs.Size;
  cs.Free;
  cs := TCPSFileStream.Create('biolife.mb',fmOpenRead);
  size := size + cs.Size;
  cs.Free;
  cs := TCPSFileStream.Create('biolife.px',fmOpenRead);
  size := size + cs.Size;
  cs.Free;
 except
  on e: Exception do
   begin
    MessageDlg('Error: '+e.Message,mtError,[mbOK],0);
    Exit;
   end;
 end;
  ratio := (srcSize - Size) / srcSize * 100.0;
  ShowMessage('Table compressed successfully. '+#13#10
              +'UncompressedSize = '+IntToStr(srcsize)+' bytes' + #13#10
              +'CompressedSize = '+IntToStr(size)+' bytes' + #13#10
              +'Time = '+IntToStr(t)+' ms' + #13#10
              +'Ratio = '+FormatFloat('0.00',ratio)+' %'
              );
end;

procedure TForm1.bnExitClick(Sender: TObject);
begin
 Close;
 Application.Terminate;
end;

procedure TForm1.bnBrowseCompressedClick(Sender: TObject);
begin
// to avoid D2009 bug in TTable.Exists
// if (not tDest.Exists) then
 if (not SysUtils.FileExists('biolife.db')) then
  begin
   MessageDlg('Compressed table does not exists. Click on "Compress Table" button at first',
   mtWarning,[mbOK],0);
   Exit;
  end;
 tDest.ReadOnly := True;
 tDest.Open;
 tDest.First;
end;

procedure TForm1.tDestAfterScroll(DataSet: TDataSet);
var cs: TCPSCryptoPressStream;
    bs: TStream;
    i:  Integer;
    b1,b2: Boolean;
begin
 if (not tDest.ReadOnly) then
  Exit;
 b1 := False;
 b2 := False;
 for i := 0 to tDest.FieldCount-1 do
  begin
   if (b1 and b2) then
    break
   else
    if (tDest.Fields[i].FieldName = 'Notes') or (tDest.Fields[i].FieldName = 'Graphic') then
     begin
      bs := TDest.CreateBlobStream(tDest.Fields[i],bmRead);
      cs := CPSManager1.CreateCryptoPressStream(bs,False,True);
      try
        if (tDest.Fields[i].FieldName = 'Notes') then
         begin
          RichEdit2.Lines.LoadFromStream(cs);
          b1 := True;
         end
        else
         begin
           Image2.Picture.Bitmap.LoadFromStream(cs);
           b2 := True;
         end;
      finally
       // no need in bs.Free as we created stream with FreeBaseStream = true
       cs.Free;
      end;
     end;
  end;
end;

end.
