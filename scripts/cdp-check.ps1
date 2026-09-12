param(
  [string]$UrlPath = "index.html",
  [int]$Width = 1440,
  [int]$Height = 1000,
  [switch]$Mobile,
  [string]$ScreenshotOut = $null,
  [switch]$Click,
  [string]$ClickSelector = "",
  [string]$EvalAfter = "",
  [string]$PressKeyAfter = "",
  [string]$RealClickSelector = ""
)

$port = Get-Random -Minimum 9300 -Maximum 9700
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$profileDir = "$env:TEMP\cdp-profile-$port"

$proc = Start-Process -FilePath $chrome -ArgumentList @(
  "--headless=new","--disable-gpu","--no-sandbox",
  "--remote-debugging-port=$port","--remote-debugging-address=127.0.0.1","--user-data-dir=$profileDir"
) -PassThru -WindowStyle Hidden

try {
  # Wait for the debugger endpoint to come up (use 127.0.0.1, not localhost:
  # on this machine "localhost" can resolve to ::1 first and time out even
  # though Chrome is already listening on 127.0.0.1).
  $ready = $false
  for ($i=0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 300
    try {
      $r = Invoke-WebRequest -Uri "http://127.0.0.1:$port/json/version" -UseBasicParsing -TimeoutSec 1
      if ($r.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "No se pudo conectar al puerto de depuración $port" }

  $newTab = Invoke-RestMethod -Uri "http://127.0.0.1:$port/json/new?about:blank" -Method PUT -TimeoutSec 5
  $wsUrl = $newTab.webSocketDebuggerUrl

  $ws = New-Object System.Net.WebSockets.ClientWebSocket
  $cts = New-Object System.Threading.CancellationTokenSource
  $ws.ConnectAsync($wsUrl, $cts.Token).GetAwaiter().GetResult() | Out-Null

  $script:msgId = 0
  $consoleEvents = New-Object System.Collections.Generic.List[string]
  $script:pendingResults = @{}

  function Send-CDP($method, $params) {
    $script:msgId++
    $id = $script:msgId
    $obj = @{ id = $id; method = $method; params = $params }
    $json = $obj | ConvertTo-Json -Depth 10 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $seg = New-Object System.ArraySegment[byte] (,$bytes)
    $ws.SendAsync($seg, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).GetAwaiter().GetResult() | Out-Null
    return $id
  }

  function Read-OneMessage([int]$timeoutMs = 15000) {
    # A single logical WebSocket text message can arrive split across
    # several frames/ReceiveAsync calls; keep reading until EndOfMessage.
    $ms = New-Object System.IO.MemoryStream
    $buffer = New-Object byte[] 65536
    $deadline = (Get-Date).AddMilliseconds($timeoutMs)
    while ($true) {
      $remaining = [int](($deadline - (Get-Date)).TotalMilliseconds)
      if ($remaining -le 0) { return $null }
      $seg = New-Object System.ArraySegment[byte] (,$buffer)
      $task = $ws.ReceiveAsync($seg, $cts.Token)
      if (-not $task.Wait($remaining)) { return $null }
      $result = $task.Result
      $ms.Write($buffer, 0, $result.Count)
      if ($result.EndOfMessage) { break }
    }
    return [System.Text.Encoding]::UTF8.GetString($ms.ToArray())
  }

  function Wait-ForEvent($methodName, [int]$timeoutMs = 15000) {
    $deadline = (Get-Date).AddMilliseconds($timeoutMs)
    while ((Get-Date) -lt $deadline) {
      $remaining = [int](($deadline - (Get-Date)).TotalMilliseconds)
      if ($remaining -le 0) { break }
      $msg = Read-OneMessage -timeoutMs $remaining
      if ($null -eq $msg) { break }
      try { $o = $msg | ConvertFrom-Json -ErrorAction Stop } catch { continue }
      if ($o.method -eq "Runtime.consoleAPICalled") {
        $args = ($o.params.args | ForEach-Object { $_.value } ) -join " "
        $consoleEvents.Add("[console.$($o.params.type)] $args")
      } elseif ($o.method -eq "Runtime.exceptionThrown") {
        $desc = $o.params.exceptionDetails.exception.description
        if (-not $desc) { $desc = $o.params.exceptionDetails.text }
        $consoleEvents.Add("[exception] $desc")
      } elseif ($o.method -eq "Log.entryAdded") {
        $consoleEvents.Add("[log.$($o.params.entry.level)] $($o.params.entry.text)")
      } elseif ($o.method -eq "Network.responseReceived") {
        if ($o.params.response.status -ge 400) {
          $consoleEvents.Add("[http $($o.params.response.status)] $($o.params.response.url)")
        }
      }
      if ($o.method -eq $methodName) { return $o }
    }
    return $null
  }

  function Eval-JS($expression, [int]$timeoutMs = 5000) {
    $id = Send-CDP "Runtime.evaluate" @{ expression = $expression; returnByValue = $true }
    $deadline = (Get-Date).AddMilliseconds($timeoutMs)
    while ((Get-Date) -lt $deadline) {
      $remaining = [int](($deadline - (Get-Date)).TotalMilliseconds)
      if ($remaining -le 0) { break }
      $msg = Read-OneMessage -timeoutMs $remaining
      if ($null -eq $msg) { break }
      try { $o = $msg | ConvertFrom-Json -ErrorAction Stop } catch { continue }
      if ($o.id -eq $id) { return $o.result.result.value }
      if ($o.method -eq "Runtime.consoleAPICalled") {
        $a = ($o.params.args | ForEach-Object { $_.value }) -join " "
        $consoleEvents.Add("[console.$($o.params.type)] $a")
      }
    }
    return $null
  }

  Send-CDP "Runtime.enable" @{} | Out-Null
  Send-CDP "Log.enable" @{} | Out-Null
  Send-CDP "Network.enable" @{} | Out-Null
  Send-CDP "Page.enable" @{} | Out-Null

  Send-CDP "Emulation.setDeviceMetricsOverride" @{
    width = $Width; height = $Height; deviceScaleFactor = 1; mobile = [bool]$Mobile
  } | Out-Null

  Send-CDP "Page.navigate" @{ url = "http://127.0.0.1:8000/$UrlPath" } | Out-Null
  Wait-ForEvent "Page.loadEventFired" 15000 | Out-Null
  Start-Sleep -Milliseconds 800  # let images/fonts settle

  if ($Click -and $ClickSelector -ne "") {
    $expr = "document.querySelector('$ClickSelector').click(); document.querySelector('$ClickSelector').getBoundingClientRect().toJSON ? 'clicked' : 'clicked'"
    Send-CDP "Runtime.evaluate" @{ expression = $expr } | Out-Null
    Start-Sleep -Milliseconds 1500
  }

  if ($RealClickSelector -ne "") {
    # A genuine synthesized pointer click (via the Input domain) goes through
    # the browser's real input pipeline, so focus-on-click behaves exactly
    # like a real user click (unlike element.click() called from JS).
    # behavior:'instant' overrides the page's CSS scroll-behavior:smooth,
    # otherwise the animated scroll may still be in flight when we read
    # coordinates a moment later.
    Eval-JS "document.querySelector('$RealClickSelector').scrollIntoView({block:'center', behavior:'instant'})" | Out-Null
    Start-Sleep -Milliseconds 300
    $rectJson = Eval-JS "JSON.stringify(document.querySelector('$RealClickSelector').getBoundingClientRect())"
    $rect = $rectJson | ConvertFrom-Json
    $cx = [math]::Round($rect.x + $rect.width/2)
    $cy = [math]::Round($rect.y + $rect.height/2)
    Write-Output "REALCLICK_RECT=$rectJson  ->  cx=$cx cy=$cy"
    Send-CDP "Input.dispatchMouseEvent" @{ type="mouseMoved"; x=$cx; y=$cy } | Out-Null
    Send-CDP "Input.dispatchMouseEvent" @{ type="mousePressed"; x=$cx; y=$cy; button="left"; clickCount=1 } | Out-Null
    Send-CDP "Input.dispatchMouseEvent" @{ type="mouseReleased"; x=$cx; y=$cy; button="left"; clickCount=1 } | Out-Null
    Start-Sleep -Milliseconds 800
  }

  # Measure real layout metrics
  $evalId = Send-CDP "Runtime.evaluate" @{
    expression = "JSON.stringify({inner:innerWidth, scrollW:document.documentElement.scrollWidth, bodyScrollW:document.body.scrollWidth})"
    returnByValue = $true
  }
  $metrics = $null
  $deadline = (Get-Date).AddSeconds(5)
  while ((Get-Date) -lt $deadline) {
    $msg = Read-OneMessage -timeoutMs 2000
    if ($null -eq $msg) { break }
    try { $o = $msg | ConvertFrom-Json -ErrorAction Stop } catch { continue }
    if ($o.id -eq $evalId) { $metrics = $o.result.result.value; break }
    if ($o.method -eq "Runtime.consoleAPICalled") {
      $a = ($o.params.args | ForEach-Object { $_.value }) -join " "
      $consoleEvents.Add("[console.$($o.params.type)] $a")
    }
  }

  if ($PressKeyAfter -ne "") {
    $keyMap = @{
      "Escape" = @{ code="Escape"; key="Escape"; windowsVirtualKeyCode=27 }
      "ArrowRight" = @{ code="ArrowRight"; key="ArrowRight"; windowsVirtualKeyCode=39 }
      "ArrowLeft" = @{ code="ArrowLeft"; key="ArrowLeft"; windowsVirtualKeyCode=37 }
      "Tab" = @{ code="Tab"; key="Tab"; windowsVirtualKeyCode=9 }
    }
    $k = $keyMap[$PressKeyAfter]
    Send-CDP "Input.dispatchKeyEvent" @{ type="keyDown"; code=$k.code; key=$k.key; windowsVirtualKeyCode=$k.windowsVirtualKeyCode } | Out-Null
    Send-CDP "Input.dispatchKeyEvent" @{ type="keyUp"; code=$k.code; key=$k.key; windowsVirtualKeyCode=$k.windowsVirtualKeyCode } | Out-Null
    Start-Sleep -Milliseconds 500
  }

  if ($EvalAfter -ne "") {
    $evalId2 = Send-CDP "Runtime.evaluate" @{ expression = $EvalAfter; returnByValue = $true }
    $evalResult = $null
    $deadline3 = (Get-Date).AddSeconds(5)
    while ((Get-Date) -lt $deadline3) {
      $msg = Read-OneMessage -timeoutMs 2000
      if ($null -eq $msg) { break }
      try { $o = $msg | ConvertFrom-Json -ErrorAction Stop } catch { continue }
      if ($o.id -eq $evalId2) { $evalResult = $o.result.result.value; break }
    }
    Write-Output "EVAL_AFTER=$evalResult"
  }

  if ($ScreenshotOut) {
    $shotId = Send-CDP "Page.captureScreenshot" @{ format = "png"; captureBeyondViewport = $false }
    $b64 = $null
    $deadline2 = (Get-Date).AddSeconds(10)
    while ((Get-Date) -lt $deadline2) {
      $msg = Read-OneMessage -timeoutMs 3000
      if ($null -eq $msg) { break }
      try { $o = $msg | ConvertFrom-Json -ErrorAction Stop } catch { continue }
      if ($o.id -eq $shotId) { $b64 = $o.result.data; break }
    }
    if ($b64) {
      [IO.File]::WriteAllBytes($ScreenshotOut, [Convert]::FromBase64String($b64))
    }
  }

  Write-Output "PAGE=$UrlPath WIDTH=$Width MOBILE=$Mobile"
  Write-Output "METRICS=$metrics"
  if ($consoleEvents.Count -eq 0) {
    Write-Output "CONSOLE=none"
  } else {
    foreach ($e in $consoleEvents) { Write-Output "CONSOLE: $e" }
  }

  $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "done", $cts.Token).GetAwaiter().GetResult() | Out-Null
}
finally {
  Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 300
  Remove-Item -Recurse -Force $profileDir -ErrorAction SilentlyContinue
}
