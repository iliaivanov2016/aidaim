unit MainUnit;

interface

{$I ver.inc}

uses
   SvcMgr, Windows, Messages,
   Dialogs, StdCtrls, Forms,
   SysUtils, Classes, Graphics,
   ExtCtrls, Menus, Controls, ShellAPI,
   ACRConst,
   ACRTypesNetwork,
   ACRServer,
   ACRCriticalSection, ComCtrls, Grids;

const

   DS_INITIALIZE = (WM_USER+1);
   DS_TRAYICON = (WM_USER+2);
   DS_DESTROY = (WM_USER+3);

type

  TACRServerService = class(TService)
   protected
    procedure Start(Sender: TService; var Started: Boolean);
    procedure Stop(Sender: TService; var Stopped: Boolean);
   public
    function GetServiceController: TServiceController; override;
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
  end;

  TMainForm = class(TForm)
    pmTrayMenu: TPopupMenu;
    imgServerUp: TImage;
    imgServerDown: TImage;
    miViewSettings: TMenuItem;
    miStopServer: TMenuItem;
    miStartServer: TMenuItem;
    miShutdown: TMenuItem;
    tTimer: TTimer;
    SaveDialog: TSaveDialog;
    OpenDialog: TOpenDialog;
    pnlBottom: TPanel;
    Splitter1: TSplitter;
    bnStart: TButton;
    bnStop: TButton;
    bnLoadSettings: TButton;
    bnSaveSettings: TButton;
    bnAbout: TButton;
    bnClose: TButton;
    bnShutdown: TButton;
    pnlClient: TPanel;
    pgcntrlClient: TPageControl;
    tsServerSettings: TTabSheet;
    mServerSettings: TMemo;
    tsConnections: TTabSheet;
    sgConnections: TStringGrid;
    Server: TACRServer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure miViewSettingsClick(Sender: TObject);
    procedure miShutdownClick(Sender: TObject);
    procedure bnCloseClick(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth,
      NewHeight: integer; var Resize: Boolean);
    procedure AboutButtonClick(Sender: TObject);
    procedure bnStopClick(Sender: TObject);
    procedure bnStartClick(Sender: TObject);
    procedure tTimerTimer(Sender: TObject);
    procedure ServerServerStart(Sender: TObject);
    procedure ServerServerStop(Sender: TObject);
    procedure bnLoadSettingsClick(Sender: TObject);
    procedure bnSaveSettingsClick(Sender: TObject);
    procedure bnShutdownClick(Sender: TObject);
   private
    FISect:             TRTLCriticalSection;
    FromService:        Boolean;
    FNoUserInterface:   Boolean;
    FIconHint:          String;
    FIconVisible:       Boolean;

   protected
    procedure DSInitialize(var Msg: TMessage); message DS_INITIALIZE;
    procedure DSTrayIcon(var Msg: TMessage); message DS_TRAYICON;
    procedure DSDestroy(var Msg: TMessage); message DS_DESTROY;
    procedure UpdateTrayIcon;
    procedure RemoveTrayIcon;
    procedure ShowConnections;
   public
    FCurrentDir: String;
   public
    procedure Initialize(Service: TService);
   end;

var
   MainForm:          TMainForm;
   ServerService:     TACRServerService;
   ServerName:        String;
   ServerDescription: String;

implementation

uses
   AboutUnit;

{$R *.DFM}

procedure ServiceController(CtrlCode: DWORD); stdcall;
begin
   ServerService.Controller(CtrlCode);
end;


function TACRServerService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;


constructor TACRServerService.CreateNew(AOwner: TComponent; Dummy: Integer);
begin
  inherited CreateNew(AOwner,Dummy);
  AllowStop := True;
  AllowPause := False;
  Interactive := Boolean(Dummy);
  DisplayName := ACRServerDescription;
  Name := ServerName;
  OnStart := Start;
  OnStop := Stop;
end;


procedure TACRServerService.Start(Sender: TService; var Started: Boolean);
begin
  PostMessage(MainForm.Handle,DS_INITIALIZE,1,Integer(Self));
  Started := True;
end;


procedure TACRServerService.Stop(Sender: TService; var Stopped: Boolean);
begin
  PostMessage(MainForm.Handle,WM_QUIT,0,0);
  Stopped := True;
end;


////////////////////////////////////////////////////////////////////////////////
//
// TMainForm
//
////////////////////////////////////////////////////////////////////////////////


procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCurrentDir := ExtractFilePath(Application.ExeName);
  OpenDialog.FileName := Server.ConfigFileName;
  SaveDialog.FileName := Server.ConfigFileName;
  SaveDialog.InitialDir := ExtractFilePath(Application.ExeName);
  OpenDialog.InitialDir := ExtractFilePath(Application.ExeName);
  pgcntrlClient.ActivePageIndex := 0;
  sgConnections.ColWidths[0] := 28;
  sgConnections.ColWidths[1] := 70;
  sgConnections.ColWidths[2] := 35;
  sgConnections.ColWidths[3] := 100;
  sgConnections.ColWidths[4] := 100;
  sgConnections.ColWidths[5] := 185;
  sgConnections.ColWidths[6] := 70;
end;


procedure TMainForm.FormDestroy(Sender: TObject);
begin
 if (not InstallingService) then
  begin
    if (not FNoUserInterface) then
     tTimer.Enabled := False;
    try
     Server.Active := False;
    except
    end;
    if (not FNoUserInterface) then
     begin
      RemoveTrayIcon;
      DeleteCriticalSection(FISect)
     end;
  end;
end;


procedure TMainForm.miViewSettingsClick(Sender: TObject);
begin
  Show;
end;


procedure TMainForm.miShutdownClick(Sender: TObject);
begin
  Close;
end;


procedure TMainForm.bnCloseClick(Sender: TObject);
begin
  Hide;
end;


procedure TMainForm.FormShow(Sender: TObject);
begin
  ActiveControl := bnClose;
end;


procedure TMainForm.FormCanResize(Sender: TObject; var NewWidth,
   NewHeight: integer; var Resize: Boolean);
begin
  Resize := False;
end;


procedure TMainForm.AboutButtonClick(Sender: TObject);
begin
  ACRManAbout.ShowModal;
end;


procedure TMainForm.bnStartClick(Sender: TObject);
begin
  try
    bnStart.Enabled := False;
    miStartServer.Enabled := False;
    FIconHint := 'Started';
    UpdateTrayIcon;
    Server.Active := True;
  except
    bnStart.Enabled := True;
    miStartServer.Enabled := True;
    bnStop.Enabled := False;
    miStopServer.Enabled := False;
    UpdateTrayIcon;
    raise;
  end;
end;


procedure TMainForm.bnStopClick(Sender: TObject);
var ContinueStopping: Boolean;
begin
  ContinueStopping := True;
  if (ContinueStopping) then
    begin
      try
        FIconHint := 'Stopped';
        UpdateTrayIcon;
        bnStop.Enabled := False;
        miStopServer.Enabled := False;
        Server.Active := False;
      except
        bnStart.Enabled := False;
        miStartServer.Enabled := False;
        bnStop.Enabled := True;
        miStopServer.Enabled := True;
        UpdateTrayIcon;
        raise;
      end;
    end;
end;


procedure TMainForm.tTimerTimer(Sender: TObject);
begin
  UpdateTrayIcon;
  ShowConnections;
end;


procedure TMainForm.ServerServerStart(Sender: TObject);
begin
  bnStart.Enabled := False;
  bnStop.Enabled := True;
  miStartServer.Enabled := False;
  miStopServer.Enabled := True;
  UpdateTrayIcon;
  mServerSettings.Lines.LoadFromFile(Server.ConfigFileName);
end;


procedure TMainForm.ServerServerStop(Sender: TObject);
begin
  bnStart.Enabled := True;
  bnStop.Enabled := False;
  miStartServer.Enabled := True;
  miStopServer.Enabled := False;
  UpdateTrayIcon;
end;


procedure TMainForm.bnLoadSettingsClick(Sender: TObject);
begin
  if (OpenDialog.Execute) then
   begin
    try
      Server.ConfigFileName := OpenDialog.FileName;
      Server.LoadSettingsFromConfigFile;
      MessageDlg('Settings loaded successfully.',mtInformation,[mbOK],0);
    except
      on e: Exception do
        MessageDlg('Error loading settings from file "'+
                   Server.ConfigFileName+'", error message: '+e.Message,
                   mtError,[mbOK],0);
    end;
   end;
end;


procedure TMainForm.bnSaveSettingsClick(Sender: TObject);
begin
  if (SaveDialog.Execute) then
   begin
    try
      Server.ConfigFileName := SaveDialog.FileName;
      Server.SaveSettingsToConfigFile;
      MessageDlg('Settings saved successfully.',mtInformation,[mbOK],0);
    except
      on e: Exception do
        MessageDlg('Error saving settings from file "'+
                   Server.ConfigFileName+'", error message: '+e.Message,
                   mtError,[mbOK],0);
    end;
   end;
end;


procedure TMainForm.DSInitialize(var Msg: TMessage);
begin
  Initialize(TService(Msg.LParam));
end;


