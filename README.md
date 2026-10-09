Code Agent - 代码生成智能体
基于 LLM Function Calling 的代码生成智能体，采用 ReAct（Reasoning + Acting）设计模式，能够自主编写、执行、调试和保存 Python 代码。

功能特性
完整的 Agent 循环：输入 → 推理 → 工具调用 → 观察结果 → 修正 → 输出
代码执行工具：在隔离子进程中执行 Python 代码，带超时保护
文件读写工具：将生成的代码保存到 output/ 目录
上下文记忆：支持多轮对话，Agent 能记住之前的执行结果
错误处理与重试：LLM 调用失败自动指数退避重试；代码执行错误自动回传给 LLM 自我修正
命令行交互：纯 CLI，零额外依赖界面
快速开始
1. 安装依赖
pip install -r requirements.txt
2. 配置 API Key
复制 .env.example 为 .env，填入通义千问 API Key：

cp .env.example .env
编辑 .env：

DASHSCOPE_API_KEY=sk-你的key
API Key 获取地址：https://dashscope.console.aliyun.com/

3. 运行
python main.py
4. 示例对话
你: 写一个 Python 函数计算斐波那契数列的第 n 项，并测试 n=10 的结果

Agent: [自动编写代码 → 执行验证 → 保存文件 → 给出答案]

你: 再写一个快速排序算法，用随机数组测试

Agent: [同上流程...]
输入 exit 退出，clear 清空对话历史。

项目结构
code-agent/
├── main.py                  # CLI 入口
├── requirements.txt         # Python 依赖
├── .env.example             # 环境变量模板
├── README.md                # 项目说明（本文件）
├── Design.md                # 设计文档
├── output/                  # Agent 生成的代码输出目录
└── agent/
    ├── core.py              # Agent 核心循环（ReAct）
    ├── llm.py               # LLM 客户端（通义千问 + 重试）
    ├── memory.py            # 对话记忆管理
    ├── prompts.py           # 系统提示词
    └── tools/
        ├── __init__.py      # 工具注册与分发
        ├── python_executor.py  # Python 代码执行器
        └── file_tool.py     # 文件读写工具
技术栈
语言：Python 3.10+
LLM：通义千问（DashScope OpenAI 兼容模式）
SDK：openai-python（兼容模式）
架构：手写 ReAct 循环，无重型框架依赖
配置项
环境变量	默认值	说明
DASHSCOPE_API_KEY	-	通义千问 API Key（必填）
DASHSCOPE_BASE_URL	https://dashscope.aliyuncs.com/compatible-mode/v1	API 地址
DASHSCOPE_MODEL	qwen-plus	模型名称
MAX_AGENT_TURNS	10	单次任务最大推理轮数
CODE_EXEC_TIMEOUT	15	代码执行超时（秒）
