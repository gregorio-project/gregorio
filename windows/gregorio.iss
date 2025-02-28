[Setup]
AppName=gregorio
AppVersion=6.1.0
DefaultDirName={commonpf}\gregorio
DefaultGroupName=gregorio
SetupIconFile=gregorio.ico
Compression=lzma2
SolidCompression=yes
LicenseFile=../COPYING.md
AppCopyright=Copyright (C) 2006-2025 The Gregorio Project
AppComments=Software for engraving Gregorian Chant scores.
AppContact=gregorio-devel@googlegroups.com
AppPublisher=The Gregorio Project
AppPublisherURL=https://github.com/gregorio-project/gregorio
AppReadmeFile=https://github.com/gregorio-project/gregorio
WizardSmallImageFile=gregorio-32.bmp
WizardImageFile=gregorio-image.bmp
ChangesAssociations=yes
ChangesEnvironment=true

[Registry]
Root: HKCR; Subkey: ".gabc"; ValueType: string; ValueName: ""; ValueData: "Gregorio"; Flags: uninsdeletevalue
Root: HKCR; Subkey: "Gregorio"; ValueType: string; ValueName: ""; ValueData: "Gregorio score"; Flags: uninsdeletekey
Root: HKCR; Subkey: "Gregorio\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\gregorio.ico"; Flags: uninsdeletekey
Root: HKCR; Subkey: "Gregorio\shell\open\command"; ValueType: string; ValueName: ""; ValueData: "texworks.exe ""%1"""; Flags: uninsdeletekey

[Dirs]
Name: "{app}\bin"
Name: "{app}\contrib"
Name: "{app}\examples"
Name: "{app}\texmf"
Name: "{app}\texmf\tex"
Name: "{app}\texmf\tex\luatex"
Name: "{app}\texmf\tex\luatex\gregoriotex"
Name: "{app}\texmf\tex\lualatex"
Name: "{app}\texmf\tex\lualatex\gregoriotex"
Name: "{app}\texmf\fonts"
Name: "{app}\texmf\fonts\truetype"
Name: "{app}\texmf\fonts\truetype\public"
Name: "{app}\texmf\fonts\truetype\public\gregoriotex"
Name: "{app}\texmf\fonts\source"
Name: "{app}\texmf\fonts\source\gregoriotex"
Name: "{app}\texmf\doc"
Name: "{app}\texmf\doc\luatex"
Name: "{app}\texmf\doc\luatex\gregoriotex"
Name: "{app}\texmf\doc\luatex\gregoriotex\examples"

