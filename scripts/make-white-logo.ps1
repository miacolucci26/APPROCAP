Add-Type -AssemblyName System.Drawing

$srcPath = "C:\Users\looez\OneDrive\Desktop\approcap\assets\img\logo-approcap.png"
$outPath = "C:\Users\looez\OneDrive\Desktop\approcap\assets\img\logo-approcap-white.png"

$src = New-Object System.Drawing.Bitmap $srcPath
$w = $src.Width; $h = $src.Height
$out = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

# Lock bits for fast pixel access instead of GetPixel/SetPixel (very slow per-pixel in .NET).
$srcRect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
$srcData = $src.LockBits($srcRect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$outData = $out.LockBits($srcRect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

$bytes = $w * $h * 4
$srcBuffer = New-Object byte[] $bytes
[System.Runtime.InteropServices.Marshal]::Copy($srcData.Scan0, $srcBuffer, 0, $bytes)
$outBuffer = New-Object byte[] $bytes

$whiteThreshold = 250
for ($i = 0; $i -lt $bytes; $i += 4) {
    $b = $srcBuffer[$i]
    $g = $srcBuffer[$i + 1]
    $r = $srcBuffer[$i + 2]
    if ($b -ge $whiteThreshold -and $g -ge $whiteThreshold -and $r -ge $whiteThreshold) {
        # Background (white) -> fully transparent
        $outBuffer[$i] = 255; $outBuffer[$i+1] = 255; $outBuffer[$i+2] = 255; $outBuffer[$i+3] = 0
    } else {
        # Logo shape -> solid white silhouette
        $outBuffer[$i] = 255; $outBuffer[$i+1] = 255; $outBuffer[$i+2] = 255; $outBuffer[$i+3] = 255
    }
}

[System.Runtime.InteropServices.Marshal]::Copy($outBuffer, 0, $outData.Scan0, $bytes)
$src.UnlockBits($srcData)
$out.UnlockBits($outData)

$out.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$src.Dispose(); $out.Dispose()
Write-Output "Saved: $outPath ($w x $h)"
