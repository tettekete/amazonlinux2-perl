AmazonLinux2 ベースの汎用 perl 実行・開発用 Docker イメージビルド用リポジトリ。

# Prerequisites

- docker,docker-compose
- bash

# Usage

## Build image

```bash
$ docker-compose nuild
```

## Image, container usage

```bash
$ cd <path-to-your-work-dir>
$ curl https://raw.githubusercontent.com/tettekete/amazonlinux2-perl/master/docker-compose.yml -O
$ docker-compose pull
$ docker-compose up -d
$ docker-compose exec perl bash --login
```
