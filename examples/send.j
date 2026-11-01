#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * Send a message: TELEGRAM_BOT_TOKEN=... TELEGRAM_CHAT_ID=... jennifer run examples/send.j
 *
 * Identifies the bot, then sends a plain message and one with a URL button to
 * the chat. Without both variables it prints a hint and sends nothing; on an
 * API or network error it prints the error.
 */

use convert;
use io;
use os;

import "../src/telegram.j" as telegram;

def token as string init os.getEnv("TELEGRAM_BOT_TOKEN");
def chat as string init os.getEnv("TELEGRAM_CHAT_ID");

if (len($token) == 0 or len($chat) == 0) {
    io.printf("set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID to send a message\n");
} else {
    def bot as telegram.Bot init telegram.bot($token);
    def chatId as int init convert.toInt($chat);
    try {
        def me as telegram.User init telegram.getMe($bot);
        io.printf("bot: @%s\n", $me.username);
        def m as telegram.Message init telegram.sendMessage(
            $bot,
            $chatId,
            "Hello from @jennifer/telegram");
        io.printf("sendMessage -> message %d\n", $m.messageId);
        def rows as list of list of telegram.Button init [
            [telegram.urlButton("Docs", "https://jennifer-language.github.io/deck-telegram/")]
        ];
        def k as telegram.Message init telegram.sendMessageWithKeyboard(
            $bot,
            $chatId,
            "Tap to open the docs",
            $rows);
        io.printf("sendMessageWithKeyboard -> message %d\n", $k.messageId);
    } catch (e) {
        io.printf("%s\n", $e.message);
    }
}
