# 🫟

### Development Setup
```bash
pnpm setup:env
git submodule update --init --recursive
cp .env.sample .env
```

### Deploy steps
1. pnpm deploy:test --debug
2. pnpm deploy:prod --debug
3. pnpm init:test --debug
4. pnpm init:prod --debug