{    Copyright (C) 2004 by Erico Mendonca                                                                   }
{   This program is free software; you can redistribute it and/or modify it under the terms of the GNU      }
{   General Public License as published by the Free Software Foundation; either version 2 of the License, or} 
{   (at your option) any later version.                                                                     }
{                                                                                                           }
{   This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even  } 
{   the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public } 
{   License for more details.                                                                               }
{                                                                                                           }
{   You should have received a copy of the GNU General Public License along with this program; if not, write} 
{   to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA            }

{ Controla a placa SpaSe PCRadio SEM FRESCURAS!                           }
{ Por Erico Mendonca <slaughter@malaconet.org>                            }
{                                                                         }
{ Historico:                                                              }
{ ==========                                                              }
{ (F) -> bugfix                                                           }
{ (+) -> novo feature                                                     }
{ (-) -> feature removido                                                 }
{                                                                         }
{ Versao 1.0-1.3 - (15-19/04/1998)                                        }
{               (*) testes/programacao inicial                            }
{                                                                         }
{ Versao 1.4  - (20/04/1998)                                              }
{               (*) primeiro release                                      }
{               (+) Suporte a multitaskers, cede timeslices agora         }
{                                                                         }
{ Versao 1.41 - (23/04/1998)                                              }
{               (F) cursor pulando na tela removido                       }
{                                                                         }
{ Versao 1.5  - (24/04/1998)                                              }
{               (+) parametros de linha de comando <OFF>, <freq>          }
{                                                                         }
{ Versao 1.6  - (16/05/1998)                                              }
{               (F) bugs das teclas de funcao                             }
{                  (V,B,C e outras teclas ativavam teclas de funcao)      }
{               (+) [Ctrl+S] Stereo/Mono toggle                           }
{               (+) [Left/Right] +/- 0.1 Mhz                              }
{               (+) [Ctrl+Left/Right] +/- 0.05 Mhz                        }
{               (+) [Ctrl+X] Extended Range (50-150Mhz)                   }
{               (F) A frequencia armazenada em settings.dat as vezes      }
{                   era ignorada ao iniciar o programa                    }
{               (F) Procurar frequencias manualmente agora encontra o     }
{                   nome da estacao nos presets                           }
{               (F) Limite de tolerancia ao procurar nos presets baixado  }
{                   para 0.01 Mhz                                         }
{               (+) Frequencias dentro do Ext. Range ligam automaticamente}
{                   o flag necessario tanto ao setar a ultima frequencia  }
{                   quanto um preset nessa faixa                          }
{                                                                         }
{ Version 2.0 - (15/08/1998)                                              }
{               (+) Nova interface em ANSI                                }
{                                                                         }
{ Version 2.1 - (12/10/1998)                                              }
{               (F) Nome da estacao cobria indicador de Ext Range         }
{               (+) Versao para OS/2!                                     }
{               (F) Numero da memoria nao era apagado no display          }
{               (F) Numero da memoria 10 agora mostrado como zero         }
{                                                                         }
{ Version 2.2 - (14/06/2001)                                              }
{               (F) Acerto de alguns problemas de timing com as funcoes   }
{                   de Treble e Bass quando compilado sob Virtual Pascal  }
{                   v2.1 build 243 no Merlin Convenience Pack 1           }
{               (F) Presets deixavam radio mudo sob VP/2 2.1 b243         }
{               (+) Texto 'press [h] for help]' acrescentado              }
{               (+) Mudancas esteticas na tela principal                  }
{               (F) Mudancas da mensagem de copyright                     }
{               (+) Possibilidade de alterar volume via linha de comando  }
{               (+) Possibilidade de fazer scan de estacoes via linha de  }
{                   comando (SCANUP e SCANDOWN)                           }
{               (+) Settings agora sao lidos/salvos ao chamar o programa  }
{                   em linha de comando                                   }
{               (+) Possibilidade de escolher presets a partir da linha   }
{                   de comando                                            }
{               (F) Preset nao aparecia corretamente caso uma frequencia  }
{                   fosse setada via linha de comando                     }

Program Radio;

{$IFDEF OS2}
Uses crt, PCR_SUPW, ScanCode, OS2Base, VPUtils;
{$ENDIF}
{$IFDEF WIN32}
Uses crt, PCR_SUPW, ScanCode, TimeTask;
{$ENDIF}
{$IFDEF DOS}
Uses crt, PCR_SUPW, ScanCode, TimeTask;
{$ENDIF}

{$I d:\vp21\work\radio\RADIOC.PAS}
type
    Settings = record
                 LastVol : Integer;
                 LastBal: Integer;
                 LastBass: Integer;
                 LastTreb: Integer;
                 LastFreq: Real;
                 AutoMute :Boolean;
               end;

    Presets = record
                 Num  : Integer;
                 Freq : Real;
                 Nome : String[20];
               end;
    {$IFDEF OS2}
    {$ENDIF}
    {$IFDEF WIN32}
    ScreenType = array [0..3999] of Byte;
    {$ENDIF}
    {$IFDEF DOS}
    ScreenType = array [0..3999] of Byte;
    {$ENDIF}

const
    version = '2.2';
    copyright = '(c) 2002 by Erico Mendonca';
    copyright2 = 'This software comes with ABSOLUTELY NO WARRANTY; This is free software, and you are welcome to redistribute it under certain conditions; See LICENSE.TXT for details.';
    email = '<slaughter@malaconet.org>';

