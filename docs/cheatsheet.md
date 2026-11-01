<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# telegram cheatsheet

Every export of `@jennifer/telegram`. Background is in
[the introduction](index.md).

```jennifer
import "@jennifer/telegram/" as telegram;
```

API calls throw `Error{kind: "telegram"}` on `{"ok": false}`, a non-JSON reply
or a transport failure, with the token removed from the message.

## Types

### `Bot`

| Field | Meaning |
|---|---|
| `token as string` | bot token from BotFather |
| `baseUrl as string` | API base URL, no trailing slash |

### `User`

| Field | Meaning |
|---|---|
| `id as int` | user id |
| `isBot as bool` | whether the user is a bot |
| `firstName as string` | first name |
| `username as string` | username, `""` if none |

### `Message`

| Field | Meaning |
|---|---|
| `messageId as int` | message id |
| `chatId as int` | chat id |
| `text as string` | text, `""` for non-text messages |
| `date as int` | send time, Unix seconds |

### `Update`

| Field | Meaning |
|---|---|
| `updateId as int` | update id; poll from this + 1 next |
| `hasMessage as bool` | whether `message` is set |
| `message as Message` | the message, zero when `hasMessage` is false |

### `Button`

| Field | Meaning |
|---|---|
| `text as string` | label |
| `url as string` | URL to open, `""` for a callback button |
| `callbackData as string` | callback payload, `""` for a URL button |

### `CallbackQuery`

| Field | Meaning |
|---|---|
| `id as string` | id to pass to `answerCallbackQuery` |
| `from as User` | who pressed the button |
| `data as string` | the button's callback data |
| `messageId as int` | message the button belongs to, 0 if absent |

## Bots

| Function | Returns | Notes |
|---|---|---|
| `telegram.bot(token)` | `Bot` | public API |
| `telegram.botWith(token, baseUrl)` | `Bot` | self-hosted server or test endpoint |
| `telegram.getMe(b)` | `User` | token check |

## Sending

| Function | Returns | Notes |
|---|---|---|
| `telegram.sendMessage(b, chatId, text)` | `Message` | |
| `telegram.sendMessageWith(b, chatId, text, parseMode)` | `Message` | `"Markdown"`, `"MarkdownV2"`, `"HTML"` or `""` |
| `telegram.sendMessageWithKeyboard(b, chatId, text, rows)` | `Message` | inline keyboard |
| `telegram.sendPhoto(b, chatId, photo, caption)` | `Message` | URL or file id |
| `telegram.sendPhotoFile(b, chatId, filePath, contentType)` | `Message` | multipart upload |
| `telegram.sendDocumentFile(b, chatId, filePath, contentType)` | `Message` | multipart upload |
| `telegram.sendChatAction(b, chatId, action)` | `bool` | `"typing"`, `"upload_photo"`, ... |

## Keyboards and callbacks

| Function | Returns | Notes |
|---|---|---|
| `telegram.urlButton(text, url)` | `Button` | opens a link |
| `telegram.inlineButton(text, callbackData)` | `Button` | sends a callback query |
| `telegram.renderInlineKeyboard(rows)` | `string` | the `reply_markup` JSON |
| `telegram.parseCallbackQuery(update)` | `CallbackQuery` | from a raw update (`getUpdatesRaw`); `id` is `""` when it is not a button press |
| `telegram.answerCallbackQuery(b, callbackId, text)` | `bool` | stops the client's spinner |

## Receiving

| Function | Returns | Notes |
|---|---|---|
| `telegram.getUpdates(b, offset, timeout)` | `list of Update` | long poll, `timeout` in seconds; text messages only |
| `telegram.getUpdatesRaw(b, offset, timeout)` | `list of json.Value` | the same poll, every update as decoded JSON |
| `telegram.parseUpdate(update)` | `Update` | one raw update; throws `telegram` without `update_id` |

## Helpers

| Function | Returns | Notes |
|---|---|---|
| `telegram.buildUpload(field, chatId, filename, contentType, data)` | `multipart.Built` | an upload form, not sent |
| `telegram.redactToken(s, token)` | `string` | removes the token from a string |