procedure TMainForm.DSTrayIcon(var Msg: TMessage);
var Point: TPoint;
begin
 with Msg do
  begin
    case LParam of
      WM_RBUTTONDOWN:
        begin
          GetCursorPos(Point);
          SetForegroundWindow(Handle);
          pmTrayMenu.Popup(Point.X,Point.Y);
        end;
      WM_LBUTTONDBLCLK:
        begin
          pmTrayMenu.Items[0].Click;
        end;
    end;
  end;
end;


procedure TMainForm.DSDestroy(var Msg: TMessage);
begin
{$IFDEF DEBUG_SERVER}
  Close();
  Application.Terminate;
{$ENDIF}
end;


procedure TMainForm.UpdateTrayIcon;
var IconData: TNotifyIconData;
begin
  if (FNoUserInterface) then
    Exit;
  EnterCriticalSection(FISect);
  try
    IconData.cbSize := SizeOf(IconData);
    IconData.Wnd := Handle;
    IconData.uID := Tag;
    IconData.uFlags := (NIF_ICON or NIF_TIP or NIF_MESSAGE);
    IconData.uCallbackMessage := DS_TRAYICON;
    StrPCopy(IconData.szTip,FIconHint);
    if (Server.Active) then
      IconData.hIcon := imgServerUp.Picture.Icon.Handle
    else
      IconData.hIcon := imgServerDown.Picture.Icon.Handle;
    if (FIconVisible) then
      Shell_NotifyIcon(NIM_MODIFY,@IconData)
    else
      begin
       if (Shell_NotifyIcon(NIM_ADD,@IconData)) then
         FIconVisible := True;
      end;
  finally
    LeaveCriticalSection(FISect);
  end;
end;


procedure TMainForm.RemoveTrayIcon;
var IconData: TNotifyIconData;
begin
  EnterCriticalSection(FISect);
  try
    IconData.cbSize := SizeOf(IconData);
    IconData.Wnd := Handle;
    IconData.uID := Tag;
    IconData.uFlags := (NIF_ICON or NIF_TIP or NIF_MESSAGE);
    IconData.uCallbackMessage := DS_TRAYICON;
    if (Shell_NotifyIcon(NIM_DELETE,@IconData)) then
      FIconVisible := False;
  finally
    LeaveCriticalSection(FISect);
  end;
end;


procedure TMainForm.ShowConnections;
var i:        Integer;
    Clients:  TACRClientInfoArray;

 procedure ClearGrid;
 var i:        Integer;
 begin
   sgConnections.RowCount := 2;
   for i := 0 to sgConnections.ColCount-1 do
    sgConnections.Cells[i,1] := '';
 end;

begin
 ClearGrid;
 if (not Server.Active) then
   Exit;
 Server.GetClients(Clients);
 sgConnections.ShowHint := True;
 sgConnections.Hint := 'Clients connected: '+IntToStr(Length(Clients));
 sgConnections.RowCount := Length(Clients)+1;
 if (sgConnections.RowCount < 2) then
  sgConnections.RowCount := 2;
 sgConnections.FixedRows := 1;
 sgConnections.Cells[0,0] := 'Protocol';
 sgConnections.Cells[1,0] := 'Host';
 sgConnections.Cells[2,0] := 'Port';
 sgConnections.Cells[3,0] := 'Application';
 sgConnections.Cells[4,0] := 'Database name';
 sgConnections.Cells[5,0] := 'Database file';
 sgConnections.Cells[6,0] := 'SessionID';
 for i := Low(Clients) to High(Clients) do
  begin
   if Clients[i].Protocol = acrUDP then
     sgConnections.Cells[0,i+1] := 'UDP'
   else
     sgConnections.Cells[0,i+1] := 'TCP';
   sgConnections.Cells[1,i+1] := Clients[i].Host;
   sgConnections.Cells[2,i+1] := IntToStr(Clients[i].Port);
   sgConnections.Cells[3,i+1] := Clients[i].Application;
   sgConnections.Cells[4,i+1] := Clients[i].DatabaseName;
   sgConnections.Cells[5,i+1] := Clients[i].DatabaseFileName;
   sgConnections.Cells[6,i+1] := IntToStr(Clients[i].SessionID);
  end;
 Clients := nil;
end;


procedure TMainForm.Initialize(Service: TService);
begin
  // go to current directory
  ChDir(FCurrentDir);
  FromService := (Service <> nil);
  FNoUserInterface := False;
  if (FromService) then
   begin
    miShutdown.Visible := False;
    FNoUserInterface := (not Service.Interactive);
   end;
  if (not FNoUserInterface) then
   begin
    InitializeCriticalSection(FISect);
    tTimer.Enabled := True;
   end;
  try
   Server.Active := True;
  except
  end;
  if (not FNoUserInterface) then
   tTimer.Enabled := True;
end;


procedure TMainForm.bnShutdownClick(Sender: TObject);
begin
 miShutdownClick(Sender);
end;


end.

