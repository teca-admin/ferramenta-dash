# WFS Dashboard — Movimentação de Cargas

Dashboard interno da Worldflight Services para acompanhamento de movimentação de cargas.

## Deploy

1. Suba este repositório no GitHub
2. Importe no [Vercel](https://vercel.com) → **Add New Project** → seleciona o repo
3. Framework Preset: **Other** → clica **Deploy**

## Banco de dados

Execute o arquivo `wfs-schema.sql` no **SQL Editor** do seu Supabase self-hosted antes do primeiro uso.

## Estrutura

```
index.html      ← aplicação completa (HTML + CSS + JS)
vercel.json     ← configuração de roteamento do Vercel
wfs-schema.sql  ← SQL para criar o schema e tabelas no Supabase
README.md       ← este arquivo
```
