---
title: 在 Ubuntu 云服务器上搭建 Discourse 论坛
tags: 
  - Discourse
  - Ubuntu
  - mailjet
  - Docker
categories: Programming
comment: true
toc: true
date: 2020-12-04 15:21:22
---

{% alert success %}
基于腾讯云的 Discourse 论坛搭建.
{% endalert %}
<!-- more -->

Discourse 论坛是近些年来比较流行的一款开源论坛应用程序，拥有很完善的用户互动和管理员功能，也提供了丰富的插件和扩展入口。

笔者认为论坛形式是促进学术交流的一个非常重要的手段，以往课题组同学老师之前交流一般都是在线下或者微信群，不利于记录和搜索，不利于知识积累和知识库的构建，因此考虑使用这款开源应用搭建一个用于课题组同学内部交流的论坛.

这里简单记录笔者的 Discourse 论坛搭建流程，使用的是官方提供的 Docker 容器安装方法.

## 准备工作

域名和云服务器是搭建网站的一般操作。因为这个页面就是搭在 [腾讯云](https://console.cloud.tencent.com/) (TC) 上的，因此这里域名和云服务器都是用的 TC.

Discourse 比较特殊的地方是它需要邮件服务器进行通讯，包括用户注册和网站备份下载，因此我们也需要一个免费的邮件服务器。这里我使用的是 [mailjet](https://app.mailjet.com/).

### 云服务器

笔者购买的是单核 2GB, 带宽 3M 的轻量应用服务器，对于小规模的论坛和网站是比较合适的。系统选择 Ubuntu 20.04 LTS. 亲测 CentOS 和 Fedora 在安装 Docker 过程中会遇到一些问题，比如无法找到 `docker.io` 命令等。在 Ubuntu 上基本是一次通过的。为方便说明，这里假设服务器公网 IP 为 `m.n.p.q`.

### 域名解析

按照自己喜好和预算购买域名即可。唯一可能需要注意的是 Discourse 对 `.work` 域名的解析似乎很慢，在初始化 Discourse 时出现无法解析域名的情况，故不推荐。此外建议尽快进行域名实名认证，否则容易被管局封停，进入 `serverHold` 状态而无法解析，这之后不仅需要实名还需要进行备案，比较麻烦.

为了方便后面的说明，这里假设注册的域名为 `domain.abc`. 在 DNS 记录中添加主机名分别为 `@` 和 `discourse`, 值均为 `m.n.p.q` 的 `A` 记录.

### 邮件服务器

在 mailjet 上注册账户，注册成功后就可以看到自己的 SMTP 用户名和密码，需要在初始化 Discourse 时填入.

![mailjet 设置界面](mailjet_smtp.png)

进入发送域名管理页面 [`account/sender`](https://app.mailjet.com/account/sender), 点击 `Add Domain`, 在 `example.com` 的地方输入 `discourse.domain.abc`, 继续. 下面需要用 DNS TXT 记录验证域名。回到 TC 控制台，在域名管理中添加 TXT 记录，主机为 `mailjet._xxxxx.discourse`, `xxxxx` 和值都是 mailjet 自动分配的。添加完后稍等几秒，回到 mailjet 页面，点 `Check now` 就通过了.

为了保证邮件发送的稳定性，在设置完 SMTP 后再配置 SPF/DKIM 域名验证。进入 [`domain_info`](https://app.mailjet.com/account/sender/domain_info/), 根据指示，回到 TC 控制台添加两条 TXT 记录。保存后回到 mailjet, 点 `FORCE REFRESH`, 出现两个绿色块就说明验证通过了.

![验证通过](mailjet_pass.png)

到此为止网络配置大致完成。配置完后的 DNS 记录页面大致如下

![设置完成邮件服务器后的 TC 控制台](tc_console.png)

## 安装

### 初始化系统环境

SSH 登录 TC 服务器。由于 TC 不支持 root 登录，需要用 ubuntu 用户登录后首先初始化 su 密码，再用 su 进入 root 权限，即

```bash
sudo passwd root
su
```

随后安装最新的 Docker 环境

```bash
apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic test"
apt update
apt upgrade
```

如此一来系统环境配置完成.

### 初始化 Discourse

克隆官方的 Docker 安装器到 `/var/discourse/` 下，运行初始化脚本

```bash
git clone https://github.com/discourse/discourse_docker.git/var/discourse
cd /var/discourse
./discourse-setup
```

根据提示输入信息

```text
Hostname for your Discourse? [discourse.example.com]: discourse.domain.abc
Email address for admin account (s)?: zmysmile0929@gmail.com
SMTP server address? [in-v3.mailjet.com]: in-v3.mailjet.com
SMTP port? [587]: 587
SMTP user name? [reply@example.com]: <mailjet-API>
SMTP password? [pa$$wd]: <mailjet-secret>
Optional email address for Let's Encrypt warnings? (ENTER to skip) [me@example.com]:
```

其中 `<mailjet-API>` 和 `<mailjet-secret>` 使用 mailjet 用户界面给出的值. admin 账户可以输入多个邮件，在初始化时。输入完成后，安装程序自动执行。安装结束后在浏览器输入 `discourse.domain.abc`, 如果出现了撒花页面就表示成功了 :P

### 插件安装

启用论坛插件需要两步。首先，修改 `container/app.yml` 安装插件，具体办法是在 `after_code` 后面添加 Git 命令:

```yaml
hooks:
after_code:
    - exec:
        cd: $home/plugins
        cmd:
        - git clone https://github.com/discourse/docker_manager.git
        - git clone https://github.com/discourse/discourse-math.git          # MathJax/KaTeX 数学支持
        - git clone https://github.com/discourse/discourse-footnote.git      # 脚注
        - git clone https://github.com/discourse/discourse-checklist.git     # 代办列表
        - git clone https://github.com/discourse/discourse-bbcode-color.git  # 颜色代码环境
```

然后运行

```bash
./launch rebuild app
```

重新构建论坛。构建完成后，从浏览器进入管理界面，在如图所示的插件标签下，点击想要启用的插件的设置按钮，勾选启用即可.

![开启插件 (并未包含上述全部插件) ](switch_on_plugins.png)
