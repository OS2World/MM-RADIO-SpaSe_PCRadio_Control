{
   Note: I have no idea if this unit still has any restrictions on 
   distribution. I originally downloaded it from SpaSe's website, and 
   it was a free download at the time. I make quite a lot of changes 
   in it so it could run under Virtual Pascal and be compiled under
   DOS, OS/2 and Win32.
   
   -- Erico Mendonca (Jul 30th 2004)
}
UNIT PCR_SUPW;
{ PCRadio support unit to implement in Turbo Pascal programs           }
{ Rename PCR_SUP.TP4 to PCR_SUP.TPU for Turbo Pascal 4.0               }
{ Rename PCR_SUP.T55 to PCR_SUP.TPU for Turbo Pascal 5.5               }
{ Distribution in compiled form is free.               Date: 25 APR 90 }

{$UNDEF TESTUNIT}

INTERFACE

USES CRT{, Winprocs}
     {$IFDEF TESTUNIT}
     ,Busio;
     {$ELSE}
     ;
     {$ENDIF}

VAR  PCRadio_Address : Integer;  { hardware PCRadio card address       }
     ExtendedRange   : Boolean;  { FALSE --> 87.50 .. 108.00 MHz       }
                                 { TRUE  --> 80.00 .. 120.00 MHz       }
     { in ExtendedRange the frequency synthesizer is capable of        }
     { generating the correct values. However the performance of       }
     { the radio is in this case determined by the FM-Tuner and the    }
     { supply voltage. So propper performance is at PROGRAMMERS RISK.  }
     { Only the non-extended range is guaranteed !!!                   }


Procedure Init_PCradio;
{ call this procedure at the very beginning of your program after      }
{ setting the global variable 'PCRadio_Address' to the correct value.  }
{ If this variable is NOT set at the beginning of the program a search }
{ will be made for the hardware address.                               }

Procedure SetAudio( Var Volume,
                        Balance,
                        Treble,
                        Bass      : Integer);
{ controls the individual audio settings in the ranges:                }
{         0 <=  Volume   <= 63                                         }
{        -8 <=  Balance  <=  8                                         }
{        -4 <=  Treble   <=  4                                         }
{        -4 <=  Bass     <=  4                                         }
{ values are forced into the correct range, when they are not at entry }

Procedure LF(Mode : Boolean);
{ switches sound on/off; does not affect volume level                  }
{        Mode = TRUE    --> Sound on                                   }
{        Mode = FALSE   --> No sound                                   }

Procedure SetStereo(Stereo : Boolean);
{ controls MONO / STEREO switch                                        }
{        Stereo = TRUE   --> Stereo reproduction                       }
{        Stereo = FALSE  --> Mono reproduction                         }

Procedure MPX_In(MPX_Mode : Boolean);
{ source select for the stereodecoder.                                 }
{        MPX_Mode = TRUE  --> deselect RF device (external MPX input)  }
{        MPX_Mode = FALSE --> select RF device                         }

Procedure SetFrequency(Var Frequency : Real; Current : Boolean);
{ When EXTENDEDRANGE is made FALSE (default) the frequency is forced   }
{ into the correct range if it is not at entry, otherwise it remains   }
{ untouched (within reason) and it the programmers responsability to   }
{ control the range.                                                   }
{ smallest tuning step = 0.01, which equals to a resolution of 10 kHz  }
{ when CURRENT is made TRUE, high chargepump current is used (default) }

Procedure GetTuningInfo( Var Level     : Byte;
                         Var Stereo    : Boolean;
                         Var Deviation : Integer);
{ read the current tuning status:                                      }
{      0 <= Level <= 7    --> Signal level                             }
{      Stereo = TRUE      --> Stereo reception                         }
{      Stereo = FALSE     --> Mono reception                           }
{      -10 <= Deviation <= +10  Deviation from optimum tuning position }
{ tuning is correct if deviation is in the range -2 .. +2              }
{ deviation resolution is appr. 13 kHz                                 }

