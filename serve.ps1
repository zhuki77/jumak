$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:8780/")
$listener.Start()
try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    try {
      $path = $ctx.Request.Url.LocalPath
      if ($path -eq "/") { $path = "/index.html" }
      $rel = [Uri]::UnescapeDataString($path.TrimStart("/")) -replace "/", [IO.Path]::DirectorySeparatorChar
      $file = Join-Path $root $rel
      $rootFull = [IO.Path]::GetFullPath($root)
      $fileFull = [IO.Path]::GetFullPath($file)
      if ($fileFull.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $fileFull -PathType Leaf)) {
        $bytes = [IO.File]::ReadAllBytes($fileFull)
        $ext = [IO.Path]::GetExtension($fileFull).ToLowerInvariant()
        $type = switch ($ext) {
          ".html" { "text/html; charset=utf-8" }
          ".css" { "text/css; charset=utf-8" }
          ".js" { "text/javascript; charset=utf-8" }
          default { "application/octet-stream" }
        }
        $ctx.Response.StatusCode = 200
        $ctx.Response.ContentType = $type
        $ctx.Response.Headers.Add("Cache-Control", "no-store")
        $ctx.Response.ContentLength64 = $bytes.Length
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
      } else {
        $ctx.Response.StatusCode = 404
      }
    } catch {
      try { $ctx.Response.StatusCode = 500 } catch {}
    } finally {
      try { $ctx.Response.Close() } catch {}
    }
  }
} finally {
  if ($listener.IsListening) { $listener.Stop() }
}
