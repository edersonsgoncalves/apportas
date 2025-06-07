-----

## 🚦 Monitor de Portas Abertas (AppORTAS)

**AppORTAS** é uma aplicação web leve, baseada em Flask e Psutil, projetada para monitorar e exibir portas TCP/UDP em estado `LISTEN` no seu servidor (Raspberry Pi, em um cenário típico). Ele permite identificar quais processos ou contêineres estão utilizando cada porta, além de oferecer funcionalidades de busca, ordenação e mapeamento personalizado de portas para nomes de aplicações.

-----

### ✨ Funcionalidades

  * **Monitoramento em Tempo Real:** Visualiza as portas abertas em estado `LISTEN` (escuta) no servidor.
  * **Identificação de Processos/Contêineres:** Exibe o nome do processo que está utilizando cada porta.
  * **Mapeamento de Portas Personalizado:** Permite associar portas a nomes de aplicações amigáveis via interface web.
  * **Endereços Localhost Humanizados:** Substitui endereços genéricos (`0.0.0.0`, `::`, `127.0.0.1`) por descrições mais claras ("Localhost Amplo", "Localhost Restrito").
  * **Busca Dinâmica:** Filtra a tabela de portas por qualquer campo (endereço, porta, status, nome da aplicação/processo).
  * **Ordenação Flexível:** Ordena os dados da tabela por diferentes colunas (Porta, Aplicação, Endereço, Status) em ordem crescente ou decrescente.
  * **Prioridade de Mapeamentos:** As portas com mapeamentos personalizados são exibidas primeiro na lista.
  * **Contêiner Docker:** Empacotado em um contêiner Docker para fácil implantação e isolamento (rodando em modo de rede `host` para monitorar o host).

-----

### 🚀 Começando

Este guia detalha como configurar e executar o AppORTAS usando Docker no seu Raspberry Pi.

#### Pré-requisitos

  * **Raspberry Pi** (ou qualquer sistema Linux compatível com Docker).
  * **Docker** e **Docker Compose** instalados no seu Raspberry Pi. Se você ainda não tem, siga as instruções oficiais:
    ```bash
    # Instalar Docker
    curl -sSL https://get.docker.com | sh
    # Adicionar seu usuário ao grupo docker para não precisar de sudo
    sudo usermod -aG docker $USER
    # Fazer logout e login novamente para aplicar a alteração de grupo
    # Ou reiniciar o Raspberry Pi
    ```

-----

### ⚙️ Configuração

1.  **Clone o Repositório:**

    ```bash
    git clone https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git
    cd SEU_REPOSITORIO/apportas # ou o nome da sua pasta do projeto
    ```

    *(Ajuste `SEU_USUARIO` e `SEU_REPOSITORIO` para os seus próprios dados do GitHub.)*

2.  **Estrutura do Projeto:**
    Certifique-se de que a sua estrutura de arquivos esteja organizada da seguinte forma:

    ```
    apportas/
    ├── Dockerfile
    ├── port_monitor.py
    └── requirements.txt
    ```

