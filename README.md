# Fade Into You: Chord Player

Plays the chord progression of Mazzy Star's *Fade Into You* (A, E, Bm, plus D at the end of the chorus) straight from a script. There is one version for Windows (PowerShell) and one for Ubuntu/Linux (bash + SoX).

The song structure is: intro, verse, chorus, instrumental, verse, chorus x2, outro.

Chords are polyphonic, and `[Console]::Beep` can only play one note at a time. So each chord is built by layering sine waves, with a fast attack and a slow decay, so it sounds like a strummed guitar rather than a beep.

## Chords used

| Chord | Frequencies (Hz) |
|-------|------------------|
| A     | 110, 220, 277.18, 329.63 |
| E     | 82.41, 164.81, 246.94, 329.63, 415.30 |
| Bm    | 123.47, 185.00, 246.94, 293.66, 369.99 |
| D     | 146.83, 220, 293.66, 369.99 |

## Windows (PowerShell)

**Requirements:** Windows with PowerShell 5.1 or newer. Nothing else to install.

1. Save the script below as `fade.ps1`.
2. Run it:

```powershell
powershell -ExecutionPolicy Bypass -File .\fade.ps1
```

It takes a few seconds to synthesize the audio into a WAV file in `%TEMP%`, then plays it.

> **Tip:** Run it from a file. Pasting a long script into the console can drop `$` characters and break the parsing.

```powershell
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
```

## Ubuntu / Linux (bash)

**Requirements:** SoX.

```bash
sudo apt install sox
```

1. Save the script below as `fade.sh`.
2. Run it:

```bash
chmod +x fade.sh
./fade.sh
```

```bash
#!/bin/bash
bar=2.4   # seconds per chord
declare -A C=(
  [A]="110 220 277.18 329.63"
  [E]="82.41 164.81 246.94 329.63 415.30"
  [Bm]="123.47 185 246.94 293.66 369.99"
  [D]="146.83 220 293.66 369.99"
)
L="A E Bm"; LD="A E Bm D"
V1="$L $L $L $L $L $L $L $L"; V2="$L $L $L $L"
CH="$L $L $LD $L"
song="$L $L $V1 $CH $CH $V2 $CH $CH $L $L"

for ch in $song; do
  args=()
  for f in ${C[$ch]}; do args+=(sine mix "$f"); done
  play -nq synth "$bar" "${args[@]}" vol 0.25 fade h 0.01 "$bar" 0.4
done
```

## Customizing

- **Tempo:** change `$bar` (PowerShell) or `bar` (bash), the number of seconds each chord lasts. About `2.4` is close to the record, and a smaller number is faster.
- **Arrangement:** edit the `$seq` / `song` lines. Each section is built from `A E Bm`, with `D` added at the end of the third chorus line.
- **Volume:** in PowerShell, change `20000` (max about 32000). In bash, change `vol 0.25`.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Unexpected token` errors in PowerShell | Run from a `.ps1` file instead of pasting into the console |
| Script blocked in PowerShell | Use `-ExecutionPolicy Bypass` as shown above |
| `play: command not found` | Install SoX with `sudo apt install sox` |
| No sound on Linux | Check that your audio output works, e.g. `play -n synth 1 sine 440` |

## Credits

Chords based on - https://tabs.ultimate-guitar.com/tab/mazzy-star/fade-into-you-chords-945178

## License
MIT License

Copyright (c) 2026 pdf-rag-chatbot contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
