// If destination database does not exist, ACR4Convert will create it with options from source database


// Command Line Options:

// ACR4Convert.exe data4.adb data5.adb [options]

// First parameter - always Accuracer 4 database file name,
// Second paramter - always Accuracer 5 database file name

// Options:

// -4 - convert from Accuracer 5 to Accuracer 4. If not specified or -5
//    - from v.4 to v.5
// -lLogPath - path to directory to store log files
// -p4Password - password for encrypted Accuracer 4 database
// -i4InitVectorFile - inital vector file name for encrypted Accuracer 4 database
// -k4KeyFile - key file name for encrypted Accuracer 4 database
// -p5Password - password for encrypted Accuracer 5 database
// -i5InitVectorFile - inital vector file name for encrypted Accuracer 5 database
// -k5KeyFile - key file name for encrypted Accuracer 5 database


unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Gauges, ComCtrls, Grids, DBGrids, DB,
  DBCtrls, ACRMain, ACRConst, ACRComMain, AC4Main, ACRCompression, ACRTypes, AC4Types
  , Security, ACRMemory;

{$WARNINGS OFF}

{$I ACR4Convert.Inc}

type
  TfmMain = class(TForm)
    Panel1: TPanel;
    bn4To5Beta: TButton;
    bn4OpenClose: TButton;
    bnExit: TButton;
    bn5BetaOpenClose: TButton;
    bn5BetaTo4: TButton;
    Panel2: TPanel;
    Panel3: TPanel;
    Splitter1: TSplitter;
    reLog: TRichEdit;
    gIndicator: TGauge;
    Panel4: TPanel;
    Label1: TLabel;
    eDB4File: TEdit;
    bn4Browse: TButton;
    Panel5: TPanel;
    Label2: TLabel;
    eDB5File: TEdit;
    bn5Browse: TButton;
    lb4Tables: TListBox;
    Splitter2: TSplitter;
    Panel6: TPanel;
    Splitter3: TSplitter;
    lb5Tables: TListBox;
    Panel7: TPanel;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    ds4: TDataSource;
    ds5: TDataSource;
    ACR5DB: TACRDatabase;
    ACR5Table: TACRTable;
    ACR4Table: TAC4Table;
    ACR4DB: TAC4Database;
    od4: TOpenDialog;
    od5: TOpenDialog;
    cbTransactions: TCheckBox;
    procedure bnExitClick(Sender: TObject);
    procedure ACR5TableProgress(Sender: TComponent; Progress: Double;
      Operation: TACRTableOperation; var Abort: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure bn4BrowseClick(Sender: TObject);
    procedure bn5BrowseClick(Sender: TObject);
    procedure bn4OpenCloseClick(Sender: TObject);
    procedure lb4TablesClick(Sender: TObject);
    procedure bn5BetaOpenCloseClick(Sender: TObject);
    procedure lb5TablesClick(Sender: TObject);
    procedure ACR4TableAfterClose(DataSet: TDataSet);
    procedure ACR4TableAfterOpen(DataSet: TDataSet);
    procedure ACR5TableAfterOpen(DataSet: TDataSet);
    procedure ACR5TableAfterClose(DataSet: TDataSet);
    procedure bn4To5BetaClick(Sender: TObject);
    procedure bn5BetaTo4Click(Sender: TObject);
  private
    { Private declarations }
    FParams:      Boolean;
    FAbort:       Boolean;
    FAppPath:     String;
    FLogPath:     String;
    FSuccess:     Boolean;
    FSourceFile:  String;
    FDestFile:    String;
    FParamCount:  Integer;
    FPassword4:   String;
    FKeyFile4:    String;
    FIVFile4:     String;
    FPassword5:   String;
    FKeyFile5:    String;
    FIVFile5:     String;
  public
    { Public declarations }
    procedure ShowButtons(Enable: Boolean);
    procedure ConvertDefsTo5;
    procedure ConvertDefsTo4;
    procedure ProcessFromCommandLine;
  end;

var
  fmMain: TfmMain;

function ConvertFK4ToFK5(FKDef4: TAC4ForeignKeyDef): TACRForeignKeyDef;
function ConvertFK5ToFK4(FKDef5: TACRForeignKeyDef): TAC4ForeignKeyDef;
procedure CopyCryptoParams4To5(ACR4DB: TAC4Database; ACR5DB: TACRDatabase);
procedure CopyCryptoParams5To4(ACR5DB: TACRDatabase; ACR4DB: TAC4Database);
function ACRReplaceDB4Name(FileName: String): String;

implementation

{$R *.dfm}

procedure TfmMain.bnExitClick(Sender: TObject);
begin
 FAbort := True;
 try
   if (ACR4DB.Connected) then
    if (ACR4DB.InTransaction) then
     begin
      ACR4DB.Rollback;
      ACR4DB.Close;
     end;
 except
 end;
 try
   if (ACR5DB.Connected) then
    if (ACR5DB.InTransaction) then
     begin
      ACR5DB.Rollback;
      ACR5DB.Close;
     end;
 except
 end;
 Close;
 Application.Terminate;
 
end;

procedure TfmMain.ACR5TableProgress(Sender: TComponent; Progress: Double;
  Operation: TACRTableOperation; var Abort: Boolean);
begin
 gIndicator.Progress := Round(Progress);
 Application.ProcessMessages;
 Abort := FAbort;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
 FAbort := False;
 Caption := Caption +'        Accuracer version: '+ACRGetCurrentVersion;
 FAppPath := IncludeTrailingBackslash(ExtractFilePath(Application.ExeName))+'..\..\Demos\Data';
 FLogPath := IncludeTrailingBackslash(ExtractFilePath(Application.ExeName));
 FPassword4 := '';
 FKeyFile4 := '';
 FIVFile4 := '';
 FPassword5 := '';
 FKeyFile5 := '';
 FIVFile5 := '';
 od4.InitialDir := FAppPath;
 od5.InitialDir := FAppPath;
 try
  FParamCount := ParamCount;
  FParams := (FParamCount >= 1);
  if (FParams) then
   ProcessFromCommandLine;
 finally
  if (FParams) then
   begin
     if (FSuccess) then
      reLog.Lines.SaveToFile(FLogPath+'success.txt')
     else
      reLog.Lines.SaveToFile(FLogPath+'errors.txt');
     Close;
     Application.Terminate;
   end;
 end;
end;


procedure TfmMain.bn4BrowseClick(Sender: TObject);
begin
 if (od4.Execute) then
  begin
   eDB4File.Text := od4.FileName;
   if (Length(eDB5File.Text) <= 0) then
     eDB5File.Text := ACRReplaceDB4Name(eDB4File.Text);
  end;
end;

procedure TfmMain.bn5BrowseClick(Sender: TObject);
begin
 if (od5.Execute) then
   eDB5File.Text := od5.FileName;
end;

procedure TfmMain.bn4OpenCloseClick(Sender: TObject);
begin
 if (ACR4DB.Connected) then
  begin
    try
      ACR4DB.Close;
      bn4OpenClose.Caption := 'ACR4 Open';
      lb4Tables.Clear;
      reLog.Lines.Add('Accuracer 4 database closed.');
    except
      on e: Exception do
       begin
        reLog.Lines.Add(e.Message);
       end;
    end;
  end // close
 else
  begin
   if (eDB4File.Text = '') then
    begin
     if (not FParams) then
      MessageDlg('Error - Accuracer 4 file name is not set',mtError,[mbOK],0);
     Exit;
    end;
   ACR4DB.DatabaseFileName := eDB4File.Text;
   reLog.Lines.Add('Accuracer 4 database file: '+ACR4DB.DatabaseFileName);
   lb4Tables.Clear;
   try
     if (not ACR4DB.Exists) then
      begin
       if (not FParams) then
        begin
          reLog.Lines.Add('Accuracer 4 database does not exist: '+#13#10+ACR4DB.DatabaseFileName);
          Exit;
        end;
         if (ACR5DB.IsDatabaseEncrypted) then
          begin
            CopyCryptoParams5To4(ACR5DB,ACR4DB);
          end
         else
          begin
           ACR4DB.CryptoParams.CryptoAlgorithm := TAC4CryptoAlgorithm(craNone);
          end;
       ACR4DB.CreateDatabase;
       reLog.Lines.Add('Accuracer 4 database created.');
      end
     else
      begin
       // db exists - check if it is encryted
       if (not FParams) then
        if (ACR4DB.IsDatabaseEncrypted) then
         begin
          IsACR5 := False;
          Data4 := ACR4DB;
          if (FormSecurity.ShowModal <> mrOk) then
           Exit;
         end;
      end;
     ACR4DB.Open;
     bn4OpenClose.Caption := 'ACR4 Close';
     reLog.Lines.Add('Accuracer 4 database opened.');
     ACR4DB.GetTablesList(lb4Tables.Items);
     reLog.Lines.Add('Accuracer 4 database: '+IntToStr(lb4Tables.Items.Count)+' tables');
     lb4Tables.SelectAll;
   except
    on e: Exception do
     begin
      reLog.Lines.Add(e.Message);
     end;
   end;
  end; // open
end;

procedure TfmMain.lb4TablesClick(Sender: TObject);
var i: Integer;
begin
 try
   if (ACR4Table.Active) then
    ACR4Table.Close;
   for i := 0 to lb4Tables.Items.Count-1 do
    if (lb4Tables.Selected[i]) then
     begin
      ACR4Table.TableName := lb4Tables.Items[i];
      ACR4Table.Open;
      break;
     end;
 except
    on e: Exception do
     begin
      reLog.Lines.Add(e.Message);
     end;
 end;
end;

procedure TfmMain.bn5BetaOpenCloseClick(Sender: TObject);
begin
 if (ACR5DB.Connected) then
  begin
    try
      ACR5DB.Close;
      bn5BetaOpenClose.Caption := 'ACR5 Open';
      lb5Tables.Clear;
      reLog.Lines.Add('Accuracer 5 database closed.');
    except
      on e: Exception do
       begin
        reLog.Lines.Add(e.Message);
       end;
    end;
  end // close
 else
  begin
   if (eDB5File.Text = '') then
    begin
     if (FParamCount < 2) then
      MessageDlg('Error - Accuracer 5 file name is not set',mtError,[mbOK],0);
     Exit;
    end;
   bn5BetaOpenClose.Caption := 'ACR5 Close';
   ACR5DB.DatabaseFileName := eDB5File.Text;
   reLog.Lines.Add('Accuracer 5 database file: '+ACR5DB.DatabaseFileName);
   lb5Tables.Clear;
   try
     if (not ACR5DB.Exists) then
      begin
         if (ACR4DB.IsDatabaseEncrypted) then
          begin
           CopyCryptoParams4To5(ACR4DB,ACR5DB);
          end
         else
          begin
           ACR5DB.CryptoParams.CryptoAlgorithm := TACRCryptoAlgorithm(craNone);
          end;
         ACR5DB.CreateDatabase;
       reLog.Lines.Add('Accuracer 5 database created.');
      end
     else
      begin
       // db exists - check if it is encryted
       if (not FParams) then
        if (ACR5DB.IsDatabaseEncrypted) then
         begin
          IsACR5 := True;
          Data5 := ACR5DB;
          if (FormSecurity.ShowModal <> mrOk) then
           Exit;
         end;
      end;
     ACR5DB.Open;
     reLog.Lines.Add('Accuracer 5 database opened.');
     ACR5DB.GetTablesList(lb5Tables.Items);
     reLog.Lines.Add('Accuracer 5 database: '+IntToStr(lb5Tables.Items.Count)+' tables');
     lb5Tables.SelectAll;
   except
    on e: Exception do
     begin
      reLog.Lines.Add(e.Message);
     end;
   end;
  end; // open
end;

procedure TfmMain.lb5TablesClick(Sender: TObject);
var i: Integer;
begin
 try
   if (ACR5Table.Active) then
    ACR5Table.Close;
   for i := 0 to lb5Tables.Items.Count-1 do
    if (lb5Tables.Selected[i]) then
     begin
      ACR5Table.TableName := lb5Tables.Items[i];
      ACR5Table.Open;
      break;
     end;
 except
    on e: Exception do
     begin
      reLog.Lines.Add(e.Message);
     end;
 end;
end;

procedure TfmMain.ACR4TableAfterClose(DataSet: TDataSet);
begin
 reLog.Lines.Add('Table '+ACR4Table.TableName+' closed.');
end;

procedure TfmMain.ACR4TableAfterOpen(DataSet: TDataSet);
begin
 reLog.Lines.Add('Table '+ACR4Table.TableName+' opened. RecordCount = '+IntToStr(ACR4Table.RecordCount));
end;

procedure TfmMain.ACR5TableAfterOpen(DataSet: TDataSet);
begin
 reLog.Lines.Add('Table '+ACR5Table.TableName+' opened. RecordCount = '+IntToStr(ACR5Table.RecordCount));
end;

procedure TfmMain.ACR5TableAfterClose(DataSet: TDataSet);
begin
 reLog.Lines.Add('Table '+ACR5Table.TableName+' closed.');
end;

procedure TfmMain.ShowButtons(Enable: Boolean);
begin
  bn4Browse.Enabled := Enable;
  bn4OpenClose.Enabled := Enable;
  bn4To5Beta.Enabled := Enable;
  bn5BetaTo4.Enabled := Enable;
  bn5Browse.Enabled := Enable;
  bn5BetaOpenClose.Enabled := Enable;
  eDB4File.Enabled := Enable;
  eDB5File.Enabled := Enable;
  cbTransactions.Enabled := Enable;
  if (Enable) then
    ACR4Table.EnableControls
  else
    ACR4Table.DisableControls;
  if (Enable) then
    ACR5Table.EnableControls
  else
    ACR5Table.DisableControls;
end;

procedure TfmMain.bn4To5BetaClick(Sender: TObject);
var i,j:      Integer;
    s:        String;
    t:        Cardinal;
    f1:       double;
    fkExists: Boolean;
    FKDef5:   TACRForeignKeyDef;
begin
 FSuccess := False;
 FDestFile := eDB5File.Text;
 ShowButtons(False);
 t := GetTickCount;
 try
   if (not ACR4DB.Connected) then
     bn4OpenClose.Click;
   if (not ACR4DB.Connected) then
    begin
     if (FParamCount < 2) then
      MessageDlg('Error - Accuracer 4 file cannot be opened or created.',mtError,[mbOK],0);
     Exit;
    end;
   if (not ACR5DB.Connected) then
     bn5BetaOpenClose.Click;
   if (not ACR5DB.Connected) then
    begin
     if (FParamCount < 2) then
      MessageDlg('Error - Accuracer 5 file cannot be opened or created.',mtError,[mbOK],0);
     Exit;
    end;
   fkExists := False;
   for i := 0 to lb4Tables.Count-1 do
    if (lb4Tables.Selected[i]) then
      begin
       try
        if (ACR4Table.Active) then
          ACR4Table.Close;
        if (ACR5Table.Active) then
          ACR5Table.Close;
        ACR4Table.TableName := lb4Tables.Items[i];
        ACR4Table.Open;
        ACR5Table.TableName := ACR4Table.TableName;
        ConvertDefsTo5;
        if (not fkExists) then
          if (ACR4Table.ForeignKeyDefs.Count > 0) then
           fkExists := True;
        ACR5Table.CreateTable;
        ACR5Table.Open;
        reLog.Lines.Add('Converting table '+ACR5Table.TableName+'... RecordCount = '+IntToStr(ACR4Table.RecordCount));
        if (cbTransactions.Checked) then
         ACR5DB.StartTransaction;
        s := ACRMain.CopyDatasets(ACR4Table,ACR5Table,False,ACRMain.tbopCopy);
        if (s <> '') then
         reLog.Lines.Add('Error copying records: '+#13#10+s)
        else
         reLog.Lines.Add('Table '+ACR5Table.TableName+' converted successfully. RecordCount = '+IntToStr(ACR5Table.RecordCount));
        if (cbTransactions.Checked) then
         ACR5DB.Commit;
       except
        on e: Exception do
         begin
          if (cbTransactions.Checked) then
           if (ACR5DB.InTransaction) then
            ACR5DB.Rollback;
          reLog.Lines.Add('Error converting table '+ACR4Table.TableName+':'+#13#10+e.Message);
         end;
       end;
      end;
   if (fkExists) then
     for i := 0 to lb4Tables.Count-1 do
      if (lb4Tables.Selected[i]) then
        begin
         try
          ACR4Table.Close;
          ACR4Table.TableName := lb4Tables.Items[i];
          ACR4Table.Open;
          if (ACR4Table.ForeignKeyDefs.Count <= 0) then
           continue;
          ACR5Table.Close;
          ACR5Table.TableName := lb4Tables.Items[i];
          for j := 0 to ACR4Table.ForeignKeyDefs.Count - 1 do
           begin
            FKDef5 := ConvertFK4ToFK5(ACR4Table.ForeignKeyDefs.Items[j]);
            try
             ACR5Table.AddForeignKey(FKDef5);
            finally
             FKDef5.Free;
            end;
           end;
          ACR5Table.Open;
         except
          on e: Exception do
           begin
            if (cbTransactions.Checked) then
             if (ACR5DB.InTransaction) then
              ACR5DB.Rollback;
            reLog.Lines.Add('Error converting table '+ACR4Table.TableName+' - copying foreign keys:'+#13#10+e.Message);
           end;
         end; // except
        end; // copy foreign keys
   lb5Tables.Clear;
   ACR5DB.GetTablesList(lb5Tables.Items);
   reLog.Lines.Add('Accuracer 5 database: '+IntToStr(lb5Tables.Items.Count)+' tables');
   FSuccess := True;
 finally
   t := GetTickCount-t;
   f1 := t / 1000.0;
   reLog.Lines.Add('Conversion time, sec: '+Format('%8.3f',[f1]));
   ShowButtons(True);
 end;
end;

procedure TfmMain.ConvertDefsTo4;
var i:              Integer;
    AdvFieldDef4:   TAC4AdvFieldDef;
    AdvFieldDef5:   TACRAdvFieldDef;
    ms:             TACRMemoryStream;
begin
  ACR4Table.ClearDefinitions;
  ms := TACRMemoryStream.Create;
  try
    for i := 0 to ACR5Table.AdvFieldDefs.Count-1 do
     begin
      AdvFieldDef5 := ACR5Table.AdvFieldDefs.Items[i];
      AdvFieldDef4 := ACR4Table.AdvFieldDefs.AddFieldDef;
      AdvFieldDef4.Name := AdvFieldDef5.Name;
      AdvFieldDef4.DataType := AC4Types.TAC4AdvancedFieldType(Byte(AdvFieldDef5.DataType));
      AdvFieldDef4.Required := AdvFieldDef5.Required;
      AdvFieldDef4.Size := AdvFieldDef5.Size;
      if (not AdvFieldDef5.DefaultValue.IsNull) then
       begin
        ms.Size := 0;
        try
         AdvFieldDef5.DefaultValue.SaveToStream(ms);
         ms.Position := 0;
         AdvFieldDef4.DefaultValue.LoadFromStream(ms);
        except
        end;
       end;
      if (not AdvFieldDef5.MinValue.IsNull) then
       begin
        ms.Size := 0;
        try
         AdvFieldDef5.MinValue.SaveToStream(ms);
         ms.Position := 0;
         AdvFieldDef4.MinValue.LoadFromStream(ms);
        except
        end;
       end;
      if (not AdvFieldDef5.MaxValue.IsNull) then
       begin
        ms.Size := 0;
        try
         AdvFieldDef5.MaxValue.SaveToStream(ms);
         ms.Position := 0;
         AdvFieldDef4.MaxValue.LoadFromStream(ms);
        except
        end;
       end;
      AdvFieldDef4.AutoincIncrement := AdvFieldDef5.AutoincIncrement;
      AdvFieldDef4.AutoincInitialValue := AdvFieldDef5.AutoincInitialValue;
      AdvFieldDef4.AutoincMinValue := AdvFieldDef5.AutoincMinValue;
      AdvFieldDef4.AutoincMaxValue := AdvFieldDef5.AutoincMaxValue;
      AdvFieldDef4.AutoincCycled := AdvFieldDef5.AutoincCycled;
      AdvFieldDef4.BlobCompressionAlgorithm := AC4Main.TCompressionAlgorithm(Byte(
                                               AdvFieldDef5.BlobCompressionAlgorithm));
      AdvFieldDef4.BlobCompressionMode := AdvFieldDef5.BlobCompressionMode;
      AdvFieldDef4.BlobBlockSize := AdvFieldDef5.BlobBlockSize;
     end;
    ACR4Table.IndexDefs.Assign(ACR5Table.IndexDefs);
  finally
    ms.Free;
  end;
end;

procedure TfmMain.ConvertDefsTo5;
var i:              Integer;
    AdvFieldDef4:   TAC4AdvFieldDef;
    AdvFieldDef5:   TACRAdvFieldDef;
    ms:             TACRMemoryStream;
begin
  ACR5Table.ClearDefinitions;
  ms := TACRMemoryStream.Create;
  try
    for i := 0 to ACR4Table.AdvFieldDefs.Count-1 do
     begin
      AdvFieldDef4 := ACR4Table.AdvFieldDefs.Items[i];
      AdvFieldDef5 := ACR5Table.AdvFieldDefs.AddFieldDef;
      AdvFieldDef5.Name := AdvFieldDef4.Name;
      AdvFieldDef5.DataType := ACRTypes.TACRAdvancedFieldType(Byte(AdvFieldDef4.DataType));
      AdvFieldDef5.Required := AdvFieldDef4.Required;
      AdvFieldDef5.Size := AdvFieldDef4.Size;
      if (not AdvFieldDef4.DefaultValue.IsNull) then
       begin
        ms.Size := 0;
        try
         AdvFieldDef4.DefaultValue.SaveToStream(ms);
         ms.Position := 0;
         AdvFieldDef5.DefaultValue.LoadFromStream(ms);
        except
        end;
       end;
      if (not AdvFieldDef4.MinValue.IsNull) then
       begin
        ms.Size := 0;
        try
         AdvFieldDef4.MinValue.SaveToStream(ms);
         ms.Position := 0;
         AdvFieldDef5.MinValue.LoadFromStream(ms);
        except
        end;
       end;
      if (not AdvFieldDef4.MaxValue.IsNull) then
       begin
        ms.Size := 0;
        try
         AdvFieldDef4.MaxValue.SaveToStream(ms);
         ms.Position := 0;
         AdvFieldDef5.MaxValue.LoadFromStream(ms);
        except
        end;
       end;
      AdvFieldDef5.AutoincIncrement := AdvFieldDef4.AutoincIncrement;
      AdvFieldDef5.AutoincInitialValue := AdvFieldDef4.AutoincInitialValue;
      AdvFieldDef5.AutoincMinValue := AdvFieldDef4.AutoincMinValue;
      AdvFieldDef5.AutoincMaxValue := AdvFieldDef4.AutoincMaxValue;
      AdvFieldDef5.AutoincCycled := AdvFieldDef4.AutoincCycled;
      AdvFieldDef5.BlobCompressionAlgorithm := ACRComMain.TCompressionAlgorithm(Byte(
                                               AdvFieldDef4.BlobCompressionAlgorithm));
      AdvFieldDef5.BlobCompressionMode := AdvFieldDef4.BlobCompressionMode;
      AdvFieldDef5.BlobBlockSize := AdvFieldDef4.BlobBlockSize;
     end;
    ACR5Table.IndexDefs.Assign(ACR4Table.IndexDefs);
  finally
    ms.Free;
  end;
end; // ConvertDefsTo5

procedure TfmMain.bn5BetaTo4Click(Sender: TObject);
var i,j:      Integer;
    s:        String;
    t:        Cardinal;
    f1:       double;
    fkExists: Boolean;
    FKDef4:   TAC4ForeignKeyDef;
begin
 fkExists := False;
 FSuccess := False;
 FDestFile := eDB4File.Text;
 ShowButtons(False);
 t := GetTickCount;
 try
   if (not ACR4DB.Connected) then
     bn4OpenClose.Click;
   if (not ACR4DB.Connected) then
    begin
     if (FParamCount < 2) then
      MessageDlg('Error - Accuracer 4 file cannot be opened or created.',mtError,[mbOK],0);
     Exit;
    end;
   if (not ACR5DB.Connected) then
     bn5BetaOpenClose.Click;
   if (not ACR5DB.Connected) then
    begin
     if (FParamCount < 2) then
      MessageDlg('Error - Accuracer 5 file cannot be opened or created.',mtError,[mbOK],0);
     Exit;
    end;
   for i := 0 to lb5Tables.Count-1 do
    if (lb5Tables.Selected[i]) then
      begin
       try
        if (ACR4Table.Active) then
          ACR4Table.Close;
        if (ACR5Table.Active) then
          ACR5Table.Close;
        ACR5Table.TableName := lb5Tables.Items[i];
        ACR5Table.Open;
        if (not fkExists) then
          if (ACR5Table.ForeignKeyDefs.Count > 0) then
           fkExists := True;
        ACR4Table.TableName := ACR5Table.TableName;
        ConvertDefsTo4;
        ACR4Table.CreateTable;
        ACR4Table.Open;
        reLog.Lines.Add('Converting table '+ACR4Table.TableName+'... RecordCount = '+IntToStr(ACR4Table.RecordCount));
        if (cbTransactions.Checked) then
         ACR4DB.StartTransaction;
        s := ACRMain.CopyDatasets(ACR5Table,ACR4Table,True,ACRMain.tbopCopy);
        if (s <> '') then
         reLog.Lines.Add('Error copying records: '+#13#10+s)
        else
         reLog.Lines.Add('Table '+ACR4Table.TableName+' converted successfully. RecordCount = '+IntToStr(ACR4Table.RecordCount));
        if (cbTransactions.Checked) then
         ACR4DB.Commit;
       except
        on e: Exception do
         begin
          if (cbTransactions.Checked) then
           if (ACR4DB.InTransaction) then
            ACR4DB.Rollback;
          reLog.Lines.Add('Error converting table '+ACR5Table.TableName+':'+#13#10+e.Message);
         end;
       end;
      end;
   if (fkExists) then
     for i := 0 to lb5Tables.Count-1 do
      if (lb5Tables.Selected[i]) then
        begin
         try
          ACR5Table.Close;
          ACR5Table.TableName := lb5Tables.Items[i];
          ACR5Table.Open;
          if (ACR5Table.ForeignKeyDefs.Count <= 0) then
           continue;
          ACR4Table.Close;
          ACR4Table.TableName := lb5Tables.Items[i];
          for j := 0 to ACR5Table.ForeignKeyDefs.Count - 1 do
           begin
            FKDef4 := ConvertFK5ToFK4(ACR5Table.ForeignKeyDefs.Items[j]);
            try
             ACR4Table.AddForeignKey(FKDef4);
            finally
             FKDef4.Free;
            end;
           end;
          ACR4Table.Open;
         except
          on e: Exception do
           begin
            if (cbTransactions.Checked) then
             if (ACR4DB.InTransaction) then
              ACR4DB.Rollback;
            reLog.Lines.Add('Error converting table '+ACR5Table.TableName+' - copying foreign keys:'+#13#10+e.Message);
           end;
         end; // except
        end; // copy foreign keys
   lb4Tables.Clear;
   ACR4DB.GetTablesList(lb4Tables.Items);
   reLog.Lines.Add('Accuracer 4 database: '+IntToStr(lb4Tables.Items.Count)+' tables');
   FSuccess := True;
 finally
   t := GetTickCount-t;
   f1 := t / 1000.0;
   reLog.Lines.Add('Conversion time, sec: '+Format('%8.3f',[f1]));
   ShowButtons(True);
 end;
end;


procedure TfmMain.ProcessFromCommandLine;
var bTo4: boolean;
    i,l,sz: Integer;
    s:      String;
    fs:     TACRFileStream;
    buf:    PAnsiChar;
begin
  bTo4 := False;
  for i := 1 to FParamCount do
   begin
    s := ParamStr(i);
    l := Length(s);
    if (i = 1) then
     FSourceFile := s
    else
    if (i = 2) and (Pos('-',s) = 0) then
     FDestFile := s
    else
    if (l > 3) and ((Pos('-p4',s) > 0) or (Pos('/p4',s) > 0)) then
      FPassword4 := Copy(s,4,l-3)
    else
    if (l > 3) and ((Pos('-p5',s) > 0) or (Pos('/p5',s) > 0)) then
      FPassword5 := Copy(s,4,l-3)
    else
    if (l > 3) and ((Pos('-i4',s) > 0) or (Pos('/i4',s) > 0)) then
      FIVFile4 := Copy(s,4,l-3)
    else
    if (l > 3) and ((Pos('-i5',s) > 0) or (Pos('/i5',s) > 0)) then
      FIVFile5 := Copy(s,4,l-3)
    else
    if (l > 3) and ((Pos('-k4',s) > 0) or (Pos('/k4',s) > 0)) then
      FKeyFile4 := Copy(s,4,l-3)
    else
    if (l > 3) and ((Pos('-k5',s) > 0) or (Pos('/k5',s) > 0)) then
      FKeyFile5 := Copy(s,4,l-3)
    else
    if (l > 2) and ((Pos('-l',s) > 0) or (Pos('/l',s) > 0)) then
      FLogPath := Copy(s,3,l-2)
    else
    if (s = '-4') then
      bTo4 := True
    else
    if (s = '-5') then
      bTo4 := False;
   end;
  eDB4File.Text := FSourceFile;
  if (FDestFile = '') then
   FDestFile := ACRReplaceDB4Name(FSourceFile);
  eDB5File.Text := FDestFile;
  ACR5DB.CryptoParams.UseInitVector := False;
  ACR4DB.CryptoParams.UseInitVector := False;
  ACR4DB.DatabaseFileName := FSourceFile;
  ACR5DB.DatabaseFileName := FDestFile;

  // check if some settings missed
  if (FPassword4 <> '') then
   if (FPassword5 = '') and (not bTo4) then
    FPassword5 := FPassword4;
  if (FIVFile4 <> '') then
   if (FIVFile5 = '') and (not bTo4) then
    FIVFile5 := FIVFile4;
  if (FKeyFile4 <> '') then
   if (FKeyFile5 = '') and (not bTo4) then
    FKeyFile5 := FKeyFile4;

  if (FPassword5 <> '') then
   if (FPassword4 = '') and (bTo4) then
    FPassword4 := FPassword5;
  if (FIVFile5 <> '') then
   if (FIVFile4 = '') and (bTo4) then
    FIVFile4 := FIVFile5;
  if (FKeyFile5 <> '') then
   if (FKeyFile4 = '') and (bTo4) then
    FKeyFile4 := FKeyFile5;

  // set password for Accuracer 4 database
  if (FPassword4 <> '') then
   ACR4DB.CryptoParams.Password := FPassword4
  else
   ACR4DB.CryptoParams.Password := '';

  // initial vector for Accuracer 4 database
  if (FIVFile4 <> '') then
   if (ACRFileExists(FIVFile4)) then
    try
     fs := TACRFileStream.Create(FIVFile4,fmOpenRead or fmShareDenyWrite);
     try
      sz := fs.Size;
      buf := MemoryManager.GetMem(sz);
      try
       fs.ReadBuffer(buf^,sz);
       ACR4DB.CryptoParams.SetInitVector(buf);
       ACR4DB.CryptoParams.UseInitVector := True;
      finally
       MemoryManager.FreeAndNilMem(buf);
      end;
     finally
      fs.Free;
     end;
    except on E: Exception do
     begin
       reLog.Lines.Add('Error loading initival vector for Accuracer 4:'+#13#10+e.Message);
       exit;
     end;
    end;

  // initial vector for Accuracer 4 database
  if (FKeyFile4 <> '') then
   if (ACRFileExists(FKeyFile4)) then
    try
     fs := TACRFileStream.Create(FKeyFile4,fmOpenRead or fmShareDenyWrite);
     try
      sz := fs.Size;
      buf := MemoryManager.GetMem(sz);
      try
       fs.ReadBuffer(buf^,sz);
       ACR4DB.CryptoParams.SetKey(buf,sz);
       ACR4DB.CryptoParams.Password := '';
      finally
       MemoryManager.FreeAndNilMem(buf);
      end;
     finally
      fs.Free;
     end;
    except on E: Exception do
     begin
       reLog.Lines.Add('Error loading key for Accuracer 4:'+#13#10+e.Message);
       exit;
     end;
    end;

  if (FPassword5 <> '') then
   ACR5DB.CryptoParams.Password := FPassword5
  else
   ACR5DB.CryptoParams.Password := '';

  // initial vector for Accuracer 5 database
  if (FIVFile5 <> '') then
   if (ACRFileExists(FIVFile5)) then
    try
     fs := TACRFileStream.Create(FIVFile5,fmOpenRead or fmShareDenyWrite);
     try
      sz := fs.Size;
      buf := MemoryManager.GetMem(sz);
      try
       fs.ReadBuffer(buf^,sz);
       ACR5DB.CryptoParams.SetInitVector(buf,sz);
       ACR5DB.CryptoParams.UseInitVector := True;
      finally
       MemoryManager.FreeAndNilMem(buf);
      end;
     finally
      fs.Free;
     end;
    except on E: Exception do
     begin
       reLog.Lines.Add('Error loading initival vector for Accuracer 5:'+#13#10+e.Message);
       exit;
     end;
    end;

  // initial vector for Accuracer 5 database
  if (FKeyFile5 <> '') then
   if (ACRFileExists(FKeyFile5)) then
    try
     fs := TACRFileStream.Create(FKeyFile5,fmOpenRead or fmShareDenyWrite);
     try
      sz := fs.Size;
      buf := MemoryManager.GetMem(sz);
      try
       fs.ReadBuffer(buf^,sz);
       ACR5DB.CryptoParams.SetKey(buf,sz);
       ACR5DB.CryptoParams.Password := '';
      finally
       MemoryManager.FreeAndNilMem(buf);
      end;
     finally
      fs.Free;
     end;
    except on E: Exception do
     begin
       reLog.Lines.Add('Error loading key for Accuracer 5:'+#13#10+e.Message);
       exit;
     end;
    end;
  if (bTo4) then
   bn5BetaTo4Click(Self)
  else
   bn4To5BetaClick(Self);
end;


function ConvertFK4ToFK5(FKDef4: TAC4ForeignKeyDef): TACRForeignKeyDef;
begin
  Result := TACRForeignKeyDef.Create;
  Result.Name := FKDef4.Name;
  Result.ReferencedTableName := FKDef4.ReferencedTableName;
  Result.Columns := FKDef4.Columns;
  Result.MatchType := ACRMain.TACRForeignKeyMatchType(Byte(FKDef4.MatchType));
  Result.DeleteAction := ACRMain.TACRForeignKeyAction(Byte(FKDef4.DeleteAction));
  Result.UpdateAction := ACRMain.TACRForeignKeyAction(Byte(FKDef4.UpdateAction));
end; // ConvertFK4ToFK5


function ConvertFK5ToFK4(FKDef5: TACRForeignKeyDef): TAC4ForeignKeyDef;
begin
  Result := TAC4ForeignKeyDef.Create;
  Result.Name := FKDef5.Name;
  Result.ReferencedTableName := FKDef5.ReferencedTableName;
  Result.Columns := FKDef5.Columns;
  Result.MatchType := AC4Main.TAC4ForeignKeyMatchType(Byte(FKDef5.MatchType));
  Result.DeleteAction := AC4Main.TAC4ForeignKeyAction(Byte(FKDef5.DeleteAction));
  Result.UpdateAction := AC4Main.TAC4ForeignKeyAction(Byte(FKDef5.UpdateAction));
end; // ConvertFK5ToFK4

procedure CopyCryptoParams4To5(ACR4DB: TAC4Database; ACR5DB: TACRDatabase);
begin
 ACR5DB.CryptoParams.CryptoAlgorithm := TACRCryptoAlgorithm(ACR4DB.CryptoParams.CryptoAlgorithm);
 if (ACR5DB.CryptoParams.CryptoAlgorithm = TACRCryptoAlgorithm(craNone)) then
  Exit;
 case ACR4DB.CryptoParams.CryptoMode of
  acmCTS: ACR5DB.CryptoParams.CryptoMode := TACRCryptoMode(acmCTS);
  acmCBC: ACR5DB.CryptoParams.CryptoMode := TACRCryptoMode(acmCBC);
  acmCFB: ACR5DB.CryptoParams.CryptoMode := TACRCryptoMode(acmCFB);
  acmOFB: ACR5DB.CryptoParams.CryptoMode := TACRCryptoMode(acmOFB);
 end;
 if (ACR4DB.CryptoParams.Password <> '') then
  ACR5DB.CryptoParams.Password := ACR4DB.CryptoParams.Password
 else
  begin
    // binary key
    ACR5DB.CryptoParams.Password := '';
    ACR5DB.CryptoParams.SetKey(ACR4DB.CryptoParams.GetKey,ACR4DB.CryptoParams.KeySize);
  end;
 // init vector
 ACR5DB.CryptoParams.UseInitVector := ACR4DB.CryptoParams.UseInitVector;
 if (ACR4DB.CryptoParams.UseInitVector) then
  begin
   ACR5DB.CryptoParams.SetInitVector(
     ACR4DB.CryptoParams.GetInitVector,
     ACR4DB.CryptoParams.MaxInitVectorSize);
  end;
end;

procedure CopyCryptoParams5To4(ACR5DB: TACRDatabase; ACR4DB: TAC4Database);
begin
 ACR4DB.CryptoParams.CryptoAlgorithm := TAC4CryptoAlgorithm(ACR5DB.CryptoParams.CryptoAlgorithm);
 if (ACR4DB.CryptoParams.CryptoAlgorithm = TAC4CryptoAlgorithm(craNone)) then
  Exit;
 case ACR5DB.CryptoParams.CryptoMode of
  TACRCryptoMode(acmCTS): ACR4DB.CryptoParams.CryptoMode := TAC4CryptoMode(acmCTS);
  TACRCryptoMode(acmCBC): ACR4DB.CryptoParams.CryptoMode := TAC4CryptoMode(acmCBC);
  TACRCryptoMode(acmCFB): ACR4DB.CryptoParams.CryptoMode := TAC4CryptoMode(acmCFB);
  TACRCryptoMode(acmOFB): ACR4DB.CryptoParams.CryptoMode := TAC4CryptoMode(acmOFB)
 else
  ACR4DB.CryptoParams.CryptoMode := TAC4CryptoMode(acmCTS);
 end;
 if (ACR5DB.CryptoParams.Password <> '') then
  ACR4DB.CryptoParams.Password := ACR5DB.CryptoParams.Password
 else
  begin
    // binary key
    ACR4DB.CryptoParams.Password := '';
    ACR4DB.CryptoParams.SetKey(ACR5DB.CryptoParams.GetKey,ACR5DB.CryptoParams.KeySize);
  end;
 // init vector
 ACR4DB.CryptoParams.UseInitVector := ACR5DB.CryptoParams.UseInitVector;
 if (ACR5DB.CryptoParams.UseInitVector) then
  begin
   ACR4DB.CryptoParams.SetInitVector(ACR5DB.CryptoParams.GetInitVector);
  end;
end;


function ACRReplaceDB4Name(FileName: String): String;
var n,l: Integer;
    ext: String;
begin
 l := Length(FileName);
 ext := ExtractFileExt(FileName);
 n := Length(ext);
 if (n > 0) then
  Result := Copy(FileName,1,l-n)
 else
  Result := FileName;
 Result := Result +  '_5'+ ext;
end;

end.
