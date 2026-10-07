$rate = 22050; $bar = 2.4
$chords = @{
  A  = 110,220,277.18,329.63
  E  = 82.41,164.81,246.94,329.63,415.30
  Bm = 123.47,185.00,246.94,293.66,369.99
  D  = 146.83,220,293.66,369.99
}
$cache = @{}
foreach ($k in $chords.Keys) {
  $n = [int]($rate * $bar)
  $buf = New-Object byte[] ($n * 2)
  for ($i = 0; $i -lt $n; $i++) {
    $t = $i / $rate
    $s = 0.0
    foreach ($f in $chords[$k]) { $s += [math]::Sin(2 * [math]::PI * $f * $t) }
    $e = [math]::Exp(-0.9 * $t) * [math]::Min(1, $t * 200) * [math]::Min(1, ($bar - $t) * 50)
    $v = [int](($s / $chords[$k].Count) * $e * 20000)
    $buf[2*$i]   = [byte]($v -band 0xFF)
    $buf[2*$i+1] = [byte](($v -shr 8) -band 0xFF)
  }
  $cache[$k] = $buf
}

$L  = 'A','E','Bm'
$LD = 'A','E','Bm','D'
$V1 = $L * 8
$V2 = $L * 4
$CH = $L + $L + $LD + $L
$seq = ($L * 2) + $V1 + $CH + $CH + $V2 + $CH + $CH + ($L * 2)

$path = Join-Path $env:TEMP "fade.wav"
$dataLen = $seq.Count * $cache['A'].Length
$fs = [IO.File]::Create($path)
$w = New-Object IO.BinaryWriter($fs)
$w.Write([Text.Encoding]::ASCII.GetBytes("RIFF"))
$w.Write([int](36 + $dataLen))
$w.Write([Text.Encoding]::ASCII.GetBytes("WAVEfmt "))
$w.Write([int]16)
$w.Write([int16]1)
$w.Write([int16]1)
$w.Write([int]$rate)
$w.Write([int]($rate * 2))
$w.Write([int16]2)
$w.Write([int16]16)
$w.Write([Text.Encoding]::ASCII.GetBytes("data"))
$w.Write([int]$dataLen)
foreach ($c in $seq) { $w.Write($cache[$c]) }
$w.Close()

(New-Object Media.SoundPlayer $path).PlaySync()