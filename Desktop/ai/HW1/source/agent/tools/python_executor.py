"""Python 代码执行工具：在子进程中隔离执行，带超时保护"""

import subprocess
import sys
import tempfile
import os
import logging

logger = logging.getLogger(__name__)


class PythonExecutor:
    """在临时目录中用子进程执行 Python 代码，捕获 stdout/stderr。"""

    def __init__(self, timeout: int = 15):
        self.timeout = timeout

    def run(self, code: str) -> str:
        """
        执行一段 Python 代码，返回格式化的执行结果。
        超时、异常都会被捕获并作为文本返回，供 LLM 分析修正。
        """
        if not code or not code.strip():
            return "错误：代码为空，未执行任何内容。"

        # 写入临时文件
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".py", delete=False, encoding="utf-8"
        ) as f:
            f.write(code)
            tmp_path = f.name

        try:
            result = subprocess.run(
                [sys.executable, tmp_path],
                capture_output=True,
                text=True,
                timeout=self.timeout,
                cwd=os.path.dirname(tmp_path),
            )

            output_parts = []
            if result.stdout.strip():
                output_parts.append(f"[标准输出]\n{result.stdout.rstrip()}")
            if result.stderr.strip():
                output_parts.append(f"[错误输出]\n{result.stderr.rstrip()}")

            if output_parts:
                status = "执行成功" if result.returncode == 0 else f"执行失败（退出码 {result.returncode}）"
                return f"{status}\n\n" + "\n\n".join(output_parts)
            else:
                return f"执行成功（退出码 {result.returncode}，无输出）"

        except subprocess.TimeoutExpired:
            return (
                f"执行超时：代码运行超过 {self.timeout} 秒被强制终止。"
                "请检查是否有死循环或耗时操作。"
            )
        except Exception as exc:
            return f"执行环境异常：{type(exc).__name__}: {exc}"
        finally:
            # 清理临时文件
            try:
                os.unlink(tmp_path)
            except OSError:
                pass