3.  **`port_monitor.py`** (Conteúdo)
    Este é o arquivo principal da aplicação Flask.

    ```python
    # port_monitor.py
    from flask import Flask, render_template_string, request, redirect, url_for, flash
    import psutil
    import socket
    import datetime
    import json
    import os
    from operator import itemgetter

    app = Flask(__name__)
    # MUDE ISSO PARA UMA STRING LONGA E ALEATÓRIA E MANTENHA EM SEGURANÇA!
    app.secret_key = 'sua_chave_secreta_muito_segura_aqui_12345'

    # Caminho do arquivo JSON dentro do container (efêmero)
    MAPPINGS_FILE = '/app/port_mappings.json'

    # Mapeamentos padrão para inicialização (serão recriados se o container for descartado)
    DEFAULT_MAPPINGS = {
        "80": "Apache (HTTP)",
        "443": "Apache (HTTPS)",
        "81": "CasaOS",
        "22": "SSH",
        "3306": "MySQL",
        "6379": "Redis",
        "9000": "Algum Serviço Docker (Exemplo)",
        "1111": "Monitor de Portas (AppORTAS)"
    }

    def load_mappings():
        """Carrega os mapeamentos de porta do arquivo JSON."""
        if os.path.exists(MAPPINGS_FILE):
            try:
                with open(MAPPINGS_FILE, 'r') as f:
                    loaded = json.load(f)
                    return loaded if loaded else DEFAULT_MAPPINGS
            except json.JSONDecodeError:
                print(f"Erro ao decodificar JSON em {MAPPINGS_FILE}. Usando mapeamentos padrão.")
                return DEFAULT_MAPPINGS
        return DEFAULT_MAPPINGS

    def save_mappings(mappings):
        """Salva os mapeamentos de porta no arquivo JSON."""
        with open(MAPPINGS_FILE, 'w') as f:
            json.dump(mappings, f, indent=4)

    HTML_TEMPLATE = """
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Monitor de Portas Abertas</title>
        <style>
            body { font-family: sans-serif; margin: 20px; background-color: #f4f4f4; color: #333; }
            h1 { color: #0056b3; }
            .flash-message {
                padding: 10px;
                margin-bottom: 15px;
                border-radius: 5px;
                font-weight: bold;
            }
            .flash-message.success {
                background-color: #d4edda;
                color: #155724;
                border: 1px solid #c3e6cb;
            }
            .flash-message.error {
                background-color: #f8d7da;
                color: #721c24;
                border: 1px solid #f5c6cb;
            }
            table { width: 100%; border-collapse: collapse; margin-top: 20px; background-color: #fff; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
            th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #ddd; }
            th { background-color: #007bff; color: white; }
            tr:nth-child(even) { background-color: #f8f8f8; }
            tr:hover { background-color: #f1f1f1; }
            .no-data { text-align: center; color: #666; padding: 20px; }
            footer { margin-top: 40px; text-align: center; color: #777; font-size: 0.9em; }
            .form-container {
                background-color: #fff;
                padding: 20px;
                margin-top: 20px;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .form-container label {
                display: block;
                margin-bottom: 5px;
                font-weight: bold;
            }
            .form-container input[type="text"],
            .form-container input[type="number"],
            .form-container select {
                width: calc(100% - 22px);
                padding: 10px;
                margin-bottom: 15px;
                border: 1px solid #ddd;
                border-radius: 4px;
            }
            .form-container button {
                background-color: #28a745;
                color: white;
                padding: 10px 20px;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-size: 16px;
                margin-right: 10px;
            }
            .form-container button.delete {
                background-color: #dc3545;
            }
            .form-container button:hover {
                opacity: 0.9;
            }
            .filter-sort-form {
                display: flex;
                gap: 15px;
                flex-wrap: wrap;
                margin-bottom: 20px;
                padding: 15px;
                background-color: #e9ecef;
                border-radius: 8px;
            }
            .filter-sort-form div {
                flex: 1;
                min-width: 150px;
            }
            .filter-sort-form button {
                align-self: flex-end;
                margin-bottom: 15px; /* Align with input bottom */
            }
        </style>
    </head>
    <body>
        <h1>Monitor de Portas Abertas no Servidor ({{ hostname }})</h1>

        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}
                {% for category, message in messages %}
                <div class="flash-message {{ category }}">
                    {{ message }}
                </div>
                {% endfor %}
            {% endif %}
        {% endwith %}

        {# Mapeamento Form - Movido para cima #}
        <div class="form-container">
            <h2>Adicionar/Atualizar/Remover Mapeamento de Porta</h2>
            <form method="POST" action="{{ url_for('update_mapping') }}">
                <label for="port_to_map">Porta:</label>
                <input type="number" id="port_to_map" name="port" required><br>

                <label for="app_name">Nome da Aplicação (deixe em branco para remover):</label>
                <input type="text" id="app_name" name="app_name"><br>

                <button type="submit">Salvar/Atualizar Mapeamento</button>
                <button type="submit" name="action" value="delete" class="delete">Remover Mapeamento</button>
            </form>
        </div>

        {# Filtro e Ordenação Form #}
        <div class="form-container filter-sort-form">
            <h2>Filtrar e Ordenar</h2>
            <form method="GET" action="{{ url_for('index') }}" style="width: 100%; display: flex; flex-wrap: wrap; gap: 15px;">
                <div>
                    <label for="search_query">Buscar:</label>
                    <input type="text" id="search_query" name="search_query" value="{{ search_query or '' }}">
                </div>
                <div>
                    <label for="sort_by">Ordenar por:</label>
                    <select id="sort_by" name="sort_by">
                        <option value="laddr.port" {% if sort_by == 'laddr.port' %}selected{% endif %}>Porta</option>
                        <option value="application_name" {% if sort_by == 'application_name' %}selected{% endif %}>Aplicação/Processo</option>
                        <option value="display_laddr_ip" {% if sort_by == 'display_laddr_ip' %}selected{% endif %}>Endereço Local</option>
                        <option value="status" {% if sort_by == 'status' %}selected{% endif %}>Status</option>
                    </select>
                </div>
                <div>
                    <label for="sort_order">Ordem:</label>
                    <select id="sort_order" name="sort_order">
                        <option value="asc" {% if sort_order == 'asc' %}selected{% endif %}>Crescente</option>
                        <option value="desc" {% if sort_order == 'desc' %}selected{% endif %}>Decrescente</option>
                    </select>
                </div>
                <button type="submit" style="flex-grow: 0; padding: 10px 20px;">Aplicar</button>
            </form>
        </div>

        {# Tabela de Portas #}
        {% if connections %}
        <table>
            <thead>
                <tr>
                    <th>Endereço Local</th>
                    <th>Porta Local</th>
                    <th>Status</th>
                    <th>Aplicação/Processo</th>
                </tr>
            </thead>
            <tbody>
                {% for conn in connections %}
                <tr>
                    <td>{{ conn.display_laddr_ip }}</td>
                    <td>{{ conn.laddr.port }}</td>
                    <td>{{ conn.status }}</td>
                    <td>{{ conn.application_name }}</td>
                </tr>
                {% endfor %}
            </tbody>
        </table>
        {% else %}
        <p class="no-data">Nenhuma conexão de escuta encontrada.</p>
        {% endif %}

        <footer>
            Atualizado em: {{ current_time }}
        </footer>
    </body>
    </html>
    """

    @app.route('/')
    def index():
        connections_info = []
        custom_mappings = load_mappings()

        for conn in psutil.net_connections(kind='inet'):
            if conn.status == psutil.CONN_LISTEN:
                display_laddr_ip = conn.laddr.ip
                if conn.laddr.ip == '0.0.0.0' or conn.laddr.ip == '::':
                    display_laddr_ip = 'Localhost Amplo'
                elif conn.laddr.ip == '127.0.0.1':
                    display_laddr_ip = 'Localhost Restrito'

                application_name = custom_mappings.get(str(conn.laddr.port))
                
                has_custom_mapping = application_name is not None

                if application_name is None:
                    try:
                        p = psutil.Process(conn.pid)
                        application_name = f"Processo: {p.name()}"
                    except (psutil.NoSuchProcess, psutil.AccessDenied):
                        application_name = "Processo Desconhecido"

                connections_info.append({
                    'laddr': conn.laddr,
                    'display_laddr_ip': display_laddr_ip,
                    'status': conn.status,
                    'application_name': application_name,
                    'has_custom_mapping': has_custom_mapping
                })

        search_query = request.args.get('search_query', '').lower()
        sort_by = request.args.get('sort_by', 'laddr.port')
        sort_order = request.args.get('sort_order', 'asc')

        if search_query:
            connections_info = [
                conn for conn in connections_info
                if search_query in str(conn['laddr'].ip).lower() or
                   search_query in str(conn['laddr'].port).lower() or
                   search_query in conn['status'].lower() or
                   search_query in conn['application_name'].lower() or
                   search_query in conn['display_laddr_ip'].lower()
            ]

        mapped_connections = [conn for conn in connections_info if conn['has_custom_mapping']]
        unmapped_connections = [conn for conn in connections_info if not conn['has_custom_mapping']]

        def get_sort_key(item):
            if '.' in sort_by:
                parts = sort_by.split('.')
                val = item
                for part in parts:
                    if isinstance(val, dict):
                        val = val.get(part)
                    elif hasattr(val, part):
                        val = getattr(val, part)
                    else:
                        return ''
                return val
            return item.get(sort_by)

        mapped_connections.sort(key=get_sort_key, reverse=(sort_order == 'desc'))
        unmapped_connections.sort(key=get_sort_key, reverse=(sort_order == 'desc'))

        connections_info = mapped_connections + unmapped_connections

        current_time = datetime.datetime.now().strftime("%d/%m/%Y %H:%M:%S")
        hostname = socket.gethostname()
        
        return render_template_string(HTML_TEMPLATE, 
                                      connections=connections_info, 
                                      current_time=current_time, 
                                      hostname=hostname,
                                      search_query=search_query,
                                      sort_by=sort_by,
                                      sort_order=sort_order)


    @app.route('/update_mapping', methods=['POST'])
    def update_mapping():
        port = request.form.get('port')
        app_name = request.form.get('app_name').strip()
        action = request.form.get('action') 

        if not port:
            flash('A porta é obrigatória!', 'error')
            return redirect(url_for('index'))

        custom_mappings = load_mappings()

        if action == 'delete':
            if str(port) in custom_mappings:
                del custom_mappings[str(port)]
                save_mappings(custom_mappings)
                flash(f'Mapeamento para porta {port} removido com sucesso!', 'success')
            else:
                flash(f'Mapeamento para porta {port} não encontrado.', 'error')
        else: # Salvar/Atualizar
            if not app_name:
                flash('O nome da aplicação não pode estar vazio para salvar/atualizar.', 'error')
                return redirect(url_for('index'))
            
            custom_mappings[str(port)] = app_name
            save_mappings(custom_mappings)
            flash(f'Mapeamento para porta {port} salvo como "{app_name}" com sucesso!', 'success')
        
        return redirect(url_for('index'))

    if __name__ == '__main__':
        if not os.path.exists(MAPPINGS_FILE):
            save_mappings(DEFAULT_MAPPINGS)
            print(f"Arquivo de mapeamentos padrão criado em {MAPPINGS_FILE}")

        app.run(host='0.0.0.0', port=1111, debug=False)
    ```

