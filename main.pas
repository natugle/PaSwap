unit main;

{Paswap (Pascal Atomic Coin Swap) version 0.01 ALFA TEST
Copyright (c) 2019 Preben Björn Biermann Madsen
email: natugle@gmail.com
http://pascalcoin.frizen.eu/
github: https://github.com/natugle/

*** THIS IS EXPERIMENTAL SOFTWARE. Use it for educational purposes only. ***

This tool is for the Pascal Coin P2P Cryptocurrency copyright (c) 2016-2019 Albert Molina.
Some code from PascalCoin is used in Paswap.

Distributed under the MIT software license, see the accompanying file LICENSE
or visit http://www.opensource.org/licenses/mit-license.php.}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls, StdCtrls, ClipBrd,  StrUtils, USha256,
  blcksock, httpsend, UJSONFunctions, xon, xonjson, xtypes, lazbro;

{$DEFINE DEBUG}

type
  TStreamOp = Class
  public
    class Function SaveStreamToRaw(Stream: TStream) : Ansistring;
    class procedure LoadStreamFromRaw(Stream: TStream; const raw : Ansistring);
  End;

  TInfoType = (info,call,response,error);

type
  IniData = Record
     RcpServer: String[24];
     SenderAcc: String[12];
  end;


  { TForm1 }

  TForm1 = class(TForm)
    btAccountCheck: TButton;
    btMakeSecret: TButton;
    btLockAcc: TButton;
    btDoSwap: TButton;
    btExit: TButton;
    btCopySecret: TButton;
    btCopyHash: TButton;
    btPasteSecret: TButton;
    btUnlockAcc: TButton;
    edAccountCheck: TEdit;
    edUnlockAcc: TEdit;
    edSendAcc: TEdit;
    edSwapAcn: TEdit;
    edSecretHex: TEdit;
    edSwapAcc: TEdit;
    edCounterAcc: TEdit;
    edLockUntil: TEdit;
    edSecret: TEdit;
    edHashSecret: TEdit;
    edSwapAmount: TEdit;
    edServer: TEdit;
    Image1: TImage;
    Label1: TLabel;
    lbUnlockAcc: TLabel;
    lbAccountCheck: TLabel;
    lbSendAcc: TLabel;
    lbSwapAcn: TLabel;
    lbSecretHex: TLabel;
    lbLockUntil: TLabel;
    lbHashSecret: TLabel;
    lbSecret: TLabel;
    lbSwapAmount: TLabel;
    lbCounteAcc: TLabel;
    lbSwapAcc: TLabel;
    lbServer: TLabel;
    mmDisp: TMemo;
    mmInfo: TMemo;
    mmHelp: TMemo;
    mmAbout: TMemo;
    PageControl: TPageControl;
    pnMarket: TPanel;
    pnTop: TPanel;
    StatusBar1: TStatusBar;
    tsMarket: TTabSheet;
    tsLog: TTabSheet;
    tsUnlockAcc: TTabSheet;
    tsHelp: TTabSheet;
    tsAbout: TTabSheet;
    tsCheckAcc: TTabSheet;
    tsDoSwap: TTabSheet;
    tsLockAcc: TTabSheet;
    procedure btAccountCheckClick(Sender: TObject);
    procedure btCopyHashClick(Sender: TObject);
    procedure btCopySecretClick(Sender: TObject);
    procedure btDoSwapClick(Sender: TObject);
    procedure btExitClick(Sender: TObject);
    procedure btMakeSecretClick(Sender: TObject);
    procedure btLockAccClick(Sender: TObject);
    procedure btPasteSecretClick(Sender: TObject);
    procedure btUnlockAccClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tsMarketShow(Sender: TObject);
  private
    parser: TJSONParser;
    FBro : TLazbro;
    procedure Display(Str:string);
    procedure Clr();
    function IsValidInt(str:string): Boolean;
    function CheckAndTrimAcc(AccNum: string): string;
    function Sha256HexStrToHexStr(HexSt: String): AnsiString;    procedure RandomSecret();
    procedure ShowCallInfo(infoType: TInfoType; value: String);
    function DecodeJSONResult(jsonString: String; out jsonResult: TPCJSONObject): Boolean;
    procedure UpdateLastCallResult(jsonResult: TPCJSONObject);
    procedure DumpData(X: XVar; const APrefix: string);
    procedure DoSendJSON(json: TPCJSONObject);
  public

  end;

Const
  CT_TIntoType_Str : Array[TInfoType] of String = ('info','call','response','error');
var
  Form1: TForm1;

implementation

{$R *.lfm}

class function TStreamOp.SaveStreamToRaw(Stream: TStream): Ansistring;
begin
  SetLength(Result,Stream.Size);
  Stream.Position:=0;
  Stream.ReadBuffer(Result[1],Stream.Size);
end;

class procedure TStreamOp.LoadStreamFromRaw(Stream: TStream; const raw: Ansistring);
begin
  Stream.WriteBuffer(raw[1],Length(raw));
end;

{ TForm1 }

procedure TForm1.Display(Str:string);
begin
{$IFDEF DEBUG}
  mmDisp.Lines.Add(Str);
  mmDisp.SelStart := length(mmDisp.Text);
{$ENDIF}
end;
procedure TForm1.Clr();
begin
  mmDisp.Clear;
end;
function TForm1.IsValidInt(str:string): Boolean;
begin
  Result := True;
  Try
    StrToInt64(str);
  except
    On E : EConvertError do Result := false;
  end;
end;

function TForm1.CheckAndTrimAcc(AccNum: string): string;
var
  i : integer;
  a, c : string;
begin
  result := ''; a := ''; c := '';
  try
  i := Pos('-', AccNum);
  if i > 0 then
  begin
     a := copy(AccNum, 1, i-1);
     c := copy(AccNum, i + 1, 2);
  end
  else a := trim(AccNum);

  if IsValidInt(a) then i := StrToInt(a)
  else exit;
  if ((C<>'') and (StrToInt(c) = ((i * 101) MOD 89)+10) or (c='')) then result := a;
  except
    Statusbar1.Panels[1].text := 'Error - Invalid Account';
  end;
end;

function TForm1.Sha256HexStrToHexStr(HexSt: String): AnsiString;
var
  l, i: integer;
  s: Ansistring;
begin
  result := '';
  s:= '';
  l :=  length(HexSt) mod 2;
  if l = 0 then
    l:=length(HexSt) div 2
  else exit;

  try
    for i:=0 to l-1 do
      s:= s + Chr(Hex2Dec(MidStr(HexSt, i*2+1, 2)));
  except
      exit;
  end;

  result := DelSpace(Sha256toStr(CalcSha256(s)));
end;

procedure TForm1.RandomSecret();
var
  s: AnsiString;
  i: integer;
begin
  s := '';
  for i := 1 to 32 do
    s := s + HexStr(Random(256),2);
  edSecret.Text := s;
  edHashSecret.Text := Sha256HexStrToHexStr(s);
end;

procedure TForm1.tsMarketShow(Sender: TObject);
var
  HTTP : THTTPSend;
begin
  HTTP := THTTPSend.Create;
  try
    if not HTTP.HTTPMethod('GET', 'http://exchange.frizen.eu/exch/') then
      begin
        {$IFDEF DEBUG}
          Display('ERROR');
          Display(IntToStr(Http.Resultcode));
        {$ENDIF}
      end
    else
      begin
        {$IFDEF DEBUG}
          Display(IntToStr(Http.Resultcode) + ' ' + Http.Resultstring);
          Display('');
          Display(Http.headers.text);
          Display('');
        {$ENDIF}
        FBro.loadfromstream(Http.Document,'');
     end;
  finally
    HTTP.Free;
  end;
end;

procedure TForm1.btAccountCheckClick(Sender: TObject);
Var
  s: string;
  obj : TPCJSONObject;
  iRow : Integer;
  decJSON : TPCJSONData;
begin
  s:='';
  s := checkAndTrimAcc(edAccountCheck.Text);
  if (s = '') then
  begin
    StatusBar1.Panels[1].Text := 'Error: Indvalid Acount Number';
    Exit;
  end;
  mmInfo.Clear;
  obj := TPCJSONObject.Create;
  try
    obj.GetAsVariant('jsonrpc').Value:='2.0';
    obj.GetAsVariant('id').Value:=100;
    obj.GetAsVariant('method').Value:='getaccount';
    obj.GetAsObject('params').GetAsVariant('account').Value:= StrToInt(s);
    //
    DoSendJSON(obj);
  finally
    obj.Free;
  end;
end;

procedure TForm1.btCopySecretClick(Sender: TObject);
begin
  Clipboard.AsText := Trim(edSecret.Text);
end;

procedure TForm1.btCopyHashClick(Sender: TObject);
begin
  Clipboard.AsText := Trim(edHashSecret.Text);
end;

procedure TForm1.btPasteSecretClick(Sender: TObject);
begin
  edSecretHex.Text := Trim(ClipBoard.AsText);
end;

procedure TForm1.btUnlockAccClick(Sender: TObject);
Var
  a: string;
  obj : TPCJSONObject;
  iRow : Integer;
  decJSON : TPCJSONData;
begin
  if (edUnlockAcc.Text <> '') then
  begin
    a := checkAndTrimAcc(edUnlockAcc.Text);
    if (a = '') then
    begin
      StatusBar1.Panels[1].Text := 'Error: Not Valid Acount Number';
      Exit;
    end;
    obj := TPCJSONObject.Create;
     try
       obj.GetAsVariant('jsonrpc').Value:='2.0';
       obj.GetAsVariant('id').Value:=100;
       obj.GetAsVariant('method').Value:='delistaccountforsale';
       obj.GetAsObject('params').GetAsVariant('account_target').Value:= StrToInt(a);
       obj.GetAsObject('params').GetAsVariant('account_signer').Value:= StrToInt(a);
       //
       DoSendJSON(obj);
     finally
       obj.Free;
     end;
  end
  else ShowCallInfo(error, 'Account # Missing!');
end;

procedure TForm1.btDoSwapClick(Sender: TObject);
Var
  a, s: string;
  obj : TPCJSONObject;
  iRow : Integer;
  decJSON : TPCJSONData;
begin
  if ((edSendAcc.Text <> '') and (edSwapAcn.Text <> '') and (edSecretHex.Text <> '')) then
  begin
    s := checkAndTrimAcc(edSendAcc.Text);
    a := checkAndTrimAcc(edSwapAcn.Text);
    if (s = '') or (a = '') then
    begin
      StatusBar1.Panels[1].Text := 'Error: Not Valid Acount Number';
      Exit;
    end;

    obj := TPCJSONObject.Create;
     try
       obj.GetAsVariant('jsonrpc').Value:='2.0';
       obj.GetAsVariant('id').Value:=100;
       obj.GetAsVariant('method').Value:='sendto';
       obj.GetAsObject('params').GetAsVariant('sender').Value:= StrToInt(s);
       obj.GetAsObject('params').GetAsVariant('target').Value:= StrToInt(a);
       obj.GetAsObject('params').GetAsVariant('amount').Value:= StrToFloat('0.0001');
       obj.GetAsObject('params').GetAsVariant('payload').Value:= Trim(edSecretHex.Text);
       obj.GetAsObject('params').GetAsVariant('payload_method').Value:= 'none';
       //
       DoSendJSON(obj);
     finally
       obj.Free;
     end;
   end
   else ShowCallInfo(error, 'Input Missing!');
end;

procedure TForm1.btExitClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.btMakeSecretClick(Sender: TObject);
begin
  RandomSecret();
end;

procedure TForm1.btLockAccClick(Sender: TObject);
Var
  s,c: string;
  obj : TPCJSONObject;
  iRow : Integer;
  decJSON : TPCJSONData;
  f: TReplaceFlags;
begin
  if ((edSwapAcc.Text <> '') and (edCounterAcc.Text <> '') and (edSwapAmount.Text <> '')
    and (edHashSecret.Text <> '') and (edLockUntil.Text <> '')) then
  begin
   s := checkAndTrimAcc(edSwapAcc.Text);
   c := checkAndTrimAcc(edCounterAcc.Text);
  if (s = '') or (c='') then
  begin
    StatusBar1.Panels[1].Text := 'Error: Not Valid Acount Number';
    Exit;
  end;

 if (Pos(',',edSwapAmount.Text) > 0) then
   edSwapAmount.Text := StringReplace(edSwapAmount.Text,',','.', []);

    obj := TPCJSONObject.Create;
    try
      obj.GetAsVariant('jsonrpc').Value:='2.0';
      obj.GetAsVariant('id').Value:=100;
      obj.GetAsVariant('method').Value:='listaccountforsale';
      obj.GetAsObject('params').GetAsVariant('type').Value:= 'atomic_coin_swap';
      obj.GetAsObject('params').GetAsVariant('account_target').Value:= StrToInt(s);
      obj.GetAsObject('params').GetAsVariant('account_signer').Value:= StrToInt(s);
      obj.GetAsObject('params').GetAsVariant('seller_account').Value:= StrToInt(c);
      obj.GetAsObject('params').GetAsVariant('price').Value:= StrToFloat(edSwapAmount.Text);
      obj.GetAsObject('params').GetAsVariant('locked_until_block').Value:= StrToInt(edLockUntil.Text);
      obj.GetAsObject('params').GetAsVariant('enc_hash_lock').Value:= edHashSecret.Text;
      //
      DoSendJSON(obj);
    finally
      obj.Free;
    end;
  end
  else ShowCallInfo(error, 'Input Missing!');
end;

procedure TForm1.ShowCallInfo(infoType: TInfoType; value: String);
begin
  StatusBar1.Panels[0].Text:= Format('%s [%s] %s',[FormatDateTime('hh:nn:ss.zzz',Now),CT_TIntoType_Str[infoType],value]);
end;

function TForm1.DecodeJSONResult(jsonString: String; out jsonResult: TPCJSONObject): Boolean;
Var jsd : TPCJSONData;
begin
  jsonResult := Nil;
  Result := false;
  If (jsonString='') then Exit;
  jsd := TPCJSONData.ParseJSONValue(jsonString);
  Try
    if jsd is TPCJSONObject then jsonResult := jsd as TPCJSONObject;
  finally
    if not Assigned(jsonResult) then begin
      jsd.Free;
      Result := False;
    end else Result := True;
  end;
end;

procedure TForm1.UpdateLastCallResult(jsonResult: TPCJSONObject);
var
  s: string;
begin
  If Assigned(jsonResult) then begin
    if jsonResult.IndexOfName('result')>=0 then begin
      // Has a valid result:
      StatusBar1.Panels[1].Text:='OK'; //* Format('%s OK',[FormatDateTime('hh:nn:ss.zzz',Now)]);
      s := jsonResult.ToJSON(False);
      parser.reset;
      if parser.parse(s) < 0 then exit;
      Clr();;
      DumpData(Parser.XON, '');
    end else begin
      // Is an error
      StatusBar1.Panels[1].Text := Format('ERROR %d',[jsonResult.GetAsObject('error').AsInteger('code',0)]);  //* Format('%s ERROR %d',[FormatDateTime('hh:nn:ss.zzz',Now),jsonResult.GetAsObject('error').AsInteger('code',0)]);
      s := jsonResult.ToJSON(False);
      parser.reset;
      if parser.parse(s) < 0 then exit;
      Clr();;
      DumpData(Parser.XON, '');
    end;
  end else begin
    StatusBar1.Panels[1].Text:='';
    Clr();;
  end;
end;

procedure TForm1.DumpData(X: XVar; const APrefix: string);
var
  NodeTxt: String;
  Prefix: String;
  C: integer;
begin
  NodeTxt:= APrefix;
  if not(X.isContainer) then NodeTxt:=NodeTxt+Format(':%s',[X.AsString]); // variables

  {$IFDEF DEBUG}
    Display(NodeTxt);
  {$ENDIF}

  if pageControl.ActivePage = tsCheckAcc then
  begin
    if ((Pos('_swap_',NodeTxt)>0) or (Pos('_secret',NodeTxt)>0) or (Pos('locked_',NodeTxt)>0)) then
      mmInfo.Lines.Add(NodeTxt);
  end;

  if X.isContainer then
    for c:=0 to X.Count-1 do
    begin
      case X.VarType of

      xtList: with X do
               begin
                    Prefix:=Keys[C].AsString;
                    DumpData(Vars[C], PreFix);
               end;
      xtArray: DumpData(X[c],'-------');   // separator
    end
   end
end;

procedure TForm1.DoSendJSON(json: TPCJSONObject);
  function DoHttpPostBinary(const URL: string; const Data: TStream): Boolean;
  var
    HTTP: THTTPSend;
  begin
    HTTP := THTTPSend.Create;
    try
      HTTP.Protocol:='1.1';
      HTTP.Document.CopyFrom(Data, 0);
      HTTP.MimeType := 'Application/octet-stream';
      Result := HTTP.HTTPMethod('POST', URL);
      Data.Size := 0;
      if Result then
      begin
        Data.Seek(0, soFromBeginning);
        Data.CopyFrom(HTTP.Document, 0);
      end;
    finally
      HTTP.Free;
    end;
  end;
Var
  ms : TMemoryStream;
  s : String;
  jsonResult : TPCJSONObject;
begin
  ShowCallInfo(call,json.ToJSON(false));
  ms := TMemoryStream.Create;
  Try
    ms.Size := 0;
    TStreamOp.LoadStreamFromRaw(ms,json.ToJSON(False));
    If Not DoHttpPostBinary(edServer.Text,ms) then ShowCallInfo(error,'no valid response from '+edServer.Text);
    s := TStreamOp.SaveStreamToRaw(ms);
    ShowCallInfo(response,s);
    if DecodeJSONResult(s,jsonResult) then begin
      Try
        UpdateLastCallResult(jsonResult);
      finally
        jsonResult.Free;
      end;
    end else begin
      ShowCallInfo(error,'Invalid JSON response');
      UpdateLastCallResult(Nil);
    end;
  finally
    ms.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Ini: IniData;
  f: file of IniData;
begin
  Randomize;
  parser:= TJSONParser.Create;
  pageControl.ActivePage:=tsMarket;
  {$I-}
  if FileExists('paswap.ini') then
  begin
    try
      Assignfile(f,'paswap.ini');
      Reset(f);
      Read(f, Ini);
      edServer.Text := Ini.RcpServer;
      edSendAcc.Text := Ini.SenderAcc;
    finally
      closefile(f);
    end;
  end;
  {$I+}
  FBro := TLazbro.Create(Self);
  FBro.Align := alClient;
  FBro.Parent := pnMarket;
end;

procedure TForm1.FormDestroy(Sender: TObject);
var
  Ini: IniData;
  f: file of IniData;
begin
  FreeAndNil(parser);
  {$I-}
  try
    Assignfile(f,'paswap.ini');
    Rewrite(f);
    Ini.RcpServer := edServer.Text;
    Ini.SenderAcc := edSendAcc.Text;
    Write(f,Ini);
  finally
    Closefile(f);
  end;
  {$I+}
  FreeAndNil(FBro);
end;

end.

