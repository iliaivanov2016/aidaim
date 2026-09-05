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
#include "MsgTypes.hpp"
#include "MsgLinux.hpp"
#include "MsgComBase.hpp"
#include "MsgServer.hpp"
#include <ComCtrls.hpp>
#include <Dialogs.hpp>
//---------------------------------------------------------------------------
class TForm1 : public TForm
{
__published:	// IDE-managed Components
        TGroupBox *gbSendClient;
        TLabel *Label1;
        TLabel *label3;
        TLabel *FileSize;
        TLabel *llabel4;
        TLabel *Speed;
        TLabel *SendPercent;
        TEdit *Blocks;
        TEdit *BlockSize;
        TButton *btnSend;
        TRadioButton *rbDirectly;
        TRadioButton *rbThruServer;
        TProgressBar *ProgressBar1;
        TButton *btnConnectDirectly;
        TButton *btnConnect1;
        TButton *btnDisconnect1;
        TButton *btnDiconnectDirectly;
        TEdit *FileName;
        TButton *btnBrowse;
        TGroupBox *gbRecvClient;
        TLabel *lbFileName;
        TLabel *lbFileSize;
        TLabel *lbBlocks;
        TLabel *lbBlockSize;
        TLabel *lbRecvBytes;
        TLabel *lbSpeed;
        TLabel *RecvPercent;
        TLabel *lbDirectly;
        TLabel *lbBlockNo;
        TButton *btnAllowRecv;
        TButton *btnConnect2;
        TButton *btnDisconnect2;
        TButton *btnAllowDirect;
        TProgressBar *ProgressBar2;
        TButton *btnForbidRecv;
        TButton *btnForbidDirect;
        TButton *btnReceiveFile;
        TButton *btnSaveFile;
        TGroupBox *gbServer;
        TButton *btnStart;
        TButton *btnStop;
        TButton *btnAllowFiles;
        TButton *btnForbidFiles;
        TOpenDialog *OpenDialog1;
        TMsgServer *MsgServer1;
        TMsgClient *MsgClient1;
        TMsgClient *MsgClient2;
        void __fastcall FormCreate(TObject *Sender);
        void __fastcall MsgClient1SendFile(const DWORD ToUserID,
          const DWORD FileID, const AnsiString FileName, Int64 FullSize,
          int BlockSize, int BlockNo, int Blocks);
        void __fastcall MsgClient2ReceiveFile(const DWORD FromUserID,
          const DWORD FileID, const TDateTime SendingDate,
          const TDateTime DeliveryDate, const AnsiString FileName,
          Int64 FullSize, int BlockSize, int BlockNo, int Blocks,
          bool Directly);
        void __fastcall btnBrowseClick(TObject *Sender);
        void __fastcall btnConnect1Click(TObject *Sender);
        void __fastcall btnConnectDirectlyClick(TObject *Sender);
        void __fastcall btnDisconnect1Click(TObject *Sender);
        void __fastcall btnDiconnectDirectlyClick(TObject *Sender);
        void __fastcall btnSendClick(TObject *Sender);
        void __fastcall btnAllowFilesClick(TObject *Sender);
        void __fastcall btnForbidFilesClick(TObject *Sender);
        void __fastcall btnAllowRecvClick(TObject *Sender);
        void __fastcall btnForbidRecvClick(TObject *Sender);
        void __fastcall btnConnect2Click(TObject *Sender);
        void __fastcall btnAllowDirectClick(TObject *Sender);
        void __fastcall btnDisconnect2Click(TObject *Sender);
        void __fastcall btnForbidDirectClick(TObject *Sender);
        void __fastcall btnReceiveFileClick(TObject *Sender);
        void __fastcall btnStartClick(TObject *Sender);
        void __fastcall btnStopClick(TObject *Sender);
private:	// User declarations
public:		// User declarations
        __fastcall TForm1(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern PACKAGE TForm1 *Form1;

int  SendStartTime;
unsigned int aaFileID;
AnsiString aaFileName;
TDateTime StartDate;

//---------------------------------------------------------------------------
#endif
