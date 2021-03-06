@ECHO OFF
POWERSHELL.EXE -command "Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
CLS
ECHO xWSL for Ubuntu 18.04 // Daniel Milisic - dmilisic@desktopecho.com
ECHO.
SET "DISTRO=xWSL" 
SET "RDPPRT=3388"
SET "SSHPRT=3322"
SET /p DISTRO=Enter a unique name for the distro or hit Enter to use default [xWSL]: 
SET /p RDPPRT=Enter port number for xRDP traffic or hit Enter to use default [3388]: 
SET /p SSHPRT=Enter port number for SSHd traffic or hit Enter to use default [3322]: 
REM Quit on Name Collision
IF EXIST %DISTRO% EXIT
FOR /F "skip=2 tokens=2,*" %%A IN ('reg.exe query "HKLM\Software\Microsoft\Windows NT\CurrentVersion" /v "InstallationType"') DO set "HazCore=%%B"
IF "%HazCore%"=="Server Core" (ECHO Server Core / Hyper-V Server Detected, installing pre-requisites...)
IF "%HazCore%"=="Server Core" (POWERSHELL.EXE -Command "wget https://aka.ms/vs/16/release/vc_redist.x64.exe -UseBasicParsing -OutFile %TEMP%\vc_redist.x64.exe ; %TEMP%\vc_redist.x64.exe /install /quiet")
SET DISTROFULL=%CD%\%DISTRO%
ECHO xWSL (%DISTRO%) To be installed in: %DISTROFULL%
ECHO Downloading Ubuntu 18.04 for WSL from Microsoft...
REM If We already have the distro don't waste time grabbing it again
IF NOT EXIST %TEMP%\Ubuntu1804.zip POWERSHELL.EXE -Command "wget https://aka.ms/wsl-ubuntu-1804 -UseBasicParsing -OutFile %TEMP%\Ubuntu1804.zip"
REM But always refresh xWSLres from GitHub
IF EXIST %TEMP%\xWSLres.zip DEL %TEMP%\xWSLres.zip
POWERSHELL.EXE -Command "wget https://raw.githubusercontent.com/DesktopECHO/xWSL/master/xWSLres.zip -UseBasicParsing -OutFile %TEMP%\xWSLres.zip"
POWERSHELL.EXE -command "Expand-Archive %TEMP%\Ubuntu1804.zip -DestinationPath %DISTRO%"
POWERSHELL.EXE -command "Expand-Archive %TEMP%\xWSLres.zip    -DestinationPath %DISTRO%\xWSLres"
NETSH AdvFirewall Firewall add rule name="XRDP Port %RDPPRT% for WSL" dir=in action=allow protocol=TCP localport=%RDPPRT%
NETSH AdvFirewall Firewall add rule name="SSHd Port %SSHPRT% for WSL" dir=in action=allow protocol=TCP localport=%SSHPRT%
REM Install Distro with LxRunOffline -- https://github.com/DDoSolitary/LxRunOffline
CD %DISTRO%
xWSLres\LxRunOffline.exe install -n %DISTRO% -d . -f install.tar.gz
REM Register Distro
xWSLres\LxRunOffline.exe sd -n %DISTRO%
REM Work-around WSL DNS Resolution Failure Issue
CD xWSLres
WSL rm -f /etc/resolv.conf ; cp resolv.conf /etc/resolv.conf ; chmod 444 /etc/resolv.conf ; ssh-keygen -A ; cp environment /etc/environment
REM Pull in Seamonkey as default browser, WSL Not playing nicely with Chrome or FireFox
WSL cp mozilla.list /etc/apt/sources.list.d/mozilla.list ; apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2667CA5C 
REM Pull in PPA's
WSL add-apt-repository -y ppa:xubuntu-dev/staging ; add-apt-repository -y ppa:mark-pcnetspec/gksu ; apt-add-repository -y ppa:remmina-ppa-team/remmina-next ; add-apt-repository -y ppa:system76/pop ; add-apt-repository -y ppa:xubuntu-dev/ppa ; apt update
WSL DEBIAN_FRONTEND=noninteractive apt-get -y remove --allow-remove-essential apparmor plymouth plymouth-theme-ubuntu-text cloud-init cloud-initramfs-copymods cloud-initramfs-dyn-netconf friendly-recovery initramfs-tools initramfs-tools-core libnss-systemd libpam-systemd mdadm netplan.io nplan open-iscsi overlayroot policykit-1 snapd ubuntu-minimal ubuntu-server ubuntu-standard libfreetype6
WSL DEBIAN_FRONTEND=noninteractive apt -y install ./xrdp_0.9.9-1-xWSL_amd64.deb -o APT::Install-Suggests=0 -o APT::Install-Recommends=0
WSL apt -y install eog eog-plugins gksu xorg xorgxrdp pulseaudio imagemagick cgroup-lite zip libnotify-bin at-spi2-core wslu xfce4 xfce4-panel xfce4-terminal thunar dbus-x11 libgtk-3-bin mousepad thunar-volman xfce4-notifyd thunar-archive-plugin remmina-common remmina-plugin-exec remmina-plugin-rdp remmina-plugin-secret remmina-plugin-vnc remmina-plugin-www filezilla seamonkey pop-theme p7zip-full unzip pavucontrol pavumeter xarchiver xdg-utils libept1.5.0 -o APT::Install-Suggests=0 -o APT::Install-Recommends=0
REM This version of Synaptic works well and prevents a crap-ton of dependancies from getting pulled in due to PolicyKit/systemd:
WSL dpkg -i libxapian22v5_1.2.22-2-xWSL_amd64.deb
WSL dpkg -i synaptic_0.83-xWSL_amd64.deb
WSL apt-mark hold synaptic
WSL rm -rf /etc/skel ; cp skel.tar /etc ; cd /etc ; tar xf skel.tar ; chown -R root:root /etc/skel ; chmod -R 755 /etc/skel
REM Ugly but effective replacement of pkexec with gksu, hey at least Synaptic is able to elevate properly  
WSL ln -s /usr/bin/gksu /usr/bin/pkexec 
WSL ln -s /usr/bin/xfce4-session /usr/bin/xterm
WSL ln -s /mnt/c/Windows/Fonts /usr/share/fonts/truetype/microsoft
REM Get some init system action going...
WSL cp initWSL /usr/local/bin/initWSL ; chown root:root /usr/local/bin/initWSL ; chmod 755 /usr/local/bin/initWSL
REM Custom xrdp config
WSL cp xrdp.ini /etc/xrdp/xrdp.ini ; cp sesman.ini /etc/xrdp/sesman.ini ; cp xWSL.png /usr/share/pixmaps ; cp xrdp_logo.bmp /usr/share/xrdp/
REM Get rid of a bunch of useless bits taking up space
WSL rm -rf /usr/share/themes/Xfce* ; rm -rf /usr/share/themes/ZOMG* ; rm -rf /usr/share/themes/R* ; rm -rf /usr/share/icons/Humanity*
WSL sed -i 's/3388/%RDPPRT%/g' /etc/xrdp/xrdp.ini
WSL sed -i 's/#Port 22/Port %SSHPRT%/g' /etc/ssh/sshd_config
WSL sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
WSL mkdir /var/lib/xrdp-pulseaudio-installer ; cp ./module-xrdp-* /var/lib/xrdp-pulseaudio-installer/
WSL rm -rf /etc/rc2.d/S01console-setup.sh 
set /p xu=Enter name of xWSL user: 
bash -c "useradd -m -p nulltemp -s /bin/bash %xu%"
powershell -Command $pword = read-host "Enter password" -AsSecureString ; $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pword) ; [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) > .tmp.txt & set /p password=<.tmp.txt & del .tmp.txt
bash -c "echo %xu%:%password% | chpasswd"
bash -c "echo '%xu% ALL=(ALL:ALL) ALL' >> /etc/sudoers"
for /f "delims=" %%n in ('whoami') do set NAME=%%n
ECHO Creating Scheduled Task for InitSystem and PulseAudio
SCHtasks /create /RU %USERNAME% /RL HIGHEST /SC ONSTART /TN %DISTRO%-InitSystem /TR "%DISTROFULL%\xWSLres\LxRunOffline.exe run -w -n %DISTRO% -c 'initWSL 2'"
SCHtasks /create /RU %USERNAME% /RL HIGHEST /SC ONSTART /TN %DISTRO%-PulseAudio /TR "%DISTROFULL%\xWSLres\xWSLpa.exe"
CD ..
ECHO @SCHtasks /run /TN %DISTRO%-InitSystem > %DISTRO%.CMD
ECHO @SCHtasks /run /TN %DISTRO%-PulseAudio >> %DISTRO%.CMD
START /MIN %DISTRO%.CMD
START /WAIT /MIN "Bad Wait Loop" "PING" "-n" 7 "127.0.0.1"
%DISTROFULL%\xWSLres\WFreeRDP.exe /bpp:24 /h:600 /w:1000 /v:LOCALHOST:%RDPPRT% /u:%xu% /p:%password%
