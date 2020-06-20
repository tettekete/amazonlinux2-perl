FROM amazonlinux:2

ARG DOCKER_HOME="/docker"
ARG LOCAL_PERL_VERSION=5.28.1

USER root

# MySQL 5.7 系 rpm を yum リポジトリに追加
WORKDIR /tmp/docker_build
RUN curl -L https://repo.mysql.com/mysql57-community-release-el7-11.noarch.rpm -O && \
	rpm -Uvh mysql57-community-release-el7-11.noarch.rpm && \
	rm mysql57-community-release-el7-11.noarch.rpm

RUN amazon-linux-extras install epel

################################################################################
# 定番コマンド + その他 yum でインストールするもの
RUN yum -y install		\
		which			\
		tree			\
		less			\
		openssl			\
		openssl-devel	\
		tar				\
		patch			\
		gcc				\
		perl-devel		\
		make			\
		sudo			\
		libxml2-devel	\
		expat-devel		\
		mysql-community-devel	\
	&& yum clean all

# openssl			| IO::Sockecket::SSL -> Net::SSLeay のインストールに必要
# openssl-devel		| IO::Sockecket::SSL -> Net::SSLeay のインストールに必要
# tar,patch,gcc		| 少なくとも pleenv のインストールに必要
# perl-devel		| vender perl 向けの ExtUtils::MakeMaker が入っていないと plenv による perl ビルドでコケる場合があるためインストール
# make				| plenv で perl をインストールするのに必要
# sudo				| yum info,install など何かと必要
# libxml2-devel		| XML::Simple や XML::Parser 等のインストールに必要
# expat-devel		| XML::Parser が依存
# mysql-community-devel	| DBD::MySQL に必要

# EPEL リポジトリからインストールするもの
RUN yum --enablerepo=epel -y install inotify-tools


################################################################################
## plenv

# plenv 本体のインストール
WORKDIR $DOCKER_HOME
RUN curl -sL https://github.com/tokuhirom/plenv/archive/master.tar.gz -o plenv.tar.gz && \
	mkdir ~/.plenv && \
	tar --directory ~/.plenv --strip-components=1 -zxvf plenv.tar.gz && \
	rm plenv.tar.gz

# plenv で perl をビルドするためのプラグイン 2 種をインストール
# Plugins such as perl-build and plenv-contrib will need to be installed into ~/.plenv/plugins similarly.
RUN curl -sL https://github.com/tokuhirom/Perl-Build/archive/master.tar.gz -o perl-build.tar.gz && \
	mkdir -p ~/.plenv/plugins/perl-build && \
	tar --directory ~/.plenv/plugins/perl-build --strip-components=1 -zxvf perl-build.tar.gz && \
	rm perl-build.tar.gz

RUN curl -sL https://github.com/miyagawa/plenv-contrib/archive/master.tar.gz -o plenv-contrib.tar.gz && \
	mkdir -p ~/.plenv/plugins/plenv-contrib && \
	tar --directory ~/.plenv/plugins/plenv-contrib --strip-components=1 -zxvf plenv-contrib.tar.gz && \
	rm plenv-contrib.tar.gz

# plenv を使うためのツールと仕組みを作成
RUN {\
		echo '#!/bin/sh' ; \
		echo 'export PATH="$HOME/.plenv/bin:$PATH"' ; \
		echo 'eval "$(plenv init -)"' ; \
	} >> ~/.bash_profile

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# plenv での perl インストール

RUN source ~/.bash_profile && \
	plenv install $LOCAL_PERL_VERSION && \
	plenv local $LOCAL_PERL_VERSION && \
	curl -L https://cpanmin.us | perl - App::cpanminus && \
	plenv rehash && \
	cpanm Carton && \
	rm -rf $HOME/.cpanm/work/*

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# carton で CPAN モジュールをインストール
COPY ./cpanfile $DOCKER_HOME/cpanfile
RUN source ~/.bash_profile && \
	carton install

RUN echo "export PERL5LIB=$HOME/local/lib/perl5" >> ~/.bash_profile

################################################################################
# 締め
USER root
## タイムゾーン関係（zlib 更新などで書き換えられてしまうため最後の方でやった方がよい）
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

WORKDIR $DOCKER_HOME/scripts
USER $LOCAL_USER_NAME
RUN echo "export PS1='\[\e[34m\][\[\e[0m\]\[\e[0;39m\]\u\[\e[00m\]@\[\e[30;04;01;46m\]\h\[\e[0m\] :\W\[\e[34m\]]\[\e[0m\] \$ '" >> ~/.bash_profile

