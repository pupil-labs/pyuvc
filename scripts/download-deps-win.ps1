param ($DEPS_TMP_PATH)
if ($DEPS_TMP_PATH -eq $null) {
    Write-Error "DEPS_TMP_PATH param not set"
    Exit -1
}

rm _skbuild -Recurse -Confirm:$false

choco install vcredist-all

# libturbojpeg
Set-Variable -Name "LTJ_VERSION" -Value "2.1.0"
Set-Variable -Name "LTJ_URL" -Value "https://github.com/pupil-labs/pyndsi/wiki/libjpeg-turbo-${LTJ_VERSION}-vc64.exe"
Set-Variable -Name "LTJ_INSTALLER" -Value "${DEPS_TMP_PATH}\libjpeg-turbo.exe"
Set-Variable -Name "LTJ_INSTALL_PATH" -Value "${DEPS_TMP_PATH}\libjpeg-turbo-install"

[System.IO.Directory]::CreateDirectory(${LTJ_INSTALL_PATH})
Write-Output "Downloading libturbojpeg..."
Invoke-WebRequest -Uri ${LTJ_URL} -OutFile ${LTJ_INSTALLER}
Write-Output "Installing libturbojpeg..."
& 'C:\Program Files\7-Zip\7z.exe' x -aoa ${LTJ_INSTALLER} -o"${LTJ_INSTALL_PATH}"

Set-Variable -Name "LUSB_VERSION" -Value "1.0.26"
Set-Variable -Name "LUSB_BIN_URL" -Value "https://github.com/libusb/libusb/releases/download/v${LUSB_VERSION}/libusb-${LUSB_VERSION}-binaries.7z"
Set-Variable -Name "LUSB_SRC_URL" -Value "https://github.com/libusb/libusb/releases/download/v${LUSB_VERSION}/libusb-${LUSB_VERSION}.tar.bz2"

Set-Variable -Name "LUSB_BIN_ARCHIVE" -Value "${DEPS_TMP_PATH}\libusb-bin-archive.7z"
Set-Variable -Name "LUSB_SRC_ARCHIVE_TAR_BZ2" -Value "${DEPS_TMP_PATH}\libusb-src-archive.tar.bz2"
Set-Variable -Name "LUSB_SRC_ARCHIVE_TAR" -Value "${DEPS_TMP_PATH}\libusb-src-archive.tar"
Set-Variable -Name "LUSB_INSTALL_PATH" -Value "${DEPS_TMP_PATH}\libusb-install"

Write-Output "Downloading libusb... ${LUSB_BIN_URL}"
Invoke-WebRequest -Uri ${LUSB_BIN_URL} -OutFile ${LUSB_BIN_ARCHIVE}
Write-Output "Downloading libusb... ${LUSB_SRC_URL}"
Invoke-WebRequest -Uri ${LUSB_SRC_URL} -OutFile ${LUSB_SRC_ARCHIVE_TAR_BZ2}

Write-Output "Extracting libusb..."
& 'C:\Program Files\7-Zip\7z.exe' x -aoa ${LUSB_BIN_ARCHIVE} -o"${LUSB_INSTALL_PATH}"
& 'C:\Program Files\7-Zip\7z.exe' x -aoa ${LUSB_SRC_ARCHIVE_TAR_BZ2} -o"${DEPS_TMP_PATH}"
& 'C:\Program Files\7-Zip\7z.exe' x -aoa ${LUSB_SRC_ARCHIVE_TAR} -o"${LUSB_INSTALL_PATH}"

$dep_paths = @{
    LIBUSB_WIN_IMPORT_LIB_PATH    = "${LUSB_INSTALL_PATH}/libusb-${LUSB_VERSION}-binaries/VS2015-x64/dll/libusb-1.0.lib"
    LIBUSB_WIN_DLL_SEARCH_PATH    = "${LUSB_INSTALL_PATH}/libusb-${LUSB_VERSION}-binaries/VS2015-x64/dll"
    LIBUSB_WIN_INCLUDE_DIR        = "${LUSB_INSTALL_PATH}/libusb-${LUSB_VERSION}/libusb"
    TURBOJPEG_WIN_IMPORT_LIB_PATH = "${LTJ_INSTALL_PATH}/lib/turbojpeg.lib"
    TURBOJPEG_WIN_DLL_SEARCH_PATH = "${LTJ_INSTALL_PATH}/bin"
    TURBOJPEG_WIN_INCLUDE_DIR     = "${LTJ_INSTALL_PATH}/include"
}

$dep_paths_json = $dep_paths | ConvertTo-Json
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines("${DEPS_TMP_PATH}\dep_paths.json", $dep_paths_json, $Utf8NoBomEncoding)
