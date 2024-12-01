
# API de Pagamento - Tech Challenge

#### 🚧  API de Pagamento 💳 Em construção... 🚧

## 📋 Índice 

- [API de Pagamento - Tech Challenge](#api-de-pagamento---tech-challenge)
      - [🚧  API de Pagamento 💳 Em construção... 🚧](#--api-de-pagamento--em-construção-)
  - [📋 Índice](#-índice)
  - [💻 Sobre o Projeto](#-sobre-o-projeto)
  - [⚙️ Funcionalidades](#️-funcionalidades)
  - [🏗 Arquitetura](#-arquitetura)
  - [🚀 Como Executar o Projeto](#-como-executar-o-projeto)
    - [Pré-requisitos](#pré-requisitos)
    - [🎲 Configurando e Executando](#-configurando-e-executando)
  - [🧪 Testando a API](#-testando-a-api)
    - [Criar Preferência de Pagamento](#criar-preferência-de-pagamento)
    - [Processar Retorno de Pagamento](#processar-retorno-de-pagamento)
  - [🛠 Tecnologias](#-tecnologias)
  - [👥 Contribuidores](#-contribuidores)
  - [🦸 Autor](#-autor)
  - [📝 Licença](#-licença)

## 💻 Sobre o Projeto

💳 **API de Pagamento** - É uma solução serverless desenvolvida como parte de um desafio técnico para processar pagamentos de forma segura e eficiente, utilizando a integração com o Mercado Pago.

Este projeto foi desenvolvido durante o **Tech Challenge** oferecido pela [FIAP] como parte do curso de Arquitetura de Software.

## ⚙️ Funcionalidades

- [x] Criação de preferências de pagamento
- [x] Processamento de retornos de pagamento
- [x] Armazenamento de informações de transações no DynamoDB
- [x] Integração com o Mercado Pago para processamento de pagamentos
- [ ] Consulta de status de transações (em desenvolvimento)
- [ ] Estorno de transações (planejado)
- [ ] Geração de relatórios (planejado)

## 🏗 Arquitetura

O projeto utiliza uma arquitetura serverless na AWS, composta por:

- **API Gateway:** Para expor os endpoints da API
- **Lambda Functions:** Para processar as requisições
- **DynamoDB:** Para armazenar informações das transações
- **IAM:** Para gerenciar permissões e acessos

A infraestrutura é gerenciada usando Terraform, permitindo uma implantação consistente e versionada.

## 🚀 Como Executar o Projeto

### Pré-requisitos

Antes de começar, você vai precisar ter instalado em sua máquina as seguintes ferramentas:
- [Git](https://git-scm.com)
- [Python](https://www.python.org/downloads/) (versão 3.8 ou superior)
- [Terraform](https://www.terraform.io/downloads.html) (versão 1.0 ou superior)
- [AWS CLI](https://aws.amazon.com/cli/) (configurado com suas credenciais)

### 🎲 Configurando e Executando

```bash
# Clone este repositório
$ git clone git@github.com:gabriel-gsilva/api-pagamento-tech-challenge.git

# Acesse a pasta do projeto no terminal/cmd
$ cd api-pagamento-tech-challenge

# Instale as dependências do Python
$ pip install -r requirements.txt

# Acesse a pasta do Terraform
$ cd terraform

# Inicialize o Terraform
$ terraform init

# Verifique o plano de execução do Terraform
$ terraform plan

# Aplique as mudanças na infraestrutura
$ terraform apply

# Confirme a aplicação digitando 'yes' quando solicitado
```

Após a execução bem-sucedida do Terraform, os endpoints da API estarão disponíveis para uso.

## 🧪 Testando a API

Após a implantação, você pode testar os endpoints da API usando curl ou ferramentas como Postman. Aqui estão alguns exemplos:

### Criar Preferência de Pagamento

Endpoint: `POST /criar_preferencia`

Exemplo de payload:

```json
{
  "items": [
    {
      "title": "X-Tudo",
      "quantity": 1,
      "currency_id": "BRL",
      "unit_price": 25.90
    },
    {
      "title": "Refrigerante 350ml",
      "quantity": 2,
      "currency_id": "BRL",
      "unit_price": 5.50
    },
    {
      "title": "Batata Frita Média",
      "quantity": 1,
      "currency_id": "BRL",
      "unit_price": 8.90
    }
  ]
}
```

### Processar Retorno de Pagamento

Endpoint: `GET /retorno`

Este endpoint é chamado automaticamente pelo Mercado Pago após o processamento do pagamento. Para testes, você pode simular uma chamada usando:

```bash
curl -X GET "https://seu-api-gateway-url/dev/retorno?collection_status=approved&external_reference=seu-id-de-referencia"
```

## 🛠 Tecnologias

As seguintes ferramentas foram usadas na construção do projeto:

- [Python](https://www.python.org/)
- [AWS Lambda](https://aws.amazon.com/lambda/)
- [Amazon API Gateway](https://aws.amazon.com/api-gateway/)
- [Amazon DynamoDB](https://aws.amazon.com/dynamodb/)
- [Terraform](https://www.terraform.io/)
- [Mercado Pago SDK](https://www.mercadopago.com.br/developers/pt/guides/sdks)

## 👥 Contribuidores

Agradecemos às seguintes pessoas que contribuíram para este projeto:

<table>
  <tr>
    <td align="center"><a href="https://github.com/gabriel-gsilva"><img style="border-radius: 50%;" src="https://avatars.githubusercontent.com/u/seu-id?v=4" width="100px;" alt=""/><br /><sub><b>Gabriel Silva</b></sub></a><br /><a href="https://github.com/gabriel-gsilva" title="Desenvolvedor">👨‍💻</a></td>
  </tr>
</table>

## 🦸 Autor

<a href="https://github.com/gabriel-gsilva">
 <img style="border-radius: 50%;" src="https://avatars.githubusercontent.com/u/seu-id?v=4" width="100px;" alt=""/>
 <br />
 <sub><b>Gabriel Silva</b></sub></a>
 <br />

[![LinkedIn Badge](https://img.shields.io/badge/-LinkedIn-blue?style=flat-square&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/seu-linkedin/)](https://www.linkedin.com/in/seu-linkedin/)
[![Gmail Badge](https://img.shields.io/badge/-Gmail-c14438?style=flat-square&logo=Gmail&logoColor=white&link=mailto:seu-email@gmail.com)](mailto:seu-email@gmail.com)

## 📝 Licença

Este projeto está sob a licença [MIT](./LICENSE).

Feito com ❤️ por Gabriel Silva 👋🏽 [Entre em contato!](https://www.linkedin.com/in/seu-linkedin/)