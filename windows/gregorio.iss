[Setup]
AppName=gregorio
AppVersion=2.4.3
DefaultDirName={pf}\gregorio
DefaultGroupName=gregorio
SetupIconFile=gregorio.ico
Compression=lzma2
SolidCompression=yes
LicenseFile=license.txt
AppCopyright=Copyright (C) 2006-2014 Elie Roux
AppComments=Gregorian chant typesetting software.
AppContact=gregorio-devel@gna.org
AppPublisher=Elie Roux
AppPublisherURL=http://home.gna.org/gregorio/
AppReadmeFile=http://home.gna.org/gregorio/
BackColor=$D4AE65
BackColor2=$FDF7EB
WizardSmallImageFile=gregorio-32.bmp
WizardImageFile=gregorio-image.bmp
ChangesAssociations=yes

[Registry]
Root: HKCR; Subkey: ".gabc"; ValueType: string; ValueName: ""; ValueData: "Gregorio"; Flags: uninsdeletevalue
Root: HKCR; Subkey: "Gregorio"; ValueType: string; ValueName: ""; ValueData: "Gregorio score"; Flags: uninsdeletekey
Root: HKCR; Subkey: "Gregorio\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\gregorio.ico"; Flags: uninsdeletekey
Root: HKCR; Subkey: "Gregorio\shell\open\command"; ValueType: string; ValueName: ""; ValueData: "texworks.exe ""%1"""; Flags: uninsdeletekey

[Dirs]
Name: "{app}\contrib"
Name: "{app}\examples"
Name: "{app}\contrib\TeXworks"

[Files]
Source: "../src/gregorio.exe"; DestDir: "{app}";
Source: "gregorio.ico"; DestDir: "{app}";
Source: "install.lua"; DestDir: "{app}";
Source: "README.txt"; DestDir: "{app}"; Flags: isreadme
Source: "license.txt"; DestDir: "{app}";
Source: "../contrib\*"; DestDir: "{app}\contrib";
Source: "../examples\*"; DestDir: "{app}\examples";
Source: "../fonts/gregoriotex.tds.zip"; DestDir: "{app}";
Source: "../contrib\TeXworks\Windows\*"; DestDir: "{app}\contrib\TeXworks";

[Run]
Filename: "texlua.exe"; Parameters: """{app}\install.lua"" > ""{app}\install.log"""; StatusMsg: "Installing Fonts..."; Description: "Font installation"; Flags: postinstall ; WorkingDir: "{app}";
Filename: "texlua.exe"; Parameters: """{app}\install.lua"" --conf ""{app}"" > ""{app}\install-conf.log"""; StatusMsg: "Configuring TeXWorks..."; Description: "Configure TeXWorks"; Flags: postinstall ; WorkingDir: "{app}";

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
  StaticText.Caption := 'The best way to install LuaTeX is to install the TeXLive distribution.';
  StaticText.Parent := Page.Surface;

  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(75);;
  StaticText.Caption := 'If you have not already installed it, please do it before proceeding further!';
  StaticText.Parent := Page.Surface;

  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(100);;
  StaticText.Caption := 'Note that you have to reboot your computer after having installed TeXLive';
  StaticText.Parent := Page.Surface;
  
  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(115);;
  StaticText.Caption := 'and before installing Gregorio.';
  StaticText.Parent := Page.Surface;

  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(145);;
  StaticText.Caption := 'http://www.tug.org/texlive/acquire.html';
  StaticText.Cursor := crHand;
  StaticText.OnClick := @URLLabelOnClickOne;
  StaticText.Parent := Page.Surface;
  StaticText.Font.Style := StaticText.Font.Style + [fsUnderline];
  StaticText.Font.Color := clBlue;
  
  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(165);;
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
