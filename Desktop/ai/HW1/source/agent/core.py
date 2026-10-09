import json
import logging
from .llm import LLMClient
from .memory import ConversationMemory
from .tools import build_tools, dispatch_tool, PythonExecutor, FileTool

logger = logging.getLogger(__name__)


class CodeAgent:
    def __init__(
        self,
        llm_client: LLMClient,
        system_prompt: str,
        max_turns: int = 10,
        code_timeout: int = 15,
    ):
        self.llm = llm_client
        self.memory = ConversationMemory(system_prompt)
        self.max_turns = max_turns
        self.tools = build_tools()
        self.executor = PythonExecutor(timeout=code_timeout)
        self.file_tool = FileTool()

    def run(self, user_input: str) -> str:
        self.memory.add_user(user_input)

        for turn in range(1, self.max_turns + 1):
            logger.info("Agent 第 %d 轮推理...", turn)

            try:
                response = self.llm.chat(
                    messages=self.memory.messages,
                    tools=self.tools,
                )
            except RuntimeError as exc:
                return f"模型调用失败：{exc}"

            self.memory.add_assistant(response)

            tool_calls = response.get("tool_calls")

            if not tool_calls:
                return response.get("content", "(空回复)")

            for tool_call in tool_calls:
                func_name = tool_call["function"]["name"]
                func_args = self._parse_args(tool_call["function"]["arguments"])
                tool_call_id = tool_call["id"]

                print(f"\n  🔧 调用工具: {func_name}")

                result = dispatch_tool(
                    func_name, func_args, self.executor, self.file_tool
                )

                preview = result[:200] + ("..." if len(result) > 200 else "")
                print(f"  📤 工具返回: {preview}")

                self.memory.add_tool_result(tool_call_id, result)

        return (
            f"已达到最大推理轮数（{self.max_turns}轮），流程终止。"
            "Agent 在有限轮次内未能完成任务。"
        )

    @staticmethod
    def _parse_args(raw_args) -> dict:
        if isinstance(raw_args, dict):
            return raw_args
        if not isinstance(raw_args, str):
            return {}
        try:
            return json.loads(raw_args)
        except json.JSONDecodeError:
            logger.warning("工具参数解析失败: %s", raw_args)
            return {}