Procedure Search(Var Frequency : Real;
                     MinLevel  : Byte;
                     Up        : Boolean);
{ search next station: UP = TRUE   --> next higher station             }
{                      UP = FALSE  --> next lower station              }
{ search is performed on a grid of 100 kHz. The width of the tuning    }
{ window is approx. +/- 26 kHz.                                        }
{ the minimum signal level should be at least equal to MINLEVEL        }
{ On entry of the procedure, FREQUENCY is the starting point for the   }
{ search action. On exit FREQUENCY equals the new frequency.           }
{ the search action can be aborted by a keypress.                      }
{ SEARCH also depends on EXTENDEDRANGE. When set to TRUE, SEARCH may   }
{ lead to unpredictable results !!!                                    }

{Procedure Delay(Msecs : Longint); }

IMPLEMENTATION

CONST   _On                = TRUE;
        Off                = FALSE;

TYPE    I2CData            = Array[1..8] of Byte;

VAR     Musti, Symo, Sofac : I2CData;

{Procedure Delay(Msecs : Longint);
var tmp :longint;
begin
  tmp:=GetTickcount;
  Repeat
  Until GetTickcount >= tmp + msecs;
end;} {delay}


Procedure IIC(    NrOfBytes     : Byte;
                      Swap      : Boolean;
                  Var Data      : I2CData;
                  Var Error     : Boolean);
