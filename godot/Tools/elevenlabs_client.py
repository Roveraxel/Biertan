"""ElevenLabs client for Biertan voice tools (reads ELEVENLABS_API_KEY from .env.local)."""
import os
from dotenv import load_dotenv
from elevenlabs.client import ElevenLabs


def get_client(env_path: str = ".env.local") -> ElevenLabs:
    """Load ELEVENLABS_API_KEY from env_path and return an ElevenLabs client."""
    load_dotenv(env_path)
    return ElevenLabs(api_key=os.environ.get("ELEVENLABS_API_KEY"))
