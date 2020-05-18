* 2020-05-07
	* 更换gitee为默认源 
	* coding更换lfs储存方式的文件地址，导致工具箱下载源失效
	* **注意安装命令已更换**
	* 回滚v2ray的sniff配置


* 2020-05-04
	* 更新`v2ray`配置文件，inbound 和 inboundDetour 中增加 sniffing 配置


* 2020-04-26
	* 优化工具箱离线使用
	* `vsftpd`不能使用的用户可以尝试`entware`的方式启用
	* 更新一些arm程序的二进制版本，感谢@DC提供的二进制程序


* 2020-03-06
	* 更新frps到0.31.2
	* 修复工具箱下载插件失败的问题


* 2020-03-05-2
	* 由于cdn缓存不刷新，还是滚回了`coding`源：`https://monlor.coding.net/p/mbfiles/d/mbfiles/git/raw/master`
	* 新增`DLNA`插件`DMS`
	* `Qiandao`插件bug修复


* 2020-03-05
	* 由于`coding`限制仓库容量不能大于`2G`，尝试使用`github`的`cdn`源：`https://cdn.jsdelivr.net/gh/monlor/mbfiles`
	* 最新版本里选择`github下载源`默认为`cdn`源，**推荐使用**
	* 仓库已经重置，删除了历史记录
	* 修复`EasyExployer`启动bug，更新二进制程序版本
	* 更新`BaiduPCS`二进制程序


* 2020-03-04
	* 为了减少项目体积，现在采用`Github Actions`自动部署插件安装包
	* coding下载源地址改为`https://monlor.coding.net/p/mbfiles/d/mbfiles/git/raw/master`
	* github下载源地址改为`https://raw.githubusercontent.com/monlor/mbfiles/master`
	* 这一版更新需要手动更新，请执行下方的**手动更新命令**，并手动更换下载源
	* 不想更新的以前的版本同样会保留，只是不再会更新


* 2020-03-03
	* 更新工具箱coding下载源，**请手动更换coding下载源：`https://monlor.coding.net/p/MIXBOX/d/MIXBOX/git/raw/master`**
	* 更新插件`Koolproxy`规则地址
	* 更新`qiandao`插件，现在支持更多网站签到，**并且支持mips设置，如R3**


* 2020-02-27
	* 新增插件npc，待测试
	* aria2版本更新


* 2019-03-03
	* 修复`v2ray`配置文件问题（未测试），感谢`@leafnsand`的PR
	* 修复`Entware`插件无法启动`ONMP`的问题
	* 插件`VerySync`和`BaiduPCS`的程序版本更新
	* 现在修复小米路由器远程访问后会自动开放8098端口