Const AddressByte = 1;
Var   ByteNr      : Byte;
      WriteMode   : Boolean;
      AddByte     : Byte;

  Procedure Loop;
  Var I : LongInt;
  Begin
    For I := 1 to 100 do;
  End;  {loop}

  Procedure IICStart;
  Begin
                                                                      Loop;
    {$IFDEF TESTUNIT}
    PortW(PCRadio_Address,3);  Loop;   PortW(PCRadio_Address,1);  Loop;
    PortW(PCRadio_Address,0);  Loop;
    {$ELSE}
    Port[PCRadio_Address] := 3;  Loop;   Port[PCRadio_Address] := 1;  Loop;
    Port[PCRadio_Address] := 0;  Loop;
    {$ENDIF}
  End;  {start}

  Procedure IICStop;
  Begin
    {$IFDEF TESTUNIT}
    PortW(PCRadio_Address,0);  Loop;   PortW(PCRadio_Address,3);  Loop;
    PortW(PCRadio_Address,0);  Loop;   PortW(PCRadio_Address,1);  Loop;
    PortW(PCRadio_Address,3);  Loop;   PortW(PCRadio_Address,0);  Loop;
    {$ELSE}
    Port[PCRadio_Address] := 0;  Loop;   Port[PCRadio_Address] := 3;  Loop;
    Port[PCRadio_Address] := 0;  Loop;   Port[PCRadio_Address] := 1;  Loop;
    Port[PCRadio_Address] := 3;  Loop;   Port[PCRadio_Address] := 0;  Loop;
    {$ENDIF}
  End;  {stop}

  Procedure SendByte(ByteNr : Byte);
  Var BitNr       : Byte;
      CurrentByte : Integer;
  Begin
    CurrentByte := Data[ByteNr];
    For BitNr := 1 to 8 do
      begin
        If ((CurrentByte AND 128) = 128)
          {$IFDEF TESTUNIT}
          then begin PortW(PCRadio_Address,2);        Loop;
                     PortW(PCRadio_Address,3);        Loop;
                     PortW(PCRadio_Address,2); end
          else begin PortW(PCRadio_Address,0);        Loop;
                     PortW(PCRadio_Address,1);        Loop;
                     PortW(PCRadio_Address,0); end;
          {$ELSE}
          then begin Port[PCRadio_Address] := 2;        Loop;
                     Port[PCRadio_Address] := 3;        Loop;
                     Port[PCRadio_Address] := 2; end
          else begin Port[PCRadio_Address] := 0;        Loop;
                     Port[PCRadio_Address] := 1;        Loop;
                     Port[PCRadio_Address] := 0; end;
          {$ENDIF}
        CurrentByte := CurrentByte SHL 1;               Loop;
      end;
  End;  {sendbyte}

  Procedure ReadAcknowledge;
  Var Dummy : Byte;
  Begin
    {$IFDEF TESTUNIT}
    PortW(PCRadio_Address,0);  Loop;   PortW(PCRadio_Address,3);  Loop;
    Dummy := InPort(PCRadio_Address);                                   Loop;
    Error := (Dummy AND 4) = 4;
    PortW(PCRadio_Address,0);  Loop;   PortW(PCRadio_Address,2);  Loop;
    {$ELSE}
    Port[PCRadio_Address] := 0;  Loop;   Port[PCRadio_Address] := 3;  Loop;
    Dummy := Port[PCRadio_Address];                                   Loop;
    Error := (Dummy AND 4) = 4;
    Port[PCRadio_Address] := 0;  Loop;   Port[PCRadio_Address] := 2;  Loop;
    {$ENDIF}
  End;  {readacknowledge}

  Procedure SendAcknowledge;
  Begin
    {$IFDEF TESTUNIT}
    PortW(PCRadio_Address,0);  Loop;   PortW(PCRadio_Address,1);  Loop;
    PortW(PCRadio_Address,0);  Loop;   PortW(PCRadio_Address,2);  Loop;
    {$ELSE}
    Port[PCRadio_Address] := 0;  Loop;   Port[PCRadio_Address] := 1;  Loop;
    Port[PCRadio_Address] := 0;  Loop;   Port[PCRadio_Address] := 2;  Loop;
    {$ENDIF}
  End;  {sendacknowledge}

  Procedure ReadByte(ByteNr : Byte);
  Var BitNr : Byte;
  Begin
    Data[ByteNr] := 0;
    For BitNr := 1 to 7 do
    {$IFDEF TESTUNIT}
      begin PortW(PCRadio_Address,3);                 Loop;
            If ((InPort(PCRadio_Address) AND 4) = 4) then
              Data[ByteNr] := Data[ByteNr] + AddByte;
            If Swap then Data[ByteNr] := Data[ByteNr] SHR 1
                    else Data[ByteNr] := Data[ByteNr] SHL 1;
            Loop;     PortW(PCRadio_Address,2);       Loop;
      end;
    PortW(PCRadio_Address,3);                         Loop;
    If ((InPort(PCRadio_Address) AND 4) = 4)
      then Data[ByteNr] := Data[ByteNr] + AddByte;
    Loop;    PortW(PCRadio_Address,2);                Loop;
    {$ELSE}
      begin Port[PCRadio_Address] := 3;                 Loop;
            If ((Port[PCRadio_Address] AND 4) = 4) then
              Data[ByteNr] := Data[ByteNr] + AddByte;
            If Swap then Data[ByteNr] := Data[ByteNr] SHR 1
                    else Data[ByteNr] := Data[ByteNr] SHL 1;
            Loop;     Port[PCRadio_Address] := 2;       Loop;
      end;
    Port[PCRadio_Address] := 3;                         Loop;
    If ((Port[PCRadio_Address] AND 4) = 4)
      then Data[ByteNr] := Data[ByteNr] + AddByte;
    Loop;    Port[PCRadio_Address] := 2;                Loop;
    {$ENDIF}
  End;  {readbyte}

Begin                    { IIC }
  If PCRadio_Address = 0 then Exit;
  WriteMode := ((Data[AddressByte] AND 1) = 0);
  If Swap then AddByte := 128 else AddByte := 1;
  IICStart;     SendByte(AddressByte);       ReadAcknowledge;
  If (NrOfBytes > 1) then
    If WriteMode
      then begin If (NrOfBytes > 2)
                   then For ByteNr := 2 to (NrOfBytes - 1) do
                          begin SendByte(ByteNr);
                                ReadAcknowledge;
                          end;
                 SendByte(NrOfBytes);
           end
      else begin If (NrOfBytes > 2)
                   then For ByteNr := 2 to (NrOfBytes - 1) do
                          begin ReadByte(ByteNr);
                                SendAcknowledge;
                          end;
                 ReadByte(NrOfBytes);
           end;
  IICStop;
