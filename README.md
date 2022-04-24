# MIXBOX 

![](https://github.com/monlor/MIXBOX/workflows/Main-CI/badge.svg)

> MIXBOX是一款全新的，完全基于Shell脚本的工具箱，为在路由器上实现程序的快速配置及运行管理，欢迎大佬们stars、fork及pr.

* Telegram群：[MIXBOX CHAT](https://t.me/mixboxchat)
* 我的博客：[Monlor's Blog](https://www.monlor.com)，[备用地址](https://monlor.github.io)
* GitHub地址：[monlor/MIXBOX](https://github.com/monlor/MIXBOX)

***

### [更新日志](https://github.com/monlor/MIXBOX/blob/master/changelog.md)

### 2022-04-25
* 更新frp版本0.42.0
* 【测试版】添加插件[aliyundrive-fuse](https://github.com/messense/aliyundrive-fuse), [LingMaxDns](https://www.right.com.cn/forum/thread-8137820-1-1.html)

#### 2022-04-18
* 由于部分地区安装失败，现在新增 ghproxy 源、github.do 源
* 如果还是安装失败，可能因为 CDN 未同步，请在24小时后继续尝试，或者尝试其他源

### 介绍

**工具箱`MIXBOX`公测发布，`Monlor Tools`不再更新。新版本有以下改变：**
* MIXBOX
	* 工具箱尝试支持更多的路由器固件，正在努力中，需要测试
	* 去掉随时可能被小米封的web界面
	* 移除针对小米路由器设置的功能，如修改samba路径和禁用迅雷等，合并到新的插件`MIWIFI`
	* 增加一个应急功能，在用户目录创建文件`uninstall_mixbox`即可卸载工具箱
	* 增加几个工具箱常用命令，`applist`:用于管理插件列表，`cru`:定时任务管理，`mbdb`:工具箱数据库，基于uci，`mixbox`:工具箱命令行交互界面
	* 工具箱增加目录，`/etc/mixbox/mbdb`:存放数据文件，`/etc/mixbox/var/run`:存在程序进程pid文件，`/etc/mixbox/var/log`:工具箱日志目录
	* 工具箱现在不会特意去兼容某个型号，比如`R3`上的`Aria2`问题，只考虑`CPU`架构，`mips`/`arm`等，所以如果`R3`/`R1CM`发现程序不兼容的情况，可以选择自己替换程序，或同时安装`Monlor-Tools`工具箱
	* 插件安装去掉了离线安装的功能，后续会加入进来，给用户提供一个自己修改打包插件的机会


* ShadowSocks
	* 订阅现在会多次尝试，如已安装`EntWare`中的`curl`程序会自动调用用作订阅
	* 现已支持`v2ray`并测试黑白名单和全局模式，正常使用，v2ray订阅暂不支持
	* 已支持`kcptun`加速功能，`ss`和`kcp`需为同一个服务器，否则不启用
	* 优化添加`ss`节点时的提示信息
	* 增加`haveged`程序，用于生成随机数


* KoolProxy
	* 由于作者更新程序修改了视频模式的启用方式，更新了启动脚本
	* `https`证书生成不再使用`openssl`程序，而使用`kp`自带程序生成


* 新增插件
	* AliDDNS：获取当前网络的ip，自动解析到阿里云
	* BaiduPCS：第三方百度网盘下载工具，带web界面
	* DropBear：移植小米路由器的`SSH`功能到工具箱
	* Frps：快速搭建`frp`服务端
	* PPTPD：快速搭建`vpn`服务器，基于`EntWare`环境
	* SmartDNS：智能`dns`解析，从多个上游`dns`服务器中选取最快的解析地址
	* SSServer：搭建`ss`服务器
	* Transmission：强大的`pt`下载工具，基于`EntWare`环境
	* WebD：极其小巧的网盘工具，功能比较简单


* 其他等等等小更新...


### 注意事项

* 用户目录是指存放一下大文件的目录，如下载的文件等
* **经测试`R3`不支持`EntWare`环境，原因未知，所以基于`EntWare`的程序都无法使用**
* **0.1.9.7以前的版本请手动更换下载源**，步骤：mixbox => 工具箱管理 => 更换下载源 => 输入以下地址
```
https://cdn.jsdelivr.net/gh/monlor/mbfiles
```
* 默认源更换为jsdelivr源，coding源不再使用

### 命令

#### 本站提供的下载源，基于 cloudflare 搭建【NEW】

```shell
export MB_URL=https://g.monlor.com/https://raw.githubusercontent.com/monlor/mbfiles/master && sh -c "$(curl -kfsSl ${MB_URL}/install.sh)" && source /etc/profile &> /dev/null
```

#### ghproxy源一键安装命令【NEW】

``` shell
export MB_URL=https://ghproxy.com/https://raw.githubusercontent.com/monlor/mbfiles/master && sh -c "$(curl -kfsSl ${MB_URL}/install.sh)" && source /etc/profile &> /dev/null
```

#### github.do源一键安装命令【NEW】

``` shell
export MB_URL=https://github.do/https://raw.githubusercontent.com/monlor/mbfiles/master && sh -c "$(curl -kfsSl ${MB_URL}/install.sh)" && source /etc/profile &> /dev/null
```

#### github源一键安装命令

``` shell
export MB_URL=https://raw.githubusercontent.com/monlor/mbfiles/master && sh -c "$(curl -kfsSl ${MB_URL}/install.sh)" && source /etc/profile &> /dev/null
```

#### jsdelivr源一键安装命令

``` shell
export MB_URL=https://cdn.jsdelivr.net/gh/monlor/mbfiles && sh -c "$(curl -kfsSl ${MB_URL}/install.sh)" && source /etc/profile &> /dev/null
```

### 手动更新命令

``` shell
sh -c "$(curl -kfsSl https://cdn.jsdelivr.net/gh/monlor/mbfiles/update.sh)" && source /etc/profile &> /dev/null
```

### 手动卸载命令

``` shell
sh -c "$(curl -kfsSl https://cdn.jsdelivr.net/gh/monlor/MIXBOX/apps/mixbox/scripts/uninstall.sh)" && source /etc/profile &> /dev/null
```

#### 一键更新所有插件（请先更新工具箱）

``` shell
applist installed -n | while read line; do mixbox upgrade $line; done
```

#### 查看插件常用命令（appname为插件名）

``` shell
mixbox help
```

### 小米路由器目录结构  

```
/
|--- /etc/mixbox
|    |--- /apps/        --- 插件安装目录
|    |--- /config/      --- 工具箱配置文件目录
|    |--- /scripts/     --- 工具箱脚本目录
|    |--- /mbdb/        --- 工具箱数据文件目录
|  |--- /var/   --- 工具箱运行pid及日志存放目录
|--- /tmp
|    |--- /messages     --- 系统日志，工具箱日志
|--- /userdisk
|    |--- /data/        --- 硬盘目录
|--- /extdisks/
|    |--- /sd*/         --- 外接盘目录
```

### 插件列表

> 感谢以下插件列表中的作者给我们带来的这么好用的程序！`作者链接待完善`

01. [ShadowSocks](https://github.com/shadowsocks/shadowsocks/tree/master)
02. [KoolProxy](http://koolshare.b0.upaiyun.com/)
03. [Aria2](http://aria2.github.io/)
04. [VsFtpd](https://security.appspot.com/vsftpd.html)
05. [kms](https://github.com/Wind4/vlmcsd)
06. [Frpc](https://github.com/fatedier/frp)
07. [Ngrok](https://github.com/dosgo/ngrok-c)
08. [WebShell](https://github.com/shellinabox/shellinabox)
09. [TinyProxy](https://github.com/tinyproxy/tinyproxy)
10. [Entware](https://github.com/Entware/Entware-ng)
11. [KodExplorer](https://kodcloud.com/)
12. [EasyExplorer](http://koolshare.cn/thread-129199-1-1.html)
13. [HttpFile](http://nginx.org/)
14. [VerySync](http://verysync.com/)
15. [FastDick](https://github.com/fffonion/Xunlei-Fastdick)
16. [FireWall](https://www.netfilter.org/)
17. [JetBrains](http://blog.lanyus.com/archives/174.html)
18. [QianDao](http://koolshare.cn/thread-127783-1-1.html)
19. [FileBrowser](https://github.com/filebrowser/filebrowser)
20. [ZeroTier](https://www.zerotier.com)
21. MIWIFI
22. [AliDDNS]
23. [BaiduPCS]
24. [DropBear]
25. [Frps]
26. [PPTPD]
27. [SmartDNS]
28. [SSServer]
29. [Transmission]
30. [WebD]
31. [ttyd](https://github.com/tsl0922/ttyd)

### 快速制作插件

#### 步骤

* `git clone https://github.com/monlor/MIXBOX.git`
* `cd MIXBOX/`
* `chmod +x ./tools/*.sh`
* `./tools/newapp.sh [插件名] [插件服务名] [插件介绍]`
* 修改插件脚本和配置文件
* `./tools/gitsync.sh pack [插件名] [-v]`

#### 注意事项

* 插件名必须为小写，插件服务名一般为驼峰的写法
* 插件二进制名称建议与插件名对应，二进制名不能出现下划线，建议用横杠，如obfs-local
* 执行完插件生成脚本后，插件会生成在apps中，注意名称不能与现有插件重复

#### 请喝咖啡

|                             微信                             |                            支付宝                            |
| :----------------------------------------------------------: | :----------------------------------------------------------: |
| ![](https://cdn.jsdelivr.net/gh/monlor/file/img/20200312145215.png) | ![](https://cdn.jsdelivr.net/gh/monlor/file/img/20200312145148.png) |
