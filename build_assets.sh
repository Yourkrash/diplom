#!/bin/bash
# Renders presentation figures and formulas to tight PNGs via standalone LaTeX.
set -e
cd "$(dirname "$0")"
AD=slides_assets
mkdir -p "$AD"

PRE='\documentclass[border=10pt]{standalone}
\usepackage[T2A]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage[russian]{babel}
\usepackage{amsmath,amssymb}
\usepackage{lmodern}
\usepackage{tikz}
\usetikzlibrary{arrows.meta,positioning,fit,backgrounds,calc}
\usepackage{pgfplots}
\pgfplotsset{compat=1.18}
\begin{document}'
END='\end{document}'

mk () { # name  bodyfile
  local name="$1"; local body="$2"
  { printf '%s\n' "$PRE"; cat "$body"; printf '%s\n' "$END"; } > "$AD/$name.tex"
}

# ---------- FIGURES ----------
cat > /tmp/fig_pipeline.tex <<'TIKZ'
\begin{tikzpicture}[
    node distance=0.9cm and 1.0cm,
    block/.style={draw, rounded corners, minimum height=1.1cm,
        minimum width=2.4cm, align=center, font=\small},
    frozen/.style={block, fill=black!6},
    trained/.style={block, fill=black!16},
    >={Stealth[length=2.5mm]}]
    \node (in) [align=center, font=\small] {Искажённый\\сигнал $y$};
    \node (enc) [frozen, right=of in] {SSL-энкодер\\$E$ (заморожен)};
    \node (fc)  [trained, right=of enc] {Очиститель\\признаков $G_\phi$};
    \node (voc) [trained, right=of fc] {Вокодер\\$V_\psi$};
    \node (out) [align=center, font=\small, right=of voc] {Чистый\\сигнал $\hat{x}$};
    \draw[->] (in) -- (enc);
    \draw[->] (enc) -- node[above, font=\scriptsize] {$z$} (fc);
    \draw[->] (fc) -- node[above, font=\scriptsize] {$\hat{z}$} (voc);
    \draw[->] (voc) -- (out);
\end{tikzpicture}
TIKZ
mk fig_pipeline /tmp/fig_pipeline.tex

cat > /tmp/fig_arch.tex <<'TIKZ'
\begin{tikzpicture}[
    >={Stealth[length=2.4mm]},
    lyr/.style={draw, minimum width=3.6cm, minimum height=0.8cm,
        align=center, font=\small, fill=black!6},
    sel/.style={lyr, fill=black!16, very thick},
    adp/.style={draw, rounded corners=2pt, minimum width=1.5cm,
        minimum height=0.7cm, align=center, font=\small, fill=black!22},
    io/.style={align=center, font=\small}]
    \node (cnn) [lyr] {Свёрточный фронтенд (CNN)};
    \node (l1)  [lyr, above=1.1cm of cnn] {Трансформерный слой $1$};
    \node (ld)  [above=0.6cm of l1, font=\large] {$\vdots$};
    \node (le)  [sel, above=0.6cm of ld] {Трансформерный слой $\ell$};
    \node (in) [io, below=0.85cm of cnn] {Искажённый сигнал $y$};
    \draw[->] (in) -- (cnn);
    \draw[->] (cnn) -- (l1);
    \draw[->] (l1) -- (ld);
    \draw[->] (ld) -- (le);
    \node (a1) [adp, right=1.9cm of l1] {Адаптер};
    \node (ae) [adp, right=1.9cm of le] {Адаптер};
    \draw[->] (l1.east) -- (a1.west);
    \draw[->] (le.east) -- (ae.west);
    \begin{scope}[on background layer]
        \node (encbox) [draw, dashed, rounded corners,
            fit=(cnn)(le)(a1)(ae), inner sep=9pt] {};
    \end{scope}
    \node [font=\small, anchor=south] at (encbox.north)
        {Замороженный энкодер $E$ + обучаемые адаптеры $G_\phi$};
    \node (voc) [draw, rounded corners, fill=black!16, minimum width=2.8cm,
        minimum height=1.1cm, align=center, font=\small,
        right=2.6cm of ae] {Вокодер $V_\psi$\\(HiFi-GAN / WaveFit)};
    \node (res) [io, below=1.1cm of voc] {Чистый\\сигнал $\hat{x}$};
    \draw[->] (ae.east) -- node[above, font=\footnotesize] {$\hat{z}^{(\ell)}$} (voc.west);
    \draw[->] (voc) -- (res);
\end{tikzpicture}
TIKZ
mk fig_arch /tmp/fig_arch.tex

