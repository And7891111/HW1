"""工具模块：Agent 可调用的工具集合"""

from .python_executor import PythonExecutor
from .file_tool import FileTool

__all__ = ["PythonExecutor", "FileTool", "build_tools", "dispatch_tool"]


def build_tools() -> list[dict]:
    """构建 OpenAI function calling 格式的工具 schema 列表。"""
    return [
        {
            "type": "function",
            "function": {
                "name": "execute_python",
                "description": "在隔离的子进程中执行 Python 代码，返回标准输出和错误输出。代码运行有超时限制（默认15秒）。执行后请根据输出判断是否正确，如有错误请修复后重新执行。",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "code": {
                            "type": "string",
                            "description": "要执行的完整 Python 代码",
                        }
                    },
                    "required": ["code"],
                },
            },
        },
        {
            "type": "function",
            "function": {
                "name": "write_file",
                "description": "将代码或文本内容写入 output/ 目录下的指定文件。用于保存最终结果。",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "filename": {
                            "type": "string",
                            "description": "文件名（不含路径），如 solution.py",
                        },
                        "content": {
                            "type": "string",
                            "description": "要写入的完整文件内容",
                        },
                    },
                    "required": ["filename", "content"],
                },
            },
        },
        {
            "type": "function",
            "function": {
                "name": "read_file",
                "description": "读取 output/ 目录下已存在的文件内容。",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "filename": {
                            "type": "string",
                            "description": "要读取的文件名",
                        }
                    },
                    "required": ["filename"],
                },
            },
        },
    ]


def dispatch_tool(name: str, arguments: dict, executor: PythonExecutor, file_tool: FileTool) -> str:
    """根据工具名分发调用，返回工具执行结果的字符串。"""
    if name == "execute_python":
        return executor.run(arguments.get("code", ""))
    elif name == "write_file":
        return file_tool.write(arguments.get("filename", ""), arguments.get("content", ""))
    elif name == "read_file":
        return file_tool.read(arguments.get("filename", ""))
    else:
        return f"错误：未知工具 '{name}'"
