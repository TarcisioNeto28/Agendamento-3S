-- =========================================================================
-- SCHEMA: Agendamento de Serviços - Oficina de Auto Elétrica
-- Banco de Dados: Supabase (PostgreSQL)
-- =========================================================================
-- Como usar:
-- 1. Acesse seu projeto em https://app.supabase.com
-- 2. Vá em "SQL Editor" -> "New query"
-- 3. Cole todo este arquivo e clique em "Run"
-- =========================================================================

-- Extensão necessária para gerar UUIDs (geralmente já vem habilitada no Supabase)
create extension if not exists "pgcrypto";

-- -------------------------------------------------------------------------
-- 1. TABELA PRINCIPAL
-- -------------------------------------------------------------------------
create table if not exists public.agendamentos (
    id                   uuid primary key default gen_random_uuid(),
    created_at           timestamptz not null default now(),

    cliente_nome         text not null,
    cliente_whatsapp     text not null,

    veiculo_modelo       text not null,
    placa_veiculo        text,

    categoria_problema   text not null,
    descricao_problema   text,

    data_agendamento     date not null,
    hora_agendamento     time not null,

    status               text not null default 'confirmado'
                          constraint agendamentos_status_check
                          check (status in ('confirmado', 'concluido', 'cancelado'))
);

comment on table public.agendamentos is 'Agendamentos de serviços de auto elétrica marcados pelos clientes';

-- -------------------------------------------------------------------------
-- 2. REGRA DE UNICIDADE DE HORÁRIO
-- -------------------------------------------------------------------------
-- Impede dois agendamentos ATIVOS ("confirmado") no mesmo dia/horário.
-- Usamos um índice único PARCIAL (em vez de uma UNIQUE constraint simples)
-- para que, quando um agendamento for CANCELADO, o horário seja liberado
-- automaticamente para um novo cliente — sem isso, o slot ficaria travado
-- para sempre mesmo após o cancelamento.
create unique index if not exists agendamentos_slot_unico
    on public.agendamentos (data_agendamento, hora_agendamento)
    where (status = 'confirmado');

-- Índice auxiliar para acelerar a consulta "quais horários já estão
-- ocupados nesta data", que é chamada toda vez que o cliente escolhe uma data.
create index if not exists agendamentos_por_data
    on public.agendamentos (data_agendamento, status);

-- -------------------------------------------------------------------------
-- 3. ROW LEVEL SECURITY (RLS)
-- -------------------------------------------------------------------------
alter table public.agendamentos enable row level security;

-- Qualquer visitante (chave anon) pode LER os agendamentos.
-- Necessário para o site consultar quais horários já estão ocupados.
create policy "Leitura publica de agendamentos"
    on public.agendamentos
    for select
    to anon
    using (true);

-- Qualquer visitante (chave anon) pode CRIAR um novo agendamento.
create policy "Criacao publica de agendamentos"
    on public.agendamentos
    for insert
    to anon
    with check (true);

-- Qualquer visitante com a chave anon pode ATUALIZAR (usado pelo admin.html
-- para cancelar/concluir agendamentos). Como o projeto não usa login do
-- Supabase Auth, o painel admin.html é protegido apenas por uma senha
-- simples no navegador (ver instruções). Para um ambiente de produção com
-- mais de um funcionário, o ideal é trocar isso por Supabase Auth e
-- restringir esta policy a usuários autenticados (to authenticated).
create policy "Atualizacao publica de agendamentos"
    on public.agendamentos
    for update
    to anon
    using (true)
    with check (true);

-- (Opcional) Não criamos policy de DELETE de propósito: agendamentos nunca
-- são apagados, apenas marcados como 'cancelado' ou 'concluido'. Isso
-- mantém um histórico completo para a oficina.

-- =========================================================================
-- FIM DO SCRIPT
-- =========================================================================
