function Get-Luminance($hex) {
    $hex = $hex.TrimStart('#')
    $r = [Convert]::ToInt32($hex.Substring(0,2),16) / 255.0
    $g = [Convert]::ToInt32($hex.Substring(2,2),16) / 255.0
    $b = [Convert]::ToInt32($hex.Substring(4,2),16) / 255.0
    $f = { param($c) if ($c -le 0.03928) { $c/12.92 } else { [math]::Pow((($c+0.055)/1.055), 2.4) } }
    $r2 = & $f $r; $g2 = & $f $g; $b2 = & $f $b
    return 0.2126*$r2 + 0.7152*$g2 + 0.0722*$b2
}

function Get-Contrast($hex1, $hex2) {
    $l1 = Get-Luminance $hex1
    $l2 = Get-Luminance $hex2
    $lighter = [math]::Max($l1,$l2); $darker = [math]::Min($l1,$l2)
    return [math]::Round(($lighter + 0.05) / ($darker + 0.05), 2)
}

function Blend($fgHex, $bgHex, $alpha) {
    $fg = $fgHex.TrimStart('#'); $bg = $bgHex.TrimStart('#')
    $fr=[Convert]::ToInt32($fg.Substring(0,2),16); $fgc=[Convert]::ToInt32($fg.Substring(2,2),16); $fb=[Convert]::ToInt32($fg.Substring(4,2),16)
    $br=[Convert]::ToInt32($bg.Substring(0,2),16); $bgc=[Convert]::ToInt32($bg.Substring(2,2),16); $bb=[Convert]::ToInt32($bg.Substring(4,2),16)
    $r = [math]::Round($fr*$alpha + $br*(1-$alpha))
    $g = [math]::Round($fgc*$alpha + $bgc*(1-$alpha))
    $b = [math]::Round($fb*$alpha + $bb*(1-$alpha))
    return "#{0:x2}{1:x2}{2:x2}" -f [int]$r, [int]$g, [int]$b
}

Write-Output "=== Pares de color reales del sitio ==="
$pairs = @(
    @{name="Texto primario (#24312B) sobre blanco";        fg="#24312B"; bg="#FFFFFF"; min=4.5},
    @{name="Texto muted (#5B6961) sobre blanco";            fg="#5B6961"; bg="#FFFFFF"; min=4.5},
    @{name="Encabezados verde (#004F2D) sobre blanco (texto grande)"; fg="#004F2D"; bg="#FFFFFF"; min=3.0},
    @{name="Enlace azul (#0089D0) sobre blanco [actual .btn a]";     fg="#0089D0"; bg="#FFFFFF"; min=4.5},
    @{name="Texto blanco sobre verde primario (#004F2D)";   fg="#FFFFFF"; bg="#004F2D"; min=4.5},
    @{name="Texto ink (#142018) sobre amarillo accent (#FFEB00) [btn-primary]"; fg="#142018"; bg="#FFEB00"; min=4.5},
    @{name="Texto verde (#004F2D) sobre verde-agua tint (#EAF3EE) [tag]";       fg="#004F2D"; bg="#EAF3EE"; min=4.5},
    @{name="Muted (#5B6961) sobre tint alterno (#F5F7F3)";  fg="#5B6961"; bg="#F5F7F3"; min=4.5}
)
foreach ($p in $pairs) {
    $ratio = Get-Contrast $p.fg $p.bg
    $pass = if ($ratio -ge $p.min) { "PASA" } else { "FALLA" }
    Write-Output ("{0,-70} ratio={1,-6} min={2}  {3}" -f $p.name, $ratio, $p.min, $pass)
}

Write-Output ""
Write-Output "=== Texto semitransparente sobre footer (#142018) ==="
$footerPairs = @(
    @{name="rgba(255,255,255,0.82) sobre #142018 [texto footer]"; alpha=0.82},
    @{name="rgba(255,255,255,0.55) sobre #142018 [footer-bottom]"; alpha=0.55}
)
foreach ($fp in $footerPairs) {
    $blended = Blend "#FFFFFF" "#142018" $fp.alpha
    $ratio = Get-Contrast $blended "#142018"
    $pass = if ($ratio -ge 4.5) { "PASA" } else { "FALLA" }
    Write-Output ("{0,-55} color efectivo={1}  ratio={2,-6} min=4.5  {3}" -f $fp.name, $blended, $ratio, $pass)
}

Write-Output ""
Write-Output "=== Candidatos para un azul de enlace accesible sobre blanco ==="
foreach ($hex in @("#0089D0","#0077B6","#006999","#005C86","#004F73")) {
    $ratio = Get-Contrast $hex "#FFFFFF"
    $pass = if ($ratio -ge 4.5) { "PASA" } else { "FALLA" }
    Write-Output ("{0}  ratio={1,-6} {2}" -f $hex, $ratio, $pass)
}
