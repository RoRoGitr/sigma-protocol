---
name: telegram-bot-development
description: "Build Telegram bots with grammy — BotFather setup, commands, inline keyboards, conversations, webhooks, and deployment"
triggers:
  - telegram
  - bot
  - grammy
  - botfather
---

# Telegram Bot Development Skill

Build production-ready Telegram bots using grammy (TypeScript). Covers BotFather setup, command handlers, inline keyboards, conversation flows, media handling, and webhook deployment.

## When to Invoke

- Creating a new Telegram bot from scratch
- Adding commands or interactive keyboards
- Building multi-step conversation flows
- Handling media (photos, videos, documents)
- Deploying a bot with webhooks

---

## Project Structure

```
my-telegram-bot/
├── src/
│   ├── commands/           # Command handlers
│   │   ├── start.ts
│   │   ├── help.ts
│   │   └── settings.ts
│   ├── conversations/      # Multi-step flows
│   │   └── onboarding.ts
│   ├── keyboards/          # Reusable keyboard layouts
│   │   ├── mainMenu.ts
│   │   └── settings.ts
│   ├── middleware/          # Error handling, logging, auth
│   │   ├── error.ts
│   │   └── auth.ts
│   ├── utils/
│   │   └── logger.ts
│   └── bot.ts              # Bot setup and launch
├── .env.example
├── package.json
├── tsconfig.json
└── Dockerfile
```

## Scaffolding

### package.json essentials

```json
{
  "dependencies": {
    "grammy": "^1.30.0",
    "@grammyjs/conversations": "^2.0.0",
    "@grammyjs/runner": "^2.0.0",
    "dotenv": "^16.4.0"
  },
  "devDependencies": {
    "typescript": "^5.6.0",
    "@types/node": "^22.0.0",
    "tsx": "^4.19.0"
  }
}
```

### Bot setup

```typescript
import { Bot, session } from 'grammy';
import { conversations, createConversation } from '@grammyjs/conversations';
import 'dotenv/config';

const bot = new Bot(process.env.TELEGRAM_BOT_TOKEN!);

// Session for conversations
bot.use(session({ initial: () => ({}) }));
bot.use(conversations());

// Register commands
bot.command('start', (ctx) => ctx.reply('Welcome! Use /help to see commands.'));
bot.command('help', (ctx) => ctx.reply('Available commands:\n/start - Start bot\n/help - Show help'));

// Error handling
bot.catch((err) => {
  console.error('Bot error:', err);
});

// Start
bot.start();
```

## BotFather Setup

### Step-by-step

1. Open Telegram, search for `@BotFather`
2. Send `/newbot`
3. Enter display name (e.g., "My Project Bot")
4. Enter username (must end in `bot`, e.g., `myproject_bot`)
5. Copy the token BotFather gives you
6. Configure bot profile:
   - `/setcommands` — define the command menu
   - `/setdescription` — bot description shown in profile
   - `/setabouttext` — about text in bot info
   - `/setuserpic` — bot avatar

### Command menu format

```
start - Start the bot
help - Show available commands
settings - Configure preferences
```

## Inline Keyboards

```typescript
import { InlineKeyboard } from 'grammy';

const keyboard = new InlineKeyboard()
  .text('Option A', 'callback_a')
  .text('Option B', 'callback_b')
  .row()
  .text('Cancel', 'callback_cancel');

await ctx.reply('Choose an option:', { reply_markup: keyboard });

// Handle callbacks
bot.callbackQuery('callback_a', async (ctx) => {
  await ctx.answerCallbackQuery({ text: 'You chose A!' });
  await ctx.editMessageText('You selected Option A.');
});
```

## Conversation Flows

```typescript
import { type Conversation, type ConversationFlavor } from '@grammyjs/conversations';

type MyContext = ConversationFlavor<Context>;

async function onboarding(conversation: Conversation<MyContext>, ctx: MyContext) {
  await ctx.reply('What is your name?');
  const { message } = await conversation.wait();
  const name = message?.text;

  await ctx.reply(`Nice to meet you, ${name}! What is your role?`);
  const { message: roleMsg } = await conversation.wait();
  const role = roleMsg?.text;

  await ctx.reply(`Welcome, ${name} (${role})! Setup complete.`);
}

bot.use(createConversation(onboarding));
bot.command('onboard', async (ctx) => {
  await ctx.conversation.enter('onboarding');
});
```

## Media Handling

```typescript
// Send photo
await ctx.replyWithPhoto(new InputFile('/path/to/image.png'), {
  caption: 'Check this out!',
  parse_mode: 'HTML',
});

// Send document
await ctx.replyWithDocument(new InputFile(buffer, 'report.pdf'), {
  caption: 'Here is your report',
});

// Media group (album)
await ctx.replyWithMediaGroup([
  InputMediaBuilder.photo(new InputFile('/path/to/photo1.jpg')),
  InputMediaBuilder.photo(new InputFile('/path/to/photo2.jpg')),
]);
```

## Rate Limits

| Scope | Limit |
|-------|-------|
| Messages to different chats | 30/second |
| Messages to same group | 20/minute |
| Bulk notifications | 30 messages/second |
| File upload | 50 MB (bot), 20 MB (photo) |
| Message length | 4096 characters |
| Caption length | 1024 characters |
| Inline results | 50 per query |

## Deployment

### Webhook (production)

```typescript
import { webhookCallback } from 'grammy';
import express from 'express';

const app = express();
app.use(express.json());
app.post('/webhook', webhookCallback(bot, 'express'));
app.listen(3000);

// Set webhook URL
await bot.api.setWebhook('https://your-domain.com/webhook');
```

### Long polling (development only)

```typescript
bot.start(); // Uses long polling by default
```

### Docker

```dockerfile
FROM node:22-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY dist/ ./dist/
CMD ["node", "dist/bot.js"]
```

## Security Checklist

- [ ] Bot token in environment variable, never committed
- [ ] `.env` in `.gitignore`
- [ ] Webhook URL uses HTTPS
- [ ] Input validation on all user messages
- [ ] Rate limit handling implemented
- [ ] Error boundary middleware configured
- [ ] Admin command authorization checks
