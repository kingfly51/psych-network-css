# Psychological Network Analysis for Claude Code

一个面向心理学、精神病学、护理学及相关健康研究的 Claude Code 插件市场。目前包含 `psych-network-analysis` 插件，用于在 R 中完成可复现的横断面心理症状网络分析，并生成分析代码、结果表、学术图形以及论文的 **2.4 Data Analysis** 和完整 **3 Results**。

## 功能

- 自动检查数据结构、变量类型、缺失值、稀疏类别和节点信息量；
- 检查重复或潜在冗余节点，并输出节点审查表；
- 根据节点类型选择网络模型：
  - 连续变量：Gaussian Graphical Model（GGM）；
  - 有序变量：基于 polychoric correlation 的 ordinal GGM；
  - 二分类变量：Ising model；
  - 混合变量：Mixed Graphical Model（MGM）；
- 将社会人口学和临床协变量仅用于控制混杂；
- 绘制带节点可预测性圆环的症状网络图；
- 输出 Strength、Expected Influence 等中心性指标；
- 进行边权精确性、差异检验和 case-dropping 稳定性检验；
- 在存在预先定义的症状类别时进行桥接网络分析和桥接稳定性检验；
- 输出调整与未调整网络的敏感性比较；
- 根据实际分析结果撰写符合学术规范的方法和结果部分；
- 保留分析决策、数据处理记录、软件版本和结果追踪信息。

## 分析范围

本插件仅用于横断面心理症状网络分析。

协变量只用于控制预先指定的混杂因素。协变量不会作为核心症状、桥接症状或干预靶点进行解释，也不会参与症状中心性排名。

以下分析不属于当前插件范围，计划由其他独立插件处理：

- 调节网络分析；
- 不同人群或时间点之间的网络比较；
- 纵向网络、时间网络和个体内网络；
- 因果发现或有向网络；
- 干预网络和动态网络。

## 数据要求

支持以下文件：

- Excel：`.xlsx`、`.xls`；
- CSV：`.csv`；
- SPSS：`.sav`；
- Stata：`.dta`；
- R：`.rds`。

数据应采用参与者 × 变量的矩形结构：

- 每行代表一名参与者或一次独立观察；
- 每列代表一个症状、协变量或其他研究变量；
- 第一行必须是唯一的变量名；
- 不应包含合并单元格、多行表头、合计行或脚注行；
- 特殊缺失值编码（例如 `-99`、`999`）需要明确说明；
- 反向计分、维度合成和节点选择规则需要能够追溯。

推荐提供节点信息表：

| 字段 | 含义 | 示例 |
|---|---|---|
| `variable` | 数据中的列名 | `PHQ1` |
| `short_label` | 网络图英文短标签 | `LowMood` |
| `full_english_label` | 完整英文名称 | `Depressed mood` |
| `community` | 症状类别 | `Depression` |
| `measurement` | 测量类型 | `ordinal` |

## 协变量控制

插件支持两类混杂控制思路：

1. **残差化**：仅在症状节点均为连续变量且条件均值模型合理时使用。每个症状使用同一组预设协变量进行回归，然后基于残差估计症状网络。
2. **联合条件调整**：症状或协变量包含二分类、有序或混合类型时，使用适合变量类型的联合条件模型，并只提取症状—症状子网络。

协变量不能仅因为单因素检验达到 `p < .05` 而被纳入。应根据研究问题、既往证据或明确的混杂路径预先确定。

协变量调整必须在每一次 bootstrap 重抽样中重新执行。插件的通用 R 模板对此采用失败关闭策略，避免错误地对一组固定残差进行 bootstrap。

## 安装

### 从 GitHub Marketplace 安装

将下面的 `YOUR_GITHUB_USERNAME` 和仓库名替换为实际地址：

```text
/plugin marketplace add YOUR_GITHUB_USERNAME/psych-network-marketplace
```

安装插件：

```text
/plugin install psych-network-analysis@psych-network-tools
```

