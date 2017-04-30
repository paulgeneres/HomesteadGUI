unit admin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Menus, ActnList, ComCtrls, configure, homestead, ComObj,
  LazFileUtils, data, Windows;

type
  TTrafficLightColor = (
    GreenLight,
    YellowLight,
    RedLight,
    BlueLight
    );

  TVagrantAction = (
    vaUp,
    vaDestroy,
    vaHalt,
    vaSuspend,
    vaResume,
    vaProvision,
    vaReload
    );

  { TAdminForm }

  TAdminForm = class(TForm)
    BackupAction: TAction;
    RestoreAction: TAction;
    CmdAction: TAction;
    ConfigureAction: TAction;
    Image1: TImage;
    ImageList1: TImageList;
    ToolButton1: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton13: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    TrayIcon1: TTrayIcon;
    UpAction: TAction;
    HaltAction: TAction;
    SuspendAction: TAction;
    ResumeAction: TAction;
    ProvisionAction: TAction;
    ReloadAction: TAction;
    DestroyAction: TAction;
    SshAction: TAction;
    ActionList1: TActionList;
    OutputMemo: TMemo;
    ToolBar1: TToolBar;
    StatusLabel: TLabel;
    procedure BackupActionExecute(Sender: TObject);
    procedure CmdActionExecute(Sender: TObject);
    procedure ConfigureActionExecute(Sender: TObject);
    procedure DestroyActionExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure HaltActionExecute(Sender: TObject);
    procedure ProvisionActionExecute(Sender: TObject);
    procedure ReloadActionExecute(Sender: TObject);
    procedure RestoreActionExecute(Sender: TObject);
    procedure ResumeActionExecute(Sender: TObject);
    procedure SshActionExecute(Sender: TObject);
    procedure SuspendActionExecute(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure UpActionExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
    FHidden: boolean;
    FShown: boolean;
    procedure RefreshStatus;
    procedure StateIsUp;
    procedure StateIsHalted;
    procedure StateIsSuspended;
    procedure VagrantActionExecute(VagrantAction: TVagrantAction);
    procedure SetTrafficLight(LightColor: TTrafficLightColor);
  public
    { public declarations }
    property TrafficLight: TTrafficLightColor write SetTrafficLight;
  end;

var
  AdminForm: TAdminForm;

implementation

{$R *.lfm}

{ TAdminForm }

procedure TAdminForm.ConfigureActionExecute(Sender: TObject);
begin
  ConfigDialog.ShowModal;
end;

procedure TAdminForm.CmdActionExecute(Sender: TObject);
begin
  AHomestead.cmd;
end;

procedure TAdminForm.BackupActionExecute(Sender: TObject);
begin
  //AHomestead.Backup
end;

procedure TAdminForm.VagrantActionExecute(VagrantAction: TVagrantAction);
var
  Output: string;
begin
  TrafficLight := BlueLight;
  Toolbar1.Enabled := False;
  Toolbar1.Visible := False;
  OutputMemo.Cursor := crHourGlass;
  StatusLabel.Caption := 'Vagrant is running. Please wait...';
  Application.ProcessMessages;
  case VagrantAction of
    vaUp: AHomestead.Up(Output, OutputMemo);
    vaDestroy: AHomestead.DestroyBox(Output, OutputMemo);
    vaHalt: AHomestead.Halt(Output, OutputMemo);
    vaSuspend: AHomestead.Suspend(Output, OutputMemo);
    vaResume: AHomestead.Resume(Output, OutputMemo);
    vaProvision: AHomestead.Provision(Output, OutputMemo);
    vaReload: AHomestead.Reload(Output, OutputMemo)
  end;
  OutputMemo.Cursor := crDefault;
  Toolbar1.Visible := True;
  Toolbar1.Enabled := True;
  RefreshStatus;
end;

procedure TAdminForm.DestroyActionExecute(Sender: TObject);
begin
  if MessageDlg('CONFIRM', 'DO YOU REALLY WANT TO DESTROY THE HOMESTEAD INSTANCE',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    VagrantActionExecute(vaDestroy);
  end;
end;

procedure TAdminForm.FormCreate(Sender: TObject);
begin
  OutputMemo.Text := '';
  OutputMemo.ScrollBars := ssAutoBoth;
  FHidden := False;
  FShown := False;
  TrayIcon1.Show;
  SetEnvironmentVariable('VAGRANT_NO_COLOR', 'YES')
end;

procedure TAdminForm.SshActionExecute(Sender: TObject);
begin
  AHomestead.ssh;
end;

procedure TAdminForm.UpActionExecute(Sender: TObject);
begin
  VagrantActionExecute(vaUp);
end;

procedure TAdminForm.HaltActionExecute(Sender: TObject);
begin
  VagrantActionExecute(vaHalt);
end;

procedure TAdminForm.SuspendActionExecute(Sender: TObject);
begin
  VagrantActionExecute(vaSuspend);
end;

procedure TAdminForm.TrayIcon1Click(Sender: TObject);
begin
  if FHidden then
  begin
    Show;
    FHidden := False;
  end
  else
  begin
    Hide;
    FHidden := True;
  end;
end;

procedure TAdminForm.ResumeActionExecute(Sender: TObject);
begin
  VagrantActionExecute(vaResume);
end;

procedure TAdminForm.ProvisionActionExecute(Sender: TObject);
begin
  VagrantActionExecute(vaProvision);
end;

procedure TAdminForm.ReloadActionExecute(Sender: TObject);
begin
  VagrantActionExecute(vaReload);
end;

procedure TAdminForm.RestoreActionExecute(Sender: TObject);
begin
  //AHomestead.Restore
end;

procedure TAdminForm.FormShow(Sender: TObject);
var
  t: longint;
begin
  if not FShown then
  begin
    t := mrOk;
    while (t = mrOk) and (not Global.LoadValidConfig) do
    begin
      t := ConfigDialog.ShowModal;
    end;
    if t <> mrOk then
    begin
      Application.Terminate;
    end
    else
    begin
      RefreshStatus;
      FShown := True;
    end;
  end;
end;

procedure TAdminForm.RefreshStatus;
var
  Output: string;
begin
  Cursor := crHourglass;
  StatusLabel.Caption := 'Checking Homestead status. Please wait...';
  Application.ProcessMessages;
  case AHomestead.Status(Output) of
    HomesteadUp: StateIsUp;
    HomesteadHalted: StateIsHalted;
    HomesteadSuspended: StateIsSuspended;
    HomesteadDestroyed: StateIsHalted
  end;
  Cursor := crDefault;
end;

procedure TAdminForm.StateIsUp;
begin
  StatusLabel.Caption := 'Homestead is running.';
  UpAction.Enabled := False;
  HaltAction.Enabled := True;
  SuspendAction.Enabled := True;
  ResumeAction.Enabled := False;
  ProvisionAction.Enabled := True;
  ReloadAction.Enabled := True;
  SshAction.Enabled := True;
  TrafficLight := GreenLight;
end;

procedure TAdminForm.StateIsHalted;
begin
  StatusLabel.Caption := 'Homestead is halted.';
  UpAction.Enabled := True;
  HaltAction.Enabled := False;
  SuspendAction.Enabled := False;
  ResumeAction.Enabled := False;
  ProvisionAction.Enabled := False;
  ReloadAction.Enabled := False;
  SshAction.Enabled := False;
  TrafficLight := RedLight;
end;


procedure TAdminForm.StateIsSuspended;
begin
  StatusLabel.Caption := 'Homestead is suspended.';
  UpAction.Enabled := False;
  HaltAction.Enabled := False;
  SuspendAction.Enabled := False;
  ResumeAction.Enabled := True;
  ProvisionAction.Enabled := False;
  ReloadAction.Enabled := False;
  SshAction.Enabled := False;
  TrafficLight := YellowLight;
end;

procedure TAdminForm.SetTrafficLight(LightColor: TTrafficLightColor);
begin
  Image1.Picture.Bitmap := nil;
  Image1.Picture.Bitmap.TransparentMode := tmFixed;
  Image1.Picture.Bitmap.TransparentColor := clWhite;
  ImageList1.GetBitmap(Ord(LightColor), Image1.Picture.Bitmap);
end;

end.
