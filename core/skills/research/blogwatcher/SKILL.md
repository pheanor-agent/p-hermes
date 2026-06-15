---
name: blogwatcher
description: "Monitor blogs and RSS/Atom feeds via blogwatcher-cli tool."
version: 2.0.0
author: JulienTant (fork of Hyaxia/blogwatcher)
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [RSS, Blogs, Feed-Reader, Monitoring]
    homepage: https://github.com/JulienTant/blogwatcher-cli
prerequisites:
  commands: [blogwatcher-cli]
---

# Blogwatcher

Track blog and RSS/Atom feed updates with the `blogwatcher-cli` tool. Supports automatic feed discovery, HTML scraping fallback, OPML import, and read/unread article management.

## Installation

Pick one method:

- **Go:** `go install github.com/JulienTant/blogwatcher-cli/cmd/blogwatcher-cli@latest`
- **Docker:** `docker run --rm -v blogwatcher-cli:/data ghcr.io/julientant/blogwatcher-cli`
- **Binary (Linux amd64):** `curl -sL https://github.com/JulienTant/blogwatcher-cli/releases/latest/download/blogwatcher-cli_linux_amd64.tar.gz | tar xz -C /usr/local/bin blogwatcher-cli`
- **Binary (Linux arm64):** `curl -sL https://github.com/JulienTant/blogwatcher-cli/releases/latest/download/blogwatcher-cli_linux_arm64.tar.gz | tar xz -C /usr/local/bin blogwatcher-cli`
- **Binary (macOS Apple Silicon):** `curl -sL https://github.com/JulienTant/blogwatcher-cli/releases/latest/download/blogwatcher-cli_darwin_arm64.tar.gz | tar xz -C /usr/local/bin blogwatcher-cli`
- **Binary (macOS Intel):** `curl -sL https://github.com/JulienTant/blogwatcher-cli/releases/latest/download/blogwatcher-cli_darwin_amd64.tar.gz | tar xz -C /usr/local/bin blogwatcher-cli`

All releases: https://github.com/JulienTant/blogwatcher-cli/releases

### Docker with persistent storage

By default the database lives at `~/.blogwatcher-cli/blogwatcher-cli.db`. In Docker this is lost on container restart. Use `BLOGWATCHER_DB` or a volume mount to persist it:

```bash
# Named volume (simplest)
docker run --rm -v blogwatcher-cli:/data -e BLOGWATCHER_DB=/data/blogwatcher-cli.db ghcr.io/julientant/blogwatcher-cli scan

# Host bind mount
docker run --rm -v /path/on/host:/data -e BLOGWATCHER_DB=/data/blogwatcher-cli.db ghcr.io/julientant/blogwatcher-cli scan
```

### Migrating from the original blogwatcher

If upgrading from `Hyaxia/blogwatcher`, move your database:

```bash
mv ~/.blogwatcher/blogwatcher.db ~/.blogwatcher-cli/blogwatcher-cli.db
```

The binary name changed from `blogwatcher` to `blogwatcher-cli`.

## Common Commands

### Managing blogs

- Add a blog: `blogwatcher-cli add "My Blog" https://example.com`
- Add with explicit feed: `blogwatcher-cli add "My Blog" https://example.com --feed-url https://example.com/feed.xml`
- Add with HTML scraping: `blogwatcher-cli add "My Blog" https://example.com --scrape-selector "article h2 a"`
- List tracked blogs: `blogwatcher-cli blogs`
- Remove a blog: `blogwatcher-cli remove "My Blog" --yes`
- Import from OPML: `blogwatcher-cli import subscriptions.opml`

### Scanning and reading

- Scan all blogs: `blogwatcher-cli scan`
- Scan one blog: `blogwatcher-cli scan "My Blog"`
- List unread articles: `blogwatcher-cli articles`
- List all articles: `blogwatcher-cli articles --all`
- Filter by blog: `blogwatcher-cli articles --blog "My Blog"`
- Filter by category: `blogwatcher-cli articles --category "Engineering"`
- Mark article read: `blogwatcher-cli read 1`
- Mark article unread: `blogwatcher-cli unread 1`
- Mark all read: `blogwatcher-cli read-all`
- Mark all read for a blog: `blogwatcher-cli read-all --blog "My Blog" --yes`

