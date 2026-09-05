unit uDisplayThread;

interface

uses
  Classes, SysUtils,  Dialogs, Windows, ComCtrls;

type
  TDisplayThread = class(TThread)
  private
    FText:     String;
    FRichEdit: TRichEdit;
  protected
    procedure Execute; override;
    procedure Display;
  public
    property Text: String read FText write FText;
    property RichEdit: TRichEdit read FRichEdit write FRichEdit default nil;
  end;

implementation

uses uMain;

procedure TDisplayThread.Execute;
begin
 Synchronize(Display);
end;

procedure TDisplayThread.Display;
begin
 if (FRichEdit <> nil) then
   FRichEdit.Lines.Add(FText);
end;

end.