重新加载：

```text
/reload-plugins
```

### 本地开发加载

在仓库根目录运行：

```powershell
claude --plugin-dir ./plugins/psych-network-analysis
```

## 使用

插件支持自然语言自动调用。安装后可以直接说：

```text
请对当前目录的数据进行横断面心理症状网络分析。
```

包含协变量时：

```text
请对 data.xlsx 进行横断面心理症状网络分析，并将年龄、性别和教育程度作为混杂因素控制。
```

也可以强制指定技能和数据文件：

```text
/psych-network-analysis:analyze D:/project/data.xlsx
```

## 主要输出

典型分析目录包括：

- `analysis.R`：可复现的 R 分析脚本；
- `sessionInfo.txt`：R 和软件包版本；
- `model_decision.txt`：模型选择及理由；
- `covariate_decision.txt`：协变量选择、编码和调整策略；
- `data_flow_log.csv`：样本排除和数据处理记录；
- `node_audit.csv`：节点类型、分布、缺失和冗余检查；
- `edges.csv`：非零边及边权；
- `centrality.csv`：症状中心性指标；
- `stability.csv`：bootstrap 与 CS 系数结果；
- `bridge_centrality.csv`：桥接指标（适用时）；
- PDF 和高分辨率 PNG/TIFF 网络图；
- `manuscript_sections.md`：论文 2.4 Data Analysis 和 3 Results。

## 解释原则

- 横断面网络中的边表示条件关联，不表示因果关系；
- 中心性高不等于已经证明是最佳干预靶点；
- Expected Influence 优先用于包含正负边的网络；
- Closeness 和 Betweenness 只有在稳定性充分时才解释；
- 桥接指标仅在症状类别具有理论依据时使用；
- 所有论文结果必须能够追溯到实际输出表格，禁止生成不存在的统计量。

## R 依赖

主要使用以下 R 软件包：

```r
c(
  "bootnet", "qgraph", "networktools", "mgm", "readxl", "haven",
  "readr", "dplyr", "tidyr", "purrr", "tibble", "stringr", "moments"
)
```

最终依赖会根据数据类型和所选估计器调整。正式分析建议至少运行 1,000 次 bootstrap；少量 bootstrap 只能用于试运行。

## 当前限制

- 插件不会自动证明协变量是真正的混杂因素；
- 联合条件协变量调整需要根据具体变量类型选择并验证估计器；
- 通用模板不能替代研究者对节点含义、量表计分和协变量选择的确认；
- 小样本、高维节点、极端类别不平衡和大量缺失可能导致网络不稳定；
- 当前插件不替代统计咨询、研究设计审查或因果推断。

## 仓库结构

```text
psych-network-marketplace/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   └── psych-network-analysis/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── assets/
│       ├── references/
│       └── skills/
│           └── analyze/
│               └── SKILL.md
└── README.md
```

## 方法学参考

- Burger, J., et al. (2023). Reporting standards for psychological network analyses in cross-sectional data. *Psychological Methods, 28*(4), 806–824. https://doi.org/10.1037/met0000471
- Epskamp, S., Borsboom, D., & Fried, E. I. (2018). Estimating psychological networks and their accuracy: A tutorial paper. *Behavior Research Methods, 50*, 195–212. https://doi.org/10.3758/s13428-017-0862-1
- Haslbeck, J. M. B., & Waldorp, L. J. (2018). How well do network models predict observations? *Behavior Research Methods, 50*, 853–861. https://doi.org/10.3758/s13428-017-0910-x
- Jones, P. J., Ma, R., & McNally, R. J. (2021). Bridge centrality: A network approach to understanding comorbidity. *Multivariate Behavioral Research, 56*(2), 353–367. https://doi.org/10.1080/00273171.2019.1614898

## 安全说明

插件不包含 MCP server 或 hooks。分析前请检查插件内容，并避免将包含敏感参与者信息的原始数据提交到公开仓库。
