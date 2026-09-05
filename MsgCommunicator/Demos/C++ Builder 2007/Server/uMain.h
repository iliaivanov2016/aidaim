//---------------------------------------------------------------------------
#ifndef uMainH
#define uMainH
//---------------------------------------------------------------------------
#include <alloc.h>
#include <stdlib.h>
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "MsgComBase.hpp"
#include "MsgServer.hpp"
#include <ComCtrls.hpp>
#include <ExtCtrls.hpp>
#include <Grids.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TPageControl *Pages;
        TTabSheet *Control;
        TLabel *Label6;
        TButton *ServerStart;
        TButton *ServerStop;
        TEdit *LocalPort;
        TTabSheet *Users;
        TLabel *Label5;
        TStringGrid *sgAllUsers;
        TEdit *SelectedUserID;
        TButton *DeleteUser;
        TButton *DisconnectUser;
        TTabSheet *Send;
        TLabel *Label10;
        TLabel *Label2;
        TLabel *Label3;
        TStringGrid *sgConnectedUsers;
        TButton *ServerSend;
        TEdit *ServerToID;
        TMemo *ServerMsg;
        TTabSheet *Incoming;
        TLabel *Label1;
        TMemo *ServerIncoming;
        TTabSheet *Sent;
        TLabel *Label4;
        TMemo *ServerSent;
        TMsgServer *MsgServer1;
        TTimer *Timer1;
        void __fastcall FormClose(TObject *Sender, TCloseAction &Action);
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall Timer1Timer(TObject *Sender);
        void __fastcall MsgServer1AfterConnect(TObject *Sender);
        void __fastcall MsgServer1AfterDisconnect(TObject *Sender);
        void __fastcall MsgServer1AfterServerStart(TObject *Sender);
        void __fastcall MsgServer1BeforeServerStop(TObject *Sender);
        void __fastcall MsgServer1BeforeDisconnect(TObject *Sender);
        void __fastcall MsgServer1ReceiveTextMessage(
          const DWORD FromUserID, const TDateTime SendingDate,
          const TDateTime DeliveryDate, const AnsiString Text);
        void __fastcall ServerStartClick(TObject *Sender);
        void __fastcall ServerStopClick(TObject *Sender);
        void __fastcall sgAllUsersSelectCell(TObject *Sender, int ACol,
          int ARow, bool &CanSelect);
        void __fastcall DisconnectUserClick(TObject *Sender);
        void __fastcall DeleteUserClick(TObject *Sender);
        void __fastcall ServerSendClick(TObject *Sender);
        void __fastcall sgConnectedUsersSelectCell(TObject *Sender,
          int ACol, int ARow, bool &CanSelect);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
        void __fastcall FillGrids();
        void __fastcall ClearGrid(TStringGrid *Grid);

};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