End;  {iic}

Procedure LF(Mode : Boolean);
Var Error : Boolean;
Begin
  Sofac[2] := $05;  If Mode then Sofac[3] := $00 else Sofac[3] := $80;
  IIC(3,Off,Sofac,Error);
End;  {lf_off}

Procedure SetAudio( Var Volume,
                        Balance,
                        Treble,
                        Bass      : Integer);
Var Error : Boolean;
    Dummy : Integer;
Begin
  If Volume < 0 then Volume := 0; If Volume > 63 then Volume := 63;
  Sofac[3] := Volume;    Sofac[4] := Volume;
  Sofac[5] := Bass + 7;  Sofac[6] := Treble + 7;  Dummy := Balance + 8;
  If Dummy < 0 then Dummy := 0; If Dummy > 16 then Dummy := 16;
  If Dummy < 8
    then Sofac[3] := Sofac[3] - (Volume DIV 8 - 3) * ABS(Dummy - 8);
  If Dummy > 8
    then Sofac[4] := Sofac[4] - (Volume DIV 8 - 3) * ABS(Dummy - 8);
  If Sofac[3] <  0 then Sofac[3] :=  0;  If Sofac[4] <  0 then Sofac[4] :=  0;
  If Sofac[5] <  3 then Sofac[5] :=  3;  If Sofac[6] <  3 then Sofac[6] :=  3;
  If Sofac[5] > 11 then Sofac[5] := 11;  If Sofac[6] > 11 then Sofac[6] := 11;
  Bass := Sofac[5] - 7;  Treble := Sofac[6] - 7;  Balance := Dummy - 8;
  Sofac[2] := $00;                       IIC(6,Off,Sofac,Error);
End;  {setaudio}

Procedure SetStereo(Stereo : Boolean);
Var Error : Boolean;
Begin
  If Stereo then Symo[3] := $60 else Symo[3] := $64;
  Symo[2] := $02;   IIC(3,Off,Symo,Error);
End;  {setstereo}

Procedure MPX_In(MPX_Mode : Boolean);
Var Error : Boolean;
Begin
  If MPX_Mode
    then Musti[2] := $00       { select AM input of TEA6000   }
    else Musti[2] := $FE;      { select FM input of TEA6000   }
  Musti[1] := $C2;             { write address TEA6000        }
  IIC(2,Off,Musti,Error);      { enable selected input        }
  Musti[1] := $C3;             { restore read address TEA6000 }
End;  {mpx_in}

Procedure SetFrequency(Var Frequency : Real; Current : Boolean);
Var DividingNumber : LongInt;
    Error          : Boolean;
Begin
  If ExtendedRange
    then begin
           If Round(Frequency * 100) / 100 > 150.00 then Frequency :=  50.50;
           If Round(Frequency * 100) / 100 <  50.00 then Frequency := 150.00;
         end
    else begin
           If Round(Frequency * 100) / 100 > 108.00 then Frequency :=  87.50;
           If Round(Frequency * 100) / 100 <  87.50 then Frequency := 108.00;
         end;
  DividingNumber := ROUND((Frequency + 10.701) / 0.01) SHL 1;
  If Current then Symo[3] := Lo(DividingNumber) OR  $01
             else Symo[3] := Lo(DividingNumber) AND $FE;
  Symo[2] := $00; Symo[4] := Hi(DividingNumber);    IIC(4,Off,Symo,Error);
End;  {setfrequency}

Procedure GetTuningInfo( Var Level     : Byte;
                         Var Stereo    : Boolean;
                         Var Deviation : Integer);
