[Setup]
AppName=gregorio
AppVersion=1.1
DefaultDirName={pf}\gregorio
DefaultGroupName=gregorio
SetupIconFile=gregorio.ico
Compression=lzma2
SolidCompression=yes
LicenseFile=license.txt
AppCopyright=Copyright (C) 2006-2010 Elie Roux
AppComments=Gregorian chant typesetting software.
AppContact=gregorio-devel@gna.org
AppPublisher=Elie Roux
AppPublisherURL=http://home.gna.org/gregorio/
AppReadmeFile=http://home.gna.org/gregorio/
BackColor=$D4AE65
BackColor2=$FDF7EB
WizardSmallImageFile=gregorio-24.bmp
WizardImageFile=gregorio-image.bmp

[Dirs]
Name: "{app}\fonts"
Name: "{app}\tex"
Name: "{app}\contrib"

[Files]
Source: "gregorio.exe"; DestDir: "{app}";
Source: "gregorio.ico"; DestDir: "{app}";
Source: "install.lua"; DestDir: "{app}";
Source: "README.txt"; DestDir: "{app}";
Source: "license.txt"; DestDir: "{app}";
Source: "contrib\*"; DestDir: "{app}\contrib";
Source: "tex\*"; DestDir: "{app}\tex";
Source: "fonts\*"; DestDir: "{app}\fonts";

[Run]
Filename: "texlua.exe"; Parameters: """{app}\install.lua"""; StatusMsg: "Installing Fonts..."; Description: "Font installation"; Flags: postinstall ; WorkingDir: "{app}";
Filename: "{app}\README.txt"; Description: "View the README file"; Flags: postinstall shellexec skipifsilent;

[Code]
procedure URLLabelOnClickOne(Sender: TObject);
var
  ErrorCode: Integer;
begin
  ShellExec('open', 'http://www.tug.org/texlive/acquire.html', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
end;

procedure URLLabelOnClickTwo(Sender: TObject);
var
  ErrorCode: Integer;
begin
  ShellExec('open', 'http://home.gna.org/gregorio/installation-windows', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
end;

procedure CreateTheWizardPages;
var
  Page: TWizardPage;
  StaticText: TNewStaticText;
begin
  Page := CreateCustomPage(wpWelcome, 'Installation Requirements', 'Please read the following important information before continuing.');

  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(0);
  StaticText.Height := ScaleY(15);
  StaticText.Caption := 'You are about to install the gregorio software, which is working with a';
  StaticText.Parent := Page.Surface;
  
  StaticText := TNewStaticText.Create(Page);
  StaticText.Height := ScaleY(15);
  StaticText.Top := ScaleY(13);
  StaticText.Caption := 'typesetting software called LuaTeX.';
  StaticText.Parent := Page.Surface;
  
  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(35);;
  StaticText.Caption := 'The installation and use of gregorio needs LuaTeX in order to work.';
  StaticText.Parent := Page.Surface;

  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(60);;
  StaticText.Caption := 'The best way to install it is to install the free TeX distribution TeXLive (at least 2010).';
  StaticText.Parent := Page.Surface;

  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(75);;
  StaticText.Caption := 'If you have not already installed it, please do it before proceeding further!';
  StaticText.Parent := Page.Surface;
  
  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(105);;
  StaticText.Caption := 'http://www.tug.org/texlive/acquire.html';
  StaticText.Cursor := crHand;
  StaticText.OnClick := @URLLabelOnClickOne;
  StaticText.Parent := Page.Surface;
  StaticText.Font.Style := StaticText.Font.Style + [fsUnderline];
  StaticText.Font.Color := clBlue;
  
  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(125);;
  StaticText.Caption := 'http://home.gna.org/gregorio/installation-windows';
  StaticText.Cursor := crHand;
  StaticText.OnClick := @URLLabelOnClickTwo;
  StaticText.Parent := Page.Surface;
  StaticText.Font.Style := StaticText.Font.Style + [fsUnderline];
  StaticText.Font.Color := clBlue;
end;

procedure InitializeWizard();

begin
  CreateTheWizardPages;
end;
