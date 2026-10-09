import os
os.environ.pop("HTTP_PROXY", None)
os.environ.pop("HTTPS_PROXY", None)
os.environ.pop("ALL_PROXY", None)

import os
import sys
import logging
from dotenv import load_dotenv

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from agent.llm import LLMClient
from agent.core import CodeAgent
from agent.prompts import SYSTEM_PROMPT


def setup_logging(verbose: bool = False):
    level = logging.DEBUG if verbose else logging.WARNING
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
    )


def main():
    load_dotenv()
    setup_logging(verbose="--verbose" in sys.argv)

    api_key = os.getenv("DASHSCOPE_API_KEY", "")
    base_url = os.getenv(
        "DASHSCOPE_BASE_URL",
        "https://dashscope.aliyuncs.com/compatible-mode/v1",
    )
    model = os.getenv("DASHSCOPE_MODEL", "qwen-plus")
    max_turns = int(os.getenv("MAX_AGENT_TURNS", "10"))
    code_timeout = int(os.getenv("CODE_EXEC_TIMEOUT", "15"))

    if not api_key or api_key == "your_api_key_here":
        print("=" * 50)
        print("错误：未配置 DASHSCOPE_API_KEY")
        print("请复制 .env.example 为 .env 并填入你的 API Key")
        print("获取地址: https://dashscope.console.aliyun.com/")
        print("=" * 50)
        sys.exit(1)

    llm_client = LLMClient(api_key=api_key, base_url=base_url, model=model)
    agent = CodeAgent(
        llm_client=llm_client,
        system_prompt=SYSTEM_PROMPT,
        max_turns=max_turns,
        code_timeout=code_timeout,
    )

    print("=" * 50)
    print("  Code Agent - 代码生成智能体")
    print(f"  模型: {model} | 最大轮数: {max_turns}")
    print("  输入 'exit' 或 'quit' 退出，'clear' 清空对话")
    print("=" * 50)

    while True:
        try:
            user_input = input("\n你: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n再见！")
            break

        if not user_input:
            continue
        if user_input.lower() in ("exit", "quit"):
            print("再见！")
            break
        if user_input.lower() == "clear":
            agent.memory.clear()
            print("对话已清空。")
            continue

        print()
        response = agent.run(user_input)
        print(f"\nAgent: {response}")


if __name__ == "__main__":
    main()
