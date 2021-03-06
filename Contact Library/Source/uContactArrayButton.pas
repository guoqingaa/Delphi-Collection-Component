{ ============================================
  Software Name : 	ContactArrayButton
  ============================================ }
{ ******************************************** }
{ Written By WalWalWalides }
{ CopyRight � 2019 }
{ Email : WalWalWalides@gmail.com }
{ GitHub :https://github.com/walwalwalides }
{ ******************************************** }
unit uContactArrayButton;

interface

uses windows, extctrls, controls, classes, graphics, messages, sysUtils;

const
  ContactMaxBtn = 48;

type

  TContact = record
    ContactName: string[20];
    ContactDescription: string[20];
  end;

  TBtnShape = (bsFlat, bs3D);
  TBtnStatus = (stHidden, stFlat, stDown, stHI);
  TBtnOpmode = (omMom, omPress, omToggle);
  TBtnColorIndex = (bcInactBG, bcActiveBG, bcFlat, bcHI, bcLO);
  TBtnChangeProc = procedure(sender: TObject; BtnNr: byte; status: TBtnStatus; button: TmouseButton) of object;
  TBtnPaintProc = procedure(sender: TObject; BtnNr: byte; status: TBtnStatus) of object;
  TColorTable = array [bcInactBG .. bcLO] of LongInt;
  TPColorTable = ^TColorTable;

  TContactArrayBtn = class(TGraphicControl)
  private
    // FContacts:TContact;
    FContacts: array of string;
    FonBtnchange: TBtnChangeProc;
    FonBtnPaint: TBtnPaintProc;
    FonEnter: TNotifyEvent;
    FonLeave: TNotifyEvent;
    FHiBtn: byte;
    Frows: byte;
    Fcolumns: byte;
    FbtnWidth: byte;
    FbtnHeight: byte;
    FBtnEdge: byte;
    FBtnSpacing: byte;
    FBorder: byte;
    FBtnShape: TBtnShape;
    FPcolorTable: TPColorTable;
    FBtnControl: array [0 .. ContactMaxBtn] of byte;
    FNextRelease: byte;
    FBtnCaptionSize: byte;
    procedure setRows(n: byte);
    procedure setColumns(n: byte);
    procedure setBtnWidth(n: byte);
    procedure setBtnHeight(n: byte);
    procedure setBtnshape(bs: TBtnShape);
    procedure setBorder(b: byte);
    procedure setSpacing(b: byte);
    procedure setBtnEdge(edge: byte);
    procedure repaintBtns;
    procedure fixdimensions;
    procedure BtnPaint(BtnNr: byte; bst: TBtnStatus);
    procedure CMmouseLeave(var message: Tmessage); message CM_MOUSELEAVE;
    procedure CMmouseEnter(var message: Tmessage); message CM_MOUSEENTER;
    procedure InitBtns;
    procedure SetBtnStatus(BtnNr: byte; status: TBtnStatus);
    function GetBtnGroup(BtnNr: byte): byte;
    function GetBtnOpMode(BtnNr: byte): TBtnOpmode;
    function GetContacts(Index: Integer): string;
    procedure SetContacts(Index: Integer; const Value: string);
    procedure setBtnCaptionSize(n: byte);
  protected
    procedure paint; override;
    procedure MouseDown(button: TmouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(button: TmouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure AssignColorTable(p: TPColorTable);
    procedure TestReleaseBtn(downBtn: byte);
  public
    constructor Create(AOwner: TComponent); override;
    function GetBtnRect(BtnNr: byte): TRect;
    function GetBtnStatus(BtnNr: byte): TBtnStatus;
    procedure setBtnOpmode(BtnNr: byte; opMode: TBtnOpmode);
    procedure BtnHide(BtnNr: byte);
    procedure BtnShow(BtnNr: byte);
    procedure BtnDown(BtnNr: byte);
    procedure BtnRelease(BtnNr: byte);
    procedure setBtnGroup(BtnNr, group: byte);
    property Contacts[Index: Integer]: string read GetContacts write SetContacts;
    property canvas;
    property PColorTable: TPColorTable read FPcolorTable write AssignColorTable;
  published

    property Border: byte read FBorder write setBorder default 10;
    property BtnHeight: byte read FbtnHeight write setBtnHeight default 20;
    property BtnCaptionSize: byte read FBtnCaptionSize write setBtnCaptionSize default 6;
    property BtnSpacing: byte read FBtnSpacing write setSpacing default 5;
    property BtnShape: TBtnShape read FBtnShape write setBtnshape default bs3D;
    property BtnWidth: byte read FbtnWidth write setBtnWidth default 30;
    property BtnEdge: byte read FBtnEdge write setBtnEdge default 1;
    property Color;
    property Columns: byte read Fcolumns write setColumns default 2;
    property Enabled;
    property Font;
    property onBtnChange: TBtnChangeProc read FonBtnchange write FonBtnchange;
    property onBtnPaint: TBtnPaintProc read FonBtnPaint write FonBtnPaint;
    property OnEnter: TNotifyEvent read FonEnter write FonEnter;
    property OnLeave: TNotifyEvent read FonLeave write FonLeave;
    property Rows: byte read Frows write setRows default 2;
    property Visible;
  end;


implementation

const
  defaultColors: TColorTable = ($C0C0C0, $F0F0F0, $808080, $FFFFFF, $202020);


procedure TContactArrayBtn.setBtnOpmode(BtnNr: byte; opMode: TBtnOpmode);
var
  cb: byte;
begin
  cb := FBtnControl[BtnNr] and $CF;
  FBtnControl[BtnNr] := cb or (byte(opMode) shl 4);
end;

function TContactArrayBtn.GetBtnOpMode(BtnNr: byte): TBtnOpmode;
begin
  result := TBtnOpmode((FBtnControl[BtnNr] shr 4) and $3);
end;

procedure TContactArrayBtn.SetBtnStatus(BtnNr: byte; status: TBtnStatus);
var
  bc: byte;
begin
  bc := FBtnControl[BtnNr] and $3F;
  FBtnControl[BtnNr] := bc or (byte(status) shl 6);
end;

function TContactArrayBtn.GetBtnGroup(BtnNr: byte): byte;
begin
  result := FBtnControl[BtnNr] and $F;
end;

procedure TContactArrayBtn.setBtnGroup(BtnNr, group: byte);
// add button to group
var
  bc: byte;
begin
  bc := FBtnControl[BtnNr] and $F0;
  FBtnControl[BtnNr] := bc or group;
end;

procedure TContactArrayBtn.InitBtns;
// alle buttons group -0-, press
var
  i, top: byte;
  control: byte;
begin
  top := Frows * Fcolumns - 1;
  SetLength(FContacts, top + 1);
  control := (byte(stFlat) shl 6) or (byte(omPress) shl 4);
  for i := 0 to ContactMaxBtn do
    if i <= top then
    begin
      FBtnControl[i] := control;

    end
    else
      FBtnControl[i] := 0;
end;

function TContactArrayBtn.GetBtnStatus(BtnNr: byte): TBtnStatus;
begin
  result := TBtnStatus((FBtnControl[BtnNr] shr 6) and $3);
end;

function TContactArrayBtn.GetContacts(Index: Integer): string;
begin
  if (Index < 0) or (Index > High(FContacts)) then
    exit;
  result := FContacts[Index];
end;

procedure TContactArrayBtn.BtnHide(BtnNr: byte);
// hide button
begin
  if GetBtnStatus(BtnNr) <> stHidden then
  begin
    SetBtnStatus(BtnNr, stHidden);
    if FHiBtn = BtnNr then
      FHiBtn := ContactMaxBtn;
    BtnPaint(BtnNr, stHidden);
  end;
end;

procedure TContactArrayBtn.BtnShow(BtnNr: byte);
// show a hidden button, set flat
begin
  if GetBtnStatus(BtnNr) = stHidden then
  begin
    SetBtnStatus(BtnNr, stFlat);
    BtnPaint(BtnNr, stFlat);
  end;
end;

procedure TContactArrayBtn.BtnRelease(BtnNr: byte);
// set button from DOWN to Flat
begin
  if GetBtnStatus(BtnNr) = stDown then
  begin
    SetBtnStatus(BtnNr, stFlat);
    BtnPaint(BtnNr, stFlat);
  end;
end;

procedure TContactArrayBtn.BtnDown(BtnNr: byte);
begin
  if GetBtnStatus(BtnNr) = stFlat then
  begin
    SetBtnStatus(BtnNr, stDown);
    BtnPaint(BtnNr, stDown);
    TestReleaseBtn(BtnNr); // to release other buttons
  end;
end;

procedure TContactArrayBtn.TestReleaseBtn(downBtn: byte);
// downBtn was pressed down, test to release buttons of same group
var
  groupNr, i: byte;
begin
  groupNr := GetBtnGroup(downBtn);
  for i := 0 to Frows * Fcolumns - 1 do
    if (i <> downBtn) and (GetBtnGroup(i) = groupNr) and (GetBtnStatus(i) = stDown) then
    begin
      SetBtnStatus(i, stFlat);
      BtnPaint(i, stFlat);
    end;
end;

procedure TContactArrayBtn.BtnPaint(BtnNr: byte; bst: TBtnStatus);
// if button hidden: erase
var
  r: TRect;
  radius: byte;
  k1, k2: LongInt;
  i: byte;
  K: Integer;
  j: Integer;
  sumCR: string;
begin
  r := GetBtnRect(BtnNr);
  with canvas do
  begin
    pen.Width := 1;
    brush.style := bssolid;
    case bst of
      stHidden:
        begin
          brush.Color := Color;
          brush.style := bssolid;
          fillrect(r);
          exit;
        end;
      stFlat:
        begin
          brush.Color := PColorTable^[bcInactBG];
          k1 := PColorTable^[bcFlat];
          k2 := k1;
        end;
      stHI:
        begin
          brush.Color := PColorTable^[bcInactBG];
          k1 := PColorTable^[bcHI];
          k2 := PColorTable^[bcLO];
        end;
      stDown:
        begin
          brush.Color := PColorTable^[bcActiveBG];
          k1 := PColorTable^[bcLO];
          k2 := PColorTable^[bcHI];

        end;
    end;

    if FBtnShape = bsFlat then
    begin
      radius := FbtnHeight div 2;
      if radius > 40 then
        radius := 40;
      if radius < 10 then
        radius := 10;
      pen.Width := FBtnEdge;
      pen.Color := k1;
      roundrect(r.left + 1, r.top + 1, r.right, r.bottom, radius, radius);
    end
    else
    begin
      fillrect(r);
      for i := 0 to FBtnEdge - 1 do
      begin
        pen.Color := k1;
        moveto(r.right - 1 - i, r.top + i);
        lineto(r.left + i, r.top + i);
        lineto(r.left + i, r.bottom - 1 - i);
        pen.Color := k2;
        lineto(r.right - 1 - i, r.bottom - 1 - i);
        lineto(r.right - 1 - i, r.top + i);
        // ---------------------------------------------//

      end;

      for K := 0 to Fcolumns - 1 do
      begin
        for j := 0 to Frows - 1 do
        begin
          with canvas do
          begin
            brush.Color := $C0C0C0;
            Font.Size := FBtnCaptionSize;
            if (K = 0) then
            begin
              if (j <> 0) then
              begin
                sumCR := inttostr(j * Fcolumns)
              end
              else
              begin
                sumCR := '0';
              end;
            end;
          end;

          if (j = 0) then
          begin
            if (K <> 0) then
            begin
              sumCR := inttostr(K * 1)
            end
            else
            begin
              sumCR := '0';
            end;
          end;
          if (K <> 0) and (j <> 0) then
          begin
            sumCR := inttostr((j * Fcolumns) + K);

          end;
          canvas.TextOut((13 + ((FbtnWidth + 5) * K)), (29 + ((FbtnHeight + 5) * j)), ('Contact' + sumCR));
        end;
      end;

    end; // else
  end; // with canvas
  if not(csDesigning in componentstate) and assigned(onBtnPaint) then
    onBtnPaint(self, BtnNr, bst);
end;

procedure TContactArrayBtn.repaintBtns;
// na initialiseren hele paintbox
var
  i: byte;

begin
  for i := 0 to Frows * Fcolumns - 1 do
  begin

    BtnPaint(i, GetBtnStatus(i));

  end;

end;

procedure TContactArrayBtn.fixdimensions;
// adjust width,height na verandering van knop of spacing
// generates onPaint event
begin
  if Frows = 0 then
    Frows := 1;
  if Fcolumns = 0 then
    Fcolumns := 1;
  Width := Fcolumns * (FbtnWidth + FBtnSpacing) - FBtnSpacing + 2 * FBorder;
  height := Frows * (FbtnHeight + FBtnSpacing) - FBtnSpacing + 2 * FBorder;
end;

constructor TContactArrayBtn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  canvas.Font := Font;
  FHiBtn := ContactMaxBtn; // =off
  FBtnShape := bs3D;
  FBtnEdge := 1;
  FPcolorTable := @defaultColors;
  Frows := 4;
  Fcolumns := 4;
  InitBtns;
  FbtnWidth := 40;
  FbtnHeight := 30;
  FBtnSpacing := 5;
  FBorder := 10;
  FBtnCaptionSize := 6;
  Color := clAppWorkSpace;
  fixdimensions; // set width , height

end;

procedure TContactArrayBtn.AssignColorTable(p: TPColorTable);
begin
  FPcolorTable := p;
  invalidate;
end;

procedure TContactArrayBtn.MouseDown(button: TmouseButton; Shift: TShiftState; X, Y: Integer);
var
  status: TBtnStatus;
begin
  FNextRelease := ContactMaxBtn;
  if (FHiBtn = ContactMaxBtn) then
    exit; // no button selected
  // ----
  status := GetBtnStatus(FHiBtn);
  if status = stFlat then
  begin
    SetBtnStatus(FHiBtn, stDown);
    BtnPaint(FHiBtn, stDown);
    TestReleaseBtn(FHiBtn);
    if assigned(FonBtnchange) and (not(csDesigning in componentstate)) then
      onBtnChange(self, FHiBtn, stDown, button);
  end;
  case GetBtnOpMode(FHiBtn) of
    omMom:
      FNextRelease := FHiBtn;
    omToggle:
      if status = stDown then
        FNextRelease := FHiBtn;
  end; // case
end;

procedure TContactArrayBtn.MouseUp(button: TmouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FNextRelease <> ContactMaxBtn then
  begin
    SetBtnStatus(FNextRelease, stFlat);
    BtnPaint(FNextRelease, stFlat);
    if (not(csDesigning in componentstate)) and assigned(FonBtnchange) then
      onBtnChange(self, FNextRelease, stFlat, button);
  end;
end;

procedure TContactArrayBtn.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  dx, maxX, maxY, dy: Integer;
  button: byte;
  px, py: Integer;
  status: TBtnStatus;
begin
  X := X - FBorder;
  Y := Y - FBorder;
  dx := FBtnSpacing + FbtnWidth;
  dy := FBtnSpacing + FbtnHeight;
  maxX := Fcolumns * dx;
  maxY := Frows * dy;
  px := X mod dx;
  py := Y mod dy;
  if (X < maxX) and (Y < maxY) and (px > FBtnEdge) and (px < dx - FBtnEdge - FBtnSpacing) and (py > FBtnEdge) and (py < dy - FBtnEdge - FBtnSpacing) then
  begin
    button := X div dx + Fcolumns * (Y div dy);
  end
  else
    button := ContactMaxBtn;
  status := GetBtnStatus(button);
  if (status = stHidden) then
    button := ContactMaxBtn;
  if button = FHiBtn then
    exit; // if no change

  // ---process Btn change
  if button <> ContactMaxBtn then
    cursor := crhandpoint
  else
    cursor := crArrow;

  if (FHiBtn <> ContactMaxBtn) and (GetBtnStatus(FHiBtn) <> stDown) then
    BtnPaint(FHiBtn, stFlat); //
  if (button <> ContactMaxBtn) and (GetBtnStatus(button) <> stDown) then
    BtnPaint(button, stHI); //
  FHiBtn := button;
end;

procedure TContactArrayBtn.paint;
var
  i: byte;
  k1, k2: LongInt;
begin
  FHiBtn := ContactMaxBtn;
  with canvas do
  begin
    brush.Color := Color;
    pen.Width := 1;
    pen.Color := PColorTable^[bcFlat];
    fillrect(rect(0, 0, Width, height));
    if FBorder > 0 then
    begin
      if FBtnShape = bs3D then
      begin
        k1 := PColorTable^[bcHI];
        k2 := PColorTable^[bcFlat];
      end
      else
      begin
        k1 := PColorTable^[bcFlat];
        k2 := k1;
      end;
      pen.Color := k1;
      moveto(Width - 1, 0);
      lineto(0, 0);
      lineto(0, height - 1);
      pen.Color := k2;
      lineto(Width - 1, height - 1);
      lineto(Width - 1, 0);
    end;
  end;
  for i := 0 to Fcolumns * Frows - 1 do
    if GetBtnStatus(i) <> stHidden then
      BtnPaint(i, GetBtnStatus(i));
end;

function TContactArrayBtn.GetBtnRect(BtnNr: byte): TRect;
var
  X, Y: Integer;
begin
  X := BtnNr mod Fcolumns;
  Y := BtnNr div Fcolumns;
  with result do
  begin
    left := FBorder + (FbtnWidth + FBtnSpacing) * X;
    right := left + FbtnWidth;
    top := FBorder + (FbtnHeight + FBtnSpacing) * Y;
    bottom := top + FbtnHeight;
  end;
end;

procedure TContactArrayBtn.setRows(n: byte);
begin
  if n = 0 then
    n := 1;
  if n > ContactMaxBtn then
    n := ContactMaxBtn;
  if n * Fcolumns > ContactMaxBtn then
    Fcolumns := 1;
  Frows := n;
  InitBtns;
  fixdimensions;
end;

procedure TContactArrayBtn.setColumns(n: byte);
begin
  if n = 0 then
    n := 1;
  if n > ContactMaxBtn then
    n := ContactMaxBtn;
  if n * Frows > ContactMaxBtn then
    Frows := 1;
  Fcolumns := n;
  InitBtns;
  fixdimensions;
end;

procedure TContactArrayBtn.SetContacts(Index: Integer; const Value: string);
begin
  if (Index < 0) or (Index > High(FContacts)) then
    exit;
  FContacts[Index] := Value;
end;

procedure TContactArrayBtn.setBtnWidth(n: byte);
begin
  if n < 10 then
    n := 10;
  FbtnWidth := n;
  fixdimensions;
end;

procedure TContactArrayBtn.setBtnHeight(n: byte);
begin
  if n < 10 then
    n := 10;
  FbtnHeight := n;
  fixdimensions;
end;

procedure TContactArrayBtn.setBtnshape(bs: TBtnShape);
begin
  FBtnShape := bs;
  invalidate;
end;

procedure TContactArrayBtn.setBtnCaptionSize(n: byte);
begin
  if (n < 6) then
    n := 6;
  FBtnCaptionSize := n;
  fixdimensions;
  invalidate;
end;

procedure TContactArrayBtn.setBtnEdge(edge: byte);
begin
  if (edge = 0) then
    edge := 1
  else if (edge > 2) then
    edge := 2;
  FBtnEdge := edge;
  repaintBtns;
end;

procedure TContactArrayBtn.setBorder(b: byte);
begin
  FBorder := b;
  fixdimensions;
end;

procedure TContactArrayBtn.setSpacing(b: byte);
begin
  FBtnSpacing := b;
  fixdimensions;
end;

procedure TContactArrayBtn.CMmouseLeave(var message: Tmessage);
begin
  if (FHiBtn <> ContactMaxBtn) then
  begin
    if GetBtnStatus(FHiBtn) <> stDown then
      BtnPaint(FHiBtn, stFlat);
    FHiBtn := ContactMaxBtn;
  end;
  if not(csDesigning in componentstate) and assigned(FonLeave) then
    OnLeave(self);
end;

procedure TContactArrayBtn.CMmouseEnter(var message: Tmessage);
begin
  if not(csDesigning in componentstate) and assigned(FonLeave) then
    OnEnter(self);
end;

end.
