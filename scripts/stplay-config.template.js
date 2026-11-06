/* Gerado por scripts/sync.ps1 a partir deste template - nao editar o gerado. */
(function () {
  /* A TV e tela grande: bloqueia a classe st-mobile que o bundle adiciona
     quando detecta toque/ponteiro grosso. Sem ela o app usa o layout de TV
     (o mesmo do Electron) e nao para na tela de login. */
  try {
    var addOriginal = DOMTokenList.prototype.add;
    DOMTokenList.prototype.add = function () {
      var args = Array.prototype.slice.call(arguments).filter(function (c) { return c !== "st-mobile"; });
      if (!args.length) return;
      return addOriginal.apply(this, args);
    };
  } catch (e) {}

  /* App instalado (file://): tenta a LAN (rapida) e cai para o tunel se a
     rede isolar a TV do PC. Navegador usa a mesma origem. */
  var LAN = "http://192.168.100.196/proxy";
  var TUNNEL = "__PROXY_TUNNEL__";
  var base = (location.protocol === "file:") ? LAN : "/proxy";
  window.__stplayProxyBase = base;

  window.SturNativeConfig = {
    getProxyBase: function () { return window.__stplayProxyBase; },
    getCoverBase: function () { return window.__stplayProxyBase; },
    getDownloadsDir: function () { return ""; },
    getVersion: function () { return "1.0.0"; }
  };
  window.sturplay = {
    get proxyBase() { return window.__stplayProxyBase; },
    get coverBase() { return window.__stplayProxyBase; }
  };
  window.__STPLAY_BUILD = "__BUILD__";

  try {
    var fetch0 = window.fetch;
    window.fetch = function (input, init) {
      var url = typeof input === "string" ? input : (input && input.url) || "";
      if (url.indexOf(LAN) === 0) {
        var opts = init ? Object.assign({}, init) : {};
        try { opts.signal = AbortSignal.timeout(4000); } catch (e) {}
        return fetch0(input, opts)
          .then(function (r) { if (!r.ok && r.status >= 500) throw new Error("lan " + r.status); return r; })
          .catch(function () {
            window.__stplayProxyBase = TUNNEL;
            return fetch0(url.replace(LAN, TUNNEL), init);
          });
      }
      return fetch0(input, init);
    };
  } catch (e) {}

  try {
    var xhrOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function () {
      var args = Array.prototype.slice.call(arguments);
      try {
        var u = String(args[1] || "");
        if (u.indexOf(LAN) === 0) {
          var self = this;
          self.addEventListener("error", function () { window.__stplayProxyBase = TUNNEL; }, { once: true });
        }
      } catch (e) {}
      return xhrOpen.apply(this, args);
    };
  } catch (e) {}

  /* O hls.js depende de MSE e, com o CDN lento (segmento de ~5s), ele estoura
     os timeouts e aborta. O <video> nativo toca HLS (Tizen e Edge) e usa o
     proxy jÃƒÂ¡ reescrito. Sem MediaSource o app nem tenta o hls.js. */
  try {
    window.MediaSource = undefined
    window.ManagedMediaSource = undefined
  } catch (e) {}

  /* No Tizen o <video> toca HLS nativo. O app so escolhe esse caminho quando
     canPlayType('application/vnd.apple.mpegurl') responde algo; no Edge ele
     responde vazio e o app gasta ~18s no hls.js antes de cair no nativo.
     Declarar suporte faz o app ir direto no caminho que funciona. */
  try {
    var canPlayOriginal = HTMLMediaElement.prototype.canPlayType;
    HTMLMediaElement.prototype.canPlayType = function (type) {
      if (String(type || '').toLowerCase().indexOf('mpegurl') !== -1) return 'maybe';
      return canPlayOriginal.apply(this, arguments);
    };
  } catch (e) {}

  /* O player tenta o CDN direto primeiro. No navegador o CORS derruba os
     segmentos e o hls.js desiste. Aqui todo XHR cross-origin passa pelo proxy,
     que resolve CORS e manda UA/Referer. As playlists ja vem reescritas com
     URLs absolutas do proxy, entao a resolucao relativa nao quebra. */
  try {
    var xhrOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function (method, url) {
      try {
        var u = String(url || '');
        var sameOrigin = u.indexOf(location.origin) === 0;
        var jaProxied = u.indexOf('/proxy?') !== -1 || u.indexOf('/stream?') !== -1;
        if (/^https?:\/\//i.test(u) && !sameOrigin && !jaProxied) {
          url = '/proxy?url=' + encodeURIComponent(u);
        }
      } catch (e) {}
      var args = Array.prototype.slice.call(arguments);
      args[1] = url;
      return xhrOpen.apply(this, args);
    };
  } catch (e) {}

  try {
    var HOST = "__HOST__";
    var USER = "__USER__";
    var PASS = "__PASS__";
    var ID = "gmaster";
    var PERFIL = "principal";

    var lista = [];
    try { lista = JSON.parse(localStorage.getItem("sturplay.playlists") || "[]"); } catch (e) { lista = []; }
    if (!Array.isArray(lista)) lista = [];

    var existe = false;
    for (var i = 0; i < lista.length; i++) {
      if (lista[i] && lista[i].id === ID) {
        lista[i].xtream = { host: HOST, username: USER, password: PASS };
        existe = true;
        break;
      }
    }
    if (!existe) {
      lista.push({ id: ID, name: "GMaster", kind: "xtream", xtream: { host: HOST, username: USER, password: PASS } });
    }
    localStorage.setItem("sturplay.playlists", JSON.stringify(lista));
    localStorage.setItem("sturplay.active", ID);

    var perfis = [];
    try { perfis = JSON.parse(localStorage.getItem("sturplay.profiles") || "[]"); } catch (e) { perfis = []; }
    if (!Array.isArray(perfis)) perfis = [];
    var temPerfil = false;
    for (var j = 0; j < perfis.length; j++) {
      if (perfis[j] && perfis[j].id === PERFIL) { temPerfil = true; break; }
    }
    if (!temPerfil) {
      perfis.push({ id: PERFIL, name: "Meu perfil", color: "#2dd4bf", playlistIds: [ID], lastPlaylistId: ID, favorites: [], continueWatching: [] });
    }
    localStorage.setItem("sturplay.profiles", JSON.stringify(perfis));
    localStorage.setItem("sturplay.active-profile", PERFIL);

    /* Player: a 1.0.8 usa STUR (mpv do .exe) por padrao. No navegador/Tizen
       nao existe, entao fixa o player interno e marca as migracoes como
       rodadas (senao a cadeia v8..v13 volta para STUR). */
    for (var v = 8; v <= 13; v++) localStorage.setItem("sturplay.player-engine-v" + v, "1");
    var cfg = {};
    try { cfg = JSON.parse(localStorage.getItem("sturplay.settings") || "{}") || {}; } catch (e) { cfg = {}; }
    if (!cfg.player || cfg.player === "stur" || cfg.player === "mpeg") cfg.player = "auto";
    localStorage.setItem("sturplay.settings", JSON.stringify(cfg));
  } catch (e) { /* storage indisponivel */ }
})();