Var Error : Boolean;
Begin
  IIC(3,_On,Musti,Error);
  Stereo    := (Musti[2] AND $F0 SHR 5) <= 3;
  Level     :=  Musti[2] AND $0F SHR 1;
  Deviation := (Musti[3] - 127) DIV 2 ;
  If Deviation < -10 then Deviation := -10 else
    If Deviation > 10 then Deviation := 10;
End;  {gettuninginfo}

Procedure Search(Var Frequency : Real;
                     MinLevel  : Byte;
                     Up        : Boolean);
Var Level     : Byte;
    Deviation : Integer;
    Stereo    : Boolean;

  Function OnGrid : Boolean;
  Var St : String[8];
  Begin
    Str(Frequency:7:3,St);  OnGrid := (Copy(St,6,1) = '0');
  End;  {ongrid}

  Function TuningCorrect : Boolean;
  Var Ok         : Boolean;
      FoundLevel : Byte;
  Begin
    Ok := (Level >= MinLevel); FoundLevel := Level;
    If Ok then begin
                 Delay(10);   { check level second time }
                 GetTuningInfo(Level,Stereo,Deviation);
                 Ok := (Level >= FoundLevel - 1) AND
                       (Level <= FoundLevel + 1);
                 If Ok then begin        { check level third time }
                              Delay(60);
                              GetTuningInfo(Level,Stereo,Deviation);
                              Ok := (Level >= FoundLevel - 1) AND
                                    (Level <= FoundLevel + 1);
                            end;
               end;
    If Ok then
      begin
        Ok := (Level          >= MinLevel)  AND
              (Deviation + 2  in [0..4]);
        If Ok then                     {read and evaluate MUSTI second time}
                begin Delay(80);
                      GetTuningInfo(Level,Stereo,Deviation);
                      Ok := (Level         >= MinLevel)  AND
                            (Deviation + 2 in [0..4]);
                end;
        If Ok then                     {read and evaluate MUSTI third time }
                begin Delay(80);
                      GetTuningInfo(Level,Stereo,Deviation);
                      Ok := (Level         >= MinLevel)  AND
                            (Deviation + 2 in [0..4]);
                end;
      end;
    TuningCorrect := Ok;
  End;  {tuningcorrect}

Begin                    { search }
  LF(Off);
  If Up
    then Repeat
           If NOT OnGrid
             then Repeat Frequency := Frequency - 0.01
                  Until  OnGrid;
           Frequency := Frequency + 0.1;
           SetFrequency(Frequency,TRUE);   Delay(10);
           GetTuningInfo(Level,Stereo,Deviation);
         Until TuningCorrect OR KeyPressed
    else Repeat
           If NOT OnGrid
             then Repeat Frequency := Frequency + 0.01
                  Until  OnGrid;
           Frequency := Frequency - 0.1;
           SetFrequency(Frequency,TRUE);   Delay(10);
           GetTuningInfo(Level,Stereo,Deviation);
         Until TuningCorrect OR KeyPressed;
  LF(_On);
End;  {search}

