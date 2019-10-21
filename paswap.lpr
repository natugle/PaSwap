program paswap;

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

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, main
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.

