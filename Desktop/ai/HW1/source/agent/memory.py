class ConversationMemory:

    def __init__(self, system_prompt: str):
        self._messages: list[dict] = [
            {"role": "system", "content": system_prompt}
        ]

    @property
    def messages(self) -> list[dict]:
        return self._messages

    def add_user(self, content: str) -> None:
        self._messages.append({"role": "user", "content": content})

    def add_assistant(self, message: dict) -> None:
        self._messages.append(message)

    def add_tool_result(self, tool_call_id: str, content: str) -> None:
        self._messages.append({
            "role": "tool",
            "tool_call_id": tool_call_id,
            "content": content,
        })

    def clear(self) -> None:
        system = self._messages[0]
        self._messages.clear()
        self._messages.append(system)

    def __len__(self) -> int:
        return len(self._messages)
