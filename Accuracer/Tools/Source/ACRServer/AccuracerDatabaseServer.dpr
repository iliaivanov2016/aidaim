program AccuracerDatabaseServer;

uses
  WinSvc,
  SvcMgr,
  SysUtils,
  Windows,
  Forms,
  ACRServer,
  ACRConst,
  MainUnit in 'MainUnit.pas' {MainForm},
  AboutUnit in 'AboutUnit.pas' {ACRManAbout};

{$R *.RES}

function StartingService(var Interactive: Boolean): Boolean;
var
  ConfigBytes:     DWORD;
  Service,Manager: Integer;
  ServiceStatus:   TServiceStatus;
  ServiceConfig:   pQueryServiceConfig;
begin
  Result := False;
  Interactive := False;
  ServerName := AnsiUpperCase(ExtractFileName(Application.ExeName));
  ServerName := StringReplace(ServerName,ExtractFileExt(ServerName),'',[rfReplaceAll]);
  Manager := OpenSCManager(nil,nil,SC_MANAGER_ALL_ACCESS);
  if (Manager <> 0) then
   begin
    try
     Service := OpenService(Manager,PChar(String(ServerName)),SERVICE_ALL_ACCESS);
     Result := (Service <> 0);
     if (Result) then
      begin
       try
        if (QueryServiceStatus(Service,ServiceStatus)) then
         begin
          if (ServiceStatus.dwCurrentState = SERVICE_START_PENDING) then
           begin
            Result := True;
            QueryServiceConfig(Service,nil,0,ConfigBytes);
            ServiceConfig := AllocMem(ConfigBytes);
            try
             if QueryServiceConfig(Service,ServiceConfig,ConfigBytes,ConfigBytes) then
              Interactive := ((ServiceConfig^.dwServiceType and SERVICE_INTERACTIVE_PROCESS) = SERVICE_INTERACTIVE_PROCESS);
            finally
             FreeMem(ServiceConfig);
            end;
           end
          else
           Result := False;
         end
        else
         Result := False;
       finally
        CloseServiceHandle(Service);
       end;
      end; // if (Result)
    finally
     CloseServiceHandle(Manager);
    end;
   end; // if (Manager <> 0)
end; // StartingService


function GetServerName: String;
var s: String;
begin
  s := AnsiUpperCase(ExtractFileName(ParamStr(0)));
  s := Copy(s,1,Length(s)-4);
  Result := s;
end; // GetServerName


const
   ACR_SERVER_GUID = '{7E102F1D-C7AF-4CBB-A401-317DDBCFD197}';
var
  IsInteractive: Boolean;
  Mutex:         THandle;
  MutexName:     array [0..MAX_PATH] of Char;
begin
{$RANGECHECKS OFF}
  StrPCopy(@MutexName, ACR_SERVER_GUID);
  Mutex := CreateMutex(nil, True, @MutexName);
  if ((Mutex <> 0) and (GetLastError = 0)) then
   begin
    IsInteractive := False;
    ServerName := GetServerName;
    ServerDescription := ACRServerDescription;
    if (InstallingService or StartingService(IsInteractive)) then
     begin
      SvcMgr.Application.Initialize;
      if (InstallingService) then
        ServerService := TACRServerService.CreateNew(SvcMgr.Application,Integer(InteractiveService))
      else
        ServerService := TACRServerService.CreateNew(SvcMgr.Application,Integer(IsInteractive));
      SvcMgr.Application.CreateForm(TMainForm, MainForm);
      SvcMgr.Application.Run;
     end
    else
     begin
      Forms.Application.ShowMainForm := False;
      Forms.Application.UpdateFormatSettings := False;
      Forms.Application.Initialize;
      Forms.Application.CreateForm(TMainForm,MainForm);
      Forms.Application.CreateForm(TACRManAbout,ACRManAbout);
      MainForm.Initialize(nil);
      Forms.Application.Run;
     end;
    CloseHandle(Mutex);
   end; // if ((Mutex <> 0) and (GetLastError = 0))
end.