var
{$IFDEF OS2}
    Code : Longint;
{$ENDIF}
{$IFDEF WIN32}
    Screen : ScreenType;
    Code : Longint;
{$ENDIF}
{$IFDEF DOS}
    Screen : ScreenType absolute $B800:0000;
    Code : Integer;
{$ENDIF}

    Volume, Treble, Bass, Balance :integer;
    Extended_Range : Boolean;
    ch: char;
    Level, i : byte;
    Stereo, Mute, Up, MuteExit, Encontrado, AutoMute, HelpMode : Boolean;
    Deviation : Integer;
    Frequency, _Freq : Real;
    SetFile : file of Settings;
    lastset: Settings;
    A_Presets: array [1..10] of Presets;
    currpreset: Presets;
    FPresets : file of Presets;
    _Nome, Nome: String[20];
    Y: real;
    Str,Str2,X,XX: string;


const
    MinLevel = 5;
    PCRadio_address = 432;


Function Arq_Existe (FileName: string):Boolean;
var f:file;
begin

 {$I-}
  Assign(F, FileName);
  FileMode := 0;
  Reset(F);
  Close(F);
  {$I+}
  if IOResult = 0 then Arq_Existe := true else Arq_Existe := false;

end;

{$IFDEF OS2}
{$ELSE}
Procedure HideCursor; Assembler;
Asm
  MOV   ax,$0100
  MOV   cx,$2607
  INT   $10
end;

Procedure ShowCursor; Assembler;
Asm
  MOV   ax,$0100
  MOV   cx,$0506
  INT   $10
end;
{$ENDIF}

Function UPCaseL(Var CString:String) : string;
Var I:Byte;
begin

   For I:=1 to LENGTH(CString) do
      CString[I]:=UPCase(CString[I]);

   UpCaseL:=CString;

end;


Function Get_Prg_Dir : string;
var
  Tmp : string;
