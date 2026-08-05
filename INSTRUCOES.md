# Agendamento — Oficina de Auto Elétrica

Aplicação 100% gratuita e serverless: front-end estático (HTML + Tailwind + JS puro) e back-end no Supabase (PostgreSQL).

## Arquivos
- `schema.sql` — script para rodar no Supabase (tabela, índice único parcial, RLS)
- `index.html` — página pública onde o cliente agenda
- `admin.html` — painel restrito da oficina

## Passo 1 — Criar o projeto no Supabase
1. Crie uma conta gratuita em https://supabase.com e um novo projeto.
2. No menu lateral, abra **SQL Editor** → **New query**.
3. Cole o conteúdo de `schema.sql` e clique em **Run**.
4. Confirme que a tabela `agendamentos` foi criada em **Table Editor**.

## Passo 2 — Pegar a URL e a chave pública (anon)
1. No projeto Supabase, vá em **Project Settings** → **API**.
2. Copie:
   - **Project URL** → cole em `SUPABASE_URL`
   - **anon public key** → cole em `SUPABASE_ANON_KEY`

## Passo 3 — Onde colar as credenciais no código
Em **`index.html`**, dentro do `<script type="module">`, no topo:
```js
const SUPABASE_URL = 'SUA_SUPABASE_URL_AQUI'
const SUPABASE_ANON_KEY = 'SUA_SUPABASE_ANON_KEY_AQUI'
const OFICINA_WHATSAPP = '5511999999999' // número da oficina, só dígitos, com código do país
```

Em **`admin.html`**, no mesmo local:
```js
const SUPABASE_URL = 'SUA_SUPABASE_URL_AQUI'
const SUPABASE_ANON_KEY = 'SUA_SUPABASE_ANON_KEY_AQUI'
const ADMIN_PASSWORD = 'troque-esta-senha' // defina uma senha só sua
```

> Como a chave `anon` é pública por natureza (fica visível no navegador), quem
> protege os dados é o RLS configurado no `schema.sql`. A senha do
> `admin.html` é uma proteção simples no navegador — suficiente para uma
> oficina pequena com link não divulgado. Se quiser algo mais robusto no
> futuro, migre para **Supabase Auth** (login de verdade) e restrinja a
> policy de `update` a usuários autenticados.

## Passo 4 — Testar localmente
Como os arquivos usam ES Modules, alguns navegadores bloqueiam ao abrir via
`file://`. Rode um servidor local simples, por exemplo:
```bash
npx serve .
# ou
python3 -m http.server 8080
```
Depois acesse `http://localhost:8080/index.html` e `http://localhost:8080/admin.html`.

## Passo 5 — Publicar (Vercel ou Cloudflare Pages)

### Vercel
1. Suba os arquivos (`index.html`, `admin.html`, `schema.sql`) para um repositório no GitHub.
2. Em https://vercel.com, clique em **Add New → Project** e importe o repositório.
3. Como é um site puramente estático, não é necessário configurar build command — deixe em branco ou use "Other" como framework.
4. Deploy. Pronto: você terá uma URL pública para `index.html` e outra para `admin.html`.

### Cloudflare Pages
1. Em https://pages.cloudflare.com, clique em **Create a project → Connect to Git** (ou **Direct Upload** para subir os arquivos manualmente, sem repositório).
2. Não é necessário build command para arquivos estáticos.
3. Deploy.

## Compartilhando os links
- Link do cliente: `https://seudominio.com/index.html` (ou apenas `/` se renomear para o arquivo raiz)
- Link do admin: `https://seudominio.com/admin.html` — envie apenas para a equipe da oficina, sem divulgar publicamente.

## Sobre a regra de horário único
O banco usa um **índice único parcial** em `(data_agendamento, hora_agendamento) WHERE status = 'confirmado'`.
Isso garante duas coisas ao mesmo tempo:
- Dois clientes nunca conseguem confirmar o mesmo horário (o banco rejeita o segundo com erro `23505`, que o `index.html` já trata mostrando uma mensagem e atualizando a grade).
- Quando a oficina **cancela** um agendamento pelo `admin.html`, o horário é liberado automaticamente para outro cliente, porque o registro cancelado deixa de contar na regra de unicidade.
