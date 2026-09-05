unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
{$IFDEF VER120}
  HTTPApp, DBWeb, EasyTable, Db, DSProd, HTTPProd;
{$ELSE}
 {$IFDEF VER130}
  HTTPApp, DBWeb, EasyTable, Db, DSProd;
 {$ELSE}
   HTTPApp, DBWeb, Db, DSProd,
   HTTPProd, EasyTable;
 {$ENDIF}
{$ENDIF}

type
  TCustomerInfoModule = class(TWebModule)
    Root: TPageProducer;
    BioLifeProducer: TDataSetPageProducer;
    BioLife: TEasyTable;
    EasySession1: TEasySession;
    BioLifeSpeciesNo: TFloatField;
    BioLifeCategory: TStringField;
    BioLifeCommon_Name: TStringField;
    BioLifeSpeciesName: TStringField;
    BioLifeLengthcm: TFloatField;
    BioLifeLength_In: TFloatField;
    BioLifeNotes: TMemoField;
    BioLifeGraphic: TGraphicField;
    BioLifeid: TAutoIncField;
    procedure BioLifeGraphicGetText(Sender: TField; var Text: String;
      DisplayText: Boolean);
    procedure CustomerInfoModuleGetImageAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure BioLifeNotesGetText(Sender: TField; var Text: String;
      DisplayText: Boolean);
    procedure CustomerInfoModuleBioLifeAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure RootHTMLTag(Sender: TObject; Tag: TTag;
      const TagString: String; TagParams: TStrings;
      var ReplaceText: String);
  end;

var
  CustomerInfoModule: TCustomerInfoModule;
  DllFileName: String;

implementation

uses JPeg;

{$R *.dfm}

procedure TCustomerInfoModule.CustomerInfoModuleBioLifeAction(
  Sender: TObject; Request: TWebRequest; Response: TWebResponse;
  var Handled: Boolean);
begin
  Biolife.DatabaseFileName := ExtractFilePath(DllFileName) + 'DBFishes.edb';
  Biolife.Open;
  try
    Response.Content := BiolifeProducer.Content;
  finally
    Biolife.Close;
  end;
end;

procedure TCustomerInfoModule.BioLifeGraphicGetText(Sender: TField;
  var Text: String; DisplayText: Boolean);
begin
  Text := Format('<IMG SRC="%s/getimage?id=%d" alt="[%s]" border="0">',
    [Request.ScriptName, BioLifeSpeciesNo.AsInteger, BiolifeCommon_Name.Text]);
end;

procedure TCustomerInfoModule.BioLifeNotesGetText(Sender: TField;
  var Text: String; DisplayText: Boolean);
begin
  Text := Sender.AsString;
end;

procedure TCustomerInfoModule.CustomerInfoModuleGetImageAction(
  Sender: TObject; Request: TWebRequest; Response: TWebResponse;
  var Handled: Boolean);
var
  Jpg: TJpegImage;
  S: TMemoryStream;
  B: TBitmap;
  ID: Integer;
begin
  // First, make sure that we are at the correct image by moving to that ID
  // in the table.
  ID := StrToIntDef(Request.QueryFields.Values['id'], -1);
  Biolife.DatabaseFileName := ExtractFilePath(DllFileName) + 'DBFishes.edb';
  BioLife.Open;
  if not BioLife.Locate('Species No', ID, []) then
    raise Exception.Create('Could not locate image ID');
  Jpg := TJpegImage.Create;
  try
    S := TMemoryStream.Create;
    try
      BioLifeGraphic.SaveToStream(S);
      S.Seek(0, soFromBeginning);
      B := TBitmap.Create;
      try
        B.LoadFromStream(S);
        Jpg.Assign(B);
      finally
        B.Free;
      end;
      S.Clear;
      Jpg.SaveToStream(S);
      S.Position := 0;
      Response.ContentType := 'image/jpeg';
    except
      S.Free;
      raise;
    end;
    Response.ContentStream := S;
  finally
    Jpg.Free;
  end;
end;

procedure TCustomerInfoModule.RootHTMLTag(Sender: TObject; Tag: TTag;
  const TagString: String; TagParams: TStrings; var ReplaceText: String);
begin
  if TagString = 'MODULENAME' then
    ReplaceText := Request.ScriptName;
end;

Initialization
  SetLength(DllFileName, 260);
  GetModuleFileName(HInstance, PChar(DllFileName), 260);


end.