4.  **`requirements.txt`** (Conteúdo)
    Certifique-se de que este arquivo contenha as dependências necessárias:

    ```
    Flask
    psutil
    ```

5.  **`Dockerfile`** (Conteúdo)
    Este Dockerfile constrói a imagem da sua aplicação.

    ```dockerfile
    FROM python:3.9-slim-buster

    WORKDIR /app

    COPY requirements.txt .
    RUN pip install --no-cache-dir -r requirements.txt

    COPY port_monitor.py .

    # Cria o diretório /app para garantir que o arquivo de mapeamentos possa ser criado
    RUN mkdir -p /app

    EXPOSE 1111

    CMD ["python", "port_monitor.py"]
    ```

-----

### 🛠️ Instalação e Execução

Siga estes passos para ter o AppORTAS funcionando no seu servidor:

1.  **Navegue até o diretório do projeto:**

    ```bash
    cd /caminho/para/o/seu/projeto/apportas
    ```

2.  **Construa a imagem Docker:**
    Este comando cria a imagem do contêiner a partir do `Dockerfile`.

    ```bash
    sudo docker build -t apportas .
    ```

3.  **Execute o contêiner:**
    Este comando inicia o contêiner em segundo plano (`-d`), configura-o para reiniciar automaticamente (`--restart always`), usa a rede do host (`--network host`) para monitorar todas as portas do servidor, e dá a ele o nome `apportas`.

    **Importante:** O uso de `--network host` permite que o contêiner veja e monitore as portas do sistema hospedeiro (seu Raspberry Pi) como se estivesse rodando diretamente nele.

    ```bash
    sudo docker run -d \
      --restart always \
      --network host \
      --name apportas \
      apportas
    ```

4.  **Acesse a Aplicação:**
    Abra seu navegador web e digite o endereço IP do seu Raspberry Pi, seguido da porta `1111`.

    `http://SEU_IP_DO_RASPBERRY_PI:1111`

    (Ex: `http://192.168.1.100:1111` ou `http://100.64.0.1:1111`)

-----

### 🗑️ Limpeza (Remover Contêiner e Imagem)

Se precisar remover o contêiner e a imagem (por exemplo, para iniciar do zero):

1.  **Pare o contêiner:**

    ```bash
    sudo docker stop apportas
    ```

2.  **Remova o contêiner:**

    ```bash
    sudo docker rm apportas
    ```

3.  **Remova a imagem Docker:**

    ```bash
    sudo docker rmi apportas
    ```

-----

### 🤝 Contribuição

Contribuições são sempre bem-vindas\! Se você tiver ideias para melhorias, novas funcionalidades ou encontrar bugs, sinta-se à vontade para abrir uma *issue* ou enviar um *pull request*.

-----

### 📝 Licença

Este projeto é de código aberto e está sob a licença [MIT](https://www.google.com/search?q=LICENSE) (ou a licença de sua escolha).

-----
