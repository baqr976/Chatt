-- Matches the migration applied to project yuwnhpbwrdfcpjonfodr.
-- The retention function is an internal trigger function, not a public RPC.
revoke execute on function public.keep_latest_10_global_chat_messages() from public, anon, authenticated;

alter table public.chat_messages
  add constraint chat_messages_username_length
    check (char_length(btrim(username)) between 1 and 32) not valid,
  add constraint chat_messages_message_length
    check (char_length(btrim(message)) between 1 and 240) not valid;

alter table public.chat_messages
  validate constraint chat_messages_username_length,
  validate constraint chat_messages_message_length;
