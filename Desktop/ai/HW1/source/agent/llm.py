import logging
import time
from openai import OpenAI, APIError, APIConnectionError, RateLimitError

logger = logging.getLogger(__name__)


class LLMClient:
    def __init__(
        self,
        api_key: str,
        base_url: str = "https://dashscope.aliyuncs.com/compatible-mode/v1",
        model: str = "qwen-plus",
        max_retries: int = 3,
    ):
        self.client = OpenAI(api_key=api_key, base_url=base_url)
        self.model = model
        self.max_retries = max_retries

    def chat(self, messages: list[dict], tools: list[dict] | None = None) -> dict:

        last_exc: Exception | None = None
        for attempt in range(self.max_retries):
            try:
                kwargs = {
                    "model": self.model,
                    "messages": messages,
                }
                if tools:
                    kwargs["tools"] = tools
                    kwargs["tool_choice"] = "auto"

                response = self.client.chat.completions.create(**kwargs)
                return response.choices[0].message.model_dump()

            except (APIConnectionError, RateLimitError, APIError) as exc:
                last_exc = exc
                wait = 2 ** attempt
                logger.warning(
                    "LLM 调用失败（第 %d/%d 次），%d 秒后重试: %s",
                    attempt + 1, self.max_retries, wait, exc,
                )
                time.sleep(wait)

        raise RuntimeError(f"LLM 调用连续失败 {self.max_retries} 次") from last_exc
