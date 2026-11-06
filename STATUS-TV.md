# ST PLAY na TV — estado final

## Resumo

O app **ST PLAY 1.0.8** (renderer de `Documents\st`) roda na TV pelo navegador,
com **ao vivo, filmes e séries funcionando**.

| Teste | Resultado |
|---|---|
| Home | 1.776 ao vivo · 32.058 filmes · 10.798 séries |
| Ao vivo | abre na hora, 40s contínuos, buffer 50s à frente |
| Filme (VOD) | reproduz (primeiro buffer ~13s — CDN lento) |
| Série | reproduz em ~5s |
| D-pad | setas navegam, Enter abre, Voltar (10009) fecha |
| Downloads | removido do menu |
| Config | abas Armazenamento/Novidades/Atualizações e motores STUR/MPEG escondidos |
| `.wgt` | 2,43 MB, assinado, com `tizen-ui.js` |

## Abrir na TV

```
https://cst-first-frequencies-tremendous.trycloudflare.com
```

Na rede local: `http://192.168.100.196` (porta 80, sem digitar porta).

O servidor roda com `iniciar-tudo.bat` (servidor + túnel). O PC precisa ficar
ligado.

## O que estava quebrando o VOD (e foi corrigido)

1. **DNS do Windows** — o resolvedor do sistema (`getaddrinfo`) devolve
   NXDOMAIN para os hosts do CDN de filmes (`open01.online`, `hubby-dmca.com`),
   enquanto uma consulta DNS direta resolve normal. O proxy agora resolve por
   **c-ares (`dns.resolve4`)** e só cai no `getaddrinfo` se falhar.
2. **`Content-Range` mentiroso** — o CDN devolve `206` com `Content-Length` do
   pedaço, mas `Content-Range` dizendo o arquivo inteiro (1,8 GB). O navegador
   rejeita e aborta. O proxy **recalcula** o `Content-Range` a partir do Range
   pedido + Content-Length real.
3. **Timeout de VOD de 8s/10s** — o primeiro buffer do filme leva ~13s (CDN a
   ~750 KB/s), então o player desistia antes. Em `st/src/lib/player.ts`:
   `scheduleLoadTimeout` 8s → **30s** e `scheduleBlankCheck` de VOD 10s → **30s**.
4. **Player `internal` quebrava filme/série** — com `player: 'internal'`, o app
   não renderiza o overlay do player para filme/série. Config agora usa
   **`auto`** (que no navegador cai no interno).
5. **Cache do `stplay-config.js`** — o navegador servia a config antiga por 1h.
   Os scripts agora entram com `?v=<timestamp>` e `cache-control: no-cache`.

## Adaptações de TV (tizen-ui.js)

- **Downloads** removido do trilho e botões "Baixar" escondidos
- Abas **Armazenamento**, **Novidades** e **Atualizações** escondidas
- Motores **STUR** e **MPEG** escondidos (não existem no Tizen)
- **D-pad**: navegação espacial por setas, Enter ativa, Voltar (10009) fecha o
  player, teclas de mídia registradas via `tizen.tvinputdevice`
- Foco visível (anel branco), sem menu de contexto/arrastar

## Instalar no menu da TV

A TV recusa o certificado público do Tizen (`118 – invalid certificate chain`).
O certificado tem de ser emitido pela Samsung e vinculado ao DUID:

```
uuid:1a92721a-346c-4b9d-8efc-30b948cf74ee
```

Com a TV ligada, rode `instalar-na-tv.bat` — ele abre o login da conta Samsung
Developers no navegador (única etapa manual) e assina o `.wgt`.

## Correções no app desktop (.exe)

Além do proxy web/TV, o app Electron tinha dois problemas próprios:

1. **`electron/stream-proxy.cjs`** — no caminho `/stream` ele **removia
   `Content-Length`/`Content-Range`** e servia em chunked. O `<video>` tratava o
   MP4 como stream ao vivo: a duração crescia (7s, 12s, 17s…) e o player vivia
   rebufferizando. Agora, para VOD (não-HLS), o proxy preserva
   `Content-Length`, `Content-Range` e `Accept-Ranges`; HLS continua chunked.
2. **`src/App.tsx`** — com `player: 'internal'`, o overlay do player era
   **suprimido** para filme/série (`!(settings.player === 'internal' && ...)`),
   então clicar em "Assistir" não abria nada. A condição foi removida.

Resultado no app instalado: duração fixa (`6177s`), `readyState 4`, **0 frames
perdidos** e buffer crescendo (24s → 66s à frente). No app, o player fica em
**Interno** (`sturplay.settings.player = "internal"` + chaves de migração
marcadas, senão a cadeia v8..v13 volta para `stur`).

## TV: HEVC/HDR (por que o VOD dava erro)

O catálogo de filmes mistura dois tipos de arquivo:

| Origem | Codec | Toca no `<video>` da TV? |
|---|---|---|
| `gmaster` (a maioria) | H.264 High 1080p + AAC | ✅ sim |
| `ggfiberpre` (4K) | **HEVC Main 10 HDR10**, 3840×1600 | ❌ não |

O `<video>` do navegador da TV não decodifica HEVC Main10/HDR — o ao vivo é
H.264, por isso só ele funcionava. Foi por isso que **outros apps na TV** também
falharam no VOD: o arquivo é o mesmo.

**Correção**: o proxy agora **detecta HEVC** (probe com ffmpeg, em cache por URL)
e transcodifica na **GPU (NVENC, RTX 2060)** para H.264 1080p, entregando um MP4
fragmentado. Filmes H.264 continuam indo direto.

- HEVC: começa em ~15s (transcode) e **não tem seek** (stream fragmentado)
- H.264: +~5s no primeiro play (probe); depois fica em cache
- Testado: `rs 4`, tocando, 37 MB em 70s (~realtime)

## Limitações

- Primeiro filme demora ~13s para abrir (velocidade do CDN do painel, ~6 Mbps).
  Se o filme tiver bitrate maior que isso, pode travar durante a reprodução.
- O PC precisa ficar ligado (proxy + servidor).
- Se o túnel mudar de URL, rode `iniciar-tudo.bat` e use a URL impressa.
- Alterei `st/src/lib/player.ts` (timeouts de VOD) e rebuildei `st/dist`.

## Arquivos

| Arquivo | Para quê |
|---|---|
| `iniciar-tudo.bat` | servidor (porta 80) + túnel |
| `instalar-na-tv.bat` | assina com certificado Samsung e instala |
| `testar-no-pc.bat` | abre o app no PC em janela 1920×1080 |
| `STATUS-TV.md` | este documento |
| `tools/requests.log` | log das requisições |
| `tools/cloudflared.log` | log do túnel |