Procedure Abort(Nr : Byte);
Begin
{  Exit;}
  ClrScr;
  If Nr = 1
    then WriteLn(#7,'No PCRadio hardware found !!')
    else WriteLn(#7,'Incorrect PCRadio Cardaddress  !!');
  Halt;
End;  {abort}

Procedure Init_PCRadio;

Const MaxAddresses = 6;
      AddressRange : Array[1..MaxAddresses] of Integer
                   = (432,496,632,888,760,956);
      MaxDevices   = 7; { 4 * COM + 3 * LPT }
Var AddressOk,Error   : Boolean;
    Devices           : Array[1..MaxDevices] of Integer;
    NrOfDevices       : Byte;

{  Procedure CheckSystem;
  Var Addresses      : Array[1..9] of Word Absolute $0040:$0000;
      DeviceCounter  : Byte;
  Begin
    NrOfDevices := 0;
    For DeviceCounter := 1 to MaxDevices do
      If Addresses[DeviceCounter] <> 0
        then begin NrOfDevices := NrOfDevices + 1;
                   Devices[NrOfDevices] := Addresses[DeviceCounter]; end;
  End;  {checksystem}

  Procedure FindCardAddress(Var Error : Boolean);
  Var Counter, DeviceCounter : Byte;
      InUse                  : Boolean;

    Function MustiFound : Boolean;
    Var Error : Boolean;

      Function FreeAddress : Boolean;
      Var ReferenceByte, CheckByte : Byte;
          Free                     : Boolean;
      Begin
        {$IFDEF TESTUNIT}
        PortW(PCRadio_Address,0);
        PortW(PCRadio_Address,1);
        PortW(PCRadio_Address,0);
        ReferenceByte := InPort(PCRadio_Address) AND $04;
        Free := (ReferenceByte = $00);
        If Free
          then begin PortW(PCRadio_Address,2);
                     PortW(PCRadio_Address,3);
                     PortW(PCRadio_Address,2);
                     ReferenceByte := InPort(PCRadio_Address) AND $04;
                     Free := (ReferenceByte = $04);
               end;
        {$ELSE}
        Port[PCRadio_Address] := 0;
        Port[PCRadio_Address] := 1;
        Port[PCRadio_Address] := 0;
        ReferenceByte := Port[PCRadio_Address] AND $04;
        Free := (ReferenceByte = $00);
        If Free
          then begin Port[PCRadio_Address] := 2;
                     Port[PCRadio_Address] := 3;
                     Port[PCRadio_Address] := 2;
                     ReferenceByte := Port[PCRadio_Address] AND $04;
                     Free := (ReferenceByte = $04);
               end;
        {$ENDIF}
        FreeAddress := Free;
      End;  {freeaddress}

    Begin                 { musti found }
      Musti[1]   := $C2;          Musti[2]   := $FE;
      IIC(3,Off,Musti,Error);
      MustiFound := NOT Error AND FreeAddress;
    End;  {mustifound}

  Begin              { find card address }
    Counter := 0;   { CheckSystem; }
    Repeat
      Counter := Counter + 1;
      PCRadio_Address := AddressRange[Counter];
      DeviceCounter := 1;
      Repeat
        InUse := (PCRadio_Address = Devices[DeviceCounter]);
        If NOT InUse then DeviceCounter := DeviceCounter + 1;
      Until InUse OR (DeviceCounter > NrOfDevices);
      If InUse then AddressOk := Off else AddressOk := MustiFound;
    Until AddressOk OR (Counter >= MaxAddresses);
    If NOT AddressOk then PCRadio_Address := 0;
  End;  {findcardaddress}
}
Begin                 { init PCRadio }
{  If PCRadio_Address = 0       { check hardware presence                  }
    then begin FindCardAddress(AddressOk);
               If NOT AddressOk then Abort(1);
         end;                                 }
  Musti[1] := $C2;             { write address Musti                      }
  Musti[2] := $FE;             { initialization code at program start     }
  IIC(3,Off,Musti,Error);      { initialize Musti for FM mode             }
{  If Error
    then Abort(2);   }          { check given or found hardware address    }
  Musti[1] := $C3;             { read address Musti                       }
  Symo[1]  := $C4;             { address Symo                             }
  Symo[2]  := $00;             { sub address                              }
  Symo[5]  := $60;             { $60 = stereo on, $64 = stereo off        }
  Symo[6]  := $00;             { initialization code at program start     }
  Sofac[1] := $80;             { address Sofac                            }
  Sofac[2] := $00;             { sub address                              }
  Sofac[7] := $FF;             { initialization code at program start     }
  Sofac[8] := $00;             { $00 = LF _On,  $80 = LF Off               }
  SetStereo(_On);               { initialization Symo                      }
End;  {init_pcradio}

BEGIN  {INITIALIZATION}
  PCRadio_Address := 0;
  ExtendedRange   := FALSE;
END.  { PCR_Sup }
