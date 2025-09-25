import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
    AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
    AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
    AWS_ACCOUNT_ID = os.getenv("AWS_ACCOUNT_ID")
    APP_CONFIG_TABLE = os.getenv("APP_CONFIG_TABLE", "Applications")

settings = Settings()