begin { Get_Prg_Dir }
  Tmp := ParamStr(0);
  while (Tmp[Length(Tmp)] <> '\') and (Length(Tmp) <> 0) do
    Delete(Tmp,Length(Tmp),1);
{  if Tmp = '' then
    Tmp := Get_Cur_Dir;}
  Get_Prg_Dir := Tmp;
end;

Procedure Beep;
var i:integer;
begin

     {$IFDEF OS2}
     PlaySound (220,5);
     {$ENDIF}
     {$IFDEF WIN32}
     {$ENDIF}
     {$IFDEF DOS}
     Sound (220);
     Delay (5);
     NoSound;
     {$ENDIF}

end;

Procedure SavePresets;
begin
  rewrite (FPresets);
  A_Presets[10].Num := 0;
  for i := 1 to 10 do
     write (FPresets, A_Presets[i]);
  close (FPresets);
end;

Procedure SaveSettings;
begin
   lastset.LastVol := Volume;
   lastset.LastFreq := Frequency;
   lastset.LastBass := Bass;
   lastset.LastTreb := Treble;
   lastset.LastBal  := Balance;
   lastset.AutoMute := AutoMute;
   rewrite (SetFile);
   write (SetFile, lastset);
   close (SetFile);
end;

Procedure InitSettingsFiles;
begin
     { Inicializar arquivos de settings e presets... }

     If Arq_Existe (Get_Prg_Dir+'presets.dat') then
     begin
        Assign (FPresets, Get_Prg_Dir+'presets.dat');
        FileMode := 2;
        reset (FPresets);
      while not EOF (FPresets) do
       begin
        For i := 1 to 10 do
        begin
          read (FPresets, currpreset);
         if i = 10 then
         begin
          A_Presets[10].Num := 0;
          A_Presets[10].Nome := currpreset.Nome;
          A_Presets[10].Freq := currpreset.Freq;
         end else
         begin
          A_Presets[currpreset.Num].Num := currpreset.Num;
          A_Presets[currpreset.Num].Nome := currpreset.Nome;
          A_Presets[currpreset.Num].Freq := currpreset.Freq;
         end
        end;
      end;
     end;
      If not Arq_Existe (Get_Prg_Dir+'presets.dat') then
         begin
          Assign (FPresets, Get_Prg_Dir+'presets.dat');
          FileMode := 2;
          rewrite (FPresets);
          For i:= 1 to 10 do
          begin
              if i = 10 then currpreset.Num := 0 else
              currpreset.Num := i;
              if i = 10 then A_Presets[i].Num := 0 else
              A_Presets[i].Num := i;
              currpreset.Nome := '';
              A_Presets[i].Nome :='';
              currpreset.Freq := 87.5;
              A_Presets[i].Freq := 87.5;
              write (FPresets, currpreset);
          end;
          close (FPresets);
          reset (FPresets);

          { Coloca valores default... }
          Frequency := 87.5;
          AutoMute := True;
          Volume := 35;
          Balance := 0;
          Treble := 0;
          Bass := 0;
          SetFrequency(Frequency, AutoMute);
          SetAudio (Volume, Balance, Treble, Bass);
         end;

     If Arq_Existe (Get_Prg_Dir+'settings.dat') then
     begin
        Assign (SetFile, Get_Prg_Dir+'settings.dat');
        FileMode := 2;
        reset (SetFile);
        read (SetFile, lastset);

        If ((lastset.LastFreq < 87.5) or
            (lastset.LastFreq > 108)) then ExtendedRange:= True;

        SetFrequency (lastset.LastFreq, lastset.AutoMute);
        SetAudio (lastset.LastVol, lastset.LastBal, lastset.LastTreb, lastset.LastBass);

        Frequency := lastset.LastFreq;
        Volume    := lastset.LastVol;
        Bass      := lastset.LastBass;
        Treble    := lastset.LastTreb;
        Balance   := lastset.LastBal;
        AutoMute  := lastset.AutoMute;

     end;

      If not Arq_Existe ('settings.dat') then
         begin
         Assign (SetFile, Get_Prg_Dir+'settings.dat');
         FileMode := 2;
         rewrite (SetFile);

         lastset.LastFreq := 87.5;
         lastset.LastVol := 35;
         lastset.LastBass := 0;
         lastset.LastTreb := 0;
         lastset.LastBal := 0;
         lastset.AutoMute := True;

         write (SetFile, lastset);
         close (SetFile);
         reset (SetFile);
         end;



end;



Procedure Desenha_ANSI;
begin

{$IFDEF OS2}
      viowrtcellstr (@imagedata, 4000, 0, 0, 0);
{$ENDIF}
{$IFDEF WIN32}
     Move (ImageData,Screen,4000);
{$ENDIF}
{$IFDEF DOS}
     Move (ImageData,Screen,4000);
{$ENDIF}

end;


Procedure Desenha_Tela;
begin

        GetTuningInfo (Level, Stereo, Deviation);
        textcolor(green);

        If HelpMode then
         begin
              gotoxy (1,20);
              writeln ('[+]    Volume   [-]         [PgUp] Scan Up/Down [PgDn]      [[] Balance []]');
              writeln ('[Insert]  Bass  [Delete]    [Home]  Treble      [End]       [F1..F10] Presets');
              writeln ('[0] Mute On Exit            [Ctrl+F1..F10] Store Preset     [M] Mute');
              writeln ('[\] Toggle AutoMute         [Ctrl+S] Toggle Stereo/Mono     [Ctrl+X] Ext Range');
              writeln ('[Left] -/+ 0.1 Mhz [Right]  [Ctrl+Left] -/+ 0.05 Mhz [Ctrl+Right]');
         end
            else
             begin
               for i:=20 to 24 do
                begin
                   gotoxy (1,i);
                   clreol;
                end;
               end;

        gotoxy (20,8);
        for i:= 1 to (20-length(Nome)) do
            Nome := Nome + ' ';
        write (Nome);
        gotoxy (20,9);
        write (Frequency:0:2,' ');

        gotoxy (40,12);
        case Level of
            1 : write ('°      ');
            2 : write ('°°     ');
            3 : write ('°°±    ');
            4 : write ('°°±±   ');
            5 : write ('°°±±²  ');
            6 : write ('°°±±²² ');
            7 : write ('°°±±²²Û');
        end;
        textbackground(blue);
        gotoxy (32,16);
        case Balance of
            -8: write ('צתתתתתתתתתתתתתתתת');
            -7: write ('תצתתתתתתתתתתתתתתת');
            -6: write ('תתצתתתתתתתתתתתתתת');
            -5: write ('תתתצתתתתתתתתתתתתת');
            -4: write ('תתתתצתתתתתתתתתתתת');
            -3: write ('תתתתתצתתתתתתתתתתת');
            -2: write ('תתתתתתצתתתתתתתתתת');
            -1: write ('תתתתתתתצתתתתתתתתת');
             0: write ('תתתתתתתתצתתתתתתתת');
             1: write ('תתתתתתתתתצתתתתתתת');
             2: write ('תתתתתתתתתתצתתתתתת');
             3: write ('תתתתתתתתתתתצתתתתת');
             4: write ('תתתתתתתתתתתתצתתתת');
             5: write ('תתתתתתתתתתתתתצתתת');
             6: write ('תתתתתתתתתתתתתתצתת');
             7: write ('תתתתתתתתתתתתתתתצת');
             8: write ('תתתתתתתתתתתתתתתתצ');
            end;
        textbackground (black);
        gotoxy (48,9);
        write (Volume,' ');
        gotoxy (57,9);
        write (Balance,' ');
        gotoxy (48,10);
        write (Treble,' ');
        gotoxy (57,10);
        write (Bass,' ');

        textcolor(red);
        If Stereo then
         begin
           gotoxy (22,10);
           write (#250+'Stereo'+#250)
         end
           else
          begin
           gotoxy (22,10);
           write ('        ');
          end;

        If (Deviation <> 0) then
        begin
            gotoxy (37,9);
            write (deviation, ' Hz ');
        end
           else
             begin
                gotoxy (35,9);
                write ('       ');
             end;

        If Mute then
        begin
            gotoxy (33,10);
            write (#250+'Mute'+#250)
        end
            else
             begin
                gotoxy (33,10);
                write ('      ');
             end;

         If AutoMute then
         begin
            gotoxy(40,10);
            writeln (#250+'A'+#250)
         end
             else
              begin
                 gotoxy(40,10);
                 write ('   ');
              end;

        If ExtendedRange then
        begin
           gotoxy(46,8);
           write (#250+'Ext Range'+#250);
        end
          else
           begin
             gotoxy (46,8);
             write ('           ');
           end;


        textbackground(blue);
        textcolor (yellow);
        If MuteExit then
        begin
           gotoxy (51,15);
           write (#254);
           end
             else
              begin
                 gotoxy (51,15);
                 write (' ');
              end;
        textbackground(black);
        textcolor(lightgray);
end;

begin

     Extended_range := false;
     Init_PCradio;
     MPX_In(False);
     SetStereo(True);
     Mute := False;
     MuteExit := False;

     {le os arquivos de settings}
     InitSettingsFiles;

     If ParamStr(1) <> '' then
     begin
        X:= ParamStr(1);
        for i:= 1 to length (X) do
        begin
          XX:= XX+Upcase(X[i]);
        end;
        If XX = 'OFF' then
        begin
          LF(False);
          writeln ('Radio off.');
          Halt(0);
        end else if XX = 'SHOW' then
         begin
          writeln ('SpaSe PCRadio Control ', version, ' ', copyright, ' ', email);
	  writeln (copyright2);
          writeln;
          writeln ('Currently stored settings:');
          writeln ('Frequency: ', Frequency:0:2, ' Mhz');
          writeln ('Volume: ', Volume);
          writeln ('Balance: ', Balance);
          writeln ('Treble: ', Treble);
          writeln ('Bass: ', Bass);
          writeln ('AutoMute: ', AutoMute);
          Halt(0);
        end else if XX = 'P1' then
        begin
         LF (True);
         Frequency:=A_Presets[1].Freq;
         Volume := lastset.LastVol;
         Balance :=lastset.LastBal;
         Treble := lastset.LastTreb;
         Bass := lastset.LastBass;
         AutoMute := lastset.AutoMute;

         SetFrequency (Frequency, AutoMute);
         SetFrequency (Frequency, AutoMute); { pra garantir }
         SetAudio (Volume, Balance, Treble, Bass);
         SetAudio (Volume, Balance, Treble, Bass);

         writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
	 writeln (copyright2);
         writeln ('Frequency set to ', Frequency:0:2,' Mhz ([1] ',A_Presets[1].Nome,')');

         SaveSettings;
         halt(0);
        end else if XX = 'P2' then
        begin
         LF (True);
         Frequency:=A_Presets[2].Freq;
         Volume := lastset.LastVol;
         Balance :=lastset.LastBal;
         Treble := lastset.LastTreb;
         Bass := lastset.LastBass;
         AutoMute := lastset.AutoMute;

         SetFrequency (Frequency, AutoMute);
         SetFrequency (Frequency, AutoMute); { pra garantir }
         SetAudio (Volume, Balance, Treble, Bass);
         SetAudio (Volume, Balance, Treble, Bass);

         writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
	 writeln (copyright2);
         writeln ('Frequency set to ', Frequency:0:2,' Mhz ([2] ',A_Presets[2].Nome,')');

         SaveSettings;
         halt(0);
        end else if XX = 'P3' then
        begin
         LF (True);
         Frequency:=A_Presets[3].Freq;
         Volume := lastset.LastVol;
         Balance :=lastset.LastBal;
         Treble := lastset.LastTreb;
         Bass := lastset.LastBass;
         AutoMute := lastset.AutoMute;

         SetFrequency (Frequency, AutoMute);
         SetFrequency (Frequency, AutoMute); { pra garantir }
         SetAudio (Volume, Balance, Treble, Bass);
         SetAudio (Volume, Balance, Treble, Bass);

         writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
	 writeln (copyright2);
         writeln ('Frequency set to ', Frequency:0:2,' Mhz ([3] ',A_Presets[3].Nome,')');

         SaveSettings;
         halt(0);
        end else if XX = 'P4' then
        begin
         LF (True);
         Frequency:=A_Presets[4].Freq;
         Volume := lastset.LastVol;
         Balance :=lastset.LastBal;
         Treble := lastset.LastTreb;
         Bass := lastset.LastBass;
         AutoMute := lastset.AutoMute;

         SetFrequency (Frequency, AutoMute);
         SetFrequency (Frequency, AutoMute); { pra garantir }
         SetAudio (Volume, Balance, Treble, Bass);
         SetAudio (Volume, Balance, Treble, Bass);

         writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
	 writeln (copyright2);	 
         writeln ('Frequency set to ', Frequency:0:2,' Mhz ([4] ',A_Presets[4].Nome,')');

         SaveSettings;
         halt(0);
        end else if XX = 'P5' then
        begin
         LF (True);
         Frequency:=A_Presets[5].Freq;
         Volume := lastset.LastVol;
         Balance :=lastset.LastBal;
         Treble := lastset.LastTreb;
         Bass := lastset.LastBass;
         AutoMute := lastset.AutoMute;

         SetFrequency (Frequency, AutoMute);
         SetFrequency (Frequency, AutoMute); { pra garantir }
         SetAudio (Volume, Balance, Treble, Bass);
         SetAudio (Volume, Balance, Treble, Bass);

         writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
	 writeln (copyright2);	 
         writeln ('Frequency set to ', Frequency:0:2,' Mhz ([5] ',A_Presets[5].Nome,')');

         SaveSettings;
         halt(0);
        end else if XX = 'P6' then
        begin
         LF (True);
         Frequency:=A_Presets[6].Freq;
         Volume := lastset.LastVol;
         Balance :=lastset.LastBal;
         Treble := lastset.LastTreb;
         Bass := lastset.LastBass;
         AutoMute := lastset.AutoMute;

         SetFrequency (Frequency, AutoMute);
         SetFrequency (Frequency, AutoMute); { pra garantir }
         SetAudio (Volume, Balance, Treble, Bass);
         SetAudio (Volume, Balance, Treble, Bass);

         writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
	 writeln (copyright2);	 
         writeln ('Frequency set to ', Frequency:0:2,' Mhz ([6] ',A_Presets[6].Nome,')');

         SaveSettings;
         halt(0);
        end else if XX = 'P7' then
        begin
         LF (True);
         Frequency:=A_Presets[7].Freq;
         Volume := lastset.LastVol;
         Balance :=lastset.LastBal;
         Treble := lastset.LastTreb;
         Bass := lastset.LastBass;
         AutoMute := lastset.AutoMute;

         SetFrequency (Frequency, AutoMute);
         SetFrequency (Frequency, AutoMute); { pra garantir }
         SetAudio (Volume, Balance, Treble, Bass);
         SetAudio (Volume, Balance, Treble, Bass);

         writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
	 writeln (copyright2);	 
         writeln ('Frequency set to ', Frequency:0:2,' Mhz ([7] ',A_Presets[7].Nome,')');

         SaveSettings;
         halt(0);
        end else if XX = 'P8' then
        begin
         LF (True);
         Frequency:=A_Presets[8].Freq;
         Volume := lastset.LastVol;
         Balance :=lastset.LastBal;
         Treble := lastset.LastTreb;
         Bass := lastset.LastBass;
         AutoMute := lastset.AutoMute;

         SetFrequency (Frequency, AutoMute);
         SetFrequency (Frequency, AutoMute); { pra garantir }
         SetAudio (Volume, Balance, Treble, Bass);
         SetAudio (Volume, Balance, Treble, Bass);

         writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
	 writeln (copyright2);	 
         writeln ('Frequency set to ', Frequency:0:2,' Mhz ([8] ',A_Presets[8].Nome,')');

         SaveSettings;
         halt(0);
        end else if XX = 'P9' then
        begin
         LF (True);
         Frequency:=A_Presets[9].Freq;
         Volume := lastset.LastVol;
         Balance :=lastset.LastBal;
         Treble := lastset.LastTreb;
         Bass := lastset.LastBass;
         AutoMute := lastset.AutoMute;

         SetFrequency (Frequency, AutoMute);
         SetFrequency (Frequency, AutoMute); { pra garantir }
         SetAudio (Volume, Balance, Treble, Bass);
         SetAudio (Volume, Balance, Treble, Bass);

         writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
	 writeln (copyright2);	 
         writeln ('Frequency set to ', Frequency:0:2,' Mhz ([9] ',A_Presets[9].Nome,')');

         SaveSettings;
         halt(0);
        end else if XX = 'P10' then
        begin
         LF (True);
         Frequency:=A_Presets[10].Freq;
         Volume := lastset.LastVol;
         Balance :=lastset.LastBal;
         Treble := lastset.LastTreb;
         Bass := lastset.LastBass;
         AutoMute := lastset.AutoMute;

         SetFrequency (Frequency, AutoMute);
         SetFrequency (Frequency, AutoMute); { pra garantir }
         SetAudio (Volume, Balance, Treble, Bass);
         SetAudio (Volume, Balance, Treble, Bass);

         writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
	 writeln (copyright2);	 
         writeln ('Frequency set to ', Frequency:0:2,' Mhz ([10] ',A_Presets[10].Nome,')');

         SaveSettings;
         halt(0);

        end else if XX = 'SCANDOWN' then
          begin
            Up := false;
            Frequency := lastset.LastFreq;
            Volume := lastset.LastVol;
            Balance :=lastset.LastBal;
            Treble := lastset.LastTreb;
            Bass := lastset.LastBass;
            AutoMute := lastset.AutoMute;

            Search (Frequency, MinLevel, Up);

            SetAudio (Volume, Balance, Treble, Bass);
            SetAudio (Volume, Balance, Treble, Bass); {pra garantir}

            SetFrequency (Frequency, True); {so pra garantir}
            SetFrequency (Frequency, True); {so pra garantir}
            LF(True);
            writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
	    writeln (copyright2);	    
            write ('Scanning down... Frequency set to ',Frequency:0:2, ' Mhz.');
            For i:= 1 to 10 do
            begin
              If (round(Frequency) = round(A_Presets[i].Freq)) then
                   writeln(' ([',i,'] ',A_Presets[i].Nome,')');
            end;
            SaveSettings;
            SetAudio (Volume, Balance, Treble, Bass);
            Halt(0);
          end else If XX = 'SCANUP' then
            begin
              Up := True;
              Frequency := lastset.LastFreq;
              Volume := lastset.LastVol;
              Balance :=lastset.LastBal;
              Treble := lastset.LastTreb;
              Bass := lastset.LastBass;
              AutoMute := lastset.AutoMute;

              Search (Frequency, MinLevel, Up);

              SetAudio (Volume, Balance, Treble, Bass);
              SetAudio (Volume, Balance, Treble, Bass); {pra garantir}

              SetFrequency (Frequency, True); {so pra garantir}
              SetFrequency (Frequency, True); {so pra garantir}
              LF(True);
              writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
	      writeln (copyright2);	      
              write ('Scanning up... Frequency set to ', Frequency:0:2, ' Mhz');
              For i:= 1 to 10 do
              begin
                 If (round(Frequency) = round(A_Presets[i].Freq)) then
                             writeln(' ([',i,'] ',A_Presets[i].Nome,')');
              end;
              SaveSettings;
              SetAudio (Volume, Balance, Treble, Bass);
              Halt(0);
            end
          else
            begin
               Val (X, Y, Code);
               If (code <> 0) or not ((Y >=87.5) and (Y<=108)) and not ((round(Y)>=0) and (round(Y)<=64)) then
               begin
                  writeln ('SpaSe PCRadio Control ', version, ' ', copyright, ' ', email);
		  writeln (copyright2);
                  writeln ('Invalid frequency or parameter.');
                  writeln ('Usage: RADIO.EXE <frequency> ==> sets <frequency> and turns radio on');
                  writeln ('                 <volume>    ==> sets <volume> (0-64)');
                  writeln ('                 SCANDOWN    ==> scans to the next radio station');
                  writeln ('                 SCANUP      ==> scans to the previous radio station');
                  writeln ('                 OFF         ==> turns off the radio');
                  writeln ('                 SHOW        ==> shows the last stored settings');
                  halt(1);
               end else
                if ((Y >=87.5) and (Y<=108)) then
                begin
                  LF (True);
                  Frequency:=Y;
                  Volume := lastset.LastVol;
                  Balance :=lastset.LastBal;
                  Treble := lastset.LastTreb;
                  Bass := lastset.LastBass;
                  AutoMute := lastset.AutoMute;

                  SetFrequency (Frequency, AutoMute);
                  SetFrequency (Frequency, AutoMute); { pra garantir }
                  SetAudio (Volume, Balance, Treble, Bass);
                  SetAudio (Volume, Balance, Treble, Bass);

                  writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
		  writeln (copyright2);
                  write ('Frequency set to ', Frequency:0:2,' Mhz');
                  For i:= 1 to 10 do
                  begin
                    If (round(Frequency) = round(A_Presets[i].Freq)) then
                             writeln(' ([',i,'] ',A_Presets[i].Nome,')');
                  end;
                  SaveSettings;
                  halt(0);
                end else if ((Y >=0) and (Y<=64)) then
                begin
                  LF (True);
                  Frequency := lastset.LastFreq;
                  Balance :=lastset.LastBal;
                  Treble := lastset.LastTreb;
                  Bass := lastset.LastBass;
                  AutoMute := lastset.AutoMute;
                  Volume := round(Y);

                  SetAudio (Volume, Balance, Treble, Bass);
                  SetAudio (Volume, Balance, Treble, Bass); {pra garantir}
                  writeln ('SpaSe PCRadio Control ',version, ' ',copyright, ' ', email);
		  writeln (copyright2);
                  writeln ('Volume set to ', round(Y),'.');
                  SaveSettings;
                  halt(0);
                end

         end;
     end;

     InitSettingsFiles;

{$IFDEF OS2}
{$ELSE}
     InitMulti;
{$ENDIF}
     clrscr;
     HideCursor;
     LF(True);
     Desenha_ANSI;
     gotoxy (1,1);
     writeln ('SpaSe PCRadio Control ',version, ' ', copyright);

     For i:=1 to 10 do
     begin
       If (round(Frequency) <> round(A_Presets[i].Freq)) then
       begin
        gotoxy (32,9);
        write ('-');
       end;
     end;

       For i:= 1 to 10 do
       begin
        If (round(Frequency) = round(A_Presets[i].Freq)) then
        begin
          Nome := A_Presets[i].Nome;
          gotoxy (32,9);
          if i = 10 then write ('0') else
          write (i);
         end
       end;


     while ch <> #27 do
     begin
        Desenha_Tela;
        {$IFDEF OS2}
        Dossleep(2);
        {$ELSE}
        TimeSlice;
        {$ENDIF}
        if KeyPressed then
        begin
          ch := upcase(ReadKey);
          Beep;
          Case ch of
          EscapeKey: begin
                   clrscr;
                   ShowCursor;
                   writeln ('SpaSe PCRadio Control ', version,' ', copyright);
		   writeln (copyright2);

                   SaveSettings;
                   SavePresets;

                   If MuteExit then LF (False);
                   Exit;
                   end;
        end;

        if ch = NullKey then
        begin
         Case ord(readkey) of

            CtrlLf : begin
                      Frequency := Frequency - 0.05;
                      SetFrequency (Frequency, AutoMute);
                      Nome := '';
                      gotoxy(32,9);
                      write ('-');
                      For i:= 1 to 10 do
                      begin
                          if (Frequency <= A_Presets[i].Freq+0.01) AND
                           (Frequency >= A_Presets[i].Freq-0.01)  then
                           begin
                             Nome:= A_Presets[i].Nome;
                             gotoxy (32,9);
                             If i = 10 then write ('0') else
                             write (i);
                           end
                      end
                     end;

            CtrlRt : begin
                      Frequency := Frequency + 0.05;
                      SetFrequency (Frequency, AutoMute);
                      Nome :='';
                      gotoxy(32,9);
                      write ('-');
                      For i:= 1 to 10 do
                      begin
                          if (Frequency <= A_Presets[i].Freq+0.01) AND
                           (Frequency >= A_Presets[i].Freq-0.01)  then
                           begin
                             Nome:= A_Presets[i].Nome;
                             gotoxy(32,9);
                             If i = 10 then write ('0') else
                             write (i);
                           end
                       end
                     end;

            RtArrow: begin
                       Frequency := Frequency + 0.1;
                       SetFrequency (Frequency, AutoMute);
                       Nome :='';
                      gotoxy(32,9);
                      write ('-');
                      For i:= 1 to 10 do
                      begin
                          if (Frequency <= A_Presets[i].Freq+0.01) AND
                           (Frequency >= A_Presets[i].Freq-0.01)  then
                           begin
                             Nome:= A_Presets[i].Nome;
                             gotoxy(32,9);
                             If i = 10 then write ('0') else
                             write (i);
                           end
                      end
                     end;

            LfArrow: begin
                       Frequency := Frequency - 0.1;
                       SetFrequency (Frequency, AutoMute);
                       Nome :='';
                      gotoxy(32,9);
                      write ('-');
                      For i:= 1 to 10 do
                      begin
                          if (Frequency <= A_Presets[i].Freq+0.01) AND
                           (Frequency >= A_Presets[i].Freq-0.01)  then
                           begin
                             Nome:= A_Presets[i].Nome;
                             gotoxy(32,9);
                             If i = 10 then write ('0') else
                             write (i);
                           end
                      end
                     end;

            CtrlF1 : begin
                   gotoxy (1,19);
                   write ('Entre com o nome da estacao [1]: ');
                   Readln (_Nome);
                   gotoxy (1,19);
                   clreol;
                   If (_Nome <> '') then
                   begin
                    A_Presets[1].Num := 1;
                    Nome:= _Nome;
                    A_Presets[1].Nome := _Nome;
                    A_Presets[1].Freq := Frequency;
                    gotoxy(32,9);
                    write ('1');
                   end;
                  end;

            CtrlF2 : begin
                   gotoxy (1,19);
                   write ('Entre com o nome da estacao [2]: ');
                   Readln (_Nome);
                   gotoxy (1,19);
                   clreol;
                   If (_Nome <> '') then
                   begin
                    A_Presets[2].Num := 2;
                    Nome:= _Nome;
                    A_Presets[2].Nome := _Nome;
                    A_Presets[2].Freq := Frequency;
                    gotoxy(32,9);
                    write ('2');
                   end;
                  end;

            CtrlF3 : begin
                   gotoxy (1,19);
                   write ('Entre com o nome da estacao [3]: ');
                   Readln (_Nome);
                   gotoxy (1,19);
                   clreol;
                   If (_Nome <> '') then
                   begin
                    A_Presets[3].Num := 3;
                    Nome:= _Nome;
                    A_Presets[3].Nome := _Nome;
                    A_Presets[3].Freq := Frequency;
                    gotoxy(32,9);
                    write ('3');
                   end;
                  end;

            CtrlF4 : begin
                   gotoxy (1,19);
                   write ('Entre com o nome da estacao [4]: ');
                   Readln (_Nome);
                   gotoxy (1,19);
                   clreol;
                   If (_Nome <> '') then
                   begin
                    A_Presets[4].Num := 4;
                    Nome:= _Nome;
                    A_Presets[4].Nome := _Nome;
                    A_Presets[4].Freq := Frequency;
                    gotoxy(32,9);
                    write ('4');
                   end;
                  end;

            CtrlF5 : begin
                   gotoxy (1,19);
                   write ('Entre com o nome da estacao [5]: ');
                   Readln (_Nome);
                   gotoxy (1,19);
                   clreol;
                   If (_Nome <> '') then
                   begin
                    A_Presets[5].Num := 5;
                    Nome:= _Nome;
                    A_Presets[5].Nome := _Nome;
                    A_Presets[5].Freq := Frequency;
                    gotoxy(32,9);
                    write ('5');
                   end;
                  end;

            CtrlF6 : begin
                   gotoxy (1,19);
                   write ('Entre com o nome da estacao [6]: ');
                   Readln (_Nome);
                   gotoxy (1,19);
                   clreol;
                   If (_Nome <> '') then
                   begin
                    A_Presets[6].Num := 6;
                    Nome:= _Nome;
                    A_Presets[6].Nome := _Nome;
                    A_Presets[6].Freq := Frequency;
                    gotoxy(32,9);
                    write ('6');
                   end;
                  end;

            CtrlF7 : begin
                   gotoxy (1,19);
                   write ('Entre com o nome da estacao [7]: ');
                   Readln (_Nome);
                   gotoxy (1,19);
                   clreol;
                   If (_Nome <> '') then
                   begin
                    A_Presets[7].Num := 7;
                    Nome:= _Nome;
                    A_Presets[7].Nome := _Nome;
                    A_Presets[7].Freq := Frequency;
                    gotoxy(32,9);
                    write ('7');
                   end;
                  end;

            CtrlF8 : begin
                   gotoxy (1,19);
                   write ('Entre com o nome da estacao [8]: ');
                   Readln (_Nome);
                   gotoxy (1,19);
                   clreol;
                   If (_Nome <> '') then
                   begin
                    A_Presets[8].Num := 8;
                    Nome:= _Nome;
                    A_Presets[8].Nome := _Nome;
                    A_Presets[8].Freq := Frequency;
                    gotoxy(32,9);
                    write ('8');
                   end;
                  end;

            CtrlF9 : begin
                   gotoxy (1,19);
                   write ('Entre com o nome da estacao [9]: ');
                   Readln (_Nome);
                   gotoxy (1,19);
                   clreol;
                   If (_Nome <> '') then
                   begin
                    A_Presets[9].Num := 9;
                    Nome:= _Nome;
                    A_Presets[9].Nome := _Nome;
                    A_Presets[9].Freq := Frequency;
                    gotoxy(32,9);
                    write ('9');
                   end;
                  end;

            CtrlF10 : begin
                   gotoxy (1,19);
                   write ('Entre com o nome da estacao [10]: ');
                   Readln (_Nome);
                   gotoxy (1,19);
                   clreol;
                   If (_Nome <> '') then
                   begin
                    A_Presets[10].Num := 0;
                    Nome:= _Nome;
                    A_Presets[10].Nome := _Nome;
                    A_Presets[10].Freq := Frequency;
                    gotoxy(32,9);
                    write ('0');
                   end;
                  end;

            F1 : begin
                   Frequency := A_Presets[1].Freq;
                   Nome := A_Presets[1].Nome;
                   If ((Frequency < 87.5) or
                     (Frequency > 108)) then ExtendedRange:= True;
                   SetFrequency (Frequency, AutoMute);
                   gotoxy (32,9);
                   write ('1');
                  end;
            F2 : begin
                   Frequency := A_Presets[2].Freq;
                   Nome := A_Presets[2].Nome;
                   If ((Frequency < 87.5) or
                     (Frequency > 108)) then ExtendedRange:= True;
                   SetFrequency (Frequency, AutoMute);
                   gotoxy (32,9);
                   write ('2');
                  end;
            F3 : begin
                   Frequency := A_Presets[3].Freq;
                   Nome := A_Presets[3].Nome;
                   If ((Frequency < 87.5) or
                     (Frequency > 108)) then ExtendedRange:= True;
                   SetFrequency (Frequency, AutoMute);
                   gotoxy (32,9);
                   write ('3');
                  end;

            F4 : begin
                   Frequency := A_Presets[4].Freq;
                   Nome := A_Presets[4].Nome;
                   If ((Frequency < 87.5) or
                     (Frequency > 108)) then ExtendedRange:= True;
                   SetFrequency (Frequency, AutoMute);
                   gotoxy (32,9);
                   write ('4');
                  end;

            F5 : begin
                   Frequency := A_Presets[5].Freq;
                   Nome := A_Presets[5].Nome;
                   If ((Frequency < 87.5) or
                     (Frequency > 108)) then ExtendedRange:= True;
                   SetFrequency (Frequency, AutoMute);
                   gotoxy (32,9);
                   write ('5');
                  end;

            F6 : begin
                   Frequency := A_Presets[6].Freq;
                   Nome := A_Presets[6].Nome;
                   If ((Frequency < 87.5) or
                     (Frequency > 108)) then ExtendedRange:= True;
                   SetFrequency (Frequency, AutoMute);
                   gotoxy (32,9);
                   write ('6');
                  end;

            F7 : begin
                   Frequency := A_Presets[7].Freq;
                   Nome := A_Presets[7].Nome;
                   If ((Frequency < 87.5) or
                     (Frequency > 108)) then ExtendedRange:= True;
                   SetFrequency (Frequency, AutoMute);
                   gotoxy (32,9);
                   write ('7');
                  end;

            F8 : begin
                   Frequency := A_Presets[8].Freq;
                   Nome := A_Presets[8].Nome;
                   If ((Frequency < 87.5) or
                     (Frequency > 108)) then ExtendedRange:= True;
                   SetFrequency (Frequency, AutoMute);
                   gotoxy (32,9);
                   write ('8');
                  end;

            F9 : begin
                   Frequency := A_Presets[9].Freq;
                   Nome := A_Presets[9].Nome;
                   If ((Frequency < 87.5) or
                     (Frequency > 108)) then ExtendedRange:= True;
                   SetFrequency (Frequency, AutoMute);
                   gotoxy (32,9);
                   write ('9');
                  end;

            F10 : begin
                   Frequency := A_Presets[10].Freq;
                   Nome := A_Presets[10].Nome;
                   If ((Frequency < 87.5) or
                     (Frequency > 108)) then ExtendedRange:= True;
                   SetFrequency (Frequency, AutoMute);
                   gotoxy (32,9);
                   write ('0');
                  end;

            PgDn  : begin
                     Encontrado := false;
                     Up := false;
                     Search (Frequency, MinLevel, Up);
                     LF (True);
                      gotoxy(32,9);
                      write ('-');
                     For i:= 1 to 10 do
                     begin
                      If (Frequency = A_Presets[i].Freq) or ((Frequency <= (A_Presets[i].Freq)+0.01) and
                         (Frequency >= (A_Presets[i].Freq)-0.01)) then
                      begin
                         Nome := A_Presets[i].Nome;
                         Encontrado:= true;
                         gotoxy (32,9);
                         if i=10 then write ('0') else
                         write (i);
                      end
                       else If not Encontrado then Nome := '';
                     end;
                     Desenha_Tela;
                   end;

            PgUp : begin
                     Encontrado := false;
                     Up := true;
                     Search (Frequency, Minlevel, Up);
                     LF (True);
                      gotoxy(32,9);
                      write ('-');
                     For i:= 1 to 10 do
                     begin
                      If (Frequency = A_Presets[i].Freq) or ((Frequency <= (A_Presets[i].Freq)+0.01) and
                         (Frequency >= (A_Presets[i].Freq)-0.01)) then
                      begin
                         Nome := A_Presets[i].Nome;
                         Encontrado := true;
                         gotoxy (32,9);
                         if i=10 then write ('0') else
                         write (i);
                      end
                       else If not Encontrado then Nome := '';
                     end;
                     Desenha_Tela;
                  end;

            InsertKey : begin
                   If (Bass <= 8) and (Bass >= -8) then
                   begin
                     Bass := Bass + 1;
                     SetAudio (Volume, Balance, Treble, Bass);
                     LF(True);
                     {$IFDEF OS2}
                     DosSleep(1);
                     {$ENDIF}
                   end
                  end;

             HomeKey : begin
                   If (Treble <= 8) and (Balance >= -8) then
                   begin
                     Treble := Treble + 1;
                     SetAudio (Volume, Balance, Treble, Bass);
                     LF(True);
                     {$IFDEF OS2}
                     DosSleep(1);
                     {$ENDIF}

                   end
                  end;

             DeleteKey : begin
                   If (Bass <= 8) and (Bass >= -8) then
                   begin
                     Bass := Bass - 1;
                     SetAudio (Volume, Balance, Treble, Bass);
                     LF(True);
                     {$IFDEF OS2}
                     DosSleep(1);
                     {$ENDIF}

                   end
                  end;

             EndKey : begin
                   If (Treble <= 8) and (Treble >= -8) then
                   begin
                     Treble := Treble - 1;
                     SetAudio (Volume, Balance, Treble, Bass);
                     LF(True);
                     {$IFDEF OS2}
                     DosSleep(1);
                     {$ENDIF}

                   end
                  end;
               end;
         end;

       Case Upcase(ch) of

            'H' : begin
                  If not HelpMode then HelpMode:=True else HelpMode:=False;
                  end;

            CtrlS : begin
                      If not Stereo then Stereo:=True else Stereo:=False;
                      SetStereo(Stereo);
                    end;

            CtrlX : begin
                    If not ExtendedRange then
                    begin
                      ExtendedRange:=True;
                      end else
                        begin
                          ExtendedRange:=False;
                        end
                  end;

            '+' : begin
                   If (Volume <= 64) and (Volume >= 0) then
                   begin
                     Volume := Volume + 1;
                     SetAudio (Volume, Balance, Treble, Bass);
                   end
                  end;
            '-' : begin
                   If (Volume <= 64) and (Volume >= 0) then
                   begin
                     Volume := Volume - 1;
                     SetAudio (Volume, Balance, Treble, Bass);
                   end
                  end;

            '[' : begin
                   If (Balance <= 8) and (Balance >= -8) then
                   begin
                     Balance := Balance - 1;
                     SetAudio (Volume, Balance, Treble, Bass);
                   end
                  end;

            ']' : begin
                   If (Balance <= 8) and (Balance >= -8) then
                   begin
                     Balance := Balance + 1;
                     SetAudio (Volume, Balance, Treble, Bass);
                   end
                  end;

{            'I' : MPX_In(True);
            'i' : MPX_In(False);  Sem uso? }

            'M' : If Mute then
                  begin
                     LF (True);
                     Mute := false;
                  end
                    else
                    If not Mute then
                     begin
                       LF (False);
                       Mute := true;
                    end;


            '0' : begin
                    If not MuteExit then
                       MuteExit := true
                    else
                     begin
                       MuteExit := false;
                     end;
                  end;

             '\' : begin
                    If not AutoMute then
                       AutoMute := true
                    else
                     begin
                       AutoMute := false;
                     end;
                   end;
               end;
        end;
     end;
end.
