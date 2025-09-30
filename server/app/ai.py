import asyncio
import asyncio
import logging
import os
from typing import Optional, List

try:
    import google.generativeai as genai
except ImportError:  # pragma: no cover - optional dependency
    genai = None


class GeminiClient:
    """Google Gemini 封装：用于指令反馈与世界种子生成。

    变更说明（兼容修复）：
    - 兼容 `models/` 前缀：优先保留用户提供的模型名，同时在初始化时同时尝试
      带前缀与不带前缀两种形式，提升跨版本兼容性（v1beta 与 v1）。
    - 默认模型：改为 `models/gemini-flash-latest`（用户环境实测要求），并自动扩展为
      常见别名，如 `gemini-2.5-flash-latest`/`gemini-2.5-flash-001` 等。
    - 初始化容错：若模型 404 或 API 版本不兼容（常见于旧版 `v1beta` 或旧包），
      自动尝试一组候选（包含 `-latest`/`-001` 与 `gemini-pro` 系列）并记录日志，避免接口 503。
    - 日志中文化与提示：引导用户升级 `google-generativeai (>= 0.7.0)` 或检查虚拟环境。
    """

    def __init__(self, api_key: Optional[str], model_name: Optional[str] = None) -> None:
        self._logger = logging.getLogger("lingyan.ai.gemini")
        # 1) 读取模型名（保留用户传入形式），默认使用用户环境期望的资源名
        raw_model = model_name or os.environ.get(
            "GEMINI_MODEL_NAME", "models/gemini-flash-latest"
        )
        normalized = self._normalize_model_name(raw_model)

        self._enabled = bool(api_key and genai)
        self._model_name = normalized
        self._model = None

        if self._enabled:
            try:
                genai.configure(api_key=api_key)
            except Exception:  # pragma: no cover - 极端情况下记录但不抛出
                self._enabled = False
                self._logger.exception("Gemini 客户端初始化失败：API Key 配置异常")
                return

            # 2) 使用候选列表容错初始化，尽量找到可用模型
            candidates = self._candidate_model_names(normalized)
            chosen = self._init_model_with_fallbacks(candidates)
            if chosen:
                self._model_name = chosen
                self._logger.info("Gemini 已就绪，使用模型：%s", chosen)
            else:
                self._enabled = False
                self._logger.error(
                    "Gemini 模型不可用，请确认：1) 机器已安装并激活虚拟环境，"
                    "2) 执行 `pip install -r server/requirements.txt` 并确保 google-generativeai >= 0.7.0，"
                    "3) 模型名设置正确（建议使用 gemini-2.5-flash 或 gemini-1.0-pro-latest）。"
                )

    # ===== 内部工具方法 =====
    @staticmethod
    def _normalize_model_name(name: str) -> str:
        """轻量归一：仅做去空白，保留 `models/` 等前缀，避免误删。

        - 输入：可能包含前缀的模型名，例如："models/gemini-flash-latest"
        - 输出：原样返回去除首尾空白的名称
        """
        if not name:
            return name
        return name.strip()

    def _candidate_model_names(self, base: str) -> List[str]:
        """根据基准名生成一组备选模型，兼容不同库版本与 API 变体。"""
        base = self._normalize_model_name(base)
        cands: List[str] = []

        if not base:
            return cands

        # 兼容带/不带 models/ 两种形式
        name_no_prefix = base.split("/", 1)[1] if base.startswith("models/") else base
        with_prefix = f"models/{name_no_prefix}"

        # 1) 原始输入优先
        cands.append(base)
        # 2) 另一种前缀形式
        if name_no_prefix != base:
            cands.append(name_no_prefix)
        if with_prefix != base:
            cands.append(with_prefix)

        # 3) latest 变体（两种前缀形式都尝试）
        if not name_no_prefix.endswith("-latest"):
            cands.append(f"{name_no_prefix}-latest")
            cands.append(f"models/{name_no_prefix}-latest")

        # 4) flash 系列的常见别名互补
        if name_no_prefix.startswith("gemini-2.5-flash") and not name_no_prefix.endswith("-001"):
            cands.extend([
                "gemini-2.5-flash-001",
                "models/gemini-2.5-flash-001",
            ])
        if name_no_prefix.startswith("gemini-flash") and "1.5" not in name_no_prefix:
            cands.extend([
                "gemini-2.5-flash-latest",
                "models/gemini-2.5-flash-latest",
            ])

        # 5) 回退到 1.0 系列与老 pro 名称（兼容旧版库 v1beta）
        cands.extend([
            "gemini-1.0-pro-latest",
            "models/gemini-1.0-pro-latest",
            "gemini-1.0-pro",
            "models/gemini-1.0-pro",
            "gemini-pro",
        ])

        # 去重保持顺序
        seen = set()
        deduped = []
        for m in cands:
            if m and m not in seen:
                seen.add(m)
                deduped.append(m)
        return deduped

    def _init_model_with_fallbacks(self, names: List[str]) -> Optional[str]:
        """依次尝试候选模型，成功则返回所选名称。失败记录 debug 便于排查。"""
        if not genai:
            return None
        for n in names:
            try:
                self._model = genai.GenerativeModel(model_name=n)
                # 触发一个轻量属性访问确保实例化不抛错
                _ = getattr(self._model, "model_name", n)
                return n
            except Exception as e:  # pragma: no cover - 尝试容错
                self._model = None
                self._logger.debug("模型候选不可用：%s，原因：%s", n, e)
        return None

    @classmethod
    def from_environment(cls) -> "GeminiClient":
        return cls(os.environ.get("GEMINI_API_KEY"))

    @property
    def available(self) -> bool:
        return self._enabled

    @property
    def model_name(self) -> Optional[str]:
        return getattr(self, "_model_name", None)

    async def generate_command_feedback(self, content: str, context: str | None = None) -> Optional[str]:
        """Call Gemini Flash to craft narrative feedback for a player command."""
        if not self._enabled or not self._model:
            return None

        context_block = f"\n【对话上下文】\n{context}\n" if context else "\n"
        prompt = (
            "你是修仙世界的执掌天机之灵，请根据玩家指令演绎接下来真正发生的完整事件过程，"
            "而非仅描述变化。要求：1) 中文古风叙述；2) 细化行动、环境、人物互动与结果，避免空泛形容；"
            "3) 不得剧透未解锁信息；4) 合理推进世界状态（但不要直接替玩家作重大选择）。"
            "结尾用一句话向玩家发问，引导其下一步行动（不提供选项列表）。"
            f"{context_block}玩家指令：{content}\n请输出事件叙事与结尾发问："
        )

        try:
            response = await asyncio.to_thread(self._model.generate_content, prompt)
            text = (response.text or "").strip()
            return text or None
        except Exception as exc:  # pragma: no cover - 网络或模型异常
            # 某些地区会返回：FailedPrecondition: 400 User location is not supported
            msg = str(exc)
            if "User location is not supported" in msg or "FailedPrecondition" in msg:
                self._logger.warning("Gemini 在当前地区不可用：%s", msg)
            else:
                # 其余错误保留告警但不抛栈
                self._logger.warning(
                    "Gemini generate_content 失败：%s；建议检查虚拟环境与 google-generativeai 版本。",
                    msg,
                )
            return None

    async def generate_world_seed(self, prompt: str) -> Optional[str]:
        if not self._enabled or not self._model:
            return None
        try:
            response = await asyncio.to_thread(self._model.generate_content, prompt)
            text = (response.text or "").strip()
            return text or None
        except Exception as exc:  # pragma: no cover - 初始化失败时仅记录
            msg = str(exc)
            if "User location is not supported" in msg or "FailedPrecondition" in msg:
                # 避免启动时打印长堆栈，降级为警告并走本地初始世界
                self._logger.warning("Gemini 世界种子生成不可用：%s（将使用内置初始世界）", msg)
            else:
                self._logger.warning("Gemini 世界种子生成失败：%s", msg)
            return None

    async def summarize_dialogue(self, transcript: str) -> Optional[str]:
        """使用 Gemini 对过往对话进行压缩摘要，仅供内部上下文，不向玩家展示。"""
        if not self._enabled or not self._model or not transcript.strip():
            return None
        prompt = (
            "请将以下修仙世界对话历史压缩为不超过200字的中文要点，"
            "保留关键人物/地点/未完成目标/约定/关系变化/已达成结果等；避免重复与空话。"
            "不得加入新剧情。\n\n对话历史：\n" + transcript
        )
        try:
            response = await asyncio.to_thread(self._model.generate_content, prompt)
            return (response.text or "").strip() or None
        except Exception:
            return None

    # ===== 生成玩家与初始事件（便于服务端直接调用） =====
    async def generate_player_state_text(self, prompt: str) -> Optional[str]:
        """基于给定 Prompt 生成 PlayerState 的 JSON 文本。

        说明：与 generate_world_seed 一致的底层实现，这里单独暴露便于语义区分与日志检索。
        """
        return await self.generate_world_seed(prompt)

    async def generate_initial_event_summary(
        self,
        player_name: str,
        realm: str,
        guild: str,
        location_name: str,
        seed_hint: str | None = None,
    ) -> Optional[str]:
        """生成玩家“初试事件”的叙事摘要（中文，≥200字）。

        - 必须以“天道/天机”视角，古风文体；
        - 交代姓名、出身（凡人阶段），嵌入一则“天赋/体质/眷顾”设定与简要机制；
        - 围绕当前地点 {location_name} 给出一个具体抉择场景；
        - 结尾以一句简短发问引导下一步；
        - 返回纯文本摘要（不包含 JSON 或 Markdown）。
        """
        if not self._enabled or not self._model:
            return None
        seed_line = f"（签名：{seed_hint}）" if seed_hint else ""
        prompt = (
            "你是修仙世界的天机灵枢，请为新入世之人写一段‘初试事件’叙事，"
            "要求：中文古风、第二或全知视角、细节充足（≥200字），不得给出选项列表；"
            "须交代姓名/出身（仍为凡人阶段）、嵌入一则‘天赋/体质/眷顾’及其简单机制；"
            "围绕其当前所在之地引出一个具体抉择场景；结尾以一句简短发问引导下一步。\n"
            f"姓名：{player_name}；境界：{realm}；所属/羁绊：{guild}；所在：{location_name}。{seed_line}\n"
            "请只输出叙事正文，不要任何解释。"
        )
        try:
            response = await asyncio.to_thread(self._model.generate_content, prompt)
            text = (response.text or "").strip()
            return text or None
        except Exception:
            return None
