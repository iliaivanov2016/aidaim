//---------------------------------------------------------------------------
#ifndef Unit1H
#define Unit1H
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include "MsgClient.hpp"
#include "MsgConst.hpp"
#include "MsgComBase.hpp"
#include <CheckLst.hpp>
#include <ExtCtrls.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TLabel *Label17;
        TPanel *pCenter;
        TGroupBox *gbSend;
        TLabel *Label3;
        TLabel *Label5;
        TLabel *Label6;
        TMemo *U1Msg;
        TButton *U1Send;
        TComboBox *U1To;
        TEdit *U1ToID;
        TGroupBox *gbMessages;
        TMemo *U1Incoming;
        TPanel *pLeft;
        TGroupBox *gbConnection;
        TLabel *Label2;
        TLabel *Label4;
        TLabel *Label7;
        TLabel *Label9;
        TLabel *Label8;
        TLabel *Label23;
        TEdit *ServerID;
        TEdit *ServerHost;
        TEdit *ServerPort;
        TEdit *ClientPort;
        TEdit *UserID;
        TEdit *Password;
        TButton *U1Connect;
        TButton *U1Disconnect;
        TButton *btnLogon;
        TButton *btnLogoff;
        TGroupBox *gbRegistration;
        TLabel *Label12;
        TLabel *Label10;
        TLabel *Label13;
        TLabel *Label14;
        TLabel *Label15;
        TLabel *Label16;
        TLabel *Label24;
        TEdit *RegUserID;
        TEdit *RegPassword;
        TEdit *RegUserName;
        TEdit *RegUserFirstName;
        TEdit *RegUserLastName;
        TEdit *RegUserCompany;
        TEdit *RegUserDepartment;
        TPanel *pRegTop;
        TButton *btnRegister;
        TPanel *pRight;
        TGroupBox *gbContacts;
        TPanel *pContactsTop;
        TButton *btnGetContactList;
        TPanel *pContactsBottom;
        TLabel *Label1;
        TEdit *UserID2Add;
        TButton *btnAddUserToContacts;
        TButton *btnRemoveUserFromContacts;
        TCheckListBox *clbContactList;
        TGroupBox *gbUserInfo;
        TLabel *Label18;
        TLabel *Label19;
        TLabel *Label20;
        TLabel *Label21;
        TLabel *Label22;
        TEdit *InfoUserName;
        TEdit *InfoUserFirstName;
        TEdit *InfoUserLastName;
        TEdit *InfoUserCompany;
        TEdit *InfoUserDepartment;
        TPanel *pUserInfoTop;
        TLabel *Label11;
        TEdit *UserID2GetInfo;
        TButton *btnGetUserInfo;
        TPanel *pGap;
        TMsgClient *MsgClient1;
        void __fastcall U1ConnectClick(TObject *Sender);
        void __fastcall U1DisconnectClick(TObject *Sender);
        void __fastcall MsgClient1ServerShutdown(TObject *Sender);
        void __fastcall MsgClient1ReceiveTextMessage(
          const DWORD FromUserID, const TDateTime SendingDate,
          const TDateTime DeliveryDate, const AnsiString Text);
        void __fastcall MsgClient1UserOffLine(const DWORD UserID);
        void __fastcall MsgClient1UserOnLine(const DWORD UserID);
        void __fastcall btnLogonClick(TObject *Sender);
        void __fastcall btnLogoffClick(TObject *Sender);
        void __fastcall btnRegisterClick(TObject *Sender);
        void __fastcall btnGetContactListClick(TObject *Sender);
        void __fastcall btnAddUserToContactsClick(TObject *Sender);
        void __fastcall btnRemoveUserFromContactsClick(TObject *Sender);
        void __fastcall btnGetUserInfoClick(TObject *Sender);
        void __fastcall U1SendClick(TObject *Sender);
        void __fastcall U1ToChange(TObject *Sender);
        void __fastcall U1ToIDChange(TObject *Sender);
        void __fastcall UserIDChange(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
        void __fastcall ShowError(AnsiString Operation, int ErrorCode);
        void __fastcall VisualizeLogged();
        void __fastcall AddMessage(
                                        const unsigned int FromUserID,
                                        const AnsiString Text,
                                        const TDateTime MsgDate);
        void __fastcall SetConnectParams();
        void __fastcall GetConnectParams();
        void __fastcall Connected();
        unsigned int __fastcall GetUserID(AnsiString Str);

};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;
//---------------------------------------------------------------------------
#endif
