FROM python:3.9-slim-buster

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY port_monitor.py .

# Cria o diretório /app para garantir que o arquivo de mapeamentos possa ser criado
RUN mkdir -p /app

EXPOSE 1111

CMD ["python", "port_monitor.py"]