cat > /tmp/fig_layers.tex <<'TIKZ'
\begin{tikzpicture}
\begin{axis}[
    width=14cm, height=8cm,
    xlabel={Номер слоя $\ell$}, ylabel={PESQ (валидация)},
    xmin=0.5, xmax=12.5, ymin=2.2, ymax=3.1,
    xtick={1,2,3,4,5,6,7,8,9,10,11,12},
    legend pos=south west, legend cell align=left,
    grid=both, grid style={black!12}, tick label style={font=\small},
    label style={font=\large}]
\addplot[mark=*, thick] coordinates {
    (1,2.39)(2,2.57)(3,2.65)(4,2.82)(5,2.84)(6,2.93)(7,2.95)(8,2.87)
    (9,2.85)(10,2.71)(11,2.69)(12,2.55)};
\addlegendentry{WavLM Base+}
\addplot[mark=square*, thick, dashed] coordinates {
    (1,2.36)(2,2.44)(3,2.61)(4,2.66)(5,2.79)(6,2.82)(7,2.78)(8,2.76)
    (9,2.64)(10,2.62)(11,2.50)(12,2.47)};
\addlegendentry{HuBERT Base}
\end{axis}
\end{tikzpicture}
TIKZ
mk fig_layers /tmp/fig_layers.tex

cat > /tmp/fig_tradeoff.tex <<'TIKZ'
\begin{tikzpicture}
\begin{axis}[
    width=13cm, height=8cm,
    xlabel={RTF (меньше --- быстрее)}, ylabel={PESQ},
    xmin=0, xmax=0.18, ymin=2.6, ymax=3.05,
    grid=both, grid style={black!12},
    nodes near coords, point meta=explicit symbolic,
    every node near coord/.append style={font=\small, anchor=south},
    tick label style={font=\small}, label style={font=\large}]
\addplot[only marks, mark=*, mark size=3pt] coordinates {
    (0.031,2.71) [K1]
    (0.142,2.78) [K2]
    (0.034,2.94) [K3]
    (0.149,2.97) [K4]};
\end{axis}
\end{tikzpicture}
TIKZ
mk fig_tradeoff /tmp/fig_tradeoff.tex

# ---------- FORMULAS ----------
fml () { # name  math
  printf '$\\displaystyle %s$\n' "$2" > /tmp/_f.tex
  mk "$1" /tmp/_f.tex
}
fml m_degradation 'y(t) = \mathcal{C}\bigl((x * h)(t) + n(t)\bigr)'
fml m_snr '\mathrm{SNR} = 10\lg\frac{\sum_t \bigl((x*h)(t)\bigr)^2}{\sum_t n^2(t)}\ \ [\text{дБ}]'
fml m_notation 'z = E(y),\qquad z^{\ast} = E(x),\qquad \hat{z} = G_\phi(z),\qquad \hat{x} = V_\psi(\hat{z})'
fml m_sisdr '\mathrm{SI\text{-}SDR} = 10\lg\frac{\lVert\alpha x\rVert^2}{\lVert\alpha x - \hat{x}\rVert^2},\qquad \alpha = \frac{\langle \hat{x},\,x\rangle}{\lVert x\rVert^2}'
fml m_adapter '\tilde{h}^{(i)} = h^{(i)} + W_{\text{up}}\,\sigma\!\bigl(W_{\text{down}}\,h^{(i)}\bigr)'
fml m_fcloss '\mathcal{L}_{\text{fc}}(\phi) = \bigl\lVert G_\phi(E(y)) - E(x)\bigr\rVert_1 + \lambda\,\bigl\lVert G_\phi(E(y)) - E(x)\bigr\rVert_2^2'
fml m_vloss '\mathcal{L}_{V} = \mathcal{L}_{\text{adv}}(V_\psi) + \lambda_{\text{fm}}\,\mathcal{L}_{\text{fm}} + \lambda_{\text{mel}}\,\mathcal{L}_{\text{mel}}'
fml m_mix 'y_0 = (x * h) + g\cdot n,\qquad g = \sqrt{\frac{\lVert x*h\rVert^2}{\lVert n\rVert^2}\cdot 10^{-\mathrm{SNR}/10}}'

# ---------- COMPILE ----------
cd "$AD"
for t in *.tex; do
  b="${t%.tex}"
  pdflatex -interaction=nonstopmode "$t" > "/tmp/asset_$b.log" 2>&1 || { echo "FAIL $b"; tail -5 "/tmp/asset_$b.log"; }
  if [ -f "$b.pdf" ]; then
     pdftoppm -png -r 300 -singlefile "$b.pdf" "$b" >/dev/null 2>&1
  fi
done
echo "=== produced PNGs ==="
ls -1 *.png 2>/dev/null
