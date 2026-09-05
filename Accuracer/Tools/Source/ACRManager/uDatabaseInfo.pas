unit uDatabaseInfo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ACRMain, ACRComMain;

type
  TDatabaseInfo = class(TForm)
    bnOk: TBitBtn;
    GroupBox1: TGroupBox;
    Label8: TLabel;
    Label9: TLabel;
    GroupBox2: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label14: TLabel;
    lPageSize: TLabel;
    lMaxCon: TLabel;
    lEncrypt: TLabel;
    lAlg: TLabel;
    lMode: TLabel;
    lInv: TLabel;
    Label1: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    lFreePages: TLabel;
    lTotalPages: TLabel;
    lUsedPages: TLabel;
    lDensity: TLabel;
    CompactNeeded: TLabel;
    Label10: TLabel;
    lFormatVersion: TLabel;
    labStoredFunctionManager: TLabel;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DatabaseInfo: TDatabaseInfo;

implementation

uses MainUnit;
{$R *.dfm}

function SizeFormat(Size: Int64) : string;
begin
 case Size of
  0..1023: Result := IntToStr(Size)+' Bytes';
  1024..1048575: Result := FloatToStrF(Size/1024.0,ffFixed,7,2)+' KB';
  1048576..1073741823: Result := FloatToStrF(Size/1048576.0,ffFixed,7,2)+' MB';
 else
  Result := FloatToStrF(Size/1073741824.0,ffFixed,7,2)+' GB';
 end;
end;

procedure TDatabaseInfo.FormShow(Sender: TObject);
var
 FreePages : Int64;
 TotalPages : Int64;
 UsedPages : Int64;
begin
 FreePages := Int64(MainForm.CurrentDB.Options.PageSize)*Int64(MainForm.CurrentDB.FreePageCount);
 TotalPages := Int64(MainForm.CurrentDB.Options.PageSize)*Int64(MainForm.CurrentDB.TotalPageCount);
 UsedPages := Int64(MainForm.CurrentDB.Options.PageSize)*Int64(MainForm.CurrentDB.UsedPageCount);
 lPageSize.Caption := IntToStr(MainForm.CurrentDB.Options.PageSize)+' Bytes';
     //SizeFormat(MainForm.CurrentDB.Options.PageSize);
 lMaxCon.Caption := IntToStr(MainForm.CurrentDB.Options.MaxSessionCount);
 lFreePages.Caption := IntToStr(MainForm.CurrentDB.FreePageCount)+' ('
                      +SizeFormat(FreePages)+')';
 lTotalPages.Caption := IntToStr(MainForm.CurrentDB.TotalPageCount)+' ('
                      +SizeFormat(TotalPages)+')';
 lUsedPages.Caption := IntToStr(MainForm.CurrentDB.UsedPageCount)+' ('
                      +SizeFormat(UsedPages)+')';
 lDensity.Caption := FloatToStrF(MainForm.CurrentDB.Density,ffFixed,7,2) +' %';
 lFormatVersion.Caption := FloatToStrF(MainForm.CurrentDB.FormatVersion,ffFixed,7,2);
 if MainForm.CurrentDB.Density <= 50 then
  CompactNeeded.Caption := 'It is recommended to compact the database !'
 else
  CompactNeeded.Caption := '';
   if MainForm.CurrentDB.IsDatabaseEncrypted then
    begin
     case MainForm.CurrentDB.CryptoParams.CryptoAlgorithm of
      craRijndael_128 : lAlg.Caption := 'Rijndael 128';
	    craRijndael_256 : lAlg.Caption := 'Rijndael 256';
	    craBlowfish : lAlg.Caption := 'Blowfish';
	    craTwofish_128 : lAlg.Caption := 'Twofish 128';
	    craTwofish_256 : lAlg.Caption := 'Twofish 256';
	    craSquare : lAlg.Caption := 'Square';
	    craDES_Single_8 : lAlg.Caption := 'DES Single 8';
	    craDES_Double_8 : lAlg.Caption := 'DES Double 8';
	    craDES_Double_16 : lAlg.Caption := 'DES Double 16';
      craDES_Triple_8 : lAlg.Caption := 'craDES Triple 8';
	    craDES_Triple_16 : lAlg.Caption := 'DES Triple 16';
	    craDES_Triple_24 : lAlg.Caption := 'DES Triple 24';
     end;
     case MainForm.CurrentDB.CryptoParams.CryptoMode of
      acmCTS : lMode.Caption := 'CTS';
	    acmCBC : lMode.Caption := 'CBC';
	    acmCFB : lMode.Caption := 'CFB';
	    acmOFB : lMode.Caption := 'OFB';
     end;
     if MainForm.CurrentDB.CryptoParams.UseInitVector then
      lInv.Caption := 'Exist'
     else
      lInv.Caption := 'None';
     if MainForm.CurrentDB.IsDatabaseEncryptedByPassword then
      lEncrypt.Caption := 'By password'
     else
      lEncrypt.Caption := 'By key'
    end
   else
    begin
     lEncrypt.Caption := 'None';
     lInv.Caption := '';
     lMode.Caption := '';
     lAlg.Caption := 'None';
    end;
 if MainForm.CurrentDB.IsStoredFunctionManagerExists then
  begin
    labStoredFunctionManager.Font.Color := clGreen;
    labStoredFunctionManager.Caption :=  'Stored Function Manager exists.'+#13#10
                             +'Use CREATE FUNCTION to create new stored function.';
  end
 else
  begin
    labStoredFunctionManager.Font.Color := clRed;
    labStoredFunctionManager.Caption :=  'Stored Function Manager does not exists!'+#13#10
                             +'It is recommended to compact the database !';
  end;
end;

end.
