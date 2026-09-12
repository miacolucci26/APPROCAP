Add-Type -AssemblyName System.Drawing

function Save-Resized {
    param(
        [string]$SrcPath,
        [string]$DstPath,
        [int]$MaxEdge,
        [int]$Quality = 82
    )
    $img = [System.Drawing.Image]::FromFile($SrcPath)
    try {
        $w = $img.Width; $h = $img.Height
        $scale = 1.0
        if ($w -ge $h -and $w -gt $MaxEdge) { $scale = $MaxEdge / $w }
        elseif ($h -gt $w -and $h -gt $MaxEdge) { $scale = $MaxEdge / $h }
        $newW = [int]([math]::Round($w * $scale))
        $newH = [int]([math]::Round($h * $scale))

        $bmp = New-Object System.Drawing.Bitmap $newW, $newH
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.DrawImage($img, 0, 0, $newW, $newH)

        $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
        $encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
        $encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, [int64]$Quality)
        $bmp.Save($DstPath, $jpegCodec, $encParams)
        $g.Dispose(); $bmp.Dispose()
        Write-Output "$DstPath : $newW x $newH"
    } finally {
        $img.Dispose()
    }
}

function Save-ResizedPng {
    param([string]$SrcPath, [string]$DstPath, [int]$MaxEdge)
    $img = [System.Drawing.Image]::FromFile($SrcPath)
    try {
        $w = $img.Width; $h = $img.Height
        $scale = 1.0
        if ($w -ge $h -and $w -gt $MaxEdge) { $scale = $MaxEdge / $w }
        elseif ($h -gt $w -and $h -gt $MaxEdge) { $scale = $MaxEdge / $h }
        $newW = [int]([math]::Round($w * $scale))
        $newH = [int]([math]::Round($h * $scale))
        $bmp = New-Object System.Drawing.Bitmap $newW, $newH
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($img, 0, 0, $newW, $newH)
        $bmp.Save($DstPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $g.Dispose(); $bmp.Dispose()
        Write-Output "$DstPath : $newW x $newH"
    } finally { $img.Dispose() }
}

$src = "C:\Users\looez\OneDrive\Desktop\approcap\COOP.APPROCAP"
$img = "C:\Users\looez\OneDrive\Desktop\approcap\assets\img"
$rec = "C:\Users\looez\OneDrive\Desktop\approcap\assets\img\reconocimientos"

# Photographic assets
Save-Resized "$src\imagen.jpg" "$img\hero-productora-cacao-approcap.jpg" 1800 82
Save-Resized "$src\imagen 2.jpg" "$img\premio-cacao-of-excellence-silver-2025.jpg" 1800 82
Save-Resized "$src\712623576_1426618179510439_3489350886145918234_n.jpg" "$img\apertura-mazorca-cacao-blanco.jpg" 1600 82
Save-Resized "$src\WhatsApp Image 2026-09-11 at 10.31.22 AM (3).jpeg" "$img\poscosecha-granos-cacao-etapas.jpg" 1600 82
Save-Resized "$src\WhatsApp Image 2026-09-11 at 10.31.22 AM (2).jpeg" "$img\productos-intensso-mazorcas-flatlay.jpg" 1600 82
Save-Resized "$src\WhatsApp Image 2026-09-11 at 10.31.22 AM (1).jpeg" "$img\linea-productos-intensso-anaqueles.jpg" 1600 82
Save-Resized "$src\WhatsApp Image 2026-09-11 at 10.31.22 AM.jpeg" "$img\stand-intensso-feria.jpg" 1400 82

# Logo
Save-ResizedPng "$src\Logo.png" "$img\logo-approcap.png" 600

# Reconocimientos (certificate photos)
Save-Resized "$src\Certificado 1.jpeg" "$rec\2021-xv-concurso-nacional-cacao-3er-puesto.jpg" 1200 80
Save-Resized "$src\Certificado 2.jpeg" "$rec\2021-xv-concurso-nacional-cacao-9no-puesto.jpg" 1200 80
Save-Resized "$src\Certificado 3.jpeg" "$rec\diploma-mejor-chocolate-alto-piurano-bigote.jpg" 1200 80
Save-Resized "$src\Diploma de honor 1.jpeg" "$rec\diploma-mejor-pasta-cacao-alto-piurano-bigote.jpg" 1200 80
Save-Resized "$src\Certificado 4.jpeg" "$rec\2022-reconocimiento-feria-agropecuaria-lalaquiz.jpg" 1200 80
Save-Resized "$src\certificado 5.jpeg" "$rec\2023-xvii-concurso-nacional-cacao-1er-puesto.jpg" 1200 80
Save-Resized "$src\WhatsApp Image 2026-09-11 at 9.46.46 AM.jpeg" "$rec\2023-ix-concurso-regional-mejor-chocolate-piurano-3er-puesto.jpg" 1200 80
Save-Resized "$src\WhatsApp Image 2026-09-11 at 10.29.50 AM.jpeg" "$rec\2025-cacao-of-excellence-silver-award.jpg" 1200 80
Save-Resized "$src\WhatsApp Image 2026-09-11 at 10.30.54 AM.jpeg" "$rec\2023-avpa-paris-gourmet-3er-puesto.jpg" 1200 80

Write-Output "DONE"
