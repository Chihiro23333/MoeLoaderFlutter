## 自定义站点规则定义
### 1、完整骨架如下

```yaml
meta:

  name: "网站名字"
  type: "assets"
  headers:
    Referer: "https://www.pixiv.net/"
    User-Agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

display:
  columnCount: 6
  aspectRatio: 1

url:
  home: {link: "https://www.pixiv.net/ranking.php?p=${page}&format=json${mode}" }
  search: {link: "https://www.pixiv.net/ajax/search/artworks/${tag}?word=${tag}&order=date_d&mode=all&p=${page}&csw=0&s_mode=s_tag_full&type=all&lang=z"}
  options:
    - id: "mode"
      desc: "排行榜"
      items:
        - { desc: "今日", param: "&mode=daily" }
        - { desc: "本周", param: "&mode=weekly" }
        - { desc: "本月", param: "&mode=monthly" }
        - { desc: "新人", param: "&mode=rookie" }
        - { desc: "原创", param: "&mode=original" }
        - { desc: "AI生成", param: "&mode=daily_ai" }
        - { desc: "受男性欢迎", param: "&mode=male" }
        - { desc: "受女性欢迎", param: "&mode=female" }

homePage:
  onParseResult:
    contentType: "json"
    list:
      getNodes: { jsonpath: "$.contents" }
      foreach:
        coverUrl:
          get: { jsonpath: ".url" }
        href:
          get: { jsonpath: ".illust_id" }
          format:
            - concat: { start: "https://www.pixiv.net/artworks/", end: "" }
        width:
          get: { jsonpath: ".width" }
        height:
          get: { jsonpath: ".height" }
        tags:
          get: { jsonpath: ".tags" }
        id:
          get: { jsonpath: ".illust_id" }
        author:
          get: { jsonpath: ".user_name" }
        characters:
          get: { jsonpath: ".title" }

searchPage:
  onParseResult:
    contentType: "json"
    list:
      getNodes: { jsonpath: "$..illustManga.data" }
      foreach:
        coverUrl:
          get: { jsonpath: ".url" }
        href:
          get: { jsonpath: ".id" }
          format:
            - concat: { start: "https://www.pixiv.net/artworks/", end: "" }
        tags:
          get: { jsonpath: ".tags" }

detailPage:
  onValidateResult:
    result:
      - { regex: '"regular":null', action: "login" }
  onPreprocessResult:
    contentType: "html"
    get: { cssSelector: "#meta-preload-data", attr: "content" }
  onParseResult:
    contentType: "json"
    object:
      url:
        get: { jsonpath: "$..illust..regular" }
      rawUrl:
        get: { jsonpath: "$..illust..original" }
      tags:
        get: { jsonpath: "$..illust..userIllusts..tags" }
```