[Files]
; PARSE_VERSION_FILE_NEXTLINE
Source: "../src/gregorio-6_1_0.exe"; DestDir: "{app}\bin";
Source: "gregorio.ico"; DestDir: "{app}";
Source: "install.lua"; DestDir: "{app}";
Source: "uninstall.lua"; DestDir: "{app}";
Source: "README.txt"; DestDir: "{app}"; Flags: isreadme
Source: "../CHANGELOG.md"; DestDir: "{app}";
Source: "../README.md"; DestDir: "{app}";
Source: "../CONTRIBUTORS.md"; DestDir: "{app}";
Source: "../UPGRADE.md"; DestDir: "{app}";
Source: "../doc/*.pdf"; DestDir: "{app}";
Source: "../doc/*.pdf"; DestDir: "{app}\texmf\doc\luatex\gregoriotex";
Source: "../COPYING.md"; DestDir: "{app}";
Source: "../contrib/system-setup.bat"; DestDir: "{app}";
Source: "../contrib/*"; DestDir: "{app}\contrib"; Excludes: "Makefile*,TeXShop\*,*.command";
Source: "../examples/*.gabc"; DestDir: "{app}\examples";
Source: "../examples/*.gabc"; DestDir: "{app}\texmf\doc\luatex\gregoriotex\examples";
Source: "../examples/*.tex"; DestDir: "{app}\examples";
Source: "../examples/*.tex"; DestDir: "{app}\texmf\doc\luatex\gregoriotex\examples";
Source: "../tex/*.tex"; DestDir: "{app}\texmf\tex\luatex\gregoriotex";
Source: "../tex/*.sty"; DestDir: "{app}\texmf\tex\lualatex\gregoriotex";
Source: "../tex/*.lua"; DestDir: "{app}\texmf\tex\luatex\gregoriotex";
Source: "../tex/gregorio-vowels.dat"; DestDir: "{app}\texmf\tex\luatex\gregoriotex";
Source: "../fonts/greciliae*.ttf"; DestDir: "{app}\texmf\fonts\truetype\public\gregoriotex";
Source: "../fonts/greextra.ttf"; DestDir: "{app}\texmf\fonts\truetype\public\gregoriotex";
Source: "../fonts/gregall.ttf"; DestDir: "{app}\texmf\fonts\truetype\public\gregoriotex";
Source: "../fonts/grelaon.ttf"; DestDir: "{app}\texmf\fonts\truetype\public\gregoriotex";
Source: "../fonts/gresgmodern.ttf"; DestDir: "{app}\texmf\fonts\truetype\public\gregoriotex";
Source: "../fonts/greciliae-base.sfd"; DestDir: "{app}\texmf\fonts\source\gregoriotex";
Source: "../fonts/greextra.sfd"; DestDir: "{app}\texmf\fonts\source\gregoriotex";
Source: "../fonts/gregall.sfd"; DestDir: "{app}\texmf\fonts\source\gregoriotex";
Source: "../fonts/grelaon.sfd"; DestDir: "{app}\texmf\fonts\source\gregoriotex";
Source: "../fonts/gresgmodern.sfd"; DestDir: "{app}\texmf\fonts\source\gregoriotex";
Source: "../fonts/*.py"; DestDir: "{app}\texmf\fonts\source\gregoriotex";
Source: "../fonts/fonts_README.md"; DestDir: "{app}\texmf\fonts\source\gregoriotex";
Source: "../doc/*.tex"; DestDir: "{app}\texmf\doc\luatex\gregoriotex";
Source: "../doc/*.lua"; DestDir: "{app}\texmf\doc\luatex\gregoriotex";
Source: "../doc/*.gabc"; DestDir: "{app}\texmf\doc\luatex\gregoriotex";
Source: "../doc/doc_README.md"; DestDir: "{app}\texmf\doc\luatex\gregoriotex";

[InstallDelete]
Type: files; Name: "{app}\gregorio.exe"

[Run]
Filename: "texlua.exe"; Parameters: """{app}\install.lua"" > ""{app}\install.log"""; StatusMsg: "Adding files to texmf tree..."; Description: "Add files to texmf tree"; Flags: postinstall runascurrentuser ; WorkingDir: "{app}"

[UninstallRun]
Filename: "texlua.exe"; Parameters: """{app}\uninstall.lua"" > ""{userdesktop}\uninstall.log"""; WorkingDir: "{app}"; RunOnceId: "Remove_texmf"; Flags: runascurrentuser

[Tasks]
Name: modifypath; Description: "Add gregorio to PATH"; GroupDescription: "New Installs and Upgrades from 4.0 and earlier"; Flags: checkedonce

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
  StaticText.Caption := 'The best way to install LuaTeX is to install the TeX Live distribution.';
  StaticText.Parent := Page.Surface;

  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(75);;
  StaticText.Caption := 'If you have not already installed it, please do it before proceeding further!';
  StaticText.Parent := Page.Surface;

  StaticText := TNewStaticText.Create(Page);
  StaticText.Top := ScaleY(100);;
  StaticText.Caption := 'Note that you have to reboot your computer after having installed TeX Live';
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

const
    ModPathName = 'modifypath';
    ModPathType = 'system';

function ModPathDir(): TArrayOfString;
begin
    setArrayLength(Result, 1)
    Result[0] := ExpandConstant('{app}\bin');
end;
#include "modpath.iss"
