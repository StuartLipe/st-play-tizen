# Instalar o app na TV — certificado Samsung

O `sdb` já conecta (`192.168.100.14:26101`). O que falta é **assinar com um
certificado de distribuidor emitido pela Samsung**, vinculado ao DUID desta TV.

O certificado público do Tizen **não serve** — a TV responde:

```
install failed[118, -12]
reason: Check certificate error: Invalid certificate chain with certificate in signature
```

## Dados desta TV

| Campo | Valor |
|---|---|
| Modelo | `UN55DU7700GXZD` (Crystal UHD 2024, Tizen 8) |
| IP | `192.168.100.14` |
| DUID | `uuid:1a92721a-346c-4b9d-8efc-30b948cf74ee` |

O DUID também aparece na TV em **Menu → Suporte → Contato Samsung → ID
exclusivo do dispositivo**.

## Pré-requisito

- Conta **Samsung Developers** (a mesma do `developer.samsung.com`)
- Tizen Studio **IDE** instalado (o Certificate Manager é plugin do IDE)
- Samsung Certificate Extension (instalada pelo Package Manager do IDE)

## Passo a passo no IDE

1. Abra o **Tizen Studio** → menu **Tools → Certificate Manager**
2. Se aparecer o diálogo "Migration for Certificate Profile", clique **Cancel**
3. Clique **+** para criar um perfil
4. Escolha **Samsung** (não "Tizen")
5. Selecione **TV** → **Next**
6. Nome do perfil: **STPlayTV** (tem que ser o mesmo usado no `pack.ps1`)
7. **Author Certificate** → *Create a new author certificate* → preencher dados
8. **Sign in** com a conta Samsung Developers (abre login no navegador do IDE)
9. Escolha uma pasta de backup para o `author.p12`
10. **Distributor Certificate** → *Create a new distributor certificate*
11. Privilege level: **Public**
12. Adicione o **DUID** `uuid:1a92721a-346c-4b9d-8efc-30b948cf74ee`
    (ou clique no **+** ao lado da TV conectada)
13. **Finish**

## Depois do certificado

```powershell
cd C:\Users\Administrator\Documents\st-app-tizen
.\scripts\sync.ps1
.\scripts\pack.ps1 -Profile STPlayTV
.\scripts\install.ps1 -TvIp 192.168.100.14
```

Se o perfil criado tiver outro nome, passe esse nome em `-Profile`.

## Enquanto o certificado não sai

O app roda **hoje** pelo navegador da TV, sem instalar nada e sem certificado:

1. Na TV, abra o app **Internet**
2. Acesse `http://192.168.100.196:8787/`

Esse endereço é servido pelo `iniciar-proxy.bat` (mesmo processo que faz o
proxy do painel). Precisa do PC ligado e do servidor rodando.

## Arquivos do certificado

- `cert/author.p12` — chave do autor (não versionar, não compartilhar)
- `C:\tizen-studio-data\profile\profiles.xml` — perfis do CLI
- O certificado Samsung fica no seu usuário do Windows, gerenciado pelo IDE

> **Atenção:** o `.wgt` atual tem seu usuário e senha do painel embutidos
> (`stplay-config.js`). Não compartilhe esse arquivo.
