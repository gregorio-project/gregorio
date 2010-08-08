[Setup]
AppName=La vieille Lulu
AppVersion=1.1
DefaultDirName={pf}\Gregorio
DefaultGroupName=My Program
UninstallDisplayIcon={app}\MyProg.exe
Compression=lzma2
SolidCompression=yes
LicenseFile=license.txt

[Dirs]
Name: "{app}\fonts"
Name: "{app}\tex"
Name: "{app}\contrib"

[Files]
Source: "gregorio.exe"; DestDir: "{app}";
Source: "install.lua"; DestDir: "{app}";
Source: "license.txt"; DestDir: "{app}";
Source: "fonts\*"; DestDir: "{app}\fonts";
Source: "contrib\*"; DestDir: "{app}\contrib";
Source: "tex\*"; DestDir: "{app}\tex";

[Run]
Filename: "texlua.exe"; Parameters: """{app}\install.lua"""; StatusMsg: "Installing Fonts..."; Description: "Font installation"; Flags: postinstall; WorkingDir: "{app}";
Filename: "updmap-sys.exe"; Parameters: "--enable MixedMap=gresym.map"; StatusMsg: "Installing Fonts..."; Flags: postinstall; WorkingDir: "{app}";
Filename: "updmap-sys.exe"; Parameters: "--enable MixedMap=greextra.map"; StatusMsg: "Installing Fonts..."; Flags: postinstall; WorkingDir: "{app}";
Filename: "updmap-sys.exe"; Parameters: "--enable MixedMap=greciliae.map"; StatusMsg: "Installing Fonts..."; Flags: postinstall; WorkingDir: "{app}";
Filename: "updmap-sys.exe"; Parameters: "--enable MixedMap=gregorio.map"; StatusMsg: "Installing Fonts..."; Flags: postinstall; WorkingDir: "{app}";
Filename: "updmap-sys.exe"; Parameters: "--enable MixedMap=parmesan.map"; StatusMsg: "Installing Fonts..."; Flags: postinstall; WorkingDir: "{app}";
Filename: "updmap.exe"; Parameters: "--enable MixedMap=gresym.map"; StatusMsg: "Installing Fonts..."; Flags: postinstall; WorkingDir: "{app}";
Filename: "updmap.exe"; Parameters: "--enable MixedMap=greextra.map"; StatusMsg: "Installing Fonts..."; Flags: postinstall; WorkingDir: "{app}";
Filename: "updmap.exe"; Parameters: "--enable MixedMap=greciliae.map"; StatusMsg: "Installing Fonts..."; Flags: postinstall; WorkingDir: "{app}";
Filename: "updmap.exe"; Parameters: "--enable MixedMap=gregorio.map"; StatusMsg: "Installing Fonts..."; Flags: postinstall; WorkingDir: "{app}";
Filename: "updmap.exe"; Parameters: "--enable MixedMap=parmesan.map"; StatusMsg: "Installing Fonts..."; Flags: postinstall; WorkingDir: "{app}";
