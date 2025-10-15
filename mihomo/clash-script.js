// Define the `main` function

function main(config) {
  if (!config.proxies) return config;

  // dns
  config.dns = {
    enable: true,
    ipv6: true,
    "enhanced-mode": "fake-ip",
    "fake-ip-range": "198.18.0.1/16",
    "fake-ip-filter-mode": "blacklist",
    "fake-ip-filter": [
      "rule-set:private",
      "rule-set:direct",
      "geosite:connectivity-check",
      "geosite:private",
      "rule-set:fake-ip-filter",
    ],
    "prefer-h3": false,
    "default-nameserver": [
      "223.5.5.5",
      "8.8.8.8",
      "tls://1.12.12.12:853",
      "tls://223.5.5.5:853",
    ],
    nameserver: [
      "https://dns.alidns.com/dns-query",
      "https://doh.pub/dns-query",
    ],
    "respect-rules": true,
    "proxy-server-nameserver": [
      "https://dns.alidns.com/dns-query",
      "https://doh.pub/dns-query",
    ],
    "nameserver-policy": {
      "geosite:cn,private": [
        "https://dns.alidns.com/dns-query",
        "https://doh.pub/dns-query",
        "223.5.5.5",
        "119.29.29.29",
      ],
      "geo:cn": [
        "https://dns.alidns.com/dns-query",
        "https://doh.pub/dns-query",
        "223.5.5.5",
        "119.29.29.29",
      ],
      "geosite:gfw": [
        "https://1.1.1.1/dns-query",
        "https://dns.google/dns-query",
        "1.1.1.1",
        "8.8.8.8",
      ],
      "geosite:geolocation-!cn": [
        "https://1.1.1.1/dns-query",
        "https://dns.google/dns-query",
        "1.1.1.1",
        "8.8.8.8",
      ],
      "full-nameserver": [
        "https://1.1.1.1/dns-query",
        "https://dns.google/dns-query",
        "1.1.1.1",
        "8.8.8.8",
      ],
    },
    fallback: ["1.1.1.1", "8.8.8.8"],
  };

  // tun
  config.tun = {
    enable: true,
    stack: "mixed",
    "auto-route": true,
    "auto-redirect": true,
    "auto-detect-interface": true,
    "strict-route": true,
    "dns-hijack": ["any:53", "tcp://any:53"],
    mtu: 1500,
    gso: false,
    "gso-max-size": 65536,
    "udp-timeout": 300,
  };

  config.sniffer = {
    enable: true,
    sniff: {
      HTTP: {
        ports: [80, "8080-8880"],
        "override-destination": true,
      },
      TLS: {
        ports: [443, 8443],
      },
      QUIC: {
        ports: [443, 8443],
      },
    },
    "force-domain": ["+.v2ex.com"],
    "skip-domain": ["+.baidu.com", "+.bilibili.com"],
  };

  // 策略元信息
  const DIRECT = "DIRECT";
  const REJECT = "REJECT";
  const strategies = {
    proxyMode: {
      name: "代理模式",
      type: "select",
      icon: "https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Final.png",
    },
    self: {
      name: "自建",
      type: "select",
      icon: "https://www.clashverge.dev/assets/icons/link.svg",
    },
    master: {
      name: "Master",
      type: "select",
      icon: "https://www.clashverge.dev/assets/icons/speed.svg",
    },
    masterAuto: {
      name: "🧭 master自动选择",
      type: "urlTest",
      regex: /^master/,
    },
    hk: {
      name: "🇭🇰️ 香港",
      type: "urlTest",
      regex: /^master.*(港|Hong\sKong).*$/,
    },
    hkThrottle: {
      name: "🇭🇰️ 香港➰",
      type: "urlTest",
      regex: /^master.*(港|Hong\sKong)[^|]*$/,
    },
    tw: {
      name: "🇹🇼 台湾",
      type: "urlTest",
      regex: /^master.*(台|Taiwan).*$/,
    },
    twThrottle: {
      name: "🇹🇼 台湾➰",
      type: "urlTest",
      regex: /^master.*(台|Taiwan)[^|]*$/,
    },
    jp: {
      name: "🇯🇵 日本",
      type: "urlTest",
      regex: /^master.*(日|Japan).*$/,
    },
    jpThrottle: {
      name: "🇯🇵 日本➰",
      type: "urlTest",
      regex: /^master.*(日|Japan)[^|]*$/,
    },
    sg: {
      name: "🇸🇬 新加坡",
      type: "urlTest",
      regex: /^master.*(新|Singapore).*$/,
    },
    sgThrottle: {
      name: "🇸🇬 新加坡➰",
      type: "urlTest",
      regex: /^master.*(新|Singapore)[^|]*$/,
    },
    us: {
      name: "🇺🇸 美国",
      type: "urlTest",
      regex: /^master.*(美|USA).*$/,
    },
    usChecked: {
      name: "🇺🇸 美国✔️",
      type: "urlTest",
      regex: /^master.*(美|USA).*(原生).*$/,
    },
    usThrottle: {
      name: "🇺🇸 美国➰",
      type: "urlTest",
      regex: /^master.*(美|USA)[^|]*$/,
    },
    uk: {
      name: "🇬🇧 英国",
      type: "urlTest",
      regex: /^master.*(英|UK).*$/,
    },
    ukThrottle: {
      name: "🇬🇧 英国➰",
      type: "urlTest",
      regex: /^master.*(英|UK)[^|]*$/,
    },
    microsoft: {
      name: "Microsoft",
      type: "select",
      icon: "https://www.clashverge.dev/assets/icons/microsoft.svg",
    },
    steam: {
      name: "Steam",
      type: "select",
      icon: "https://www.clashverge.dev/assets/icons/steam.svg",
    },
    video: {
      name: "Video",
      type: "select",
      icon: "https://www.clashverge.dev/assets/icons/netflix.svg",
    },
    github: {
      name: "Github",
      type: "select",
      icon: "https://www.clashverge.dev/assets/icons/github.svg",
    },
    google: {
      name: "Google",
      type: "select",
      icon: "https://www.clashverge.dev/assets/icons/google.svg",
    },
    spotify: {
      name: "Spotify",
      type: "select",
      icon: "https://raw.githubusercontent.com/Koolson/Qure/master/IconSet/Color/Spotify.png",
    },
    twitter: {
      name: "Twitter",
      type: "select",
      icon: "https://www.clashverge.dev/assets/icons/twitter.svg",
    },
    claude: {
      name: "Claude",
      type: "select",
      icon: "https://www.clashverge.dev/assets/icons/claude.svg",
    },
    chatgpt: {
      name: "Chatgpt",
      type: "select",
      icon: "https://www.clashverge.dev/assets/icons/chatgpt.svg",
    },
    blockAd: {
      name: "广告拦截",
      type: "select",
      icon: "https://www.clashverge.dev/assets/icons/block.svg",
    },
    proxy: {
      name: "PROXY",
      type: "select",
      icon: "https://www.clashverge.dev/assets/icons/adjust.svg",
    },
  };

  function getName(name) {
    return strategies[name].name;
  }

  function getProxies(regex) {
    return config.proxies.filter((e) => regex.test(e.name)).map((e) => e.name);
  }
  // 自建节点
  defaultProxy = getProxies(/hotfree/);

  // 根据正则添加节点
  for (let strategy in strategies) {
    const regex = strategies[strategy].regex;
    if (regex) {
      let proxies = getProxies(regex);
      if (proxies == undefined || proxies.length == 0) {
        proxies = defaultProxy;
      }
      strategies[strategy].proxies = proxies;
    }
  }

  // 给没有正则的手动添加节点
  const stdProxies = [
    getName("hk"),
    getName("hkThrottle"),
    getName("tw"),
    getName("twThrottle"),
    getName("jp"),
    getName("jpThrottle"),
    getName("sg"),
    getName("sgThrottle"),
    getName("us"),
    getName("usChecked"),
    getName("usThrottle"),
    getName("uk"),
    getName("ukThrottle"),
    getName("self"),
  ];
  strategies.proxyMode.proxies = [DIRECT, getName("proxy")];
  strategies.self.proxies = defaultProxy;
  strategies.master.proxies = [getName("masterAuto"), ...stdProxies].concat(
    getProxies(/^master/),
  );
  strategies.steam.proxies = [DIRECT, ...stdProxies];
  strategies.microsoft.proxies = [DIRECT, ...stdProxies];
  strategies.video.proxies = [DIRECT, ...stdProxies];
  strategies.google.proxies = stdProxies;
  strategies.spotify.proxies = stdProxies;
  strategies.twitter.proxies = stdProxies;
  strategies.github.proxies = [DIRECT, ...stdProxies];
  strategies.claude.proxies = [...stdProxies];
  strategies.chatgpt.proxies = [...stdProxies];
  strategies.blockAd.proxies = [DIRECT, REJECT, getName("proxy")];
  strategies.proxy.proxies = [DIRECT, getName("self"), getName("master")];

  const proxyGroups = [];

  for (let key in strategies) {
    const type = strategies[key].type;
    if (type === "select") {
      proxyGroups.push(strategies[key]);
    } else if (type === "urlTest") {
      proxyGroups.push(
        urlTestStrategyGenerator(strategies[key].name, strategies[key].proxies),
      );
    }
  }

  config["proxy-groups"] = proxyGroups;

  // rule providers
  config["rule-providers"] = {
    "fake-ip-filter": {
      type: "http",
      behavior: "domain",
      format: "text",
      url: "https://cdn.jsdelivr.net/gh/juewuy/ShellCrash@dev/public/fake_ip_filter.list",
      path: "./ruleset/fake_ip_filter.list",
      interval: 86400,
    },
    steam: {
      type: "http",
      behavior: "classical",
      url: "https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/Steam/Steam.yaml",
      path: "./ruleset/steam.yaml",
      interval: 86400,
    },
    spotify: {
      type: "http",
      behavior: "classical",
      url: "https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/Spotify/Spotify.yaml",
      path: "./ruleset/spotify.yaml",
      interval: 86400,
    },
    twitter: {
      type: "http",
      behavior: "classical",
      url: "https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/Twitter/Twitter.yaml",
      path: "./ruleset/twitter.yaml",
      interval: 86400,
    },
    github: {
      type: "http",
      behavior: "classical",
      url: "https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/GitHub/GitHub.yaml",
      path: "./ruleset/github.yaml",
      interval: 86400,
    },
    microsoft: {
      type: "http",
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/Microsoft/Microsoft.yaml",
      path: "./ruleset/microsoft.yaml",
      interval: 86400,
    },
    openai: {
      type: "http",
      behavior: "classical",
      url: "https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/OpenAI/OpenAI.yaml",
      path: "./ruleset/openai.yaml",
      interval: 86400,
    },
    claude: {
      type: "http",
      behavior: "classical",
      url: "https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/Claude/Claude.yaml",
      path: "./ruleset/claude.yaml",
      interval: 86400,
    },
    reject: {
      type: "http",
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/reject.txt",
      path: "./ruleset/reject.yaml",
      interval: 86400,
    },
    icloud: {
      type: "http",
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/icloud.txt",
      path: "./ruleset/icloud.yaml",
      interval: 86400,
    },
    apple: {
      type: "http",
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/apple.txt",
      path: "./ruleset/apple.yaml",
      interval: 86400,
    },
    gemini: {
      type: "http",
      behavior: "classical",
      url: "https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/Gemini/Gemini.yaml",
      path: "./ruleset/gemini.yaml",
      interval: 86400,
    },
    google: {
      type: "http",
      behavior: "classical",
      url: "https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/Google/Google.yaml",
      path: "./ruleset/google.yaml",
      interval: 86400,
    },
    proxy: {
      type: "http",
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/proxy.txt",
      path: "./ruleset/proxy.yaml",
      interval: 86400,
    },
    direct: {
      type: "http",
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/direct.txt",
      path: "./ruleset/direct.yaml",
      interval: 86400,
    },
    private: {
      type: "http",
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/private.txt",
      path: "./ruleset/private.yaml",
      interval: 86400,
    },
    gfw: {
      type: "http",
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/gfw.txt",
      path: "./ruleset/gfw.yaml",
      interval: 86400,
    },
    greatfire: {
      type: "http",
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/greatfire.txt",
      path: "./ruleset/greatfire.yaml",
      interval: 86400,
    },
    "tld-not-cn": {
      type: "http",
      behavior: "domain",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/tld-not-cn.txt",
      path: "./ruleset/tld-not-cn.yaml",
      interval: 86400,
    },
    telegramcidr: {
      type: "http",
      behavior: "ipcidr",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/telegramcidr.txt",
      path: "./ruleset/telegramcidr.yaml",
      interval: 86400,
    },
    cncidr: {
      type: "http",
      behavior: "ipcidr",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/cncidr.txt",
      path: "./ruleset/cncidr.yaml",
      interval: 86400,
    },
    lancidr: {
      type: "http",
      behavior: "ipcidr",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/lancidr.txt",
      path: "./ruleset/lancidr.yaml",
      interval: 86400,
    },
    applications: {
      type: "http",
      behavior: "classical",
      url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/applications.txt",
      path: "./ruleset/applications.yaml",
      interval: 86400,
    },
  };

  const videoDomains = [
    "olevod.com",
    "olevod.com",
    "olelive.com",
    "olemovienews.com",
    "iyf.tv",
    "anygate.vip",
    "generalcdn.com",
    "newwycdn.com",
    "newyvpa.com",
    "tfbgddd.com",
    "tfbgeee.com",
    "wyav.tv",
  ];
  const videoRules = videoDomains.map(
    (d) => `DOMAIN-SUFFIX,${d},${getName("video")}`,
  );

  // rules
  const rules = [
    ...videoRules,
    `IP-CIDR,66.112.218.65/24,${DIRECT},no-resolve`,
    `DOMAIN-SUFFIX,scrapy.org,${DIRECT}`,
    `DOMAIN-SUFFIX,hotfree.xyz,${DIRECT}`,
    `DOMAIN-SUFFIX,apache.org,${DIRECT}`,
    `RULE-SET,applications,${DIRECT}`,
    `DOMAIN-SUFFIX,linux.do,${getName("proxy")}`,
    `RULE-SET,steam,${getName("steam")}`,
    `DOMAIN-SUFFIX,diagrams.org,${DIRECT}`,
    `DOMAIN,clash.razord.top,${DIRECT}`,
    `DOMAIN,yacd.haishan.me,${DIRECT}`,
    `RULE-SET,private,${DIRECT}`,
    `RULE-SET,reject,${getName("blockAd")}`,
    `RULE-SET,direct,${DIRECT}`,
    `RULE-SET,icloud,${DIRECT}`,
    `RULE-SET,apple,${DIRECT}`,
    `RULE-SET,gemini,${getName("claude")}`,
    `RULE-SET,google,${getName("google")}`,
    `RULE-SET,github,${getName("github")}`,
    `RULE-SET,spotify,${getName("spotify")}`,
    `RULE-SET,twitter,${getName("twitter")}`,
    `RULE-SET,openai,${getName("chatgpt")}`,
    `DOMAIN-SUFFIX,claudeusercontent.com,${getName("claude")}`,
    `RULE-SET,claude,${getName("claude")}`,
    `DOMAIN-SUFFIX,openrouter.ai,${getName("claude")}`,
    `RULE-SET,microsoft,${getName("microsoft")}`,
    `RULE-SET,tld-not-cn,${getName("proxy")}`,
    `RULE-SET,gfw,${getName("proxy")}`,
    `RULE-SET,greatfire,${getName("proxy")}`,
    `RULE-SET,telegramcidr,${getName("proxy")}`,
    `RULE-SET,lancidr,${DIRECT}`,
    `RULE-SET,cncidr,${DIRECT}`,
    `GEOIP,LAN,${DIRECT}`,
    `GEOIP,CN,${DIRECT}`,
    `RULE-SET,direct,${DIRECT}`,
    `MATCH,${getName("proxyMode")}`,
  ];

  config.rules = rules;

  return config;
}

function urlTestStrategyGenerator(
  name,
  proxies,
  url = "http://www.gstatic.com/generate_204",
  interval = 86400,
) {
  return {
    name,
    type: "url-test",
    hidden: true,
    url,
    interval,
    proxies,
  };
}
