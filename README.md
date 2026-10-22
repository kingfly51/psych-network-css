# psych-network-css

面向 Claude Code 和 Codex 的心理网络分析资源包。包含五个相互独立的分析 skill，分装在两个插件中：横断面网络分析、横断面网络比较、交叉滞后面板网络（CLPN）、横断面 NIRA 计算机模拟干预、KimNIRA 动态模拟干预。每项功能都有对应的精简 R 教程。

所有流程以数据结构和研究问题为起点，控制默认分析数量与计算量；可选分析不自动铺开。学术报告范围默认为 `2.4 Data Analysis` 与 `3 Results`，只报告实际运行且可追溯的结果。网络关联或模拟结果不表述为因果效应或已证实的治疗效果。

## 五项功能

| 分析 | 数据/问题 | 教程 |
|---|---|---|
| 横断面网络 | 单次测量；按节点类型选择 GGM、Ising 或 MGM 等适用模型；含节点审查、可预测性、中心性与按需桥接分析 | `network_analysis_template.R` |
| 横断面网络比较 | 两个或多个独立组；统一节点、编码和估计设置后进行网络比较 | `network_comparison_tutorial.R` |
| 交叉滞后面板网络（CLPN） | 同一参与者至少两波、宽格式数据；正则化节点回归估计相邻波次预测关联 | `clpn_tutorial.R` |
| 横断面 NIRA 模拟干预 | 真正的二分类横断面 Ising 网络；小网络优先解析解，网络较大时再考虑 Monte Carlo | `analytical_nira_tutorial.R`；Monte Carlo 模板为可选 |
| KimNIRA 动态模拟干预 | 按时间排序的密集二分类 EMA/ESM 长格式数据；个体内动态网络 | `kimnira_tutorial.R` |

解析枚举计算精确模型状态结果，但不会消除参与者抽样不确定性；参与者 bootstrap 是另一类不确定性评估。KimNIRA 的 exact 状态空间也随节点数指数增长，超过包的限制时才考虑 Monte Carlo。默认不自动运行多套剂量、方向、诊断或稳定性套餐。

## 插件与调用

### Claude Code

插件：`psych-network-analysis`（前三项）、`psych-network-simulation`（后两项）。自然语言可直接触发；也可显式调用：

```text
/psych-network-analysis:analyze D:/project/data.xlsx
/psych-network-analysis:compare-cross-sectional-networks D:/project/data.xlsx
/psych-network-analysis:analyze-cross-lagged-panel-network D:/project/panel.xlsx
/psych-network-simulation:simulate-network-intervention D:/project/binary.xlsx
/psych-network-simulation:simulate-dynamic-network-intervention D:/project/ema.xlsx
```

从 GitHub Marketplace 安装：

```text
/plugin marketplace add kingfly51/psych-network-css
/plugin install psych-network-analysis@psych-network-css
/plugin install psych-network-simulation@psych-network-css
/reload-plugins
```

### Codex

插件：`psych-network-css`（前三项）、`psych-network-simulation`（后两项）。可自然语言调用，或使用：

```text
$analyze-cross-sectional-network
$compare-cross-sectional-networks
$analyze-cross-lagged-panel-network
$simulate-network-intervention
$simulate-dynamic-network-intervention
```

从本地资源包安装（在包根目录运行）：

```text
codex plugin marketplace add .
codex plugin add psych-network-css@psych-network-css
codex plugin add psych-network-simulation@psych-network-css
```

如网络可用，也可在 Codex 的“添加插件市场”窗口填写 GitHub 来源 `kingfly51/psych-network-css`；两个插件分别是 `psych-network-css` 与 `psych-network-simulation`。安装后新建任务以加载新 skill。

## 数据准备

- 横断面：每行一名参与者、每列一个节点；说明类别类型、计分方向、缺失编码和节点标签。
- 网络比较：增加组别列，明确组间独立；同一节点须在各组采用一致定义/编码。
- CLPN：每行一个参与者，包含 ID 和至少两波相同节点的列，如 `Dep_T1`、`Dep_T2`；说明失访和缺失处理。
- 横断面 NIRA：节点须为有意义且方向一致的 0/1；说明单网络或干预社区/结果社区及结果总分定义。
- KimNIRA：每行一次 EMA/ESM 观测，含参与者 ID、日/时间顺序以及二分类节点；确认是否跨夜连接相邻观测。

不要仅依据 Excel 中“数字”格式判断测量类型，也不要未经说明就二分化连续/有序节点。若数据字典、节点方向或研究设计无法确定，技能会先标出必要问题。

## 文件结构

```text
psych-network-css/
├── .claude-plugin/marketplace.json
├── .agents/plugins/marketplace.json
├── plugins/
│   ├── psych-network-analysis/   # Claude：横断面、比较、CLPN
│   ├── psych-network-css/        # Codex：横断面、比较、CLPN
│   └── psych-network-simulation/ # Claude/Codex：NIRA、KimNIRA
└── README.md
```


