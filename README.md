-----

## 🚦 Monitor de Portas Abertas (ApPortas) (IAG)

**ApPortas** é uma aplicação web leve, baseada em **Flask** e **Psutil**, projetada para monitorar e exibir portas TCP/UDP em estado `LISTEN` no seu servidor. Ele permite identificar quais processos ou contêineres estão utilizando cada porta, além de oferecer funcionalidades de busca, ordenação e mapeamento personalizado de portas para nomes de aplicações.

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

Este guia detalha como configurar e executar o ApPortas usando Docker.

#### Pré-requisitos

  * **Linux server** (preferencialmente, ou qualquer sistema compatível com Docker).
  * **Docker** e **Docker Compose** instalados. Se você ainda não tem, siga as instruções oficiais:
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
    git clone https://github.com/edersonsgoncalves/apportas.git
    cd edersonsgoncalves/apportas # ou o nome da sua pasta do projeto
    ```
    
2.  **Estrutura do Projeto:**
    Certifique-se de que a sua estrutura de arquivos esteja organizada da seguinte forma:

    ```
    apportas/
    ├── Dockerfile
    ├── port_monitor.py
    └── requirements.txt
    ```

3.  **`port_monitor.py`**
    Este é o arquivo principal da aplicação Flask.

4.  **`requirements.txt`**
    Certifique-se de que este arquivo contenha as dependências necessárias:

5.  **`Dockerfile`**
    Este Dockerfile constrói a imagem da sua aplicação.


-----

### 🛠️ Instalação e Execução

Siga estes passos para ter o ApPortas funcionando no seu servidor:

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

    **Importante:** O uso de `--network host` permite que o contêiner veja e monitore as portas do sistema hospedeiro como se estivesse rodando diretamente nele.

    ```bash
    sudo docker run -d \
      --restart always \
      --network host \
      --name apportas \
      apportas
    ```

4.  **Acesse a Aplicação:**
    Abra seu navegador web e digite o endereço IP do seu Raspberry Pi, seguido da porta `1111`.

    `http://SEU_IP:1111`

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

Este projeto é de código aberto e está sob a licença [MIT](https://www.google.com/search?q=LICENSE).
O código foi gerado por inteligência artificial (Gemini - 2.5 Flash), supervisionado por mim.

-----