## Environment Variables

All flags can be set via environment variables with the `BLOGWATCHER_` prefix:

| Variable | Description |
|---|---|
| `BLOGWATCHER_DB` | Path to SQLite database file |
| `BLOGWATCHER_WORKERS` | Number of concurrent scan workers (default: 8) |
| `BLOGWATCHER_SILENT` | Only output "scan done" when scanning |
| `BLOGWATCHER_YES` | Skip confirmation prompts |
| `BLOGWATCHER_CATEGORY` | Default filter for articles by category |

## Example Output

```
$ blogwatcher-cli blogs
Tracked blogs (1):

  xkcd
    URL: https://xkcd.com
    Feed: https://xkcd.com/atom.xml
    Last scanned: 2026-04-03 10:30
```

```
$ blogwatcher-cli scan
Scanning 1 blog(s)...

  xkcd
    Source: RSS | Found: 4 | New: 4

Found 4 new article(s) total!
```

```
$ blogwatcher-cli articles
Unread articles (2):

  [1] [new] Barrel - Part 13
       Blog: xkcd
       URL: https://xkcd.com/3095/
       Published: 2026-04-02
       Categories: Comics, Science

  [2] [new] Volcano Fact
       Blog: xkcd
       URL: https://xkcd.com/3094/
       Published: 2026-04-01
       Categories: Comics
```

## Notes

- Auto-discovers RSS/Atom feeds from blog homepages when no `--feed-url` is provided.
- Falls back to HTML scraping if RSS fails and `--scrape-selector` is configured.
- Categories from RSS/Atom feeds are stored and can be used to filter articles.
- Import blogs in bulk from OPML files exported by Feedly, Inoreader, NewsBlur, etc.
- Database stored at `~/.blogwatcher-cli/blogwatcher-cli.db` by default (override with `--db` or `BLOGWATCHER_DB`).
- Use `blogwatcher-cli <command> --help` to discover all flags and options.

## Inline RSS/Atom 파싱 (JOB-1584)

blogwatcher-cli 없이 Python으로 RSS/Atom 직접 파싱하는 패턴. bash 스크립트에서 inline 사용 가능.

### Atom XML 파싱 (GeekNews 예시)

```bash
# GeekNews RSS (Atom XML)
curl -s "https://news.hada.io/rss/news" | python3 -c "
import sys, xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
for entry in root.iter('{http://www.w3.org/2005/Atom}entry'):
    title = entry.find('{http://www.w3.org/2005/Atom}title').text
    link = entry.find('{http://www.w3.org/2005/Atom}link').get('href')
    print(f'- [{title}]({link})')
" 2>/dev/null
```

### RSS 2.0 파싱 (TechCrunch 예시)

```bash
curl -s "https://techcrunch.com/feed/" | python3 -c "
import sys, xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
for item in root.iter('item'):
    title = item.find('title').text
    link = item.find('link').text
    print(f'- [{title}]({link})')
" 2>/dev/null
```

### 네임스페이스 처리

```python
# Atom feed (네임스페이스 필요)
ns = {'atom': 'http://www.w3.org/2005/Atom'}
for entry in root.iter('{http://www.w3.org/2005/Atom}entry'):
    title = entry.find('{http://www.w3.org/2005/Atom}title').text

# RSS 2.0 (네임스페이스 없음)
for item in root.iter('item'):
    title = item.find('title').text
```

### ⚠️ Pitfalls

1. **RSS URL 변경**: `https://news.hada.io/rss/news` (Atom) vs `https://techcrunch.com/feed/` (RSS 2.0). 사이트별로 형식 다름.
2. **HTML fallback 필수**: RSS 파싱 실패 시 기존 HTML parser 재사용 필요
3. **네임스페이스 필수**: Atom XML은 `{http://www.w3.org/2005/Atom}` 네임스페이스 없이 find() 실패
4. **키워드 필터링**: 모든 RSS 항목 수집하지 않고 AI/기술 관련 키워드만 필터링
