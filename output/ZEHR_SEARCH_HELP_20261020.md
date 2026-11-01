# SAP 通用搜索帮助接口提炼说明

本包提取现有 SAP 搜索帮助查询逻辑，并保留 Java Web 可调用的通用 RFC 网关。ZIP 根目录与原 abapGit 导出一致，为 `.abapgit.xml` 和 `src/`。对象名称沿用原系统。

## 提炼范围

通用函数组 `ZEHR_FG_COMM` 保留以下 9 个函数。PA 和 PE 的表单、人员业务处理、组织树和页面权限包装不在本次通用接口范围内。

| 函数 | 用途 |
| --- | --- |
| `ZFM_EHR_COMM_SEARCH_HELP` | 按搜索帮助编号读取配置并分派查询 |
| `ZFM_EHR_GET_SHLP_FR_DOMAIN` | 查询域固定值 |
| `ZFM_EHR_GET_SHLP_FR_TABLE` | 按配置查询数据表或关联表 |
| `ZFM_EHR_GET_SHLP_FR_SHLP` | 调用 SAP 搜索帮助 |
| `ZFM_EHR_GET_SHLP_FR_SUBTY` | 查询 HR 信息类型子类型 |
| `ZFM_EHR_IF_COM` | 接收接口编号和 JSON 参数，动态调用目标函数；元数据标记为 RFC |
| `ZFM_EHR_GET_FUNC_INFO` | 读取目标函数的参数定义 |
| `ZFM_EHR_JSON_TO_ABAP` | 使用 `/UI2/CL_JSON` 反序列化参数 |
| `ZFM_EHR_ABAP_TO_JSON` | 原有序列化函数，当前导出版本的有效实现为空 |

包内同时包含搜索帮助配置表 `ZTHR0015`、文本表 `ZTHR0015T`、返回结构 `ZSHR_F4_TAB`、条件结构 `ZSHR_F4_CONDITION`、数据元素和域，以及网关使用的接口配置、参数和日志定义。配置维护代码包含 `ZVHR0015`、`ZTHR0015D`、`ZTEHR0001` 三个函数组，以及 `ZEHR_F4HELP` 和 `ZEHR_INTERFACE` 事务码。

自定义函数来源 `F` 保留原有动态调用能力。实际调用哪个业务函数由配置表记录决定；配置命名的业务函数属于接入该搜索帮助时需要提供的扩展。

## 来源和裁剪

主来源为用户指定的 `ZEHR_20260608_155344.zip`。该包没有包含若干基础字典对象，因此补入同项目目录的 `ZHR002_20260106_195330.zip` 中的原始定义。

共 106 个文件：57 个来自 ZEHR 导出，49 个来自 ZHR002 导出。逐文件来源、SHA256 和处理方式见同目录的 `ZEHR_SEARCH_HELP_20261020.manifest.json`。该清单保留了两个来源包的完整路径及哈希。

9 个函数的 ABAP 源码保持原样。为使提取后的函数组只依赖这条调用链，调整了以下 5 个文件：

- `zehr_fg_comm.fugr.xml`：只保留上述函数定义和 4 个需要的 Include。
- `zehr_fg_comm.fugr.lzehr_fg_commf01.abap`：保留原文件第 1 至 61 行，即域查询和表查询两个 FORM。
- `zehr_fg_comm.fugr.lzehr_fg_commtop.abap`：保留函数池声明，移除被排除程序才使用的全局声明。
- `zehr_fg_comm.fugr.saplzehr_fg_comm.abap`：保留 TOP、系统生成的 UXX、F01 和 F02 引用。
- `zehr_fg_comm.fugr.saplzehr_fg_comm.xml`：移除未使用的邮件文本池。

其余 101 个文件与各自来源 ZIP 中的内容逐字节一致。所有保留的函数接口元数据与原导出一致。

## Java 调用契约

源码中可确认的调用链为：

