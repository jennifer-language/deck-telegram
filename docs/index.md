<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# @jennifer/telegram

A client for the [Telegram Bot API](https://core.telegram.org/bots/api) over
Jennifer's `http` module: send messages, photos and files, attach inline
keyboards, and poll for updates. The full API is on the
[cheatsheet](cheatsheet.md).

## Conventions

Snippets assume this import:

```jennifer
import "@jennifer/telegram/" as telegram;
```

The trailing slash resolves to the entry module.

## A bot

```jennifer
def bot as telegram.Bot init telegram.bot(os.getEnv("TELEGRAM_BOT_TOKEN"));
def me as telegram.User init telegram.getMe($bot);
```

`bot` talks to `https://api.telegram.org`; `botWith(token, baseUrl)` points at
a self-hosted Bot API server or a test endpoint. A `Bot` is a plain value with
no connection state. The token travels in the request path, so read it from the
environment and never log a request URL.

## Sending

```jennifer
telegram.sendMessage($bot, 12345678, "deploy finished");
telegram.sendMessageWith($bot, 12345678, "*deploy* finished", "MarkdownV2");
telegram.sendPhoto($bot, 12345678, "https://example.org/chart.png", "today");
telegram.sendChatAction($bot, 12345678, "typing");
```

Each returns the sent `Message` (`sendChatAction` returns `true`). Chat ids
are ints; group and channel ids are negative.

With `"HTML"`, `"Markdown"` or `"MarkdownV2"`, Telegram reads markup in the
whole text. Escape text from elsewhere (a user name, a commit message) as that
parse mode requires before you interpolate it, or send it with `parseMode` set
to `""`.

Local files go up as `multipart/form-data`:

```jennifer
telegram.sendPhotoFile($bot, 12345678, "chart.png", "image/png");
telegram.sendDocumentFile($bot, 12345678, "report.pdf", "");
```

An empty content type lets Telegram detect it. `buildUpload` builds the same
form without sending it. The request timeout is an idle timeout, so a large
upload on a slow link is not cut off while data keeps flowing.

## Inline keyboards

A keyboard is a list of rows of buttons. `urlButton` opens a link;
`inlineButton` sends its data back to the bot as a callback query.

```jennifer
def rows as list of list of telegram.Button init [
    [telegram.urlButton("Logs", "https://ci.example.com/1234")],
    [telegram.inlineButton("Retry", "retry:1234"), telegram.inlineButton("Ignore", "ignore")]
];
telegram.sendMessageWithKeyboard($bot, 12345678, "build 1234 failed", $rows);
```

`renderInlineKeyboard` gives the `reply_markup` JSON on its own.

## Receiving updates

`getUpdates` long-polls. Pass the last processed `updateId + 1` as the offset,
so Telegram drops what you have seen:

```jennifer
def offset as int init 0;
while (true) {
    for (def u in telegram.getUpdates($bot, $offset, 30)) {
        $offset = $u.updateId + 1;
        if ($u.hasMessage) {
            telegram.sendMessage($bot, $u.message.chatId, "you said: " + $u.message.text);
        }
    }
}
```

`Update` carries text messages only: any other update, a button press
included, arrives with `hasMessage` false and its content dropped. To see
button presses, poll with `getUpdatesRaw`, which returns each update as decoded
JSON. `parseUpdate` turns one into an `Update` and `parseCallbackQuery` reads
its button press; acknowledge the press with `answerCallbackQuery` so the
client stops its spinner:

```jennifer
def offset as int init 0;
while (true) {
    for (def raw in telegram.getUpdatesRaw($bot, $offset, 30)) {
        def u as telegram.Update init telegram.parseUpdate($raw);
        $offset = $u.updateId + 1;
        def cq as telegram.CallbackQuery init telegram.parseCallbackQuery($raw);
        if ($cq.id != "") {
            telegram.answerCallbackQuery($bot, $cq.id, "got " + $cq.data);
        } else if ($u.hasMessage) {
            telegram.sendMessage($bot, $u.message.chatId, "you said: " + $u.message.text);
        }
    }
}
```

## Errors

Every API call throws `Error{kind: "telegram"}` when Telegram answers
`{"ok": false}` (the message is Telegram's `description`), when the reply is not
JSON or has a field of the wrong type, or when the request fails in transport. Transport errors have the token
removed from the message; `redactToken` does the same for your own logs.

## Runtime

Needs `net`, so it runs on the default `jennifer` binary. The stock
`jennifer-tiny` has no network driver and every call throws.

## Moving from the standard library module

Jennifer has shipped `telegram` as a standard library module
(`modules/telegram.j`) since 0.18.0; inline keyboards, callback queries, file
uploads and `redactToken` came in 0.23.0. The module is deprecated from
Jennifer 0.26.0 and removed in 0.28.0. This deck replaces it with the same
types and functions; only the import changes:

```jennifer
import "telegram.j" as telegram;              # before
import "@jennifer/telegram/" as telegram;     # after: jvc add @jennifer/telegram
```

The deck adds `getUpdatesRaw` and `parseUpdate`, so button presses can be
received at all. A reply with a field of the wrong type throws a `telegram`
error where the module threw a `json` one.
