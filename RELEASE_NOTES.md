# v0.1.0 · BSL 10.1.8 简体中文覆盖补丁与 1070 Ti 优化魔改补丁

**先从 [BSL 官网](https://capttatsu.com/bslshaders/)／[官方下载入口](https://capttatsu.com/bslshaders/download.html) 下载原版 BSL 10.1.8，再安装补丁。** [对应官方 Modrinth 版本](https://modrinth.com/shader/bsl-shaders/version/Y68yiql9)。原作者：Capt Tatsu。

## 普通用户：纯汉化覆盖包

下载 `BSL_10.1.8_zhCN_Overlay_v0.1.0.zip`。解压官方原包，将补丁中的 `shaders` 文件夹复制进去合并／覆盖，再把合并后的光影放入 `shaderpacks`。在游戏中选择“简体中文”。只修改语言，不修改渲染算法。

## 可选：1070 Ti 优化魔改补丁

下载 `BSL_10.1.8_zhCN_1070Ti_ModPatch_v0.1.0.zip`，完整解压，双击 `应用优化魔改.cmd`，选择官网下载的原版 ZIP。工具会校验版本、生成并覆盖本地改动，在原 ZIP 旁输出 `BSL_v10.1.8_zhCN_1070Ti.zip`；原版保留。把输出包放入 `shaderpacks`，在光影设置中选“1070 Ti｜保真均衡”。

**这是非官方魔改版，不适用于所有显卡。** 提供保真均衡、高帧流畅、近景彩光、PBR 近景四档；允许自调反射步数和柔和阴影采样。减少开销会损失部分远处投影或细节。彩光档需要支持该功能的 Iris，PBR 档需要对应资源包。其他显卡、驱动和模组环境需自行验证，不保证高帧或固定 FPS。

## 此版修复与验证

修复初版中文 `.properties` 注释导致的 Iris 预处理异常及 `shadowcomp` 连带报错。语言、配置引用、采样归一化、官方原包匹配与 Windows 补丁生成检查已通过。游戏重载验证结果见仓库的验证说明；尚无受控性能实测。

此发布只提供补丁，**不包含完整原光影代码和纹理**。两个 ZIP 各自附带安装说明，`SHA256SUMS.txt` 提供校验值。[完整说明](https://github.com/QianLieXian/BSL-zhCN-Patch#readme)。