```text
Java 或现有中间层
  → ZFM_EHR_IF_COM
  → ZTEHR0001 中 IFNUM 对应的 IFNAM
  → ZFM_EHR_COMM_SEARCH_HELP
  → ZTHR0015 中 SHHID 对应的查询配置
  → D 域固定值、T 数据表、H SAP 搜索帮助、S HR 子类型、F 扩展函数
  → ET_SHH_DATA
```

Java 的现有传输实现没有随 ABAP 包提供，需在 Java 项目中确认。`ZFM_EHR_COMM_SEARCH_HELP` 本身未标记为 RFC；沿用该代码时，远程入口为 `ZFM_EHR_IF_COM`。

| 参数 | 含义 |
| --- | --- |
| 网关 `IV_IFNUM` | `ZTEHR0001` 中映射到搜索帮助函数的实际接口编号 |
| 网关 `IV_INPUT` | 参数数组的 JSON 字符串，数组元素字段为 `PNAME`、`VALUE` |
| 查询 `IV_SHHID` | `ZTHR0015` 中的实际搜索帮助编号 |
| 查询 `IT_SHH_CONDITION` | 条件表，字段为 `FIELD`、`VALUE`；经网关传入时，VALUE 中再次存放该表的 JSON 字符串 |
| 查询 `IV_USER` | 可选人员编号，HR 子类型分支会使用 |
| 查询 `IV_DATUM` | 默认系统日期；当前实现仅直接传给 F 分支 |
| 查询 `IV_LANGU` | 声明默认系统语言，但通用入口实际向下传递 `SY-LANGU` |
| 查询 `IV_ZVERS` | 默认 `28`，用于国家分组相关查询 |

`ET_SHH_DATA` 的行结构为 `KEY` 和 `VALUE`。补齐的原始定义中，KEY 对应 `ZEHR_KEY`，域为 `CHAR40`；VALUE 对应 `ZEHR_VALUE`，域为 `TEXT100`。

## 导入和运行条件

ZIP 可作为 abapGit 离线仓库的代码导入包。应先在隔离的测试环境中导入并激活，尤其需要核对已经存在的同名 `ZEHR_FG_COMM`：本包保留的是该函数组的一个子集，不能将它当作原完整 HR 函数组的更新包直接覆盖使用。

运行前需要准备以下内容：

1. 目标系统具有源码调用的 SAP HR 标准对象、标准函数和 `/UI2/CL_JSON`。
2. 从原系统补充 `ZTHR0015`、`ZTHR0015T` 的搜索帮助配置记录，以及 `ZTEHR0001` 的接口编号映射。两个来源 ZIP 均没有提供这些表的数据记录。
3. 对配置中命名的数据表、搜索帮助和 F 分支业务函数，提供对应对象。无法仅凭表定义枚举实际使用的扩展。
4. 如启用 `ZTEHR0001-IFLOG`，目标系统需具有 `ZEHR_IFLOG` 号码范围对象及 `01` 区间。来源包没有该号码范围的导出文件。
5. 检查配置维护界面的目标系统登记状态。`ZTEHR0001` 的维护函数组源码存在，但来源导出中没有与它对应的 TOBJ 注册对象；需要时可在目标系统重新生成表维护。

`ZFM_EHR_ABAP_TO_JSON` 在本次来源中的函数体只有被注释的旧实现，没有有效序列化语句。因此，该导出版本的网关无法正常产生 JSON 返回。此次按原代码提炼，保留了这个状态；正式联调前必须补齐序列化实现。

通用查询中也保留了原项目对 `00019`、`00115`、`PM005` 的特殊处理、排序和空选项行为。PA 包装层中的子类型权限裁剪、PA 和 PE 的组织树处理没有并入通用层。

## 核验范围

本地核验覆盖 ZIP 完整性、根目录布局、XML 可解析性、函数与 Include 的元数据配对、原始文件哈希、保留函数的源码及接口一致性，以及静态自定义依赖检查。此次扫描未发现缺失的静态自定义引用。

SAP 激活、abapGit 实际导入和 Java 端联调需要目标 SAP 环境，本地未执行；上述核验不代表已经通过 SAP 运行验证。
