"""文件读写工具：在项目 output/ 目录下操作文件"""

import os
import logging

logger = logging.getLogger(__name__)

# 统一使用项目根目录下的 output/
OUTPUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "output",
)


class FileTool:
    """在 output/ 目录下读写文件，防止路径穿越。"""

    def __init__(self, base_dir: str | None = None):
        self.base_dir = os.path.abspath(base_dir or OUTPUT_DIR)
        os.makedirs(self.base_dir, exist_ok=True)

    def _safe_path(self, filename: str) -> str:
        """将文件名限定在 base_dir 内，防止 ../ 路径穿越。"""
        # 拒绝绝对路径和路径分隔符
        if os.path.isabs(filename) or "/" in filename or "\\" in filename:
            raise ValueError(f"文件名不允许包含路径，仅允许纯文件名: {filename}")
        full = os.path.abspath(os.path.join(self.base_dir, filename))
        if not full.startswith(self.base_dir):
            raise ValueError(f"路径越界: {filename}")
        return full

    def write(self, filename: str, content: str) -> str:
        if not filename:
            return "错误：未提供文件名。"
        if content is None:
            content = ""
        try:
            path = self._safe_path(filename)
            with open(path, "w", encoding="utf-8") as f:
                f.write(content)
            size = os.path.getsize(path)
            return f"文件已保存: output/{filename}（{size} 字节）"
        except ValueError as exc:
            return f"文件名不合法: {exc}"
        except OSError as exc:
            return f"写入文件失败: {exc}"

    def read(self, filename: str) -> str:
        if not filename:
            return "错误：未提供文件名。"
        try:
            path = self._safe_path(filename)
            if not os.path.exists(path):
                return f"文件不存在: output/{filename}"
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            return f"文件内容 output/{filename}:\n{content}"
        except ValueError as exc:
            return f"文件名不合法: {exc}"
        except OSError as exc:
            return f"读取文件失败: {exc}"
