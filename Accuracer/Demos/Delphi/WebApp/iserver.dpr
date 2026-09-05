{
  1. Compile this DLL.
  2. Place it into your web server scripts directory.
  3. Copy file DBFishes.edb into your web server scripts directory.
  4. You can then access this application  from a web browser
     using http://<your web server>/scripts/iserver.dll
}
library IServer;

uses
{$IFNDEF VER120}
  WebBroker,
  HTTPApp,
  ISAPIApp,
{$ELSE}
  HTTPApp,
  ISAPIApp,
{$ENDIF}
  main in 'main.pas' {CustomerInfoModule: TDataModule};

{$R *.RES}

exports
  GetExtensionVersion,
  HttpExtensionProc,
  TerminateExtension;

begin
  IsMultiThread := true;
  Application.Initialize;
  Application.CreateForm(TCustomerInfoModule, CustomerInfoModule);
  Application.Run;
end.
