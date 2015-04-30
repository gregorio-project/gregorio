[Setup]
AppName=gregorio
AppVersion=3.0.0-rc2
DefaultDirName={pf}\gregorio
DefaultGroupName=gregorio
SetupIconFile=gregorio.ico
Compression=lzma2
SolidCompression=yes
LicenseFile=../COPYING.md
AppCopyright=Copyright (C) 2006-2015 Gregorio project
AppComments=Software for engraving Gregorian Chant scores.
AppContact=gregorio-devel@gna.org
AppPublisher=Gregorio Project
AppPublisherURL=https://github.com/gregorio-project/gregorio
AppReadmeFile=https://github.com/gregorio-project/gregorio
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

[Files]
Source: "../src/gregorio.exe"; DestDir: "{app}";
Source: "gregorio.ico"; DestDir: "{app}";
Source: "install.lua"; DestDir: "{app}";
Source: "README.txt"; DestDir: "{app}"; Flags: isreadme
Source: "../CHANGELOG.md"; DestDir: "{app}";
Source: "../README.md"; DestDir: "{app}";
Source: "../CONTRIBUTORS.md"; DestDir: "{app}";
Source: "../UPGRADE.md"; DestDir: "{app}";
; PARSE_VERSION_FILE_NEXTLINE
Source: "../doc/GregorioRef-3_0_0-rc2.pdf"; DestDir: "{app}";
Source: "../COPYING.md"; DestDir: "{app}";
Source: "../contrib/900_gregorio.xml"; DestDir: "{app}\contrib";
Source: "../contrib/gregorio-scribus.lua"; DestDir: "{app}\contrib";
Source: "../contrib/*"; DestDir: "{app}\contrib";
Source: "../examples/PopulusSion.gabc"; DestDir: "{app}\examples";
Source: "../examples/main-lualatex.tex"; DestDir: "{app}\examples";
Source: "../gregoriotex.tds.zip"; DestDir: "{app}";

[Run]
Filename: "texlua.exe"; Parameters: """{app}\install.lua"" > ""{app}\install.log"""; StatusMsg: "Configuring texmf..."; Description: "Add files to texmf tree"; Flags: postinstall ; WorkingDir: "{app}";

[Code]
procedure URLLabelOnClickOne(Sender: TObject);
var
  ErrorCode: Integer;
begin
  ShellExec('open', 'https://www.tug.org/texlive/acquire.html', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
end;

procedure URLLabelOnClickTwo(Sender: TObject);
var
  ErrorCode: Integer;
begin
  ShellExec('open', 'http://gregorio-project.github.io/installation-windows.html', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
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
  StaticText.Caption := 'https://www.tug.org/texlive/acquire.html';
  StaticText.Cursor := crHand;
  StaticText.OnClick := @URLLabelOnClickOne;
  StaticText.Parent := Page.Surface;
  StaticText.Font.Style := StaticText.Font.Style + [fsUnderline];
  StaticText.Font.Color := clBlue;
  
  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(165);;
  StaticText.Caption := 'http://gregorio-project.github.io/installation-windows.html';
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
