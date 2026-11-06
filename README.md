# ST PLAY — Tizen TV (`.wgt`)

App **web** para TV Samsung, empacotado como widget Tizen. Usa o renderer do
`st-app` (React/Vite) — o mesmo do ST PLAY de celular e desktop.

> Samsung TV roda Tizen, não Android. O app nativo `teve` (Kotlin/Media3) **não
> roda aqui** e não pode ser convertido: seria outro app.

## Estrutura

```
st-app-tizen/
├─ config.xml              manifesto Tizen (profile tv, privilégios)
├─ .project                marca o diretório como projeto Tizen
├─ index.html              gerado pelo sync (dist do st-app)
├─ assets/                 gerado pelo sync
├─ stplay-config.js        gerado pelo sync (proxyBase)
├─ res/icon-512.png        ícone da loja/TV
├─ proxy/proxy-server.cjs  proxy HTTP que roda no PC
└─ scripts/
   ├─ sync.ps1             build do st-app + cópia do dist + config do proxy
   ├─ pack.ps1             tizen package (assina e gera .wgt)
   └─ install.ps1          sdb connect + install + launch
```

## Pré-requisitos

1. **Tizen Studio** — https://developer.tizen.org/development/tizen-studio/download
   No Package Manager, instale também **TV Extensions** (sem isso não existe
   profile `tv`).
2. **Node 18+** (para o proxy).
3. TV com **Developer Mode** ligado, `Host PC IP = 192.168.100.196`, reiniciada.

## Fluxo de desenvolvimento

```powershell
# 1. proxy (deixe rodando em outra janela)
node proxy\proxy-server.cjs

# 2. build + cópia
.\scripts\sync.ps1

# 3. assinar e empacotar (1x por mudança)
.\scripts\pack.ps1

# 4. instalar na TV
.\scripts\install.ps1 -TvIp 192.168.100.14
```

Logs da TV:

```powershell
& "C:\tizen-studio\tools\sdb.exe" dlog
```

### Por que o proxy é obrigatório

O renderer chama o painel Xtream por `fetch` e o painel não manda cabeçalho
CORS. No Android quem resolve isso é o `StreamProxyServer.kt`, dentro do
aparelho. No Tizen não existe processo nativo, então o proxy roda no PC
(`proxy-server.cjs`, porta 8787) e o app é apontado para ele via
`window.sturplay.proxyBase` (injetado em `stplay-config.js`).

O proxy também reescreve playlists HLS: cada variante, segmento e chave AES vira
uma URL absoluta do proxy. Sem isso, os caminhos relativos do `.m3u8`
quebrariam ao passar pelo proxy.

**Consequência:** com o PC desligado, o app na TV não carrega painel nem canais.

### Alvo de build

`sync.ps1 -Target chrome63` (padrão) cobre Tizen 4.0/2018+. Para TVs 2015–2017:

```powershell
.\scripts\sync.ps1 -Target chrome49
```

## Publicação oficial na Samsung Apps Store

### 1. Conta de vendedor

- Portal: **Samsung TV Seller Office** (`seller.samsungapps.com/tv`)
- Login com conta Samsung → cadastro de vendedor (pessoa física ou empresa)
- Apps gratuitos não têm taxa de publicação; apps pagos exigem dados
  fiscais/bancários

### 2. Registrar o app e obter o App ID

No Seller Office: **Register Application** → o sistema emite um **App ID de 10
caracteres**. Ele é obrigatório no `config.xml`:

```xml
<tizen:application id="<APP_ID>.STPlayTV" package="<APP_ID>" required_version="2.3"/>
```

O `stplay0001` atual serve só para modo desenvolvedor. Na loja, tem de ser o ID
emitido pela Samsung.

### 3. Distributor Certificate da Samsung

O certificado "Public" do Tizen Studio instala apenas em TV com Developer Mode.
Para a loja, o Seller Office emite um **distributor certificate** por app:

1. Seller Office → seu app → **Certificate** → baixar
2. Tizen Studio → **Certificate Manager** → importar como *Distributor
   Certificate*
3. Criar o security profile (ex.: `STPlayTV`) usando seu **Author Certificate**
   + esse distributor

### 4. Empacotar e assinar

```powershell
.\scripts\pack.ps1 -Profile STPlayTV
```

O `.wgt` gerado é o mesmo arquivo que vai para a loja.

### 5. Submeter

No Seller Office, além do `.wgt`:

| Item | Observação |
|---|---|
| Ícone | 512×512 PNG (`res/icon-512.png`) |
| Screenshots | resolução de TV (1920×1080), no mínimo 3 |
| Descrição | curta e longa, em cada idioma |
| Categoria | ex.: Video / Entertainment |
| Classificação etária | questionário obrigatório |
| Política de privacidade | URL pública |
| Países e data | definidos antes de publicar |

### 6. Certificação (QA da Samsung)

O app passa por teste em TVs reais. Checklist que reprova com frequência:

- navegação completa só com o controle (setas, OK, voltar `10009`)
- tecla **Voltar** não pode sair do app no meio de uma tela
- sem tela preta/travamento ao trocar de canal ou perder rede
- uso de memória dentro do limite da TV
- app não pode depender de serviço rodando no PC do usuário
- sem execução de código remoto

Aprovado → liberação para publicação (data/países).

## Bloqueios antes de submeter (importante)

1. **O proxy tem de ser público.** O revisor não tem o seu PC. Para a loja, o
   proxy precisa estar num servidor com HTTPS (VPS, Cloudflare Worker, etc.) ou
   o painel precisa responder CORS direto.
2. **Credenciais.** Não existe Android Keystore no Tizen. Para guardar
   usuário/senha do painel, use `tizen.keymanager`
   (`http://tizen.org/privilege/keymanager`), não `localStorage`.
3. **IPTV e direitos de conteúdo.** A Samsung exige que o app não facilite
   acesso a conteúdo sem direitos. Player que aceita lista de terceiros é
   categoria de alto risco de reprovação — mesmo tecnicamente perfeito.
4. **TVs 2015–2017.** `hls.js` depende de MSE; nessas TVs pode falhar. O
   caminho é HLS nativo do `<video>` ou AVPlay.

## Limitações conhecidas desta versão

- sem Media3/MediaSession (o Tizen tem AVPlay e `tizen.mediacontroller`)
- navegação por toque do `st-app` ainda não foi mapeada para D-pad
- o proxy é HTTP na LAN; para produção precisa de TLS e autenticação
- app instalado por `sdb` pode ser removido em atualização de firmware da TV
