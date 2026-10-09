from datetime import datetime, timedelta, timezone

# Horário de Brasília. Offset fixo porque o Brasil não tem horário de verão desde 2019
# (e evita depender do pacote tzdata, que o zoneinfo exige no Windows).
FUSO_BRASILIA = timezone(timedelta(hours=-3), "America/Sao_Paulo")


def agora_brasilia():
    """Data e hora atuais em Brasília, sem fuso (as colunas DateTime do banco são naive)."""
    return datetime.now(FUSO_BRASILIA).replace(tzinfo=None)


def hoje_brasilia():
    """Data atual em Brasília (independe do fuso configurado no servidor)."""
    return agora_brasilia().date()
